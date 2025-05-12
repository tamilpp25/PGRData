--local XUiMainDown = require("XUi/XUiMain/XUiMainDown")
local XUiMainRightTop = require("XUi/XUiMain/XUiMainRightTop")
local XUiMainRightMid = require("XUi/XUiMain/XUiMainRightMid")
local XUiMainLeftTop = require("XUi/XUiMain/XUiMainLeftTop")
--local XUiMainRightMidSecond = require("XUi/XUiMain/XUiMainRightMidSecond")
local XUiMainRightBottom = require("XUi/XUiMain/XUiMainRightBottom")


--local XUiMainLeftMid = require("XUi/XUiMain/XUiMainLeftMid")
local XUiMainLeftBottom = require("XUi/XUiMain/XUiMainLeftBottom")
local XUiMainOther = require("XUi/XUiMain/XUiMainOther")
local XUiPanelSignBoard = require("XUi/XUiMain/XUiChildView/XUiPanelSignBoard")
local XUiMainLeftCalendar = require("XUi/XUiMain/XUiMainLeftCalendar")
local XUiMainBoardEffect = require("XUi/XUiMain/XUiMainBoardEffect")

---@class XUiMain : XLuaUi
local XUiMain = XLuaUiManager.Register(XLuaUi, "UiMain")

local CameraIndex = {
    Main = 1,
    MainEnter = 2,
    MainChatEnter = 3,
    MainRightMidSecondEnter = 4,
    MainLeftCalendarEnter = 5,
}

local MenuType = {
    Main = 1,
    Second = 2,
    Calendar = 3,
}

XUiMain.LowPowerState = {
    Full = 1,
    Low = 2,
    LowToFull = 3,
    FullToLow = 4,
    None = 5
}

local RightMidType = MenuType.Main
local InitBackgroundScreenCapture = false

function XUiMain:InitPanel()
    ---@type XUiMainRightTop
    self.RightTop =    XUiMainRightTop.New(self.PanelRightTop.transform, self, self)           --右上角组件（资源、电量、时间、设置、邮件……）
    self.RightMid =    XUiMainRightMid.New(self.PanelRightMid, self, self)           --右中角组件（各种功能……）

    --self.RightMidSecond = XUiMainRightMidSecond.New(self)   -- 右中角二级菜单
    self.RightBottom = XUiMainRightBottom.New(self.PanelRightBottom.transform, self, self)        --右下角组件（各个大功能入口……）
    ---@type XUiMainLeftTop
    self.LeftTop =    XUiMainLeftTop.New(self.PanelLeftTop, self, self)            --左上角组件（玩家信息……）
    --self.LeftMid =    XUiMainLeftMid.New(self.PanelLeftMid.transform, self)            --左中角组件（自动战斗、过期提醒……）
    self.LeftBottom = XUiMainLeftBottom.New(self.PanelLeftBottom.transform, self)         --左下角组件（公告、好友、福利、AD、聊天……）
    ---@type XUiMainOther
    self.Other =        XUiMainOther.New(self.PanelOther.transform, self, self)              --其他组件（角色触摸、截图……）
    --self.Down =    XUiMainDown.New(self.PanelDown, self, self)                 --底部组件（战斗通行证……）
    self.Terminal = require("XUi/XUiMain/XUiMainTerminal").New(self.PanelRightMidSecond.transform, self, self) --终端界面
    ---@type XUiMainLeftCalendar
    self.Calendar = XUiMainLeftCalendar.New(self.PanelLeftCalendar, self) --周历界面
    ---@type XUiPanelCharacterCG
    self.CG = require("XUi/XUiCharacterCG/XUiPanelCharacterCG").New(self.PanelVideo, self)
    ---@type XUiMainBoardEffect
    self.MainBoardEffect = XUiMainBoardEffect.New(self)
    
    -- self.AreanOnline = XUiPanelArenaOnline.New(self, self.PanelArenaOnline)  --屏蔽合众战局
end

function XUiMain:OnAwake()
    
    self._IsClose = false
    self._IsPlayingEnterAnima = false
   
    self.PreEnterFightCallback = function() self:OnPreEnterFight() end
    XEventManager.AddEventListener(XEventId.EVENT_PRE_ENTER_FIGHT, self.PreEnterFightCallback)
    
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UIMAIN_RIGHTMIDTYPE_CHANGE, self.ForceChangeUiMainRightMidType, self)

    --self.Down.GameObject:SetActiveEx(not XUiManager.IsHideFunc)
    self.PanelLeftBottom.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
end

function XUiMain:OnStart()
    self:InitPanel()
    self:InitTheme()
    -- 注销后重新登录 主界面默认不显示二级菜单
    if XLoginManager.IsFirstOpenMainUi() then
        RightMidType = MenuType.Main
    end

    --界面重新打开
    self.NewOpen = true

    if InitBackgroundScreenCapture == false then
        CS.XBlurHelper.GetBlurScreenCapture(CS.XUiManager.Instance.UiCamera,
            CS.XGraphicManager.RenderConst.Ui.PopupBackgroundBlurInfo, function(tex2D)
                CS.UnityEngine.Object.DestroyImmediate(tex2D);
                -- CS.XLog.Debug("----- InitBackgroundScreenCapture")
            end, false);
        InitBackgroundScreenCapture = true
    end

    -- 回到主界面就重置XInputSystem.operationType
    CS.XInputManager.SetCurInputMap(CS.XInputMapId.System)
end

function XUiMain:OnEnable()
    if XDataCenter.GuideManager.CheckIsInGuide() then
        RightMidType = MenuType.Main
    end

    -- 刷新二级菜单
    self:UpdateRightMenu()

    CS.XResourceRecord.Stop();

    XDataCenter.PhotographManager.GetNextRandomSceneId() -- 进行一次场景随机

    local curSceneId = nil
    curSceneId = XDataCenter.PhotographManager.GetCurSceneId()
    if curSceneId ~= self.CurSceneId then
        self.Other:OnChangeSync()
    end
    local curSceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(curSceneId)
    local curSceneUrl, _ = XSceneModelConfigs.GetSceneAndModelPathById(curSceneTemplate.SceneModelId)
    local modelUrl = self:GetDefaultUiModelUrl()
    self.CurSceneId = curSceneId
    --先加载可见界面主题
    self:UpdateTheme()
    XDataCenter.SetManager.SetSceneUIType()
    self:LoadUiScene(curSceneUrl, modelUrl, function() self:OnUiSceneLoaded(curSceneTemplate.ParticleGroupName) end, false)

    self:PlayEnterAnim()
    XRedPointManager.AutoReleaseRedPointEvent()
    -- self.LeftTop:OnEnable()
    -- --self.LeftMid:OnEnable()
    -- self.LeftBottom:OnEnable()
    -- self.RightMid:OnEnable()
    -- --self.RightMidSecond:OnEnable()
    -- self.RightTop:OnEnable()
    -- self.RightBottom:OnEnable()
    -- self.Other:OnEnable()
    -- self.Calendar:OnEnable()
    self.MainBoardEffect:OnEnable()
    self:SetCacheFight()
    self:SetScreenAdaptorCache()
    --self.Down:OnEnable()
    XLoginManager.ResetHearbeatInterval()

    self:AreanOnlineInviteNotify()
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UIMAIN_STATE_CHANGE, self.OnBackGroupPreview, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_RECEIVE_INVITE, self.OnDlcReceiveInvite, self)
    XMVCA.XFavorability:AddRoleActionUiAnimListener(self)
    if not XLoginManager.IsFirstOpenMainUi() then
        self:PlayEquipGuide(false)
    end

    -- 开启时钟
    self.ClockTimer = XUiHelper.SetClockTimeTempFun(self)
    CS.XUwaGpmLuaAgent.ChangeScene("UiMain")
end

function XUiMain:ForceChangeUiMainRightMidType(arg)
    RightMidType = arg
end

function XUiMain:OnDisable()
    -- self.LeftTop:OnDisable()
    --self.LeftMid:OnDisable()
    -- self.LeftBottom:OnDisable()
    -- self.RightMid:OnDisable()
    -- --self.RightMidSecond:OnDisable()
    -- self.Other:OnDisable()
    -- self.RightBottom:OnDisable()
    -- self.RightTop:OnDisable()
    -- self.Terminal:Close()
    -- self.Calendar:OnDisable()
    --self.Down:OnDisable()
    self.MainBoardEffect:OnDisable()
    
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UIMAIN_STATE_CHANGE, self.OnBackGroupPreview, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_RECEIVE_INVITE, self.OnDlcReceiveInvite, self)
    XMVCA.XFavorability:RemoveRoleActionUiAnimListener(self)
    --界面重新打开
    self.NewOpen = false
    self:ClearSceneReference()

    -- 关闭时钟
    if self.ClockTimer then
        XUiHelper.StopClockTimeTempFun(self, self.ClockTimer)
        self.ClockTimer = nil
    end

    self.HasUpdataThemed = false

    -- 防止ui动画被打断没人开启射线检测
    if not XTool.UObjIsNil(self.SafeAreaContentPane) then
        local cvgp = self.SafeAreaContentPane.transform:GetComponent("CanvasGroup")
        if not XTool.UObjIsNil(cvgp) then
            cvgp.blocksRaycasts = true
        end
    end

    XEventManager.DispatchEvent(XEventId.EVENT_SCENE_UIMAIN_DISABLE)
end

function XUiMain:OnDestroy()
    self.LeftBottom:OnDestroy()
    self.Other:OnDestroy()
    self.RightTop:OnDestroy()
    self.LeftTop:OnDestroy()
    self.RightBottom:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_PRE_ENTER_FIGHT, self.PreEnterFightCallback)
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UIMAIN_RIGHTMIDTYPE_CHANGE, self.ForceChangeUiMainRightMidType, self)
    self._IsClose = true
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
        self:OnShowMain()
    elseif evt == XEventId.EVENT_SCENE_SET_NONE_STATE then
        self:ChangeLowPowerState(self.LowPowerState.None)
    elseif evt == CS.XEventId.EVENT_VIDEO_PLAYER_STATUS_PLAYING then
        if not self.CG:IsLanguagePreparing() then
            self.CG:OnCGPlay()
        end
    elseif evt == CS.XEventId.EVENT_VIDEO_PLAYER_STATUS_PLAYEND then
        self.CG:OnCGStop()
    end

    self.LeftBottom:OnNotify(evt)
    self.RightMid:OnNotify(evt)
    self.RightTop:OnNotify(evt)
end

function XUiMain:OnPreEnterFight()
    self:LoadUiScene("", "") -- 释放主界面角色场景
end

function XUiMain:AreanOnlineInviteNotify()
    local chatdata = XDataCenter.ArenaOnlineManager.GetPrivateChatData()
    if not chatdata or not next(chatdata) then
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
        XAgencyEventId.EVENT_MAIL_COUNT_CHANGE,
        XEventId.EVENT_CHAT_RECEIVE_PRIVATECHAT,
        XEventId.EVENT_GUIDE_START,
        XEventId.EVENT_SCENE_SET_NONE_STATE,
        CS.XEventId.EVENT_VIDEO_PLAYER_STATUS_PLAYING,
        CS.XEventId.EVENT_VIDEO_ACTION_STOP,
        CS.XEventId.EVENT_VIDEO_PLAYER_STATUS_PLAYEND,
    }
end

--初始化摄像机
function XUiMain:InitSceneRoot(particleGroupName)
    local root = self.UiModelGo.transform
    self.CameraFar = {
        [CameraIndex.Main] = self:FindVirtualCamera("CamFarMain"),
        [CameraIndex.MainEnter] = self:FindVirtualCamera("CamFarMainEnter"),
        [CameraIndex.MainChatEnter] = self:FindVirtualCamera("CamFarMainChatEnter"),
        [CameraIndex.MainRightMidSecondEnter] = self:FindVirtualCamera("CamFarMainRightMidSecondEnter"),
        [CameraIndex.MainLeftCalendarEnter] = self:FindVirtualCamera("CamFarTolist"),
    }
    self.CameraNear = {
        [CameraIndex.Main] = self:FindVirtualCamera("CamNearMain"),
        [CameraIndex.MainEnter] = self:FindVirtualCamera("CamNearMainEnter"),
        [CameraIndex.MainChatEnter] = self:FindVirtualCamera("CamNearMainChatEnter"),
        [CameraIndex.MainRightMidSecondEnter] = self:FindVirtualCamera("CamNearMainRightMidSecondEnter"),
        [CameraIndex.MainLeftCalendarEnter] = self:FindVirtualCamera("CamNearTolist"),
    }

    --主页面电量特效相关
    local sceneRoot = self.UiSceneInfo.Transform
    local animationRoot = self.UiSceneInfo.Transform:Find("Animations")
    if XTool.UObjIsNil(animationRoot) then return end

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

--- 清除场景引用，避免场景加载前使用
---@return void
--------------------------
function XUiMain:ClearSceneReference()
    self.CameraFar = nil
    self.CameraNear = nil
    self.ChargeAnimator = nil
    self.ToChargePD = nil
    self.ToFullPD = nil
    self.FullPD = nil
    self.ChargePD = nil
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
    if not XTool.UObjIsNil(self.ToChargePD) then self.ToChargePD.gameObject:SetActiveEx(false) end
    if not XTool.UObjIsNil(self.ToFullPD) then self.ToFullPD.gameObject:SetActiveEx(false) end
    if not XTool.UObjIsNil(self.FullPD) then self.FullPD.gameObject:SetActiveEx(false) end
    if not XTool.UObjIsNil(self.ChargePD) then self.ChargePD.gameObject:SetActiveEx(false) end

    if state == self.LowPowerState.Full then
        if not XTool.UObjIsNil(self.FullPD) then self.FullPD.gameObject:SetActiveEx(true) end
        XDataCenter.PhotographManager.UpdatePreviewState(true, true)
    elseif state == self.LowPowerState.Low then
        if not XTool.UObjIsNil(self.ChargePD) then self.ChargePD.gameObject:SetActiveEx(true) end
        XDataCenter.PhotographManager.UpdatePreviewState(false, true)
    elseif state == self.LowPowerState.LowToFull then
        if not XTool.UObjIsNil(self.ToFullPD) then self.ToFullPD.gameObject:SetActiveEx(true) end
        XDataCenter.PhotographManager.UpdatePreviewState(true, true)
    elseif state == self.LowPowerState.FullToLow then
        if not XTool.UObjIsNil(self.ToChargePD) then self.ToChargePD.gameObject:SetActiveEx(true) end
        XDataCenter.PhotographManager.UpdatePreviewState(false, true)
    end
end

function XUiMain:ChangeLowPowerState(state)
    self:ChangeLowPowerPartical(state)
    self:ChangeLowPowerTimeLine(state)
end

function XUiMain:UpdateCamera(camera)
    if not self.CameraFar or not self.CameraNear then
        return
    end
    for _, cameraIndex in pairs(CameraIndex) do
        local nearCamera = self.CameraNear[cameraIndex]
        if not XTool.UObjIsNil(nearCamera) then
            nearCamera.gameObject:SetActive(cameraIndex == camera)
        end
        local farCamera = self.CameraFar[cameraIndex]
        if not XTool.UObjIsNil(farCamera) then
            farCamera.gameObject:SetActive(cameraIndex == camera)
        end
    end
end

function XUiMain:UpdateRightMenu()
    if self:IsShowTerminal() then
        self:OnShowTerminal()
    elseif self:IsShowCalendar() then
        self:OnShowCalendar()
    else
        self:OnShowMain()
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
    self._IsPlayingEnterAnima = true
    endCb = function()
        if self._IsClose then
            return
        end
        self._IsPlayingEnterAnima = false
        if XLoginManager.IsFirstOpenMainUi() then
            anim = "AnimEnter2"
            self:PlayAnimation(anim, endCb)
            self:UpdateCamera(CameraIndex.Main)
            self:PlayEquipGuide(true)
            XLoginManager.SetFirstOpenMainUi(false)
            --第一次进入界面，拦截公告请求
            self.InterceptNotice = true
            XEventManager.DispatchEvent(XEventId.EVENT_FIRST_ENTER_UI_MAIN)
        else
            XLoginManager.SetStartGuide(true)
            XEventManager.DispatchEvent(XEventId.EVENT_MAINUI_ENABLE)
            XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
            XLuaUiManager.SetMask(false)
            -- if XDataCenter.UiPcManager.IsPc() then 
            --     CS.XPCCheat.BeginCheatCheck()
            -- end
            
            -- if XDataCenter.DlcRoomManager.IsCanReconnect() then
            --     XDataCenter.DlcRoomManager.DialogReconnect()
            -- end
            --- 打开邀请界面
            self:OnDlcReceiveInvite()
            --发送公告请求
            self:UpdateNotice()
            --取消拦截公告
            self.InterceptNotice = false
            --动画播放完，再加载剩余主题
            self:UpdateTheme()
        end
    end
    
    self:PlayAnimation(anim, endCb)
end

--播放关闭聊天动画
function XUiMain:PlayMainChatOut()
    self:SetSignPanelEnable(true)
    self:UpdateCamera(CameraIndex.Main)
    self:PlayAnimation("AnimChatIn")
end

--播放打开聊天动画
function XUiMain:PlayMainChatIn()
    self:SetSignPanelEnable(false)
    self.Other:Stop()
    self:UpdateCamera(CameraIndex.MainChatEnter)
    self:PlayAnimation("AnimChatOut")
end

--播放装备目标动画
function XUiMain:PlayEquipGuide(isFirst)
    local isSetEquipTarget = XDataCenter.EquipGuideManager.IsSetEquipTarget()
    if not isSetEquipTarget then
        return
    end
    local anim = isFirst and "EquipGuideEnableLong" or "EquipGuideEnableShort"
    self:PlayAnimation(anim, function()
        self.RightMid:SetBtnEquipGuideState(false)
    end, function() 
        self.RightMid:SetBtnEquipGuideState(true)
    end)
end

function XUiMain:SetCacheFight()
    if not self.IsFirstSetFight then
        self.IsFirstSetFight = true
        XDataCenter.SetManager.SetAllyDamageByCache()
        XDataCenter.SetManager.SetAllyEffectByCache()
        XDataCenter.SetManager.SetOwnFontSizeByCache()
        XDataCenter.SetManager.SetDefaultFontSize()
        XDataCenter.SetManager.SetDefaultNumStyleByCache()
        XDataCenter.SetManager.InitFightCameraVibration()
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
function XUiMain:OnShowMain(playAnimation)
    self:SetSignPanelEnable(true)
    self:UpdateCamera(CameraIndex.Main)
    --终端界面由隐藏变为显示不需要播放动画。重新打开界面则需要播一次
    playAnimation = playAnimation or self.NewOpen
    if playAnimation then
        if self:IsShowTerminal() then
            self:PlayAnimationWithMask("RightMidSecondDisable")
            self.Terminal:Close()
        end
        if self:IsShowCalendar() then
            self:PlayAnimationWithMask("LeftCalendarDisable", function()
                self.Calendar:Close()
            end)
        end
    end
    self:PlayAnimation("RightEnable")
    self:PlayAnimation("LeftUiEnable")
    RightMidType = MenuType.Main
    XEventManager.DispatchEvent(XEventId.EVENT_MAINUI_RIGHT_MENU_STATUS_CHANGE, RightMidType)
end

-- 下一页按钮（主界面二级菜单）
function XUiMain:OnShowTerminal(playAnimation)
    self.Other:ForceStop()
    self:SetSignPanelEnable(false)
    self:UpdateCamera(CameraIndex.MainRightMidSecondEnter)
    --终端界面由隐藏变为显示不需要播放动画。重新打开界面则需要播一次
    playAnimation = playAnimation or self.NewOpen
    if playAnimation then
        self:PlayAnimationWithMask("RightMidSecondEnable")
        self:PlayAnimation("RightDisable")
        self:PlayAnimation("LeftUiDisable")
    end
    RightMidType = MenuType.Second
    self.Terminal:Open()
    XEventManager.DispatchEvent(XEventId.EVENT_MAINUI_RIGHT_MENU_STATUS_CHANGE, RightMidType)
end

-- 打开周历（主界面二级菜单）
function XUiMain:OnShowCalendar(playAnimation)
    self:SetSignPanelEnable(false)
    self.Other:Stop()
    self:UpdateCamera(CameraIndex.MainLeftCalendarEnter)
    --终端界面由隐藏变为显示不需要播放动画。重新打开界面则需要播一次
    playAnimation = playAnimation or self.NewOpen
    if playAnimation then
        self:PlayAnimationWithMask("LeftCalendarEnable")
        self:PlayAnimation("LeftUiDisable")
        self:PlayAnimation("RightDisable")
    end
    self.Calendar:Open()
    RightMidType = MenuType.Calendar
    XEventManager.DispatchEvent(XEventId.EVENT_MAINUI_RIGHT_MENU_STATUS_CHANGE, RightMidType)
end

function XUiMain:OnUiSceneLoaded(particleGroupName)
    --self:SetGameObject()
    self:InitSceneRoot(particleGroupName)
    --self.Other.SignBoard = XUiPanelSignBoard.New(self.Other.PanelSignBoard, self, XUiPanelSignBoard.SignBoardOpenType.MAIN)
    self.Other:SafeCreateSignBoard()
    if XLoginManager.IsFirstOpenMainUi() then
        self:SetBtnWelfareTagActive(false)
        self:UpdateCamera(CameraIndex.MainEnter)
    else
        local camera = CameraIndex.Main
        if self:IsShowTerminal() then
            camera = CameraIndex.MainRightMidSecondEnter
        elseif self:IsShowCalendar() then
            camera = CameraIndex.MainLeftCalendarEnter
        end
        self:UpdateCamera(camera)
    end
end

function XUiMain:IsShowTerminal()
    return RightMidType == MenuType.Second or (self.PanelRightMidSecond.gameObject and self.PanelRightMidSecond.gameObject.activeInHierarchy)
end

function XUiMain:IsShowCalendar()
    return RightMidType == MenuType.Calendar
end

function XUiMain:IsShowMain()
    return RightMidType == MenuType.Main
end

function XUiMain:PlayChangeModelEffect()
    self.ChangeActionEffect = self.UiModelGo.transform:FindTransform("ChangeActionEffect")
    if not self.ChangeActionEffect or XTool.UObjIsNil(self.ChangeActionEffect) then return end
    self.ChangeActionEffect.gameObject:SetActiveEx(false)
    self.ChangeActionEffect.gameObject:SetActiveEx(true)
end

-- v1.29 预览状态下切换
function XUiMain:OnBackGroupPreview()
    if XDataCenter.PhotographManager.GetPreviewState() == XPhotographConfigs.BackGroundState.Full then --满电状态
        self:ChangeLowPowerState(self.LowPowerState.Full)
    else
        self:ChangeLowPowerState(self.LowPowerState.Low)
    end
end

-- Dlc新邀请界面
function XUiMain:OnDlcReceiveInvite()
    if not self._IsPlayingEnterAnima then
        XMVCA.XDlcRoom:CheckReceiveInvitation()
    end
end

-- v1.32 播放角色特殊动作Ui动画
-- ===================================================

function XUiMain:PlayRoleActionUiDisableAnim(signBoardid, stopTime)
    if XMVCA.XFavorability:CheckIsUseNoneUiAnim(signBoardid, self.Name) then
        return
    end
    self.IsInFullScreenCharacterAction = true
    -- XMVCA.XFavorability:StartBreakTimer(stopTime)

    XLuaUiManager.OpenWithCloseCallback("UiFullScreenCharacterActionBreakTip", function ()
        self:PlayRoleActionUiBreakAnim()
    end)

    -- 关闭福利按钮特效
    self:SetBtnWelfareTagActive(false)
    if XMVCA.XFavorability:CheckCurSceneAnimIsGachaLamiya() then
        XEventManager.DispatchEvent(XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_BEGIN)
        self:PlayAnimation("UiDisableLamiya")
    end
    if XMVCA.XFavorability:CheckIsUseNormalUiAnim(signBoardid, self.Name) then
        XEventManager.DispatchEvent(XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_BEGIN)
        self:PlayAnimation("UiDisable")
    end
end

function XUiMain:PlayRoleActionUiEnableAnim(signBoardid)
    self.IsInFullScreenCharacterAction = false

    -- 检查福利按钮特效
    self.LeftBottom:OnRefreshFirstRechargeId()
    if XMVCA.XFavorability:CheckCurSceneAnimIsGachaLamiya() then
        self:PlayAnimation("UiEnableLamiya", function()
            XEventManager.DispatchEvent(XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_END)
        end)
    elseif XMVCA.XFavorability:CheckIsUseNormalUiAnim(signBoardid, self.Name) then
        self:PlayAnimationWithMask("UiEnable", function()
            XEventManager.DispatchEvent(XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_END)
        end)
    end
end

function XUiMain:PlayRoleActionUiBreakAnim()
    if not self.IsInFullScreenCharacterAction then
        return
    end

    if self.CG:IsCGPlaying() then
        self.Other:ForceStopAnim() -- 先结束动作 否则CG结束时有一瞬间能看到动作在切换
        self.CG:StopCG(false, function()
            self.Other:Stop()
            XEventManager.DispatchEvent(XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_BREAK)
        end)
        self.LeftBottom:OnRefreshFirstRechargeId()
    else
        self:PlayAnimationWithMask("DarkEnable", function()
            self.Other:Stop()
            self:PlayAnimationWithMask("DarkDisable", function()
                XEventManager.DispatchEvent(XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_BREAK)
            end)
            -- 检查福利按钮特效
            self.LeftBottom:OnRefreshFirstRechargeId()
        end)
    end
end

-- 禁用角色动作
function XUiMain:SetSignPanelEnable(enable)
    self.Other:SetSignBoardEnable(enable)
end

---@return XUiPanelRoleModel
function XUiMain:GetRoleModel()
    return self.Other:GetRoleModel()
end

-- ===================================================

--- 每次返回主界面检查是否需要弹出公告
--------------------------
function XUiMain:UpdateNotice()
    if self:IsShowTerminal() or self:IsShowCalendar() or XLoginManager.IsFirstOpenMainUi() 
            or self.InterceptNotice then
        return
    end
    
    XDataCenter.NoticeManager.RequestInGameNotice(function()
        if XLuaUiManager.GetTopUiName() == "UiMain" then
            XDataCenter.NoticeManager.AutoOpenInGameNotice()
        end
    end)
end

--region   ------------------UI主题 start-------------------
function XUiMain:UpdateTheme()
    if self.HasUpdataThemed then
        return
    end

    if not XTool.IsNumberValid(self.CurSceneId) then
        return
    end

    if self.CurSceneId == self._LastSceneId then
        return
    else
        self._LastSceneId = self.CurSceneId
    end
   
    local curSceneId = self.CurSceneId
    local theme = XUiConfigs.GetUiTheme(curSceneId)
    
    local colors = {}
    for _, colorStr in ipairs(theme.Color) do
        local color = XUiHelper.Hexcolor2Color(colorStr)
        table.insert(colors, color)
    end
    
    ---@type ThemeData
    local themeTemplate = {
        Colors = colors,
        Backgrounds = theme.Background,
        Effects = theme.Effect,
    }
    self.LeftBottom:UpdateTheme(themeTemplate)
    self.LeftTop:UpdateTheme(themeTemplate)
    self.Other:UpdateTheme(themeTemplate)
    self.RightBottom:UpdateTheme(themeTemplate)
    self.RightMid:UpdateTheme(themeTemplate)
    self.RightTop:UpdateTheme(themeTemplate)
    self.Terminal:UpdateTheme(themeTemplate)
    self.Calendar:UpdateTheme(themeTemplate)

    self.HasUpdataThemed = true
end

function XUiMain:InitTheme()
    self.LeftBottom:InitTheme()
    self.LeftTop:InitTheme()
    self.Other:InitTheme()
    self.RightBottom:InitTheme()
    self.RightMid:InitTheme()
    self.RightTop:InitTheme()
    self.Terminal:InitTheme()
    self.Calendar:InitTheme()
end 
--endregion------------------UI主题 finish------------------

--region CG

function XUiMain:TryPlayCG(fashionId, id)
    if XMVCA.XFavorability:CheckCGBoardAct(fashionId, id) then
        self:HideBoardEffect()
        if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.Android then
            self.CG:PlayCG(1015301)
        else
            self.CG:PlayCG(10153)
        end
    end
end

--endregion

--region BoardEffect

-- 获取角色模型Transform
---@return UnityEngine.Transform
function XUiMain:GetRoleModelTransform()
    return self.Other:GetRoleModelTransform()
end

-- 刷新角色之前
function XUiMain:OnRefreshRoleBefore()
    self:HideBoardEffect()
end

-- 隐藏特效
function XUiMain:HideBoardEffect()
    if self.MainBoardEffect then
        self.MainBoardEffect:HideEffect()
    end
end

--endregion
