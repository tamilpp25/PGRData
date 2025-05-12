local XUiBigWorldSetPanelOther = require("XUi/XUiBigWorld/XSet/SubUi/XUiBigWorldSetPanelOther")

---@class XUiBigWorldSetPanelOtherPC : XUiBigWorldSetPanelOther
---@field SliderAdaptation UnityEngine.UI.Slider
---@field TxtAdaptation UnityEngine.UI.Image
---@field SafeAreaContentPanel XUiSafeAreaAdapter
---@field TogCursor_1 UnityEngine.UI.Toggle
---@field TogCursor_2 UnityEngine.UI.Toggle
---@field TogCursor_3 UnityEngine.UI.Toggle
---@field TGroupCursor UnityEngine.UI.ToggleGroup
---@field Super XUiBigWorldSetPanelOther
---@field ParentUi XUiBigWorldSet
---@field _Control XBigWorldSetControl
local XUiBigWorldSetPanelOtherPC = XMVCA.XBigWorldUI:Register(XUiBigWorldSetPanelOther, "UiBigWorldSetPanelOtherPC")

function XUiBigWorldSetPanelOtherPC:OnTogCursorOneClick(value)
    if value then
        self._Setting:SetCursorSizeValue(XEnumConst.BWSetting.CursorSize.Small)
    end
end

function XUiBigWorldSetPanelOtherPC:OnTogCursorTwoClick(value)
    if value then
        self._Setting:SetCursorSizeValue(XEnumConst.BWSetting.CursorSize.Medium)
    end
end

function XUiBigWorldSetPanelOtherPC:OnTogCursorThreeClick(value)
    if value then
        self._Setting:SetCursorSizeValue(XEnumConst.BWSetting.CursorSize.Large)
    end
end

function XUiBigWorldSetPanelOtherPC:_RegisterButtonClicks()
    self.Super._RegisterButtonClicks(self)
    self.TogCursor_1.onValueChanged:AddListener(Handler(self, self.OnTogCursorOneClick))
    self.TogCursor_2.onValueChanged:AddListener(Handler(self, self.OnTogCursorTwoClick))
    self.TogCursor_3.onValueChanged:AddListener(Handler(self, self.OnTogCursorThreeClick))
end

function XUiBigWorldSetPanelOtherPC:_Refresh()
    self.Super._Refresh(self)
    self.TogCursor_1.isOn = self._Setting:GetCursorSizeValue() == XEnumConst.BWSetting.CursorSize.Small
    self.TogCursor_2.isOn = self._Setting:GetCursorSizeValue() == XEnumConst.BWSetting.CursorSize.Medium
    self.TogCursor_3.isOn = self._Setting:GetCursorSizeValue() == XEnumConst.BWSetting.CursorSize.Large
end

return XUiBigWorldSetPanelOtherPC
