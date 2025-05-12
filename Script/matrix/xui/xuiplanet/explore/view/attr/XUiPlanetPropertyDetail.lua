local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPlanetPropertyDetailGrid = require("XUi/XUiPlanet/Explore/View/Attr/XUiPlanetPropertyDetailGrid")

---@class XUiPlanetPropertyDetail:XLuaUi
local XUiPlanetPropertyDetail = XLuaUiManager.Register(XLuaUi, "UiPlanetPropertyDetail")

function XUiPlanetPropertyDetail:Ctor()
end

function XUiPlanetPropertyDetail:OnAwake()
    self:BindExitBtns(self.BtnTanchuangClose)
    self:BindExitBtns(self.BtnClose)
    self:InitDynamicTable()
end

function XUiPlanetPropertyDetail:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewList)
    self.DynamicTable:SetProxy(XUiPlanetPropertyDetailGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridAttr.gameObject:SetActiveEx(false)
end

function XUiPlanetPropertyDetail:OnStart()
    local allAttr = XPlanetCharacterConfigs.GetAllAttr()
    self.DynamicTable:SetDataSource(allAttr)
    self.DynamicTable:ReloadDataASync(1)
end

---@param grid XUiPlanetPropertyDetailGrid
function XUiPlanetPropertyDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    end
end


return XUiPlanetPropertyDetail
