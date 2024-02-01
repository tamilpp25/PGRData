local XUiGridUnionRankMember = XClass(nil, "XUiGridUnionRankMember")

function XUiGridUnionRankMember:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridUnionRankMember:RefreshKillRank(info, playerId)
    self.GameObject:SetActiveEx(true)
    local headInfo = info.CharacterHeadInfo or {}
    self.RImgTeam:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(info.Id, true, headInfo.HeadFashionId, headInfo.HeadFashionType))
    self.LikeNum.gameObject:SetActiveEx(false)
    self.HelperIcon.gameObject:SetActiveEx(playerId ~= info.SharerId)
end

function XUiGridUnionRankMember:RefreshPraiseRank(info)
    self.GameObject:SetActiveEx(true)
    local headInfo = info.CharacterHeadInfo or {}
    self.RImgTeam:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(info.Id, true, headInfo.HeadFashionId, headInfo.HeadFashionType))
    self.LikeNum.gameObject:SetActiveEx(true)
    self.HelperIcon.gameObject:SetActiveEx(false)
    self.TxtPraiseNum.text = info.PraiseCount or 0
end

return XUiGridUnionRankMember