local XUiBabelMemberSmallHead = XClass(nil, "XUiBabelMemberSmallHead")

function XUiBabelMemberSmallHead:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiBabelMemberSmallHead:UpdateMember(characterId)
    self.ImgIcon:SetRawImage(XMVCA.XCharacter:GetCharRoundnessHeadIcon(characterId))
    -- local character = XMVCA.XCharacter:GetCharacter(characterId)
end

return XUiBabelMemberSmallHead