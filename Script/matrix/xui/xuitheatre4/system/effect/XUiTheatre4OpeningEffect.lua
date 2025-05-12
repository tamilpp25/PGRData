local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTheatre4OpeningEffectGrid = require("XUi/XUiTheatre4/System/Effect/XUiTheatre4OpeningEffectGrid")

---@class XUiTheatre4OpeningEffect : XLuaUi
---@field _Control XTheatre4Control
local XUiTheatre4OpeningEffect = XLuaUiManager.Register(XLuaUi, "UiTheatre4OpeningEffect")

function XUiTheatre4OpeningEffect:OnAwake()
    self:BindExitBtns()

    ---@type XDynamicTableNormal
    self.DynamicTableNormal = XDynamicTableNormal.New(self.ListEffect)
    self.DynamicTableNormal:SetProxy(XUiTheatre4OpeningEffectGrid, self)
    self.DynamicTableNormal:SetDelegate(self)
    self.GridEffect.gameObject:SetActiveEx(false)
end

function XUiTheatre4OpeningEffect:OnEnable()
    self:Update()
end

function XUiTheatre4OpeningEffect:Update()
    self._Control.SetControl:UpdateAffix()
    local data = self._Control.SetControl:GetUiData().Affix
    local affixList = data.AffixList
    self.DynamicTableNormal:SetDataSource(affixList)
    self.DynamicTableNormal:ReloadDataSync()
end

function XUiTheatre4OpeningEffect:RefreshAffixList()
    self._Control.SetControl:UpdateAffix()
    local data = self._Control.SetControl:GetUiData().Affix
    self.DynamicTableNormal:SetDataSource(data.AffixList)
    for index, grid in pairs(self.DynamicTableNormal:GetGrids()) do
        grid:Update(self.DynamicTableNormal:GetData(index))
    end
end

---@param grid XUiTheatre4OpeningEffectGrid
function XUiTheatre4OpeningEffect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DynamicTableNormal:GetData(index)
        grid:Update(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClick()
        self:RefreshAffixList()
    end
end

return XUiTheatre4OpeningEffect
