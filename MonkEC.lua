local _, trueclass = UnitClass("player")
if trueclass ~= "MONK" then return end

MonkEC = LibStub("AceAddon-3.0"):NewAddon("MonkEC", "AceConsole-3.0", "AceEvent-3.0");

local media = LibStub("LibSharedMedia-3.0")
local textures = media:List("statusbar")
local fonts = media:List("font")

---------------------------------------------
-- On Initialized, Enable and Disable Methods
---------------------------------------------
function MonkEC:OnInitialize()
	MonkEC:InitializeOptions()
	
	MonkEC:SetChiGeneration()
	MonkEC:SetMinimumLevel()
	MonkEC:SetSpellCooldowns()
	MonkEC:CreatePriorityLists();
		
	MonkEC:InitializeFrames()

	MonkEC:RegisterEvent("PLAYER_TALENT_UPDATE")	
	MonkEC:RegisterEvent("PLAYER_REGEN_ENABLED")
	MonkEC:RegisterEvent("PLAYER_REGEN_DISABLED")
	MonkEC:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	
	MonkEC:RegisterChatCommand("monkec", "ChatCommand")
	MonkEC:Print(STARTUPMESSAGE)
end
 
function MonkEC:OnEnable()
	MonkEC:InspectSpecialization()
end

function MonkEC:OnDisable()
end

function MonkEC:PLAYER_TALENT_UPDATE()
	MonkEC:InspectSpecialization()
end

function MonkEC:PLAYER_REGEN_ENABLED()
	self:UpdateFrameVisibility()
	MonkEC:ClearTrackedTargets()
end

function MonkEC:PLAYER_REGEN_DISABLED()
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
