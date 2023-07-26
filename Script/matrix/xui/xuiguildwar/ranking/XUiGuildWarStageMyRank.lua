---@class XUiGuildWarStageMyRank
local XUiGuildWarStageMyRank = XClass(nil, "XUiGuildWarStageMyRank")

function XUiGuildWarStageMyRank:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    if self.BtnDetail then
        self.BtnDetail.CallBack = function() self:OnClickBtnDetail() end
    end
end

function XUiGuildWarStageMyRank:RefreshData(data)
    XUiPLayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.Head)
    self.TxtPlayerName.text = data.Name
    self.TxtPointScore.text = data.Point
    self.TxtActiveScore.text = data.Activation
    local ranking = data.Rank
    if ranking <= 100 then
        --local icon = XDataCenter.SuperSmashBrosManager.GetRankingSpecialIcon(ranking)
        --if icon then self.RootUi:SetUiSprite(self.ImgRankSpecial, icon) end
        self.TxtRankNormal.gameObject:SetActive(true)--icon == nil)
        self.ImgRankSpecial.gameObject:SetActive(false)--icon ~= nil)
        self.TxtRankNormal.text = ranking == 0 and "-" or ranking
    else
        local rankPercent = math.floor(ranking / data.MemberCount * 100)
        --向下取整低于1时应该也显示为1%
        if rankPercent < 1 then rankPercent = 1 end
        self.TxtRankNormal.gameObject:SetActive(true)
        self.ImgRankSpecial.gameObject:SetActive(false)
        self.TxtRankNormal.text = rankPercent .. "%"
    end
end

function XUiGuildWarStageMyRank:OnClickBtnDetail()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(XPlayer.Id)
end

return XUiGuildWarStageMyRank