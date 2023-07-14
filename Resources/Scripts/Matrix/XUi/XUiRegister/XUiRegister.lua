local XUiRegister = XLuaUiManager.Register(XLuaUi, "UiRegister")
local XUiGridAccount = require("XUi/XUiRegister/XUiGridAccount")

function XUiRegister:OnAwake()
    self:InitAutoScript()
end

function XUiRegister:OnStart(loginCb)
    self.LoginCb = loginCb
    self.InFUserId.text = XUserManager.UserId or ""
    self.PanelRegister.gameObject:SetActive(true)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelAccountHistory)
    self.DynamicTable:SetProxy(XUiGridAccount)
    self.DynamicTable:SetDelegate(self)

    self.AccountList = XHaruUserManager.GetAccountList()
    self.DynamicTable:SetDataSource(self.AccountList)
    self.DynamicTable:ReloadDataSync()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiRegister:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiRegister:AutoInitUi()
    self.PanelRegister = self.Transform:Find("SafeAreaContentPane/PanelRegister")
    self.InFUserId.contentType = CS.UnityEngine.UI.InputField.ContentType.Standard
end

function XUiRegister:AutoAddListener()
    self:RegisterClickEvent(self.BtnSignIn, self.OnBtnSignInClick)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
end
-- auto

function XUiRegister:OnBtnSignInClick()
    local userIdText = self.InFUserId.text

    if not userIdText or #self.InFUserId.text == 0 then
        XUiManager.TipText("LoginPhoneEmpty")
        return
    end

    self:OnSignIn(userIdText)
end

function XUiRegister:OnBtnCancelClick()
    self:Close()
end

function XUiRegister:OnSignIn(userId)
    XHaruUserManager.SignIn(userId, function()
        if self.LoginCb then
            self.LoginCb()
        end

        self:Close()
    end)
end

--动态列表事件
function XUiRegister:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.AccountList[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnSignIn(self.AccountList[index].Name)
    end
end