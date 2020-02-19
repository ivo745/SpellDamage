local shortNumber, matchDigit, matchDigits, printTable, strstarts = SD.shortNumber, SD.matchDigit, SD.matchDigits, SD.printTable, SD.strstarts
local SpellUnknown, SpellEmpty, SpellDamage, SpellTimeDamage, SpellHeal, SpellTimeHeal, SpellMana, SpellTimeMana, SpellAbsorb = SD.SpellUnknown, SD.SpellEmpty, SD.SpellDamage, SD.SpellTimeDamage, SD.SpellHeal, SD.SpellTimeHeal, SD.SpellMana, SD.SpellTimeMana, SD.SpellAbsorb
local SpellDamageAndTimeDamage, SpellDamageAndMana, SpellHealAndMana, SpellHealAndTimeHeal, SpellDamageAndHeal, SpellTimeDamageAndTimeHeal, SpellDamageAndTimeHeal, SpellManaAndTimeMana, SpellTimeHealAndTimeMana, SpellAbsorbAndHeal, SpellAbsorbAndDamage = SD.SpellDamageAndTimeDamage, SD.SpellDamageAndMana, SD.SpellHealAndMana, SD.SpellHealAndTimeHeal, SD.SpellDamageAndHeal, SD.SpellTimeDamageAndTimeHeal, SD.SpellDamageAndTimeHeal, SD.SpellManaAndTimeMana, SD.SpellTimeHealAndTimeMana, SD.SpellAbsorbAndHeal, SD.SpellAbsorbAndDamage
local SpellData, Class, ClassSpells, ClassItems = SD.SpellData, SD.Class, SD.ClassSpells, SD.ClassItems

--

SD.CustomParser = {}
function SD.CustomParser:create(func)
	local parser = {}
	parser.parse = func
	self.__index = self
	return setmetatable(parser, self)
end

function SD.CustomParser:getData(description)
	local data = SD.SpellData:create(SpellUnknown)
	self.parse(data, description)
	return data
end

function SD.Custom(computeFunc) return SD.CustomParser:create(computeFunc); end

--

SD.SimpleSpell = {}

function SD.SimpleSpell:create(spellType, indexes, computeFunc)
	if type(indexes) ~= "number" then error("Wrong type '"..type(indexes).."' of 'indexes' in 'SD.SimpleSpell:create' function"); end
	local spell = {}
	spell.type = spellType
	spell.index = indexes
	if type(spell.index) ~= "number" then error("Wrong type '"..type(spell.index).."' of 'spell.index' in 'SD.SimpleSpell:create' function"); end
	spell.computeFunc = computeFunc
	self.__index = self
	return setmetatable(spell, self)
end

function SD.SimpleSpell:getData(description)
	local data = SD.SpellData:create(SpellUnknown)
	local match = self.index
		if self.computeFunc then self.computeFunc(data, match, description); end
	return data
end

--caching functions:
function SD.Damage(rank, computeFunc)
	return SD.SimpleSpell:create(SpellDamage, rank, computeFunc)
end

function SD.Heal(index, computeFunc)
	return SD.SimpleSpell:create(SpellHeal, index, computeFunc)
end