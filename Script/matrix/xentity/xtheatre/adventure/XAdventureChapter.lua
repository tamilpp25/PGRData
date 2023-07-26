local XAMovieNode = require("XEntity/XTheatre/Adventure/Node/XAMovieNode")
local XABattleNode = require("XEntity/XTheatre/Adventure/Node/XABattleNode")
local XAShopNode = require("XEntity/XTheatre/Adventure/Node/XAShopNode")
local XAEventNode = require("XEntity/XTheatre/Adventure/Node/Event/XAEventNode")
local XABattleEventNode = require("XEntity/XTheatre/Adventure/Node/Event/XABattleEventNode")
local XAGlobalRewardEventNode = require("XEntity/XTheatre/Adventure/Node/Event/XAGlobalRewardEventNode")
local XALocalRewardEventNode = require("XEntity/XTheatre/Adventure/Node/Event/XALocalRewardEventNode")
local XASelectableEventNode = require("XEntity/XTheatre/Adventure/Node/Event/XASelectableEventNode")
local XATalkEventNode = require("XEntity/XTheatre/Adventure/Node/Event/XATalkEventNode")
local XMovieEventNode = require("XEntity/XTheatre/Adventure/Node/Event/XMovieEventNode")
local XANode = require("XEntity/XTheatre/Adventure/Node/XANode")
local XAdventureRole = require("XEntity/XTheatre/Adventure/XAdventureRole")
local XAdventureChapter = XClass(nil, "XAdventureChapter")

local NodeType2Class = {
    [XTheatreConfigs.NodeType.Event] = {
        [XTheatreConfigs.EventNodeType.Talk] = XATalkEventNode,
        [XTheatreConfigs.EventNodeType.Selectable] = XASelectableEventNode,
        [XTheatreConfigs.EventNodeType.LocalReward] = XALocalRewardEventNode,
        [XTheatreConfigs.EventNodeType.GlobalReward] = XAGlobalRewardEventNode,
        [XTheatreConfigs.EventNodeType.Battle] = XABattleEventNode,
        [XTheatreConfigs.EventNodeType.Movie] = XMovieEventNode,
    },
    [XTheatreConfigs.NodeType.Shop] = XAShopNode,
    [XTheatreConfigs.NodeType.Battle] = XABattleNode,
    [XTheatreConfigs.NodeType.Random] = XABattleNode, -- 目前随机类型本质上只有战斗节点
    [XTheatreConfigs.NodeType.MovieBattle] = XABattleNode, -- 剧情关本质上只有战斗节点
    [XTheatreConfigs.NodeType.Movie] = XAMovieNode, -- 剧情关本质上只有战斗节点
}

local CreateNode = function(data)
    local classDefine = NodeType2Class[data.SlotType]
    if data.SlotType == XTheatreConfigs.NodeType.Event then
        local config = XTheatreConfigs.GetEventNodeConfig(data.ConfigId, data.CurStepId)
        if config == nil then
            return 
        end
        classDefine = classDefine[config.Type]
    end
    local result = classDefine.New()
    result:InitWithServerData(data)
    return result
end

function XAdventureChapter:Ctor(id)
    self.CurrentChapterId = id
    self.Config = XTheatreConfigs.GetTheatreChapter(id)
    -- 当前招募刷新的次数
    self.RefreshRoleCount = self:GetRefreshRoleMaxCount()
    -- 当前的节点数据 XANode
    self.CurrentNodes = {}
    -- 当前可招募的角色 XAdventureRole
    self.RecruitRoleDic = nil
    -- 等待选择的技能，PS:在选择技能期间重登会拥有部分数据
    self.WaitSelectableSkillIds = nil
    -- 当前服务器返回的节点Id
    self.CurrentNodeId = nil
    -- 当前通过的节点数
    self.CurrentPassNodeCount = 0
    -- 是否已准备好
    self.IsReady = false
end

function XAdventureChapter:SetIsReady(value)
    self.IsReady = value
end

function XAdventureChapter:GetIsReady()
    return self.IsReady
end

function XAdventureChapter:GetId()
    return self.Config.Id
end

function XAdventureChapter:GetCurrentNodeId()
    return self.CurrentNodeId
end

function XAdventureChapter:InitWithServerData(data)
    -- 更新角色刷新次数
    self.RefreshRoleCount = self:GetRefreshRoleMaxCount() - data.RefreshRoleCount
    -- 更新等待可选择的技能
    self.WaitSelectableSkillIds = data.SkillToSelect
    if #self.WaitSelectableSkillIds > 0 then
        XDataCenter.TheatreManager.GetCurrentAdventureManager():AddNextOperationData({
            OperationQueueType = XTheatreConfigs.OperationQueueType.NodeReward,
            RewardType = XTheatreConfigs.AdventureRewardType.SelectSkill,
            Skills = self.WaitSelectableSkillIds,
        })
    end
    -- 更新已刷新出来的角色
    self.RecruitRoleDic = {}
    for index, roleId in ipairs(data.RefreshRole) do
        if roleId > 0 then
            self.RecruitRoleDic[index] = XAdventureRole.New(roleId)
        end
    end
    -- 更新当前的节点
    self:UpdateCurrentNode(data.CurNodeDb)
    self.CurrentPassNodeCount = data.PassNodeCount or 0
end

function XAdventureChapter:UpdateWaitSelectableSkillIds(value)
    self.WaitSelectableSkillIds = value
end

function XAdventureChapter:GetWaitSelectableSkillIds()
    return self.WaitSelectableSkillIds
end

function XAdventureChapter:UpdateCurrentNode(data)
    self.CurrentNodes = {}
    self.CurrentNodeId = data.NodeId
    for _, data in ipairs(data.Slots) do
        local newNode = CreateNode(data)
        if newNode then
            table.insert(self.CurrentNodes, newNode)
        else
            XLog.Error("找不到对应的节点数据：", data)
        end
    end
end

function XAdventureChapter:AddPassNodeCount(value)
    self.CurrentPassNodeCount = self.CurrentPassNodeCount + value
end

function XAdventureChapter:GetCurrentPassNodeCount()
    return self.CurrentPassNodeCount
end

-- 更新下一个事件节点
function XAdventureChapter:UpdateNextEventNode(node, newData)
    for index, value in ipairs(self.CurrentNodes) do
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

function XAdventureChapter:GetEventNode(evenId)
    for _, node in ipairs(self.CurrentNodes) do
        if node:GetNodeType() == XTheatreConfigs.NodeType.Event 
            and node:GetEventId() == evenId then
            return node
        end
    end
end

function XAdventureChapter:GetCurrentNode()
    for _, node in ipairs(self.CurrentNodes) do
        if node:GetIsSelected() then
            return node
        end
    end
end

function XAdventureChapter:GetIsHasNodeSelected()
    for _, node in ipairs(self.CurrentNodes) do
        if node:GetIsSelected() then
            return true
        end
    end
    return false
end

function XAdventureChapter:GetIsOpen(showTip)
    -- 由服务器来判断装饰条件，客户端不处理
    if self.Config.ConditionId <= 0 then
        return true
    end
    local isOK, desc = XConditionManager.CheckCondition(self.Config.ConditionId)
    if not isOK and showTip then
        XUiManager.TipMsg(desc)
    end
    return isOK
end

function XAdventureChapter:GetOpenIndexIcon()
    return self.Config.OpenIndexIcon
end

function XAdventureChapter:GetOpenTitleIcon()
    return self.Config.OpenTitleIcon
end

-- 开幕标题
function XAdventureChapter:GetTitle()
    return self.Config.Title
end

function XAdventureChapter:GetCurrentNodes()
    return self.CurrentNodes
end

-- 获取该章节是否可进行招募
function XAdventureChapter:GetIsCanRecruit()
    return self.Config.IsRecruit == 1
end

-- 获取招募数量
function XAdventureChapter:GetRecruitCount()
    local chapterConfigs = XTheatreConfigs.GetTheatreChapter()
    local chapterCount = 0
    local totalCount = 0
    for id, config in ipairs(chapterConfigs) do
        if self.Config.Id >= id and self.Config.GroupId == config.GroupId then
            totalCount = totalCount + config.RecruitCount
            chapterCount = chapterCount + 1
        end
    end
    local addCount = 0
    XDataCenter.TheatreManager.GetDecorationManager():HandleActiveDecorationTypeParam(XTheatreConfigs.DecorationRecruitOptionType
        , function(param)
            addCount = addCount + tonumber(param)
        end)
    totalCount = totalCount + addCount * chapterCount
    return totalCount - #XDataCenter.TheatreManager.GetCurrentAdventureManager():GetCurrentRoles(false)
end

-- 获取是否能够进入玩法
function XAdventureChapter:GetIsCanEnterGame()
    if self:GetRecruitCount() <= 0 then -- 招满人了，可以进了
        return true
    end
    local hasRoleRecruit = false
    for _, role in pairs(self:GetRecruitRoleDic()) do
        if XDataCenter.TheatreManager.GetCurrentAdventureManager():GetRole(role:GetId()) == nil then
            hasRoleRecruit = true
            break
        end
    end
    -- 没招满人，但刷新次数为0，而且也没人可以招了，也可以进了
    if self:GetRefreshRoleCount() <= 0 and not hasRoleRecruit then
        return true
    end
    return false
end

-- 获取招募刷新数量
function XAdventureChapter:GetRefreshRoleCount()
    return self.RefreshRoleCount
end

-- 获得招募刷新最大数量
function XAdventureChapter:GetRefreshRoleMaxCount()
    local totalCount = self.Config.RecruitRefreshCount
    XDataCenter.TheatreManager.GetDecorationManager():HandleActiveDecorationTypeParam(XTheatreConfigs.DecorationRecruitRefreshOptionType
        , function(param)
            totalCount = totalCount + tonumber(param)
        end)
    return totalCount
end

-- 获取当前章节可招募的角色
function XAdventureChapter:GetRecruitRoleDic()
    return self.RecruitRoleDic or {}
end

function XAdventureChapter:GetBeginStoryId()
    return self.Config.BeginStory
end

function XAdventureChapter:GetEndStoryId()
    return self.Config.EndStory
end

-- 请求招募角色
function XAdventureChapter:RequestRecruitRole(id, callback)
    -- 检查是否满足招募数次
    if self:GetRecruitCount() <= 0 then
        return 
    end
    local requestBody = {
        RoleId = id,
    }
    XNetwork.CallWithAutoHandleErrorCode("TheatreRecruitCharacterRequest", requestBody, function(res)
        XDataCenter.TheatreManager.GetCurrentAdventureManager():AddRoleById(id)
        if callback then callback() end
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE_RECRUIT_COMPLETE)
        XUiManager.TipText("TheatreRecruitComplete")
    end)
end

-- 请求刷新角色
function XAdventureChapter:RequestRefreshRoles(calllback, showTip)
    if showTip == nil then showTip = true end
    -- 检查刷新次数是否足够
    if self:GetRefreshRoleCount() <= 0 then
        -- 剩余刷新次数不足
        XUiManager.TipErrorWithKey("TheatreRecruitRefreshNotEnough")
        return
    end
    local requestBody = {}
    XNetwork.CallWithAutoHandleErrorCode("TheatreRefreshCharacterRequest", requestBody, function(res)
        -- 刷新剩余招募刷新次数
        self.RefreshRoleCount = self:GetRefreshRoleMaxCount() - res.RefreshRoleCount
        self.RecruitRoleDic = nil
        self.RecruitRoleDic = {}
        for index, roleId in ipairs(res.RoleList) do
            if roleId > 0 then
                self.RecruitRoleDic[index] = XAdventureRole.New(roleId)
            end
        end
        if calllback then calllback() end
        if showTip then
            XUiManager.TipText("TheatreRecruitRefreshComplete")
        end
    end)
end

function XAdventureChapter:RequestTriggerNode(id, callback)
    local requestBody = {
        NodeId = self.CurrentNodeId,
        SlotId = id
    }
    XNetwork.CallWithAutoHandleErrorCode("TheatreSelectNodeRequest", requestBody, function(res)
        if callback then callback() end
    end)
end

function XAdventureChapter:GetCurrentChapterId()
    return self.CurrentChapterId
end

function XAdventureChapter:CheckHasMovieNode()
    for _, node in ipairs(self.CurrentNodes) do
        if node:GetNodeType() == XTheatreConfigs.NodeType.Movie then
            return true
        end
    end
    return false
end

return XAdventureChapter