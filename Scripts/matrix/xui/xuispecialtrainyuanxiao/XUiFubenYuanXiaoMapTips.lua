local XUiFubenYuanXiaoMapTips = XLuaUiManager.Register(XLuaUi,"UiFubenYuanXiaoMapTips")
local XUiGridFubenYuanXiaoMap = require("XUi/XUiSpecialTrainYuanXiao/XUiGridFubenYuanXiaoMap")

function XUiFubenYuanXiaoMapTips:OnStart(stageId, isRandomStageId, closeCb)
    self.StageId = stageId
    self.IsHell = XFubenSpecialTrainConfig.IsHellStageId(stageId)
    self.IsRandomStageId = isRandomStageId
    self.CloseCallback = closeCb
    self:InitUiView()

    -- 开启自动关闭检查
    local endTime = XDataCenter.FubenSpecialTrainManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.FubenSpecialTrainManager.HandleActivityEndTime()
        end
    end)
end

function XUiFubenYuanXiaoMapTips:InitUiView()
    self:RegisterButtonClick()
    self:InitScrollList()
end

function XUiFubenYuanXiaoMapTips:RegisterButtonClick()
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
end

function XUiFubenYuanXiaoMapTips:InitScrollList()
    self.Stages = XDataCenter.FubenSpecialTrainManager.GetAllStageIdByActivityId(XDataCenter.FubenSpecialTrainManager.GetCurActivityId(), self.IsRandomStageId)
    for _, stageId in pairs(self.Stages) do
        if self.IsHell and not self.IsRandomStageId then
            stageId = XFubenSpecialTrainConfig.GetHellStageId(stageId)
        end
        local obj = CS.UnityEngine.GameObject.Instantiate(self.GridMusic, self.Content)
        local grid = XUiGridFubenYuanXiaoMap.New(stageId, obj, handler(self, self.OnClickGrid))
        if stageId == self.StageId then
            grid:SetSelect(true)
        end
    end
    self.GridMusic.gameObject:SetActiveEx(false)
end

function XUiFubenYuanXiaoMapTips:OnClickGrid(stageId)
    if self.CloseCallback then
        self.CloseCallback(stageId)
    end
    
    self:Close()
end

return XUiFubenYuanXiaoMapTips