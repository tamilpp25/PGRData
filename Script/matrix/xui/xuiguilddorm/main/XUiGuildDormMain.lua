local XUiGuildDormPanelOperation = require("XUi/XUiGuildDorm/Main/XUiGuildDormPanelOperation")
local XUiGuildDormPanelChannel = require("XUi/XUiGuildDorm/Main/XUiGuildDormPanelChannel")
local XUiGuildDormPanelAction = require("XUi/XUiGuildDorm/Main/XUiGuildDormPanelAction")
local XUiGuildDormPanelUiSetting = require("XUi/XUiGuildDorm/Main/XUiGuildDormPanelUiSetting")
--=================
--公会宿舍主页面
--=================
local XUiGuildDormMain = XLuaUiManager.Register(XLuaUi, "UiGuildDormMain")

function XUiGuildDormMain:OnAwake()
    self.TopController = XUiHelper.NewPanelTopControl(self, self.TopControl, self.OnClickBackBtn, self.OnClickMainUiBtn)
    -- self:BindHelpBtn(self.BtnHelp, "GuildDorm")
    self:InitButtons()
    self:InitChildPanels()
    self:AddEventListeners()
    self.UiPanelChannel:ConnectSignal("OnSwitchChannelSuccess", self, self.OnSwitchChannelSuccess)
    self.UiPanelChannel:ConnectSignal("OpenBlackScreen", self, self.OpenBlackScreen)
    self.UiPanelChannel:ConnectSignal("CloseBlackScreen", self, self.CloseBlackScreen)
    self.UiPanelChannel:ConnectSignal("ClosePanelChannel", self, function()
            self.UiPanelOperation:SetIsCanMove(true)
        end)
end

function XUiGuildDormMain:OnStart()
    local scene = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene()
    local room = scene:GetCurrentRoom()
    self:OnEnterRoom(room)
    for _, component in pairs(self.ChildComponents or {}) do
        if component["OnStart"] then
            component:OnStart()
        end
    end
end

function XUiGuildDormMain:OnEnable()
    XUiGuildDormMain.Super.OnEnable(self)
    local currentScene = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene()
    --重置天空盒
    currentScene:ResetSkyBox()
    currentScene:GetCurrentRoom():SetIsShow(true)
    local camera = currentScene:GetCamera()
    if camera then
        camera.gameObject:SetActiveEx(true)
    end
    for _, component in pairs(self.ChildComponents or {}) do
        if component["OnEnable"] then
            component:OnEnable()
        end
    end
    --当从其他界面返回到此界面时，需要重新设置光照
    CS.XGlobalIllumination.SetSceneType(CS.XSceneType.Dormitory)
    --这里需要手动把XSceneSetting打开，刷新脚本初始化
    local XSceneSetting = currentScene.GameObject:GetComponent("XSceneSetting")
    if XSceneSetting then
        XSceneSetting.enabled = true
    end
    --现在场景是烘焙的，不需要设置全局光照
    --XDataCenter.GuildDormManager.SceneManager.GetCurrentScene():SetGlobalIllumSO()
    --显示时刷新一下拟真围剿的蓝点
    self:RefreshChallengeRed()
end

function XUiGuildDormMain:OnDisable()
    XUiGuildDormMain.Super.OnDisable(self)
    for _, component in pairs(self.ChildComponents or {}) do
        if component["OnDisable"] then
            component:OnDisable()
        end
    end
    CS.XGlobalIllumination.SetSceneType(CS.XSceneType.Ui)
    local currentScene = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene()
    currentScene:GetCurrentRoom():SetIsShow(false)
    local camera = currentScene:GetCamera()
    if camera then
        camera.gameObject:SetActiveEx(false)
    end
    --这里需要手动把XSceneSetting关闭，返回时打开，刷新脚本初始化
    local XSceneSetting = currentScene.GameObject:GetComponent("XSceneSetting")
    if XSceneSetting then
        XSceneSetting.enabled = false
    end
    --退出公会宿舍界面时，主动GC一次
    LuaGC()
end
--============
--在ui释放时在堆栈中把这个界面移除避免战斗重开Ui时直接打开这个界面导致错误
--============
function XUiGuildDormMain:OnRelease()
    XUiGuildDormMain.Super.OnRelease(self)
    XLuaUiManager.Remove("UiGuildDormCommon")
    XLuaUiManager.Remove("UiGuildDormMain")
end

function XUiGuildDormMain:OnDestroy()
    for _, component in pairs(self.ChildComponents or {}) do
        if component["OnDestroy"] then
            component:OnDestroy()
        end
    end
    self:RemoveEventListeners()
    self:DisposeChildComponents()
    XDataCenter.GuildDormManager.RequestExitRoom()
    XDataCenter.GuildDormManager.ExitGuildDorm()
end
--============
--添加界面事件监听
--============
function XUiGuildDormMain:AddEventListeners()
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_ON_ENTER_ROOM, self.OnEnterRoom, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_PLAY_ACTION, self.OnPlayAction, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_UI_SETTING, self.SetComponentsClose, self)
    XRedPointManager.AddRedPointEvent(self.BtnGift, self.SetBtnGiftRed, self, { XRedPointConditions.Types.CONDITION_GUILD_ACTIVEGIFT })
    XRedPointManager.AddRedPointEvent(self.BtnInformation, self.SetBtnInformationRed, self, { XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST })
end
--============
--移除界面事件监听
--============
function XUiGuildDormMain:RemoveEventListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_ON_ENTER_ROOM, self.OnEnterRoom, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_PLAY_ACTION, self.OnPlayAction, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_UI_SETTING, self.SetComponentsClose, self)
    XRedPointManager.RemoveRedPointEvent(self.BtnGift, self.SetBtnGiftRed, self, { XRedPointConditions.Types.CONDITION_GUILD_ACTIVEGIFT })
    XRedPointManager.RemoveRedPointEvent(self.BtnInformation, self.SetBtnInformationRed, self, { XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST })
end
--=====================================按钮相关方法Start=========================================
function XUiGuildDormMain:InitButtons()
    self.BtnTabMember.CallBack = function() self:OnClickBtnTabMember() end
    self.BtnTabChallenge.CallBack = function() self:OnClickBtnTabChallenge() end
    self.BtnTabGift.CallBack = function() self:OnClickBtnTabGift() end
    self.BtnUI.CallBack = function() self:OnClickBtnUI() end
    self.BtnPeople.CallBack = function() self:OnClickBtnPeople() end
    self.BtnAct.CallBack = function() self:OnClickBtnAct() end
    self.BtnInformation.CallBack = function() self:OnClickInformation() end
    self.BtnGift.CallBack = function() self:OnClickGift() end
    XUiHelper.RegisterClickEvent(self, self.BtnChannel, self.OnBtnChannelClicked)
    if self.SwitchGuildDorm then
        local btn = require("XUi/XUiGuildDorm/XUiGuildSwitchBtn")
        self.BtnSwitchGuild = btn.New(self, self.SwitchGuildDorm, true)
    end
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, function()
        self.UiPanelOperation:SetIsCanMove(false)
        XUiManager.ShowHelpTip("GuildDorm", function()
            self.UiPanelOperation:SetIsCanMove(true)
        end)  
    end)
end
--============
--返回按钮点击
--============
function XUiGuildDormMain:OnClickBackBtn()
    XDataCenter.GuildDormManager.RequestExitRoom(function()
            XLuaUiManager.RunMain()
        end)
end
--============
--主菜单按钮点击
--============
function XUiGuildDormMain:OnClickMainUiBtn()
    XDataCenter.GuildDormManager.RequestExitRoom(function()
            XLuaUiManager.RunMain()
        end)
end
--============
--成员按钮点击
--============
function XUiGuildDormMain:OnClickBtnTabMember()
    local guildId = XDataCenter.GuildManager.GetGuildId()
    local now = XTime.GetServerNowTimestamp()
    if now - self.Data.LastRequestMember >= XGuildDormConfig.RequestMemberGap then
        self.Data.LastRequestMember = now
        XDataCenter.GuildManager.GetGuildMembers(guildId, function()
                XLuaUiManager.Open("UiGuildRongyu")
            end)
    else
        XLuaUiManager.Open("UiGuildRongyu")
    end
end
--============
--挑战按钮点击
--============
function XUiGuildDormMain:OnClickBtnTabChallenge()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.GuildBoss) then
        return
    end
    XDataCenter.GuildBossManager.OpenGuildBossHall()
end
--============
--奖励按钮点击
--============
function XUiGuildDormMain:OnClickBtnTabGift()
    XLuaUiManager.Open("UiGuildPanelWelfare")
end
--============
--UI设置按钮点击
--============
function XUiGuildDormMain:OnClickBtnUI()
    self.UiPanelOperation:SetIsCanMove(false)
    self.UiPanelUiSetting:Open(function()
        self.UiPanelOperation:SetIsCanMove(true)
    end)
end
--============
--人员按钮点击
--============
function XUiGuildDormMain:OnClickBtnPeople()
    self.UiPanelOperation:SetIsCanMove(false)
    RunAsyn(function ()
            XLuaUiManager.Open("UiGuildDormPerson")
            local signalCode = XLuaUiManager.AwaitSignal("UiGuildDormPerson", "_", self)
            if signalCode ~= XSignalCode.RELEASE then return end
            self.UiPanelOperation:SetIsCanMove(true)
        end)

end
--============
--表情动作按钮点击
--============
function XUiGuildDormMain:OnClickBtnAct()
    if self.PanelActionCD.gameObject.activeSelf then
        XUiManager.TipErrorWithKey("GuildDormActionCDTip")
        return
    end
    self.UiPanelOperation:SetIsCanMove(false)
    self.UiPanelAction:Open(function()
        self.UiPanelOperation:SetIsCanMove(true)
    end)
end
--============
--公会信息按钮点击
--============
function XUiGuildDormMain:OnClickInformation()
    self.UiPanelOperation:SetIsCanMove(false)
    self.UiPanelGuildInformation:Show(function()
        self.UiPanelOperation:SetIsCanMove(true)
    end)
end
--============
--旧公会入口按钮点击
--============
function XUiGuildDormMain:OnClickOldGuild()
    XDataCenter.GuildManager.EnterGuild()
end
--============
--频道按钮点击
--============
function XUiGuildDormMain:OnBtnChannelClicked()
    XDataCenter.GuildDormManager.RequestRoomChannelData(function()
            self.UiPanelChannel:Open()
            self.UiPanelOperation:SetIsCanMove(false)
        end)
end
--============
--奖励按钮点击
--============
function XUiGuildDormMain:OnClickGift()
    self.UiPanelOperation:SetIsCanMove(false)
    RunAsyn(function ()
        XLuaUiManager.Open("UiGuildDormGiftInfo")
        local signalCode = XLuaUiManager.AwaitSignal("UiGuildDormGiftInfo", "_", self)
        if signalCode ~= XSignalCode.RELEASE then return end
        self.UiPanelOperation:SetIsCanMove(true)
    end)
end
--============
--奖励按钮红点
--============
function XUiGuildDormMain:SetBtnGiftRed(count)
    local giftContribute = XDataCenter.GuildManager.GetGiftContribute()
    local canReceive = count >= 0
    self.BtnGift:SetName(XUiHelper.GetText(canReceive and "GuildDormGiftButtonCanReceive" or "GuildDormGiftButtonNormal", giftContribute))
    self.BtnGift:ShowReddot(count >= 0)
end
--============
--公会面板按钮红点
--============
function XUiGuildDormMain:SetBtnInformationRed(count)
    self.BtnInformation:ShowReddot(count >= 0)
end
--============
--刷新挑战按钮
--============
function XUiGuildDormMain:RefreshChallengeRed()
    if XDataCenter.GuildBossManager.IsReward() then
        self.BtnInformation:ShowReddot(true)
    else
        XRedPointManager.CheckOnceByButton(self.BtnInformation, { XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST })
    end
end
--=====================================按钮相关方法End=========================================

--=====================================子控件相关方法Start=========================================
local ChildComponentsData = {
    PanelGuildInformation = require("XUi/XUiGuildDorm/Main/XUiGuildDormPanelGuildInformation"),
    DormTopName = require("XUi/XUiGuildDorm/Main/Panels/XUiGuildDormMainTopName"),
    BtnInformation = require("XUi/XUiGuildDorm/Main/Panels/XUiGuildDormMainBtnInfo"),
    PanelOperation = require("XUi/XUiGuildDorm/Main/XUiGuildDormPanelOperation"),
    PanelChannel = require("XUi/XUiGuildDorm/Main/XUiGuildDormPanelChannel"),
    PanelAction = require("XUi/XUiGuildDorm/Main/XUiGuildDormPanelAction"),
    PanelUiSetting = require("XUi/XUiGuildDorm/Main/XUiGuildDormPanelUiSetting"),
    DormTopChannel = require("XUi/XUiGuildDorm/Main/Panels/XUiGuildDormMainTopChannel"),
    PanelChat = require("XUi/XUiGuildDorm/Main/XUiGuildDormPanelChat")
}
--==============
--初始化子面板
--==============
function XUiGuildDormMain:InitChildPanels()
    self.ChildComponents = {}
    local uiClassIns
    for name, script in pairs(ChildComponentsData) do
        uiClassIns = script.New(self[name])
        self["Ui" .. name] = uiClassIns
        table.insert(self.ChildComponents, uiClassIns)
        if CheckClassSuper(uiClassIns, XSignalData) then
            uiClassIns:ConnectSignal("SetRoleIsCanMove", self, self.SetRoleIsCanMove)
        end
    end
end

function XUiGuildDormMain:SetRoleIsCanMove(value)
    self.UiPanelOperation:SetIsCanMove(value)
end

function XUiGuildDormMain:DisposeChildComponents()
    for _, component in pairs(self.ChildComponents) do
        if component["Dispose"] then
            component:Dispose()
        end
    end
end

function XUiGuildDormMain:SetComponentsClose(value)
    if value then
        self.TopController:ShowUi()
        self.BtnTabMember.gameObject:SetActiveEx(true)
        self.BtnTabChallenge.gameObject:SetActiveEx(true)
        self.BtnTabGift.gameObject:SetActiveEx(true)
        self.BtnPeople.gameObject:SetActiveEx(true)
        self.BtnAct.gameObject:SetActiveEx(true)
        self.BtnHelp.gameObject:SetActiveEx(true)
        self.BtnSwitchGuild.GameObject:SetActiveEx(true)
        self.BtnGift.gameObject:SetActiveEx(true)
    else
        self.TopController:HideUi()
        self.BtnTabMember.gameObject:SetActiveEx(false)
        self.BtnTabChallenge.gameObject:SetActiveEx(false)
        self.BtnTabGift.gameObject:SetActiveEx(false)
        self.BtnPeople.gameObject:SetActiveEx(false)
        self.BtnAct.gameObject:SetActiveEx(false)
        self.BtnHelp.gameObject:SetActiveEx(false)
        self.BtnSwitchGuild.GameObject:SetActiveEx(false)
        self.BtnGift.gameObject:SetActiveEx(false)
    end
    for _, component in pairs(self.ChildComponents) do
        if value and component.SetShow then
            component:SetShow()
        elseif not value and component.SetHide then
            component:SetHide()
        end
    end
end
--=====================================子控件相关方法End=========================================
--=============
--进入房间时
--=============
function XUiGuildDormMain:OnEnterRoom(room)
    if not room then return end
    self.Data = room:GetRoomData() --房间数据
end
--=============
--打开黑屏
--=============
function XUiGuildDormMain:OpenBlackScreen()
    self.BlackScreen.alpha = 1
    self.BlackScreen.gameObject:SetActiveEx(true)
end
--=============
--关闭黑屏
--=============
function XUiGuildDormMain:CloseBlackScreen()
    self:PlayAnimation("ChannelQieHuan", function()
            self.BlackScreen.gameObject:SetActiveEx(false)
        end, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
end
--=============
--切换频道成功后的处理
--=============
function XUiGuildDormMain:OnSwitchChannelSuccess(index)
    self.UiPanelOperation:SetData()
end

function XUiGuildDormMain:OnPlayAction(playerId, actionId)
    if XPlayer.Id ~= playerId or actionId <= 0 then return end
    if self.__CDTimer then
        XScheduleManager.UnSchedule(self.__CDTimer)
    end
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormPlayAction, actionId)
    self.PanelActionCD.gameObject:SetActiveEx(true)
    self.ImgCD.fillAmount = 1
    self.TxtCDTime.text = config.CoolDown .. XUiHelper.GetText("Second")
    self.__CDTimer = XUiHelper.Tween(config.CoolDown, function(t)
            if XTool.UObjIsNil(self.GameObject) then
                XScheduleManager.UnSchedule(self.__CDTimer)
                return
            end
            self.ImgCD.fillAmount = 1 - t
            self.TxtCDTime.text = getRoundingValue(config.CoolDown - config.CoolDown * t, 1) .. XUiHelper.GetText("Second")
        end, function(a)
            self.PanelActionCD.gameObject:SetActiveEx(false)
        end)
end