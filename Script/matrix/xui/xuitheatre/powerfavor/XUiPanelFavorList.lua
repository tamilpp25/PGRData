local XUiGridFavorList = require("XUi/XUiTheatre/PowerFavor/XUiGridFavorList")

--肉鸽玩法势力总览界面
local XUiPanelFavorList = XClass(nil, "XUiPanelFavorList")

function XUiPanelFavorList:Ctor(ui, clickGridCallback)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.ClickGridCallback = clickGridCallback
    self:InitDynamicTable()
end

function XUiPanelFavorList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridFavorList, self.ClickGridCallback)
    self.DynamicTable:SetDelegate(self)

    self.PowerIdList = XTheatreConfigs.GetPowerConditionIdList()
    self.GridShop.gameObject:SetActiveEx(false)
end

function XUiPanelFavorList:UpdateDynamicTable()
    self.DynamicTable:SetDataSource(self.PowerIdList)
    self.DynamicTable:ReloadDataASync()
end

function XUiPanelFavorList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.PowerIdList[index])
    end
end

function XUiPanelFavorList:Show()
    self:UpdateDynamicTable()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelFavorList:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelFavorList:IsShow()
    return self.GameObject.activeSelf
end

return XUiPanelFavorList