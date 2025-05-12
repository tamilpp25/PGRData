local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelSpecialTrain : XUiNode
local XUiPanelSpecialTrain = XClass(XUiNode, "XUiPanelSpecialTrain")

function XUiPanelSpecialTrain:OnStart()
    self.DynamicTable = false
    self:InitUi()
end

function XUiPanelSpecialTrain:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelCore)
    self.DynamicTable:SetProxy(require("XUi/XUiSet/XUiPanelSpecialTrainGrid"), self.Parent)
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

return XUiPanelSpecialTrain
