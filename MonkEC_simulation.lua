local _, trueclass = UnitClass("player")
if trueclass ~= "MONK" then return end

-- Thresholds
local castHealThreshold = 80
local dumpChiThreshold	= 4

-- Priority lists
local desperationPriorities
local brewmasterPriorities

-- Target tracking
local numTargets = 0
local trackedTargets = {}

function MonkEC:CreatePriorityLists()
	brewmasterPriorities = {
		{	spell = self.brewmaster.guard, 
			condition = function(self, characterState, currentGCD) 
				return self:InDesperateNeedOfHealing(characterState)
			end, 
		},
		{	spell = self.brewmaster.fortifyingBrew, 
			condition = function(self, characterState, currentGCD) 
				return self:InDesperateNeedOfHealing(characterState)
			end, 
		},
		{	spell = self.brewmaster.dampenHarm, 
			condition = function(self, characterState, currentGCD) 
				return self:InDesperateNeedOfHealing(characterState)
			end, 
		},
		{	spell = self.brewmaster.purifyingBrew, 
			condition = function(self, characterState, currentGCD) 
				return self:HaveHealingElixirs(characterState) and
					self:StaggerTooHigh(characterState)
			end, 
		},
		{	spell = function(self) return self:Level30Talent() end, 
			condition = function(self, characterState, currentGCD) 
				return self:InDesperateNeedOfHealing(characterState)					
			end, 
		},
		{	spell = self.common.expelHarm, 
			condition = function(self, characterState, currentGCD) 
				return self:InDesperateNeedOfHealing(characterState)
			end, 
		},
		{	spell = self.common.touchOfDeath, 
			condition = function(self, characterState, currentGCD) 
				return (self.db.profile.suggest_touchOfDeath == true) and
						UnitExists("target") and 
						(
							(UnitHealth("player") >= UnitHealth("target")) or
							((UnitHealthMax("target") / UnitHealth("target")) > 10)
						); 
			end, 
		},
		{	spell = self.brewmaster.stanceOfTheSturdyOx, 
			condition = function(self, characterState, currentGCD) 
				return self:StanceIsWrong(characterState)
			end, 
		},
		{	spell = self.brewmaster.summonBlackOxStatue, 
			condition = function(self, characterState, currentGCD) 
				return (self.db.profile.suggest_summonBlackOxStatue == true) and
						not self:PlayerHasBuff(self.buff.sanctuaryOfTheOx, characterState)
			end, 
		},
		{	spell = self.brewmaster.dizzyingHaze, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and 
						not characterState.inMeleeRange
				end, 
		},
		{	spell = self.brewmaster.clash, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and 
						not characterState.inMeleeRange
			end, 
		},
		{	spell = self.common.blackoutKick, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and
						(self:BuffWearingOffSoon(self.buff.shuffle, characterState) or self:DumpChi(characterState))
			end, 
		},
		{	spell = self.brewmaster.kegSmash, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target")
			end, 
		},
		{	spell = self.common.expelHarm, 
			condition = function(self, characterState, currentGCD) 
				return self:DamagedEnough(characterState) 
			end, 
		},
		{	spell = self.brewmaster.purifyingBrew, 
			condition = function(self, characterState, currentGCD) 
				return self:StaggerTooHigh(characterState)
			end, 
		},
		{	spell = self.brewmaster.elusiveBrew, 
			condition = function(self, characterState, currentGCD)
				return self:DoElusiveBrew(characterState) 
			end, 
		},
		{	spell = self.common.tigerPalm, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and
						not self:ChiLow(characterState) and
						not self:EnergyHigh(characterState) and
						self:DebuffWearingOffSoon(self.buff.tigerPower, characterState)
			end, 
		},
		{	spell = function(self) return self:Level45Talent() end, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and
						self:ChiLow(characterState) and
						not self:EnergyHigh(characterState)
			end, 
		},
		{	spell = self.brewmaster.breathOfFire, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and
						self:DoAOE(characterState) and
						self:DebuffWearingOffSoon(self.brewmaster.breathOfFire, characterState)
			end, 
		},
		{	spell = self.common.spinningCraneKick, 
			condition = function(self, characterState, currentGCD) 
				return self:DoAOE(characterState)
			end, 
		},
		{	spell = self.common.jab, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and
						not self:DoAOE(characterState) 
			end, 
		},
		{	spell = self.brewmaster.guard, 
			condition = function(self, characterState, currentGCD) 
				return (self.db.profile.suggest_guard == true) 
			end, 
		},
		{	spell = function(self) return self:Level30Talent() end, 
			condition = function(self, characterState, currentGCD) 
				return self:DamagedEnough(characterState) 
			end, 
		},
		{	spell = self.common.tigerPalm, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target")
			end, 
		},
	}
		
	windwalkerPriorities = {
		{	spell = self.common.touchOfDeath, 
			condition = function(self, characterState, currentGCD) 
				return (self.db.profile.suggest_touchOfDeath == true) and
						UnitExists("target") and 
						(
							(UnitHealth("player") >= UnitHealth("target")) or
							((UnitHealthMax("target") / UnitHealth("target")) > 10)
						); 
			end, 
		},
		{	spell = self.windwalker.legacyOfTheWhiteTiger, 
			condition = function(self, characterState, currentGCD) 
				return not self:PlayerHasBuff(self.buff.legacyOfTheWhiteTiger, characterState)
			end, 
		},
		{	spell = self.windwalker.stanceOfTheFierceTiger, 
			condition = function(self, characterState, currentGCD) 
				return self:StanceIsWrong(characterState); 
			end, 
		},
		{	spell = self.windwalker.flyingSerpentKick, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and 
						not characterState.inMeleeRange
			end, 
		},
		{	spell = self.common.tigerPalm, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and
						MonkEC:BuffWearingOffSoon(self.buff.tigerPower, characterState)
			end, 
		},
		{	spell = self.windwalker.risingSunKick, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target")
			end, 
		},
		{	spell = self.common.spinningCraneKick, 
			condition = function(self, characterState, currentGCD) 
				return self:DoAOE(characterState)
			end, 
		},
		{	spell = function(self) return self:Level30Talent() end, 
			condition = function(self, characterState, currentGCD) 
				return self:DamagedEnough(characterState)
			end, 
		},
		{	spell = self.common.expelHarm, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and
						self:EnergyHigh(characterState) and
						self:DamagedEnough(characterState)
			end, 
		},
		{	spell = self.windwalker.tigerEyeBrew, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and
						self:BuffStackedTo(self.buff.tigerEye, 10, characterState)
			end, 
		},
		{	spell = self.windwalker.fistsOfFury, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and
						not self:SpellWillBeOffCooldown(self.windwalker.risingSunKick, currentGCD + MonkEC.fistsOfFuryDuration) and
						characterState.energy < 40 and 
						not self:BuffWearingOffBefore(self.buff.tigerPower, characterState, MonkEC.fistsOfFuryDuration) and
						not MonkEC:PlayerHasBuff(self.windwalker.energizingBrew, characterState) and
						not MonkEC:Hasted(characterState)
			end, 
		},
		{	spell = function(self) return self:Level45Talent() end, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and
						self:ChiLow(characterState) and
						not self:EnergyHigh(characterState)
			end, 
		},
		{	spell = self.windwalker.energizingBrew, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and 
						self:EnergyLow(characterState) and
						not MonkEC:Hasted(characterState)
			end, 
		},
		{	spell = function(self) return self:Level100Talent() end, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and
						not self:ChiLow(characterState) and
						not self:EnergyHigh(characterState)
			end, 
		},
		{	spell = self.common.blackoutKick, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and 
						self:PlayerHasBuff(self.buff.comboBreakerBlackoutKick, characterState)
			end, 
		},
		{	spell = self.common.tigerPalm, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and 
						self:PlayerHasBuff(self.buff.comboBreakerTigerPalm, characterState)
			end, 
		},
		{	spell = self.common.blackoutKick, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target") and self:DumpChi(characterState)
			end, 
		},
		{	spell = self.common.jab, 
			condition = function(self, characterState, currentGCD) 
				return UnitExists("target")
			end, 
		},
		{	spell = function(self) return self:Level30Talent() end, 
			condition = function(self, characterState, currentGCD) 
				return self:DamagedEnough(characterState) 
			end, 
		},
	}
end

function MonkEC:FindNextSpell(currentGCD, characterState)
	local priorities
	local spell = nil
	
	if MonkEC.talentSpec == MonkEC.talentSpecBrewmaster then
		self.common.tigerPalm.cost = 0 --temp
		priorities = brewmasterPriorities
	else
		self.common.tigerPalm.cost = 1 --temp
		priorities = windwalkerPriorities
	end

	spell = self:FindNextSpellFrom(priorities, currentGCD, characterState)
	if spell ~= nil then
		self:UpdateStateForSpellcast(spell, characterState)
	end

	return spell
end

function MonkEC:UpdateStateForSpellcast(spell, characterState)
	self:ConsumePowerForSpell(spell, characterState)
	self:GenerateChiFromSpell(spell, characterState)
	self:UpdateBuffsForSpell(spell, characterState)
	self:IncreaseCooldown(spell)
	self:NextGCD(characterState)
end

function MonkEC:NextGCD(characterState)
	characterState.energy = characterState.energy + MonkEC.energyGeneratedPerGCD
	characterState.breathOfFireSecondsLeft = characterState.breathOfFireSecondsLeft - MonkEC.theGCD
	characterState.shuffleSecondsLeft = characterState.shuffleSecondsLeft - MonkEC.theGCD
	characterState.tigerPowerSecondsLeft = characterState.tigerPowerSecondsLeft - MonkEC.theGCD
	characterState.energizingBrewSecondsLeft = characterState.energizingBrewSecondsLeft - MonkEC.theGCD
	characterState.risingSunKickSecondsLeft = characterState.risingSunKickSecondsLeft - MonkEC.theGCD
	characterState.blackoutKickDebuffSecondsLeft = characterState.blackoutKickDebuffSecondsLeft - MonkEC.theGCD
end

function MonkEC:ConsumePowerForSpell(spell, characterState)
	local _, _, _, cost, _, powerType = GetSpellInfo(spell.id); 
-- temp
cost = spell.cost
powerType = spell.powerType

	if powerType == MonkEC.energyPowerType then
		characterState.energy = characterState.energy - cost
	elseif powerType == MonkEC.chiPowerType then
		characterState.chi = characterState.chi - cost
	end	
end

function MonkEC:GenerateChiFromSpell(spell, characterState)
	if spell.id == self.common.expelHarm.id or
		spell.id == self.common.spinningCraneKick.id or
		spell.id == self.brewmaster.kegSmash.id 
	then
		characterState.chi = characterState.chi + 1
	elseif spell.id == self.common.jab.id then
		if characterState.stance == MonkEC.brewmasterStance then
			characterState.chi = characterState.chi + 1
		else
			characterState.chi = characterState.chi + 2
		end
	elseif spell.id == self.talent.chiBrew.id then
		characterState.chi = characterState.chi + 2
	end
end

function MonkEC:UpdateBuffsForSpell(spell, characterState)
	if spell.id == self.buff.sanctuaryOfTheOx.id then
		characterState.playerHasSanctuaryOfTheOx = true
	elseif spell.id == self.brewmaster.breathOfFire.id then
		characterState.breathOfFireSecondsLeft = MonkEC.breathOfFireDebuffLength
	elseif spell.id == self.brewmaster.elusiveBrew.id then
		characterState.elusiveBrewCount = 0;
	elseif spell.id == self.brewmaster.purifyingBrew.id then
		characterState.staggerTooHigh = false;
	elseif spell.id == self.brewmaster.stanceOfTheSturdyOx.id then
		characterState.stance = MonkEC.brewmasterStance
	elseif spell.id == self.common.blackoutKick.id then
		characterState.shuffleSecondsLeft = MonkEC.shuffleBuffLength
		characterState.hasComboBreakerBlackoutKick = false
		characterState.blackoutKickDebuffSecondsLeft = MonkEC.blackoutKickDebuffLength
	elseif spell.id == self.common.tigerPalm.id then
		characterState.tigerPowerSecondsLeft = MonkEC.tigerPowerBuffLength
		characterState.hasComboBreakerTigerPalm = false
	elseif spell.id == self.windwalker.energizingBrew.id then
		characterState.energizingBrewSecondsLeft = MonkEC.energizingBrewBuffLength
		characterState.hasEnergizingBrew = true
	elseif spell.id == self.windwalker.legacyOfTheWhiteTiger.id then
		characterState.playerHasLegacyOfTheWhiteTiger = true
	elseif spell.id == self.windwalker.risingSunKick.id then
		characterState.risingSunKickSecondsLeft = MonkEC.risingSunKickDebuffLength
	elseif spell.id == self.windwalker.stanceOfTheFierceTiger.id then
		characterState.stance = MonkEC.windwalkerStance
	elseif spell.id == self.windwalker.tigerEyeBrew.id then
		characterState.tigerEyeCount = 0;
	end
end

function MonkEC:IncreaseCooldown(spell)
	if spell.cooldownLength == nil then 
		spell.cooldown = spell.cooldown + MonkEC.theGCD
	else
		spell.cooldown = spell.cooldown + spell.cooldownLength
	end
end

function MonkEC:Hasted(characterState)
	return characterState.hasted;
end

function MonkEC:InDesperateNeedOfHealing(characterState)
	return characterState.currentHealthPercentage < MonkEC.db.profile.dangerousHealth
end

function MonkEC:ChiLow(characterState)
	local chiLow = false
	if MonkEC.talentSpec == MonkEC.talentSpecBrewmaster then
		chiLow = characterState.chi < MonkEC.db.profile.targetChi
	else
		chiLow = characterState.chi < 3
	end
	
	return chiLow
end

function MonkEC:EnergyHigh(characterState)
	return characterState.energy > MonkEC.db.profile.targetEnergy
end

function MonkEC:EnergyLow(characterState)
	return characterState.energy <= 30
end

function MonkEC:StaggerTooHigh(characterState)
	return characterState.staggerTooHigh
end

function MonkEC:HaveHealingElixirs(characterState)
	return characterState.haveHealingElixirs
end

function MonkEC:DoElusiveBrew(characterState)
	-- Don't use when other tank has aggro in raid or we don't have enough stacks
	return ((GetNumGroupMembers() <= 5) or UnitIsUnit("targettarget", "player")) and 
		(characterState.elusiveBrewCount > MonkEC.db.profile.elusiveBrewThreshold)
end

function MonkEC:DoAOE(characterState)
	local doAOE = false;
	
	if self.db.profile.suggest_aoe == true then
		if MonkEC.talentSpec == MonkEC.talentSpecBrewmaster then
			doAOE = numTargets > 3 -- We're always damaging ourself with stagger
		elseif MonkEC.talentSpec == MonkEC.talentSpecWindwalker  then
			doAOE = numTargets > 4
		end
	end
	
	return doAOE
end

function MonkEC:ChiWillNotOverflow(spell, characterState)
	local willNotOverflow = true

	if spell.chiGenerated ~= nil then
		willNotOverflow = (characterState.chi + spell.chiGenerated) <= MonkEC.maxChi
	end
	
	return willNotOverflow
end

function MonkEC:BuffWearingOffSoon(spell, characterState)
	return MonkEC:BuffWearingOffBefore(spell, characterState, MonkEC.theGCD)
end

function MonkEC:BuffWearingOffBefore(spell, characterState, duration)
	local wearingOffBefore = true
	
	if spell.id == self.buff.shuffle.id then
		if characterState.shuffleSecondsLeft > duration or characterState.level < 72 then
			wearingOffBefore = false
		end
	elseif spell.id == self.buff.tigerPower.id then
		if characterState.tigerPowerSecondsLeft > duration then
			wearingOffBefore = false
		end
	elseif spell.id == self.windwalker.energizingBrew.id then
		if characterState.energizingBrewSecondsLeft > duration then
			wearingOffBefore = false
		end
	end
	
	return wearingOffBefore
end

function MonkEC:BuffStackedTo(spell, targetStackSize, characterState)
	local stacked = false
	
	if MonkEC.talentSpec == MonkEC.talentSpecWindwalker then
		if spell.id == self.buff.tigerEye.id then
			if characterState.tigerEyeCount >= targetStackSize then
				stacked = true
			end
		end
	end
	
	return stacked
end

function MonkEC:DebuffWearingOffSoon(spell, characterState)
	return MonkEC:DebuffWearingOffBefore(spell, characterState, MonkEC.theGCD)
end

function MonkEC:DebuffWearingOffBefore(spell, characterState, duration)
	local wearingOffBefore = true
	
	if spell.id == self.brewmaster.breathOfFire.id then
		if characterState.breathOfFireSecondsLeft > duration then
			wearingOffBefore = false
		end
	elseif spell.id == self.windwalker.risingSunKick.id then
		if characterState.risingSunKickSecondsLeft > duration then
			wearingOffBefore = false
		end
	elseif spell.id == self.common.blackoutKick.id then
		if characterState.blackoutKickDebuffSecondsLeft > duration then
			wearingOffBefore = false
		end
	end
	
	return wearingOffBefore
end

function MonkEC:DamagedEnough(characterState)
	return characterState.currentHealthPercentage < castHealThreshold
end

function MonkEC:DumpChi(characterState)
	return characterState.chi >= dumpChiThreshold
end

function MonkEC:FindNextSpellFrom(priorities, currentGCD, characterState)
	local spell = nil
	
	for key,candidate in pairs(priorities) do
		if candidate.spell ~= nil and
			(candidate.condition == nil or candidate.condition(self, characterState, currentGCD)) then
			if type(candidate.spell) == "function" then
				spell = candidate.spell(self)
			else
				spell = candidate.spell
			end
			if self:CanPerformSpell(spell, currentGCD, characterState) then
				return spell
			end
		end
	end
	
	return nil
end

function MonkEC:CanPerformSpell(spell, currentGCD, characterState)
	return self:IsHighEnoughLevel(spell, characterState) and 
			self:HasEnoughResources(spell, characterState) and
			self:SpellWillBeOffCooldown(spell, currentGCD) and 
			self:ChiWillNotOverflow(spell, characterState)
end

function MonkEC:IsHighEnoughLevel(spell, characterState)
	return spell ~= nil and (spell.minimumLevel == nil or spell.minimumLevel <= characterState.level)
end

function MonkEC:HasEnoughResources(spell, characterState)
	local _, _, _, cost, _, powerType = GetSpellInfo(spell.id); 
-- temp
cost = spell.cost
if (cost == nil) then
	cost = 0
end
powerType = spell.powerType
if (powerType == nil) then
	powerType = 0
end

	local haveEnoughResources = true
	if powerType == MonkEC.energyPowerType then
		haveEnoughResources = characterState.energy >= cost
	elseif powerType == MonkEC.chiPowerType then
		haveEnoughResources = characterState.chi >= cost
	end

	return haveEnoughResources
end

function MonkEC:SpellWillBeOffCooldown(spell, currentGCD)
	return spell.cooldown <= currentGCD 
end

function MonkEC:StanceIsWrong(characterState)
	local stanceIsWrong = false
	if MonkEC.talentSpec == MonkEC.talentSpecBrewmaster and characterState.stance ~= MonkEC.brewmasterStance then
		stanceIsWrong = true
	end

	return stanceIsWrong
end

function MonkEC:PlayerHasBuff(spell, characterState)
	local hasBuff = false

	if spell.id == self.buff.tigerPower.id then
		hasBuff = characterState.tigerPowerSecondsLeft > 0
	elseif MonkEC.talentSpec == MonkEC.talentSpecBrewmaster then
		if spell.id == self.buff.sanctuaryOfTheOx.id then
			hasBuff = characterState.playerHasSanctuaryOfTheOx
		elseif spell.id == self.brewmaster.shuffle.id then
			hasBuff = characterState.shuffleSecondsLeft > 0
		end
	elseif MonkEC.talentSpec == MonkEC.talentSpecWindwalker then
		if spell.id == self.buff.legacyOfTheWhiteTiger.id then
			hasBuff = characterState.playerHasLegacyOfTheWhiteTiger
		elseif spell.id == self.buff.comboBreakerBlackoutKick.id then
			hasBuff = characterState.hasComboBreakerBlackoutKick
		elseif spell.id == self.buff.comboBreakerTigerPalm.id then
			hasBuff = characterState.hasComboBreakerTigerPalm
		elseif spell.id == self.windwalker.energizingBrew.id then 
			hasBuff = characterState.energizingBrewSecondsLeft > 0
		end
	end
	
	return hasBuff
end
	
function MonkEC:TrackTarget(GUID)
	if trackedTargets[GUID] == nil then
		numTargets = numTargets + 1
	end
	trackedTargets[GUID] = GetTime()
end

function MonkEC:ClearOldTargets()
	local staleTime = GetTime() - 3
	for targetId,lastSeen in pairs(trackedTargets) do
		if lastSeen < staleTime then
			trackedTargets[targetId] = nil
			numTargets = numTargets - 1
		end
	end
end

function MonkEC:ClearTrackedTargets()
	wipe(trackedTargets)
	numTargets = 0
end

function MonkEC:SetChiGoal(info, value)
	self.db.profile.targetChi = value
end

function MonkEC:SetEnergyGoal(info, value)
	self.db.profile.targetEnergy = value
end

function MonkEC:SetDangerousHealth(info, value)
	self.db.profile.dangerousHealth = value
end

function MonkEC:SetElusiveBrewThreshold(info, value)
	self.db.profile.elusiveBrewThreshold = value
end

