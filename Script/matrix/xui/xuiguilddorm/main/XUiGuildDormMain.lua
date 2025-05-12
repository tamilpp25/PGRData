local XUiGuildDormPanelOperation = require("XUi/XUiGuildDorm/Main/XUiGuildDormPanelOperation")
local XUiGuildDormPanelChannel = require("XUi/XUiGuildDorm/Main/XUiGuildDormPanelChannel")
local XUiGuildDormPanelAction = require("XUi/XUiGuildDorm/Main/XUiGuildDormPanelAction")
local XUiGuildDormPanelUiSetting = require("XUi/XUiGuildDorm/Main/XUiGuildDormPanelUiSetting")
--=================
--公会宿舍主页面
--=================
---@class UiGuildDormMain : XLuaUi
---@field UiPanelPhotograph XUiGuildDormPanelPhotograph
---@field UiPanelOperation XUiGuildDormPanelOperation
---@field UiPanelUiSetting XUiGuildDormPanelUiSetting
local XUiGuildDormMain = XLuaUiManager.Register(XLuaUi, "UiGuildDormMain")

function XUiGuildDormMain:OnAwake()
    self.TopController = XUiHelper.NewPanelTopControl(self, self.TopControl, handler(self, self.Close), self.OnClickMainUiBtn)
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
    self.UiPanelPhotograph:ConnectSignal("OnSwitchPhotographModel", self, self.OnSwitchPhotographModel)
    self.UiPanelPhotograph:ConnectSignal("PhotographUiEnable", self, self.PhotographUiEnable)
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
    XDataCenter.GuildDormManager.UpdateSortingOrder(self.Transform:GetComponent("Canvas").sortingOrder)
end

function XUiGuildDormMain:OnEnable()
    XUiGuildDormMain.Super.OnEnable(self)
    self.GuildWarEntry:OnEnable()
    ---@type XGuildDormScene
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
    XUiHelper.SetSceneType(CS.XSceneType.Dormitory)
    --这里需要手动把XSceneSetting打开，刷新脚本初始化
    local XSceneSetting = currentScene.GameObject:GetComponent("XSceneSetting")
    if XSceneSetting then
        XSceneSetting.enabled = true
        CS.XGraphicManager.BindScene(XSceneSetting)
    end
    --现在场景是烘焙的，不需要设置全局光照
    --XDataCenter.GuildDormManager.SceneManager.GetCurrentScene():SetGlobalIllumSO()
    --显示时刷新一下拟真围剿的蓝点
    self:RefreshChallengeRed()

    XDataCenter.GuildWarManager.OnEnterUiGuild()
    self:CheckOpenHelp()

    -- 刷新乐器/音乐屏蔽按钮
    -- toggle的显示用GameObjectLayerSettingActive组件实现了
    local themeId = XDataCenter.GuildDormManager.GetThemeId()
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormInstrumentVolumeControl, themeId, true)
    self.BtnMusicMuteSet.gameObject:SetActiveEx(not XTool.IsTableEmpty(config))

    local enterThemeKey = string.format("GuildDormEnterTheme_%d_PlayerId%d", themeId, XPlayer.Id)
    if not XSaveTool.GetData(enterThemeKey) and not XTool.IsTableEmpty(config) then
        local musicSaveRes = (config.FirstMuteBgm == 0) and 1 or 0
        local instrumentSaveRes = (config.FirstMuteInstrument == 0) and 1 or 0
        XDataCenter.GuildDormManager.SaveToggleSceneMusicCache(musicSaveRes)
        XDataCenter.GuildDormManager.SaveToggleInstrumentMusicCache(instrumentSaveRes)
        XSaveTool.SaveData(enterThemeKey, true)
    end
    -- 刷新Toggle状态
    self:RefreshToggleState()
    -- 根据toggle状态屏蔽声音
    self:OnToggleSceneMusicClick()
    self:OnToggleInstrumentMusicClick()
end

function XUiGuildDormMain:RefreshToggleState()
    -- 刷新Toggle状态
    self.ToggleSceneMusic:SetButtonState(XDataCenter.GuildDormManager.GetToggleSceneMusicCache() and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self.ToggleInstrumentMusic:SetButtonState(XDataCenter.GuildDormManager.GetToggleInstrumentMusicCache() and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiGuildDormMain:OnDisable()
    XUiGuildDormMain.Super.OnDisable(self)
    for _, component in pairs(self.ChildComponents or {}) do
        if component["OnDisable"] then
            component:OnDisable()
        end
    end
    XUiHelper.SetSceneType(CS.XSceneType.Ui)
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
    self.GuildWarEntry:OnDestroy()
end
--============
--添加界面事件监听
--============
function XUiGuildDormMain:AddEventListeners()
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_ON_ENTER_ROOM, self.OnEnterRoom, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_PLAY_ACTION, self.OnPlayAction, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_UI_SETTING, self.SetComponentsClose, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_UI_SETTING_RIGHT, self.SetRightBtnGroupClose, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_TOGGLE_MUSIC, self.RefreshToggleState, self)
    self.RedPointGiftId = self:AddRedPointEvent(self.BtnGift, self.SetBtnGiftRed, self, {
        XRedPointConditions.Types.CONDITION_GUILD_ACTIVEGIFT,
        XRedPointConditions.Types.CONDITION_GUILDBOSS_BOSSHP,
        XRedPointConditions.Types.CONDITION_GUILDBOSS_SCORE,
    })
    self.RedPointInfomationId = self:AddRedPointEvent(self.BtnInformation, self.SetBtnInformationRed, self, { XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST })

    --新手引导结束
    --CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_GUIDE_END, handler(self, self.OnGuideEnd))

    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_3D_UI_SHOW, self.CheckOpenHelp, self)
end
--============
--移除界面事件监听
--============
function XUiGuildDormMain:RemoveEventListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_ON_ENTER_ROOM, self.OnEnterRoom, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_PLAY_ACTION, self.OnPlayAction, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_UI_SETTING, self.SetComponentsClose, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_UI_SETTING_RIGHT, self.SetRightBtnGroupClose, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_TOGGLE_MUSIC, self.RefreshToggleState, self)
    self:RemoveRedPointEvent(self.RedPointGiftId)
    self:RemoveRedPointEvent(self.RedPointInfomationId)

    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_3D_UI_SHOW, self.CheckOpenHelp, self)

    --新手引导结束
    --CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_GUIDE_END, handler(self, self.OnGuideEnd))
end
--=====================================按钮相关方法Start=========================================
function XUiGuildDormMain:InitButtons()
    self.BtnTabMember.CallBack = function()
        self:OnClickBtnTabMember()
    end
    self.BtnTabChallenge.CallBack = function()
        self:OnClickBtnTabChallenge()
    end
    self.BtnTabGift.CallBack = function()
        self:OnClickBtnTabGift()
    end
    self.BtnUI.CallBack = function()
        self:OnClickBtnUI()
    end
    self.BtnPeople.CallBack = function()
        self:OnClickBtnPeople()
    end
    self.BtnAct.CallBack = function()
        self:OnClickBtnAct()
    end
    self.BtnInformation.CallBack = function()
        self:OnClickInformation()
    end
    self.BtnGift.CallBack = function()
        self:OnClickGift()
    end
    self.BtnCamera.CallBack = function()
        self:OnClickCamera()
    end
    XUiHelper.RegisterClickEvent(self, self.BtnChannel, self.OnBtnChannelClicked)
    if self.SwitchGuildDorm then
        local btn = require("XUi/XUiGuildDorm/XUiGuildSwitchBtn")
        self.BtnSwitchGuild = btn.New(self, self.SwitchGuildDorm, true)
    end
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, function()
        self:OnOpenHelpTips(false)
    end)
    XUiHelper.RegisterClickEvent(self, self.ToggleSceneMusic, self.OnToggleSceneMusicClick)
    XUiHelper.RegisterClickEvent(self, self.ToggleInstrumentMusic, self.OnToggleInstrumentMusicClick)

    local guildWarEntryButtonScript = require("XUi/XUiGuildWar/XUiGuildWarEntryButton")
    self.GuildWarEntry = guildWarEntryButtonScript.New(self.BtnGuildWarEntry, function()
        self:OnBtnGuildWarEntryClick()
    end)
    self.GuildWarEntry:OnShow()

    self:AddRedPointEvent(self.BtnGuildWarEntry, self.OnCheckGuildWarEntryRedPoint, self,
            {
                XRedPointConditions.Types.CONDITION_GUILDWAR_Main,
            })
end

function XUiGuildDormMain:OnToggleSceneMusicClick()
    XDataCenter.GuildDormManager.SetGuildSceneCDMusicMute(not self.ToggleSceneMusic:GetToggleState())
    XDataCenter.GuildDormManager.SaveToggleSceneMusicCache(self.ToggleSceneMusic:GetToggleState() and 1 or 0)
end

function XUiGuildDormMain:OnToggleInstrumentMusicClick()
    XMVCA.XInstrumentSimulator:MuteInstrumentSimulator(not self.ToggleInstrumentMusic:GetToggleState())
    XDataCenter.GuildDormManager.SaveToggleInstrumentMusicCache(self.ToggleInstrumentMusic:GetToggleState() and 1 or 0)
end

function XUiGuildDormMain:CheckOpenHelp()
    if not XDataCenter.GuildDormManager.CheckIsShowUiGuildDormCommon() then
        return
    end
    --需要等到UiPanelOperation OnEnable 之后才能判断
    if XDataCenter.GuildDormManager.IsNewVersionFirstIn()
            and XDataCenter.GuildDormManager.CheckGuideGroupsIsCompleteForOpenHelp() then
        self:OnOpenHelpTips(true)
        XDataCenter.GuildDormManager.MarkNewVersionFirstIn()
    end
end

---@desc 打开帮助提示，并跳转到最后一个
---@param isJump boolean 是否需要跳转
function XUiGuildDormMain:OnOpenHelpTips(isJump)
    self.UiPanelOperation:SetIsCanMove(false)
    local helpKey = "GuildDorm"
    local index = isJump and XHelpCourseConfig.GetImageAssetCount(helpKey) or 0
    XUiManager.ShowHelpTip(helpKey, function()
        self.UiPanelOperation:SetIsCanMove(true)
    end, index - 1)
end

--如果没有完成新手引导，则等新手引导完成后再执行
function XUiGuildDormMain:OnGuideEnd()
    self:OnOpenHelpTips(true)
    XDataCenter.GuildDormManager.MarkNewVersionFirstIn()
end

--============
--返回按钮点击
--============
function XUiGuildDormMain:Close()
    -- 先判断是否在拍照中
    if self.UiPanelPhotograph:CheckPhotographModel() then
        self.UiPanelPhotograph:QuitPhotographModel()
        return
    end
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
    local dict = {}
    dict["button"] = XGlobalVar.BtnGuildDormMain.BtnTabMember
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200006", "GuildDorm")

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
    local dict = {}
    dict["button"] = XGlobalVar.BtnGuildDormMain.BtnTabChallenge
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200006", "GuildDorm")
    XDataCenter.GuildBossManager.OpenGuildBossHall()
end
--============
--奖励按钮点击
--============
function XUiGuildDormMain:OnClickBtnTabGift()
    local dict = {}
    dict["button"] = XGlobalVar.BtnGuildDormMain.BtnTabGift
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200006", "GuildDorm")
    XLuaUiManager.Open("UiGuildPanelWelfare")
end
--============
--UI设置按钮点击
--============
function XUiGuildDormMain:OnClickBtnUI()
    local dict = {}
    dict["button"] = XGlobalVar.BtnGuildDormMain.BtnUi
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200006", "GuildDorm")
    self.UiPanelOperation:SetIsCanMove(false)
    self.UiPanelUiSetting:Open(function()
        self.UiPanelOperation:SetIsCanMove(true)
    end)
end
--============
--人员按钮点击
--============
function XUiGuildDormMain:OnClickBtnPeople()
    local dict = {}
    dict["button"] = XGlobalVar.BtnGuildDormMain.BtnPeople
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200006", "GuildDorm")
    self.UiPanelOperation:SetIsCanMove(false)
    RunAsyn(function()
        XLuaUiManager.Open("UiGuildDormPerson")
        local signalCode = XLuaUiManager.AwaitSignal("UiGuildDormPerson", "_", self)
        if signalCode ~= XSignalCode.RELEASE then
            return
        end
        self.UiPanelOperation:SetIsCanMove(true)
    end)
end
--============
--表情动作按钮点击
--============
function XUiGuildDormMain:OnClickBtnAct()
    local dict = {}
    dict["button"] = XGlobalVar.BtnGuildDormMain.BtnAct
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200006", "GuildDorm")

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
    local dict = {}
    dict["button"] = XGlobalVar.BtnGuildDormMain.BtnChannel
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200006", "GuildDorm")
    XDataCenter.GuildDormManager.RequestRoomChannelData(function()
        self.UiPanelChannel:Open()
        self.UiPanelOperation:SetIsCanMove(false)
    end)
end
--============
--奖励按钮点击
--============
function XUiGuildDormMain:OnClickGift()
    local dict = {}
    dict["button"] = XGlobalVar.BtnGuildDormMain.BtnGift
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200006", "GuildDorm")
    self.UiPanelOperation:SetIsCanMove(false)
    RunAsyn(function()
        --XLuaUiManager.Open("UiGuildDormGiftInfo")
        --local signalCode = XLuaUiManager.AwaitSignal("UiGuildDormGiftInfo", "_", self)
        XLuaUiManager.Open("UiGuildTaskGroup")
        local signalCode = XLuaUiManager.AwaitSignal("UiGuildTaskGroup", "_", self)
        if signalCode ~= XSignalCode.RELEASE then
            return
        end
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
    if XDataCenter.GuildBossManager.IsReward()
            and XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.GuildBoss) then
        self.BtnInformation:ShowReddot(true)
        self.BtnTabChallenge:ShowReddot(true)
    else
        self.BtnTabChallenge:ShowReddot(false)
        XRedPointManager.CheckOnceByButton(self.BtnInformation, { XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST })
    end
end

---公会战按钮点击
function XUiGuildDormMain:OnBtnGuildWarEntryClick()
    local dict = {}
    dict["button"] = XGlobalVar.BtnGuildDormMain.BtnGuildWarEntry
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200006", "GuildDorm")

    XDataCenter.GuildWarManager.OpenUiGuildWarMain(function()
        XLuaUiManager.Open("UiGuildWarSelect")
    end)
end

-- 拍照按钮点击
function XUiGuildDormMain:OnClickCamera()
    self.UiPanelPhotograph:OnClick()
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
    PanelChat = require("XUi/XUiGuildDorm/Main/XUiGuildDormPanelChat"),
    PanelPhotograph = require("XUi/XUiGuildDorm/Photograph/XUiGuildDormPanelPhotograph"),
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

function XUiGuildDormMain:SetRightBtnGroupClose(value)
    self.RightBtnGroup.gameObject:SetActiveEx(value)
    self.TopControl.gameObject:SetActiveEx(value)
    XDataCenter.GuildDormManager.SetIsHideUi(not value)
end

function XUiGuildDormMain:SetComponentsClose(value, withOperation)
    if withOperation == nil then
        withOperation = false
    end
    self.BtnTabMember.gameObject:SetActiveEx(value)
    self.BtnTabChallenge.gameObject:SetActiveEx(value)
    self.BtnTabGift.gameObject:SetActiveEx(value)
    self.BtnHelp.gameObject:SetActiveEx(value)
    self.BtnSwitchGuild.GameObject:SetActiveEx(value)
    self.BtnGift.gameObject:SetActiveEx(value)
    if value then
        if XDataCenter.GuildWarManager.CheckActivityIsInTime() then
            self.BtnGuildWarEntry.gameObject:SetActiveEx(true)
        end
    else
        self.BtnGuildWarEntry.gameObject:SetActiveEx(false)
    end
    if withOperation then
        self.UiPanelOperation.GameObject:SetActiveEx(value)
        self.UiPanelOperation:SetIsCanMove(value)
        self.BtnUI.gameObject:SetActiveEx(value)
        if value then
            self.TopController:ShowUi()
        else
            self.TopController:HideUi()
        end
        self.BtnPeople.gameObject:SetActiveEx(value)
        self.BtnAct.gameObject:SetActiveEx(value)
        self.BtnCamera.gameObject:SetActiveEx(value)
    else
        self.UiPanelOperation.GameObject:SetActiveEx(true)
        self.UiPanelOperation:SetIsCanMove(true)
        self.BtnUI.gameObject:SetActiveEx(true)
        self.TopController:ShowUi()
        self.BtnPeople.gameObject:SetActiveEx(true)
        self.BtnAct.gameObject:SetActiveEx(true)
        self.BtnCamera.gameObject:SetActiveEx(true)
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
    if not room then
        return
    end
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
    if XPlayer.Id ~= playerId or actionId <= 0 then
        return
    end
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

function XUiGuildDormMain:OnCheckGuildWarEntryRedPoint(count)
    self.BtnGuildWarEntry:ShowReddot(count >= 0)
end

function XUiGuildDormMain:OnSwitchPhotographModel(isPhotographModel)
    self.PanelRightBtn.gameObject:SetActiveEx(not isPhotographModel)
    self.UiPanelPhotograph.GameObject:SetActiveEx(isPhotographModel)
    self.BtnCamera.gameObject:SetActiveEx(not isPhotographModel)
    -- 拍照模式下不显示（显示界面按钮）Ui
    self.UiPanelUiSetting:PanelUIEnable(not isPhotographModel)
    -- 拍照模式下Npc不显示交互按钮
    self.UiPanelOperation:SetPhotographModel(isPhotographModel)
end

function XUiGuildDormMain:PhotographUiEnable(value)
    if value then
        self.TopController:ShowUi()
    else
        self.TopController:HideUi()
    end
    self.UiPanelOperation:SetIsCanMove(value)
    self.UiPanelOperation.GameObject:SetActiveEx(value)
    self.BtnUI.gameObject:SetActiveEx(value)
    self.BtnPeople.gameObject:SetActiveEx(value)
    self.BtnAct.gameObject:SetActiveEx(value)
end