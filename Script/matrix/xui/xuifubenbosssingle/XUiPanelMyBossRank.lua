---@class XUiPanelMyBossRank : XUiNode
---@field _Control XFubenBossSingleControl
local XUiPanelMyBossRank = XClass(XUiNode, "XUiPanelMyBossRank")

function XUiPanelMyBossRank:OnStart(rootUi)
    self._RootUi = rootUi
end

function XUiPanelMyBossRank:OnEnable()
    self:_Refresh()
end

function XUiPanelMyBossRank:_Refresh()
    if not self.RankMyData then
        return
    end

    local rankMyData = self.RankMyData
    local boosSingleData = self._Control:GetBossSingleData()
    local maxCount = self._Control:GetMaxRankCount()
    local maxSpecialNumber = self._Control:GetMaxSpecialNumber()

    if rankMyData.MineRankNum <= maxCount and rankMyData.MineRankNum > 0 then
        self.TxtRankPrecent.gameObject:SetActive(false)
        self.TxtRankNormal.gameObject:SetActive(math.floor(rankMyData.MineRankNum) > maxSpecialNumber)
        self.ImgRankSpecial.gameObject:SetActive(rankMyData.MineRankNum <= maxSpecialNumber)

        if rankMyData.MineRankNum <= maxSpecialNumber then
            local icon = self._Control:GetRankSpecialIcon(math.floor(rankMyData.MineRankNum))
            self._RootUi:SetUiSprite(self.ImgRankSpecial, icon)
        else
            self.TxtRankNormal.text = math.floor(rankMyData.MineRankNum)
        end
    else
        self.TxtRankPrecent.gameObject:SetActive(true)
        self.TxtRankNormal.gameObject:SetActive(false)
        self.ImgRankSpecial.gameObject:SetActive(false)
        local text
        if rankMyData.MineRankNum > 0 then
            if not rankMyData.TotalCount or rankMyData.TotalCount == 0 then
                text = XUiHelper.GetText("None")
            else
                local num = math.floor(rankMyData.MineRankNum / rankMyData.TotalCount * 100)
                if num < 1 then
                    num = 1
                end

                text = XUiHelper.GetText("BossSinglePercentDesc", num)
            end
        else
            text = XUiHelper.GetText("None")
        end
        self.TxtRankPrecent.text = text
    end

    local text = XUiHelper.GetText("BossSingleBossRankScore", boosSingleData:GetBossSingleTotalScore())
    local name = XPlayer.Name
    
    self.TxtRankScore.text = text
    self.TxtPlayerName.text = name

    XUiPLayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)

    if rankMyData.HistoryMaxRankNum <= maxCount and rankMyData.HistoryMaxRankNum > 0 then
        self.TxtHighistRank.text = math.floor(rankMyData.HistoryMaxRankNum)
    else
        self.TxtHighistRank.text = XUiHelper.GetText("None")
    end
end

function XUiPanelMyBossRank:SetData(rankMyData)
    self.RankMyData = rankMyData    

    if self:IsNodeShow() then
        self:_Refresh()
    end
end

return XUiPanelMyBossRank