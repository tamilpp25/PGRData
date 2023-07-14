local XANode = require("XEntity/XBiancaTheatre/Adventure/Node/XANode")
local XARewardNode = require("XEntity/XBiancaTheatre/Adventure/Node/XARewardNode")
local XABattleNode = XClass(XANode, "XABattleNode")

function XABattleNode:Ctor()
    -- 奖励类型
    self.RewarType = XBiancaTheatreConfigs.AdventureRewardType.None
    -- 获取关卡配置
    self.TheatreStageConfig = nil
    -- 节点事件配置
    self.EventClientConfig = nil
    -- 战斗中的关卡Id列表
    self.StageIds = {}
    -- 已通关的关卡Id，Id可重复
    self.PassedStageIds = {}
    -- 已通关的关卡索引，多队伍用
    self.PassedStageIndexs = {}
end

function XABattleNode:InitWithServerData(data)
    XABattleNode.Super.InitWithServerData(self, data)
    -- 获取关卡配置
    self.TheatreStageConfig = XBiancaTheatreConfigs.GetBiancaTheatreFightStageTemplate(data.FightTemplateId, true)
    -- 节点事件配置
    self.EventClientConfig = XBiancaTheatreConfigs.GetBiancaTheatreFightNodeClient(data.FightId)
    -- 获取奖励类型
    self.RewarType = data.RewardType or XBiancaTheatreConfigs.AdventureRewardType.None
    -- 战斗中的关卡Id列表
    self.StageIds = data.StageIds
    -- 已通关的关卡Id，Id可重复
    self.PassedStageIds = data.PassedStageIds
end

function XABattleNode:UpdatePassedStageIndexs(passedStageIndexs)
    for i, passedStageIndex in ipairs(passedStageIndexs or {}) do
        self.PassedStageIndexs[passedStageIndex] = true
    end
end

-- 获取推荐战力
function XABattleNode:GetSuggestPower()
    return self.TheatreStageConfig.SuggestAbility
end

-- 获取战斗携带的奖励类型
function XABattleNode:GetRewardType()
    return self.RewarType
end

function XABattleNode:GetRewardTypeIcon()
    return XBiancaTheatreConfigs.GetRewardTypeIcon(self:GetRewardType(), self.RawData.PowerId)
end

function XABattleNode:GetTeamCount()
    return #self.TheatreStageConfig.StageId
end

function XABattleNode:GetShowDatas()
    local result = {}
    local nodeRewardData = self.RawData.NodeRewards[1]
    if nodeRewardData then
        table.insert(result, {
            rewardNode = XARewardNode.New(nodeRewardData)
        })
    end
    return result
end

function XABattleNode:Trigger()
    XABattleNode.Super.Trigger(self, function()
        XLuaUiManager.Open("UiBattleRoleRoom"
            , self.TheatreStageConfig.StageId
            , XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetSingleTeam()
            , require("XUi/XUiBiancaTheatre/XUiBiancaTheatreBattleRoleRoom"))
    end)
end

function XABattleNode:EnterFight(index)
    if index == nil then index = 1 end
    XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
        :EnterFight(self.TheatreStageConfig.Id, index)
end

function XABattleNode:GetStageIds()
    return self.StageIds
end

function XABattleNode:SetStageFinish(stageId, index)
    if not index or index <= 0 then
        return
    end

    self.PassedStageIndexs[index] = true
end

function XABattleNode:IsStageFinish(index)
    return self.PassedStageIndexs[index] or false
end

function XABattleNode:GetPassedStageIds()
    return self.PassedStageIds
end

function XABattleNode:ResetFinishStage(index)
    self.PassedStageIndexs[index] = false
end

function XABattleNode:GetTheatreStageId()
    return self.TheatreStageConfig.Id
end

function XABattleNode:GetIsBattle()
    return true
end

function XABattleNode:GetNodeTypeIcon()
    if self.EventClientConfig and self.EventClientConfig.NodeTypeIcon then
        return self.EventClientConfig.NodeTypeIcon
    end
    return XABattleNode.Super.GetNodeTypeIcon(self)
end

function XABattleNode:GetNodeTypeDesc()
    if self.EventClientConfig and self.EventClientConfig.NodeTypeDesc then
        return self.EventClientConfig.NodeTypeDesc
    end
    return XABattleNode.Super.GetNodeTypeDesc(self)
end

function XABattleNode:GetNodeTypeName()
    if self.EventClientConfig and self.EventClientConfig.NodeTypeName then
        return self.EventClientConfig.NodeTypeName
    end
    return XABattleNode.Super.GetNodeTypeName(self)
end

--获得首个战斗节点奖励预览
function XABattleNode:GetNodeReward()
    local nodeRewardData = self.RawData.NodeRewards[1]
    if not nodeRewardData then
        return
    end
    self.NodeReward = self.NodeReward or XARewardNode.New(nodeRewardData)
    return self.NodeReward
end

function XABattleNode:GetNodeTypeSmallIcon()
    return self.EventClientConfig and self.EventClientConfig.SmallIcon or XABattleNode.Super.GetNodeTypeSmallIcon(self)
end

return XABattleNode 
