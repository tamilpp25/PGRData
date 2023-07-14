local XUiPhotographSDKPanel = require("XUi/XUiPhotograph/XUiPhotographSDKPanel")
local XUiReviewActivityShare = XLuaUiManager.Register(XLuaUi, "UiReviewActivityShare")
local CsXUiManager = CS.XUiManager
function XUiReviewActivityShare:OnAwake()
    self.SDKPanel = XUiPhotographSDKPanel.New(self, self.PanelSDK)
    self:RegisterButtonEvent()
end

function XUiReviewActivityShare:OnStart(photoName, shareTexture, sprite, onCloseCb)
    self.PhotoName = photoName
    self.ShareTexture = shareTexture
    self.ImagePhoto.sprite = sprite
    self.OnCloseCb = onCloseCb
    XEventManager.AddEventListener(XEventId.EVENT_PHOTO_SHARE_SUCCESS, function(photoName) self:OnShareSuccess(photoName) end)
end

function XUiReviewActivityShare:RegisterButtonEvent()
    self.BtnClose.CallBack = function() self:Close() end
end

function XUiReviewActivityShare:OnShareSuccess(photoName)
    if self.PhotoName == photoName then
        self.ShareSuccess = true
    end
end

function XUiReviewActivityShare:OnDisable()  
    if self.OnCloseCb then
        local cb = self.OnCloseCb
        self.OnCloseCb = nil
        cb(self.ShareSuccess)
    end
end

function XUiReviewActivityShare:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_PHOTO_SHARE_SUCCESS, function(photoName) self:OnShareSuccess(photoName) end)
    --XLuaUiManager.Remove("UiNewRegressionForwardScreenShot")
    if self.OnCloseCb then
        local cb = self.OnCloseCb
        self.OnCloseCb = nil
        cb(self.ShareSuccess)
    end
end