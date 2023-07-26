local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiPanelGraphic = require("XUi/XUiRpgMakerGame/Character/XUiPanelGraphic")

local CSXTextManagerGetText = CS.XTextManager.GetText

---推箱子4.0 本体和复制体
local XUiRpgMakerGameChoice = XLuaUiManager.Register(XLuaUi, "UiRpgMakerGameChoice")

function XUiRpgMakerGameChoice:OnAwake()
    self:AutoAddListener()
    self:InitSceneRoot()
    self.GraphicPanelRight = XUiPanelGraphic.New(self.PanelGraphicRight, self)
    self.GraphicPanelLeft = XUiPanelGraphic.New(self.PanelGraphicLeft, self)
end

function XUiRpgMakerGameChoice:OnStart(stageId)
    self.StageId = stageId
    --限定使用的角色Id
    self.OnlyUseRoleId = XRpgMakerGameConfigs.GetStageUseRoleId(stageId)
    self:InitCharacter()
end

function XUiRpgMakerGameChoice:OnEnable()
    local characterId = self:GetCharacterId()
    local copyCharacterId = XRpgMakerGameConfigs.GetStageShadowId(self.StageId)
    self.PanelDrag.gameObject:SetActiveEx(false)
    if self.PanelDragLock then
        self.PanelDragLock.gameObject:SetActiveEx(false)
    end
    self:UpdateLeftCharacterInfo(characterId)
    self:UpdateRightCharacterInfo(copyCharacterId)
    self:UpdateLeftModel(characterId)
    self:UpdateRightModel(copyCharacterId)
end

function XUiRpgMakerGameChoice:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self.BtnEnterFight.CallBack = handler(self, self.OnBtnEnterFightClick)

    local curChapterGroupId = XDataCenter.RpgMakerGameManager.GetCurChapterGroupId()
    self:BindHelpBtn(self.BtnHelp, XRpgMakerGameConfigs.GetChapterGroupHelpKey(curChapterGroupId))
end

function XUiRpgMakerGameChoice:InitSceneRoot()
    local root = self.UiModelGo.transform

    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.PanelRoleModel2 = root:FindTransform("PanelRoleModel2")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.ImgEffectLogoGouzao = root:FindTransform("ImgEffectLogoGouzao")
    self.ImgEffectLogoGanran = root:FindTransform("ImgEffectLogoGanran")
    self.CameraFar = {
        root:FindTransform("UiCamFarLv"),
        root:FindTransform("UiCamFarGrade"),
        root:FindTransform("UiCamFarQuality"),
        root:FindTransform("UiCamFarSkill"),
        root:FindTransform("UiCamFarrExchange"),
    }
    self.CameraNear = {
        root:FindTransform("UiCamNearLv"),
        root:FindTransform("UiCamNearGrade"),
        root:FindTransform("UiCamNearQuality"),
        root:FindTransform("UiCamNearSkill"),
        root:FindTransform("UiCamNearrExchange"),
    }
    self.RightRoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name)
    self.LeftRoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel2, self.Name)
end

function XUiRpgMakerGameChoice:InitCharacter()
    local useRoleId = self.OnlyUseRoleId
    self.LeftCharacterId = XTool.IsNumberValid(useRoleId) and useRoleId or XDataCenter.RpgMakerGameManager.GetOnceUnLockRoleId()
end

function XUiRpgMakerGameChoice:CheckOpenTips(characterId)
    local isUnlock, desc = XDataCenter.RpgMakerGameManager.IsUnlockRole(characterId)
    if not isUnlock then
        XUiManager.TipMsg(desc)
    end
    return isUnlock
end

function XUiRpgMakerGameChoice:PlaySwitchAnima(oldCharacterId, newCharacterId)
    self:PlayAnimation("QieHuan1")

    local isUnlockRoleOld = XDataCenter.RpgMakerGameManager.IsUnlockRole(oldCharacterId)
    local isUnlockRoleNew = XDataCenter.RpgMakerGameManager.IsUnlockRole(newCharacterId)

    if isUnlockRoleNew then
        self.ImgEffectHuanren.gameObject:SetActiveEx(false)
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    end

    --从3d角色（已解锁）切换到2d立绘（未解锁）播放的动画
    if not isUnlockRoleNew and isUnlockRoleOld ~= isUnlockRoleNew then
        self:PlayAnimation("QieHuan2")
    end
end

function XUiRpgMakerGameChoice:UpdateBtnEnterFightState(characterId)
    local isUnlockRole, desc = XDataCenter.RpgMakerGameManager.IsUnlockRole(characterId)
    self.BtnEnterFight:SetDisable(not isUnlockRole, isUnlockRole)
    self.TextStyleTitle.gameObject:SetActiveEx(isUnlockRole)
    if not isUnlockRole then
        self.BtnEnterFight:SetNameByGroup(1, desc)
    end
end

---复制体介绍面板
function XUiRpgMakerGameChoice:UpdateRightCharacterInfo(characterId)
    if not XTool.IsNumberValid(characterId) then return end
    local isUnlockRole = XDataCenter.RpgMakerGameManager.IsUnlockRole(characterId)
    self.RightCharacterId = characterId
    self.TextNameRight.text = isUnlockRole and XRpgMakerGameConfigs.GetRpgMakerGameRoleName(characterId) or CSXTextManagerGetText("RpgMakerGameCharacterLockName")
    self.TextStyleRight.text = isUnlockRole and XRpgMakerGameConfigs.GetRpgMakerGameRoleStyle(characterId) or ""
    self.TextInfoNameRight.text = isUnlockRole and XRpgMakerGameConfigs.GetRpgMakerGameRoleInfoName(characterId) or CSXTextManagerGetText("RpgMakerGameCharacterLockInfoTitle")
    self.TxtEnergyRight.text = isUnlockRole and XRpgMakerGameConfigs.GetRpgMakerGameRoleInfo(characterId) or CSXTextManagerGetText("RpgMakerGameCharacterLockInfoDesc")
    self.GraphicPanelRight:Refresh(characterId)

    self.ImgAttributeRight = XUiHelper.TryGetComponent(self.TextNameRight.transform, "ImgAttribute", "RawImage")
    local roleSkillType = XRpgMakerGameConfigs.GetRpgMakerGameRoleSkillType(characterId)
    if XTool.IsNumberValid(roleSkillType) and self.ImgAttributeRight then
        self.ImgAttributeRight:SetRawImage(XRpgMakerGameConfigs.GetRpgMakerGameSkillTypeIcon(roleSkillType))
    end
    if self.ImgAttributeRight then
        self.ImgAttributeRight.gameObject:SetActiveEx(XTool.IsNumberValid(roleSkillType))
    end
end

---本体介绍面板
function XUiRpgMakerGameChoice:UpdateLeftCharacterInfo(characterId)
    if not XTool.IsNumberValid(characterId) then return end
    local isUnlockRole = XDataCenter.RpgMakerGameManager.IsUnlockRole(characterId)
    self.LeftCharacterId = characterId
    self.TextNameLeft.text = isUnlockRole and XRpgMakerGameConfigs.GetRpgMakerGameRoleName(characterId) or CSXTextManagerGetText("RpgMakerGameCharacterLockName")
    self.TextStyleLeft.text = isUnlockRole and XRpgMakerGameConfigs.GetRpgMakerGameRoleStyle(characterId) or ""
    self.TextInfoNameLeft.text = isUnlockRole and XRpgMakerGameConfigs.GetRpgMakerGameRoleInfoName(characterId) or CSXTextManagerGetText("RpgMakerGameCharacterLockInfoTitle")
    self.TxtEnergyLeft.text = isUnlockRole and XRpgMakerGameConfigs.GetRpgMakerGameRoleInfo(characterId) or CSXTextManagerGetText("RpgMakerGameCharacterLockInfoDesc")

    self.GraphicPanelLeft:Refresh(characterId)
    self.ImgAttributeLeft = XUiHelper.TryGetComponent(self.TextNameLeft.transform, "ImgAttribute", "RawImage")
    local roleSkillType = XRpgMakerGameConfigs.GetRpgMakerGameRoleSkillType(characterId)
    if XTool.IsNumberValid(roleSkillType) and self.ImgAttributeLeft then
        self.ImgAttributeLeft:SetRawImage(XRpgMakerGameConfigs.GetRpgMakerGameSkillTypeIcon(roleSkillType))
    end
    if self.ImgAttributeLeft then
        self.ImgAttributeLeft.gameObject:SetActiveEx(XTool.IsNumberValid(roleSkillType))
    end
end

-- 复制体模型
function XUiRpgMakerGameChoice:UpdateRightModel(copyCharacterId)
    if not XTool.IsNumberValid(copyCharacterId) then return end
    local isUnlockRole = XDataCenter.RpgMakerGameManager.IsUnlockRole(copyCharacterId)

    if not isUnlockRole then
        self.RightRoleModelPanel:HideRoleModel()
        return
    end

    local copyModelName = XRpgMakerGameConfigs.GetRpgMakerGameRoleModelAssetPath(copyCharacterId)
    self.RightRoleModelPanel:UpdateRoleModelWithAutoConfig(copyModelName, XModelManager.MODEL_UINAME.XUiCharacter, function(model)
        -- self.PanelDrag.Target = model.transform
    end)
    self.RightRoleModelPanel:SetEffectMaxCount(2)
    local skillModelKey = XRpgMakerGameConfigs.GetModelSkillShadowEffctKey(XRpgMakerGameConfigs.GetRoleSkillType(copyCharacterId))
    if not skillModelKey then return end
    local effectPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(skillModelKey)
    self.RightRoleModelPanel:LoadEffect(effectPath, skillModelKey, true, true, false)
    self.RightRoleModelPanel:ShowRoleModel()
    local effect = self.RightRoleModelPanel:GetEffectObj(skillModelKey, effectPath)
    if effect then
        effect.gameObject:SetLayerRecursively(CS.UnityEngine.LayerMask.NameToLayer("UiNear"))
    end
end

function XUiRpgMakerGameChoice:UpdateLeftModel(characterId)
    local isUnlockRole = XDataCenter.RpgMakerGameManager.IsUnlockRole(characterId)

    if not isUnlockRole then
        self.LeftRoleModelPanel:HideRoleModel()
        return
    end

    local modelName = XRpgMakerGameConfigs.GetRpgMakerGameRoleModelAssetPath(characterId)
    self.LeftRoleModelPanel:UpdateRoleModelWithAutoConfig(modelName, XModelManager.MODEL_UINAME.XUiCharacter, function(model)
        -- self.PanelDrag.Target = model.transform
    end)
    self.LeftRoleModelPanel:ShowRoleModel()
end

function XUiRpgMakerGameChoice:OnBtnEnterFightClick()
    local stageId = self:GetStageId()
    local characterId = self:GetCharacterId()
    local cb = function()
        XLuaUiManager.Remove("UiRpgMakerGameDetail")
        XLuaUiManager.PopThenOpen("UiRpgMakerGamePlayMain")
    end
    XDataCenter.RpgMakerGameManager.RequestRpgMakerGameEnterStage(stageId, characterId, cb)
end

function XUiRpgMakerGameChoice:GetCharacterId()
    return self.LeftCharacterId
end

function XUiRpgMakerGameChoice:GetStageId()
    return self.StageId
end