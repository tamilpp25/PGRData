---@class XMaverick3Activity
---@field _StageMap XMaverick3StageData[]
---@field _StageSavedMap XMaverick3StageSaved[]
---@field _RankStageInfoMap XMaverick3RankStageInfo[]
---@field _UnlockTalents number[]
local XMaverick3Activity = XClass(nil, "XMaverick3Activity")

function XMaverick3Activity:Ctor()
    self:ResetData()
end

function XMaverick3Activity:ResetData()
    self._StageMap = {}
    self._StageSavedMap = {}
    self._RankStageInfoMap = {}
    self._UnlockTalents = {}
end

function XMaverick3Activity:SetData(data)
    self:ResetData()
    if not XTool.IsTableEmpty(data.StageData) then
        for _, v in pairs(data.StageData) do
            self:UpdateStageData(v)
        end
    end
    self:UpdateTalentData(data.UnlockTalent)
    if not XTool.IsTableEmpty(data.RecordForRanks) then
        for _, v in pairs(data.RecordForRanks) do
            self:UpdateRankData(v)
        end
    end
end

function XMaverick3Activity:UpdateStageData(stageData)
    ---@type XMaverick3StageData
    local stage = {}
    stage.IsPass = stageData.IsPass
    stage.Star = stageData.Star
    stage.BestDeadCount = stageData.BestDeadCount
    stage.BestCostTime = stageData.BestCostTime
    stage.TotalScore = stageData.TotalScore
    self._StageMap[stageData.StageId] = stage

    self:UpdateStageSave(stageData.StageId, stageData.RobotSaved)
end

function XMaverick3Activity:UpdateStageSave(stageId, robotSaved)
    if not robotSaved then
        self._StageSavedMap[stageId] = nil
        return
    end
    ---@type XMaverick3StageSaved
    local saved = {}
    saved.RobotId = robotSaved.RobotId
    saved.Hp = robotSaved.Hp
    saved.MaxHp = robotSaved.MaxHp
    saved.DeadCount = robotSaved.DeadCount
    saved.UltimateSkill = robotSaved.UltimateSkill
    saved.Hangings = robotSaved.Hangings
    saved.BulletCount = robotSaved.BulletCount
    saved.StageProgress = robotSaved.StageProgress
    saved.StageSavePoint = robotSaved.StageSavePoint
    self._StageSavedMap[stageId] = saved
end

function XMaverick3Activity:UpdateTalentData(unlockTalent)
    self._UnlockTalents = unlockTalent
end

function XMaverick3Activity:UpdateRankData(recordForRank)
    ---@type XMaverick3RankStageInfo
    local record = {}
    record.RobotId = recordForRank.RobotId
    record.Hangings = recordForRank.Hangings
    record.UltimateSkill = recordForRank.UltimateSkill
    self._RankStageInfoMap[recordForRank.StageId] = record
end

function XMaverick3Activity:AddUnlockTalent(id)
    table.insert(self._UnlockTalents, id)
end

function XMaverick3Activity:GetStageData(stageId)
    return self._StageMap[stageId]
end

function XMaverick3Activity:GetStageSavedData(stageId)
    return self._StageSavedMap[stageId]
end

function XMaverick3Activity:GetRankStageInfo()
    return self._RankStageInfoMap
end

function XMaverick3Activity:IsTalentUnlock(id)
    return table.indexof(self._UnlockTalents, id) ~= false
end

return XMaverick3Activity

---@class XMaverick3StageData 关卡数据
---@field IsPass boolean
---@field Star number
---@field BestDeadCount number
---@field BestCostTime number
---@field TotalScore number 最高分数

---@class XMaverick3StageSaved 关卡缓存
---@field RobotId number 当前出战的RobotId
---@field Hp number 剩余血量
---@field MaxHp number 最大血量
---@field DeadCount number 死亡次数
---@field UltimateSkill number 当前选择的终极技能
---@field Hangings number 当前选择的挂饰
---@field BulletCount number[] 技能次数
---@field StageProgress number 前端显示关卡进度
---@field StageSavePoint number 保存点

---@class XMaverick3RankStageInfo 排行榜个人关卡信息
---@field RobotId number 当前出战的RobotId
---@field UltimateSkill number 当前选择的终极技能
---@field Hangings number 当前选择的挂饰