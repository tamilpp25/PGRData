---@class XViewModelTransfinite
local XViewModelTransfinite = XClass(nil, "XViewModelTransfinite")

function XViewModelTransfinite:Ctor()
    self.Data = {
        --Name = false,
        RegionName = false,
        RegionLevel = false,
        RegionColor = false,
        Time = false,
        ScoreIcon = false,
        ScoreNumber = false,
        ScoreNumber2 = false,
        ScoreRatio = 0,
        ScoreReward = false,
        NextScoreReward = false,
        NextChallengeReward = false,
        NextScoreRewardReceived = false,
        NextChallengeRewardReceived = false,

        ImgScore = false,
        RedPointRecord = false,

        Background = false,
        AchievementAmount = false,
        AchievementProgress = 0,
        AchievementReward = false,

        TextWinAmount = false,
        WinAmount = 0,
        StageAmount = 0,
        IsShowWinAmount = false,
        StageGroupName = false,

        IslandName = false,
        IslandIcon = false,
        IslandReward = false,

        IsShowIsland = false,
    }

    self.DataIsland = {
        ---@type XViewModelTransfiniteDataIsland[]
        DataSource = false,
        BackgroundStageGroup = false
    }

    ---@type XTransfiniteStageGroup
    self._StageGroup = XDataCenter.TransfiniteManager.GetStageGroup()

    ---@type XTransfiniteRegion
    self._Region = XDataCenter.TransfiniteManager.GetRegion()

    self._NewRecordKey = "TransfiniteRecord" .. XPlayer.Id
    self._NewRecordTime = XSaveTool.GetData(self._NewRecordKey) or math.huge
end

function XViewModelTransfinite:SetStageGroup(stageGroup)
    self._StageGroup = stageGroup
end

function XViewModelTransfinite:Update()
    local data = self.Data
    local stageGroup = self._StageGroup
    local region = self._Region

    --data.Name = stageGroup:GetName()
    data.RegionName = region:GetName()
    local levelMin = region:GetMinLv()
    local levelMax = region:GetMaxLv()
    data.RegionLevel = XUiHelper.GetText("TransfiniteLevel", levelMin, levelMax)
    data.RegionIconLv = region:GetIconLv()
    data.RegionColor = region:GetColor()

    local itemId = XDataCenter.ItemManager.ItemId.TransfiniteScore
    data.ScoreIcon = XDataCenter.ItemManager.GetItemIcon(itemId)
    local amount = XDataCenter.ItemManager.GetCount(itemId)
    local limit = XDataCenter.ItemManager.GetMaxCount(itemId)
    data.ScoreNumber = amount
    data.ScoreNumber2 = "/" .. limit
    if limit <= 0 then
        data.ScoreRatio = 0
    else
        data.ScoreRatio = amount / limit
    end
    data.ScoreReward = XDataCenter.TransfiniteManager.IsRewardScoreAchieved()
            or XDataCenter.TransfiniteManager.IsRewardChallengeAchieved()

    --周期奖励: 奖励内容抽取下一个未领取的积分与挑战任务图标显示，若全都领取了则显示最后一个
    -- 积分奖励
    local rewardScore
    local rewardList = region:GetScoreRewardIdCanReceive()
    local rewardId = rewardList[1]
    if rewardId then
        rewardScore = XRewardManager.GetRewardList(rewardId)[1]
    else
        local scoreArray, rewardIdArray = region:GetScoreAndRewardArray()
        for i = 1, #rewardIdArray do
            if not region:IsRewardReceived(i) then
                rewardId = rewardIdArray[i]
                break
            end
        end
        if not rewardId then
            rewardId = rewardIdArray[#rewardIdArray]
        end
        if rewardId then
            rewardScore = XRewardManager.GetRewardList(rewardId)[1]
        end
    end
    data.NextScoreReward = rewardScore
    data.NextScoreRewardReceived = region:IsAllScoreRewardReceived()

    local rewardChallenge
    -- 挑战奖励
    -- 优先, 可领取奖励
    local taskGroupId = region:GetChallengeTaskGroupId()
    local taskIdList = XTransfiniteConfigs.GetTaskTaskIds(taskGroupId)
    local taskDataList = XDataCenter.TaskManager.GetTaskIdListData(taskIdList, false)
    for i = 1, #taskDataList do
        local taskData = taskDataList[i]
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            rewardChallenge = XDataCenter.TransfiniteManager.GetRewardByTaskId(taskData.Id, 1)
            break
        end
    end
    -- 然后, 未完成
    if not rewardChallenge then
        for i = 1, #taskDataList do
            local taskData = taskDataList[i]
            if taskData.State == XDataCenter.TaskManager.TaskState.Accepted
                    or taskData.State == XDataCenter.TaskManager.TaskState.Active
            then
                rewardChallenge = XDataCenter.TransfiniteManager.GetRewardByTaskId(taskData.Id, 1)
                break
            end
        end
    end
    -- 都完成了, 显示最后一个
    if not rewardChallenge then
        local lastTaskId = taskIdList[#taskIdList]
        rewardChallenge = XDataCenter.TransfiniteManager.GetRewardByTaskId(lastTaskId, 1)
    end
    data.NextChallengeReward = rewardChallenge
    data.NextChallengeRewardReceived = region:IsAllChallengeRewardReceived()

    data.ImgScore = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.TransfiniteScore)
    data.RedPointRecord = self:IsNewRecord()

    data.Background = stageGroup:GetBackground()
    local achievementAmount, achievementAmountMax = stageGroup:GetAchievementProgress()
    data.AchievementAmount = string.format("<size=52>%d</size>/%d", achievementAmount, achievementAmountMax)
    if achievementAmountMax == 0 then
        data.AchievementProgress = 0
    else
        data.AchievementProgress = achievementAmount / achievementAmountMax
    end
    data.AchievementReward = XDataCenter.TransfiniteManager.IsRewardAchievementAchieved()

    local winAmount = stageGroup:GetStageAmountClear()
    local stageAmount = stageGroup:GetStageAmount()
    data.TextWinAmount = winAmount .. "/" .. stageAmount
    data.WinAmount = winAmount
    data.StageAmount = stageAmount
    data.IsShowWinAmount = stageGroup:IsBegin()
    data.StageGroupName = stageGroup:GetName()

    --local islandGroup = self._IslandGroup
    --local firstIsland = islandGroup:GetStage(1)
    --data.IslandName = firstIsland:GetName()
    --data.IslandIcon = firstIsland:GetBackground()
    --data.IslandReward = islandGroup:IsRewardCanGet()

    local islandGroupIdArray = self._Region:GetIslandStageGroupIdArray()
    if islandGroupIdArray then
        data.IsShowIsland = #islandGroupIdArray > 0
    else
        data.IsShowIsland = false
    end
end

function XViewModelTransfinite:UpdateTime()
    local endTime = XDataCenter.TransfiniteManager.GetEndTime()
    local time = XTime.GetServerNowTimestamp()
    local remainTime = endTime - time
    if remainTime < 0 then
        remainTime = 0
        XDataCenter.TransfiniteManager.CloseUi()
        return
    end
    local timeStr = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
    self.Data.Time = XUiHelper.GetText("TransfiniteTime", timeStr)
end

function XViewModelTransfinite:UpdateIsland()
    local data = self.DataIsland
    local dataSource = {}
    data.DataSource = dataSource
    local groupIdArray = self._Region:GetIslandStageGroupIdArray()
    for i = 1, #groupIdArray do
        local groupId = groupIdArray[i]
        local stageGroup = XDataCenter.TransfiniteManager.GetStageGroup(groupId)
        if stageGroup then
            local amountClear = stageGroup:GetStageAmountClear()
            local amount = stageGroup:GetStageAmount()
            local achievementProgress, achievementAllCount = stageGroup:GetAchievementProgress()
            local progress
            if amount == 0 then
                progress = 0
            else
                progress = amountClear / amount
            end
            ---@class XViewModelTransfiniteDataIsland
            local dataIsland = {
                Name = stageGroup:GetName(),
                Icon = stageGroup:GetIcon(),
                TextProgress = amountClear .. "/" .. amount,
                Progress = progress,
                AchievementAmount = achievementProgress .. "/" .. achievementAllCount,
                IsEnableReward = false,
                StageGroup = stageGroup,
            }
            dataSource[#dataSource + 1] = dataIsland
        end
    end
end

function XViewModelTransfinite:GetStageGroup()
    return self._StageGroup
end

function XViewModelTransfinite:GetMedal()
    local XTransfiniteMedal = require("XEntity/XTransfinite/XTransfiniteMedal")
    ---@type XTransfiniteMedal
    local medal = XTransfiniteMedal.New()
    medal:SetTime(self._StageGroup:GetBestClearTime())
    return medal
end

function XViewModelTransfinite:GetHelpKey()
    return "Transfinite"
end

function XViewModelTransfinite:OnClickRecord()
    local stageGroup = self:GetStageGroup()
    local bestTime = stageGroup:GetBestClearTime()
    if bestTime <= 0 then
        XUiManager.TipText("SSBStageNotClear")
        return
    end
    if bestTime < self._NewRecordTime then
        XSaveTool.SaveData(self._NewRecordKey, bestTime)
        self._NewRecordTime = bestTime
        self.Data.RedPointRecord = false
    end
    XLuaUiManager.Open("UiTransfiniteBestTime", self:GetMedal())
end

function XViewModelTransfinite:IsNewRecord()
    local recordTime = self._NewRecordTime
    local stageGroup = self:GetStageGroup()
    local bestTime = stageGroup:GetBestClearTime()
    if bestTime < recordTime and bestTime > 0 then
        return true
    end
    return false
end

return XViewModelTransfinite
