local XUiPhotographSDKPanel = require("XUi/XUiPhotograph/XUiPhotographSDKPanel")
local XUiPhotographCapturePanel = require("XUi/XUiPhotograph/XUiPhotographCapturePanel")

---@class XUiTemple2Share : XLuaUi
---@field _Control XTemple2Control
local XUiTemple2Share = XLuaUiManager.Register(XLuaUi, "UiTemple2Share")

function XUiTemple2Share:OnAwake()
    self:RegisterClickEvent(self.BtnClickEmpty, self.Close)
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnShare, self.OnClickShare)

    ---@type XUiPhotographCapturePanel
    self.CapturePanel = XUiPhotographCapturePanel.New(self, self.PanelCapture)
    ---@type XUiPhotographSDKPanel
    self.SDKPanel = XUiPhotographSDKPanel.New(self, self.PanelSDK)
end

function XUiTemple2Share:OnEnable()
    --XEventManager.AddEventListener(XEventId.EVENT_PHOTO_SHARE, self._OnShare, self)
end

function XUiTemple2Share:OnDisable()
    --XEventManager.RemoveEventListener(XEventId.EVENT_PHOTO_SHARE, self._OnShare, self)
end

---@param texture UnityEngine.Texture2D
function XUiTemple2Share:OnStart(photoName, texture, sprite)
    self.PhotoName = photoName
    self.ShareTexture = texture
    ---@type UnityEngine.RectTransform
    --local transform = self.CapturePanel.ImagePhoto.transform
    --local rect = transform.rect
    --local sprite = CS.XTool.GetSprite(texture, texture.width, texture.height)
    self.CapturePanel.ImagePhoto.sprite = sprite
    self.CapturePanel:Show()
end

function XUiTemple2Share:ChangeState()
end

return XUiTemple2Share