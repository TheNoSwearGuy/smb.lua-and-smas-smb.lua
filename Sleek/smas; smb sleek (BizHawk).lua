--This lua script is supposed to be identical to the smb3.lua script (https://github.com/fortenbt/smb3-lua) but for SMAS: SMB, for BizHawk, and a sleek version
--Thank you to @Simplistic for helping me fix the Frame counter display :)
--Note: The "BP?" ("Backwards Pole?") feature isn't entirely accurate, but it's like 95% accurate

--Before running the script, you MUST set this variable to the region you're playing on — NTSC or PAL — in order for the timer to use
--the right framerate. If you set this variable to a non-valid value, this will make the timer default to you not playing on PAL.
local region = "NTSC" --Valid inputs: '"NTSC"' and '"PAL"'

--toggle features, change to false if you don't want them
local toggle_display_above_status_bar_information   = true
local toggle_display_sprite_hitboxes                = true
local toggle_display_mario_hitbox                   = true
local toggle_display_sprite_slot_above_sprite       = true
local toggle_display_sprite_information             = true
local toggle_display_sprite_information_after_death = false
local toggle_display_time                           = true

--variables
local text_colour             = "white"
local text_faded_colour       = "#80FFFFFF"
local text_back_colour        = "#66000000"
local text_faded_back_colour  = "#33000000"
local hitbox_edge_colour_on   = "#00FF00" --Hitbox back and edge colour for when collisions are being checked
local hitbox_back_colour_on   = "#8000FF00"
local hitbox_edge_colour_off  = "#00FF00" --Hitbox back and edge colour for when collisions are not being checked
local hitbox_back_colour_off  = "clear"
local sprite_slot_text_colour = "white"
local sprite_slot_back_colour = "#66000000"

--Timer settings:
local negative_delay = true --'true' for negative delay, 'false' for the timer to say "00:00:00.000" until timing starts
local start_frame    = 0 --0 for TAS timing
local end_frame      = -1 --Set to -1 for no end frame

--Pellsson settings:
local XOrg = 0x3AD
local YOrg = 0x705

--all of the wram addresses I need
local wram_FrameCounter          = 9
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
local wram_Player_Rel_XPos       = 0x3AD
local wram_SprObject_X_MoveForce = 0x401
local wram_SprObject_YMF_Dummy   = 0x41C
local wram_Player_Y_MoveForce    = 0x43C
local wram_WarpZoneControl       = 0x6D6
local wram_FrictionAdderLow      = 0x702
local wram_Player_X_MoveForce    = 0x705
local wram_VerticalForce         = 0x709
local wram_ScreenLeft_PageLoc    = 0x71A
local wram_ScreenLeft_X_Pos      = 0x71C
local wram_ScreenRoutineTask     = 0x73C
local wram_StarFlagTaskControl   = 0x746
local wram_LevelNumber           = 0x75C
local wram_WorldNumber           = 0x75F
local wram_OperMode              = 0x770
local wram_OperMode_Task         = 0x772
local wram_IntervalTimerControl  = 0x787
local wram_JumpSwimTimer         = 0x78A
local wram_BoundingBox_UL_Corner = 0xF9C
local wram_Sample7SoundQueue     = 0x1603

--Pellsson variables:
local sock                    = 0
BackwardsPole                 = 0
Frame                         = 0
FrameDisplay                  = -1
OperMode_TaskDisplay          = -1
ScreenEnterDisplay            = 0
StarFlagTaskControlDisplay    = -1
StarFlagTaskControlEndDisplay = -1
XOrgDisplay                   = 0
YOrgDisplay                   = 0

function display_remainder(x) --Function to display the remainder and to compact the code to display Pellsson information
	if StarFlagTaskControlDisplay == -1 then
		Frame = memory.readbyte(wram_FrameCounter)
		StarFlagTaskControlDisplay = (memory.readbyte(wram_IntervalTimerControl) + x) % 21
	end
	gui.pixelText(72, 15, string.format("%d", StarFlagTaskControlDisplay), text_colour, "clear", "fceux")
end

function display_pellsson() --Code to display Pellsson information
	local sockvalue = (memory.readbyte(wram_SprObject_X_Position) << 8)
		+ memory.readbyte(wram_SprObject_X_MoveForce)
		+ ((0xFF - memory.readbyte(wram_SprObject_Y_Position) >> 2) * 0x280)
	if memory.readbyte(wram_IntervalTimerControl) % 4 == 2 then
		sock = sockvalue % 0x10000
	end
	gui.drawBox(0, 7, 32, 15, text_back_colour, text_back_colour)
	gui.pixelText(-1, 7, "S", text_colour, "clear", "fceux")
	gui.pixelText(4, 7, ":", text_colour, "clear", "fceux")
	gui.pixelText(8, 7, string.format("%04X", sock), text_colour, "clear", "fceux")
	
	if memory.readbyte(wram_ScreenRoutineTask) == 4 then
		local chars = "0123456789ABCDEFGHIJK"
		Frame = memory.readbyte(wram_FrameCounter) - 1
		ScreenEnterDisplay = string.sub(chars, memory.readbyte(wram_IntervalTimerControl) + 1, memory.readbyte(wram_IntervalTimerControl) + 1)
	end
	gui.drawBox(34, 0, 49, 7, text_back_colour, text_back_colour)
	gui.drawPixel(35, 2, text_colour)
	gui.drawPixel(36, 3, text_colour)
	gui.drawPixel(37, 4, text_colour)
	gui.drawPixel(38, 5, text_colour)
	gui.drawPixel(39, 6, text_colour)
	gui.drawPixel(35, 6, text_colour)
	gui.drawPixel(36, 5, text_colour)
	gui.drawPixel(38, 3, text_colour)
	gui.drawPixel(39, 2, text_colour)
	gui.pixelText(39, -1, ":", text_colour, "clear", "fceux")
	gui.pixelText(43, -1, string.format("%s", ScreenEnterDisplay), text_colour, "clear", "fceux")
	
	if (memory.readbyte(wram_OperMode) == 0 and memory.readbyte(wram_FrameCounter) % 2 == 0)
	or memory.readbyte(wram_JumpSwimTimer) == 0x20
	or memory.readbyte(wram_Sample7SoundQueue ) == 1
	or memory.readbyte(wram_FloateyNum_Timer) == 0x2A
	or memory.readbyte(wram_FloateyNum_Timer + 1) == 0x2A
	or memory.readbyte(wram_FloateyNum_Timer + 2) == 0x2A
	or memory.readbyte(wram_FloateyNum_Timer + 3) == 0x2A
	or memory.readbyte(wram_FloateyNum_Timer + 4) == 0x2A
	or memory.readbyte(wram_FloateyNum_Timer + 5) == 0x2A
	or memory.readbyte(wram_FloateyNum_Timer + 6) == 0x2A
	or memory.readbyte(wram_FloateyNum_Timer + 7) == 0x2A
	or memory.readbyte(wram_FloateyNum_Timer + 8) == 0x2A
	or memory.readbyte(wram_FloateyNum_Timer + 9) == 0x2A
	or memory.readbyte(wram_GameEngineSubroutine) == 7 then
		if FrameDisplay == -1 then
			FrameDisplay = memory.readbyte(wram_FrameCounter)
			Frame = memory.readbyte(wram_FrameCounter)
		end
	else
		FrameDisplay = -1
	end
	gui.drawBox(34, 7, 61, 15, text_back_colour, text_back_colour)
	memory.usememorydomain("CGRAM")
	if memory.readbyte(0xB) == 3 and memory.readbyte(0xA) == 0x5F then
		gui.pixelText(34, 7, "F", "#FFD600", "clear", "fceux")
	elseif memory.readbyte(0xB) == 3 and memory.readbyte(0xA) == 0xFF then
		gui.pixelText(34, 7, "F", "#FFFF00", "clear", "fceux")
	else
		gui.pixelText(34, 7, "F", "#FFFFFF", "clear", "fceux")
	end
	gui.pixelText(39, 7, ":", text_colour, "clear", "fceux")
	gui.pixelText(43, 7, string.format("%03d", Frame), text_colour, "clear", "fceux")
	
	memory.usememorydomain("System Bus")
	if memory.readbyte(wram_FrameCounter) % 2 == 0 then
		XOrgDisplay = memory.readbyte(XOrg)
		YOrgDisplay = memory.readbyte(YOrg)
	end
	gui.drawBox(63, 0, 90, 7, text_back_colour, text_back_colour)
	gui.pixelText(63, -1, "X", text_colour, "clear", "fceux")
	gui.pixelText(68, -1, ":", text_colour, "clear", "fceux")
	gui.pixelText(72, -1, string.format("%03d", XOrgDisplay), text_colour, "clear", "fceux")
	
	gui.drawBox(63, 7, 90, 15, text_back_colour, text_back_colour)
	gui.pixelText(63, 7, "Y", text_colour, "clear", "fceux")
	gui.pixelText(68, 7, ":", text_colour, "clear", "fceux")
	gui.pixelText(72, 7, string.format("%03d", YOrgDisplay), text_colour, "clear", "fceux")
	
	gui.drawBox(63, 15, 84, 23, text_back_colour, text_back_colour)
	gui.pixelText(63, 15, "R", text_colour, "clear", "fceux")
	gui.pixelText(68, 15, ":", text_colour, "clear", "fceux")
	if memory.readbyte(wram_StarFlagTaskControl) == 4
	or memory.readbyte(wram_StarFlagTaskControl) == 5
	or memory.readbyte(wram_OperMode) == 2
	or memory.readbyte(wram_GameEngineSubroutine) == 2 then
		display_remainder(0)
	elseif memory.readbyte(wram_GameEngineSubroutine) == 3 then
		if memory.readbyte(wram_WarpZoneControl) ~= 0 then
			display_remainder(8)
		else
			display_remainder(0)
		end
	else
		StarFlagTaskControlDisplay = -1
	end
	if memory.readbyte(wram_StarFlagTaskControl) == 5 then
		if StarFlagTaskControlEndDisplay == -1 then
			Frame = memory.readbyte(wram_FrameCounter)
			StarFlagTaskControlEndDisplay = memory.readbyte(wram_IntervalTimerControl)
			StarFlagTaskControlDisplay = StarFlagTaskControlEndDisplay
		end
	else
		StarFlagTaskControlEndDisplay = -1
	end
	if memory.readbyte(wram_OperMode_Task) == 6 then
		if OperMode_TaskDisplay == -1 then
			Frame = memory.readbyte(wram_FrameCounter)
			OperMode_TaskDisplay = memory.readbyte(wram_IntervalTimerControl)
			StarFlagTaskControlDisplay = OperMode_TaskDisplay
		end
	else
		OperMode_TaskDisplay = -1
	end
	
	if memory.readbyte(wram_Player_Rel_XPos) > 0x70 then
		xpos = memory.readbyte(wram_Player_Rel_XPos) - 0x70
	else
		xpos = 0
	end
	if (memory.readbyte(wram_WorldNumber) == 0 and memory.readbyte(wram_LevelNumber) == 0) or (memory.readbyte(wram_WorldNumber) == 7 and memory.readbyte(wram_LevelNumber) == 2) then
		if (memory.readbyte(wram_SprObject_X_Position + 10) - (0xE6 - xpos) >= -128 and memory.readbyte(wram_SprObject_X_Position + 10) - (0xE6 - xpos) <= -1) or memory.readbyte(wram_SprObject_X_Position + 10) - (0xE6 - xpos) >= 0x80 then
			BackwardsPole = true
		else
			BackwardsPole = false
		end
	elseif (memory.readbyte(wram_WorldNumber) == 0 and memory.readbyte(wram_LevelNumber) == 1) or (memory.readbyte(wram_WorldNumber) == 1 and memory.readbyte(wram_LevelNumber) == 1) or (memory.readbyte(wram_WorldNumber) == 3 and memory.readbyte(wram_LevelNumber) == 1) or (memory.readbyte(wram_WorldNumber) == 6 and memory.readbyte(wram_LevelNumber) == 1) then
		if (memory.readbyte(wram_SprObject_X_Position + 10) - (0xE7 - xpos) >= -128 and memory.readbyte(wram_SprObject_X_Position + 10) - (0xE7 - xpos) <= -1) or memory.readbyte(wram_SprObject_X_Position + 10) - (0xE7 - xpos) >= 0x80 then
			BackwardsPole = true
		else
			BackwardsPole = false
		end
	elseif (memory.readbyte(wram_WorldNumber) == 0 and memory.readbyte(wram_LevelNumber) == 2) or (memory.readbyte(wram_WorldNumber) == 4 and memory.readbyte(wram_LevelNumber) == 2) then
		if xpos > 5 then
			if (memory.readbyte(wram_SprObject_X_Position + 10) - (5 - xpos + 0x100) >= -128 and memory.readbyte(wram_SprObject_X_Position + 10) - (5 - xpos + 0x100) <= -1) or memory.readbyte(wram_SprObject_X_Position + 10) - (5 - xpos + 0x100) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		else
			if (memory.readbyte(wram_SprObject_X_Position + 10) - (5 - xpos) >= -128 and memory.readbyte(wram_SprObject_X_Position + 10) - (5 - xpos) <= -1) or memory.readbyte(wram_SprObject_X_Position + 10) - (5 - xpos) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		end
	elseif memory.readbyte(wram_WorldNumber) == 1 and memory.readbyte(wram_LevelNumber) == 0 then
		if xpos > 0x10 then
			if (memory.readbyte(wram_SprObject_X_Position + 10) - (0x10 - xpos + 0x100) >= -128 and memory.readbyte(wram_SprObject_X_Position + 10) - (0x10 - xpos + 0x100) <= -1) or memory.readbyte(wram_SprObject_X_Position + 10) - (0x10 - xpos + 0x100) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		else
			if (memory.readbyte(wram_SprObject_X_Position + 10) - (0x10 - xpos) >= -128 and memory.readbyte(wram_SprObject_X_Position + 10) - (0x10 - xpos) <= -1) or memory.readbyte(wram_SprObject_X_Position + 10) - (0x10 - xpos) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		end
	elseif (memory.readbyte(wram_WorldNumber) == 1 and memory.readbyte(wram_LevelNumber) == 2) or (memory.readbyte(wram_WorldNumber) == 3 and memory.readbyte(wram_LevelNumber) == 0) or (memory.readbyte(wram_WorldNumber) == 6 and memory.readbyte(wram_LevelNumber) == 2) then
		if (memory.readbyte(wram_SprObject_X_Position + 10) - (0x98 - xpos) >= -128 and memory.readbyte(wram_SprObject_X_Position + 10) - (0x98 - xpos) <= -1) or memory.readbyte(wram_SprObject_X_Position + 10) - (0x98 - xpos) >= 0x80 then
			BackwardsPole = true
		else
			BackwardsPole = false
		end
	elseif (memory.readbyte(wram_WorldNumber) == 2 and memory.readbyte(wram_LevelNumber) == 0) or (memory.readbyte(wram_WorldNumber) == 4 and memory.readbyte(wram_LevelNumber) == 2) then
		if xpos > 8 then
			if (memory.readbyte(wram_SprObject_X_Position + 10) - (8 - xpos + 0x100) >= -128 and memory.readbyte(wram_SprObject_X_Position + 10) - (8 - xpos + 0x100) <= -1) or memory.readbyte(wram_SprObject_X_Position + 10) - (8 - xpos + 0x100) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		else
			if (memory.readbyte(wram_SprObject_X_Position + 10) - (8 - xpos) >= -128 and memory.readbyte(wram_SprObject_X_Position + 10) - (8 - xpos) <= -1) or memory.readbyte(wram_SprObject_X_Position + 10) - (8 - xpos) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		end
	elseif memory.readbyte(wram_WorldNumber) == 2 and memory.readbyte(wram_LevelNumber) == 1 then
		if (memory.readbyte(wram_SprObject_X_Position + 10) - (0x96 - xpos) >= -128 and memory.readbyte(wram_SprObject_X_Position + 10) - (0x96 - xpos) <= -1) or memory.readbyte(wram_SprObject_X_Position + 10) - (0x96 - xpos) >= 0x80 then
			BackwardsPole = true
		else
			BackwardsPole = false
		end
	elseif memory.readbyte(wram_WorldNumber) == 2 and memory.readbyte(wram_LevelNumber) == 2 then
		if (memory.readbyte(wram_SprObject_X_Position + 10) - (0xF7 - xpos) >= -128 and memory.readbyte(wram_SprObject_X_Position + 10) - (0xF7 - xpos) <= -1) or memory.readbyte(wram_SprObject_X_Position + 10) - (0xF7 - xpos) >= 0x80 then
			BackwardsPole = true
		else
			BackwardsPole = false
		end
	elseif (memory.readbyte(wram_WorldNumber) == 3 and memory.readbyte(wram_LevelNumber) == 2) or (memory.readbyte(wram_WorldNumber) == 6 and memory.readbyte(wram_LevelNumber) == 0) then
		if (memory.readbyte(wram_SprObject_X_Position + 10) - (0xB6 - xpos) >= -128 and memory.readbyte(wram_SprObject_X_Position + 10) - (0xB6 - xpos) <= -1) or memory.readbyte(wram_SprObject_X_Position + 10) - (0xB6 - xpos) >= 0x80 then
			BackwardsPole = true
		else
			BackwardsPole = false
		end
	elseif (memory.readbyte(wram_WorldNumber) == 4 and memory.readbyte(wram_LevelNumber) == 0) or (memory.readbyte(wram_WorldNumber) == 5 and memory.readbyte(wram_LevelNumber) == 2) then
		if (memory.readbyte(wram_SprObject_X_Position + 10) - (0xF6 - xpos) >= -128 and memory.readbyte(wram_SprObject_X_Position + 10) - (0xF6 - xpos) <= -1) or memory.readbyte(wram_SprObject_X_Position + 10) - (0xF6 - xpos) >= 0x80 then
			BackwardsPole = true
		else
			BackwardsPole = false
		end
	elseif memory.readbyte(wram_WorldNumber) == 5 and memory.readbyte(wram_LevelNumber) == 0 then
		if xpos > 0x27 then
			if (memory.readbyte(wram_SprObject_X_Position + 10) - (0x27 - xpos + 0x100) >= -128 and memory.readbyte(wram_SprObject_X_Position + 10) - (0x27 - xpos + 0x100) <= -1) or memory.readbyte(wram_SprObject_X_Position + 10) - (0x27 - xpos + 0x100) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		else
			if (memory.readbyte(wram_SprObject_X_Position + 10) - (0x27 - xpos) >= -128 and memory.readbyte(wram_SprObject_X_Position + 10) - (0x27 - xpos) <= -1) or memory.readbyte(wram_SprObject_X_Position + 10) - (0x27 - xpos) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		end
	elseif (memory.readbyte(wram_WorldNumber) == 5 and memory.readbyte(wram_LevelNumber) == 1) or (memory.readbyte(wram_WorldNumber) == 7 and memory.readbyte(wram_LevelNumber) == 0) or (memory.readbyte(wram_WorldNumber) == 7 and memory.readbyte(wram_LevelNumber) == 1) then
		if xpos > 7 then
			if (memory.readbyte(wram_SprObject_X_Position + 10) - (7 - xpos + 0x100) >= -128 and memory.readbyte(wram_SprObject_X_Position + 10) - (7 - xpos + 0x100) <= -1) or memory.readbyte(wram_SprObject_X_Position + 10) - (7 - xpos + 0x100) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		else
			if (memory.readbyte(wram_SprObject_X_Position + 10) - (7 - xpos) >= -128 and memory.readbyte(wram_SprObject_X_Position + 10) - (7 - xpos) <= -1) or memory.readbyte(wram_SprObject_X_Position + 10) - (7 - xpos) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		end
	end
	gui.drawBox(0, 15, 20, 23, text_back_colour, text_back_colour)
	gui.pixelText(-1, 15, "BP?", text_colour, "clear", "fceux")
	gui.pixelText(16, 15, ":", text_colour, "clear", "fceux")
	gui.drawBox(0, 23, 20, 31, text_back_colour, text_back_colour)
	if BackwardsPole then
		gui.pixelText(-1, 23, "Y", text_colour, "clear", "fceux")
	else
		gui.pixelText(-1, 23, "N", text_colour, "clear", "fceux")
	end
end

local function hitbox(x1, y1, x2, y2) --Function to draw the hitboxes
	if memory.readbyte(wram_FrameCounter) % 2 == 0 then --If collisions are being checked, draw "on" colour
		if y1 > y2 then
			gui.drawBox(x1, 0, x2, y2, hitbox_edge_colour_on, hitbox_back_colour_on)
		else
			gui.drawBox(x1, y1, x2, y2, hitbox_edge_colour_on, hitbox_back_colour_on)
		end
	else --Otherwise, draw "off" colour
		if y1 > y2 then
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
		if emu.framecount() - start_frame < 0 then
			frames = round(1 / (snes_framerate_numerator / snes_framerate_denominator) * snes_framerate_numerator * ((emu.framecount() - start_frame) * -1) / (snes_framerate_numerator / 1000)) / 1000 --Absolute value of current frames in movie
		else
			frames = round(1 / (snes_framerate_numerator / snes_framerate_denominator) * snes_framerate_numerator * (emu.framecount() - start_frame) / (snes_framerate_numerator / 1000)) / 1000 --current frames in movie
		end
	else --If there is an end frame, stop updating the timer when end frame has been reached
		if emu.framecount() <= end_frame then
			if emu.framecount() - start_frame < 0 then
				frames = round(1 / (snes_framerate_numerator / snes_framerate_denominator) * snes_framerate_numerator * ((emu.framecount() - start_frame) * -1) / (snes_framerate_numerator / 1000)) / 1000 --Absolute value of current frames in movie
			else
				frames = round(1 / (snes_framerate_numerator / snes_framerate_denominator) * snes_framerate_numerator * (emu.framecount() - start_frame) / (snes_framerate_numerator / 1000)) / 1000 --current frames in movie
			end
		else
			frames = round(1 / (snes_framerate_numerator / snes_framerate_denominator) * snes_framerate_numerator * (end_frame - start_frame) / (snes_framerate_numerator / 1000)) / 1000 --current frames in movie
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
	gui.drawBox(92, 0, 128, 7, text_back_colour, text_back_colour)
	gui.pixelText(92, -1, "XP", text_colour, "clear", "fceux")
	gui.pixelText(103, -1, ":", text_colour, "clear", "fceux")
	gui.pixelText(107, -1, string.format("%02X", memory.readbyte(wram_SprObject_X_Position)), text_colour, "clear", "fceux")
	gui.pixelText(118, -1, ".", text_colour, "clear", "fceux")
	gui.pixelText(122, -1, string.format("%X", memory.readbyte(wram_SprObject_X_MoveForce) >> 4), text_colour, "clear", "fceux")
	gui.drawBox(92, 7, 134, 15, text_back_colour, text_back_colour)
	gui.pixelText(92, 7, "YP", text_colour, "clear", "fceux")
	gui.pixelText(103, 7, ":", text_colour, "clear", "fceux")
	gui.pixelText(107, 7, string.format("%02X", memory.readbyte(wram_SprObject_Y_Position)), text_colour, "clear", "fceux")
	gui.pixelText(118, 7, ".", text_colour, "clear", "fceux")
	gui.pixelText(122, 7, string.format("%02X", memory.readbyte(wram_SprObject_YMF_Dummy)), text_colour, "clear", "fceux")
	
	--Display X Speed, the CORRECT X SubSpeed value, Y Speed, and the CORRECT Y SubSpeed value
	--How this essentially works:
	--• If X Speed is positive, display the normal X SubSpeed value. Otherwise, display the two's complement of the X SubSpeed value.
	--• If Y Speed is positive, display the normal Y SubSpeed value. Otherwise, display the two's complement of the Y SubSpeed value.
	if memory.read_s8(wram_Player_X_Speed) > -1 then
		if memory.readbyte(wram_Player_X_Speed) < 10 then
			gui.drawBox(136, 0, 172, 7, text_back_colour, text_back_colour)
			gui.pixelText(156, -1, ".", text_colour, "clear", "fceux")
			gui.pixelText(160, -1, string.format("%02X", memory.readbyte(wram_Player_X_MoveForce)), text_colour, "clear", "fceux")
		else
			gui.drawBox(136, 0, 178, 7, text_back_colour, text_back_colour)
			gui.pixelText(162, -1, ".", text_colour, "clear", "fceux")
			gui.pixelText(166, -1, string.format("%02X", memory.readbyte(wram_Player_X_MoveForce)), text_colour, "clear", "fceux")
		end
		gui.pixelText(151, -1, string.format("%d", memory.readbyte(wram_Player_X_Speed)), text_colour, "clear", "fceux")
	else
		if memory.read_s8(wram_Player_X_Speed) > -10 then
			gui.drawBox(136, 0, 177, 7, text_back_colour, text_back_colour)
			gui.pixelText(161, -1, ".", text_colour, "clear", "fceux")
			gui.pixelText(165, -1, string.format("%02X", (256 - memory.readbyte(wram_Player_X_MoveForce)) % 256), text_colour, "clear", "fceux")
		else
			gui.drawBox(136, 0, 183, 7, text_back_colour, text_back_colour)
			gui.pixelText(167, -1, ".", text_colour, "clear", "fceux")
			gui.pixelText(171, -1, string.format("%02X", (256 - memory.readbyte(wram_Player_X_MoveForce)) % 256), text_colour, "clear", "fceux")
		end
		gui.drawLine(152, 3, 155, 3, text_colour)
		gui.pixelText(156, -1, string.format("%d", memory.read_s8(wram_Player_X_Speed) * -1), text_colour, "clear", "fceux")
	end
	gui.pixelText(136, -1, "XS", text_colour, "clear", "fceux")
	gui.pixelText(147, -1, ":", text_colour, "clear", "fceux")
	if memory.read_s8(wram_Player_Y_Speed) > -1 then
		if memory.readbyte(wram_Player_Y_Speed) < 10 then
			gui.drawBox(136, 7, 172, 15, text_back_colour, text_back_colour)
			gui.pixelText(156, 7, ".", text_colour, "clear", "fceux")
			gui.pixelText(160, 7, string.format("%02X", memory.readbyte(wram_Player_Y_MoveForce)), text_colour, "clear", "fceux")
		else
			gui.drawBox(136, 7, 178, 15, text_back_colour, text_back_colour)
			gui.pixelText(162, 7, ".", text_colour, "clear", "fceux")
			gui.pixelText(166, 7, string.format("%02X", memory.readbyte(wram_Player_Y_MoveForce)), text_colour, "clear", "fceux")
		end
		gui.pixelText(151, 7, string.format("%d", memory.readbyte(wram_Player_Y_Speed)), text_colour, "clear", "fceux")
	else
		if memory.read_s8(wram_Player_Y_Speed) > -10 then
			gui.drawBox(136, 7, 177, 15, text_back_colour, text_back_colour)
			gui.pixelText(161, 7, ".", text_colour, "clear", "fceux")
			gui.pixelText(165, 7, string.format("%02X", (256 - memory.readbyte(wram_Player_Y_MoveForce)) % 256), text_colour, "clear", "fceux")
		else
			gui.drawBox(136, 7, 183, 15, text_back_colour, text_back_colour)
			gui.pixelText(167, 7, ".", text_colour, "clear", "fceux")
			gui.pixelText(171, 7, string.format("%02X", (256 - memory.readbyte(wram_Player_Y_MoveForce)) % 256), text_colour, "clear", "fceux")
		end
		gui.drawLine(152, 11, 155, 11, text_colour)
		gui.pixelText(156, 7, string.format("%d", memory.read_s8(wram_Player_Y_Speed) * -1), text_colour, "clear", "fceux")
	end
	gui.pixelText(136, 7, "YS", text_colour, "clear", "fceux")
	gui.pixelText(147, 7, ":", text_colour, "clear", "fceux")
	
	gui.drawBox(185, 0, 227, 7, text_back_colour, text_back_colour) --Display X SpeedAdder
	gui.pixelText(185, -1, "XSA", text_colour, "clear", "fceux")
	gui.pixelText(202, -1, ":", text_colour, "clear", "fceux")
	gui.pixelText(206, -1, string.format("%d", memory.readbyte(wram_FrictionAdderLow - 1)), text_colour, "clear", "fceux")
	gui.pixelText(211, -1, ".", text_colour, "clear", "fceux")
	gui.pixelText(215, -1, string.format("%02X", memory.readbyte(wram_FrictionAdderLow)), text_colour, "clear", "fceux")
	gui.drawBox(185, 7, 227, 15, text_back_colour, text_back_colour) --Display Y SpeedAdder
	gui.pixelText(185, 7, "YSA", text_colour, "clear", "fceux")
	gui.pixelText(202, 7, ":", text_colour, "clear", "fceux")
	gui.pixelText(206, 7, "0", text_colour, "clear", "fceux")
	gui.pixelText(211, 7, ".", text_colour, "clear", "fceux")
	gui.pixelText(215, 7, string.format("%02X", memory.readbyte(wram_VerticalForce)), text_colour, "clear", "fceux")
	
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
		display_pellsson()
		display_information()
	end
	
	if toggle_display_time then
		display_time()
	end
	emu.frameadvance()
end