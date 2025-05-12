local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

local XUiSuperSmashBrosClearTime = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosClearTime")

function XUiSuperSmashBrosClearTime:OnStart()
    self.Mode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(XSuperSmashBrosConfig.ModeType.Survive)
    self:InitBtns()
    self:InitPanels()
end

function XUiSuperSmashBrosClearTime:InitBtns()
    self.BtnClose.CallBack = function() self:OnClickBtnClose() end
end

function XUiSuperSmashBrosClearTime:OnClickBtnClose()
    self:Close()
end

function XUiSuperSmashBrosClearTime:InitPanels()
    self:InitDynamicTable()
    self:InitTxtScores()
end

function XUiSuperSmashBrosClearTime:InitTxtScores()
    self.TxtLastTotalTime.text = XUiHelper.GetTime(self.Mode:GetSpendTime(), XUiHelper.TimeFormatType.DEFAULT)
    self.TxtBestTotalTime.text = XUiHelper.GetTime(self.Mode:GetBestTime(), XUiHelper.TimeFormatType.DEFAULT)
    self.TxtLastWinCount.text = self.Mode:GetWinCount()
    self.TxtBestWinCount.text = self.Mode:GetBestStageAttackNum()
end

function XUiSuperSmashBrosClearTime:InitDynamicTable()
    self.GridRecord.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.SView.gameObject)
    local gridProxy = require("XUi/XUiSuperSmashBros/ClearTime/XUiSSBClearTimeGrid")
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetDelegate(self)
end

--================
--动态列表事件
--================
function XUiSuperSmashBrosClearTime:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(index, self.DataList[index].LastTime, self.DataList[index].BestTime)
    end
end
--================
--刷新动态列表
--================
function XUiSuperSmashBrosClearTime:OnEnable()
    self.DataList = self:CreateTimeAttackData()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end
--================
--建立时间挑战数据
--================
function XUiSuperSmashBrosClearTime:CreateTimeAttackData()
    local bestTimeAttackData = self.Mode:GetBestTimeAttackData()
    local lastTimeAttackData = self.Mode:GetLastTimeAttackData()
    local resultList = {}
    for index = 1, #self.Mode:GetAllStages() do
        local timeAttackInfo = {
                LastTime = lastTimeAttackData[index] and lastTimeAttackData[index].Time,
                BestTime = bestTimeAttackData[index] and bestTimeAttackData[index].Time
            }
        resultList[index] = timeAttackInfo
    end
    return resultList
end