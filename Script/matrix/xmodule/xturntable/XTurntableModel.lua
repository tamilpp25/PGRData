local XTurntableActivity = require("XModule/XTurntable/XEntity/XTurntableActivity")

---@class XTurntableModel : XModel
---@field ActivityData XTurntableActivity
local XTurntableModel = XClass(XModel, "XTurntableModel")

local TableKey = {
    Turntable = { CacheType = XConfigUtil.CacheType.Temp },
    TurntableActivity = { CacheType = XConfigUtil.CacheType.Temp },
}

function XTurntableModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/Turntable", TableKey)
    -- 最大奖励进度
    self.MaxProgressValue = nil
    -- 进度奖励
    self.ProgressRewardMap = {}
    -- 转盘奖励池
    self.TurntableRewardMap = {}
    -- 转盘奖励池里的重要奖励
    -- self.MainItems = {}
    -- 转盘奖励池总量
    self.TotalTurntableTimes = {}
end

function XTurntableModel:ClearPrivate()

end

function XTurntableModel:ResetAll()

end

--region config

---@return XTableTurntableActivity
function XTurntableModel:GetTurntableActivityById(activityId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TurntableActivity, activityId)
    return config or {}
end

---@return XTableTurntable
function XTurntableModel:GetTurntableById(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Turntable, id)
    return config or {}
end

---@return XTableTurntable[]
function XTurntableModel:GetTurntable()
    local config = self._ConfigUtil:GetByTableKey(TableKey.Turntable)
    return config or {}
end

---@return XTableTurntableActivity[]
function XTurntableModel:GetTurntableActivity()
    local config = self._ConfigUtil:GetByTableKey(TableKey.TurntableActivity)
    return config or {}
end

--endregion

function XTurntableModel:GetProgressReward(activityId)
    if XTool.IsTableEmpty(self.ProgressRewardMap) then
        self:InitProgressReward()
    end
    return self.ProgressRewardMap[activityId] or {}
end

function XTurntableModel:GetActivityTotalItemNum(activityId)
    if XTool.IsTableEmpty(self.TotalTurntableTimes) then
        self:InitTotalTurntableTimes()
    end
    return self.TotalTurntableTimes[activityId] or 0
end

function XTurntableModel:GetProgressByRewardIndex(activityId, index)
    local cfg = self:GetTurntableActivityById(activityId)
    return cfg.AccumulateNums[index]
end

function XTurntableModel:GetMaxProgress(activityId)
    local result = self:GetProgressReward(activityId)
    return result[#result] and result[#result][2] or 0
end

function XTurntableModel:InitProgressReward()
    self.ProgressRewardMap = {}
    local configs = self:GetTurntableActivity()
    for _, v in pairs(configs) do
        local data = {}
        for k, num in ipairs(v.AccumulateNums) do
            table.insert(data, { v.AccumulateRewardIds[k], num })
        end
        table.sort(data, function(a, b)
            return a[2] < b[2]
        end)
        self.ProgressRewardMap[v.Id] = data
    end
end

function XTurntableModel:InitTotalTurntableTimes()
    self.TotalTurntableTimes = {}
    local config = self:GetTurntable()
    for _, v in pairs(config) do
        if not self.TotalTurntableTimes[v.ActivityId] then
            self.TotalTurntableTimes[v.ActivityId] = 0
        end
        self.TotalTurntableTimes[v.ActivityId] = self.TotalTurntableTimes[v.ActivityId] + v.CanGainTimes
    end
end

function XTurntableModel:GetTurntableRewards(activity)
    if not XTool.IsNumberValid(activity) then
        return {}
    end
    local result = self.TurntableRewardMap[activity]
    if not result then
        result = {}
        local configs = self:GetTurntable()
        for _, v in pairs(configs) do
            if v.ActivityId == activity then
                table.insert(result, v)
            end
        end
        self.TurntableRewardMap[activity] = result
    end
    return result
end

function XTurntableModel:GetRemindItemCount(activityId)
    local total = self:GetActivityTotalItemNum(activityId)
    local infos = self.ActivityData:GetGainRewardInfos()
    for _, v in pairs(infos) do
        total = total - v
    end
    return total
end

--region 协议

function XTurntableModel:NotifyTurntableData(data)
    if not data then
        return
    end
    if not self.ActivityData then
        self.ActivityData = XTurntableActivity.New()
    end
    self.ActivityData:NotifyTurntableActivity(data.TurntableData)
end

--endregion

return XTurntableModel