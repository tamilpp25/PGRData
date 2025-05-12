local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelBWDelivery : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiBigWorldPopupDelivery
---@field _Control
local XUiPanelBWDelivery = XClass(XUiNode, "XUiPanelBWDelivery")

local ColorEnum = {
    FirNoneEnough = "#B72424",
    SecNoneEnough = "#000000",

    FirEnough = "#fff100",
    SecEnough = "#fff100",
}

function XUiPanelBWDelivery:OnStart(title, isWarehouse)
    if not string.IsNilOrEmpty(title) then
        self.Txt.text = title
    end
    self._IsWarehouse = isWarehouse
    self:InitCb()
    self:InitView()
end

function XUiPanelBWDelivery:InitCb()
end

function XUiPanelBWDelivery:InitView()
    self.Grid.gameObject:SetActiveEx(false)

    self._DynamicTable = XDynamicTableNormal.New(self.PanelList)
    local clickProxy
    if self._IsWarehouse then
        clickProxy = function(itemParams) self:OnClickItemProxy(itemParams) end
    end
    
    self._DynamicTable:SetProxy(require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem"), self, clickProxy)
    self._DynamicTable:SetDelegate(self)
end

function XUiPanelBWDelivery:RefreshView(consumes)
    self._DataList = consumes
    self:SetupDynamicTable()
end

function XUiPanelBWDelivery:SetupDynamicTable()
    local isEmpty = XTool.IsTableEmpty(self._DataList)
    self.PanelEmpty.gameObject:SetActiveEx(isEmpty)
    if isEmpty then
        return
    end

    self._DynamicTable:SetDataSource(self._DataList)
    self._DynamicTable:ReloadDataSync()
end

---@param grid XUiGridBWItem
function XUiPanelBWDelivery:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DataList[index]
        grid:Refresh(data)
        self:RefreshProgressNum(evt, index, grid)
    end
end

function XUiPanelBWDelivery:RefreshProgressNum(evt, index, grid)
    local data = self._DataList[index]
    local count = self._IsWarehouse and XMVCA.XBigWorldService:GetQuestItemCount(data.Id) or data.Select
    local color1, color2
    if count >= data.Total then
        color1 = ColorEnum.FirEnough
        color2 = ColorEnum.SecEnough
    else
        color1 = ColorEnum.FirNoneEnough
        color2 = ColorEnum.SecNoneEnough
    end
    grid:RefreshProgressNum(data.Select, data.Total, color1, color2)
end

function XUiPanelBWDelivery:OnClickItemProxy(itemParams)
    if not itemParams then
        return
    end

    self.Parent:OnSelectItemInWarehouse(itemParams.TemplateId)
end

return XUiPanelBWDelivery