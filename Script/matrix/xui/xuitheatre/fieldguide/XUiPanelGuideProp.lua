local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGuidePropGrid = require("XUi/XUiTheatre/FieldGuide/XUiGuidePropGrid")

--信物和其他道具布局
local XUiPanelGuideProp = XClass(nil, "XUiPanelGuideProp")

function XUiPanelGuideProp:Ctor(ui, clickCb, isCurSelectTokenFunc, isShowUseBtn)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.ClickCallback = clickCb
    self.IsCurSelectTokenFunc = isCurSelectTokenFunc
    self.IsShowUseBtn = isShowUseBtn
    self.TheatreManager = XDataCenter.TheatreManager
    self.TokenManager = self.TheatreManager.GetTokenManager()

    self:InitDynamicTable()
end

function XUiPanelGuideProp:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGuidePropGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridNameplate.gameObject:SetActiveEx(false)
end

function XUiPanelGuideProp:UpdateDynamicTable()
    self.AllToken = self.TokenManager:GetAllToken(self.IsShowUseBtn)
    self.DynamicTable:SetDataSource(self.AllToken)
    self.DynamicTable:ReloadDataSync()
    self.PanelEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.AllToken))
end

function XUiPanelGuideProp:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.ClickCallback, self.IsCurSelectTokenFunc)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local token = self.AllToken[index]
        grid:SetData(token)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local grid = self.DynamicTable:GetGridByIndex(1)
        if grid then
            grid:OnGridBtnClick()
        end
    end
end

function XUiPanelGuideProp:Show()
    self:UpdateDynamicTable()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelGuideProp:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelGuideProp