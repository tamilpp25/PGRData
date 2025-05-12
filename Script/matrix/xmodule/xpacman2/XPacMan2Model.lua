local TableKey = {
    PacMan2Entity = { DirPath = XConfigUtil.DirectoryType.Client },
    PacMan2GameConfig = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key", },
    PacMan2Activity = { CacheType = XConfigUtil.CacheType.Normal },
    PacMan2Stage = {},
}

---@class XPacMan2Model : XModel
local XPacMan2Model = XClass(XModel, "XPacMan2Model")
function XPacMan2Model:OnInit()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/PacMan2", TableKey)

    self._ActivityId = 0
    self._StageRecords = false
    self.IsPlaying = false
end

function XPacMan2Model:ClearPrivate()
    self.IsPlaying = false
end

function XPacMan2Model:ResetAll()
    self._ActivityId = 0
    self._StageRecords = false
    self.IsPlaying = false
end

function XPacMan2Model:SetDataFromServer(data)
    self._ActivityId = data.ActivityId
    self._StageRecords = data.StageRecords
end

function XPacMan2Model:SetStageData(stageData)
    if not stageData then
        XLog.Error("[XPacMan2Model] SetStageData stageData is nil")
        return
    end
    if not self._StageRecords then
        self._StageRecords = {}
    end
    for i = 1, #self._StageRecords do
        local stageId = self._StageRecords[i].StageId
        if stageId == stageData.StageId then
            self._StageRecords[stageId] = stageData
            return
        end
    end
    table.insert(self._StageRecords, stageData)
end

---@return XTablePacMan2Activity
function XPacMan2Model:GetActivityConfig()
    local activityId = self._ActivityId
    if not activityId or activityId == 0 then
        return nil
    end
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PacMan2Activity, activityId, true)
    return config
end

function XPacMan2Model:GetStageConfigs()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.PacMan2Stage)
    return configs
end

---@return XTablePacMan2Stage
function XPacMan2Model:GetStageConfig(stageId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PacMan2Stage, stageId, true)
    return config
end

function XPacMan2Model:IsStagePassed(stageId)
    if self._StageRecords then
        local star = self:GetStageStar(stageId)
        if star > 0 then
            return true
        end
    end
    return false
end

function XPacMan2Model:GetStageStar(stageId)
    if not self._StageRecords then
        return 0
    end
    for i, record in ipairs(self._StageRecords) do
        if record.StageId == stageId then
            local score = record.HighestScore
            local stageConfig = self:GetStageConfig(stageId)
            if stageConfig then
                for i = #stageConfig.Star, 1, -1 do
                    if score >= stageConfig.Star[i] then
                        return i
                    end
                end
            end
        end
    end
    return 0
end

function XPacMan2Model:GetGameConfig()
    local config = self._ConfigUtil:GetByTableKey(TableKey.PacMan2GameConfig)
    return config
end

function XPacMan2Model:GetEntityConfig(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PacMan2Entity, id, true)
    return config
end

return XPacMan2Model