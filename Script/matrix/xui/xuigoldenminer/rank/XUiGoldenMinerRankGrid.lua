---@class XUiGoldenMinerRankGrid : XUiNode
---@field _Control XGoldenMinerControl
local XUiGoldenMinerRankGrid = XClass(XUiNode, "XUiGoldenMinerRankGrid")

function XUiGoldenMinerRankGrid:OnStart()
    self:AddBtnListener()
end

---@param rankPlayerInfo XGoldenMinerRankPlayerInfo
function XUiGoldenMinerRankGrid:Refresh(rankPlayerInfo, isSelf)
    if not rankPlayerInfo then
        return
    end
    self._RankPlayerInfo = rankPlayerInfo
    self:_RefreshRank(isSelf)
    self:_RefreshPlayerInfo()
    self:_RefreshGameScore()
    self:_RefreshHex()
end

function XUiGoldenMinerRankGrid:SetCanvasGroupAlpha(value)
    if self.GridRankCanvasGroup then
        self.GridRankCanvasGroup.alpha = value
    end
end

function XUiGoldenMinerRankGrid:PlayAnimationRefresh()
    if self.GridRankEnable then
        self.GridRankEnable:PlayTimelineAnimation()
    end
end

function XUiGoldenMinerRankGrid:_RefreshRank(isSelf)
    local rankNum = self._RankPlayerInfo:GetRank()
    local isNotRank = not XTool.IsNumberValid(rankNum)
    self.TxtRankNormal.gameObject:SetActive(not isNotRank and isSelf or rankNum > XEnumConst.GOLDEN_MINER.RANK_MAX_SPECIAL_NUM)
    if not isSelf then
        self.ImgRankSpecial.gameObject:SetActive(not isNotRank and rankNum <= XEnumConst.GOLDEN_MINER.RANK_MAX_SPECIAL_NUM)
    end
    if not isSelf and not isNotRank and rankNum <= XEnumConst.GOLDEN_MINER.RANK_MAX_SPECIAL_NUM then
        local icon = XUiHelper.GetRankIcon(math.floor(rankNum))
        self.ImgRankSpecial:SetSprite(icon)
    else
        local totalCount = self._Control:GetRankDb():GetTotalCount()
        local rankPercent = math.max(math.min(math.floor(rankNum / totalCount * 100), 99), 1)
        local rankNumTemp = (rankNum <= XEnumConst.GOLDEN_MINER.RANK_MAX_COUNT and XTool.IsNumberValid(totalCount)) and rankNum or rankPercent .. "%"
        self.TxtRankNormal.text = rankNumTemp
    end
    if self.TxtNotRank then
        self.TxtNotRank.gameObject:SetActiveEx(isNotRank)
    end
end

function XUiGoldenMinerRankGrid:_RefreshPlayerInfo()
    local playerId = self._RankPlayerInfo:GetId()
    local name = self._RankPlayerInfo:GetName()
    self.TxtPlayerName.text = XDataCenter.SocialManager.GetPlayerRemark(playerId, name)

    local headPortraitId = self._RankPlayerInfo:GetHeadPortraitId()
    local headFrameId = self._RankPlayerInfo:GetHeadFrameId()
    XUiPlayerHead.InitPortrait(headPortraitId, headFrameId, self.Head)
end

function XUiGoldenMinerRankGrid:_RefreshGameScore()
    self.TxtRankScore.text = self._RankPlayerInfo:GetScore()
end

function XUiGoldenMinerRankGrid:_RefreshCharacter()
    local characterId = self._RankPlayerInfo:GetCharacterId()
    local headPath = XTool.IsNumberValid(characterId) and self._Control:GetCfgCharacterHeadIcon(characterId)
    if headPath then
        self.RImgTeam:SetRawImage(headPath)
    end
    self.RImgTeam.gameObject:SetActiveEx(headPath and headPath ~= "")
end

function XUiGoldenMinerRankGrid:_RefreshHex()
    local hexes = self._RankPlayerInfo:GetHexes()
    if XTool.IsTableEmpty(hexes) then
        self.PlayerTeam.gameObject:SetActiveEx(false)
        self.PlayerTeam2.gameObject:SetActiveEx(false)
    else
        local hex1Icon = hexes[1] and self._Control:GetCfgHexIcon(hexes[1])
        local hex2Icon = hexes[2] and self._Control:GetCfgHexIcon(hexes[2])
        if not string.IsNilOrEmpty(hex1Icon) then
            self.PlayerTeam.gameObject:SetActiveEx(true)
            self.RImgTeam:SetRawImage(hex1Icon)
        else
            self.PlayerTeam.gameObject:SetActiveEx(false)
        end
        if not string.IsNilOrEmpty(hex2Icon) then
            self.PlayerTeam2.gameObject:SetActiveEx(true)
            self.RImgTeam2:SetRawImage(hex2Icon)
        else
            self.PlayerTeam2.gameObject:SetActiveEx(false)
        end
    end
end

--region Ui - BtnListener
function XUiGoldenMinerRankGrid:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick)
end

function XUiGoldenMinerRankGrid:OnBtnDetailClick()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self._RankPlayerInfo:GetId())
end
--endregion

return XUiGoldenMinerRankGrid