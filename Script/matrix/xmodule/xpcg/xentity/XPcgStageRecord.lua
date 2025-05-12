---@class XPcgStageRecord
local XPcgStageRecord = XClass(nil, "XPcgStageRecord")

function XPcgStageRecord:Ctor(stageId)
    -- 关卡Id
    ---@type number
    self.StageId = stageId
    -- 历史最高积分
    ---@type number
    self.Score = 0
    -- 历史最高星数
    ---@type number
    self.Stars = 0
    -- 怪物波次
    ---@type number
    self.MonsterLoop = 0
    -- 是否是新记录
    ---@type boolean
    self.IsNew = false
end

function XPcgStageRecord:RefreshData(data)
    self.IsNew = false
    if data.Stars > self.Stars or data.Score > self.Score then
        self.Score = data.Score or 0
        self.Stars = data.Stars or 0
        self.MonsterLoop = data.MonsterLoop or 0
        self.IsNew = true
    end
end

function XPcgStageRecord:GetScore()
    return self.Score
end

function XPcgStageRecord:GetStars()
    return self.Stars
end

function XPcgStageRecord:GetMonsterLoop()
    return self.MonsterLoop
end

function XPcgStageRecord:GetIsNew()
    return self.IsNew
end

return XPcgStageRecord
