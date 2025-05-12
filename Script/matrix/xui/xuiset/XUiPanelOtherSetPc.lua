local XUiPanelOtherSet = require("XUi/XUiSet/XUiPanelOtherSet")
---@class XUiPanelOtherSetPc : XUiPanelOtherSet
local XUiPanelOtherSetPc = XClass(XUiPanelOtherSet, "XUiPanelOtherSetPc")
local XCursorHelper = CS.XPc.XCursorHelper

function XUiPanelOtherSetPc:OnStart()
    self.Super.OnStart(self)
    self._IsDirtyPc = false
    self._CursorSizeIndex = XCursorHelper.CursorSizeIndex
    self:InitPc()
end

function XUiPanelOtherSetPc:InitPc()
    self:InitCursorToggles()
end

function XUiPanelOtherSetPc:InitCursorToggles()
    self:UpdateCursorToggles()

    self.TogCursorSize_0.onValueChanged:AddListener(function()
        if self._RevertingCursorSize then
            return
        end
        if self.TogCursorSize_0.isOn then
            self._IsDirtyPc = true
            self._CursorSizeIndex = 0
        end
    end)

    self.TogCursorSize_1.onValueChanged:AddListener(function()
        if self._RevertingCursorSize then
            return
        end
        if self.TogCursorSize_1.isOn then
            self._IsDirtyPc = true
            self._CursorSizeIndex = 1
        end
    end)

    self.TogCursorSize_2.onValueChanged:AddListener(function()
        if self._RevertingCursorSize then
            return
        end
        if self.TogCursorSize_2.isOn then
            self._IsDirtyPc = true
            self._CursorSizeIndex = 2
        end
    end)
end

function XUiPanelOtherSetPc:UpdateCursorToggles()
    self.TogCursorSize_0.isOn = self._CursorSizeIndex == 0
    self.TogCursorSize_1.isOn = self._CursorSizeIndex == 1
    self.TogCursorSize_2.isOn = self._CursorSizeIndex == 2
end

function XUiPanelOtherSetPc:RevertCursorSetting()
    self._RevertingCursorSize = true
    self._CursorSizeIndex = 1
    self:UpdateCursorToggles()
    self._RevertingCursorSize = false
end

function XUiPanelOtherSetPc:SaveChange()
    XUiPanelOtherSetPc.Super.SaveChange(self)
    self._IsDirtyPc = false
    XCursorHelper.CursorSizeIndex = self._CursorSizeIndex
    CS.XFightUiManager.NoUiMode = self._IsNoUiMode
end

function XUiPanelOtherSetPc:CheckDataIsChange()
    return self._IsDirtyPc or XUiPanelOtherSetPc.Super.CheckDataIsChange(self)
end

function XUiPanelOtherSetPc:ResetToDefault()
    XUiPanelOtherSetPc.Super.ResetToDefault(self)
    self:RevertCursorSetting()
    XCursorHelper.CursorSizeIndex = self._CursorSizeIndex
end

return XUiPanelOtherSetPc