local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiPhotograph = XLuaUiManager.Register(XLuaUi, "UiPhotograph")
local XUiPhotographPanel = require("XUi/XUiPhotograph/XUiPhotographPanel")
local XUiPhotographCapturePanel = require("XUi/XUiPhotograph/XUiPhotographCapturePanel")
local XUiPhotographSDKPanel = require("XUi/XUiPhotograph/XUiPhotographSDKPanel")

local SCREEN_WIDTH = CS.UnityEngine.Screen.width
local SCREEN_HEIGHT = CS.UnityEngine.Screen.height
local Vector2 = CS.UnityEngine.Vector2

local XQualityManager = CS.XQualityManager.Instance
local LowPowerValue = CS.XGame.ClientConfig:GetFloat("UiMainLowPowerValue")
local BatteryComponent = CS.XUiBattery

function XUiPhotograph:OnAwake()
    self.PhotographPanel = XUiPhotographPanel.New(self, self.PanelPhotograph)
    self.CapturePanel = XUiPhotographCapturePanel.New(self, self.PanelCapture)
    self.SDKPanel = XUiPhotographSDKPanel.New(self, self.PanelSDK)

    local signBoardPlayer = require("XCommon/XSignBoardPlayer").New(self, CS.XGame.ClientConfig:GetInt("SignBoardPlayInterval"), CS.XGame.ClientConfig:GetFloat("SignBoardDelayInterval"))
    local playerData = XDataCenter.SignBoardManager.GetSignBoardPlayerData()
    signBoardPlayer:SetPlayerData(playerData)
    self.SignBoardPlayer = signBoardPlayer
end

function XUiPhotograph:OnStart()
    self:SetProportionImage()
    self.Parent = self
    self:AutoRegisterBtnListener()
    local displayChar = XDataCenter.DisplayManager.GetDisplayChar()
    self.CurCharacterId = displayChar.Id
    self.CurFashionId = displayChar.FashionId
    self.SelectCharacterId = self.CurCharacterId
    self.SelectFashionId = self.CurFashionId
    self.TxtUserName.text = XPlayer.Name
    XDataCenter.PhotographManager.SetCurSelectSceneId()
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
    local sceneId = XDataCenter.PhotographManager.GetCurSceneId()
    local sceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
    local scenePath, modelPath = XSceneModelConfigs.GetSceneAndModelPathById(sceneTemplate.SceneModelId)
    self:LoadUiScene(scenePath, modelPath, self.OnUiSceneLoadedCB, false)
    self.Enable = true
    self:PlayAnimation("PanelSceneListEnable")
    XEventManager.DispatchEvent(XEventId.EVENT_PHOTO_ENTER)
end

function XUiPhotograph:Update()
    if not self.Enable then
        return
    end

    local dt = CS.UnityEngine.Time.deltaTime
    if self.SignBoardPlayer then
        self.SignBoardPlayer:Update(dt)
    end
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
    }
end

function XUiPhotograph:OnNotify(evt, ...)
    if evt == XEventId.EVENT_PHOTO_CHANGE_SCENE then
        self.SignBoardPlayer:Stop()
        self:ChangeScene(...)
        self.PhotographPanel:SetBtnSynchronousActiveEx(self:CheckHasChanged())
    elseif evt == XEventId.EVENT_PHOTO_CHANGE_MODEL then
        self.SignBoardPlayer:Stop()
        self:UpdateRoleModel(...)
        self:PlayChangeActionEffect()
        self.PhotographPanel:SetBtnSynchronousActiveEx(self:CheckHasChanged())
    elseif evt == XEventId.EVENT_PHOTO_PLAY_ACTION then
        self:ForcePlay(...)
    elseif evt == XEventId.EVENT_PHOTO_PHOTOGRAPH then
        self:Photograph()
    end
end

function XUiPhotograph:OnBtnBackClick()
    self:Close()
end

function XUiPhotograph:ChangeScene(sceneId)
    XDataCenter.PhotographManager.SetCurSelectSceneId(sceneId)
    local sceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
    local scenePath, modelPath = XSceneModelConfigs.GetSceneAndModelPathById(sceneTemplate.SceneModelId)
    self:LoadUiScene(scenePath, modelPath, self.OnUiSceneLoadedCB, false)
end

function XUiPhotograph:AutoRegisterBtnListener()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.OnUiSceneLoadedCB = function() self:OnUiSceneLoaded() end
end

function XUiPhotograph:ChangeState(state)
    if state == XPhotographConfigs.PhotographViewState.Normal then
        self.PhotographPanel:Show()
        self.CapturePanel:Hide()
        self.SDKPanel:Hide()
        self.PanelMenu.gameObject:SetActiveEx(true)
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
    self:SetGameObject()
    self:InitSceneRoot()
    self:UpdateRoleModel(self.SelectCharacterId, self.SelectFashionId)
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
end

function XUiPhotograph:UpdateRoleModel(charId, fashionId)
    self.SelectCharacterId = charId
    self.SelectFashionId = fashionId
    XDataCenter.DisplayManager.UpdateRoleModel(self.RoleModel, charId, nil, fashionId)
end

function XUiPhotograph:UpdateCamera()
    self.CameraFar.gameObject:SetActiveEx(true)
    self.CameraNear.gameObject:SetActiveEx(true)
end

function XUiPhotograph:ForcePlay(signBoardActionId)
    local config = XSignBoardConfigs.GetSignBoardConfigById(signBoardActionId)
    if self.SignBoardPlayer:GetInterruptDetection() and self.SignBoardPlayer.PlayerData.PlayingElement.Id ~= config.Id then
        self:PlayChangeActionEffect()
    end
    self.SignBoardPlayer:ForcePlay(config)
    self.SignBoardPlayer:SetInterruptDetection(true)
end

function XUiPhotograph:Play(element)
    if not element then
        return
    end

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
end

--停止
function XUiPhotograph:OnStop(playingElement)
    if self.PlayingCv then
        self.PlayingCv:Stop()
        self.PlayingCv = nil
    end

    if playingElement then
        self.RoleModel:StopAnima(playingElement.SignBoardConfig.ActionId)
        self.RoleModel:LoadCurrentCharacterDefaultUiEffect()
    end

    self.SignBoardPlayer:SetInterruptDetection(false)
end

function XUiPhotograph:Photograph()
    XCameraHelper.ScreenShotNew(self.ImgPicture, self.CameraComponentNear, function (screenShot)
        -- 截图后操作
        XCameraHelper.ScreenShotNew(self.CapturePanel.ImagePhoto, self.CameraCupture, function (screenShot) -- 把合成后的图片渲染到游戏UI中的照片展示(最终要分享的图片)
            CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, CS.XUiManager.Instance.UiCamera)
            self.ShareTexture = screenShot
            self.PhotoName = "[" .. tostring(XPlayer.Id) .. "]" .. XTime.GetServerNowTimestamp()
            self:PlayAnimation("Shanguang", function ()
                if not XTool.UObjIsNil(self.ImgPicture.mainTexture) and self.ImgPicture.mainTexture.name ~= "UnityWhite" then -- 销毁texture2d (UnityWhite为默认的texture2d)
                    CS.UnityEngine.Object.Destroy(self.ImgPicture.mainTexture)
                end
            end)
            self:PlayAnimation("Photo", function ()
                self.CapturePanel.BtnClose.gameObject:SetActiveEx(true)
            end, function ()
                self:ChangeState(XPhotographConfigs.PhotographViewState.SDK)
                self.CapturePanel.BtnClose.gameObject:SetActiveEx(false)
            end)
        end, function () CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, self.CameraCupture) end)
    end)
    XDataCenter.PhotographManager.SendPhotoGraphRequest()
end

function XUiPhotograph:SetProportionImage()
    local defaultHeight = self.ImageContainer.rect.height
    local ProportionValue = SCREEN_WIDTH / SCREEN_HEIGHT
    local screenWidth = math.floor(ProportionValue * defaultHeight)
    self.ImageContainer.sizeDelta =  Vector2(screenWidth, defaultHeight)

    self.ImgPicture.rectTransform.sizeDelta = Vector2(CsXUiManager.RealScreenWidth, CsXUiManager.RealScreenHeight)
end

function XUiPhotograph:CheckHasChanged()
    local curSceneId = XDataCenter.PhotographManager.GetCurSceneId()
    local curSelectSceneId = XDataCenter.PhotographManager.GetCurSelectSceneId()
    if curSceneId == curSelectSceneId and self.CurCharacterId == self.SelectCharacterId and self.CurFashionId == self.SelectFashionId then
        return false
    end

    return true
end

function XUiPhotograph:PlayChangeActionEffect()
    if self.ChangeActionEffect then
        self.ChangeActionEffect.gameObject:SetActive(false)
        self.ChangeActionEffect.gameObject:SetActive(true)
    end
end

function XUiPhotograph:UpdateBatteryMode() -- editor模式下 BatteryComponent.BatteryLevel 默认值为-1
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

    local curSelectSceneId = XDataCenter.PhotographManager.GetCurSelectSceneId()
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