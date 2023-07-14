local XNormalGWNode = require("XEntity/XGuildWar/Battle/Node/XNormalGWNode")
-- 黑白鲨节点
---@class XTwinsRootGWNode:XGWNode
local XTwinsRootGWNode = XClass(XNormalGWNode, "XTwinsRootGWNode")

function XTwinsRootGWNode:Ctor(id)
    self.NextBossAttackTime = false
    self.Weakness = false
end

-- data : XGuildWarNodeData
function XTwinsRootGWNode:UpdateWithServerData(data, ...)
    XTwinsRootGWNode.Super.UpdateWithServerData(self, data, ...)
    if data == nil then data = {} end
    self.NextBossAttackTime = data.NextBossAttackTime
    self.NextBossTreatMstTime = data.NextBossTreatMstTime
    self.Weakness = data.Weakness
    self.IsMerge = data.IsMerge
end
-- 更新进攻时间
function XTwinsRootGWNode:UpdateNextBossAttackTime(time)
    if time then
        self.NextBossAttackTime = time
    end
end

--获取名字 死亡后返回残留区名字
function XTwinsRootGWNode:GetName(checkDead)
    if checkDead == nil then checkDead = true end
    if checkDead and self:GetIsDead() then
        return XUiHelper.GetText("GuildWarResidueName")
    else
        return self.Config.Name
    end
end
--获取英文名 死亡后返回残留区名字
function XTwinsRootGWNode:GetNameEn()
    if self:GetIsDead() then
        return XUiHelper.GetText("GuildWarResidueNameEn")
    else
        return self.Config.NameEn
    end
end
-- 获取节点血量
function XTwinsRootGWNode:GetHP()
    if self:GetIsMerge() then
        return XTwinsRootGWNode.Super.GetHP(self)
    end
    local node1 = XDataCenter.GuildWarManager.GetChildNode(self:GetId(), 1)
    local node2 = XDataCenter.GuildWarManager.GetChildNode(self:GetId(), 2)
    local hp = (node1:GetHP() + node2:GetHP()) / 2
    return hp
end
-- 获取子节点血量
function XTwinsRootGWNode:GetChildHp(childIndex)
    local node = XDataCenter.GuildWarManager.GetChildNode(self:GetId(), childIndex)
    return node:GetHP()
end
-- 获取子节点模型ID
function XTwinsRootGWNode:GetChildModelId(childIndex)
    return XGuildWarConfig.GetChildNodeModelId(self:GetId(), childIndex)
end
-- 获取链接的近卫区节点
function XTwinsRootGWNode:GetGuardNodes()
    local result = {}
    for _, node in pairs(self:GetFrontNodes()) do
        if node:GetNodeType() == XGuildWarConfig.NodeType.Guard then
            table.insert(result, node)
        end
    end
    return result
end
-- 获取当前节点当场最高伤害
function XTwinsRootGWNode:GetMaxDamage()
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
function XTwinsRootGWNode:CheckCanSweep(checkCostEnergy)
    if self:GetMaxDamage() <= 0 then
        return false
    end
    if checkCostEnergy then
        return XDataCenter.GuildWarManager.GetCurrentActionPoint() >= self.Config.SweepCostEnergy
    end
    return true
end
-- 获取关卡ID
function XTwinsRootGWNode:GetStageId()
    if self:GetIsRuinsStatus() then
        return XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Stage
        , self.Config.ResidueStageId).StageId
    end
    return XTwinsRootGWNode.Super.GetStageId(self)
end
-- 获取是否残留区
function XTwinsRootGWNode:GetIsRuinsStatus()
    return self:GetIsDead()
end
-- 获取离BOSS节点发动攻击剩余时间
function XTwinsRootGWNode:GetTimeToBossAttack()
    if self:GetIsDead() then
        return 0
    end
    return (self.NextBossAttackTime or 0) - XTime.GetServerNowTimestamp()
end
-- 获取离BOSS节点发动回复剩余时间(强化伏兵)
function XTwinsRootGWNode:GetTimeToBossAttack()
    if self:GetIsDead() then
        return 0
    end
    return (self.NextBossTreatMstTime or 0) - XTime.GetServerNowTimestamp()
end
-- 获取是否合体
function XTwinsRootGWNode:GetIsMerge()
    return self.IsMerge == 1
end

-- 获取展示怪物名字 攻略后返回残留区名
function XTwinsRootGWNode:GetShowMonsterName()
    if self:GetIsRuinsStatus() then
        return XUiHelper.GetText("GuildWarResidueName")
    end
    return XTwinsRootGWNode.Super.GetShowMonsterName(self)
end

-- 虚弱状态(暴露弱点)
function XTwinsRootGWNode:HasWeakness()
    return self.Weakness == 1
end
function XTwinsRootGWNode:SetWeakness(value)
    self.Weakness = value and 1 or 0
end

--地图界面移动到这个节点时回调
function XTwinsRootGWNode:OnDetailGoCallback()
    if not self:GetIsDead() then
        XLuaUiManager.Close("UiGuildWarStageDetail")
        XLuaUiManager.Open("UiGuildWarTwinsPanel", self, false)
        return true
    end
    return false
end

return XTwinsRootGWNode
