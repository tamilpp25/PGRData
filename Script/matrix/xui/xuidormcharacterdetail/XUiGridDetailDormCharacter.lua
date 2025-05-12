local XUiGridDetailDormCharacter = XClass(nil, "XUiGridDetailDormCharacter")

function XUiGridDetailDormCharacter:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridDetailDormCharacter:Refresh(id, isLike, isPet)
    self.Id = id
    if isPet then
        self:RefreshPet(isLike)
    else
        self:RefreshCharacter(isLike)
    end

    self.PanelLikeIcon.gameObject:SetActive(isLike)
    self.PanelHateIcon.gameObject:SetActive(not isLike)
end

function XUiGridDetailDormCharacter:RefreshCharacter()
    local id = self.Id
    local charStyleConfig = XDormConfig.GetCharacterStyleConfigById(id)
    self.RImgHead:SetRawImage(charStyleConfig.HeadRoundIcon, nil, true)
    self.TxtCharacterName.text = charStyleConfig.Name
end

function XUiGridDetailDormCharacter:RefreshPet()
    local id = self.Id
    local template = XDormConfig.GetDormPetTemplate(id)
    self.RImgHead:SetRawImage(template.HeadRoundIcon, nil, true)
    self.TxtCharacterName.text = template.Name
end

return XUiGridDetailDormCharacter