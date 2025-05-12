---@class XSameColorModel : XModel
local XSameColorModel = XClass(XModel, "XSameColorModel")

local TableKey = {
    --- 活动总控
    SameColorGameActivity = { CacheType = XConfigUtil.CacheType.Normal },
    --- 角色球
    SameColorGameBall = { CacheType = XConfigUtil.CacheType.Normal },
    --- 关卡Boss
    SameColorGameBoss = { },
    --- 关卡Boss分数等级
    SameColorGameBossGrade = { },
    --- 剧情类型配置
    SameColorGameBossSkill = { },
    --- buff配置
    SameColorGameBuff = { },
    --- 被动技能配置
    SameColorGamePassiveSkill = { },
    --- 角色配置
    SameColorGameRole = { },
    --- 角色技能
    SameColorGameSkill = { },
    --- 角色技能组(一期二期角色分为表技能和里技能)
    SameColorGameSkillGroup = { },
    --- 角色能量属性
    SameColorGameAttributeFactor = { },
    
    --- ClientCfg
    SameColorGameCfg = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal, ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key" },
    --- 战斗表现
    BattleShowRole = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String, Identifier = "ModelId", TableDefindName = "XTableUiBattleShowRole" },
    --- Buff消球特效
    BallBuffEffectShow = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "BuffType", TableDefindName = "XTableSameColorBallBuffEffectShow" },
    --- 技能消球特效
    SkillEffectShow = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "SkillId", TableDefindName = "XTableSameColorSkillEffectShow" },
    --- 属性介绍
    SameColorGameAttributeType = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Type"},
}

function XSameColorModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("SameColorGame", TableKey)
end

function XSameColorModel:ClearPrivate()
    --这里执行内部数据清理
end

function XSameColorModel:ResetAll()
    --这里执行重登数据清理
end

--region Data - Task
---@param taskType number XEnumConst.SAME_COLOR_GAME.TASK_TYPE
function XSameColorModel:GetTaskData(taskType, isSort)
    taskType = taskType or XEnumConst.SAME_COLOR_GAME.TASK_TYPE.DAY
    local groupId
    if taskType == XEnumConst.SAME_COLOR_GAME.TASK_TYPE.DAY then
        groupId = tonumber(self:GetClientCfgStringValue("TaskGroupId", 1))
    elseif taskType == XEnumConst.SAME_COLOR_GAME.TASK_TYPE.REWARD then
        groupId = tonumber(self:GetClientCfgStringValue("TaskGroupId", 2))
    end
    return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId, isSort)
end
--endregion

--region Cfg - PassiveSkillConfig
---@return XTableSameColorGamePassiveSkill
function XSameColorModel:GetPassiveSkillCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SameColorGamePassiveSkill, id)
end
--endregion

--region Cfg - ClientConfig
---@return XTableSameColorGameCfg
function XSameColorModel:_GetClientCfg(key)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SameColorGameCfg, key)
end

---@return string[]
function XSameColorModel:GetClientCfgValue(key)
    local cfg = self:_GetClientCfg(key)
    return cfg.Values
end

function XSameColorModel:GetClientCfgStringValue(key, index)
    local cfg = self:_GetClientCfg(key)
    if index then
        return cfg and cfg.Values[index]
    end
    return cfg and cfg.Values[1]
end
--endregion

--region Cfg - BattleShowRole
---@return XTableUiBattleShowRole
function XSameColorModel:GetBattleShowRoleCfg(ModelId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BattleShowRole, ModelId)
end
--endregion

--region Cfg - BallBuffEffectShow
---@return XTableSameColorBallBuffEffectShow
function XSameColorModel:GetBallBuffEffectShowCfg(buffType)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BallBuffEffectShow, buffType, true)
end
--endregion

--region Cfg - SkillEffectShow
---@return XTableSameColorSkillEffectShow
function XSameColorModel:GetSkillEffectShowCfg(skillId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkillEffectShow, skillId, true)
end
--endregion

--region Cfg - AttributeFactor
---@return XTableSameColorGameAttributeFactor
function XSameColorModel:GetAttributeFactorCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SameColorGameAttributeFactor, id, true)
end
--endregion

--region Cfg - AttributeType
---@return XTableSameColorGameAttributeType
function XSameColorModel:GetAttributeTypeCfg(type)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SameColorGameAttributeType, type, true)
end
--endregion

return XSameColorModel