local XUiRiftRankingGrid = XClass(nil, "UiRiftRankingGrid")
local MAX_TEAM_CNT = 3

function XUiRiftRankingGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
end

function XUiRiftRankingGrid:Init()
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiRiftRankingGrid:Refresh(rankInfo)
    self.RankInfo = rankInfo
    local icon = XDataCenter.RiftManager.GetRankingSpecialIcon(rankInfo.Rank)
    if icon then 
        self.ImgRankSpecial:SetSprite(icon)
    end
    self.TxtRankNormal.gameObject:SetActive(icon == nil)
    self.ImgRankSpecial.gameObject:SetActive(icon ~= nil)
    self.TxtRankNormal.text = rankInfo.Rank
    self.TxtPlayerName.text = rankInfo.Name
    local layer = math.floor(rankInfo.Score / 10000)
    self.TxtDeep.text = layer
    local spendTime = 1000 - rankInfo.Score % 1000
    if layer == 0 then spendTime = 0 end -- 未挑战时发默认积分9999，为通关0层耗时1秒，修正耗时1秒
    self.TxtSpendTime.text = XUiHelper.GetTime(spendTime, XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)
    XUiPLayerHead.InitPortrait(rankInfo.HeadPortraitId, rankInfo.HeadFrameId, self.Head)

    for i = 1, MAX_TEAM_CNT do
        local roleId = rankInfo.CharacterIds and rankInfo.CharacterIds[i]
        local roleName = "PanelRole" .. i
        self[roleName].gameObject:SetActiveEx(roleId ~= nil)
        if roleId then 
            local roleIcon = XDataCenter.CharacterManager.GetCharSmallHeadIcon(roleId, false)
            local imgName = "ImgRole" .. i
            self[imgName]:SetRawImage(roleIcon)
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
