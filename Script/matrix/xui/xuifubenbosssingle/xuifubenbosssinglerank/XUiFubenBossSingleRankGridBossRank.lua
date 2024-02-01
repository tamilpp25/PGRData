---@class XUiFubenBossSingleRankGridBossRank : XUiNode
---@field TxtRankScore UnityEngine.UI.Text
---@field TxtPlayerName UnityEngine.UI.Text
---@field TxtRankNormal UnityEngine.UI.Text
---@field ImgRankSpecial UnityEngine.UI.Image
---@field RImgTeam1 UnityEngine.UI.RawImage
---@field RImgTeam2 UnityEngine.UI.RawImage
---@field RImgTeam3 UnityEngine.UI.RawImage
---@field BtnDetail UnityEngine.UI.Button
---@field Head UnityEngine.RectTransform
---@field PlayerTeam UnityEngine.RectTransform
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleRankGridBossRank = XClass(XUiNode, "XUiFubenBossSingleRankGridBossRank")

local MAX_SPECIAL_NUM = 3

function XUiFubenBossSingleRankGridBossRank:OnStart(levelType)
    self._LevelType = levelType
    self._PlayerId = XPlayer.Id
    self:_RegisterButtonClicks()
end

---@param data XBossSingleRankShowData
function XUiFubenBossSingleRankGridBossRank:Refresh(data, isBossRank, isChallenge)
    local rankNumber = data:GetRankNumber()

    self._PlayerId = data:GetId()
    self.TxtRankNormal.gameObject:SetActiveEx(rankNumber > MAX_SPECIAL_NUM)
    self.ImgRankSpecial.gameObject:SetActiveEx(rankNumber <= MAX_SPECIAL_NUM)

    if rankNumber <= MAX_SPECIAL_NUM then
        local icon = self._Control:GetRankSpecialIcon(math.floor(rankNumber), self._LevelType)

        self.Parent:SetUiSprite(self.ImgRankSpecial, icon)
    else
        self.TxtRankNormal.text = math.floor(rankNumber)
    end

    self.TxtPlayerName.text = XDataCenter.SocialManager.GetPlayerRemark(data:GetId(), data:GetName())
    self.PlayerTeam.gameObject:SetActiveEx(isBossRank)

    XUiPLayerHead.InitPortrait(data:GetHeadPortraitId(), data:GetHeadFrameId(), self.Head)
    if isBossRank then
        self.TxtRankScore.text = XUiHelper.GetText("BossSingleBossRankScore", data:GetScore())
        for i = 1, data:GetCharacterListCount() do
            local character = data:GetCharacterByIndex(i)
            local charIcon = XMVCA.XCharacter:GetCharSmallHeadIcon(character:GetId(), true,
            character:GetHeadFashionId(), character:GetHeadFashionType())
            
            self["RImgTeam" .. i].gameObject:SetActiveEx(true)
            self["RImgTeam" .. i]:SetRawImage(charIcon)
        end
        for i = data:GetCharacterListCount() + 1, 3 do
            self["RImgTeam" .. i].gameObject:SetActiveEx(false)
        end
    else
        self.TxtRankScore.text = XUiHelper.GetText("BossSingleAllRankScore", data:GetScore())
    end
end

-- region 按钮事件

function XUiFubenBossSingleRankGridBossRank:OnBtnDetailClick()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self._PlayerId)
end

-- endregion

-- region 私有方法

function XUiFubenBossSingleRankGridBossRank:_RegisterButtonClicks()
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick, true)
end

-- endregion

return XUiFubenBossSingleRankGridBossRank
