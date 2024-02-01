local XUiGridCharacterCareer = XClass(nil, "XUiGridCharacterCareer")

function XUiGridCharacterCareer:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridCharacterCareer:Refresh(careerId)
    local name = XMVCA.XCharacter:GetCareerName(careerId)
    self.TxtTypeName.text = name

    local des = XMVCA.XCharacter:GetCareerDes(careerId)
    self.TxtTypeDes.text = des

    local icon = XMVCA.XCharacter:GetNpcTypeIcon(careerId)
    self.RImgCareerType:SetRawImage(icon)
end

return XUiGridCharacterCareer