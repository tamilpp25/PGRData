
local XUiSSBRankingGrid = XClass(nil, "XUiSSBRankingGrid")

function XUiSSBRankingGrid:Ctor(uiPrefab)
    self._Career = 1
    if uiPrefab then self:Init(uiPrefab) end
end

function XUiSSBRankingGrid:Init(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
end

function XUiSSBRankingGrid:Refresh(playerSelf, data, index, career)
    self._Career = career
    local ranking = index
    if not playerSelf then
        self:RefreshAfterGetRanking(ranking, playerSelf, data)
    else
        self:RefreshAfterGetRanking(ranking, playerSelf, data)
    end
end

function XUiSSBRankingGrid:RefreshAfterGetRanking(ranking, playerSelf, data)
    if ranking == 0 then
        if playerSelf then
            self.TxtRankNormal.text = CS.XTextManager.GetText("SSBNoRanking")
            XUiPLayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
            if data then
                self.TxtWinCount.text = data.WinCount
                self.TxtSpendTime.text = XUiHelper.GetTime(data.SpendTime, XUiHelper.TimeFormatType.DEFAULT)
            else
                self.TxtWinCount.text = 0
                self.TxtSpendTime.text = XUiHelper.GetTime(0, XUiHelper.TimeFormatType.DEFAULT)
            end

            local captainIcon = XDataCenter.SuperSmashBrosManager.GetRankingCaptainIcon(self._Career)
            if captainIcon then
                self.RImgChara:SetRawImage(captainIcon)
                self.RImgChara.gameObject:SetActive(true)
            else
                self.RImgChara.gameObject:SetActive(false)
            end
        else
            self.TxtRankNormal.text = CS.XTextManager.GetText("SSBNoRanking")
            XUiPLayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
            self.TxtPlayerName.text = (not playerSelf and data.Name) or XPlayer.Name
            --local mode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(XSuperSmashBrosConfig.ModeType.Survive)
            self.TxtWinCount.text = 0
            self.TxtSpendTime.text = XUiHelper.GetTime(0, XUiHelper.TimeFormatType.DEFAULT)
            self.RImgChara.gameObject:SetActive(false)
        end
        
        return
    end
    self.RImgChara.gameObject:SetActive(true)
    local icon = XDataCenter.SuperSmashBrosManager.GetRankingSpecialIcon(ranking)
    if icon then self.RootUi:SetUiSprite(self.ImgRankSpecial, icon) end
    self.TxtRankNormal.gameObject:SetActive(icon == nil)
    self.ImgRankSpecial.gameObject:SetActive(icon ~= nil)
    self.TxtRankNormal.text = ranking
    self.TxtPlayerName.text = (not playerSelf and data.Name) or XPlayer.Name
    if playerSelf then
        XUiPLayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
        if data then
            self.TxtWinCount.text = data.WinCount
            self.TxtSpendTime.text = XUiHelper.GetTime(data.SpendTime, XUiHelper.TimeFormatType.DEFAULT)
        else
            self.TxtWinCount.text = 0
            self.TxtSpendTime.text = XUiHelper.GetTime(0, XUiHelper.TimeFormatType.DEFAULT)
        end
        
        local captainIcon = XDataCenter.SuperSmashBrosManager.GetRankingCaptainIcon(self._Career)
        if captainIcon then
            self.RImgChara:SetRawImage(captainIcon)
        else
            self.RImgChara.gameObject:SetActive(false)
        end
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
                self.RImgChara.gameObject:SetActive(false)
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
                    self.RImgChara.gameObject:SetActive(false)
                end
            end
        end
    end
end

return XUiSSBRankingGrid