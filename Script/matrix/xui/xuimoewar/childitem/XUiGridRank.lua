local XUiGridRank = XClass(nil, "XUiGridRank")
local CSXTextManagerGetText = CS.XTextManager.GetText
local MAX_SPECIAL_NUM = 3

function XUiGridRank:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridRank:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridRank:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick)
end

function XUiGridRank:Refresh(rankMetaData, rankType)
    if rankMetaData then
        self.RankMetaData = rankMetaData
    else
        return
    end

    self.TxtRankNormal.gameObject:SetActive(self.RankMetaData.Rank > MAX_SPECIAL_NUM)
    self.ImgRankSpecial.gameObject:SetActive(self.RankMetaData.Rank <= MAX_SPECIAL_NUM)
    if self.RankMetaData.Rank <= MAX_SPECIAL_NUM then
        local icon = XMoeWarConfig.RankIcon[self.RankMetaData.Rank]
        self.UiRoot:SetUiSprite(self.ImgRankSpecial, icon)
    else
        self.TxtRankNormal.text = math.floor(self.RankMetaData.Rank)
    end

    local textPrefix = ""
    if rankType == XMoeWarConfig.RankType.Player then
        textPrefix = CSXTextManagerGetText("MoeWarRankPlayer")
    elseif rankType == XMoeWarConfig.RankType.Daily then
        textPrefix = CSXTextManagerGetText("MoeWarRankDaily")
    end
    self.TxtRankScore.text = CSXTextManagerGetText("MoeWarRankScore", textPrefix, self.RankMetaData.Score)
    self.TxtPlayerName.text = XDataCenter.SocialManager.GetPlayerRemark(self.RankMetaData.PlayerId, self.RankMetaData.Name)
    
    XUiPLayerHead.InitPortrait(self.RankMetaData.HeadPortraitId, self.RankMetaData.HeadFrameId, self.Head)
end

function XUiGridRank:OnBtnDetailClick()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.RankMetaData.PlayerId)
end

return XUiGridRank