local XUiFightCerberus = XLuaUiManager.Register(XLuaUi, "UiFightCerberus")
local XUiFightCerberusGrid = require("XUi/XUiFightCerberus/XUiFightCerberusGrid")
local Sprite = CS.UnityEngine.Sprite
local XResourceManager = CS.XResourceManager
local XFightIntStringMapManager = CS.XFightIntStringMapManager
local Rect = CS.UnityEngine.Rect
local Vector2 = CS.UnityEngine.Vector2
local Destroy = CS.UnityEngine.Object.Destroy
local XCustomUi = CS.XCustomUi
local XEventId = CS.XEventId
local tableInsert = table.insert
local ipairs = ipairs
local math = math
local MAX_COUNT = 99

function XUiFightCerberus:OnAwake()
    self.Count = 0
    self.Value = 0
    self.MaxValue = 100
    self.CustomUiChangeEvent = handler(self, self.ApplyCustomUi)

    self:InitGrids()
    self:ApplyCustomUi()

    CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_CUSTOM_UI_SCHEME_CHANGED, self.CustomUiChangeEvent)
end

function XUiFightCerberus:ApplyCustomUi()
    XCustomUi.Instance:ApplyCustomUi(self.Panel, XCustomUi.Interaction1)
end

function XUiFightCerberus:InitGrids()
    self.Grids = { }
    tableInsert(self.Grids, XUiFightCerberusGrid.New(self, self.ImgScoringOne, 0))
    tableInsert(self.Grids, XUiFightCerberusGrid.New(self, self.ImgScoringTen, 1))
end

function XUiFightCerberus:GetSpriteUrl(key)
    local _, url = XFightIntStringMapManager.TryGetString(1000 + key)
    return url
end

function XUiFightCerberus:OnDestroy()
    CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_CUSTOM_UI_SCHEME_CHANGED, self.CustomUiChangeEvent)
    
    for _, grid in ipairs(self.Grids) do
        grid:OnDestroy()
    end
end

function XUiFightCerberus:SetBarValue(value)
    self.Value = value
    self.ImgBar:SetValue(value)
    self:RefreshFullBarEffect()
end

function XUiFightCerberus:SetBarMaxValue(maxValue)
    self.MaxValue = maxValue
    self.ImgBar:SetMaxValue(maxValue)
    self.ImgBar:SetValue(self.Value, true)
    self:RefreshFullBarEffect()
end

function XUiFightCerberus:RefreshFullBarEffect()
    self.FullBarEffect.gameObject:SetActiveEx(self.Value >= self.MaxValue)
end

function XUiFightCerberus:SetCount(count)
    if count < 0 then
        count = 0
    elseif count > MAX_COUNT then
        count = MAX_COUNT
    end

    if self.Count == count then
        return
    end

    for _, grid in ipairs(self.Grids) do
        grid:SetCount(math.floor(count / grid.BaseCount))
    end

    self.Count = count
    self.MaxCountEffect.gameObject:SetActiveEx(count >= MAX_COUNT)
end