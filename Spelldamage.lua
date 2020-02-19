local shortNumber, matchDigit, matchDigits, printTable, SPELL_COMBO_POINTS, comboMatch, comboHelper, strstarts = SD.shortNumber, SD.matchDigit, SD.matchDigits, SD.printTable, SD.SPELL_COMBO_POINTS, SD.comboMatch, SD.comboHelper, SD.strstarts
local Items = SD.Items

local emptyClass = SD.Class:create(SD.ClassSpells)
local currentClass = emptyClass

local nonStandardUi = false
local ui_needUpdate = false

local onUpdateSpells = false
local onUpdateLastTime = GetTime()

local delayedUpdate = false
local delayedUpdateTime = GetTime()

local updatingHistory = {}

local buttons = {}
local buttonsCache = {}

local function clearButtons(buttons)
	for _, button in ipairs(buttons) do
		button.centerText:SetText("")
		button.bottomText:SetText("")
	end
end

local function createButtons()
	if IsAddOnLoaded("ElvUI") then
		for i = 1, 6 do
			for j = 1, 12 do
				table.insert(buttons, _G["ElvUI_Bar"..i.."Button"..j])
			end
		end
		nonStandardUi = true
	elseif IsAddOnLoaded("Bartender4") then
		for i = 1, 160 do
			table.insert(buttons, _G["BT4Button"..i])
		end
		nonStandardUi = true
	else
		for i = 1, 6 do
			for j = 1, 12 do
				table.insert(buttons, _G[((select(i, "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton", "MultiBarLeftButton", "BonusActionButton"))..j)])
			end
		end

		if IsAddOnLoaded("Dominos") then
			for i = 1, 60 do
				table.insert(buttons, _G["DominosActionButton"..i])
			end
			nonStandardUi = true
		end
	end

	local fontName = "Fonts\\FRIZQT__.TTF"
	local cx, cy = 0, 0
	local bx, by = 0, 0
	if SpellDamageStorage and SpellDamageStorage["font"] then
		fontName = "Fonts\\"..SpellDamageStorage["font"]
		if SpellDamageStorage["font"] == "ARIALN.TTF" then
			cx = 2
			cy = 3
			bx = 2
			by = 1
		end
	end
	for _, button in ipairs(buttons) do   
		button.centerText = button:CreateFontString(nil, nil, "GameFontNormalLeft")
		button.centerText:SetFont(fontName, 10, "OUTLINE")
		button.centerText:SetPoint("CENTER", 0, cy)
		button.centerText:SetPoint("LEFT", cx, 0)
		
		button.bottomText = button:CreateFontString(nil, nil, "GameFontNormalLeft")
		button.bottomText:SetFont(fontName, 10, "OUTLINE")
		button.bottomText:SetPoint("BOTTOM", 0, by)
		button.bottomText:SetPoint("LEFT", bx, 0)
	end
end

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:RegisterEvent("PLAYER_LOGOUT")
EventFrame:RegisterEvent("UNIT_STATS")
EventFrame:RegisterEvent("UNIT_AURA")
EventFrame:RegisterEvent("UNIT_POWER_UPDATE")
EventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
EventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
EventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
EventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
local logined, updateSpells = false, {}
local function EventHandler(self, event, ...)
	local needCheckOnUpdate = false
	local needUpdateButtonsCache = false

	if event == "PLAYER_LOGIN" then
		logined = true
		needCheckOnUpdate = true
		needUpdateButtonsCache = true
		local className = select(2, UnitClass("player"))
	
		createButtons()

		if SpellDamageStorage then
		else
			SpellDamageStorage = {}
		end

		currentClass = SD.classes[className]
		if currentClass then currentClass:init(); end
		SD.classes = nil
		SD.class = currentClass
	end

	if event == "PLAYER_LOGOUT" then logined = false; end
	if logined == false then return; end

	local currentTime = GetTime()
	if updatingHistory[event] and currentTime - updatingHistory[event] < 0.1 then
		delayedUpdate = true
		delayedUpdateTime = currentTime
		return
	else
		updatingHistory[event] = currentTime
	end

	if event == "UPDATE_BONUS_ACTIONBAR" then
		delayedUpdate = true
		delayedUpdateTime = currentTime
	end

	if event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_TALENT_UPDATE" or event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_MACROS" 
		or event == "UPDATE_BONUS_ACTIONBAR"
		or event == "CUSTOM_DELAYED_UPDATE" or event == "CUSTOM_UI_UPDATE"
		or (event == "ACTIONBAR_SLOT_CHANGED") then
		
		needCheckOnUpdate = true
		needUpdateButtonsCache = true

		if #buttonsCache > 0 then
			clearButtons(buttonsCache)
			buttonsCache = {}
		end
	end

	if event == "ACTIONBAR_PAGE_CHANGED" and nonStandardUi then
		ui_needUpdate = true
		return
	end
	if currentClass == nil then
		return nil
	end
	if event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_LOGIN" or event == "PLAYER_EQUIPMENT_CHANGED" or event == "UPDATE_MACROS"
		or event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" or event == "PLAYER_EQUIPMENT_CHANGED"
		or event == "CUSTOM_ON_UPDATE_SPELLS" or event == "CUSTOM_DELAYED_UPDATE" or event == "CUSTOM_UI_UPDATE"
		or (event == "UNIT_STATS" and select(1, ...) == "player")
		or (event == "UNIT_AURA" and select(1, ...) == "player")
		or (event == "UNIT_POWER_UPDATE" and currentClass.dependFromPower == true and select(1, ...) == "player" and currentClass.dependPowerTypes[select(2, ...)] ~= nil)
		or (event == "PLAYER_TARGET_CHANGED" and currentClass.dependFromTarget == true)
		or (event == "UNIT_AURA" and select(1, ...) == "target" and currentClass.dependFromTarget == true) then
		if currentClass:hasOnUpdateSpells() then
			updateSpells = {}
			if needCheckOnUpdate == true then
				onUpdateSpells = false
				needCheckOnUpdate = false
				for id,_ in pairs(currentClass.onUpdateSpells) do
					updateSpells[id] = true
					needCheckOnUpdate = true
				end
			end
		else
			needCheckOnUpdate = false
		end

		local currentButtons = buttonsCache
		if needUpdateButtonsCache == true then currentButtons = buttons; end

		for _, button in ipairs(currentButtons) do
			local slot = ActionButton_GetPagedID(button)
			if slot == 0 then slot = ActionButton_CalculateAction(button); end
			if slot == 0 then slot = button:GetAttribute("action"); end
			if HasAction(slot) then
				local actionType, id = GetActionInfo(slot)

				if actionType == "macro" and id then
					local match = string.match(GetMacroBody(id), "#%s*sd%s*%d+")
					if match then
						actionType = "spell"
						id = tonumber(string.match(match, "%d+"))
					end
				end

				if actionType == "spell" and id then
					button.centerText:SetText("")
					button.bottomText:SetText("")

					if needCheckOnUpdate == true and updateSpells[id] then
						onUpdateSpells = true
						needCheckOnUpdate = false
					end
					
					local used = currentClass:updateButton(button, id)
					if used and needUpdateButtonsCache then table.insert(buttonsCache, button); end
				end
			end
		end
	end
end

EventFrame:SetScript("OnUpdate", function(self, elapsed)
	if ui_needUpdate == true then
		ui_needUpdate = false
		EventHandler(self, "CUSTOM_UI_UPDATE")
	elseif onUpdateSpells == true and GetTime() - onUpdateLastTime > 0.2 then
		EventHandler(self, "CUSTOM_ON_UPDATE_SPELLS")
		onUpdateLastTime = GetTime()
	elseif delayedUpdate == true and GetTime() - delayedUpdateTime > 0.2 then
		delayedUpdate = false
		EventHandler(self, "CUSTOM_DELAYED_UPDATE")
	end
end)

EventFrame:SetScript("OnEvent", EventHandler)

SLASH_SPELLDAMAGE1, SLASH_SPELLDAMAGE2, SLASH_SPELLDAMAGE3, SLASH_SPELLDAMAGE4 = "/sd", "/SD", "/spelldamage", "/SpellDamage"
function SlashCmdList.SPELLDAMAGE(msg, editbox)
	if msg == "" then
 		DEFAULT_CHAT_FRAME:AddMessage("chat_commands_list")
 		DEFAULT_CHAT_FRAME:AddMessage("   |cFFffff00/sd status|r - chat_command_status")
 		if Items then
 			DEFAULT_CHAT_FRAME:AddMessage("   |cFFffff00/sd items|r - chat_command_items")
 		end
 		DEFAULT_CHAT_FRAME:AddMessage("   |cFFffff00/sd errors|r - chat_command_errors")
 		DEFAULT_CHAT_FRAME:AddMessage("   |cFFffff00/sd macroshelp|r - chat_command_help")
 		DEFAULT_CHAT_FRAME:AddMessage("   |cFFffff00/sd font (friz|arial)|r - chat_command_font")
 		DEFAULT_CHAT_FRAME:AddMessage("   |cFFffff00/sd version|r - chat_command_version")
 	end
end
