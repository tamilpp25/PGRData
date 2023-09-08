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
        DisplayReward = {},

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
    local displayRewardList = region:GetRewardIds()

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

    local isAllReceive = region:IsAllScoreRewardReceived() and region:IsAllChallengeRewardReceived()
    for i = 1, #displayRewardList do
        local reward = {
            Item = XRewardManager.GetRewardList(displayRewardList[i])[1],
            IsReceived = isAllReceive,
        }
        
        data.DisplayReward[i] = reward
    end

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
    data.IslandReward = false
    --local islandGroup = self._IslandGroup
    --local firstIsland = islandGroup:GetStage(1)
    --data.IslandName = firstIsland:GetName()
    --data.IslandIcon = firstIsland:GetBackground()
    --data.IslandReward = islandGroup:IsRewardCanGet()

    local islandGroupIdArray = self._Region:GetIslandStageGroupIdArray()
    if islandGroupIdArray then
        data.IsShowIsland = #islandGroupIdArray > 0
        for i = 1, #islandGroupIdArray do
            local islandStageGroup = XDataCenter.TransfiniteManager.GetStageGroup(islandGroupIdArray[i])

            if islandStageGroup:IsAchievementAchieved() then
                data.IslandReward = true
            end
        end 
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
    local islandImage = XTransfiniteConfigs.GetIslandImage(self._Region:GetIslandId())
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
                IsEnableReward = stageGroup:IsAchievementAchieved(),
                StageGroup = stageGroup,
                IslandImage = islandImage,
            }
            dataSource[#dataSource + 1] = dataIsland
        end
    end
end

function XViewModelTransfinite:GetStageGroup()
    return self._StageGroup
end

function XViewModelTransfinite:GetMedal(stageGroup)
    stageGroup = stageGroup or self._StageGroup
    local XTransfiniteMedal = require("XEntity/XTransfinite/XTransfiniteMedal")
    ---@type XTransfiniteMedal
    local medal = XTransfiniteMedal.New()
    medal:SetTime(stageGroup:GetBestClearTime())
    return medal
end

function XViewModelTransfinite:GetHelpKey()
    return "Transfinite"
end

function XViewModelTransfinite:OnClickRecord(stageGroup)
    stageGroup = stageGroup or self:GetStageGroup()
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
    XLuaUiManager.Open("UiTransfiniteBestTime", self:GetMedal(stageGroup))
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
