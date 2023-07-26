local XTRPGMazeLayer = require("XEntity/XTRPG/XTRPGMazeLayer")

local type = type
local pairs = pairs
local tableInsert = table.insert

local Default = {
    __Id = 0,
    __CurrentLayerId = 0,
    __Layers = {},
    __LayerIdList = {},
    __RecordCardInfoList = {}, --计算进度使用的卡牌组
}

local XTRPGMaze = XClass(nil, "XTRPGMaze")

function XTRPGMaze:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self.__Id = id
    self:InitMaze()
end

function XTRPGMaze:InitMaze()
    local layerIds = XTRPGConfigs.GetMazeLayerIds(self.__Id)
    for _, layerId in ipairs(layerIds) do
        local layer = XTRPGMazeLayer.New(layerId)
        self.__Layers[layerId] = layer
        tableInsert(self.__LayerIdList, layerId)

        local cardIds = layer:GetCardIds()
        for cardId in pairs(cardIds) do
            local cardRecordGroupId = XTRPGConfigs.GetMazeCardRecordGroupId(cardId)
            if cardRecordGroupId and cardRecordGroupId > 0 then
                local group = self.__RecordCardInfoList[cardRecordGroupId]
                if not group then
                    group = {}
                    self.__RecordCardInfoList[cardRecordGroupId] = group
                end

                group[cardId] = false
            end
        end
    end
end

function XTRPGMaze:UpdateData(data)
    if not data then return end
    self:UpdateLayers(data.LayerInfos)
    self:UpdateRecordCards(data.RecordCardIds)
end

function XTRPGMaze:UpdateLayers(datas)
    if not datas then return end

    for _, data in pairs(datas) do
        local layer = self:GetLayer(data.Id)
        layer:UpdateData(data.FinishCardId)
    end
end

function XTRPGMaze:UpdateRecordCards(datas)
    if not datas then return end

    for _, cardId in pairs(datas) do
        local cardRecordGroupId = XTRPGConfigs.GetMazeCardRecordGroupId(cardId)
        local group = self.__RecordCardInfoList[cardRecordGroupId]
        if group and group[cardId] ~= nil then
            group[cardId] = true
        else
            XLog.Error("XTRPGMaze:UpdateRecordCards Error: 服务端下发的记录卡牌Id与配置不对应, cardId is: " .. cardId, self.__RecordCardInfoList)
        end
    end

    CsXGameEventManager.Instance:Notify(XEventId.EVENT_TRPG_MAZE_RECORD_CARD)
end

function XTRPGMaze:GetLayer(layerId)
    local layer = self.__Layers[tonumber(layerId)]
    if not layer then
        XLog.Error("XTRPGMaze:GetLayer Error: layer not exist, layerId is: " .. layerId, self.__Layers)
        return
    end
    return layer
end

function XTRPGMaze:GetLayerIdList()
    return self.__LayerIdList
end

function XTRPGMaze:GetCurrentLayerId()
    return self.__CurrentLayerId
end

function XTRPGMaze:GetCurrentNodeId()
    local layer = self:GetLayer(self.__CurrentLayerId)
    return layer:GetCurrentNodeId()
end

function XTRPGMaze:GetCurrentStandNodeIndex(layerId)
    local layer = self:GetLayer(layerId)
    return layer:GetCurrentStandNodeIndex()
end

function XTRPGMaze:GetRecordGroupCardCount(cardRecordGroupId)
    local finishCount, totalCount = 0, 0

    local group = self.__RecordCardInfoList[cardRecordGroupId]
    if not group then return finishCount, totalCount end

    for cardId, isFinished in pairs(group) do
        if isFinished then
            finishCount = finishCount + 1
        end

        totalCount = totalCount + 1
    end

    return finishCount, totalCount
end

function XTRPGMaze:GetProgress()
    local totalfinishCount, totalTotalCount = 0, 0

    for groupId in pairs(self.__RecordCardInfoList) do
        local finishCount, totalCount = self:GetRecordGroupCardCount(groupId)
        totalfinishCount = totalfinishCount + finishCount
        totalTotalCount = totalTotalCount + totalCount
    end

    if totalTotalCount == 0 then return 1 end
    return totalfinishCount / totalTotalCount
end

function XTRPGMaze:GetLayerNodeIdList(layerId, notSort)
    local layer = self:GetLayer(layerId)
    return layer:GetSortedNodeIdList(notSort)
end

function XTRPGMaze:GetLayerCardBeginEndPos(layerId, nodeId)
    local layer = self:GetLayer(layerId)
    return layer:GetNodeCardBeginEndPos(nodeId)
end

function XTRPGMaze:GetLayerCardNum(layerId, nodeId)
    local layer = self:GetLayer(layerId)
    return layer:GetNodeCardNum(nodeId)
end

function XTRPGMaze:GetLayerCardId(layerId, nodeId, cardIndex)
    local layer = self:GetLayer(layerId)
    return layer:GetNodeCardId(nodeId, cardIndex)
end

function XTRPGMaze:IsLayerReachable(layerId)
    return layerId == self.__CurrentLayerId
end

function XTRPGMaze:IsNodeReachable(layerId, nodeId)
    if not self:IsLayerReachable(layerId) then return false end

    local layer = self:GetLayer(layerId)
    return layer:IsNodeReachable(nodeId)
end

function XTRPGMaze:IsCardReachable(layerId, nodeId, cardIndex)
    if not self:IsLayerReachable(layerId) then return false end

    local layer = self:GetLayer(layerId)
    return layer:IsCardReachable(nodeId, cardIndex)
end

function XTRPGMaze:IsCardAfterCurrentStand(layerId, nodeId, cardIndex)
    if not self:IsLayerReachable(layerId) then return false end

    local layer = self:GetLayer(layerId)
    return layer:IsCardAfterCurrentStand(nodeId, cardIndex)
end

function XTRPGMaze:IsCardCurrentStand(layerId, nodeId, cardIndex)
    if not self:IsLayerReachable(layerId) then return false end

    local layer = self:GetLayer(layerId)
    return layer:IsCardCurrentStand(nodeId, cardIndex)
end

function XTRPGMaze:GetMoveDelta(cardIndex)
    local layerId = self.__CurrentLayerId
    local layer = self:GetLayer(layerId)
    return layer:GetMoveDelta(cardIndex)
end

function XTRPGMaze:GetCardFinishedId(layerId, nodeId, cardIndex)
    local layer = self:GetLayer(layerId)
    return layer:GetCardFinishedId(nodeId, cardIndex)
end

function XTRPGMaze:CheckCardCurrentType(layerId, nodeId, cardId, cardType)
    local layer = self:GetLayer(layerId)
    return layer:CheckCardCurrentType(nodeId, cardId, cardType)
end

function XTRPGMaze:IsCardFinished(layerId, cardId)
    local layer = self:GetLayer(layerId)
    return layer:IsCardFinished(cardId)
end

function XTRPGMaze:IsCardDisposeableForeverFinished(layerId, cardId)
    local layer = self:GetLayer(layerId)
    return layer:IsCardDisposeableForeverFinished(cardId)
end

function XTRPGMaze:SelectCard(cardIndex)
    local layerId = self.__CurrentLayerId
    local layer = self:GetLayer(layerId)
    layer:SelectCard(cardIndex)
end

function XTRPGMaze:OnCardResult(cardIndex, resultData)
    local layerId = self.__CurrentLayerId
    local layer = self:GetLayer(layerId)
    layer:OnCardResult(cardIndex, resultData)
end

function XTRPGMaze:Enter()
    self.__CurrentLayerId = XTRPGConfigs.GetMazeStartLayerId(self.__Id)
    local layer = self:GetLayer(self.__CurrentLayerId)
    layer:Enter()

    self:Reset()
end

function XTRPGMaze:Reset()
    for _, layer in pairs(self.__Layers) do
        layer:Reset()
    end
end

function XTRPGMaze:RestartCurrentLayer()
    local layer = self:GetLayer(self.__CurrentLayerId)
    layer:Enter()
end

function XTRPGMaze:MoveNext(cardIndex)
    local layerId = self.__CurrentLayerId
    local layer = self:GetLayer(layerId)
    layer:MoveNext(cardIndex)
end

function XTRPGMaze:MoveTo(layerId, nodeId, cardIndex)
    self.__CurrentLayerId = layerId
    local layer = self:GetLayer(layerId)
    layer:MoveTo(nodeId, cardIndex)
end

return XTRPGMaze