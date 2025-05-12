local TableKey = {
    StageMemoryShow = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal, Identifier = "StageId" },
    StageMemoryActivity = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
}

---@class XStageMemoryModel : XModel
local XStageMemoryModel = XClass(XModel, "XStageMemoryModel")
function XStageMemoryModel:OnInit()
    self._ActivityId = nil
    if XMain.IsZlbDebug then
        self._ActivityId = 1
    end
    self._GotRewardIndexSet = {}

    self._ConfigUtil:InitConfigByTableKey("MiniActivity/StageMemory", TableKey)
end

function XStageMemoryModel:ClearPrivate()
end

function XStageMemoryModel:ResetAll()
end

---@return XTable.XTableStageMemoryActivity
function XStageMemoryModel:GetActivityConfig()
    if not self._ActivityId or self._ActivityId == 0 then
        return false
    end
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageMemoryActivity, self._ActivityId)
    return config
end

function XStageMemoryModel:GetStageConfig(stageId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageMemoryShow, stageId)
    return config
end

function XStageMemoryModel:IsRewardReceived(index)
    return self._GotRewardIndexSet[index] and true or false
end

function XStageMemoryModel:SetRewardReceived(index)
    self._GotRewardIndexSet[index] = true
end

---@param data XStageChoiceDataDb
function XStageMemoryModel:SetServerData(data)
    self._ActivityId = data.ActivityId or 0
    self._GotRewardIndexSet = {}
    for i = 1, #data.GotRewardIndexSet do
        local index = data.GotRewardIndexSet[i]
        self._GotRewardIndexSet[index] = true
    end
end

return XStageMemoryModel