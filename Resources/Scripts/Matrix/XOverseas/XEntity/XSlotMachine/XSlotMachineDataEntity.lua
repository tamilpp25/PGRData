local XSlotMachineDataEntity = XClass(nil, "XSlotMachineDataEntity")
local tableRemove = table.remove
local tableInsert = table.insert

local Default = {
    -- Client
    Id = 0,
    Tmp = {}, -- 配置数据
    -- Sever
    RockTimes = 0, -- 摇奖次数
    TotalScore = 0, -- 当前积分
    RecvIndex = {}, -- 已领取奖励下标
    SlotMachineRecords = {}, -- 抽奖记录
}

function XSlotMachineDataEntity:Ctor(template, slotMachineData)
    for key in pairs(Default) do
        self[key] = Default[key]
    end

    if template then
        self.Tmp = template
        self.Id = template.Id
    end

    self:RefreshItem(slotMachineData)
end

function XSlotMachineDataEntity:RefreshItem(slotMachineData)
    if not slotMachineData then
        return
    end

    if slotMachineData.RockTimes then
        self.RockTimes = slotMachineData.RockTimes
    end

    if slotMachineData.TotalScore then
        self.TotalScore = slotMachineData.TotalScore
    end

    if slotMachineData.RecvIndex then
        self.RecvIndex = slotMachineData.RecvIndex
    end

    if slotMachineData.SlotMachineRecords then
        self.SlotMachineRecords = slotMachineData.SlotMachineRecords
    end
end

-- Begain Get
-- Client
function XSlotMachineDataEntity:GetId()
    return self.Id
end

function XSlotMachineDataEntity:GetName()
    return self.Tmp.Name
end

function XSlotMachineDataEntity:GetConsumeItemId()
    return self.Tmp.ConsumeItemId
end

function XSlotMachineDataEntity:GetConsumeCount()
    return self.Tmp.ConsumeCount
end

function XSlotMachineDataEntity:GetUnlockNeedPreScore()
    return self.Tmp.UnlockNeedPreScore
end

function XSlotMachineDataEntity:GetScoreLimit()
    return self.Tmp.ScoreLimit
end

function XSlotMachineDataEntity:GetBgImage()
    return self.Tmp.BgImage
end

function XSlotMachineDataEntity:GetMachineImage()
    return self.Tmp.MachineImage
end

function XSlotMachineDataEntity:GetMachineLockImage()
    return self.Tmp.MachineLockImage
end

function XSlotMachineDataEntity:GetNextMachineBtnImage()
    return self.Tmp.NextMachineBtnImage
end

function XSlotMachineDataEntity:GetNextMachineBtnText()
    return self.Tmp.NextMachineBtnText
end

function XSlotMachineDataEntity:GetRulesIds()
    return self.Tmp.RulesIds
end

function XSlotMachineDataEntity:GetIcons()
    return self.Tmp.Icons
end

function XSlotMachineDataEntity:GetRewardIds()
    return self.Tmp.RewardIds
end

function XSlotMachineDataEntity:GetRewardScores()
    return self.Tmp.RewardScores
end

function XSlotMachineDataEntity:GetPrixBottomTimes()
    return self.Tmp.PrixBottomTimes
end

function XSlotMachineDataEntity:GetTaskDailyLimitId()
    return self.Tmp.TaskDailyLimitId
end

function XSlotMachineDataEntity:GetTaskCumulativeLimitId()
    return self.Tmp.TaskCumulativeLimitId
end

-- Sever
function XSlotMachineDataEntity:GetRockTimes()
    return self.RockTimes
end

function XSlotMachineDataEntity:GetTotalScore()
    return self.TotalScore
end

function XSlotMachineDataEntity:GetRecvIndex()
    return self.RecvIndex
end

function XSlotMachineDataEntity:GetSlotMachineRecords()
    return self.SlotMachineRecords
end
-- End Get

-- Begain Set
function XSlotMachineDataEntity:SetRockTimes(rockTimes)
    self.RockTimes = rockTimes
end

function XSlotMachineDataEntity:SetTotalScore(totalScore)
    self.TotalScore = totalScore
end

function XSlotMachineDataEntity:SetSlotMachineRecords(slotMachineRecords)
    self.SlotMachineRecords = slotMachineRecords
end

function XSlotMachineDataEntity:SetRecvIndex(index)
    tableInsert(self.RecvIndex, index)
end
-- End Set

return XSlotMachineDataEntity