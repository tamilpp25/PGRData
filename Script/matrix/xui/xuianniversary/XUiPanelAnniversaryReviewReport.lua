local XUiPanelAnniversaryReviewReport=XClass(XUiNode,'XUiPanelAnniversaryReviewReport')

function XUiPanelAnniversaryReviewReport:OnStart()
    self.BtnClose.CallBack=function() 
        self.Parent:Close()
    end
    self.Btnshare.CallBack=function() 
        self.Parent:OpenShare()
    end
    self:Refresh()
end

function XUiPanelAnniversaryReviewReport:Refresh() 
    self.TxtName.text=XDataCenter.ReviewActivityManager.GetName()
    self.TxtId.text=XDataCenter.ReviewActivityManager.GetPlayerId()
    self.TxtSign.text=XPlayer.Sign
    self.TxtSignUp.text=XDataCenter.ReviewActivityManager.GetCreateTime()
    self.TxtSignUpDay.text=XUiHelper.GetText('AnniverReviewSignUpDay',XDataCenter.ReviewActivityManager.GetExistDayCount())
    self.TxtMedalNum.text=XDataCenter.ReviewActivityManager.GetMedalCount()
    self.TxtCollectionNum.text=XDataCenter.ReviewActivityManager.GetScoreTitleCount()
    self.TxtCharacterNum.text=XDataCenter.ReviewActivityManager.GetCharacterCnt()
    self.TxtCharacterLove.text=XUiHelper.GetText('AnniverReviewReportLoveLabel',XDataCenter.ReviewActivityManager.GetMaxTrustName())
    self.TxtCharacterLoveNum.text=XDataCenter.ReviewActivityManager.GetMaxTrustLvCharacterCnt()
    self.TxtDormNum.text=XDataCenter.ReviewActivityManager.GetDormCount()
    self.TxtFurnitureItemNum.text=XDataCenter.ReviewActivityManager.GetFurnitureCount()
    
    --设置头像相关
    local headPortraitInfo = XPlayerManager.GetHeadPortraitInfoById(XPlayer.CurrHeadPortraitId)
    if headPortraitInfo~=nil then
        self.RImgPlayerHead:SetRawImage(headPortraitInfo.ImgSrc)
    end
    local frameInfo=XPlayerManager.GetHeadPortraitInfoById(XPlayer.CurrHeadFrameId)
    if frameInfo~=nil then
        self.RImgIconKuang:SetRawImage(frameInfo.ImgSrc)
    else
        self.RImgIconKuang.gameObject:SetActiveEx(false)
    end
    
end

return XUiPanelAnniversaryReviewReport