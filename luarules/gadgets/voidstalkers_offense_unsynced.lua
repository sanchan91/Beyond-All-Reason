-- If there is no spoon, dont load Voidstalkers
if gadgetHandler:IsSyncedCode() then return false end
if not Spring.Utilities.Gametype.IsVoidstalkers() then return false end


------------------------------------
-- Gadget Info
-- Enables or Disables this gadget with the "enabled" field
-- "gadget" files get parsed twice
--  first for Synced code
--  second for UUnsynced code
--  technically this GetInfo exists twice, once for synced, next for unsynced
------------------------------------
function gadget:GetInfo()
	return {
		name    = "Voidstalkers AI unsynced",
		desc    = "Loads and runs the VoidBrain",
		author  = "Gilgamesh",
		date    = "2022",
		license = "GNU GPL, v2 or later",
		layer   = 9999,
		enabled = true,
	}
end


----------------------
-- Common uses for this part of the file
-- NO dynamic variables in this section unless you know what you are doing
-- 1. Check to see if this should even be loaded? (else return false here)
-- 2. gadget: functions that would be common to both SYNCED and UNSYNCED?
-- 3. utility functions that would be common to both SYNCED and UNSYNCED?
-- 4. STATIC variable declarations that do not change common to both SYNCED and UNSYNCED?

local function VoidEcho(...)
	Spring.Echo("VoidEcho: Unsynced",...)
end

----------------------
-- The lobby has to send paramaters to spring which includes some "Lua AI" information
-- To add the AI to the lobby and have it pass in the correct paramaters
-- the following is added to BYAR-Chobby.sdd and BAR.sdd so that IsVoidstalkers() works here
-- ALSO the launhcer has to be set to "Dev Lobby" in the config dropdown so that BYAR-Chobby.sdd is used
-- BYAR-Chobby.sdd
--     E LuaMenu\configs\gameConfig\byar\mainConfig.lua  
--     E LuaMenu\configs\gameConfig\byar\aiSimpleName.lua	
--     E LuaMenu\widgets\chobby\components\ai_list_window.lua
-- BAR.sdd
--     E luaai.lua
--     E common\springUtilities\teamFunctions.lua
--
--   *Units/Unitscripts/Models/Textures (New or Existing)
--     N objects3d\Voidstalkers\*
--     N units\Voidstalkers\*
--     N scripts\Voidstalkers\*
--     N unittextures\<list files>
-- 	   N effects\Voidstalkers\shadowsmoke.lua
--	   N effects\Voidstalkers\archonsmoke.lua
--
--   *UI related: (New or Existing)
--     N luaui\Widgets\gui_voidstalkers_info.lua <-- this is like the scav information panel that pops up when you run scavs for the first time
--     N luaui\Widgets\gui_voidstalkersStatsPanel.lua <-- this is like the scav/chickens panel in the upper right that shows stats    
--     E luaui\Widgets\gui_top_bar.lua
--     E language\en\interface.json  <-- translation for the button at the top for "Voidstalkers"
--     N language\en\voidstalkers.json   <---- might not exist yet
--     N gamedata\Voidstalkers\* 
--
--   *Voidstate/Archon Saving related:
--     N luaui\Widgets\cmd_voidstalkers_actions.lua     




-- Got here, must have done something right...unless the rest of the code fails... Blame Damgam
VoidEcho("Voidstalkers unsynced is online!")


-----
-- TESTING STUFF
local arm_peewee = {type = 0,  action = "buildunit_armpw", id = -UnitDefNames["armpw"].id, tooltip = "This is a custom tooltip", cursor = "armpw", showUnique = true, params = {1}, name = "armpw", onlyTexture = true, disabled = false, hidden = false, queueing = false, texture = "" }
	

----------------
-- UNSYNCED LOGIC


----------------
-- UNSYNCED CALLINS

-- GAME STARTUP AND END
function gadget:Initialize() end
function gadget:GamePreload() end
function gadget:GameStart() end
function gadget:GameOver() end

-- GAME MAIN LOOP
function gadget:GameFrame(n) end
	


