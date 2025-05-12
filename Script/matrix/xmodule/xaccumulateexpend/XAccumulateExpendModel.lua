---@class XAccumulateExpendModel : XModel
local XAccumulateExpendModel = XClass(XModel, "XAccumulateExpendModel")

local TableKey = {
    AccumulateExpendActivity = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    AccumulateExpendReward = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
}

function XAccumulateExpendModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ActivityId = nil
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/AccumulateExpend", TableKey)
end

function XAccumulateExpendModel:ClearPrivate()
    --这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XAccumulateExpendModel:ResetAll()
    --这里执行重登数据清理
    -- XLog.Error("重登数据清理")
end

function XAccumulateExpendModel:SetActivityId(id)
    self._ActivityId = id
end

function XAccumulateExpendModel:GetActivityId()
    return self._ActivityId
end

-- region ActivityConfig
---@return XTableAccumulateExpendActivity[]
function XAccumulateExpendModel:GetActivityConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.AccumulateExpendActivity) or {}
end

---@return XTableAccumulateExpendActivity
function XAccumulateExpendModel:GetActivityConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.AccumulateExpendActivity, id, false) or {}
end

function XAccumulateExpendModel:GetActivityTimeIdById(id)
    local config = self:GetActivityConfigById(id)

    return config.TimeId
end

function XAccumulateExpendModel:GetActivityItemIdById(id)
    local config = self:GetActivityConfigById(id)

    return config.ItemId
end

function XAccumulateExpendModel:GetActivityItemIconById(id)
    local config = self:GetActivityConfigById(id)

    return config.ItemIcon
end

function XAccumulateExpendModel:GetActivityConditionIdsById(id)
    local config = self:GetActivityConfigById(id)

    return config.ConditionIds
end

function XAccumulateExpendModel:GetActivityBaseRuleTitlesById(id)
    local config = self:GetActivityConfigById(id)

    return config.BaseRuleTitles
end

function XAccumulateExpendModel:GetActivityBaseRulesById(id)
    local config = self:GetActivityConfigById(id)

    return config.BaseRules
end
-- endregion

-- region RewardConfig
---@return XTableAccumulateExpendReward[]
function XAccumulateExpendModel:GetRewardConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.AccumulateExpendReward) or {}
end

---@return XTableAccumulateExpendReward
function XAccumulateExpendModel:GetRewardConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.AccumulateExpendReward, id, false) or {}
end

function XAccumulateExpendModel:GetRewardTaskIdById(id)
    local config = self:GetRewardConfigById(id)

    return config.TaskId
end

function XAccumulateExpendModel:GetRewardIsSpecialShowById(id)
    local config = self:GetRewardConfigById(id)

    return config.IsSpecialShow
end

function XAccumulateExpendModel:GetRewardIsMainRewardById(id)
    local config = self:GetRewardConfigById(id)

    return config.IsMainReward
end
-- endregion

return XAccumulateExpendModel