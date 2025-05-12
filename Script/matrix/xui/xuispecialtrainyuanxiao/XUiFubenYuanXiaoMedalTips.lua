local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiFubenYuanXiaoMedalTips = XLuaUiManager.Register(XLuaUi,"UiFubenYuanXiaoMedalTips")
local XUiGridFubenYuanXiaoMedal = require("XUi/XUiSpecialTrainYuanXiao/XUiGridFubenYuanXiaoMedal")

function XUiFubenYuanXiaoMedalTips:OnStart()
    self.GridMusic.gameObject:SetActiveEx(false)
    self:RegisterButtonClick()
    self:InitDynamicTable()
    self:SetupDynamicTable()
    self:BindExitBtns(self.BtnClose)

    -- 开启自动关闭检查
    local endTime = XDataCenter.FubenSpecialTrainManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.FubenSpecialTrainManager.HandleActivityEndTime()
        end
    end)
end

function XUiFubenYuanXiaoMedalTips:RegisterButtonClick()
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
end

function XUiFubenYuanXiaoMedalTips:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelMapGroup)
    self.DynamicTable:SetProxy(XUiGridFubenYuanXiaoMedal)
    self.DynamicTable:SetDelegate(self)
end

function XUiFubenYuanXiaoMedalTips:SetupDynamicTable()
    local activityId = XDataCenter.FubenSpecialTrainManager.GetCurActivityId()
    self.DynamicTableDataList = XFubenSpecialTrainConfig.GetRankAllId(activityId)
    self.DynamicTable:SetDataSource(self.DynamicTableDataList)

    local index = -1
    local curRankId = XDataCenter.FubenSpecialTrainManager.GetCurrentRankId()
    for key, value in pairs(self.DynamicTableDataList) do
        if value == curRankId then
            index = key
        end
    end

    self.DynamicTable:ReloadDataASync(index)
end

function XUiFubenYuanXiaoMedalTips:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DynamicTableDataList[index])
    end
end

return XUiFubenYuanXiaoMedalTips