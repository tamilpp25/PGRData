local XUiTemple2CheckBoardGrid = require("XUi/XUiTemple2/Game/XUiTemple2CheckBoardGrid")

---@class XUiTemple2EditorBlockOption : XUiNode
---@field _Control XTemple2Control
local XUiTemple2EditorBlockOption = XClass(XUiNode, "XUiTemple2EditorBlockOption")

function XUiTemple2EditorBlockOption:OnStart()
    self._Data = false
    ---@type XUiTemple2CheckBoardGrid
    self._Grid = XUiTemple2CheckBoardGrid.New(self.Grid, self)
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)

    self._EditorControl = self._Control:GetEditorControl()
end

function XUiTemple2EditorBlockOption:SetEditorControl(control)
    self._EditorControl = control
end

---@param data XUiTemple2EditorBlockOptionData
function XUiTemple2EditorBlockOption:Update(data)
    self._Data = data
    self.TxtName.text = data.Name
    self._Grid:Update(data.Grid)
end

function XUiTemple2EditorBlockOption:OnClick()
    self._EditorControl:SetBlock2EditMap(self._Data.Block)
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_UPDATE_OPERATION)
end

return XUiTemple2EditorBlockOption