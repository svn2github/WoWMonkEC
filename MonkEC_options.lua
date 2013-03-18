local _, trueclass = UnitClass("player")
if trueclass ~= "MONK" then return end
 
MonkEC.trackableBuffs = {}

function MonkEC:InitializeOptions()
	MonkEC.trackableBuffs = { WEAKENEDBLOWS, SHUFFLE, ELUSIVEBREW, TIGERPOWER, SANCTUARYOFTHEOX }
	
	local defaults = {
		profile = {
			enabled = true,
			isLocked = false,
			showOnlyIC = false,

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
		
			cooldowns_x = 400,
			cooldowns_y = 300,
			cooldowns_width = 190,
			cooldowns_height = 50,
			cooldowns_scale = 1.0,
			cooldowns_isShown = true,

			suggest_guard = false,
			suggest_touchOfDeath = false,
			suggest_summonBlackOxStatue = false,
			suggest_aoe = false,
			elusiveBrewThreshold = 4,
			dangerousHealth = 20,
			targetChi = 2,
			targetEnergy = 75,
			
			icon_size = 64,
			icon_size_small = 48,
			icon_size_tiny = 32,				
		},
	}
	self.db = LibStub("AceDB-3.0"):New("MonkECDB", defaults, true)

	self.options = {
		name = "MonkEC",
		handler = MonkEC,
		type = "group",
		args = {
			lock = {
				type = "toggle",
				name = LOCK_FRAMES,
				order = 10,
				desc = LOCK_FRAME_DESCRIPTION,
				get = function() return MonkEC.db.profile.isLocked end,
				set = "SetLocked",
			},
			showOnlyIC = {
				type = "toggle",
				name = SHOWONLYINCOMBAT,
				order = 20,
				desc = v,
				get = function() return MonkEC.db.profile.showOnlyIC end,
				set = function(self, value) MonkEC.db.profile.showOnlyIC = value
							MonkEC:UpdateFrameVisibility() end,
			},
			frame = {
				type = "group",
				name = ABILITYQUEUEFRAME,
				order = 100,
				args = {
					header = {
						type = "header",
						name = ABILITYQUEUEFRAME,
						order = 105,
					},
					enable = {
						type = "toggle",
						name = ENABLEABILITYQUEUE,
						width = "double",
						order = 110,
						get = function() return MonkEC.db.profile.enabled end,
						set = function() 
										MonkEC.db.profile.enabled = not MonkEC.db.profile.enabled
										MonkEC:UpdateFrameVisibility()
									end,
					},
					scale = {
						type = "range",
						name = SCALE,
						order = 120,
						min = 0.5,
						max = 1.5,
						step = 0.1,
						desc = SCALEDESCRIPTION,		
						get = function() return MonkEC.db.profile.frame_scale end,
						set = "SetScale",
					},									
					posx = {
						type = "input",
						name = XCOORDINATE,
						order = 110,
						desc = XCOORDINATEDESCRIPTION,
						get = function() return MonkEC.db.profile.frame_x end,
						set = "SetXCoord",
					},
					posy = {
						type = "input",
						name = YCOORDINATE,
						order = 115,
						desc = YCOORDINATEDESCRIPTION,
						get = function() return MonkEC.db.profile.frame_y end,
						set = "SetYCoord",
					},
					header2 = {
						type = "header",
						name = OPTIONALSUGGESTIONS,
						order = 137,
					},
					suggestTouchOfDeath = {
						type = "toggle",
						name = TOUCHOFDEATH,
						desc = TOUCHOFDEATHCHECKBOXDESCRIPTION,
						order = 140,
						get = function() return MonkEC.db.profile.suggest_touchOfDeath end,
						set = function() MonkEC.db.profile.suggest_touchOfDeath = not MonkEC.db.profile.suggest_touchOfDeath end,
					},
					suggestBlackOx = {
						type = "toggle",
						name = BLACKOXSTATUE,
						desc = SUMMONSTATUECHECKBOXDESCRIPTION,
						order = 150,
						get = function() return MonkEC.db.profile.suggest_summonBlackOxStatue end,
						set = function() MonkEC.db.profile.suggest_summonBlackOxStatue = not MonkEC.db.profile.suggest_summonBlackOxStatue end,
					},
					suggestGuard = {
						type = "toggle",
						name = GUARD,
						desc = GUARDCHECKBOXDESCRIPTION,
						order = 160,
						get = function() return MonkEC.db.profile.suggest_guard end,
						set = function() MonkEC.db.profile.suggest_guard = not MonkEC.db.profile.suggest_guard end,
					},
					suggestAoE = {
						type = "toggle",
						name = "AoE",
						desc = "Suggest AoE skills",
						order = 160,
						get = function() return MonkEC.db.profile.suggest_aoe end,
						set = function() MonkEC.db.profile.suggest_aoe = not MonkEC.db.profile.suggest_aoe end,
					},
					header3 = {
						type = "header",
						name = RESOURCETHRESHOLDS,
						order = 200,
					},
					targetChi = {
						type = "range",
						name = TARGETCHI,
						order = 210,
						min = 0,
						max = MonkEC.maxChi,
						step = 1,
						desc = TARGETCHIDESCRIPTION,		
						get = function() return MonkEC.db.profile.targetChi end,
						set = "SetChiGoal",
					},									
					targetEnergy = {
						type = "range",
						name = ENERGYTARGET,
						order = 220,
						min = 0,
						max = 100,
						step = 5,
						desc = ENERGYTARGETDESCRIPTION,		
						get = function() return MonkEC.db.profile.targetEnergy end,
						set = "SetEnergyGoal",
					},									
					dangerousHealth = {
						type = "range",
						name = HEALTHPANICTHRESHOLD,
						order = 230,
						min = 0,
						max = 50,
						step = 1,
						desc = HEALTHPANICTHRESHOLDDESCRIPTION,		
						get = function() return MonkEC.db.profile.dangerousHealth end,
						set = "SetDangerousHealth", 
					},									
					elusiveBrewThreshold = {
						type = "range",
						name = ELUSIVEBREWTHRESHOLD,
						order = 240,
						min = 0,
						max = 20,
						step = 1,
						desc = ELUSIVEBREWTHRESHOLDDESCRIPTION,		
						get = function() return MonkEC.db.profile.elusiveBrewThreshold end,
						set = "SetElusiveBrewThreshold",
					},									
				},
			},
			buffs = {
				type = "group",
				name = BUFFSDEBUFFSFRAMEHEADER,
				order = 200,
				args = {
					header = {
						type = "header",
						name = BUFFSDEBUFFSFRAMEHEADER,
						order = 205,
					},					 
					toggleBuffs = {
						type = "toggle",
						name = ENABLE,
						order = 212,
						get = function() return MonkEC.db.profile.buff_isShown end,
						set = function(self, key) 
										MonkEC.db.profile.buff_isShown = key
										MonkEC:UpdateFrameVisibility() end,
					},					
					scale = {
						type = "range",
						name = SCALE,
						order = 220,
						min = 0.5,
						max = 1.5,
						step = 0.1,
						desc = BUFFSSCALINGDESCRIPTION,		
						get = function() return MonkEC.db.profile.buff_scale end,
						set = "SetBuffScale",
					},									
					posx = {
						type = "input",
						name = XCOORDINATE,
						order = 230,
						desc = BUFFSXCOORDINATEDESCRIPTION,
						get = function() return MonkEC.db.profile.buff_x end,
						set = "SetBuffXCoord",
					},
					posy = {
						type = "input",
						name = YCOORDINATE,
						order = 240,
						desc = BUFFSYCOORDINATEDESCRIPTION,
						get = function() return MonkEC.db.profile.buff_y end,
						set = "SetBuffYCoord",
					},
				},
			},
			cooldowns = {
				type = "group",
				name = "Cooldowns",
				order = 200,
				args = {
					header = {
						type = "header",
						name = "Cooldowns",
						order = 205,
					},					 
					toggleCooldowns = {
						type = "toggle",
						name = ENABLE,
						order = 212,
						get = function() return MonkEC.db.profile.cooldowns_isShown end,
						set = function(self, key) 
										MonkEC.db.profile.cooldowns_isShown = key
										MonkEC:UpdateFrameVisibility() end,
					},					
					scale = {
						type = "range",
						name = SCALE,
						order = 220,
						min = 0.5,
						max = 1.5,
						step = 0.1,
						desc = "Cooldowns Scaling",		
						get = function() return MonkEC.db.profile.cooldowns_scale end,
						set = "SetCooldownsScale",
					},
					posx = {
						type = "input",
						name = XCOORDINATE,
						order = 230,
						desc = "Cooldowns X Coordinate",
						get = function() return MonkEC.db.profile.cooldowns_x end,
						set = "SetCooldownsXCoord",
					},
					posy = {
						type = "input",
						name = YCOORDINATE,
						order = 240,
						desc = "Cooldowns Y Coordinate",
						get = function() return MonkEC.db.profile.cooldowns_y end,
						set = "SetCooldownsYCoord",
					},
				},
			},
		},
	}
	LibStub("AceConfig-3.0"):RegisterOptionsTable("MonkEC", self.options)

	LibStub("AceConfigDialog-3.0"):SetDefaultSize("MonkEC", 600, 500)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MonkEC", "MonkEC")	
	LibStub('AceConfigRegistry-3.0'):NotifyChange('MonkEC')
end
