local XInfestorExploreOutPostStory = require("XEntity/XInfestorExplore/XInfestorExploreOutPostStory")

local next = next
local type = type
local tableInsert = table.insert

local MAX_SUPPLY_OPTION_NUM = 3

local XInfestorExploreMapNode = XClass(nil, "XInfestorExploreMapNode")

local NodeType = {
    Empty = 1, --空白点（起点）
    Rest = 2, --休息点
    Fight = 3, --战斗点
    Shop = 4, --商店
    Supply = 5, --补给点
    Reward = 6, --奖励点
    SelectEvent = 7, --可选择事件点
    AutoEvent = 8, --自动事件点
    OutPost = 9, --据点
}

local NodeStatus = {
    UnReach = 1, --够不着
    Fog = 2, --迷雾
    Current = 3, --当前
    Reach = 4, --可到达
    Passed = 5, --走过的
}

local NodePrefabPath = {
    [NodeStatus.UnReach] = CS.XGame.ClientConfig:GetString("GridFubenInfestorExploreStageUnReach"),
    [NodeStatus.Fog] = CS.XGame.ClientConfig:GetString("GridFubenInfestorExploreStageFog"),
    [NodeStatus.Current] = CS.XGame.ClientConfig:GetString("GridFubenInfestorExploreStageCurrent"),
    [NodeStatus.Reach] = CS.XGame.ClientConfig:GetString("GridFubenInfestorExploreStageReach"),
    [NodeStatus.Passed] = CS.XGame.ClientConfig:GetString("GridFubenInfestorExploreStagePassed"),
}

local NodeUiName = {
    [NodeType.Fight] = "UiInfestorExploreStageDetailFight",
    [NodeType.Shop] = "UiInfestorExploreStageDetailShop",
    [NodeType.AutoEvent] = "UiInfestorExploreStageDetailEvent",
    [NodeType.Rest] = "UiInfestorExploreStageDetailRest",
    [NodeType.Supply] = "UiInfestorExploreStageDetailSupply",
    [NodeType.Reward] = "UiInfestorExploreStageDetailReward",
    [NodeType.SelectEvent] = "UiInfestorExploreStageDetailEvent",
    [NodeType.OutPost] = "UiInfestorExploreStageDetailOutPost",
}

local Default = {
    NodeId = 0,
    StageId = 0,
    Type = NodeType.Empty,
    ResType = 0,
    Status = NodeStatus.UnReach,
    ParentIds = {},
    ChildIds = {},
    PlayerIdCheckTable = {},
    OutPostStory = nil,
    SupplyRandomDesList = {},
}

function XInfestorExploreMapNode:Ctor(nodeId)
    self:Reset()
    self.NodeId = nodeId
end

function XInfestorExploreMapNode:Reset()
    for key, v in pairs(Default) do
        if type(v) == "table" then
            self[key] = {}
        else
            self[key] = v
        end
    end
end

function XInfestorExploreMapNode:SetParentId(parentId)
    self.ParentIds[parentId] = true
end

function XInfestorExploreMapNode:SetChildId(childId)
    self.ChildIds[childId] = true
end

function XInfestorExploreMapNode:SetStageId(stageId)
    self.StageId = stageId or 0
    self.ResType = XFubenInfestorExploreConfigs.GetNodeResType(stageId)
    self.Type = XFubenInfestorExploreConfigs.GetNodeType(stageId)

    if self.Type == NodeType.OutPost then
        self.OutPostStory = XInfestorExploreOutPostStory.New()
    elseif self.Type == NodeType.Supply then
        self.SupplyRandomDesList = XDataCenter.FubenInfestorExploreManager.GetRandomSupplyRewardDesList(MAX_SUPPLY_OPTION_NUM)
    end
end

function XInfestorExploreMapNode:SetStatusCurrent()
    self.Status = NodeStatus.Current
end

function XInfestorExploreMapNode:SetStatusFog()
    if self.Status == NodeStatus.Fog
    or self.Status == NodeStatus.Passed
    or self.Status == NodeStatus.Reach
    then return end

    if self:IsStart()
    or self:IsEnd()
    then return end

    if self.Type == NodeType.Shop
    or self.Type == NodeType.Rest
    then return end

    self.Status = NodeStatus.Fog
end

function XInfestorExploreMapNode:SetStatusReach()
    self.Status = NodeStatus.Reach
end

function XInfestorExploreMapNode:SetStatusUnReach()
    self.Status = NodeStatus.UnReach
end

function XInfestorExploreMapNode:SetStatusPassed()
    self.Status = NodeStatus.Passed
end

function XInfestorExploreMapNode:SetOccupiedPlayerId(playerId)
    self.PlayerIdCheckTable[playerId] = playerId
end

function XInfestorExploreMapNode:ClearOccupiedPlayerId(playerId)
    self.PlayerIdCheckTable[playerId] = nil
end

function XInfestorExploreMapNode:GetOccupiedPlayerIds()
    local playerIds = {}
    for _, playerId in pairs(self.PlayerIdCheckTable) do
        tableInsert(playerIds, playerId)
    end
    return playerIds
end

function XInfestorExploreMapNode:GetOutPostStory()
    if self.Type ~= NodeType.OutPost then
        XLog.Error("XInfestorExploreMapNode:GetOutPostStory Error: 感染体玩法节点类型错误, 该类型没有据点战斗剧情配置, nodeId: " .. self.NodeId .. ",type: " .. self.Type)
        return
    end
    return self.OutPostStory
end

function XInfestorExploreMapNode:GetSupplyDesList()
    if self.Type ~= NodeType.Supply then
        XLog.Error("XInfestorExploreMapNode:GetSupplyDesList Error: 感染体玩法节点类型错误, 该类型没有补给点随机描述配置, nodeId: " .. self.NodeId .. ",type: " .. self.Type)
        return
    end
    return self.SupplyRandomDesList
end

function XInfestorExploreMapNode:GetNodeId()
    return self.NodeId
end

function XInfestorExploreMapNode:GetParentIds()
    return self.ParentIds
end

function XInfestorExploreMapNode:GetChildIds()
    return self.ChildIds
end

function XInfestorExploreMapNode:GetPrefabPath()
    return NodePrefabPath[self.Status]
end

function XInfestorExploreMapNode:GetTypeIcon()
    return XFubenInfestorExploreConfigs.GetNodeTypeIcon(self.ResType)
end

function XInfestorExploreMapNode:GetNodeTypeUiName()
    if self.Type == NodeType.Empty then return end
    local uiName = NodeUiName[self.Type]
    if not uiName then
        XLog.Error("XInfestorExploreMapNode:GetNodeTypeUiName Error: 感染体玩法节点类型错误, 该类型没有对应详情UI, nodeId: " .. self.NodeId .. ",type: " .. self.Type)
        return
    end
    return uiName
end

function XInfestorExploreMapNode:GetUseActionPoint()
    return XFubenInfestorExploreConfigs.GetUseActionPoint(self.StageId)
end

function XInfestorExploreMapNode:GetEventPoolId()
    if self.Type ~= NodeType.AutoEvent
    and self.Type ~= NodeType.SelectEvent then
        XLog.Error("XInfestorExploreMapNode:GetEventId Error: 感染体玩法节点类型错误, 该类型没有事件Id配置, nodeId: " .. self.NodeId .. ",type: " .. self.Type)
        return
    end
    return XFubenInfestorExploreConfigs.GetEventPoolId(self.StageId)
end

function XInfestorExploreMapNode:GetStageBg()
    return XFubenInfestorExploreConfigs.GetNodeTypeStageBg(self.ResType)
end

function XInfestorExploreMapNode:GetFightStageId()
    if self.Type ~= NodeType.Fight then
        XLog.Error("XInfestorExploreMapNode:GetFightStageId Error: 感染体玩法节点类型错误, 该类型没有关卡Id配置, nodeId: " .. self.NodeId .. ",type: " .. self.Type)
        return
    end
    return XFubenInfestorExploreConfigs.GetFightStageId(self.StageId)
end

function XInfestorExploreMapNode:GetShowRewardId()
    if self.Type ~= NodeType.OutPost
    and self.Type ~= NodeType.Fight then
        XLog.Error("XInfestorExploreMapNode:GetShowRewardId Error: 感染体玩法节点类型错误, 该类型没有奖励Id配置, nodeId: " .. self.NodeId .. ",type: " .. self.Type)
        return
    end
    return XFubenInfestorExploreConfigs.GetShowRewardId(self.StageId)
end

function XInfestorExploreMapNode:IsStart()
    return not next(self.ParentIds)
end

function XInfestorExploreMapNode:IsEnd()
    return not next(self.ChildIds)
end

function XInfestorExploreMapNode:IsCurrent()
    return self.Status == NodeStatus.Current
end

function XInfestorExploreMapNode:IsReach()
    return self.Status == NodeStatus.Reach
end

function XInfestorExploreMapNode:IsUnReach()
    return self.Status == NodeStatus.UnReach
end

function XInfestorExploreMapNode:IsPassed()
    return self.Status == NodeStatus.Passed
end

function XInfestorExploreMapNode:IsFog()
    return self.Status == NodeStatus.Fog
end

function XInfestorExploreMapNode:IsSelectEvent()
    return self.Type == NodeType.SelectEvent
end

function XInfestorExploreMapNode:IsAutoEvent()
    return self.Type == NodeType.AutoEvent
end

function XInfestorExploreMapNode:IsShop()
    return self.Type == NodeType.Shop
end

return XInfestorExploreMapNode