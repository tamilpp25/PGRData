---@class XUiGridBossRank : XUiNode
local XUiGridBossRank = XClass(XUiNode, "XUiGridBossRank")

local MAX_SPECIAL_NUM = 3

function XUiGridBossRank:OnStart(rootUi)
    self._RootUi = rootUi
    self:_RegisterButtonListeners()
end

function XUiGridBossRank:OnEnable()
    self:_Refresh()
end

function XUiGridBossRank:_RegisterButtonListeners()
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick, true)
end

function XUiGridBossRank:_Refresh()
    if not self._RankMetaData or not self._CurLevelType then
        return
    end

    self.TxtRankNormal.gameObject:SetActiveEx(self._RankMetaData.RankNum > MAX_SPECIAL_NUM)
    self.ImgRankSpecial.gameObject:SetActiveEx(self._RankMetaData.RankNum <= MAX_SPECIAL_NUM)
    if self._RankMetaData.RankNum <= MAX_SPECIAL_NUM then
        local icon = XDataCenter.FubenBossSingleManager.GetRankSpecialIcon(math.floor(self._RankMetaData.RankNum),
            self._CurLevelType)
        self._RootUi:SetUiSprite(self.ImgRankSpecial, icon)
    else
        self.TxtRankNormal.text = math.floor(self._RankMetaData.RankNum)
    end
    local text = CS.XTextManager.GetText("BossSingleBossRankSocre", self._RankMetaData.Score)
    self.TxtRankScore.text = text
    self.TxtPlayerName.text = XDataCenter.SocialManager.GetPlayerRemark(self._RankMetaData.PlayerId,
        self._RankMetaData.Name)

    XUiPLayerHead.InitPortrait(self._RankMetaData.HeadPortraitId, self._RankMetaData.HeadFrameId, self.Head)

    for i = 1, #self._RankMetaData.CharacterHeadData do
        self["RImgTeam" .. i].gameObject:SetActiveEx(true)
        local charId = self._RankMetaData.CharacterHeadData[i].Id
        local headInfo = self._RankMetaData.CharacterHeadData[i].CharacterHeadInfo or {}
        local charIcon = XDataCenter.CharacterManager.GetCharSmallHeadIcon(charId, true, headInfo.HeadFashionId,
            headInfo.HeadFashionType)
        self["RImgTeam" .. i]:SetRawImage(charIcon)
    end

    for i = #self._RankMetaData.CharacterHeadData + 1, 3 do
        self["RImgTeam" .. i].gameObject:SetActiveEx(false)
    end
end

function XUiGridBossRank:SetData(rankMetaData, curLevelType)
    self._RankMetaData = rankMetaData
    self._CurLevelType = curLevelType
end

function XUiGridBossRank:OnBtnDetailClick()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self._RankMetaData.PlayerId)
end

return XUiGridBossRank
