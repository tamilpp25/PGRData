local XANode = require("XEntity/XTheatre/Adventure/Node/XANode")
local XABattleNode = XClass(XANode, "XABattleNode")

function XABattleNode:Ctor()
    -- 奖励类型
    self.RewarType = XTheatreConfigs.AdventureRewardType.None
    -- 获取关卡配置
    self.TheatreStageConfig = nil
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
    self.TheatreStageConfig = XTheatreConfigs.GetTheatreStage(data.TheatreStageId)
    -- 获取奖励类型
    self.RewarType = data.RewardType or XTheatreConfigs.AdventureRewardType.None
    -- 战斗中的关卡Id列表
    self.StageIds = data.StageIds
    -- 已通关的关卡Id，Id可重复
    self.PassedStageIds = data.PassedStageIds
    -- 已通关的关卡索引，多队伍用
    self:UpdatePassedStageIndexs(data.PassedStageIndexs)
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
    return XTheatreConfigs.GetRewardTypeIcon(self:GetRewardType(), self.RawData.PowerId)
end

function XABattleNode:GetTeamCount()
    return #self.TheatreStageConfig.StageId
end

function XABattleNode:GetShowDatas()
    local result = {}
    if self:GetNodeType() == XTheatreConfigs.NodeType.Random 
        and self:GetRewardType() > 0 then
        table.insert(result, {
            rewardType = self:GetRewardType(),
            showIcon = self:GetRewardTypeIcon(),
            powerId = self.RawData.PowerId
        })
    end
    if self.TheatreStageConfig.RewardId > 0 then
        table.insert(result, {
            rewardType = XTheatreConfigs.AdventureRewardType.RewardId,
            rewardId = self.TheatreStageConfig.RewardId
        })
    end
    return result
end

function XABattleNode:Trigger()
    XABattleNode.Super.Trigger(self, function()
        if self:GetTeamCount() <= 1 then
            XLuaUiManager.Open("UiBattleRoleRoom"
                , self.TheatreStageConfig.StageId[1]
                , XDataCenter.TheatreManager.GetCurrentAdventureManager():GetSingleTeam()
                , require("XUi/XUiTheatre/XUiTheatreBattleRoleRoom"))
        else
            -- 进入多队伍编队界面
            XLuaUiManager.Open("UiTheatreDeploy", self.TheatreStageConfig.Id)
        end
        
    end)
end

function XABattleNode:EnterFight(index)
    if index == nil then index = 1 end
    XDataCenter.TheatreManager.GetCurrentAdventureManager()
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

return XABattleNode 
