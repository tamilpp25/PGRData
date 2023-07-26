
---@class XUiDormNotification : XLuaUi
local XUiDormNotification = XLuaUiManager.Register(XLuaUi, "UiDormNotification")

function XUiDormNotification:OnAwake()
    self:InitCb()
    self.IgnoreClose = false
end

function XUiDormNotification:OnStart(title, content, positiveCb, negativeCb, positiveTxt, negativeTxt, ignoreClose)
    if title then
        self.TxtTitle.text = title
    end

    if content then
        self.TxtContent.text = XUiHelper.ReplaceTextNewLine(content)
    end
    
    self.PositiveCb = positiveCb
    self.NegativeCb = negativeCb

    if positiveTxt then
        self.BtnPositive:SetNameByGroup(0, positiveTxt)
    end

    if negativeTxt then
        self.BtnNegative:SetNameByGroup(0, negativeTxt)
    end

    self.IgnoreClose = ignoreClose
end

function XUiDormNotification:InitCb()
    self.BtnClose.CallBack = function() 
        self:Close()
    end
    
    self.BtnTanchuangClose.CallBack = function() 
        self:Close()
    end
    
    self.BtnPositive.CallBack = function()
        if self.IgnoreClose then
            if self.PositiveCb then self.PositiveCb() end
            return
        end
        self:Close()
        if self.PositiveCb then self.PositiveCb() end
    end
    
    self.BtnNegative.CallBack = function()
        self:Close()
        if self.NegativeCb then self.NegativeCb() end
    end
end  