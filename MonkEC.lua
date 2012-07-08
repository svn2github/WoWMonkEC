MonkEC = LibStub("AceAddon-3.0"):NewAddon("MonkEC", "AceConsole-3.0", "AceEvent-3.0");
local media = LibStub("LibSharedMedia-3.0")
local textures = media:List("statusbar")
local fonts = media:List("font")
local AceGUI = LibStub("AceGUI-3.0")

-- State
local timeSinceLastUpdate = 0
local updateFrequency = 0.5
local inCombat = false
local timeEnteringCombat = 0

-- Talents
local talentSpec = -1 -- Brewmaster (1), Mistweaver (2), Windwalker (3)
local talentSpecBrewmaster = 1
local talentSpecMistweaver = 2
local talentSpecWindwalker = 3
local brewmasterStance = 1
local windwalkerStance = 2

-- Resources (chi and energy)
local chiPowerType = 12
local maxChi = 4
local maximumChiGain = 1
local energyPowerType = 3
local energyGeneratedPerGCD = 8
local theGCD = 1.0

-- Priority lists
local desperationPriorities
local brewmasterPriorities

-- Frame position data
local abilityIconXOffset = { [1] = 8, [2] = 80, [3] = 136 }
local abilityIconYOffset = 8
local buffIconXOffset = { [1] = 13, [2] = 57, [3] = 101, [4] = 145 }
local buffIconYOffset = 8
local aoeToggleXOffset = 190
local aoeToggleYOffset = 0

-- Buff info
local elusiveBrewCount, elusiveBrewSecondsLeft, elusiveBrewSpell
local sanctuaryOfTheOxCount, sanctuaryOfTheOxSecondsLeft, sanctuaryOfTheOxSpell
local shuffleCount, shuffleSecondsLeft, shuffleSpell
local tigerPowerCount, tigerPowerSecondsLeft, tigerPowerSpell
local weakenedBlowsCount,weakenedBlowsSecondsLeft,weakenedBlowsSpell

function MonkEC:GetSpellData(id) 
	local name, _, icon, cost, _, powerType = GetSpellInfo(id); 
	-- if id == 100784 then
		-- self:Print("bok uses chi:" .. tostring(powerType == chiPowerType) .. " cost=" .. cost)
	-- end

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
	risingSunKick = MonkEC:GetSpellData(107428),
}

-- Spell Details for Buffs
MonkEC.buff = {
	shuffle	= MonkEC:GetSpellData(115307),
	powerGuard = MonkEC:GetSpellData(118636),
	sanctuaryOfTheOx = MonkEC:GetSpellData(126119),
	tigerPower = MonkEC:GetSpellData(125359),
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
}

MonkEC.trackableBuffs = {	"Weakened Blows", "Shuffle", "Elusive Brew", "Mortal Wounds", "Tiger Power", 
							"Sanctuary of the Ox", "--------------" }

------------------------
-- Defaults and Options
------------------------
local defaults = {
	profile = {
		frame_width = 190,
		frame_height = 80,
		frame_x = 400,
		frame_y = 400,
		frame_scale = 1.0,
	
		buff_x = 400,
		buff_y = 300,
		buff_width = 190,
		buff_height = 50,
		buff_scale = 1.0,
		buff_isShown = true,
		buff_isShownProt = true,

		suggest_guard = false,
		suggest_touchOfDeath = false,
		suggest_summonBlackOxStatue = false,
		suggest_aoe = false,
			
		prot_priority_1 = 1, -- 
		prot_priority_2 = 2, -- 
		prot_priority_3 = 3, -- 
		prot_priority_4 = 4, -- 
		prot_priority_5 = 5, -- 
		prot_priority_6 = 6, -- 
		prot_priority_7 = 7, -- 
		prot_priority_8 = 8, -- 
		prot_priority_9 = 9, -- 
		prot_priority_10 = 10, -- 
		sw_stacks = 3,
		time_in_combat = 10,
		revenge_override = true,
				
		tracked_buffs_1 = 1,
		tracked_buffs_2 = 2,
		tracked_buffs_3 = 3,
		tracked_buffs_4 = 4,
			
		hs_threshold = 50,
		hs_threshold_prot = 50,
		ability_buffer = 0.2,
				
		icon_size = 64,
		icon_size_small = 48,
		icon_size_tiny = 32,				
		isLocked = false,
		showOnlyIC = false,
		enabled = true,
		enable_prot = true,
	},
}

local options = {
	name = "MonkEC",
	handler = MonkEC,
	type = "group",
	args = {
		lock = {
			type = "toggle",
			name = "Lock Frames",
			order = 10,
			desc = "Locks the MonkEC frame",
			get = function() return MonkEC.db.profile.isLocked end,
			set = "SetLocked",
		},
		showOnlyIC = {
			type = "toggle",
			name = "Show only in Combat",
			order = 20,
			desc = "Toggles showing the frames only while in combat",
			get = function() return MonkEC.db.profile.showOnlyIC end,
			set = function(self, value) MonkEC.db.profile.showOnlyIC = value
						MonkEC:UpdateFrameVisibility() end,
		},
		frame = {
			type = "group",
			name = "Ability Queue Frame",
			order = 100,
			args = {
				header = {
					type = "header",
					name = "Ability Queue Frame",
					order = 105,
				},
				scale = {
					type = "range",
					name = "Scale",
					order = 120,
					min = 0.5,
					max = 1.5,
					step = 0.1,
					desc = "Sets the scaling of the MonkEC Frame",		
					get = function() return MonkEC.db.profile.frame_scale end,
					set = "SetScale",
				},									
				posx = {
					type = "input",
					name = "X-Coordinate",
					order = 110,
					desc = "Sets the X-Coordinate of the MonkEC Frame",
					get = function() return MonkEC.db.profile.frame_x end,
					set = "SetXCoord",
				},
				posy = {
					type = "input",
					name = "Y-Coordinate",
					order = 115,
					desc = "Sets the Y-Coordinate of the MonkEC Frame",
					get = function() return MonkEC.db.profile.frame_y end,
					set = "SetYCoord",
				},
				buffer = {
					type = "range",
					name = "Ability Queue Priority Delay",
					order = 136,
					min = 0.1,
					max = 1.45,
					step = 0.05,
					width = "double",
					desc = "How long we should stall to wait for a higher priority ability. Example: Bloodthirst on 0.2 second cooldown, don't waste the GCD on slam.",		
					get = function() return MonkEC.db.profile.ability_buffer end,
					set = function(self, key) MonkEC.db.profile.ability_buffer = key end,
				},
				header2 = {
					type = "header",
					name = "Optional Ability Queue Suggestions",
					order = 137,
				},
				suggestTouchOfDeath = {
					type = "toggle",
					name = "Touch of Death",
					desc = "Will suggest using Touch of Death.",
					order = 140,
					get = function() return MonkEC.db.profile.suggest_touchOfDeath end,
					set = function() MonkEC.db.profile.suggest_touchOfDeath = not MonkEC.db.profile.suggest_touchOfDeath end,
				},
				suggestBlackOx = {
					type = "toggle",
					name = "Black Ox Statue",
					desc = "Will suggest using Summon Black Ox Statue.",
					order = 150,
					get = function() return MonkEC.db.profile.suggest_summonBlackOxStatue end,
					set = function() MonkEC.db.profile.suggest_summonBlackOxStatue = not MonkEC.db.profile.suggest_summonBlackOxStatue end,
				},
				suggestGuard = {
					type = "toggle",
					name = "Guard",
					desc = "Will suggest using Guard.",
					order = 160,
					get = function() return MonkEC.db.profile.suggest_guard end,
					set = function() MonkEC.db.profile.suggest_guard = not MonkEC.db.profile.suggest_guard end,
				},
				suggestOpeners = {
					type = "toggle",
					name = "Openers",
					desc = "Will suggest openers.",
					order = 170,
					get = function() return MonkEC.db.profile.suggest_openers end,
					set = function() MonkEC.db.profile.suggest_openers = not MonkEC.db.profile.suggest_openers end,
				},
				header3 = {
					type = "header",
					name = "Resource Thresholds",
					order = 200,
				},
				targetChi = {
					type = "range",
					name = "Target Chi",
					order = 210,
					min = 0,
					max = maxChi,
					step = 1,
					desc = "Sets the amount of chi that MonkEC will try to maintain",		
					get = function() return MonkEC.db.profile.targetChi end,
					set = "SetChiGoal",
				},									
				targetEnergy = {
					type = "range",
					name = "Energy Target",
					order = 220,
					min = 0,
					max = 100,
					step = 5,
					desc = "Sets the amount of energy that MonkEC will try to maintain",		
					get = function() return MonkEC.db.profile.targetEnergy end,
					set = "SetEnergyGoal",
				},									
				prot_priority = {
					type = "group",
					name = "Priorities",
					desc = "Priority of abilities in main frame",
					order = 600,
					args = {
						header = {
							type = "header",
							name = "Ability Priorities",
							order = 611,
						},										
						prot_enable = {
							type = "toggle",
							name = "Enable ability queue",
							width = "double",
							order = 605,
							get = function() return MonkEC.db.profile.enable_prot end,
							set = function() 
											MonkEC.db.profile.enable_prot = not MonkEC.db.profile.enable_prot
											MonkEC:UpdateFrameVisibility()
										end,
						},
						time_in_combat = {
							type = "range",
							name = "Combat Time Before Debuffs",
							desc = "Minimum time spent in combat before recommending missing debuffs. (Rend, Demo Shout, Thunderclap)",
							order = 608,
							min = 0,
							max = 30,
							step = 1,
							width = "double",
							get = function() return MonkEC.db.profile.time_in_combat end,
							set = function(self,key) MonkEC.db.profile.time_in_combat = key end,
						},
					},
				},				
			},
		},
		buffs = {
			type = "group",
			name = "Buffs / Debuffs Frame",
			order = 200,
			args = {
				header = {
					type = "header",
					name = "Buffs / Debuffs Frame",
					order = 205,
				},					 
				toggleProt = {
					type = "toggle",
					name = "Enable",
					order = 212,
					get = function() return MonkEC.db.profile.buff_isShownProt end,
					set = function(self, key) MonkEC.db.profile.buff_isShownProt = key
																		MonkEC:UpdateFrameVisibility() end,
				},					
				scale = {
					type = "range",
					name = "Scale",
					order = 220,
					min = 0.5,
					max = 1.5,
					step = 0.1,
					desc = "Sets the scaling of the Buffs / Debuffs Frame",		
					get = function() return MonkEC.db.profile.buff_scale end,
					set = "SetBuffScale",
				},									
				posx = {
					type = "input",
					name = "X-Coordinate",
					order = 230,
					desc = "Sets the X-Coordinate of the Buffs / Debuffs Frame",
					get = function() return MonkEC.db.profile.buff_x end,
					set = "SetBuffXCoord",
				},
				posy = {
					type = "input",
					name = "Y-Coordinate",
					order = 240,
					desc = "Sets the Y-Coordinate of the Buffs / Debuffs Frame",
					get = function() return MonkEC.db.profile.buff_y end,
					set = "SetBuffYCoord",
				},
				protGroup = {
					type = "group",
					name = "Buffs/Debuffs",
					args = {
						-- prot
						header = {
							type = "header",
							name = "Brewmaster Buffs/Debuffs",
							order = 254,
						},
						tracked_buff1 = {
							type = "select",
							name = "Buff #1",
							desc = "Custom Buff #1",
							order = 255,
							values = MonkEC.trackableBuffs,
							get = function() return MonkEC.db.profile.tracked_buffs_1 end,
							set = function(self, key)	
											MonkEC.db.profile.tracked_buffs_1 = key
										end,
							style = "dropdown",						
						},
						tracked_buff2 = {
							type = "select",
							name = "Buff #2",
							desc = "Custom Buff #2",
							order = 255,
							values = MonkEC.trackableBuffs,
							get = function() return MonkEC.db.profile.tracked_buffs_2 end,
							set = function(self, key)	
											MonkEC.db.profile.tracked_buffs_2 = key
										end,
							style = "dropdown",						
						},
						tracked_buff3 = {
							type = "select",
							name = "Buff #3",
							desc = "Custom Buff #3",
							order = 255,
							values = MonkEC.trackableBuffs,
							get = function() return MonkEC.db.profile.tracked_buffs_3 end,
							set = function(self, key)	
											MonkEC.db.profile.tracked_buffs_3 = key
										end,
							style = "dropdown",						
						},
						tracked_buff4 = {
							type = "select",
							name = "Buff #4",
							desc = "Custom Buff #4",
							order = 255,
							values = MonkEC.trackableBuffs,
							get = function() return MonkEC.db.profile.tracked_buffs_4 end,
							set = function(self, key)	
											MonkEC.db.profile.tracked_buffs_4 = key
										end,
							style = "dropdown",						
						},					
					},
				},
			},
		},
	},
}

---------------------------------------------
-- On Initialized, Enable and Disable Methods
---------------------------------------------
function MonkEC:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("MonkECDB", defaults, "Default")
	local className, myClass = UnitClass("player")
	if myClass ~= "MONK" then
		self:Print("You have loaded MonkEC on a " .. className .. ". This addon is designed for the Monk class.")
	else
		self:Initialize()
	end	
end

function MonkEC:Initialize()
	LibStub("AceConfigDialog-3.0"):SetDefaultSize("MonkEC", 600,	500)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("MonkEC", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MonkEC", "MonkEC")	
	self:RegisterChatCommand("monkec", "ChatCommand")
	
	self:RegisterEvent("PLAYER_TALENT_UPDATE")	
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		
	self:InitAbilityFrame()
	self:InitBuffFrame()
	
	self:CreatePriorityLists();
	
	self:Print("MonkEC loaded. Please type /monkec config for the configuration GUI")
end
 
function MonkEC:OnEnable()
	MonkEC:InspectSpecialization()
end

function MonkEC:OnDisable()
end

function MonkEC:PLAYER_TALENT_UPDATE()
	MonkEC:InspectSpecialization()
end

function MonkEC:COMBAT_LOG_EVENT_UNFILTERED(self, event, ...)

end

function MonkEC:InspectSpecialization()
	talentSpec = GetSpecialization()

	if GetSpellBookItemInfo(MonkEC.talent.ascension.name) ~= nil then
		maxChi = 5
	end
	if GetSpellBookItemInfo(MonkEC.talent.powerStrikes.name) ~= nil then
		maximumChiGain = 2
	end
	
	haveHealingElixirs = GetSpellBookItemInfo(MonkEC.talent.chiBurst.name) ~= nil
	
	self:DetermineChiGeneration()
	self:DetermineSpellCooldowns()
	
	if self.common.blackoutKick.cost ~= 2 then
		self:Print("Blackout Kick cost is incorrect (" .. tostring(self.common.blackoutKick.cost) .. " vs 2).  Try switching specs and reloading.")
	end
	if self.common.touchOfDeath.cost ~= 3 then
		self:Print("Touch of Death cost is incorrect (" .. tostring(self.common.touchOfDeath.cost) .. " vs 2).  Try switching specs and reloading.")
	end
end

function MonkEC:DetermineChiGeneration()
	self.common.expelHarm.chiGenerated = maximumChiGain
	self.common.jab.chiGenerated = maximumChiGain
	self.common.spinningCraneKick.chiGenerated = maximumChiGain
	self.talent.chiBrew.chiGenerated = maxChi
	self.brewmaster.kegSmash.chiGenerated = maximumChiGain
end

function MonkEC:DetermineSpellCooldowns()
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
	self.windwalker.risingSunKick.cooldownLength = 8
end

function MonkEC:CreatePriorityLists()
	desperationPriorities = {
		{	spell = self.brewmaster.guard, condition = nil, },
		{	spell = self.brewmaster.fortifyingBrew, condition = nil, },
		{	spell = self.brewmaster.dampenHarm, condition = nil, },
		{	spell = self.brewmaster.purifyingBrew, 
			condition = function(self, value) 
				return haveHealingElixirs; 
			end, 
		},
		{	spell = self.talent.chiBurst, condition = nil, },
		{	spell = self.talent.chiWave, condition = nil, },
		{	spell = self.talent.zenSphere, condition = nil, },
		{	spell = self.common.expelHarm, condition = nil, },
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
				return (self.frame.aoeToggle:GetValue() == true)
			end, 
		},
		{	spell = self.common.jab, 
			condition = function(self, characterState) 
				return UnitExists("target") and
						(self.frame.aoeToggle:GetValue() == false) 
			end, 
		},
		{	spell = self.brewmaster.guard, 
			condition = function(self, characterState) return (self.db.profile.suggest_guard == true) end, },
		{	spell = self.talent.chiBurst, 
			condition = function(self, characterState) return self:DamagedEnough(characterState) end, },
		{	spell = self.talent.chiWave, 
			condition = function(self, characterState) return self:DamagedEnough(characterState) end, },
		{	spell = self.talent.zenSphere, 
			condition = function(self, characterState) return self:DamagedEnough(characterState) end, },
		{	spell = self.brewmaster.breathOfFire, 
			condition = function(self, characterState) 
				return UnitExists("target") and
						(self.frame.aoeToggle:GetValue() == true) 
			end, 
		},
		-- {	spell = self.common.blackoutKick, 
			-- condition = function(self, characterState) 
				-- return UnitExists("target") and self:DumpChi(characterState)
			-- end, 
		-- },
		{	spell = self.common.tigerPalm, 
			condition = function(self, characterState) 
				return UnitExists("target")
			end, 
		},
	}
end

----------------------------------
-- Override the OnUpdate function
----------------------------------
local function OnUpdate(this, elapsed)
	timeSinceLastUpdate = timeSinceLastUpdate + elapsed
	if timeSinceLastUpdate > updateFrequency then	
		MonkEC:UpdateTrackedBuffs()
		MonkEC:UpdateQueue()
		MonkEC:UpdateCDs()

		if (MonkEC.buffFrame:IsShown() ~= nil) then
			MonkEC:UpdateBuffFrame()
		end
		
		-- Refresh Textures
		MonkEC:RefreshTextures()
		
		MonkEC:UpdateFrameVisibility()

		timeSinceLastUpdate = 0
	end
end

-----------------------------------------------
-- Frame initializing for MonkEC, Buffs, RageBar
------------------------------------------------
function MonkEC:InitAbilityFrame()
	-- MonkEC and Ability Frames
	local scale = self.db.profile.frame_scale
	local iconSize = self.db.profile.icon_size
	local iconSizeSmall = self.db.profile.icon_size_small
	local baseFrame = CreateFrame("Frame", "MonkECAbilityFrame", UIParent)
	self.frame = baseFrame
	
	-- Set Frame Strata and load background
	baseFrame:SetFrameStrata("BACKGROUND")
	baseFrame:SetWidth(self.db.profile.frame_width * scale)
	baseFrame:SetHeight(self.db.profile.frame_height * scale)
	
	-- Set the Backdrop
	baseFrame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = nil,
		tile = true, tileSize = 4, edgeSize = 0,
		insets = { left = 1, right = 1, top = 1, bottom = 1 }
	})
	if (self.db.profile.isLocked == true) then
		baseFrame:SetBackdropColor(0, 0, 0, 0)
	else
		baseFrame:SetBackdropColor(0, 0, 0, 0.7)
	end
	
	baseFrame.abilityFrame = {
		MonkEC:CreateAbilityFrame("MonkECAbility1", baseFrame, 
			MonkEC.brewmaster.breathOfFire, abilityIconXOffset[1], abilityIconYOffset, iconSize, scale),
		MonkEC:CreateAbilityFrame("MonkECAbility2", baseFrame, 
			MonkEC.brewmaster.kegSmash, abilityIconXOffset[2], abilityIconYOffset, iconSizeSmall, scale),
		MonkEC:CreateAbilityFrame("MonkECAbility3", baseFrame, 
			MonkEC.brewmaster.clash, abilityIconXOffset[3], abilityIconYOffset, iconSizeSmall, scale),
	}
	
	-- AOE check Box
	aoeToggle = AceGUI:Create("CheckBox")
	aoeToggle:SetLabel("AOE")
	aoeToggle:SetType("checkbox")
	aoeToggle:SetValue(true)
	aoeToggle.frame:ClearAllPoints()
	aoeToggle.frame:SetPoint("BOTTOMLEFT", baseFrame, "BOTTOMLEFT", 
			aoeToggleXOffset * scale, aoeToggleYOffset * scale)
	aoeToggle.frame:Show()

	baseFrame.aoeToggle = aoeToggle

	-- Set X/Y points, enable mouse 
	baseFrame:ClearAllPoints()
	baseFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.frame_x, self.db.profile.frame_y)
	baseFrame:EnableMouse(true)
	baseFrame:SetMovable(true)
	baseFrame:SetClampedToScreen(true)
	baseFrame:RegisterForDrag("LeftButton")
	baseFrame:SetScript("OnDragStart", function()
		baseFrame:StartMoving()
	end) 
	baseFrame:SetScript("OnDragStop", function()
		local baseFrame = MonkEC.frame;
		local profile = MonkEC.db.profile
		baseFrame:StopMovingOrSizing()
		profile.frame_x = baseFrame:GetLeft()
		profile.frame_y = baseFrame:GetTop()
		baseFrame.aoeToggle.frame:ClearAllPoints()
		baseFrame.aoeToggle.frame:SetPoint("BOTTOMLEFT", baseFrame, "BOTTOMLEFT", 
				aoeToggleXOffset * scale, aoeToggleYOffset * scale)
	end)	

	if (self.db.profile.isLocked == true) then
		baseFrame:EnableMouse(false)
	else
		baseFrame:EnableMouse(true)
	end

	-- Set up OnUpdate
	self.frame:SetScript("OnUpdate", OnUpdate)
end

function MonkEC:InitBuffFrame()
	local buffFrame = CreateFrame("Frame", "MonkECBuffFrame", UIParent)

	local iconSize = self.db.profile.icon_size_tiny
	local scale = self.db.profile.buff_scale

	self.buffFrame = buffFrame
	
	-- Create individual buff/debuffs
	buffFrame.buff1 = self:CreateBuffFrame("MonkECBuffsBuff1", buffFrame, 
			self.debuff.weakenedBlows, buffIconXOffset[1], buffIconYOffset, iconSize, scale)
	buffFrame.buff2 = self:CreateBuffFrame("MonkECBuffsBuff2", buffFrame, 
			self.buff.shuffle, buffIconXOffset[2], buffIconYOffset, iconSize, scale)
	buffFrame.buff3 = self:CreateBuffFrame("MonkECBuffsBuff3", buffFrame, 
			self.brewmaster.dizzyingHaze, buffIconXOffset[3], buffIconYOffset, iconSize, scale)
	buffFrame.buff4 = self:CreateBuffFrame("MonkECBuffsBuff4", buffFrame, 
			self.debuff.mortalWounds, buffIconXOffset[4], buffIconYOffset, iconSize, scale)

	-- Set Frame Strata and load background
	buffFrame:SetFrameStrata("BACKGROUND")
	buffFrame:SetWidth(self.db.profile.buff_width * scale)
	buffFrame:SetHeight(self.db.profile.buff_height * scale)

	-- Set the Backdrop
	buffFrame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = nil,
		tile = true, tileSize = 4, edgeSize = 0,
		insets = { left = 1, right = 1, top = 1, bottom = 1 }
	})
	if (self.db.profile.isLocked == true) then
		buffFrame:SetBackdropColor(0, 0, 0, 0)
	else
		buffFrame:SetBackdropColor(0, 0, 0, 0.7)
	end

	-- Setup the Buffs Frame
	buffFrame:ClearAllPoints()
	buffFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.buff_x, self.db.profile.buff_y)
	buffFrame:EnableMouse(true)
	buffFrame:SetMovable(true)
	buffFrame:SetClampedToScreen(true)
	buffFrame:RegisterForDrag("LeftButton")
	buffFrame:SetScript("OnDragStart", function()
		buffFrame:StartMoving()
	end) 
	buffFrame:SetScript("OnDragStop", function()
		buffFrame:StopMovingOrSizing()
		self.db.profile.buff_x = buffFrame:GetLeft()
		self.db.profile.buff_y = buffFrame:GetTop()
	end)	
	
	if (self.db.profile.isLocked == true) then
		buffFrame:EnableMouse(false)
	else
		buffFrame:EnableMouse(true)
	end
	
	-- We're ready to process updates on this frame since we're done constructing it
	self.buffFrame:SetScript("OnUpdate", OnUpdate)
end

function MonkEC:CreateAbilityFrame(baseName, parentFrame, ability, xOffset, yOffset, size, scale)
	local abilityFrame = self:CreateSpellFrame(baseName, parentFrame, ability, xOffset, yOffset, size, scale)

	abilityFrame.cooldownFrame = CreateFrame("Cooldown", baseName .. "Cooldown", abilityFrame)	
	abilityFrame.cooldownFrame:SetAllPoints(abilityFrame)
	
	return abilityFrame
end

function MonkEC:CreateBuffFrame(baseName, parentFrame, buff, xOffset, yOffset, iconSize, scale)
	local buffFrame = self:CreateSpellFrame(baseName, parentFrame, buff, xOffset, yOffset, iconSize, scale)

	buffFrame.secondsLeftText = self:CreateBuffText(buffFrame, "LEFT", 6, 0, scale, 12)
	buffFrame.stackCountText = self:CreateBuffText(buffFrame, "BOTTOMRIGHT", -1, -1, scale, 10)
	
	buffFrame:SetFrameStrata("BACKGROUND")

	return buffFrame
end

function MonkEC:CreateSpellFrame(baseName, parentFrame, spell, xOffset, yOffset, iconSize, scale)
	local spellFrame = CreateFrame("Frame", baseName .. "Frame", parentFrame)
	local scaledXOffset = xOffset * scale
	local scaledYOffset = yOffset * scale
	local scaledIconSize = iconSize * scale

	spellFrame.spell = spell	
	spellFrame:SetWidth(scaledIconSize)
	spellFrame:SetHeight(scaledIconSize)
	spellFrame:ClearAllPoints()
	spellFrame:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", scaledXOffset, scaledYOffset)
	spellFrame.icon = spellFrame:CreateTexture(nil, "OVERLAY")
	spellFrame.icon:SetTexture(spell.icon)
	spellFrame.icon:SetWidth(scaledIconSize)
	spellFrame.icon:SetHeight(scaledIconSize)
	spellFrame.icon:ClearAllPoints() 
	spellFrame.icon:SetPoint("BOTTOMLEFT", spellFrame, "BOTTOMLEFT")
	
	return spellFrame
end

function MonkEC:CreateBuffText(parentFrame, location, xOffset, yOffset, scale, pointSize)
	local text = parentFrame:CreateFontString(nil, "OVERLAY")
	text:ClearAllPoints()
	text:SetPoint(location, parentFrame, location, xOffset * scale, yOffset * scale)
	text:SetJustifyH("CENTER")
	text:SetFont("Fonts\\FRIZQT__.TTF", pointSize * scale, "OUTLINE")
	text:SetText("")
	
	return text
end

function MonkEC:UpdateFrameVisibility()
	local showAbilityFrame = false
	local showBuffFrame = false
	
	if talentSpec == nil then
		self:Print("All frames hidden until a spec is chosen.")
	else
		if MonkEC:TalentSpecIsSupported() then
			if not self.db.profile.showOnlyIC or inCombat then
				if self.db.profile.enabled then
					showAbilityFrame = true
					showBuffFrame = self.db.profile.buff_isShown
				end
			end
		end
	end
	
	if showAbilityFrame then
		if not self.frame:IsShown() then
			self.frame:Show()
		end
	else
		if self.frame:IsShown() then
			self.frame:Hide()
		end
	end
				
	if showBuffFrame then
		if not self.buffFrame:IsShown() then
			self.buffFrame:Show()
		end
	else
		if self.buffFrame:IsShown() then
			self.buffFrame:Hide()
		end
	end
end

function MonkEC:TalentSpecIsSupported() 
	return talentSpec == talentSpecBrewmaster
end

function MonkEC:PLAYER_REGEN_ENABLED()
	inCombat = false
	self:UpdateFrameVisibility()
end

function MonkEC:PLAYER_REGEN_DISABLED()
	inCombat = true
	timeEnteringCombat = GetTime()
	self:UpdateFrameVisibility()
end

---------------------------------
-- Scale of MonkEC/Buffs frames
---------------------------------							 
function MonkEC:SetScale(info, scale)
	if (tonumber(scale) > 1.5 or tonumber(scale) < 0.5) then
		self:Print("Scale value out of range (0.5-1.5)")
	else
		self.db.profile.frame_scale = scale
		self:ScaleFrame()
	end
end

function MonkEC:ScaleFrame()
	local scale = self.db.profile.frame_scale
	local iconSize = self.db.profile.icon_size
	local iconSmallSize = self.db.profile.icon_size_small
	local frame = self.frame

	frame:SetWidth(self.db.profile.frame_width * scale)
	frame:SetHeight(self.db.profile.frame_height * scale)
	
	self:ScaleSpell(frame.abilityFrame[1], frame, abilityIconXOffset[1], abilityIconYOffset, iconSize, scale)
	self:ScaleSpell(frame.abilityFrame[2], frame, abilityIconXOffset[2], abilityIconYOffset, iconSmallSize, scale)
	self:ScaleSpell(frame.abilityFrame[3], frame, abilityIconXOffset[3], abilityIconYOffset, iconSmallSize, scale)
	
	-- AOE Frame
	frame.aoeToggle.frame:ClearAllPoints()
	frame.aoeToggle.frame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 
				aoeToggleXOffset * scale, aoeToggleYOffset * scale)
end

function MonkEC:SetBuffScale(info, value)
	if (tonumber(value) > 1.5 or tonumber(value) < 0.5) then
		self:Print("Scale value out of range (0.5-1.5)")
	else
		self.db.profile.buff_scale = value
		self:ScaleBuffFrame()
	end
end

function MonkEC:ScaleSpell(spell, parentFrame, xOffset, yOffset, iconSize, scale)
	local scaledIconSize = iconSize * scale
	local scaledXOffset = xOffset * scale
	local scaledYOffset = yOffset * scale
	
	spell:SetWidth(scaledIconSize)
	spell:SetHeight(scaledIconSize)
	spell:ClearAllPoints()
	spell:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", scaledXOffset, scaledYOffset)
	spell.icon:SetWidth(scaledIconSize)
	spell.icon:SetHeight(scaledIconSize)
end

function MonkEC:ScaleBuffFrame()
	local buffSize = self.db.profile.icon_size_tiny;
	local buffScale = self.db.profile.buff_scale;
	local buffFrame = self.buffFrame
	
	buffFrame:SetWidth(self.db.profile.buff_width * buffScale)
	buffFrame:SetHeight(self.db.profile.buff_height * buffScale) 
	
	self:ScaleBuff(buffFrame.buff1, buffFrame, buffIconXOffset[4], buffIconYOffset, buffSize, buffScale)
	self:ScaleBuff(buffFrame.buff2, buffFrame, buffIconXOffset[4], buffIconYOffset, buffSize, buffScale)
	self:ScaleBuff(buffFrame.buff3, buffFrame, buffIconXOffset[4], buffIconYOffset, buffSize, buffScale)
	self:ScaleBuff(buffFrame.buff4, buffFrame, buffIconXOffset[4], buffIconYOffset, buffSize, buffScale)
end

function MonkEC:ScaleBuff(buff, parentFrame, xOffset, yOffset, iconSize, scale)
	self:ScaleSpell(buff, parentFrame, xOffset, yOffset, iconSize, scale)
	
	buff.secondsLeftText:SetFont("Fonts\\FRIZQT__.TTFa", 12 * scale, "OUTLINE")
	buff.stackCountText:SetFont("Fonts\\FRIZQT__.TTFa", 10 * scale, "OUTLINE")
end

function MonkEC:SetEnergyGoal(info, energy)
	if (tonumber(energy) < 0 or tonumber(energy) > 100) then
		self:Print("Energy target value out of range (0-100)")
	else
		self.db.profile.targetEnergy = energy
	end
end

function MonkEC:SetChiGoal(info, chi)
	if (tonumber(chi) < 0 or tonumber(chi) > maxChi) then
		self:Print("Chi target value out of range (0-" .. maxChi .. ")")
	else
		self.db.profile.targetChi = chi
	end
end

-------------------------------
-- Interpret the Chat Commnads
-------------------------------
function MonkEC:ChatCommand(input)
	if input:trim() == "options" or input:trim() == "config" then
		LibStub("AceConfigDialog-3.0"):Open("MonkEC", self.optionFrame)
	else
		self:Print("MonkEC: Enter \"/MonkEC config\" for configuration GUI")
	end
end

------------------------------------
-- Update the DPS Priority Queue (Prot)
------------------------------------
function MonkEC:UpdateQueue()
	-- Find the current GCD
	local currentStart,currentBaseGCD = GetSpellCooldown(self.common.jab.id)
	local currentGCD = 0
	if (currentStart > 0) then
		currentGCD = currentBaseGCD - (GetTime() - currentStart)
	end
	
	self:UpdateCooldowns(currentGCD, MonkEC.common)
	self:UpdateCooldowns(currentGCD, MonkEC.talent)
	self:UpdateCooldowns(currentGCD, MonkEC.brewmaster)
	
	local characterState = self:GatherCharacterState()

	for i = 1,3 do
--self:Print("loop " .. i .. " gcd=" .. currentGCD .. " energy=" .. characterState.energy .. " chi=" .. characterState.chi)
		local spell = self:FindNextSpell(currentGCD, characterState)
		self.frame.abilityFrame[i].spell = spell
		if spell ~= nil then
			self:UpdateStateForSpellcast(spell, characterState)
		end
		currentGCD = currentGCD + theGCD
	end
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

function MonkEC:GatherCharacterState()
	local state = {
		stance = GetShapeshiftForm(),
		inMeleeRange = IsSpellInRange(MonkEC.common.jab.name, "target") == 1,
		currentHealthPercentage = UnitHealth("player") / UnitHealthMax("player") * 100,
		chi = UnitPower("player", SPELL_POWER_LIGHT_FORCE),
		energy = UnitPower("player"),
		
		playerHasLegacyOfTheEmperor = UnitBuff("player", self.common.legacyOfTheEmperor.name) ~= nil,
		playerHasSanctuaryOfTheOx = UnitBuff("player", self.buff.sanctuaryOfTheOx.name) ~= nil,
		
		shuffleSecondsLeft = shuffleSecondsLeft,
		staggerTooHigh = (UnitDebuff("player", self.debuff.moderateStagger.name) ~= nil) or 
						(UnitDebuff("player", self.debuff.heavyStagger.name) ~= nil),

		weakenedBlowsSecondsLeft = weakenedBlowsSecondsLeft,
		
		tigerPowerCount = tigerPowerCount,
		tigerPowerSecondsLeft = tigerPowerSecondsLeft,
	}
		
	if state.shuffleSecondsLeft == nil then
		state.shuffleSecondsLeft = 0
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
	
	return state
end

function MonkEC:UpdateStateForSpellcast(spell, characterState)
	self:ConsumePowerForSpell(spell, characterState)
	self:GenerateChiFromSpell(spell, characterState)
	self:UpdateBuffsForSpell(spell, characterState)
	self:IncreaseCooldown(spell)
	self:NextGCD(characterState)
end

function MonkEC:NextGCD(characterState)
	characterState.energy = characterState.energy + energyGeneratedPerGCD
	characterState.shuffleSecondsLeft = characterState.shuffleSecondsLeft - 1
	characterState.tigerPowerSecondsLeft = characterState.tigerPowerSecondsLeft - 1
	characterState.weakenedBlowsSecondsLeft = characterState.weakenedBlowsSecondsLeft - 1
end

function MonkEC:ConsumePowerForSpell(spell, characterState)
	if spell.powerType == energyPowerType then
		characterState.energy = characterState.energy - spell.cost
	elseif spell.powerType == chiPowerType then
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
		characterState.chi = maxChi
	end
end

function MonkEC:UpdateBuffsForSpell(spell, characterState)
	if spell.id == self.buff.sanctuaryOfTheOx.id then
		characterState.playerHasSanctuaryOfTheOx = true
	elseif spell.id == self.common.legacyOfTheEmperor.id then
		characterState.playerHasLegacyOfTheEmperor = true
	elseif spell.id == self.brewmaster.stanceOfTheSturdyOx.id then
		characterState.stance = brewmasterStance
	elseif spell.id == self.common.blackoutKick.id then
		characterState.shuffleSecondsLeft = 8
	elseif spell.id == self.common.tigerPalm.id then
		if characterState.tigerPowerCount < 3 then
			characterState.tigerPowerCount = characterState.tigerPowerCount + 1
		end
		characterState.tigerPowerSecondsLeft = 20
	elseif spell.id == self.brewmaster.dizzyingHaze.id or spell.id == self.brewmaster.kegSmash.id then
		characterState.weakenedBlowsSecondsLeft = 15
	end
end

function MonkEC:IncreaseCooldown(spell)
	if spell.cooldownLength == nil then 
		spell.cooldown = spell.cooldown + theGCD
	else
		spell.cooldown = spell.cooldown + spell.cooldownLength
	end
end

function MonkEC:FindNextSpell(currentGCD, characterState)
	local spell = nil
	
	if talentSpec == talentSpecBrewmaster then
		if self:InDesperateNeedOfHealing(characterState) then
			spell = self:FindNextSpellFrom(desperationPriorities, currentGCD, characterState)
		else
			spell = self:FindNextSpellFrom(brewmasterPriorities, currentGCD, characterState)
		end
	end

	return spell
end

function MonkEC:InDesperateNeedOfHealing(characterState)
	return characterState.currentHealthPercentage < 20
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

function MonkEC:DoElusiveBrew(characterState)
	return (elusiveBrewCount ~= nil) and (elusiveBrewCount > 4)
end

function MonkEC:ChiWillNotOverflow(spell, characterState)
	local willNotOverflow = true

	if spell.chiGenerated ~= nil then
		willNotOverflow = (characterState.chi + spell.chiGenerated) <= maxChi
		--MonkEC:Print("ChiWillNotOverflow: " .. tostring(willNotOverflow) .. " = (" .. characterState.chi .. " + " .. spell.chiGenerated .. ") <= " .. maxChi)
	end
	
	return willNotOverflow
end

function MonkEC:BuffWearingOffSoon(spell, characterState)
	local wearingOffSoon = true
	
	if spell.id == self.buff.shuffle.id then
--self:Print("Checking shuffle characterState.shuffleSecondsLeft > theGCD - " .. characterState.shuffleSecondsLeft .. ">" .. theGCD .. "=" .. tostring(characterState.shuffleSecondsLeft > theGCD))
		if characterState.shuffleSecondsLeft > theGCD then
			wearingOffSoon = false
		end
	end
	
	return wearingOffSoon
end

function MonkEC:DebuffWearingOffSoon(spell, characterState)
	local wearingOffSoon = true
	
	if spell.id == self.debuff.weakenedBlows.id then
		if characterState.weakenedBlowsSecondsLeft > theGCD then
			wearingOffSoon = false
		end
	end
	
	return wearingOffSoon
end

function MonkEC:DamagedEnough(characterState)
	return characterState.currentHealthPercentage < 80
end

function MonkEC:DumpChi(characterState)
	return characterState.chi > 3
end

function MonkEC:NeedsMoreTigerPower(characterState)
	return characterState.tigerPowerCount < 3
end

function MonkEC:FindNextSpellFrom(priorities, currentGCD, characterState)
	for key,candidate in pairs(priorities) do
		if candidate.spell ~= nil then
			local candidateAccepted = true
			if candidate.condition ~= nil then
				candidateAccepted = candidate.condition(self, characterState)
			end
			
			if candidateAccepted then
				candidateAccepted = self:CanPerformSpell(candidate.spell, currentGCD, characterState)
			end
			
			if candidateAccepted then
				return candidate.spell
			end
		end
	end
	
	return nil
end

function MonkEC:CanPerformSpell(spell, currentGCD, characterState)
	local canPerform = true
	
	-- if spell.id == self.common.blackoutKick.id then
		-- self:Print("bok uses chi:" .. tostring(spell.powerType == chiPowerType) .. " cost=" .. spell.cost
		-- .. " and " .. characterState.chi .. " is available")
	-- end
	if spell.powerType == energyPowerType then
		canPerform = characterState.energy >= spell.cost
	elseif spell.powerType == chiPowerType then
		canPerform = characterState.chi >= spell.cost
	end
	
	if canPerform then
		canPerform = spell.cooldown <= currentGCD
		if canPerform then
			canPerform = self:ChiWillNotOverflow(spell, characterState)
			-- if not canPerform then
				-- self:Print(spell.name .. " would overflow chi " .. characterState.chi)
			-- end
		-- else
			-- self:Print(spell.name .. " will be on cooldown until " .. spell.cooldown)
		end
	end

	return canPerform
end

function MonkEC:StanceIsWrong(characterState)
	local stanceIsWrong = true
	
	if talentSpec == talentSpecBrewmaster and characterState.stance == brewmasterStance then
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

------------------------------------
-- Refresh icons in the DPS queue
------------------------------------
function MonkEC:RefreshTextures()
	for i = 1,3 do
		if self.frame.abilityFrame[i].spell == nil then
			self.frame.abilityFrame[i].icon:SetTexture(nil)
		else
			self.frame.abilityFrame[i].icon:SetTexture(self.frame.abilityFrame[i].spell.icon)
		end
	end
	self.buffFrame.buff1.icon:SetTexture(self.buffFrame.buff1.spell.icon)
	self.buffFrame.buff2.icon:SetTexture(self.buffFrame.buff2.spell.icon)
	self.buffFrame.buff3.icon:SetTexture(self.buffFrame.buff3.spell.icon)
	self.buffFrame.buff4.icon:SetTexture(self.buffFrame.buff4.spell.icon)
end

------------------------------------
-- Update the Cooldowns on the ability queue.
------------------------------------
function MonkEC:UpdateCDs()
	for i = 1,3 do
		if self.frame.abilityFrame[i].spell ~= nil then
			local start, duration = GetSpellCooldown(self.frame.abilityFrame[i].spell.id)
			if duration and duration > 0 and inCombat == true and self.frame.abilityFrame[i]:IsShown() ~= nil then
				self.frame.abilityFrame[i].cooldownFrame:SetCooldown(start, duration)
				self.frame.abilityFrame[i].cooldownFrame:Show()
			else
				self.frame.abilityFrame[i].cooldownFrame:Hide()
			end
		end
	end
end

-------------------------------------
-- Update Buff/Debuff durations and 
-- change opacities based on them
-------------------------------------
function MonkEC:UpdateBuffFrame()
	local buff1 = self.buffFrame.buff1
	local buff2 = self.buffFrame.buff2
	local buff3 = self.buffFrame.buff3
	local buff4 = self.buffFrame.buff4

	-- Update buff icons
	buff1.spell,buff1.secondsLeft,buff1.stacknum = self:GetBuffInfo(self.db.profile.tracked_buffs_1)
	buff2.spell,buff2.secondsLeft,buff2.stacknum = self:GetBuffInfo(self.db.profile.tracked_buffs_2)
	buff3.spell,buff3.secondsLeft,buff3.stacknum = self:GetBuffInfo(self.db.profile.tracked_buffs_3)
	buff4.spell,buff4.secondsLeft,buff4.stacknum = self:GetBuffInfo(self.db.profile.tracked_buffs_4)
	
	-- Update Buff Text
	self:UpdateBuffText(buff1)
	self:UpdateBuffText(buff2)
	self:UpdateBuffText(buff3)
	self:UpdateBuffText(buff4)
end

function MonkEC:UpdateBuffText(buffFrame)
	local alpha = 0.3
	local secondsLeft = ""
	local stackCount = ""
	local buffScale = self.db.profile.buff_scale

	if buffFrame.secondsLeft ~= nil and buffFrame.secondsLeft > 0 then
		alpha = 1
		if (buffFrame.secondsLeft <= 9.5) then
			buffFrame.secondsLeftText:ClearAllPoints()
			buffFrame.secondsLeftText:SetPoint("LEFT", buffFrame, "LEFT", 10 * buffScale, 0)
			buffFrame.stackCountText:ClearAllPoints()
			buffFrame.stackCountText:SetPoint("BOTTOMRIGHT", buffFrame, "BOTTOMRIGHT", -1 * buffScale, 1 * buffScale)
		else
			buffFrame.secondsLeftText:ClearAllPoints()
			buffFrame.secondsLeftText:SetPoint("LEFT", buffFrame, "LEFT", 6 * buffScale, 0)		
		end
		secondsLeft = format("%.0f", buffFrame.secondsLeft)
		
		if buffFrame.stacknum ~= nil and buffFrame.stacknum > 0 then
			stackCount = buffFrame.stacknum
		end 
	end

	buffFrame:SetAlpha(alpha)
	buffFrame.icon:SetTexture(buffFrame.icon)
	buffFrame.secondsLeftText:SetText(secondsLeft)
	buffFrame.stackCountText:SetText(stackCount)
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
		return mortalWoundsIcon,mortalWoundsSecondsLeft,mortalWoundsCount
	elseif num == 5 then
		return tigerPowerSpell,tigerPowerSecondsLeft,tigerPowerCount
	else
		return sanctuaryOfTheOxSpell,sanctuaryOfTheOxTime,sanctuaryOfTheOxCount
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
end

-----------------------------------------------------
-- Methods for setting options
-----------------------------------------------------
function MonkEC:SetXCoord(info, value)
	if (self.db.profile.isLocked == false) then
		self.db.profile.frame_x = value
		self.frame:ClearAllPoints()
		self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.frame_x, self.db.profile.frame_y)
	end
end

function MonkEC:SetYCoord(info, value)
	if (self.db.profile.isLocked == false) then
		self.db.profile.frame_y = value
		self.frame:ClearAllPoints()
		self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.frame_x, self.db.profile.frame_y)
	end
end

function MonkEC:SetBuffXCoord(info, value)
	if (self.db.profile.isLocked == false) then
		self.db.profile.buff_x = value
		self.buffFrame:ClearAllPoints()
		self.buffFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.buff_x, self.db.profile.buff_y)
	end
end

function MonkEC:SetBuffYCoord(info, value)
	if (self.db.profile.isLocked == false) then
		self.db.profile.buff_y = value
		self.buffFrame:ClearAllPoints()
		self.buffFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.buff_x, self.db.profile.buff_y)
	end
end

----------------------------------------
-- Toggling of MonkEC/Buffs Locking
---------------------------------------
function MonkEC:SetLocked(info, newLockedValue)
	self.db.profile.isLocked = newLockedValue
	
	if (newLockedValue == true) then
			self.frame:EnableMouse(false)
			self.frame:SetBackdropColor(0, 0, 0, 0)
			self.buffFrame:EnableMouse(false)
			self.buffFrame:SetBackdropColor(0, 0, 0, 0)
	else
			self.frame:EnableMouse(true)
			self.frame:SetBackdropColor(0, 0, 0, 0.7)
			self.buffFrame:EnableMouse(true)
			self.buffFrame:SetBackdropColor(0, 0, 0, 0.7)
	end
	
	self:UpdateFrameVisibility()
end
