local XUiFubenMaverickLose = XLuaUiManager.Register(XLuaUi, "UiFubenMaverickLose")

function XUiFubenMaverickLose:OnAwake()
    self:InitButtons()
end

function XUiFubenMaverickLose:OnStart()
    local beginData = XDataCenter.FubenManager.GetFightBeginData()
    self.StageId = beginData.StageId
    local stagCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.TxtStageName.text = stagCfg.Name

    local stage = XDataCenter.MaverickManager.GetStage(self.StageId)
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

function XUiFubenMaverickLose:OnDestroy()
    self.Super.OnDestroy(self)
    
    XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_FINISH_LOSEUI_CLOSE)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.OnOpenLoadingOrBeginPlayMovie, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.OnOpenLoadingOrBeginPlayMovie, self)
end

function XUiFubenMaverickLose:InitButtons()
    self.BtnLose.onClick:AddListener(function() self:Close() end)
    self.BtnRestart.CallBack = function() XDataCenter.MaverickManager.EnterFight(self.StageId) end
end

function XUiFubenMaverickLose:OnOpenLoadingOrBeginPlayMovie()
    self:Remove()
end