-- 虚像地平线我的排行控件
local XUiExpeditionMyRank = XClass(nil, "XUiExpeditionMyRank")

function XUiExpeditionMyRank:Ctor(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
end

function XUiExpeditionMyRank:Refresh()
    XUiPLayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
    self.TxtPlayerName.text = XPlayer.Name
    self:RefreshRankingText()
    self:RefreshRankScore()
end

function XUiExpeditionMyRank:RefreshRankScore()
    local endlessStage = self:GetEndlessStage()
    local eActivity = XDataCenter.ExpeditionManager.GetEActivity()
    local infinityInfo = eActivity:GetInfinityStageInfo()
    local totalScore = 0
    
    for i = 1, 3 do
        local grid = self["Rank0" .. i]
        local txtRankScore = XUiHelper.TryGetComponent(grid, "TxtRankScore", "Text")

        if i == 3 then
            txtRankScore.text = totalScore
            break
        end

        local stageId = infinityInfo[i]
        local score = 0

        if XTool.IsNumberValid(stageId) then
            score = endlessStage[stageId] or 0
        end
        txtRankScore.text = score
        totalScore = totalScore +score
    end
end

-- 获取无限关得分 Key 为StageId value 为分数
function XUiExpeditionMyRank:GetEndlessStage()
    local myRankInfo = XDataCenter.ExpeditionManager.GetMyRankInfo()
    local endlessStage = myRankInfo.EndlessStage or {}
    local tempStage = {}
    for _, info in pairs(endlessStage) do
        if info then
            tempStage[info.Stage] = info.Scores
        end
    end
    return tempStage
end

function XUiExpeditionMyRank:RefreshRankingText()
    local selfRanking = XDataCenter.ExpeditionManager.GetSelfRank()
    if selfRanking == 0 then self.TxtRankNormal.text = CS.XTextManager.GetText("ExpeditionNoRanking") return end
    local icon = XDataCenter.ExpeditionManager.GetRankSpecialIcon(XDataCenter.ExpeditionManager.GetSelfRank())
    if icon then self.RootUi:SetUiSprite(self.ImgRankSpecial, icon) end
    self.TxtRankNormal.gameObject:SetActive(icon == nil)
    self.ImgRankSpecial.gameObject:SetActive(icon ~= nil)
    self.TxtRankNormal.text = XDataCenter.ExpeditionManager.GetSelfRankStr()
end
return XUiExpeditionMyRank