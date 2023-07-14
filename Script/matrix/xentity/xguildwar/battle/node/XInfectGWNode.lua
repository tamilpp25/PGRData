local XNormalGWNode = require("XEntity/XGuildWar/Battle/Node/XNormalGWNode")
-- 感染区节点
local XInfectGWNode = XClass(XNormalGWNode, "XInfectGWNode")

function XInfectGWNode:Ctor(id)
    
end

-- 获取链接的近卫区节点
function XInfectGWNode:GetGuardNodes()
    local result = {}
    for _, node in pairs(self:GetParentNodes()) do
        if node:GetNodeType() == XGuildWarConfig.NodeType.Guard then
            table.insert(result, node)
        end
    end
    return result
end

function XInfectGWNode:GetAllGuardIsDead()
    for _, node in pairs(self:GetParentNodes()) do
        if node:GetNodeType() == XGuildWarConfig.NodeType.Guard 
           and not node:GetIsDead() then
            return false
        end
    end
    return true
end

function XInfectGWNode:GetStageId()
    if self:GetStutesType() == XGuildWarConfig.NodeStatusType.Die then
        return XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Stage
           , self.Config.ResidueStageId).StageId
    end
    return XInfectGWNode.Super.GetStageId(self)
end

function XInfectGWNode:GetName(checkDead)
    if checkDead == nil then checkDead = true end
    if checkDead and self:GetIsDead() then
        return XUiHelper.GetText("GuildWarResidueName")
    else
        return self.Config.Name
    end
end

function XInfectGWNode:GetNameEn()
    if self:GetIsDead() then
        return XUiHelper.GetText("GuildWarResidueNameEn")
    else
        return self.Config.NameEn
    end
end

-- 获取当前节点当场最高伤害
function XInfectGWNode:GetMaxDamage()
    local aliveType = XGuildWarConfig.FightRecordAliveType.Die
    if self:GetHP() > 0 then
        aliveType = XGuildWarConfig.FightRecordAliveType.Alive
    end
    return XDataCenter.GuildWarManager
        .GetBattleManager():GetMaxDamageByUID(self.UID, aliveType)
end

-- 检查是否能够扫荡
function XInfectGWNode:CheckCanSweep(checkCostEnergy)
    if self:GetMaxDamage() <= 0 then
        return false
    end
    if checkCostEnergy then
        return XDataCenter.GuildWarManager.GetCurrentActionPoint() >= self.Config.SweepCostEnergy
    end
    return true
end

return XInfectGWNode