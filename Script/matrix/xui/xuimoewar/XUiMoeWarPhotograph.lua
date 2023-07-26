local XUiMoeWarPhotograph = XLuaUiManager.Register(XLuaUi,"UiMoeWarPhotograph")
local XUiPhotographSDKPanel = require("XUi/XUiPhotograph/XUiPhotographSDKPanel")

function XUiMoeWarPhotograph:OnStart(playerId)
    self.PlayerId = playerId
    self.SDKPanel = XUiPhotographSDKPanel.New(self, self.PanelSDK)
    local playerEntity = XDataCenter.MoeWarManager.GetPlayer(self.PlayerId)
    self.RImgRoleIcon:SetRawImage(playerEntity:GetShareImage())
    self.TxtUserName.text = XPlayer.Name
    self:Photograph()
    self:RegisterButtonEvent()
end

function XUiMoeWarPhotograph:OnDestroy()
	XDataCenter.PhotographManager.ClearTextureCache()
	CS.UnityEngine.Object.Destroy(self.ShareTexture)	
end

function XUiMoeWarPhotograph:RegisterButtonEvent()
    self.BtnClose.CallBack = function() self:Close() end
end

function XUiMoeWarPhotograph:ChangeState(state)
    if state == XPhotographConfigs.PhotographViewState.Normal then
        self.SDKPanel:Hide()
    elseif state == XPhotographConfigs.PhotographViewState.Capture then
        self.SDKPanel:Hide()
    elseif state == XPhotographConfigs.PhotographViewState.SDK then
        self.SDKPanel:Show()
    end
end

function XUiMoeWarPhotograph:Photograph()
	self:PlayAnimation("Photo")
    XCameraHelper.ScreenShotNew(self.ImagePhoto, self.CameraCupture, function(screenShot)
        -- 把合成后的图片渲染到游戏UI中的照片展示(最终要分享的图片)
        CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, CS.XUiManager.Instance.UiCamera)
        self.ShareTexture = screenShot
        self.PhotoName = "[" .. tostring(XPlayer.Id) .. "]" .. XTime.GetServerNowTimestamp()
    end, function()
        CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, self.CameraCupture)
    end)
    XDataCenter.MoeWarManager.RequestShare(self.PlayerId)
end

return XUiMoeWarPhotograph