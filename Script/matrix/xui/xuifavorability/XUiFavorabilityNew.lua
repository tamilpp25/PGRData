local XUiFavorabilityNew = XLuaUiManager.Register(XLuaUi, "UiFavorabilityNew")
local XUiPanelSignBoard = require("XUi/XUiMain/XUiChildView/XUiPanelSignBoard")
local XUiPanelFavorabilityMain =require("XUi/XUiFavorability/XUiPanelFavorabilityMain")
local XUiPanelFavorabilityExchangeRole=require("XUi/XUiFavorability/XUiPanelFavorabilityExchangeRole")

local XUiMainPanelBase = require("XUi/XUiMain/XUiMainPanelBase")

local XFavorabilityType = {
    UILikeMain = 1,
    UILikeSwitchRole = 2,
    UILikeFile = 3,
    UILikePlot = 4,
    UILikeGift = 5,
}

local XQualityManager = CS.XQualityManager.Instance
local LowPowerValue = CS.XGame.ClientConfig:GetFloat("UiMainLowPowerValue")
local DateStartTime = CS.XGame.ClientConfig:GetString("BackgroundChangeTimeStr")
local DateEndTime = CS.XGame.ClientConfig:GetString("BackgroundChangeTimeEnd")
local BatteryComponent = CS.XUiBattery

--region 生命周期

function XUiFavorabilityNew:OnAwake()
    local curSceneId = XDataCenter.PhotographManager.GetCurSceneId()
    local curSceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(curSceneId)
    local curSceneUrl, _ = XSceneModelConfigs.GetSceneAndModelPathById(curSceneTemplate.SceneModelId)
    local modelUrl = self:GetDefaultUiModelUrl()
    self:LoadUiScene(curSceneUrl, modelUrl, function() self:OnUiSceneLoaded() end, false)
    self.ThemeCtrl=XUiMainPanelBase.New(self.PanelTheme,self)
    self.ThemeCtrl:InitTheme(self.PanelTheme.transform)
end


function XUiFavorabilityNew:OnStart(characterId)
    if XTool.IsNumberValid(characterId) then
        if XMVCA.XCharacter:IsOwnCharacter(characterId) then
            self:SetCurrFavorabilityCharacter(characterId)
        end
    end
    self.CvType = CS.XAudioManager.CvType
    self:OpenMainView(true)

    self._Control:BoardMutualRequest()

    local curCharacterId = self:GetCurrFavorabilityCharacter()
    
    self.RedPointSwitchId = self:AddRedPointEvent(self.ImgReddot, nil, self, { XRedPointConditions.Types.CONDITION_FAVORABILITY_RED }, { CharacterId = curCharacterId })
end

function XUiFavorabilityNew:OnEnable()
    if self.SignBoard then
        self.SignBoard:OnEnable()
    end
    self:RefreshSelectedModel()
    if self.FavorabilityMain then
        self.FavorabilityMain:UpdateAllInfos()
    end
    XDataCenter.SignBoardManager.AddRoleActionUiAnimListener(self)

    -- 开启时钟
    self.ClockTimer = XUiHelper.SetClockTimeTempFun(self)

    --刷新主题
    self:UpdateTheme()
end

function XUiFavorabilityNew:OnDisable()
    if self.SignBoard then
        self.SignBoard:OnDisable()
    end
    XDataCenter.SignBoardManager.RemoveRoleActionUiAnimListener(self)

    -- 关闭时钟
    if self.ClockTimer then
        XUiHelper.StopClockTimeTempFun(self, self.ClockTimer)
        self.ClockTimer = nil
    end
end

function XUiFavorabilityNew:OnDestroy()
    if self.SignBoard then
        self.SignBoard:OnDestroy()
    end

    self.FavorabilityMain:OnClose()
    self.CurrentCharacterId = nil
end
--endregion

--region 初始化
function XUiFavorabilityNew:InitUiAfterAuto()
    local characterId = self:GetCurrFavorabilityCharacter()
    characterId = (characterId == nil) and XDataCenter.DisplayManager.GetDisplayChar().Id or characterId
    self:SetCurrFavorabilityCharacter(characterId)
    self.PanelFavorabilityExchangeRole.gameObject:SetActiveEx(false)
    ---@type XUiPanelFavorabilityExchangeRole
    self.FavorabilityChangeRole = XUiPanelFavorabilityExchangeRole.New(self.PanelFavorabilityExchangeRole, self)
    ---@type XUiPanelSignBoard
    self.SignBoard = XUiPanelSignBoard.New(self.PanelFavorabilityBoard, self, XUiPanelSignBoard.SignBoardOpenType.FAVOR)
    self.SignBoard.OperateTrigger = false
    self.SignBoard:SetAutoPlay(true)
    self.FavorabilityMain = XUiPanelFavorabilityMain.New(self.PanelFavorabilityMain, self)
    self.FavorabilityMain:Close()

    self.BtnMask.CallBack = function() self:OnBtnMaskClick() end
    self.BtnSwitch.CallBack = function() self:OnBtnSwitchClick() end
end

--endregion

--region 数据更新
function XUiFavorabilityNew:UpdateTheme()
    local curSceneId = XDataCenter.PhotographManager.GetCurSceneId()
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
    self.ThemeCtrl:UpdateTheme(themeTemplate)
end

function XUiFavorabilityNew:SetCurrFavorabilityCharacter(characterId)
    self.CurrentCharacterId = characterId
end

function XUiFavorabilityNew:SetWhetherPlayChangeActionEffect(value)
    self.WhetherPlayChangeActionEffect = value
end

-- [更换模型]
function XUiFavorabilityNew:ChangeCharacterModel(templateId)
    self.SignBoard:SetDisplayCharacterId(templateId)
    self.SignBoard:RefreshCharacterModelById(templateId)
    self.SignBoard:ResetPlayList(templateId)
end

function XUiFavorabilityNew:RefreshSelectedModel()
    local characterId = self:GetCurrFavorabilityCharacter()
    characterId = (characterId == nil) and XDataCenter.DisplayManager.GetDisplayChar().Id or characterId
    self:SetCurrFavorabilityCharacter(characterId)
    self:ChangeCharacterModel(characterId)
end
--endregion 

--region 数据处理
function XUiFavorabilityNew:GetCurrFavorabilityCharacter()
    return self.CurrentCharacterId
end

-- [打开main:isAnim是否伴随动画]
function XUiFavorabilityNew:OpenMainView(isAnim)
    self:RefreshSelectedModel()

    self.FavorabilityMain:Open()
    if isAnim then
        self.FavorabilityMain:RefreshDatas()
    else
        self.FavorabilityMain:UpdateDatas()
    end
    self.LastViewType = self.CurrViewType or XFavorabilityType.UILikeMain
    local characterId = self:GetCurrFavorabilityCharacter()
    XRedPointManager.Check(self.RedPointSwitchId, { CharacterId = characterId })
end

function XUiFavorabilityNew:UpdateCamera(isChangeRoleOpen)
    self.PanelCamFarMain.gameObject:SetActiveEx(true)
    self.PanelCamFarrExchange.gameObject:SetActiveEx(not isChangeRoleOpen)
    self.PanelCamNearrExchange.gameObject:SetActiveEx(isChangeRoleOpen)
end

function XUiFavorabilityNew:UpdateBeginCamera(isOpen)
    self.PanelCamFarrBegin.gameObject:SetActiveEx(isOpen)
    self.PanelCamNearBegin.gameObject:SetActiveEx(not isOpen)
end

function XUiFavorabilityNew:OnResume(value)
    local curselectCharacterId = value.CurrentCharacterId
    if curselectCharacterId then
        self:SetCurrFavorabilityCharacter(curselectCharacterId)
    end
    self.FavorabilityMain:UpdateResume(value)
end

function XUiFavorabilityNew:OnGetEvents()
    return { XEventId.EVENT_FAVORABILITY_MAIN_REFRESH, XEventId.EVENT_FAVORABILITY_RUMORS_PREVIEW, XEventId.EVENT_FAVORABILITY_ON_GIFT_CHANGED }
end
--endregion

--region 事件

-- [预览]
function XUiFavorabilityNew:OnPreView(previewArgs)
    if previewArgs and previewArgs[1] then
        self.PanelPreView.gameObject:SetActiveEx(true)
        self:SetUiSprite(self.ImgPreview, previewArgs[1])
    end
end

-- [标记显示的界面]
function XUiFavorabilityNew:ChangeViewType(currViewType)
    self.LastViewType = self.CurrViewType
    self.CurrViewType = currViewType
end

function XUiFavorabilityNew:PlayChangeActionEffect()
    if self.ChangeActionEffect and self.WhetherPlayChangeActionEffect then
        self.ChangeActionEffect.gameObject:SetActiveEx(false)
        self.ChangeActionEffect.gameObject:SetActiveEx(true)
    end
    self.WhetherPlayChangeActionEffect = false
end

function XUiFavorabilityNew:OnReleaseInst()
    return self.FavorabilityMain:GetReleaseData()
end

function XUiFavorabilityNew:OnNotify(evt, ...)
    local args = { ... }

    if evt == XEventId.EVENT_FAVORABILITY_MAIN_REFRESH then
        self.FavorabilityMain:UpdateAllInfos(true)
        self:OnCurrentCharacterFavorabilityLevelChanged(args[1])
    elseif evt == XEventId.EVENT_FAVORABILITY_RUMORS_PREVIEW then
        self:OnPreView(args)

    elseif evt == XEventId.EVENT_FAVORABILITY_ON_GIFT_CHANGED then
        self.FavorabilityMain:UpdatePreviewExp(args)
    end
end


function XUiFavorabilityNew:OnBtnMainUIClick()
    self:SetCurrFavorabilityCharacter(nil)
    XLuaUiManager.RunMain()
end

function XUiFavorabilityNew:OnBtnMaskClick()
    self.PanelPreView.gameObject:SetActiveEx(false)
end

-- [打开切换角色]
function XUiFavorabilityNew:OpenChangeRoleView()
    self:CloseOtherViewWhenExchagneRoleOpen(self.CurrViewType)
    self.FavorabilityChangeRole:Open()
    self.FavorabilityChangeRole:RefreshDatas()
    self:ChangeViewType(XFavorabilityType.UILikeSwitchRole)
    self:UpdateCamera(true)
    self.FavorabilityMain:SetTopControlActive(false)
    self.FavorabilityMain:SetPanelBgActive(false)
    --策划要求开启切换角色时不能播放动作
    self:PauseCvContent()
    self:PlaySaftyAnimation("CharacterExchangeEnable")
end

-- [关闭切换角色,回到上一个界面]
function XUiFavorabilityNew:CloseChangeRoleView()
    --界面关闭恢复状态
    self:ResumeCvContent()
    self:SetWhetherPlayChangeActionEffect(false)
    self:PlaySaftyAnimation("CharacterExchangeDisable", function()
        self.FavorabilityChangeRole:Close()
        self:OpenOtherViewWhenExchangeRoleClose(self.LastViewType)
        --  self.FavorabilityMain:UpdateAllInfos()
        self.FavorabilityMain:SetTopControlActive(true)
        self.FavorabilityMain:SetPanelBgActive(true)
    end)
end

-- [打开档案界面]
function XUiFavorabilityNew:OpenInformationView()
    self:ChangeViewType(XFavorabilityType.UILikeFile)
end

-- [打开礼物界面]
function XUiFavorabilityNew:OpenGiftView()
    self:ChangeViewType(XFavorabilityType.UILikeGift)
end

-- [关闭换人界面时打开上一个界面]
function XUiFavorabilityNew:OpenOtherViewWhenExchangeRoleClose()
    self.FavorabilityMain:OpenFuncBtns()
    self:OpenMainView()
end

-- [打开换人界面时关闭其他界面]CloseOtherViewWhenExchagneRoleOpen
function XUiFavorabilityNew:CloseOtherViewWhenExchagneRoleOpen()
    self.FavorabilityMain:CloseFuncBtns()
end

-- [切换角色]
function XUiFavorabilityNew:OnBtnSwitchClick()
    self:SetWhetherPlayChangeActionEffect(false)
    self:StopCvContent()
    self:OpenChangeRoleView()
end

function XUiFavorabilityNew:PlayCvContent(cvId, cvType)

    if not self.SignBoard then return end
    self.SignBoard:Stop()
    self.SignBoard:Freeze()
    self.SignBoard:ShowContent(cvId, cvType)
end

function XUiFavorabilityNew:StopCvContent()
    if not self.SignBoard then return end
    self.SignBoard:CvStop()
end

function XUiFavorabilityNew:PauseCvContent()
    if not self.SignBoard then return end
    self.SignBoard:Freeze()
end

function XUiFavorabilityNew:ResumeCvContent()
    if not self.SignBoard then return end
    self.SignBoard:Resume()
end

function XUiFavorabilityNew:OnCurrentCharacterFavorabilityLevelChanged()
    local characterId = self:GetCurrFavorabilityCharacter()
    local favorUp = XSignBoardConfigs.GetSignBoardConfigByRoldIdAndCondition(characterId, XSignBoardEventType.FAVOR_UP)
    favorUp = self._Control:FilterSignBoardActionsByFavorabilityUnlock(favorUp)
    if favorUp and #favorUp > 0 and (not self.SignBoard:IsPlaying()) then
        local index = math.random(1, #favorUp)
        self.SignBoard:ForcePlay(favorUp[index].Id)
    end
end

function XUiFavorabilityNew:PlaySubTabAnim()
    --self:PlaySaftyAnimation("YeMianTwo")
end

function XUiFavorabilityNew:PlayBaseTabAnim()
    --self:PlaySaftyAnimation("YeMianOne")
end

function XUiFavorabilityNew:PlaySaftyAnimation(animName, endCb, startCb)
    self:PlayAnimation(animName, function()
        if endCb then
            endCb()
        end
        XLuaUiManager.SetMask(false)
    end,
    function()
        if startCb then
            startCb()
        end
        XLuaUiManager.SetMask(true)
    end)
end

function XUiFavorabilityNew:OnUiSceneLoaded()
    --self:SetGameObject()
    local root = self.UiModelGo
    self.PanelCamFarrExchange = self:FindVirtualCamera("PanelCamFarrExchange")
    self.PanelCamNearrExchange = self:FindVirtualCamera("PanelCamNearrExchange")
    self.PanelCamFarMain = self:FindVirtualCamera("CamFarMain")
    self.PanelCamFarrBegin = self:FindVirtualCamera("PanelCamFarrBegin")
    self.PanelCamNearBegin = self:FindVirtualCamera("PanelCamNearrBegin")
    self.ChangeActionEffect = self:FindVirtualCamera("ChangeActionEffect")
    self:InitUiAfterAuto()
    self:UpdateCamera(false)
    self:UpdateBatteryMode()
end

function XUiFavorabilityNew:UpdateBatteryMode() -- editor模式下 BatteryComponent.BatteryLevel 默认值为-1
    if XQualityManager.IsSimulator and not BatteryComponent.DebugMode then
        return
    end

    local animationRoot = self.UiSceneInfo.Transform:Find("Animations")
    if XTool.UObjIsNil(animationRoot) then return end

    local toChargeTimeLine = animationRoot:Find("ToChargeTimeLine")
    local toFullTimeLine = animationRoot:Find("ToFullTimeLine")
    local fullTimeLine = animationRoot:Find("FullTimeLine")
    local chargeTimeLine = animationRoot:Find("ChargeTimeLine")

    toChargeTimeLine.gameObject:SetActiveEx(false)
    toFullTimeLine.gameObject:SetActiveEx(false)
    fullTimeLine.gameObject:SetActiveEx(false)
    chargeTimeLine.gameObject:SetActiveEx(false)

    local curSelectSceneId = XDataCenter.PhotographManager.GetCurSceneId()
    local type = XPhotographConfigs.GetBackgroundTypeById(curSelectSceneId)
    local particleGroupName = XDataCenter.PhotographManager.GetSceneTemplateById(curSelectSceneId).ParticleGroupName
    local chargeAnimator = nil
    if particleGroupName and particleGroupName ~= "" then
        local chargeAnimatorTrans = self.UiSceneInfo.Transform:FindTransform(particleGroupName)
        if chargeAnimatorTrans then
            chargeAnimator = chargeAnimatorTrans:GetComponent("Animator")
        else
            XLog.Error("Can't Find \"" .. particleGroupName .. "\", Plase Check \"ParticleGroupName\" In Share/PhotoMode/Background.tab")
        end
    end

    if type == XPhotographConfigs.BackGroundType.PowerSaved then
        if BatteryComponent.IsCharging then --充电状态
            if chargeAnimator then chargeAnimator:Play("Full") end
            fullTimeLine.gameObject:SetActiveEx(true)
        else
            if BatteryComponent.BatteryLevel > LowPowerValue then -- 比较电量
                if chargeAnimator then chargeAnimator:Play("Full") end
                fullTimeLine.gameObject:SetActiveEx(true)
            else
                if chargeAnimator then chargeAnimator:Play("Low") end
                chargeTimeLine.gameObject:SetActiveEx(true)
            end
        end
    else
        -- v1.29 场景预览 时间模式判断
        local startTime = XTime.ParseToTimestamp(DateStartTime)
        local endTime = XTime.ParseToTimestamp(DateEndTime)
        local nowTime = XTime.ParseToTimestamp(CS.System.DateTime.Now:ToLocalTime():ToString())
        if startTime > nowTime and nowTime > endTime then   -- 比较时间
            if chargeAnimator then chargeAnimator:Play("Full") end
            fullTimeLine.gameObject:SetActiveEx(true)
        else
            if chargeAnimator then chargeAnimator:Play("Low") end
            chargeTimeLine.gameObject:SetActiveEx(true)
        end
    end
end

-- v1.32 播放角色特殊动作Ui动画
-- ===================================================

function XUiFavorabilityNew:PlayRoleActionUiDisableAnim(signBoardid, stopTime)
    XDataCenter.SignBoardManager.StartBreakTimer(stopTime)
    if XSignBoardConfigs.CheckIsUseNormalUiAnim(signBoardid, self.Name) then
        self:PlayAnimation("UiDisable")
    end
end

function XUiFavorabilityNew:PlayRoleActionUiEnableAnim(signBoardid)
    if XSignBoardConfigs.CheckIsUseNormalUiAnim(signBoardid, self.Name) then
        self:PlayAnimationWithMask("UiEnable")
    end
end

function XUiFavorabilityNew:PlayRoleActionUiBreakAnim()
    self:PlayAnimationWithMask("DarkEnable", function ()
        self.SignBoard:Stop(true)
        self:PlayAnimationWithMask("DarkDisable")
    end)
end

-- ===================================================

--endregion