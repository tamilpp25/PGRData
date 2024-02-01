local XUiGridExhibitionName = XClass(nil, "XUiGridExhibitionName")

function XUiGridExhibitionName:Ctor(RootUI, index, uiName, exhibitionCfg)
    self.RootUI = RootUI
    self.Index = index
    self.GameObject = uiName.gameObject
    self.Transform = uiName.transform
    XTool.InitUiObject(self)
    self:Refresh(exhibitionCfg)
end

function XUiGridExhibitionName:Refresh(exhibitionCfg)
    self.CharacterId = exhibitionCfg and exhibitionCfg.CharacterId or 0
    local name
    if self.CharacterId == nil or self.CharacterId == 0 then
        name = "???"
    else
        name = XMVCA.XCharacter:GetCharacterFullNameStr(self.CharacterId)
    end
    self.TxtName.text = name
end

function XUiGridExhibitionName:ResetPosition(position)
    self.Transform.position = position
end

return XUiGridExhibitionName