
------------------------------------
-- Gadget Info
-- Enables or Disables this gadget with the "enabled" field
------------------------------------
function gadget:GetInfo()
	return {
		name    = "Loader for VoidstalkersAI",
		desc    = "Loads and runs the VoidBrain",
		author  = "Gilgamesh",
		date    = "2022",
		license = "GNU GPL, v2 or later",
		layer   = 0,
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
	Spring.Echo("VoidEcho: Gadget",...)
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


-- If there is no spoon, dont load Voidstalkers
if not Spring.Utilities.Gametype.IsVoidstalkers() then return false end

-- Got here, must have done something right...unless the rest of the code fails... Blame Damgam
VoidEcho("Voidstalkers are Online!")



------------------------------------
-- SYNCED
-- Simulation (execute simulation)
--
if gadgetHandler:IsSyncedCode() then
------------------------------------

	
	-------------------------
	-- Utilities
	
	local utilities = {}
	
	utilities.GetAllNonStartUnitsForTeam = function(team) end
	-------------------------
	-- Systems

	local systems = {}

	systems.TestSystemsMessage = function() VoidEcho("TestSystemsMessage") end
	-------------------------
	-- Events

	local events = {}
	
	events.Initialize = function()
		VoidEcho("Sync Initialize...")
		--local info = VFS.Include("/Saves/20221105_012731.lua")
		--Spring.Deubg.TableEcho(info)
		-- Setup randomize/setup variables for terrain,objective, events, base placement, unit spawns?
		-- Setup teams such that humans/AIs are on the same "light" 
		-- Steup teams such that Voidstalkers are on the same "dark" AllyTeam 
		-- Setup allianes such that Gaia -> team and team -> Gaia to all teams under the "light" AllyTeam
		--
	end

	events.GamePreload = function() 
		VoidEcho("GamePreload...")
		--local voidstate = Spring.GetGameRulesParam('voidstateSave_player0')
		--VoidEcho("voidstate ="..voidstate)
		-- Change the terrain
		-- Spawn in the base
		-- Spawn in the base defenses
		-- Spawn in enemies across the field
		-- Spawn in gaia across the field
		-- Spawn in wrecks across the field
		-- Spawn in Voidtech
		-- Spawn in Voidcrystalks
		-- Spawn in Voidartifacts
	end
	
	events.GameStart = function()
		-- Not sure yet	
	end

	events.GameOver = function()
		
	end

	events.Shutdown = function()
		
	end

	-----------------------------
	-- Communications
	
	communicationLoadVoidState = function(inPlayerID, inPayload)
		VoidEcho("communicationLoadVoidState")
		VoidEcho(inPlayerID, inPayload)
		local tempVoidState = Json.decode(inPayload)
		Spring.Debug.TableEcho(tempVoidState)
	end

	local recvLuaMsgFunctions = {}
	recvLuaMsgFunctions["voidstalkers voidstate"] = communicationLoadVoidState
	
	events.RecvLuaMsg = function(_,inMsg, inPlayerID)
		
		VoidEcho("lua msg comms = "..inMsg.. " / "..inPlayerID)

		local recvLuaMsgText,recvLuaMsgArgs = string.match(inMsg,"^(%a+ %a+) (.*)$")

		local recvLuaMsgFunction = recvLuaMsgFunctions[recvLuaMsgText]

		VoidEcho(recvLuaMsgText,recvLuaMsgArgs,recvLuaMsgFunction)
		--Check if this command is registered
		if not recvLuaMsgFunction then return end

		--Call the function
		recvLuaMsgFunction(inPlayerID, recvLuaMsgArgs)
		
	end
	------------------------------
	-- Main Loop
	local mainLoopEvents = {}

	local mainLoopRepeatingEvents = {}
	mainLoopRepeatingEvents[30] = {systems.TestSystemsMessage}
	mainLoopRepeatingEvents[60] = {systems.TestSystemsMessage,systems.TestSystemsMessage}
	mainLoopRepeatingEvents[90] = {systems.TestSystemsMessage,systems.TestSystemsMessage,systems.TestSystemsMessage}
	--mainLoopRepeatingEvents[90] = function() VoidState(90) end
	 
	local loopedFrame = 0
	events.GameFrame = function(_,frame)
		loopedFrame = frame % 1800 -- the frames loop every minute

		--check if repeating events has functions to call and add them to the end of the main loop events
		if mainLoopRepeatingEvents[loopedFrame] then 
			for i=1, #mainLoopRepeatingEvents[loopedFrame] do
					table.insert(mainLoopEvents,mainLoopRepeatingEvents[loopedFrame][i])
			end
		end

		--check if we have any events to run
		if not mainLoopEvents then return end

		--loop over the events
		for i=1, #mainLoopEvents do	mainLoopEvents[i]() end
		
		--Clear the main loop events
		 mainLoopEvents = {}
		--VoidEcho("Gameframe ",frame)		
	end

	---------------
	-- SYNCED CALLINS
	--

	-- GAME STARTUP AND END
	gadget.Initialize = events.Initialize
	gadget.GamePreload = events.GamePreload 
	gadget.GameStart = events.GameStart
	gadget.GameOver = events.GameOver
	gadget.Shutdown = events.Shutdown
	
	-- COMMUNICATIONS
	gadget.RecvLuaMsg = events.RecvLuaMsg

	-- GAME MAIN LOOP
	gadget.GameFrame = events.GameFrame

	-- UNITS
	function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID) end
	function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, projectileID, attackerID, attackerDefID, attackerTeam) end
	function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, projectileID, attackerID, attackerDefID, attackerTeam) end
	function gadget:UnitFromFactory(unitID, unitDefID, unitTeam, factID, factDefID, userOrders) end
	function gadget:UnitFinished(unitID, unitDefID, unitTeam) end
	function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID) end
	function gadget:UnitTaken(unitID, unitDefID, oldTeam, newTeam) end
	function gadget:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, capture) end

	
	-- FEATURES
	function gadget:FeatureCreated(featureID, allyTeam) end

	-- COMMANDS
	function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions, cmdTag, playerID, fromSynced, fromLua) return true	end
	function gadget:UnitCommand(unitID, unitDefID, unitTeamID, cmdID, cmdParams, cmdOptions, cmdTag, playerID, fromSynced, fromLua) end
	function gadget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag) end

	-- TEAMS
	function gadget:TeamDied(teamID) end 	

------------------------------------
-- UNSYNCED
-- Viewport (players view into the simulation rendered client side)
else    
------------------------------------

	----------------
	-- UNSYNCED LOGIC

	-------------------------
	-- Events

	local events = {}

	events.Initialize = function() 	end

	----------------
	-- UNSYNCED CALLINS
	
	-- GAME STARTUP AND END
	gadget.Initialize = events.Initialize
	function gadget:GamePreload() end
	function gadget:GameStart() end
	function gadget:GameOver() end

	-- GAME MAIN LOOP
	function gadget:GameFrame(n) end
	


------------------------------------
-- DONE
end
------------------------------------	