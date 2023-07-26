local XTRPGMazeNode = require("XEntity/XTRPG/XTRPGMazeNode")

local type = type
local tableInsert = table.insert
local Default = {
    __Id = 0,
    __CurrentNodeIndex = 0,
    __Map = {},
    __NodeNum = 0,
    __NodeIdList = {},
    __CardIdToNodeIdDic = {},
}

local XTRPGMazeLayer = XClass(nil, "XTRPGMazeLayerLayer")

function XTRPGMazeLayer:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self.__Id = id
    self:InitMap()
end

function XTRPGMazeLayer:InitMap()
    local configs = XTRPGConfigs.GetMazeMapConfigs(self.__Id)
    for nodeId, config in pairs(configs) do
        local cardIds = config.CardId

        local node = XTRPGMazeNode.New(nodeId)
        node:InitCards(cardIds)

        self.__Map[nodeId] = node
        tableInsert(self.__NodeIdList, nodeId)

        for _, cardId in pairs(cardIds) do
            self.__CardIdToNodeIdDic[cardId] = nodeId
        end
    end

    self.__NodeNum = #self.__NodeIdList
end

function XTRPGMazeLayer:UpdateData(finishCardIds)
    if not finishCardIds then return end

    for _, cardId in pairs(finishCardIds) do
        local node = self:GetNodeByCardId(cardId)
        if node then
            node:SetCardFinished(cardId)
        end
    end
end

function XTRPGMazeLayer:GetCardIds()
    return self.__CardIdToNodeIdDic
end

function XTRPGMazeLayer:GetNodeIdByCardId(cardId)
    local nodeId = self.__CardIdToNodeIdDic[cardId]
    if not nodeId then
        XLog.Error("XTRPGMaze:GetNodeIdByCardId Error: nodeId not exist, cardId is: " .. cardId, self.__CardIdToNodeIdDic)
        return
    end
    return nodeId
end

function XTRPGMazeLayer:GetNodeId(nodeIndex)
    local nodeId = self.__NodeIdList[nodeIndex]
    if not nodeId then
        XLog.Error("XTRPGMaze:GetNodeId Error: nodeId not exist, nodeIndex is: " .. nodeIndex, self.__NodeIdList)
        return
    end
    return nodeId
end

function XTRPGMazeLayer:GetNodeIndex(paramNodeId)
    for nodeIndex, nodeId in pairs(self.__NodeIdList) do
        if nodeId == paramNodeId then
            return nodeIndex
        end
    end
    return 0
end

function XTRPGMazeLayer:GetLastNodeIndex(nodeIndex)
    local nextIndex = nodeIndex - 1
    if nextIndex < 1 then
        nextIndex = self:GetNodeNum()
    end
    return nextIndex
end

function XTRPGMazeLayer:GetNextNodeIndex(nodeIndex)
    local nextIndex = nodeIndex + 1
    if nextIndex > self:GetNodeNum() then
        nextIndex = 1
    end
    return nextIndex
end

function XTRPGMazeLayer:GetNodeNum()
    return self.__NodeNum
end

function XTRPGMazeLayer:GetNextNodeId()
    local nextNodeIndex = self:GetNextNodeIndex(self.__CurrentNodeIndex)
    return self:GetNodeId(nextNodeIndex)
end

function XTRPGMazeLayer:GetNode(nodeId)
    if not nodeId then
        XLog.Error("XTRPGMaze:GetNode Error: nodeId is nil")
        return
    end

    local node = self.__Map[nodeId]
    if not node then
        XLog.Error("XTRPGMaze:GetNode Error: node not exist, nodeId is: " .. nodeId, self.__Map)
        return
    end
    return node
end

function XTRPGMazeLayer:GetNodeByCardId(cardId)
    local nodeId = self:GetNodeIdByCardId(cardId)
    return self:GetNode(nodeId)
end

function XTRPGMazeLayer:GetSortedNodeIdList(notSort)
    local list = {}

    local nodeNum = self:GetNodeNum()
    local nodeIndex = notSort and 1 or self.__CurrentNodeIndex
    for i = 1, nodeNum do
        tableInsert(list, self:GetNodeId(nodeIndex))
        nodeIndex = self:GetNextNodeIndex(nodeIndex)
    end

    return list
end

function XTRPGMazeLayer:GetNodeCardBeginEndPos(nodeId)
    local node = self:GetNode(nodeId)
    return node:GetStartPos(), node:GetEndPos()
end

function XTRPGMazeLayer:GetNodeCardNum(nodeId)
    local node = self:GetNode(nodeId)
    return node:GetCardNum()
end

function XTRPGMazeLayer:GetNodeCardId(nodeId, cardIndex)
    local node = self:GetNode(nodeId)
    return node:GetCardId(cardIndex)
end

function XTRPGMazeLayer:GetCurrentStandNodeIndex()
    return self:GetLastNodeIndex(self.__CurrentNodeIndex)
end

function XTRPGMazeLayer:GetCurrentNodeId()
    return self:GetNodeId(self.__CurrentNodeIndex)
end

function XTRPGMazeLayer:IsNodeReachable(nodeId)
    local curNodeId = self:GetCurrentNodeId()
    return nodeId == curNodeId
end

function XTRPGMazeLayer:IsCardReachable(nodeId, cardIndex)
    if not self:IsNodeReachable(nodeId) then return false end

    local node = self:GetNode(nodeId)
    return node:IsCardReachable(cardIndex)
end

function XTRPGMazeLayer:IsCardFinished(cardId)
    local node = self:GetNodeByCardId(cardId)
    if not node then return false end

    return node:IsCardFinished(cardId)
end

function XTRPGMazeLayer:IsCardDisposeableForeverFinished(cardId)
    local node = self:GetNodeByCardId(cardId)
    if not node then return false end

    return node:IsCardDisposeableForeverFinished(cardId)
end

--当前所在卡牌的正前方卡牌位置判断
function XTRPGMazeLayer:IsCardAfterCurrentStand(nodeId, cardIndex)
    --站立位置正前方是可选择的
    local curNodeId = self:GetCurrentNodeId()
    if nodeId ~= curNodeId then return false end

    --卡牌位置为上次选择作为中轴的卡牌
    local node = self:GetNode(nodeId)
    if not node:IsCardCurrentStand(cardIndex) then return false end

    return true
end

--当前所在卡牌判断
function XTRPGMazeLayer:IsCardCurrentStand(nodeId, cardIndex)
    --站在可选择的节点前面一行
    local lastNodeIndex = self:GetLastNodeIndex(self.__CurrentNodeIndex)
    local lastNodeId = self:GetNodeId(lastNodeIndex)
    if nodeId ~= lastNodeId then return false end

    --卡牌位置为上次选择作为中轴的卡牌
    local node = self:GetNode(nodeId)
    if not node:IsCardCurrentStand(cardIndex) then return false end

    return true
end

function XTRPGMazeLayer:GetMoveDelta(cardIndex)
    local nodeId = self:GetCurrentNodeId()
    local node = self:GetNode(nodeId)
    return node:GetMoveDelta(cardIndex)
end

function XTRPGMazeLayer:GetCardFinishedId(nodeId, cardIndex)
    local node = self:GetNode(nodeId)
    return node:GetCardFinishedId(cardIndex)
end

function XTRPGMazeLayer:CheckCardCurrentType(nodeId, cardId, cardType)
    local node = self:GetNode(nodeId)
    return node:CheckCardCurrentType(cardId, cardType)
end

function XTRPGMazeLayer:Enter()
    self.__CurrentNodeIndex = XTRPGConfigs.GetMazeLayerStartNodeId(self.__Id)
    self.__CurrentNodeIndex = self:GetNextNodeIndex(self.__CurrentNodeIndex) --实际配置的是站立节点位置，当前可选择卡牌节点应前进一位

    local startCardIndex = XTRPGConfigs.GetMazeLayerStartCardIndex(self.__Id)
    for _, node in pairs(self.__Map) do
        node:Enter(startCardIndex)
    end
end

function XTRPGMazeLayer:Reset()
    for _, node in pairs(self.__Map) do
        node:Reset()
    end
end

function XTRPGMazeLayer:SelectCard(cardIndex)
    local nodeId = self:GetCurrentNodeId()
    local node = self:GetNode(nodeId)
    node:SelectCard(cardIndex)
end

function XTRPGMazeLayer:OnCardResult(cardIndex, resultData)
    local nodeId = self:GetCurrentNodeId()
    local node = self:GetNode(nodeId)
    node:OnCardResult(cardIndex, resultData)
end

function XTRPGMazeLayer:MoveNext(cardIndex)
    for _, node in pairs(self.__Map) do
        node:MoveNext(cardIndex)
    end

    self.__CurrentNodeIndex = self:GetNextNodeIndex(self.__CurrentNodeIndex)
end

function XTRPGMazeLayer:MoveTo(nodeId, cardIndex)
    for _, node in pairs(self.__Map) do
        node:MoveTo(cardIndex)
    end

    self.__CurrentNodeIndex = self:GetNodeIndex(nodeId)
    self.__CurrentNodeIndex = self:GetNextNodeIndex(self.__CurrentNodeIndex) --实际配置的是站立节点位置，当前可选择卡牌节点应前进一位
end

return XTRPGMazeLayer