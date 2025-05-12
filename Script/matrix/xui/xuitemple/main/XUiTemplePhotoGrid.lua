--local XUiTempleBattleGrid = require("XUi/XUiTemple/XUiTempleBattleGrid")
local XUiTempleUtil = require("XUi/XUiTemple/XUiTempleUtil")
local XUiTempleChessBoardPanel = require("XUi/XUiTemple/XUiTempleChessBoardPanel")

---@class XUiTemplePhotoGrid : XUiNode
---@field _Control XTempleModel
local XUiTemplePhotoGrid = XClass(XUiNode, "XUiTemplePhotoGrid")

function XUiTemplePhotoGrid:Ctor()
    self._Grids = {}
    self._Data = false
end

function XUiTemplePhotoGrid:OnStart()
    ---@type XUiTempleChessBoardPanel
    self._PanelChessBoard = XUiTempleChessBoardPanel.New(self.PanelCheckerboard, self)
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)
end

function XUiTemplePhotoGrid:Update(data)
    self._Data = data
    self.StandIcon:SetRawImage(data.Icon)
    if data.Grids then
        self.Checkerboard.gameObject:SetActiveEx(true)
        --self._PanelChessBoard:Open()
        --self._PanelChessBoard:Update(data.Grids, data.Bg, false)

        --self.PanelCheckerboard
        self.ImgNone.gameObject:SetActiveEx(false)

        --XUiTempleUtil:UpdateDynamicItem(self, self._Grids, dataProvider, self.GridCheckerboard, XUiTempleBattleGrid, isGridClick)

        local imgBg = self.Bg or XUiHelper.TryGetComponent(self.Transform, "PanelCheckerboard/ValentineBg/Bg", "RawImage")
        imgBg:SetRawImage(data.Bg)

    else
        --self._PanelChessBoard:Close()
        self.Bg.gameObject:SetActiveEx(false)
        self.ImgNone.gameObject:SetActiveEx(true)

        local uiGrid = self.GridCheckerboard
        if not uiGrid then
            uiGrid = XUiHelper.TryGetComponent(self.Transform, "PanelCheckerboard/Checkerboard/GridCheckerboard", "Transform")
        end
        uiGrid.gameObject:SetActiveEx(false)
    end
end

function XUiTemplePhotoGrid:UpdateGrids()
    local data = self._Data
    if not data.Grids then
        return
    end
    local dataProvider = data.Grids
    local uiGrid = self.GridCheckerboard
    if not uiGrid then
        uiGrid = XUiHelper.TryGetComponent(self.Transform, "PanelCheckerboard/Checkerboard/GridCheckerboard", "Transform")
    end
    local gridArray = self._Grids
    for i = 1, #dataProvider do
        local grid = gridArray[i]
        if not grid then
            grid = CS.UnityEngine.Object.Instantiate(uiGrid, uiGrid.transform.parent)
            gridArray[i] = grid
        end
        local dataGrid = dataProvider[i]
        local image = XUiHelper.TryGetComponent(grid.transform, "Image", "Image")
        image:SetSprite(dataGrid.Icon)
    end
    uiGrid.gameObject:SetActiveEx(false)
end

function XUiTemplePhotoGrid:OnClick()
    if self._Data and self._Data.Grids then
        XLuaUiManager.Open("UiTemplePhotoDetail", self._Data.Id)
    end
end

return XUiTemplePhotoGrid