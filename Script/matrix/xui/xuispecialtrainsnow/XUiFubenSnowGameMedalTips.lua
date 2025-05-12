---@class XUiFubenSnowGameMedalTips : XLuaUi
local XUiFubenSnowGameMedalTips = XLuaUiManager.Register(XLuaUi, "UiFubenSnowGameMedalTips")
local XUiGridFubenSnowGameMedal = require("XUi/XUiSpecialTrainSnow/XUiGridFubenSnowGameMedal")

function XUiFubenSnowGameMedalTips:OnStart(curRankId)
    self.CurRankId = curRankId
    self:RegisterButtonClick()
    self:RefreshGrid()
end

function XUiFubenSnowGameMedalTips:RegisterButtonClick()
    self.BtnClose.CallBack = function()
        self:Close()
    end
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
end

function XUiFubenSnowGameMedalTips:RefreshGrid()
    local activityId = XDataCenter.FubenSpecialTrainManager.GetCurActivityId()
    local dataList = XFubenSpecialTrainConfig.GetRankAllId(activityId)
    local gird = {
        self.GridMusic1, self.GridMusic2, self.GridMusic3, self.GridMusic4, self.GridMusic5, self.GridMusic6
    }
    self:RefreshTemplateGrids(gird, dataList, self.PanelMapGroup, XUiGridFubenSnowGameMedal, "GridMedalList", function(grid, data)
        grid:Refresh(data, self.CurRankId)
    end)
end

return XUiFubenSnowGameMedalTips