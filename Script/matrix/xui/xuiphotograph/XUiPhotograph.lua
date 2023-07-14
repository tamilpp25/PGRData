local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiPhotograph = XLuaUiManager.Register(XLuaUi, "UiPhotograph")
local XUiPhotographPanel = require("XUi/XUiPhotograph/XUiPhotographPanel")
local XUiPhotographCapturePanel = require("XUi/XUiPhotograph/XUiPhotographCapturePanel")
local XUiPhotographSDKPanel = require("XUi/XUiPhotograph/XUiPhotographSDKPanel")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local Vector2 = CS.UnityEngine.Vector2
local OffsetX, OffsetY = 50, 50

local XQualityManager = CS.XQualityManager.Instance
local LowPowerValue = CS.XGame.ClientConfig:GetFloat("UiMainLowPowerValue")
local DateStartTime = CS.XGame.ClientConfig:GetString("BackgroundChangeTimeStr")
local DateEndTime = CS.XGame.ClientConfig:GetString("BackgroundChangeTimeEnd")
local BatteryComponent = CS.XUiBattery


function XUiPhotograph:OnAwake()
    local displayChar = XDataCenter.DisplayManager.GetDisplayChar()
    self.CurCharacterId = displayChar.Id
    self.CurFashionId = displayChar.FashionId
    self.SelectCharacterId = self.CurCharacterId
    self.SelectFashionId = self.CurFashionId
    self.PhotoSetData = XDataCenter.PhotographManager.GetSetData()
    XDataCenter.PhotographManager.SetCurSelectSceneId()
    
    self.PhotographPanel = XUiPhotographPanel.New(self, self.PanelPhotograph, self.PhotoSetData, self.CurCharacterId)
    self.CapturePanel = XUiPhotographCapturePanel.New(self, self.PanelCapture)
    self.SDKPanel = XUiPhotographSDKPanel.New(self, self.PanelSDK)
    self.PanelAutoLayout = self.PanelName:GetComponent("XAutoLayoutGroup")
    self.TxtRank = self.TxtLevel.transform.parent:Find("TxtLv"):GetComponent("Text")
    self.ImgGlory = self.TxtLevel.transform.parent:Find("Icon")

    local signBoardPlayer = require("XCommon/XSignBoardPlayer").New(self, CS.XGame.ClientConfig:GetInt("SignBoardPlayInterval"), CS.XGame.ClientConfig:GetFloat("SignBoardDelayInterval"))
    local playerData = XDataCenter.SignBoardManager.GetSignBoardPlayerData()
    signBoardPlayer:SetPlayerData(playerData)
    self.SignBoardPlayer = signBoardPlayer
end

function XUiPhotograph:OnStart()

    self.StartWidth  = CS.UnityEngine.Screen.width
    self.StartHeight = CS.UnityEngine.Screen.height
    self.ContainerSize = self.ImageContainer.sizeDelta
    
    self:SetProportionImage()
    self.Parent = self
    self:AutoRegisterBtnListener()
    self.TxtUserName.text = XPlayer.Name
    self.TxtLevel.text = XPlayer.GetLevelOrHonorLevel()
    self.TxtRank.text = XPhotographConfigs.GetRankLevelText()
    self.ImgGlory.gameObject:SetActiveEx(XPlayer.IsHonorLevelOpen())
    self.TxtID.text = string.format("ID: %s", XPlayer.Id)
end

function XUiPhotograph:OnEnable()
    -- 重启计时器
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end

    self.Timer = XScheduleManager.ScheduleForever(function()
        self:Update()
    end, 0)

    if self.SignBoardPlayer then
        self.SignBoardPlayer:OnEnable()
    end
    
    self.PhotographPanel:DefaultClick()
    --首次进入界面使用设置的场景Id, 界面再次被激活，使用当前选择的Id
    local sceneId = XDataCenter.PhotographManager.GetCurSelectSceneId()
    local sceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
    local scenePath, modelPath = XSceneModelConfigs.GetSceneAndModelPathById(sceneTemplate.SceneModelId)
    self:LoadUiScene(scenePath, modelPath, self.OnUiSceneLoadedCB, false)
    self.CurrSeleSceneId = sceneId
    self.Enable = true
    --self:PlayAnimation("PanelSceneListEnable")
    XEventManager.DispatchEvent(XEventId.EVENT_PHOTO_ENTER)
    self:UpdateView()
    XDataCenter.SignBoardManager.AddRoleActionUiAnimListener(self)

    -- 开启时钟
    self.ClockTimer = XUiHelper.SetClockTimeTempFun(self)
end

function XUiPhotograph:Update()
    if not self.Enable then
        return
    end

    local dt = CS.UnityEngine.Time.deltaTime
    if self.SignBoardPlayer then
        self.SignBoardPlayer:Update(dt)
    end
    
    local width, height = CS.UnityEngine.Screen.width, CS.UnityEngine.Screen.height
    if width ~= self.StartWidth or height ~= self.StartHeight then
        self:SetProportionImage()
        self.StartWidth  = width
        self.StartHeight = height
    end
end

function XUiPhotograph:UpdateView()
    self:BindViewModelPropertyToObj(self.PhotoSetData, function(logo)
        local show = logo.Value ~= 0
        self.ImgLogo.gameObject:SetActiveEx(show)
        if show then
            XPhotographConfigs.SetLogoOrInfoPos(self.ImgLogo.transform, logo, false, OffsetX, OffsetY)
        end
        XDataCenter.PhotographManager.SaveSetData()
    end, "_LogoAlignment")

    self:BindViewModelPropertyToObj(self.PhotoSetData, function(info)
        local show = info.Value ~= 0
        self.PanelName.gameObject:SetActiveEx(show)
        if show then
            XPhotographConfigs.SetLogoOrInfoPos(self.PanelName, info, true, OffsetX, OffsetY, self.PanelAutoLayout)
        end
        XDataCenter.PhotographManager.SaveSetData()
    end, "_InfoAlignment")

    self:BindViewModelPropertyToObj(self.PhotoSetData, function(openLevel)
        self.TxtLevel.transform.parent.gameObject:SetActiveEx(XTool.IsNumberValid(openLevel))
        XDataCenter.PhotographManager.SaveSetData()
    end, "_OpenLevel")

    self:BindViewModelPropertyToObj(self.PhotoSetData, function(openUId)
        self.TxtID.gameObject:SetActiveEx(XTool.IsNumberValid(openUId))
        XDataCenter.PhotographManager.SaveSetData()
    end, "_OpenUId")
end

function XUiPhotograph:OnDisable()
    if self.Timer ~= nil then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end

    if self.SignBoardPlayer then
        self.SignBoardPlayer:OnDisable()
    end

    self.Enable = false
    XEventManager.DispatchEvent(XEventId.EVENT_PHOTO_LEAVE)
    XDataCenter.SignBoardManager.RemoveRoleActionUiAnimListener(self)

    -- 关闭时钟
    if self.ClockTimer then
        XUiHelper.StopClockTimeTempFun(self, self.ClockTimer)
        self.ClockTimer = nil
    end
end

function XUiPhotograph:OnDestroy()
    if self.Timer ~= nil then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end

    if self.SignBoardPlayer then
        self.SignBoardPlayer:OnDestroy()
    end

    XDataCenter.PhotographManager.ClearTextureCache()
end

function XUiPhotograph:OnGetEvents()
    return {
        XEventId.EVENT_PHOTO_CHANGE_SCENE,
        XEventId.EVENT_PHOTO_CHANGE_MODEL,
        XEventId.EVENT_PHOTO_PLAY_ACTION,
        XEventId.EVENT_PHOTO_PHOTOGRAPH,
        XEventId.EVENT_PHOTO_CHANGE_PARTNER,
        XEventId.EVENT_PHOTO_HIDE_UI,
        XEventId.EVENT_PHOTO_CHANGE_ANIMATION_STATE,
        XEventId.EVENT_PHOTO_REPLAY_ANIMATION,
    }
end

function XUiPhotograph:OnNotify(evt, ...)
    if evt == XEventId.EVENT_PHOTO_CHANGE_SCENE then
        self.SignBoardPlayer:Stop()
        self:ChangeScene(...)
        self.PhotographPanel:RefreshBtnSynchronous()
    elseif evt == XEventId.EVENT_PHOTO_CHANGE_MODEL then
        self.SignBoardPlayer:Stop()
        self:UpdateRoleModel(...)
        self:PlayChangeActionEffect()
        self.PhotographPanel:RefreshBtnSynchronous()
        self.PhotographPanel:ClearActionCache()
    elseif evt == XEventId.EVENT_PHOTO_PLAY_ACTION then
        self:ForcePlay(...)
    elseif evt == XEventId.EVENT_PHOTO_PHOTOGRAPH then
        self:Photograph()
    elseif evt == XEventId.EVENT_PHOTO_CHANGE_PARTNER then
        self:UpdatePartner(...)
    elseif evt == XEventId.EVENT_PHOTO_HIDE_UI then
        self:UpdateViewState(...)
    elseif evt == XEventId.EVENT_PHOTO_CHANGE_ANIMATION_STATE then
        self:ChangeAnimationState(...)
    elseif evt == XEventId.EVENT_PHOTO_REPLAY_ANIMATION then
        self:Replay()
    end
end

function XUiPhotograph:OnBtnBackClick()
    self:Close()
end

function XUiPhotograph:ChangeScene(sceneId)
    -- 切换的时候也要开启时钟，而且避免重复需要先关闭
    -- 关闭时钟
    if self.ClockTimer then
        XUiHelper.StopClockTimeTempFun(self, self.ClockTimer)
        self.ClockTimer = nil
    end

    XDataCenter.PhotographManager.SetCurSelectSceneId(sceneId)
    local sceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
    local scenePath, modelPath = XSceneModelConfigs.GetSceneAndModelPathById(sceneTemplate.SceneModelId)
    self:LoadUiScene(scenePath, modelPath, self.OnUiSceneLoadedCB, false)
    self.CurrSeleSceneId = sceneId

    -- 开启时钟
    self.ClockTimer = XUiHelper.SetClockTimeTempFun(self)
end

function XUiPhotograph:AutoRegisterBtnListener()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.OnUiSceneLoadedCB = function() self:OnUiSceneLoaded() end
    if self.BtnBreakActionAnim then
        self.BtnBreakActionAnim.CallBack = function () self:PlayRoleActionUiBreakAnim() end
    end
end

function XUiPhotograph:ChangeState(state)
    if state == XPhotographConfigs.PhotographViewState.Normal then
        self.PhotographPanel:Show()
        self.CapturePanel:Hide()
        self.SDKPanel:Hide()
        --self.PanelMenu.gameObject:SetActiveEx(true)
        self.ImgLine.gameObject:SetActiveEx(true)
    elseif state == XPhotographConfigs.PhotographViewState.Capture then
        self.PhotographPanel:Hide()
        self.CapturePanel:Show()
        self.SDKPanel:Hide()
        self.PanelMenu.gameObject:SetActiveEx(false)
        self.ImgLine.gameObject:SetActiveEx(false)
    elseif state == XPhotographConfigs.PhotographViewState.SDK then
        self.PhotographPanel:Hide()
        self.CapturePanel:Show()
        self.SDKPanel:Show()
        self.PanelMenu.gameObject:SetActiveEx(false)
        self.ImgLine.gameObject:SetActiveEx(false)
    end
end

function XUiPhotograph:OnUiSceneLoaded()
    self:PlayAnimation("Loading2")
    --self:SetGameObject()
    self:InitSceneRoot()
    self:UpdateRoleModel(self.SelectCharacterId, self.SelectFashionId)
    self:UpdatePartner(self.PartnerTemplateId)
    self:UpdateCamera()
    self:UpdateBatteryMode()
end

function XUiPhotograph:InitSceneRoot()
    local root = self.UiModelGo.transform
    self.CameraFar = self:FindVirtualCamera("CamFarMain")
    self.CameraNear = self:FindVirtualCamera("CamNearMain")
    self.CameraComponentFar = root:FindTransform("UiFarCamera"):GetComponent("Camera")
    self.CameraComponentNear = root:FindTransform("UiNearCamera"):GetComponent("Camera")
    self.UiModelParent = root:FindTransform("UiModelParent")
    self.ChangeActionEffect = root:FindTransform("ChangeActionEffect")
    self.RoleModel = XUiPanelRoleModel.New(self.UiModelParent, self.Name, true, true, false, true, nil, nil, true)
    self.PartnerModelPanel = XUiPanelRoleModel.New(self.UiModelParent, self.Name, false, true, true, true, false)
end

function XUiPhotograph:UpdateRoleModel(charId, fashionId)
    if self.SelectCharacterId ~= charId then
        self.SignBoardActionId = nil
        self.SignBoardPlayer.PlayerData.PlayingElement = nil
    end
    self.SelectCharacterId = charId
    --self.CurCharacterId = charId
    --self.CurFashionId = fashionId
    self.SelectFashionId = fashionId
    XDataCenter.DisplayManager.UpdateRoleModel(self.RoleModel, charId, nil, fashionId)
    self.RoleAnimator = self.RoleModel:GetAnimator()

    self.RoleModel:SetXPostFaicalControllerActive(true)
end

function XUiPhotograph:UpdatePartner(templateId)
    if not XTool.IsNumberValid(templateId) then
        if self.PartnerModel then
            self.PartnerModel.gameObject:SetActiveEx(false)
        end
        return
    end
    self.PartnerTemplateId = templateId
    local standByModel = XPartnerConfigs.GetPartnerModelStandbyModel(templateId)
    
    self.PartnerModelPanel:UpdatePartnerModel(standByModel, XModelManager.MODEL_UINAME.XUiPhotograph, nil, function(model)
        self.PartnerModel = model
        model.gameObject:SetActiveEx(true)
        model.transform.localPosition = CS.UnityEngine.Vector3(-0.6, 0.6, -0.5)
    end, false, true)
    ---播放出现特效
    self.PartnerModelPanel:LoadPartnerUiEffect(standByModel, XPartnerConfigs.EffectParentName.ModelOnEffect, true, true, true)
end

function XUiPhotograph:UpdateViewState(show)
    local animName = show and "UiEnable" or "UiDisable"
    self:PlayAnimation(animName)
    self.BtnBack.gameObject:SetActiveEx(show)
    self.ImgLine.gameObject:SetActiveEx(show)
end

function XUiPhotograph:UpdateCamera()
    self.CameraFar.gameObject:SetActiveEx(true)
    self.CameraNear.gameObject:SetActiveEx(true)
end

function XUiPhotograph:ForcePlay(signBoardActionId, actionId)
    self.SignBoardActionId = signBoardActionId
    self.ActionId = actionId or self.ActionId -- characterAction表的主键
    local config = XSignBoardConfigs.GetSignBoardConfigById(signBoardActionId)
    if self.SignBoardPlayer:GetInterruptDetection() and self.SignBoardPlayer.PlayerData.PlayingElement.Id ~= config.Id then
        self:PlayChangeActionEffect()
    end
    self:ChangeAnimationState(false)
    self.PhotographPanel.ActionPanel:SetBtnPlayState(false)
    XScheduleManager.ScheduleNextFrame(function()
        self.SignBoardPlayer:ForcePlayCross(config)
    end)
    self.SignBoardPlayer:SetInterruptDetection(true)
end

function XUiPhotograph:Play(element)
    if not element then
        return
    end
    self.PhotographPanel:RefreshActionPanel(true, self.SignBoardActionId ~= nil)
    if element.SignBoardConfig.CvId and element.SignBoardConfig.CvId > 0 then
        if element.CvType then
            self.PlayingCv = CS.XAudioManager.PlayCvWithCvType(element.SignBoardConfig.CvId, element.CvType)
        else
            self.PlayingCv = CS.XAudioManager.PlayCv(element.SignBoardConfig.CvId)
        end
    end

    local actionId = element.SignBoardConfig.ActionId
    if actionId then
        self.RoleModel:PlayAnima(actionId, true)
        self.RoleModel:LoadCharacterUiEffect(tonumber(element.SignBoardConfig.RoleId), actionId)
    end

    -- 关闭角色头部跟随
    self.RoleModel:SetXPostFaicalControllerActive(false)
end

function XUiPhotograph:PlayCross(element)
    if not element then
        return
    end
    self.PhotographPanel:RefreshActionPanel(true, self.SignBoardActionId ~= nil)
    if element.SignBoardConfig.CvId and element.SignBoardConfig.CvId > 0 then
        if element.CvType then
            self.PlayingCv = CS.XAudioManager.PlayCvWithCvType(element.SignBoardConfig.CvId, element.CvType)
        else
            self.PlayingCv = CS.XAudioManager.PlayCv(element.SignBoardConfig.CvId)
        end
    end

    local actionId = element.SignBoardConfig.ActionId
    if actionId then
        self.RoleModel:PlayAnimaCross(actionId, true)
        self.RoleModel:LoadCharacterUiEffect(tonumber(element.SignBoardConfig.RoleId), actionId)
    end

    -- 关闭角色头部跟随
    self.RoleModel:SetXPostFaicalControllerActive(false)
end

--停止
function XUiPhotograph:OnStop(playingElement, force)
    if self.PlayingCv then
        self.PlayingCv:Stop()
        self.PlayingCv = nil
    end
    self.PhotographPanel:RefreshActionPanel(false, self.SignBoardActionId ~= nil)
    if playingElement then
        self.RoleAnimator.speed = 1
        self.RoleModel:StopAnima(playingElement.SignBoardConfig.ActionId, force)
        self.RoleModel:LoadCurrentCharacterDefaultUiEffect()
    end
    self.SignBoardPlayer:SetInterruptDetection(false)

    -- 开启角色头部跟随
    self.RoleModel:SetXPostFaicalControllerActive(true)
end

function XUiPhotograph:ChangeAnimationState(pause)
    if not self.RoleAnimator then
        return
    end
    local speed
    if pause then
        speed = 0
        self.SignBoardPlayer:Pause()
        if self.PlayingCv then
            self.PlayingCv:Pause()
        end
    else
        speed = 1
        self.SignBoardPlayer:Resume()
        if self.PlayingCv then
            self.PlayingCv:Resume()
        end
    end
    self.RoleAnimator.speed = speed
end

function XUiPhotograph:Replay()
    if not XTool.IsNumberValid(self.SignBoardActionId) or not XTool.IsNumberValid(self.ActionId) then
        return
    end

    local configs = XFavorabilityConfigs.GetCharacterActionById(self.SelectCharacterId)
    local data = nil
    for k, v in pairs(configs) do
        if v.Id == self.ActionId then
            data = v
        end
    end
    if XTool.IsTableEmpty(data) then
        return
    end
    local tryFashionId = self.SelectFashionId
    local trySceneId = self.CurrSeleSceneId
    local isHas = XDataCenter.FavorabilityManager.CheckTryCharacterActionUnlock(data, XDataCenter.PhotographManager.GetCharacterDataById(self.SelectCharacterId).TrustLv, tryFashionId, trySceneId)
    if not isHas then
        XUiManager.TipError(data.ConditionDescript)
        return
    end

    self.SignBoardPlayer:Stop()
    self:ForcePlay(self.SignBoardActionId)
end

function XUiPhotograph:IsPlaying()
    return self.SignBoardPlayer and self.SignBoardPlayer:IsPlaying()
end

function XUiPhotograph:Photograph()
    XCameraHelper.ScreenShotNew(self.ImgPicture, self.CameraComponentNear, function(screenShot)
        -- 截图后操作
        XCameraHelper.ScreenShotNew(self.CapturePanel.ImagePhoto, self.CameraCupture, function(shot) -- 把合成后的图片渲染到游戏UI中的照片展示(最终要分享的图片)
            CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, CS.XUiManager.Instance.UiCamera)
            self.ShareTexture = shot
            self.PhotoName = "[" .. tostring(XPlayer.Id) .. "]" .. XTime.GetServerNowTimestamp()
            self:PlayAnimation("Shanguang", function()
                if not XTool.UObjIsNil(self.ImgPicture.mainTexture) and self.ImgPicture.mainTexture.name ~= "UnityWhite" then -- 销毁texture2d (UnityWhite为默认的texture2d)
                    CS.UnityEngine.Object.Destroy(self.ImgPicture.mainTexture)
                end
            end)
            self:PlayAnimation("Photo", function()
                self.CapturePanel.BtnClose.gameObject:SetActiveEx(true)
            end, function()
                self:ChangeState(XPhotographConfigs.PhotographViewState.SDK)
                self.CapturePanel.BtnClose.gameObject:SetActiveEx(false)
            end)
        end, function() CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, self.CameraCupture) end)
    end)
    XDataCenter.PhotographManager.SendPhotoGraphRequest()
end

function XUiPhotograph:SetProportionImage()
    --切换横竖屏后，获取到的宽高不一定正确，会在延后几帧更新
    local width, height = CS.UnityEngine.Screen.width, CS.UnityEngine.Screen.height
    local defaultSize = self.ContainerSize
    local ratio = width / height
    local screenW
    --横屏以高度为基准进行等比缩放
    if ratio < 1 then
        screenW = 1 / ratio * defaultSize.y
    else
        screenW = ratio * defaultSize.y
    end
    self.ImageContainer.sizeDelta = Vector2(screenW, defaultSize.y)
    if not self.InitPic then
        self.ImgPicture.rectTransform.sizeDelta = Vector2(CsXUiManager.RealScreenWidth, CsXUiManager.RealScreenHeight)
        self.InitPic = true
    end
end

function XUiPhotograph:CheckHasChanged()
    local curSceneId = XDataCenter.PhotographManager.GetCurSceneId()
    local curSelectSceneId = XDataCenter.PhotographManager.GetCurSelectSceneId()
    if curSceneId ~= curSelectSceneId 
            or self.CurCharacterId ~= self.SelectCharacterId 
            or self.CurFashionId ~= self.SelectFashionId then
        return true
    end

    return false
end

function XUiPhotograph:PlayChangeActionEffect()
    if self.ChangeActionEffect then
        self.ChangeActionEffect.gameObject:SetActive(false)
        self.ChangeActionEffect.gameObject:SetActive(true)
    end
end

function XUiPhotograph:OnPortraitChanged(charId, fashionId, oldCharId)
    if charId ~= self.SelectCharacterId then
        self.SignBoardActionId = nil
        self.SignBoardPlayer.PlayerData.PlayingElement = nil
        self.PhotographPanel:ClearActionCache()
    end
    self.SelectCharacterId = charId
    self.SelectFashionId = fashionId
    self.CurCharacterId = oldCharId
    self.CurFashionId = XDataCenter.CharacterManager.GetShowFashionId(oldCharId)
end

function XUiPhotograph:UpdateBatteryMode() -- editor模式下 BatteryComponent.BatteryLevel 默认值为-1
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

    local curSelectSceneId = XDataCenter.PhotographManager.GetCurSelectSceneId()
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
    
    local type = XPhotographConfigs.GetBackgroundTypeById(curSelectSceneId)
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

-- 播放场景动画
function XUiPhotograph:PlaySceneAnim(element)
    if not element then
        return
    end
    local animRoot = self.UiModelGo.transform
    local sceneId = XDataCenter.PhotographManager.GetCurSelectSceneId()
    local sighBoardId = element.SignBoardConfig.Id
    XDataCenter.SignBoardManager.LoadSceneAnim(animRoot, self.CameraFar, self.CameraNear, sceneId, sighBoardId, self)
    XDataCenter.SignBoardManager.SceneAnimPlay()
end

function XUiPhotograph:PlayRoleActionUiDisableAnim(signBoardid)
    self:SetActionMask(true)
    if XSignBoardConfigs.CheckIsUseNormalUiAnim(signBoardid, self.Name) then
        self:PlayAnimation("UiDisable")
    end
end

function XUiPhotograph:PlayRoleActionUiEnableAnim(signBoardid)
    self:SetActionMask(false)
    if XSignBoardConfigs.CheckIsUseNormalUiAnim(signBoardid, self.Name) then
        self:PlayAnimationWithMask("UiEnable")
    end
end

function XUiPhotograph:PlayRoleActionUiBreakAnim()
    self:SetActionMask(false)
    self.SignBoardPlayer:Stop()
end

function XUiPhotograph:SetActionMask(active)
    if self.BtnBreakActionAnim then
        self.BtnBreakActionAnim.gameObject:SetActiveEx(active)
    end
end

-- ===================================================