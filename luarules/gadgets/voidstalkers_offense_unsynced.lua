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
	
------
-- Variables

local vars = {}
vars.atmosphereState = {}


----------------
-- UNSYNCED LOGIC

local function GetLightingAndAtmosphere()  -- from map_atmosphere_cegs.lua - returns a table of the common parameters
	local res =  {
		lighting = {
			groundAmbientColor =  {gl.GetSun("ambient")},
			groundDiffuseColor =  {gl.GetSun("diffuse")},
			groundSpecularColor =  {gl.GetSun("specular")},
			
			unitAmbientColor =  {gl.GetSun("ambient","unit")},
			unitDiffuseColor =  {gl.GetSun("diffuse","unit")},
			unitSpecularColor =  {gl.GetSun("specular","unit")},
			
			groundShadowDensity = gl.GetSun("shadowDensity"),
			modelShadowDensity = gl.GetSun("shadowDensity","unit"),
		},
		atmosphere = {
			skyColor = {gl.GetAtmosphere("skyColor")},
			sunColor = {gl.GetAtmosphere("sunColor")},
			cloudColor = {gl.GetAtmosphere("cloudColor")},
			fogColor = {gl.GetAtmosphere("fogColor")},
			fogStart = gl.GetAtmosphere("fogStart"),
			fogEnd = gl.GetAtmosphere("fogEnd"),
		},
		sunDir = {gl.GetSun("pos")},
	}
	return res
end

local function GetStartingLightingAndAtmosphere()

	return table.copy(vars.atmosphereState.starting)
end


function VoidSetDarkFromHaunt(_)
	
	VoidEcho("VoidSetDarkFromHaunt")
	--local atmosphere_object = GetLightingAndAtmosphere()
	local atmosphere_object = GetStartingLightingAndAtmosphere()
	--atmosphere_object.atmosphere = {}
	--atmosphere_object.lighting = {}

	--atmosphere_object.sunDir = {0,-1,0}

	atmosphere_object.atmosphere.skyColor = {0,0,0}		
	atmosphere_object.atmosphere.sunColor = {0,0,0}
	atmosphere_object.atmosphere.cloudColor = {0,0,0}
	atmosphere_object.atmosphere.fogColor = {0,0,0}
	atmosphere_object.atmosphere.fogStart = 1
	atmosphere_object.atmosphere.fogEnd = 1.2

	atmosphere_object.lighting.groundAmbientColor = {0.2,0.2,0.2}
	atmosphere_object.lighting.groundDiffuseColor = {0.2,0.2,0.2}
	atmosphere_object.lighting.groundSpecularColor = {0.2,0.2,0.2}
	atmosphere_object.lighting.unitAmbientColor = {0.2,0.2,0.2}
	atmosphere_object.lighting.unitDiffuseColor = {0.2,0.2,0.2}
	atmosphere_object.lighting.unitSpecularColor = {0.2,0.2,0.2}
	atmosphere_object.lighting.groundShadowDensity = 0.89999998
	atmosphere_object.lighting.modelShadowDensity = 0.89999998

	Spring.Debug.TableEcho(atmosphere_object)
	

	--[[

	atmosphere_object.sunDir = {-0.7534609,0.55060601,-0.3593429}
	
	--atmosphere_object.atmosphere.skyColor = {0.42879999,0.58016002,0.63999999}
	atmosphere_object.atmosphere.sunColor = {1,0.92000002,0.77999997}
	--atmosphere_object.atmosphere.cloudColor = {0.89999998,0.89999998,0.89999998}
	--atmosphere_object.atmosphere.fogColor = {0.80000001,0.80000001,0.5}
	atmosphere_object.atmosphere.fogStart = 1
	atmosphere_object.atmosphere.fogEnd = 1.2

	--atmosphere_object.lighting.groundAmbientColor = {0.51999998,0.50959998,0.50959998}
	atmosphere_object.lighting.groundDiffuseColor = {1,1,1}
	atmosphere_object.lighting.groundSpecularColor = {0.60000002,0.5,0.5}
	--atmosphere_object.lighting.unitAmbientColor = {0.51999998,0.50959998,0.50959998}
	atmosphere_object.lighting.unitDiffuseColor = {1,0.98533332,0.92000002}
	atmosphere_object.lighting.unitSpecularColor = {0.80000001,0.60000002,0.60000002}
	atmosphere_object.lighting.groundShadowDensity = 0.89999998
	atmosphere_object.lighting.modelShadowDensity = 0.89999998


	--SendToUnsynced("SetLightingAndAtmosphere",atmosphere_object)
	]]
	Spring.SetAtmosphere(atmosphere_object.atmosphere) 
	Spring.SetSunLighting(atmosphere_object.lighting)
	Spring.SetSunDirection(atmosphere_object.sunDir[1], atmosphere_object.sunDir[2], atmosphere_object.sunDir[3] )

end

function VoidSetLightFromHauntFinish(_)
	VoidEcho("VoidSetLightFromHauntFinish ")

	local atmosphere_object = GetStartingLightingAndAtmosphere()

	Spring.Debug.TableEcho(atmosphere_object)
	

	Spring.SetAtmosphere(atmosphere_object.atmosphere) 
	Spring.SetSunLighting(atmosphere_object.lighting)
	Spring.SetSunDirection(atmosphere_object.sunDir[1], atmosphere_object.sunDir[2], atmosphere_object.sunDir[3] )
	VoidEcho("VoidSetLightFromHauntFinish done!")
end
----------------
-- UNSYNCED CALLINS

function HandleSaveStartingAtmosphere()
	VoidEcho("saving atmosphere starting values")
	vars.atmosphereState.starting = GetLightingAndAtmosphere()

	Spring.Debug.TableEcho(vars.atmosphereState.starting)

end

function HandleAddSyncActions()
	gadgetHandler:AddSyncAction("VoidSetDarkFromHaunt", VoidSetDarkFromHaunt)
	gadgetHandler:AddSyncAction("VoidSetLightFromHauntFinish", VoidSetLightFromHauntFinish)
end

function HandleRemoveSyncActions()
	gadgetHandler:RemoveSyncAction("VoidSetDarkFromHaunt")
	gadgetHandler:RemoveSyncAction("VoidSetLightFromHauntFinish")
end

-- GAME STARTUP AND END
function gadget:Initialize()
	HandleSaveStartingAtmosphere()
	HandleAddSyncActions()
	
end

function gadget:Shutdown()
	HandleRemoveSyncActions()
end

function gadget:GamePreload() end

function gadget:GameStart() end

function gadget:GameOver() end

-- GAME MAIN LOOP
function gadget:GameFrame(n) end
	


