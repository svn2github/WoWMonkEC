local _, trueclass = UnitClass("player")
if trueclass ~= "MONK" then return end

-- Thresholds
local castHealThreshold = 80
local dumpChiThreshold	= 3

-- Priority lists
local desperationPriorities
local brewmasterPriorities

function MonkEC:CreatePriorityLists()
	desperationPriorities = {
		{	spell = self.brewmaster.guard, condition = nil, },
		{	spell = self.brewmaster.fortifyingBrew, condition = nil, },
		{	spell = self.brewmaster.dampenHarm, condition = nil, },
		{	spell = self.brewmaster.purifyingBrew, 
			condition = function(self, characterState) 
				return self:HaveHealingElixirs(characterState) and
					self:StaggerTooHigh(characterState)
			end, 
		},
		{	spell = self:Level30Talent(), condition = nil, },
		{	spell = self.common.expelHarm, condition = nil, },
		{	spell = self.brewmaster.kegSmash, condition = nil, },
		{	spell = self.common.jab, condition = nil, },
	}
	
	brewmasterPriorities = {
		{	spell = self.common.touchOfDeath, 
			condition = function(self, characterState) 
				return (self.db.profile.suggest_touchOfDeath == true) and
						UnitExists("target") and 
						(UnitHealth("player") >= UnitHealth("target")); 
			end, 
		},
		{	spell = self.common.legacyOfTheEmperor, 
			condition = function(self, characterState) 
				return not self:PlayerHasBuff(self.common.legacyOfTheEmperor, characterState)
			end, 
		},
		{	spell = self.brewmaster.stanceOfTheSturdyOx, 
			condition = function(self, characterState) 
				return self:StanceIsWrong(characterState); 
			end, 
		},
		{	spell = self.brewmaster.summonBlackOxStatue, 
			condition = function(self, characterState) 
				return (self.db.profile.suggest_summonBlackOxStatue == true) and
						not self:PlayerHasBuff(self.buff.sanctuaryOfTheOx, characterState)
			end, 
		},
		{	spell = self.brewmaster.dizzyingHaze, 
			condition = function(self, characterState) 
				return UnitExists("target") and 
						not characterState.inMeleeRange and 
						self:DebuffWearingOffSoon(self.debuff.weakenedBlows, characterState)
				end, 
		},
		{	spell = self.brewmaster.clash, 
			condition = function(self, characterState) 
				return UnitExists("target") and 
						not characterState.inMeleeRange
			end, 
		},
		{	spell = self.brewmaster.kegSmash, 
			condition = function(self, characterState) 
				return UnitExists("target") and
						self:DebuffWearingOffSoon(self.debuff.weakenedBlows, characterState)
			end, 
		},
		{	spell = self.common.blackoutKick, 
			condition = function(self, characterState) 
				return UnitExists("target") and
						self:BuffWearingOffSoon(self.buff.shuffle, characterState)
			end, 
		},
		{	spell = self.common.expelHarm, 
			condition = function(self, characterState) 
				return self:DamagedEnough(characterState) 
			end, 
		},
		{	spell = self.brewmaster.purifyingBrew, 
			condition = function(self, characterState) 
				return self:StaggerTooHigh(characterState)
			end, 
		},
		{	spell = self.brewmaster.elusiveBrew, 
			condition = function(self, characterState)
				return self:DoElusiveBrew(characterState) 
			end, 
		},
		{	spell = self.common.tigerPalm, 
			condition = function(self, characterState) 
				return UnitExists("target") and
						not self:ChiLow(characterState) and
						not self:EnergyHigh(characterState) and
						self:NeedsMoreTigerPower(characterState)
			end, 
		},
		{	spell = self.common.spinningCraneKick, 
			condition = function(self, characterState) 
				return self:DoAOE(characterState)
			end, 
		},
		{	spell = self.common.jab, 
			condition = function(self, characterState) 
				return UnitExists("target") and
						not self:DoAOE(characterState) 
			end, 
		},
		{	spell = self.brewmaster.guard, 
			condition = function(self, characterState) return (self.db.profile.suggest_guard == true) end, },
		{	spell = self:Level30Talent(), 
			condition = function(self, characterState) return self:DamagedEnough(characterState) end, },
		{	spell = self.brewmaster.breathOfFire, 
			condition = function(self, characterState) 
				return UnitExists("target") and
						self:DoAOE(characterState) 
			end, 
		},
		{	spell = self.common.blackoutKick, 
			condition = function(self, characterState) 
				return UnitExists("target") and self:DumpChi(characterState)
			end, 
		},
		{	spell = self.brewmaster.kegSmash, 
			condition = function(self, characterState) 
				return UnitExists("target") and self:EnergyHigh(characterState)
			end, 
		},
		{	spell = self.common.tigerPalm, 
			condition = function(self, characterState) 
				return UnitExists("target")
			end, 
		},
	}
end

function MonkEC:FindNextSpell(currentGCD, characterState)
	local spell = nil
	
	if MonkEC.talentSpec == MonkEC.talentSpecBrewmaster then
		if self:InDesperateNeedOfHealing(characterState) then
			spell = self:FindNextSpellFrom(desperationPriorities, currentGCD, characterState)
		else
			spell = self:FindNextSpellFrom(brewmasterPriorities, currentGCD, characterState)
		end
	end

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
	characterState.energy = characterState.energy + MonkEC.energyGeneratedPerGCD_brewmaster
	characterState.shuffleSecondsLeft = characterState.shuffleSecondsLeft - MonkEC.theGCD
	characterState.tigerPowerSecondsLeft = characterState.tigerPowerSecondsLeft - MonkEC.theGCD
	characterState.weakenedBlowsSecondsLeft = characterState.weakenedBlowsSecondsLeft - MonkEC.theGCD
end

function MonkEC:ConsumePowerForSpell(spell, characterState)
	if spell.powerType == MonkEC.energyPowerType then
		characterState.energy = characterState.energy - spell.cost
	elseif spell.powerType == MonkEC.chiPowerType then
		characterState.chi = characterState.chi - spell.cost
	end	
end

function MonkEC:GenerateChiFromSpell(spell, characterState)
	if spell.id == self.common.expelHarm.id or
		spell.id == self.common.jab.id or
		spell.id == self.common.spinningCraneKick.id or
		spell.id == self.brewmaster.kegSmash.id then
		characterState.chi = characterState.chi + 1
	elseif spell.id == self.talent.chiBrew.id then
		characterState.chi = MonkEC.maxChi
	end
end

function MonkEC:UpdateBuffsForSpell(spell, characterState)
	if spell.id == self.buff.sanctuaryOfTheOx.id then
		characterState.playerHasSanctuaryOfTheOx = true
	elseif spell.id == self.common.legacyOfTheEmperor.id then
		characterState.playerHasLegacyOfTheEmperor = true
	elseif spell.id == self.brewmaster.stanceOfTheSturdyOx.id then
		characterState.stance = MonkEC.brewmasterStance
	elseif spell.id == self.common.blackoutKick.id then
		characterState.shuffleSecondsLeft = MonkEC.shuffleBuffLength
	elseif spell.id == self.common.tigerPalm.id then
		if characterState.tigerPowerCount < MonkEC.tigerPowerMaxStack then
			characterState.tigerPowerCount = characterState.tigerPowerCount + 1
		end
		characterState.tigerPowerSecondsLeft = MonkEC.tigerPowerBuffLength
	elseif spell.id == self.brewmaster.dizzyingHaze.id or spell.id == self.brewmaster.kegSmash.id then
		characterState.weakenedBlowsSecondsLeft = MonkEC.weakenedBlowsDebuffLength
	elseif spell.id == self.brewmaster.elusiveBrew.id then
		characterState.elusiveBrewCount = 0;
	elseif spell.id == self.brewmaster.purifyingBrew.id then
		characterState.staggerTooHigh = false;
	end
end

function MonkEC:IncreaseCooldown(spell)
	if spell.cooldownLength == nil then 
		spell.cooldown = spell.cooldown + MonkEC.theGCD
	else
		spell.cooldown = spell.cooldown + spell.cooldownLength
	end
end

function MonkEC:InDesperateNeedOfHealing(characterState)
	return characterState.currentHealthPercentage < MonkEC.db.profile.dangerousHealth
end

function MonkEC:ChiLow(characterState)
	return characterState.chi < MonkEC.db.profile.targetChi
end

function MonkEC:EnergyHigh(characterState)
	return characterState.energy > MonkEC.db.profile.targetEnergy
end

function MonkEC:StaggerTooHigh(characterState)
	return characterState.staggerTooHigh
end

function MonkEC:HaveHealingElixirs(characterState)
	return characterState.haveHealingElixirs
end

function MonkEC:DoElusiveBrew(characterState)
	return characterState.elusiveBrewCount > MonkEC.db.profile.elusiveBrewThreshold
end

function MonkEC:DoAOE(characterState)
	return characterState.doAOE
end

function MonkEC:ChiWillNotOverflow(spell, characterState)
	local willNotOverflow = true
--MonkEC:Print("ChiWillNotOverflow checking: " .. spell.name)

	if spell.chiGenerated ~= nil then
		willNotOverflow = (characterState.chi + spell.chiGenerated) <= MonkEC.maxChi
		--MonkEC:Print("ChiWillNotOverflow: " .. tostring(willNotOverflow) .. " = (" .. characterState.chi .. " + " .. spell.chiGenerated .. ") <= " .. MonkEC.maxChi)
	end
	
	return willNotOverflow
end

function MonkEC:BuffWearingOffSoon(spell, characterState)
	local wearingOffSoon = true
	
	if spell.id == self.buff.shuffle.id then
--self:Print("Checking shuffle characterState.shuffleSecondsLeft > theGCD - " .. characterState.shuffleSecondsLeft .. ">" .. theGCD .. "=" .. tostring(characterState.shuffleSecondsLeft > theGCD))
		if characterState.shuffleSecondsLeft > MonkEC.theGCD or characterState.level < 72 then
			wearingOffSoon = false
		end
	end
	
	return wearingOffSoon
end

function MonkEC:DebuffWearingOffSoon(spell, characterState)
	local wearingOffSoon = true
	
	if spell.id == self.debuff.weakenedBlows.id then
		if characterState.weakenedBlowsSecondsLeft > MonkEC.theGCD then
			wearingOffSoon = false
		end
	end
	
	return wearingOffSoon
end

function MonkEC:DamagedEnough(characterState)
	return characterState.currentHealthPercentage < castHealThreshold
end

function MonkEC:DumpChi(characterState)
	return characterState.chi > dumpChiThreshold
end

function MonkEC:NeedsMoreTigerPower(characterState)
	return characterState.tigerPowerCount < MonkEC.tigerPowerMaxStack
end

function MonkEC:FindNextSpellFrom(priorities, currentGCD, characterState)
	for key,candidate in pairs(priorities) do
		if candidate.spell ~= nil and
			(candidate.condition == nil or candidate.condition(self, characterState)) and
			self:CanPerformSpell(candidate.spell, currentGCD, characterState) then
			return candidate.spell
		end
		-- if candidate.spell ~= nil then
			-- local candidateAccepted = true
			-- if candidate.condition ~= nil then
				-- candidateAccepted = candidate.condition(self, characterState)
			-- end
			
			-- if candidateAccepted then
				-- candidateAccepted = self:CanPerformSpell(candidate.spell, currentGCD, characterState)
			-- end
			
			-- if candidateAccepted then
				-- return candidate.spell
			-- end
		-- end
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
	return spell.minimumLevel == nil or spell.minimumLevel <= characterState.level
end

function MonkEC:HasEnoughResources(spell, characterState)
	local haveEnoughResources = true
	
	if spell.powerType == MonkEC.energyPowerType then
		haveEnoughResources = characterState.energy >= spell.cost
	elseif spell.powerType == MonkEC.chiPowerType then
		haveEnoughResources = characterState.chi >= spell.cost
	end

	return haveEnoughResources
end

function MonkEC:SpellWillBeOffCooldown(spell, currentGCD)
	return spell.cooldown <= currentGCD 
end

function MonkEC:StanceIsWrong(characterState)
	local stanceIsWrong = true
	
	if MonkEC.talentSpec == MonkEC.talentSpecBrewmaster and characterState.stance == MonkEC.brewmasterStance then
		stanceIsWrong = false
	end

	return stanceIsWrong
end

function MonkEC:PlayerHasBuff(spell, characterState)
	local hasBuff = false

	if spell.id == self.buff.sanctuaryOfTheOx.id then
		hasBuff = characterState.playerHasSanctuaryOfTheOx
	elseif spell.id == self.common.legacyOfTheEmperor.id then
		hasBuff = characterState.playerHasLegacyOfTheEmperor
	elseif spell.id == self.brewmaster.shuffle.id then
		hasBuff = characterState.shuffleSecondsLeft > 0
	end
	
	return hasBuff
end
