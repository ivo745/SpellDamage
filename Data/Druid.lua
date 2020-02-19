local shortNumber, matchDigit, matchDigits, printTable, strstarts = SD.shortNumber, SD.matchDigit, SD.matchDigits, SD.printTable, SD.strstarts
local SpellUnknown, SpellEmpty, SpellDamage, SpellTimeDamage, SpellHeal, SpellTimeHeal, SpellMana, SpellTimeMana, SpellAbsorb = SD.SpellUnknown, SD.SpellEmpty, SD.SpellDamage, SD.SpellTimeDamage, SD.SpellHeal, SD.SpellTimeHeal, SD.SpellMana, SD.SpellTimeMana, SD.SpellAbsorb
local SpellDamageAndTimeDamage, SpellDamageAndMana, SpellHealAndMana, SpellHealAndTimeHeal, SpellDamageAndHeal, SpellTimeDamageAndTimeHeal, SpellDamageAndTimeHeal, SpellManaAndTimeMana, SpellTimeHealAndTimeMana, SpellAbsorbAndHeal = SD.SpellDamageAndTimeDamage, SD.SpellDamageAndMana, SD.SpellHealAndMana, SD.SpellHealAndTimeHeal, SD.SpellDamageAndHeal, SD.SpellTimeDamageAndTimeHeal, SD.SpellDamageAndTimeHeal, SD.SpellManaAndTimeMana, SD.SpellTimeHealAndTimeMana, SD.SpellAbsorbAndHeal
local SpellData, Class, ClassSpells, ClassItems = SD.SpellData, SD.Class, SD.ClassSpells, SD.ClassItems
local Damage, TimeDamage, Heal, TimeHeal, Mana, TimeMana, Absorb, CriticalDamage, DamageAndTimeDamage, HealAndTimeHeal, DamageAndHeal, DamageAndTimeHeal, HealAndMana, DamageAndDamage, DamageAndMana, TimeDamageAndTimeHeal, Custom, getLocaleIndex = SD.Damage, SD.TimeDamage, SD.Heal, SD.TimeHeal, SD.Mana, SD.TimeMana, SD.Absorb, SD.CriticalDamage, SD.DamageAndTimeDamage, SD.HealAndTimeHeal, SD.DamageAndHeal, SD.DamageAndTimeHeal, SD.HealAndMana, SD.DamageAndDamage, SD.DamageAndMana, SD.TimeDamageAndTimeHeal, SD.Custom

local Druid = Class:create(ClassSpells)
Druid.dependFromPower = true
Druid.dependPowerTypes["COMBO_POINTS"] = true
Druid.dependPowerTypes["ENERGY"] = true
Druid.dependPowerTypes["MANA"] = true
SD.classes["DRUID"] = Druid

local function lowDamage()
	return select(1, UnitDamage("player"))
end

local function attackPowerBonus()
	local base, positiveBuff, negativeBuff = UnitAttackPower('player');
	return base + positiveBuff + negativeBuff
end

local function healingBonus()
	return GetSpellBonusHealing()
end

local function spellDamageBonus(school)
	if school >= 1 and school <= 7 then
		return GetSpellBonusDamage(school)
	end
end

local function manaRegen()
	return select(2, GetManaRegen()) * 0.4
end

local SpellSchools = {
	Physical = 1, Holy = 2, Fire = 3, Nature = 4, Frost = 5, Shadow = 6, Arcane = 7
}

local function castTime(spellId)
	return select(4, GetSpellInfo(spellId)) / 1000
end

function Druid:init()
	local function addFunctionsToSpells(functions, spellTable)
		for key, func in pairs(functions) do
			for k, v in pairs(spellTable[key]) do
				self.spells[v] = Damage(k, func)
			end
		end
	end

	local penalty_coef_table = { }
	local PenaltySpellLevels = {
		{ 1, 8, 14 }, -- healing touch
		{ 4, 10, 16 }, -- rejuvenation
		{ 12, 18 }, -- regrowth
	}

	for k, v in pairs(PenaltySpellLevels) do
		local tempTable = { }
		for key, value in pairs(v) do
			table.insert(tempTable, (20 - value) * 0.0375)
		end
		table.insert(penalty_coef_table, tempTable)
	end

	local gift_of_nature_multiplier = 1.0
	local improved_rejuvenation_multiplier = 1.15
	local healing_touch_fixed_cast_time = 0.5
	local feral_aggression_multiplier = 1.12

	local DruidTalents = {
		GiftOfNature = { 17104, 24943, 24944, 24945, 24946 },
		ImprovedRejuvenation = { 17111, 17112, 17113 },
		ImprovedHealingTouch = { 17069, 17070, 17071, 17072, 17073 }
	}

	local healing_touch_coef = 3.5 -- variable cast time added in function
	local tranquility_coef = 3.5/3.5/3
	local rejuvenation_coef = 12/15
	local regrowth_direct_coef = (2/3.5)*(2/3.5) / (2/3.5 + 15/15)
	local regrowth_hot_coef = (15/15)*(15/15) / (2/3.5 + 15/15)
	local starfire_coef = 3.5/3.5
	local wrath_coef = 2/3.5
	local insect_swarm_coef = 12/15/0.95
	local entangling_roots_coef = 1.5/3.5*0.95
	local moonfire_direct_coef = (1.5/3.5)*(1.5/3.5) / (1.5/3.5 + 12/15)
	local moonfire_dot_coef = (12/15)*(12/15) / (1.5/3.5 + 12/15)
	local hurricane_coef = 3.5/3.5*0.95/3

	local DruidSpells = {
		Feral = {
			Claw = { 1082, 3029, 5201, 9849, 9850 },
			FerociousBite = { 22568, 22827, 22828, 22829, 31018 },
			Pounce = { 9005, 9823, 9827 },
			Rake = { 1822, 1823, 1824, 9904 },
			Ravage = { 6785, 6787, 9866, 9867 },
			Rip = { 1079, 9492, 9493, 9752, 9894, 9896 },
			Shred = { 5221, 6800, 8992, 9829, 9830 },
			Maul = { 6807, 6808, 6809, 8972, 9745, 9880, 9881 },
			Swipe = { 779, 780, 769, 9754, 9908 }
		},
		Balance = {
			Moonfire = { 8921, 8924, 8925, 8926, 8927, 8928, 8929, 9833, 9834, 9835 },
			Wrath = { 5176, 5177, 5178, 5179, 5180, 6780, 8905, 9912 },
			Starfire = { 2912, 8949, 8950, 8951, 9875, 9876, 25298 },
			Hurricane = { 16914, 17401, 17402 }
		},
		Restoration = {
			HealingTouch = { 5185, 5186, 5187, 5188, 5189, 6778, 8903, 9758, 9888, 9889, 25297 },
			Rejuvenation = { 774, 1058, 1430, 2090, 2091, 3627, 8910, 9839, 9840, 9841, 25299 },
			Regrowth = { 8936, 8938, 8939, 8940, 8941, 9750, 9856, 9857, 9858 },
			Tranquility = { 740, 8918, 9862, 9863 },
			Innervate = { 29166 },
			InsectSwarm = { 5570, 24974, 24975, 24976, 24977 }
		}
	}

	FeralFunctions = {
		FerociousBite = function(data, rank)
			local comboDamageByRank = { 
				{ 50, 86, 122, 158, 194 },
				{ 79, 138, 197, 256, 315 },
				{ 122, 214, 306, 398, 490 },
				{ 173, 301, 429, 557, 685 },
				{ 199, 346, 493, 640, 787 },
			}
			local combo = GetComboPoints('player', 'target')
			if combo == 0 then combo = 1 end
	
			local energy = UnitPower("player")
			if energy < 35 then energy = 35 end
			data.damage = comboDamageByRank[rank][combo] * feral_aggression_multiplier + (1.5 * (energy-35)) * 1+(combo*(attackPowerBonus()*0.03))
		end,
		Rip = function(data, rank)
			local comboDamageByRank = { 
				{ 42, 66, 90, 114, 138 },
				{ 66, 108, 150, 192, 234 },
				{ 90, 144, 198, 252, 306 },
				{ 138, 222, 306, 390, 474 },
				{ 192, 312, 432, 552, 672 },
				{ 270, 438, 606, 884, 942 }
			}
			local combo = GetComboPoints('player', 'target')
			if combo == 0 then combo = 1; end
			local attackPowerCoefficient = attackPowerBonus() * (combo * 0.06)
			if (combo >= 5) then
				attackPowerCoefficient = attackPowerBonus() * (4 * 0.06)
			end
			data.damage = comboDamageByRank[rank][combo] + attackPowerCoefficient
		end,
		Claw = function(data, rank)
			local baseDirect = { 27, 39, 57, 88, 115 }
			data.damage = baseDirect[rank] + lowDamage()
		end,
		Shred = function(data, rank)
			local baseDirect = { 54, 72, 99, 144, 180 }
			data.damage = baseDirect[rank] + (lowDamage() * 2.25)
		end,
		Ravage = function(data, rank)
			local baseDirect = { 147, 217, 273, 343 }
			data.damage = baseDirect[rank] + (lowDamage() * 3.50)
		end,
		Maul = function(data, rank)
			local baseDirect = { 18, 27, 37, 49, 71, 101, 128 }
			data.damage = baseDirect[rank] + lowDamage()
		end,
		Swipe = function(data, rank)
			local baseDirect = { 18, 25, 36, 60, 83 }
			data.damage = baseDirect[rank]
		end,
		Rake = function(data, rank)
			local baseDirect = { 19, 28, 43, 58 }
			local baseDot = { 39, 57, 75, 69 }
			data.damage = baseDirect[rank] + baseDot[rank]
		end,
	}
	BalanceFunctions = {
		Moonfire = function(data, rank)
			local baseDirect = { 9, 17, 30, 47, 70, 91, 117, 143, 172, 195 }
			local baseDot = { 12, 32, 52, 80, 124, 164, 212, 264, 320, 384 }
			data.damage = baseDirect[rank] + (spellDamageBonus(SpellSchools.Arcane) * moonfire_direct_coef) + 
			baseDot[rank] + (spellDamageBonus(SpellSchools.Arcane) * moonfire_dot_coef)
		end,
		Wrath = function(data, rank)
			local baseDirect = { 13, 28, 48, 69, 108, 148, 198, 248 }
			data.damage = baseDirect[rank] + spellDamageBonus(SpellSchools.Nature) * wrath_coef
		end,
		Starfire = function(data, rank)
			local baseDirect = { 95, 146, 212, 293, 378, 451, 496 }
			data.damage = baseDirect[rank] + spellDamageBonus(SpellSchools.Arcane) * starfire_coef
		end,
		Hurricane = function(data, rank)
			local baseDirect = { 72, 102, 134 }
			data.damage = (baseDirect[rank] * 10) + spellDamageBonus(SpellSchools.Nature) * hurricane_coef
		end,
	}
	RestorationFunctions = {
		HealingTouch = function(data, rank)
			local baseCastTime = { 1.5, 2.0, 2.5, 3.0, 3.5, 3.5, 3.5, 3.5, 3.5, 3.5 }
			local coef = baseCastTime[rank] / healing_touch_coef
			local baseDirect = { 40, 94, 204, 376, 589, 762, 958, 1214, 1545, 1916, 2267 }
			if rank < 4 then
				coef = (coef * (1 - penalty_coef_table[1][rank]))
			end
			data.damage = (baseDirect[rank] * gift_of_nature_multiplier) + (healingBonus() * coef)
		end,
		Rejuvenation = function(data, rank)
			local coef = rejuvenation_coef
			local baseHot = { 32, 56, 116, 180, 244, 304, 388, 488, 608, 756, 888 }
			if rank < 4 then
				effective_coef = (effective_coef * (1 - penalty_coef_table[2][rank]))
			end
			data.damage = (baseHot[rank] * gift_of_nature_multiplier * improved_rejuvenation_multiplier) + (healingBonus() * coef)
		end,
		Regrowth = function(data, rank)
			local direct_coef = regrowth_direct_coef
			local hot_coef = regrowth_hot_coef
			local baseDirect = { 93, 176, 255, 336, 425, 534, 672, 839, 1003 }
			local baseHot = { 98, 175, 259, 343, 427, 546, 686, 861, 1064 }
			if rank < 3 then
				direct_coef = (regrowth_direct_coef * (1 - penalty_coef_table[3][rank]))
				hot_coef = (regrowth_hot_coef * (1 - penalty_coef_table[3][rank]))
			end
			data.damage = (baseDirect[rank] * gift_of_nature_multiplier) + (healingBonus() * direct_coef) + 
			(baseHot[rank] * gift_of_nature_multiplier) + (healingBonus() * hot_coef)
		end,
		Tranquility = function(data, rank)
			local baseHot = { 98, 143, 211, 294 }
			data.damage = (baseHot[rank] * gift_of_nature_multiplier * 5) + (healingBonus() * tranquility_coef)
		end,
		Innervate = function(data, rank)
			data.damage = (manaRegen() * 5) * 4 * 10
		end,
		InsectSwarm = function(data, rank)
			local baseDot = { 66, 138, 174, 264, 324 }
			data.damage = baseDot[rank] + spellDamageBonus(SpellSchools.Nature) * insect_swarm_coef
		end,
	}

	addFunctionsToSpells(FeralFunctions, DruidSpells.Feral)
	addFunctionsToSpells(BalanceFunctions, DruidSpells.Balance)
	addFunctionsToSpells(RestorationFunctions, DruidSpells.Restoration)
end