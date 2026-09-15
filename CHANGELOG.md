# Changelog
## 2026-09-15
- Fixed the subpixel string to be compatible for both NTSC and PAL
- Added "Bowser HP" (only displayed when a Bowser has been loaded)
- Condensed the code for detecting Kaname, and fixed the code to properly detect Kaname 3.9, Kaname 3.8, Kaname 3.7, and Kaname 3.6 for the NES scripts
- Modified the framerule counter code for the NES scripts
- Made all the information only display when playing either SMAS: SMB1 or SMAS: SMB2J (except for the timer, which is always displayed) for the SNES scripts
- Modified the backwards pole code to be compatible for both SMAS: SMB1 and SMAS: SMB2J for the SNES scripts
- Minor changes, optimizations, and fixes

## 2026-03-09
- Fixed the timer on the Mesen, MesenRTA, Mesen-S, MesenRTA-S, Mesen 2, and Mesen2RTA scripts so when an end frame has been set, rewinding past it resets it
- Fixed a bug in the Mesen-S, MesenRTA-S, SNES Mesen 2, and SNES Mesen2RTA scripts so pressing Start during the fade in between game select and the title screen doesn't start the timer
- Fixes

## 2026-02-26
- Updated the practice information to work the same as on Kaname 3.8
- Compacted the frame counter code
- Fixed an error when updating the frame counter when Bowser loads for the SNES scripts
- Fixed the black screen remainder to only display in warp zones and when starting the game from the title screen
- Changed the name "SpeedAdder" to "Acceleration", and "XSA" and "YSA" to "XA" and "YA" respectively
- Modified the timer on the Mesen, MesenRTA, Mesen-S, MesenRTA-S, Mesen 2, and Mesen2RTA scripts to be configurable for starting, stopping, and resetting
- Added a "Practice" folder for versions with only the practice information
- Minor changes, optimizations, and fixes

## 2025-11-18
- Updated the practice information to work the same as on Kaname 3.6
- All versions of Pellsson are no longer automatically detected, and only Kaname is automatically detected for the NES scripts
- As a result of the previous two points, the `game` variable has been removed and replaced with the `region` variable for the NES scripts
- Made the colour of the "F" of the frame counter match the coin flash colour for the NES BizHawk scripts
- Added a variable to toggle displaying when collisions are being checked — either use one colour only or use two different colours for the fill
- Compacted the backwards pole code by a ton for the SNES scripts
- Minor changes, optimizations, and fixes
