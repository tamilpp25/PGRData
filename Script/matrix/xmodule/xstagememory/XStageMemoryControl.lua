---@class XStageMemoryControl : XControl
---@field private _Model XStageMemoryModel
local XStageMemoryControl = XClass(XControl, "XStageMemoryControl")

function XStageMemoryControl:OnInit()
    XMVCA.XStageMemory:SetHasViewedToday()
    self._Data = {
        RemainTime = 0,
        ---@type XStageMemoryControlStage[]
        Stages = {},
        ---@type XStageMemoryControlReward[]
        Rewards = {},
        PassedStageAmount = 0,
        StageAmount = 0,
        IsInit = false,
    }
end

function XStageMemoryControl:AddAgencyEvent()
    self:UpdateTime()
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTime()
        end, XScheduleManager.SECOND)
    end
end

function XStageMemoryControl:RemoveAgencyEvent()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XStageMemoryControl:OnRelease()
end

function XStageMemoryControl:GetUiData()
    return self._Data
end

function XStageMemoryControl:InitUiData()
    ---@type XTable.XTableStageMemoryActivity
    local activityConfig = self._Model:GetActivityConfig()
    if not activityConfig then
        XLog.Error("[XStageMemoryControl] 找不到活动配置")
        return
    end
    local stages = activityConfig.StageIds
    self._Data.StageAmount = #stages
    for i = 1, #stages do
        local stageId = stages[i]
        ---@type XTable.XTableStageMemoryShow
        local stageConfig = self._Model:GetStageConfig(stageId)
        if stageConfig then
            ---@class XStageMemoryControlStage
            local stageData = {
                Index = i,
                Name = stageConfig.Name,
                Desc = stageConfig.Desc,
                DescDetail = stageConfig.DescDetail,
                Id = stageId,
                TimeId = activityConfig.StageTimeIds[i]
            }
            self._Data.Stages[i] = stageData
        else
            XLog.Error("[XStageMemoryControl] 该关卡未配置StageMemoryShow.tab:" .. stageId)
            local stageData = {
                Index = i,
                Name = "",
                Desc = "",
                Id = stageId,
                IsUnlock = false
            }
            self._Data.Stages[i] = stageData
        end
    end

    local rewards = self._Data.Rewards
    local requireStageAmount = activityConfig.RequireStages
    local rewardIds = activityConfig.RewardIds
    local maxStageAmount = 0
    for i = 1, #rewardIds do
        local rewardId = rewardIds[i]
        local stageAmount = requireStageAmount[i]
        if not stageAmount then
            stageAmount = 0
            XLog.Error("[XStageMemoryControl] StageMemoryActivity.tab表, RequireStages和Rewards的数组长度不相等:" .. i)
        end
        ---@class XStageMemoryControlReward
        local reward = {
            Index = i,
            Rewards = XRewardManager.GetRewardList(rewardId),
            StageAmount = stageAmount,
            IsEmpty = false,
            RewardId = rewardId,
        }
        rewards[stageAmount] = reward
        if stageAmount > maxStageAmount then
            maxStageAmount = stageAmount
        end
    end

    for i = 1, maxStageAmount do
        if not rewards[i] then
            rewards[i] = {
                Index = i,
                IsEmpty = true,
            }
        end
    end
end

function XStageMemoryControl:UpdateUiData()
    if not self._Data.IsInit then
        self:InitUiData()
        self._Data.IsInit = true
    end

    local passedStageAmount = 0
    local stages = self._Data.Stages
    for i = 1, #stages do
        ---@type XStageMemoryControlStage
        local stage = stages[i]
        stage.IsUnlock = XFunctionManager.CheckInTimeByTimeId(stage.TimeId)
        local isPassed = XMVCA.XFuben:CheckStageIsPass(stage.Id)
        stage.IsPassed = isPassed
        if isPassed and stage.IsUnlock then
            passedStageAmount = passedStageAmount + 1
        end
    end
    self._Data.PassedStageAmount = passedStageAmount

    local rewards = self._Data.Rewards
    for i = 1, #rewards do
        ---@type XStageMemoryControlReward
        local reward = rewards[i]
        if not reward.IsEmpty then
            reward.IsReceived = self._Model:IsRewardReceived(reward.Index)
            reward.IsCanReceive = passedStageAmount >= reward.StageAmount
        end
    end
    self:UpdateTime()
end

function XStageMemoryControl:UpdateTime()
    local config = self._Model:GetActivityConfig()
    if not config then
        XLuaUiManager.Close("UiStageMemory")
        XLog.Error("[XStageMemoryControl] 找不到活动配置")
        return
    end
    local timeId = config.TimeId
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local currentTime = XTime.GetServerNowTimestamp()
    local remainTime = endTime - currentTime
    if remainTime <= 0 then
        self._Data.RemainTime = 0
        XLuaUiManager.Close("UiStageMemory")
    else
        self._Data.RemainTime = remainTime
        XEventManager.DispatchEvent(XEventId.EVENT_STAGE_MEMORY_UPDATE_TIME)
    end

    local stages = self._Data.Stages
    for i = 1, #stages do
        local stage = stages[i]
        stage.IsUnlock = XFunctionManager.CheckInTimeByTimeId(stage.TimeId)
    end
end

---@param data XStageMemoryControlStage
function XStageMemoryControl:EnterFight(data)
    if not data.IsUnlock then
        return
    end
    if not data.Id then
        XLog.Error("[XStageMemoryControl] 进入战斗失败，找不到对应的关卡配置")
        return
    end
    local stage = XMVCA.XFuben:GetStageCfg(data.Id)
    if stage then
        XMVCA.XFuben:EnterFight(stage, 0)
    else
        XLog.Error("[XStageMemoryControl] 进入战斗失败，找不到对应的关卡配置:" .. data.Id)
    end
end

---@param data XStageMemoryControlReward
function XStageMemoryControl:ReceiveReward(data)
    XMVCA.XStageMemory:RequestStageChoiceGetReward(data.Index)
end

return XStageMemoryControl