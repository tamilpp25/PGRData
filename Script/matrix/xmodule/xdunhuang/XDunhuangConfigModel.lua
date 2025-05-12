local TableKey = {
    MuralShareActivity = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    MuralSharePainting = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    MuralShareReward = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
}

---@class XDunhuangConfigModel : XModel
local XDunhuangConfigModel = XClass(XModel, "XDunhuangConfigModel")
function XDunhuangConfigModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/MuralShare", TableKey)
end

function XDunhuangConfigModel:GetConfigActivityTimeId(activityId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MuralShareActivity, activityId)
    if not config then
        return false
    end
    return config.TimeId
end

function XDunhuangConfigModel:GetConfigActivityTaskIds(activityId)
    if not activityId then
        return {}
    end
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MuralShareActivity, activityId)
    if not config then
        return nil
    end
    return config.TaskId
end

function XDunhuangConfigModel:GetConfigActivityFirstRewardId(activityId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MuralShareActivity, activityId)
    if not config then
        return nil
    end
    return config.RewardId
end

function XDunhuangConfigModel:GetConfigsPainting()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.MuralSharePainting)
    return configs
end

function XDunhuangConfigModel:GetConfigPainting(paintingId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MuralSharePainting, paintingId)
    return config
end

function XDunhuangConfigModel:GetConfigPaintings()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.MuralSharePainting)
    return configs
end

function XDunhuangConfigModel:GetConfigReward()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.MuralShareReward)
    return configs
end

return XDunhuangConfigModel
