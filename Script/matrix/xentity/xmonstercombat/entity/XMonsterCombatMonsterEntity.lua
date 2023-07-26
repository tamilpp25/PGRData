-- 怪物配置类
---@class XMonsterCombatMonsterEntity
local XMonsterCombatMonsterEntity = XClass(nil, "XMonsterCombatMonsterEntity")

function XMonsterCombatMonsterEntity:Ctor(monsterId)
    self:UpdateMonsterId(monsterId)
end

function XMonsterCombatMonsterEntity:UpdateMonsterId(monsterId)
    self.MonsterId = monsterId
    self.Config = XMonsterCombatConfigs.GetCfgByIdKey(XMonsterCombatConfigs.TableKey.MonsterCombatMonster, monsterId)
    self.ConfigDetail = XMonsterCombatConfigs.GetCfgByIdKey(XMonsterCombatConfigs.TableKey.MonsterCombatMonsterDetail, monsterId)
end
-- 怪物名称
function XMonsterCombatMonsterEntity:GetName()
    return self.Config.Name or ""
end
-- 负重
function XMonsterCombatMonsterEntity:GetCost()
    return self.Config.Cost or 0
end
-- 排序
function XMonsterCombatMonsterEntity:GetOrder()
    return self.Config.Order or 0
end

--region 详情信息

-- 战斗时间
function XMonsterCombatMonsterEntity:GetFightTime()
    return self.ConfigDetail.FightTime or 0
end
-- 怪物描述
function XMonsterCombatMonsterEntity:GetDescription()
    local desc = self.ConfigDetail.Description or ""
    return XUiHelper.ConvertLineBreakSymbol(desc)
end
-- 怪物模型Id
function XMonsterCombatMonsterEntity:GetUiModelId()
    return self.ConfigDetail.UiModelId or ""
end
-- 怪物图片路径
function XMonsterCombatMonsterEntity:GetIcon()
    return self.ConfigDetail.Icon or ""
end
-- 怪物头像图标
function XMonsterCombatMonsterEntity:GetAchieveIcon()
    return self.ConfigDetail.AchieveIcon or ""
end
-- 主动技能名称
function XMonsterCombatMonsterEntity:GetActiveSkillName()
    return self.ConfigDetail.ActiveSkillName or ""
end
-- 主动技能描述
function XMonsterCombatMonsterEntity:GetActiveSkillDesc()
    local desc = self.ConfigDetail.ActiveSkillDesc or ""
    return XUiHelper.ConvertLineBreakSymbol(desc)
end
-- 主动技能冷却
function XMonsterCombatMonsterEntity:GetActiveSkillCooling()
    return self.ConfigDetail.ActiveSkillCooling or 0
end
-- 被动技能名称
function XMonsterCombatMonsterEntity:GetPassiveSkillName()
    return self.ConfigDetail.PassiveSkillName or ""
end
-- 被动技能描述
function XMonsterCombatMonsterEntity:GetPassiveSkillDesc()
    local desc = self.ConfigDetail.PassiveSkillDesc or ""
    return XUiHelper.ConvertLineBreakSymbol(desc)
end
-- 解锁条件描述
function XMonsterCombatMonsterEntity:GetUnlockConditionDesc()
    return self.ConfigDetail.UnlockConditionDesc or ""
end

--endregion

-- 检查怪物是否解锁 解锁为true
function XMonsterCombatMonsterEntity:CheckIsUnlock()
    local viewModel = XDataCenter.MonsterCombatManager.GetViewModel()
    if not viewModel then
        return false
    end
    return viewModel:CheckMonsterUnlock(self.MonsterId)
end

-- 检查是否有新怪物解锁
-- 规则为：解锁且未点击
function XMonsterCombatMonsterEntity:CheckNewUnlockMonster()
    local isUnlock = self:CheckIsUnlock()
    local isClick = XDataCenter.MonsterCombatManager.CheckMonsterClick(self.MonsterId)
    return isUnlock and not isClick
end

return XMonsterCombatMonsterEntity