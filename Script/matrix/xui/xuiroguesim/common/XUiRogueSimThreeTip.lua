---@class XUiRogueSimThreeTip : XLuaUi
---@field private _Control XRogueSimControl
---@field BtnSkip XUiComponent.XUiButton
local XUiRogueSimThreeTip = XLuaUiManager.Register(XLuaUi, "UiRogueSimThreeTip")

function XUiRogueSimThreeTip:OnAwake()
    self:RegisterUiEvents()
end

function XUiRogueSimThreeTip:OnStart(title, content, closeCallback, sureCallback, jumpCallBack, skipCallBack, data)
    -- 额外参数
    local sureText, jumpText
    local isShowJump = false
    local isShowSkip = false
    if data then
        sureText = data.SureText
        jumpText = data.JumpText
        isShowJump = data.IsShowJump
        isShowSkip = data.IsShowSkip
    end
    if sureText then
        self.BtnOK:SetNameByGroup(0, sureText)
    end
    if isShowJump then
        self.BtnGo.gameObject:SetActiveEx(true)
        self.BtnNo.gameObject:SetActiveEx(false)
        if jumpText then
            self.BtnGo:SetNameByGroup(0, jumpText)
        end
    else
        self.BtnGo.gameObject:SetActiveEx(false)
        self.BtnNo.gameObject:SetActiveEx(true)
    end
    -- 本次登陆不再提示
    self.BtnSkip.gameObject:SetActiveEx(isShowSkip)
    -- 标题
    if title then
        self.TxtTitle.text = title
    end
    -- 内容
    if content then
        self.TxtContent.text = XUiHelper.ReplaceTextNewLine(content)
    end
    self.CloseCallBack = closeCallback
    self.SureCallBack = sureCallback
    self.JumpCallBack = jumpCallBack
    self.SkipCallBack = skipCallBack
end

function XUiRogueSimThreeTip:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnOK, self.OnBtnOKClick)
    XUiHelper.RegisterClickEvent(self, self.BtnNo, self.OnBtnNoClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGo, self.OnBtnGoClick)
end

function XUiRogueSimThreeTip:OnBtnCloseClick()
    XLuaUiManager.CloseWithCallback(self.Name, self.CloseCallBack)
end

function XUiRogueSimThreeTip:OnBtnOKClick()
    local isSkip = self.BtnSkip:GetToggleState()
    if self.SkipCallBack then
        self.SkipCallBack(isSkip)
    end
    XLuaUiManager.CloseWithCallback(self.Name, self.SureCallBack)
end

function XUiRogueSimThreeTip:OnBtnNoClick()
    XLuaUiManager.CloseWithCallback(self.Name, self.CloseCallBack)
end

function XUiRogueSimThreeTip:OnBtnGoClick()
    XLuaUiManager.CloseWithCallback(self.Name, self.JumpCallBack)
end

return XUiRogueSimThreeTip
