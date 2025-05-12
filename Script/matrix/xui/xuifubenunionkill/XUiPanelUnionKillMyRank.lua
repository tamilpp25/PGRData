local XUiPanelUnionKillMyRank = XClass(nil, "XUiPanelUnionKillMyRank")

function XUiPanelUnionKillMyRank:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
end

function XUiPanelUnionKillMyRank:Refresh(rankType, rankLevel)
    self.RankType = rankType
    self.RankLevel = rankLevel
    self:RefreshMyPraiseRank()
    self:RefreshMyKillRank()
    self.TxtHighistRank.gameObject:SetActiveEx(self.RankType == XFubenUnionKillConfigs.UnionRankType.KillNumber)
end

function XUiPanelUnionKillMyRank:RefreshMyPraiseRank()
    if XFubenUnionKillConfigs.UnionRankType.ThumbsUp == self.RankType then
        local praiseDatas = XDataCenter.FubenUnionKillManager.GetPraiseRankInfos()
        local percent = (praiseDatas.TotalRank == nil or praiseDatas.TotalRank == 0)
        and "0" or tostring(math.ceil(praiseDatas.Rank * 1.0 / praiseDatas.TotalRank * 100))

        if praiseDatas.Rank == 0 then
            self.TxtRankNormal.text = CS.XTextManager.GetText("UnionUnRank")
        elseif praiseDatas.Rank <= 100 then
            self.TxtRankNormal.text = praiseDatas.Rank
        else
            self.TxtRankNormal.text = string.format("%s%%", percent)
        end
        self.TxtRankScore.text = CS.XTextManager.GetText("UnionWhitePraiseNum", praiseDatas.Score)
        self.TxtPlayerName.text = XPlayer.Name
        
        XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)

        self.TxtHighistRank.text = praiseDatas.HistoryRank
    end
end

function XUiPanelUnionKillMyRank:RefreshMyKillRank()
    if XFubenUnionKillConfigs.UnionRankType.KillNumber == self.RankType then
        local myRankLevel
        local unionKillInfo = XDataCenter.FubenUnionKillManager.GetUnionKillInfo()
        if unionKillInfo then
            local sectionId = unionKillInfo.CurSectionId
            local sectionInfo = XDataCenter.FubenUnionKillManager.GetSectionInfoById(sectionId)
            if sectionInfo then
                myRankLevel = sectionInfo.RankLevel
            end
        end
        if not myRankLevel or not self.RankLevel or myRankLevel ~= self.RankLevel then
            self.GameObject:SetActiveEx(false)
            return
        end

        if myRankLevel then
            local rankLevelInfos = XDataCenter.FubenUnionKillManager.GetKillRankInfosByLevel(myRankLevel)
            if rankLevelInfos then
                self.GameObject:SetActiveEx(true)
                local percent = (rankLevelInfos.TotalRank == nil or rankLevelInfos.TotalRank == 0)
                and "0" or tostring(math.ceil(rankLevelInfos.Rank * 1.0 / rankLevelInfos.TotalRank * 100))

                if rankLevelInfos.Rank == 0 then
                    self.TxtRankNormal.text = CS.XTextManager.GetText("UnionUnRank")
                elseif rankLevelInfos.Rank <= 100 then
                    self.TxtRankNormal.text = rankLevelInfos.Rank
                else
                    self.TxtRankNormal.text = string.format("%s%%", percent)
                end
                self.TxtRankScore.text = CS.XTextManager.GetText("UnionWhiteFightPoint", rankLevelInfos.Score)
                self.TxtPlayerName.text = XPlayer.Name
                
                XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
                
                self.TxtHighistRank.text = rankLevelInfos.HistoryRank
            end
        end

    end
end

return XUiPanelUnionKillMyRank