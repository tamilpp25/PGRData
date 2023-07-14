local XUiMainDown = require("XUi/XUiMain/XUiMainDown")

local XUiMain = XLuaUiManager.Register(XLuaUi, "UiMain")

local CameraIndex = {
    Main = 1,
    MainEnter = 2,
    MainChatEnter = 3,
}

local MenuType = {
    Main = 1,
    Second = 2,
}

XUiMain.LowPowerState = {
    Full = 1,
    Low = 2,
    LowToFull = 3,
    FullToLow = 4,
}

local RightMidType = MenuType.Main

function XUiMain:OnAwake()
    --BDC
    CS.XHeroBdcAgent.BdcIntoGame(CS.UnityEngine.Time.time)

    self.RightTop =    XUiMainRightTop.New(self)           --右上角组件（资源、电量、时间、设置、邮件……）
    self.RightMid =    XUiMainRightMid.New(self)           --右中角组件（各种功能……）
    
    self.RightMidSecond = XUiMainRightMidSecond.New(self)   -- 右中角二级菜单
    self.RightBottom = XUiMainRightBottom.New(self)        --右下角组件（各个大功能入口……）
    
    self.LeftTop =    XUiMainLeftTop.New(self)            --左上角组件（玩家信息……）
    self.LeftMid =    XUiMainLeftMid.New(self)            --左中角组件（自动战斗、过期提醒……）
    self.LeftBottom = XUiMainLeftBottom.New(self)         --左下角组件（公告、好友、福利、AD、聊天……）
    self.Other =        XUiMainOther.New(self)              --其他组件（角色触摸、截图……）
    self.Down =       XUiMainDown.New(self, self.PanelDown)                 --底部组件（战斗通行证……）
    -- self.AreanOnline = XUiPanelArenaOnline.New(self, self.PanelArenaOnline)  --屏蔽合众战局
    
    self.PreEnterFightCallback = function() self:OnPreEnterFight() end
    XEventManager.AddEventListener(XEventId.EVENT_PRE_ENTER_FIGHT, self.PreEnterFightCallback)
end

function XUiMain:OnStart()
    -- 注销后重新登录 主界面默认不显示二级菜单
    if XLoginManager.IsFirstOpenMainUi() then
        RightMidType = MenuType.Main
    end
    
    -- 二级菜单切换按钮
    self.BtnMain.CallBack = function() self:OnBtnMain() end
    self.BtnSecond.CallBack = function() self:OnBtnSecond() end

end

function XUiMain:OnEnable()
    if XDataCenter.GuideManager.CheckIsInGuide() then
        RightMidType = MenuType.Main
    end
    if XDataCenter.PokemonManager then
        XDataCenter.PokemonManager.ResetSpeed()
    end
    
    -- 刷新二级菜单
    self:UpdateRightMenu()
    
    -- 每次打开的时候重新加载一下场景
    local curSceneId = XDataCenter.PhotographManager.GetCurSceneId()
    local curSceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(curSceneId)
    local curSceneUrl, _ = XSceneModelConfigs.GetSceneAndModelPathById(curSceneTemplate.SceneModelId)
    local modelUrl = self:GetDefaultUiModelUrl()
    self:LoadUiScene(curSceneUrl, modelUrl, function() self:OnUiSceneLoaded(curSceneTemplate.ParticleGroupName) end, false)

    self:PlayEnterAnim()
    XRedPointManager.AutoReleseRedPointEvent()
    self.LeftTop:OnEnable()
    self.LeftMid:OnEnable()
    self.LeftBottom:OnEnable()
    self.RightMid:OnEnable()
    self.RightMidSecond:OnEnable()
    self.RightTop:OnEnable()
    self.RightBottom:OnEnable()
    self.Other:OnEnable()
    self:SetCacheFight()
    self:SetScreenAdaptorCache()
    XDataCenter.SetManager.SetSceneUIType()
    self:AreanOnlineInviteNotify()
    self.Down:OnEnable()
end

function XUiMain:OnDisable()
    self.LeftTop:OnDisable()
    self.LeftMid:OnDisable()
    self.LeftBottom:OnDisable()
    self.RightMid:OnDisable()
    self.RightMidSecond:OnDisable()
    self.Other:OnDisable()
    self.RightBottom:OnDisable()
    self.RightTop:OnDisable()
    self.Down:OnDisable()
end

function XUiMain:OnDestroy()
    self.LeftBottom:OnDestroy()
    self.Other:OnDestroy()
    self.RightTop:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_PRE_ENTER_FIGHT, self.PreEnterFightCallback)
end

function XUiMain:OnNotify(evt, ...)
    if evt == XEventId.EVENT_CHAT_OPEN then
        --打开聊天界面
        self:PlayMainChatIn()
    elseif evt == XEventId.EVENT_CHAT_CLOSE then
        --聊天界面关闭
        self:PlayMainChatOut()
    elseif evt == XEventId.EVENT_CHAT_RECEIVE_PRIVATECHAT then
        -- self.AreanOnline:Show(...)
    elseif evt == XEventId.EVENT_GUIDE_START then
        -- 进行新手引导时，切换显示为主菜单
        self:OnBtnMain()
    end

    self.LeftBottom:OnNotify(evt)
    self.RightMid:OnNotify(evt)
    self.RightTop:OnNotify(evt)
end

function XUiMain:OnPreEnterFight()
    self:LoadUiScene("" , "") -- 释放主界面角色场景
end

function XUiMain:AreanOnlineInviteNotify()
    local chatdata = XDataCenter.ArenaOnlineManager.GetPrivateChatData()
    if not chatdata or not next(chatdata)then
        return 
    end

    XLuaUiManager.Open("UiArenaOnlineInvitation")
end  

function XUiMain:OnGetEvents()
    return {
        XEventId.EVENT_CHAT_OPEN,
        XEventId.EVENT_CHAT_CLOSE,
        XEventId.EVENT_NOTICE_PIC_CHANGE,
        XEventId.EVENT_TASKFORCE_INFO_NOTIFY,
        XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE,
        XEventId.EVENT_MAIL_COUNT_CHANGE,
        XEventId.EVENT_CHAT_RECEIVE_PRIVATECHAT,
        XEventId.EVENT_GUIDE_START,
    }
end

--初始化摄像机
function XUiMain:InitSceneRoot(particleGroupName)
    local root = self.UiModelGo.transform
    self.CameraFar = {
        [CameraIndex.Main] = self:FindVirtualCamera("CamFarMain"),
        [CameraIndex.MainEnter] = self:FindVirtualCamera("CamFarMainEnter"),
        [CameraIndex.MainChatEnter] = self:FindVirtualCamera("CamFarMainChatEnter"),
    }
    self.CameraNear = {
        [CameraIndex.Main] = self:FindVirtualCamera("CamNearMain"),
        [CameraIndex.MainEnter] = self:FindVirtualCamera("CamNearMainEnter"),
        [CameraIndex.MainChatEnter] = self:FindVirtualCamera("CamNearMainChatEnter"),
    }

    --主页面电量特效相关
    local sceneRoot = self.UiSceneInfo.Transform
    if particleGroupName and particleGroupName ~= "" then
        self.ChargeAnimator = sceneRoot:FindTransform(particleGroupName):GetComponent("Animator")
    else
        self.ChargeAnimator = nil
    end
    self.ToChargePD = sceneRoot:Find("Animations/ToChargeTimeLine")
    self.ToFullPD = sceneRoot:Find("Animations/ToFullTimeLine")
    self.FullPD = sceneRoot:Find("Animations/FullTimeLine")
    self.ChargePD = sceneRoot:Find("Animations/ChargeTimeLine")
end

function XUiMain:ChangeLowPowerPartical(state)
    if self.ChargeAnimator then
        if state == self.LowPowerState.Full then
            self.ChargeAnimator:Play("Full")
        elseif state == self.LowPowerState.Low then
            self.ChargeAnimator:Play("Low")
        elseif state == self.LowPowerState.LowToFull then
            self.ChargeAnimator:Play("LowToFull")
        elseif state == self.LowPowerState.FullToLow then
            self.ChargeAnimator:Play("FullToLow")
        end
    end
end

function XUiMain:ChangeLowPowerTimeLine(state)
    if self.ToChargePD then self.ToChargePD.gameObject:SetActiveEx(false) end
    if self.ToFullPD then self.ToFullPD.gameObject:SetActiveEx(false) end
    if self.FullPD then self.FullPD.gameObject:SetActiveEx(false) end
    if self.ChargePD then self.ChargePD.gameObject:SetActiveEx(false) end

    if state == self.LowPowerState.Full then
        if self.FullPD then self.FullPD.gameObject:SetActiveEx(true) end
    elseif state == self.LowPowerState.Low then
        if self.ChargePD then self.ChargePD.gameObject:SetActiveEx(true) end
    elseif state == self.LowPowerState.LowToFull then
        if self.ToFullPD then self.ToFullPD.gameObject:SetActiveEx(true) end
    elseif state == self.LowPowerState.FullToLow then
        if self.ToChargePD then self.ToChargePD.gameObject:SetActiveEx(true) end
    end
end

function XUiMain:ChangeLowPowerState(state)
    self:ChangeLowPowerPartical(state)
    self:ChangeLowPowerTimeLine(state)
end

function XUiMain:UpdateCamera(camera)
    for _, cameraIndex in pairs(CameraIndex) do
        self.CameraNear[cameraIndex].gameObject:SetActive(cameraIndex == camera)
        self.CameraFar[cameraIndex].gameObject:SetActive(cameraIndex == camera)
    end
end

function XUiMain:UpdateRightMenu()
    -- 根据状态控制右侧面板的显隐

    self.BtnSecond.gameObject:SetActiveEx(RightMidType == MenuType.Main)
    self.PanelRightBottom.gameObject:SetActiveEx(RightMidType == MenuType.Main)
    self.PanelRightMid.gameObject:SetActiveEx(RightMidType == MenuType.Main)

    self.BtnMain.gameObject:SetActiveEx(RightMidType == MenuType.Second)
    self.PanelRightMidSecond.gameObject:SetActiveEx(RightMidType == MenuType.Second)
    
    if RightMidType == MenuType.Second then
        self.RightMidSecond:RefreshMenu()
    end
end

--播放主界面打开动画
function XUiMain:PlayEnterAnim()
    local anim, endCb
    if XLoginManager.IsFirstOpenMainUi() then
        anim = "AnimEnter"
    else
        anim = "AnimReenter"
    end
    XLuaUiManager.SetMask(true)
    endCb = function()
        if XLoginManager.IsFirstOpenMainUi() then
            anim = "AnimEnter2"
            self:PlayAnimation(anim, endCb)
            self:UpdateCamera(CameraIndex.Main)
            XLoginManager.SetFirstOpenMainUi(false)
        else
            XLoginManager.SetStartGuide(true)
            XEventManager.DispatchEvent(XEventId.EVENT_MAINUI_ENABLE)
            XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
            XLuaUiManager.SetMask(false)
        end
    end
    self:PlayAnimation(anim, endCb)
end

--播放关闭聊天动画
function XUiMain:PlayMainChatOut()
    self:UpdateCamera(CameraIndex.Main)
    self:PlayAnimation("AnimChatIn")
end

--播放打开聊天动画
function XUiMain:PlayMainChatIn()
    self:UpdateCamera(CameraIndex.MainChatEnter)
    self:PlayAnimation("AnimChatOut")
end

function XUiMain:SetCacheFight()
    if not self.IsFirstSetFight then
        self.IsFirstSetFight = true
        XDataCenter.SetManager.SetAllyDamageByCache()
        XDataCenter.SetManager.SetAllyEffectByCache()
        XDataCenter.SetManager.SetOwnFontSizeByCache()
        XDataCenter.SetManager.SetDefaultFontSize()
        XDataCenter.SetManager.SetScreenOff()
    end
end

function XUiMain:SetScreenAdaptorCache()
    if XDataCenter.SetManager.IsAdaptorScreen() and not XTool.UObjIsNil(self.SafeAreaContentPane) then
        self.SafeAreaContentPane:UpdateSpecialScreenOff()
    end
end

-- 设置福利按钮特效可见性
function XUiMain:SetBtnWelfareTagActive(active)
    self.LeftBottom:SetBtnWelfareTagActive(active)
end

-- 回到主页按钮
function XUiMain:OnBtnMain()
    if RightMidType == MenuType.Main then return end

    RightMidType = MenuType.Main

    self.BtnSecond.gameObject:SetActiveEx(true)
    self.BtnMain.gameObject:SetActiveEx(false)
    
    self.PanelRightBottom.gameObject:SetActiveEx(true)
    self.PanelRightMid.gameObject:SetActiveEx(true)
    
    self:PlayAnimationWithMask("AnimPanelRightMid", function()
        self.PanelRightMidSecond.gameObject:SetActiveEx(false)
    end)
end

-- 下一页按钮（主界面二级菜单）
function XUiMain:OnBtnSecond()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SubMenu) then return end
    RightMidType = MenuType.Second
    self.RightMidSecond:RefreshMenu()
    
    self.BtnMain.gameObject:SetActiveEx(true)
    self.BtnSecond.gameObject:SetActiveEx(false)
    self.PanelRightMidSecond.gameObject:SetActiveEx(true)
    
    self:PlayAnimationWithMask("AnimPanelRightMidSecond", function()
        self.PanelRightMid.gameObject:SetActiveEx(false)
        self.PanelRightBottom.gameObject:SetActiveEx(false)
    end)
end

function XUiMain:OnUiSceneLoaded(particleGroupName)
    self:SetGameObject()
    self:InitSceneRoot(particleGroupName)
    self.Other.SignBoard = XUiPanelSignBoard.New(self.Other.PanelSignBoard, self, XUiPanelSignBoard.SignBoardOpenType.MAIN)
    if XLoginManager.IsFirstOpenMainUi() then
        self:SetBtnWelfareTagActive(false)
        self:UpdateCamera(CameraIndex.MainEnter)
    else
        self:UpdateCamera(CameraIndex.Main)
    end
end