local _, trueclass = UnitClass("player")
if trueclass ~= "MONK" then return end

local AceGUI = LibStub("AceGUI-3.0")

-- Frame position data
local abilityIconXOffset = { [1] = 8, [2] = 80, [3] = 136 }
local abilityIconYOffset = 8
local buffIconXOffset = { [1] = 13, [2] = 57, [3] = 101, [4] = 145 }
local buffIconYOffset = 8
--local aoeToggleXOffset = 190
--local aoeToggleYOffset = 0

local timeSinceLastUpdate = 0
local updateFrequency = 0.1

----------------------------------
-- Override the OnUpdate function
----------------------------------
local function OnUpdate(this, elapsed)
	timeSinceLastUpdate = timeSinceLastUpdate + elapsed
	if timeSinceLastUpdate > updateFrequency then	
		MonkEC:UpdateTrackedBuffs()
		MonkEC:UpdateAbilityQueue()
		MonkEC:UpdateCDs()
		MonkEC:ClearOldTargets()
	
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
function MonkEC:InitializeFrames()
	self:InitAbilityFrame()
	self:InitBuffFrame()
end

function MonkEC:InitAbilityFrame()
	local scale = self.db.profile.frame_scale
	local iconSize = self.db.profile.icon_size
	local iconSizeSmall = self.db.profile.icon_size_small
	local baseFrame = CreateFrame("Frame", "MonkECAbilityFrame", UIParent)
	self.frame = baseFrame
	
	baseFrame:SetFrameStrata("BACKGROUND")
	baseFrame:SetWidth(self.db.profile.frame_width * scale)
	baseFrame:SetHeight(self.db.profile.frame_height * scale)
	
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
--	aoeToggle = AceGUI:Create("CheckBox")
--	aoeToggle:SetLabel("AOE")
--	aoeToggle:SetType("checkbox")
--	aoeToggle:SetValue(self.db.profile.suggest_aoe)
--	aoeToggle:SetCallback("OnValueChanged", function(widget, callback) MonkEC.db.profile.suggest_aoe = widget:GetValue() end)
--	aoeToggle.frame:ClearAllPoints()
--	aoeToggle.frame:SetPoint("BOTTOMLEFT", baseFrame, "BOTTOMLEFT", 
--			aoeToggleXOffset * scale, aoeToggleYOffset * scale)
--	aoeToggle.frame:Show()

--	baseFrame.aoeToggle = aoeToggle

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
--		baseFrame.aoeToggle.frame:ClearAllPoints()
--		baseFrame.aoeToggle.frame:SetPoint("BOTTOMLEFT", baseFrame, "BOTTOMLEFT", 
--				aoeToggleXOffset * scale, aoeToggleYOffset * scale)
	end)	

	if (self.db.profile.isLocked == true) then
		baseFrame:EnableMouse(false)
	else
		baseFrame:EnableMouse(true)
	end

	MonkEC.frame:SetScript("OnUpdate", OnUpdate)
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
	
	if MonkEC.talentSpec == nil then
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
--			self.frame.aoeToggle.frame:Show()
		end
	else
		if self.frame:IsShown() then
			self.frame:Hide()
--			self.frame.aoeToggle.frame:Hide()
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
	return MonkEC.talentSpec == MonkEC.talentSpecBrewmaster or  MonkEC.talentSpec == MonkEC.talentSpecWindwalker 
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
	
--	frame.aoeToggle.frame:ClearAllPoints()
--	frame.aoeToggle.frame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 
--				aoeToggleXOffset * scale, aoeToggleYOffset * scale)
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

function MonkEC:UpdateAbilityQueue()
	-- Find the current GCD
	local currentStart,currentBaseGCD = GetSpellCooldown(self.common.jab.id)
	local currentGCD = 0
	if (currentStart > 0) then
		currentGCD = currentBaseGCD - (GetTime() - currentStart)
	end
	
	self:UpdateCooldowns(currentGCD, MonkEC.common)
	self:UpdateCooldowns(currentGCD, MonkEC.talent)
	self:UpdateCooldowns(currentGCD, MonkEC.brewmaster)
	self:UpdateCooldowns(currentGCD, MonkEC.windwalker)
	
	local characterState = self:GatherCharacterState()

	for i = 1,3 do
		local spell = self:FindNextSpell(currentGCD, characterState)
		self.frame.abilityFrame[i].spell = spell
		currentGCD = currentGCD + MonkEC.theGCD
	end
end