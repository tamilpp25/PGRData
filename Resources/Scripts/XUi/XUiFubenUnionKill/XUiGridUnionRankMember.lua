local XUiGridUnionRankMember = XClass(nil, "XUiGridUnionRankMember")

function XUiGridUnionRankMember:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridUnionRankMember:RefreshKillRank(info, playerId)
    self.GameObject:SetActiveEx(true)
    self.RImgTeam:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(info.Id, info.LiberateLv))
    self.LikeNum.gameObject:SetActiveEx(false)
    self.HelperIcon.gameObject:SetActiveEx(playerId ~= info.SharerId)
end

function XUiGridUnionRankMember:RefreshPraiseRank(info)
    self.GameObject:SetActiveEx(true)
    self.RImgTeam:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(info.Id, info.LiberateLv))
    self.LikeNum.gameObject:SetActiveEx(true)
    self.HelperIcon.gameObject:SetActiveEx(false)
    self.TxtPraiseNum.text = info.PraiseCount or 0
end

return XUiGridUnionRankMember