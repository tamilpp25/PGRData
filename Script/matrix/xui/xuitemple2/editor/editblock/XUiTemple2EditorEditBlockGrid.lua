local XUiTemple2CheckBoardGrid = require("XUi/XUiTemple2/Game/XUiTemple2CheckBoardGrid")
local XTemple2Enum = require("XModule/XTemple2/XTemple2Enum")

---@class XUiTemple2EditorEditBlockGrid : XUiNode
---@field _Control XTemple2Control
local XUiTemple2EditorEditBlockGrid = XClass(XUiNode, "XUiTemple2EditorEditBlockGrid")

function XUiTemple2EditorEditBlockGrid:OnStart()
    self._Grids = {}
    self._Data = false
end

---@param data XUiTemple2EditorEditBlockGridData
function XUiTemple2EditorEditBlockGrid:Update(data)
    self._Data = data
    if self.TxtName then
        self.TxtName.text = data.Name
    end

    ---@type UnityEngine.RectTransform
    local content = self.PanelGrid.transform
    content:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Horizontal, XTemple2Enum.GRID_SIZE * XTemple2Enum.BLOCK_SIZE.X)
    content:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Vertical, XTemple2Enum.GRID_SIZE * XTemple2Enum.BLOCK_SIZE.Y)
    XTool.UpdateDynamicItem(self._Grids, data.Grids, self.Grid, XUiTemple2CheckBoardGrid, self)
    self:UpdateToggle()
end

function XUiTemple2EditorEditBlockGrid:UpdateSelected(block)
    if self._Data and self._Data.Block:Equals(block) then
        self.Selected.gameObject:SetActiveEx(true)
    else
        self.Selected.gameObject:SetActiveEx(false)
    end
end

function XUiTemple2EditorEditBlockGrid:UpdateToggle()
    if self.PanelConfirm then
        if self._Data.IsCheckMark ~= nil then
            self.PanelConfirm.gameObject:SetActiveEx(self._Data.IsCheckMark)
        end
    end
end

return XUiTemple2EditorEditBlockGrid