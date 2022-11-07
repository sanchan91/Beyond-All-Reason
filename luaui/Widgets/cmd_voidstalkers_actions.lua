--Check if we need to load voidstalkers
if not Spring.Utilities.Gametype.IsVoidstalkers() then return false end

Spring.Echo("Voidstalkers Actions Online (Widget)")

function widget:GetInfo()
	return {
		name = "Voidstalkers Commands",
		desc = "Listens for commands",
		author = "Gilgamesh",
		date = "2022",
		license = "GNU GPL, v2 or later",
		layer = -9999,
		enabled = true
	}
end


--------------------------
-- Commands that this widget understands
-- /voidstalkers load
-- /voidstalkers save
-- /voidstalkers archon give [unitName]
-- /voidstalkers archon level [integer]
-- /voidstalkers void level [integer]


---------
-- Utilities
local function VoidEcho(...)
	Spring.Echo("VoidEcho: Widget: ",...)
end

---------
-- Systems

local commandStateLoad = function()
	VoidEcho("commandStateLoad")
end

local commandStateSave = function()
	VoidEcho("commandStateSave")
end

local commandArchonGive = function(inUnitName)
	
	VoidEcho("archon give", inUnitName)
	--VoidEcho("commandArchonGive "..inNumber)
end

local commandArchonLevel = function(inNumber)
	VoidEcho("archon level", inNumber)
end

local commandVoidLevel = function(inNumber)
	VoidEcho("void level", inNumber)
end
 
local voidCommands = {}
voidCommands["state load"] = commandStateLoad
voidCommands["state save"] = commandStateSave
voidCommands["archon give"] = commandArchonGive
voidCommands["archon level"] = commandArchonLevel 
voidCommands["void level"] = commandVoidLevel


---------
-- Events

local events = {}

events.TextCommand = function(_,inCommand)
	--Grab the command from the string
	-- and remember that match can return multiple values -> --local key, value = string.match("Bob = Sam", "(%a+)%s*=%s*(%a+)")
	local commandText,commandArgs = string.match(inCommand,"^voidstalkers (%a+ %a+) (%S+)")
	local commandFunction = voidCommands[commandText]

	--Check if this command is registered
	if not commandFunction then return end

	--Call the function
	commandFunction(commandArgs)

	--VoidEcho(inCommand,commandText,commandArgs)

	
end

---------
-- Call-ins

widget.TextCommand = events.TextCommand 



--[[
local SAVE_DIR = "Voidstate"
local SAVE_DIR_LENGTH = string.len(SAVE_DIR) + 2

local LOAD_GAME_STRING = "loadFilename "
local SAVE_TYPE = "save "

local function WriteDate(dateTable)
	return string.format("%02d/%02d/%04d", dateTable.day, dateTable.month, dateTable.year)
		.. " " .. string.format("%02d:%02d:%02d", dateTable.hour, dateTable.min, dateTable.sec)
end

local function SecondsToClock(seconds)
	local seconds = tonumber(seconds)

	if seconds <= 0 then
		return "00:00";
	else
		hours = string.format("%02d", math.floor(seconds / 3600));
		mins = string.format("%02d", math.floor(seconds / 60 - (hours * 60)));
		secs = string.format("%02d", math.floor(seconds - hours * 3600 - mins * 60));
		if seconds >= 3600 then
			return hours .. ":" .. mins .. ":" .. secs
		else
			return mins .. ":" .. secs
		end
	end
end

local function trim(str)
	return str:match '^()%s*$' and '' or str:match '^%s*(.*%S)'
end

--------------------------------------------------------------------------------
-- Savegame utlity functions
--------------------------------------------------------------------------------
-- FIXME: currently unused as it doesn't seem to give the correct order

local function GetSaveExtension(path)
	if VFS.FileExists(path .. ".ssf") then
		return ".ssf"
	end
	return VFS.FileExists(path .. ".slsf") and ".slsf"
end

local function GetSaveWithExtension(path)
	local ext = GetSaveExtension(path)
	return ext and path .. ext
end

-- Returns the data stored in a save file
local function GetSave(path)
	local ret = nil
	local success, err = pcall(function()
		local saveData = VFS.Include(path)
		saveData.filename = string.sub(path, SAVE_DIR_LENGTH, -5)    -- pure filename without directory or extension
		saveData.path = path
		ret = saveData
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error getting save " .. path .. ": " .. err)
	else
		local engineSaveFilename = GetSaveWithExtension(string.sub(path, 1, -5))
		if not engineSaveFilename then
			--Spring.Log(widget:GetInfo().name, LOG.ERROR, "Save " .. engineSaveFilename .. " does not exist")
			return nil
		else
			return ret
		end
	end
end

local function GetSaveDescText(saveFile)
	if not saveFile then
		return ""
	end
	return (saveFile.description or "no description")
		.. "\n" .. saveFile.gameName .. " " .. saveFile.gameVersion
		.. "\n" .. saveFile.map
		.. "\n" .. (WG.Translate("interface", "time_ingame") or "Ingame time") .. ": " .. SecondsToClock((saveFile.totalGameframe or saveFile.gameframe or 0) / 30)
		.. "\n" .. WriteDate(saveFile.date)
end

local function SaveGame(filename, description, requireOverwrite)
	if WG.Analytics and WG.Analytics.SendRepeatEvent then
		WG.Analytics.SendRepeatEvent("game_start:savegame", filename)
	end
	local success, err = pcall(
		function()
			Spring.CreateDir(SAVE_DIR)
			filename = (filename and trim(filename)) or ("save" .. string.format("%03d", FindFirstEmptySaveSlot()))
			path = SAVE_DIR .. "/" .. filename .. ".lua"
			local saveData = {}
			--saveData.filename = filename
			saveData.date = os.date('*t')
			saveData.description = description or "No description"
			saveData.gameName = Game.gameName
			saveData.gameVersion = Game.gameVersion
			saveData.engineVersion = Engine.version
			saveData.map = Game.mapName
			saveData.gameID = (Spring.GetGameRulesParam("save_gameID") or Game.gameID)
			saveData.gameframe = Spring.GetGameFrame()
			saveData.totalGameframe = Spring.GetGameFrame() + (Spring.GetGameRulesParam("totalSaveGameFrame") or 0)
			saveData.playerName = Spring.GetPlayerInfo(Spring.GetMyPlayerID(), false)
			table.save(saveData, path)

			-- TODO: back up existing save?
			--if VFS.FileExists(SAVE_DIR .. "/" .. filename) then
			--end

			--if requireOverwrite then
			--	Spring.SendCommands(SAVE_TYPE .. filename .. " -y")
			--else
			--	Spring.SendCommands(SAVE_TYPE .. filename)
			--end
			Spring.Log(widget:GetInfo().name, LOG.INFO, "Voidstate saved to " .. path)

			--DisposeWindow()
		end
	)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error saving voidstate: " .. err)
	end
end

local function LoadGameByFilename(filename)
	local saveData = GetSave(SAVE_DIR .. '/' .. filename .. ".lua")
	if saveData then
		if Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName() then
			Spring.SendLuaMenuMsg(LOAD_GAME_STRING .. filename)
		else
			local ext = GetSaveExtension(SAVE_DIR .. '/' .. filename)
			if not ext then
				Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error loading game: cannot find save file.")
				return
			end
			local success, err = pcall(
				function()
					-- This should perhaps be handled in chobby first?
					--Spring.Log(widget:GetInfo().name, LOG.INFO, "Save file " .. path .. " loaded")

					local script = [[
	[GAME]
	{
		SaveFile=__FILE__;
		IsHost=1;
		OnlyLocal=1;
		MyPlayerName=__PLAYERNAME__;
	}
	
					script = script:gsub("__FILE__", filename .. ext)
					script = script:gsub("__PLAYERNAME__", saveData.playerName)
					Spring.Reload(script)
				end
			)
			if (not success) then
				Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error loading game: " .. err)
			end
		end
	else
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Save game " .. filename .. " not found")
	end
	if saveFilenameEdit then
		saveFilenameEdit:SetText(filename)
	end
end

local function DeleteSave(filename)
	if not filename then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "No filename specified for save deletion")
	end
	local success, err = pcall(function()
		local pathNoExtension = SAVE_DIR .. "/" .. filename
		os.remove(pathNoExtension .. ".lua")
		local saveFilePath = GetSaveWithExtension(pathNoExtension)
		if saveFilePath then
			os.remove(saveFilePath)
		end
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error deleting save " .. filename .. ": " .. err)
	end
end

function widget:Initialize()
	WG['savegame'] = {}
end

function widget:Shutdown()
	WG['savegame'] = nil
end

local options = {}

function widget:TextCommand(msg)
	if string.sub(msg, 1, 8) == "savegame" then

		Spring.Echo("Trying to save:", msg)
		local savefilename = string.sub(msg, 10)
		SaveGame(savefilename, savefilename, true)
	end
end



function widget:GameFrame(n)

	if not options.enableautosave.value then
		return
	end
	if options.autosaveFrequency.value == 0 then
		return
	end
	if n % (options.autosaveFrequency.value * 1800) == 0 and n ~= 0 then
		if Spring.GetSpectatingState() or Spring.IsReplay() or (not WG.crude.IsSinglePlayer()) then
			return
		end
		Spring.Log(widget:GetInfo().name, LOG.INFO, "Autosaving")
		SaveGame("autosave", "", true)
	end
end
]]--
