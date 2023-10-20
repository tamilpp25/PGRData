---@class XUiRogueSimThreeTip : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimThreeTip = XLuaUiManager.Register(XLuaUi, "UiRogueSimThreeTip")

function XUiRogueSimThreeTip:OnAwake()
    self:RegisterUiEvents()
end

function XUiRogueSimThreeTip:OnStart(title, content, closeCallback, sureCallback, jumpCallBack, data)
    -- 额外参数
    local sureText, jumpText
    local isShowJump = false
    if data then
        sureText = data.SureText
        jumpText = data.JumpText
        isShowJump = data.IsShowJump
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
end

-- 置空回调
function XUiRogueSimThreeTip:ClearCallBack()
    self.CloseCallBack = nil
    self.SureCallBack = nil
    self.JumpCallBack = nil
end

function XUiRogueSimThreeTip:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnOK, self.OnBtnOKClick)
    XUiHelper.RegisterClickEvent(self, self.BtnNo, self.OnBtnNoClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGo, self.OnBtnGoClick)
end

function XUiRogueSimThreeTip:OnBtnCloseClick()
    self:Close()
    if self.CloseCallBack then
        self.CloseCallBack()
    end
    self:ClearCallBack()
end

function XUiRogueSimThreeTip:OnBtnOKClick()
    self:Close()
    if self.SureCallBack then
        self.SureCallBack()
    end
    self:ClearCallBack()
end

function XUiRogueSimThreeTip:OnBtnNoClick()
    self:Close()
    if self.CloseCallBack then
        self.CloseCallBack()
    end
    self:ClearCallBack()
end

function XUiRogueSimThreeTip:OnBtnGoClick()
    self:Close()
    if self.JumpCallBack then
        self.JumpCallBack()
    end
    self:ClearCallBack()
end

return XUiRogueSimThreeTip
