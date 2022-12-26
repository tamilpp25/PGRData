local XTRPGMazeCard = require("XEntity/XTRPG/XTRPGMazeCard")

local type = type
local pairs = pairs
local mathCeil = math.ceil
local mathFloor = math.floor
local tableInsert = table.insert

local MAX_CARD_NUM = 9 --每个节点最大卡牌数量
local MAX_POS = mathFloor(MAX_CARD_NUM / 2) * 2 + MAX_CARD_NUM --17:左右移动至中心轴后预留出一半位置用于界面展示
local MID_PIVOT_POS = mathCeil(MAX_POS / 2)

local Default = {
    __Id = 0,
    __StartPos = 0,
    __Cards = {},
}

local XTRPGMazeNode = XClass(nil, "XTRPGMazeLayerLayer")

function XTRPGMazeNode:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self.__Id = id
end

function XTRPGMazeNode:InitCards(cardIds)
    for _, cardId in ipairs(cardIds) do
        local card = XTRPGMazeCard.New(cardId)
        tableInsert(self.__Cards, card)
    end

    if self:GetCardNum() > MAX_CARD_NUM then
        XLog.Error("XTRPGMazeNode:InitCards Error: 迷宫节点初始化卡牌错误, 超过单节点最大卡牌数量上限: " .. MAX_CARD_NUM)
        return
    end
end

function XTRPGMazeNode:GetCardNum()
    return #self.__Cards
end

function XTRPGMazeNode:GetStartPos()
    return self.__StartPos
end

function XTRPGMazeNode:GetEndPos()
    return self.__StartPos + self:GetCardNum() - 1
end

function XTRPGMazeNode:GetCard(cardIndex)
    local card = self.__Cards[cardIndex]
    if not card then
        XLog.Error("XTRPGMazeNode:GetCard Error: card not exist, cardIndex is: " .. cardIndex, self.__Cards)
        return
    end
    return card
end

function XTRPGMazeNode:GetCardId(cardIndex)
    local card = self:GetCard(cardIndex)
    return card:GetId()
end

function XTRPGMazeNode:GetCardFinishedId(cardIndex)
    local card = self:GetCard(cardIndex)
    return card:GetFinishedId()
end

function XTRPGMazeNode:CheckCardCurrentType(cardId, cardType)
    local card = self:GetCardByCardId(cardId)
    return card:CheckType(cardType)
end

function XTRPGMazeNode:GetCardByCardId(cardId)
    for _, card in pairs(self.__Cards) do
        if card:GetId() == cardId then
            return card
        end
    end
    XLog.Error("XTRPGMazeNode:GetCardByCardId Error: card not exist, cardId is: " .. cardId, self.__Cards)
end

function XTRPGMazeNode:CalcCardPos(cardIndex)
    return self.__StartPos + cardIndex - 1
end

function XTRPGMazeNode:IsCardReachable(cardIndex)
    if not cardIndex or cardIndex == 0 then return false end
    local cardPos = self:CalcCardPos(cardIndex)
    return cardPos >= MID_PIVOT_POS - 1 and cardPos <= MID_PIVOT_POS + 1
end

function XTRPGMazeNode:IsCardCurrentStand(cardIndex)
    if not cardIndex or cardIndex == 0 then return false end
    local cardPos = self:CalcCardPos(cardIndex)
    return cardPos == MID_PIVOT_POS
end

function XTRPGMazeNode:Enter(startCardIndex)
    self:ResetStartPos(startCardIndex)
end

function XTRPGMazeNode:Reset()
    for _, card in pairs(self.__Cards) do
        card:Reset()
    end
end

function XTRPGMazeNode:ResetStartPos(startCardIndex)
    local delta = mathCeil(self:GetCardNum() / 2) - startCardIndex
    self.__StartPos = MID_PIVOT_POS - mathFloor(self:GetCardNum() / 2) + delta
end

function XTRPGMazeNode:SelectCard(cardIndex)
    if not self:IsCardReachable(cardIndex) then
        XLog.Error("XTRPGMazeNode:SelectCard Error: 当前卡牌位置不可选择, cardIndex: " .. cardIndex)
        return
    end

    local card = self:GetCard(cardIndex)
    card:OnSelect(cardIndex)
end

function XTRPGMazeNode:OnCardResult(cardIndex, resultData)
    local card = self:GetCard(cardIndex)
    card:OnResult(cardIndex, resultData)
end

function XTRPGMazeNode:SetCardFinished(cardId)
    local card = self:GetCardByCardId(cardId)
    card:SetFinished()
end

function XTRPGMazeNode:IsCardFinished(cardId)
    local card = self:GetCardByCardId(cardId)
    return card:IsFinished()
end

function XTRPGMazeNode:IsCardDisposeableForeverFinished(cardId)
    local card = self:GetCardByCardId(cardId)
    return card:IsFinished() and card:IsDisposeableForever()
end

function XTRPGMazeNode:GetMoveDelta(cardIndex)
    local cardPos = self:CalcCardPos(cardIndex)
    return MID_PIVOT_POS - cardPos
end

function XTRPGMazeNode:MoveNext(cardIndex)
    if not self:IsCardReachable(cardIndex) then
        XLog.Error("XTRPGMazeNode:MoveNext Error: 当前卡牌位置不可到达, cardIndex: " .. cardIndex)
        return
    end

    local targetMidPos = self:CalcCardPos(cardIndex)
    local deltaPos = -(targetMidPos - MID_PIVOT_POS)
    self.__StartPos = self.__StartPos + deltaPos
end

function XTRPGMazeNode:MoveTo(cardIndex)
    local targetMidPos = self:CalcCardPos(cardIndex)
    local deltaPos = -(targetMidPos - MID_PIVOT_POS)
    self.__StartPos = self.__StartPos + deltaPos
end

return XTRPGMazeNode