local XUiChessPursuitCardsTip = XLuaUiManager.Register(XLuaUi, "UiChessPursuitCardsTip")
function XUiChessPursuitCardsTip:OnAwake()
    self:AutoAddListener()
end

function XUiChessPursuitCardsTip:OnStart(cardId)
    self.TxtName.text = XChessPursuitConfig.GetCardName(cardId)
    self.TxtWorldDesc.text = XChessPursuitConfig.GetCardDescribe(cardId)
    local cardQualityIcon = XChessPursuitConfig.GetCardTipsQualityIconBg(cardId)
    self:SetUiSprite(self.ImgTipsCards, cardQualityIcon)    --图片背景
    local cardIcon = XChessPursuitConfig.GetCardIcon(cardId)
    self.RImgIcon:SetRawImage(cardIcon)
end

function XUiChessPursuitCardsTip:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnOk, self.Close)
    self:RegisterClickEvent(self.BtnTcanchaungBlack, self.Close)
end