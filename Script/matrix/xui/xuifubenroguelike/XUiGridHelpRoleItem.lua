local XUiGridHelpRoleItem = XClass(nil, "XUiGridHelpRoleItem")

function XUiGridHelpRoleItem:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
end

function XUiGridHelpRoleItem:UpdateHelpRoleInfo(robotId)
    local characterId = XRobotManager.GetCharacterId(robotId)
    self.RImgRole:SetRawImage(XDataCenter.CharacterManager.GetCharHalfBodyImage(characterId))
    self.TxtName.text = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
    self.ImgNew.gameObject:SetActiveEx(XDataCenter.FubenRogueLikeManager.IsRobotNew(robotId))
end



return XUiGridHelpRoleItem