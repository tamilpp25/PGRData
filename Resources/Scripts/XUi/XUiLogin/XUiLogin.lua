local XUiLoginNetworkModePanel = require("XUi/XUiLogin/XUiLoginNetworkModePanel")

local XUiLogin = XLuaUiManager.Register(XLuaUi, "UiLogin")

local HasRequestNotice = false

function XUiLogin:OnAwake()
    self:InitAutoScript()
    self.GridServer.gameObject:SetActive(false)

    self.PanelLogin.gameObject:SetActive(true)
    self.PanelServerList.gameObject:SetActive(false)
    self.ServerList = {}
    self.SyncServer = false

    self.VerificationWaitInterval = CS.XGame.ClientConfig:GetInt("VerificationWaitInterval")
    self.SyncServerListInterval = CS.XGame.ClientConfig:GetInt("SyncServerListInterval")
    self.TxtNewVersion.text = CS.XRemoteConfig.DocumentVersion .. " (DocumentVersion)"
    self.TxtOldVersion.text = CS.XRemoteConfig.ApplicationVersion .. " (ApplicationVersion)"

    self:InitServerList()

    -- self.TxtUser.text = XUserManager.UserId

    -- XEventManager.BindEvent(self.TxtUser, XEventId.EVENT_USERID_CHANGE, function(userName)
    --     self.TxtUser.text = userName or ""
    --     XLog.Warning("XEventId.EVENT_USERID_CHANGE")
    --     --self.PanelServerList.gameObject:SetActive(true)
    -- end)

    XLoginManager.SetStartGuide(false)

    self.NeedAutoLoginByDeepLink = CS.XRemoteConfig.DeepLinkEnabled and not string.IsNilOrEmpty(CS.XAppsflyerEvent.GetDeepLinkValue())


    XEventManager.AddEventListener(XEventId.EVNET_HGSDKLOGIN_SUCCESS, self.OnHgSdkLoginSuccess, self)
    XEventManager.AddEventListener(XEventId.EVENT_AGREEMENT_LOAD_FINISH, self.OnLoadAgreementFinish, self)
    XEventManager.AddEventListener(XEventId.EVENT_WHEN_CLOSE_LOGIN_NOTICE, self.OnCloseLoginNotice, self)
end

function XUiLogin:OnUserIDChange()
    self.TxtUser.text = XUserManager.UserId or ""
    -- XLog.Debug("XEventId.EVENT_USERID_CHANGE")
end

function XUiLogin:OnCloseLoginNotice()
    if XAgreementManager.CheckNeedShow() then
        if not XLuaUiManager.IsUiShow("UiLoginAgreement") then
            XLuaUiManager.Open("UiLoginAgreement")
        end
    end
end

function XUiLogin:OnLoadAgreementFinish()
    if XLuaUiManager.IsUiShow("UiLoginNotice") then
        return
    end
    if XAgreementManager.CheckNeedShow() then
        if not XLuaUiManager.IsUiShow("UiLoginAgreement") then
            XLuaUiManager.Open("UiLoginAgreement")
        end
    end
end

function XUiLogin:OnDestroy()
    -- XEventManager.UnBindEvent(self.TxtUser)
    XEventManager.RemoveEventListener(XEventId.EVNET_HGSDKLOGIN_SUCCESS, self.OnHgSdkLoginSuccess, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_AGREEMENT_LOAD_FINISH, self.OnLoadAgreementFinish, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_WHEN_CLOSE_LOGIN_NOTICE, self.OnCloseLoginNotice, self)
end

function XUiLogin:OnDisable()
    self.IsInLogin = false
end

function XUiLogin:OnStart(...)
    if self.BlackMask then
        self.BlackMask.color = CS.UnityEngine.Color(0.0, 0.0, 0.0, 0.0)
        self.BlackMask.gameObject:SetActive(false)
    end

    --CS.XAudioManager.PlayMusic(CS.XAudioManager.LOGIN_BGM)

    self:ShowLoginPanel()
    if XUserManager.Channel ~= XUserManager.CHANNEL.KuroPC then 
        self.TxtUser.text = XUserManager.UserId or ""
    else 
        self.TxtUser.text = ""
    end
    self.GameObject:ScheduleOnce(function()
        --释放启动界面的资源
        CS.UnityEngine.Resources.UnloadUnusedAssets()
    end,100)

    XAgreementManager.LoadAgreeInfo()

    self:RequestLoginNotice()
    --self.IsRequestNotice = true
end

function XUiLogin:ShowLoginPanel()
    self.PanelLogin.gameObject:SetActive(true)
    self.PanelServerList.gameObject:SetActive(false)
end

function XUiLogin:ShowActivatePanel()
    self.PanelActivate.gameObject:SetActive(true)
end

function XUiLogin:HideActivatePanel()
    self.PanelActivate.gameObject:SetActive(false)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiLogin:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiLogin:AutoInitUi()
    self.PanelLogin = self.Transform:Find("SafeAreaContentPane/PanelLogin")
    self.BtnStart = self.Transform:Find("SafeAreaContentPane/PanelLogin/BtnStart"):GetComponent("Button")
    self.PanelLoginServer = self.Transform:Find("SafeAreaContentPane/PanelLogin/PanelLoginServer")
    self.BtnServer = self.Transform:Find("SafeAreaContentPane/PanelLogin/PanelLoginServer/BtnServer"):GetComponent("XUiButton")
    self.PanelUser = self.Transform:Find("SafeAreaContentPane/PanelLogin/PanelUser")
    self.BtnUser = self.Transform:Find("SafeAreaContentPane/PanelLogin/PanelUser/BtnUser"):GetComponent("Button")
    self.TxtUser = self.Transform:Find("SafeAreaContentPane/PanelLogin/PanelUser/BtnUser/TxtUser"):GetComponent("Text")
    self.TxtNewVersion = self.Transform:Find("SafeAreaContentPane/PanelLogin/TxtNewVersion"):GetComponent("Text")
    self.PanelServerList = self.Transform:Find("SafeAreaContentPane/PanelLogin/PanelServerList")
    self.PanelServer = self.Transform:Find("SafeAreaContentPane/PanelLogin/PanelServerList/PanelServer")
    self.SViewServer = self.Transform:Find("SafeAreaContentPane/PanelLogin/PanelServerList/PanelServer/SViewServer"):GetComponent("ScrollRect")
    self.PanelServerContent = self.Transform:Find("SafeAreaContentPane/PanelLogin/PanelServerList/PanelServer/SViewServer/Viewport/PanelServerContent")
    self.GridServer = self.Transform:Find("SafeAreaContentPane/PanelLogin/PanelServerList/PanelServer/SViewServer/Viewport/PanelServerContent/GridServer")
    self.BtnHideServerList = self.Transform:Find("SafeAreaContentPane/PanelLogin/PanelServerList/PanelServer/BtnHideServerList"):GetComponent("Button")
    self.TxtOldVersion = self.Transform:Find("SafeAreaContentPane/PanelLogin/TxtOldVersion"):GetComponent("Text")
    self.ImgLogo = self.Transform:Find("SafeAreaContentPane/ImgLogo"):GetComponent("Image")
    self.BtnLoginNotice = self.Transform:Find("SafeAreaContentPane/BtnLoginNotice"):GetComponent("Button")
    --LoginAgreePanel.OnAwake(self.Transform:Find("SafeAreaContentPane/PanelAgreement").gameObject)
    --LoginTypePanel.OnAwake(self.Transform:Find("SafeAreaContentPane/PanelLoginType").gameObject)
    self.PanelLoginNetworkMode = XUiLoginNetworkModePanel.New(self, self.PanelNetworkModeTip)
end

function XUiLogin:AutoAddListener()
    self:RegisterClickEvent(self.BtnStart, self.OnBtnStartClick)
    self:RegisterClickEvent(self.BtnServer, self.OnBtnServerClick)
    self:RegisterClickEvent(self.BtnUser, self.OnBtnUserClick)
    self:RegisterClickEvent(self.BtnHideServerList, self.OnBtnHideServerListClick)
    self:RegisterClickEvent(self.SwitchAccount, self.OnSwitchAccountClick)
    self:RegisterClickEvent(self.PanelAgree, self.OnAgreePanelClick)
    self:RegisterClickEvent(self.BtnMenu, self.OnBtnMenuClick)
    self.BtnNetworkMode.CallBack = function() self:OnBtnNetworkModeClick() end
end

function XUiLogin:SwitchServer()
     XLog.Warning("XUiLogin.SwitchServer")
    self.PanelServerList.gameObject:SetActive(true)
end

function XUiLogin:OnBtnMenuClick()
    XLuaUiManager.Open("UiLoginDialog", "Menu")
end

function XUiLogin:OnAgreePanelClick()
    XLuaUiManager.Open("UiLoginAgreement")
end

function XUiLogin:OnBtnNetworkModeClick()
    self.PanelLoginNetworkMode:Show()
end

function XUiLogin:OnHgSdkLoginSuccess()
    self.PanelUser.gameObject:SetActiveEx(true)
    self.BtnStart.gameObject:SetActiveEx(true)
    self:OnUserIDChange()
    if XUserManager.UserId then -- 海外修改
        local user_ServerId = XSaveTool.GetData(XPrefs.User_ServerId..XUserManager.UserId)
        local user_ServerId_Num = tonumber(user_ServerId)
        XLog.Debug("User_ServerId:"..XPrefs.User_ServerId..XUserManager.UserId..":"..tostring(user_ServerId))
        self.TxtUser.text = XUserManager.UserId;
        local serverDataList = XServerManager.GetServerList()
        -- user_ServerId_Num 才是真实的serverId
        if user_ServerId and user_ServerId_Num then
            local currentServer;
            for _, server in pairs(serverDataList) do
                if server.Id == user_ServerId_Num then
                    currentServer = server;
                end
            end
            if currentServer then
                XServerManager.Select(currentServer);
                self:UpdateSelectServer(currentServer);
            end
        else
            self.PanelServerList.gameObject:SetActive(true)
        end
    end
    --XAppEventManager.ApplogEvent(CS.XHgSdkEventConfig.SDK_Login);
end

function XUiLogin:OnSwitchAccountClick(eventData)
    if XUserManager.Channel == XUserManager.CHANNEL.Android or XUserManager.Channel == XUserManager.CHANNEL.IOS then
        XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.Change_account)
        XLuaUiManager.Open("UiLoginDialog", "Account")
    elseif XUserManager.Channel == XUserManager.CHANNEL.KuroPC then 
        XUserManager.Logout()
    else 
        CsXUiManager.Instance:Open("UiRegister")
    end
end

function XUiLogin:OnBtnUserClick(...)
    --注释 JP分支通过切换用户来登录，不需要退出账号行为
    --XUserManager.ShowLogout()
    --仅仅用来调试
    if self.ClickCount == nil then
        self.ClickCount = 0
        return
    end
    self.ClickCount = self.ClickCount + 1
    if self.ClickCount == 10 then
        local type = CS.XRemoteConfig.Channel
        type = type + 1
        if type == 5 then
            type = 1
        end
        CS.XRemoteConfig.Channel = type
        XUiManager.TipError("Network connect Type changed to " .. type)
        self.ClickCount = 0
    end
end

function XUiLogin:OnBtnStartClick(...)
    if XLoginManager.GetSDKAccountStatus() == XLoginManager.SDKAccountStatus.Cancellation then -- 检测sdk账号是否已经申请注销
        XUiManager.DialogTip(CS.XGame.ClientConfig:GetString("AccountUnCancellationTitle"), CS.XGame.ClientConfig:GetString("AccountUnCancellationContent"), XUiManager.DialogType.Normal, function() end, function()
            XHgSdkManager.AccountUnCancellation()
        end)
        return
    end
    --如果默认的用户没有同意协议，则弹出用户协议
    --当用户成功登录后，将同意协议存储在本地，不再需要同意协议
    if XLoginManager.GetSDKAccountStatus() == XLoginManager.SDKAccountStatus.Cancellation then
        XUiManager.DialogTip(CS.XGame.ClientConfig:GetString("AccountUnCancellationTitle"), CS.XGame.ClientConfig:GetString("AccountUnCancellationContent"), nil, function() end, function()
            XHgSdkManager.AccountUnCancellation()
        end)
        return
    end
    if XAgreementManager.CheckNeedShow() then
        XLuaUiManager.Open("UiLoginAgreement")
        return
    end

    if not self.IsRequestNotice then
        return
    end

    XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.SDK_Login)

    if XUserManager.IsNeedLogin() then
        XUserManager.ShowLogin()
    else
        self:DoLogin()
    end
end

-------------------------------------获取公告--------------------------------------------

function XUiLogin:RequestLoginNotice()
    XLuaUiManager.SetAnimationMask(true)
    XDataCenter.NoticeManager.RequestLoginNotice(function(invalid)
        self.IsRequestNotice = true
        XLuaUiManager.SetAnimationMask(false)
        XDataCenter.NoticeManager.AutoOpenLoginNotice()
    end)
end

----------------------------------- 登录到服务器 ------------------------------------------

function XUiLogin:DoLogin(...)
    if self.IsInLogin then
        return
    end
    self.IsInLogin = true
    XLuaUiManager.SetAnimationMask(true)
    local loginProfiler = CS.XProfiler.Create("login")
    loginProfiler:Start()
    XLoginManager.Login(function(code)
        XLuaUiManager.SetAnimationMask(false)
        if code and code ~= XCode.Success then
            if code == XCode.Fail then
                self.IsInLogin = false
                return
            end
            if code == XCode.LoginServiceInvalidToken then
                self.IsInLogin = false
                XUserManager.SignOut()
                XUserManager.ShowLogin()
            end
            self.IsInLogin = false
            return
        end

        --CS.XAudioManager.PlayMusic(CS.XAudioManager.MAIN_BGM)

        local runMainProfiler = loginProfiler:CreateChild("RunMain")
        runMainProfiler:Start()

        --BDC
        CS.XHeroBdcAgent.BdcAfterSdkLoginPage()

        XDataCenter.PurchaseManager.YKInfoDataReq(function()
            if self.BlackMask then
                self.BlackMask.color = CS.UnityEngine.Color(0.0, 0.0, 0.0, 0.0)
                self.BlackMask.gameObject:SetActive(true)
                self.BlackMask:DOFade(1.1, 0.3):OnComplete(function()
                    local guideFight = XDataCenter.GuideManager.GetNextGuideFight()
                    if guideFight then
                        self:Close()

                        XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.Anime_Start)
                        XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.Completed_Registration)

                        local movieId = CS.XGame.ClientConfig:GetString("NewUserMovieId")
                        CS.Movie.XMovieManager.Instance:PlayById(movieId, function()
                            XDataCenter.FubenManager.EnterGuideFight(guideFight.Id, guideFight.StageId, guideFight.NpcId, guideFight.Weapon)
                        end)
                    else
                        XLoginManager.SetFirstOpenMainUi(true)
                        XLuaUiManager.RunMain()
                    end
                end)
            else
                local guideFight = XDataCenter.GuideManager.GetNextGuideFight()
                if guideFight then
                    self:Close()

                    XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.Anime_Start)
                    XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.Completed_Registration)

                    local movieId = CS.XGame.ClientConfig:GetString("NewUserMovieId")
                    CS.Movie.XMovieManager.Instance:PlayById(movieId, function()
                        XDataCenter.FubenManager.EnterGuideFight(guideFight.Id, guideFight.StageId, guideFight.NpcId, guideFight.Weapon)
                    end)
                else
                    XLoginManager.SetFirstOpenMainUi(true)
                    XLuaUiManager.RunMain()
                end
            end
            -- self:OnCheckBindTask()
        end)

        XDataCenter.SetManager.SetOwnFontSizeByCache()
        runMainProfiler:Stop()

        loginProfiler:Stop()
        XLog.Debug(loginProfiler)
    end)
end

----------------------------------- 获取服务器列表 ----------------------------------------
---实际上功能上去掉了一部分功能，登录界面上并没有当前选择的服务器状态，low high 和 maintain都是失效的

function XUiLogin:OnBtnHideServerListClick(...)
    self.PanelServerList.gameObject:SetActive(false)
end

function XUiLogin:OnBtnServerClick(...)
    self.PanelServerList.gameObject:SetActive(true)
end

function XUiLogin:UpdateSelectServer(server)
    self.BtnServer:SetName(server.Name)
end

function XUiLogin:UpdateServerListSelect()
    for _, server in pairs(self.ServerList) do
        server:UpdateServerSelect()
    end
end

function XUiLogin:InitServerList()
    local list = XServerManager.GetServerList()

    if list then
        self.BtnServer.gameObject:SetActiveEx(#list > 1)
    end

    local currentServer;

    for _, server in pairs(list) do
        local serverGrid = XUiGridServer.New(CS.UnityEngine.Object.Instantiate(self.GridServer), server, function()
            XServerManager.Select(server)
            self:UpdateSelectServer(server)
            self:UpdateServerListSelect()
            self.PanelServerList.gameObject:SetActive(false)
        end)

        if server.Id == XServerManager.Id then
            currentServer = server;            
        end

        serverGrid.Transform:SetParent(self.PanelServerContent, false)
        serverGrid.GameObject:SetActive(true)
        self.ServerList[server.Id] = serverGrid
    end

    self:UpdateSelectServer(currentServer)
end

--------------------------------------------------------------------------Recycle-------------------------------------------------------------------------------

-- --似乎暂时也不用了
-- function XUiLogin:StopSyncServerList()
--     if self.SyncServerTimer then
--         CS.XScheduleManager.UnSchedule(self.SyncServerTimer)
--         self.SyncServer = false
--         self.SyncServerTimer = null
--     end
-- end

-- --没有地方用到
-- function XUiLogin:SyncServerList(cb)
--     if not self.SyncServer then
--         self.SyncServer = true
--         self.SyncServerTimer = CS.XScheduleManager.ScheduleForever(function(...)
--             self:SyncServerList()
--         end, self.SyncServerListInterval, 0)
--     end

--     local baseGrid = self.GridServer
--     XServerManager.GetServerData(function(serverData)
--         XTool.LoopMap(serverData.ServerTable, function(key, value)
--             if value.Id == XServerManager.Id then
--                 self:UpdateSelectServer(value)
--             end

--             if self.ServerList[value.Id] then
--                 self.ServerList[value.Id]:UpdateServer(value)
--             else
--                 local serverGrid = XUiGridServer.New(CS.UnityEngine.Object.Instantiate(baseGrid), value, function()
--                     XServerManager.Select(value)
--                     self:UpdateSelectServer(value)
--                     self:UpdateServerListSelect()
--                     self.PanelServerList.gameObject:SetActive(false)
--                 end)

--                 serverGrid.Transform:SetParent(self.PanelServerContent, false)
--                 serverGrid.GameObject:SetActive(true)
--                 self.ServerList[value.Id] = serverGrid
--             end
--         end)

--         if cb then
--             cb()
--         end
--     end)
-- end

-- function XUiLogin:OnCheckBindTask()
--     if XUserManager.UserType == XHgSdkManager.UserType.FaceBook or XUserManager.UserType == XHgSdkManager.UserType.Apple or XUserManager.UserType == XHgSdkManager.UserType.Google
--     or XUserManager.UserType == XHgSdkManager.UserType.Twitter then
--         XHgSdkManager.OnBindTaskFinished()
--     end
-- end