function widget:GetInfo()
	return {
		name = "VoidStalkers Stats Panel",
		desc = "Shows statistics and progress when fighting vs Chickens",
		author = "Gilgamesh, original author quantum",
		date = "Dec 2022",
		license = "GNU GPL, v2 or later",
		layer = -9,
		enabled = true  --  loaded by default?
	}
end

if not Spring.Utilities.Gametype.IsVoidstalkers() then return false end


local customScale = 1
local widgetScale = customScale
local font, font2, chobbyInterface
local messageArgs, marqueeMessage
local refreshMarqueeMessage = false
local showMarqueeMessage = false


local GetGameSeconds = Spring.GetGameSeconds
local gl = gl
local math = math

local displayList
local panelTexture = ":n:LuaUI/Images/voidstalkerspanel.tga"

local panelFontSize = 14
local waveFontSize = 36

local vsx, vsy = Spring.GetViewGeometry()
local fontfile2 = "fonts/" .. Spring.GetConfigString("bar_font2", "Exo2-SemiBold.otf")

local viewSizeX, viewSizeY = 0, 0
local w = 300
local h = 210
local x1 = 0
local y1 = 0
local panelMarginX = 30
local panelMarginY = 40
local panelSpacingY = 7
local waveSpacingY = 7
local moving
local capture
local gameInfo
local waveSpeed = 0.1
local waveCount = 0
local waveTime
local enabled = true
local gotScore
local scoreCount = 0
local resistancesTable = {}
local currentlyResistantTo = {}

local guiPanel --// a displayList
local updatePanel

local difficultyOption = Spring.GetModOptions().chicken_difficulty

local rules = {
	"voidstalkers_Count",
	"voidstalkers_Killed"
}

local waveColor = "\255\255\0\0"
local textColor = "\255\255\255\255"


local voidTypes = {
	--"voidstalker_ghost",
}

local function commaValue(amount)
	local formatted = amount
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then
			break
		end
	end
	return formatted
end

local function getVoidCounts(type)
	local total = 0
	local subtotal

	for _, voidType in ipairs(voidTypes) do
		subtotal = gameInfo[voidType .. type]
		total = total + subtotal
	end

	return total
end

local function updatePos(x, y)
	x1 = math.min((viewSizeX * 0.94) - (w * widgetScale) / 2, x)
	y1 = math.min((viewSizeY * 0.89) - (h * widgetScale) / 2, y)
	updatePanel = true
end

local function PanelRow(n)
	return h - panelMarginY - (n - 1) * (panelFontSize + panelSpacingY)
end

local function WaveRow(n)
	return n * (waveFontSize + waveSpacingY)
end

local function CreatePanelDisplayList()
	gl.PushMatrix()
	gl.Translate(x1, y1, 0)
	gl.Scale(widgetScale, widgetScale, 1)
	gl.CallList(displayList)

	local currentTime = GetGameSeconds()
	local techLevel = ""
	

	font:Begin()
	font:SetTextColor(1, 1, 1, 1)
	font:SetOutlineColor(0, 0, 0, 1)
	--Row 1
	font:Print("Row 1:  Hello Sydney!", panelMarginX, PanelRow(1), panelFontSize, "")
	--Row 2
	font:Print("Row 2:  Hello Reagan!", panelMarginX, PanelRow(2), panelFontSize, "")
	--Row 3
	font:Print("Row 3:  Daddy loves you both!", panelMarginX, PanelRow(3), panelFontSize, "")
	--Row 4
	font:Print("Row 4", panelMarginX, PanelRow(4), panelFontSize, "")
	--Row 5
	font:Print("Row 5", panelMarginX, PanelRow(5), panelFontSize, "")
	--Row 6
	font:Print("Row 6", panelMarginX, PanelRow(6), panelFontSize, "")
	--Row 7
	font:Print("Row 7", panelMarginX, PanelRow(7), panelFontSize, "")
	--Row 8
	font:Print("Row 8", panelMarginX, PanelRow(8), panelFontSize, "")
	
	
	font:End()

	gl.Texture(false)
	gl.PopMatrix()
end


local function Draw()
	if not enabled or not gameInfo then
		return
	end

	if updatePanel then
		if (guiPanel) then
			gl.DeleteList(guiPanel);
			guiPanel = nil
		end
		guiPanel = gl.CreateList(CreatePanelDisplayList)
		updatePanel = false
	end

	if guiPanel then
		gl.CallList(guiPanel)
	end

	
end

local function UpdateRules()
	if not gameInfo then
		gameInfo = {}
	end

	for _, rule in ipairs(rules) do
		gameInfo[rule] = Spring.GetGameRulesParam(rule) or 999	
	end
	gameInfo.voidCounts = getVoidCounts('Count')
	gameInfo.voidKills = getVoidCounts('Kills')

	updatePanel = true
end

function VoidstalkersEvent(chickenEventArgs)
	if chickenEventArgs.type == "firstWave" or chickenEventArgs.type == "airWave" or chickenEventArgs.type == "miniQueen" or chickenEventArgs.type == "queen" then
		showMarqueeMessage = true
		refreshMarqueeMessage = true
		messageArgs = chickenEventArgs
		waveTime = Spring.GetTimer()
	end

	if chickenEventArgs.type == "queenResistance" then
		if chickenEventArgs.number then
			if not currentlyResistantTo[chickenEventArgs.number] then
				table.insert(resistancesTable, chickenEventArgs.number)
				currentlyResistantTo[chickenEventArgs.number] = true
			end
		end
	end

end

--------------
-- Handlers

function HandleViewResize()

	vsx, vsy = Spring.GetViewGeometry()

	font = WG['fonts'].getFont()
	font2 = WG['fonts'].getFont(fontfile2)

	x1 = math.floor(x1 - viewSizeX)
	y1 = math.floor(y1 - viewSizeY)
	viewSizeX, viewSizeY = vsx, vsy
	widgetScale = (0.75 + (viewSizeX * viewSizeY / 10000000)) * customScale
	x1 = viewSizeX + x1 + ((x1 / 2) * (widgetScale - 1))
	y1 = viewSizeY + y1 + ((y1 / 2) * (widgetScale - 1))

end

function HandleDisplayPanelSetup()
	displayList = gl.CreateList(function()
		gl.Blending(true)
		gl.Color(1, 1, 1, 1)
		gl.Texture(panelTexture)
		gl.TexRect(0, 0, w, h)
	end)
end

function HandleRulesUpdate()
	UpdateRules()
end

function HandleEventRegister()
	widgetHandler:RegisterGlobal("VoidstalkersEvent", VoidstalkersEvent)
end

function HandleUpdatePosition()
	viewSizeX, viewSizeY = gl.GetViewSizes()
	local x = math.abs(math.floor(viewSizeX - 320))
	local y = math.abs(math.floor(viewSizeY - 300))
	updatePos(x, y)
end


function HandleShutdown()
	if guiPanel then
		gl.DeleteList(guiPanel);
		guiPanel = nil
	end

	gl.DeleteList(displayList)
	gl.DeleteTexture(panelTexture)
end

function HandleUpdateDisplayText(inArgs)

	if inArgs.frame % 30 ~= 0 then return end
	
	UpdateRules()
		
end

function HandleDrawScreen()
	if chobbyInterface then return end

	Draw()
end

function HandleLanguageChanged()
	refreshMarqueeMessage = true;
	updatePanel = true;
end


--------------
-- Call-ins

function widget:Initialize()
	HandleViewResize()
	HandleDisplayPanelSetup()
	HandleRulesUpdate()
	HandleEventRegister()
	HandleUpdatePosition()
end

function widget:Shutdown()
	HandleShutdown()
end

function widget:GameFrame(n)
	HandleUpdateDisplayText({frame = n})
	--if not hasChickenEvent and n > 1 then
	--	Spring.SendCommands({ "luarules HasChickenEvent 1" })
	--	hasChickenEvent = true
	--end

	--[[
		if n % 30 == 0 then
		UpdateRules()
		if not enabled and n > 1 then
			enabled = true
		end
	end
	]]
	--updatePanel = true
	
end

function widget:RecvLuaMsg(msg, playerID)
	if msg:sub(1, 18) == 'LobbyOverlayActive' then
		chobbyInterface = (msg:sub(1, 19) == 'LobbyOverlayActive1')
	end
end

function widget:DrawScreen()
	HandleDrawScreen()
end

function widget:MouseMove(x, y, dx, dy, button)
	if enabled and moving then
		updatePos(x1 + dx, y1 + dy)
	end
end

function widget:MousePress(x, y, button)
	if enabled and
		x > x1 and x < x1 + (w * widgetScale) and
		y > y1 and y < y1 + (h * widgetScale)
	then
		capture = true
		moving = true
	end
	return capture
end

function widget:MouseRelease(x, y, button)
	if not enabled then
		return
	end
	capture = nil
	moving = nil
	return capture
end

function widget:ViewResize()
	HandleViewResize()
	
end

function widget:LanguageChanged()
	HandleLanguageChanged()
end
