local XNormalGWNode = require("XEntity/XGuildWar/Battle/Node/XNormalGWNode")

---@class XTerm4BossGWNode:XGWNode@ 4期boss
local XTerm4BossGWNode = XClass(XNormalGWNode, "XTerm4BossGWNode")

function XTerm4BossGWNode:Ctor(id)
    self._CurrentChildIndex = XGuildWarConfig.ChildNodeIndex.Left
    self._ChildIndexLastChallenge = XGuildWarConfig.ChildNodeIndex.None
    self._ResurrectionTimes = 0
    self._RuinTimes = 2
end

---@return number@ 复活次数
function XTerm4BossGWNode:GetResurrectionTimes()
    return self._ResurrectionTimes
end

-- 获取当前节点当场最高伤害
function XTerm4BossGWNode:GetMaxDamage()
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

-- 获取是否残留区
function XTerm4BossGWNode:GetIsRuinsStatus()
    -- 子节点全通关
    ---@type XTerm4BossChildGWNode[]
    local childNodes = self:GetChildrenNodes()
    for i = 1, #childNodes do
        local node = childNodes[i]
        local lv = node:GetBossLevel()
        if lv <= 0 then
            return false
        end
    end
    return self:GetIsDead()
end

function XTerm4BossGWNode:GetCurrentChildNode()
    return XDataCenter.GuildWarManager.GetChildNode(self:GetId(), self._CurrentChildIndex)
end

function XTerm4BossGWNode:GetChildNodeLastChallenge()
    if self._ChildIndexLastChallenge == XGuildWarConfig.ChildNodeIndex.None then
        return false
    end
    return XDataCenter.GuildWarManager.GetChildNode(self:GetId(), self._ChildIndexLastChallenge)
end

function XTerm4BossGWNode:GetShowMonsterName()
    local lv = 1
    ---@type XTerm4BossChildGWNode[]
    local childNodes = self:GetChildrenNodes()
    for i = 1, #childNodes do
        local node = childNodes[i]
        local childLv = node:GetBossLevel()
        if childLv > lv then
            lv = childLv
        end
    end
    return self.Super.GetShowMonsterName(self) .. " Lv." .. lv
end

function XTerm4BossGWNode:CheckCanSweep()
    return false
end

--地图界面移动到这个节点时回调
function XTerm4BossGWNode:OnDetailGoCallback()
    if not self:GetIsDead() then
        XLuaUiManager.Close("UiGuildWarStageDetail")
        XLuaUiManager.Open("UiGuildWarTerm4Panel", self)
        return true
    end
    return false
end

return XTerm4BossGWNode
