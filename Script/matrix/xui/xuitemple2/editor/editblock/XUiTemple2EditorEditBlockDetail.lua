local XUiTemple2EditorBlockOption = require("XUi/XUiTemple2/Editor/XUiTemple2EditorBlockOption")

---@class XUiTemple2EditorEditBlockDetail : XUiNode
---@field _Control XTemple2Control
local XUiTemple2EditorEditBlockDetail = XClass(XUiNode, "XUiTemple2EditorEditBlockDetail")

function XUiTemple2EditorEditBlockDetail:OnStart()
    ---@type XUiTemple2EditorBlockOption[]
    self._OptionGrids = {}

    ---@type XUiTemple2CheckBoard
    self._CheckBoard = require("XUi/XUiTemple2/Game/XUiTemple2CheckBoard").New(self.PanelCheckerboard, self, self._Control:GetEditorBlockControl())

    XUiHelper.RegisterClickEvent(self, self.ButtonClose, self.OnClickClose)

    ---@type UnityEngine.UI.InputField
    local inputFiled = self.InputField
    inputFiled.onValueChanged:AddListener(function(value)
        self._Control:GetEditorControl():SetNameOfBlockBeingEdited(value)
    end)

    ---@type UnityEngine.UI.InputField
    local inputFiled2 = self.InputField2
    inputFiled2.onValueChanged:AddListener(function(value)
        self._Control:GetEditorControl():SetTypeNameOfBlockBeingEdited(value)
    end)

    ---@type UnityEngine.UI.InputField
    local inputFiled3 = self.InputField3
    if inputFiled3 then
        inputFiled3.onValueChanged:AddListener(function(value)
            value = tonumber(value)
            self._Control:GetEditorControl():SetEffectiveTimesOfBlockBeingEdited(value)
        end)
    end

    self:UpdateEditMap()
end

function XUiTemple2EditorEditBlockDetail:OnEnable()
    local blockBeingEditing = self._Control:GetEditorControl():GetBlockBeingEdited()
    self._Control:GetEditorBlockControl():SetBlockBeingEdited(blockBeingEditing)
    self:Update()
end

function XUiTemple2EditorEditBlockDetail:Update()
    ---@type XTemple2Block
    local block = self._Control:GetEditorBlockControl():GetBlockBeingEdited()
    if not block then
        return
    end

    self._CheckBoard:Update()

    ---@type UnityEngine.UI.InputField
    local inputFiled = self.InputField
    inputFiled.text = block:GetName()

    ---@type UnityEngine.UI.InputField
    local inputFiled2 = self.InputField2
    inputFiled2.text = block:GetTypeName()

    ---@type UnityEngine.UI.InputField
    local inputFiled3 = self.InputField3
    if inputFiled3 then
        local effectiveTimes = block:GetEffectiveTimes()
        if effectiveTimes and effectiveTimes > 0 then
            inputFiled3.text = effectiveTimes
        else
            inputFiled3.text = ""
        end
    end
end

function XUiTemple2EditorEditBlockDetail:UpdateEditMap()
    local options = self:GetControl():GetUiDataBlockOptions()
    XTool.UpdateDynamicItem(self._OptionGrids, options, self.BtnOptionEditor, XUiTemple2EditorBlockOption, self)
    for i = 1, #self._OptionGrids do
        local option = self._OptionGrids[i]
        option:SetEditorControl(self._Control:GetEditorBlockControl())
    end
end

function XUiTemple2EditorEditBlockDetail:GetControl()
    return self._Control:GetEditorBlockControl()
end

function XUiTemple2EditorEditBlockDetail:OnClickClose()
    self:GetControl():ConfirmBlockBeingEdited()
    self:Close()
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_UPDATE_EDIT_BLOCK)
end

return XUiTemple2EditorEditBlockDetail