--
local XUiGuildWarPlayerGrid = XClass(nil, "XUiGuildWarPlayerGrid")

function XUiGuildWarPlayerGrid:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    if self.BtnDetail then
        self.BtnDetail.CallBack = function() self:OnClickBtnDetail() end
    end
end

function XUiGuildWarPlayerGrid:RefreshData(data)
    XUiPlayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.Head)
    self.PlayerId = data.Uid
    self.TxtPlayerName.text = data.Name
    self.TxtPointScore.text = data.Point
    self.TxtActiveScore.text = data.Activation
    local ranking = data.Rank
    if ranking <= 100 then
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

function XUiGuildWarPlayerGrid:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiGuildWarPlayerGrid:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildWarPlayerGrid:OnClickBtnDetail()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.PlayerId)
end

return XUiGuildWarPlayerGrid