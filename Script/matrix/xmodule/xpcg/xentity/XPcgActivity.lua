---@class XPcgActivity
local XPcgActivity = XClass(nil, "XPcgActivity")

function XPcgActivity:Ctor()
    -- 活动Id
    ---@type number
    self.ActivityId = 0
    -- 已完解锁角色Id哈希表
    ---@type table<number, boolean>
    self.UnlockCharacterDic = {}
    -- 关卡记录
    ---@type XPcgStageRecord[]
    self.Stages = {}
end

function XPcgActivity:PcgStagesNotify(data)
    self.ActivityId = data.ActivityId or 0
    self.UnlockCharacterDic = {}
    if data.Characters then
        for _, charId in pairs(data.Characters) do
            self.UnlockCharacterDic[charId] = true
        end
    end
    self.Stages = {}
    if data.Stages then
        for stageId, stageData in pairs(data.Stages) do
            self:RefreshStageRecord(stageId, stageData)
        end
    end
end

-- 刷新关卡记录
function XPcgActivity:RefreshStageRecord(stageId, stageData)
    if not stageData then return end
    local stage = self.Stages[stageId]
    if not stage then
        local XPcgStageRecord = require("XModule/XPcg/XEntity/XPcgStageRecord")
        stage = XPcgStageRecord.New(stageId)
        self.Stages[stageId] = stage
    end
    stage:RefreshData(stageData)
end

-- 收到新角色解锁
function XPcgActivity:OnCharacterUnlockNotify(newCharacterIds)
    if newCharacterIds then
        for _, charId in pairs(newCharacterIds) do
            self.UnlockCharacterDic[charId] = true
        end
    end
end

--region 获取数据接口
function XPcgActivity:GetActivityId()
    return self.ActivityId
end

-- 角色是否解锁
function XPcgActivity:IsCharacterUnlock(characterId)
    return self.UnlockCharacterDic[characterId] == true
end

-- 获取关卡记录
---@return XPcgStageRecord
function XPcgActivity:GetStageRecord(stageId)
    return self.Stages[stageId]
end
--endregion

return XPcgActivity
