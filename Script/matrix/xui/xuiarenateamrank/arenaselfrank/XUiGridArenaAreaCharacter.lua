local XUiGridArenaAreaCharacter = XClass(nil, "XUiGridArenaAreaCharacter")

function XUiGridArenaAreaCharacter:Ctor(gameObject)
    self.GameObject = gameObject
    self.Transform = gameObject.transform
    XTool.InitUiObject(self)
    self.TxtDis = self.Normal:FindTransform("TxtDis"):GetComponent("Text")
    self.ImgLeftNull = self.GameObject:FindTransform("ImgLeftnull"):GetComponent("Image")
    self.ImgRightNull = self.GameObject:FindTransform("ImgRightnull"):GetComponent("Image")
end

function XUiGridArenaAreaCharacter:Refresh(characterId, partnerId, fightScore, quality, headInfo, color)
    self.Normal.gameObject:SetActiveEx(characterId ~= 0)
    self.Disable.gameObject:SetActiveEx(characterId == 0)
    self.RImgPetIcon.gameObject:SetActiveEx(partnerId ~= 0)
    self.TxtDis.gameObject:SetActiveEx(partnerId == 0)
    self.ImgLeftNull.color = color
    self.ImgRightNull.color = color
    if characterId and characterId ~= 0 then
        if headInfo then
            self.RImgRoleIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId, true, headInfo.HeadFashionId, headInfo.HeadFashionType))
        else
            self.RImgRoleIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))
        end
        self.TxtName.text = XMVCA.XCharacter:GetCharacterLogName(characterId)
    end
    if partnerId and partnerId ~= 0 then
        self.RImgPetIcon:SetRawImage(XPartnerConfigs.GetPartnerTemplateIcon(partnerId))
    end
    if fightScore then
        self.TxtFight.text = fightScore
    end
    if quality and quality ~= 0 then
        self.ImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(quality))
    end
end

return XUiGridArenaAreaCharacter