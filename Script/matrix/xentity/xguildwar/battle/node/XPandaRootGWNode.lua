local XNormalGWNode = require("XEntity/XGuildWar/Battle/Node/XNormalGWNode")
-- 黑白鲨节点
---@class XPandaRootGWNode:XGWNode
local XPandaRootGWNode = XClass(XNormalGWNode, "XPandaRootGWNode")

function XPandaRootGWNode:Ctor(id)
    self.NextBossAttackTime = false
    self.Weakness = false
end

-- data : XGuildWarNodeData
function XPandaRootGWNode:UpdateWithServerData(data, ...)
    XPandaRootGWNode.Super.UpdateWithServerData(self, data, ...)
    if data == nil then data = {} end
    self.NextBossAttackTime = data.NextBossAttackTime
    self.Weakness = data.Weakness
end
-- 更新进攻时间
function XPandaRootGWNode:UpdateNextBossAttackTime(time)
    if time then
        self.NextBossAttackTime = time
    end
end

--获取名字 死亡后返回残留区名字
function XPandaRootGWNode:GetName(checkDead)
    if checkDead == nil then checkDead = true end
    if checkDead and self:GetIsDead() then
        return XUiHelper.GetText("GuildWarResidueName")
    else
        return self.Config.Name
    end
end
--获取英文名 死亡后返回残留区名字
function XPandaRootGWNode:GetNameEn()
    if self:GetIsDead() then
        return XUiHelper.GetText("GuildWarResidueNameEn")
    else
        return self.Config.NameEn
    end
end
-- 获取节点血量
function XPandaRootGWNode:GetHP()
    local node1 = XDataCenter.GuildWarManager.GetChildNode(self:GetId(), XGuildWarConfig.ChildNodeIndex.Left)
    local node2 = XDataCenter.GuildWarManager.GetChildNode(self:GetId(), XGuildWarConfig.ChildNodeIndex.Right)
    return (node1:GetHP() + node2:GetHP()) / 2
end
-- 获取模型ID
function XPandaRootGWNode:GetModelId(pandaType)
    return XGuildWarConfig.GetChildNodeModelId(self:GetId(), pandaType)
end
-- 获取离BOSS节点攻击剩余时间
function XPandaRootGWNode:GetTimeToBossAttack()
    if self:GetIsDead() then
        return 0
    end
    return (self.NextBossAttackTime or 0) - XTime.GetServerNowTimestamp()
end
-- 获取链接的近卫区节点
function XPandaRootGWNode:GetGuardNodes()
    local result = {}
    for _, node in pairs(self:GetFrontNodes()) do
        if node:GetNodeType() == XGuildWarConfig.NodeType.Guard then
            table.insert(result, node)
        end
    end
    return result
end
-- 获取当前节点当场最高伤害
function XPandaRootGWNode:GetMaxDamage()
    local aliveType = XGuildWarConfig.FightRecordAliveType.Die
    if self:GetHP() > 0 then
        aliveType = XGuildWarConfig.FightRecordAliveType.Alive
    end
    if aliveType == XGuildWarConfig.FightRecordAliveType.Alive and not self:GetIsRuinsStatus() then
        local node1 = XDataCenter.GuildWarManager.GetChildNode(self:GetId(), XGuildWarConfig.ChildNodeIndex.Left)
        local node2 = XDataCenter.GuildWarManager.GetChildNode(self:GetId(), XGuildWarConfig.ChildNodeIndex.Right)
        return math.max(node1:GetMaxDamage(), node2:GetMaxDamage())
    end
    return XDataCenter.GuildWarManager.GetBattleManager():GetMaxDamageByUID(self.UID, aliveType)
end
-- 检查是否能够扫荡
function XPandaRootGWNode:CheckCanSweep(checkCostEnergy)
    if self:GetMaxDamage() <= 0 then
        return false
    end
    if checkCostEnergy then
        return XDataCenter.GuildWarManager.GetCurrentActionPoint() >= self.Config.SweepCostEnergy
    end
    return true
end
-- 获取关卡ID
function XPandaRootGWNode:GetStageId()
    if self:GetIsRuinsStatus() then
        return XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Stage
        , self.Config.ResidueStageId).StageId
    end
    return XPandaRootGWNode.Super.GetStageId(self)
end
-- 残留区
function XPandaRootGWNode:GetIsRuinsStatus()
    return self:GetIsDead()
end
-- 获取展示怪物名字 攻略后返回残留区名
function XPandaRootGWNode:GetShowMonsterName()
    if self:GetIsRuinsStatus() then
        return XUiHelper.GetText("GuildWarResidueName")
    end
    return XPandaRootGWNode.Super.GetShowMonsterName(self)
end

-- 虚弱状态(暴露弱点)
function XPandaRootGWNode:HasWeakness()
    return self.Weakness == 1
end
function XPandaRootGWNode:SetWeakness(value)
    self.Weakness = value and 1 or 0
end

--地图界面移动到这个节点时回调
function XPandaRootGWNode:OnDetailGoCallback()
    if not self:GetIsDead() then
        XLuaUiManager.Close("UiGuildWarStageDetail")
        XLuaUiManager.Open("UiGuildWarPandaStageDetail", self, false)
        return true
    end
    return false
end

return XPandaRootGWNode
