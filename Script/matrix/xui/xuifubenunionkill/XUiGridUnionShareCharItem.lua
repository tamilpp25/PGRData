local XUiGridUnionShareCharItem = XClass(nil, "XUiGridUnionShareCharItem")

function XUiGridUnionShareCharItem:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
end

function XUiGridUnionShareCharItem:Init(rootUi)
    self.RootUi = rootUi
end

function XUiGridUnionShareCharItem:Refresh(shareInfos)
    local character = shareInfos.Character
    local characterId = character.Id

    self.RImgHeadIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))
    self.TxtLevel.text = character.Level
    self.TxtFight.text = math.floor(character.Ability)
    self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(character.Quality))
end

return XUiGridUnionShareCharItem