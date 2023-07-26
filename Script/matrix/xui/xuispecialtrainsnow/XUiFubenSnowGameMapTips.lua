local XUiFubenSnowGameMapTips = XLuaUiManager.Register(XLuaUi, "UiFubenSnowGameMapTips")
local XUiGridFubenSnowGameMap = require("XUi/XUiSpecialTrainSnow/XUiGridFubenSnowGameMap")

function XUiFubenSnowGameMapTips:OnStart(stageId, closeCb)
    self.StageId = stageId
    self.CloseCallback = closeCb
    self:InitUiView()
end

function XUiFubenSnowGameMapTips:OnDestroy()
    if self.CloseCallback then
        self.CloseCallback(self.StageId)
    end
end

function XUiFubenSnowGameMapTips:InitUiView()
    self:RegisterButtonClick()
    self:InitScrollList()
end

function XUiFubenSnowGameMapTips:InitScrollList()
    self.GridList = {}
    self.Stages = XDataCenter.FubenSpecialTrainManager.GetStagesByActivityId(XDataCenter.FubenSpecialTrainManager.GetCurActivityId())

    for _, stageId in pairs(self.Stages) do
        local obj = CS.UnityEngine.GameObject.Instantiate(self.GridMusic, self.Content)
        local grid = XUiGridFubenSnowGameMap.New(stageId, obj, handler(self, self.OnClickGrid))
        if stageId == self.StageId then
            grid:SetSelect(true)
        end
        table.insert(self.GridList, grid)
    end
    self.GridMusic.gameObject:SetActiveEx(false)
end

function XUiFubenSnowGameMapTips:OnClickGrid(stageId)
    self.StageId = stageId
    for _, grid in pairs(self.GridList) do
        grid:SetSelect(stageId == grid.StageId)
    end
    self:Close()
end

function XUiFubenSnowGameMapTips:RegisterButtonClick()
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
end

return XUiFubenSnowGameMapTips