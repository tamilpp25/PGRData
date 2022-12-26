local XUiGridRpgMakerGameCardMini = require("XUi/XUiRpgMakerGame/Hint/XUiGridRpgMakerGameCardMini")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

--提示说明地图上的节点
local XUiGridRpgMakerGameMapNode = XClass(nil, "XUiGridRpgMakerGameMapNode")

function XUiGridRpgMakerGameMapNode:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.CardGrids = {}

    XTool.InitUiObject(self)
end

function XUiGridRpgMakerGameMapNode:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridRpgMakerGameMapNode:Refresh(blockId, mapId)
    local cardGrids = self.CardGrids
    local blockColList = XRpgMakerGameConfigs.GetRpgMakerGameBlockColList(blockId)
    for colIndex, col in ipairs(blockColList) do
        local grid = cardGrids[colIndex]
        if not grid then
            local ui = colIndex == 1 and self.GridCardMini or CSUnityEngineObjectInstantiate(self.GridCardMini, self.Transform)
            grid = XUiGridRpgMakerGameCardMini.New(ui, self.UiRoot)
            cardGrids[colIndex] = grid
        end
        grid:Refresh(blockId, colIndex, col, mapId)
    end
end

return XUiGridRpgMakerGameMapNode