local XUiFavorabilityNew = XLuaUiManager.Register(XLuaUi, "UiFavorabilityNew")

local XFavorabilityType = {
    UILikeMain = 1,
    UILikeSwitchRole = 2,
    UILikeFile = 3,
    UILikePlot = 4,
    UILikeGift = 5,
}

local XQualityManager = CS.XQualityManager.Instance
local LowPowerValue = CS.XGame.ClientConfig:GetFloat("UiMainLowPowerValue")
local BatteryComponent = CS.XUiBattery

function XUiFavorabilityNew:OnAwake()
    local curSceneId = XDataCenter.PhotographManager.GetCurSceneId()
    local curSceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(curSceneId)
    local curSceneUrl, _ = XSceneModelConfigs.GetSceneAndModelPathById(curSceneTemplate.SceneModelId)
    local modelUrl = self:GetDefaultUiModelUrl()
    self:LoadUiScene(curSceneUrl, modelUrl, function() self:OnUiSceneLoaded() end, false)
end


function XUiFavorabilityNew:OnStart()
    self.CvType = CS.XAudioManager.CvType
    self:OpenMainView(true)

    XDataCenter.FavorabilityManager.BoardMutualRequest()

    local characterId = self:GetCurrFavorabilityCharacter()
    self.RedPointSwitchId = XRedPointManager.AddRedPointEvent(self.ImgReddot, nil, self, { XRedPointConditions.Types.CONDITION_FAVORABILITY_RED }, { CharacterId = characterId })
end

function XUiFavorabilityNew:OnEnable()
    if self.SignBoard then
        self.SignBoard:OnEnable()
    end
    self:RefreshSelectedModel()
    if self.FavorabilityMain then
        self.FavorabilityMain:UpdateAllInfos()
    end
end

function XUiFavorabilityNew:OnDisable()
    if self.SignBoard then
        self.SignBoard:OnDisable()
    end
end

function XUiFavorabilityNew:OnDestroy()
    if self.SignBoard then
        self.SignBoard:OnDestroy()
    end

    self.FavorabilityMain:OnClose()
    self.CurrentCharacterId = nil
end

function XUiFavorabilityNew:SetCurrFavorabilityCharacter(characterId)
    self.CurrentCharacterId = characterId
end

function XUiFavorabilityNew:GetCurrFavorabilityCharacter()
    return self.CurrentCharacterId
end

function XUiFavorabilityNew:OnGetEvents()
    return { XEventId.EVENT_FAVORABILITY_MAIN_REFRESH, XEventId.EVENT_FAVORABILITY_RUMORS_PREVIEW, XEventId.EVENT_FAVORABILITY_ON_GIFT_CHANGED }
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

function XUiFavorabilityNew:InitUiAfterAuto()
    local characterId = self:GetCurrFavorabilityCharacter()
    characterId = (characterId == nil) and XDataCenter.DisplayManager.GetDisplayChar().Id or characterId
    self:SetCurrFavorabilityCharacter(characterId)

    self.FavorabilityChangeRole = XUiPanelFavorabilityExchangeRole.New(self.PanelFavorabilityExchangeRole, self)
    self.SignBoard = XUiPanelSignBoard.New(self.PanelFavorabilityBoard, self, XUiPanelSignBoard.SignBoardOpenType.FAVOR)
    self.SignBoard.OperateTrigger = false
    self.SignBoard:SetAutoPlay(true)
    self.FavorabilityMain = XUiPanelFavorabilityMain.New(self.PanelFavorabilityMain, self)

    self.BtnMask.CallBack = function() self:OnBtnMaskClick() end
    self.BtnSwitch.CallBack = function() self:OnBtnSwitchClick() end
end

function XUiFavorabilityNew:PlayChangeActionEffect()
    if self.ChangeActionEffect and self.WhetherPlayChangeActionEffect then
        self.ChangeActionEffect.gameObject:SetActiveEx(false)
        self.ChangeActionEffect.gameObject:SetActiveEx(true)
    end
    self.WhetherPlayChangeActionEffect = false
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

-- [打开main:isAnim是否伴随动画]
function XUiFavorabilityNew:OpenMainView(isAnim)
    self:RefreshSelectedModel()

    self.FavorabilityMain.GameObject:SetActiveEx(true)
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

-- [打开切换角色]
function XUiFavorabilityNew:OpenChangeRoleView()
    self:CloseOtherViewWhenExchagneRoleOpen(self.CurrViewType)
    self.FavorabilityChangeRole.GameObject:SetActiveEx(true)
    self.FavorabilityChangeRole:RefreshDatas()
    self:ChangeViewType(XFavorabilityType.UILikeSwitchRole)
    self:UpdateCamera(true)
    self.FavorabilityMain:SetTopControlActive(false)
    self:PlaySaftyAnimation("CharacterExchangeEnable")
end

-- [关闭切换角色,回到上一个界面]
function XUiFavorabilityNew:CloseChangeRoleView()
    self:SetWhetherPlayChangeActionEffect(false)
    self:PlaySaftyAnimation("CharacterExchangeDisable", function()
        self.FavorabilityChangeRole.GameObject:SetActiveEx(false)
        self:OpenOtherViewWhenExchangeRoleClose(self.LastViewType)
        --  self.FavorabilityMain:UpdateAllInfos()
        self.FavorabilityMain:SetTopControlActive(true)
    end)
end

-- [打开档案界面]
function XUiFavorabilityNew:OpenInformationView()
    self:ChangeViewType(XFavorabilityType.UILikeFile)
end

-- [打开剧情界面]
function XUiFavorabilityNew:OpenPlotView()
    self:ChangeViewType(XFavorabilityType.UILikePlot)
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
    local content = XFavorabilityConfigs.GetCvContentByIdAndType(cvId, cvType)
    self.SignBoard:ShowContent(content)
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
    if favorUp and favorUp[1] and (not self.SignBoard:IsPlaying()) then
        self.SignBoard:ForcePlay(favorUp[1].Id)
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
    self:SetGameObject()
    local root = self.UiModelGo
    self.PanelCamFarrExchange = self:FindVirtualCamera("PanelCamFarrExchange")
    self.PanelCamNearrExchange = self:FindVirtualCamera("PanelCamNearrExchange")
    self.PanelCamFarMain = self:FindVirtualCamera("CamFarMain")
    self.PanelCamFarrBegin = self:FindVirtualCamera("PanelCamFarrBegin")
    self.PanelCamNearBegin = self:FindVirtualCamera("PanelCamNearrBegin")
    self.ChangeActionEffect = self:FindVirtualCamera("ChangeActionEffect")
    self:InitUiAfterAuto()
    self:UpdateCamera()
    self:UpdateBatteryMode()
end

function XUiFavorabilityNew:UpdateBatteryMode() -- editor模式下 BatteryComponent.BatteryLevel 默认值为-1
    if XQualityManager.IsSimulator and not BatteryComponent.DebugMode then
        return
    end

    local animationRoot = self.UiSceneInfo.Transform:Find("Animations")
    local toChargeTimeLine = animationRoot:Find("ToChargeTimeLine")
    local toFullTimeLine = animationRoot:Find("ToFullTimeLine")
    local fullTimeLine = animationRoot:Find("FullTimeLine")
    local chargeTimeLine = animationRoot:Find("ChargeTimeLine")

    toChargeTimeLine.gameObject:SetActiveEx(false)
    toFullTimeLine.gameObject:SetActiveEx(false)
    fullTimeLine.gameObject:SetActiveEx(false)
    chargeTimeLine.gameObject:SetActiveEx(false)

    local curSelectSceneId = XDataCenter.PhotographManager.GetCurSceneId()
    local particleGroupName = XDataCenter.PhotographManager.GetSceneTemplateById(curSelectSceneId).ParticleGroupName
    local chargeAnimator = nil
    if particleGroupName and particleGroupName ~= "" then
        local chargeAnimatorTrans = self.UiSceneInfo.Transform:FindTransform(particleGroupName)
        if chargeAnimatorTrans then
            chargeAnimator = chargeAnimatorTrans:GetComponent("Animator")
        else
            XLog.Error("Can't Find \""..particleGroupName.."\", Plase Check \"ParticleGroupName\" In Share/PhotoMode/Background.tab")
        end
    end

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
end