local textManager = CS.XTextManager

local XUiClickClearPanelGeneralFailure = XClass(nil, "XUiClickClearPanelGeneralFailure")

function XUiClickClearPanelGeneralFailure:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiClickClearPanelGeneralFailure:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiClickClearPanelGeneralFailure:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiClickClearPanelGeneralFailure