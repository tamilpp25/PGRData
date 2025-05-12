---@class XUiBigWorldTeachVisual : XUiNode
---@field VisualImage UnityEngine.UI.RawImage
---@field VisualVideo UnityEngine.RectTransform
---@field VideoBtn XUiComponent.XUiButton
---@field ImagePlay UnityEngine.RectTransform
---@field Video XVideoPlayerUGUI
---@field _Control XBigWorldTeachControl
---@field Parent XUiBigWorldTeachMain
local XUiBigWorldTeachVisual = XClass(XUiNode, "XUiBigWorldTeachVisual")

function XUiBigWorldTeachVisual:OnStart()
    self._TeachContentId = 0
    
    self:_RegisterButtonClicks()
end

function XUiBigWorldTeachVisual:Refresh(teachContentId)
    self._TeachContentId = teachContentId

    if self._Control:CheckTeachContentIsVideo(teachContentId) then
        self:_RefreshVideo()
    else
        self:_RefreshImage()
    end
end

function XUiBigWorldTeachVisual:OnVideoBtnClick()
    
end

function XUiBigWorldTeachVisual:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.VideoBtn.CallBack = Handler(self, self.OnVideoBtnClick)
end

function XUiBigWorldTeachVisual:_RefreshImage()
    self:_ShowImagePanel(true)
    self.VisualImage:SetRawImage(self._Control:GetTeachContentImageByTeachContentId(self._TeachContentId))
end

function XUiBigWorldTeachVisual:_RefreshVideo()
    self:_ShowImagePanel(false)
end

function XUiBigWorldTeachVisual:_ShowImagePanel(isShow)
    self.VisualImage.gameObject:SetActiveEx(isShow)
    self.VisualVideo.gameObject:SetActiveEx(not isShow)
end

return XUiBigWorldTeachVisual
