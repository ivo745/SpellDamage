local shortNumber, printTable= SD.shortNumber, SD.printTable

--

SD.SpellUnknown, SD.SpellEmpty, SD.SpellDamage, SD.SpellTimeDamage, SD.SpellHeal, SD.SpellTimeHeal, SD.SpellMana, SD.SpellTimeMana, SD.SpellAbsorb = 0, 1, 2, 3, 4, 5, 6, 7, 8
SD.SpellDamageAndTimeDamage, SD.SpellDamageAndMana, SD.SpellHealAndMana, SD.SpellHealAndTimeHeal, SD.SpellDamageAndHeal, SD.SpellTimeDamageAndTimeHeal, SD.SpellDamageAndTimeHeal, SD.SpellManaAndTimeMana, SD.SpellTimeHealAndTimeMana, SD.SpellAbsorbAndHeal, SD.SpellAbsorbAndDamage = 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20

local SpellUnknown, SpellEmpty, SpellDamage, SpellTimeDamage, SpellHeal, SpellTimeHeal, SpellMana, SpellTimeMana, SpellAbsorb = SD.SpellUnknown, SD.SpellEmpty, SD.SpellDamage, SD.SpellTimeDamage, SD.SpellHeal, SD.SpellTimeHeal, SD.SpellMana, SD.SpellTimeMana, SD.SpellAbsorb
local SpellDamageAndTimeDamage, SpellDamageAndMana, SpellHealAndMana, SpellHealAndTimeHeal, SpellDamageAndHeal, SpellTimeDamageAndTimeHeal, SpellDamageAndTimeHeal, SpellManaAndTimeMana, SpellTimeHealAndTimeMana, SpellAbsorbAndHeal, SpellAbsorbAndDamage = SD.SpellDamageAndTimeDamage, SD.SpellDamageAndMana, SD.SpellHealAndMana, SD.SpellHealAndTimeHeal, SD.SpellDamageAndHeal, SD.SpellTimeDamageAndTimeHeal, SD.SpellDamageAndTimeHeal, SD.SpellManaAndTimeMana, SD.SpellTimeHealAndTimeMana, SD.SpellAbsorbAndHeal, SD.SpellAbsorbAndDamage

local _spellData = {}	--cache for minimizing memory new/delete function calls
_spellData.type = SD.SpellUnknown
SD.SpellData = {}
function SD.SpellData:create(type)
	_spellData.type = type
	return _spellData
end

SD.ClassSpells, SD.ClassItems = 1, 2
local ClassSpells, ClassItems = SD.ClassSpells, SD.ClassItems

SD.Class = {}
function SD.Class:create(classType)
	local class = {}
	class.spells = {}
	class.dependFromPower = false
	class.dependFromTarget = false
	class.dependPowerTypes = {}
	class.onUpdateSpells = {}
	class.onLoad = function() end
	class.type = classType
	if classType == ClassItems then
		class.getSpellText = GetItemDescription
	else
		class.getSpellText = GetSpellDescription
	end
	self.__index = self
	return setmetatable(class, self)
end

function SD.Class:hasOnUpdateSpells()
	if self.hasOnUpdateSpellsCache ~= nil then return self.hasOnUpdateSpellsCache; end
	self.hasOnUpdateSpellsCache = false
	for _,_ in pairs(self.onUpdateSpells) do
		self.hasOnUpdateSpellsCache = true
		break
	end
	return self.hasOnUpdateSpellsCache
end

function SD.Class:updateButton(button, spellId)
	local spellParser = self.spells[spellId]
	local updateParser = self.onUpdateSpells[spellId]

	if spellParser == nil and updateParser == nil then return false; end
	local data = SD.SpellData:create(SpellUnknown)
	if spellParser then
		data = spellParser:getData(nil);
	elseif updateParser then
		data = updateParser:getData(nil)
	end

	if data.type == SpellEmpty then return true; end

	if self.type == ClassSpells then
		button.centerText:SetText(shortNumber(data.damage) )
		button.centerText:SetTextColor(1, 1, 0, 1)
	end
	return true
end

SD.classes = {}

function SD.checkSpells()
	local str = ""
	for className, class in pairs(SD.classes) do
		class:init()
		local s = ""
		for id, parser in pairs(class.spells) do
			local description = GetSpellDescription(id)
			if not description then
				s = s.."no descr for "..id..", "
			else
				local data = parser:getData(description)
				if not data or data.type == SD.SpellUnknown then s = s..id..", "; end
			end
		end
		if s ~= "" then str = str..className.."("..s.."), "; end
		class.spells = {}
	end
	if str ~= "" then error("SpellDamage check spells error: "..str); end
end