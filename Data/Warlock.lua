local shortNumber, matchDigit, matchDigits, printTable, strstarts = SD.shortNumber, SD.matchDigit, SD.matchDigits, SD.printTable, SD.strstarts
local SpellUnknown, SpellEmpty, SpellDamage, SpellTimeDamage, SpellHeal, SpellTimeHeal, SpellMana, SpellTimeMana, SpellAbsorb = SD.SpellUnknown, SD.SpellEmpty, SD.SpellDamage, SD.SpellTimeDamage, SD.SpellHeal, SD.SpellTimeHeal, SD.SpellMana, SD.SpellTimeMana, SD.SpellAbsorb
local SpellDamageAndTimeDamage, SpellDamageAndMana, SpellHealAndMana, SpellHealAndTimeHeal, SpellDamageAndHeal, SpellTimeDamageAndTimeHeal, SpellDamageAndTimeHeal, SpellManaAndTimeMana, SpellTimeHealAndTimeMana, SpellAbsorbAndHeal = SD.SpellDamageAndTimeDamage, SD.SpellDamageAndMana, SD.SpellHealAndMana, SD.SpellHealAndTimeHeal, SD.SpellDamageAndHeal, SD.SpellTimeDamageAndTimeHeal, SD.SpellDamageAndTimeHeal, SD.SpellManaAndTimeMana, SD.SpellTimeHealAndTimeMana, SD.SpellAbsorbAndHeal
local SpellData, Class, ClassSpells, ClassItems = SD.SpellData, SD.Class, SD.ClassSpells, SD.ClassItems
local Damage, TimeDamage, Heal, TimeHeal, Mana, TimeMana, Absorb, CriticalDamage, DamageAndTimeDamage, HealAndTimeHeal, DamageAndHeal, DamageAndTimeHeal, HealAndMana, DamageAndDamage, DamageAndMana, TimeDamageAndTimeHeal, Custom, getLocaleIndex = SD.Damage, SD.TimeDamage, SD.Heal, SD.TimeHeal, SD.Mana, SD.TimeMana, SD.Absorb, SD.CriticalDamage, SD.DamageAndTimeDamage, SD.HealAndTimeHeal, SD.DamageAndHeal, SD.DamageAndTimeHeal, SD.HealAndMana, SD.DamageAndDamage, SD.DamageAndMana, SD.TimeDamageAndTimeHeal, SD.Custom

local Warlock = Class:create(ClassSpells)
Warlock.dependFromPower = true
Warlock.dependPowerTypes["MANA"] = true
SD.classes["WARLOCK"] = Warlock

local function spellDamageBonus(school)
	if school >= 1 and school <= 7 then
		return GetSpellBonusDamage(school)
	end
end

local function castTime(spellId)
	return select(4, GetSpellInfo(spellId)) / 1000
end

local SpellSchools = {
	Physical = 1, Holy = 2, Fire = 3, Nature = 4, Frost = 5, Shadow = 6, Arcane = 7
}

function Warlock:init()
	local function addFunctionsToSpells(functions, spellTable)
		for key, func in pairs(functions) do
			for k, v in pairs(spellTable[key]) do
				self.spells[v] = Damage(k, func)
			end
		end
	end
	
	local corruption_coef = 15 / 15
	local shadowbolt_coef = 3 / 3.5
	local shadowburn_coef = 1.5 / 3.5
	local searing_pain_coef = 1.5 / 3.5
	local immolate_direct_coef = 2 / 3.5 * 2 / 3.5 / (2 / 3.5 + 15 / 15)
	local immolate_hot_coef = 15 / 15 * 15 / 15 / (2 / 3.5 + 15 / 15)
	local death_coil_coef = 1.5 / 3.5 * 0.5
	local rain_of_fire_coef = 8 / 3.5 / 2
	local hellfire_coef = 15 / 3.5 / 2
	local curse_of_agony_coef = 15 / 15
	local curse_of_doom_coef = 15 / 15
	local drain_life_coef = 3.5 / 3.5 / 2
	local siphon_life_coef = 15 / 15 * 0.5
	local soul_fire_coef = 6 / 3.5
	local conflagrate_coef = 1.5 / 3.5
	local drain_soul_coef = 15 / 3.5 * 0.5

	local WarlockSpells = {
		Affliction = {
			Corruption = { 172, 6222, 6223, 7648, 11671, 11672, 25311 },
			CurseOfAgony = { 980, 1014, 6217, 11711, 11712, 11713 },
			CurseOfDoom = { 603 },
			DeathCoil = { 6789, 17925, 17926 },
			DrainLife = { 689, 699, 709, 7651, 11699, 11700 },
			DrainMana = { 5138, 6226, 11703, 11704 },
			DrainSoul = { 1120, 8288, 8289, 11675 },
			LifeTap = { 1454, 1455, 1456, 11687, 11688, 11689 },
			SiphonLife = { 18265, 18879, 18880, 18881 }
		},
		Demonology = {
			CreateHealthstone = { 8921, 8924, 8925, 8926, 8927, 8928, 8929, 9833, 9834, 9835 },
			HealthFunnel = { 5176, 5177, 5178, 5179, 5180, 6780, 8905, 9912 },
			Inferno = { 2912, 8949, 8950, 8951, 9875, 9876, 25298 },
			ShadowWard = { 16914, 17401, 17402 },
			CreateSpellstone = { 16914, 17401, 17402 }
		},
		Destruction = {
			Hellfire = { 5185, 5186, 5187, 5188, 5189, 6778, 8903, 9758, 9888, 9889, 25297 },
			Immolate = { 774, 1058, 1430, 2090, 2091, 3627, 8910, 9839, 9840, 9841, 25299 },
			RainOfFire = { 8936, 8938, 8939, 8940, 8941, 9750, 9856, 9857, 9858 },
			SearingPain = { 740, 8918, 9862, 9863 },
			ShadowBolt = { 29166 },
			SoulFire = { 29166 }
		}
	}

	AfflictionFunctions = {
		Corruption = function(data, rank)
			local damageByRank = { 40, 90, 222, 324, 486, 666, 822 }
			data.damage = (damageByRank[rank] + spellDamageBonus(SpellSchools.Shadow) * corruption_coef) * 1.1
		end,
		CurseOfAgony = function(data, rank)
			local damageByRank = { 84, 180, 324, 504, 780, 1044 }
			data.damage = damageByRank[rank] + spellDamageBonus(SpellSchools.Shadow) * curse_of_agony_coef
		end,
		CurseOfDoom = function(data, rank)
			local damageByRank = { 3200 }
			data.damage = damageByRank[rank] + spellDamageBonus(SpellSchools.Shadow)
		end,
		DeathCoil = function(data, rank)
			local damageByRank = { 301, 391, 476 }
			data.damage = damageByRank[rank] + spellDamageBonus(SpellSchools.Shadow)
		end,
		DrainLife = function(data, rank)
			local damageByRank = { 10, 17, 29, 41, 55, 71 }
			data.damage = (damageByRank[rank] * 1.1 * 1.1 * 5) + spellDamageBonus(SpellSchools.Shadow) * drain_life_coef
		end,
		DrainMana = function(data, rank)
			local damageByRank = { 44, 71, 102, 140 }
			data.damage = (damageByRank[rank] * 5) + spellDamageBonus(SpellSchools.Shadow)
		end,
		DrainSoul = function(data, rank)
			local damageByRank = { 55, 155, 295, 455 }
			data.damage = damageByRank[rank] + spellDamageBonus(SpellSchools.Shadow) * drain_soul_coef
		end,
		LifeTap = function(data, rank)
			local damageByRank = { 30, 75, 140, 222, 310, 424 }
			data.damage = damageByRank[rank]
		end,
		SiphonLife = function(data, rank)
			local damageByRank = { 17, 24, 36, 48 }
			data.damage = (damageByRank[rank] * 10) + spellDamageBonus(SpellSchools.Shadow) * siphon_life_coef
		end,
	}
	DemonologyFunctions = {
		CreateHealthstone = function(data, rank)
			local damageByRank = { }
			data.damage = damageByRank[rank]
		end,
		HealthFunnel = function(data, rank)
			local damageByRank = { }
			data.damage = damageByRank[rank] * drain_life_coef * 5
		end,
		Inferno = function(data, rank)
			local damageByRank = { }
			data.damage = damageByRank[rank] * 5
		end,
		ShadowWard = function(data, rank)
			local damageByRank = { }
			data.damage = damageByRank[rank] * drain_soul_coef
		end,
		CreateSpellstone = function(data, rank)
			local damageByRank = { }
			data.damage = damageByRank[rank]
		end,
	}
	DestructionFunctions = {
		Hellfire = function(data, rank)
			local damageByRank = { }
			data.damage = damageByRank[rank]
		end,
		Immolate = function(data, rank)
			local damageByRank = {  }
			data.damage = damageByRank[rank] * drain_life_coef * 5
		end,
		RainOfFire = function(data, rank)
			local damageByRank = { }
			data.damage = damageByRank[rank] * 5
		end,
		SearingPain = function(data, rank)
			local damageByRank = { }
			data.damage = damageByRank[rank] * drain_soul_coef
		end,
		ShadowBolt = function(data, rank)
			local damageByRank = {  }
			data.damage = damageByRank[rank]
		end,
		SoulFire = function(data, rank)
			local damageByRank = {  }
			data.damage = damageByRank[rank]
		end,
	}

	addFunctionsToSpells(AfflictionFunctions, WarlockSpells.Affliction)
	addFunctionsToSpells(DemonologyFunctions, WarlockSpells.Demonology)
	addFunctionsToSpells(DestructionFunctions, WarlockSpells.Destruction)
end