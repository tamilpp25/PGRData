---@field Parent XUiPanelFightSet
local XGridChooseScheme = XClass(nil, "XGridChooseScheme")
local CSXCustomUi = CS.XCustomUi.Instance

function XGridChooseScheme:Ctor(parent, ui)
    self.Parent = parent
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.GridOption, self.OnGridOptionClick)
end

function XGridChooseScheme:Refresh(schemeIndex)
    self.SchemeIndex = schemeIndex
    self.GridOption:SetName(CSXCustomUi:GetSchemeName(schemeIndex))
    self.GameObject:SetActiveEx(true)
end

function XGridChooseScheme:OnGridOptionClick()
    local isSave = true
    CSXCustomUi:SetCurScheme(self.SchemeIndex, isSave)
    self.Parent:OnBtnChooseClick()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_CUSTOM_UI_SCHEME_CHANGED)
end

return XGridChooseScheme