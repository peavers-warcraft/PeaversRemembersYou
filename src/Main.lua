local addonName, PRY = ...

-- Access the PeaversCommons library
local PeaversCommons = _G.PeaversCommons
local Utils = PeaversCommons.Utils

-- Initialize addon namespace and modules
PRY = PRY or {}

-- Module namespaces
PRY.Utils = {}

-- Version information
PRY.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"
PRY.addonName = addonName
PRY.name = addonName

-- Register slash commands
PeaversCommons.SlashCommands:Register(addonName, "pry", {
	default = function()
		Settings.OpenToCategory("PeaversRemembersYou")
	end,
	reset = function()
		StaticPopup_Show("PRY_CONFIRM_RESET")
	end,
	help = function()
		Utils.Print(PRY, "Commands:")
		print("  /pry - Open settings")
		print("  /pry reset - Reset player database")
	end
})

-- Initialize addon using the PeaversCommons Events module
PeaversCommons.Events:Init(addonName, function()
	-- Configuration initialization is handled by ConfigManager
	-- However we need to call Initialize to ensure player data is set up
	PRY.Config:Initialize()

	-- Initialize core functionality
	PRY:Initialize()

	-- Initialize configuration UI
	if PRY.ConfigUI and PRY.ConfigUI.Initialize then
		PRY.ConfigUI:Initialize()
	end
	
	-- Initialize patrons support
	if PRY.Patrons and PRY.Patrons.Initialize then
		PRY.Patrons:Initialize()
	end

	C_Timer.After(0.5, function()
		PeaversCommons.SettingsUI:CreateRedirectPage(PRY, "PeaversRemembersYou", "Peavers Remembers You")
	end)

	-- Register with PeaversConfig registry
	if PeaversCommons.ConfigRegistry then
		PeaversCommons.ConfigRegistry:Register({
			name = "PeaversRemembersYou",
			displayName = "Remembers You",
			description = "Records and notifies about returning group members",
			addonRef = PRY,
			config = PRY.Config,
			pages = PRY.ConfigUI:GetPages(),
			order = 7,
		})
	end
end, {
	suppressAnnouncement = true
})
