local XUiRpgMakerGameCharacterGrid = require("XUi/XUiRpgMakerGame/Character/XUiRpgMakerGameCharacterGrid")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiPanelGraphic = require("XUi/XUiRpgMakerGame/Character/XUiPanelGraphic")

local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiRpgMakerGameCharacter = XLuaUiManager.Register(XLuaUi, "UiRpgMakerGameCharacter")

function XUiRpgMakerGameCharacter:OnAwake()
    self:AutoAddListener()
    self:InitSceneRoot()
    self.GraphicPanel = XUiPanelGraphic.New(self.PanelGraphic, self)
    self.GridCharacterNew.gameObject:SetActiveEx(false)
end

function XUiRpgMakerGameCharacter:OnStart(stageId)
    self.StageId = stageId
    --限定使用的角色Id
    self.OnlyUseRoleId = XRpgMakerGameConfigs.GetStageUseRoleId(stageId)
    self:InitDynamicTable()
end

function XUiRpgMakerGameCharacter:OnEnable()
    local characterId = self:GetCharacterId()
    self:UpdateCurCharacterInfo(characterId)
    self.DynamicTable:ReloadDataSync()
end

function XUiRpgMakerGameCharacter:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self.BtnEnterFight.CallBack = handler(self, self.OnBtnEnterFightClick)

    local curChapterGroupId = XDataCenter.RpgMakerGameManager.GetCurChapterGroupId()
    self:BindHelpBtn(self.BtnHelp, XRpgMakerGameConfigs.GetChapterGroupHelpKey(curChapterGroupId))
end

function XUiRpgMakerGameCharacter:InitSceneRoot()
    local root = self.UiModelGo.transform

    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
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
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name)
end

function XUiRpgMakerGameCharacter:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiRpgMakerGameCharacterGrid)

    local useRoleId = self.OnlyUseRoleId
    self.CharacterList = XRpgMakerGameConfigs.GetRpgMakerGameRoleIdList()
    self.CharacterId = XTool.IsNumberValid(useRoleId) and useRoleId or XDataCenter.RpgMakerGameManager.GetOnceUnLockRoleId()
    self.DynamicTable:SetDataSource(self.CharacterList)
end

function XUiRpgMakerGameCharacter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local characterId = self.CharacterList[index]
        local currSelectCharId = self:GetCharacterId()
        if currSelectCharId == characterId then
            self.CurSelectGrid = grid
        end
        grid:Refresh(characterId, self.OnlyUseRoleId)
        grid:SetSelect(currSelectCharId == characterId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local characterId = self.CharacterList[index]
        local onlyUseRoleId = self.OnlyUseRoleId
        if XTool.IsNumberValid(onlyUseRoleId) and onlyUseRoleId ~= characterId then
            XUiManager.TipErrorWithKey("RpaMakerGameOnlyUseRole")
            return
        end

        local currSelectCharId = self:GetCharacterId()
        if currSelectCharId ~= characterId and self:CheckOpenTips(characterId) then
            if self.CurSelectGrid then
                self.CurSelectGrid:SetSelect(false)
            end
            grid:SetSelect(true)
            self.CurSelectGrid = grid
            self:UpdateCurCharacterInfo(characterId)
            self:UpdateBtnEnterFightState(characterId)
            self:PlaySwitchAnima(currSelectCharId, characterId)
        end
    end
end

function XUiRpgMakerGameCharacter:CheckOpenTips(characterId)
    local isUnlock, desc = XDataCenter.RpgMakerGameManager.IsUnlockRole(characterId)
    if not isUnlock then
        XUiManager.TipMsg(desc)
    end
    return isUnlock
end

function XUiRpgMakerGameCharacter:PlaySwitchAnima(oldCharacterId, newCharacterId)
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

function XUiRpgMakerGameCharacter:UpdateBtnEnterFightState(characterId)
    local isUnlockRole, desc = XDataCenter.RpgMakerGameManager.IsUnlockRole(characterId)
    self.BtnEnterFight:SetDisable(not isUnlockRole, isUnlockRole)
    self.TextStyleTitle.gameObject:SetActiveEx(isUnlockRole)
    if not isUnlockRole then
        self.BtnEnterFight:SetNameByGroup(1, desc)
    end
end

function XUiRpgMakerGameCharacter:UpdateCurCharacterInfo(characterId)
    local isUnlockRole = XDataCenter.RpgMakerGameManager.IsUnlockRole(characterId)
    self.CharacterId = characterId
    self.TextName.text = isUnlockRole and XRpgMakerGameConfigs.GetRpgMakerGameRoleName(characterId) or CSXTextManagerGetText("RpgMakerGameCharacterLockName")
    local roleSkillType = XRpgMakerGameConfigs.GetRpgMakerGameRoleSkillType(characterId)
    if XTool.IsNumberValid(roleSkillType) and self.ImgAttribute then
        self.ImgAttribute:SetSprite(XRpgMakerGameConfigs.GetRpgMakerGameSkillTypeIcon(roleSkillType))
    end
    if self.ImgAttribute then
        self.ImgAttribute.gameObject:SetActiveEx(XTool.IsNumberValid(roleSkillType))
    end
    self.TextStyle.text = isUnlockRole and XRpgMakerGameConfigs.GetRpgMakerGameRoleStyle(characterId) or ""
    self.TextInfoName.text = isUnlockRole and XRpgMakerGameConfigs.GetRpgMakerGameRoleInfoName(characterId) or CSXTextManagerGetText("RpgMakerGameCharacterLockInfoTitle")
    self.TxtEnergy.text = isUnlockRole and XRpgMakerGameConfigs.GetRpgMakerGameRoleInfo(characterId) or CSXTextManagerGetText("RpgMakerGameCharacterLockInfoDesc")
    self:UpdateModel(characterId)
    self.GraphicPanel:Refresh(characterId)
end

function XUiRpgMakerGameCharacter:UpdateModel(characterId)
    local isUnlockRole = XDataCenter.RpgMakerGameManager.IsUnlockRole(characterId)
    self.PanelDrag.gameObject:SetActiveEx(isUnlockRole)
    if self.PanelDragLock then
        self.PanelDragLock.gameObject:SetActiveEx(not isUnlockRole)
    end

    if not isUnlockRole then
        self.RoleModelPanel:HideRoleModel()
        return
    end

    local modelName = XRpgMakerGameConfigs.GetRpgMakerGameRoleModelAssetPath(characterId)
    self.RoleModelPanel:UpdateRoleModelWithAutoConfig(modelName, XModelManager.MODEL_UINAME.XUiCharacter, function(model)
        self.PanelDrag.Target = model.transform
    end)
    self.RoleModelPanel:ShowRoleModel()
end

function XUiRpgMakerGameCharacter:OnBtnEnterFightClick()
    local stageId = self:GetStageId()
    local characterId = self:GetCharacterId()
    local cb = function()
        XLuaUiManager.Remove("UiRpgMakerGameDetail")
        XLuaUiManager.PopThenOpen("UiRpgMakerGamePlayMain")
    end
    XDataCenter.RpgMakerGameManager.RequestRpgMakerGameEnterStage(stageId, characterId, cb)
end

function XUiRpgMakerGameCharacter:GetCharacterId()
    return self.CharacterId
end

function XUiRpgMakerGameCharacter:GetStageId()
    return self.StageId
end