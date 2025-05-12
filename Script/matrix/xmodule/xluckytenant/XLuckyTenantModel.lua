local XLuckyTenantConfigModel = require("XModule/XLuckyTenant/XLuckyTenantConfigModel")

---@class XLuckyTenantModel : XLuckyTenantConfigModel
local XLuckyTenantModel = XClass(XLuckyTenantConfigModel, "XLuckyTenantModel")
function XLuckyTenantModel:OnInit()
    self._ActivityId = 0
    self._PlayingStageId = 0
    self._PlayingStageRound = 0

    self:_InitTableKey()
    self._StageRecord = false

    self._StageTask = false
    self._RoundsToNormalClear = false
    self._RoundsToPerfectClear = false
end

function XLuckyTenantModel:ClearPrivate()
    self._StageTask = false
end

function XLuckyTenantModel:GetValidRoundConfig(stageId, currentRound)
    local roundConfigs = self:GetLuckyTenantChessRoundConfigs()
    local result = false

    local startId = stageId * 1000 + 1
    local startRoundConfig = roundConfigs[startId]
    if startRoundConfig then
        for i = startId, startId + 99 do
            local round = roundConfigs[i]
            if not round then
                break
            end
            if round.StageId ~= stageId then
                break
            end
            if currentRound >= round.StartRound then
                result = round
            end
        end
    else
        XLog.Error("[XLuckyTenantGame] 麻烦配置成, 回合表的id = stageId * 1000 + index, 比如1001")
    end
    if not result then
        XLog.Error("[XLuckyTenantGame] 暴力遍历round表了")
        for i = 1, #roundConfigs do
            local round = roundConfigs[i]
            if round.StageId == stageId then
                if currentRound >= round.StartRound then
                    result = round
                end
            end
        end
    end
    return result
end

---@return XTable.XTableLuckyTenantActivity
function XLuckyTenantModel:GetActivityConfig()
    local activityId = self._ActivityId
    local config = self:GetLuckyTenantActivityById(activityId)
    if config then
        return config
    end
end

function XLuckyTenantModel:GetHelpKey()
    local config = self:GetActivityConfig()
    if not config then
        return "LuckyTenantGame"
    end
    return config.HelpId
end

function XLuckyTenantModel:GetStages()
    local activityId = self._ActivityId
    local result = {}
    local stages = self:GetLuckyTenantStageConfigs()
    for id, stage in pairs(stages) do
        if stage.ActivityId == activityId then
            result[#result + 1] = stage
        end
    end
    return result
end

function XLuckyTenantModel:GetStageRecord(stageId)
    if self._StageRecord then
        return self._StageRecord[stageId]
    end
    return false
end

function XLuckyTenantModel:GetRoundsToNormalClear(stageId)
    local stages = self:GetStageTasks(stageId)
    for i = 1, #stages do
        ---@type XTable.XTableLuckyTenantStageTask
        local stage = stages[i]
        if stage.NormalClear then
            return stage.Round, stage.Score
        end
    end
    XMVCA.XLuckyTenant:Print("[XLuckyTenantModel] stage表没有配置NormalClear", tostring(stageId))
    return 0
end

function XLuckyTenantModel:GetQuestAmount(stageId)
    local stageQuests = self:GetStageTasks(stageId)
    return #stageQuests
end

function XLuckyTenantModel:GetRoundsToPerfectClear(stageId)
    local stageQuests = self:GetStageTasks(stageId)
    for i = 1, #stageQuests do
        ---@type XTable.XTableLuckyTenantStageTask
        local stage = stageQuests[i]
        if stage.PerfectClear then
            return stage.Round, stage.Score
        end
    end
    XMVCA.XLuckyTenant:Print("[XLuckyTenantModel] stage表没有配置PerfectClear", tostring(stageId))
    if stageQuests[#stageQuests] then
        return stageQuests[#stageQuests].Round
    end
    return 0, 0
end

---@return XTable.XTableLuckyTenantStageTask[]
function XLuckyTenantModel:GetStageTasks(stageId)
    if not self._StageTask then
        self._StageTask = {}
    end
    if self._StageTask[stageId] then
        return self._StageTask[stageId]
    end
    local result = {}
    for i = 1, 99 do
        local questId = stageId * 1000 + i
        local config = self:GetLuckyTenantStageTaskConfigById(questId)
        if config then
            result[#result + 1] = config
        else
            break
        end
    end
    self._StageTask[stageId] = result
    return result
end

function XLuckyTenantModel:IsStagePassed(stageId)
    local record = self:GetStageRecord(stageId)
    if record then
        --local needRound, needScore = self:GetRoundsToNormalClear(stageId)
        --local round = record.Round
        --local score = record.Score
        --if round >= needRound and score > needScore then
        --    return true
        --end
        if record.IsNormalClear then
            return true
        end
    end
    return false
end

function XLuckyTenantModel:GetPlayingStageId()
    return self._PlayingStageId
end

function XLuckyTenantModel:GetPlayingStageRound()
    return self._PlayingStageRound
end

function XLuckyTenantModel:SetDataFromServer(LuckyTenantStagesNotify)
    if XMVCA.XLuckyTenant:IsOffline() then
        self._ActivityId = 1
        return
    end
    self._ActivityId = LuckyTenantStagesNotify.ActivityId
    self._PlayingStageRound = LuckyTenantStagesNotify.CurrentStageRound
    self._PlayingStageId = LuckyTenantStagesNotify.CurrentStage
    self._StageRecord = LuckyTenantStagesNotify.Stages
end

function XLuckyTenantModel:SetStageRecord(record)
    self._StageRecord = self._StageRecord or {}
    self._StageRecord[record.StageId] = record
end

function XLuckyTenantModel:DebugClearStageRecord(stageId)
    if self._StageRecord then
        self._StageRecord[stageId] = nil
        XMVCA.XLuckyTenant:Print("删除本地记录成功:" .. tostring(stageId))
    end
end

function XLuckyTenantModel:SetPlayingStageId(value)
    self._PlayingStageId = value
end

function XLuckyTenantModel:SetPlayingStageRound(value)
    self._PlayingStageRound = value
end

function XLuckyTenantModel:ClearPlayingStage()
    self:SetPlayingStageId(0)
    self:SetPlayingStageRound(0)
end

function XLuckyTenantModel:OnStagePassed(recordNew)
    local record = self:GetStageRecord(recordNew.StageId)
    if record then
        local isNewRecord = false
        if recordNew.Score > record.Score then
            record.Score = recordNew.Score
            isNewRecord = true
        end
        if recordNew.Round > record.Round then
            record.Round = recordNew.Round
            isNewRecord = true
        end
        record.IsNewRecord = isNewRecord
        record.IsNormalClear = record.IsNormalClear or recordNew.IsNormalClear
    else
        recordNew.IsNewRecord = true
        self:SetStageRecord(recordNew)
    end
end

function XLuckyTenantModel:IsActivityOpen()
    if self._ActivityId and self._ActivityId > 0 then
        local config = self:GetActivityConfig()
        if config then
            local timeId = config.TimeId
            if XFunctionManager.CheckInTimeByTimeId(timeId) then
                return true
            end
        end
    end
    return false
end

return XLuckyTenantModel