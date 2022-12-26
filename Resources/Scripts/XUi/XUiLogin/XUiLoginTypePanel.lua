local this = {}

function this.OnAwake(rootUi)
    this.GameObject = rootUi.gameObject
    this.Transform = rootUi.transform
    XTool.InitUiObject(this)
    this.InitUI()
    this.AutoAddListeners()
end

function this.InitUI()
    --苹果端菜显示苹果专用登录选项
    this.AppleGroup.gameObject:SetActiveEx(CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.IPhonePlayer);
end

function this.AutoAddListeners()
    this.CloseLoginTypeBtn.onClick:AddListener(this.CloseLoginType)
    this.LoginTwitterBtn.onClick:AddListener(this.OnTwitterLogin)
    this.LoginLineBtn.onClick:AddListener(this.OnLineLogin)
    this.LoginAppleBtn.onClick:AddListener(this.OnAppleLogin)
    this.LoginSidBtn.onClick:AddListener(this.OnSidLogin)
end

function this.OnAppleLogin()
    XHgSdkManager.Logout()
    XHgSdkManager.Login(XHgSdkManager.UserType.Apple)
end

function this.OnSidLogin()
    XHgSdkManager.Logout()
    XHgSdkManager.Login(XHgSdkManager.UserType.Suid)
end

function this.OnTwitterLogin()
    XHgSdkManager.Logout()
    XHgSdkManager.Login(XHgSdkManager.UserType.Twitter)
end

function this.OnLineLogin()
    XHgSdkManager.Logout()
    XHgSdkManager.Login(XHgSdkManager.UserType.Line)
end

function this.CloseLoginType()
    this.GameObject:SetActiveEx(false)
end

function this.Show()
    this.GameObject:SetActiveEx(true)
end

function this.Hide()
    this.GameObject:SetActiveEx(false)
end

return this