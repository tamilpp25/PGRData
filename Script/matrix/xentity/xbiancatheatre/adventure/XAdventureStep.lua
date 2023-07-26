local XAMovieNode = require("XEntity/XBiancaTheatre/Adventure/Node/XAMovieNode")
local XABattleNode = require("XEntity/XBiancaTheatre/Adventure/Node/XABattleNode")
local XAShopNode = require("XEntity/XBiancaTheatre/Adventure/Node/XAShopNode")
local XAEventNode = require("XEntity/XBiancaTheatre/Adventure/Node/Event/XAEventNode")
local XABattleEventNode = require("XEntity/XBiancaTheatre/Adventure/Node/Event/XABattleEventNode")
local XAGlobalRewardEventNode = require("XEntity/XBiancaTheatre/Adventure/Node/Event/XAGlobalRewardEventNode")
local XALocalRewardEventNode = require("XEntity/XBiancaTheatre/Adventure/Node/Event/XALocalRewardEventNode")
local XASelectableEventNode = require("XEntity/XBiancaTheatre/Adventure/Node/Event/XASelectableEventNode")
local XATalkEventNode = require("XEntity/XBiancaTheatre/Adventure/Node/Event/XATalkEventNode")
local XMovieEventNode = require("XEntity/XBiancaTheatre/Adventure/Node/Event/XMovieEventNode")
local XARewardNode = require("XEntity/XBiancaTheatre/Adventure/Node/XARewardNode")

--肉鸽2.0步骤
local XAdventureStep = XClass(nil, "XAdventureStep")

local NodeType2Class = {
    [XBiancaTheatreConfigs.NodeType.Fight] = XABattleNode,
    [XBiancaTheatreConfigs.NodeType.Event] = {
        [XBiancaTheatreConfigs.EventNodeType.Talk] = XATalkEventNode,
        [XBiancaTheatreConfigs.EventNodeType.Selectable] = XASelectableEventNode,
        [XBiancaTheatreConfigs.EventNodeType.LocalReward] = XALocalRewardEventNode,
        [XBiancaTheatreConfigs.EventNodeType.GlobalReward] = XAGlobalRewardEventNode,
        [XBiancaTheatreConfigs.EventNodeType.Battle] = XABattleEventNode,
        [XBiancaTheatreConfigs.EventNodeType.Movie] = XMovieEventNode,
        [XBiancaTheatreConfigs.EventNodeType.FightNoSkill] = XABattleEventNode,
    },
    [XBiancaTheatreConfigs.NodeType.Shop] = XAShopNode,
}

local CreateNode = function(data)
    local classDefine = NodeType2Class[data.SlotType]
    if data.SlotType == XBiancaTheatreConfigs.NodeType.Event then
        local config = XBiancaTheatreConfigs.GetEventNodeConfig(data.EventId, data.CurStepId)
        if config == nil then
            return 
        end
        classDefine = classDefine[config.Type]
    end
    local result = classDefine.New()
    result:InitWithServerData(data)
    return result
end

function XAdventureStep:Ctor(data)
    --唯一ID
    self.Uid = data.Uid
    --步骤类型, XBiancaTheatreConfigs.XStepType
    self.StepType = data.StepType
    --上级步骤UID，例如招募角色的上级步骤是招募券选择
    self.RootUid = data.RootUid
    --当前步骤是否已过期，例如招募角色步骤完成后，当前步骤过期
    self:SetOverdue(data.Overdue)

    --====================道具箱奖励， 3选1==============
    --肉鸽物品ID
    self.ItemIds = data.ItemIds
    --已选择道具ID
    self.SelectedItemId = data.SelectedItemId
    --是否是章节额外奖励
    self.IsExTraReward = data.IsExtraReward

    --====================招募券选择================
    self.TickIds = data.TickIds

    --====================招募角色==================
    --招募券ID
    local tickId = data.TickId
    self.TickId = tickId
    if XTool.IsNumberValid(tickId) then
        XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():UpdateSelectTickId(tickId)
    end
    --已刷新的角色
    self.RefreshCharacterIds = data.RefreshCharacterIds
    --已招募的角色
    self:InitRecruitCharacterId()
    -- 触发保底的索引
    self.FloorIndexes = data.FloorIndexes
    for _, characterId in ipairs(data.RecruitCharacterIds) do
        self:UpdateRecruitCharacterId(characterId)
    end
    --刷新次数
    self.RefreshCount = data.RefreshCount
    --已招募次数
    self.RecruitCount = data.RecruitCount
    --当前刷新次数
    self:UpdateCurRefreshCount(data.CurRefreshCount)
    --当前招募次数
    self:UpdateCurRecruitCount(data.CurRecruitCount)

    --=====================节点=======================
    --节点数据
    self:UpdateCurrentNode(data.NodeData)

    --=====================战斗后奖励选择=================
    --奖励界面里的选项，金币组，道具箱，招募券
    self:UpdateFightRewards(data.FightRewards)
end

function XAdventureStep:InitRecruitCharacterId()
    self.RecruitCharacterIdDic = {}
end

function XAdventureStep:UpdateRecruitCharacterId(characterId)
    self.RecruitCharacterIdDic[characterId] = true
end

function XAdventureStep:SetOverdue(overdue)
    self.Overdue = overdue
end

function XAdventureStep:UpdateCurRefreshCount(curRefreshCount)
    self.CurRefreshCount = curRefreshCount
end

function XAdventureStep:UpdateCurRecruitCount(curRecruitCount)
    self.CurRecruitCount = curRecruitCount
end

function XAdventureStep:UpdateFightRewards(fightRewards)
    self.FightRewards = {}
    for _, value in ipairs(fightRewards) do
        table.insert(self.FightRewards, XARewardNode.New(value))
    end
end

function XAdventureStep:UpdateCurrentNode(data)
    if not data then
        return
    end
    
    self.CurrentNodes = {}
    self.CurrentNodeId = data.NodeId
    for _, nodeSlot in ipairs(data.Slots) do
        --事件节点的当前步骤Id，最后一个步骤结束后会置为0
        if nodeSlot.SlotType == XBiancaTheatreConfigs.NodeType.Event and not XTool.IsNumberValid(nodeSlot.CurStepId) then
            goto continue
        end
        
        local newNode = CreateNode(nodeSlot)
        if newNode then
            table.insert(self.CurrentNodes, newNode)
        else
            XLog.Error("找不到对应的节点数据：", nodeSlot)
        end
        
        :: continue ::
    end
end

function XAdventureStep:GetCurrentNodes()
    return self.CurrentNodes or {}
end

--获得已选择的节点类型
function XAdventureStep:GetSelectNodeType()
    for _, node in ipairs(self:GetCurrentNodes()) do
        if node:GetIsSelected() then
            return node:GetNodeType()
        end
    end
end

function XAdventureStep:GetCurrentNodeId()
    return self.CurrentNodeId
end

-- 更新下一个事件节点
function XAdventureStep:UpdateNextEventNode(node, newData)
    for index, value in ipairs(self:GetCurrentNodes()) do
        if value == node then
            local newNode = CreateNode(newData)
            if newNode then
                self.CurrentNodes[index] = newNode
                return self.CurrentNodes[index]
            else
                table.remove(self.CurrentNodes, index)
                return nil
            end
        end
    end
end

function XAdventureStep:GetStepType()
    return self.StepType
end

function XAdventureStep:GetRootUid()
    return self.RootUid
end

function XAdventureStep:GetIsExTraReward()
    return self.IsExTraReward
end

function XAdventureStep:GetRootStepType()
    local curChapter = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetCurrentChapter(false)
    if not curChapter then
        return
    end

    local rootStep = curChapter:GetStepByUid(self:GetRootUid())
    return rootStep and rootStep:GetStepType()
end

--获得步骤根节点是否是选项事件
function XAdventureStep:GetRootStepIsSelectableEvent()
    local curChapter = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetCurrentChapter(false)
    if not curChapter then
        return false
    end

    local rootStep = curChapter:GetStepByUid(self:GetRootUid())
    if not rootStep then
        return false
    end
    if rootStep:GetStepType() ~= XBiancaTheatreConfigs.XStepType.Node then
        return false
    end
    
    local curNode = curChapter:GetCurrentNode(rootStep)
    return curNode and curNode:GetNodeType() == XBiancaTheatreConfigs.EventNodeType.Selectable
end

function XAdventureStep:IsOverdue()
    return XTool.IsNumberValid(self.Overdue)
end

function XAdventureStep:GetItemIds()
    return self.ItemIds
end

function XAdventureStep:GetSelectedItemId()
    return self.SelectedItemId
end

function XAdventureStep:GetTickIds()
    table.sort(self.TickIds, function(idA, idB)
        local qualityA = XBiancaTheatreConfigs.GetRecruitTicketQuality(idA)
        local qualityB = XBiancaTheatreConfigs.GetRecruitTicketQuality(idB)
        if qualityA ~= qualityB then
            return qualityA > qualityB
        end
        return idA < idB
    end)
    return self.TickIds
end

function XAdventureStep:GetTickId()
    return self.TickId
end

function XAdventureStep:GetRefreshCharacterIds()
    return self.RefreshCharacterIds
end

function XAdventureStep:GetFloorIndexes()
    return self.FloorIndexes
end

--角色是否已招募
function XAdventureStep:IsRecruitCharacter(characterId)
    return self.RecruitCharacterIdDic[characterId] or false
end

function XAdventureStep:GetRefreshCount()
    return self.RefreshCount
end

function XAdventureStep:GetRecruitCount()
    return self.RecruitCount
end

function XAdventureStep:GetCurRefreshCount()
    return self.CurRefreshCount
end

function XAdventureStep:GetCurRecruitCount()
    return self.CurRecruitCount
end

function XAdventureStep:GetNodeData()
    return self.NodeData
end

function XAdventureStep:GetFightRewards()
    return self.FightRewards
end

--获得未领取的战斗奖励列表
function XAdventureStep:GetNotReceivedFightRewards()
    local notReceivedFightRewards = {}
    local fightRewards = self:GetFightRewards()
    for _, fightReward in ipairs(fightRewards) do
        if not fightReward:IsReceived() then
            table.insert(notReceivedFightRewards, fightReward)
        end
    end
    return notReceivedFightRewards
end

return XAdventureStep