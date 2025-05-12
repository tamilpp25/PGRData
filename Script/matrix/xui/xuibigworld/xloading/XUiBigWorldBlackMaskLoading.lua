
---@class XUiBigWorldBlackMaskLoading : XBigWorldUi
local XUiBigWorldBlackMaskLoading = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldBlackMaskLoading")

function XUiBigWorldBlackMaskLoading:OnAwake()
    if not self.DarkEnable then
        self.DarkEnable = self.Transform:Find("FullScreenBackground/UiBigWorldDark/Animation/DarkEnable")
    end
    if not self.DarkDisable then
        self.DarkDisable = self.Transform:Find("FullScreenBackground/UiBigWorldDark/Animation/DarkDisable")
    end
end

function XUiBigWorldBlackMaskLoading:OnStart(enableFinishCb, disableFinishCb)
    self._EnableFinishCb = enableFinishCb
    self._DisableFinishCb = disableFinishCb
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BLACK_MASK_LOADING_CLOSE, self.OnFadeOut, self)
end

function XUiBigWorldBlackMaskLoading:OnDestroy()
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BLACK_MASK_LOADING_CLOSE, self.OnFadeOut, self)
end

function XUiBigWorldBlackMaskLoading:OnEnable()
    self.DarkEnable:PlayTimelineAnimation(self._EnableFinishCb)
end

function XUiBigWorldBlackMaskLoading:OnFadeOut()
    self.DarkDisable:PlayTimelineAnimation(function() 
        self:Close()
        if self._DisableFinishCb then
            self._DisableFinishCb()
        end
    end)
end

return XUiBigWorldBlackMaskLoading
