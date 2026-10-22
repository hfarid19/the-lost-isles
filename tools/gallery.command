#!/bin/bash
# Boots the Mac build straight into the sprite-gallery floor (all downloaded monster / chest packs at 2x).
cd "$(dirname "$0")/.."
PACKS=1 ./export/macos/bin/TheLostIsles.app/Contents/MacOS/TheLostIsles
