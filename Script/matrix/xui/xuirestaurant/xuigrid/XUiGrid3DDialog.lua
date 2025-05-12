local XUiGrid3DBase = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DBase")

---@class XUiGrid3DDialog : XUiGrid3DBase
---@field CanvasGroup UnityEngine.CanvasGroup
local XUiGrid3DDialog = XClass(XUiGrid3DBase, "XUiGrid3DDialog")

-- 缓动动画时间
local TweenDuration = 0.2

function XUiGrid3DDialog:InitUi()
    self._BubbleDuration = self._Control:GetBubbleProperty() * XScheduleManager.SECOND
    self._OnHideCb = function()
        XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_HIDE_3D_DIALOG, self.Id)
    end
    
    self._OnShowCb = function()
        self:StopHideTimer()
        self.HideTimer = XScheduleManager.ScheduleOnce(function()
            self:TryTweenHide()
        end, self._BubbleDuration)
    end
end

function XUiGrid3DDialog:OnRefresh(id, content, emoji)
    self.Id = id
    self:TweenShow()
    self.PanelText.gameObject:SetActiveEx(false)
    self.PanelEmoji.gameObject:SetActiveEx(false)
    if content then
        self.TxtDesc.text = content
        self.PanelText.gameObject:SetActiveEx(true)
    end

    if emoji then
        self.RImgEmoji:SetRawIamge(emoji)
        self.PanelEmoji.gameObject:SetActiveEx(true)
    end
end

function XUiGrid3DDialog:Hide()
    self:StopHideTimer()
    XUiGrid3DBase.Hide(self)
    self.CanvasGroup.alpha = 0
    self.Target = nil
end
function XUiGrid3DDialog:TweenShow()
    self.CanvasGroup:DOFade(1, TweenDuration):OnComplete(self._OnShowCb)
end

function XUiGrid3DDialog:TryTweenHide()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    if XTool.UObjIsNil(self.CanvasGroup) then
        return
    end

    self.CanvasGroup:DOFade(0, TweenDuration):OnComplete(self._OnHideCb)
end

function XUiGrid3DDialog:StopHideTimer()
    if not self.HideTimer then
        return
    end
    XScheduleManager.UnSchedule(self.HideTimer)
    self.HideTimer = nil
end

return XUiGrid3DDialog