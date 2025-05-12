---@class XAnniversaryAgency : XAgency
---@field private _Model XAnniversaryModel
local XAnniversaryAgency = XClass(XAgency, "XAnniversaryAgency")

--渲染层级
local HiddenLayer = 30
local AnniversaryMainSkipId = 89047--SkipFunctional中周年主界面的skipId
local AnniversaryDrawId = {}

function XAnniversaryAgency:OnInit()
    --初始化一些变量
    self.HiddenLayerMask = math.pow(2, HiddenLayer)
    local drawIdStr = CS.XGame.ClientConfig:GetString('AnniversaryDrawId')
    local drawIdStrs = string.Split(drawIdStr, '|')
    if not XTool.IsTableEmpty(drawIdStrs) then
        for i, v in pairs(drawIdStrs) do
            local drawId = tonumber(v)
            AnniversaryDrawId[drawId] = true
        end
    end
end

function XAnniversaryAgency:InitRpc()
    --实现服务器事件注册
    XRpc.NotifyReviewData = handler(self, self.OnNotifyReviewData)

    XRpc.NotifyReviewSlapFaceState = handler(self, self.OnNotifyReviewSlapFaceState)

    XRpc.NotifyReviewConfig = handler(self, self.OnNotifyReviewConfig)
end

function XAnniversaryAgency:InitEvent()
    self:AddAgencyEvent(XEventId.EVENT_AWARD_SHOP_ENTER, self._OnRepeatChallengeEnterEvent, self)
    self:AddAgencyEvent(XEventId.EVENT_DRAW_SELECT, self._OnDrawSelectEvent, self)
end

function XAnniversaryAgency:RemoveEvent()
    self:RemoveAgencyEvent(XEventId.EVENT_AWARD_SHOP_ENTER, self._OnRepeatChallengeEnterEvent, self)
    self:RemoveAgencyEvent(XEventId.EVENT_DRAW_SELECT, self._OnDrawSelectEvent, self)
end

function XAnniversaryAgency:GetAnniversaryMainSkipId()
    return AnniversaryMainSkipId
end

function XAnniversaryAgency:GetHadInDrawkey()
    return 'Anniversary4_had_into_draw_'..tostring(self._Model:GetActivityId())..'_'.. XPlayer.Id
end

function XAnniversaryAgency:GetHadInRepeatChallengeKey()
    return 'Anniversary4_had_into_repeatChallenge_' .. tostring(self._Model:GetActivityId())..'_'..XPlayer.Id
end

--region 活动开启判定

function XAnniversaryAgency:IsActivityInTime(activityid)
    local cfg = self._Model:GetAnniversaryActivity()[activityid]
    if cfg then
        return XFunctionManager.CheckSkipInDuration(cfg.SkipID)
    end
end

function XAnniversaryAgency:IsActivityOutTime(activityid)
    local cfg = self._Model:GetAnniversaryActivity()[activityid]
    if cfg then
        local curTime = XTime.GetServerNowTimestamp()
        local skipCfg = XFunctionConfig.GetSkipFuncCfg(cfg.SkipID)
        --没有配置默认不开放
        if not skipCfg then
            return true
        end

        local endTime = 0
        if XTool.IsNumberValid(skipCfg.TimeId) then
            endTime = XFunctionManager.GetEndTimeByTimeId(skipCfg.TimeId) or 0
        elseif skipCfg.CloseTime then
            endTime = XTime.ParseToTimestamp(skipCfg.CloseTime)
        else
            --没有时间约束，则默认没有超出活动时间
            return false
        end
        return curTime >= endTime
    end
end

function XAnniversaryAgency:IsActivityConditionSatisfy(activityId)
    local cfg = self._Model:GetAnniversaryActivity()[activityId]
    local isOpen = true
    local desc = ''
    if cfg then
        isOpen = XFunctionManager.IsCanSkip(cfg.SkipID)
        local list = XFunctionConfig.GetSkipList(cfg.SkipID)
        if list then
            desc = XFunctionManager.GetFunctionOpenCondition(list.FunctionalId)
        end
    end

    return isOpen, desc
end

function XAnniversaryAgency:JudgeCanOpen(activityid)

    if self:IsActivityOutTime(activityid) then
        --活动已结束
        return false, XUiHelper.GetText('ActivityAlreadyOver')
    elseif self:IsActivityInTime(activityid) then
        return self:IsActivityConditionSatisfy(activityid)
    else
        local cfg = self._Model:GetAnniversaryActivity()[activityid]
        if cfg then
            --活动于xx月xx日开启
            local skipCfg = XFunctionConfig.GetSkipFuncCfg(cfg.SkipID)
            if skipCfg then
                if skipCfg.TimeId then
                    local startTime = XFunctionManager.GetStartTimeByTimeId(skipCfg.TimeId)
                    local dt = CS.XDateUtil.GetLocalDateTime(startTime)
                    return false, XUiHelper.GetText('ActivityOpenMonthDayTime', dt.Month, dt.Day)
                else
                    return false, XUiHelper.GetText('ActivityAlreadyOver')
                end
            end

        end

    end
end
--endregion

function XAnniversaryAgency:AutoOpenReview()
    if self._Model:CheckIsReviewDataEmpty() or self._Model:GetReviewIsShown() then
        return false 
    end
    
    local isOpen, desc = XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.Review)
    if isOpen then
        XLuaUiManager.Open("UiAnniversaryReviewEntrance")
        return true
    end
    return false, desc
end

function XAnniversaryAgency:HasActivityInTime()
    local reviewConfigs = self._Model:GetReviewActivityServerConfigs()

    if not XTool.IsTableEmpty(reviewConfigs) then
        for id, cfg in pairs(reviewConfigs) do
            if not cfg then return false end
            local startTime = cfg.StartTime
            local endTime = cfg.EndTime
            if not startTime or (startTime == 0) then

            elseif not endTime or (endTime == 0) then

            else
                local now = XTime.GetServerNowTimestamp()
                local isOpen=(startTime <= now) and (endTime > now)
                if isOpen then return true end
            end

        end
    end
    return false
end

function XAnniversaryAgency:CheckHasActivityInTime()
    if self:HasActivityInTime() then
        return true, ''
    else
        return false, XUiHelper.GetText('CommonActivityNotStart')
    end
end

--region private

function XAnniversaryAgency:_OnRepeatChallengeEnterEvent()
    XSaveTool.SaveData(self:GetHadInRepeatChallengeKey(), true)
end

function XAnniversaryAgency:_OnDrawSelectEvent(drawId)
    --如果选择的是周年卡池
    if AnniversaryDrawId[drawId] then
        XSaveTool.SaveData(self:GetHadInDrawkey(), true)
    end
end

--endregion

--region 协议
function XAnniversaryAgency:OnNotifyReviewConfig(data)
    self._Model:SetReviewActivityServerConfig(data.ReviewActivityConfigList)
end

function XAnniversaryAgency:OnNotifyReviewSlapFaceState(data)
    self._Model:SetReviewIsShown(data.SlapFaceState)
end

function XAnniversaryAgency:OnNotifyReviewData(data)
    self._Model:RefreshReviewData(data.ReviewActivityData)
end

function XAnniversaryAgency:DoReviewDataInfoRequest(cb)
    if not self._Model:CheckIsReviewDataEmpty() then
        if cb then
            cb()
        end
        return
    end
    XNetwork.Call('ReviewDataInfoRequest', { ActivityId = self._Model:GetActivityId()}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:RefreshReviewData(res.ReviewActivityData)
        if cb then
            cb()
        end
    end)
end

function XAnniversaryAgency:DoSetReviewSlapFaceStateRequest(cb)
    if self._Model:GetReviewIsShown() then
        if cb then
            cb(false)
        end
        return
    end
    XNetwork.Call("SetReviewSlapFaceStateRequest", { ActivityId = self._Model:GetActivityId()}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetReviewIsShown(true)
        if cb then
            cb(true)
        end
    end)
end
--endregion


return XAnniversaryAgency