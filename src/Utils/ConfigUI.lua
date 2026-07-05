local _, PRY = ...

local ConfigUI = {}
PRY.ConfigUI = ConfigUI

local PeaversCommons = _G.PeaversCommons
local W = PeaversCommons.Widgets

local pageOpts = {
    indent = 25,
    width = 360,
}

local function GetPageOpts(parentFrame)
    local opts = {}
    for k, v in pairs(pageOpts) do opts[k] = v end
    local frameWidth = parentFrame:GetWidth()
    if frameWidth and frameWidth > 100 then
        opts.width = frameWidth - (opts.indent * 2) - 10
    end
    return opts
end

function ConfigUI:BuildGeneralPage(parentFrame)
    local y = -10
    local opts = GetPageOpts(parentFrame)
    local indent = opts.indent
    local width = opts.width

    local _, newY = W:CreateSectionHeader(parentFrame, "General Options", indent, y)
    y = newY - 8

    local toggle1 = W:CreateToggle(parentFrame, "Enable Addon", {
        checked = PRY.Config.enabled,
        width = width,
        onChange = function(checked)
            PRY.Config.enabled = checked
            PRY.Config:Save()
        end,
    })
    toggle1:SetPoint("TOPLEFT", indent, y)
    y = y - 30

    local toggle2 = W:CreateToggle(parentFrame, "Exclude Guild Members", {
        checked = PRY.Config.excludeGuild,
        width = width,
        onChange = function(checked)
            PRY.Config.excludeGuild = checked
            PRY.Config:Save()
        end,
    })
    toggle2:SetPoint("TOPLEFT", indent, y)
    y = y - 40

    _, newY = W:CreateSectionHeader(parentFrame, "Notification Settings", indent, y)
    y = newY - 8

    local ttlSlider = W:CreateSlider(parentFrame, "Days to Remember Players", {
        min = 1, max = 365, step = 1,
        value = PRY.Config.ttl,
        width = width,
        onChange = function(value)
            PRY.Config.ttl = value
            PRY.Config:Save()
        end,
    })
    ttlSlider:SetPoint("TOPLEFT", indent, y)
    y = y - 52

    local chatFrameSlider = W:CreateSlider(parentFrame, "Notification Chat Frame", {
        min = 1, max = 10, step = 1,
        value = PRY.Config.chatFrame,
        width = width,
        onChange = function(value)
            PRY.Config.chatFrame = value
            PRY.Config:Save()
        end,
    })
    chatFrameSlider:SetPoint("TOPLEFT", indent, y)
    y = y - 52

    local thresholdSlider = W:CreateSlider(parentFrame, "Notification Threshold (minutes - 0 for always)", {
        min = 0, max = 60, step = 1,
        value = PRY.Config.notificationThreshold / 60,
        width = width,
        onChange = function(value)
            PRY.Config.notificationThreshold = value * 60
            PRY.Config:Save()
        end,
    })
    thresholdSlider:SetPoint("TOPLEFT", indent, y)
    y = y - 60

    _, newY = W:CreateSectionHeader(parentFrame, "Database Management", indent, y)
    y = newY - 8

    local listBtn = W:CreateButton(parentFrame, "Open Player List", {
        width = 150,
        onClick = function()
            PRY.ListUI:Toggle()
        end,
    })
    listBtn:SetPoint("TOPLEFT", indent, y)
    y = y - 32

    local resetBtn = W:CreateButton(parentFrame, "Reset Database", {
        style = "danger",
        width = 150,
        onClick = function()
            StaticPopup_Show("PRY_CONFIRM_RESET")
        end,
    })
    resetBtn:SetPoint("TOPLEFT", indent, y)
    y = y - 40

    parentFrame:SetHeight(math.abs(y) + 30)
end

function ConfigUI:GetPages()
    return {
        { key = "general", label = "General", builder = function(f) ConfigUI:BuildGeneralPage(f) end },
    }
end

function ConfigUI:BuildIntoFrame(parentFrame)
    self:BuildGeneralPage(parentFrame)
    return parentFrame
end

function ConfigUI:Open()
    if _G.PeaversConfig and _G.PeaversConfig.MainFrame then
        _G.PeaversConfig.MainFrame:Show()
        _G.PeaversConfig.MainFrame:SelectAddon("PeaversRemembersYou")
        return
    end

    if Settings and Settings.OpenToCategory then
        if PRY.directSettingsCategoryID then
            pcall(Settings.OpenToCategory, PRY.directSettingsCategoryID)
        end
    end
end

function ConfigUI:Initialize()
end

return ConfigUI
