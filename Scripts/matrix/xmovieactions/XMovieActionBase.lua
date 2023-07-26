local CSXScheduleManagerScheduleOnce = XScheduleManager.ScheduleOnce
local CSXScheduleManagerUnSchedule = XScheduleManager.UnSchedule

local ActionStatus = {
    UNINIIALIZED = "UNINIIALIZED",
    ENTER = "ENTER",
    RUNNING = "RUNNING",
    BLOCK = "BLOCK",
    EXIT = "EXIT",
    TERMINATED = "TERMINATED"
}

local _ActiveActionCount = 0 --记录所有已激活剧情节点，用于判断退出剧情后所有节点清理行为完全结束的状态

XMovieActionBase = XClass(nil, "XMovieActionBase")

function XMovieActionBase:Ctor(actionData)
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.Status = ActionStatus.UNINIIALIZED
    self.ActionId = actionData.ActionId
    self.IsActionBlock = paramToNumber(actionData.IsBlock) ~= 0
    self.IsEnd = actionData.IsEnd ~= 0
    self.NextActionId = actionData.NextActionId
    self.BeginAnim = actionData.BeginAnim
    self.EndAnim = actionData.EndAnim
    self.BeginDelay = actionData.BeginDelay
    self.EndDelay = actionData.EndDelay
    self.Type = actionData.Type

    XEventManager.AddEventListener(XEventId.EVENT_MOVIE_UI_OPEN, self.InitUiRoot, self)
    XEventManager.AddEventListener(XEventId.EVENT_MOVIE_UI_DESTROY, self.ClearUiRoot, self)
    XEventManager.AddEventListener(XEventId.EVENT_MOVIE_AUTO_PLAY, self.OnSwitchAutoPlay, self)
end

function XMovieActionBase:GetNextActionId()
    return self.NextActionId
end

function XMovieActionBase:GetSelectedActionId()
    return 0
end

function XMovieActionBase:GetDelaySelectActionId()
    return 0
end

function XMovieActionBase:GetResumeActionId()
    return 0
end

function XMovieActionBase:GetBeginAnim()
    return self.BeginAnim
end

function XMovieActionBase:GetEndAnim()
    return self.EndAnim
end

function XMovieActionBase:GetBeginDelay()
    return self.BeginDelay
end

function XMovieActionBase:GetEndDelay()
    return self.EndDelay
end

function XMovieActionBase:GetType()
    return self.Type
end

function XMovieActionBase:IsBlock()
    return self.IsActionBlock
end

function XMovieActionBase:IsEnding()
    return self.IsEnd
end

function XMovieActionBase:IsWaiting()
    return self.Lock
end

function XMovieActionBase:InitUiRoot(uiRoot)
    _ActiveActionCount = _ActiveActionCount + 1

    self.UiRoot = uiRoot
    self:OnUiRootInit(uiRoot)
end

function XMovieActionBase:ClearUiRoot()
    self.UiRoot = {}
    self:ClearDelayId()
    self.Status = ActionStatus.UNINIIALIZED
    self:OnUiRootDestroy()

    _ActiveActionCount = _ActiveActionCount - 1
    if _ActiveActionCount == 0 then
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_UI_CLOSED)
    end
end

function XMovieActionBase:Enter()
    if self.Status ~= ActionStatus.ENTER then
        return
    end
    self:OnInit()
    self:ChangeStatus(self:GetBeginDelay(), self:GetBeginAnim())
end

function XMovieActionBase:BlockSelf()
    if self.Status ~= ActionStatus.BLOCK then
        return
    end
end

function XMovieActionBase:Run()
    if self.Status ~= ActionStatus.RUNNING then
        return
    end
    self:OnRunning()
    self:ChangeStatus()
end

function XMovieActionBase:Exit()
    if self.Status ~= ActionStatus.EXIT then
        return
    end
    self:ChangeStatus(self:GetEndDelay(), self:GetEndAnim())
end

function XMovieActionBase:Destroy()
    if self.Status ~= ActionStatus.TERMINATED then
        return
    end

    --self.Status = ActionStatus.UNINIIALIZED
    self:OnDestroy()
    return true
end

function XMovieActionBase:ChangeStatus(delay, animName)
    self.Lock = true

    local changeFunc = function()
        self.Lock = nil
        if XTool.UObjIsNil(self.UiRoot.GameObject) then
            return
        end

        if self.Status == ActionStatus.UNINIIALIZED then
            self.Status = ActionStatus.ENTER
            self:Enter()
        elseif self.Status == ActionStatus.ENTER then
            self.Status = ActionStatus.RUNNING
            self:Run()
        elseif self.Status == ActionStatus.RUNNING then
            if self:IsBlock() then
                self.Status = ActionStatus.BLOCK
                self:BlockSelf()
            else
                self.Status = ActionStatus.EXIT
                self:Exit()
            end
        elseif self.Status == ActionStatus.BLOCK then
            self.Status = ActionStatus.EXIT
            self:Exit()
        elseif self.Status == ActionStatus.EXIT then
            self.Status = ActionStatus.TERMINATED
            self:OnExit()
            XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
        end
    end

    local animCb = function()
        if delay and delay ~= 0 then
            self.DelayId =
                self.DelayId or
                CSXScheduleManagerScheduleOnce(
                    function()
                        self.DelayId = nil
                        changeFunc()
                    end,
                    delay
                )
        else
            changeFunc()
        end
    end

    if animName and animName ~= "NoAnim" then
        if XTool.UObjIsNil(self.UiRoot.GameObject) then
            return
        end

        local anim = self.UiRoot[animName]
        if not anim then
            XLog.Error("animName配置错误，找不到" .. animName .. "对应的动画，请检查节点: " .. self.ActionId)
            return
        end

        anim.gameObject:SetActiveEx(true)
        if not anim.gameObject.activeInHierarchy then
            return
        end
        anim:PlayTimelineAnimation(
            function()
                XLuaUiManager.SetMask(false)
                anim.gameObject:SetActiveEx(false)
                animCb()
            end,
            function()
                XLuaUiManager.SetMask(true)
            end
        )
    else
        animCb()
    end
end

function XMovieActionBase:ClearDelayId()
    if self.DelayId then
        CSXScheduleManagerUnSchedule(self.DelayId)
        self.DelayId = nil
    end
    self.Lock = false
end

function XMovieActionBase:OnUiRootInit()
end

function XMovieActionBase:OnUiRootDestroy()
end

function XMovieActionBase:OnInit()
end

function XMovieActionBase:OnRunning()
end

function XMovieActionBase:OnExit()
end

function XMovieActionBase:OnDestroy()
end

function XMovieActionBase:OnSwitchAutoPlay()
end

function XMovieActionBase:CanContinue()
    return true
end

function XMovieActionBase:OnReset()
    self.Status = ActionStatus.UNINIIALIZED
end

function XMovieActionBase:OnUndo()
end
