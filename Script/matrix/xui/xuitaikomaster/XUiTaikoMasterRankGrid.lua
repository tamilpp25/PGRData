local XUiTaikoMasterRankGrid = XClass(nil, "XUiTaikoMasterRankGrid")

function XUiTaikoMasterRankGrid:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    self.RootUi = rootUi
    self._RankInfo = nil
    -- 1到3名显示彩色的数字
    self._ColorRankIndex = 3
    self._LevelType = 1
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClicked)
end

function XUiTaikoMasterRankGrid:SetData(rankInfo, songId)
    self._RankInfo = rankInfo
    -- 名次
    local showColorRank = rankInfo.Rank <= self._ColorRankIndex
    self.TxtRankNormal.gameObject:SetActiveEx(not showColorRank)
    self.ImgRankSpecial.gameObject:SetActiveEx(showColorRank)
    if showColorRank then
        local icon = XDataCenter.FubenBossSingleManager.GetRankSpecialIcon(rankInfo.Rank, self._LevelType)
        self.RootUi:SetUiSprite(self.ImgRankSpecial, icon)
    else
        self.TxtRankNormal.text = rankInfo.Rank
    end
    if rankInfo.Id == XPlayer.Id then
        self:RefreshMyRank(songId)
    else
        -- 头像
        XUiPLayerHead.InitPortrait(rankInfo.HeadPortraitId, rankInfo.HeadFrameId, self.Head)
        -- 名字
        self.TxtPlayerName.text = rankInfo.Name
    end
    -- 最高分数
    self.TxtRankScore.text = XUiHelper.GetText("TaikoMasterScore", rankInfo.Score)
    -- 连击数
    self.TxtCombo.text = XUiHelper.GetText("TaikoMasterCombo", rankInfo.Combo)
    -- 准确率
    self.TxtAccuracy.text = XUiHelper.GetText("TaikoMasterAccuracy", rankInfo.Accuracy)
end

function XUiTaikoMasterRankGrid:RefreshMyRank(songId)
    self.TxtPlayerName.text = XPlayer.Name
    XUiPLayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
end

function XUiTaikoMasterRankGrid:OnBtnDetailClicked()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self._RankInfo.Id)
end

return XUiTaikoMasterRankGrid
