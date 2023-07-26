--新回归邀请活动分享界面的合成图片界面
local XUiNewRegressionForwardScreenShot = XLuaUiManager.Register(XLuaUi, "UiNewRegressionForwardScreenShot")
local DEBUG_SHOW_SHARE_IMAGE = true

function XUiNewRegressionForwardScreenShot:OnDestroy()
    XDataCenter.PhotographManager.ClearTextureCache()
    if self.ShareTexture then
        CS.UnityEngine.Object.Destroy(self.ShareTexture)
    end
end

function XUiNewRegressionForwardScreenShot:OnAwake()
    self.Code = nil
    self.ImgBarCodeDefaultActive = self.ImgBarCode.gameObject.activeSelf
    self.TxtFettersDefaultActive = self.TxtFetters.gameObject.activeSelf
    self.TxtInviteCodeDefaultActive = self.TxtInviteCode.gameObject.activeSelf
    self.TxtFettersDefaultText = self.TxtFetters.text
end

function XUiNewRegressionForwardScreenShot:OnStart(code)
    self.Code = code or ""    --邀请码
    self.TxtInviteCode.text = self.Code

    local desc = XNewRegressionConfigs.GetChildActivityConfig("ForwardDesc")
    self.TxtFettersDesc.text = string.gsub(desc, "\\n", "\n")

    self:PhotographWithOpenUi()
end

function XUiNewRegressionForwardScreenShot:PhotographWithOpenUi()
    self:Photograph(function (photoName, screenShot)
        XLuaUiManager.Open("UiNewRegressionForward", photoName, self.ShareTexture, self.ImagePhoto.sprite)
        local luaUi = XLuaUiManager.GetTopLuaUi("UiNewRegressionForward")
        if luaUi then
            luaUi:ConnectSignal("SDKPanel", "ShareBtnClicked", self.OnShareBtnClicked, self, "isAwait")
        end
    end)
end

function XUiNewRegressionForwardScreenShot:Photograph(callback)
    XCameraHelper.ScreenShotNew(self.ImagePhoto, self.CameraCupture, function(screenShot)
        -- 把合成后的图片渲染到游戏UI中的照片展示(最终要分享的图片)
        CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Hud, CS.XUiManager.Instance.UiCamera)
        self.ShareTexture = screenShot
        local photoName = "[" .. tostring(XPlayer.Id) .. "]" .. XTime.GetServerNowTimestamp()
        if callback then callback(photoName, screenShot) end
    end, function()
        CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Hud, self.CameraCupture)
    end)
end

function XUiNewRegressionForwardScreenShot:OnShareBtnClicked(platformType, sdkPanel)
    -- 根据平台设置相关东西和文字
    local config = XNewRegressionConfigs.GetShareConfig(platformType)
    if config then
        -- 是否保留二维码
        local isKeepQRCode = config.KeepQRCode
        -- 图片文本信息
        local imgPlayerInfo = config.ImagePlayerInfo
        self.ImgBarCode.gameObject:SetActiveEx(isKeepQRCode)
        self.TxtFetters.gameObject:SetActiveEx(imgPlayerInfo ~= nil)
        self.TxtInviteCode.gameObject:SetActiveEx(false)
        if imgPlayerInfo then
            self.TxtFetters.text = CS.XStringEx.Format(imgPlayerInfo, XPlayer.Name, self.Code)
        end
    else
        self.ImgBarCode.gameObject:SetActiveEx(self.ImgBarCodeDefaultActive)
        self.TxtFetters.gameObject:SetActiveEx(self.TxtFettersDefaultActive)
        self.TxtInviteCode.gameObject:SetActiveEx(self.TxtInviteCodeDefaultActive)
        self.TxtFetters.text = self.TxtFettersDefaultText
    end
    -- 重新截图
    self:Photograph(function(photoName, screenShot)
        if DEBUG_SHOW_SHARE_IMAGE then
            sdkPanel.RootUi.ImagePhoto.sprite = self.ImagePhoto.sprite
        end
        sdkPanel.RootUi.PhotoName = photoName
        sdkPanel.RootUi.ShareTexture = screenShot        
        -- 分享
        sdkPanel:EmitSignal("FinishedReadyShare")
    end)
    return true
end

return XUiNewRegressionForwardScreenShot