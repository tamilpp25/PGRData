---@class XUiRiftRankingGrid:XUiNode
---@field Parent XUiRiftRanking
---@field _Control XRiftControl
local XUiRiftRankingGrid = XClass(XUiNode, "UiRiftRankingGrid")
local MAX_TEAM_CNT = 3

function XUiRiftRankingGrid:Init()
    self:SetButtonCallBack()
end

function XUiRiftRankingGrid:Refresh(rankInfo)
    self.RankInfo = rankInfo
    local icon = self._Control:GetRankingSpecialIcon(rankInfo.Rank)
    if icon then 
        self.ImgRankSpecial:SetSprite(icon)
    end
    self.TxtRankNormal.gameObject:SetActive(icon == nil)
    self.ImgRankSpecial.gameObject:SetActive(icon ~= nil)
    self.TxtRankNormal.text = rankInfo.Rank
    self.TxtPlayerName.text = rankInfo.Name
    -- rankInfo.Score后端用来排序用的 实际显示需要用10000减掉（分数不会超过10000 服务端有判断）
    self.TxtSpendTime.text = XUiHelper.GetTime(10000 - rankInfo.Score, XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)
    XUiPlayerHead.InitPortrait(rankInfo.HeadPortraitId, rankInfo.HeadFrameId, self.Head)

    for i = 1, MAX_TEAM_CNT do
        local roleId = rankInfo.CharacterIds and rankInfo.CharacterIds[i]
        local roleName = "PanelRole" .. i
        if self[roleName] then
            self[roleName].gameObject:SetActiveEx(roleId ~= nil)
            if roleId then
                local roleIcon = XMVCA.XCharacter:GetCharSmallHeadIcon(roleId, false)
                local imgName = "ImgRole" .. i
                self[imgName]:SetRawImage(roleIcon)
            end
        end
    end
end

function XUiRiftRankingGrid:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.Transform, self.OnBtnDetailClicked)
end

function XUiRiftRankingGrid:OnBtnDetailClicked()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.RankInfo.Id)
end

return XUiRiftRankingGrid
