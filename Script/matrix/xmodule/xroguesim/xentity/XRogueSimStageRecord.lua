---@class XRogueSimStageRecord
local XRogueSimStageRecord = XClass(nil, "XRogueSimStageRecord")

function XRogueSimStageRecord:Ctor()
    -- 关卡id
    self.StageId = 0
    -- 最高分数
    self.MaxPoint = 0
    -- 星级奖励领取Mask
    self.StarMask = 0
    -- 通关次数
    self.FinishedTimes = 0
end

function XRogueSimStageRecord:UpdateRecordData(data)
    self.StageId = data.StageId or 0
    self.MaxPoint = data.MaxPoint or 0
    self.StarMask = data.StarMask or 0
    self.FinishedTimes = data.FinishedTimes or 0
end

-- 获取最高分数
function XRogueSimStageRecord:GetMaxPoint()
    return self.MaxPoint
end

-- 获取星级奖励领取Mask
function XRogueSimStageRecord:GetStarMask()
    return self.StarMask
end

-- 获取通关次数
function XRogueSimStageRecord:GetFinishedTimes()
    return self.FinishedTimes
end

return XRogueSimStageRecord
