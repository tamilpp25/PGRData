local XUiFightButtonSettings = XLuaUiManager.Register(XLuaUi, "UiFightButtonSettings")


function XUiFightButtonSettings:OnAwake()
    self.CurrentBtnProj1 = nil
    self.CurrentBtnProj2 = nil
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

    self.BtnProject1PC.CallBack = function() self:OnButtonProject1() end
    self.BtnProject2PC.CallBack = function() self:OnButtonProject2() end

    self:RefreshBtnPoint()

    self.BtnGouxuan1.CallBack = function(value) self:OnBtnGouxuan1(value) end
    self.BtnGouxuan2.CallBack = function(value) self:OnBtnGouxuan2(value) end
    self.BtnClose.CallBack = function() self:OnBtnClose() end
    self.BtnTongBlue.CallBack = function() self:OnBtnClose() end
end

function XUiFightButtonSettings:OnEnable()
    CS.XPc.XCursorHelper.ForceResponse = true;
end

function XUiFightButtonSettings:OnDisable()
    CS.XPc.XCursorHelper.ForceResponse = false;
end

function XUiFightButtonSettings:RefreshBtnPoint()
    if XDataCenter.UiPcManager.IsPc() then
        self.BtnProject1.gameObject:SetActiveEx(false)
        self.BtnProject2.gameObject:SetActiveEx(false)
        self.BtnProject1PC.gameObject:SetActiveEx(true)
        self.BtnProject2PC.gameObject:SetActiveEx(true)
        self.CurrentBtnProj1 = self.BtnProject1PC
        self.CurrentBtnProj2 = self.BtnProject2PC
    else
        self.BtnProject1.gameObject:SetActiveEx(true)
        self.BtnProject2.gameObject:SetActiveEx(true)
        self.BtnProject1PC.gameObject:SetActiveEx(false)
        self.BtnProject2PC.gameObject:SetActiveEx(false)
        self.CurrentBtnProj1 = self.BtnProject1
        self.CurrentBtnProj2 = self.BtnProject2
    end
end

-- function XUiFightButtonSettings:OpenCustomFight()
-- XLuaUiManager.Open("UiFightCustom",true)
-- end
function XUiFightButtonSettings:OnBtnClose()
    XUiFightButtonDefaultStyleConfig.SaveDefaultStyleById(self.CurSelect)
    XDataCenter.SetManager.SetCurSeleButton(self.CurSelect)

    CsXGameEventManager.Instance:Notify(CS.XEventId.EVENT_CUSTOM_UI_SCHEME_CHANGED);
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiFightButtonSettings:OnBtnGouxuan1(value)
    self.CurSelect = 0
    self.CurrentBtnProj1:SetButtonState(XUiButtonState.Select)
    self.CurrentBtnProj2:SetButtonState(XUiButtonState.Normal)
    self.BtnGouxuan2:SetButtonState(XUiButtonState.Normal)
    if value == 0 then
        self:OnBtnGouxuan2()
        self.BtnGouxuan2:SetButtonState(XUiButtonState.Select)
    end
end

function XUiFightButtonSettings:OnBtnGouxuan2(value)
    self.CurSelect = 1
    self.CurrentBtnProj1:SetButtonState(XUiButtonState.Normal)
    self.CurrentBtnProj2:SetButtonState(XUiButtonState.Select)
    self.BtnGouxuan1:SetButtonState(XUiButtonState.Normal)
    if value == 0 then
        self:OnBtnGouxuan1()
        self.BtnGouxuan1:SetButtonState(XUiButtonState.Select)
    end
end

function XUiFightButtonSettings:OnButtonProject1()
    self.CurSelect = 0
    self.CurrentBtnProj1:SetButtonState(XUiButtonState.Select)
    self.CurrentBtnProj2:SetButtonState(XUiButtonState.Normal)
    self.BtnGouxuan1:SetButtonState(XUiButtonState.Select)
    self.BtnGouxuan2:SetButtonState(XUiButtonState.Normal)
end

function XUiFightButtonSettings:OnButtonProject2()
    self.CurSelect = 1
    self.CurrentBtnProj1:SetButtonState(XUiButtonState.Normal)
    self.CurrentBtnProj2:SetButtonState(XUiButtonState.Select)
    self.BtnGouxuan1:SetButtonState(XUiButtonState.Normal)
    self.BtnGouxuan2:SetButtonState(XUiButtonState.Select)
end