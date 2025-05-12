local XUiPhotographSDKPanel = require("XUi/XUiPhotograph/XUiPhotographSDKPanel")

--新回归邀请活动分享界面
local XUiNewRegressionForward = XLuaUiManager.Register(XLuaUi, "UiNewRegressionForward")

function XUiNewRegressionForward:OnAwake()
    self.InviteManager = XDataCenter.NewRegressionManager.GetInviteManager()
    self.SDKPanel = XUiPhotographSDKPanel.New(self, self.PanelSDK)
    self:RegisterButtonEvent()
end

function XUiNewRegressionForward:OnDestroy()
    XLuaUiManager.Remove("UiNewRegressionForwardScreenShot")
end

function XUiNewRegressionForward:OnStart(photoName, shareTexture, sprite)
    self.PhotoName = photoName
    self.ShareTexture = shareTexture
    self.ImagePhoto.sprite = sprite
    local showCopyButton = self.InviteManager:GetIsShowCopyButton()
    self.SDKPanel.GameObject:SetActiveEx(not showCopyButton)
    self.PanelSDKTemp.gameObject:SetActiveEx(showCopyButton)
end

function XUiNewRegressionForward:RegisterButtonEvent()
    self.BtnClose.CallBack = function() self:Close() end
    XUiHelper.RegisterClickEvent(self, self.BtnCopy, self.OnBtnCopyClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnSave, self.OnBtnSaveClicked)
end

function XUiNewRegressionForward:OnBtnCopyClicked()
    local text = self:GetPlatformType2CustomText(0)
    if text == nil then
        text = XNewRegressionConfigs.GetChildActivityConfig("DefaultCopyText")
    end
    XTool.CopyToClipboard(text)
end

function XUiNewRegressionForward:OnBtnSaveClicked()
    XDataCenter.PhotographManager.SharePhoto(self.PhotoName, self.ShareTexture, XPlatformShareConfigs.PlatformType.Local)
end

function XUiNewRegressionForward:GetPlatformType2CustomText(platformType)
    local config = XNewRegressionConfigs.GetShareConfig(platformType)
    if config == nil then return nil end
    local platformTextContent = ""
    local shareLink = self.InviteManager:GetShareLink()
    if config.TextPlayerInfo then
        platformTextContent = CS.XStringEx.Format(config.TextPlayerInfo, XPlayer.Name, self.InviteManager:GetCode())
    end
    if config.TextContent then
        platformTextContent = platformTextContent .. config.TextContent
    end
    if config.KeepLink and shareLink then
        platformTextContent = platformTextContent .. shareLink
    end
    return platformTextContent
end

return XUiNewRegressionForward