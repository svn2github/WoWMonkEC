local _, trueclass = UnitClass("player")
if trueclass ~= "MONK" then return end

MonkEC.theGCD = 1.0
MonkEC.fistsOfFuryDuration = 4.0

-- Talents
MonkEC.talentSpec = -1 -- Brewmaster (1), Mistweaver (2), Windwalker (3)
MonkEC.talentSpecBrewmaster = 1
MonkEC.talentSpecMistweaver = 2
MonkEC.talentSpecWindwalker = 3
MonkEC.brewmasterStance = 1
MonkEC.windwalkerStance = 2
MonkEC.haveHealingElixirs = false

-- Resources (chi and energy)
MonkEC.chiPowerType = 12
MonkEC.maxChi = 4
MonkEC.maximumChiGain = 1
MonkEC.energyPowerType = 3
MonkEC.energyGeneratedPerGCD = 10

-- Buff lengths
MonkEC.shuffleBuffLength = 8
MonkEC.energizingBrewBuffLength = 6
MonkEC.tigerPowerBuffLength = 20
MonkEC.tigerPowerMaxStack = 3

-- Buff info
local elusiveBrewCount, elusiveBrewSecondsLeft, elusiveBrewSpell
local energizingBrewCount, energizingBrewSecondsLeft, energizingBrewSpell
local shuffleCount, shuffleSecondsLeft, shuffleSpell
local tigerPowerCount, tigerPowerSecondsLeft, tigerPowerSpell
local tigerEyeCount, tigerEyeSecondsLeft, tigerEyeSpell

-- Debuff lengths
MonkEC.breathOfFireDebuffLength = 8
MonkEC.blackoutKickDebuffLength = 4
MonkEC.risingSunKickDebuffLength = 15

-- Debuff info
local breathOfFireCount, breathOfFireSecondsLeft
local risingSunKickCount, risingSunKickSecondsLeft

function MonkEC:GetSpellData(id) 
	local name, _, icon, _, _, _ = GetSpellInfo(id); 
	return { name=name, id=id, icon=icon } 
 end 
 
-- Spells shared between specs
MonkEC.common = {
	blackoutKick = MonkEC:GetSpellData(100784),
	expelHarm = MonkEC:GetSpellData(115072),
	jab = MonkEC:GetSpellData(100780),
	paralysis = MonkEC:GetSpellData(115078),
	spearHandStrike = MonkEC:GetSpellData(116705),
	spinningCraneKick = MonkEC:GetSpellData(101546),
	tigerPalm = MonkEC:GetSpellData(100787),
	touchOfDeath = MonkEC:GetSpellData(115080),
	zenMeditation = MonkEC:GetSpellData(115176),
}
 
-- Spell form Talents
MonkEC.talent = {
	-- lvl 15
	tigersLust = MonkEC:GetSpellData(116841),

	-- lvl 30
	chiBurst = MonkEC:GetSpellData(123986),
	chiWave = MonkEC:GetSpellData(115098),
	zenSphere = MonkEC:GetSpellData(124081),

	-- lvl 45
	ascension = MonkEC:GetSpellData(115396),
	chiBrew = MonkEC:GetSpellData(115399),
	powerStrikes = MonkEC:GetSpellData(121817),

	-- lvl 60
	chargingOxWave = MonkEC:GetSpellData(119392),
	legSweep = MonkEC:GetSpellData(119381),

	-- lvl 75
	dampenHarm = MonkEC:GetSpellData(122278),
	diffuseMagic = MonkEC:GetSpellData(122783),
	healingElixirs = MonkEC:GetSpellData(122280),

	-- lvl 90
	invokeXuen = MonkEC:GetSpellData(123904),
	rushingJadeWind = MonkEC:GetSpellData(116847),
	chiTorpedo = MonkEC:GetSpellData(115008),

	-- lvl 100
	hurricaneStrike = MonkEC:GetSpellData(158221),
	chiExplosion = MonkEC:GetSpellData(157676),
	chiExplosion = MonkEC:GetSpellData(152174),
	serenity = MonkEC:GetSpellData(152173),
}

MonkEC.brewmaster = {
	avertHarm = MonkEC:GetSpellData(115213),
	breathOfFire = MonkEC:GetSpellData(115181),
	clash = MonkEC:GetSpellData(122057),
	dizzyingHaze = MonkEC:GetSpellData(115180),
	elusiveBrew	= MonkEC:GetSpellData(115308),	
	fortifyingBrew = MonkEC:GetSpellData(115203),	
	guard = MonkEC:GetSpellData(115295),
	kegSmash = MonkEC:GetSpellData(121253),
	leerOfTheOx = MonkEC:GetSpellData(115543),
	provoke = MonkEC:GetSpellData(115546),
	purifyingBrew = MonkEC:GetSpellData(119582),
	stanceOfTheSturdyOx = MonkEC:GetSpellData(115069),
	summonBlackOxStatue = MonkEC:GetSpellData(115315),
}

MonkEC.windwalker = {
	energizingBrew = MonkEC:GetSpellData(115288),
	fistsOfFury = MonkEC:GetSpellData(113656),
	flyingSerpentKick = MonkEC:GetSpellData(101545),
	legacyOfTheWhiteTiger = MonkEC:GetSpellData(116781),
	risingSunKick = MonkEC:GetSpellData(107428),
	stanceOfTheFierceTiger = MonkEC:GetSpellData(103985),
	tigerEyeBrew = MonkEC:GetSpellData(116740),
}

-- Spell Details for Buffs
MonkEC.buff = {
	comboBreakerBlackoutKick = MonkEC:GetSpellData(116768),
	comboBreakerTigerPalm = MonkEC:GetSpellData(118864),
	heroism = MonkEC:GetSpellData(32182),
	legacyOfTheWhiteTiger = MonkEC:GetSpellData(116781),
	powerGuard = MonkEC:GetSpellData(118636),
	sanctuaryOfTheOx = MonkEC:GetSpellData(126119),
	shuffle	= MonkEC:GetSpellData(115307),
	tigerPower = MonkEC:GetSpellData(125359),
	tigerEye = MonkEC:GetSpellData(123980),
}

 -- Spell details for Debuffs
MonkEC.debuff = {
	blackoutKick = MonkEC:GetSpellData(128531),
	mortalWounds = MonkEC:GetSpellData(115804),	
	lightStagger = MonkEC:GetSpellData(124275),
	moderateStagger = MonkEC:GetSpellData(124274),
	heavyStagger = MonkEC:GetSpellData(124273),
}

MonkEC.external = {
	-- Buff Equivalents
	markOfTheWild = MonkEC:GetSpellData(1126),
	blessingOfKings = MonkEC:GetSpellData(20217),
	embraceOfTheShaleSpider = MonkEC:GetSpellData(90363),
	leaderOfThePack = MonkEC:GetSpellData(17007),
	arcaneBrilliance = MonkEC:GetSpellData(1459),
	dalaranBrilliance = MonkEC:GetSpellData(61316),
	furiousHowl = MonkEC:GetSpellData(24604),
	terrifyingRoar = MonkEC:GetSpellData(90309),
	fearlessRoar = MonkEC:GetSpellData(126373),
	stillWater = MonkEC:GetSpellData(126309),
	bloodlust = MonkEC:GetSpellData(2825),
	heroism = MonkEC:GetSpellData(32182),
	timeWarp = MonkEC:GetSpellData(80353),
	ancientHysteria = MonkEC:GetSpellData(90355),
}

function MonkEC:InspectSpecialization()
	MonkEC.talentSpec = GetSpecialization()

	if (MonkEC.talentSpec == MonkEC.talentSpecBrewmaster) then
		MonkEC.cooldownFrame.cooldown[1].spell = MonkEC.brewmaster.avertHarm
		MonkEC.cooldownFrame.cooldown[2].spell = MonkEC.brewmaster.clash
		MonkEC.cooldownFrame.cooldown[3].spell = MonkEC.brewmaster.fortifyingBrew
		MonkEC.cooldownFrame.cooldown[4].spell = MonkEC.brewmaster.guard
		MonkEC.cooldownFrame.cooldown[5].spell = MonkEC.brewmaster.guard
		MonkEC.energyGeneratedPerGCD = 8
	elseif (MonkEC.talentSpec == MonkEC.talentSpecWindwalker) then
		MonkEC.cooldownFrame.cooldown[1].spell = MonkEC.windwalker.energizingBrew
		MonkEC.cooldownFrame.cooldown[2].spell = MonkEC.windwalker.fistsOfFury
		MonkEC.cooldownFrame.cooldown[3].spell = MonkEC:Level90Talent()
		MonkEC.cooldownFrame.cooldown[4].spell = MonkEC:Level30Talent()
		MonkEC.cooldownFrame.cooldown[5].spell = MonkEC:Level100Talent()
		MonkEC.energyGeneratedPerGCD = 10
	end	

	MonkEC.haveHealingElixirs = GetSpellBookItemInfo(MonkEC.talent.healingElixirs.name) ~= nil

	if UnitLevel("player") < 91 then
		MonkEC.maxChi = 4
	else
		MonkEC.maxChi = 5
	end

	if GetSpellBookItemInfo(MonkEC.talent.ascension.name) ~= nil then
		MonkEC.maxChi = MonkEC.maxChi + 1
		MonkEC.energyGeneratedPerGCD = MonkEC.energyGeneratedPerGCD * 1.15
	end
	
	if GetSpellBookItemInfo(MonkEC.talent.powerStrikes.name) ~= nil then
		MonkEC.maximumChiGain = 2
	end
end

function MonkEC:SetChiGeneration()
	self.common.expelHarm.chiGenerated = MonkEC.maximumChiGain
	self.common.spinningCraneKick.chiGenerated = MonkEC.maximumChiGain
	self.talent.chiBrew.chiGenerated = 2
	self.brewmaster.kegSmash.chiGenerated = MonkEC.maximumChiGain
	self.common.jab.chiGenerated = MonkEC.maximumChiGain
	if MonkEC.talentSpec == MonkEC.talentSpecWindwalker then
		self.common.jab.chiGenerated = self.common.jab.chiGenerated + 1
	end
end

function MonkEC:SetMinimumLevel()
	self.brewmaster.breathOfFire.minimumLevel = 18
	self.windwalker.flyingSerpentKick.minimumLevel = 18
	self.common.touchOfDeath.minimumLevel = 22
	self.brewmaster.fortifyingBrew.minimumLevel = 24
	self.brewmaster.guard.minimumLevel = 26
	self.common.expelHarm.minimumLevel = 26
	self.common.spearHandStrike.minimumLevel = 32
	self.windwalker.energizingBrew.minimumLevel = 36
	self.common.spinningCraneKick.minimumLevel = 46
	self.brewmaster.elusiveBrew.minimumLevel = 56
	self.windwalker.risingSunKick.minimumLevel = 56
	self.brewmaster.summonBlackOxStatue.minimumLevel = 70
	self.brewmaster.purifyingBrew.minimumLevel = 75
	self.windwalker.legacyOfTheWhiteTiger.minimumLevel = 81
end

function MonkEC:SetSpellCooldowns()
	self.common.expelHarm.cooldownLength = 15
	self.common.paralysis.cooldownLength = 15
	self.common.spearHandStrike.cooldownLength = 15
	self.common.touchOfDeath.cooldownLength = 90
	self.talent.tigersLust.cooldownLength = 30
	self.talent.chiWave.cooldownLength = 8
	self.talent.chiBrew.cooldownLength = 90
	self.talent.chargingOxWave.cooldownLength = 60
	self.talent.legSweep.cooldownLength = 25
	self.talent.dampenHarm.cooldownLength = 90
	self.talent.diffuseMagic.cooldownLength = 90
	self.talent.invokeXuen.cooldownLength = 80
	self.talent.rushingJadeWind.cooldownLength = 30
	self.talent.serenity.cooldownLength = 90
	self.brewmaster.avertHarm.cooldownLength = 60
	self.brewmaster.clash.cooldownLength = 35
	self.brewmaster.fortifyingBrew.cooldownLength = 180
	self.brewmaster.guard.cooldownLength = 30
	self.brewmaster.kegSmash.cooldownLength = 8
	self.brewmaster.leerOfTheOx.cooldownLength = 20
	self.brewmaster.provoke.cooldownLength = 8
	self.brewmaster.summonBlackOxStatue.cooldownLength = 180
	self.windwalker.energizingBrew.cooldownLength = 60
	self.windwalker.fistsOfFury.cooldownLength = 25
	self.windwalker.flyingSerpentKick.cooldownLength = 25
	self.windwalker.risingSunKick.cooldownLength = 8
end

--temp
function MonkEC:SetSpellCosts()
	self.brewmaster.breathOfFire.cost = 2
	self.brewmaster.guard.cost = 2
	self.brewmaster.kegSmash.cost = 40
	self.common.blackoutKick.cost = 2
	self.common.expelHarm.cost = 40
	self.common.jab.cost = 40
	self.common.spinningCraneKick.cost = 40
	self.common.tigerPalm.cost = 1
	self.common.touchOfDeath.cost = 3
	self.windwalker.fistsOfFury.cost = 3
	self.windwalker.risingSunKick.cost = 2
	
	self.brewmaster.breathOfFire.powerType = MonkEC.chiPowerType
	self.brewmaster.guard.powerType = MonkEC.chiPowerType
	self.brewmaster.kegSmash.powerType = MonkEC.energyPowerType
	self.common.blackoutKick.powerType = MonkEC.chiPowerType
	self.common.expelHarm.powerType = MonkEC.energyPowerType
	self.common.jab.powerType = MonkEC.energyPowerType
	self.common.spinningCraneKick.powerType = MonkEC.energyPowerType
	self.common.tigerPalm.powerType = MonkEC.chiPowerType
	self.common.touchOfDeath.powerType = MonkEC.chiPowerType
	self.windwalker.fistsOfFury.powerType = MonkEC.chiPowerType
	self.windwalker.risingSunKick.powerType = MonkEC.chiPowerType
end

function MonkEC:Level30Talent()
	local spell = nil
	local currentSpec = GetActiveSpecGroup()
	local _, _, _, selected, _ = GetTalentInfo(2, 1, currentSpec)
	if (selected) then
		spell = MonkEC.talent.chiWave
	else
		_, _, _, selected, _ = GetTalentInfo(2, 2, currentSpec)
		if (selected) then
			spell = MonkEC.talent.zenSphere
		else
			_, _, _, selected, _ = GetTalentInfo(2, 3, currentSpec)
			if (selected) then
				spell = MonkEC.talent.chiBurst
			end
		end
	end
	
	return spell
end

function MonkEC:Level45Talent()
	local spell = nil
	local currentSpec = GetActiveSpecGroup()
	_, _, _, selected, _ = GetTalentInfo(3, 3, currentSpec)
	if (selected) then
		spell = MonkEC.talent.chiBrew
	end
	
	return spell
end

function MonkEC:Level90Talent()
	local spell = nil
	local currentSpec = GetActiveSpecGroup()
	local _, _, _, selected, _ = GetTalentInfo(6, 1, currentSpec)
	if (selected) then
		spell = MonkEC.talent.rushingJadeWind
	else
		_, _, _, selected, _ = GetTalentInfo(6, 2, currentSpec)
		if (selected) then
			spell = MonkEC.talent.invokeXuen
		else
			_, _, _, selected, _ = GetTalentInfo(6, 3, currentSpec)
			if (selected) then
				spell = MonkEC.talent.chiTorpedo
			end
		end
	end
	
	return spell
end

function MonkEC:Level100Talent()
	local spell = nil
	local currentSpec = GetActiveSpecGroup()
	local _, _, _, selected, _ = GetTalentInfo(7, 1, currentSpec)
	if (selected) then
		spell = MonkEC.talent.hurricaneStrike
	else
		_, _, _, selected, _ = GetTalentInfo(7, 2, currentSpec)
		if (selected) then
			spell = MonkEC.talent.chiExplosion
		else
			_, _, _, selected, _ = GetTalentInfo(7, 3, currentSpec)
			if (selected) then
				spell = MonkEC.talent.serenity
			end
		end
	end
	
	return spell
end

function MonkEC:GetBuffInfo(num)
	local buffInfo

	if MonkEC.talentSpec == MonkEC.talentSpecBrewmaster then
		if num == 1 then
			return shuffleSpell,shuffleSecondsLeft,shuffleCount
		elseif num == 2 then
			return elusiveBrewSpell,elusiveBrewSecondsLeft,elusiveBrewCount
		elseif num == 3 then
			return tigerPowerSpell,tigerPowerSecondsLeft,tigerPowerCount
		end
	elseif MonkEC.talentSpec == MonkEC.talentSpecWindwalker then
		if num == 1 then
			return mortalWoundsIcon,mortalWoundsSecondsLeft,mortalWoundsCount
		elseif num == 2 then
			return tigerEyeSpell,tigerEyeSecondsLeft,tigerEyeCount
		elseif num == 3 then
			return blackoutKickDebuffSpell,blackoutKickDebuffSecondsLeft,blackoutKickDebuffCount
		elseif num == 4 then
			return tigerPowerSpell,tigerPowerSecondsLeft,tigerPowerCount
		end
	end

	return buffInfo
end

function MonkEC:UpdateTrackedBuffs()
	local elusiveBrewExpirationTime = nil
	local mortalWoundsExpirationTime = nil
	local sanctuaryOfTheOxExpirationTime = nil
	local shuffleExpirationTime = nil
	local tigerPowerExpirationTime = nil
	local breathOfFireExpirationTime = nil
	local risingSunKickExpirationTime = nil
	
	shuffleSpell = MonkEC.buff.shuffle
	_,_,_,shuffleCount,_,_,shuffleExpirationTime,_,_ = UnitAura("player", MonkEC.buff.shuffle.name)
	if shuffleExpirationTime ~= nil then
		shuffleSecondsLeft = shuffleExpirationTime - GetTime()
	else
		shuffleSecondsLeft = 0
	end
	
	elusiveBrewSpell = MonkEC.brewmaster.elusiveBrew
	_,_,_,elusiveBrewCount,_,_,elusiveBrewExpirationTime,_,_ = UnitAura("player", MonkEC.brewmaster.elusiveBrew.name)
	if elusiveBrewExpirationTime ~= nil then
		elusiveBrewSecondsLeft = elusiveBrewExpirationTime - GetTime()
	else
		elusiveBrewSecondsLeft = 0
	end
	
	tigerPowerSpell = MonkEC.buff.tigerPower
	_,_,_,tigerPowerCount,_,_,tigerPowerExpirationTime,_,_ = UnitAura("player", MonkEC.buff.tigerPower.name)
	if tigerPowerExpirationTime ~= nil then
		tigerPowerSecondsLeft = tigerPowerExpirationTime - GetTime()
	else
		tigerPowerSecondsLeft = 0
	end
	
	_,_,_,_,_,_,breathOfFireExpirationTime,_,_ = UnitDebuff("target", MonkEC.brewmaster.breathOfFire.name)
	if breathOfFireExpirationTime ~= nil then
		breathOfFireSecondsLeft = breathOfFireExpirationTime - GetTime()
	else
		breathOfFireSecondsLeft = 0
	end
	
	-- Windwalker
	tigerEyeSpell = MonkEC.windwalker.tigerEyeBrew
	_,_,_,tigerEyeCount,_,_,tigerEyeExpirationTime,_,_ = UnitAura("player", tigerEyeSpell.name)
	if tigerEyeExpirationTime ~= nil then
		tigerEyeSecondsLeft = tigerEyeExpirationTime - GetTime()
	else
		tigerEyeSecondsLeft = 0
	end
	
	blackoutKickDebuffSpell = MonkEC.debuff.blackoutKick
	_,_,_,blackoutKickDebuffCount,_,_,blackoutKickDebuffExpirationTime,_,_ = UnitDebuff("target", blackoutKickDebuffSpell.name)
	if blackoutKickDebuffExpirationTime ~= nil then
		blackoutKickDebuffSecondsLeft = blackoutKickDebuffExpirationTime - GetTime()
	else
		blackoutKickDebuffSecondsLeft = 0
	end

	energizingBrewBuffSpell = MonkEC.windwalker.energizingBrew
	_,_,_,energizingBrewBuffCount,_,_,energizingBrewBuffExpirationTime,_,_ = UnitAura("player", energizingBrewBuffSpell.name)
	if energizingBrewBuffExpirationTime ~= nil then
		energizingBrewSecondsLeft = energizingBrewBuffExpirationTime - GetTime()
	else
		energizingBrewSecondsLeft = 0
	end
		
	mortalWoundsIcon = MonkEC.debuff.mortalWounds
	_,_,_,mortalWoundsCount,_,_,mortalWoundsExpirationTime,_,_ = UnitDebuff("target", MonkEC.debuff.mortalWounds.name)
	if mortalWoundsExpirationTime ~= nil then
		mortalWoundsSecondsLeft = mortalWoundsExpirationTime - GetTime()
	else
		mortalWoundsSecondsLeft = 0
	end
	
	_,_,_,_,_,_,risingSunKickExpirationTime,_,_ = UnitDebuff("target", MonkEC.windwalker.risingSunKick.name)
	if risingSunKickExpirationTime ~= nil then
		risingSunKickSecondsLeft = risingSunKickExpirationTime - GetTime()
	else
		risingSunKickSecondsLeft = 0
	end
end

function MonkEC:GatherCharacterState(currentBaseGCD)
	playerHasHasteBuff = UnitBuff("player", self.external.bloodlust.name) ~= nil or
		UnitBuff("player", self.external.heroism.name) ~= nil or
		UnitBuff("player", self.external.timeWarp.name) ~= nil or
		UnitBuff("player", self.external.ancientHysteria.name) ~= nil
	playerHasStatBoost = UnitBuff("player", self.buff.legacyOfTheWhiteTiger.name) ~= nil or
		UnitBuff("player", self.external.markOfTheWild.name) ~= nil or
		UnitBuff("player", self.external.blessingOfKings.name) ~= nil or
		UnitBuff("player", self.external.embraceOfTheShaleSpider.name) ~= nil
	playerHasCritBoost = UnitBuff("player", self.buff.legacyOfTheWhiteTiger.name) ~= nil or
		UnitBuff("player", self.external.leaderOfThePack.name) ~= nil or
		UnitBuff("player", self.external.arcaneBrilliance.name) ~= nil or
		UnitBuff("player", self.external.dalaranBrilliance.name) ~= nil or
		UnitBuff("player", self.external.furiousHowl.name) ~= nil or
		UnitBuff("player", self.external.terrifyingRoar.name) ~= nil or
		UnitBuff("player", self.external.fearlessRoar.name) ~= nil or
		UnitBuff("player", self.external.stillWater.name) ~= nil
	
	local state = {
		talentSpec = MonkEC.talentSpec,
		level = UnitLevel("player"),
		stance = GetShapeshiftForm(),
		hasted = playerHasHasteBuff,
		haveHealingElixirs = MonkEC.haveHealingElixirs,
		doAOE = self.db.profile.suggest_aoe,
		inMeleeRange = IsSpellInRange(self.common.jab.name, "target") == 1,
		currentHealthPercentage = UnitHealth("player") / UnitHealthMax("player") * 100,
		chi = UnitPower("player", SPELL_POWER_CHI),
		energy = UnitPower("player"),
		
		playerHasLegacyOfTheWhiteTiger = (playerHasCritBoost and playerHasStatBoost),
		
		hasComboBreakerBlackoutKick = UnitBuff("player", self.buff.comboBreakerBlackoutKick.name) ~= nil,
		hasComboBreakerTigerPalm = UnitBuff("player", self.buff.comboBreakerTigerPalm.name) ~= nil,

		shuffleSecondsLeft = shuffleSecondsLeft,
		staggerTooHigh = (UnitDebuff("player", self.debuff.moderateStagger.name) ~= nil) or 
						(UnitDebuff("player", self.debuff.heavyStagger.name) ~= nil),
		elusiveBrewCount = elusiveBrewCount,
		tigerEyeCount = tigerEyeCount,
		energizingBrewSecondsLeft = energizingBrewSecondsLeft,
		tigerPowerSecondsLeft = tigerPowerSecondsLeft,
		breathOfFireSecondsLeft = breathOfFireSecondsLeft,
		risingSunKickSecondsLeft = risingSunKickSecondsLeft,
		blackoutKickDebuffSecondsLeft = blackoutKickDebuffSecondsLeft,
	}

	if state.doAOE == nil then
		state.doAOE = false
	end
		
	if state.shuffleSecondsLeft == nil then
		state.shuffleSecondsLeft = 0
	end
	
	if state.elusiveBrewCount == nil then
		state.elusiveBrewCount = 0
	end
	
	if state.tigerEyeCount == nil then
		state.tigerEyeCount = 0
	end
	
	if state.tigerPowerCount == nil then
		state.tigerPowerCount = 0
	end
	
	if state.tigerPowerSecondsLeft == nil then
		state.tigerPowerSecondsLeft = 0
	end

	if state.energizingBrewSecondsLeft == nil then
		state.energizingBrewSecondsLeft = 0
	end
	
	if state.breathOfFireSecondsLeft == nil then
		state.breathOfFireSecondsLeft = 0
	end
	
	if state.risingSunKickSecondsLeft == nil then
		state.risingSunKickSecondsLeft = 0
	end
	
	if state.blackoutKickDebuffSecondsLeft == nil then
		state.blackoutKickDebuffSecondsLeft = 0
	end
	
	return state
end

function MonkEC:UpdateCooldowns(currentGCD, spellList)
	for key,spell in pairs(spellList) do
		local startTime,duration = GetSpellCooldown(spell.id)
		if (startTime > 0) then
			spell.cooldown = duration - (GetTime() - startTime)
		else
			spell.cooldown = 0
		end
	end
end
