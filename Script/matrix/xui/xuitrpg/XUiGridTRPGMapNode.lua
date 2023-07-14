local XUiGridTRPGMapCardMini = require("XUi/XUiTRPG/XUiGridTRPGMapCardMini")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiGridTRPGMapNode = XClass(nil, "XUiGridTRPGMapNode")

function XUiGridTRPGMapNode:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.CardGrids = {}

    XTool.InitUiObject(self)
end

function XUiGridTRPGMapNode:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridTRPGMapNode:Refresh(mazeId, layerId, nodeId)
    local cardGrids = self.CardGrids

    local cardNum = XDataCenter.TRPGManager.GetMazeCardNum(mazeId, layerId, nodeId)
    for cardIndex = 1, cardNum do
        local cardId = XDataCenter.TRPGManager.GetMazeCardId(mazeId, layerId, nodeId, cardIndex)
        local isCurrentStand = XDataCenter.TRPGManager.IsCardCurrentStand(mazeId, layerId, nodeId, cardIndex)
        local isNextPos = XDataCenter.TRPGManager.IsCardAfterCurrentStand(mazeId, layerId, nodeId, cardIndex)
        local isDisposeableForeverFinished = XDataCenter.TRPGManager.IsMazeCardDisposeableForeverFinished(mazeId, layerId, cardId)

        local grid = cardGrids[cardIndex]
        if not grid then
            local ui = cardIndex == 1 and self.GridCardMini or CSUnityEngineObjectInstantiate(self.GridCardMini, self.Transform)
            grid = XUiGridTRPGMapCardMini.New(ui, self.UiRoot)
            cardGrids[cardIndex] = grid
        end
        grid:Refresh(cardId, isCurrentStand, isNextPos, isDisposeableForeverFinished)
        grid.GameObject:SetActiveEx(true)
    end

    for i = cardNum + 1, #cardGrids do
        if cardGrids[i] then
            cardGrids[i].GameObject:SetActiveEx(false)
        end
    end
end

return XUiGridTRPGMapNode