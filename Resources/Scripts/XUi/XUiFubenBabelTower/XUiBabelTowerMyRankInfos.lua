local XUiBabelTowerMyRankInfos = XClass(nil, "XUiBabelTowerMyRankInfos")

function XUiBabelTowerMyRankInfos:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)

    -- HeadIconEffect
end

-- 刷新排名
function XUiBabelTowerMyRankInfos:Refresh()
    local _, maxScore = XDataCenter.FubenBabelTowerManager.GetCurrentActivityScores()
    self.TxtPlayerName.text = XPlayer.Name
    self.TxtRankScore.text = string.format(CS.XTextManager.GetText("BabelTowerMyRankLevel"), maxScore)

    XUiPLayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)

    local curScore, curRank, totalRank = XDataCenter.FubenBabelTowerManager.GetScoreInfos()
    if curRank == 0 then
        self.TxtRankNormal.text = CS.XTextManager.GetText("None")
        self.TxtRankNormal.text = CS.XTextManager.GetText("None")
    elseif curRank <= 100 then
        self.TxtRankNormal.text = curRank
    else
        local playerRank = (curRank * 1) / totalRank * 100
        self.TxtRankNormal.text = string.format("%s%%", math.ceil(playerRank))
    end
end


return XUiBabelTowerMyRankInfos