local XUiFubenMaverickFight = XLuaUiManager.Register(XLuaUi, "UiFubenMaverickFight")

function XUiFubenMaverickFight:OnAwake()
    self:InitButtons()
end

function XUiFubenMaverickFight:OnStart(settle, cb)
    self.StageId = settle.StageId

    local curFightResult = XDataCenter.FubenManager.CurFightResult
    local oldStageScore = XDataCenter.MaverickManager.GetStageScore(self.StageId)
    local newStageScore = 0
    local killCount = 0
    local tempResult = false
    XTool.LoopMap(curFightResult.CustomData, function(_, data)
        tempResult, newStageScore = data.Dict:TryGetValue(XDataCenter.MaverickManager.ResultKeys.Score)
        tempResult, killCount = data.Dict:TryGetValue(XDataCenter.MaverickManager.ResultKeys.killCount)
    end)
    
    local stage = XDataCenter.MaverickManager.GetStage(self.StageId)
    --text
    self.TxtTile.text = XDataCenter.MaverickManager.GetPatternName(stage.PatternId)
    self.TxtHitCombo.text = killCount
    self.TxtHitScore.text = "+" .. newStageScore
    if newStageScore > oldStageScore then
        self.TxtPoint.text = CSXTextManagerGetText("MaverickStageScoreMax", newStageScore)
        self.TxtHighScore.text = CSXTextManagerGetText("MaverickStageHistoryScoreMax", newStageScore)
        self.PanelNewRecord.gameObject:SetActiveEx(true)
    else
        self.TxtPoint.text = newStageScore
        self.TxtHighScore.text = oldStageScore
        self.PanelNewRecord.gameObject:SetActiveEx(false)
    end

    local costTime = (curFightResult.SettleFrame - curFightResult.PauseFrame - curFightResult.StartFrame) / CS.XFightConfig.FPS
    local h = XMath.ToMinInt(costTime / (60 * 60))
    local m = XMath.ToMinInt((costTime - h * (60 * 60)) / 60)
    local s = XMath.ToMinInt(costTime - h * (60 * 60) - m * 60)
    self.TxtCostTime.text = string.format("%02d:%02d:%02d", h, m, s)

    if cb then
        cb(newStageScore)
    end
    
    local activityEndTime = XDataCenter.MaverickManager.GetEndTime()
    local patternEndTime = XDataCenter.MaverickManager.GetPatternEndTime(stage.PatternId)
    if patternEndTime < activityEndTime then
        self:SetAutoCloseInfo(patternEndTime, function(isClose)
            if isClose then
                XDataCenter.MaverickManager.EndPattern(stage.PatternId)
            end
        end, nil , 0)
    else
        self:SetAutoCloseInfo(activityEndTime, function(isClose)
            if isClose then
                XDataCenter.MaverickManager.EndActivity()
            end
        end, nil , 0)
    end

    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.OnOpenLoadingOrBeginPlayMovie, self)
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.OnOpenLoadingOrBeginPlayMovie, self)
end

function XUiFubenMaverickFight:OnDestroy()
    self.Super.OnDestroy(self)

    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.OnOpenLoadingOrBeginPlayMovie, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.OnOpenLoadingOrBeginPlayMovie, self)
end

function XUiFubenMaverickFight:InitButtons()
    self.BtnExitFight.CallBack = function() self:Close() end
    self.BtnReFight.CallBack = function() XDataCenter.MaverickManager.EnterFight(self.StageId) end
end

function XUiFubenMaverickFight:OnOpenLoadingOrBeginPlayMovie()
    self:Remove()
end