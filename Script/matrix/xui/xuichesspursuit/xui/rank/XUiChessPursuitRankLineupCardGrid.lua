local XUiChessPursuitRankLineupCardGrid = XClass(nil, "XUiChessPursuitRankLineupCardGrid")

function XUiChessPursuitRankLineupCardGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.BtnClickCard.CallBack = function() self:OnClickCard() end
end

function XUiChessPursuitRankLineupCardGrid:Refresh(cardId)
    if not cardId then return end

    self.CardId = cardId
    if self.RootUi then
        local cardQualityIcon = XChessPursuitConfig.GetCardTipsQualityIconBg(cardId)
        self.RootUi:SetUiSprite(self.ImgTipsCards, cardQualityIcon)
    end
    if self.RImgIcon then
        local cardIcon = XChessPursuitConfig.GetCardIcon(cardId)
        self.RImgIcon:SetRawImage(cardIcon)
    end
end

function XUiChessPursuitRankLineupCardGrid:OnClickCard()
    XLuaUiManager.Open("UiChessPursuitCardsTip", self.CardId)
end

return XUiChessPursuitRankLineupCardGrid