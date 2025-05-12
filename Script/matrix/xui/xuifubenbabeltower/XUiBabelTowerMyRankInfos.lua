---@class XUiBabelTowerMyRankInfos
local XUiBabelTowerMyRankInfos = XClass(nil, "XUiBabelTowerMyRankInfos")

function XUiBabelTowerMyRankInfos:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
end

-- 刷新排名
function XUiBabelTowerMyRankInfos:Refresh()
    local curScore, curRank, totalRank, minTime = XDataCenter.FubenBabelTowerManager.GetScoreInfos()
    self.TxtPlayerName.text = XPlayer.Name
    self.TxtRankScore.text = string.format(CS.XTextManager.GetText("BabelTowerMyRankLevel"), curScore)

    XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)

    if curRank == 0 then
        self.TxtRankNormal.text = CS.XTextManager.GetText("None")
        self.TxtRankNormal.text = CS.XTextManager.GetText("None")
    elseif curRank <= 100 then
        self.TxtRankNormal.text = curRank
    else
        local playerRank = (curRank * 1) / totalRank * 100
        self.TxtRankNormal.text = string.format("%s%%", math.ceil(playerRank))
    end

    -- 最短通关时间
    if self.TxtRankTime then
        local time = minTime or 0
        self.PanelRankTime.gameObject:SetActiveEx(time > 0)
        self.TxtRankTime.text = XTime.TimestampToGameDateTimeString(time, "mm:ss")
    end
end

return XUiBabelTowerMyRankInfos
