--This lua script is supposed to be identical to the smb3.lua script (https://github.com/fortenbt/smb3-lua) but for SMB and for FCEUX
--Thank you to @Simplistic for helping me fix the Frame counter display and @slither for helping me with the framerule counter :)
--Note: Unless you're using Pellsson, the framerule counter only works with the following routes:
--• Start → Small → End
--• Start → Small → Mushroom → End
--• Start → Small → Mushroom → Fire → End

--Before running the script, you MUST set this variable to either the game you're playing or the game the ROMhack you're playing is based off of in order to have
--accurate warp zone remainders, the framerule counter to be accurate, and for the timer to use the right framerate. For example, if you're playing Super Bob, that
--game is based off of NTSC SMB, so you would set this variable to '"NTSC SMB"'. Pellsson ROM is automatically detected and is prioritized over all the other four
--games, so if you're using Pellsson, it doesn't matter what you have this variable set to. If you set this variable to a non-valid value, this will cause you to
--not have accurate warp zone remainders, and it will make the framerule counter and the timer default to you not playing on PAL SMB.
local game = "NTSC SMB" --Valid inputs: "NTSC SMB", "PAL SMB", "SMB2J", and "ANNSMB"

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
local text_colour             = "white"
local text_faded_colour       = "#FFFFFF80"
local text_back_colour        = "#00000066"
local text_faded_back_colour  = "#00000033"
local hitbox_edge_colour_on   = "green" --Hitbox back and edge colour for when collisions are being checked
local hitbox_back_colour_on   = "#00FF0080"
local hitbox_edge_colour_off  = "green" --Hitbox back and edge colour for when collisions are not being checked
local hitbox_back_colour_off  = "clear"
local sprite_slot_text_colour = "white"
local sprite_slot_back_colour = "#00000066"

--Timer settings:
local negative_delay = true --'true' for negative delay, 'false' for the timer to say "00:00:00.000" until timing starts
local start_frame    = 0 --0 for TAS timing
local end_frame      = -1 --Set to -1 for no end frame

--Pellsson settings:
local XOrg = 0x3AD
local YOrg = 0x705

--all of the ram addresses I need
local ram_FrameCounter          = 9
local ram_GameEngineSubroutine  = 0xE
local ram_Enemy_Flag            = 0xF
local ram_Enemy_ID              = 0x16
local ram_Player_State          = 0x1D
local ram_Fireball_State        = 0x24
local ram_Misc_State            = 0x2A
local ram_Player_X_Speed        = 0x57
local ram_SprObject_PageLoc     = 0x6D
local ram_SprObject_X_Position  = 0x86
local ram_Player_Y_Speed        = 0x9F
local ram_SprObject_Y_Position  = 0xCE
local ram_NoiseSoundQueue       = 0xFD
local ram_Square2SoundQueue     = 0xFE
local ram_FloateyNum_Timer      = 0x12C
local ram_SprObject_X_MoveForce = 0x400
local ram_SprObject_YMF_Dummy   = 0x416
local ram_Player_Y_MoveForce    = 0x433
local ram_BoundingBox_UL_Corner = 0x4AC
local ram_WarpZoneControl       = 0x6D6
local ram_FrictionAdderLow      = 0x702
local ram_Player_X_MoveForce    = 0x705
local ram_VerticalForce         = 0x709
local ram_ScreenLeft_PageLoc    = 0x71A
local ram_ScreenLeft_X_Pos      = 0x71C
local ram_ScreenRoutineTask     = 0x73C
local ram_StarFlagTaskControl   = 0x746
local ram_PlayerStatus          = 0x756
local ram_OperMode              = 0x770
local ram_OperMode_Task         = 0x772
local ram_IntervalTimerControl  = 0x77F
local ram_JumpSwimTimer         = 0x782
local ram_PseudoRandomBitReg    = 0x7A7
local ram_CurrentRule           = 0x7DF --Pellsson RAM address
local ram_BANK_SELECTED         = 0x7FF --Pellsson RAM address

--Pellsson variables:
local framerule               = 0
local sock                    = 0
Frame                         = 0
FrameDisplay                  = -1
OperMode_TaskDisplay          = -1
OperMode_TaskDisplay2         = -1
Rule                          = 0
ScreenEnterDisplay            = 0
StarFlagTaskControlDisplay    = -1
StarFlagTaskControlEndDisplay = -1
XOrgDisplay                   = 0
YOrgDisplay                   = 0

function display_remainder(x, mod) --Function to display the remainder and to compact the code to display Pellsson information
	if StarFlagTaskControlDisplay == -1 then
		Frame = memory.readbyte(ram_FrameCounter)
		Rule = framerule
		StarFlagTaskControlDisplay = (memory.readbyte(ram_IntervalTimerControl) + x) % mod
	end
	if StarFlagTaskControlDisplay < 10 then
		gui.text(1, 57, string.format("R:%d ", StarFlagTaskControlDisplay), text_colour, text_back_colour)
	else
		gui.text(1, 57, string.format("R:%d", StarFlagTaskControlDisplay), text_colour, text_back_colour)
	end
end
	
function display_pellsson() --Code to display Pellsson information
	if memory.readbyte(0xFDFD) == 0xEA and memory.readbyte(0xFDFE) == 0xEA --Check if we're playing on any version of Pellsson
	and memory.readbyte(0xFDFF) == 0xEA and memory.readbyte(0xFE00) == 0xA9
	and memory.readbyte(0xFE02) == 0x20 and memory.readbyte(0xFE04) == 0xFF
	and memory.readbyte(0xFE05) == 0x4C then
		if (memory.readbyte(0xFE01) == 6 and memory.readbyte(0xFE03) == 0x16
		and memory.readbyte(0xFE06) == 0x6B and memory.readbyte(0xFE07) == 0xB7)
		or (memory.readbyte(0xFE01) == 6 and memory.readbyte(0xFE03) == 0x16
		and memory.readbyte(0xFE06) == 0x69 and memory.readbyte(0xFE07) == 0xB7)
		or (memory.readbyte(0xFE01) == 6 and memory.readbyte(0xFE03) == 0x3D
		and memory.readbyte(0xFE06) == 0x7A and memory.readbyte(0xFE07) == 0xB9) then
			Pellsson_Pellsson = "5.5 FDS/5.6/6.0 Beta"
		elseif memory.readbyte(0xFE01) == 0xC and memory.readbyte(0xFE03) == 0x4A
		and memory.readbyte(0xFE06) == 0xF5 and memory.readbyte(0xFE07) == 0xBB then
			Pellsson_Pellsson = "6.0 MMC5"
		elseif memory.readbyte(0xFE01) == 6 and memory.readbyte(0xFE03) == 0x16
		and memory.readbyte(0xFE06) == 0x9B and memory.readbyte(0xFE07) == 0xB7 then
			Pellsson_Pellsson = "PAL"
		elseif memory.readbyte(0xFE01) == 0xEA and memory.readbyte(0xFE03) == 0xEA
		and memory.readbyte(0xFE06) == 0xEA and memory.readbyte(0xFE07) == 0xEA then
			Pellsson_Pellsson = Pellsson
		else
			Pellsson_Pellsson = false
		end
	elseif memory.readbyte(0xFDFD) == 0xEA and memory.readbyte(0xFDFE) == 0xEA
	and memory.readbyte(0xFDFF) == 0xEA and memory.readbyte(0xFE00) == 0xEA
	and memory.readbyte(0xFE02) == 0xEA and memory.readbyte(0xFE04) == 0xEA
	and memory.readbyte(0xFE05) == 0xEA then
		Pellsson_Pellsson = Pellsson
	else
		Pellsson_Pellsson = false
	end
	
	if Pellsson_Pellsson == false then
		if memory.readbyte(0xE141) == 0x38 and memory.readbyte(0xE142) == 0x44
		and memory.readbyte(0xE143) == 0xBA and memory.readbyte(0xE144) == 0xAA
		and memory.readbyte(0xE145) == 0xB2 and memory.readbyte(0xE146) == 0xAA
		and memory.readbyte(0xE147) == 0x44 and memory.readbyte(0xE148) == 0x38 then --If playing an FDS game
			x = 2
		else
			x = 1
		end
		
		if game == "PAL SMB" then
			if memory.readbyte(ram_PlayerStatus) == 0 then
				framerule = math.floor((emu.framecount() - emu.lagcount() - 1) / 18 + 1) % 10000
			elseif memory.readbyte(ram_PlayerStatus) == 1 then
				framerule = math.floor((emu.framecount() - emu.lagcount() - 60) / 18 + 1) % 10000
			else
				framerule = math.floor((emu.framecount() - emu.lagcount() - 123) / 18 + 1) % 10000
			end
		else
			if memory.readbyte(ram_PlayerStatus) == 0 then
				framerule = math.floor((emu.framecount() - emu.lagcount() - x) / 21 + 1) % 10000
			elseif memory.readbyte(ram_PlayerStatus) == 1 then
				framerule = math.floor((emu.framecount() - emu.lagcount() - x - 59) / 21 + 1) % 10000
			else
				framerule = math.floor((emu.framecount() - emu.lagcount() - x - 122) / 21 + 1) % 10000
			end
		end
	else
		framerule = memory.readbyte(ram_CurrentRule) * 1000
			+ memory.readbyte(ram_CurrentRule + 1) * 100
			+ memory.readbyte(ram_CurrentRule + 2) * 10
			+ memory.readbyte(ram_CurrentRule + 3)
	end
	
	local sockvalue = bit.lshift(memory.readbyte(ram_SprObject_X_Position), 8)
		+ memory.readbyte(ram_SprObject_X_MoveForce)
		+ (bit.rshift(0xFF - memory.readbyte(ram_SprObject_Y_Position), 2) * 0x280)
	if memory.readbyte(ram_IntervalTimerControl) % 4 == 2 then
		sock = sockvalue % 0x10000
	end
	gui.text(1, 17, string.format("S:%04X", sock), text_colour, text_back_colour)
	
	if memory.readbyte(ram_ScreenRoutineTask) == 4 then
		local chars = "0123456789ABCDEFGHIJK"
		Frame = memory.readbyte(ram_FrameCounter) - 1
		Rule = framerule
		ScreenEnterDisplay = string.sub(chars, memory.readbyte(ram_IntervalTimerControl) + 1, memory.readbyte(ram_IntervalTimerControl) + 1)
	end
	gui.text(1, 25, string.format(" :%s", ScreenEnterDisplay), text_colour, text_back_colour)
	gui.pixel(1, 27, text_colour)
	gui.pixel(2, 28, text_colour)
	gui.pixel(3, 29, text_colour)
	gui.pixel(4, 30, text_colour)
	gui.pixel(5, 31, text_colour)
	gui.pixel(5, 27, text_colour)
	gui.pixel(4, 28, text_colour)
	gui.pixel(2, 30, text_colour)
	gui.pixel(1, 31, text_colour)
	
	if (memory.readbyte(ram_OperMode) == 0 and memory.readbyte(ram_FrameCounter) % 2 == 0)
	or memory.readbyte(ram_JumpSwimTimer) == 0x20
	or memory.readbyte(ram_Square2SoundQueue) == 1
	or memory.readbyte(ram_FloateyNum_Timer) == 0x2A
	or memory.readbyte(ram_FloateyNum_Timer + 1) == 0x2A
	or memory.readbyte(ram_FloateyNum_Timer + 2) == 0x2A
	or memory.readbyte(ram_FloateyNum_Timer + 3) == 0x2A
	or memory.readbyte(ram_FloateyNum_Timer + 4) == 0x2A
	or memory.readbyte(ram_GameEngineSubroutine) == 7
	or memory.readbyte(ram_NoiseSoundQueue) == 1 and memory.readbyte(ram_OperMode) ~= 2 then
		if FrameDisplay == -1 then
			FrameDisplay = memory.readbyte(ram_FrameCounter)
			Frame = memory.readbyte(ram_FrameCounter)
			Rule = framerule
		end
	elseif memory.readbyte(ram_FloateyNum_Timer + 5) == 0x2A then
		if FrameDisplay == -1 then
			FrameDisplay = memory.readbyte(ram_FrameCounter)
			Frame = memory.readbyte(ram_FrameCounter)
			if memory.readbyte(ram_PlayerStatus) == 1 then
				if memory.readbyte(ram_IntervalTimerControl) < 9 then
					Rule = framerule + 2
				else
					Rule = framerule + 3
				end
			else
				if memory.readbyte(ram_IntervalTimerControl) < 5 then
					Rule = framerule + 2
				else
					Rule = framerule + 3
				end
			end
		end
	else
		FrameDisplay = -1
	end
	gui.text(1, 33, string.format(" rame:%03d", Frame), text_colour, text_back_colour)
	if ppu.readbyte(0x3F0D) == 7 then
		gui.text(1, 33, "F", "#7D0800", "clear")
	elseif ppu.readbyte(0x3F0D) == 0x17 then
		gui.text(1, 33, "F", "#CB4D0C", "clear")
	else
		gui.text(1, 33, "F", "#FF9A38", "clear")
	end
	
	if memory.readbyte(ram_FrameCounter) % 2 == 0 then
		XOrgDisplay = memory.readbyte(XOrg)
		YOrgDisplay = memory.readbyte(YOrg)
	end
	gui.text(1, 41, string.format("X:%03d", XOrgDisplay), text_colour, text_back_colour)
	
	gui.text(1, 49, string.format("Y:%03d", YOrgDisplay), text_colour, text_back_colour)
	
	if memory.readbyte(ram_StarFlagTaskControl) == 4
	or memory.readbyte(ram_StarFlagTaskControl) == 5
	or memory.readbyte(ram_OperMode) == 2
	or memory.readbyte(ram_GameEngineSubroutine) == 2 then
		display_remainder(0, 21)
	elseif memory.readbyte(ram_GameEngineSubroutine) == 3 then
		if memory.readbyte(ram_WarpZoneControl) ~= 0 then
			if Pellsson_Pellsson == "5.5 FDS/5.6/6.0 Beta" then --If playing on Pellsson 5.5 FDS, 5.6, or 6.0 Beta
				if memory.readbyte(ram_BANK_SELECTED) == 4 then --If playing SMB on Pellsson 5.5 FDS, 5.6, or 6.0 Beta
					display_remainder(8, 21)
				elseif memory.readbyte(ram_BANK_SELECTED) == 12 then --If playing SMB2J on Pellsson 5.5 FDS, 5.6, or 6.0 Beta
					display_remainder(6, 21)
				end
			elseif Pellsson_Pellsson == "6.0 MMC5" then --If playing Pellsson 6.0 MMC5
				if memory.readbyte(ram_BANK_SELECTED) == 8 then --If playing SMB on Pellsson 6.0 MMC5
					display_remainder(8, 21)
				elseif memory.readbyte(ram_BANK_SELECTED) == 24 then --If playing SMB2J on Pellsson 6.0 MMC5
					display_remainder(6, 21)
				elseif memory.readbyte(ram_BANK_SELECTED) == 32 then --If playing ANNSMB on Pellsson 6.0 MMC5
					display_remainder(5, 21)
				end
			elseif Pellsson_Pellsson == "PAL" then --If playing Pallsson
				display_remainder(7, 18)
			elseif Pellsson_Pellsson == false then --If not playing on any version of Pellsson
				if game == "NTSC SMB" then -- If playing on NTSC SMB
					display_remainder(8, 21)
				elseif game == "PAL SMB" then --If playing on PAL SMB
					display_remainder(7, 18)
				elseif game == "SMB2J" then --If playing on SMB2J
					display_remainder(6, 21)
				elseif game == "ANNSMB" then --If playing on ANNSMB
					display_remainder(5, 21)
				else --If the 'game' variable is set to a non-valid value, then display inaccurate warp zone remainders
					display_remainder(0, 21)
				end
			end
		else
			display_remainder(0, 21)
		end
	else
		StarFlagTaskControlDisplay = -1
		gui.text(1, 57, "R:  ", text_colour, text_back_colour)
	end
	if memory.readbyte(ram_StarFlagTaskControl) == 5 then
		if StarFlagTaskControlEndDisplay == -1 then
			Frame = memory.readbyte(ram_FrameCounter)
			Rule = framerule
			StarFlagTaskControlEndDisplay = memory.readbyte(ram_IntervalTimerControl)
			StarFlagTaskControlDisplay = StarFlagTaskControlEndDisplay
		end
	else
		StarFlagTaskControlEndDisplay = -1
	end
	if memory.readbyte(ram_OperMode_Task) == 4 then
		if OperMode_TaskDisplay == -1 then
			Frame = memory.readbyte(ram_FrameCounter)
			Rule = framerule
			OperMode_TaskDisplay = memory.readbyte(ram_IntervalTimerControl)
			StarFlagTaskControlDisplay = OperMode_TaskDisplay
		end
	else
		OperMode_TaskDisplay = -1
	end
	if memory.readbyte(ram_OperMode_Task) == 5 then
		if OperMode_TaskDisplay2 == -1 then
			Frame = memory.readbyte(ram_FrameCounter)
			Rule = framerule
			OperMode_TaskDisplay2 = memory.readbyte(ram_IntervalTimerControl)
			StarFlagTaskControlDisplay = OperMode_TaskDisplay2
		end
	else
		OperMode_TaskDisplay2 = -1
	end
	
	gui.text(1, 9, string.format("R:%04d", Rule), text_colour, text_back_colour)
end

function display_spriteslots()
	local y_counter = 68 --for listing sprites and removing blank spriteslot's spaces
	for i = 1, 6, 1 do
		if memory.readbyte(ram_Enemy_Flag + i - 1) ~= (toggle_display_sprite_information_after_death and -1 or 0) then --if the sprite isn't dead, unless ..._after_death is set
			if memory.readbyte(ram_Enemy_Flag + i - 1) == 0 then --If dead, display faded text and background
				gui.text(1, y_counter, string.format("%d:%02X", i - 1, memory.readbyte(ram_Enemy_ID + i - 1)), text_faded_colour, text_faded_back_colour) --display sprite slot number and sprite ID
				gui.text(24, y_counter, string.format("(%02X.%X, %02X.%02X)", memory.readbyte(ram_SprObject_X_Position + i), bit.rshift(memory.readbyte(ram_SprObject_X_MoveForce + i), 4), memory.readbyte(ram_SprObject_Y_Position + i), memory.readbyte(ram_SprObject_YMF_Dummy + i)), text_faded_colour, text_faded_back_colour) --draw position
				y_counter = y_counter + 8 --add to y_counter so the next sprite is shown below the previous
			else --Otherwise, display fully-bright text and background
				gui.text(1, y_counter, string.format("%d:%02X", i - 1, memory.readbyte(ram_Enemy_ID + i - 1)), text_colour, text_back_colour) --display sprite slot number and sprite ID
				gui.text(24, y_counter, string.format("(%02X.%X, %02X.%02X)", memory.readbyte(ram_SprObject_X_Position + i), bit.rshift(memory.readbyte(ram_SprObject_X_MoveForce + i), 4), memory.readbyte(ram_SprObject_Y_Position + i), memory.readbyte(ram_SprObject_YMF_Dummy + i)), text_colour, text_back_colour) --draw position
				y_counter = y_counter + 8 --add to y_counter so the next sprite is shown below the previous
			end
		end
	end
end

function display_time()
	if memory.readbyte(0xFDFD) == 0xEA and memory.readbyte(0xFDFE) == 0xEA --Check if we're playing on any version of Pellsson
	and memory.readbyte(0xFDFF) == 0xEA and memory.readbyte(0xFE00) == 0xA9
	and memory.readbyte(0xFE02) == 0x20 and memory.readbyte(0xFE04) == 0xFF
	and memory.readbyte(0xFE05) == 0x4C then
		if (memory.readbyte(0xFE01) == 6 and memory.readbyte(0xFE03) == 0x16
		and memory.readbyte(0xFE06) == 0x6B and memory.readbyte(0xFE07) == 0xB7)
		or (memory.readbyte(0xFE01) == 6 and memory.readbyte(0xFE03) == 0x16
		and memory.readbyte(0xFE06) == 0x69 and memory.readbyte(0xFE07) == 0xB7)
		or (memory.readbyte(0xFE01) == 6 and memory.readbyte(0xFE03) == 0x3D
		and memory.readbyte(0xFE06) == 0x7A and memory.readbyte(0xFE07) == 0xB9)
		or memory.readbyte(0xFE01) == 0xC and memory.readbyte(0xFE03) == 0x4A
		and memory.readbyte(0xFE06) == 0xF5 and memory.readbyte(0xFE07) == 0xBB then
			Pellsson_time = "NTSC"
		elseif memory.readbyte(0xFE01) == 6 and memory.readbyte(0xFE03) == 0x16
		and memory.readbyte(0xFE06) == 0x9B and memory.readbyte(0xFE07) == 0xB7 then
			Pellsson_time = "PAL"
		elseif memory.readbyte(0xFE01) == 0xEA and memory.readbyte(0xFE03) == 0xEA
		and memory.readbyte(0xFE06) == 0xEA and memory.readbyte(0xFE07) == 0xEA then
			Pellsson_time = Pellsson_time
		else
			Pellsson_time = false
		end
	elseif memory.readbyte(0xFDFD) == 0xEA and memory.readbyte(0xFDFE) == 0xEA
	and memory.readbyte(0xFDFF) == 0xEA and memory.readbyte(0xFE00) == 0xEA
	and memory.readbyte(0xFE02) == 0xEA and memory.readbyte(0xFE04) == 0xEA
	and memory.readbyte(0xFE05) == 0xEA then
		Pellsson_time = Pellsson_time
	else
		Pellsson_time = false
	end
	
	if Pellsson_time == false then
		if game == "PAL SMB" then --If playing a PAL game
			nes_framerate_numerator = 322445
			nes_framerate_denominator = 6448
		else
			nes_framerate_numerator = 39375000
			nes_framerate_denominator = 655171
		end
	elseif Pellsson_time == "PAL" then
		nes_framerate_numerator = 322445
		nes_framerate_denominator = 6448
	else
		nes_framerate_numerator = 39375000
		nes_framerate_denominator = 655171
	end
	
	if end_frame < 0 then --If there is no end frame, update the timer forever
		if emu.framecount() - start_frame < 0 then
			frames = round(1 / (nes_framerate_numerator / nes_framerate_denominator) * nes_framerate_numerator * ((emu.framecount() - start_frame) * -1) / (nes_framerate_numerator / 1000)) / 1000 --Absolute value of current frames in movie
		else
			frames = round(1 / (nes_framerate_numerator / nes_framerate_denominator) * nes_framerate_numerator * (emu.framecount() - start_frame) / (nes_framerate_numerator / 1000)) / 1000 --current frames in movie
		end
	else --If there is an end frame, stop updating the timer when end frame has been reached
		if emu.framecount() <= end_frame then
			if emu.framecount() - start_frame < 0 then
				frames = round(1 / (nes_framerate_numerator / nes_framerate_denominator) * nes_framerate_numerator * ((emu.framecount() - start_frame) * -1) / (nes_framerate_numerator / 1000)) / 1000 --Absolute value of current frames in movie
			else
				frames = round(1 / (nes_framerate_numerator / nes_framerate_denominator) * nes_framerate_numerator * (emu.framecount() - start_frame) / (nes_framerate_numerator / 1000)) / 1000 --current frames in movie
			end
		else
			frames = round(1 / (nes_framerate_numerator / nes_framerate_denominator) * nes_framerate_numerator * (end_frame - start_frame) / (nes_framerate_numerator / 1000)) / 1000 --end frame in movie
		end
	end
	
	hours = math.floor(frames / 3600)
	minutes = math.floor((frames / 60) % 60)
	seconds = math.floor(frames % 60)
	milliseconds = math.floor((frames * 1000) % 1000)
	
	if negative_delay then --If negative delay, show negative time before timing starts
		if emu.framecount() - start_frame < 0 then
			gui.text(188, 224, string.format("-%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds), text_colour, text_back_colour) --draw it
		else
			gui.text(193, 224, string.format("%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds), text_colour, text_back_colour) --draw it
		end
	else --Otherwise, show 0 hours, 0 minutes, 0 seconds, and 0 milliseconds until timing starts
		if emu.framecount() - start_frame < 0 then
			gui.text(193, 224, "00:00:00.000", text_colour, text_back_colour) --draw 0 hours, 0 minutes, 0 seconds, and 0 milliseconds
		else
			gui.text(193, 224, string.format("%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds), text_colour, text_back_colour) --draw it
		end
	end
end

function round(n)
	return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

function display_information()
	local y_counter = 9
	
	if toggle_display_21_framerule then
		if memory.readbyte(ram_IntervalTimerControl) < 10 then --Done to make the display look nice
			gui.text(173, y_counter, string.format("21 Framerule:  %d", memory.readbyte(ram_IntervalTimerControl)), text_colour, text_back_colour)
		else
			gui.text(173, y_counter, string.format("21 Framerule: %d", memory.readbyte(ram_IntervalTimerControl)), text_colour, text_back_colour)
		end
	end
	
	y_counter = 119
	
	--display mario information
	if toggle_display_mario_position or toggle_display_mario_velocity or toggle_display_mario_velocity_adder or toggle_display_state then
		gui.text(1, y_counter, "Mario:", text_colour, text_back_colour)
		y_counter = y_counter + 8
	end
	
	if toggle_display_mario_position then
		gui.text(1, y_counter, string.format("Pos: (%02X.%X, %02X.%02X)", memory.readbyte(ram_SprObject_X_Position), bit.rshift(memory.readbyte(ram_SprObject_X_MoveForce), 4), memory.readbyte(ram_SprObject_Y_Position), memory.readbyte(ram_SprObject_YMF_Dummy)), text_colour, text_back_colour)
		y_counter = y_counter + 8
	end
	
	if toggle_display_mario_velocity then --Display X Speed, the CORRECT X SubSpeed value, Y Speed, and the CORRECT Y SubSpeed value
		--How this essentially works:
		--• If X Speed is positive, display the normal X SubSpeed value. Otherwise, display the two's complement of the X SubSpeed value.
		--• If Y Speed is positive, display the normal Y SubSpeed value. Otherwise, display the two's complement of the Y SubSpeed value.
		if memory.readbytesigned(ram_Player_X_Speed) > -1 and memory.readbytesigned(ram_Player_Y_Speed) > -1 then
			gui.text(1, y_counter, string.format("Speed: (%d.%02X, %d.%02X)", memory.readbyte(ram_Player_X_Speed), memory.readbyte(ram_Player_X_MoveForce), memory.readbyte(ram_Player_Y_Speed), memory.readbyte(ram_Player_Y_MoveForce)), text_colour, text_back_colour)
		elseif memory.readbytesigned(ram_Player_X_Speed) > -1 and memory.readbytesigned(ram_Player_Y_Speed) < 0 then
			gui.text(1, y_counter, string.format("Speed: (%d.%02X, %d.%02X)", memory.readbyte(ram_Player_X_Speed), memory.readbyte(ram_Player_X_MoveForce), memory.readbytesigned(ram_Player_Y_Speed), (256 - memory.readbyte(ram_Player_Y_MoveForce)) % 256), text_colour, text_back_colour)
		elseif memory.readbytesigned(ram_Player_X_Speed) < 0 and memory.readbytesigned(ram_Player_Y_Speed) > -1 then
			gui.text(1, y_counter, string.format("Speed: (%d.%02X, %d.%02X)", memory.readbytesigned(ram_Player_X_Speed), (256 - memory.readbyte(ram_Player_X_MoveForce)) % 256, memory.readbyte(ram_Player_Y_Speed), memory.readbyte(ram_Player_Y_MoveForce)), text_colour, text_back_colour)
		else
			gui.text(1, y_counter, string.format("Speed: (%d.%02X, %d.%02X)", memory.readbytesigned(ram_Player_X_Speed), (256 - memory.readbyte(ram_Player_X_MoveForce)) % 256, memory.readbytesigned(ram_Player_Y_Speed), (256 - memory.readbyte(ram_Player_Y_MoveForce)) % 256), text_colour, text_back_colour)
		end
		y_counter = y_counter + 8
	end
	
	if toggle_display_mario_velocity_adder then
		gui.box(0, y_counter - 1, 94, y_counter + 7, text_back_colour, text_back_colour)
		gui.text(1, y_counter, "Speed", text_colour, "clear") --Display "Speed"
		gui.text(1, y_counter + 8, string.format("Adder: (%d.%02X, 0.%02X)", memory.readbyte(ram_FrictionAdderLow - 1), memory.readbyte(ram_FrictionAdderLow), memory.readbyte(ram_VerticalForce)), text_colour, text_back_colour) --Display "Adder:" and SpeedAdder
		y_counter = y_counter + 16
	end
		
	if toggle_display_state then
		gui.text(1, y_counter, string.format("State?: %d", memory.readbyte(ram_Player_State)), text_colour, text_back_colour)
	end
end

function calculations()
	if toggle_display_pellsson then
		display_pellsson()
	end
	
	if toggle_display_sprite_information then
		display_spriteslots()
	end
	
	if toggle_display_time then
		display_time()
	end
	display_information()
end

emu.registerafter(calculations)

local function hitbox(x1, y1, x2, y2) --Function to draw the hitboxes
	if memory.readbyte(ram_FrameCounter) % 2 == 0 then --If collisions are being checked, draw "on" colour
		if y1 > y2 and y2 >= 8 then
			gui.box(x1, 0, x2, y2, hitbox_back_colour_on, hitbox_edge_colour_on)
		elseif y2 >= 8 then
			gui.box(x1, y1, x2, y2, hitbox_back_colour_on, hitbox_edge_colour_on)
		end
	else --Otherwise, draw "off" colour
		if y1 > y2 and y2 >= 8 then
			gui.box(x1, 0, x2, y2, hitbox_back_colour_off, hitbox_edge_colour_off)
		elseif y2 >= 8 then
			gui.box(x1, y1, x2, y2, hitbox_back_colour_off, hitbox_edge_colour_off)
		end
	end
end

while true do --Things needed to be done when graphics are updated — which is one frame after memory is updated
	if toggle_display_sprite_hitboxes then
		for i = 1, 6, 1 do --Draw enemy and power-up hitboxes
			if memory.readbyte(ram_Enemy_Flag + i - 1) ~= 0 then
				hitbox(memory.readbyte(ram_BoundingBox_UL_Corner + (i * 4)), memory.readbyte(ram_BoundingBox_UL_Corner + (i * 4 + 1)), memory.readbyte(ram_BoundingBox_UL_Corner + (i * 4 + 2)), memory.readbyte(ram_BoundingBox_UL_Corner + (i * 4 + 3)))
			end
		end
		
		for i = 1, 2, 1 do --Draw fireball hitboxes
			if memory.readbyte(ram_Fireball_State + i - 1) ~= 0 then
				hitbox(memory.readbyte(ram_BoundingBox_UL_Corner + ((6 + i) * 4)), memory.readbyte(ram_BoundingBox_UL_Corner + ((6 + i) * 4 + 1)), memory.readbyte(ram_BoundingBox_UL_Corner + ((6 + i) * 4 + 2)), memory.readbyte(ram_BoundingBox_UL_Corner + ((6 + i) * 4 + 3)))
			end
		end
		
		for i = 1, 9, 1 do --Draw hammer and coin hitboxes
			if memory.readbyte(ram_Misc_State + i - 1) ~= 0 then
				hitbox(memory.readbyte(ram_BoundingBox_UL_Corner + ((8 + i) * 4)), memory.readbyte(ram_BoundingBox_UL_Corner + ((8 + i) * 4 + 1)), memory.readbyte(ram_BoundingBox_UL_Corner + ((8 + i) * 4 + 2)), memory.readbyte(ram_BoundingBox_UL_Corner + ((8 + i) * 4 + 3)))
			end
		end
	end
	
	if toggle_display_mario_hitbox then
		if memory.readbyte(ram_GameEngineSubroutine) ~= 0 then --If Mario is alive, draw Mario's hitbox
			hitbox(memory.readbyte(ram_BoundingBox_UL_Corner), memory.readbyte(ram_BoundingBox_UL_Corner + 1), memory.readbyte(ram_BoundingBox_UL_Corner + 2), memory.readbyte(ram_BoundingBox_UL_Corner + 3))
		end
	end
	
	if toggle_display_sprite_slot_above_sprite then
		for i = 1, 6, 1 do
			if memory.readbyte(ram_Enemy_Flag + i - 1) ~= 0 then
				gui.text((memory.readbyte(ram_SprObject_PageLoc + i) * 256 + memory.readbyte(ram_SprObject_X_Position + i)) - (memory.readbyte(ram_ScreenLeft_PageLoc) * 256 + memory.readbyte(ram_ScreenLeft_X_Pos)) + 2, memory.readbyte(ram_SprObject_Y_Position + i), string.format("[%d]", i - 1), sprite_slot_text_colour, sprite_slot_back_colour) --draw the sprite slot above it
			end
		end
	end
	emu.frameadvance()
end