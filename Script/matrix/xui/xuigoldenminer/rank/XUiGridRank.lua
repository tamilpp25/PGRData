local XUiGridRank = XClass(nil, "XUiGridRank")

local MAX_SPECIAL_NUM = 3 --前多少名用特殊数字的图片显示
local MAX_RANK_COUNT = 100 --最多显示的排名数

function XUiGridRank:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridRank:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick)
end

function XUiGridRank:Refresh(rankPlayerInfo, isSelf)
    if not rankPlayerInfo then
        return
    end

    self.RankPlayerInfo = rankPlayerInfo

    local rankNum = rankPlayerInfo:GetRank()
    local isNotRank = not XTool.IsNumberValid(rankNum)
    self.TxtRankNormal.gameObject:SetActive(not isNotRank and isSelf or rankNum > MAX_SPECIAL_NUM)
    if not isSelf then
        self.ImgRankSpecial.gameObject:SetActive(not isNotRank and rankNum <= MAX_SPECIAL_NUM)
    end
    if not isSelf and not isNotRank and rankNum <= MAX_SPECIAL_NUM then
        local icon = XUiHelper.GetRankIcon(math.floor(rankNum))
        self.RootUi:SetUiSprite(self.ImgRankSpecial, icon)
    else
        local totalCount = XDataCenter.GoldenMinerManager.GetGoldenMinerRankData():GetTotalCount()
        local rankNumTemp = (rankNum <= MAX_RANK_COUNT and XTool.IsNumberValid(totalCount)) and rankNum or math.floor(rankNum / totalCount * 100) .. "%"
        self.TxtRankNormal.text = rankNumTemp
    end

    self.TxtRankScore.text = rankPlayerInfo:GetScore()

    local playerId = rankPlayerInfo:GetId()
    local name = rankPlayerInfo:GetName()
    self.TxtPlayerName.text = XDataCenter.SocialManager.GetPlayerRemark(playerId, name)

    local headPortraitId = rankPlayerInfo:GetHeadPortraitId()
    local headFrameId = rankPlayerInfo:GetHeadFrameId()
    XUiPLayerHead.InitPortrait(headPortraitId, headFrameId, self.Head)

    local characterId = rankPlayerInfo:GetCharacterId()
    local headPath = XTool.IsNumberValid(characterId) and XGoldenMinerConfigs.GetCharacterHeadPath(characterId)
    if headPath then
        self.RImgTeam:SetRawImage(headPath)
    end
    self.RImgTeam.gameObject:SetActiveEx(headPath and headPath ~= "")

    if self.TxtNotRank then
        self.TxtNotRank.gameObject:SetActiveEx(isNotRank)
    end
end

function XUiGridRank:OnBtnDetailClick()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.RankPlayerInfo:GetId())
end

return XUiGridRank