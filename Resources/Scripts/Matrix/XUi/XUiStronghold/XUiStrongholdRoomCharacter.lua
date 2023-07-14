local XUiPanelStrongholdRoomCharacterOthers = require("XUi/XUiStronghold/XUiPanelStrongholdRoomCharacterOthers")
local XUiPanelStrongholdRoomCharacterSelf = require("XUi/XUiStronghold/XUiPanelStrongholdRoomCharacterSelf")

local handler = handler
local IsNumberValid = XTool.IsNumberValid

local TabBtnIndex = {
    Normal = 1, --构造体
    Isomer = 2, --授格者
    Others = 3, --援助角色
}

local XUiStrongholdRoomCharacter = XLuaUiManager.Register(XLuaUi, "UiStrongholdRoomCharacter")

function XUiStrongholdRoomCharacter:OnAwake()
    self:AutoAddListener()

    local selectCharacterCb = handler(self, self.OnSelectCharacter)
    local closeUiFunc = handler(self, self.Close)
    local playAnimationCb = function(animName)
        self:PlayAnimationWithMask(animName)
    end
    self.OthersPanel = XUiPanelStrongholdRoomCharacterOthers.New(self.PanelOthers, selectCharacterCb, closeUiFunc, playAnimationCb, self)
    self.SelfPanel = XUiPanelStrongholdRoomCharacterSelf.New(self.PanelSelf, selectCharacterCb, closeUiFunc, playAnimationCb)

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BtnFilter.gameObject:SetActiveEx(false)
end

function XUiStrongholdRoomCharacter:OnStart(teamList, teamId, memberIndex, groupId)
    self.TeamList = teamList
    self.TeamId = teamId
    self.MemberIndex = memberIndex
    self.GroupId = groupId

    local member = self:GetMember()
    self.CharacterId = member:GetInTeamCharacterId()
    self.PlayerId = member:GetOthersPlayerId()

    self:InitModel()
    self:InitCharacterTypeBtns()

    XEventManager.AddEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.UpdateTeamPrefab, self)
end

function XUiStrongholdRoomCharacter:OnEnable()
    CS.XGraphicManager.UseUiLightDir = true

    if self.SelectTabIndex then
        self.PanelCharacterTypeBtns:SelectIndex(self.SelectTabIndex)
    end
end

function XUiStrongholdRoomCharacter:OnDisable()
    CS.XGraphicManager.UseUiLightDir = false
end

function XUiStrongholdRoomCharacter:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.UpdateTeamPrefab, self)
end

function XUiStrongholdRoomCharacter:InitCharacterTypeBtns()
    local lockShougezhe = not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer)
    self.BtnTabShougezhe:SetDisable(lockShougezhe, not lockShougezhe)
    self.BtnTabShougezhe.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Isomer))

    local isPrefab = self:IsPrefab()
    self.BtnTabHelp.gameObject:SetActiveEx(not isPrefab)

    local tabBtns = { self.BtnTabGouzaoti, self.BtnTabShougezhe, self.BtnTabHelp }
    self.PanelCharacterTypeBtns:Init(tabBtns, function(index) self:SelectPanel(index) end)

    local defaultIndex = self:GetDefaultTabBtnIndex()
    self.PanelCharacterTypeBtns:SelectIndex(defaultIndex)
end

function XUiStrongholdRoomCharacter:SelectPanel(index)
    if index == TabBtnIndex.Isomer then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Isomer) then return end
    end

    if self.CurPanel and self.CurPanel:IsLoading() then
        self.PanelCharacterTypeBtns:SelectIndex(self.SelectTabIndex, false)
        return
    end

    self.SelectTabIndex = index
    if index == TabBtnIndex.Normal then
        self.SelfPanel:Show(self.TeamList, self.TeamId, self.MemberIndex, self.GroupId)
        self.OthersPanel:Hide()
        self.CurPanel = self.SelfPanel
    elseif index == TabBtnIndex.Isomer then
        local isSelectIsomer = true
        self.SelfPanel:Show(self.TeamList, self.TeamId, self.MemberIndex, self.GroupId, isSelectIsomer)
        self.OthersPanel:Hide()
        self.CurPanel = self.SelfPanel
    elseif index == TabBtnIndex.Others then
        self.SelfPanel:Hide()
        self.OthersPanel:Show(self.TeamList, self.TeamId, self.MemberIndex, self.GroupId)
        self.CurPanel = self.OthersPanel
    end

    local id = IsNumberValid(self.PlayerId) and self.PlayerId or self.CharacterId
    self.CurPanel:SelectCharacter(id)
end

function XUiStrongholdRoomCharacter:OnSelectCharacter(characterId, playerId)
    self.CharacterId = characterId
    self.PlayerId = playerId
    self:UpdateRoleModel()
end

function XUiStrongholdRoomCharacter:UpdateRoleModel()
    local playerId = self.PlayerId

    local characterId = self.CharacterId
    if XRobotManager.CheckIsRobotId(self.CharacterId) then
        characterId = XRobotManager.GetCharacterId(self.CharacterId)
    end

    if not IsNumberValid(characterId) then
        self.RoleModelPanel.GameObject:SetActiveEx(false)
        return
    end
    self.RoleModelPanel.GameObject:SetActiveEx(true)

    local targetPanelRole = self.PanelRoleModel
    local targetUiName = self.Name
    local cb = function(model)
        if not model then return end
        self.PanelDrag.Target = model.transform
        if self.SelectTabIndex == TabBtnIndex.Normal then
            self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        elseif self.SelectTabIndex == TabBtnIndex.Isomer then
            self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
        end
    end

    if XRobotManager.CheckIsRobotId(self.CharacterId) then
        local robotId = self.CharacterId
        local robotCfg = XRobotManager.GetRobotTemplate(robotId)
        local fashionId = robotCfg.FashionId
        local weaponId = robotCfg.WeaponId

        self.ImgEffectHuanren.gameObject:SetActiveEx(false)
        self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
        self.RoleModelPanel:UpdateRobotModel(robotId, characterId, nil, fashionId, weaponId, cb)

    else
        local fashionId = nil
        local growUpLevel = nil
        if IsNumberValid(playerId) then
            --别人的角色信息
            fashionId = XDataCenter.StrongholdManager.GetAssistantPlayerFashionId(playerId)
            growUpLevel = XDataCenter.StrongholdManager.GetAssistantPlayerLiberateLv(playerId)
        end

        self.ImgEffectHuanren.gameObject:SetActiveEx(false)
        self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
        self.RoleModelPanel:UpdateCharacterModel(characterId, targetPanelRole, targetUiName, cb, nil, fashionId, growUpLevel)
    end
end

function XUiStrongholdRoomCharacter:InitModel()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true)
end

function XUiStrongholdRoomCharacter:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
end

function XUiStrongholdRoomCharacter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiStrongholdRoomCharacter:OnBtnBackClick()
    self:Close()
end

function XUiStrongholdRoomCharacter:GetTeam()
    return self.TeamList[self.TeamId]
end

function XUiStrongholdRoomCharacter:GetMember()
    local team = self:GetTeam()
    return team:GetMember(self.MemberIndex)
end

function XUiStrongholdRoomCharacter:GetDefaultTabBtnIndex()
    local tabIndex = TabBtnIndex.Normal

    local member = self:GetMember()
    local groupId = self.GroupId
    local stageIndex = self.TeamId
    local stageId = groupId and stageIndex and XDataCenter.StrongholdManager.GetGroupStageId(groupId, stageIndex)
    local characterLimitType = stageId and XFubenConfigs.GetStageCharacterLimitType(stageId)

    if member:IsAssitant() and not self:IsPrefab() then
        tabIndex = TabBtnIndex.Others
    elseif member:IsIsomer() or (self.CharacterId == 0 and (characterLimitType == XFubenConfigs.CharacterLimitType.Isomer or characterLimitType == XFubenConfigs.CharacterLimitType.NormalDebuff)) then
        tabIndex = TabBtnIndex.Isomer
    end

    return tabIndex
end

function XUiStrongholdRoomCharacter:IsPrefab()
    return not IsNumberValid(self.GroupId)
end

function XUiStrongholdRoomCharacter:UpdateTeamPrefab(team)
    self.SelfPanel:UpdateTeamPrefab(team)
end