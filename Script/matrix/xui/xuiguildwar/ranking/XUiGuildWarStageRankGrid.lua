---@class XUiGuildWarStageRankGrid
local XUiGuildWarStageRankGrid = XClass(nil, "XUiGuildWarStageRankGrid")
local PointPanel = require("XUi/XUiGuildWar/Ranking/XUiGuildWarStagePointPanel")
function XUiGuildWarStageRankGrid:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.BeforePanel = PointPanel.New(self.PanelBefore)
    self.StayPanel = PointPanel.New(self.PanelStay)
    if self.BtnDetail then
        self.BtnDetail.CallBack = function() self:OnClickBtnDetail() end
    end
end

function XUiGuildWarStageRankGrid:RefreshData(data, isStay)
    XUiPLayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.Head)
    self.PlayerId = data.Uid
    if isStay then
        self.BeforePanel:Hide()
        self.StayPanel:Show()
        self.StayPanel:RefreshData(data)
    else
        self.BeforePanel:Show()
        self.StayPanel:Hide()
        self.BeforePanel:RefreshData(data)
    end
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

function XUiGuildWarStageRankGrid:OnClickBtnDetail()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.PlayerId)
end

return XUiGuildWarStageRankGrid