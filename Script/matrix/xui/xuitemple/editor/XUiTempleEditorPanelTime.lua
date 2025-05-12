---@field _Control XTempleControl
---@class XUiTempleEditorPanelTime:XUiNode
local XUiTempleEditorPanelTime = XClass(XUiNode, "XUiTempleEditorPanelTime")

function XUiTempleEditorPanelTime:Ctor()
    ---@type XTempleGameEditorControl
    self._GameControl = self._Control:GetGameEditorControl()
end

function XUiTempleEditorPanelTime:Update()
    local timeData = self._GameControl:GetData4EditTime()
    for i = 1, #timeData do
        local data = timeData[i]
        ---@type UnityEngine.UI.Toggle
        local toggle = self["Toggle" .. i]
        if toggle then
            toggle.onValueChanged:RemoveAllListeners()
            toggle.isOn = data.IsOn
            toggle.onValueChanged:AddListener(function(isOn)
                data.IsOn = isOn
                XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_EDIT_TIME, data)
                self:Update()
            end)
        end
        ---@type XUiComponent.XUiDropdown
        local uiDropdown = self["DropdownSpend" .. i]
        if uiDropdown then
            if data.IsOn then
                uiDropdown.gameObject:SetActiveEx(true)
                uiDropdown:ClearOptions()
                uiDropdown:AddOptionsText(data.DropDown)
                uiDropdown.onValueChanged:RemoveAllListeners()
                uiDropdown.value = data.Selected
                uiDropdown:RefreshShownValue()
                uiDropdown.onValueChanged:AddListener(function(selectIndex)
                    data.Selected = selectIndex
                    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_EDIT_TIME, data, data.isOn)
                end)
            else
                uiDropdown.gameObject:SetActiveEx(false)
            end
        end
    end
end

return XUiTempleEditorPanelTime
