--Thank you to @Simplistic for helping me fix the Frame counter display and for helping me with the X subpixel string
--Note: the "Backwards Pole?" feature isn't entirely accurate, but it's like 95% accurate

--Before running the script, you MUST set this variable to the region you're playing on — NTSC or PAL — in order for the timer to use
--the right framerate. If you set this variable to a non-valid value, this will make the timer default to you not playing on PAL.
local region = "NTSC" --Valid inputs: '"NTSC"' and '"PAL"'

--variables
local text_colour      = 0xFFFFFF
local text_back_colour = 0x99000000

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
local wram_Player_X_Speed        = 0x5D
local wram_SprObject_PageLoc     = 0x78
local wram_FloateyNum_Timer      = 0x138
local wram_SprObject_X_Position  = 0x219
local wram_SprObject_Y_Position  = 0x237
local wram_BowserOrigXPos        = 0x366
local wram_Player_Rel_XPos       = 0x3AD
local wram_SprObject_X_MoveForce = 0x401
local wram_WarpZoneControl       = 0x6D6
local wram_JumpspringAnimCtrl    = 0x70E
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

function drawString(x, y, text, text_colour, text_back_colour)
	emu.drawLine(x - 1, y - 1, x - 1, y + 7, text_back_colour)
	emu.drawString(x, y, text, text_colour, text_back_colour)
end

function display_practice_information() --Code to display practice information
	if emu.read(wram_Player_X_Speed, emu.memType.cpu) < 0x19 or emu.read(wram_Player_X_Speed, emu.memType.cpu) > 0xE7 then
		y = 24
	else
		y = 40
	end
	local xstringvalue = (((emu.read(wram_SprObject_PageLoc, emu.memType.cpu) << 12)
		+ (emu.read(wram_SprObject_X_Position, emu.memType.cpu) << 4)
		+ (emu.read(wram_SprObject_X_MoveForce, emu.memType.cpu) >> 4)) % y) >> 3
	local sockvalue = (emu.read(wram_SprObject_X_Position, emu.memType.cpu) << 8)
		+ emu.read(wram_SprObject_X_MoveForce, emu.memType.cpu)
		+ ((0xFF - emu.read(wram_SprObject_Y_Position, emu.memType.cpu) >> 2) * 0x280)
	if emu.read(wram_IntervalTimerControl, emu.memType.cpu) & 3 == 3 then
		xstringactual = xstringvalue
	end
	if emu.read(wram_IntervalTimerControl, emu.memType.cpu) & 3 == 2 then
		xstring = xstringactual
		sock = sockvalue & 0xFFF
		ypos = emu.read(wram_SprObject_Y_Position, emu.memType.cpu) & 3
		DontDisplaySock = false
	end
	if emu.read(wram_DisableScreenFlag, emu.memType.cpu) ~= 0 or emu.read(wram_GameEngineSubroutine, emu.memType.cpu) == 0
	or emu.read(wram_ScreenRoutineTask, emu.memType.cpu) >= 7 and emu.read(wram_ScreenRoutineTask, emu.memType.cpu) <= 9
	or emu.read(wram_AltEntranceControl, emu.memType.cpu) == 2 then
		DontDisplaySock = true
	end
	if DontDisplaySock then
		drawString(1, 16, "S:0000-0", text_back_colour, text_back_colour)
		emu.drawString(1, 16, "S:", text_colour, 0xFF000000)
	else
		drawString(1, 16, string.format("S:%d%03X-%d", xstring, sock, ypos), text_colour, text_back_colour)
	end
	
	if emu.read(wram_ScreenRoutineTask, emu.memType.cpu) == 4 then
		local chars = "0123456789ABCDEFGHIJK"
		Frame = emu.read(wram_FrameCounter, emu.memType.cpu)
		ScreenEnterDisplay = string.sub(chars, emu.read(wram_IntervalTimerControl, emu.memType.cpu) + 1, emu.read(wram_IntervalTimerControl, emu.memType.cpu) + 1)
	end
	drawString(34, 8, string.format("-%s", ScreenEnterDisplay), text_colour, text_back_colour)
	
	for i = 0, 8, 1 do
		if emu.read(wram_Enemy_Flag + i, emu.memType.cpu, 1) > 0 and emu.read(wram_Enemy_ID + i, emu.memType.cpu) == 0x2D
		and emu.read(wram_SprObject_X_Position + i + 1, emu.memType.cpu) == emu.read(wram_BowserOrigXPos, emu.memType.cpu) then
			BowserFrame = true
			break
		end
	end
	local EnemyFrame = false
	for j = 0, 9, 1 do
		if emu.read(wram_FloateyNum_Timer + j, emu.memType.cpu) == 0x2A then
			EnemyFrame = true
			break
		end
	end
	if (emu.read(wram_OperMode, emu.memType.cpu) == 0 and emu.read(wram_FrameCounter, emu.memType.cpu) & 1 == 0)
	or emu.read(wram_GameEngineSubroutine, emu.memType.cpu) == 7
	or emu.read(wram_JumpSwimTimer, emu.memType.cpu) == 0x20 or EnemyFrame or emu.read(wram_Sample7SoundQueue, emu.memType.cpu) == 6
	or (emu.read(wram_Player_State, emu.memType.cpu) == 3 and (emu.read(wram_GameEngineSubroutine, emu.memType.cpu) == 4
	or emu.read(wram_GameEngineSubroutine, emu.memType.cpu) == 5 and emu.read(wram_SprObject_Y_Position, emu.memType.cpu) >= 0xA2))
	or emu.read(wram_StarFlagTaskControl, emu.memType.cpu) == 2 then
		BowserFrame = false
		if FrameDisplay == -1 then
			FrameDisplay = emu.read(wram_FrameCounter, emu.memType.cpu)
			Frame = emu.read(wram_FrameCounter, emu.memType.cpu)
		end
	elseif BowserFrame then
		for k = 0, 8, 1 do
			if emu.read(wram_Enemy_Flag + k, emu.memType.cpu, 1) > 0 and emu.read(wram_Enemy_ID + k, emu.memType.cpu) == 0x2D
			and emu.read(wram_SprObject_X_Position + k + 1, emu.memType.cpu) ~= emu.read(wram_BowserOrigXPos, emu.memType.cpu)
			and emu.read(wram_FrameCounter, emu.memType.cpu) & 3 == 0 then
				if FrameDisplay == -1 then
					FrameDisplay = emu.read(wram_FrameCounter, emu.memType.cpu)
					Frame = emu.read(wram_FrameCounter, emu.memType.cpu)
				end
				BowserFrame = false
				break
			end
		end
	else
		FrameDisplay = -1
	end
	if emu.read(wram_GameEngineSubroutine, emu.memType.cpu) == 8 and emu.read(wram_Player_State, emu.memType.cpu) ~= 3
	and emu.read(wram_JumpspringAnimCtrl, emu.memType.cpu) == 0
	and emu.read(wram_A_B_Buttons, emu.memType.cpu) & 0x80 == 0x80 and PreviousA_B_Buttons & 0x80 == 0 then
		BowserFrame = false
		if FrameDisplay2 == -1 then
			FrameDisplay2 = emu.read(wram_FrameCounter, emu.memType.cpu)
			Frame = emu.read(wram_FrameCounter, emu.memType.cpu)
		end
	else
		FrameDisplay2 = -1
	end
	if emu.read(wram_JumpspringAnimCtrl, emu.memType.cpu) - 1 >= 1
	and emu.read(wram_A_B_Buttons, emu.memType.cpu) & 0x80 == 0x80 and PreviousA_B_Buttons & 0x80 == 0 then
		BowserFrame = false
		if FrameDisplay3 == -1 then
			FrameDisplay3 = emu.read(wram_FrameCounter, emu.memType.cpu)
			Frame = emu.read(wram_FrameCounter, emu.memType.cpu)
		end
	else
		FrameDisplay3 = -1
	end
	PreviousA_B_Buttons = emu.read(wram_A_B_Buttons, emu.memType.cpu)
	drawString(1, 24, string.format(" :%03d", Frame), text_colour, text_back_colour)
	if emu.read(0xB, emu.memType.cgram) == 3 and emu.read(0xA, emu.memType.cgram) == 0x5F then
		drawString(1, 24, "F", 0xFFD600, 0xFF000000)
	elseif emu.read(0xB, emu.memType.cgram) == 3 and emu.read(0xA, emu.memType.cgram) == 0xFF then
		drawString(1, 24, "F", 0xFFFF00, 0xFF000000)
	else
		drawString(1, 24, "F", 0xFFFFFF, 0xFF000000)
	end
	
	drawString(1, 32, string.format("A:%03d", emu.read(User_Var_A, emu.memType.cpu)), text_colour, text_back_colour)
	
	drawString(1, 40, string.format("B:%03d", emu.read(User_Var_B, emu.memType.cpu)), text_colour, text_back_colour)
	
	if emu.read(wram_WarpZoneControl, emu.memType.cpu) ~= 0 or emu.read(wram_OperMode, emu.memType.cpu) == 0 then
		WZ_or_Title_Remainder = true
	elseif emu.read(wram_ScreenRoutineTask, emu.memType.cpu) == 12 or emu.read(wram_ScreenRoutineTask, emu.memType.cpu) == 13 then
		WZ_or_Title_Remainder = false
	end
	if emu.read(wram_StarFlagTaskControl, emu.memType.cpu) >= 4
	or emu.read(wram_OperMode, emu.memType.cpu) == 2
	or emu.read(wram_GameEngineSubroutine, emu.memType.cpu) == 2
	or emu.read(wram_GameEngineSubroutine, emu.memType.cpu) == 3
	or emu.read(wram_ScreenRoutineTask, emu.memType.cpu) >= 7 and emu.read(wram_ScreenRoutineTask, emu.memType.cpu) <= 9
	and emu.read(wram_DisableScreenFlag, emu.memType.cpu) == 0 and WZ_or_Title_Remainder then
		if RemainderDisplay == -1 then
			Frame = emu.read(wram_FrameCounter, emu.memType.cpu)
			RemainderDisplay = emu.read(wram_IntervalTimerControl, emu.memType.cpu)
		end
		drawString(1, 48, string.format("R:%02d", RemainderDisplay), text_colour, text_back_colour)
	else
		RemainderDisplay = -1
	end
	if emu.read(wram_OperMode_Task, emu.memType.cpu) == 6 then
		if RemainderDisplay2 == -1 then
			Frame = emu.read(wram_FrameCounter, emu.memType.cpu)
			RemainderDisplay2 = emu.read(wram_IntervalTimerControl, emu.memType.cpu)
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
	local RelX = emu.read(wram_Player_Rel_XPos, emu.memType.cpu)
	local xpos = (RelX > 0x70) and (RelX - 0x70) or 0
	
	--Read current world and level
	local world = emu.read(wram_WorldNumber, emu.memType.cpu)
	local level = emu.read(wram_LevelNumber, emu.memType.cpu)
	
	--Check if we have a predefined screen left for this world and level
	if ScreenLeft[world + 1] and ScreenLeft[world + 1][level + 1]
	and not (emu.read(wram_GameEngineSubroutine, emu.memType.cpu) == 4 or emu.read(wram_GameEngineSubroutine, emu.memType.cpu) == 5) then
		local LeftEdge = ScreenLeft[world + 1][level + 1]
		local PowerupX = emu.read(wram_SprObject_X_Position + 10, emu.memType.cpu)
		
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

emu.addEventCallback(display_practice_information, emu.eventType.endFrame)