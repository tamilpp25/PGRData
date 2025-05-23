local XUiGridRoleInfoItem = XClass(nil, "XUiGridRoleInfoItem")

function XUiGridRoleInfoItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridRoleInfoItem:SetRoleInfo(characterId)
    self.RImgRoleIcon:SetRawImage(XMVCA.XCharacter:GetCharRoundnessHeadIcon(characterId))
    self.TxtName.text = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
end

function XUiGridRoleInfoItem:SetRandomRoleInfo()
    self.RImgRoleIcon:SetRawImage(XFubenRogueLikeConfig.UNKNOW_ROBOT)
    self.TxtName.text = CS.XTextManager.GetText("RogueLikeRandomRobotTitle")
end

return XUiGridRoleInfoItem