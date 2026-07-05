--------------------------------------------------------------------------------
-- PeaversRemembersYou List Window
-- Scrollable, searchable, sortable list of every player in the database.
-- Toggled with /pry (or /pry list). Styled to match PeaversConsumables.
--------------------------------------------------------------------------------

local addonName, PRY = ...

local PeaversCommons = _G.PeaversCommons
local FrameUtils = PeaversCommons.FrameUtils

PRY.ListUI = {}
local ListUI = PRY.ListUI

local FRAME_WIDTH = 440
local FRAME_HEIGHT = 560
local ROW_HEIGHT = 24

local searchText = ""
local sortKey = "lastSeen" -- "name" | "lastSeen" | "groupType"
local sortAsc = false

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function FormatRelativeTime(timestamp)
    local diff = time() - timestamp
    if diff < 60 then
        return "just now"
    elseif diff < 3600 then
        local m = math.floor(diff / 60)
        return string.format("%d %s ago", m, m == 1 and "minute" or "minutes")
    elseif diff < 86400 then
        local h = math.floor(diff / 3600)
        return string.format("%d %s ago", h, h == 1 and "hour" or "hours")
    else
        local d = math.floor(diff / 86400)
        return string.format("%d %s ago", d, d == 1 and "day" or "days")
    end
end

local GROUP_TYPE_COLORS = {
    dungeon = "|cff00ccff",
    raid = "|cffff8800",
    group = "|cffaaaaaa",
}

local function ColoredName(name, classFile)
    local color = classFile and RAID_CLASS_COLORS[classFile]
    if color then
        return string.format("|c%s%s|r", color.colorStr, name)
    end
    return name
end

--- Collect, filter and sort database entries into a flat array.
local function BuildEntries()
    local entries = {}
    local needle = searchText:lower()

    for name, data in pairs(PRY.Config:GetAllPlayerData()) do
        if needle == "" or name:lower():find(needle, 1, true) then
            entries[#entries + 1] = {
                name = name,
                firstSeen = data.firstSeen or 0,
                lastSeen = data.lastSeen or 0,
                groupType = data.groupType or "group",
                count = data.count or 1,
                class = data.class,
            }
        end
    end

    table.sort(entries, function(a, b)
        local av, bv
        if sortKey == "name" then
            av, bv = a.name:lower(), b.name:lower()
        elseif sortKey == "groupType" then
            av, bv = a.groupType, b.groupType
        else
            av, bv = a.lastSeen, b.lastSeen
        end
        if av == bv then
            return a.name:lower() < b.name:lower()
        end
        if sortAsc then
            return av < bv
        end
        return av > bv
    end)

    return entries
end

--------------------------------------------------------------------------------
-- Frame construction (PeaversConsumables-style: DefaultPanelTemplate +
-- modern MinimalScrollBar via ScrollFrameTemplate)
--------------------------------------------------------------------------------

local function CreateHeaderButton(parent, text, key, width, offsetX)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, 18)
    btn:SetPoint("TOPLEFT", offsetX, -60)

    btn.text = btn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    btn.text:SetPoint("LEFT", 2, 0)
    btn.text:SetText(text)

    btn.arrow = btn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    btn.arrow:SetPoint("LEFT", btn.text, "RIGHT", 3, 0)

    btn:SetScript("OnClick", function()
        if sortKey == key then
            sortAsc = not sortAsc
        else
            sortKey = key
            sortAsc = (key == "name")
        end
        ListUI:Refresh()
    end)

    btn:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 1, 1) end)
    btn:SetScript("OnLeave", function(self) self.text:SetTextColor(1, 0.82, 0) end)

    btn.sortKey = key
    return btn
end

local function CreateRow(content)
    local row = CreateFrame("Button", nil, content)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("RIGHT", content, "RIGHT", -4, 0)

    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.1)

    row.name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    row.name:SetPoint("LEFT", 2, 0)
    row.name:SetWidth(150)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    row.lastSeen = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.lastSeen:SetPoint("LEFT", 158, 0)
    row.lastSeen:SetWidth(120)
    row.lastSeen:SetJustifyH("LEFT")
    row.lastSeen:SetTextColor(0.7, 0.7, 0.7)

    row.groupType = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.groupType:SetPoint("LEFT", 284, 0)
    row.groupType:SetWidth(64)
    row.groupType:SetJustifyH("LEFT")

    row.delete = CreateFrame("Button", nil, row)
    row.delete:SetSize(16, 16)
    row.delete:SetPoint("RIGHT", -4, 0)
    row.delete:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    row.delete:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
    row.delete:SetScript("OnClick", function()
        if row.playerName then
            PRY.Config:SetPlayerData(row.playerName, nil)
            ListUI:Refresh()
        end
    end)
    row.delete:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Forget this player")
        GameTooltip:Show()
    end)
    row.delete:SetScript("OnLeave", function() GameTooltip:Hide() end)

    row:SetScript("OnEnter", function(self)
        if not self.entryData then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.playerName)
        GameTooltip:AddDoubleLine("First met", date("%Y-%m-%d %H:%M", self.entryData.firstSeen), 0.8, 0.8, 0.8, 1, 1, 1)
        GameTooltip:AddDoubleLine("Last grouped", date("%Y-%m-%d %H:%M", self.entryData.lastSeen), 0.8, 0.8, 0.8, 1, 1, 1)
        GameTooltip:AddDoubleLine("Times grouped", self.entryData.count, 0.8, 0.8, 0.8, 1, 1, 1)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return row
end

local function CreateWindow()
    local frame = CreateFrame("Frame", "PRYListFrame", UIParent, "DefaultPanelTemplate")
    frame:Hide()
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)

    frame.TitleBg = FrameUtils.CreateTitleBackground(frame)
    frame.CloseButton = FrameUtils.CreateCloseButton(frame)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", frame, "TOP", 0, -5)
    title:SetText("Peavers Remembers You")
    frame.TitleText = title

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    tinsert(UISpecialFrames, frame:GetName())

    -- Search box
    local search = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    search:SetSize(FRAME_WIDTH - 36, 22)
    search:SetPoint("TOPLEFT", 20, -32)
    search:SetAutoFocus(false)
    search:HookScript("OnTextChanged", function(self)
        searchText = self:GetText() or ""
        ListUI:Refresh()
    end)
    frame.search = search

    -- Column headers (fixed above the scroll area)
    frame.headers = {
        CreateHeaderButton(frame, "Name", "name", 150, 16),
        CreateHeaderButton(frame, "Last grouped", "lastSeen", 120, 172),
        CreateHeaderButton(frame, "Type", "groupType", 64, 298),
    }

    -- ScrollFrameTemplate provides the modern MinimalScrollBar (same style as the AH)
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "ScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -80)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 34)
    frame.scrollFrame = scrollFrame

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(FRAME_WIDTH - 42)
    scrollFrame:SetScrollChild(content)
    frame.content = content
    frame.rows = {}

    -- Footer: entry count + clear all
    frame.countText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.countText:SetPoint("BOTTOMLEFT", 14, 12)

    local clear = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clear:SetSize(80, 20)
    clear:SetPoint("BOTTOMRIGHT", -12, 8)
    clear:SetText("Clear all")
    clear:SetScript("OnClick", function()
        StaticPopup_Show("PRY_CONFIRM_RESET")
    end)

    return frame
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function ListUI:GetFrame()
    if not self.frame then
        self.frame = CreateWindow()
    end
    return self.frame
end

function ListUI:Refresh()
    local frame = self.frame
    if not frame or not frame:IsShown() then return end

    local entries = BuildEntries()
    local content = frame.content

    -- Reuse pooled rows; the pool only ever grows to the largest list seen
    for i, entry in ipairs(entries) do
        local row = frame.rows[i]
        if not row then
            row = CreateRow(content)
            frame.rows[i] = row
        end
        row:SetPoint("TOPLEFT", 4, -(i - 1) * ROW_HEIGHT)
        row.playerName = entry.name
        row.entryData = entry
        row.name:SetText(ColoredName(entry.name, entry.class))
        row.lastSeen:SetText(FormatRelativeTime(entry.lastSeen))
        local color = GROUP_TYPE_COLORS[entry.groupType] or GROUP_TYPE_COLORS.group
        row.groupType:SetText(color .. entry.groupType .. "|r")
        row:Show()
    end
    for i = #entries + 1, #frame.rows do
        frame.rows[i]:Hide()
        frame.rows[i].playerName = nil
        frame.rows[i].entryData = nil
    end

    content:SetHeight(math.max(#entries * ROW_HEIGHT + 8, 1))

    -- Sort indicators
    for _, header in ipairs(frame.headers) do
        if header.sortKey == sortKey then
            header.arrow:SetText(sortAsc and "^" or "v")
        else
            header.arrow:SetText("")
        end
    end

    local total = 0
    for _ in pairs(PRY.Config:GetAllPlayerData()) do total = total + 1 end
    if #entries == total then
        frame.countText:SetFormattedText("%d players remembered", total)
    else
        frame.countText:SetFormattedText("%d of %d players", #entries, total)
    end
end

function ListUI:Toggle()
    local frame = self:GetFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        self:Refresh()
    end
end

return ListUI
