--预设队伍界面头像控件
local XUiExpeditionDefaultHead = XClass(nil, "XUiExpeditionDefaultHead")

function XUiExpeditionDefaultHead:Ctor(uiGameObject, onClickCb)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.OnClickCallBack = onClickCb
    XUiHelper.RegisterClickEvent(self, self.RImgHead, handler(self, self.OnClickHead))
end

function XUiExpeditionDefaultHead:RefreshData(eCharaCfg, rank)
    if not eCharaCfg then
        self:Hide()
        return
    end
    self:Show()
    local characterId = eCharaCfg.CharacterId
    local fashionId = XMVCA.XCharacter:GetCharacterTemplate(characterId).DefaultNpcFashtionId
    local icon = XDataCenter.FashionManager.GetFashionBigHeadIcon(fashionId)
    self.RImgHead:SetRawImage(icon)
    self.TxtStar.text = rank
    self.TxtName.text = XMVCA.XCharacter:GetCharacterTradeName(characterId)
end

function XUiExpeditionDefaultHead:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiExpeditionDefaultHead:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiExpeditionDefaultHead:OnClickHead()
    if self.OnClickCallBack then
        self.OnClickCallBack()
    end 
end

return XUiExpeditionDefaultHead