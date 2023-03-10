local XUiRpgMakerGameCharacterGrid = require("XUi/XUiRpgMakerGame/Character/XUiRpgMakerGameCharacterGrid")

local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiRpgMakerGameCharacter = XLuaUiManager.Register(XLuaUi, "UiRpgMakerGameCharacter")

function XUiRpgMakerGameCharacter:OnAwake()
    self:AutoAddListener()
    self:InitDynamicTable()
    self:InitSceneRoot()

    self.GridCharacterNew.gameObject:SetActiveEx(false)
end

function XUiRpgMakerGameCharacter:OnStart(stageId)
    self.StageId = stageId
end

function XUiRpgMakerGameCharacter:OnEnable()
    local characterId = self:GetCharacterId()
    self:UpdateCurCharacterInfo(characterId)
    self.DynamicTable:ReloadDataSync()
end

function XUiRpgMakerGameCharacter:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, "RpgMakerGame")
    self.BtnEnterFight.CallBack = handler(self, self.OnBtnEnterFightClick)
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
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
    self.RoleModelPanel:SetDefaultAnimation("Stand1")
end

function XUiRpgMakerGameCharacter:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiRpgMakerGameCharacterGrid)

    self.CharacterList = XRpgMakerGameConfigs.GetRpgMakerGameRoleIdList()
    self.CharacterId = XDataCenter.RpgMakerGameManager.GetOnceUnLockRoleId()
    self.DynamicTable:SetDataSource(self.CharacterList)
end

function XUiRpgMakerGameCharacter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local characterId = self.CharacterList[index]
        local currSelectCharId = self:GetCharacterId()
        if currSelectCharId == characterId then
            self.CurSelectGrid = grid
        end
        grid:Refresh(characterId)
        grid:SetSelect(currSelectCharId == characterId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local characterId = self.CharacterList[index]
        local currSelectCharId = self:GetCharacterId()
        if currSelectCharId ~= characterId then
            if self.CurSelectGrid then
                self.CurSelectGrid:SetSelect(false)
            end
            grid:SetSelect(true)
            self.CurSelectGrid = grid
            self:UpdateCurCharacterInfo(characterId)
            self:UpdateBtnEnterFightState(characterId)
            self:PlaySwitchAnima(currSelectCharId, characterId)
            self:CheckOpenTips(characterId)
        end
    end
end

function XUiRpgMakerGameCharacter:CheckOpenTips(characterId)
    local isUnlock, desc = XDataCenter.RpgMakerGameManager.IsUnlockRole(characterId)
    if not isUnlock then
        XUiManager.TipMsg(desc)
    end
end

function XUiRpgMakerGameCharacter:PlaySwitchAnima(oldCharacterId, newCharacterId)
    self:PlayAnimation("QieHuan1")

    local isUnlockRoleOld = XDataCenter.RpgMakerGameManager.IsUnlockRole(oldCharacterId)
    local isUnlockRoleNew = XDataCenter.RpgMakerGameManager.IsUnlockRole(newCharacterId)

    if isUnlockRoleNew then
        self.ImgEffectHuanren.gameObject:SetActiveEx(false)
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    end

    --???3d??????????????????????????????2d????????????????????????????????????
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
    self.TextStyle.text = isUnlockRole and XRpgMakerGameConfigs.GetRpgMakerGameRoleStyle(characterId) or ""
    self.TextInfoName.text = isUnlockRole and XRpgMakerGameConfigs.GetRpgMakerGameRoleInfoName(characterId) or CSXTextManagerGetText("RpgMakerGameCharacterLockInfoTitle")
    self.TextInfo.text = isUnlockRole and XRpgMakerGameConfigs.GetRpgMakerGameRoleInfo(characterId) or CSXTextManagerGetText("RpgMakerGameCharacterLockInfoDesc")
    self:UpdateModel(characterId)
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
    self.RoleModelPanel:UpdateRoleModel(modelName, self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiCharacter, function(model)
        self.PanelDrag.Target = model.transform
    end, nil, true, true)
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