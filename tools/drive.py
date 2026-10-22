#!/usr/bin/env python3
"""Drive the game in headless Chrome via CDP for verification.

Usage: drive.py <url> <outdir> [--wait N] [--eval JS] [--keys WASD-script] [--shots N,N,N]
                                [--evalat "t;JS|t;JS"]  (run JS in the page at time t)

Launches headless Chrome with a debug port, navigates, waits REAL seconds
(no virtual time), can evaluate JS in the page, inject key events, and save
screenshots. Prints console messages and eval results to stdout.
"""
import base64, json, subprocess, sys, time, urllib.request

import websocket

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

def main():
    url = sys.argv[1]
    outdir = sys.argv[2]
    args = sys.argv[3:]

    def opt(name, default=None):
        return args[args.index(name) + 1] if name in args else default

    global PORT
    PORT = int(opt("--port", "9333"))

    wait = float(opt("--wait", "10"))
    shots = [float(s) for s in opt("--shots", str(wait)).split(",")]
    evaljs = opt("--eval")
    keys = opt("--keys")  # e.g. "2:KeyD:1.0,4:KeyW:0.5"  at t=2 hold D 1s...
    clicks = opt("--clicks")  # e.g. "2:480:432,4:654:510"  at t=2 click (480,432)

    import tempfile
    profile = tempfile.mkdtemp(prefix="drive-profile-")
    flags = [f"--remote-debugging-port={PORT}", "--remote-allow-origins=*",
             opt("--winsize","--window-size=960,660") if False else ("--window-size=" + opt("--winsize","960,660")), f"--user-data-dir={profile}",
             "--no-first-run", "--disable-session-crashed-bubble",
             "--hide-crash-restore-bubble", "--disable-infobars", "about:blank"]
    if "--headed" not in args:
        flags = ["--headless", "--disable-gpu"] + flags
    proc = subprocess.Popen([CHROME] + flags,
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        for _ in range(50):
            try:
                targets = json.load(urllib.request.urlopen(f"http://localhost:{PORT}/json"))
                page = next(t for t in targets if t["type"] == "page")
                break
            except Exception:
                time.sleep(0.2)
        ws = websocket.create_connection(page["webSocketDebuggerUrl"], timeout=30)
        mid = [0]

        def send(method, params=None, wait_result=True):
            mid[0] += 1
            ws.send(json.dumps({"id": mid[0], "method": method, "params": params or {}}))
            if not wait_result:
                return None
            ws.settimeout(1.0)
            deadline = time.time() + 15
            try:
                while time.time() < deadline:
                    try:
                        msg = json.loads(ws.recv())
                    except websocket.WebSocketTimeoutException:
                        continue
                    if msg.get("id") == mid[0]:
                        return msg.get("result", {})
                    if msg.get("method") == "Runtime.consoleAPICalled":
                        parts = [a.get("value", a.get("description", "?")) for a in msg["params"]["args"]]
                        print("CONSOLE:", " ".join(str(p) for p in parts)[:300])
            finally:
                ws.settimeout(30)
            print(f"WARN: no response for {method}", flush=True)
            return {}

        def drain(seconds):
            ws.settimeout(0.2)
            end = time.time() + seconds
            while time.time() < end:
                try:
                    msg = json.loads(ws.recv())
                    if msg.get("method") == "Runtime.consoleAPICalled":
                        parts = [a.get("value", a.get("description", "?")) for a in msg["params"]["args"]]
                        print("CONSOLE:", " ".join(str(p) for p in parts)[:300])
                    elif msg.get("method") == "Runtime.exceptionThrown":
                        print("EXCEPTION:", json.dumps(msg["params"])[:500])
                except websocket.WebSocketTimeoutException:
                    pass
            ws.settimeout(30)

        VK = {"ArrowUp": 38, "ArrowDown": 40, "ArrowLeft": 37, "ArrowRight": 39,
              "Escape": 27, "Space": 32, "Enter": 13, "Backquote": 192, "Slash": 191, "ShiftLeft": 16}

        def vk_of(code):
            if code.startswith("Key") and len(code) == 4:
                return ord(code[3])  # KeyA..KeyZ
            return VK.get(code, 0)

        def key_event(t, code, hold):
            drain(max(0, t - elapsed[0]))
            elapsed[0] = max(elapsed[0], t)
            vk = vk_of(code)
            key = code[-1].lower() if code.startswith("Key") else code
            base = {"code": code, "key": key,
                    "windowsVirtualKeyCode": vk, "nativeVirtualKeyCode": vk}
            print(f"KEY: {code} down t={t}", flush=True)
            send("Input.dispatchKeyEvent", dict(base, type="keyDown"))
            drain(hold)
            elapsed[0] += hold
            send("Input.dispatchKeyEvent", dict(base, type="keyUp"))
            print(f"KEY: {code} up", flush=True)

        def click_event(t, gx, gy):
            drain(max(0, t - elapsed[0]))
            elapsed[0] = max(elapsed[0], t)
            # map game coords (960x640 design space) through the letterboxed canvas
            res = send("Runtime.evaluate", {"expression":
                "(()=>{const c=document.querySelector('canvas');if(!c)return null;"
                "const r=c.getBoundingClientRect();return [r.x,r.y,r.width,r.height];})()",
                "returnByValue": True})
            rect = res.get("result", {}).get("value")
            if rect:
                x = rect[0] + gx / 960.0 * rect[2]
                y = rect[1] + gy / 640.0 * rect[3]
            else:
                x, y = gx, gy
            print(f"CLICK: game({gx},{gy}) -> css({int(x)},{int(y)}) t={t}", flush=True)
            for typ, count in (("mouseMoved", 0), ("mousePressed", 1), ("mouseReleased", 1)):
                send("Input.dispatchMouseEvent", {"type": typ, "x": x, "y": y,
                                                  "button": "left" if count else "none",
                                                  "clickCount": count})
                drain(0.06)
                elapsed[0] += 0.06

        send("Runtime.enable")
        send("Page.enable")
        send("Page.navigate", {"url": url})

        elapsed = [0.0]
        events = []
        if keys:
            for spec in keys.split(","):
                t, code, hold = spec.split(":")
                events.append((float(t), "key", (code, float(hold))))
        if clicks:
            for spec in clicks.split(","):
                t, x, y = spec.split(":")
                events.append((float(t), "click", (int(x), int(y))))
        evalat = opt("--evalat")
        if evalat:
            for spec in evalat.split("|"):
                t, js = spec.split(";", 1)
                events.append((float(t), "eval", (js,)))

        def eval_event(t, js):
            drain(max(0, t - elapsed[0]))
            elapsed[0] = max(elapsed[0], t)
            res = send("Runtime.evaluate", {"expression": js, "returnByValue": True})
            out = res.get("result", {}).get("value")
            if out is None and res.get("exceptionDetails"):
                out = "EXC " + json.dumps(res["exceptionDetails"])[:400]
            print(f"EVALAT t={t}:", json.dumps(out)[:400], flush=True)

        for t, kindE, args in sorted(events, key=lambda e: e[0]):
            if kindE == "key":
                key_event(t, *args)
            elif kindE == "eval":
                eval_event(t, *args)
            else:
                click_event(t, *args)
        shot_i = 0
        for s in sorted(shots):
            drain(max(0, s - elapsed[0]))
            elapsed[0] = max(elapsed[0], s)
            data = send("Page.captureScreenshot")["data"]
            path = f"{outdir}/shot_{shot_i}.png"
            with open(path, "wb") as f:
                f.write(base64.b64decode(data))
            print("SHOT:", path, f"t={s}")
            shot_i += 1
        if evaljs:
            res = send("Runtime.evaluate", {"expression": evaljs, "returnByValue": True})
            value = res.get("result", {}).get("value")
            evalfile = opt("--evalfile")
            if evalfile:
                with open(evalfile, "w") as f:
                    f.write(value if isinstance(value, str) else json.dumps(value))
                print("EVALFILE:", evalfile, len(value) if isinstance(value, str) else "?")
            else:
                print("EVAL:", json.dumps(value)[:1000])
    finally:
        proc.terminate()


if __name__ == "__main__":
    main()
