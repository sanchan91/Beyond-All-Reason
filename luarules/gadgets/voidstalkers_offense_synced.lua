-- If there is no spoon, dont load Voidstalkers
if not gadgetHandler:IsSyncedCode() then return false end
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
		name    = "Voidstalkers AI Synced",
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
	Spring.Echo("VoidEcho: Synced",...)
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
VoidEcho("Voidstalkers synced is online!")


-----
-- TESTING STUFF
local arm_peewee = {type = 0,  action = "buildunit_armpw", id = -UnitDefNames["armpw"].id, tooltip = "This is a custom tooltip", cursor = "armpw", showUnique = true, params = {1}, name = "armpw", onlyTexture = true, disabled = false, hidden = false, queueing = false, texture = "" }


--changing this also requires changing it in vmd_voidstalkers_actions.lua (the widget)
local function GetBlankVoidState()
	return {
		archonAbilities = "",
		archonSummons = "",
		archonAbilitiesLevels = "",
		archonSummonsLevels = "",
		archonExp = "0",
		archonLevel = "1",
		voidLevel = "1"
	}
end



-------------------------
-- Variables
local vars = {}

vars.teamArchonUnitIds = {}
vars.teamCommanderUnitIds = {}

-- Have to populate the summon pools manually, no good way to loop over all UnitDefs and go through arm/cor/leg real buildable units
-- and before you think about starting at a commander and sniffing out everything it and construction/factories can build
-- ... remember that a mod option can turn on experimental scav units
-- ... unless I come up with another way some day
vars.archonRewardPools = {}
vars.voidState = {}

-- Main Loop
--vars.mainLoopScope = 30 * 60 -- 30 frames is one second, 60 seconds is one minute

--vars.mainLoopEvents = {}

--vars.mainLoopTimedEvents = {}

--vars.mainLoopRepeatingEvents = {}
--vars.mainLoopRepeatingEvents[30] = {systems.TestSystemsMessage}
--vars.mainLoopRepeatingEvents[60] = {systems.TestSystemsMessage,systems.TestSystemsMessage}
--vars.mainLoopRepeatingEvents[90] = {systems.TestSystemsMessage,systems.TestSystemsMessage,systems.TestSystemsMessage}
--mainLoopRepeatingEvents[90] = function() VoidState(90) end


-------------------------
-- Utilities

local utilities = {}

utilities.GetAllNonStartUnitsForTeam = function(team) end

utilities.SetupArchonPools = function() 

	--Yes, unless something changes, these could just be set at variable declaration, but I wanted to keep this function unless
	--something else changed my mind
	vars.archonRewardPools["bronze"] = {"armpw","armwar"}
	vars.archonRewardPools["silver"] = {"armmanni","armbull"}
	vars.archonRewardPools["gold"] = {"armraz","armvang","armbanth","armthor","armlun","armmar"}
	vars.archonRewardPools["platinum"] = {"armpwt4","cordemont4"}
	vars.archonRewardPools["diamond"] = {"armpwt4","cordemont4"}
	
end
-------------------------
-- "Archon Abilities" - these are actually just systems but named so I can remember that they link to a thing
-- before getting too existed, the ability names are actually unit names that get InsertUnitCmdDesc to the archon
-- the gui build menu thinks these are units the archon can "build" but since these do not explicitly exist in the buidOptions of the archon
-- clicking on one of these to "build" does nothing in the engine
-- however, I can trap for the UnitDefID passed to UnitCommand and get the UnitDefID[id].name out of it to link into the abilities table
-- and call the corresponding function as if something happened

local abilityDesc = {type = 0,  action = "buildunit_armpw", id = -UnitDefNames["armpw"].id, tooltip = "", cursor = "", showUnique = true, params = {1}, name = "armpw", onlyTexture = true, disabled = false, hidden = false, queueing = false, texture = "" }


local abilities = {}

abilities["voidstalker_ability_b1"] = function(inUnitTeamId) 
	-- spawn 10 armpw
	local posx,posy,posz = Spring.GetUnitPosition( vars.teamArchonUnitIds[inUnitTeamId] )
	for i = 1, 10 do
		Spring.CreateUnit("armpw", posx+math.random(-100,100), posy, posz+math.random(-100,100), 0, inUnitTeamId)
	end
end

abilities["voidstalker_ability_b2"] = function(inUnitTeamId) 
	local posx,posy,posz = Spring.GetUnitPosition( vars.teamArchonUnitIds[inUnitTeamId] )
	Spring.CreateUnit("armwar", posx, posy, posz, 0, inUnitTeamId)
end
abilities["voidstalker_ability_b3"] = function(inUnitTeamId) end
abilities["voidstalker_ability_t1"] = function(inUnitTeamId) end
abilities["voidstalker_ability_t2"] = function(inUnitTeamId) end
abilities["voidstalker_ability_t3"] = function(inUnitTeamId) end
abilities["voidstalker_ability_h1"] = function(inUnitTeamId) end
abilities["voidstalker_ability_h2"] = function(inUnitTeamId) end
abilities["voidstalker_ability_h3"] = function(inUnitTeamId) end

abilities.GiveArchonAbility = function(inTeamId,inAbilityName)
	VoidEcho("Granting archon ability to player ",inTeamId, inAbilityName)
	
	local archonUnitId = vars.teamArchonUnitIds[inTeamId]
	local tempCmdDescIndex = Spring.FindUnitCmdDesc(archonUnitId, -UnitDefNames[inAbilityName].id)
	
	-- If the ability already exists, add to it
	if tempCmdDescIndex then
		local tempCmdDesc = Spring.GetUnitCmdDescs(archonUnitId, tempCmdDescIndex,tempCmdDescIndex)[1]
		Spring.Debug.TableEcho(tempCmdDesc)

		Spring.EditUnitCmdDesc(archonUnitId,tempCmdDescIndex,{ params = { tonumber(tempCmdDesc.params[1]) + 1 }, disabled = abilityDisabled })

	else
	-- if it doesnt exit, then insert it
		Spring.InsertUnitCmdDesc(vars.teamArchonUnitIds[inTeamId] ,-UnitDefNames[inAbilityName].id,{id = -UnitDefNames[inAbilityName].id, params = {1},action = "buildunit_XXXXX" } )
	end
end

abilities.CallArchonAbility = function(inAbilityName,inUnitTeamId)
	-- responsible for managing ability counts and calling the ability

	-- at this time, the gui_buildmenu does not have a way to "force" the icon display to be disabled, the disabled flag will actually hide the icon (there is a .hidden param but it doesnt do anything)
	-- so we must manually check if there are any charges left on the ability

	
	
	-- get the number of charges from param
	local archonUnitId = vars.teamArchonUnitIds[inUnitTeamId]
	local tempCmdDescIndex = Spring.FindUnitCmdDesc(archonUnitId, -UnitDefNames[inAbilityName].id)
	local tempCmdDesc = Spring.GetUnitCmdDescs(archonUnitId, tempCmdDescIndex,tempCmdDescIndex)[1]
	Spring.Debug.TableEcho(tempCmdDesc)

	-- check if there are charges left
	if not tonumber(tempCmdDesc.params[1]) then return end

	VoidEcho("Calling ability for team",inAbilityName, inUnitTeamId)
	
	-- use and decrease then optionally disable the ability if it has no more charges
	abilities[inAbilityName](inUnitTeamId)

	local newAbilityUseCount = (tonumber(tempCmdDesc.params[1]) or 0) - 1

	if newAbilityUseCount <= 0 then newAbilityUseCount = "-" end

	Spring.EditUnitCmdDesc(archonUnitId,tempCmdDescIndex,{ params = { newAbilityUseCount } })



	--  decrease by 1, but if 0 , set it to disabled

end


-------------------------
-- Missions

local missions = {}

missions["destroy"] = {}

missions["destroy"].name = "destroy"
missions["destroy"].progressMission = function() VoidEcho("progressMission") end
missions["destroy"].isComplete = function() end
missions["destroy"].checkCompletion = function() end

missions.current = missions["destroy"]

missions.current.progressMission()

function populateDestroyMission()
	return {
		name = "destroy",
		progressMission = function() VoidEcho("progressMission 2") end,
		isComplete = function() end,
	}
end
missions["destroy"] = populateDestroyMission()
missions["destroy"].progressMission()

function populateDestroyMission(inMissionTable) 

	local one = 1

	inMissionTable.name = "destroy"
	inMissionTable.progressMission = function() VoidEcho("progressMission 3",one) end
	inMissionTable.isComplete = function() end
	inMissionTable.checkCompletion = function() end
	inMissionTable.addOne = function() one = one + 1 end
	inMissionTable.printOne = function() VoidEcho("printOne",one) end

	function inMissionTable:testPrint()
			VoidEcho("testPrint",one)
	end

end

populateDestroyMission(missions["destroy"])

missions["destroy"].progressMission()
missions["destroy"].addOne()
missions["destroy"].printOne()
missions["destroy"].testPrint()


function returnDestroyMission() 

	local one = 1

	local name = "destroy"
	local progressMission = function() VoidEcho("progressMission 3",one) end
	local isComplete = function() end
	local checkCompletion = function() end
	local addOne = function() one = one + 1 end
	local printOne = function() VoidEcho("printOne",one) end

	function testPrint()
			VoidEcho("testPrint",one)
	end

	return {
		name = name,
		progressMission = progressMission,
		isComplete = isComplete,
		checkCompletion = checkCompletion,
		addOne = addOne,
		printOne = printOne,
		testPrint = testPrint,
	}

end

missions["destroy"] = returnDestroyMission()
missions["destroy"].testPrint()

missions = {}

function createDestroyMission() 

	local one = 1
	
	missions["destroy"] = {}

	missions["destroy"].name = "destroy"
	missions["destroy"].progressMission = function() VoidEcho("progressMission 3",one) end
	missions["destroy"].isComplete = function() end
	missions["destroy"].checkCompletion = function() end
	missions["destroy"].addOne = function() one = one + 1 end
	missions["destroy"].printOne = function() VoidEcho("printOne",one) end

	

end

createDestroyMission()
missions["destroy"].addOne()
missions["destroy"].printOne()






-------------------------
-- Systems

local systems = {}

systems.TestSystemsMessage = function() VoidEcho("TestSystemsMessage") end

systems.SpawnCommanderArchons = function()
	VoidEcho("Spawning commander archons!")

	-- Find all of the commanders across all teams, and give them an archon.
	local units = Spring.GetAllUnits()
	for i = 1, #units do
		if UnitDefs[ Spring.GetUnitDefID(units[i]) ].customParams.iscommander then
			local commanderUnitId = units[i]
			local teamId = Spring.GetUnitTeam(commanderUnitId)
			local commanderUnitTeam = Spring.GetUnitTeam(commanderUnitId)
			local posx, posy, posz = Spring.GetUnitPosition(commanderUnitId)
			local archonUnitId = Spring.CreateUnit("voidstalker_com_archon", posx+math.random(-30,30), posy+50, posz+math.random(-30,39), 0, commanderUnitTeam)
			
			vars.teamArchonUnitIds[teamId] = archonUnitId
			vars.teamCommanderUnitIds[teamId] = commanderUnitId
			
			Spring.GiveOrderToUnit(archonUnitId ,CMD.GUARD,commanderUnitId, {})
			Spring.GiveOrderToUnit(archonUnitId ,CMD.IDLEMODE, { 0 }, { "shift" })
			Spring.GiveOrderToUnit(archonUnitId ,CMD.MOVE_STATE,{0},0)
			
			--Remove all commands the Archon has so that it is glued to the commander
			local archonCommandsArray = Spring.GetUnitCmdDescs(archonUnitId)
			for i = 1, #archonCommandsArray do
				VoidEcho("Removing archon commands ",archonCommandsArray[i].id)
				Spring.RemoveUnitCmdDesc(archonUnitId , Spring.FindUnitCmdDesc(archonUnitId, archonCommandsArray[i].id))
			end
			--Remmove the players ability to give it orders that would break it away from guarding the commander
			--Spring.RemoveUnitCmdDesc(archonUnitId , Spring.FindUnitCmdDesc(archonUnitId, CMD.MOVE))
			--Spring.RemoveUnitCmdDesc(archonUnitId , Spring.FindUnitCmdDesc(archonUnitId, CMD.GUARD))
			--Spring.RemoveUnitCmdDesc(archonUnitId , Spring.FindUnitCmdDesc(archonUnitId, CMD.REPAIR))
			--Spring.RemoveUnitCmdDesc(archonUnitId , Spring.FindUnitCmdDesc(archonUnitId, CMD.ATTACK))
			--Spring.RemoveUnitCmdDesc(archonUnitId , Spring.FindUnitCmdDesc(archonUnitId, CMD.RECLAIM))
			--Spring.RemoveUnitCmdDesc(archonUnitId , Spring.FindUnitCmdDesc(archonUnitId, CMD.STOP))
			--Spring.RemoveUnitCmdDesc(archonUnitId , Spring.FindUnitCmdDesc(archonUnitId, CMD.WAIT))
			--Spring.RemoveUnitCmdDesc(archonUnitId , Spring.FindUnitCmdDesc(archonUnitId, CMD.RESTORE))
			--Spring.RemoveUnitCmdDesc(archonUnitId , Spring.FindUnitCmdDesc(archonUnitId, CMD.FIGHT))
			--Spring.RemoveUnitCmdDesc(archonUnitId , Spring.FindUnitCmdDesc(archonUnitId, CMD.PATROL))
			

			--give it starting "abilities"
			abilities.GiveArchonAbility(teamId,"voidstalker_ability_b1")
			abilities.GiveArchonAbility(teamId,"voidstalker_ability_b1")
			abilities.GiveArchonAbility(teamId,"voidstalker_ability_b1")
			abilities.GiveArchonAbility(teamId,"voidstalker_ability_b1")
			abilities.GiveArchonAbility(teamId,"voidstalker_ability_b2")
			abilities.GiveArchonAbility(teamId,"voidstalker_ability_b2")
			abilities.GiveArchonAbility(teamId,"voidstalker_ability_b2")
			abilities.GiveArchonAbility(teamId,"voidstalker_ability_b2")
			--Spring.InsertUnitCmdDesc(archonUnitId ,arm_peewee.id,arm_peewee )

		end
	end
end



systems.AddTimedEvent = function(inFrameTime,inEventFunction) 
	local repeatFrame = (Spring.GetGameFrame() + inFrameTime) % vars.mainLoopScope
	VoidEcho("Adding timed event at frame",repeatFrame)
	--check if this timed frame spot exists, if not, make it
	if not vars.mainLoopTimedEvents[repeatFrame] then vars.mainLoopTimedEvents[repeatFrame] = {} end
	
	--insert the event into the timed event queue
	table.insert(mainLoopTimedEvents[repeatFrame] , inEventFunction)
end



---------------
-- SYNCED CALLINS
--

-- GAME STARTUP AND END

function gadget:Initialize()
	VoidEcho("Sync Initialize...")
	-- Setup pools for archons summons/abilities
	utilities.SetupArchonPools()

	-- Turn off exp gain (if possible)
	--Spring.SetExperienceGrade(0)

	-- Setup randomize/setup variables for terrain,objective, events, base placement, unit spawns?
	-- Setup teams such that humans/AIs are on the same "light" 
	-- Steup teams such that Voidstalkers are on the same "dark" AllyTeam 
	-- Setup allianes such that Gaia -> team and team -> Gaia to all teams under the "light" AllyTeam
	--
end

function gadget:GamePreload()
	VoidEcho("GamePreload...")
	-- Spawn in commander archons (timed event)
	--systems.AddTimedEvent(90,systems.SpawnCommanderArchons)



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

function gadget:GameStart()
	systems.SpawnCommanderArchons()
end

function gadget:GameOver()
end

function gadget:Shutdown()

end


-- COMMUNICATIONS

local communicationLoadVoidState = function(inPlayerID, inPayload)
	VoidEcho("communicationLoadVoidState")
	VoidEcho(inPlayerID, inPayload)
	local tempVoidState = Json.decode(inPayload)
	Spring.Debug.TableEcho(tempVoidState)
end

local recvLuaMsgFunctions = {}
recvLuaMsgFunctions["voidstalkers voidstate"] = communicationLoadVoidState

function gadget:RecvLuaMsg (inMsg, inPlayerID)
	
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
-- GAME MAIN LOOP


-- once upon a time....
--[[	
local loopedFrame = 0
function gadget:GameFrame(frame)
	loopedFrame = frame % vars.mainLoopScope 

	--check if there are one time "timed" events which are cleared after they are used
	if vars.mainLoopTimedEvents[loopedFrame] then 
		for i=1, #vars.mainLoopTimedEvents[loopedFrame] do
				table.insert(vars.mainLoopEvents,vars.vars.mainLoopTimedEvents[loopedFrame][i])
		end
		vars.mainLoopTimedEvents[loopedFrame] = {}
	end

	
	--check if repeating events has functions to call and add them to the end of the main loop events
	if vars.mainLoopRepeatingEvents[loopedFrame] then 
		for i=1, #vars.mainLoopRepeatingEvents[loopedFrame] do
				table.insert(vars.mainLoopEvents,vars.mainLoopRepeatingEvents[loopedFrame][i])
		end
	end

	--check if we have any events to run
	if not vars.mainLoopEvents then return end

	--loop over the events
	for i=1, #vars.mainLoopEvents do	vars.mainLoopEvents[i]() end
	
	--Clear the main loop events
		vars.mainLoopEvents = {}
	--VoidEcho("Gameframe ",frame)		
end 
]]
function gadget:GameFrame(inFrame)
end


-- UNITS
function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID) end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, projectileID, attackerID, attackerDefID, attackerTeam)
	-- Spring doesnt offer a way to easily control unit damage or armor in the engine by directly setting the unit's stats
	-- Instead, manual calculations need to be done here and returned from here in order to simulate damage buffs or armor buffs
	-- As an example, the Archon provides significant damage protection to the commander based on stats - this will have to be calculated here
	
	-- if an allied commander is being damaged, reduce its damage by the archon stats
	if vars.teamCommanderUnitIds[unitTeam] == unitID then
		damage = damage * 0.10
	end

	return damage
end

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
--function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions, cmdTag, playerID, fromSynced, fromLua) return true	end
function gadget:UnitCommand(unitID, unitDefID, unitTeamID, cmdID, cmdParams, cmdOptions, cmdTag, playerID, fromSynced, fromLua) 
	
	-- check if this is a negative ability
	if cmdID >= 0 then return end

	-- for those looking at this, the cmdID comes in as negative unitDefId, and negative cmdIDs mean build something from the build menu
	local abilityName = UnitDefs[-cmdID].name

	VoidEcho("Unit command from unit ", abilityName)
	if abilities[ abilityName ] then 
		abilities.CallArchonAbility(abilityName,unitTeamID)
	end 

end


--function gadget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag) end

-- TEAMS
function gadget:TeamDied(teamID) end 	



	

