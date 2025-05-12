local XUiTempleBattleGridRule = require("XUi/XUiTemple/XUiTempleBattleGridRule")
local XUiTempleBattleGrid = require("XUi/XUiTemple/XUiTempleBattleGrid")
local XUiTempleUtil = require("XUi/XUiTemple/XUiTempleUtil")

---@class XUiTempleAffixDetailGrid : XUiNode
---@field _Control XTempleControl
local XUiTempleAffixDetailGrid = XClass(XUiTempleBattleGridRule, "UiTempleAffixDetailGrid")

function XUiTempleAffixDetailGrid:Ctor()
    self._Grids = {}

    ---@type XTempleGameControl
    self._GameControl = self._Control:GetGameControl()
end

function XUiTempleAffixDetailGrid:Update(data)
    XUiTempleBattleGridRule.Update(self, data)

    local block = data.Block
    local dataProvider = self._GameControl:GetBlockGrids4Rule(block, data.Id, true)
    self:UpdateDynamicItem(self._Grids, dataProvider, self.GridCheckerboard, XUiTempleBattleGrid)
end

function XUiTempleAffixDetailGrid:UpdateDynamicItem(gridArray, dataArray, uiObject, class)
    XUiTempleUtil:UpdateDynamicItem(self, gridArray, dataArray, uiObject, class)
end

return XUiTempleAffixDetailGrid