local _, trueclass = UnitClass("player")
if trueclass ~= "MONK" then return end

MonkEC.theGCD = 1.0

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
MonkEC.energyGeneratedPerGCD_brewmaster = 8

-- Buff lengths
MonkEC.shuffleBuffLength = 8
MonkEC.tigerPowerBuffLength = 20
MonkEC.tigerPowerMaxStack = 3
MonkEC.weakenedBlowsDebuffLength = 15

-- Buff info
local elusiveBrewCount, elusiveBrewSecondsLeft, elusiveBrewSpell
local sanctuaryOfTheOxCount, sanctuaryOfTheOxSecondsLeft, sanctuaryOfTheOxSpell
local shuffleCount, shuffleSecondsLeft, shuffleSpell
local tigerPowerCount, tigerPowerSecondsLeft, tigerPowerSpell
local tigerEyeCount, tigerEyeSecondsLeft, tigerEyeSpell
local weakenedBlowsCount,weakenedBlowsSecondsLeft,weakenedBlowsSpell

-- Debuff lengths
MonkEC.breathOfFireDebuffLength = 8

-- Debuff info
local breathOfFireCount, breathOfFireSecondsLeft, breathOfFireSpell

function MonkEC:GetSpellData(id) 
	local name, _, icon, cost, _, powerType = GetSpellInfo(id); 

	return { name=name, id=id, icon=icon, cost=cost, powerType=powerType } 
 end 
 
-- Spells shared between specs
MonkEC.common = {
	blackoutKick = MonkEC:GetSpellData(100784),
	expelHarm = MonkEC:GetSpellData(115072),
	jab = MonkEC:GetSpellData(100780),
	legacyOfTheEmperor = MonkEC:GetSpellData(115921),
	paralysis = MonkEC:GetSpellData(115078),
	pathOfBlossoms = MonkEC:GetSpellData(124336),
	spearHandStrike = MonkEC:GetSpellData(116705),
	spinningCraneKick = MonkEC:GetSpellData(101546),
	spinningFireBlossom = MonkEC:GetSpellData(115073),
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
	spinningFireBlossom = MonkEC:GetSpellData(115073),
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
	fistsOfFury = MonkEC:GetSpellData(117418),
	flyingSerpentKick = MonkEC:GetSpellData(101545),
	legacyOfTheWhiteTiger = MonkEC:GetSpellData(116781),
	risingSunKick = MonkEC:GetSpellData(107428),
	spinningFireBlossom = MonkEC:GetSpellData(115073),
	stanceOfTheFierceTiger = MonkEC:GetSpellData(103985),
	tigerEyeBrew = MonkEC:GetSpellData(116740),
}

-- Spell Details for Buffs
MonkEC.buff = {
	legacyOfTheWhiteTiger = MonkEC:GetSpellData(116781),
	powerGuard = MonkEC:GetSpellData(118636),
	sanctuaryOfTheOx = MonkEC:GetSpellData(126119),
	shuffle	= MonkEC:GetSpellData(115307),
	tigerPower = MonkEC:GetSpellData(125359),
	tigerEye = MonkEC:GetSpellData(125195),
}

 -- Spell details for Debuffs
MonkEC.debuff = {
	mortalWounds = MonkEC:GetSpellData(115804),	
	weakenedBlows = MonkEC:GetSpellData(115798),
	lightStagger = MonkEC:GetSpellData(124275),
	moderateStagger = MonkEC:GetSpellData(124274),
	heavyStagger = MonkEC:GetSpellData(124273),
}

-- Spell Details for Equivalent Debuffs
MonkEC.external = {
	-- Physical Damage Debuff Equivalents
	earthShock = MonkEC:GetSpellData(8042),
	hammerOfTheRighteous = MonkEC:GetSpellData(115801),
	scarletFever = MonkEC:GetSpellData(81132),
	thrash = MonkEC:GetSpellData(115800),
	thunderclap = MonkEC:GetSpellData(115799),
	markOfTheWild = MonkEC:GetSpellData(1126),
	blessingOfKings = MonkEC:GetSpellData(20217),
	embraceOfTheShaleSpider = MonkEC:GetSpellData(90363),
}

function MonkEC:InspectSpecialization()
	MonkEC.talentSpec = GetSpecialization()

	if GetSpellBookItemInfo(MonkEC.talent.ascension.name) ~= nil then
		MonkEC.maxChi = 5
	end
	if GetSpellBookItemInfo(MonkEC.talent.powerStrikes.name) ~= nil then
		MonkEC.maximumChiGain = 2
	end
	
	MonkEC.haveHealingElixirs = GetSpellBookItemInfo(MonkEC.talent.healingElixirs.name) ~= nil
	
	-- TODO remove when bug is fixed
	if self.common.blackoutKick.cost ~= 2 then
		self:Print("Blackout Kick cost is incorrect (" .. tostring(self.common.blackoutKick.cost) .. " vs 2).  Working around it.")
		self.common.blackoutKick.cost = 2
	end
	if self.common.touchOfDeath.cost ~= 3 then
		self:Print("Touch of Death cost is incorrect (" .. tostring(self.common.touchOfDeath.cost) .. " vs 3).  Working around it.")
		self.common.touchOfDeath.cost = 3
	end
	if MonkEC.talentSpec == MonkEC.talentSpecBrewmaster then
		if self.brewmaster.guard.cost ~= 2 then
			self:Print("Guard cost is incorrect (" .. tostring(self.brewmaster.guard.cost) .. " vs 2).  Working around it.")
			self.brewmaster.guard.cost = 2
		end
		if self.brewmaster.breathOfFire.cost ~= 2 then
			self:Print("Breath of fire cost is incorrect (" .. tostring(self.brewmaster.breathOfFire.cost) .. " vs 2).  Working around it.")
			self.brewmaster.breathOfFire.cost = 2
		end
	end
	if self.talent.chiBurst.cost ~= 2 then
		self:Print("Chi Burst cost is incorrect (" .. tostring(self.talent.chiBurst.cost) .. " vs 2).  Working around it.")
		self.talent.chiBurst.cost = 2
	end
	if self.talent.zenSphere.cost ~= 2 then
		self:Print("Zen Sphere cost is incorrect (" .. tostring(self.talent.zenSphere.cost) .. " vs 2).  Working around it.")
		self.talent.zenSphere.cost = 2
	end
	if self.talent.chiWave.cost ~= 2 then
		self:Print("Chi Wave cost is incorrect (" .. tostring(self.talent.chiWave.cost) .. " vs 2).  Working around it.")
		self.talent.chiWave.cost = 2
	end
	if MonkEC.talentSpec == MonkEC.talentSpecWindwalker then
		if self.windwalker.spinningFireBlossom.cost ~= 1 then
			self:Print("Spinning Fire Blossom cost is incorrect (" .. tostring(self.windwalker.spinningFireBlossom.cost) .. " vs 1).  Working around it.")
			self.windwalker.spinningFireBlossom.cost = 1
		end
		if self.windwalker.fistsOfFury.cost ~= 3 then
			self:Print("Fists of Fury cost is incorrect (" .. tostring(self.windwalker.fistsOfFury.cost) .. " vs 3).  Working around it.")
			self.windwalker.fistsOfFury.cost = 3
			self.windwalker.fistsOfFury.powerType = MonkEC.chiPowerType
			self.windwalker.fistsOfFury.cooldown = 25
		end
		if self.windwalker.risingSunKick.cost ~= 2 then
			self:Print("Rising Sun cost is incorrect (" .. tostring(self.windwalker.risingSunKick.cost) .. " vs 2).  Working around it.")
			self.windwalker.risingSunKick.cost = 2
		end
	end
end

function MonkEC:SetChiGeneration()
	self.common.expelHarm.chiGenerated = MonkEC.maximumChiGain
	self.common.jab.chiGenerated = MonkEC.maximumChiGain
	self.common.spinningCraneKick.chiGenerated = MonkEC.maximumChiGain
	self.talent.chiBrew.chiGenerated = MonkEC.maxChi
	self.brewmaster.kegSmash.chiGenerated = MonkEC.maximumChiGain
end

function MonkEC:SetMinimumLevel()
	self.common.legacyOfTheEmperor.minimumLevel = 22
	self.common.touchOfDeath.minimumLevel = 22
	self.brewmaster.fortifyingBrew.minimumLevel = 24
	self.common.expelHarm.minimumLevel = 26
	self.common.spearHandStrike.minimumLevel = 32
	self.common.spinningCraneKick.minimumLevel = 46
	self.brewmaster.elusiveBrew.minimumLevel = 56
	self.brewmaster.summonBlackOxStatue.minimumLevel = 70
	self.brewmaster.purifyingBrew.minimumLevel = 75
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

function MonkEC:Level30Talent()
	local spell = nil
	
	-- for i = 1,18 do
		-- local name, texture, tier, column, selected, available = GetTalentInfo(i)
		-- self:Print("GetTalentInfo " .. i .. " name " .. tostring(name) .. " selected=" .. tostring(selected))
	-- end
	
	local name,_,_,_,selected,_ = GetTalentInfo(6)
	if selected then
		spell = MonkEC.talent.chiBurst
	else
		name,_,_,_,selected,_ = GetTalentInfo(4)
		if selected then
			spell = MonkEC.talent.chiWave
		else
			name,_,_,_,selected,_ = GetTalentInfo(5)
			if selected then
				spell = MonkEC.talent.zenSphere
			end
		end
	end

	if spell == nil then -- TODO bug workaround
		spell = MonkEC.talent.zenSphere
		self:Print("Can't figure out lvl30 spell.  Forcing to " .. spell.name)
	end
	
	return spell
end

function MonkEC:GetBuffInfo(num)
	local buffInfo
	if num == 1 then
		return weakenedBlowsSpell,weakenedBlowsSecondsLeft,weakenedBlowsCount
	elseif num == 2 then
		return shuffleSpell,shuffleSecondsLeft,shuffleCount
	elseif num == 3 then
		return elusiveBrewSpell,elusiveBrewSecondsLeft,elusiveBrewCount
	elseif num == 4 then
		return tigerPowerSpell,tigerPowerSecondsLeft,tigerPowerCount
	elseif num == 5 then
		return sanctuaryOfTheOxSpell,sanctuaryOfTheOxTime,sanctuaryOfTheOxCount
	elseif num == 6 then
		return tigerEyeSpell,tigerEyeTime,tigerEyeCount
	else
		return mortalWoundsIcon,mortalWoundsSecondsLeft,mortalWoundsCount
	end

	return buffInfo
end

function MonkEC:UpdateTrackedBuffs()
	local elusiveBrewExpirationTime = nil
	local mortalWoundsExpirationTime = nil
	local sanctuaryOfTheOxExpirationTime = nil
	local shuffleExpirationTime = nil
	local tigerPowerExpirationTime = nil
	local weakenedBlowsExpirationTime = nil
	local breathOfFireExpirationTime = nil

	_,_,_,weakenedBlowsExpirationCount,_,_,weakenedBlowsExpirationTime,_,_ = UnitDebuff("target", MonkEC.external.earthShock.name)
	if (weakenedBlowsExpirationTime ~= nil) then
		weakenedBlowsSpell = MonkEC.external.earthShock
	else
		_,_,_,weakenedBlowsExpirationCount,_,_,weakenedBlowsExpirationTime,_,_ = UnitDebuff("target", MonkEC.external.hammerOfTheRighteous.name)
		if (weakenedBlowsExpirationTime ~= nil) then
			weakenedBlowsSpell = MonkEC.external.hammerOfTheRighteous
		else
			_,_,_,weakenedBlowsExpirationCount,_,_,weakenedBlowsExpirationTime,_,_ = UnitDebuff("target", MonkEC.external.scarletFever.name)
			if (weakenedBlowsExpirationTime ~= nil) then
				weakenedBlowsSpell = MonkEC.external.scarletFever
			else
				_,_,_,weakenedBlowsExpirationCount,_,_,weakenedBlowsExpirationTime,_,_ = UnitDebuff("target", MonkEC.external.thunderclap.name)
				if (weakenedBlowsExpirationTime ~= nil) then
					weakenedBlowsSpell = MonkEC.debuff.thunderclap
				else
					_,_,_,weakenedBlowsExpirationCount,_,_,weakenedBlowsExpirationTime,_,_ = UnitDebuff("target", MonkEC.brewmaster.dizzyingHaze.name)
					if (weakenedBlowsExpirationTime ~= nil) then
						weakenedBlowsSpell = MonkEC.brewmaster.kegSmash
					else
						weakenedBlowsSpell = MonkEC.debuff.weakenedBlows
					end
				end
			end
		end
	end
	if weakenedBlowsExpirationTime ~= nil then
		weakenedBlowsSecondsLeft = weakenedBlowsExpirationTime - GetTime()
	else
		weakenedBlowsSecondsLeft = 0
	end
	
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
	
	tigerPowerSpell = MonkEC.common.tigerPalm
	_,_,_,tigerPowerCount,_,_,tigerPowerExpirationTime,_,_ = UnitAura("player", MonkEC.buff.tigerPower.name)
	if tigerPowerExpirationTime ~= nil then
		tigerPowerSecondsLeft = tigerPowerExpirationTime - GetTime()
	else
		tigerPowerSecondsLeft = 0
	end
	
	tigerEyeSpell = MonkEC.windwalker.tigerEye
	_,_,_,tigerEyeCount,_,_,tigerEyeExpirationTime,_,_ = UnitAura("player", MonkEC.buff.tigerEye.name)
	if tigerEyeExpirationTime ~= nil then
		tigerEyeSecondsLeft = tigerEyeExpirationTime - GetTime()
	else
		tigerEyeSecondsLeft = 0
	end
	
	sanctuaryOfTheOxSpell = MonkEC.brewmaster.summonBlackOxStatue
	_,_,_,sanctuaryOfTheOxCount,_,_,sanctuaryOfTheOxExpirationTime,_,_ = UnitAura("player", MonkEC.buff.sanctuaryOfTheOx.name)
	if sanctuaryOfTheOxExpirationTime ~= nil then
		sanctuaryOfTheOxSecondsLeft = sanctuaryOfTheOxExpirationTime - GetTime()
	else
		sanctuaryOfTheOxSecondsLeft = 0
	end
	
	mortalWoundsIcon = MonkEC.debuff.mortalWounds
	_,_,_,mortalWoundsCount,_,_,mortalWoundsExpirationTime,_,_ = UnitDebuff("target", MonkEC.debuff.mortalWounds.name)
	if mortalWoundsExpirationTime ~= nil then
		mortalWoundsSecondsLeft = mortalWoundsExpirationTime - GetTime()
	else
		mortalWoundsSecondsLeft = 0
	end
	
	_,_,_,_,_,_,breathOfFireExpirationTime,_,_ = UnitDebuff("target", MonkEC.brewmaster.breathOfFire.name)
	if breathOfFireExpirationTime ~= nil then
		breathOfFireSecondsLeft = breathOfFireExpirationTime - GetTime()
	else
		breathOfFireSecondsLeft = 0
	end
end

function MonkEC:GatherCharacterState()
	playerHasStatBoost = UnitBuff("player", self.common.legacyOfTheEmperor.name) ~= nil or
		UnitBuff("player", self.external.markOfTheWild.name) ~= nil or
		UnitBuff("player", self.external.blessingOfKings.name) ~= nil or
		UnitBuff("player", self.external.embraceOfTheShaleSpider.name) ~= nil
	local state = {
		level = UnitLevel("player"),
		stance = GetShapeshiftForm(),
		haveHealingElixirs = MonkEC.haveHealingElixirs,
		doAOE = self.db.profile.suggest_aoe,
		inMeleeRange = IsSpellInRange(self.common.jab.name, "target") == 1,
		currentHealthPercentage = UnitHealth("player") / UnitHealthMax("player") * 100,
		chi = UnitPower("player", SPELL_POWER_CHI),
		energy = UnitPower("player"),
		
		playerHasLegacyOfTheEmperor = playerHasStatBoost,
		playerHasSanctuaryOfTheOx = UnitBuff("player", self.buff.sanctuaryOfTheOx.name) ~= nil,
		playerHasLegacyOfTheWhiteTiger = UnitBuff("player", self.windwalker.legacyOfTheWhiteTiger.name) ~= nil,
		
		shuffleSecondsLeft = shuffleSecondsLeft,
		staggerTooHigh = (UnitDebuff("player", self.debuff.moderateStagger.name) ~= nil) or 
						(UnitDebuff("player", self.debuff.heavyStagger.name) ~= nil),
		weakenedBlowsSecondsLeft = weakenedBlowsSecondsLeft,
		elusiveBrewCount = elusiveBrewCount,
		tigerEyeCount = tigerEyeCount,
		tigerPowerSecondsLeft = tigerPowerSecondsLeft,
		breathOfFireSecondsLeft = breathOfFireSecondsLeft,
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
	
	if state.tigerPowerCount == nil then
		state.tigerPowerCount = 0
	end
	
	if state.tigerPowerSecondsLeft == nil then
		state.tigerPowerSecondsLeft = 0
	end
	
	if state.weakenedBlowsSecondsLeft == nil then
		state.weakenedBlowsSecondsLeft = 0
	end
	
	if state.breathOfFireSecondsLeft == nil then
		state.breathOfFireSecondsLeft = 0
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
