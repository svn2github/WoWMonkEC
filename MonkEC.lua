local _, trueclass = UnitClass("player")
if trueclass ~= "MONK" then return end

MonkEC = LibStub("AceAddon-3.0"):NewAddon("MonkEC", "AceConsole-3.0", "AceEvent-3.0");

local media = LibStub("LibSharedMedia-3.0")
local textures = media:List("statusbar")
local fonts = media:List("font")

function OnUpdate()
	MonkEC:Update()
	
	C_Timer.After(0.1, OnUpdate)
end

---------------------------------------------
-- On Initialized, Enable and Disable Methods
---------------------------------------------
function MonkEC:OnInitialize()
	MonkEC:InitializeOptions()
	
	MonkEC:SetMinimumLevel()
	MonkEC:SetSpellCooldowns()
	--temp
	MonkEC:SetSpellCosts()
	MonkEC:CreatePriorityLists();
		
	MonkEC:InitializeFrames()

	MonkEC:RegisterEvent("PLAYER_REGEN_ENABLED")
	MonkEC:RegisterEvent("PLAYER_REGEN_DISABLED")
	MonkEC:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	
	MonkEC:RegisterChatCommand("monkec", "ChatCommand")
	MonkEC:Print(STARTUPMESSAGE)
	
	C_Timer.After(0.1, OnUpdate)
end

function MonkEC:OnEnable()
	MonkEC:InspectSpecialization()
end

function MonkEC:OnDisable()
end

function MonkEC:PLAYER_REGEN_ENABLED()
	self:ExitedCombat()
	self:UpdateFrameVisibility()
	MonkEC:ClearTrackedTargets()
end

function MonkEC:PLAYER_REGEN_DISABLED()
	self:EnteredCombat()
	self:UpdateFrameVisibility()
end

function MonkEC:COMBAT_LOG_EVENT_UNFILTERED(_, timestamp, eventtype, _, srcGUID, _, _, _, destGUID, _, _, _, spellId)
	if srcGUID == UnitGUID("player") then
		if eventtype == "SPELL_DAMAGE" or eventtype == "SPELL_MISSED" or eventtype == "SPELL_PERIODIC_DAMAGE" then
			MonkEC:TrackTarget(destGUID)
		end
	end
end

-------------------------------
-- Interpret the Chat Commnads
-------------------------------
function MonkEC:ChatCommand(input)
	LibStub("AceConfigDialog-3.0"):Open("MonkEC", self.optionFrame)
end
