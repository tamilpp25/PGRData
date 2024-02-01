---@class XAccumulateExpendControl : XControl
---@field private _Model XAccumulateExpendModel
local XAccumulateExpendControl = XClass(XControl, "XAccumulateExpendControl")
local XAccumulateExpendReward = require("XModule/XAccumulateExpend/XEntity/XAccumulateExpendReward")
local XAccumulateExpendRuler = require("XModule/XAccumulateExpend/XEntity/XAccumulateExpendRuler")

function XAccumulateExpendControl:OnInit()
    -- 初始化内部变量
    ---@type XAccumulateExpendReward[]
    self._RewardList = nil
    ---@type XAccumulateExpendRuler[]
    self._RulerList = nil
    self:RefreshRewardList()
end

function XAccumulateExpendControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XAccumulateExpendControl:RemoveAgencyEvent()

end

function XAccumulateExpendControl:OnRelease()
    self._RewardList = nil
    -- XLog.Error("这里执行Control的释放")
end

function XAccumulateExpendControl:GetCurrentRewardIndex()
    local rewardList = self:GetRewardList()

    for i, reward in pairs(rewardList) do
        if reward:IsAchieved() then
            return i
        end
    end
    for i, reward in pairs(rewardList) do
        if not reward:IsFinish() then
            return i
        end
    end

    return #rewardList
end

function XAccumulateExpendControl:GetCurrentRewardCount()
    local rewardList = self:GetRewardList()

    for i, reward in pairs(rewardList) do
        if not reward:IsComplete() then
            if i == #rewardList then
                local progress = rewardList[i]:GetProgress()
                local count = rewardList[i]:GetItemCount()

                if progress >= count then
                    return XUiHelper.GetText("AccumulateExpendMaxProgress", count)
                else
                    return progress
                end
            else
                return reward:GetProgress()
            end
        end
    end

    return XUiHelper.GetText("AccumulateExpendMaxProgress", rewardList[#rewardList]:GetItemCount())
end

function XAccumulateExpendControl:GetNextSpecialReward(index)
    local rewardList = self:GetRewardList()
    local length = self:GetRewardCount()
    local reward = nil

    index = index or self:GetCurrentRewardIndex()

    if index <= length then
        for i = index, length do
            if rewardList[i]:IsSpecialShow() then
                reward = rewardList[i]
                break
            end
        end
    end

    return reward
end

function XAccumulateExpendControl:GetAtLastSpecialRewardIndex()
    local rewardList = self:GetRewardList()

    for i = #rewardList, 1, -1 do
        if rewardList[i]:IsSpecialShow() then
            return i
        end
    end

    return 0
end

function XAccumulateExpendControl:GetItemId()
    local activityId = self._Model:GetActivityId()

    return self._Model:GetActivityItemIdById(activityId)
end

function XAccumulateExpendControl:GetItemIcon()
    local activityId = self._Model:GetActivityId()

    return self._Model:GetActivityItemIconById(activityId)
end

function XAccumulateExpendControl:GetEndTime()
    local activityId = self._Model:GetActivityId()
    local timeId = self._Model:GetActivityTimeIdById(activityId)

    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XAccumulateExpendControl:GetStartTime()
    local activityId = self._Model:GetActivityId()
    local timeId = self._Model:GetActivityTimeIdById(activityId)

    return XFunctionManager.GetStartTimeByTimeId(timeId)
end

function XAccumulateExpendControl:GetEndTimeStr()
    local time = 0
    
    if self:GetAgency():CheckIsOpen() then
        local endTime = self:GetEndTime()
        local nowTime = XTime.GetServerNowTimestamp()
        
        time = endTime - nowTime
    end
    
    return XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ACTIVITY)
end

function XAccumulateExpendControl:AutoCloseHandler(isClose)
    if isClose then
        XUiManager.TipText("CommonActivityEnd")
        XLuaUiManager.RunMain()
    end
end

---@return XAccumulateExpendReward[]
function XAccumulateExpendControl:GetRewardList(isForceRefresh)
    if not self._RewardList or isForceRefresh then
        self:RefreshRewardList()
    end

    return self._RewardList
end

function XAccumulateExpendControl:GetRewardCount()
    local rewardList = self:GetRewardList()

    if XTool.IsTableEmpty(rewardList) then
        return 0
    end

    return #rewardList
end

function XAccumulateExpendControl:RefreshRewardList()
    local configs = self._Model:GetRewardConfigs()
    self._RewardList = {}

    for i, config in pairs(configs) do
        local reward = self._RewardList[i]

        if not reward then
            self._RewardList[i] = XAccumulateExpendReward.New(config.TaskId, config.IsSpecialShow, config.IsMainReward)
        else
            reward:SetData(config.TaskId, config.IsSpecialShow, config.IsMainReward)
        end
    end
end

function XAccumulateExpendControl:ReceiveAllReward()
    local rewardList = self:GetRewardList()
    local taskIds = {}

    for i, reward in pairs(rewardList) do
        if reward:IsAchieved() then
            taskIds[#taskIds + 1] = reward:GetTaskId()
        end
    end

    if not XTool.IsTableEmpty(taskIds) then
        XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, function(goodsList)
            XUiManager.OpenUiObtain(goodsList)
        end)
    end
end

---@return XAccumulateExpendRuler[]
function XAccumulateExpendControl:GetRulerList()
    if not self._RulerList then
        local activityId = self._Model:GetActivityId()
        local rulerTitles = self._Model:GetActivityBaseRuleTitlesById(activityId)
        local rulers = self._Model:GetActivityBaseRulesById(activityId)
        local count = math.min(#rulerTitles, #rulers)

        self._RulerList = {}
        for i = 1, count do
            self._RulerList[i] = XAccumulateExpendRuler.New(rulerTitles[i], rulers[i])
        end
    end

    return self._RulerList
end

function XAccumulateExpendControl:CheckAllFinish()
    local rewardList = self:GetRewardList()

    for _, reward in pairs(rewardList) do
        if not reward:IsFinish() then
            return false
        end
    end

    return true
end

return XAccumulateExpendControl
