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

function XUiGridRank:Refresh(rankPlayerInfo)
    if not rankPlayerInfo then
        return
    end

    self.RankPlayerInfo = rankPlayerInfo

    local rankNum = rankPlayerInfo:GetRank()
    local isNotRank = not XTool.IsNumberValid(rankNum)
    self.TxtRankNormal.gameObject:SetActive(rankNum > MAX_SPECIAL_NUM)
    self.ImgRankSpecial.gameObject:SetActive(not isNotRank and rankNum <= MAX_SPECIAL_NUM)
    if not isNotRank and rankNum <= MAX_SPECIAL_NUM then
        local icon = XUiHelper.GetRankIcon(math.floor(rankNum))
        self.RootUi:SetUiSprite(self.ImgRankSpecial, icon)
    else
        local totalCount = XDataCenter.DoubleTowersManager.GetRankData():GetMemberCount()
        local rankNumTemp = rankNum < MAX_RANK_COUNT and rankNum or (XTool.IsNumberValid(totalCount) and rankNum / totalCount * 100 or XUiHelper.GetText("None"))
        self.TxtRankNormal.text = math.floor(rankNumTemp)
    end

    local score = rankPlayerInfo:GetScore()
    self.TxtRankScore.text = score

    local playerId = rankPlayerInfo:GetId()
    local name = rankPlayerInfo:GetName()
    self.TxtPlayerName.text = XDataCenter.SocialManager.GetPlayerRemark(playerId, name)

    local headPortraitId = rankPlayerInfo:GetHeadPortraitId()
    local headFrameId = rankPlayerInfo:GetHeadFrameId()
    XUiPLayerHead.InitPortrait(headPortraitId, headFrameId, self.Head)

    if self.TxtNotRank then
        self.TxtNotRank.gameObject:SetActiveEx(isNotRank)
    end
end

function XUiGridRank:OnBtnDetailClick()
    local playerId = self.RankPlayerInfo:GetId()
    if not XTool.IsNumberValid(playerId) then
        return
    end
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(playerId)
end

return XUiGridRank