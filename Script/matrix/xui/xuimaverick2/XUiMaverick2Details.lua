local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiMaverick2DetailsGrid = require("XUi/XUiMaverick2/XUiMaverick2DetailsGrid")

-- 异构阵线2.0天赋汇总界面
local XUiMaverick2Details = XLuaUiManager.Register(XLuaUi, "UiMaverick2Details")

function XUiMaverick2Details:OnAwake()
    self:SetButtonCallBack()
    self:InitTimes()
    self:InitTabBtnGroup()
    self:InitDynamicTable()
end

function XUiMaverick2Details:OnStart(robotId)
    self.RobotId = robotId
    self.BtnGroup:SelectIndex(1)
end

function XUiMaverick2Details:OnEnable()
    self.Super.OnEnable(self)
end

function XUiMaverick2Details:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnCloseBg, self.Close)
end

function XUiMaverick2Details:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.Maverick2Manager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiMaverick2Details:InitTabBtnGroup()
    self.Btns = {self.BtnTab1, self.BtnTab2 }
    self.BtnGroup:Init(self.Btns, function(tabIndex)
        self:RefreshTalentDetails(tabIndex)
    end)
end

-- 刷新天赋详情
function XUiMaverick2Details:RefreshTalentDetails(tabIndex)
    self.TalentInfos = XDataCenter.Maverick2Manager.GetRobotSummaryInfos(self.RobotId, tabIndex)
    self:RefreshDynamicTable()
    local isEmpty = #self.TalentInfos == 0
    self.PanelNo.gameObject:SetActiveEx(isEmpty)
end


---------------------------------------- 动态列表 begin ----------------------------------------
function XUiMaverick2Details:InitDynamicTable()
    self.GridDetail.gameObject:SetActive(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicTable:SetProxy(XUiMaverick2DetailsGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiMaverick2Details:RefreshDynamicTable()
    self.DynamicTable:SetDataSource(self.TalentInfos)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiMaverick2Details:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local talentInfo = self.TalentInfos[index]
        grid:Refresh(talentInfo)
    end
end
---------------------------------------- 机器人动态列表 begin ----------------------------------------
