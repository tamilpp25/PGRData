---@class XUiFubenBossSingleRankMyBossRank : XUiNode
---@field TxtRankNormal UnityEngine.UI.Text
---@field ImgRankSpecial UnityEngine.UI.Image
---@field TxtRankScore UnityEngine.UI.Text
---@field TxtRankPercent UnityEngine.UI.Text
---@field TxtPlayerName UnityEngine.UI.Text
---@field TxtHighestRank UnityEngine.UI.Text
---@field Head UnityEngine.RectTransform
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleRankMyBossRank = XClass(XUiNode, "XUiFubenBossSingleRankMyBossRank")

---@param rankData XBossSingleRankData
function XUiFubenBossSingleRankMyBossRank:Refresh(rankData, id, isChallenge)
    local totalScore = 0
    local boosSingleData = self._Control:GetBossSingleData()
    local maxCount = self._Control:GetMaxRankCount()
    local maxSpecialNumber = self._Control:GetMaxSpecialNumber()
    local rankNumber = rankData:GetRankNumber()
    local totalCount = rankData:GetTotalCount()
    local historyScore = rankData:GetHistoryNumber()

    if isChallenge then
        totalScore = boosSingleData:GetBossSingleChallengeTotalScore()
    else
        totalScore = boosSingleData:GetBossSingleTotalScore()
    end
    if rankNumber <= maxCount and rankNumber > 0 then
        self.TxtRankPercent.gameObject:SetActive(false)
        self.TxtRankNormal.gameObject:SetActive(math.floor(rankNumber) > maxSpecialNumber)
        self.ImgRankSpecial.gameObject:SetActive(rankNumber <= maxSpecialNumber)

        if rankNumber <= maxSpecialNumber then
            local icon = self._Control:GetRankSpecialIcon(math.floor(rankNumber))
            self.Parent:SetUiSprite(self.ImgRankSpecial, icon)
        else
            self.TxtRankNormal.text = math.floor(rankNumber)
        end
    else
        self.TxtRankPercent.gameObject:SetActive(true)
        self.TxtRankNormal.gameObject:SetActive(false)
        self.ImgRankSpecial.gameObject:SetActive(false)
        if rankNumber > 0 then
            if not totalCount or totalCount == 0 then
                self.TxtRankPercent.text = XUiHelper.GetText("None")
            else
                local number = math.floor(rankNumber / totalCount * 100)

                if number < 1 then
                    number = 1
                end

                self.TxtRankPercent.text = XUiHelper.GetText("BossSinglePercentDesc", number)
            end
        else
            self.TxtRankPercent.text = XUiHelper.GetText("None")
        end
    end

    if id then
        local curBossScore = isChallenge and self._Control:GetBossStageScore(id) or self._Control:GetBossCurScore(id)

        self.TxtRankScore.text = XUiHelper.GetText("BossSingleBossRankScore", curBossScore)
    else
        self.TxtRankScore.text = XUiHelper.GetText("BossSingleAllRankScore", totalScore)
    end

    self.TxtPlayerName.text = XPlayer.Name

    XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)

    self.TxtHighestRank.gameObject:SetActiveEx(id == nil)
    if not id then
        if historyScore <= maxCount and historyScore > 0 then
            self.TxtHighestRank.text = math.floor(historyScore)
        else
            self.TxtHighestRank.text = XUiHelper.GetText("None")
        end
    end
end

return XUiFubenBossSingleRankMyBossRank
