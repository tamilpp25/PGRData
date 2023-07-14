
local XUiSSBRankingGrid = XClass(nil, "XUiSSBRankingGrid")

function XUiSSBRankingGrid:Ctor(uiPrefab)
    if uiPrefab then self:Init(uiPrefab) end
end

function XUiSSBRankingGrid:Init(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
end

function XUiSSBRankingGrid:Refresh(playerSelf, data, index)
    local ranking
    if not playerSelf then
        ranking = index
        self:RefreshAfterGetRanking(ranking, playerSelf, data)
    else
        ranking = XDataCenter.SuperSmashBrosManager.GetMyRank()
        self:RefreshAfterGetRanking(ranking, playerSelf, data)
    end
end

function XUiSSBRankingGrid:RefreshAfterGetRanking(ranking, playerSelf, data)
    if ranking == 0 then
        self.TxtRankNormal.text = CS.XTextManager.GetText("SSBNoRanking")
        XUiPLayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
        self.TxtPlayerName.text = (not playerSelf and data.Name) or XPlayer.Name
        local mode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(XSuperSmashBrosConfig.ModeType.Survive)
        self.TxtWinCount.text = mode and mode:GetWinCount() or 0
        self.TxtSpendTime.text = XUiHelper.GetTime(mode and mode:GetSpendTime() or 0, XUiHelper.TimeFormatType.DEFAULT)
        self.RImgChara:SetRawImage(nil)
        return
    end
    local icon = XDataCenter.SuperSmashBrosManager.GetRankingSpecialIcon(ranking)
    if icon then self.RootUi:SetUiSprite(self.ImgRankSpecial, icon) end
    self.TxtRankNormal.gameObject:SetActive(icon == nil)
    self.ImgRankSpecial.gameObject:SetActive(icon ~= nil)
    self.TxtRankNormal.text = ranking
    self.TxtPlayerName.text = (not playerSelf and data.Name) or XPlayer.Name
    if playerSelf then
        XUiPLayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
        local mode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(XSuperSmashBrosConfig.ModeType.Survive)
        self.TxtWinCount.text = mode and mode:GetBestStageAttackNum() or 0
        self.TxtSpendTime.text = XUiHelper.GetTime(mode and mode:GetBestTime() or 0, XUiHelper.TimeFormatType.DEFAULT)
        self.RImgChara:SetRawImage(XDataCenter.SuperSmashBrosManager.GetRankingCaptainIcon())
    else
        XUiPLayerHead.InitPortrait(data.Head, data.Frame, self.Head)
        self.TxtWinCount.text = data.WinCount
        self.TxtSpendTime.text = XUiHelper.GetTime(data.SpendTime, XUiHelper.TimeFormatType.DEFAULT)
        local charaInfo = data.CharacterIdList[1]
        if charaInfo.IsRobot then
            local role = XDataCenter.SuperSmashBrosManager.GetRoleById(charaInfo.Id)
            if role then
                self.RImgChara:SetRawImage(role:GetBigHeadIcon())
            else
                self.RImgChara:SetRawImage(nil)
            end
        else
            local headInfo = charaInfo.CharacterHeadInfo
            if headInfo and headInfo.HeadFashionId > 0 then
                self.RImgChara:SetRawImage(XDataCenter.FashionManager.GetFashionBigHeadIcon(headInfo.HeadFashionId, headInfo.HeadFashionType))
            else
                local role = XDataCenter.SuperSmashBrosManager.GetRoleById(charaInfo.Id)
                if role then
                    self.RImgChara:SetRawImage(role:GetBigHeadIcon())
                else
                    self.RImgChara:SetRawImage(nil)
                end
            end
        end
    end
end

return XUiSSBRankingGrid