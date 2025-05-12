---@class XUiDownloadtips : XLuaUi
local XUiDownloadtips = XLuaUiManager.Register(XLuaUi, "UiDownloadtips")
function XUiDownloadtips:OnAwake()
    self:InitUi()
    self:InitCb()
end 

function XUiDownloadtips:OnStart(title, content, subContent, confirmCallback, jumpCallback, closeCallback)
    self.Title = title
    self.Content = content
    self.SubContent = subContent
    self.ConfirmCb = confirmCallback
    self.JumpCb = jumpCallback
    self.CloseCb = closeCallback
    
    self:InitView()
end 

function XUiDownloadtips:InitUi()
    
end

function XUiDownloadtips:InitView()
    self.TxtTitle.text = self.Title
    self.TxtContent.text = XUiHelper.ReplaceUnicodeSpace(XUiHelper.ReplaceTextNewLine(self.Content))
    
    local showSubContent = not string.IsNilOrEmpty(self.SubContent)
    self.TxtContent2.gameObject:SetActiveEx(showSubContent)
    if showSubContent then
        self.TxtContent2.text = XUiHelper.ReplaceUnicodeSpace(XUiHelper.ReplaceTextNewLine(self.SubContent))
    end
end

function XUiDownloadtips:InitCb()
    self.BtnTanchuangClose.CallBack = function()
        if self.CloseCb then self.CloseCb() end
        self:Close()
    end
    --战斗外才显示按钮
    self.BtnTcanchaungBlack.gameObject:SetActiveEx(CS.XFightInterface.IsOutFight)
    
    self.BtnTcanchaungBlue.CallBack = function() self:OnBtnConfirmClick() end
    self.BtnTcanchaungBlack.CallBack = function() self:OnBtnJumpClick() end
end 

function XUiDownloadtips:OnBtnConfirmClick()
    self:Close()
    if self.ConfirmCb then self.ConfirmCb() end
end 

function XUiDownloadtips:OnBtnJumpClick()
    self:Close()
    if self.JumpCb then self.JumpCb() end
end 