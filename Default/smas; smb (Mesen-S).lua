﻿--This lua script is supposed to be identical to the smb3.lua script (https://github.com/fortenbt/smb3-lua) but for SMAS: SMB and for Mesen-S
--Thank you to @Simplistic for helping me fix the Frame counter display :)
--Note: The "Backwards Pole?" feature isn't entirely accurate, but it's like 95% accurate

--Before running the script, you MUST set this variable to the region you're playing on — NTSC or PAL — in order for the timer to use
--the right framerate. If you set this variable to a non-valid value, this will make the timer default to you not playing on PAL.
local region = "NTSC" --Valid inputs: '"NTSC"' and '"PAL"'

--toggle features, change to false if you don't want them
local toggle_display_pellsson                       = true --Not a part of the smb3.lua script, but I thought having this would be useful
local toggle_display_sprite_hitboxes                = true
local toggle_display_mario_hitbox                   = true
local toggle_display_sprite_slot_above_sprite       = true
local toggle_display_sprite_information             = true
local toggle_display_sprite_information_after_death = false
local toggle_display_time                           = true
local toggle_display_21_framerule                   = true --Not a part of the smb3.lua script, but I thought it would be nice to have this
local toggle_display_mario_position                 = true
local toggle_display_mario_velocity                 = true
local toggle_display_mario_velocity_adder           = true --Not a part of the smb3.lua script
local toggle_display_state                          = true --Essentially the same as Player_InAir ($D8) from SMB3

--variables
local text_colour             = 0xFFFFFF
local text_faded_colour       = 0x7FFFFFFF
local text_back_colour        = 0x99000000
local text_faded_back_colour  = 0xCC000000
local hitbox_edge_colour_on   = 0x00FF00 --Hitbox back and edge colour for when collisions are being checked
local hitbox_back_colour_on   = 0x7F00FF00
local hitbox_edge_colour_off  = 0x00FF00 --Hitbox back and edge colour for when collisions are not being checked
local hitbox_back_colour_off  = 0xFF000000
local sprite_slot_text_colour = 0xFFFFFF
local sprite_slot_back_colour = 0x99000000

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

function drawString(x, y, text, text_colour, text_back_colour)
	emu.drawLine(x - 1, y - 1, x - 1, y + 7, text_back_colour)
	emu.drawString(x, y, text, text_colour, text_back_colour)
end

function display_remainder(x) --Function to display the remainder and to compact the code to display Pellsson information
	if StarFlagTaskControlDisplay == -1 then
		Frame = emu.read(wram_FrameCounter, emu.memType.cpu)
		StarFlagTaskControlDisplay = (emu.read(wram_IntervalTimerControl, emu.memType.cpu) + x) % 21
	end
	if StarFlagTaskControlDisplay < 10 then
		drawString(1, 55, string.format("R:%d ", StarFlagTaskControlDisplay), text_colour, text_back_colour)
	else
		drawString(1, 55, string.format("R:%d", StarFlagTaskControlDisplay), text_colour, text_back_colour)
	end
end

function display_pellsson() --Code to display Pellsson information
	local sockvalue = (emu.read(wram_SprObject_X_Position, emu.memType.cpu) << 8)
		+ (emu.read(wram_SprObject_X_MoveForce, emu.memType.cpu))
		+ ((0xFF - emu.read(wram_SprObject_Y_Position, emu.memType.cpu) >> 2) * 0x280)
	if emu.read(wram_IntervalTimerControl, emu.memType.cpu) % 4 == 2 then
		sock = sockvalue % 0x10000
	end
	drawString(1, 8, string.format("S:%04X", sock), text_colour, text_back_colour)
	
	if emu.read(wram_ScreenRoutineTask, emu.memType.cpu) == 4 then
		local chars = "0123456789ABCDEFGHIJK"
		Frame = emu.read(wram_FrameCounter, emu.memType.cpu) - 1
		ScreenEnterDisplay = string.sub(chars, emu.read(wram_IntervalTimerControl, emu.memType.cpu) + 1, emu.read(wram_IntervalTimerControl, emu.memType.cpu) + 1)
	end
	drawString(1, 23, string.format(" :%s", ScreenEnterDisplay), text_colour, text_back_colour)
	emu.drawPixel(1, 25, text_colour)
	emu.drawPixel(2, 26, text_colour)
	emu.drawPixel(3, 27, text_colour)
	emu.drawPixel(4, 28, text_colour)
	emu.drawPixel(5, 29, text_colour)
	emu.drawPixel(5, 25, text_colour)
	emu.drawPixel(4, 26, text_colour)
	emu.drawPixel(2, 28, text_colour)
	emu.drawPixel(1, 29, text_colour)
	
	if (emu.read(wram_OperMode, emu.memType.cpu) == 0 and emu.read(wram_FrameCounter, emu.memType.cpu) % 2 == 0)
	or emu.read(wram_JumpSwimTimer, emu.memType.cpu) == 0x20
	or emu.read(wram_Sample7SoundQueue , emu.memType.cpu) == 1
	or emu.read(wram_FloateyNum_Timer, emu.memType.cpu) == 0x2A
	or emu.read(wram_FloateyNum_Timer + 1, emu.memType.cpu) == 0x2A
	or emu.read(wram_FloateyNum_Timer + 2, emu.memType.cpu) == 0x2A
	or emu.read(wram_FloateyNum_Timer + 3, emu.memType.cpu) == 0x2A
	or emu.read(wram_FloateyNum_Timer + 4, emu.memType.cpu) == 0x2A
	or emu.read(wram_FloateyNum_Timer + 5, emu.memType.cpu) == 0x2A
	or emu.read(wram_FloateyNum_Timer + 6, emu.memType.cpu) == 0x2A
	or emu.read(wram_FloateyNum_Timer + 7, emu.memType.cpu) == 0x2A
	or emu.read(wram_FloateyNum_Timer + 8, emu.memType.cpu) == 0x2A
	or emu.read(wram_FloateyNum_Timer + 9, emu.memType.cpu) == 0x2A
	or emu.read(wram_GameEngineSubroutine, emu.memType.cpu) == 7
	or emu.read(wram_Sample7SoundQueue, emu.memType.cpu) == 7 and emu.read(wram_OperMode, emu.memType.cpu) ~= 2 then
		if FrameDisplay == -1 then
			FrameDisplay = emu.read(wram_FrameCounter, emu.memType.cpu)
			Frame = emu.read(wram_FrameCounter, emu.memType.cpu)
		end
	else
		FrameDisplay = -1
	end
	drawString(1, 31, string.format(" rame:%03d", Frame), text_colour, text_back_colour)
	if emu.read(0xB, emu.memType.cgram) == 3 and emu.read(0xA, emu.memType.cgram) == 0x5F then
		drawString(1, 31, "F", 0xFFD600, 0xFF000000)
	elseif emu.read(0xB, emu.memType.cgram) == 3 and emu.read(0xA, emu.memType.cgram) == 0xFF then
		drawString(1, 31, "F", 0xFFFF00, 0xFF000000)
	else
		drawString(1, 31, "F", 0xFFFFFF, 0xFF000000)
	end
	
	if emu.read(wram_FrameCounter, emu.memType.cpu) % 2 == 0 then
		XOrgDisplay = emu.read(XOrg, emu.memType.cpu)
		YOrgDisplay = emu.read(YOrg, emu.memType.cpu)
	end
	drawString(1, 39, string.format("X:%03d", XOrgDisplay), text_colour, text_back_colour)
	
	drawString(1, 47, string.format("Y:%03d", YOrgDisplay), text_colour, text_back_colour)
	
	if emu.read(wram_StarFlagTaskControl, emu.memType.cpu) == 4
	or emu.read(wram_StarFlagTaskControl, emu.memType.cpu) == 5
	or emu.read(wram_OperMode, emu.memType.cpu) == 2
	or emu.read(wram_GameEngineSubroutine, emu.memType.cpu) == 2 then
		display_remainder(0)
	elseif emu.read(wram_GameEngineSubroutine, emu.memType.cpu) == 3 then
		if emu.read(wram_WarpZoneControl, emu.memType.cpu) ~= 0 then
			display_remainder(8)
		else
			display_remainder(0)
		end
	else
		StarFlagTaskControlDisplay = -1
		drawString(1, 55, "R:  ", text_colour, text_back_colour)
	end
	if emu.read(wram_StarFlagTaskControl, emu.memType.cpu) == 5 then
		if StarFlagTaskControlEndDisplay == -1 then
			Frame = emu.read(wram_FrameCounter, emu.memType.cpu)
			StarFlagTaskControlEndDisplay = emu.read(wram_IntervalTimerControl, emu.memType.cpu)
			StarFlagTaskControlDisplay = StarFlagTaskControlEndDisplay
		end
	else
		StarFlagTaskControlEndDisplay = -1
	end
	if emu.read(wram_OperMode_Task, emu.memType.cpu) == 6 then
		if OperMode_TaskDisplay == -1 then
			Frame = emu.read(wram_FrameCounter, emu.memType.cpu)
			OperMode_TaskDisplay = emu.read(wram_IntervalTimerControl, emu.memType.cpu)
			StarFlagTaskControlDisplay = OperMode_TaskDisplay
		end
	else
		OperMode_TaskDisplay = -1
	end
	
	if emu.read(wram_Player_Rel_XPos, emu.memType.cpu) > 0x70 then
		xpos = emu.read(wram_Player_Rel_XPos, emu.memType.cpu) - 0x70
	else
		xpos = 0
	end
	if (emu.read(wram_WorldNumber, emu.memType.cpu) == 0 and emu.read(wram_LevelNumber, emu.memType.cpu) == 0) or (emu.read(wram_WorldNumber, emu.memType.cpu) == 7 and emu.read(wram_LevelNumber, emu.memType.cpu) == 2) then
		if (emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0xE6 - xpos) >= -128 and emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0xE6 - xpos) <= -1) or emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0xE6 - xpos) >= 0x80 then
			BackwardsPole = true
		else
			BackwardsPole = false
		end
	elseif (emu.read(wram_WorldNumber, emu.memType.cpu) == 0 and emu.read(wram_LevelNumber, emu.memType.cpu) == 1) or (emu.read(wram_WorldNumber, emu.memType.cpu) == 1 and emu.read(wram_LevelNumber, emu.memType.cpu) == 1) or (emu.read(wram_WorldNumber, emu.memType.cpu) == 3 and emu.read(wram_LevelNumber, emu.memType.cpu) == 1) or (emu.read(wram_WorldNumber, emu.memType.cpu) == 6 and emu.read(wram_LevelNumber, emu.memType.cpu) == 1) then
		if (emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0xE7 - xpos) >= -128 and emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0xE7 - xpos) <= -1) or emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0xE7 - xpos) >= 0x80 then
			BackwardsPole = true
		else
			BackwardsPole = false
		end
	elseif (emu.read(wram_WorldNumber, emu.memType.cpu) == 0 and emu.read(wram_LevelNumber, emu.memType.cpu) == 2) or (emu.read(wram_WorldNumber, emu.memType.cpu) == 4 and emu.read(wram_LevelNumber, emu.memType.cpu) == 2) then
		if xpos > 5 then
			if (emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (5 - xpos + 0x100) >= -128 and emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (5 - xpos + 0x100) <= -1) or emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (5 - xpos + 0x100) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		else
			if (emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (5 - xpos) >= -128 and emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (5 - xpos) <= -1) or emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (5 - xpos) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		end
	elseif emu.read(wram_WorldNumber, emu.memType.cpu) == 1 and emu.read(wram_LevelNumber, emu.memType.cpu) == 0 then
		if xpos > 0x10 then
			if (emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x10 - xpos + 0x100) >= -128 and emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x10 - xpos + 0x100) <= -1) or emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x10 - xpos + 0x100) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		else
			if (emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x10 - xpos) >= -128 and emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x10 - xpos) <= -1) or emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x10 - xpos) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		end
	elseif (emu.read(wram_WorldNumber, emu.memType.cpu) == 1 and emu.read(wram_LevelNumber, emu.memType.cpu) == 2) or (emu.read(wram_WorldNumber, emu.memType.cpu) == 3 and emu.read(wram_LevelNumber, emu.memType.cpu) == 0) or (emu.read(wram_WorldNumber, emu.memType.cpu) == 6 and emu.read(wram_LevelNumber, emu.memType.cpu) == 2) then
		if (emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x98 - xpos) >= -128 and emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x98 - xpos) <= -1) or emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x98 - xpos) >= 0x80 then
			BackwardsPole = true
		else
			BackwardsPole = false
		end
	elseif (emu.read(wram_WorldNumber, emu.memType.cpu) == 2 and emu.read(wram_LevelNumber, emu.memType.cpu) == 0) or (emu.read(wram_WorldNumber, emu.memType.cpu) == 4 and emu.read(wram_LevelNumber, emu.memType.cpu) == 2) then
		if xpos > 8 then
			if (emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (8 - xpos + 0x100) >= -128 and emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (8 - xpos + 0x100) <= -1) or emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (8 - xpos + 0x100) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		else
			if (emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (8 - xpos) >= -128 and emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (8 - xpos) <= -1) or emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (8 - xpos) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		end
	elseif emu.read(wram_WorldNumber, emu.memType.cpu) == 2 and emu.read(wram_LevelNumber, emu.memType.cpu) == 1 then
		if (emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x96 - xpos) >= -128 and emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x96 - xpos) <= -1) or emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x96 - xpos) >= 0x80 then
			BackwardsPole = true
		else
			BackwardsPole = false
		end
	elseif emu.read(wram_WorldNumber, emu.memType.cpu) == 2 and emu.read(wram_LevelNumber, emu.memType.cpu) == 2 then
		if (emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0xF7 - xpos) >= -128 and emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0xF7 - xpos) <= -1) or emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0xF7 - xpos) >= 0x80 then
			BackwardsPole = true
		else
			BackwardsPole = false
		end
	elseif (emu.read(wram_WorldNumber, emu.memType.cpu) == 3 and emu.read(wram_LevelNumber, emu.memType.cpu) == 2) or (emu.read(wram_WorldNumber, emu.memType.cpu) == 6 and emu.read(wram_LevelNumber, emu.memType.cpu) == 0) then
		if (emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0xB6 - xpos) >= -128 and emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0xB6 - xpos) <= -1) or emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0xB6 - xpos) >= 0x80 then
			BackwardsPole = true
		else
			BackwardsPole = false
		end
	elseif (emu.read(wram_WorldNumber, emu.memType.cpu) == 4 and emu.read(wram_LevelNumber, emu.memType.cpu) == 0) or (emu.read(wram_WorldNumber, emu.memType.cpu) == 5 and emu.read(wram_LevelNumber, emu.memType.cpu) == 2) then
		if (emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0xF6 - xpos) >= -128 and emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0xF6 - xpos) <= -1) or emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0xF6 - xpos) >= 0x80 then
			BackwardsPole = true
		else
			BackwardsPole = false
		end
	elseif emu.read(wram_WorldNumber, emu.memType.cpu) == 5 and emu.read(wram_LevelNumber, emu.memType.cpu) == 0 then
		if xpos > 0x27 then
			if (emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x27 - xpos + 0x100) >= -128 and emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x27 - xpos + 0x100) <= -1) or emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x27 - xpos + 0x100) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		else
			if (emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x27 - xpos) >= -128 and emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x27 - xpos) <= -1) or emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (0x27 - xpos) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		end
	elseif (emu.read(wram_WorldNumber, emu.memType.cpu) == 5 and emu.read(wram_LevelNumber, emu.memType.cpu) == 1) or (emu.read(wram_WorldNumber, emu.memType.cpu) == 7 and emu.read(wram_LevelNumber, emu.memType.cpu) == 0) or (emu.read(wram_WorldNumber, emu.memType.cpu) == 7 and emu.read(wram_LevelNumber, emu.memType.cpu) == 1) then
		if xpos > 7 then
			if (emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (7 - xpos + 0x100) >= -128 and emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (7 - xpos + 0x100) <= -1) or emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (7 - xpos + 0x100) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		else
			if (emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (7 - xpos) >= -128 and emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (7 - xpos) <= -1) or emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu) - (7 - xpos) >= 0x80 then
				BackwardsPole = true
			else
				BackwardsPole = false
			end
		end
	end
	emu.drawRectangle(0, 62, 50, 9, text_back_colour, text_back_colour)
	emu.drawString(1, 63, "Backwards", text_colour, 0xFF000000)
	emu.drawRectangle(0, 70, 50, 9, text_back_colour, text_back_colour)
	if BackwardsPole then
		emu.drawString(1, 71, "Pole?: Yes", text_colour, 0xFF000000)
	else
		emu.drawString(1, 71, "Pole?: No", text_colour, 0xFF000000)
	end
end

local function hitbox(x1, y1, x2, y2) --Function to draw the hitboxes
	if emu.read(wram_FrameCounter, emu.memType.cpu) % 2 == 0 then --If collisions are being checked, draw "on" colour
		if y1 > y2 then
			emu.drawRectangle(x1, 7, x2 - x1 + 1, y2 + 1, hitbox_back_colour_on, 1, 1, 2)
			emu.drawRectangle(x1, 7, x2 - x1 + 1, y2 + 1, hitbox_edge_colour_on, 0, 1, 2)
		else
			emu.drawRectangle(x1, y1 + 7, x2 - x1 + 1, y2 - y1 + 1, hitbox_back_colour_on, 1, 1, 2)
			emu.drawRectangle(x1, y1 + 7, x2 - x1 + 1, y2 - y1 + 1, hitbox_edge_colour_on, 0, 1, 2)
		end
	else --Otherwise, draw "off" colour
		if y1 > y2 then
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
		if emu.read(wram_Enemy_Flag + i - 1, emu.memType.cpu) ~= 0 then
			hitbox(emu.read(wram_BoundingBox_UL_Corner + (i * 4), emu.memType.cpu), emu.read(wram_BoundingBox_UL_Corner + (i * 4 + 1), emu.memType.cpu), emu.read(wram_BoundingBox_UL_Corner + (i * 4 + 2), emu.memType.cpu), emu.read(wram_BoundingBox_UL_Corner + (i * 4 + 3), emu.memType.cpu))
		end
	end
	
	for i = 1, 2, 1 do --Draw fireball hitboxes
		if emu.read(wram_Fireball_State + i - 1, emu.memType.cpu) ~= 0 then
			hitbox(emu.read(wram_BoundingBox_UL_Corner + ((10 + i) * 4), emu.memType.cpu), emu.read(wram_BoundingBox_UL_Corner + ((10 + i) * 4 + 1), emu.memType.cpu), emu.read(wram_BoundingBox_UL_Corner + ((10 + i) * 4 + 2), emu.memType.cpu), emu.read(wram_BoundingBox_UL_Corner + ((10 + i) * 4 + 3), emu.memType.cpu))
		end
	end
	
	for i = 1, 9, 1 do --Draw hammer and coin hitboxes
		if emu.read(wram_Misc_State + i - 1, emu.memType.cpu) ~= 0 then
			hitbox(emu.read(wram_BoundingBox_UL_Corner + ((12 + i) * 4), emu.memType.cpu), emu.read(wram_BoundingBox_UL_Corner + ((12 + i) * 4 + 1), emu.memType.cpu), emu.read(wram_BoundingBox_UL_Corner + ((12 + i) * 4 + 2), emu.memType.cpu), emu.read(wram_BoundingBox_UL_Corner + ((12 + i) * 4 + 3), emu.memType.cpu))
		end
	end
end

function display_mario_hitbox()
	if emu.read(wram_GameEngineSubroutine, emu.memType.cpu) ~= 0 then --If Mario is alive, draw Mario's hitbox
		hitbox(emu.read(wram_BoundingBox_UL_Corner, emu.memType.cpu), emu.read(wram_BoundingBox_UL_Corner + 1, emu.memType.cpu), emu.read(wram_BoundingBox_UL_Corner + 2, emu.memType.cpu), emu.read(wram_BoundingBox_UL_Corner + 3, emu.memType.cpu))
	end
end

function display_sprite_slot_above_sprite()
	for i = 1, 10, 1 do
		if emu.read(wram_Enemy_Flag + i - 1, emu.memType.cpu) ~= 0 then
			emu.drawLine((emu.read(wram_SprObject_PageLoc + i, emu.memType.cpu) * 256 + emu.read(wram_SprObject_X_Position + i, emu.memType.cpu)) - (emu.read(wram_ScreenLeft_PageLoc, emu.memType.cpu) * 256 + emu.read(wram_ScreenLeft_X_Pos, emu.memType.cpu)) + 2, emu.read(wram_SprObject_Y_Position + i, emu.memType.cpu) - 2, (emu.read(wram_SprObject_PageLoc + i, emu.memType.cpu) * 256 + emu.read(wram_SprObject_X_Position + i, emu.memType.cpu)) - (emu.read(wram_ScreenLeft_PageLoc, emu.memType.cpu) * 256 + emu.read(wram_ScreenLeft_X_Pos, emu.memType.cpu)) + 2, emu.read(wram_SprObject_Y_Position + i, emu.memType.cpu) + 6, sprite_slot_back_colour, 1, 1)
			emu.drawString((emu.read(wram_SprObject_PageLoc + i, emu.memType.cpu) * 256 + emu.read(wram_SprObject_X_Position + i, emu.memType.cpu)) - (emu.read(wram_ScreenLeft_PageLoc, emu.memType.cpu) * 256 + emu.read(wram_ScreenLeft_X_Pos, emu.memType.cpu)) + 3, emu.read(wram_SprObject_Y_Position + i, emu.memType.cpu) - 1, string.format("[%d]", i - 1), sprite_slot_text_colour, sprite_slot_back_colour, 1, 1) --draw the sprite slot above it
		end
	end
end

function display_spriteslots()
	local y_counter = 82 --for listing sprites and removing blank spriteslot's spaces
	for i = 1, 10, 1 do
		if emu.read(wram_Enemy_Flag + i - 1, emu.memType.cpu) ~= (toggle_display_sprite_information_after_death and -1 or 0) then --if the sprite isn't dead, unless ..._after_death is set
			if emu.read(wram_Enemy_Flag + i - 1, emu.memType.cpu) == 0 then --If dead, display faded text and background
				drawString(1, y_counter, string.format("%d:%02X", i - 1, emu.read(wram_Enemy_ID + i - 1, emu.memType.cpu)), text_faded_colour, text_faded_back_colour) --display sprite slot number and sprite ID
				emu.drawString(23, y_counter, string.format("(%02X.%X, %02X.%02X)", emu.read(wram_SprObject_X_Position + i, emu.memType.cpu), emu.read(wram_SprObject_X_MoveForce + i, emu.memType.cpu) >> 4, emu.read(wram_SprObject_Y_Position + i, emu.memType.cpu), emu.read(wram_SprObject_YMF_Dummy + i, emu.memType.cpu)), text_faded_colour, text_faded_back_colour) --draw position
				y_counter = y_counter + 8 --add to y_counter so the next sprite is shown below the previous
			else --Otherwise, display fully-bright text and background
				drawString(1, y_counter, string.format("%d:%02X", i - 1, emu.read(wram_Enemy_ID + i - 1, emu.memType.cpu)), text_colour, text_back_colour) --display sprite slot number and sprite ID
				emu.drawString(23, y_counter, string.format("(%02X.%X, %02X.%02X)", emu.read(wram_SprObject_X_Position + i, emu.memType.cpu), emu.read(wram_SprObject_X_MoveForce + i, emu.memType.cpu) >> 4, emu.read(wram_SprObject_Y_Position + i, emu.memType.cpu), emu.read(wram_SprObject_YMF_Dummy + i, emu.memType.cpu)), text_colour, text_back_colour) --draw position
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
		if emu.getState().ppu.frameCount - start_frame < 0 then
			frames = round(1 / (snes_framerate_numerator / snes_framerate_denominator) * snes_framerate_numerator * ((emu.getState().ppu.frameCount - start_frame) * -1) / (snes_framerate_numerator / 1000)) / 1000 --Absolute value of current frames in movie
		else
			frames = round(1 / (snes_framerate_numerator / snes_framerate_denominator) * snes_framerate_numerator * (emu.getState().ppu.frameCount - start_frame) / (snes_framerate_numerator / 1000)) / 1000 --current frames in movie
		end
	else --If there is an end frame, stop updating the timer when end frame has been reached
		if emu.getState().ppu.frameCount <= end_frame then
			if emu.getState().ppu.frameCount - start_frame < 0 then
				frames = round(1 / (snes_framerate_numerator / snes_framerate_denominator) * snes_framerate_numerator * ((emu.getState().ppu.frameCount - start_frame) * -1) / (snes_framerate_numerator / 1000)) / 1000 --Absolute value of current frames in movie
			else
				frames = round(1 / (snes_framerate_numerator / snes_framerate_denominator) * snes_framerate_numerator * (emu.getState().ppu.frameCount - start_frame) / (snes_framerate_numerator / 1000)) / 1000 --current frames in movie
			end
		else
			frames = round(1 / (snes_framerate_numerator / snes_framerate_denominator) * snes_framerate_numerator * (end_frame - start_frame) / (snes_framerate_numerator / 1000)) / 1000 --end frame in movie
		end
	end
	
	hours = math.floor(frames / 3600)
	minutes = math.floor((frames / 60) % 60)
	seconds = math.floor(frames % 60)
	milliseconds = math.floor((frames * 1000) % 1000)
	
	if negative_delay then --If negative delay, show negative time before timing starts
		if emu.getState().ppu.frameCount - start_frame < 0 then
			drawString(188, 223, string.format("-%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds), text_colour, text_back_colour) --draw it
		else
			drawString(193, 223, string.format("%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds), text_colour, text_back_colour) --draw it
		end
	else --Otherwise, show 0 hours, 0 minutes, 0 seconds, and 0 milliseconds until timing starts
		if emu.getState().ppu.frameCount - start_frame < 0 then
			drawString(193, 223, "00:00:00.000", text_colour, text_back_colour) --draw 0 hours, 0 minutes, 0 seconds, and 0 milliseconds
		else
			drawString(193, 223, string.format("%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds), text_colour, text_back_colour) --draw it
		end
	end
end

function round(n)
	return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

function display_information()
	local y_counter = 8
	
	if toggle_display_21_framerule then
		if emu.read(wram_IntervalTimerControl, emu.memType.cpu) < 10 then --Done to make the display look nice
			drawString(173, y_counter, string.format("21 Framerule:  %d", emu.read(wram_IntervalTimerControl, emu.memType.cpu)), text_colour, text_back_colour)
		else
			drawString(173, y_counter, string.format("21 Framerule: %d", emu.read(wram_IntervalTimerControl, emu.memType.cpu)), text_colour, text_back_colour)
		end
	end
	
	y_counter = 165
	
	--display mario information
	if toggle_display_mario_position or toggle_display_mario_velocity or toggle_display_mario_velocity_adder or toggle_display_state then
		drawString(1, y_counter, "Mario:", text_colour, text_back_colour)
		y_counter = y_counter + 8
	end
	
	if toggle_display_mario_position then
		drawString(1, y_counter, string.format("Pos: (%02X.%X, %02X.%02X)", emu.read(wram_SprObject_X_Position, emu.memType.cpu), emu.read(wram_SprObject_X_MoveForce, emu.memType.cpu) >> 4, emu.read(wram_SprObject_Y_Position, emu.memType.cpu), emu.read(wram_SprObject_YMF_Dummy, emu.memType.cpu)), text_colour, text_back_colour)
		y_counter = y_counter + 8
	end
	
	if toggle_display_mario_velocity then --Display X Speed, the CORRECT X SubSpeed value, Y Speed, and the CORRECT Y SubSpeed value
		--How this essentially works:
		--• If X Speed is positive, display the normal X SubSpeed value. Otherwise, display the two's complement of the X SubSpeed value
		--• If Y Speed is positive, display the normal Y SubSpeed value. Otherwise, display the two's complement of the Y SubSpeed value
		if emu.read(wram_Player_X_Speed, emu.memType.cpu, 1) > -1 and emu.read(wram_Player_Y_Speed, emu.memType.cpu, 1) > -1 then
			drawString(1, y_counter, string.format("Speed: (%d.%02X, %d.%02X)", emu.read(wram_Player_X_Speed, emu.memType.cpu), emu.read(wram_Player_X_MoveForce, emu.memType.cpu), emu.read(wram_Player_Y_Speed, emu.memType.cpu), emu.read(wram_Player_Y_MoveForce, emu.memType.cpu)), text_colour, text_back_colour)
		elseif emu.read(wram_Player_X_Speed, emu.memType.cpu, 1) > -1 and emu.read(wram_Player_Y_Speed, emu.memType.cpu, 1) < 0 then
			drawString(1, y_counter, string.format("Speed: (%d.%02X, %d.%02X)", emu.read(wram_Player_X_Speed, emu.memType.cpu), emu.read(wram_Player_X_MoveForce, emu.memType.cpu), emu.read(wram_Player_Y_Speed, emu.memType.cpu, 1), (256 - emu.read(wram_Player_Y_MoveForce, emu.memType.cpu)) % 256), text_colour, text_back_colour)
		elseif emu.read(wram_Player_X_Speed, emu.memType.cpu, 1) < 0 and emu.read(wram_Player_Y_Speed, emu.memType.cpu, 1) > -1 then
			drawString(1, y_counter, string.format("Speed: (%d.%02X, %d.%02X)", emu.read(wram_Player_X_Speed, emu.memType.cpu, 1), (256 - emu.read(wram_Player_X_MoveForce, emu.memType.cpu)) % 256, emu.read(wram_Player_Y_Speed, emu.memType.cpu), emu.read(wram_Player_Y_MoveForce, emu.memType.cpu)), text_colour, text_back_colour)
		else
			drawString(1, y_counter, string.format("Speed: (%d.%02X, %d.%02X)", emu.read(wram_Player_X_Speed, emu.memType.cpu, 1), (256 - emu.read(wram_Player_X_MoveForce, emu.memType.cpu)) % 256, emu.read(wram_Player_Y_Speed, emu.memType.cpu, 1), (256 - emu.read(wram_Player_Y_MoveForce, emu.memType.cpu)) % 256), text_colour, text_back_colour)
		end
		y_counter = y_counter + 8
	end
	
	--I blame @slither for wanting me to add this
	if toggle_display_mario_velocity_adder then
		emu.drawRectangle(0, y_counter - 1, 95, 9, text_back_colour, text_back_colour)
		emu.drawString(1, y_counter, "Speed", text_colour, 0xFF000000) --Display "Speed"
		drawString(1, y_counter + 8, string.format("Adder: (%d.%02X, 0.%02X)", emu.read(wram_FrictionAdderLow - 1, emu.memType.cpu), emu.read(wram_FrictionAdderLow, emu.memType.cpu), emu.read(wram_VerticalForce, emu.memType.cpu)), text_colour, text_back_colour) --Display "Adder:" and SpeedAdder
		y_counter = y_counter + 16
	end
	
	if toggle_display_state then
		drawString(1, y_counter, string.format("State?: %d", emu.read(wram_Player_State, emu.memType.cpu)), text_colour, text_back_colour)
	end
end

function calculations()
	if toggle_display_pellsson then
		display_pellsson()
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