local _, trueclass = UnitClass("player")
if trueclass ~= "MONK" then return end
 
MonkEC.trackableBuffs = {	"Weakened Blows", "Shuffle", "Elusive Brew", "Tiger Power", 
							"Sanctuary of the Ox", "Mortal Wounds", "--------------" }

function MonkEC:InitializeOptions()
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

			suggest_guard = false,
			suggest_touchOfDeath = false,
			suggest_summonBlackOxStatue = false,
			suggest_aoe = false,
			elusiveBrewThreshold = 4,
			dangerousHealth = 20,
			targetChi = 2,
			targetEnergy = 75,
			
			tracked_buffs_1 = 1,
			tracked_buffs_2 = 2,
			tracked_buffs_3 = 3,
			tracked_buffs_4 = 4,
					
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
					enable = {
						type = "toggle",
						name = "Enable ability queue",
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
						max = MonkEC.maxChi,
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
					dangerousHealth = {
						type = "range",
						name = "Health Panic Threshold",
						order = 230,
						min = 0,
						max = 50,
						step = 1,
						desc = "Sets the health percentage where MonkEC will suggest survival abilities",		
						get = function() return MonkEC.db.profile.dangerousHealth end,
						set = "SetDangerousHealth", 
					},									
					elusiveBrewThreshold = {
						type = "range",
						name = "Elusive Brew Threshold",
						order = 240,
						min = 0,
						max = 20,
						step = 1,
						desc = "Sets the number of Elusive Brew stacks at which MonkEC will be suggest casting",		
						get = function() return MonkEC.db.profile.elusiveBrewThreshold end,
						set = "SetElusiveBrewThreshold",
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
						get = function() return MonkEC.db.profile.buff_isShown end,
						set = function(self, key) 
										MonkEC.db.profile.buff_isShown = key
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
					buffGroup = {
						type = "group",
						name = "Buffs/Debuffs",
						args = {
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
	LibStub("AceConfig-3.0"):RegisterOptionsTable("MonkEC", self.options)

	LibStub("AceConfigDialog-3.0"):SetDefaultSize("MonkEC", 600, 500)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MonkEC", "MonkEC")	
	LibStub('AceConfigRegistry-3.0'):NotifyChange('MonkEC')
end
