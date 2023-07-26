
local XUiReviewActivityBtnShare = XClass(nil, "XUiReviewActivityBtnShare")

function XUiReviewActivityBtnShare:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:Init()
end

function XUiReviewActivityBtnShare:Init()
    local itemId, itemCount = self:GetRewardItemId()
    if itemId and itemId > 0 then
        self.GameObject:SetActiveEx(true)
        self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId)
        if self.GoodsShowParams.Icon and self.RImgShareRewardIcon then
            self.RImgShareRewardIcon:SetRawImage(self.GoodsShowParams.Icon)
        end
        if self.BtnShare then
            XUiHelper.RegisterClickEvent(self, self.BtnShare, function() self:OnClickBtnShare() end)
        end
        if itemCount and itemCount > 0 and self.TxtShareRewardNum then
            self.TxtShareRewardNum.text = itemCount
        else
            self.TxtShareRewardNum.text = 0
        end
    else
        self.GameObject:SetActiveEx(false)
    end
    if self.TxtUserName then
        self.TxtUserName.text = XPlayer.Name        
    end
end

function XUiReviewActivityBtnShare:GetRewardItemId()
    local rewardId = XDataCenter.ReviewActivityManager.GetShareRewardId()
    if rewardId and rewardId > 0 then
        local rewards = XRewardManager.GetRewardList(rewardId)
        if rewards then
            for _, v in pairs(rewards) do
                return v.TemplateId or v.Id, v.Count
            end
        end
    end
    return 0
end

function XUiReviewActivityBtnShare:OnClickBtnShare()
    XCameraHelper.ScreenShotNew(self.ImgPicture, CS.XUiManager.Instance.UiCamera, function(screenShot)
            -- 把合成后的图片渲染到游戏UI中的照片展示(最终要分享的图片)
            --CsXUiManager.Instance:ChangeCanvasTypeCamera(CS.XUiType.Hud, CS.XUiManager.Instance.UiCamera)
            self.ShareTexture = screenShot
            local photoName = "[" .. tostring(XPlayer.Id) .. "]" .. XTime.GetServerNowTimestamp()
            self:ShowShareLogo(false)
            XLuaUiManager.Open("UiReviewActivityShare", photoName, self.ShareTexture, self.ImgPicture.sprite)
            XDataCenter.ReviewActivityManager.GetShareReward()
        end, function()
            self:ShowShareLogo(true)
        end)
    --[[XLuaUiManager.Open("UiReviewActivityScreenShot", function(shareSuccess)
            self:OnShareClose()
        end)]]
end

function XUiReviewActivityBtnShare:ShowShareLogo(value)
    self.BtnShare.gameObject:SetActiveEx(not value)
    if self.PanelText then
        self.PanelText.gameObject:SetActiveEx(not value)
    end
    if self.LogoRoot then
        self.LogoRoot.gameObject:SetActiveEx(true)
    end
    if self.PanelName then
        self.PanelName.gameObject:SetActiveEx(false)
    end
    if self.BtnTanchuangClose then
        self.BtnTanchuangClose.gameObject:SetActiveEx(not value)
    end
end

function XUiReviewActivityBtnShare:OnShareClose(shareSuccess)
    if shareSuccess then
        XDataCenter.ReviewActivityManager.GetShareReward()
    end
end

function XUiReviewActivityBtnShare:OnShow()

end

function XUiReviewActivityBtnShare:OnDestroy()
    XDataCenter.PhotographManager.ClearTextureCache()
    if self.ShareTexture then
        CS.UnityEngine.Object.Destroy(self.ShareTexture)
    end
end

return XUiReviewActivityBtnShare