---@class XVersionGiftAgency : XAgency
---@field private _Model XVersionGiftModel
local XVersionGiftAgency = XClass(XAgency, "XVersionGiftAgency")
function XVersionGiftAgency:OnInit()
    --初始化一些变量
end

function XVersionGiftAgency:InitRpc()
    XRpc.NotifyVersionGiftActivity  = handler(self, self.OnNotifyVersionGiftActivity)
    XRpc.NotifyGiftRewardUpdate = handler(self, self.OnNotifyGiftRewardUpdate)
end

function XVersionGiftAgency:InitEvent()
    
end

function XVersionGiftAgency:GetIsOpen()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.VersionGift, true, true) then
        local activityId = self._Model:GetCurActivityId()

        if XTool.IsNumberValid(activityId) then
            local timeId = self._Model:GetActivityTimeId(activityId)

            if XTool.IsNumberValid(timeId) then
                return XFunctionManager.CheckInTimeByTimeId(timeId), XUiHelper.GetText('CommonActivityNotStart')
            else
                return true
            end
        end

        return false, XUiHelper.GetText('CommonActivityNotStart')
    else
        return false, XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.VersionGift)
    end
end

function XVersionGiftAgency:OpenUiMain()
    local isOpen, desc = self:GetIsOpen()

    if isOpen then
        XLuaUiManager.Open("UiVersionGift")
    else
        XUiManager.TipMsg(desc)
    end
end

--region ---------- ActivityData --------->>>

function XVersionGiftAgency:CheckAnyTaskGroupContainsFinishableTask()
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        return self._Model:CheckAnyTaskGroupContainsFinishableTaskById(activityId)
    end
end

function XVersionGiftAgency:CheckAnyRewardCanGet()
    --- 版本奖励是否领取
    if not self._Model:GetIsGotVersionGiftReward() then
        return true
    end

    --- 每日奖励是否领取
    if not self._Model:GetIsGotDailyGiftReward() then
        return true
    end
    
    --- 历程奖励是否有可且未领取
    local passCount = self._Model:GetTaskProgress()

    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        local milestones = self._Model:GetProcessTaskCompleteCountsByActivityId(activityId)
        
        local progressRewardGotList = self._Model:GetProgressRewardIndexSet()
        
        if not XTool.IsTableEmpty(milestones) then
            for i, v in pairs(milestones) do
                if v <= passCount and not table.contains(progressRewardGotList, i) then
                    return true
                end
            end
        end
    end
    
    return false
end

--endregion <<<------------------------------

--region ---------- Network ---------->>>

function XVersionGiftAgency:DoVersionGiftGetProgressRewardRequest(type, cb)
    XNetwork.Call("VersionGiftGetRewardRequest", { Type = type }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if cb then
            cb(res.RewardList)
        end
    end)
end

--endregion <<<--------------------------

--region ---------- RPC --------->>>

function XVersionGiftAgency:OnNotifyVersionGiftActivity(data)
    self._Model:RefreshActivityData(data)
end

function XVersionGiftAgency:OnNotifyGiftRewardUpdate(data)
    self._Model:RefreshGiftRewardData(data)
end

--endregion <<<---------------------

return XVersionGiftAgency