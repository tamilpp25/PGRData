local XUiTempleBattleGrid = require("XUi/XUiTemple/XUiTempleBattleGrid")
local XUiTempleUtil = require("XUi/XUiTemple/XUiTempleUtil")

---@class XUiTempleChessBoardPanel : XUiNode
---@field _Control XTempleControl
local XUiTempleChessBoardPanel = XClass(XUiNode, "XUiTempleChessBoardPanel")

function XUiTempleChessBoardPanel:Ctor()
    self._Grids = {}
end

function XUiTempleChessBoardPanel:Update(dataProvider, bg, isGridClick)
    XUiTempleUtil:UpdateDynamicItem(self, self._Grids, dataProvider, self.GridCheckerboard, XUiTempleBattleGrid, isGridClick)
    if bg then
        self.Bg:SetRawImage(bg)
        self.Bg.gameObject:SetActiveEx(true)
    else
        self.Bg.gameObject:SetActiveEx(false)
    end
end

return XUiTempleChessBoardPanel