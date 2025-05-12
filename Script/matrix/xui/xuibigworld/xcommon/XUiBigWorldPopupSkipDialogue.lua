---@class XUiBigWorldPopupSkipDialogue : XBigWorldUi
---@field BtnClose XUiComponent.XUiButton
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field TxtActorName UnityEngine.UI.Text
---@field TxtActorTalk XUiComponent.XUiRichTextCustomRender
---@field BtnContinue XUiComponent.XUiButton
---@field BtnSkip XUiComponent.XUiButton
local XUiBigWorldPopupSkipDialogue = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPopupSkipDialogue")

function XUiBigWorldPopupSkipDialogue:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiBigWorldPopupSkipDialogue:OnStart(content)
    self.TxtActorTalk.text = content or ""
end

function XUiBigWorldPopupSkipDialogue:OnBtnCloseClick()
    self:_NotifyClose(false)
end

function XUiBigWorldPopupSkipDialogue:OnBtnTanchuangCloseClick()
    self:_NotifyClose(false)
end

function XUiBigWorldPopupSkipDialogue:OnBtnContinueClick()
    self:_NotifyClose(false)
end

function XUiBigWorldPopupSkipDialogue:OnBtnSkipClick()
    self:_NotifyClose(true)
end

function XUiBigWorldPopupSkipDialogue:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnClose.CallBack = Handler(self, self.OnBtnCloseClick)
    self.BtnTanchuangClose.CallBack = Handler(self, self.OnBtnTanchuangCloseClick)
    self.BtnContinue.CallBack = Handler(self, self.OnBtnContinueClick)
    self.BtnSkip.CallBack = Handler(self, self.OnBtnSkipClick)
end

function XUiBigWorldPopupSkipDialogue:_NotifyClose(isSkip)
    XMVCA.XBigWorldUI:SendDramaSkipPopupCloseCommand(isSkip)
    self:Close()
end

return XUiBigWorldPopupSkipDialogue
