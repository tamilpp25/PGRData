---@class XGWNode
local XGWNode = XClass(nil, "XGWNode")

function XGWNode:Ctor(id)
    self._Id = id
    self.Config = XGuildWarConfig.GetNodeConfig(id)
    self.UID = 0
    -- 节点血量
    self.HP = self.Config.HpMax
    -- 节点最大血量
    self.MaxHP = self.Config.HpMax
    -- 当前到达该节点的人数
    self.MemberCount = 0
    -- 前节点
    self.FrontNodes = nil
    -- 后节点
    self.NextNodes = nil
    --父节点
    self.ParentNode = nil
    --子节点
    self.ChildrenNodes = nil
    -- 战斗次数
    self.FightCount = 0
    -- 是否死亡过，前哨重建后，也能经过
    self.IsDead = nil
    self.BossLevel = 0
    self.IsJustDestroyed = false
end

-- data : XGuildWarNodeData
function XGWNode:UpdateWithServerData(data)
    if data == nil then
        data = {}
    end
    self.UID = data.Uid
    self.HP = data.CurHp or 0
    self.MaxHP = data.HpMax or self.Config.HpMax
    self.FightCount = data.FightCount or 0
    self.MemberCount = data.CurMember or 0
    if self.IsDead == false and data.IsDead > 0 then
        self:SetIsJustDestroyed(true)
    end
    self.IsDead = data.IsDead and (data.IsDead > 0) and true or false
    self.BossLevel = data.CurBossLevel or 0
    self.BossLevel = self.BossLevel + 1
end

function XGWNode:GetId()
    return self.Config.Id
end

function XGWNode:GetUID()
    return self.UID
end

function XGWNode:GetName()
    return self.Config.Name
end

function XGWNode:GetNameEn()
    return self.Config.NameEn
end

function XGWNode:GetDesc()
    return XUiHelper.ReplaceTextNewLine(self.Config.Desc)
end

function XGWNode:GetDifficultyId()
    return self.Config.DifficultyId
end

function XGWNode:GetIcon()
    return self.Config.Icon
end

function XGWNode:GetShowMonsterIcon()
    return self.Config.ShowMonsterIcon
end

function XGWNode:GetShowMonsterName()
    return self.Config.ShowMonsterName
end

function XGWNode:GetGroupIndex()
    return self.Config.GroupIndex
end

function XGWNode:GetStageIndex()
    return self.Config.StageIndex
end

function XGWNode:GetStageIndexName()
    return string.format("%d_%d", self:GetGroupIndex(), self:GetStageIndex())
end

-- 获取节点会长标志的下标，没有标记则为-1
function XGWNode:GetPathIndex()
    return XDataCenter.GuildWarManager.GetBattleManager():GetNodePathIndex(self:GetId()) or -1
end

-- 检测是否为会长标记节点
function XGWNode:GetIsPlanNode()
    return self:GetPathIndex() >= 0
end

-- 获取节点血量
function XGWNode:GetHP()
    return self.HP
end

-- 获取节点最大血量
function XGWNode:GetMaxHP()
    return self.MaxHP
end

function XGWNode:GetIsDead()
    return self.IsDead
end

-- 获取百分比血量
function XGWNode:GetPercentageHP()
    local value = (self:GetHP() / self:GetMaxHP()) * 100
    if value > 0 and value < 1 then
        value = math.max(value, 1)
    end
    return string.format("%s%%", getRoundingValue(value, 2))
end

-- 获取节点当前成员人数
function XGWNode:GetMemberCount()
    return self.MemberCount
end

function XGWNode:GetNodeType()
    return self.Config.Type
end

function XGWNode:GetIsCanBattle()
    return false
end

--玩家是否在这个节点上
function XGWNode:GetIsPlayerNode()
    return XDataCenter.GuildWarManager.GetBattleManager():GetCurrentNodeId() == self:GetId()
end
--是否基地节点
function XGWNode:GetIsBaseNode()
    return self:GetNodeType() == XGuildWarConfig.NodeType.Home
end
--是否哨塔节点
function XGWNode:GetIsSentinelNode()
    return self:GetNodeType() == XGuildWarConfig.NodeType.Sentinel
end
--是否一期感染区
function XGWNode:GetIsInfectNode()
    return self:GetNodeType() == XGuildWarConfig.NodeType.Infect
end
--是否二期黑白鲨 大地图根节点
function XGWNode:GetIsPandaRootNode()
    return self:GetNodeType() == XGuildWarConfig.NodeType.PandaRoot
end
--是否二期黑白鲨区
function XGWNode:GetIsPandaNode()
    return XGuildWarConfig.PandaNodeType[self:GetNodeType()] or false
end
--是否三期双子区
function XGWNode:GetIsTwinsNode()
    return XGuildWarConfig.TwinsNodeType[self:GetNodeType()] or false
end
--是否四期封锁点
function XGWNode:GetIsBlockadeNode()
    return self:GetNodeType() == XGuildWarConfig.NodeType.Blockade
end
--是否四期boss
function XGWNode:GetIsTerm4Boss()
    return XGuildWarConfig.Term4BossNodeType[self:GetNodeType()] or false
end
--是否BOSS区域
function XGWNode:GetIsLastNode()
    return XGuildWarConfig.LastNodeType[self:GetNodeType()] or false
end
--是否残留区(击倒后的遗迹状态)
function XGWNode:GetIsRuinsStatus()
    return false
end
function XGWNode:GetRebuildProgress()
    -- 获取重建进度
    return 0
end

function XGWNode:GetIsInBattle()
    return false
end

-- 获取节点状态：正常，复活中，死亡
-- return : XGuildWarConfig.NodeStatusType
function XGWNode:GetStutesType()
    if self:GetHP() <= 0 then
        return XGuildWarConfig.NodeStatusType.Die
    end
    return XGuildWarConfig.NodeStatusType.Alive
end

-- 获得区域提示
function XGWNode:GetAreaTip()
    local stutesType = self:GetStutesType()
    if stutesType == XGuildWarConfig.NodeStatusType.Die then
        return "GuildWarAreaTipDie"
    end
    if stutesType == XGuildWarConfig.NodeStatusType.Revive then
        return "GuildWarAreaTipRevive"
    end
    if stutesType == XGuildWarConfig.NodeStatusType.Alive then
        return "GuildWarAreaTipAlive"
    end
end

-- 获取 路线之前节点列表
-- return { XGWNode }
function XGWNode:GetFrontNodes()
    if self.FrontNodes == nil then
        local parentIds = XGuildWarConfig.GetFrontNodeIdsByNodeId(self:GetId())
        self.FrontNodes = {}
        for _, parentId in ipairs(parentIds) do
            table.insert(self.FrontNodes, XDataCenter.GuildWarManager.GetBattleManager():GetNode(parentId))
        end
    end
    return self.FrontNodes
end

-- 获取 路线之后节点列表
-- return { XGWNode } 
function XGWNode:GetNextNodes()
    if self.NextNodes == nil then
        self.NextNodes = {}
        for _, linkId in ipairs(self.Config.LinkIds) do
            table.insert(self.NextNodes, XDataCenter.GuildWarManager.GetBattleManager():GetNode(linkId))
        end
    end
    return self.NextNodes
end

--获取父节点ID
function XGWNode:GetParentId()
    return self.Config.RootId
end

--判断自己是否子节点
function XGWNode:IsChildNode()
    return not (self.Config.RootId == 0)
end

-- 获取 父节点
-- return XGWNode
function XGWNode:GetParentNode()
    local parentId = self:GetParentId()
    if self.ParentNode == nil and parentId then
        self.ParentNode = XDataCenter.GuildWarManager.GetBattleManager():GetNode(parentId)
    end
    return self.ParentNode
end

--检查是否存在子节点
function XGWNode:CheckChildExist(node)
    return not (self:GetChildIndexByChildId(node:GetId()) == 0)
end

-- 通过子节点索引 获取子节点ID
function XGWNode:GetChildIdByIndex(index)
    return XGuildWarConfig.GetChildNodeId(self:GetId(), index)
end

-- 通过子节点索引 获取子节点
function XGWNode:GetChildByIndex(index)
    return XDataCenter.GuildWarManager.GetChildNode(self:GetId(), index)
end

-- 通过子节点ID 获取子节点
function XGWNode:GetChildById(nodeId)
    for _, childId in ipairs(XGuildWarConfig.GetNodesChildren(self:GetId())) do
        if nodeId == childId then
            return XDataCenter.GuildWarManager.GetBattleManager():GetNode(nodeId)
        end
    end
    XLog.Error("XGWNode:" .. self.GetId() .. " cant find child:" .. nodeId)
    return nil
end

-- 获取 子节点
-- return XGWNode[]
function XGWNode:GetChildrenNodes()
    if self.ChildrenNodes == nil then
        self.ChildrenNodes = {}
        for _, childId in ipairs(XGuildWarConfig.GetNodesChildren(self:GetId())) do
            table.insert(self.ChildrenNodes, XDataCenter.GuildWarManager.GetBattleManager():GetNode(childId))
        end
    end
    return self.ChildrenNodes
end

--获取子节点的索引
function XGWNode:GetChildIndexByChildId(nodeId)
    for index, childId in ipairs(XGuildWarConfig.GetNodesChildren(self:GetId())) do
        if childId == nodeId then
            return index
        end
    end
    return 0
end

function XGWNode:GetRewardId()
    return self.Config.RewardId
end

function XGWNode:GetHelpTitle()
    return self.Config.HelpTitle
end

function XGWNode:GetHelpDetail()
    return self.Config.HelpDetail
end

function XGWNode:GetFightEventIds()
    return self.Config.FightEventId
end

function XGWNode:GetShowFightEventId()
    return self.Config.ShowFightEventId
end

-- StageFightEventDetails 配置表
function XGWNode:GetFightEventDetailConfig()
    return XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(self:GetShowFightEventId()[1])
end

function XGWNode:GetAllFightEventDetailConfig()
    local showFightEventId = self:GetShowFightEventId()
    local result = {}
    for i = 1, #showFightEventId do
        local id = showFightEventId[i]
        local detail = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(id)
        result[#result + 1] = detail
    end
    return result
end

function XGWNode:CheckIsCanGo()
    local currentNodeId = XDataCenter.GuildWarManager.GetBattleManager():GetCurrentNodeId()
    if self:GetId() == currentNodeId then
        return false
    end
    -- 基地 true 
    if self:GetIsBaseNode() then
        return true
    end
    -- 已击破 true
    if self:GetIsDead() then
        return true
    end
    -- 最终节点,但近卫未击破 false
    if self:GetIsLastNode()
            and not self:GetAllGuardIsDead() then
        return false
    end
    -- 父节点里有任意节点已击破 or是基地 true
    local parentNodes = self:GetFrontNodes()
    for i = 1, #parentNodes do
        local node = parentNodes[i]
        if node:GetIsDead() or node:GetIsBaseNode() then
            return true
        end
    end
    -- false
    return false
end

function XGWNode:GetAllGuardIsDead()
    return XDataCenter.GuildWarManager:GetBattleManager():GetAllGuardIsDead()
end

--获取关卡ID
function XGWNode:GetStageId()
    local gwStageId = XGuildWarConfig.GetNodeGuildWarStageId(self:GetId())
    return XGuildWarConfig.GetStageId(gwStageId)
end

--获取推荐战力
function XGWNode:GetAbility()
    local gwStageId = XGuildWarConfig.GetNodeGuildWarStageId(self:GetId())
    return XGuildWarConfig.GetStageAbility(gwStageId)
end

--在公共节点Detail界面点击移动 并且移动到这个节点时回调 (return false的话正常执行公共逻辑 return true的话 截断公共逻辑)
function XGWNode:OnDetailGoCallback()
    return false
end

function XGWNode:GetSelfChildIndex()
    local parentNode = self:GetParentNode()
    return parentNode:GetChildIndexByChildId(self:GetId())
end
-- 获取模型ID
function XGWNode:GetModelId()
    return XGuildWarConfig.GetNodeModelId(self:GetId())
end
---@return number@ 复活次数
function XGWNode:GetBossLevel()
    return self.BossLevel
end

function XGWNode:GetIsJustDestroyed()
    return self.IsJustDestroyed
end

function XGWNode:SetIsJustDestroyed(value)
    self.IsJustDestroyed = value
end

---@param node XGWNode
function XGWNode:IsLink2TheEndUnpassBlockade(passedNodes)
    if not passedNodes then
        passedNodes = {}
    end
    ---@type XGWNode[]
    local nextNodes = self:GetNextNodes()
    for i = 1, #nextNodes do
        local nextNode = nextNodes[i]
        if not passedNodes[nextNode] then
            passedNodes[nextNode] = true
            if not nextNode:GetIsBlockadeNode() then
                if nextNode:GetIsLastNode() then
                    return true
                end
                if nextNode:IsLink2TheEndUnpassBlockade(passedNodes) then
                    return true
                end
            end
        end
    end
    return false
end

return XGWNode
