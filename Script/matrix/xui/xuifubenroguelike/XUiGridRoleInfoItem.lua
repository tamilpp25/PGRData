local XUiGridRoleInfoItem = XClass(nil, "XUiGridRoleInfoItem")

function XUiGridRoleInfoItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridRoleInfoItem:SetRoleInfo(characterId)
    self.RImgRoleIcon:SetRawImage(XDataCenter.CharacterManager.GetCharRoundnessHeadIcon(characterId))
    self.TxtName.text = XCharacterConfigs.GetCharacterFullNameStr(characterId)
end

function XUiGridRoleInfoItem:SetRandomRoleInfo()
    self.RImgRoleIcon:SetRawImage(XFubenRogueLikeConfig.UNKNOW_ROBOT)
    self.TxtName.text = CS.XTextManager.GetText("RogueLikeRandomRobotTitle")
end

return XUiGridRoleInfoItem