local XUiGrid3DBase = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DBase")

---@class XUiGrid3DDialog : XUiGrid3DBase
---@field CanvasGroup UnityEngine.CanvasGroup
local XUiGrid3DDialog = XClass(XUiGrid3DBase, "XUiGrid3DDialog")

-- 缓动动画时间
local TweenDuration = 0.2

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
    self.CanvasGroup.alpha = 0
    self.Super.Hide(self)
    self.Target = nil
end

function XUiGrid3DDialog:TweenShow()
    self.CanvasGroup:DOFade(1, TweenDuration)
end

return XUiGrid3DDialog