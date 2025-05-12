local MAX_SPECIAL_NUM = 3 --前多少名用特殊数字的图片显示
local MAX_RANK_COUNT = 100 --最多显示的排名数

local XUiGridAreaWarRank = XClass(nil, "XUiGridAreaWarRank")

function XUiGridAreaWarRank:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    if self.BtnDetail then
        XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick)
    end
end

function XUiGridAreaWarRank:Refresh(rankItem)
    self.RankItem = rankItem

    local rankCount = math.floor(rankItem.Rank)
    if XTool.IsNumberValid(rankCount) and rankCount <= MAX_RANK_COUNT then
        if rankCount <= MAX_SPECIAL_NUM then
            local icon = XUiHelper.GetRankIcon(rankCount)
            self.ImgRankSpecial:SetRawImage(icon)
            self.TxtRankNormal.gameObject:SetActiveEx(false)
            self.ImgRankSpecial.gameObject:SetActiveEx(true)
        else
            self.TxtRankNormal.text = math.floor(rankCount)
            self.ImgRankSpecial.gameObject:SetActiveEx(false)
            self.TxtRankNormal.gameObject:SetActiveEx(true)
        end
        if self.TxtRankPercent then
            self.TxtRankPercent.gameObject:SetActiveEx(false)
        end
    else
        local text = ""
        if XTool.IsNumberValid(rankItem.MemberCount) and rankCount > 0 then
            local num = math.floor(rankCount / (rankItem.MemberCount) * 100)
            --排行榜范围 1-99
            num = math.min(num, 99)
            num = math.max(num, 1)
            text = CS.XTextManager.GetText("BossSinglePercentDesc", num)
        else
            text = CS.XTextManager.GetText("None")
        end

        if self.TxtRankPercent then
            self.TxtRankPercent.text = text
            self.TxtRankPercent.gameObject:SetActiveEx(true)
            self.TxtRankNormal.gameObject:SetActiveEx(false)
        else
            self.TxtRankNormal.text = text
            self.TxtRankNormal.gameObject:SetActiveEx(true)
        end
        self.ImgRankSpecial.gameObject:SetActiveEx(false)
    end
    
    self.TxtRankScore.text = rankItem.Score
    self.TxtNum.text = rankItem.LikeCount
    self.TxtPlayerName.text = XDataCenter.SocialManager.GetPlayerRemark(rankItem.PlayerId, rankItem.Name)
    XUiPlayerHead.InitPortrait(rankItem.HeadPortraitId, rankItem.HeadFrameId, self.Head)
end

function XUiGridAreaWarRank:OnBtnDetailClick()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.RankItem.PlayerId)
end

return XUiGridAreaWarRank
