---@class XMessagePlayer
local XMessagePlayer = XClass(nil, "XMessagePlayer")

local State = {
    None = 0,
    Playing = 1,
    Waiting = 2,
    Continue = 3,
}

---@param message XBWMessageEntity
function XMessagePlayer:Ctor(proxy, message)
    self._State = State.None
    self._Timer = false
    self._IsBeginLoading = false
    self:SetMessage(message)
    self:SetProxy(proxy)
end

---@param message XBWMessageEntity
function XMessagePlayer:SetMessage(message)
    self:Stop()
    self._CurrentStepId = -1
    self._Message = message
end

function XMessagePlayer:SetProxy(proxy)
    self._Proxy = proxy
end

function XMessagePlayer:IsPlaying()
    return self._State ~= State.None
end

function XMessagePlayer:Play()
    if self:IsExist() then
        self:Stop()
        self:_ChangeState(State.Playing)
    end
end

function XMessagePlayer:PlayNext(index)
    if self:IsPlaying() and self:IsExist() then
        local content = self._Message:GetContentByStepId(self._CurrentStepId)

        if content then
            self:_RemoveTimer()

            local duration = content:GetDuration()

            if XTool.IsNumberValid(duration) and not content:IsComplete() then
                self:_OnProxyPlayBeginLoading(content)
                self._Timer = XScheduleManager.ScheduleOnce(function()
                    self._Timer = false
                    self:_OnPlay(content, index)
                end, duration * XScheduleManager.SECOND)
            else
                self:_OnPlay(content, index)
            end
        end
    end
end

function XMessagePlayer:Stop()
    self:_ChangeState(State.None)
end

function XMessagePlayer:IsExist()
    return self._Message and not self._Message:IsNil()
end

function XMessagePlayer:Destroy()
    self:Stop()
    self._Proxy = nil
    self._Message = nil
end

function XMessagePlayer:_RemoveTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

---@param content XBWMessageContentEntity
function XMessagePlayer:_OnPlay(content, index)
    if self._State ~= State.Waiting then
        self:_OnProxyPlayEndLoading(content)
        self:_OnProxyPlay(content)
    end

    if content:IsEnd() then
        self:_RequestMessageReadRecord()
        self:Stop()
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_FINISH_NOTIFY)

        return
    end

    if content:IsComplete() and self._State ~= State.Waiting then
        self._CurrentStepId = content:GetNextStepId()
        self:PlayNext()
    else
        if content:IsOptions() then
            if self._State == State.Waiting then
                self:_ChangeState(State.Continue)
                self:_RequestMessageReadRecord()

                self._CurrentStepId = content:GetOprionsNextStepByIndex(index)

                self:_RequestMessageReadRecord()
                self:PlayNext()
            else
                self:_ChangeState(State.Waiting)
            end
        else
            content:Read()
            self._CurrentStepId = content:GetNextStepId()
            self:PlayNext()
        end
    end
end

function XMessagePlayer:_OnProxyPlay(content)
    if self._Proxy and self._Proxy.OnPlayMessage then
        self._Proxy:OnPlayMessage(content)
    end
end

function XMessagePlayer:_OnProxyPlayBeginLoading(content)
    self._IsBeginLoading = true
    if self._Proxy and self._Proxy.OnPlayMessageBeginLoading then
        self._Proxy:OnPlayMessageBeginLoading(content)
    end
end

function XMessagePlayer:_OnProxyPlayEndLoading(content)
    if self._IsBeginLoading then
        self._IsBeginLoading = false
        if self._Proxy and self._Proxy.OnPlayMessageEndLoading then
            self._Proxy:OnPlayMessageEndLoading(content)
        end
    end
end

function XMessagePlayer:_ChangeState(state)
    self._State = state
    if state == State.Playing then
        self._CurrentStepId = self._Message:GetFirstStepId()
        self:PlayNext()
    elseif state == State.None then
        self._CurrentStepId = 0
        self:_RemoveTimer()
    elseif state == State.Continue then
        self._State = State.Playing
    end
end

function XMessagePlayer:_RequestMessageReadRecord()
    local content = self._Message:GetContentByStepId(self._CurrentStepId)

    if not content:IsComplete() then
        local groupStepId = content:GetStepId()
        local messageId = content:GetMessageId()

        XMVCA.XBigWorldMessage:RequestBigWorldMessageReadRecord(messageId, groupStepId, content:IsEnd())
    end
    content:Read()
end

return XMessagePlayer
