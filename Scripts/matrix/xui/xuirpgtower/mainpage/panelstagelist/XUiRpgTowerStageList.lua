-- 兵法蓝图主页面关卡动态列表控件
local XUiRpgTowerStageList = XClass(nil, "XUiRpgTowerStageList")
local XUiRpgTowerStageGrid = require("XUi/XUiRpgTower/MainPage/PanelStageList/XUiRpgTowerStageGrid")
--================
--构造函数
--================
function XUiRpgTowerStageList:Ctor(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self.GridStage.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XUiRpgTowerStageGrid)
    self.DynamicTable:SetDelegate(self)
    self.AvailableViewCount = self.GameObject:GetComponent("XDynamicTableNormal").AvailableViewCount
end
--================
--动态列表事件
--================
function XUiRpgTowerStageList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.StageList and self.StageList[index] then
            grid:RefreshData(self.StageList[index], index)
            -- if self.SetCurrent and self.Chapter:GetCurrentIndex() == index then
            --     grid:SetSelect(true)
            -- else
            if self.CurrentIndex == index then
                grid:SetSelect(true)
            end
        end
    end
end
--================
--刷新列表
--================
function XUiRpgTowerStageList:UpdateData()
    self.Chapter = XDataCenter.RpgTowerManager.GetCurrentChapter()
    -- self.StageList = self.Chapter:GetDynamicRStageList(self.AvailableViewCount, 2, self.RootUi.CurTagData.Id)
    self.StageList = XDataCenter.RpgTowerManager.GetCurrActivityStageListByTagId(self.RootUi.CurTagData.Id)
    self.DynamicTable:SetDataSource(self.StageList)
    local newStageIndex = self:GetNewStageIndex()
    self.SetCurrent = true
    self.CurrentIndex = newStageIndex
    self.DynamicTable:ReloadDataASync(newStageIndex)
end
--================
--根据最新的关卡序号，获取列表要显示的位置
--================
function XUiRpgTowerStageList:GetNewStageIndex()
    local newStageIndex = 1
    for i, rStageCfg in ipairs(self.StageList) do
        local rStage = XDataCenter.RpgTowerManager.GetRStageByStageId(rStageCfg.StageId)
        if not rStage:GetIsUnlock() then
            break
        end
        newStageIndex = i
    end
    return newStageIndex
end
--================
--列表项选中事件
--================
function XUiRpgTowerStageList:SetSelect(grid)
    if self.SetCurrent then self.SetCurrent = false end
    if self.CurGrid and self.CurGrid ~= grid then
        self.CurGrid:SetSelect(false)
    end
    self.CurGrid = grid
    self.CurrentIndex = grid.GridIndex
    self.RootUi:OnClickStageGrid(grid.RStage)
end
return XUiRpgTowerStageList