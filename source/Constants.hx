class Constants
{
	// Tiles / rooms
	public static inline var TILE:Int = 64;
	public static inline var HUD_H:Int = 64;

	// Room size is set per level (setRoomSize): 15x9 islands, 23x13 for the Keep
	public static var ROOM_TW:Int = 15; // tiles wide
	public static var ROOM_TH:Int = 9; // tiles high
	public static var ROOM_W:Int = 15 * 64;
	public static var ROOM_H:Int = 9 * 64;

	// Door cells (tile coords within a room): middle of each edge
	public static var DOOR_N_X:Int = 7;
	public static var DOOR_S_X:Int = 7;
	public static var DOOR_W_Y:Int = 4;
	public static var DOOR_E_Y:Int = 4;

	public static function setRoomSize(tw:Int, th:Int):Void
	{
		ROOM_TW = tw;
		ROOM_TH = th;
		ROOM_W = tw * TILE;
		ROOM_H = th * TILE;
		DOOR_N_X = DOOR_S_X = Std.int(tw / 2);
		DOOR_W_Y = DOOR_E_Y = Std.int(th / 2);
	}

	/** Cells that must stay free of solid props: doors and their two approach cells. */
	public static function reservedCells():Array<Array<Int>>
	{
		var cx = DOOR_N_X, cy = DOOR_W_Y;
		return [
			[cx, 0], [cx, ROOM_TH - 1], [0, cy], [ROOM_TW - 1, cy],
			[cx, 1], [cx, 2], [1, cy], [2, cy], [ROOM_TW - 3, cy], [ROOM_TW - 2, cy], [cx, ROOM_TH - 3], [cx, ROOM_TH - 2],
		];
	}

	// Floor grid
	public static inline var FLOOR_GRID:Int = 9;
	public static inline var FLOOR_ROOMS:Int = 8;

	// Player
	public static inline var PLAYER_SPEED:Float = 340;
	public static inline var PLAYER_MAX_HP:Int = 6;
	public static inline var PLAYER_IFRAMES:Float = 1.0;

	// Combat
	public static inline var ARROW_SPEED:Float = 600;
	public static inline var BOW_COOLDOWN:Float = 0.52;
}
