---@class XUiPanelSpecialTrain
local XUiPanelSpecialTrain = XClass(nil, "XUiPanelSpecialTrain")

function XUiPanelSpecialTrain:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self.DynamicTable = false
    XTool.InitUiObject(self)
    self:InitUi()
end

function XUiPanelSpecialTrain:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelCore)
    self.DynamicTable:SetProxy(require("XUi/XUiSet/XUiPanelSpecialTrainGrid"))
    self.DynamicTable:SetDelegate(self)
    self.Grid.gameObject:SetActiveEx(false)
    self:InitData()
end

function XUiPanelSpecialTrain:InitData()
    local stageType = XDataCenter.FubenManager.GetCurrentStageType()
    self.DynamicTable:SetDataSource(XFubenConfigs.GetStageGamePlayDescDataSource(stageType))
    self.DynamicTable:ReloadDataASync(1)
    self.TextTitle.text = XFubenConfigs.GetStageGamePlayTitle(stageType)
end

---@param grid XUiSpecialTrainGrid
function XUiPanelSpecialTrain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    end
end

function XUiPanelSpecialTrain:CheckDataIsChange()
    return false
end

function XUiPanelSpecialTrain:ShowPanel()
    self.GameObject:SetActive(true)
end

function XUiPanelSpecialTrain:HidePanel()
    self.GameObject:SetActive(false)
end

return XUiPanelSpecialTrain
