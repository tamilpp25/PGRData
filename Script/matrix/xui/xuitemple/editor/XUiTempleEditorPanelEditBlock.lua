local XUiTempleEditorOperation = require("XUi/XUiTemple/Editor/XUiTempleEditorOperation")

---@field _Control XTempleControl
---@class XUiTempleEditorPanelEditBlock:XUiNode
local XUiTempleEditorPanelEditBlock = XClass(XUiNode, "XUiTempleEditorPanelEditBlock")

function XUiTempleEditorPanelEditBlock:OnStart()
    ---@type XTempleGameEditorControl
    self._GameControl = self._Control:GetGameEditorControl()

    ---@type XUiTempleEditorOperation
    self._Operation = XUiTempleEditorOperation.New(self.PanelOperation, self)

    ---@type UnityEngine.UI.InputField
    local inputFiled = self.InputField
    inputFiled.onValueChanged:AddListener(function(value)
        self._GameControl:SetEditingBlockName(value)
    end)
end

function XUiTempleEditorPanelEditBlock:OnEnable()
    self:Update()
end

function XUiTempleEditorPanelEditBlock:Update()
    ---@type XTempleBlock
    local block = self._GameControl:GetEditingBlock()
    if not block then
        return
    end
    self._Operation:SetBlock(block)

    ---@type UnityEngine.UI.InputField
    local inputFiled = self.InputField
    inputFiled.text = block:GetName()
end

return XUiTempleEditorPanelEditBlock