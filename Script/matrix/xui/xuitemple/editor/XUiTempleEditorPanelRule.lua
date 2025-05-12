local XUiTempleEditorOperation = require("XUi/XUiTemple/Editor/XUiTempleEditorOperation")

---@field _Control XTempleControl
---@class XUiTempleEditorPanelRule:XUiNode
local XUiTempleEditorPanelRule = XClass(XUiNode, "XUiTempleEditorPanelRule")

function XUiTempleEditorPanelRule:Ctor()
    ---@type XTempleGameEditorControl
    self._GameControl = self._Control:GetGameEditorControl()
end

function XUiTempleEditorPanelRule:OnStart()
    XUiHelper.RegisterClickEvent(self, self.ButtonAddRule, self.OnClickAddRule)
    XUiHelper.RegisterClickEvent(self, self.ButtonDeleteRule, self.OnClickDeleteRule)

    ---@type XUiTempleEditorOperation
    self._Operation = XUiTempleEditorOperation.New(self.PanelOperation, self)

    ---@type UnityEngine.UI.InputField
    local inputField = self.InputField
    inputField.onValueChanged:AddListener(function(value)
        self._GameControl:SetEditingRuleName(value)
    end)

    ---@type UnityEngine.UI.Toggle
    local toggle = self.ToggleHideRule
    toggle.onValueChanged:AddListener(function(isOn)
        self._GameControl:SetEditingRuleHide(isOn)
    end)

    self._DropdownAmount = 8
    self._ToggleAmount = 4
end

function XUiTempleEditorPanelRule:Update()
    local data = self._GameControl:GetEditRule()
    if not data then
        self.RuleText.text = "Empty"
        self._Operation:Close()
        for i = 1, self._DropdownAmount do
            self:SetDropDown(i, false)
        end
        for i = 1, self._ToggleAmount do
            self:SetTimeToggle(i, false)
        end
        self.InputField.text = "Empty"
        return
    end
    self.InputField.text = data.RuleName
    self.RuleText.text = data.Text
    self.ToggleHideRule.isOn = data.RuleIsHide
    for i = 1, self._DropdownAmount do
        self:SetDropDown(i, data.Option[i])
    end
    for i = 1, self._ToggleAmount do
        self:SetTimeToggle(i, data.TimeToggle[i])
    end

    if data.Operation then
        self._Operation:Open()
        local block = data.Operation.Block
        self._Operation:SetBlock(block)
    else
        self._Operation:Close()
    end
end

---@param index number
---@param option XTempleGameEditorRuleOption
function XUiTempleEditorPanelRule:SetDropDown(index, option)
    ---@type XUiComponent.XUiDropdown
    local uiDropdown = self["DropdownRule" .. index]
    if uiDropdown then
        if option then
            uiDropdown.gameObject:SetActiveEx(true)
            uiDropdown:ClearOptions()
            uiDropdown:AddOptionsText(option.DropDown)
            uiDropdown.onValueChanged:RemoveAllListeners()
            uiDropdown.value = option.Selected
            uiDropdown:RefreshShownValue()
            uiDropdown.onValueChanged:AddListener(function(selectIndex)
                XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_EDIT_RULE, option, selectIndex)
            end)
            local image = XUiHelper.TryGetComponent(uiDropdown.transform, "", "Image")
            if image then

                if option.IsKeyParams then
                    image.color = XUiHelper.Hexcolor2Color("88dd88FF")
                else
                    image.color = XUiHelper.Hexcolor2Color("FFFFFFFF")
                end
            end
        else
            uiDropdown.gameObject:SetActiveEx(false)
        end
    end
end

function XUiTempleEditorPanelRule:SetTimeToggle(index, option)
    ---@type UnityEngine.UI.Toggle
    local toggle = self["Toggle" .. index]
    if toggle then
        if option then
            toggle.gameObject:SetActiveEx(true)
            toggle.onValueChanged:RemoveAllListeners()
            toggle.isOn = option.Selected
            toggle.onValueChanged:AddListener(function(selectIndex)
                XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_EDIT_RULE, option, selectIndex)
            end)
        else
            toggle.gameObject:SetActiveEx(false)
        end
    end
end

function XUiTempleEditorPanelRule:OnClickAddRule()
    self._GameControl:AddNewRule()
end

function XUiTempleEditorPanelRule:OnClickDeleteRule()
    self._GameControl:RemoveEditingRule()
end

return XUiTempleEditorPanelRule
