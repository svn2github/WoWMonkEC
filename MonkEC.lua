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
	
	MonkEC:RegisterChatCommand("monkec", "ChatCommand")
	MonkEC:Print("MonkEC loaded. Please type /monkec config for the configuration GUI")
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
end

function MonkEC:PLAYER_REGEN_DISABLED()
	self:UpdateFrameVisibility()
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
