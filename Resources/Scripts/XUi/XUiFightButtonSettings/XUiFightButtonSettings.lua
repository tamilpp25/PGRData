local XUiFightButtonSettings = XLuaUiManager.Register(XLuaUi, "UiFightButtonSettings")

function XUiFightButtonSettings:OnAwake()
    self.CurSelect = 0
    XTool.InitUiObject(self)
    self:InitUI()
end

function XUiFightButtonSettings:OnStart(closeCb)
    self.CloseCb = closeCb
    local t
    if XUiFightButtonDefaultStyleConfig.IsHaveCurSchemeStyle() then
        t = XUiFightButtonDefaultStyleConfig.GetCurSchemeStyle()
    else
        t = XDataCenter.SetManager.GetCurSeleButton()
    end

    if t == 0 then
        self:OnButtonProject1()
    else
        self:OnButtonProject2()
    end
end

function XUiFightButtonSettings:InitUI()
    self:AddListener()
end

function XUiFightButtonSettings:InitFunction()
end

function XUiFightButtonSettings:AddListener()
    -- self.BtnCustomize.CallBack = function() self:OpenCustomFight() end
    self.BtnProject1.CallBack = function() self:OnButtonProject1() end
    self.BtnProject2.CallBack = function() self:OnButtonProject2() end
    self.BtnGouxuan1.CallBack = function(value) self:OnBtnGouxuan1(value) end
    self.BtnGouxuan2.CallBack = function(value) self:OnBtnGouxuan2(value) end
    self.BtnClose.CallBack = function() self:OnBtnClose() end
    self.BtnTongBlue.CallBack = function() self:OnBtnClose() end
end

-- function XUiFightButtonSettings:OpenCustomFight()
-- XLuaUiManager.Open("UiFightCustom",true)
-- end
function XUiFightButtonSettings:OnBtnClose()
    XUiFightButtonDefaultStyleConfig.SaveDefaultStyleById(self.CurSelect)
    XDataCenter.SetManager.SetCurSeleButton(self.CurSelect)
    local uiFightInstance = CS.XFight.Instance
    if uiFightInstance then
        local uiFightNpcPortrait = uiFightInstance.UiFightManager.UiFightNpcPortrait
        if uiFightNpcPortrait then
            uiFightNpcPortrait:OnApplyCustomUi()
        end
        local uiFightOnlineMsg = uiFightInstance.UiFightManager.UiFightOnlineMsg
        if uiFightOnlineMsg then
            uiFightOnlineMsg:OnApplyCustomUi()
        end
    end
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiFightButtonSettings:OnBtnGouxuan1(value)
    self.CurSelect = 0
    self.BtnProject1:SetButtonState(XUiButtonState.Select)
    self.BtnProject2:SetButtonState(XUiButtonState.Normal)
    self.BtnGouxuan2:SetButtonState(XUiButtonState.Normal)
    if value == 0 then
        self:OnBtnGouxuan2()
        self.BtnGouxuan2:SetButtonState(XUiButtonState.Select)
    end
end

function XUiFightButtonSettings:OnBtnGouxuan2(value)
    self.CurSelect = 1
    self.BtnProject1:SetButtonState(XUiButtonState.Normal)
    self.BtnProject2:SetButtonState(XUiButtonState.Select)
    self.BtnGouxuan1:SetButtonState(XUiButtonState.Normal)
    if value == 0 then
        self:OnBtnGouxuan1()
        self.BtnGouxuan1:SetButtonState(XUiButtonState.Select)
    end
end

function XUiFightButtonSettings:OnButtonProject1()
    self.CurSelect = 0
    self.BtnProject1:SetButtonState(XUiButtonState.Select)
    self.BtnProject2:SetButtonState(XUiButtonState.Normal)
    self.BtnGouxuan1:SetButtonState(XUiButtonState.Select)
    self.BtnGouxuan2:SetButtonState(XUiButtonState.Normal)
end

function XUiFightButtonSettings:OnButtonProject2()
    self.CurSelect = 1
    self.BtnProject1:SetButtonState(XUiButtonState.Normal)
    self.BtnProject2:SetButtonState(XUiButtonState.Select)
    self.BtnGouxuan1:SetButtonState(XUiButtonState.Normal)
    self.BtnGouxuan2:SetButtonState(XUiButtonState.Select)
end