local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XSignBoardPlayer = require("XCommon/XSignBoardPlayer")

---@class XUiCharacterTowerPhotograph : XLuaUi
local XUiCharacterTowerPhotograph = XLuaUiManager.Register(XLuaUi, "UiCharacterTowerPhotograph")

function XUiCharacterTowerPhotograph:OnAwake()
    self:RegisterUiEvents()
    local signBoardPlayer = XSignBoardPlayer.New(self, CS.XGame.ClientConfig:GetInt("SignBoardPlayInterval"), CS.XGame.ClientConfig:GetFloat("SignBoardDelayInterval"))
    local playerData = XMVCA.XFavorability:GetSignBoardPlayerData()
    signBoardPlayer:SetPlayerData(playerData)
    self.SignBoardPlayer = signBoardPlayer
end

function XUiCharacterTowerPhotograph:OnStart(signBoardActionId)
    self.SignBoardActionId = signBoardActionId
    local actionConfig = XMVCA.XFavorability:GetCharacterActionBySignBoardActionId(signBoardActionId)
    self.CurCharacterId = actionConfig.CharacterId
    self:InitLoadScene()
    self.Parent = self
    
    -- 名字
    self.TxtActionName.text = XMVCA.XFavorability:GetCharacterActionMapText(actionConfig.Name)
end

function XUiCharacterTowerPhotograph:OnEnable()
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

    self.Enable = true
    
    -- 播放动作
    self:ForcePlay(self.SignBoardActionId)
end

function XUiCharacterTowerPhotograph:Update()
    if not self.Enable then
        return
    end
    
    local dt = CS.UnityEngine.Time.deltaTime
    if self.SignBoardPlayer then
        self.SignBoardPlayer:Update(dt)
    end
end

function XUiCharacterTowerPhotograph:OnDisable()
    if self.Timer ~= nil then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end

    if self.SignBoardPlayer then
        self.SignBoardPlayer:OnDisable()
    end

    self.Enable = false
end

function XUiCharacterTowerPhotograph:OnDestroy()
    if self.Timer ~= nil then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end

    if self.SignBoardPlayer then
        self.SignBoardPlayer:OnDestroy()
    end
end

function XUiCharacterTowerPhotograph:InitLoadScene()
    local curSceneId = XDataCenter.PhotographManager.GetCurSceneId()
    local curSceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(curSceneId)
    local curSceneUrl, modelUrl = XSceneModelConfigs.GetSceneAndModelPathById(curSceneTemplate.SceneModelId)
    self:LoadUiScene(curSceneUrl, modelUrl, handler(self, self.OnUiSceneLoaded), false)
end

function XUiCharacterTowerPhotograph:OnUiSceneLoaded()
    --self:SetGameObject()
    self:InitSceneRoot()
    self:UpdateRoleModel(self.CurCharacterId)
    self:UpdateCamera()
end

function XUiCharacterTowerPhotograph:InitSceneRoot()
    local root = self.UiModelGo.transform
    self.CameraFar = self:FindVirtualCamera("CamFarMain")
    self.CameraNear = self:FindVirtualCamera("CamNearMain")
    self.UiModelParent = root:FindTransform("UiModelParent")
    self.ChangeActionEffect = root:FindTransform("ChangeActionEffect")
    self.RoleModel = XUiPanelRoleModel.New(self.UiModelParent, self.Name, true, true, false, true, nil, nil, true)
end

function XUiCharacterTowerPhotograph:UpdateRoleModel(characterId)
    XDataCenter.DisplayManager.UpdateRoleModel(self.RoleModel, characterId)
    self.RoleAnimator = self.RoleModel:GetAnimator()
end

function XUiCharacterTowerPhotograph:UpdateCamera()
    self.CameraFar.gameObject:SetActiveEx(true)
    self.CameraNear.gameObject:SetActiveEx(true)
end

function XUiCharacterTowerPhotograph:ForcePlay(signBoardActionId)
    local config = XMVCA.XFavorability:GetSignBoardConfigById(signBoardActionId)
    if self.SignBoardPlayer:GetInterruptDetection() and self.SignBoardPlayer.PlayerData.PlayingElement.Id ~= config.Id then
        self:PlayChangeActionEffect()
    end
    self:ChangeAnimationState(false)
    self:SetBtnPlayState(false)
    XScheduleManager.ScheduleNextFrame(function()
        self.SignBoardPlayer:ForcePlayCross(config)
    end)
    self.SignBoardPlayer:SetInterruptDetection(true)
end

function XUiCharacterTowerPhotograph:Replay()
    if not XTool.IsNumberValid(self.SignBoardActionId) then
        return
    end
    self.SignBoardPlayer:Stop()
    self:ForcePlay(self.SignBoardActionId)
end

function XUiCharacterTowerPhotograph:PlayCross(element)
    if not element then
        return
    end
    self:RefreshAction(true, self.SignBoardActionId ~= nil)
    if element.SignBoardConfig.CvId and element.SignBoardConfig.CvId > 0 then
        if element.CvType then
            self.PlayingCv = XLuaAudioManager.PlayCvWithCvType(element.SignBoardConfig.CvId, element.CvType)
        else
            self.PlayingCv = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Voice, element.SignBoardConfig.CvId)
        end
    end

    local actionId = element.SignBoardConfig.ActionId
    if actionId then
        self.RoleModel:PlayAnimaCross(actionId, true)
        self.RoleModel:LoadCharacterUiEffect(tonumber(element.SignBoardConfig.RoleId), actionId)
    end
end

--停止
function XUiCharacterTowerPhotograph:OnStop(playingElement, force)
    if self.PlayingCv then
        self.PlayingCv:Stop()
        self.PlayingCv = nil
    end
    self:RefreshAction(false, self.SignBoardActionId ~= nil)
    if playingElement then
        self.RoleModel:StopAnima(playingElement.SignBoardConfig.ActionId, force)
        self.RoleModel:LoadCurrentCharacterDefaultUiEffect()
    end
    self.SignBoardPlayer:SetInterruptDetection(false)
end

function XUiCharacterTowerPhotograph:PlayChangeActionEffect()
    if self.ChangeActionEffect then
        self.ChangeActionEffect.gameObject:SetActive(false)
        self.ChangeActionEffect.gameObject:SetActive(true)
    end
end

function XUiCharacterTowerPhotograph:ChangeAnimationState(pause)
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

-- 播放场景动画
function XUiCharacterTowerPhotograph:PlaySceneAnim(element)
    if not element then
        return
    end
    local animRoot = self.UiModelGo.transform
    local sceneId = XDataCenter.PhotographManager.GetCurSelectSceneId()
    local sighBoardId = element.SignBoardConfig.Id
    XMVCA.XFavorability:LoadSceneAnim(animRoot, self.CameraFar, self.CameraNear, sceneId, sighBoardId, self)
    XMVCA.XFavorability:SceneAnimPlay()
end

function XUiCharacterTowerPhotograph:RefreshAction(isPlaying, cacheAnim)
    self.BtnPaly.gameObject:SetActiveEx(isPlaying)
    self.BtnAgain.gameObject:SetActiveEx(cacheAnim)
    if self.TxtActionName then
        self.TxtActionName.gameObject:SetActiveEx(isPlaying or cacheAnim)
    end
    self:SetBtnPlayState(self.SignBoardPlayer.Status == 3)
end

function XUiCharacterTowerPhotograph:SetBtnPlayState(select)
    self.BtnPaly:SetButtonState(select and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiCharacterTowerPhotograph:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPaly, self.OnBtnPalyClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAgain, self.OnBtnAgainClick)
end

function XUiCharacterTowerPhotograph:OnBtnBackClick()
    self:Close()
end

function XUiCharacterTowerPhotograph:OnBtnPalyClick()
    self:ChangeAnimationState(self.BtnPaly:GetToggleState())
end

function XUiCharacterTowerPhotograph:OnBtnAgainClick()
    self:Replay()
end

return XUiCharacterTowerPhotograph