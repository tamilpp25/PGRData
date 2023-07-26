
local XPokerGuessing = XClass(XDataEntityBase, "XPokerGuessing")

local Default = {
    _ActivityId = 0,
    _SelectRoleId = 0,
    _TipsCount = 0,
    _TipsProgress = 0,
    _DescKey = "",
    _UnLockCharacters = {}
}

local SelectRoleKey = "SelectRoleKey"
local IsFirstOpenKey = "IsFirstOpenKey"
local IsSelectFilterKey = "IsSelectFilter"

function XPokerGuessing:Ctor(activityId)
    self:Init(Default, activityId)
end

function XPokerGuessing:InitData(activityId)
    self:SetProperty("_ActivityId", activityId)

    local key = self:__GetCookiesKey(SelectRoleKey)
    local roleId = XSaveTool.GetData(key)
    roleId = XTool.IsNumberValid(roleId) and roleId or XPokerGuessingConfig.GetDefaultSelectRoleId()
    self:SetProperty("_SelectRoleId", roleId)
end

function XPokerGuessing:RefreshSelectRoleId(roleId)
    local key = self:__GetCookiesKey(SelectRoleKey)
    XSaveTool.SaveData(key, roleId)
    self:SetProperty("_SelectRoleId", roleId)
end

function XPokerGuessing:IsFirstOpen()
    local key = self:__GetCookiesKey(IsFirstOpenKey)
    return not XSaveTool.GetData(key) and true or false 
end

function XPokerGuessing:MarkFirstOpen()
    local key = self:__GetCookiesKey(IsFirstOpenKey)
    XSaveTool.SaveData(key, true)
end

function XPokerGuessing:IsSelectFilter()
    local key = self:__GetCookiesKey(IsSelectFilterKey)
    return XSaveTool.GetData(key)
end

function XPokerGuessing:MarkSelectFilter(isSelect)
    local key = self:__GetCookiesKey(IsSelectFilterKey)
    XSaveTool.SaveData(key, isSelect)
end

function XPokerGuessing:GetTipsDesc()
    return XPokerGuessingConfig.PokerRoleConfig:GetProperty(self._SelectRoleId, self._DescKey)
end

function XPokerGuessing:__GetCookiesKey(key)
    return XDataCenter.PokerGuessingManager.GetCookiesKey(key)
end

return XPokerGuessing