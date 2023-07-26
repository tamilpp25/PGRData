local RewardState = XTransfiniteConfigs.RewardState

---@class XViewModelTransfiniteGift
local XViewModelTransfiniteGift = XClass(nil, "XViewModelTransfiniteGift")

local TableSort = table.sort
local TableInsert = table.insert

local function TaskSortFunc(taskA, taskB)
    if taskA.State ~= taskB.State then
        local TaskState = XDataCenter.TaskManager.TaskState
        if taskA.State == TaskState.Finish then
            return false
        end
        if taskB.State == TaskState.Finish then
            return true
        end
        return taskA.State > taskB.State
    end
    return taskA.Id < taskB.Id
end

function XViewModelTransfiniteGift:Ctor()
    self._TabIndex = XTransfiniteConfigs.GiftTabIndex.Score

    self._DataScoreTitle = {
        RegionTitle = false,
        RegionLvText = false,
        RegionIconLv = false,

        Progress = 0,
        TxtProgress = false,
    }

    self._DataScore = {
        ---@type XTransfiniteGridRewardSource[]
        DataSource = {},
        StartIndex = 1,
        IsJustOpen = true,
    }

    self._DataChallenge = {
        ChallengeTaskGroupId = nil,
        FinishChallengeTaskIdList = {},
        DataSource = {}
    }
end

--region score
function XViewModelTransfiniteGift:UpdateScoreTitle()
    local data = self._DataScoreTitle
    local region = XDataCenter.TransfiniteManager.GetRegion()
    if not region then
        return
    end

    local minLv = region:GetMinLv()
    local maxLv = region:GetMaxLv()
    data.RegionTitle = region:GetName()
    data.RegionLvText = "Lv" .. minLv .. "~" .. maxLv
    data.RegionIconLv = region:GetIconLv()
    local score = XDataCenter.TransfiniteManager.GetScore()
    local limit = XDataCenter.TransfiniteManager.GetScoreLimit()
    data.Progress = score / limit
    data.TxtProgress = score .. "/" .. limit
end

function XViewModelTransfiniteGift:GetDataScoreTitle()
    return self._DataScoreTitle
end

function XViewModelTransfiniteGift:UpdateScore()
    local data = self._DataScore

    local region = XDataCenter.TransfiniteManager.GetRegion()
    local scoreArray, reward = region:GetScoreAndRewardArray()
    local scoreCurrent = XDataCenter.TransfiniteManager.GetScore()
    local length = #reward

    data.DataSource = {}
    for i = 1, length do
        local rewardData = self:_GetDataGridScore(region, i, scoreArray, reward, scoreCurrent)

        ---@class XTransfiniteGridRewardSource
        local dataSource = {
            ---@type XTransfiniteScoreReward
            Reward = rewardData,
        }
        data.DataSource[i] = dataSource
    end

    if data.IsJustOpen then
        for i = 1, length do
            local dataScore = data.DataSource[i]
            if dataScore.Reward.RewardState == RewardState.Active then
                data.StartIndex = i
                break
            end
        end
        for i = 1, length do
            local dataScore = data.DataSource[i]
            if dataScore.Reward.RewardState == RewardState.Achieved then
                data.StartIndex = i
                break
            end
        end
        data.IsJustOpen = false
    else
        data.StartIndex = nil
    end
end

---@param region XTransfiniteRegion
function XViewModelTransfiniteGift:_GetDataGridScore(region, index, scoreArray, rewardArray, scoreCurrent)
    local rewardId = rewardArray[index]
    local rewardList = XRewardManager.GetRewardList(rewardId)
    local score = scoreArray[index]

    local state
    if region:IsRunning() then
        if region:IsRewardReceived(index) then
            state = RewardState.Finish
        elseif scoreCurrent >= score then
            state = RewardState.Achieved
        else
            state = RewardState.Active
        end
    else
        state = RewardState.Lock
    end

    ---@class XTransfiniteScoreReward
    local scoreData = {
        Index = index,
        Desc = score,
        Reward = rewardList[1],
        RewardState = state,
    }
    return scoreData
end

function XViewModelTransfiniteGift:GetDataScoreReward()
    return self._DataScore
end

--endregion score

--region challenge
function XViewModelTransfiniteGift:GetChallengeRewardFinishTaskList()
    return self._DataChallenge.FinishChallengeTaskIdList
end

function XViewModelTransfiniteGift:GetChallengeDataList()
    local data = self._DataChallenge
    if not data.ChallengeTaskGroupId then
        local region = XDataCenter.TransfiniteManager.GetRegion()
        data.ChallengeTaskGroupId = region:GetChallengeTaskGroupId()
    end

    local challengeTaskIdList = XTransfiniteConfigs.GetTaskTaskIds(data.ChallengeTaskGroupId)
    local taskDataList = XDataCenter.TaskManager.GetTaskIdListData(challengeTaskIdList, false)
    local challengeDataList = {}

    data.FinishChallengeTaskIdList = {}

    for i = 1, #taskDataList do
        local state = taskDataList[i].State

        if state == XDataCenter.TaskManager.TaskState.Finish
                or state == XDataCenter.TaskManager.TaskState.Active
                or state == XDataCenter.TaskManager.TaskState.Accepted
                or state == XDataCenter.TaskManager.TaskState.Achieved
        then
            if state == XDataCenter.TaskManager.TaskState.Achieved then
                data.FinishChallengeTaskIdList[#data.FinishChallengeTaskIdList + 1] = taskDataList[i].Id
            end

            challengeDataList[#challengeDataList + 1] = taskDataList[i]
        end
    end

    TableSort(challengeDataList, TaskSortFunc)

    -- 一键领取
    if data.FinishChallengeTaskIdList and #data.FinishChallengeTaskIdList ~= 0 then
        local taskData = { ReceiveAll = true, AllAchieveTaskDatas = self:GetChallengeRewardFinishTaskList() }

        TableInsert(challengeDataList, 1, taskData)
    end

    return challengeDataList
end
--endregion challenge

function XViewModelTransfiniteGift:GetTabIndex()
    return self._TabIndex
end

function XViewModelTransfiniteGift:SetTabIndex(index)
    self._TabIndex = index
end

function XViewModelTransfiniteGift:OnClickOpenRoom()
    local stageGroup = XDataCenter.TransfiniteManager.GetStageGroup()
    XLuaUiManager.Open("UiTransfiniteBattlePrepare", stageGroup)
end

function XViewModelTransfiniteGift:OnClickReceiveAllScoreReward()
    XDataCenter.TransfiniteManager.RequestReceiveAllScoreReward()
end

function XViewModelTransfiniteGift:IsShowRedDotScore()
    return XDataCenter.TransfiniteManager.IsRewardScoreAchieved()
end

function XViewModelTransfiniteGift:IsShowRedDotChallenge()
    return XDataCenter.TransfiniteManager.IsRewardChallengeAchieved()
end

return XViewModelTransfiniteGift