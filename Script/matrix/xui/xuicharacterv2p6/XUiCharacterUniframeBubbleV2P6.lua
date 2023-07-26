local XUiCharacterUniframeBubbleV2P6 = XLuaUiManager.Register(XLuaUi, "UiCharacterUniframeBubbleV2P6")

function XUiCharacterUniframeBubbleV2P6:OnAwake()
    self:InitButton()
end

function XUiCharacterUniframeBubbleV2P6:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

function XUiCharacterUniframeBubbleV2P6:OnEnable()
    local str = CS.XTextManager.GetText("UiCharacterUniframeBubbleV2P6Text")
    self.TxtInformation.text = XUiHelper.ReplaceTextNewLine(str)
end

return XUiCharacterUniframeBubbleV2P6
