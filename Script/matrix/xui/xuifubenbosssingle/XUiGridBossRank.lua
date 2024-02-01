---@class XUiGridBossRank : XUiNode
---@field _Control XFubenBossSingleControl
local XUiGridBossRank = XClass(XUiNode, "XUiGridBossRank")

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

    local rankNumber = self._RankMetaData:GetRankNumber()
    local maxSpecialNumber = self._Control:GetMaxSpecialNumber()

    self.TxtRankNormal.gameObject:SetActiveEx(rankNumber > maxSpecialNumber)
    self.ImgRankSpecial.gameObject:SetActiveEx(rankNumber <= maxSpecialNumber)
    if rankNumber <= maxSpecialNumber then
        local icon = self._Control:GetRankSpecialIcon(math.floor(rankNumber),
            self._CurLevelType)
        self._RootUi:SetUiSprite(self.ImgRankSpecial, icon)
    else
        self.TxtRankNormal.text = math.floor(rankNumber)
    end
    local text = XUiHelper.GetText("BossSingleBossRankScore", self._RankMetaData:GetScore())
    self.TxtRankScore.text = text
    self.TxtPlayerName.text = XDataCenter.SocialManager.GetPlayerRemark(self._RankMetaData:GetId(),
        self._RankMetaData:GetName())

    XUiPLayerHead.InitPortrait(self._RankMetaData:GetHeadPortraitId(), self._RankMetaData:GetHeadFrameId(), self.Head)

    for i = 1, self._RankMetaData:GetCharacterListCount() do
        local character = self._RankMetaData:GetCharacterByIndex(i)
        local charIcon = XMVCA.XCharacter:GetCharSmallHeadIcon(character:GetId(), true, character:GetHeadFashionId(),
        character:GetHeadFashionType())
        
        self["RImgTeam" .. i].gameObject:SetActiveEx(true)
        self["RImgTeam" .. i]:SetRawImage(charIcon)
    end

    for i = self._RankMetaData:GetCharacterListCount() + 1, 3 do
        self["RImgTeam" .. i].gameObject:SetActiveEx(false)
    end
end

function XUiGridBossRank:SetData(rankMetaData, curLevelType)
    ---@type XBossSingleRankShowData
    self._RankMetaData = rankMetaData
    self._CurLevelType = curLevelType

    if self:IsNodeShow() then
        self:_Refresh()
    end
end

function XUiGridBossRank:OnBtnDetailClick()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self._RankMetaData:GetId())
end

return XUiGridBossRank
