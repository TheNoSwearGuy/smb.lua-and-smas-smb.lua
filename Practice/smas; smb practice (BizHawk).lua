--Thank you to @Simplistic for helping me fix the Frame counter display and for helping me with the X subpixel string
--Note: the "Backwards Pole?" feature isn't entirely accurate, but it's like 95% accurate

--Before running the script, you MUST set this variable to the region you're playing on — NTSC or PAL — in order for the timer to use
--the right framerate. If you set this variable to a non-valid value, this will make the timer default to you not playing on PAL.
local region = "NTSC" --Valid inputs: '"NTSC"' and '"PAL"'

--variables
local text_colour      = "white"
local text_back_colour = "#66000000"

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

while true do --Code to display practice information
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
	if DontDisplaySock then
		gui.pixelText(0, 8, "S:      ", text_colour, text_back_colour, "fceux")
	else
		gui.pixelText(0, 8, string.format("S:%d%03X-%d", xstring, sock, ypos), text_colour, text_back_colour, "fceux")
	end
	
	if memory.readbyte(wram_ScreenRoutineTask) == 4 then
		local chars = "0123456789ABCDEFGHIJK"
		Frame = memory.readbyte(wram_FrameCounter)
		ScreenEnterDisplay = string.sub(chars, memory.readbyte(wram_IntervalTimerControl) + 1, memory.readbyte(wram_IntervalTimerControl) + 1)
	end
	gui.pixelText(36, 0, string.format("-%s", ScreenEnterDisplay), text_colour, text_back_colour, "fceux")
	
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
	gui.pixelText(0, 16, string.format(" :%03d", Frame), text_colour, text_back_colour, "fceux")
	memory.usememorydomain("CGRAM")
	if memory.readbyte(0xB) == 3 and memory.readbyte(0xA) == 0x5F then
		gui.pixelText(0, 16, "F", "#FFD600", "clear", "fceux")
	elseif memory.readbyte(0xB) == 3 and memory.readbyte(0xA) == 0xFF then
		gui.pixelText(0, 16, "F", "#FFFF00", "clear", "fceux")
	else
		gui.pixelText(0, 16, "F", "#FFFFFF", "clear", "fceux")
	end
	memory.usememorydomain("System Bus")
	
	gui.pixelText(0, 24, string.format("A:%03d", memory.readbyte(User_Var_A)), text_colour, text_back_colour, "fceux")
	
	gui.pixelText(0, 32, string.format("B:%03d", memory.readbyte(User_Var_B)), text_colour, text_back_colour, "fceux")
	
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
		gui.pixelText(0, 40, string.format("R:%02d", RemainderDisplay), text_colour, text_back_colour, "fceux")
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
	gui.pixelText(0, 48, "Backwards ", text_colour, text_back_colour, "fceux")
	gui.pixelText(0, 56, "Pole?: "..(BackwardsPole and "Yes" or "No "), text_colour, text_back_colour, "fceux")
	emu.frameadvance()
end