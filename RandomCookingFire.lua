local rcToys = {
	163211,	-- "Akunda's Firesticks"
	203757,	-- "Brazier of Madness"
	116435,	-- "Cozy Bonfire"
	153039,	-- "Crystalline Campfire"
	184404,	-- "Ever-Abundant Hearth"
	104309,	-- "Eternal Kiln"
	127652,	-- "Felflame Campfire"
	67097,	-- "Grim Campfire"
	128536,	-- "Leylight Brazier"
	70722,	-- "Little Wickerman"
	198402,	-- "Maruuk Cooking Pot"
	182780,	-- "Muckpool Cookpot"
	116757,	-- "Steamworks Sausage Grill"
	219403,	-- "Stonebound Lantern"
	199892,	-- "Tuskarr Traveling Soup Pot"
	}

------------------------------------------------------------------------------------------------------------------------------------------------------
-- DO NOT EDIT BELOW HERE
-- Unless you want to, I'm not your supervisor.

local rcfList, macroIcon, macroToyName, macroTimer, waitTimer, pendingMacroUpdate
local rcfCheckButtons, wait, lastRnd = {}, false, 0
local addon, RCF = ...
local L = RCF.Localisation

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Frames
------------------------------------------------------------------------------------------------------------------------------------------------------
local rcfOptionsPanel = CreateFrame("Frame")
local rcfCategory = Settings.RegisterCanvasLayoutCategory(rcfOptionsPanel, "Random Cooking Fire")
local rcfTitle = CreateFrame("Frame", nil, rcfOptionsPanel)
local rcfDesc = CreateFrame("Frame", nil, rcfOptionsPanel)
local rcfOptionsScroll = CreateFrame("ScrollFrame", nil, rcfOptionsPanel, "UIPanelScrollFrameTemplate")
local rcfDivider = rcfOptionsScroll:CreateLine()
local rcfScrollChild = CreateFrame("Frame")
local rcfSelectAll = CreateFrame("Button", nil, rcfOptionsScroll, "UIPanelButtonTemplate")
local rcfDeselectAll = CreateFrame("Button", nil, rcfOptionsScroll, "UIPanelButtonTemplate")
local rcfListener = CreateFrame("Frame")
local rcfBtn = CreateFrame("Button", "rcfB", nil, "SecureActionButtonTemplate")
local rcfDropdown = CreateFrame("DropdownButton", nil, rcfOptionsPanel, "WowStyle1DropdownTemplate")
local rcfMacroName = CreateFrame("EditBox", nil, rcfOptionsPanel, "InputBoxTemplate")

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Functions
------------------------------------------------------------------------------------------------------------------------------------------------------
-- Combat Check
local function combatCheck()
	if (InCombatLockdown() or UnitAffectingCombat("player") or UnitAffectingCombat("pet")) then
		return true
	end
end

-- Defer macro update until out of combat
local function deferMacroUpdate()
	if not pendingMacroUpdate then
		pendingMacroUpdate = true
		rcfListener:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
end

-- Create or update global macro
local function updateMacro()
	if not combatCheck() then
		local macroText
		if #rcfList == 0 then
			if rcfDB.settings.warnMsg ~= true then
				rcfDB.settings.warnMsg = true
				print(L["NO_VALID_CHOSEN"])
			end
			macroText = "#showtooltip " .. macroToyName .. "\n/cast " .. macroToyName
		else
			macroText = "#showtooltip " .. macroToyName .. "\n/stopcasting\n/click [btn:2]rcfB 2;[btn:3]rcfB 3;rcfB"
		end
		if macroTimer ~= true then
			macroTimer = true
			C_Timer.After(0.1, function()
				if combatCheck() then
					macroTimer = false
					deferMacroUpdate()
					return
				end
				local macroIndex = GetMacroIndexByName(rcfDB.settings.macroName)
				if macroIndex == 0 then
					print(L["MACRO_NOT_FOUND"], rcfDB.settings.macroName, "'")
					CreateMacro(rcfDB.settings.macroName, macroIcon, macroText, nil)
					rcfMacroName:SetText(rcfDB.settings.macroName)
				else
					EditMacro(macroIndex, nil, macroIcon, macroText)
				end
				macroTimer = false
			end)
		end
	end
end

local function updateMacroName()
	if not combatCheck() then
		local name = rcfMacroName:GetText()
		local macroIndex = GetMacroIndexByName(rcfDB.settings.macroName)
		if macroIndex == 0 then
			updateMacro()
		else
			EditMacro(macroIndex, name)
			rcfDB.settings.macroName = name
			print(L["UPDATE_MACRO_NAME"], name, "'")
		end
	end
end

local function checkMacroName()
	if not combatCheck() then
		local name = rcfMacroName:GetText()
		if name == rcfDB.settings.macroName or string.len(name) == 0 then return end
		if GetMacroIndexByName(name) == 0 then
			rcfMacroName.Icon:Hide()
			updateMacroName()
		end
	end
end
-- Set random Hearthstone
local function setRandom()
	if not combatCheck() then
		if #rcfList > 0 then
			local rnd = rcfList[math.random(1, #rcfList)]
			if #rcfList > 1 then
				while rnd == lastRnd do
					rnd = rcfList[math.random(1, #rcfList)]
				end
				lastRnd = rnd
			end
			macroToyName = rcfDB.L.tList[rnd]["name"]
			rcfBtn:SetAttribute("toy", macroToyName)
			if rcfDB.iconOverride.name == L["RANDOM"] then
				macroIcon = rcfDB.L.tList[rnd]["icon"]
			else
				macroIcon = rcfDB.iconOverride.icon
			end
		else
			macroToyName = "spell:818"
			macroIcon = 135805
		end
		updateMacro()
	end
end

-- Generate a list of valid toys
local function listGenerate()
	rcfList = {}

	for i, v in pairs(rcfDB.L.tList) do
		if v["status"] == true then
			if PlayerHasToy(i) then
				table.insert(rcfList, i)
			end
		end
	end
	setRandom()
end

-- Update Hearthstone selections when options panel closes
local function rcfOptionsOkay()
	for i, v in pairs(rcfDB.L.tList) do
		v["status"] = rcfCheckButtons[i]:GetChecked()
	end
	rcfDB.settings.warnMsg = false
	listGenerate()
end

-- Macro icon selection
local function rcfSelectIcon(arg1)
	if arg1 == "Random" then
		rcfDB.iconOverride.name = L["RANDOM"]
		rcfDB.iconOverride.icon = 134400
		rcfDB.iconOverride.id = nil
	elseif arg1 == "Cooking Fire" then
		rcfDB.iconOverride.name = L["COOKINGFIRE"]
		rcfDB.iconOverride.icon = 135805
		rcfDB.iconOverride.id = 818
	else
		rcfDB.iconOverride.name = rcfDB.L.tList[arg1]["name"]
		rcfDB.iconOverride.icon = rcfDB.L.tList[arg1]["icon"]
		rcfDB.iconOverride.id = arg1
	end
	rcfDropdown:SetText(rcfDB.iconOverride.name)
	rcfDropdown.Texture:SetTexture(rcfDB.iconOverride.icon)
end

-- Dropdown menu generator function
local function rcfDropdownGenerator(dropdown, rootDescription)
	local function IsSelected(value)
		if value == "Random" then return rcfDB.iconOverride.name == L["RANDOM"] end
		if value == "Cooking Fire" then return rcfDB.iconOverride.name == L["COOKINGFIRE"] end
		return rcfDB.iconOverride.id == value
	end

	rootDescription:CreateRadio(L["RANDOM"], IsSelected, function() rcfSelectIcon("Random") end, "Random")
	rootDescription:CreateRadio(L["COOKINGFIRE"], IsSelected, function() rcfSelectIcon("Cooking Fire") end, "Cooking Fire")

	for i = 1, #rcfToys do
		if rcfDB.L.tList[rcfToys[i]] ~= nil then
			rootDescription:CreateRadio(rcfDB.L.tList[rcfToys[i]]["name"], IsSelected, function() rcfSelectIcon(rcfToys[i]) end, rcfToys[i])
		end
	end
end

-- Add items in savedvariable
local function rcfInitDB(table, item, value)
	local isTable = type(value) == "table"
	local exists = false
	-- Check if the item already exists in the table
	for k, v in pairs(table) do
		if k == item or (type(v) == "table" and isTable and v == value) then
			exists = true
			break
		end
	end
	-- If the item does not exist, add it
	if not exists then
		if value ~= nil then
			-- Add item with a value
			table[item] = value
		else
			-- Add item without a value
			table.insert(table, item)
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Button creation
------------------------------------------------------------------------------------------------------------------------------------------------------
rcfBtn:RegisterForClicks("AnyDown")
rcfBtn:SetAttribute("pressAndHoldAction", true)
rcfBtn:SetAttribute("type", "toy")
rcfBtn:SetAttribute("typerelease", "toy")
rcfBtn:SetScript("PostClick", function(self, button)
	if not combatCheck() then
		setRandom()
	end
end)

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Options panel
------------------------------------------------------------------------------------------------------------------------------------------------------
rcfOptionsPanel.name = "Random Cooking Fire"
rcfOptionsPanel.OnCommit = function() rcfOptionsOkay(); end
rcfOptionsPanel.OnDefault = function() end
rcfOptionsPanel.OnRefresh = function() end
Settings.RegisterAddOnCategory(rcfCategory)

-- Title
rcfTitle:SetPoint("TOPLEFT", 10, -10)
rcfTitle:SetWidth(SettingsPanel.Container:GetWidth() - 35)
rcfTitle:SetHeight(1)
rcfTitle.Text = rcfTitle:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
rcfTitle.Text:SetPoint("TOPLEFT", rcfTitle, 0, 0)
rcfTitle.Text:SetText(L["ADDON_NAME"])

-- Thanks
rcfOptionsPanel.Thanks = rcfOptionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
rcfOptionsPanel.Thanks:SetPoint("TOPRIGHT", rcfOptionsPanel, "TOPRIGHT", -5, -5)
rcfOptionsPanel.Thanks:SetTextColor(1, 1, 1, 0.5)
rcfOptionsPanel.Thanks:SetText(L["THANKS"] .. " :)\nNiian - Khaz'Goroth")
rcfOptionsPanel.Thanks:SetJustifyH("RIGHT")

-- Description
rcfDesc:SetPoint("TOPLEFT", 20, -40)
rcfDesc:SetWidth(SettingsPanel.Container:GetWidth() - 35)
rcfDesc:SetHeight(1)
rcfDesc.Text = rcfDesc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rcfDesc.Text:SetPoint("TOPLEFT", rcfDesc, 0, 0)
rcfDesc.Text:SetText(L["DESCRIPTION"])

-- Scroll Frame
rcfOptionsScroll:SetPoint("TOPLEFT", 5, -60)
rcfOptionsScroll:SetPoint("BOTTOMRIGHT", -25, 150)

-- Divider
rcfDivider:SetStartPoint("BOTTOMLEFT", rcfDivider:GetParent(), 20, -10)
rcfDivider:SetEndPoint("BOTTOMRIGHT", rcfDivider:GetParent(), 0, -10)
rcfDivider:SetColorTexture(0.25, 0.25, 0.25, 1)
rcfDivider:SetThickness(1.2)

-- Scroll Frame child
rcfOptionsScroll:SetScrollChild(rcfScrollChild)
rcfScrollChild:SetWidth(SettingsPanel.Container:GetWidth() - 35)
rcfScrollChild:SetHeight(1)

-- Checkbox for each toy
local chkOffset = 0
for i = 1, #rcfToys do
	if i > 1 then
		chkOffset = chkOffset + -26
	end
	rcfCheckButtons[rcfToys[i]] = CreateFrame("CheckButton", nil, rcfScrollChild, "UICheckButtonTemplate")
	rcfCheckButtons[rcfToys[i]]:SetPoint("TOPLEFT", 15, chkOffset)
	rcfCheckButtons[rcfToys[i]]:SetSize(25, 25)
	rcfCheckButtons[rcfToys[i]].Text = rcfCheckButtons[rcfToys[i]]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	local item = Item:CreateFromItemID(rcfToys[i])
	item:ContinueOnItemLoad(function()
		rcfCheckButtons[rcfToys[i]].Text:SetText(item:GetItemName())
	end)
	rcfCheckButtons[rcfToys[i]].Text:SetTextColor(1, 1, 1, 1)
	rcfCheckButtons[rcfToys[i]].Text:SetPoint("LEFT", 28, 0)
end

-- Select All button
rcfSelectAll:SetPoint("TOPLEFT", rcfSelectAll:GetParent(), "BOTTOMLEFT", 20, -20)
rcfSelectAll:SetSize(100, 25)
rcfSelectAll:SetText(L["SELECT_ALL"])
rcfSelectAll:SetScript("OnClick", function(self)
	for i, v in pairs(rcfCheckButtons) do
		v:SetChecked(true)
	end
end)

-- Deselect All button
rcfDeselectAll:SetPoint("TOPLEFT", rcfDeselectAll:GetParent(), "BOTTOMLEFT", 135, -20)
rcfDeselectAll:SetSize(100, 25)
rcfDeselectAll:SetText(L["DESELECT_ALL"])
rcfDeselectAll:SetScript("OnClick", function(self)
	for i, v in pairs(rcfCheckButtons) do
		v:SetChecked(false)
	end
end)

-- Custom macro name box
rcfMacroName:SetPoint("TOPLEFT", rcfDropdown, "BOTTOMLEFT", 25, -20)
rcfMacroName:SetAutoFocus(false)
rcfMacroName:SetSize(208, 20)
rcfMacroName:SetFontObject("GameFontNormal")
rcfMacroName:SetTextColor(1, 1, 1, 1)
rcfMacroName:SetMaxLetters(16)
rcfMacroName.Text = rcfMacroName:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rcfMacroName.Text:SetText(L["OPT_MACRO_NAME"])
rcfMacroName.Text:SetPoint("BOTTOMLEFT", rcfMacroName, "TOPLEFT", 0, 5)
rcfMacroName.Exist = rcfMacroName:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rcfMacroName.Exist:SetTextColor(1, 0, 0, 1)
rcfMacroName.Exist:SetJustifyH("LEFT")
rcfMacroName.Exist:SetPoint("TOPLEFT", rcfMacroName, "BOTTOMLEFT", 0, -5)
rcfMacroName.Exist:SetText(L["UNIQUE_NAME_ERROR"])
rcfMacroName.Exist:Hide()
rcfMacroName.Icon = rcfMacroName:CreateTexture(nil, "OVERLAY")
rcfMacroName.Icon:SetPoint("LEFT", rcfMacroName, "RIGHT", 5, 0)
rcfMacroName.Icon:SetTexture("Interface/COMMON/CommonIcons.PNG")
rcfMacroName.Icon:SetSize(24, 24)
rcfMacroName:SetScript("OnShow", function()
	rcfMacroName.Exist:Hide()
	rcfMacroName.Icon:Hide()
	rcfMacroName:SetText(rcfDB.settings.macroName)
end)
rcfMacroName:SetScript("OnTextChanged", function(self, userInput)
	if userInput == true then
		-- Checking if the macro exists. Adding in a timer so it doesn't spam check on every key press.
		if waitTimer ~= true then
			waitTimer = true
			C_Timer.After(0.5, function()
				local name = rcfMacroName:GetText()
				if name ~= rcfDB.settings.macroName and GetMacroIndexByName(name) ~= 0 then
					rcfMacroName.Exist:Show()
					rcfMacroName.Icon:SetTexCoord(0.25, 0.38, 0, 0.26)
					rcfMacroName.Icon:Show()
				elseif string.len(name) == 0 then
					rcfMacroName.Icon:Hide()
				else
					rcfMacroName.Exist:Hide()
					rcfMacroName.Icon:SetTexCoord(0, 0.13, 0.51, 0.75)
					rcfMacroName.Icon:Show()
				end
				waitTimer = false
			end)
		end
	end
end)
rcfMacroName:SetScript("OnEditFocusLost", function() checkMacroName() end)
rcfMacroName:SetScript("OnEnterPressed", function() checkMacroName() end)

-- Listener for addon loaded shenanigans
rcfListener:RegisterEvent("ADDON_LOADED")
rcfListener:RegisterEvent("PLAYER_ENTERING_WORLD")
rcfListener:SetScript("OnEvent", function(self, event, arg1)
	if event == "PLAYER_REGEN_ENABLED" and pendingMacroUpdate then
		pendingMacroUpdate = false
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		updateMacro()
		return
	end
	if event == "ADDON_LOADED" and arg1 == addon then
		-- Set savedvariable defaults if first load or compare and update savedvariables with toy list
		if rcfDB == nil then
			print(L["SETUP_1"])
			rcfDB = {}
		end
		rcfInitDB(rcfDB, "settings", {})
		rcfInitDB(rcfDB.settings, "macroName", L["MACRO_NAME"])
		rcfInitDB(rcfDB.settings, "warnMsg", false)
		rcfInitDB(rcfDB, "iconOverride", { name = "Random", icon = 134400 })
		rcfInitDB(rcfDB, "L", {})
		rcfInitDB(rcfDB.L, "locale", GetLocale())

		if rcfDB.L.tList == nil then
			wait = true
			rcfDB.L.tList = {}
			for i = 1, #rcfToys do
				local item = Item:CreateFromItemID(rcfToys[i])
				item:ContinueOnItemLoad(function()
					rcfDB.L.tList[rcfToys[i]] = {
						name = item:GetItemName(),
						icon = item:GetItemIcon(),
						status = true
					}
				end)
			end
		end

		rcfDB.chkStatus = nil

		-- Remove IDs that no longer exist in rcfToys list
		for i, v in pairs(rcfDB.L.tList) do
			local exists = 0
			for l = 1, #rcfToys do
				if i == rcfToys[l] then
					exists = 1
				end
			end
			if exists == 0 then
				rcfDB.L.tList[i] = nil
			end
		end

		-- Add any new IDs to saved variables as enabled
		for i = 1, #rcfToys do
			if not rcfDB.L.tList[rcfToys[i]] then
				wait = true
				local item = Item:CreateFromItemID(rcfToys[i])
				item:ContinueOnItemLoad(function()
					rcfDB.L.tList[rcfToys[i]] = {
						name = item:GetItemName(),
						icon = item:GetItemIcon(),
						status = true
					}
					rcfCheckButtons[rcfToys[i]]:SetChecked(true)
					if i == #rcfToys then
						listGenerate()
					end
				end)
			end
		end

		-- Update rcfDB if locale has changed
		if rcfDB.L.locale ~= GetLocale() then
			-- Update main list
			for i, v in pairs(rcfDB.L.tList) do
				local item = Item:CreateFromItemID(i)
				item:ContinueOnItemLoad(function()
					rcfDB.L.tList[i]["name"] = item:GetItemName()
				end)
			end

			-- Update iconOverride
			if rcfDB.iconOverride.id ~= nil then
				local item = Item:CreateFromItemID(rcfDB.iconOverride.id)
				item:ContinueOnItemLoad(function()
					rcfDB.iconOverride.name = item:GetItemName()
					UIDropDownMenu_SetText(rcfDropdown, rcfDB.iconOverride.name)
				end)
			end

			rcfDB.L.locale = GetLocale()
		end

		-- Loop through options and set checkbox state
		for i, v in pairs(rcfDB.L.tList) do
			rcfCheckButtons[i]:SetChecked(v["status"])
		end

		rcfDropdown.Texture:SetTexture(rcfDB.iconOverride.icon)
		rcfDropdown:SetText(rcfDB.iconOverride.name)
		rcfDropdown:SetupMenu(rcfDropdownGenerator)

		self:UnregisterEvent("ADDON_LOADED")
	end

	if event == "PLAYER_ENTERING_WORLD" then
		if not wait then
			listGenerate()
		end
	end
end)

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create slash command
------------------------------------------------------------------------------------------------------------------------------------------------------
SLASH_RandomCookingFire1 = "/rcf"
function SlashCmdList.RandomCookingFire(msg, editbox)
	Settings.OpenToCategory(rcfCategory:GetID())
end

--[[
	Ignore this, it's for future me when Blizz breaks things again:
	/Interface/SharedXML/Settings/Blizzard_Settings.lua
]]
