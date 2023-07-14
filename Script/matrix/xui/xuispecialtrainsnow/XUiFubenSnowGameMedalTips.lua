local XUiFubenSnowGameMedalTips = XLuaUiManager.Register(XLuaUi, "UiFubenSnowGameMedalTips")
local XUiGridFubenSnowGameMedal = require("XUi/XUiSpecialTrainSnow/XUiGridFubenSnowGameMedal")

function XUiFubenSnowGameMedalTips:OnStart(curRankId)
    self.CurRankId = curRankId
    self.GridMusic.gameObject:SetActiveEx(false)
    self:RegisterButtonClick()
    self:InitDynamicTable()
    self:SetupDynamicTable()
end

function XUiFubenSnowGameMedalTips:RegisterButtonClick()
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
end

function XUiFubenSnowGameMedalTips:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelMapGroup)
    self.DynamicTable:SetProxy(XUiGridFubenSnowGameMedal)
    self.DynamicTable:SetDelegate(self)
end

function XUiFubenSnowGameMedalTips:SetupDynamicTable()
    local activityId = XDataCenter.FubenSpecialTrainManager.GetCurActivityId()
    self.DynamicTableDataList = XFubenSpecialTrainConfig.GetRankAllId(activityId)
    self.DynamicTable:SetDataSource(self.DynamicTableDataList)
    
    local index = -1
    for key, value in pairs(self.DynamicTableDataList) do
        if value == self.CurRankId then
            index = key
        end
    end
    
    self.DynamicTable:ReloadDataASync(index)
end

function XUiFubenSnowGameMedalTips:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DynamicTableDataList[index], self.CurRankId)
    end
end

return XUiFubenSnowGameMedalTips