--------------------------------------------------------------------------------
-- PeaversRemembersYou Configuration
-- Uses PeaversCommons.ConfigManager with AceDB-3.0 for profile management
--------------------------------------------------------------------------------

local addonName, PRY = ...

local PeaversCommons = _G.PeaversCommons
local ConfigManager = PeaversCommons.ConfigManager

local PRY_DEFAULTS = {
    enabled = true,
    ttl = 30,
    excludeGuild = true,
    chatFrame = 1,
    notificationThreshold = 300,
    DEBUG_ENABLED = false,
}

-- Create the AceDB-backed config
PRY.Config = ConfigManager:NewWithAceDB(
    PRY,
    PRY_DEFAULTS,
    {
        savedVariablesName = "PeaversRemembersYouDB",
        profileType = "shared",
    }
)

local Config = PRY.Config

-- Player data is stored separately from profile settings (global data)
local function InitializePlayers()
    PeaversRemembersYouDB = PeaversRemembersYouDB or {}
    if not PeaversRemembersYouDB.players then
        PeaversRemembersYouDB.players = {}
    end
end

function Config:GetPlayerData(name)
    InitializePlayers()
    return PeaversRemembersYouDB.players[name]
end

function Config:SetPlayerData(name, data)
    InitializePlayers()
    PeaversRemembersYouDB.players[name] = data
end

function Config:ResetPlayerData()
    InitializePlayers()
    PeaversRemembersYouDB.players = {}
end

function Config:GetAllPlayerData()
    InitializePlayers()
    return PeaversRemembersYouDB.players
end

return PRY.Config
