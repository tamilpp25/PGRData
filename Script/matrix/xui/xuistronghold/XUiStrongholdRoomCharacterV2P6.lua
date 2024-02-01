local XUiPanelStrongholdRoomCharacterOthersV2P6 = require("XUi/XUiStronghold/XUiPanelStrongholdRoomCharacterOthersV2P6")
local XUiPanelStrongholdRoomCharacterSelfV2P6 = require("XUi/XUiStronghold/XUiPanelStrongholdRoomCharacterSelfV2P6")

local XUiGridStrongholdCharacter = require("XUi/XUiStronghold/XUiGridStrongholdCharacter")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local handler = handler
local IsNumberValid = XTool.IsNumberValid

local TabBtnIndex = {
    Normal = 1, --构造体
    Isomer = 2, --授格者
    Others = 3 --援助角色
}

local XUiStrongholdRoomCharacterV2P6 = XLuaUiManager.Register(XLuaUi, "UiStrongholdRoomCharacterV2P6")

function XUiStrongholdRoomCharacterV2P6:OnAwake()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
    ag = XMVCA:GetAgency(ModuleId.XCommonCharacterFilter)
    ---@type XCommonCharacterFilterAgency
    self.FiltAgecy = ag

    self:AutoAddListener()

    local closeUiFunc = handler(self, self.Close)
    local playAnimationCb = function(animName)
        self:PlayAnimationWithMask(animName)
    end
    self.SelfPanel = XUiPanelStrongholdRoomCharacterSelfV2P6.New(self.PanelSelf, self, nil, closeUiFunc, playAnimationCb)
    self.OthersPanel = XUiPanelStrongholdRoomCharacterOthersV2P6.New(self.PanelOthers, self, nil, closeUiFunc, playAnimationCb, self)
    
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BtnFilter.gameObject:SetActiveEx(false)
end

function XUiStrongholdRoomCharacterV2P6:InitFilter()
    self.PanelFilter = self.FiltAgecy:InitFilter(self.PanelCharacterFilter, self)
    -- 选中角色回调
    local onSeleCb = function (character, index, grid)
        if not character then
            return
        end
        self:OnSelectCharacter(character.Id)
    end
    -- 点击标签回调
    local onTagClick = function (btn)
        self:SelectPanel()
    end
    -- 刷新格子回调
    local refreshFun = function (index, grid, data)
        local charId = data.Id
        local playerId = nil
        if self:CheckIsOtherPlayer() then
            playerId = data.Id
            charId = XDataCenter.StrongholdManager.GetAssistantPlayerCharacterId(playerId)
        end
        grid:Refresh(charId, self.GroupId, self.TeamId, self.TeamList, playerId)
    end
    -- 是否在队伍中
    local checkInTeam = function (id)
        return not XDataCenter.StrongholdManager.CheckInTeamList(id, self.TeamList)
    end
    -- 重写排序算法
    local overrideFunTable = XDataCenter.StrongholdManager.GotOverrideSortList(self.InitSelectCharId, self.GroupId, self.TeamId)
    self.PanelFilter:InitData(onSeleCb, onTagClick, nil, refreshFun, XUiGridStrongholdCharacter, checkInTeam, overrideFunTable)
    -- 导入列表并刷新
    local list = XDataCenter.StrongholdManager.GetAllCanUseCharacterOrRobotIds(self.GroupId)
    self.PanelFilter:ImportList(list, self.InitSelectCharId)
    -- 导入支援列表
    self:ImportSupportList()
    -- 选中支援角色
    local isAssitant, playerId = self.TeamList[self.TeamId]:IsCharacterAssitant(self.InitSelectCharId)
    if isAssitant then
        self.PanelFilter:DoSelectTag("BtnSupport")
        local tempList = XDataCenter.StrongholdManager.GetAssistantPlayerIds(self.GroupId, self.TeamId, self.TeamList)
        self.InitChooseIndex = table.indexof(tempList, playerId)
    end
end

function XUiStrongholdRoomCharacterV2P6:ImportSupportList()
    local tempList = XDataCenter.StrongholdManager.GetAssistantPlayerIds(self.GroupId, self.TeamId, self.TeamList)
    local supportList = {}
    for k, id in pairs(tempList) do
        table.insert(supportList, {Id = id})
    end
    self.PanelFilter:ImportSupportList(supportList)
end

function XUiStrongholdRoomCharacterV2P6:OnStart(teamList, teamId, memberIndex, groupId, pos)
    self.TeamList = teamList
    self.TeamId = teamId
    self.MemberIndex = memberIndex
    self.GroupId = groupId
    self.Pos = pos

    local member = self:GetMember()
    local initCharacterId = member:GetInTeamCharacterId()
    self.InitSelectCharId = initCharacterId
    self.PlayerId = member:GetOthersPlayerId()

    self:InitModel()
    self:InitFilter()

    XEventManager.AddEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.UpdateTeamPrefab, self)
end

function XUiStrongholdRoomCharacterV2P6:OnEnable()
    CS.XGraphicManager.UseUiLightDir = true
    self.PanelFilter:RefreshList(self.InitChooseIndex)
    self.InitChooseIndex = nil
end

function XUiStrongholdRoomCharacterV2P6:OnDisable()
    CS.XGraphicManager.UseUiLightDir = false
end

function XUiStrongholdRoomCharacterV2P6:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.UpdateTeamPrefab, self)
end

function XUiStrongholdRoomCharacterV2P6:CheckIsOtherPlayer()
    return self.PanelFilter:IsTagSupport()
end

function XUiStrongholdRoomCharacterV2P6:SelectPanel()
    local isEmpty = self.PanelFilter:IsCurListEmpty()
    if self:CheckIsOtherPlayer() then
        self.SelfPanel:Close()
        if isEmpty then
            self.OthersPanel:Close()
        else
            self.OthersPanel:Open()
        end
        self.OthersPanel:Show(self.TeamList, self.TeamId, self.MemberIndex, self.GroupId)
        self.PanelRefresh.gameObject:SetActiveEx(true)
        self.CurPanel = self.OthersPanel
    else
        self.OthersPanel:Close()
        if isEmpty then
            self.SelfPanel:Close()
        else
            self.SelfPanel:Open()
        end
        self.SelfPanel:Show(self.TeamList, self.TeamId, self.MemberIndex, self.GroupId, false, self.Pos)
        self.PanelRefresh.gameObject:SetActiveEx(false)
        self.CurPanel = self.SelfPanel
    end

    --角色列表为空，不显示按钮
    self.BtnTeaching.gameObject:SetActiveEx(not isEmpty)
end

function XUiStrongholdRoomCharacterV2P6:OnSelectCharacter(characterId)
    self.CharacterId = characterId
    self:UpdateRoleModel()
    if self.CurPanel then
        self.CurPanel:Refresh() -- 面板的刷新统一由角色选中刷新
    end

    XRedPointManager.CheckOnceByButton(self.BtnTeaching, { XRedPointConditions.Types.CONDITION_CELICA_TEACH }, self.CharacterId)
end

function XUiStrongholdRoomCharacterV2P6:UpdateRoleModel()
    local characterId = self.CharacterId
    local playerId = nil
    if XRobotManager.CheckIsRobotId(self.CharacterId) then
        characterId = XRobotManager.GetCharacterId(self.CharacterId)
    end

    --别人的角色信息
    if self:CheckIsOtherPlayer() then
        playerId = self.CharacterId
        characterId = XDataCenter.StrongholdManager.GetAssistantPlayerCharacterId(characterId)
    end

    if not IsNumberValid(characterId) then
        self.RoleModelPanel.GameObject:SetActiveEx(false)
        return
    end
    self.RoleModelPanel.GameObject:SetActiveEx(true)

    local targetPanelRole = self.PanelRoleModel
    local targetUiName = self.Name
    local cb = function(model)
        if not model then
            return
        end
        self.PanelDrag.Target = model.transform
        if self.CharacterAgency:GetIsIsomer(characterId) then
            self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
        else
            self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        end
    end

    if XRobotManager.CheckIsRobotId(characterId) then
        local robotId = characterId
        
        self.ImgEffectHuanren.gameObject:SetActiveEx(false)
        self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
        
        local isOwn = self.CharacterAgency:IsOwnCharacter(characterId)
        local entity = isOwn and self.CharacterAgency:GetCharacter(characterId) or false
        if XRobotManager.CheckUseFashion(robotId) and entity then
            local viewModel = entity:GetCharacterViewModel()
            self.RoleModelPanel:UpdateCharacterModel(characterId, targetPanelRole, targetUiName, cb, nil, viewModel:GetFashionId())
        else
            local robotCfg = XRobotManager.GetRobotTemplate(robotId)
            local fashionId = robotCfg.FashionId
            local weaponId = robotCfg.WeaponId
            self.RoleModelPanel:UpdateRobotModel(robotId, characterId, nil, fashionId, weaponId, cb)
        end
    else
        local fashionId = nil
        local growUpLevel = nil
        if self:CheckIsOtherPlayer() then
            --别人的角色信息
            fashionId = XDataCenter.StrongholdManager.GetAssistantPlayerFashionId(playerId)
            growUpLevel = XDataCenter.StrongholdManager.GetAssistantPlayerLiberateLv(playerId)
        end

        self.ImgEffectHuanren.gameObject:SetActiveEx(false)
        self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
        self.RoleModelPanel:UpdateCharacterModel(
        characterId,
        targetPanelRole,
        targetUiName,
        cb,
        nil,
        fashionId,
        growUpLevel
        )
    end
end

function XUiStrongholdRoomCharacterV2P6:InitModel()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true)
end

function XUiStrongholdRoomCharacterV2P6:AutoAddListener()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnTeaching.CallBack = function() 
        self:OnBtnTeachingClick()
    end
    self:RegisterClickEvent(self.BtnRefresh, self.OnClickBtnRefresh)
end

function XUiStrongholdRoomCharacterV2P6:OnBtnTeachingClick()
    local characterId = self.CharacterId
    if self:CheckIsOtherPlayer() then
        characterId = XDataCenter.StrongholdManager.GetAssistantPlayerCharacterId(characterId)
    end
    XDataCenter.PracticeManager.OpenUiFubenPractice(characterId, true)
end

function XUiStrongholdRoomCharacterV2P6:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiStrongholdRoomCharacterV2P6:OnBtnBackClick()
    self:Close()
end

function XUiStrongholdRoomCharacterV2P6:GetTeam()
    return self.TeamList[self.TeamId]
end

function XUiStrongholdRoomCharacterV2P6:GetMember()
    local team = self:GetTeam()
    return team:GetMember(self.MemberIndex)
end

function XUiStrongholdRoomCharacterV2P6:GetDefaultTabBtnIndex()
    local tabIndex = TabBtnIndex.Normal

    local member = self:GetMember()
    local groupId = self.GroupId
    local stageIndex = self.TeamId
    local stageId = groupId and stageIndex and XDataCenter.StrongholdManager.GetGroupStageId(groupId, stageIndex)
    local characterLimitType = stageId and XFubenConfigs.GetStageCharacterLimitType(stageId)

    if member:IsAssitant() and not self:IsPrefab() then
        tabIndex = TabBtnIndex.Others
    elseif
    member:IsIsomer() or
    (self.CharacterId == 0 and
    (characterLimitType == XFubenConfigs.CharacterLimitType.Isomer or
    characterLimitType == XFubenConfigs.CharacterLimitType.NormalDebuff))
    then
        tabIndex = TabBtnIndex.Isomer
    end

    return tabIndex
end

function XUiStrongholdRoomCharacterV2P6:IsPrefab()
    return not IsNumberValid(self.GroupId)
end

function XUiStrongholdRoomCharacterV2P6:UpdateTeamPrefab(team)
    self.SelfPanel:UpdateTeamPrefab(team)
end

function XUiStrongholdRoomCharacterV2P6:OnClickBtnRefresh()
    local cb = function()
        local groupId = self.GroupId
        local teamList = self.TeamList
        XDataCenter.StrongholdManager.KickOutInvalidMembersInTeamList(teamList, groupId)
        self:ImportSupportList()
        ---@type XUiPanelCommonCharacterFilterV2P6
        local parentFilter = self.PanelFilter
        parentFilter:SetForceSeleCbTrigger()
        parentFilter:RefreshList()
    end
    XDataCenter.StrongholdManager.GetStrongholdAssistCharacterListRequest(cb)
end

return XUiStrongholdRoomCharacterV2P6