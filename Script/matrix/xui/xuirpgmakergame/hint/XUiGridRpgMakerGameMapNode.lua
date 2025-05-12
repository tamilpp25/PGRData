local XUiGridRpgMakerGameCardMini = require("XUi/XUiRpgMakerGame/Hint/XUiGridRpgMakerGameCardMini")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

--提示说明地图上的节点
local XUiGridRpgMakerGameMapNode = XClass(nil, "XUiGridRpgMakerGameMapNode")

function XUiGridRpgMakerGameMapNode:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.CardGrids = {}

    XTool.InitUiObject(self)

    self.GridCardMini.gameObject:SetActiveEx(false)
end

function XUiGridRpgMakerGameMapNode:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridRpgMakerGameMapNode:Refresh(mapObjList, mapId, isNotShowLine, row)
    local cardGrids = self.CardGrids
    -- local blockColList = XRpgMakerGameConfigs.GetRpgMakerGameBlockColList(mapObjList)
    for colIndex, colDataList in ipairs(mapObjList) do
        local grid = cardGrids[colIndex]
        if not grid then
            local ui = CSUnityEngineObjectInstantiate(self.GridCardMini, self.Transform)
            ui.gameObject:SetActiveEx(true)
            grid = XUiGridRpgMakerGameCardMini.New(ui, self.UiRoot)
            cardGrids[colIndex] = grid
        end
        grid:Refresh(row, colIndex, colDataList, mapId, isNotShowLine)
    end
end

function XUiGridRpgMakerGameMapNode:GetImageLine(id)
    local imageLine
    for _, cardGrid in pairs(self.CardGrids) do
        imageLine = cardGrid:GetImageLine(id)
        if imageLine then
            return imageLine
        end
    end
end

return XUiGridRpgMakerGameMapNode