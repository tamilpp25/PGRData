---@class UiReCallActivityShare : XLuaUi
---@field _Control XReCallActivityControl
local XUiReCallActivityShare = XLuaUiManager.Register(XLuaUi, "UiReCallActivityShare")
local XUiPhotographCapturePanel = require("XUi/XUiPhotograph/XUiPhotographCapturePanel")
local XUiPhotographSDKPanel = require("XUi/XUiPhotograph/XUiPhotographSDKPanel")

function XUiReCallActivityShare:OnAwake()
    self:InitUiAfterAuto()
end

function XUiReCallActivityShare:OnStart()
    self:SetPlayerInfo()
    self.channelId = CS.XHeroSdkAgent.GetChannelId()
    self.channelId = self.channelId > 0 and self.channelId or 1
    self.config = self._Control:GetRegressionChannelConfigById(self.channelId)
    self:SetPlatformShow()
    self:ChangeState(XPhotographConfigs.PhotographViewState.Normal)
    self.bgList = self.config.InvitationBg
    self.bgIndex = 1
    self:RefreshBg()
end

function XUiReCallActivityShare:SetPlayerInfo(RecallPhotoPanel)
    self.NameTxt.text = XPlayer.Name
    local code = self._Control:PlayIdToHexUpper()
    self.CodeTxt.text = CS.XTextManager.GetText("HoldRegressionInviteCode", code)
    if RecallPhotoPanel then
        RecallPhotoPanel.ShareCodeTxt.text = CS.XTextManager.GetText("HoldRegressionInviteCode", code)
        RecallPhotoPanel.ShareNameTxt.text = XPlayer.Name
    end
    --设置头像相关
    local headPortraitInfo = XPlayerManager.GetHeadPortraitInfoById(XPlayer.CurrHeadPortraitId)
    if headPortraitInfo ~= nil then
        self.RImgPlayerHead:SetRawImage(headPortraitInfo.ImgSrc)
        if RecallPhotoPanel then
            RecallPhotoPanel.SharePlayerHead:SetRawImage(headPortraitInfo.ImgSrc)
        end
    end
end

--等SDK回调完成分享打点
function XUiReCallActivityShare:OnShareSuccess(photoName)
    if self.PhotoName == photoName then
        --完成分享埋点
        self:ReCallRecord(2)
    end
end

function XUiReCallActivityShare:OnDestroy()
    XDataCenter.PhotographManager.ClearTextureCache()
    CS.UnityEngine.Object.Destroy(self.ShareTexture)
    XEventManager.RemoveEventListener(XEventId.EVENT_PHOTO_SHARE_SUCCESS, self.OnShareSuccessCb)
end

function XUiReCallActivityShare:InitUiAfterAuto()
    self.CapturePanel = XUiPhotographCapturePanel.New(self, self.PanelCapture)
    self.SDKPanel = XUiPhotographSDKPanel.New(self, self.PanelSDK)

    self.OnShareSuccessCb = handler(self, self.OnShareSuccess)
    XEventManager.AddEventListener(XEventId.EVENT_PHOTO_SHARE_SUCCESS, self.OnShareSuccessCb)

    self.BtnClose.CallBack = function()
        self:OnClose()
    end
    self.BtnShare.CallBack = function()
        self:Photograph()
    end
    self.BtnLeft.CallBack = function()
        self:OnLeftClick()
    end
    self.BtnRight.CallBack = function()
        self:OnRightClick()
    end
end

function XUiReCallActivityShare:Photograph()
    local refreshFun = function(RecallPhotoPanel)
        --设置分享模版图
        local bgPath = self.bgList[self.bgIndex]
        RecallPhotoPanel.ImgPicture:SetRawImage(bgPath)
        self:SetPlayerInfo(RecallPhotoPanel)
        self:SetUiSprite(RecallPhotoPanel.QRcode, self.config.QRCodeIcon)
        RecallPhotoPanel.QRcode.gameObject:SetActiveEx(self.isKeepQRCode)
    end
    local RecallPhotoPanelPath = CS.XGame.ClientConfig:GetString("RecallPhotoPanelPath")
    XCameraHelper.PhotographWithFixedRatio(self.CapturePanel.ImagePhoto, function(shot)
        -- 把合成后的图片渲染到游戏UI中的照片展示(最终要分享的图片)
        self.ShareTexture = shot
        self.PhotoName = "[" .. tostring(XPlayer.Id) .. "]" .. XTime.GetServerNowTimestamp()
        self:PlayAnimation("Shanguang")
        self:PlayAnimation("Photo", function()
            self.CapturePanel.BtnClose.gameObject:SetActiveEx(true)
        end, function()
            self:ChangeState(XPhotographConfigs.PhotographViewState.SDK)
            self.CapturePanel.BtnClose.gameObject:SetActiveEx(false)
        end)
    end, nil, RecallPhotoPanelPath, refreshFun, self)
    --生成分享图埋点
    self:ReCallRecord(1)
end

--埋点
function XUiReCallActivityShare:ReCallRecord(share_type)
    local dict = {}
    dict.share_type = share_type
    dict.invitation_code = self._Control:PlayIdToHexUpper()
    dict.invitation_user_id = XPlayer.Id
    CS.XRecord.Record(dict, "900008", "returnActivity2024")
end

function XUiReCallActivityShare:GetPlatformType2CustomText(platformType)
    local config = self._Control:GetRegressionPlatformConfigById(platformType)
    if config == nil then
        return nil
    end
    local platformTextContent = ""
    if config.Text then
        platformTextContent = config.Text
    end
    --获得分享奖励
    if not self._Control:GetIsGetShareReward() and self._Control:GetCurInviteInTime() then
        self._Control:ShareRewardRequest()
    end
    return platformTextContent
end

function XUiReCallActivityShare:ChangeState(state)
    if state == XPhotographConfigs.PhotographViewState.Normal then
        self.NormalPanel.gameObject:SetActiveEx(true)
        self.CapturePanel:Hide()
        self.SDKPanel:Hide()
        self.BtnShare.gameObject:SetActiveEx(true)
    elseif state == XPhotographConfigs.PhotographViewState.Capture then
        self.NormalPanel.gameObject:SetActiveEx(false)
        self.CapturePanel:Show()
        self.SDKPanel:Hide()
    elseif state == XPhotographConfigs.PhotographViewState.SDK then
        self.NormalPanel.gameObject:SetActiveEx(false)
        self.CapturePanel:Show()
        self.SDKPanel:Show()
    end
end

function XUiReCallActivityShare:SetPlatformShow()
    if self.config then
        -- 是否保留二维码
        self.isKeepQRCode = self.config.InvitationQRCode
        local ignoreChannel = self._Control:GetIgnoreChannelIds()
        if ignoreChannel[self.channelId] then
            self.isKeepQRCode = false
        end
        -- 是否保留邀请码
        local isKeepInviteCode = self.config.InvitationCode
        self.CodeTxt.gameObject:SetActiveEx(isKeepInviteCode)
    end
end

function XUiReCallActivityShare:OnClose()
    self:Close()
end

function XUiReCallActivityShare:OnLeftClick()
    self.bgIndex = self.bgIndex - 1
    self.bgIndex = self.bgIndex > 0 and self.bgIndex or #self.bgList
    self:RefreshBg(true)
end

function XUiReCallActivityShare:OnRightClick()
    self.bgIndex = self.bgIndex + 1
    self.bgIndex = self.bgIndex <= #self.bgList and self.bgIndex or 1
    self:RefreshBg(true)
end

function XUiReCallActivityShare:RefreshBg(playAnimation)
    local bgPath = self.bgList[self.bgIndex]
    self.Bg:SetRawImage(bgPath)
    if playAnimation then
        self:PlayAnimation("PhotoSwitch")
    end
end

function XUiReCallActivityShare:OnBtnSaveCallBack()
    --获得分享奖励
    if not self._Control:GetIsGetShareReward() and self._Control:GetCurInviteInTime() then
        self._Control:ShareRewardRequest()
    end
end