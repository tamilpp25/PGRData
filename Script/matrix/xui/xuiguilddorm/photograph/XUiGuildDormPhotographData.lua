local CSVector2 = CS.UnityEngine.Vector2
local CSTxtMgrGetText = CS.XTextManager.GetText

local Alignment = {
    Disable = {
        Value = 0,
        Name = CSTxtMgrGetText("PhotoAlignmentDisable"),
        Anchor = CSVector2(0, 0),
    },
    LT = {
        Value = 1,
        Name = CSTxtMgrGetText("PhotoAlignmentLT"),
        Anchor = CSVector2(0, 1),
        Node = "GroupUpLeft",
    },
    RT = {
        Value = 2,
        Name = CSTxtMgrGetText("PhotoAlignmentRT"),
        Anchor = CSVector2(1, 1),
        Node = "GroupUpRight",
    },
    LB = {
        Value = 3,
        Name = CSTxtMgrGetText("PhotoAlignmentLB"),
        Anchor = CSVector2(0, 0),
        Node = "GroupDownLeft",
    },
    RB = {
        Value = 4,
        Name = CSTxtMgrGetText("PhotoAlignmentRB"),
        Anchor = CSVector2(1, 0),
        Node = "GroupDownRight",
    }
}

local Default = {
    _LogoAlignment = Alignment.LT, -- logo
    _PlayerAlignment = Alignment.LT, -- 指挥官
    _GuildAlignment = Alignment.LT, -- 指挥局
    _OpenGuildId = 1, -- 工会id
    _OpenLevel = 1, -- 指挥管等级
    _OpenUId = 1 -- 指挥官uid
}

---@class XUiGuildDormPhotographData
local XUiGuildDormPhotographData = XClass(nil, "XUiGuildDormPhotographData")

function XUiGuildDormPhotographData:Ctor()
    for key, value in pairs(Default) do
        self[key] = value
    end
    self.PhotographSetKey = string.format("GuildDormPhotographSetKey_%s_Setting", XPlayer.Id)
    local cacheData = XSaveTool.GetData(self.PhotographSetKey)
    if cacheData then
        self:Update(cacheData.LogoValue, cacheData.GuildValue, cacheData.PlayerValue, cacheData.OpenGuildId, cacheData.OpenLevel, cacheData.OpenUId)
    end
end

function XUiGuildDormPhotographData:Update(logoValue, guildValue, playerValue, openGuildId, openLevel, openUid)
    self._OpenGuildId = openGuildId
    self._OpenLevel = openLevel
    self._OpenUId = openUid
    
    local oldLogoValue = self._LogoAlignment.Value
    local oldGuildValue = self._GuildAlignment.Value
    local oldPlayerValue = self._PlayerAlignment.Value
    for key, data in pairs(Alignment or {}) do
        if data.Value == logoValue and logoValue ~= oldLogoValue then
            self._LogoAlignment = Alignment[key]
        end
        if data.Value == guildValue and guildValue ~= oldGuildValue then
            self._GuildAlignment = Alignment[key]
        end
        if data.Value == playerValue and playerValue ~= oldPlayerValue then
            self._PlayerAlignment = Alignment[key]
        end
    end
end

function XUiGuildDormPhotographData:GetSampleData()
    return {
        LogoValue = self._LogoAlignment.Value,
        PlayerValue = self._PlayerAlignment.Value,
        GuildValue = self._GuildAlignment.Value,
        OpenGuildId = self._OpenGuildId,
        OpenLevel = self._OpenLevel,
        OpenUId = self._OpenUId,
    }
end

function XUiGuildDormPhotographData:GetAlignment()
    local list = {}
    for _, data in pairs(Alignment or {}) do
        table.insert(list, data)
    end
    table.sort(list, function(a, b)
        return a.Value < b.Value
    end)
    return list
end

function XUiGuildDormPhotographData:SaveSetData()
    XSaveTool.SaveData(self.PhotographSetKey, self:GetSampleData())
end

function XUiGuildDormPhotographData:GetLogoAlignment()
    return self._LogoAlignment
end

function XUiGuildDormPhotographData:GetGuildAlignment()
    return self._GuildAlignment
end

function XUiGuildDormPhotographData:GetPlayerAlignment()
    return self._PlayerAlignment
end

function XUiGuildDormPhotographData:GetOpenGuildId()
    return self._OpenGuildId == 1
end

function XUiGuildDormPhotographData:GetOpenLevel()
    return self._OpenLevel == 1
end

function XUiGuildDormPhotographData:GetOpenUId()
    return self._OpenUId == 1
end

return XUiGuildDormPhotographData