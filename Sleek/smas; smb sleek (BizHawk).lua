--Thank you to @Simplistic for helping me fix the Frame counter display and for helping me with the X subpixel string
--Note: the "BP?" ("Backwards Pole?") feature isn't entirely accurate, but it's like 95% accurate

--Before running the script, you MUST set this variable to the region you're playing on — NTSC or PAL — in order for the timer to use
--the right framerate. If you set this variable to a non-valid value, this will make the timer default to you not playing on PAL.
local region = "NTSC" --Valid inputs: '"NTSC"' and '"PAL"'

--toggle features, change to false if you don't want them
local toggle_display_above_status_bar_information   = true
local toggle_display_sprite_hitboxes                = true
local toggle_display_mario_hitbox                   = true
local toggle_display_hitbox_collision_check         = false
local toggle_display_sprite_slot_above_sprite       = true
local toggle_display_sprite_information             = true
local toggle_display_sprite_information_after_death = false
local toggle_display_time                           = true

--variables
local text_colour             = "white"
local text_faded_colour       = "#80FFFFFF"
local text_back_colour        = "#66000000"
local text_faded_back_colour  = "#33000000"
local hitbox_edge_colour_on   = "#00FF00" --Hitbox back and edge colour for when collisions are being checked (always used when not showing hitbox collision check)
local hitbox_back_colour_on   = "#8000FF00"
local hitbox_edge_colour_off  = "#00FF00" --Hitbox back and edge colour for when collisions are not being checked
local hitbox_back_colour_off  = "clear"
local sprite_slot_text_colour = "white"
local sprite_slot_back_colour = "#66000000"

--Timer settings:
local negative_delay = true --'true' for negative delay, 'false' for the timer to say "00:00:00.000" until timing starts
local start_frame    = 0 --0 for TAS timing
local end_frame      = -1 --Set to -1 for no end frame

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

function display_practice_information() --Code to display practice information
	if memory.readbyte(wram_Player_X_Speed) < 0x19 or memory.readbyte(wram_Player_X_Speed) > 0xE7 then
		y = 24
	else
		y = 40
	end
	local xstringvalue = (((memory.readbyte(wram_SprObject_PageLoc) << 12)
		+ (memory.readbyte(wram_SprObject_X_Position) << 4)
		+ (memory.readbyte(wram_SprObject_X_MoveForce) >> 4)) % y) >> 3
	local sockvalue = (memory.readbyte(wram_SprObject_X_Position) << 8)
		+ memory.readbyte(wram_SprObject_X_MoveForce)
		+ ((0xFF - memory.readbyte(wram_SprObject_Y_Position) >> 2) * 0x280)
	if memory.readbyte(wram_IntervalTimerControl) & 3 == 3 then
		xstringactual = xstringvalue
	end
	if memory.readbyte(wram_IntervalTimerControl) & 3 == 2 then
		xstring = xstringactual
		sock = sockvalue & 0xFFF
		ypos = memory.readbyte(wram_SprObject_Y_Position) & 3
		DontDisplaySock = false
	end
	if memory.readbyte(wram_DisableScreenFlag) ~= 0 or memory.readbyte(wram_GameEngineSubroutine) == 0
	or memory.readbyte(wram_ScreenRoutineTask) >= 7 and memory.readbyte(wram_ScreenRoutineTask) <= 9
	or memory.readbyte(wram_AltEntranceControl) == 2 then
		DontDisplaySock = true
	end
	gui.drawBox(0, 7, 43, 15, text_back_colour, text_back_colour)
	gui.pixelText(-1, 7, "S", text_colour, "clear", "fceux")
	gui.pixelText(4, 7, ":", text_colour, "clear", "fceux")
	if not DontDisplaySock then
		gui.pixelText(8, 7, string.format("%d%03X", xstring, sock), text_colour, "clear", "fceux")
		gui.drawLine(33, 11, 36, 11, text_colour)
		gui.pixelText(37, 7, ypos, text_colour, "clear", "fceux")
	end
	
	if memory.readbyte(wram_ScreenRoutineTask) == 4 then
		local chars = "0123456789ABCDEFGHIJK"
		Frame = memory.readbyte(wram_FrameCounter)
		ScreenEnterDisplay = string.sub(chars, memory.readbyte(wram_IntervalTimerControl) + 1, memory.readbyte(wram_IntervalTimerControl) + 1)
	end
	gui.drawBox(32, 0, 43, 7, text_back_colour, text_back_colour)
	gui.drawLine(33, 3, 36, 3, text_colour)
	gui.pixelText(37, -1, string.format("%s", ScreenEnterDisplay), text_colour, "clear", "fceux")
	
	for i = 0, 8, 1 do
		if memory.read_s8(wram_Enemy_Flag + i) > 0 and memory.readbyte(wram_Enemy_ID + i) == 0x2D
		and memory.readbyte(wram_SprObject_X_Position + i + 1) == memory.readbyte(wram_BowserOrigXPos) then
			BowserFrame = true
			break
		end
	end
	local EnemyFrame = false
	for j = 0, 9, 1 do
		if memory.readbyte(wram_FloateyNum_Timer + j) == 0x2A then
			EnemyFrame = true
			break
		end
	end
	if (memory.readbyte(wram_OperMode) == 0 and memory.readbyte(wram_FrameCounter) & 1 == 0)
	or memory.readbyte(wram_GameEngineSubroutine) == 7
	or memory.readbyte(wram_JumpSwimTimer) == 0x20 or EnemyFrame or memory.readbyte(wram_Sample7SoundQueue) == 6
	or (memory.readbyte(wram_Player_State) == 3 and (memory.readbyte(wram_GameEngineSubroutine) == 4
	or memory.readbyte(wram_GameEngineSubroutine) == 5 and memory.readbyte(wram_SprObject_Y_Position) >= 0xA2))
	or memory.readbyte(wram_StarFlagTaskControl) == 2 then
		BowserFrame = false
		if FrameDisplay == -1 then
			FrameDisplay = memory.readbyte(wram_FrameCounter)
			Frame = memory.readbyte(wram_FrameCounter)
		end
	elseif BowserFrame then
		for k = 0, 8, 1 do
			if memory.read_s8(wram_Enemy_Flag + k) > 0 and memory.readbyte(wram_Enemy_ID + k) == 0x2D
			and memory.readbyte(wram_SprObject_X_Position + k + 1) ~= memory.readbyte(wram_BowserOrigXPos)
			and memory.readbyte(wram_FrameCounter) & 3 == 0 then
				if FrameDisplay == -1 then
					FrameDisplay = memory.readbyte(wram_FrameCounter)
					Frame = memory.readbyte(wram_FrameCounter)
				end
				BowserFrame = false
				break
			end
		end
	else
		FrameDisplay = -1
	end
	if memory.readbyte(wram_GameEngineSubroutine) == 8 and memory.readbyte(wram_Player_State) ~= 3
	and memory.readbyte(wram_JumpspringAnimCtrl) == 0
	and memory.readbyte(wram_A_B_Buttons) & 0x80 == 0x80 and PreviousA_B_Buttons & 0x80 == 0 then
		BowserFrame = false
		if FrameDisplay2 == -1 then
			FrameDisplay2 = memory.readbyte(wram_FrameCounter)
			Frame = memory.readbyte(wram_FrameCounter)
		end
	else
		FrameDisplay2 = -1
	end
	if memory.readbyte(wram_JumpspringAnimCtrl) - 1 >= 1
	and memory.readbyte(wram_A_B_Buttons) & 0x80 == 0x80 and PreviousA_B_Buttons & 0x80 == 0 then
		BowserFrame = false
		if FrameDisplay3 == -1 then
			FrameDisplay3 = memory.readbyte(wram_FrameCounter)
			Frame = memory.readbyte(wram_FrameCounter)
		end
	else
		FrameDisplay3 = -1
	end
	PreviousA_B_Buttons = memory.readbyte(wram_A_B_Buttons)
	gui.drawBox(0, 15, 26, 23, text_back_colour, text_back_colour)
	memory.usememorydomain("CGRAM")
	if memory.readbyte(0xB) == 3 and memory.readbyte(0xA) == 0x5F then
		gui.pixelText(-1, 15, "F", "#FFD600", "clear", "fceux")
	elseif memory.readbyte(0xB) == 3 and memory.readbyte(0xA) == 0xFF then
		gui.pixelText(-1, 15, "F", "#FFFF00", "clear", "fceux")
	else
		gui.pixelText(-1, 15, "F", "#FFFFFF", "clear", "fceux")
	end
	gui.pixelText(4, 15, ":", text_colour, "clear", "fceux")
	gui.pixelText(8, 15, string.format("%03d", Frame), text_colour, "clear", "fceux")
	memory.usememorydomain("System Bus")
	
	gui.drawBox(50, 0, 77, 7, text_back_colour, text_back_colour)
	gui.pixelText(50, -1, "A", text_colour, "clear", "fceux")
	gui.pixelText(55, -1, ":", text_colour, "clear", "fceux")
	gui.pixelText(59, -1, string.format("%03d", memory.readbyte(User_Var_A)), text_colour, "clear", "fceux")
	
	gui.drawBox(50, 7, 77, 15, text_back_colour, text_back_colour)
	gui.pixelText(50, 7, "B", text_colour, "clear", "fceux")
	gui.pixelText(55, 7, ":", text_colour, "clear", "fceux")
	gui.pixelText(59, 7, string.format("%03d", memory.readbyte(User_Var_B)), text_colour, "clear", "fceux")
	
	if memory.readbyte(wram_WarpZoneControl) ~= 0 or memory.readbyte(wram_OperMode) == 0 then
		WZ_or_Title_Remainder = true
	elseif memory.readbyte(wram_ScreenRoutineTask) == 12 or memory.readbyte(wram_ScreenRoutineTask) == 13 then
		WZ_or_Title_Remainder = false
	end
	if memory.readbyte(wram_StarFlagTaskControl) >= 4
	or memory.readbyte(wram_OperMode) == 2
	or memory.readbyte(wram_GameEngineSubroutine) == 2
	or memory.readbyte(wram_GameEngineSubroutine) == 3
	or memory.readbyte(wram_ScreenRoutineTask) >= 7 and memory.readbyte(wram_ScreenRoutineTask) <= 9
	and memory.readbyte(wram_DisableScreenFlag) == 0 and WZ_or_Title_Remainder then
		if RemainderDisplay == -1 then
			Frame = memory.readbyte(wram_FrameCounter)
			RemainderDisplay = memory.readbyte(wram_IntervalTimerControl)
		end
		gui.drawBox(50, 15, 71, 23, text_back_colour, text_back_colour)
		gui.pixelText(50, 15, "R", text_colour, "clear", "fceux")
		gui.pixelText(55, 15, ":", text_colour, "clear", "fceux")
		gui.pixelText(59, 15, string.format("%02d", RemainderDisplay), text_colour, "clear", "fceux")
	else
		RemainderDisplay = -1
	end
	if memory.readbyte(wram_OperMode_Task) == 6 then
		if RemainderDisplay2 == -1 then
			Frame = memory.readbyte(wram_FrameCounter)
			RemainderDisplay2 = memory.readbyte(wram_IntervalTimerControl)
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
	local RelX = memory.readbyte(wram_Player_Rel_XPos)
	local xpos = (RelX > 0x70) and (RelX - 0x70) or 0
	
	--Read current world and level
	local world = memory.readbyte(wram_WorldNumber)
	local level = memory.readbyte(wram_LevelNumber)
	
	--Check if we have a predefined screen left for this world and level
	if ScreenLeft[world + 1] and ScreenLeft[world + 1][level + 1]
	and not (memory.readbyte(wram_GameEngineSubroutine) == 4 or memory.readbyte(wram_GameEngineSubroutine) == 5) then
		local LeftEdge = ScreenLeft[world + 1][level + 1]
		local PowerupX = memory.readbyte(wram_SprObject_X_Position + 10)
		
		--Compute 8-bit difference (wraps around 0–255 automatically)
		local diff = (PowerupX - (LeftEdge - xpos)) % 0x100
		
		--Backwards pole if difference >= 128 (0x80)
		BackwardsPole = diff >= 0x80
	end
	
	--Display the result
	gui.drawBox(0, 23, 26, 31, text_back_colour, text_back_colour)
	gui.pixelText(-1, 23, "BP?", text_colour, "clear", "fceux")
	gui.pixelText(16, 23, ":", text_colour, "clear", "fceux")
	gui.pixelText(20, 23, BackwardsPole and "Y" or "N", text_colour, "clear", "fceux")
end

local function hitbox(x1, y1, x2, y2) --Function to draw the hitboxes
	if memory.readbyte(wram_FrameCounter) & 1 == 0 or not toggle_display_hitbox_collision_check then
		if y1 > y2 then --If collisions are being checked or don't show hitbox collision check, draw "on" colour
			gui.drawBox(x1, 0, x2, y2, hitbox_edge_colour_on, hitbox_back_colour_on)
		else
			gui.drawBox(x1, y1, x2, y2, hitbox_edge_colour_on, hitbox_back_colour_on)
		end
	else
		if y1 > y2 then --Otherwise, draw "off" colour
			gui.drawBox(x1, 0, x2, y2, hitbox_edge_colour_off, hitbox_back_colour_off)
		else
			gui.drawBox(x1, y1, x2, y2, hitbox_edge_colour_off, hitbox_back_colour_off)
		end
	end
end

function display_sprite_hitboxes()
	for i = 1, 10, 1 do --Draw enemy and power-up hitboxes
		if memory.readbyte(wram_Enemy_Flag + i - 1) ~= 0 then
			hitbox(memory.readbyte(wram_BoundingBox_UL_Corner + (i * 4)), memory.readbyte(wram_BoundingBox_UL_Corner + (i * 4 + 1)), memory.readbyte(wram_BoundingBox_UL_Corner + (i * 4 + 2)), memory.readbyte(wram_BoundingBox_UL_Corner + (i * 4 + 3)))
		end
	end
	
	for i = 1, 2, 1 do --Draw fireball hitboxes
		if memory.readbyte(wram_Fireball_State + i - 1) ~= 0 then
			hitbox(memory.readbyte(wram_BoundingBox_UL_Corner + ((10 + i) * 4)), memory.readbyte(wram_BoundingBox_UL_Corner + ((10 + i) * 4 + 1)), memory.readbyte(wram_BoundingBox_UL_Corner + ((10 + i) * 4 + 2)), memory.readbyte(wram_BoundingBox_UL_Corner + ((10 + i) * 4 + 3)))
		end
	end
	
	for i = 1, 9, 1 do --Draw hammer and coin hitboxes
		if memory.readbyte(wram_Misc_State + i - 1) ~= 0 then
			hitbox(memory.readbyte(wram_BoundingBox_UL_Corner + ((12 + i) * 4)), memory.readbyte(wram_BoundingBox_UL_Corner + ((12 + i) * 4 + 1)), memory.readbyte(wram_BoundingBox_UL_Corner + ((12 + i) * 4 + 2)), memory.readbyte(wram_BoundingBox_UL_Corner + ((12 + i) * 4 + 3)))
		end
	end
end

function display_mario_hitbox()
	if memory.readbyte(wram_GameEngineSubroutine) ~= 0 then --If Mario is alive, draw Mario's hitbox
		hitbox(memory.readbyte(wram_BoundingBox_UL_Corner), memory.readbyte(wram_BoundingBox_UL_Corner + 1), memory.readbyte(wram_BoundingBox_UL_Corner + 2), memory.readbyte(wram_BoundingBox_UL_Corner + 3))
	end
end

function display_sprite_slot_above_sprite()
	for i = 1, 10, 1 do
		if memory.readbyte(wram_Enemy_Flag + i - 1) ~= 0 then
			gui.pixelText((memory.readbyte(wram_SprObject_PageLoc + i) * 256 + memory.readbyte(wram_SprObject_X_Position + i)) - (memory.readbyte(wram_ScreenLeft_PageLoc) * 256 + memory.readbyte(wram_ScreenLeft_X_Pos)) + 2, memory.readbyte(wram_SprObject_Y_Position + i) - 2, string.format("[%d]", i - 1), sprite_slot_text_colour, sprite_slot_back_colour, "fceux") --draw the sprite slot above it
		end
	end
end

function display_spriteslots()
	local y_counter = 31 --for listing sprites and removing blank spriteslot's spaces
	for i = 1, 10, 1 do
		if memory.readbyte(wram_Enemy_Flag + i - 1) ~= (toggle_display_sprite_information_after_death and -1 or 0) then --if the sprite isn't dead, unless ..._after_death is set
			if memory.readbyte(wram_Enemy_Flag + i - 1) == 0 then --If dead, display faded text and background
				gui.pixelText(-1, y_counter, string.format("%d:%02X", i - 1, memory.readbyte(wram_Enemy_ID + i - 1)), text_faded_colour, text_faded_back_colour, "fceux") --display sprite slot number and sprite ID
				gui.pixelText(25, y_counter, string.format("(%02X.%X, %02X.%02X)", memory.readbyte(wram_SprObject_X_Position + i), memory.readbyte(wram_SprObject_X_MoveForce + i) >> 4, memory.readbyte(wram_SprObject_Y_Position + i), memory.readbyte(wram_SprObject_YMF_Dummy + i)), text_faded_colour, text_faded_back_colour, "fceux") --draw position
				y_counter = y_counter + 8 --add to y_counter so the next sprite is shown below the previous
			else --Otherwise, display fully-bright text and background
				gui.pixelText(-1, y_counter, string.format("%d:%02X", i - 1, memory.readbyte(wram_Enemy_ID + i - 1)), text_colour, text_back_colour, "fceux") --display sprite slot number and sprite ID
				gui.pixelText(25, y_counter, string.format("(%02X.%X, %02X.%02X)", memory.readbyte(wram_SprObject_X_Position + i), memory.readbyte(wram_SprObject_X_MoveForce + i) >> 4, memory.readbyte(wram_SprObject_Y_Position + i), memory.readbyte(wram_SprObject_YMF_Dummy + i)), text_colour, text_back_colour, "fceux") --draw position
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
	
	if end_frame < 0 then --If there is no end frame, update the timer forever
		frames = round(1 / (snes_framerate_numerator / snes_framerate_denominator) * snes_framerate_numerator * math.abs(emu.framecount() - start_frame) / (snes_framerate_numerator / 1000)) / 1000 --current frames in movie
	else --If there is an end frame, stop updating the timer when end frame has been reached
		if emu.framecount() <= end_frame then
			frames = round(1 / (snes_framerate_numerator / snes_framerate_denominator) * snes_framerate_numerator * math.abs(emu.framecount() - start_frame) / (snes_framerate_numerator / 1000)) / 1000 --current frames in movie
		else
			frames = round(1 / (snes_framerate_numerator / snes_framerate_denominator) * snes_framerate_numerator * (end_frame - start_frame) / (snes_framerate_numerator / 1000)) / 1000 --end frame in movie
		end
	end
	
	hours = math.floor(frames / 3600)
	minutes = math.floor((frames / 60) % 60)
	seconds = math.floor(frames % 60)
	milliseconds = math.floor((frames * 1000) % 1000)
	
	if negative_delay then --If negative delay, show negative time before timing starts
		if emu.framecount() - start_frame < 0 then
			gui.pixelText(177, 215, string.format("-%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds), text_colour, text_back_colour, "fceux") --draw it
		else
			gui.pixelText(183, 215, string.format("%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds), text_colour, text_back_colour, "fceux") --draw it
		end
	else --Otherwise, show 0 hours, 0 minutes, 0 seconds, and 0 milliseconds until timing starts
		if emu.framecount() - start_frame < 0 then
			gui.pixelText(183, 215, "00:00:00.000", text_colour, text_back_colour, "fceux") --draw 0 hours, 0 minutes, 0 seconds, and 0 milliseconds
		else
			gui.pixelText(183, 215, string.format("%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds), text_colour, text_back_colour, "fceux") --draw it
		end
	end
end

function round(n)
	return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

function display_information()
	gui.drawBox(229, 0, 255, 7, text_back_colour, text_back_colour)
	gui.pixelText(229, -1, "FR", text_colour, "clear", "fceux")
	gui.pixelText(240, -1, ":", text_colour, "clear", "fceux")
	if memory.readbyte(wram_IntervalTimerControl) < 10 then --Done to make the display look nice
		gui.pixelText(250, -1, string.format("%d", memory.readbyte(wram_IntervalTimerControl)), text_colour, "clear", "fceux")
	else
		gui.pixelText(244, -1, string.format("%d", memory.readbyte(wram_IntervalTimerControl)), text_colour, "clear", "fceux")
	end
	
	--display mario information
	gui.drawBox(84, 0, 120, 7, text_back_colour, text_back_colour)
	gui.pixelText(84, -1, "XP", text_colour, "clear", "fceux")
	gui.pixelText(95, -1, ":", text_colour, "clear", "fceux")
	gui.pixelText(99, -1, string.format("%02X", memory.readbyte(wram_SprObject_X_Position)), text_colour, "clear", "fceux")
	gui.pixelText(110, -1, ".", text_colour, "clear", "fceux")
	gui.pixelText(114, -1, string.format("%X", memory.readbyte(wram_SprObject_X_MoveForce) >> 4), text_colour, "clear", "fceux")
	gui.drawBox(84, 7, 126, 15, text_back_colour, text_back_colour)
	gui.pixelText(84, 7, "YP", text_colour, "clear", "fceux")
	gui.pixelText(95, 7, ":", text_colour, "clear", "fceux")
	gui.pixelText(99, 7, string.format("%02X", memory.readbyte(wram_SprObject_Y_Position)), text_colour, "clear", "fceux")
	gui.pixelText(110, 7, ".", text_colour, "clear", "fceux")
	gui.pixelText(114, 7, string.format("%02X", memory.readbyte(wram_SprObject_YMF_Dummy)), text_colour, "clear", "fceux")
	
	--Display X Speed, the CORRECT X SubSpeed value, Y Speed, and the CORRECT Y SubSpeed value
	--How this essentially works:
	--• If X Speed is positive, display the normal X SubSpeed value. Otherwise, display the two's complement of the X SubSpeed value.
	--• If Y Speed is positive, display the normal Y SubSpeed value. Otherwise, display the two's complement of the Y SubSpeed value.
	if memory.read_s8(wram_Player_X_Speed) > -1 then
		if memory.readbyte(wram_Player_X_Speed) < 10 then
			gui.drawBox(132, 0, 168, 7, text_back_colour, text_back_colour)
			gui.pixelText(152, -1, ".", text_colour, "clear", "fceux")
			gui.pixelText(156, -1, string.format("%02X", memory.readbyte(wram_Player_X_MoveForce)), text_colour, "clear", "fceux")
		else
			gui.drawBox(132, 0, 174, 7, text_back_colour, text_back_colour)
			gui.pixelText(158, -1, ".", text_colour, "clear", "fceux")
			gui.pixelText(162, -1, string.format("%02X", memory.readbyte(wram_Player_X_MoveForce)), text_colour, "clear", "fceux")
		end
		gui.pixelText(147, -1, string.format("%d", memory.readbyte(wram_Player_X_Speed)), text_colour, "clear", "fceux")
	else
		if memory.read_s8(wram_Player_X_Speed) > -10 then
			gui.drawBox(132, 0, 173, 7, text_back_colour, text_back_colour)
			gui.pixelText(157, -1, ".", text_colour, "clear", "fceux")
			gui.pixelText(161, -1, string.format("%02X", (256 - memory.readbyte(wram_Player_X_MoveForce)) & 0xFF), text_colour, "clear", "fceux")
		else
			gui.drawBox(132, 0, 179, 7, text_back_colour, text_back_colour)
			gui.pixelText(163, -1, ".", text_colour, "clear", "fceux")
			gui.pixelText(167, -1, string.format("%02X", (256 - memory.readbyte(wram_Player_X_MoveForce)) & 0xFF), text_colour, "clear", "fceux")
		end
		gui.drawLine(148, 3, 151, 3, text_colour)
		gui.pixelText(152, -1, string.format("%d", memory.read_s8(wram_Player_X_Speed) * -1), text_colour, "clear", "fceux")
	end
	gui.pixelText(132, -1, "XS", text_colour, "clear", "fceux")
	gui.pixelText(143, -1, ":", text_colour, "clear", "fceux")
	if memory.read_s8(wram_Player_Y_Speed) > -1 then
		if memory.readbyte(wram_Player_Y_Speed) < 10 then
			gui.drawBox(132, 7, 168, 15, text_back_colour, text_back_colour)
			gui.pixelText(152, 7, ".", text_colour, "clear", "fceux")
			gui.pixelText(156, 7, string.format("%02X", memory.readbyte(wram_Player_Y_MoveForce)), text_colour, "clear", "fceux")
		else
			gui.drawBox(132, 7, 174, 15, text_back_colour, text_back_colour)
			gui.pixelText(158, 7, ".", text_colour, "clear", "fceux")
			gui.pixelText(162, 7, string.format("%02X", memory.readbyte(wram_Player_Y_MoveForce)), text_colour, "clear", "fceux")
		end
		gui.pixelText(147, 7, string.format("%d", memory.readbyte(wram_Player_Y_Speed)), text_colour, "clear", "fceux")
	else
		if memory.read_s8(wram_Player_Y_Speed) > -10 then
			gui.drawBox(132, 7, 173, 15, text_back_colour, text_back_colour)
			gui.pixelText(157, 7, ".", text_colour, "clear", "fceux")
			gui.pixelText(161, 7, string.format("%02X", (256 - memory.readbyte(wram_Player_Y_MoveForce)) & 0xFF), text_colour, "clear", "fceux")
		else
			gui.drawBox(132, 7, 179, 15, text_back_colour, text_back_colour)
			gui.pixelText(163, 7, ".", text_colour, "clear", "fceux")
			gui.pixelText(167, 7, string.format("%02X", (256 - memory.readbyte(wram_Player_Y_MoveForce)) & 0xFF), text_colour, "clear", "fceux")
		end
		gui.drawLine(148, 11, 151, 11, text_colour)
		gui.pixelText(152, 7, string.format("%d", memory.read_s8(wram_Player_Y_Speed) * -1), text_colour, "clear", "fceux")
	end
	gui.pixelText(132, 7, "YS", text_colour, "clear", "fceux")
	gui.pixelText(143, 7, ":", text_colour, "clear", "fceux")
	
	gui.drawBox(186, 0, 222, 7, text_back_colour, text_back_colour) --Display X acceleration
	gui.pixelText(186, -1, "XA", text_colour, "clear", "fceux")
	gui.pixelText(197, -1, ":", text_colour, "clear", "fceux")
	gui.pixelText(201, -1, string.format("%d", memory.readbyte(wram_FrictionAdderLow - 1)), text_colour, "clear", "fceux")
	gui.pixelText(206, -1, ".", text_colour, "clear", "fceux")
	gui.pixelText(210, -1, string.format("%02X", memory.readbyte(wram_FrictionAdderLow)), text_colour, "clear", "fceux")
	gui.drawBox(186, 7, 222, 15, text_back_colour, text_back_colour) --Display Y acceleration
	gui.pixelText(186, 7, "YA", text_colour, "clear", "fceux")
	gui.pixelText(197, 7, ":", text_colour, "clear", "fceux")
	gui.pixelText(201, 7, "0", text_colour, "clear", "fceux")
	gui.pixelText(206, 7, ".", text_colour, "clear", "fceux")
	gui.pixelText(210, 7, string.format("%02X", memory.readbyte(wram_VerticalForce)), text_colour, "clear", "fceux")
	
	gui.drawBox(229, 7, 255, 15, text_back_colour, text_back_colour)
	gui.pixelText(229, 7, "ST?", text_colour, "clear", "fceux")
	gui.pixelText(246, 7, ":", text_colour, "clear", "fceux")
	gui.pixelText(250, 7, string.format("%d", memory.readbyte(wram_Player_State)), text_colour, "clear", "fceux")
end

while true do
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
	
	if toggle_display_above_status_bar_information then
		display_practice_information()
		display_information()
	end
	
	if toggle_display_time then
		display_time()
	end
	emu.frameadvance()
end