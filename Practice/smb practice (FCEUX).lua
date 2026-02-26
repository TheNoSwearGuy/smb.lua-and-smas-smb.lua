--Thank you to @Simplistic for helping me fix the Frame counter display and for helping me with
--the X subpixel string, and thank you to @slither for helping me with the framerule counter
--Note: unless you're using Kaname for SMB1 (NTSC or PAL), SMB2J, or ANNSMB, the framerule counter only works with the following routes:
--• Start → Small → End
--• Start → Small → Mushroom → End
--• Start → Small → Mushroom → Fire → End
--The framerule counter desyncs when you soft reset with at least one lag frame before soft resetting after
--loading the ROM file, as soft resetting doesn't reset the lag frame counter. Hard resetting, however, does.

--Before running the script, you MUST set this variable to the region you're playing on — NTSC or PAL — in order for the framerule counter to be accurate and for
--the timer to use the right framerate. Kaname for SMB1 (NTSC and PAL), SMB2J, and ANNSMB is automatically detected and is prioritized over the regular games, so
--if you're using that, it doesn't matter what you have this variable set to. If you set this variable to a non-valid value, this will make the framerule counter
--and the timer default to you not playing on PAL.
local region = "NTSC" --Valid inputs: '"NTSC"' and '"PAL"'

--variables
local text_colour      = "white"
local text_back_colour = "#00000066"

--Kaname settings:
local User_Var_A = 0x3AD
local User_Var_B = 0x705

--all of the ram addresses I need
local ram_FrameCounter          = 9
local ram_A_B_Buttons           = 0xA
local ram_GameEngineSubroutine  = 0xE
local ram_Enemy_Flag            = 0xF
local ram_Enemy_ID              = 0x16
local ram_Player_State          = 0x1D
local ram_Player_X_Speed        = 0x57
local ram_SprObject_PageLoc     = 0x6D
local ram_SprObject_X_Position  = 0x86
local ram_SprObject_Y_Position  = 0xCE
local ram_Square1SoundQueue     = 0xFF
local ram_FloateyNum_Timer      = 0x12C
local ram_BowserOrigXPos        = 0x366
local ram_SprObject_X_MoveForce = 0x400
local ram_WarpZoneControl       = 0x6D6
local ram_JumpspringAnimCtrl    = 0x70E
local ram_ScreenRoutineTask     = 0x73C
local ram_StarFlagTaskControl   = 0x746
local ram_AltEntranceControl    = 0x752
local ram_PlayerStatus          = 0x756
local ram_OperMode              = 0x770
local ram_OperMode_Task         = 0x772
local ram_DisableScreenFlag     = 0x774
local ram_IntervalTimerControl  = 0x77F
local ram_JumpSwimTimer         = 0x782
local ram_CurrentRule           = 0x7DF --Kaname RAM address

--Practice information variables:
local framerule       = 0
local sock            = 0
local xstring         = 0
local xstringactual   = 0
local ypos            = 0
BowserFrame           = false
DontDisplaySock       = false
Frame                 = 0
FrameDisplay          = -1
FrameDisplay2         = -1
FrameDisplay3         = -1
PreviousA_B_Buttons   = 0
RemainderDisplay      = -1
RemainderDisplay2     = -1
RemainderDisplay3     = -1
Rule                  = 0
ScreenEnterDisplay    = 0
WZ_or_Title_Remainder = false

function display_practice_information() --Code to display practice information
	if memory.readbyte(0xFEFD) == 0xEA and memory.readbyte(0xFEFE) == 0xEA --Check if we're playing on Kaname
	and memory.readbyte(0xFEFF) == 0xEA and memory.readbyte(0xFF0B) == 0x4C
	and memory.readbyte(0xFF0D) == 0x84 and memory.readbyte(0xFF0E) == 0x4C
	and memory.readbyte(0xFF10) == 0x80 then
		Kaname_practice = true
	else
		Kaname_practice = false
	end
	
	if Kaname_practice then
		framerule = memory.readbyte(ram_CurrentRule) * 1000
			+ memory.readbyte(ram_CurrentRule + 1) * 100
			+ memory.readbyte(ram_CurrentRule + 2) * 10
			+ memory.readbyte(ram_CurrentRule + 3)
	else
		if region == "PAL" then
			if memory.readbyte(ram_PlayerStatus) == 0 then
				framerule = math.floor((emu.framecount() - emu.lagcount() - 1) / 18 + 1) % 10000
			elseif memory.readbyte(ram_PlayerStatus) == 1 then
				framerule = math.floor((emu.framecount() - emu.lagcount() - 60) / 18 + 1) % 10000
			else
				framerule = math.floor((emu.framecount() - emu.lagcount() - 123) / 18 + 1) % 10000
			end
		else
			if memory.readbyte(0xE141) == 0x38 and memory.readbyte(0xE142) == 0x44
			and memory.readbyte(0xE143) == 0xBA and memory.readbyte(0xE144) == 0xAA
			and memory.readbyte(0xE145) == 0xB2 and memory.readbyte(0xE146) == 0xAA
			and memory.readbyte(0xE147) == 0x44 and memory.readbyte(0xE148) == 0x38 then --If playing an FDS game
				x = 2
			else
				x = 1
			end
			
			if memory.readbyte(ram_PlayerStatus) == 0 then
				framerule = math.floor((emu.framecount() - emu.lagcount() - x) / 21 + 1) % 10000
			elseif memory.readbyte(ram_PlayerStatus) == 1 then
				framerule = math.floor((emu.framecount() - emu.lagcount() - x - 59) / 21 + 1) % 10000
			else
				framerule = math.floor((emu.framecount() - emu.lagcount() - x - 122) / 21 + 1) % 10000
			end
		end
	end
	
	if memory.readbyte(ram_Player_X_Speed) < 0x19 or memory.readbyte(ram_Player_X_Speed) > 0xE7 then
		y = 24
	else
		y = 40
	end
	local xstringvalue = bit.rshift((bit.lshift(memory.readbyte(ram_SprObject_PageLoc), 12)
		+ bit.lshift(memory.readbyte(ram_SprObject_X_Position), 4)
		+ bit.rshift(memory.readbyte(ram_SprObject_X_MoveForce), 4)) % y, 3)
	local sockvalue = bit.lshift(memory.readbyte(ram_SprObject_X_Position), 8)
		+ memory.readbyte(ram_SprObject_X_MoveForce)
		+ (bit.rshift(0xFF - memory.readbyte(ram_SprObject_Y_Position), 2) * 0x280)
	if AND(memory.readbyte(ram_IntervalTimerControl), 3) == 3 then
		xstringactual = xstringvalue
	end
	if AND(memory.readbyte(ram_IntervalTimerControl), 3) == 2 then
		xstring = xstringactual
		sock = AND(sockvalue, 0xFFF)
		ypos = AND(memory.readbyte(ram_SprObject_Y_Position), 3)
		DontDisplaySock = false
	end
	if memory.readbyte(ram_DisableScreenFlag) ~= 0 or memory.readbyte(ram_GameEngineSubroutine) == 0 or memory.readbyte(ram_AltEntranceControl) == 2 then
		DontDisplaySock = true
	end
	if DontDisplaySock then
		gui.text(1, 17, "S:0000-0", text_back_colour, text_back_colour)
		gui.text(1, 17, "S:", text_colour, "clear")
	else
		gui.text(1, 17, string.format("S:%d%03X-%d", xstring, sock, ypos), text_colour, text_back_colour)
	end
	
	for i = 0, 4, 1 do
		if memory.readbytesigned(ram_Enemy_Flag + i) > 0 and memory.readbyte(ram_Enemy_ID + i) == 0x2D
		and memory.readbyte(ram_SprObject_X_Position + i + 1) == memory.readbyte(ram_BowserOrigXPos) then
			BowserFrame = true
			break
		end
	end
	local EnemyFrame = false
	for j = 0, 5, 1 do
		if memory.readbyte(ram_FloateyNum_Timer + j) == 0x2A then
			EnemyFrame = true
			break
		end
	end
	if (memory.readbyte(ram_OperMode) == 0 and AND(memory.readbyte(ram_FrameCounter), 1) == 0)
	or memory.readbyte(ram_GameEngineSubroutine) == 7 then
		BowserFrame = false
		if FrameDisplay == -1 then
			FrameDisplay = memory.readbyte(ram_FrameCounter)
			Frame = memory.readbyte(ram_FrameCounter)
			Rule = framerule
		end
	elseif memory.readbyte(ram_JumpSwimTimer) == 0x20 or EnemyFrame or memory.readbyte(ram_Square1SoundQueue) == 0x20
	or (memory.readbyte(ram_Player_State) == 3 and (memory.readbyte(ram_GameEngineSubroutine) == 4
	or memory.readbyte(ram_GameEngineSubroutine) == 5 and memory.readbyte(ram_SprObject_Y_Position) >= 0xA2))
	or memory.readbyte(ram_StarFlagTaskControl) == 2 then
		BowserFrame = false
		if FrameDisplay == -1 then
			FrameDisplay = memory.readbyte(ram_FrameCounter)
			Frame = memory.readbyte(ram_FrameCounter)
		end
	elseif BowserFrame then
		for k = 0, 4, 1 do
			if memory.readbytesigned(ram_Enemy_Flag + k) > 0 and memory.readbyte(ram_Enemy_ID + k) == 0x2D
			and memory.readbyte(ram_SprObject_X_Position + k + 1) ~= memory.readbyte(ram_BowserOrigXPos)
			and AND(memory.readbyte(ram_FrameCounter), 3) == 0 then
				if FrameDisplay == -1 then
					FrameDisplay = memory.readbyte(ram_FrameCounter)
					Frame = memory.readbyte(ram_FrameCounter)
				end
				BowserFrame = false
				break
			end
		end
	else
		FrameDisplay = -1
	end
	if memory.readbyte(ram_GameEngineSubroutine) == 8 and memory.readbyte(ram_Player_State) ~= 3
	and memory.readbyte(ram_JumpspringAnimCtrl) == 0
	and AND(memory.readbyte(ram_A_B_Buttons), 0x80) == 0x80 and AND(PreviousA_B_Buttons, 0x80) == 0 then
		BowserFrame = false
		if FrameDisplay2 == -1 then
			FrameDisplay2 = memory.readbyte(ram_FrameCounter)
			Frame = memory.readbyte(ram_FrameCounter)
		end
	else
		FrameDisplay2 = -1
	end
	if memory.readbyte(ram_JumpspringAnimCtrl) - 1 >= 1
	and AND(memory.readbyte(ram_A_B_Buttons), 0x80) == 0x80 and AND(PreviousA_B_Buttons, 0x80) == 0 then
		BowserFrame = false
		if FrameDisplay3 == -1 then
			FrameDisplay3 = memory.readbyte(ram_FrameCounter)
			Frame = memory.readbyte(ram_FrameCounter)
		end
	else
		FrameDisplay3 = -1
	end
	PreviousA_B_Buttons = memory.readbyte(ram_A_B_Buttons)
	gui.text(1, 25, string.format(" :%03d", Frame), text_colour, text_back_colour)
	if ppu.readbyte(0x3F0D) == 7 then
		gui.text(1, 25, "F", "#7D0800", "clear")
	elseif ppu.readbyte(0x3F0D) == 0x17 then
		gui.text(1, 25, "F", "#CB4D0C", "clear")
	else
		gui.text(1, 25, "F", "#FF9A38", "clear")
	end
	
	gui.text(1, 33, string.format("A:%03d", memory.readbyte(User_Var_A)), text_colour, text_back_colour)
	
	gui.text(1, 41, string.format("B:%03d", memory.readbyte(User_Var_B)), text_colour, text_back_colour)
	
	if memory.readbyte(ram_WarpZoneControl) ~= 0 or memory.readbyte(ram_OperMode) == 0 then
		WZ_or_Title_Remainder = true
	elseif memory.readbyte(ram_ScreenRoutineTask) == 12 or memory.readbyte(ram_ScreenRoutineTask) == 13 then
		WZ_or_Title_Remainder = false
	end
	if memory.readbyte(ram_StarFlagTaskControl) >= 4
	or memory.readbyte(ram_OperMode) == 2
	or memory.readbyte(ram_GameEngineSubroutine) == 2
	or memory.readbyte(ram_GameEngineSubroutine) == 3
	or (memory.readbyte(ram_ScreenRoutineTask) == 7 or memory.readbyte(ram_ScreenRoutineTask) == 8)
	and memory.readbyte(ram_DisableScreenFlag) == 0 and WZ_or_Title_Remainder then
		if RemainderDisplay == -1 then
			Frame = memory.readbyte(ram_FrameCounter)
			RemainderDisplay = memory.readbyte(ram_IntervalTimerControl)
		end
		gui.text(1, 49, string.format("R:%02d", RemainderDisplay), text_colour, text_back_colour)
	else
		RemainderDisplay = -1
	end
	if memory.readbyte(ram_OperMode_Task) == 4 then
		if RemainderDisplay2 == -1 then
			Frame = memory.readbyte(ram_FrameCounter)
			RemainderDisplay2 = memory.readbyte(ram_IntervalTimerControl)
			RemainderDisplay = RemainderDisplay2
		end
	else
		RemainderDisplay2 = -1
	end
	if memory.readbyte(ram_OperMode_Task) == 5 then
		if RemainderDisplay3 == -1 then
			Frame = memory.readbyte(ram_FrameCounter)
			RemainderDisplay3 = memory.readbyte(ram_IntervalTimerControl)
			RemainderDisplay = RemainderDisplay3
		end
	else
		RemainderDisplay3 = -1
	end
	
	if memory.readbyte(ram_ScreenRoutineTask) == 4 then
		local chars = "0123456789ABCDEFGHIJK"
		Frame = memory.readbyte(ram_FrameCounter)
		Rule = framerule
		ScreenEnterDisplay = string.sub(chars, memory.readbyte(ram_IntervalTimerControl) + 1, memory.readbyte(ram_IntervalTimerControl) + 1)
	end
	gui.text(1, 9, string.format("R:%04d-%s", Rule, ScreenEnterDisplay), text_colour, text_back_colour)
end

emu.registerafter(display_practice_information)