local XInvertCardStage = XClass(nil, "XInvertCardStage")
local tableRemove = table.remove
local tableInsert = table.insert

local Default = {
    -- Client
    Id = 0,
    Tmp = {}, -- 配置数据
    -- Sever
    Status = XInvertCardGameConfig.InvertCardGameStageStatusType.Lock, -- 关卡状态
    RandomCardList = {}, -- 卡牌列表
    TotalCounts = 0, -- 累积翻牌次数
    InvertList = {}, -- 已翻牌链表
    Progress = 0, -- 关卡进度
    RewardListIdx = {} -- 奖励进度列表
}

function XInvertCardStage:Ctor(template, stageData)
    for key in pairs(Default) do
        self[key] = Default[key]
    end

    if template then
        self.Tmp = template
        self.Id = template.Id
    end

    self:RefreshItem(stageData)
end

function XInvertCardStage:RefreshItem(stageData)
    if not stageData then
        return
    end

    if stageData.Status then
        self.Status = stageData.Status
    end

    if stageData.RandomCardList then
        self.RandomCardList = stageData.RandomCardList
    end

    if stageData.TotalCounts then
        self.TotalCounts = stageData.TotalCounts
    end

    if stageData.InvertList then
        self.InvertList = stageData.InvertList
    end

    if stageData.Progress then
        self.Progress = stageData.Progress
    end

    if stageData.RewardListIdx then
        self.RewardListIdx = stageData.RewardListIdx
    end
end

-- Begain Get
-- Client
function XInvertCardStage:GetId()
    return self.Id
end

function XInvertCardStage:GetName()
    return self.Tmp.Name
end

function XInvertCardStage:GetRowAndColumnCount()
    return self.Tmp.RowCount, self.Tmp.ColumnCount
end

function XInvertCardStage:GetContainCards()
    return self.Tmp.ContainCards
end

function XInvertCardStage:GetCostCoinNum()
    return self.Tmp.CostCoinNum
end

function XInvertCardStage:GetMaxCostNum()
    return self.Tmp.MaxCostNum
end

function XInvertCardStage:GetTargetNum()
    return self.Tmp.TargetNum
end

function XInvertCardStage:GetFinishProgress()
    return self.Tmp.FinishProgress
end

function XInvertCardStage:GetRewards()
    return self.Tmp.Rewards
end

function XInvertCardStage:GetMaxOnCardsNum()
    return self.Tmp.MaxOnCardsNum
end

function XInvertCardStage:GetFailedPunishNum()
    return self.Tmp.FailedPunishNum
end

function XInvertCardStage:GetClearConditionDesc()
    return self.Tmp.ClearConditionDesc
end

-- Sever
function XInvertCardStage:GetStatus()
    return self.Status
end

function XInvertCardStage:GetRandomCardList()
    return self.RandomCardList
end

function XInvertCardStage:GetTotalCounts()
    return self.TotalCounts
end

function XInvertCardStage:GetInvertList()
    return self.InvertList
end

function XInvertCardStage:GetProgress()
    return self.Progress
end

function XInvertCardStage:GetRewardListIdx()
    return self.RewardListIdx
end
-- End Get

-- Begain Set
function XInvertCardStage:SetProgress(progress)
    self.Progress = progress
end

function XInvertCardStage:SetStatus(status)
    self.Status = status
end

function XInvertCardStage:SetCardFinish(idx)
    self:SetCardPunish(idx)
    self.RandomCardList[idx].IsFinish = true
end

function XInvertCardStage:SetCardPunish(idx)
    for index, invertIdx in ipairs(self.InvertList) do
        if invertIdx == idx then
            tableRemove(self.InvertList, index)
        end
    end
end

function XInvertCardStage:SetCardInvert(idx)
    if self.InvertList then
        tableInsert(self.InvertList, idx)
    end
end

function XInvertCardStage:SetRewardListIdx(rewardListIdx)
    self.RewardListIdx = rewardListIdx
end

function XInvertCardStage:AddTotalCounts()
    if self.TotalCounts then
        self.TotalCounts = self.TotalCounts + 1
    end
end
-- End Set

return XInvertCardStage