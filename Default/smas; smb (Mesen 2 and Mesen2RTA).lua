--Thank you to @Simplistic for helping me fix the Frame counter display and for helping me with the X subpixel string
--Note: the "Backwards Pole?" feature isn't entirely accurate, but it's like 95% accurate

--Before running the script, you MUST set this variable to the region you're playing on — NTSC or PAL — in order for the timer to use
--the right framerate. If you set this variable to a non-valid value, this will make the timer default to you not playing on PAL.
local region = "NTSC" --Valid inputs: '"NTSC"' and '"PAL"'

--toggle features, change to false if you don't want them
local toggle_display_practice_information           = true
local toggle_display_sprite_hitboxes                = true
local toggle_display_mario_hitbox                   = true
local toggle_display_hitbox_collision_check         = false
local toggle_display_sprite_slot_above_sprite       = true
local toggle_display_sprite_information             = true
local toggle_display_sprite_information_after_death = false
local toggle_display_time                           = true
local toggle_display_21_framerule                   = true
local toggle_display_mario_position                 = true
local toggle_display_mario_velocity                 = true
local toggle_display_mario_acceleration             = true
local toggle_display_state                          = true

--variables
local text_colour             = 0xFFFFFF
local text_faded_colour       = 0x7FFFFFFF
local text_back_colour        = 0x99000000
local text_faded_back_colour  = 0xCC000000
local hitbox_edge_colour_on   = 0x00FF00 --Hitbox back and edge colour for when collisions are being checked (always used when not showing hitbox collision check)
local hitbox_back_colour_on   = 0x7F00FF00
local hitbox_edge_colour_off  = 0x00FF00 --Hitbox back and edge colour for when collisions are not being checked
local hitbox_back_colour_off  = 0xFF000000
local sprite_slot_text_colour = 0xFFFFFF
local sprite_slot_back_colour = 0x99000000

--Timer settings:
local timer_end = {
	{0x770, 2},
	{0x75F, 7}
}
local timer_reset = {
	{0x6C9, 2},
}

--Kaname settings:
local User_Var_A = 0x3AD
local User_Var_B = 0x705

--all of the wram addresses I need
local wram_FrameCounter          = 9
local wram_A_B_Buttons           = 0xA
local wram_GameEngineSubroutine  = 0xF
local wram_Enemy_Flag            = 0x10
local wram_Enemy_ID              = 0x1C
local wram_Player_State          = 0x28
local wram_Fireball_State        = 0x33
local wram_Misc_State            = 0x39
local wram_Player_X_Speed        = 0x5D
local wram_SprObject_PageLoc     = 0x78
local wram_Player_Y_Speed        = 0xA0
local wram_FloateyNum_Timer      = 0x138
local wram_SprObject_X_Position  = 0x219
local wram_SprObject_Y_Position  = 0x237
local wram_BowserOrigXPos        = 0x366
local wram_Player_Rel_XPos       = 0x3AD
local wram_SprObject_X_MoveForce = 0x401
local wram_SprObject_YMF_Dummy   = 0x41C
local wram_Player_Y_MoveForce    = 0x43C
local wram_WarpZoneControl       = 0x6D6
local wram_FrictionAdderLow      = 0x702
local wram_Player_X_MoveForce    = 0x705
local wram_VerticalForce         = 0x709
local wram_JumpspringAnimCtrl    = 0x70E
local wram_ScreenLeft_PageLoc    = 0x71A
local wram_ScreenLeft_X_Pos      = 0x71C
local wram_ScreenRoutineTask     = 0x73C
local wram_StarFlagTaskControl   = 0x746
local wram_AltEntranceControl    = 0x752
local wram_LevelNumber           = 0x75C
local wram_WorldNumber           = 0x75F
local wram_OperMode              = 0x770
local wram_OperMode_Task         = 0x772
local wram_DisableScreenFlag     = 0x774
local wram_IntervalTimerControl  = 0x787
local wram_JumpSwimTimer         = 0x78A
local wram_BoundingBox_UL_Corner = 0xF9C
local wram_Sample7SoundQueue     = 0x1603

--Practice information variables:
local sock            = 0
local xstring         = 0
local xstringactual   = 0
local ypos            = 0
BackwardsPole         = false
BowserFrame           = false
DontDisplaySock       = false
Frame                 = 0
FrameDisplay          = -1
FrameDisplay2         = -1
FrameDisplay3         = -1
PreviousA_B_Buttons   = 0
RemainderDisplay      = -1
RemainderDisplay2     = -1
ScreenEnterDisplay    = 0
WZ_or_Title_Remainder = false

--Timer variables:
start_frame   = -1
start_reached = false
end_frame     = -1
end_reached   = false

function drawString(x, y, text, text_colour, text_back_colour)
	emu.drawLine(x - 1, y - 1, x - 1, y + 7, text_back_colour)
	emu.drawString(x, y, text, text_colour, text_back_colour)
end

function display_practice_information() --Code to display practice information
	if emu.read(wram_Player_X_Speed, emu.memType.snesMemory) < 0x19 or emu.read(wram_Player_X_Speed, emu.memType.snesMemory) > 0xE7 then
		y = 24
	else
		y = 40
	end
	local xstringvalue = (((emu.read(wram_SprObject_PageLoc, emu.memType.snesMemory) << 12)
		+ (emu.read(wram_SprObject_X_Position, emu.memType.snesMemory) << 4)
		+ (emu.read(wram_SprObject_X_MoveForce, emu.memType.snesMemory) >> 4)) % y) >> 3
	local sockvalue = (emu.read(wram_SprObject_X_Position, emu.memType.snesMemory) << 8)
		+ emu.read(wram_SprObject_X_MoveForce, emu.memType.snesMemory)
		+ ((0xFF - emu.read(wram_SprObject_Y_Position, emu.memType.snesMemory) >> 2) * 0x280)
	if emu.read(wram_IntervalTimerControl, emu.memType.snesMemory) & 3 == 3 then
		xstringactual = xstringvalue
	end
	if emu.read(wram_IntervalTimerControl, emu.memType.snesMemory) & 3 == 2 then
		xstring = xstringactual
		sock = sockvalue & 0xFFF
		ypos = emu.read(wram_SprObject_Y_Position, emu.memType.snesMemory) & 3
		DontDisplaySock = false
	end
	if emu.read(wram_DisableScreenFlag, emu.memType.snesMemory) ~= 0 or emu.read(wram_GameEngineSubroutine, emu.memType.snesMemory) == 0
	or emu.read(wram_ScreenRoutineTask, emu.memType.snesMemory) >= 7 and emu.read(wram_ScreenRoutineTask, emu.memType.snesMemory) <= 9
	or emu.read(wram_AltEntranceControl, emu.memType.snesMemory) == 2 then
		DontDisplaySock = true
	end
	if DontDisplaySock then
		drawString(1, 16, "S:0000-0", text_back_colour, text_back_colour)
		emu.drawString(1, 16, "S:", text_colour, 0xFF000000)
	else
		drawString(1, 16, string.format("S:%d%03X-%d", xstring, sock, ypos), text_colour, text_back_colour)
	end
	
	if emu.read(wram_ScreenRoutineTask, emu.memType.snesMemory) == 4 then
		local chars = "0123456789ABCDEFGHIJK"
		Frame = emu.read(wram_FrameCounter, emu.memType.snesMemory)
		ScreenEnterDisplay = string.sub(chars, emu.read(wram_IntervalTimerControl, emu.memType.snesMemory) + 1, emu.read(wram_IntervalTimerControl, emu.memType.snesMemory) + 1)
	end
	drawString(34, 8, string.format("-%s", ScreenEnterDisplay), text_colour, text_back_colour)
	
	for i = 0, 8, 1 do
		if emu.read(wram_Enemy_Flag + i, emu.memType.snesMemory, 1) > 0 and emu.read(wram_Enemy_ID + i, emu.memType.snesMemory) == 0x2D
		and emu.read(wram_SprObject_X_Position + i + 1, emu.memType.snesMemory) == emu.read(wram_BowserOrigXPos, emu.memType.snesMemory) then
			BowserFrame = true
			break
		end
	end
	local EnemyFrame = false
	for j = 0, 9, 1 do
		if emu.read(wram_FloateyNum_Timer + j, emu.memType.snesMemory) == 0x2A then
			EnemyFrame = true
			break
		end
	end
	if (emu.read(wram_OperMode, emu.memType.snesMemory) == 0 and emu.read(wram_FrameCounter, emu.memType.snesMemory) & 1 == 0)
	or emu.read(wram_GameEngineSubroutine, emu.memType.snesMemory) == 7
	or emu.read(wram_JumpSwimTimer, emu.memType.snesMemory) == 0x20 or EnemyFrame or emu.read(wram_Sample7SoundQueue, emu.memType.snesMemory) == 6
	or (emu.read(wram_Player_State, emu.memType.snesMemory) == 3 and (emu.read(wram_GameEngineSubroutine, emu.memType.snesMemory) == 4
	or emu.read(wram_GameEngineSubroutine, emu.memType.snesMemory) == 5 and emu.read(wram_SprObject_Y_Position, emu.memType.snesMemory) >= 0xA2))
	or emu.read(wram_StarFlagTaskControl, emu.memType.snesMemory) == 2 then
		BowserFrame = false
		if FrameDisplay == -1 then
			FrameDisplay = emu.read(wram_FrameCounter, emu.memType.snesMemory)
			Frame = emu.read(wram_FrameCounter, emu.memType.snesMemory)
		end
	elseif BowserFrame then
		for k = 0, 8, 1 do
			if emu.read(wram_Enemy_Flag + k, emu.memType.snesMemory, 1) > 0 and emu.read(wram_Enemy_ID + k, emu.memType.snesMemory) == 0x2D
			and emu.read(wram_SprObject_X_Position + k + 1, emu.memType.snesMemory) ~= emu.read(wram_BowserOrigXPos, emu.memType.snesMemory)
			and emu.read(wram_FrameCounter, emu.memType.snesMemory) & 3 == 0 then
				if FrameDisplay == -1 then
					FrameDisplay = emu.read(wram_FrameCounter, emu.memType.snesMemory)
					Frame = emu.read(wram_FrameCounter, emu.memType.snesMemory)
				end
				BowserFrame = false
				break
			end
		end
	else
		FrameDisplay = -1
	end
	if emu.read(wram_GameEngineSubroutine, emu.memType.snesMemory) == 8 and emu.read(wram_Player_State, emu.memType.snesMemory) ~= 3
	and emu.read(wram_JumpspringAnimCtrl, emu.memType.snesMemory) == 0
	and emu.read(wram_A_B_Buttons, emu.memType.snesMemory) & 0x80 == 0x80 and PreviousA_B_Buttons & 0x80 == 0 then
		BowserFrame = false
		if FrameDisplay2 == -1 then
			FrameDisplay2 = emu.read(wram_FrameCounter, emu.memType.snesMemory)
			Frame = emu.read(wram_FrameCounter, emu.memType.snesMemory)
		end
	else
		FrameDisplay2 = -1
	end
	if emu.read(wram_JumpspringAnimCtrl, emu.memType.snesMemory) - 1 >= 1
	and emu.read(wram_A_B_Buttons, emu.memType.snesMemory) & 0x80 == 0x80 and PreviousA_B_Buttons & 0x80 == 0 then
		BowserFrame = false
		if FrameDisplay3 == -1 then
			FrameDisplay3 = emu.read(wram_FrameCounter, emu.memType.snesMemory)
			Frame = emu.read(wram_FrameCounter, emu.memType.snesMemory)
		end
	else
		FrameDisplay3 = -1
	end
	PreviousA_B_Buttons = emu.read(wram_A_B_Buttons, emu.memType.snesMemory)
	drawString(1, 24, string.format(" :%03d", Frame), text_colour, text_back_colour)
	if emu.read(0xB, emu.memType.snesCgRam) == 3 and emu.read(0xA, emu.memType.snesCgRam) == 0x5F then
		drawString(1, 24, "F", 0xFFD600, 0xFF000000)
	elseif emu.read(0xB, emu.memType.snesCgRam) == 3 and emu.read(0xA, emu.memType.snesCgRam) == 0xFF then
		drawString(1, 24, "F", 0xFFFF00, 0xFF000000)
	else
		drawString(1, 24, "F", 0xFFFFFF, 0xFF000000)
	end
	
	drawString(1, 32, string.format("A:%03d", emu.read(User_Var_A, emu.memType.snesMemory)), text_colour, text_back_colour)
	
	drawString(1, 40, string.format("B:%03d", emu.read(User_Var_B, emu.memType.snesMemory)), text_colour, text_back_colour)
	
	if emu.read(wram_WarpZoneControl, emu.memType.snesMemory) ~= 0 or emu.read(wram_OperMode, emu.memType.snesMemory) == 0 then
		WZ_or_Title_Remainder = true
	elseif emu.read(wram_ScreenRoutineTask, emu.memType.snesMemory) == 12 or emu.read(wram_ScreenRoutineTask, emu.memType.snesMemory) == 13 then
		WZ_or_Title_Remainder = false
	end
	if emu.read(wram_StarFlagTaskControl, emu.memType.snesMemory) >= 4
	or emu.read(wram_OperMode, emu.memType.snesMemory) == 2
	or emu.read(wram_GameEngineSubroutine, emu.memType.snesMemory) == 2
	or emu.read(wram_GameEngineSubroutine, emu.memType.snesMemory) == 3
	or emu.read(wram_ScreenRoutineTask, emu.memType.snesMemory) >= 7 and emu.read(wram_ScreenRoutineTask, emu.memType.snesMemory) <= 9
	and emu.read(wram_DisableScreenFlag, emu.memType.snesMemory) == 0 and WZ_or_Title_Remainder then
		if RemainderDisplay == -1 then
			Frame = emu.read(wram_FrameCounter, emu.memType.snesMemory)
			RemainderDisplay = emu.read(wram_IntervalTimerControl, emu.memType.snesMemory)
		end
		drawString(1, 48, string.format("R:%02d", RemainderDisplay), text_colour, text_back_colour)
	else
		RemainderDisplay = -1
	end
	if emu.read(wram_OperMode_Task, emu.memType.snesMemory) == 6 then
		if RemainderDisplay2 == -1 then
			Frame = emu.read(wram_FrameCounter, emu.memType.snesMemory)
			RemainderDisplay2 = emu.read(wram_IntervalTimerControl, emu.memType.snesMemory)
			RemainderDisplay = RemainderDisplay2
		end
	else
		RemainderDisplay2 = -1
	end
	
	--Predefined left-edge positions for each world and level
	local ScreenLeft = {
		{0xE6, 0xE7, 0x05},
		{0x10, 0xE7, 0x98},
		{0x08, 0x96, 0xF7},
		{0x98, 0xE7, 0xB6},
		{0xF6, 0x08, 0x05},
		{0x27, 0x07, 0xF6},
		{0xB6, 0xE7, 0x98},
		{0x07, 0x07, 0xE6}
	}
	
	--Compute relative X position of player
	local RelX = emu.read(wram_Player_Rel_XPos, emu.memType.snesMemory)
	local xpos = (RelX > 0x70) and (RelX - 0x70) or 0
	
	--Read current world and level
	local world = emu.read(wram_WorldNumber, emu.memType.snesMemory)
	local level = emu.read(wram_LevelNumber, emu.memType.snesMemory)
	
	--Check if we have a predefined screen left for this world and level
	if ScreenLeft[world + 1] and ScreenLeft[world + 1][level + 1]
	and not (emu.read(wram_GameEngineSubroutine, emu.memType.snesMemory) == 4 or emu.read(wram_GameEngineSubroutine, emu.memType.snesMemory) == 5) then
		local LeftEdge = ScreenLeft[world + 1][level + 1]
		local PowerupX = emu.read(wram_SprObject_X_Position + 10, emu.memType.snesMemory)
		
		--Compute 8-bit difference (wraps around 0–255 automatically)
		local diff = (PowerupX - (LeftEdge - xpos)) % 0x100
		
		--Backwards pole if difference >= 128 (0x80)
		BackwardsPole = diff >= 0x80
	end
	
	--Display the result
	emu.drawRectangle(0, 55, 50, 9, text_back_colour, text_back_colour)
	emu.drawString(1, 56, "Backwards", text_colour, 0xFF000000)
	emu.drawRectangle(0, 63, 50, 9, text_back_colour, text_back_colour)
	emu.drawString(1, 64, "Pole?: "..(BackwardsPole and "Yes" or "No"), text_colour, 0xFF000000)
end

local function hitbox(x1, y1, x2, y2) --Function to draw the hitboxes
	if emu.read(wram_FrameCounter, emu.memType.snesMemory) & 1 == 0 or not toggle_display_hitbox_collision_check then
		if y1 > y2 then --If collisions are being checked or don't show hitbox collision check, draw "on" colour
			emu.drawRectangle(x1, 7, x2 - x1 + 1, y2 + 1, hitbox_back_colour_on, 1, 1, 2)
			emu.drawRectangle(x1, 7, x2 - x1 + 1, y2 + 1, hitbox_edge_colour_on, 0, 1, 2)
		else
			emu.drawRectangle(x1, y1 + 7, x2 - x1 + 1, y2 - y1 + 1, hitbox_back_colour_on, 1, 1, 2)
			emu.drawRectangle(x1, y1 + 7, x2 - x1 + 1, y2 - y1 + 1, hitbox_edge_colour_on, 0, 1, 2)
		end
	else
		if y1 > y2 then --Otherwise, draw "off" colour
			emu.drawRectangle(x1, 7, x2 - x1 + 1, y2 + 1, hitbox_back_colour_off, 1, 1, 2)
			emu.drawRectangle(x1, 7, x2 - x1 + 1, y2 + 1, hitbox_edge_colour_off, 0, 1, 2)
		else
			emu.drawRectangle(x1, y1 + 7, x2 - x1 + 1, y2 - y1 + 1, hitbox_back_colour_off, 1, 1, 2)
			emu.drawRectangle(x1, y1 + 7, x2 - x1 + 1, y2 - y1 + 1, hitbox_edge_colour_off, 0, 1, 2)
		end
	end
end

function display_sprite_hitboxes()
	for i = 1, 10, 1 do --Draw enemy and power-up hitboxes
		if emu.read(wram_Enemy_Flag + i - 1, emu.memType.snesMemory) ~= 0 then
			hitbox(emu.read(wram_BoundingBox_UL_Corner + (i * 4), emu.memType.snesMemory), emu.read(wram_BoundingBox_UL_Corner + (i * 4 + 1), emu.memType.snesMemory), emu.read(wram_BoundingBox_UL_Corner + (i * 4 + 2), emu.memType.snesMemory), emu.read(wram_BoundingBox_UL_Corner + (i * 4 + 3), emu.memType.snesMemory))
		end
	end
	
	for i = 1, 2, 1 do --Draw fireball hitboxes
		if emu.read(wram_Fireball_State + i - 1, emu.memType.snesMemory) ~= 0 then
			hitbox(emu.read(wram_BoundingBox_UL_Corner + ((10 + i) * 4), emu.memType.snesMemory), emu.read(wram_BoundingBox_UL_Corner + ((10 + i) * 4 + 1), emu.memType.snesMemory), emu.read(wram_BoundingBox_UL_Corner + ((10 + i) * 4 + 2), emu.memType.snesMemory), emu.read(wram_BoundingBox_UL_Corner + ((10 + i) * 4 + 3), emu.memType.snesMemory))
		end
	end
	
	for i = 1, 9, 1 do --Draw hammer and coin hitboxes
		if emu.read(wram_Misc_State + i - 1, emu.memType.snesMemory) ~= 0 then
			hitbox(emu.read(wram_BoundingBox_UL_Corner + ((12 + i) * 4), emu.memType.snesMemory), emu.read(wram_BoundingBox_UL_Corner + ((12 + i) * 4 + 1), emu.memType.snesMemory), emu.read(wram_BoundingBox_UL_Corner + ((12 + i) * 4 + 2), emu.memType.snesMemory), emu.read(wram_BoundingBox_UL_Corner + ((12 + i) * 4 + 3), emu.memType.snesMemory))
		end
	end
end

function display_mario_hitbox()
	if emu.read(wram_GameEngineSubroutine, emu.memType.snesMemory) ~= 0 then --If Mario is alive, draw Mario's hitbox
		hitbox(emu.read(wram_BoundingBox_UL_Corner, emu.memType.snesMemory), emu.read(wram_BoundingBox_UL_Corner + 1, emu.memType.snesMemory), emu.read(wram_BoundingBox_UL_Corner + 2, emu.memType.snesMemory), emu.read(wram_BoundingBox_UL_Corner + 3, emu.memType.snesMemory))
	end
end

function display_sprite_slot_above_sprite()
	for i = 1, 10, 1 do
		if emu.read(wram_Enemy_Flag + i - 1, emu.memType.snesMemory) ~= 0 then
			emu.drawLine((emu.read(wram_SprObject_PageLoc + i, emu.memType.snesMemory) * 256 + emu.read(wram_SprObject_X_Position + i, emu.memType.snesMemory)) - (emu.read(wram_ScreenLeft_PageLoc, emu.memType.snesMemory) * 256 + emu.read(wram_ScreenLeft_X_Pos, emu.memType.snesMemory)) + 2, emu.read(wram_SprObject_Y_Position + i, emu.memType.snesMemory) - 2, (emu.read(wram_SprObject_PageLoc + i, emu.memType.snesMemory) * 256 + emu.read(wram_SprObject_X_Position + i, emu.memType.snesMemory)) - (emu.read(wram_ScreenLeft_PageLoc, emu.memType.snesMemory) * 256 + emu.read(wram_ScreenLeft_X_Pos, emu.memType.snesMemory)) + 2, emu.read(wram_SprObject_Y_Position + i, emu.memType.snesMemory) + 6, sprite_slot_back_colour, 1, 1)
			emu.drawString((emu.read(wram_SprObject_PageLoc + i, emu.memType.snesMemory) * 256 + emu.read(wram_SprObject_X_Position + i, emu.memType.snesMemory)) - (emu.read(wram_ScreenLeft_PageLoc, emu.memType.snesMemory) * 256 + emu.read(wram_ScreenLeft_X_Pos, emu.memType.snesMemory)) + 3, emu.read(wram_SprObject_Y_Position + i, emu.memType.snesMemory) - 1, string.format("[%d]", i - 1), sprite_slot_text_colour, sprite_slot_back_colour, 0, 1, 1) --draw the sprite slot above it
		end
	end
end

function display_spriteslots()
	local y_counter = 75 --for listing sprites and removing blank spriteslot's spaces
	for i = 1, 10, 1 do
		if emu.read(wram_Enemy_Flag + i - 1, emu.memType.snesMemory) ~= (toggle_display_sprite_information_after_death and -1 or 0) then --if the sprite isn't dead, unless ..._after_death is set
			if emu.read(wram_Enemy_Flag + i - 1, emu.memType.snesMemory) == 0 then --If dead, display faded text and background
				drawString(1, y_counter, string.format("%d:%02X", i - 1, emu.read(wram_Enemy_ID + i - 1, emu.memType.snesMemory)), text_faded_colour, text_faded_back_colour) --display sprite slot number and sprite ID
				drawString(24, y_counter, string.format("(%02X.%X, %02X.%02X)", emu.read(wram_SprObject_X_Position + i, emu.memType.snesMemory), emu.read(wram_SprObject_X_MoveForce + i, emu.memType.snesMemory) >> 4, emu.read(wram_SprObject_Y_Position + i, emu.memType.snesMemory), emu.read(wram_SprObject_YMF_Dummy + i, emu.memType.snesMemory)), text_faded_colour, text_faded_back_colour) --draw position
				y_counter = y_counter + 8 --add to y_counter so the next sprite is shown below the previous
			else --Otherwise, display fully-bright text and background
				drawString(1, y_counter, string.format("%d:%02X", i - 1, emu.read(wram_Enemy_ID + i - 1, emu.memType.snesMemory)), text_colour, text_back_colour) --display sprite slot number and sprite ID
				drawString(24, y_counter, string.format("(%02X.%X, %02X.%02X)", emu.read(wram_SprObject_X_Position + i, emu.memType.snesMemory), emu.read(wram_SprObject_X_MoveForce + i, emu.memType.snesMemory) >> 4, emu.read(wram_SprObject_Y_Position + i, emu.memType.snesMemory), emu.read(wram_SprObject_YMF_Dummy + i, emu.memType.snesMemory)), text_colour, text_back_colour) --draw position
				y_counter = y_counter + 8 --add to y_counter so the next sprite is shown below the previous
			end
		end
	end
end

function display_time()
	if region == "PAL" then --If playing a PAL game
		snes_framerate_numerator = 322445
		snes_framerate_denominator = 6448
	else
		snes_framerate_numerator = 39375000
		snes_framerate_denominator = 655171
	end
	
	if emu.read(0xFF4, emu.memType.snesMemory) & 0x10 == 0x10 then
		start_reached = true
	end
	if not start_reached then
		start_frame = emu.getState().frameCount + 103
	end
	
	local all_match_end = true
	
	for _, row in ipairs(timer_end) do
		if emu.read(row[1], emu.memType.snesMemory) ~= row[2] then
			all_match_end = false
			break
		end
	end
	
	if all_match_end and not end_reached then
		end_frame = emu.getState().frameCount + 1
		end_reached = true
	end
	
	if #timer_reset > 0 then
		local all_match_reset = true
		
		for _, row in ipairs(timer_reset) do
			if emu.read(row[1], emu.memType.snesMemory) ~= row[2] then
				all_match_reset = false
				break
			end
		end
		
		if all_match_reset then
			start_frame = emu.getState().frameCount + 103
			start_reached = false
			end_frame = -1
			end_reached = false
		end
	end
	
	if start_frame < 0 then
		frames = 0
	else
		if end_frame < 0 then --If end frame has not been reached, keep running the timer
			frames = round(1 / (snes_framerate_numerator / snes_framerate_denominator) * snes_framerate_numerator * math.abs(emu.getState().frameCount - start_frame) / (snes_framerate_numerator / 1000)) / 1000 --current frames in movie
		else --Otherwise, stop the timer
			if emu.getState().frameCount <= end_frame then
				frames = round(1 / (snes_framerate_numerator / snes_framerate_denominator) * snes_framerate_numerator * math.abs(emu.getState().frameCount - start_frame) / (snes_framerate_numerator / 1000)) / 1000 --current frames in movie
			else
				frames = round(1 / (snes_framerate_numerator / snes_framerate_denominator) * snes_framerate_numerator * (end_frame - start_frame) / (snes_framerate_numerator / 1000)) / 1000 --end frame in movie
			end
		end
	end
	
	hours = math.floor(frames / 3600)
	minutes = math.floor((frames / 60) % 60)
	seconds = math.floor(frames % 60)
	milliseconds = math.floor((frames * 1000) % 1000)
	
	if emu.getState().frameCount - start_frame < 0 then --draw it
		drawString(188, 223, string.format("-%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds), text_colour, text_back_colour)
	else
		drawString(193, 223, string.format("%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds), text_colour, text_back_colour)
	end
end

function round(n)
	return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

function display_information()
	local y_counter = 8
	
	if toggle_display_21_framerule then
		if emu.read(wram_IntervalTimerControl, emu.memType.snesMemory) < 10 then --Done to make the display look nice
			drawString(173, y_counter, string.format("21 Framerule:  %d", emu.read(wram_IntervalTimerControl, emu.memType.snesMemory)), text_colour, text_back_colour)
		else
			drawString(173, y_counter, string.format("21 Framerule: %d", emu.read(wram_IntervalTimerControl, emu.memType.snesMemory)), text_colour, text_back_colour)
		end
	end
	
	y_counter = 158
	
	--display mario information
	if toggle_display_mario_position or toggle_display_mario_velocity or toggle_display_mario_acceleration or toggle_display_state then
		drawString(1, y_counter, "Mario:", text_colour, text_back_colour)
		y_counter = y_counter + 8
	end
	
	if toggle_display_mario_position then
		drawString(1, y_counter, string.format("Pos: (%02X.%X, %02X.%02X)", emu.read(wram_SprObject_X_Position, emu.memType.snesMemory), emu.read(wram_SprObject_X_MoveForce, emu.memType.snesMemory) >> 4, emu.read(wram_SprObject_Y_Position, emu.memType.snesMemory), emu.read(wram_SprObject_YMF_Dummy, emu.memType.snesMemory)), text_colour, text_back_colour)
		y_counter = y_counter + 8
	end
	
	if toggle_display_mario_velocity then --Display X Speed, the CORRECT X SubSpeed value, Y Speed, and the CORRECT Y SubSpeed value
		--How this essentially works:
		--• If X Speed is positive, display the normal X SubSpeed value. Otherwise, display the two's complement of the X SubSpeed value.
		--• If Y Speed is positive, display the normal Y SubSpeed value. Otherwise, display the two's complement of the Y SubSpeed value.
		if emu.read(wram_Player_X_Speed, emu.memType.snesMemory, 1) > -1 and emu.read(wram_Player_Y_Speed, emu.memType.snesMemory, 1) > -1 then
			drawString(1, y_counter, string.format("Speed: (%d.%02X, %d.%02X)", emu.read(wram_Player_X_Speed, emu.memType.snesMemory), emu.read(wram_Player_X_MoveForce, emu.memType.snesMemory), emu.read(wram_Player_Y_Speed, emu.memType.snesMemory), emu.read(wram_Player_Y_MoveForce, emu.memType.snesMemory)), text_colour, text_back_colour)
		elseif emu.read(wram_Player_X_Speed, emu.memType.snesMemory, 1) > -1 and emu.read(wram_Player_Y_Speed, emu.memType.snesMemory, 1) < 0 then
			drawString(1, y_counter, string.format("Speed: (%d.%02X, %d.%02X)", emu.read(wram_Player_X_Speed, emu.memType.snesMemory), emu.read(wram_Player_X_MoveForce, emu.memType.snesMemory), emu.read(wram_Player_Y_Speed, emu.memType.snesMemory, 1), (256 - emu.read(wram_Player_Y_MoveForce, emu.memType.snesMemory)) & 0xFF), text_colour, text_back_colour)
		elseif emu.read(wram_Player_X_Speed, emu.memType.snesMemory, 1) < 0 and emu.read(wram_Player_Y_Speed, emu.memType.snesMemory, 1) > -1 then
			drawString(1, y_counter, string.format("Speed: (%d.%02X, %d.%02X)", emu.read(wram_Player_X_Speed, emu.memType.snesMemory, 1), (256 - emu.read(wram_Player_X_MoveForce, emu.memType.snesMemory)) & 0xFF, emu.read(wram_Player_Y_Speed, emu.memType.snesMemory), emu.read(wram_Player_Y_MoveForce, emu.memType.snesMemory)), text_colour, text_back_colour)
		else
			drawString(1, y_counter, string.format("Speed: (%d.%02X, %d.%02X)", emu.read(wram_Player_X_Speed, emu.memType.snesMemory, 1), (256 - emu.read(wram_Player_X_MoveForce, emu.memType.snesMemory)) & 0xFF, emu.read(wram_Player_Y_Speed, emu.memType.snesMemory, 1), (256 - emu.read(wram_Player_Y_MoveForce, emu.memType.snesMemory)) & 0xFF), text_colour, text_back_colour)
		end
		y_counter = y_counter + 8
	end
	
	if toggle_display_mario_acceleration then
		drawString(1, y_counter, string.format("Acceleration: (%d.%02X, 0.%02X)", emu.read(wram_FrictionAdderLow - 1, emu.memType.snesMemory), emu.read(wram_FrictionAdderLow, emu.memType.snesMemory), emu.read(wram_VerticalForce, emu.memType.snesMemory)), text_colour, text_back_colour) --Display acceleration
		y_counter = y_counter + 8
	end
	
	if toggle_display_state then
		drawString(1, y_counter, string.format("State?: %d", emu.read(wram_Player_State, emu.memType.snesMemory)), text_colour, text_back_colour)
	end
end

function calculations()
	if toggle_display_practice_information then
		display_practice_information()
	end
	
	if toggle_display_sprite_hitboxes then
		display_sprite_hitboxes()
	end
	
	if toggle_display_mario_hitbox then
		display_mario_hitbox()
	end
	
	if toggle_display_sprite_slot_above_sprite then
		display_sprite_slot_above_sprite()
	end
	
	if toggle_display_sprite_information then
		display_spriteslots()
	end
	
	if toggle_display_time then
		display_time()
	end
	display_information()
end

emu.addEventCallback(calculations, emu.eventType.endFrame)