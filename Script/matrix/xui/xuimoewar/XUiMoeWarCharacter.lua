local CSXTextManagerGetText = CS.XTextManager.GetText
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local TabBtnIndex = {
    Normal = 1,
    Isomer = 2,
}

local CharDataType = {
    Normal = 1, --普通角色
    Try = 2, --试玩角色(robot)
}

local CharacterTypeConvert = {
    [TabBtnIndex.Normal] = XCharacterConfigs.CharacterType.Normal,
    [TabBtnIndex.Isomer] = XCharacterConfigs.CharacterType.Isomer,
}
local TabBtnIndexConvert = {
    [XCharacterConfigs.CharacterType.Normal] = TabBtnIndex.Normal,
    [XCharacterConfigs.CharacterType.Isomer] = TabBtnIndex.Isomer,
}

local stagePass = false
local LABEL_TEXT_MAX_COUNT = 3

local XUiMoeWarCharacter = XLuaUiManager.Register(XLuaUi, "UiMoeWarCharacter")

function XUiMoeWarCharacter:OnAwake()
    self:InitAutoScript()
    self:InitDynamicTable()

    local root = self.UiModelGo
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")

    self.TagCacheDic = {}
    self.SortFunction = {}
    self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default] = function(a, b, params)
        local isIgnoreQuality = params and params.IsIgnoreQuality
        local isIgnoreLevel = params and params.IsIgnoreLevel
        local isIgnoreAbility = params and params.IsIgnoreAbility

        local AIsInTeam = self:IsInTeam(a)
        local BIsInTeam = self:IsInTeam(b)

        if AIsInTeam ~= BIsInTeam then
            return AIsInTeam
        end

        local AHelperId = XDataCenter.MoeWarManager.GetPrepareOwnHelperId(a)
        local BHelperId = XDataCenter.MoeWarManager.GetPrepareOwnHelperId(b)
        local AfillConditionCount = XMoeWarConfig.GetPreparationFillConditionCount(self.StageId, AHelperId)
        local BfillConditionCount = XMoeWarConfig.GetPreparationFillConditionCount(self.StageId, BHelperId)
        if AfillConditionCount ~= BfillConditionCount then
            return AfillConditionCount > BfillConditionCount
        end

        if not isIgnoreAbility then
            local AAbility = self:GetAbility(a)
            local BAbility = self:GetAbility(b)
            if AAbility ~= BAbility then
                return AAbility > BAbility
            end
        end

        if not isIgnoreLevel then
            local ALevel = self:GetLevel(a)
            local BLevel = self:GetLevel(b)
            if ALevel ~= BLevel then
                return ALevel > BLevel
            end
        end

        if not isIgnoreQuality then
            local AQuality = self:GetQuality(a)
            local BQuality = self:GetQuality(b)
            if AQuality ~= BQuality then
                return AQuality > BQuality
            end
        end

        local ACharId = self:GetCharacterId(a)
        local BCharID = self:GetCharacterId(b)
        local priorityA = XMVCA.XCharacter:GetCharacterPriority(ACharId)
        local priorityB = XMVCA.XCharacter:GetCharacterPriority(BCharID)
        if priorityA ~= priorityB then
            return priorityA < priorityB
        end

        return ACharId > BCharID
    end
    self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Quality] = function(a, b)
        local AQuality = self:GetQuality(a)
        local BQuality = self:GetQuality(b)
        if AQuality ~= BQuality then
            return AQuality > BQuality
        end
        return self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default](a, b, { IsIgnoreQuality = true })
    end
    self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Level] = function(a, b)
        local ALevel = self:GetLevel(a)
        local BLevel = self:GetLevel(b)
        if ALevel ~= BLevel then
            return ALevel > BLevel
        end
        return self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default](a, b, { IsIgnoreLevel = true })
    end
    self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Ability] = function(a, b)
        local AAbility = self:GetAbility(a)
        local BAbility = self:GetAbility(b)
        if AAbility ~= BAbility then
            return AAbility > BAbility
        end
        return self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default](a, b, { IsIgnoreAbility = true })
    end

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.GridCharacter.gameObject:SetActiveEx(false)
end

function XUiMoeWarCharacter:OnStart(teamCharIdMap, teamSelectPos, cb, stageType, isHideQuitButton, characterLimitType, limitBuffId, teamBuffId, robotIdList, challengeId, stageId)
    self.CharacterLimitType = characterLimitType or XFubenConfigs.CharacterLimitType.All
    self.LimitBuffId = limitBuffId
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true)
    self.CharacterGrids = {}
    self.StageType = stageType or 0
    self.IsHideQuitButton = isHideQuitButton
    self.TeamCharIdMap = teamCharIdMap
    self.TeamSelectPos = teamSelectPos
    self.TeamResultCb = cb
    self.TeamBuffId = teamBuffId
    self.RobotIdList = robotIdList
    self.ChallengeId = challengeId
    self.StageId = stageId

    self:InitRequireCharacterInfo()
    self:InitCharacterTypeBtns()
    self:HideJump()
    self:InitEffectPositionInfo()
end

function XUiMoeWarCharacter:OnEnable()
    self:UpdateInfo()

    self.DynamicTable:ReloadDataASync()
    CS.XGraphicManager.UseUiLightDir = true
    XDataCenter.MoeWarManager.JudgeGotoMainWhenFightOver()
end

function XUiMoeWarCharacter:OnDisable()
    CS.XGraphicManager.UseUiLightDir = false
end

function XUiMoeWarCharacter:HideJump()
    if self.StageType ~= XDataCenter.FubenManager.StageType.ArenaOnline then
        return
    end

    if self.AssetPanel.BtnBuyJump1 then
        self.AssetPanel.BtnBuyJump1.gameObject:SetActiveEx(false)
    end

    if self.AssetPanel.BtnBuyJump2 then
        self.AssetPanel.BtnBuyJump2.gameObject:SetActiveEx(false)
    end

    if self.AssetPanel.BtnBuyJump3 then
        self.AssetPanel.BtnBuyJump3.gameObject:SetActiveEx(false)
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiMoeWarCharacter:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiMoeWarCharacter:AutoInitUi()
    self.BtnBack = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/Top/BtnBack", "Button")
    self.BtnJoinTeam = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CharList/TeamBtn/BtnJoinTeam", "Button")
    self.BtnConsciousness = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CharList/TeamBtn/BtnConsciousness", "Button")
    self.BtnQuitTeam = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CharList/TeamBtn/BtnQuitTeam", "Button")
    self.SViewCharacterList = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CharList/CharInfo/Left/SViewCharacterList", "ScrollRect")
    self.PanelRoleContent = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CharList/CharInfo/Left/SViewCharacterList/Viewport/PanelRoleContent")
    self.GridCharacter = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CharList/CharInfo/Left/SViewCharacterList/Viewport/PanelRoleContent/GridCharacter")
    self.BtnFashion = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CharList/TeamBtn/BtnFashion", "Button")
    self.PanelRoleModel = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/ModelRoot/NearRoot/PanelRoleModel")
    self.PanelDrag = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CharList/CharInfo/PanelDrag", "XDrag")
    self.BtnWeapon = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CharList/TeamBtn/BtnWeapon", "Button")
    self.TxtRequireAbility = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CharList/TeamBtn/PanelTxt/TxtRequireAbility", "Text")
    self.PanelAsset = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelAsset")
    self.BtnMainUi = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/Top/BtnMainUi", "Button")
    self.PanelRequireCharacter = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CharList/TeamBtn/PanelTxt/PanelRequireCharacter")
    self.ImgRequireCharacter = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CharList/TeamBtn/PanelTxt/PanelRequireCharacter/Image/ImgRequireCharacter", "Image")
    self.TxtRequireCharacter = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CharList/TeamBtn/PanelTxt/PanelRequireCharacter/TxtRequireCharacter", "Text")

    for i = 1, LABEL_TEXT_MAX_COUNT do
        self["TagLabel" .. i] = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/CharList/PanelLabel/Label0" .. i)
        self["TextTagLabel" .. i] = XUiHelper.TryGetComponent(self["TagLabel" .. i].transform, "Text", "Text")
    end
end

function XUiMoeWarCharacter:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnJoinTeam, self.OnBtnJoinTeamClick)
    self:RegisterClickEvent(self.BtnConsciousness, self.OnBtnConsciousnessClick)
    self:RegisterClickEvent(self.BtnQuitTeam, self.OnBtnQuitTeamClick)
    self:RegisterClickEvent(self.BtnFashion, self.OnBtnFashionClick)
    self:RegisterClickEvent(self.BtnWeapon, self.OnBtnWeaponClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnPartner, self.OnCarryPartnerClick)

    self.BtnFilter.CallBack = function() self:OnBtnFilterClick() end
end
-- auto
function XUiMoeWarCharacter:OnBtnWeaponClick()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self.CurCharacter.Id, nil, true)
end

function XUiMoeWarCharacter:OnBtnConsciousnessClick()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwareness(self.CurCharacter.Id)
end

function XUiMoeWarCharacter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiMoeWarCharacter:OnCarryPartnerClick()
    XDataCenter.PartnerManager.GoPartnerCarry(self.CurCharacter.Id, false)
end

function XUiMoeWarCharacter:OnBtnFilterClick()
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    XLuaUiManager.Open("UiRoomCharacterFilterTips",
    self,
    XRoomCharFilterTipsConfigs.EnumFilterType.Common,
    XRoomCharFilterTipsConfigs.EnumSortType.Common,
    characterType)
end

--初始化音效
function XUiMoeWarCharacter:InitBtnSound()
    self.SpecialSoundMap[self:GetAutoKey(self.BtnBack, "onClick")] = XSoundManager.UiBasicsMusic.Return
    self.SpecialSoundMap[self:GetAutoKey(self.BtnEquip, "onClick")] = XSoundManager.UiBasicsMusic.Fuben_UiMainLineRoomCharacter_Equip
    self.SpecialSoundMap[self:GetAutoKey(self.BtnFashion, "onClick")] = XSoundManager.UiBasicsMusic.Fuben_UiMainLineRoomCharacter_Fashion
    self.SpecialSoundMap[self:GetAutoKey(self.BtnJoinTeam, "onClick")] = XSoundManager.UiBasicsMusic.Fuben_UiMainLineRoomCharacter_JoinTeam
    self.SpecialSoundMap[self:GetAutoKey(self.BtnQuitTeam, "onClick")] = XSoundManager.UiBasicsMusic.Fuben_UiMainLineRoomCharacter_QuitTeam
end

function XUiMoeWarCharacter:InitRequireCharacterInfo()
    local characterLimitType = self.CharacterLimitType

    if not XFubenConfigs.IsStageCharacterLimitConfigExist(characterLimitType) then
        self.PanelRequireCharacter.gameObject:SetActiveEx(false)
        return
    else
        self.PanelRequireCharacter.gameObject:SetActiveEx(true)
    end

    local icon = XFubenConfigs.GetStageCharacterLimitImageTeamEdit(characterLimitType)
    self.ImgRequireCharacter:SetSprite(icon)
end

function XUiMoeWarCharacter:InitEffectPositionInfo()
    self.PanelEffectPosition.gameObject:SetActiveEx(false)
    --if self.StageType ~= XDataCenter.FubenManager.StageType.InfestorExplore then
    --    return
    --end
    --self.TxtEffectPosition.text = XDataCenter.FubenInfestorExploreManager.GetBuffDes()
    --self.PanelEffectPosition.gameObject:SetActiveEx(true)
end

function XUiMoeWarCharacter:RefreshCharacterTypeTips()
    local limitBuffId = self.LimitBuffId
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    local characterLimitType = self.CharacterLimitType
    local text = XFubenConfigs.GetStageCharacterLimitTextSelectCharacter(characterLimitType, characterType, limitBuffId)
    self.TxtRequireCharacter.text = text
end

function XUiMoeWarCharacter:ResetTeamData()
    self.TeamCharIdMap = { 0, 0, 0 }
end

function XUiMoeWarCharacter:InitCharacterTypeBtns()
    self.BtnTabShougezhe.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Isomer))

    local tabBtns = { self.BtnTabGouzaoti, self.BtnTabShougezhe }
    self.PanelCharacterTypeBtns:Init(tabBtns, function(index) self:TrySelectCharacterType(index) end)

    local characterLimitType = self.CharacterLimitType
    local lockGouzaoti = characterLimitType == XFubenConfigs.CharacterLimitType.Isomer
    local lockShougezhe = not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer) or characterLimitType == XFubenConfigs.CharacterLimitType.Normal
    self.BtnTabGouzaoti:SetDisable(lockGouzaoti)
    self.BtnTabShougezhe:SetDisable(lockShougezhe)

    --检查选择角色类型是否和副本限制类型冲突
    local characterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(self.CharacterLimitType)
    local tempCharacterType = self:GetTeamCharacterType()
    if tempCharacterType and not (tempCharacterType == XCharacterConfigs.CharacterType.Normal and lockGouzaoti
    or tempCharacterType == XCharacterConfigs.CharacterType.Isomer and lockShougezhe) then
        characterType = tempCharacterType
    end

    self:InitBtnTabIsClick()
    self.PanelCharacterTypeBtns:SelectIndex(TabBtnIndexConvert[characterType])
end

function XUiMoeWarCharacter:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiGridCharacter, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiMoeWarCharacter:TrySelectCharacterType(index)
    local characterType = CharacterTypeConvert[index]

    if not self:IsCanClickBtnTab(characterType) then
        return
    end

    local characterLimitType = self.CharacterLimitType
    if characterLimitType == XFubenConfigs.CharacterLimitType.Normal then
        if characterType == XCharacterConfigs.CharacterType.Isomer then
            XUiManager.TipText("TeamSelectCharacterTypeLimitTipNormal")
            return
        end
    elseif characterLimitType == XFubenConfigs.CharacterLimitType.Isomer then
        if characterType == XCharacterConfigs.CharacterType.Normal then
            XUiManager.TipText("TeamSelectCharacterTypeLimitTipIsomer")
            return
        end
    end

    self:OnSelectCharacterType(index)
end

function XUiMoeWarCharacter:OnSelectCharacterType(index)
    if self.SelectTabBtnIndex == index then
        local btn = self.PanelCharacterTypeBtns:GetButtonByIndex(index)
        btn:SetButtonState(CS.UiButtonState.Normal)
        return
    end
    self.SelectTabBtnIndex = index
    local characterType = CharacterTypeConvert[index]
    self.CharIdlist = {}
    self.AllCharIdList = {}
    XDataCenter.RoomCharFilterTipsManager.Reset()

    self.CharIdlist = XDataCenter.CharacterManager.GetRobotAndCorrespondCharacterIdList(self.RobotIdList, characterType)

    table.sort(self.CharIdlist, self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default])
    self.AllCharIdList = self.CharIdlist

    self:RefreshCharacterTypeTips()
    self:UpdateCharacterList(index)
end

function XUiMoeWarCharacter:InitBtnTabIsClick()
    local isClickNormal, isClickOmer = false, false
    local characterType
    for _, charId in ipairs(self.RobotIdList) do
        if charId > 0 then
            characterType = XMVCA.XCharacter:GetCharacterType(charId)
            if characterType == XCharacterConfigs.CharacterType.Normal and not isClickNormal then
                isClickNormal = true
            elseif characterType == XCharacterConfigs.CharacterType.Isomer and not isClickOmer then
                isClickOmer = true
            end
        end
    end
    self.IsClickNormal = isClickNormal
    self.IsClickOmer = isClickOmer
    self.BtnTabGouzaoti:SetDisable(not isClickNormal)
    self.BtnTabShougezhe:SetDisable(not isClickOmer)
end

function XUiMoeWarCharacter:IsCanClickBtnTab(characterType)
    if not self.CharIdlist then
        return true
    end

    if characterType == XCharacterConfigs.CharacterType.Normal and self.IsClickNormal then
        return true
    end
    if characterType == XCharacterConfigs.CharacterType.Isomer and self.IsClickOmer then
        return true
    end
    return false
end

function XUiMoeWarCharacter:SetPanelEmptyList(isEmpty)
    local curCharIsRobot = self.CurCharacter and XRobotManager.CheckIsRobotId(self.CurCharacter.Id) or false

    self.BtnQuitTeam.gameObject:SetActiveEx(false)
    self.BtnJoinTeam.gameObject:SetActiveEx(false)

    self.BtnConsciousness.gameObject:SetActiveEx(not isEmpty and not curCharIsRobot)
    self.BtnFashion.gameObject:SetActiveEx(not isEmpty and not curCharIsRobot)
    self.BtnWeapon.gameObject:SetActiveEx(not isEmpty and not curCharIsRobot)
    self.BtnPartner.gameObject:SetActiveEx(not isEmpty and not curCharIsRobot)

    self.PanelRoleModel.gameObject:SetActiveEx(not isEmpty)
    self.PanelRoleContent.gameObject:SetActiveEx(not isEmpty)
    self.PanelEmptyList.gameObject:SetActiveEx(isEmpty)
end

function XUiMoeWarCharacter:UpdataPanelEmptyList()
    local curCharIsRobot = self.CurCharacter and XRobotManager.CheckIsRobotId(self.CurCharacter.Id) or false

    self.BtnConsciousness.gameObject:SetActiveEx(not curCharIsRobot)
    self.BtnFashion.gameObject:SetActiveEx(not curCharIsRobot)
    self.BtnWeapon.gameObject:SetActiveEx(not curCharIsRobot)
    self.BtnPartner.gameObject:SetActiveEx(not curCharIsRobot)

    self.BtnJoinTeam.gameObject:SetActiveEx(self.NeedShowBtnJoinTeam)
end

function XUiMoeWarCharacter:UpdateCharacterList(index)
    stagePass = XDataCenter.RoomManager.CheckPlayerStagePass() or XDataCenter.ArenaOnlineManager.CheckStagePass(self.ChallengeId)
    local characterType = CharacterTypeConvert[index]
    local teamCharIdMap = self.TeamCharIdMap
    local selectId = teamCharIdMap[self.TeamSelectPos]

    if not next(self.CharIdlist) then
        self:SetPanelEmptyList(true)
        return
    end
    self:SetPanelEmptyList(false)

    self.CurIndex = nil
    self.CharacterIdToIndex = {}
    local useDefaultIndex = true
    if selectId and selectId ~= 0 and characterType == XMVCA.XCharacter:GetCharacterType(selectId) then
        useDefaultIndex = false
    end
    for index, id in ipairs(self.CharIdlist) do
        self.CharacterIdToIndex[id] = index
        if self.CurIndex == nil and id == selectId and not useDefaultIndex then
            self.CurIndex = index
        end
    end
    self.CurIndex = self.CurIndex or 1

    local charInfo = self:GetCharInfo(self.CurIndex)
    self:UpdateInfo(charInfo)

    self.DynamicTable:SetDataSource(self.CharIdlist)
    self.DynamicTable:ReloadDataASync()
end

function XUiMoeWarCharacter:OnDynamicTableEvent(event, index, grid)
    local characterId = self.CharIdlist[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if index < 0 or index > #self.CharIdlist then return end
        local char = self:GetCharInfo(index)
        grid:UpdateGrid(char, self.StageType)

        local showTeamBuff = XFubenConfigs.IsCharacterFitTeamBuff(self.TeamBuffId, characterId)
        grid:SetTeamBuff(showTeamBuff)
        grid:SetSelect(self.CurIndex == index)
        grid:SetInTeam(false)
        for pos, id in pairs(self.TeamCharIdMap) do
            if id > 0 and self.CharacterIdToIndex[id] == index then
                grid:SetInTeam(true, CSXTextManagerGetText("CommonInTheTeam"), pos)
                break
            end
        end

        grid.Transform:SetAsLastSibling()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurIndex = index
        self:UpdateInfo(grid.Character)
        self.DynamicTable:ReloadDataSync()
    end
end

function XUiMoeWarCharacter:GetCharInfo(index)
    local characterId = self.CharIdlist[index]
    local char = {}
    if XRobotManager.CheckIsRobotId(characterId) then
        char.Id = characterId
        char.IsRobot = true
    else
        char = XDataCenter.CharacterManager.GetCharacter(characterId)
    end
    return char
end

function XUiMoeWarCharacter:UpdateInfo(character)
    if character then
        self.CurCharacter = character
    end
    if not self.CurCharacter then return end

    self:UpdateTeamBtn()
    self:UpdateRoleModel()
    self:UpdateTagLabel()
end

function XUiMoeWarCharacter:UpdateTagLabel()
    local helperId = XDataCenter.MoeWarManager.GetPrepareOwnHelperId(self.CurCharacter.Id)
    local helperLabelIds = helperId > 0 and XMoeWarConfig.GetMoeWarPreparationHelperLabelIds(helperId) or {}
    for i = 1, LABEL_TEXT_MAX_COUNT do
        if not helperLabelIds[i] then
            self["TagLabel" .. i].gameObject:SetActiveEx(false)
        else
            self["TextTagLabel" .. i].text = XMoeWarConfig.GetPreparationStageTagLabelById(helperLabelIds[i])
            self["TagLabel" .. i].gameObject:SetActiveEx(true)
        end
    end
end

function XUiMoeWarCharacter:UpdateTeamBtn()
    if not (self.TeamCharIdMap and next(self.TeamCharIdMap)) then
        return
    end

    --在当前操作的队伍中
    local isInTeam = self:IsInTeam(self.CurCharacter.Id)

    local needShowBtnQuitTeam = isInTeam
    self.NeedShowBtnJoinTeam = not isInTeam

    self.BtnQuitTeam.gameObject:SetActiveEx(needShowBtnQuitTeam and not self.IsHideQuitButton)
    self.BtnJoinTeam.gameObject:SetActiveEx(false)
end

function XUiMoeWarCharacter:IsInTeam(id)
    if not (self.TeamCharIdMap and next(self.TeamCharIdMap)) then
        return false
    end
    for _, v in pairs(self.TeamCharIdMap) do
        if id == v then
            return true
        end
    end
    return false
end

function XUiMoeWarCharacter:UpdateRoleModel()
    local characterId = self.CurCharacter and self.CurCharacter.Id
    if not characterId then return end
    local targetPanelRole = self.PanelRoleModel
    local targetUiName = self.Name
    local func = function()
        self:UpdataPanelEmptyList()
    end
    local charaterFunc = function(model)
        if not model then
            return
        end
        self.PanelDrag.Target = model.transform
        if self.SelectTabBtnIndex == TabBtnIndex.Normal then
            self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        elseif self.SelectTabBtnIndex == TabBtnIndex.Isomer then
            self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
        end
    end

    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)

    if XRobotManager.CheckIsRobotId(self.CurCharacter.Id) then
        local robotCfg = XRobotManager.GetRobotTemplate(self.CurCharacter.Id)
        self.RoleModelPanel:UpdateRobotModel(self.CurCharacter.Id, self.CurCharacter.Id, nil, robotCfg.FashionId, robotCfg.WeaponId, func)
    else
        self.RoleModelPanel:UpdateCharacterModel(self.CurCharacter.Id, targetPanelRole, targetUiName, charaterFunc, func)
    end
end

function XUiMoeWarCharacter:OnBtnBackClick()
    if self.TeamResultCb then
        self.TeamResultCb(self.TeamCharIdMap)
    end
    self:Close()
end

function XUiMoeWarCharacter:OnBtnJoinTeamClick()
    local id = self.CurCharacter.Id
    local joinFunc = function(isReset)
        if isReset then
            self:ResetTeamData()
        else
            for k, v in pairs(self.TeamCharIdMap) do
                if XRobotManager.CheckIsRobotId(v) and not XRobotManager.CheckIsRobotId(id) then
                    local robotTemplate = XRobotManager.GetRobotTemplate(v)
                    local charId = robotTemplate and robotTemplate.CharacterId or 0
                    if charId == id then
                        self.TeamCharIdMap[k] = 0
                        break
                    end
                elseif not XRobotManager.CheckIsRobotId(v) and XRobotManager.CheckIsRobotId(id) then
                    local robotTemplate = XRobotManager.GetRobotTemplate(id)
                    local charId = robotTemplate and robotTemplate.CharacterId or 0
                    if v == charId then
                        self.TeamCharIdMap[k] = 0
                        break
                    end
                else
                    if v == id then
                        self.TeamCharIdMap[k] = 0
                        break
                    end
                end
            end
        end

        self.TeamCharIdMap[self.TeamSelectPos] = id

        if self.TeamResultCb then
            self.TeamResultCb(self.TeamCharIdMap)
        end

        self:Close()
    end

    -- 角色类型不一致拦截
    local inTeamCharacterType = self:GetTeamCharacterType()
    if inTeamCharacterType then
        local characterType = id and id ~= 0 and XMVCA.XCharacter:GetCharacterType(id)
        if characterType and characterType ~= inTeamCharacterType then
            local content = CSXTextManagerGetText("TeamCharacterTypeNotSame")
            local sureCallBack = function()
                local isReset = true
                joinFunc(isReset)
            end
            XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, sureCallBack)
            return
        end
    end

    joinFunc()
end

function XUiMoeWarCharacter:OnBtnQuitTeamClick()
    local count = 0
    for _, v in pairs(self.TeamCharIdMap) do
        if v > 0 then
            count = count + 1
        end
    end

    local id = self.CurCharacter.Id
    for k, v in pairs(self.TeamCharIdMap) do
        if v == id then
            self.TeamCharIdMap[k] = 0
            break
        end
    end

    if self.TeamResultCb then
        self.TeamResultCb(self.TeamCharIdMap)
    end
    self:Close()
end

function XUiMoeWarCharacter:OnBtnFashionClick()
    XLuaUiManager.Open("UiFashion", self.CurCharacter.Id)
end

function XUiMoeWarCharacter:GetTeamCharacterType()
    for k, v in pairs(self.TeamCharIdMap) do
        if v ~= 0 then
            return XMVCA.XCharacter:GetCharacterType(v)
        end
    end
end

function XUiMoeWarCharacter:CheckIsRobotId(id)
    return id < 1000000
end

function XUiMoeWarCharacter:GetCharacterId(id)
    if XRobotManager.CheckIsRobotId(id) then
        return XRobotManager.GetRobotTemplate(id).CharacterId
    else
        return id
    end
end

function XUiMoeWarCharacter:GetAbility(id)
    if XRobotManager.CheckIsRobotId(id) then
        return XRobotManager.GetRobotTemplate(id).ShowAbility
    else
        return XDataCenter.CharacterManager.GetCharacter(id).Ability
    end
end

function XUiMoeWarCharacter:GetLevel(id)
    if XRobotManager.CheckIsRobotId(id) then
        return XRobotManager.GetRobotTemplate(id).CharacterLevel
    else
        return XDataCenter.CharacterManager.GetCharacter(id).Level
    end
end

function XUiMoeWarCharacter:GetQuality(id)
    if XRobotManager.CheckIsRobotId(id) then
        return XRobotManager.GetRobotTemplate(id).CharacterQuality
    else
        return XDataCenter.CharacterManager.GetCharacter(id).Quality
    end
end

function XUiMoeWarCharacter:Filter(selectTagGroupDic, sortTagId, isThereFilterDataCb)
    local judgeCb = function(groupId, tagValue, characterId)
        local char = {}
        if XRobotManager.CheckIsRobotId(characterId) then
            char.Id = characterId
            char.IsRobot = true
        else
            char = XDataCenter.CharacterManager.GetCharacter(characterId)
        end

        local compareValue
        local detailConfig
        if char.IsRobot then
            local robotTemplate = XRobotManager.GetRobotTemplate(char.Id)
            detailConfig = XCharacterConfigs.GetCharDetailTemplate(robotTemplate.CharacterId)
        else
            detailConfig = XCharacterConfigs.GetCharDetailTemplate(char.Id)
        end

        if groupId == XRoomCharFilterTipsConfigs.EnumFilterTagGroup.Career then
            compareValue = detailConfig.Career
            if compareValue == tagValue then
                -- 当前角色满足该标签
                return true
            end
        elseif groupId == XRoomCharFilterTipsConfigs.EnumFilterTagGroup.Element then
            compareValue = detailConfig.ObtainElementList
            for _, element in pairs(compareValue) do
                if element == tagValue then
                    -- 当前角色满足该标签
                    return true
                end
            end
        else
            XLog.Error(string.format("XUiMoeWarCharacter:Filter函数错误，没有处理排序组：%s的逻辑", groupId))
            return false
        end
    end

    XDataCenter.RoomCharFilterTipsManager.Filter(self.TagCacheDic, selectTagGroupDic, self.AllCharIdList, judgeCb,
    function(filteredData)
        self:FilterRefresh(filteredData, sortTagId)
    end,
    isThereFilterDataCb)
end

function XUiMoeWarCharacter:FilterRefresh(filteredData, sortTagId)
    self.CharIdlist = filteredData

    if not next(filteredData) then
        self:SetPanelEmptyList(true)
        return
    end
    self:SetPanelEmptyList(false)

    if self.SortFunction[sortTagId] then
        table.sort(filteredData, self.SortFunction[sortTagId])
    else
        XLog.Error(string.format("XUiMoeWarCharacter:FilterRefresh函数错误，没有定义标签：%s的排序函数", sortTagId))
        return
    end

    self.CharacterIdToIndex = {}
    for index, id in ipairs(filteredData) do
        self.CharacterIdToIndex[id] = index
    end
    self.CurIndex = 1

    local charInfo = self:GetCharInfo(self.CurIndex)
    self:UpdateInfo(charInfo)

    self.DynamicTable:SetDataSource(filteredData)
    self.DynamicTable:ReloadDataASync()
end