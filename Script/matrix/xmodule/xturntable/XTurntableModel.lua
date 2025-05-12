local XTurntableActivity = require("XModule/XTurntable/XEntity/XTurntableActivity")

---@class XTurntableModel : XModel
---@field ActivityData XTurntableActivity
local XTurntableModel = XClass(XModel, "XTurntableModel")

local TableKey = {
    Turntable = {},
    TurntableActivity = {},
    TurntableDrawReward = {}
}

local TablePrivate = {
    TurntableMilestone = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
}

function XTurntableModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/Turntable", TableKey, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/Turntable", TablePrivate, XConfigUtil.CacheType.Private)
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
    -- 进过一次界面后就不用再显示该红点
    self.IsNeedShow72HoursRedPoint = true
end

function XTurntableModel:ClearPrivate()

end

function XTurntableModel:ResetAll()
    self.IsNeedShow72HoursRedPoint = true
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

---@return XTableTurntableDrawReward[]
function XTurntableModel:GetTurntableDrawReward()
    return self._ConfigUtil:GetByTableKey(TableKey.TurntableDrawReward)
end

function XTurntableModel:GetTurntableMilestonePercentByTurns(turns)
    local config = self._ConfigUtil:GetByTableKey(TablePrivate.TurntableMilestone)
    if config then
        local cfg = config[turns]
        if cfg then
            return cfg.Percent
        end
    end
    
    return 0
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
    local rewards = self:GetProgressReward(activityId)
    return rewards[index][2]
end

function XTurntableModel:GetMaxProgress(activityId)
    local result = self:GetProgressReward(activityId)
    return result[#result] and result[#result][2] or 0
end

function XTurntableModel:InitProgressReward()
    self.ProgressRewardMap = {}
    
    local configs = self:GetTurntableDrawReward()
    for i, v in pairs(configs) do
        if self.ProgressRewardMap[v.ActivityId] == nil then
            self.ProgressRewardMap[v.ActivityId] = {}
        end
        table.insert(self.ProgressRewardMap[v.ActivityId], {v.AccumulateRewardId, v.AccumulateNum, v.IsTopShow})
    end

    for i, v in pairs(self.ProgressRewardMap) do
        table.sort(v, function(a, b) 
            return a[2] < b[2]
        end)
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