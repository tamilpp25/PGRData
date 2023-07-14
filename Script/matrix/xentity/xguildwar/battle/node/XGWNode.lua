local XGWNode = XClass(nil, "XGWNode")

function XGWNode:Ctor(id)
    self.Config = XGuildWarConfig.GetNodeConfig(id)
    self.UID = 0
    -- 节点血量
    self.HP = self.Config.HpMax
    -- 节点最大血量
    self.MaxHP = self.Config.HpMax
    -- 当前到达该节点的人数
    self.MemberCount = 0
    -- 父节点
    self.ParentNodes = nil
    -- 子节点
    self.ChildNodes = nil
    -- 战斗次数
    self.FightCount = 0
    -- 是否死亡过，前哨重建后，也能经过
    self.IsDead = false
end

-- data : XGuildWarNodeData
function XGWNode:UpdateWithServerData(data)
    if data == nil then data = {} end
    self.UID = data.Uid
    self.HP = data.CurHp or 0
    self.MaxHP = data.HpMax or self.Config.HpMax
    self.FightCount = data.FightCount or 0
    self.MemberCount = data.CurMember or 0
    self.IsDead = data.IsDead and (data.IsDead > 0) and true or false
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
    return self.Config.Desc
end

function XGWNode:GetDifficultyId()
    return self.Config.DifficultyId
end

function XGWNode:GetIcon()
    return self.Config.Icon
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
function XGWNode:GetIsTargetNode()
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

function XGWNode:GetUID()
    return self.UID
end

-- 获取百分比血量
function XGWNode:GetPercentageHP()
    local value = (self:GetHP() / self:GetMaxHP()) * 100
    if value > 0 and value < 1 then
        value = math.max(value, 1)
    end
    return string.format( "%s%%", getRoundingValue(value , 2))
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

function XGWNode:GetIsPlayerNode()
    return XDataCenter.GuildWarManager.GetBattleManager():GetCurrentNodeId() == self:GetId()
end

function XGWNode:GetIsBaseNode()
    return self:GetNodeType() == XGuildWarConfig.NodeType.Home
end

function XGWNode:GetIsSentinelNode()
    return self:GetNodeType() == XGuildWarConfig.NodeType.Sentinel
end

function XGWNode:GetIsInfectNode()
    return self:GetNodeType() == XGuildWarConfig.NodeType.Infect
end

function XGWNode:GetRebuildProgress()-- 获取重建进度
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

-- return { XGWNode }
function XGWNode:GetParentNodes()
    if self.ParentNodes == nil then
        local parentIds = XGuildWarConfig.GetParentNodeIdsByNodeId(self:GetId())
        self.ParentNodes = {}
        for _, parentId in ipairs(parentIds) do
            table.insert(self.ParentNodes, XDataCenter.GuildWarManager.GetBattleManager():GetNode(parentId))
        end    
    end
    return self.ParentNodes
end

-- return { XGWNode }
function XGWNode:GetChildNodes()
    if self.ChildNodes == nil then
        self.ChildNodes = {}
        for _, linkId in ipairs(self.Config.LinkIds) do
            table.insert(self.ChildNodes, XDataCenter.GuildWarManager.GetBattleManager():GetNode(linkId))
        end    
    end
    return self.ChildNodes
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
    return XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(self:GetShowFightEventId())
end

function XGWNode:CheckIsCanGo()
    local battleManager = XDataCenter.GuildWarManager.GetBattleManager()
    local currentNodeId = battleManager:GetCurrentNodeId()
    if self:GetId() == currentNodeId then
        return false
    end
    local currentNode = battleManager:GetNode(currentNodeId)
    for _, node in ipairs(currentNode:GetParentNodes()) do
        if node:GetId() == self:GetId() then
            return true
        end
    end
    for _, node in ipairs(currentNode:GetChildNodes()) do
        if node:GetId() == self:GetId() then
            return true
        end
    end
    return false
end

return XGWNode