local CSXTextManagerGetText = CS.XTextManager.GetText
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local TabBtnIndex = {
    Normal = 1,
    Isomer = 2,
    Robot = 3,
}

local CharacterTypeConvert = {
    [TabBtnIndex.Normal] = XCharacterConfigs.CharacterType.Normal,
    [TabBtnIndex.Isomer] = XCharacterConfigs.CharacterType.Isomer,
    [TabBtnIndex.Robot] = XCharacterConfigs.CharacterType.Robot,
}
local TabBtnIndexConvert = {
    [XCharacterConfigs.CharacterType.Normal] = TabBtnIndex.Normal,
    [XCharacterConfigs.CharacterType.Isomer] = TabBtnIndex.Isomer,
    [XCharacterConfigs.CharacterType.Robot] = TabBtnIndex.Robot,
}

local stagePass = false

local XUiRoomCharacter = XLuaUiManager.Register(XLuaUi, "UiRoomCharacter")

function XUiRoomCharacter:OnAwake()
    self:InitAutoScript()
    self:InitDynamicTable()

    local root = self.UiModelGo
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")

    self.TagCacheDic = {}
    self.SortFunction = {}
    self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default] = function(a, b)
        local AIsInTeam = self:IsInTeam(a)
        local BIsInTeam = self:IsInTeam(b)

        if AIsInTeam ~= BIsInTeam then
            return AIsInTeam
        end

        if self:IsWorldBossType() or self:IsNewCharType() then
            local AAbility = self:GetAbility(a)
            local BAbility = self:GetAbility(b)
            local AIsRobot = XRobotManager.CheckIsRobotId(a)
            local BIsRobot = XRobotManager.CheckIsRobotId(b)

            if AIsRobot ~= BIsRobot then
                return AIsRobot
            else
                return AAbility > BAbility
            end
        elseif self:IsChessPursuitType() then
            local AAbility = self:GetAbility(a)
            local BAbility = self:GetAbility(b)
            if AAbility ~= BAbility then
                return AAbility > BAbility
            end

            local ACharId = self:GetCharacterId(a)
            local BCharId = self:GetCharacterId(b)
            if ACharId ~= BCharId then
                return ACharId > BCharId
            end

            local AIsRobot = XRobotManager.CheckIsRobotId(a)
            local BIsRobot = XRobotManager.CheckIsRobotId(b)
            if AIsRobot ~= BIsRobot then
                return BIsRobot
            end
            return false
        elseif self:IsActivityBossSingle() then
            local AAbility = self:GetAbility(a)
            local BAbility = self:GetAbility(b)
            if AAbility ~= BAbility then
                return AAbility > BAbility
            end
        else
            local ACharId = self:GetCharacterId(a)
            local BCharID = self:GetCharacterId(b)
            local ALevel = self:GetLevel(a)
            local BLevel = self:GetLevel(b)
            local AQuality = self:GetQuality(a)
            local BQuality = self:GetQuality(b)

            if ALevel ~= BLevel then
                return ALevel > BLevel
            end
            if AQuality ~= BQuality then
                return AQuality > BQuality
            end

            local priorityA = XCharacterConfigs.GetCharacterPriority(ACharId)
            local priorityB = XCharacterConfigs.GetCharacterPriority(BCharID)
            if priorityA ~= priorityB then
                return priorityA < priorityB
            end

            return ACharId > BCharID
        end
    end
    self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Quality] = function(a, b)
        local AQuality = self:GetQuality(a)
        local BQuality = self:GetQuality(b)
        if AQuality ~= BQuality then
            return AQuality > BQuality
        end
        return self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default](a, b)
    end
    self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Level] = function(a, b)
        local ALevel = self:GetLevel(a)
        local BLevel = self:GetLevel(b)
        if ALevel ~= BLevel then
            return ALevel > BLevel
        end
        return self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default](a, b)
    end
    self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Ability] = function(a, b)
        local AAbility = self:GetAbility(a)
        local BAbility = self:GetAbility(b)
        if AAbility ~= BAbility then
            return AAbility > BAbility
        end
        return self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default](a, b)
    end

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.GridCharacter.gameObject:SetActiveEx(false)
end

function XUiRoomCharacter:OnStart(teamCharIdMap, teamSelectPos, cb, stageType, characterLimitType, data)
    self.TeamCharIdMap = teamCharIdMap
    self.TeamSelectPos = teamSelectPos
    self.TeamResultCb = cb
    self.StageType = stageType or 0
    self.CharacterLimitType = characterLimitType or XFubenConfigs.CharacterLimitType.All

    -- data可能包含的参数：
    if data then
        self.LimitBuffId = data.LimitBuffId
        self.TeamBuffId = data.TeamBuffId
        self.RobotIdList = data.RobotIdList
        self.ChallengeId = data.ChallengeId
        self.SelectCharacterType = data.SelectCharacterType
        self.IsHideQuitButton = data.IsHideQuitButton
        self.NotReset = data.NotReset
        self.MapId = data.MapId
        self.TeamGridIndex = data.TeamGridIndex
        self.SceneUiType = data.SceneUiType
        self.IsRobotOnly = data.IsRobotOnly
        self.RobotAndCharacter = data.RobotAndCharacter
        self.StageId = data.StageId
        self.IsRobotCorrespondCharacter = data.IsRobotCorrespondCharacter --是否只根据RobotIdList显示已拥有的角色
    end
    self.Proxy = XUiRoomCharacterProxy.ProxyDic[self.StageType]

    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true)
    self.CharacterGrids = {}
    self:InitRequireCharacterInfo()
    self:InitCharacterTypeBtns()
    self:HideJump()
    self:InitEffectPositionInfo()
end

function XUiRoomCharacter:OnEnable()
    self:UpdateInfo()

    self.DynamicTable:ReloadDataASync()
    CS.XGraphicManager.UseUiLightDir = true
    XEventManager.AddEventListener(XEventId.EVENT_ARENAONLINE_WEEK_REFRESH, self.OnArenaOnlineWeekRefrsh, self)
end

function XUiRoomCharacter:OnGetEvents()
    return { XEventId.EVENT_ACTIVITY_ON_RESET }
end

function XUiRoomCharacter:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        self:OnResetEvent(args[1])
    end
end

function XUiRoomCharacter:OnDisable()
    CS.XGraphicManager.UseUiLightDir = false
    XEventManager.RemoveEventListener(XEventId.EVENT_ARENAONLINE_WEEK_REFRESH, self.OnArenaOnlineWeekRefrsh, self)
end

function XUiRoomCharacter:HideJump()
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
function XUiRoomCharacter:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiRoomCharacter:AutoInitUi()
    self.BtnBack = self.Transform:Find("SafeAreaContentPane/Top/BtnBack"):GetComponent("Button")
    self.BtnJoinTeam = self.Transform:Find("SafeAreaContentPane/CharList/TeamBtn/BtnJoinTeam"):GetComponent("Button")
    self.BtnQuitTeam = self.Transform:Find("SafeAreaContentPane/CharList/TeamBtn/BtnQuitTeam"):GetComponent("Button")
    self.SViewCharacterList = self.Transform:Find("SafeAreaContentPane/CharList/CharInfo/Left/SViewCharacterList"):GetComponent("ScrollRect")
    self.PanelRoleContent = self.Transform:Find("SafeAreaContentPane/CharList/CharInfo/Left/SViewCharacterList/Viewport/PanelRoleContent")
    self.GridCharacter = self.Transform:Find("SafeAreaContentPane/CharList/CharInfo/Left/SViewCharacterList/Viewport/PanelRoleContent/GridCharacter")
    self.PanelRoleModel = self.Transform:Find("SafeAreaContentPane/ModelRoot/NearRoot/PanelRoleModel")
    self.PanelDrag = self.Transform:Find("SafeAreaContentPane/CharList/CharInfo/PanelDrag"):GetComponent("XDrag")
    self.TxtRequireAbility = self.Transform:Find("SafeAreaContentPane/CharList/TeamBtn/PanelTxt/TxtRequireAbility"):GetComponent("Text")
    self.PanelAsset = self.Transform:Find("SafeAreaContentPane/PanelAsset")
    self.BtnMainUi = self.Transform:Find("SafeAreaContentPane/Top/BtnMainUi"):GetComponent("Button")
    self.PanelRequireCharacter = self.Transform:Find("SafeAreaContentPane/CharList/TeamBtn/PanelTxt/PanelRequireCharacter")
    self.ImgRequireCharacter = self.Transform:Find("SafeAreaContentPane/CharList/TeamBtn/PanelTxt/PanelRequireCharacter/Image/ImgRequireCharacter"):GetComponent("Image")
    self.TxtRequireCharacter = self.Transform:Find("SafeAreaContentPane/CharList/TeamBtn/PanelTxt/PanelRequireCharacter/TxtRequireCharacter"):GetComponent("Text")
end

function XUiRoomCharacter:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnJoinTeam, self.OnBtnJoinTeamClick)
    self:RegisterClickEvent(self.BtnQuitTeam, self.OnBtnQuitTeamClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    
    self.BtnConsciousness.CallBack = function() self:OnBtnConsciousnessClick()  end
    self.BtnFashion.CallBack = function() self:OnBtnFashionClick()  end
    self.BtnWeapon.CallBack = function() self:OnBtnWeaponClick()  end
    self.BtnPartner.CallBack = function() self:OnCarryPartnerClick()  end

    self.BtnTeaching.CallBack = function () self:OnBtnBtnTeachingClick() end
    self.BtnFilter.CallBack = function() self:OnBtnFilterClick() end
end
-- auto
function XUiRoomCharacter:OnBtnWeaponClick()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self.CurCharacter.Id, nil, true)
end

function XUiRoomCharacter:OnBtnConsciousnessClick()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwareness(self.CurCharacter.Id)
end

function XUiRoomCharacter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiRoomCharacter:OnCarryPartnerClick()
    XDataCenter.PartnerManager.GoPartnerCarry(self.CurCharacter.Id, false)
end

function XUiRoomCharacter:OnBtnFilterClick()
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    XLuaUiManager.Open("UiRoomCharacterFilterTips",
    self,
    XRoomCharFilterTipsConfigs.EnumFilterType.Common,
    XRoomCharFilterTipsConfigs.EnumSortType.Common,
    characterType)
end

--初始化音效
function XUiRoomCharacter:InitBtnSound()
    self.SpecialSoundMap[self:GetAutoKey(self.BtnBack, "onClick")] = XSoundManager.UiBasicsMusic.Return
    self.SpecialSoundMap[self:GetAutoKey(self.BtnEquip, "onClick")] = XSoundManager.UiBasicsMusic.Fuben_UiMainLineRoomCharacter_Equip
    self.SpecialSoundMap[self:GetAutoKey(self.BtnFashion, "onClick")] = XSoundManager.UiBasicsMusic.Fuben_UiMainLineRoomCharacter_Fashion
    self.SpecialSoundMap[self:GetAutoKey(self.BtnJoinTeam, "onClick")] = XSoundManager.UiBasicsMusic.Fuben_UiMainLineRoomCharacter_JoinTeam
    self.SpecialSoundMap[self:GetAutoKey(self.BtnQuitTeam, "onClick")] = XSoundManager.UiBasicsMusic.Fuben_UiMainLineRoomCharacter_QuitTeam
end

function XUiRoomCharacter:InitRequireCharacterInfo()
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

function XUiRoomCharacter:InitEffectPositionInfo()
    if self.StageType ~= XDataCenter.FubenManager.StageType.InfestorExplore then
        self.PanelEffectPosition.gameObject:SetActiveEx(false)
        return
    end
    self.TxtEffectPosition.text = XDataCenter.FubenInfestorExploreManager.GetBuffDes()
    self.PanelEffectPosition.gameObject:SetActiveEx(true)
end

function XUiRoomCharacter:RefreshCharacterTypeTips()
    if self.Proxy and self.Proxy.RefreshCharacterTypeTips then
        self.Proxy.RefreshCharacterTypeTips(self)
    else
        local limitBuffId = self.LimitBuffId
        local characterType = self.CurCharacter and XCharacterConfigs.GetCharacterType(self.CurCharacter.Id)
        local characterLimitType = self.CharacterLimitType
        local text = XFubenConfigs.GetStageCharacterLimitTextSelectCharacter(characterLimitType, characterType, limitBuffId)
        self.TxtRequireCharacter.text = text
    end
end

function XUiRoomCharacter:ResetTeamData()
    self.TeamCharIdMap = { 0, 0, 0 }
end

function XUiRoomCharacter:InitCharacterTypeBtns()
    local tabBtns = { self.BtnTabGouzaoti, self.BtnTabShougezhe, self.BtnTabRobot }
    self.PanelCharacterTypeBtns:Init(tabBtns, function(index) self:TrySelectCharacterType(index) end)

    if self.Proxy and self.Proxy.InitCharacterTypeBtns then
        self.Proxy.InitCharacterTypeBtns(self, self.TeamCharIdMap, TabBtnIndex)
    else
        self.BtnTabShougezhe.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Isomer))

        local characterLimitType = self.CharacterLimitType
        local lockGouzaoti = characterLimitType == XFubenConfigs.CharacterLimitType.Isomer
        local lockShougezhe = not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer) or characterLimitType == XFubenConfigs.CharacterLimitType.Normal
        self.BtnTabGouzaoti:SetDisable(lockGouzaoti)
        self.BtnTabShougezhe:SetDisable(lockShougezhe)

        if self.BtnTabRobot then
            self.BtnTabRobot.gameObject:SetActiveEx(false)
        end

        --检查选择角色类型是否和副本限制类型冲突
        local characterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(self.CharacterLimitType)

        -- 优先使用SelectCharacterType自定义要选择的角色类型，否则根据队伍的角色类型来判断选择的角色类型
        local tempCharacterType
        if self.SelectCharacterType then
            tempCharacterType = self.SelectCharacterType
        else
            tempCharacterType = self:GetTeamCharacterType()
        end

        -- tempCharacterType为上锁的角色类型时，不更新characterType，使用默认的角色类型
        if tempCharacterType and not (tempCharacterType == XCharacterConfigs.CharacterType.Normal and lockGouzaoti
        or tempCharacterType == XCharacterConfigs.CharacterType.Isomer and lockShougezhe) then
            characterType = tempCharacterType
        end

        --授格者页签未开启，默认选中构造体
        if characterType == XCharacterConfigs.CharacterType.Isomer and not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer) then
            characterType = XCharacterConfigs.CharacterType.Normal
        end

        self:InitBtnTabIsClick()
        self.PanelCharacterTypeBtns:SelectIndex(TabBtnIndexConvert[characterType])
    end
end

function XUiRoomCharacter:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiGridCharacter, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiRoomCharacter:TrySelectCharacterType(index)
    local characterType = CharacterTypeConvert[index]
    if characterType == XCharacterConfigs.CharacterType.Isomer and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Isomer) then return end

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
        -- elseif characterLimitType == XFubenConfigs.CharacterLimitType.IsomerDebuff then
        --     if characterType == XCharacterConfigs.CharacterType.Isomer then
        --         local buffDes = XFubenConfigs.GetBuffDes(self.LimitBuffId)
        --         local content = CSXTextManagerGetText("TeamSelectCharacterTypeLimitTipIsomerDebuff", buffDes)
        --         local sureCallBack = function()
        --             self:OnSelectCharacterType(index)
        --         end
        --         local closeCallback = function()
        --             self.PanelCharacterTypeBtns:SelectIndex(TabBtnIndexConvert[XCharacterConfigs.CharacterType.Normal])
        --         end
        --         XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, closeCallback, sureCallBack)
        --         return
        --     end
        -- elseif characterLimitType == XFubenConfigs.CharacterLimitType.NormalDebuff then
        --     if characterType == XCharacterConfigs.CharacterType.Normal then
        --         local buffDes = XFubenConfigs.GetBuffDes(self.LimitBuffId)
        --         local content = CSXTextManagerGetText("TeamSelectCharacterTypeLimitTipNormalDebuff", buffDes)
        --         local sureCallBack = function()
        --             self:OnSelectCharacterType(index)
        --         end
        --         local closeCallback = function()
        --             self.PanelCharacterTypeBtns:SelectIndex(TabBtnIndexConvert[XCharacterConfigs.CharacterType.Isomer])
        --         end
        --         XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, closeCallback, sureCallBack)
        --         return
        --     end
    end

    self:OnSelectCharacterType(index)
end

function XUiRoomCharacter:OnSelectCharacterType(index)
    if self.SelectTabBtnIndex == index then return end
    self.SelectTabBtnIndex = index
    local characterType = CharacterTypeConvert[index]
    self.CharIdList = {}
    self.AllCharIdList = {}
    XDataCenter.RoomCharFilterTipsManager.Reset()

    if characterType == XCharacterConfigs.CharacterType.Robot then
        self.CharIdList = self.RobotIdList and XTool.Clone(self.RobotIdList) or {}
    elseif self:IsWorldBossType() then
        self.CharIdList = XDataCenter.CharacterManager.GetRobotAndCharacterIdList(self.RobotIdList, characterType)
    elseif self:IsChessPursuitType() then
        if self.SceneUiType == XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND then
            for _, charId in pairs(self.TeamCharIdMap) do
                if charId > 0 then
                    table.insert(self.CharIdList, charId)
                end
            end
        else
            self.CharIdList = XDataCenter.CharacterManager.GetRobotAndCharacterIdList(self.RobotIdList, characterType)
        end
    elseif self.IsRobotOnly then
        self.CharIdList = XRobotManager.GetRobotIdFilterListByCharacterType(self.RobotIdList, characterType)
    elseif self.RobotAndCharacter then
        self.CharIdList = XDataCenter.CharacterManager.GetRobotAndCharacterIdList(self.RobotIdList, characterType)
    elseif self.IsRobotCorrespondCharacter then
        self.CharIdList = XDataCenter.CharacterManager.GetRobotCorrespondCharacterIdList(self.RobotIdList, characterType)
    else
        self.CharIdList = XDataCenter.CharacterManager.GetCharacterIdListInTeam(characterType)
    end

    if self.Proxy and self.Proxy.SortList then
        self.AllCharIdList = self.Proxy.SortList(self, self.CharIdList)
    else
        table.sort(self.CharIdList, self.SortFunction[XRoomCharFilterTipsConfigs.EnumSortTag.Default])
        self.AllCharIdList = self.CharIdList
    end

    self:UpdateCharacterList(index)
    self:RefreshCharacterTypeTips()
end

--初始化部分功能，当前队伍中无某个类型，则不可点击标签按钮切换
function XUiRoomCharacter:InitBtnTabIsClick()
    if not self:CheckBtnTabIsClick() then
        return
    end

    local isClickNormal, isClickOmer = false, false
    local characterType
    for _, charId in ipairs(self.TeamCharIdMap) do
        if charId > 0 then
            characterType = XCharacterConfigs.GetCharacterType(charId)
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

function XUiRoomCharacter:CheckBtnTabIsClick()
    if self:IsChessPursuitType() and self.SceneUiType == XChessPursuitCtrl.SCENE_UI_TYPE.BOSS_ROUND then
        return true
    end
    return false
end

function XUiRoomCharacter:IsCanClickBtnTab(characterType)
    if not self.CharIdList then
        return true
    end

    if not self:CheckBtnTabIsClick() then
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

function XUiRoomCharacter:SetPanelEmptyList(isEmpty)
    if self.Proxy and self.Proxy.SetPanelEmptyList then
        self.Proxy.SetPanelEmptyList(self, isEmpty)
    else
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
end

function XUiRoomCharacter:UpdatePanelEmptyList()
    if self.Proxy and self.Proxy.UpdatePanelEmptyList then
        self.Proxy.UpdatePanelEmptyList(self, self.CurCharacter.Id)
    else
        local curCharIsRobot = self.CurCharacter and XRobotManager.CheckIsRobotId(self.CurCharacter.Id) or false

        self.BtnConsciousness.gameObject:SetActiveEx(not curCharIsRobot)
        self.BtnFashion.gameObject:SetActiveEx(not curCharIsRobot)
        self.BtnWeapon.gameObject:SetActiveEx(not curCharIsRobot)
        self.BtnPartner.gameObject:SetActiveEx(not curCharIsRobot)

        self.BtnJoinTeam.gameObject:SetActiveEx(self.NeedShowBtnJoinTeam and not self:IsRogueLikeAndLock())
    end
end

function XUiRoomCharacter:CenterToGrid(grid)
    -- local normalizedPosition
    -- local count = self.SViewCharacterList.content.transform.childCount
    -- local index = grid.Transform:GetSiblingIndex()
    -- if index > count / 2 then
    --     normalizedPosition = (index + 1) / count
    -- else
    --     normalizedPosition = (index - 1) / count
    -- end
    -- self.SViewCharacterList.verticalNormalizedPosition = math.max(0, math.min(1, (1 - normalizedPosition)))
end

function XUiRoomCharacter:UpdateCharacterList(index)
    stagePass = XDataCenter.RoomManager.CheckPlayerStagePass() or XDataCenter.ArenaOnlineManager.CheckStagePass(self.ChallengeId)
    local characterType = CharacterTypeConvert[index]
    local teamCharIdMap = self.TeamCharIdMap
    local selectId = teamCharIdMap[self.TeamSelectPos]

    if not next(self.CharIdList) then
        self:SetPanelEmptyList(true)
        return
    end
    self:SetPanelEmptyList(false)

    self.CurIndex = nil
    self.CharacterIdToIndex = {}
    local useDefaultIndex = true
    if selectId and selectId ~= 0 and (characterType == XCharacterConfigs.CharacterType.Robot or characterType == XCharacterConfigs.GetCharacterType(selectId)) then
        useDefaultIndex = false
    end
    for i, id in ipairs(self.CharIdList) do
        self.CharacterIdToIndex[id] = i
        if self.CurIndex == nil and id == selectId and not useDefaultIndex then
            self.CurIndex = i
        end
    end
    self.CurIndex = self.CurIndex or 1

    local charInfo = self:GetCharInfo(self.CurIndex)
    self:UpdateInfo(charInfo)

    self.DynamicTable:SetDataSource(self.CharIdList)
    self.DynamicTable:ReloadDataASync()
end

function XUiRoomCharacter:OnDynamicTableEvent(event, index, grid)
    local characterId = self.CharIdList[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if index < 0 or index > #self.CharIdList then return end
        local char = self:GetCharInfo(index)
        grid:UpdateGrid(char, self.StageType)

        local showTeamBuff = XFubenConfigs.IsCharacterFitTeamBuff(self.TeamBuffId, characterId)
        grid:SetTeamBuff(showTeamBuff)

        if self.StageType == XDataCenter.FubenManager.StageType.BossSingle then
            local maxStamina = XDataCenter.FubenBossSingleManager.GetMaxStamina()
            local curStamina = maxStamina - XDataCenter.FubenBossSingleManager.GetCharacterChallengeCount(characterId)
            grid:UpdateStamina(curStamina, maxStamina)
        elseif self.StageType == XDataCenter.FubenManager.StageType.Explore then
            local maxStamina = XDataCenter.FubenExploreManager.GetMaxEndurance(XDataCenter.FubenExploreManager.GetCurChapterId())
            local curStamina = maxStamina - XDataCenter.FubenExploreManager.GetEndurance(XDataCenter.FubenExploreManager.GetCurChapterId(), characterId)
            grid:UpdateStamina(curStamina, maxStamina)
        elseif self.StageType == XDataCenter.FubenManager.StageType.ArenaOnline then
            if not stagePass then
                local maxStamina = XArenaOnlineConfigs.MAX_NAILI
                local curStamina = maxStamina - XDataCenter.ArenaOnlineManager.GetCharEndurance(characterId)
                grid:UpdateStamina(curStamina, maxStamina)
            end
            local isShow = XDataCenter.ArenaOnlineManager.CheckActiveBuffOnByCharId(characterId)
            grid:SetTeamBuff(isShow)
        elseif self.StageType == XDataCenter.FubenManager.StageType.InfestorExplore and XDataCenter.FubenInfestorExploreManager.IsInSectionOne() then
            local hpPercent = XDataCenter.FubenInfestorExploreManager.GetCharacterHpPrecent(char.Id)
            grid:UpdateStaminaByPercent(hpPercent)
        elseif self:IsRogueLikeType() then
            grid:SetArrowUp(XDataCenter.FubenRogueLikeManager.IsTeamEffectCharacter(characterId))
        end

        grid:SetSelect(self.CurIndex == index)
        grid:SetInTeam(false)
        for pos, id in pairs(self.TeamCharIdMap) do
            if id > 0 and self.CharacterIdToIndex[id] == index then
                grid:SetInTeam(true, CSXTextManagerGetText("CommonInTheTeam"), pos)
                break
            end
        end

        --追击玩法
        if self:IsChessPursuitType() then
            local inTeam, gridId = self:CheckIsInChessPursuit(characterId)
            if inTeam then
                grid:SetInTeam(inTeam, CSXTextManagerGetText("BfrtFightEchelonTitleSimple", gridId))
            end
            if self:IsSameCharIdInTeam(characterId) then
                grid:SetSameRoleTag(true)
            end
        elseif self:IsCoutpleCombatType() then
            --分光双星
            grid:UpdateRecommendTag(self.StageId)
            if XDataCenter.FubenCoupleCombatManager.CheckCharacterUsed(self.StageId, characterId) then
                grid:SetSameRoleTag(true, CSXTextManagerGetText("CoupleCombatRobotUsed"))
            end
        end

        grid.Transform:SetAsLastSibling()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurIndex = index
        self:UpdateInfo(grid.Character)
        self.DynamicTable:ReloadDataSync()
    end
end

function XUiRoomCharacter:GetCharInfo(index)
    local charId = self.CharIdList[index]
    if self.Proxy and self.Proxy.GetCharInfo then
        return self.Proxy.GetCharInfo(self, charId)
    else
        local charInfo = {}
        if XRobotManager.CheckIsRobotId(charId) then
            charInfo.Id = charId
            charInfo.IsRobot = true
        else
            charInfo = XDataCenter.CharacterManager.GetCharacter(charId)
        end
        return charInfo
    end
end

function XUiRoomCharacter:UpdateInfo(character)
    if character then
        self.CurCharacter = character
    end
    if not self.CurCharacter then return end

    self:UpdateTeamBtn()
    self:UpdateRoleModel()
end

function XUiRoomCharacter:UpdateTeamBtn()
    if self.Proxy and self.Proxy.UpdateTeamBtn then
        self.Proxy.UpdateTeamBtn(self, self.CurCharacter.Id)
    else
        if not (self.TeamCharIdMap and next(self.TeamCharIdMap)) then
            return
        end
        local id = self.CurCharacter.Id
        local isRobot = XRobotManager.CheckIsRobotId(id)
        local useFashion = true
        if isRobot then
            useFashion = XRobotManager.CheckUseFashion(id)
        end
        self.BtnPartner:SetDisable(isRobot, not isRobot)
        self.BtnFashion:SetDisable(not useFashion, useFashion)
        self.BtnConsciousness:SetDisable(isRobot, not isRobot)
        self.BtnWeapon:SetDisable(isRobot, not isRobot)

        --在当前操作的队伍中
        local isInTeam = self:IsInTeam(self.CurCharacter.Id)

        self.NeedShowBtnJoinTeam = not isInTeam

        self.BtnQuitTeam.gameObject:SetActiveEx(isInTeam and not self.IsHideQuitButton)
        self.BtnJoinTeam.gameObject:SetActiveEx(false)

        -- 爬塔玩法、并且角色被锁定、不能编入、卸下队伍
        if self:IsRogueLikeAndLock() then
            self.BtnQuitTeam.gameObject:SetActiveEx(false)
            self.BtnJoinTeam.gameObject:SetActiveEx(false)
        end
    end
end

function XUiRoomCharacter:IsInTeam(id)
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

-- 区域联机周刷新
function XUiRoomCharacter:OnArenaOnlineWeekRefrsh()
    if self.StageType == XDataCenter.FubenManager.StageType.ArenaOnline then
        XDataCenter.ArenaOnlineManager.RunMain()
    end
end

function XUiRoomCharacter:IsRogueLikeType()
    return self.StageType == XDataCenter.FubenManager.StageType.RogueLike
end

function XUiRoomCharacter:IsRogueLikeAndLock()
    return self:IsRogueLikeType() and XDataCenter.FubenRogueLikeManager.IsRogueLikeCharacterLock()
end

function XUiRoomCharacter:IsWorldBossType()
    return self.StageType == XDataCenter.FubenManager.StageType.WorldBoss
end

function XUiRoomCharacter:IsChessPursuitType()
    return self.StageType == XDataCenter.FubenManager.StageType.ChessPursuit
end

function XUiRoomCharacter:IsCoutpleCombatType()
    return self.StageType == XDataCenter.FubenManager.StageType.CoupleCombat
end

function XUiRoomCharacter:IsNewCharType()
    return self.StageType == XDataCenter.FubenManager.StageType.NewCharAct
end

function XUiRoomCharacter:IsHackType()
    return self.StageType == XDataCenter.FubenManager.StageType.Hack
end

function XUiRoomCharacter:IsSummerEpisodePhotoType()
    return XDataCenter.FubenSpecialTrainManager.IsPhotoStage(self.StageId)
end

function XUiRoomCharacter:IsActivityBossSingle()
    return self.StageType == XDataCenter.FubenManager.StageType.ActivityBossSingle
end

function XUiRoomCharacter:UpdateRoleModel()
    local characterId = self.CurCharacter and self.CurCharacter.Id
    if not characterId then return end
    local targetPanelRole = self.PanelRoleModel
    local targetUiName = self.Name
    local func = function()
        self:UpdatePanelEmptyList()
    end
    local characterFunc = function(model)
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
        local robotId = self.CurCharacter.Id
        characterId = XRobotManager.GetCharacterId(robotId)
        local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(characterId)

        if isOwn and XRobotManager.CheckUseFashion(robotId) then
            local character = XDataCenter.CharacterManager.GetCharacter(characterId)
            local viewModel = character:GetCharacterViewModel()
            self.RoleModelPanel:UpdateCharacterModel(characterId, targetPanelRole, targetUiName, characterFunc, func, viewModel:GetFashionId())
        else
            local robotCfg = XRobotManager.GetRobotTemplate(robotId)
            self.RoleModelPanel:UpdateRobotModel(robotId, characterId, func, robotCfg.FashionId, robotCfg.WeaponId, characterFunc)
        end
    else
        self.RoleModelPanel:UpdateCharacterModel(self.CurCharacter.Id, targetPanelRole, targetUiName, characterFunc, func)
    end
end

function XUiRoomCharacter:OnBtnBackClick()
    if self.TeamResultCb then
        self.TeamResultCb(self.TeamCharIdMap)
    end
    self:Close()
end

function XUiRoomCharacter:OnBtnJoinTeamClick()
    local id = self.CurCharacter.Id
    if self.StageType == XDataCenter.FubenManager.StageType.BossSingle then
        local challengeCount = XDataCenter.FubenBossSingleManager.GetCharacterChallengeCount(id)
        if challengeCount >= XDataCenter.FubenBossSingleManager.GetMaxStamina() then
            XUiManager.TipCode(XCode.FubenBossSingleCharacterPointsNotEnough)
            return
        end
    elseif self.StageType == XDataCenter.FubenManager.StageType.ArenaOnline then
        local stagePass = XDataCenter.RoomManager.CheckPlayerStagePass() or XDataCenter.ArenaOnlineManager.CheckStagePass(self.ChallengeId)
        if not stagePass then
            local cost = XDataCenter.ArenaOnlineManager.GetStageEndurance(self.ChallengeId)
            local cur = XArenaOnlineConfigs.MAX_NAILI - XDataCenter.ArenaOnlineManager.GetCharEndurance(id)
            if cost > cur then
                XUiManager.TipText("ArenaOnlineCharEnduranceTip", XUiManager.UiTipType.Tip)
                return
            end
        end
    end

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
    local isSpecialStage = XFubenSpecialTrainConfig.IsSpecialTrainStage(self.StageId, XFubenSpecialTrainConfig.StageType.Photo) or
            XFubenSpecialTrainConfig.IsSpecialTrainStage(self.StageId, XFubenSpecialTrainConfig.StageType.Music) or
            XFubenSpecialTrainConfig.IsSpecialTrainStage(self.StageId, XFubenSpecialTrainConfig.StageType.Rhythm)
    if not self.NotReset and (not isSpecialStage) then
        -- 角色类型不一致拦截
        local inTeamCharacterType = self:GetTeamCharacterType()
        if inTeamCharacterType then
            local characterType = id and id ~= 0 and XCharacterConfigs.GetCharacterType(id)
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
    end

    if self:IsChessPursuitType() then
        local isIn, gridId, teamDataIndex = self:CheckIsInChessPursuit(id)
        if isIn then
            local content = CSXTextManagerGetText("ChessPursuitDeploySwitchTipsContent", gridId)
            local sureCallBack = function()
                if not XDataCenter.ChessPursuitManager.CheckIsSwapTeamPos(gridId, teamDataIndex, self.TeamGridIndex, self.TeamSelectPos) then
                    XUiManager.TipText("ChessPursuitNotSwitchCharacter")
                    return
                end
                joinFunc()
            end
            XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, sureCallBack)
            return
        end
    end

    joinFunc()
end

function XUiRoomCharacter:OnBtnQuitTeamClick()
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

function XUiRoomCharacter:OnBtnFashionClick()
    local id = self.CurCharacter.Id
    local isRobot = XRobotManager.CheckIsRobotId(id)
    if isRobot and XRobotManager.CheckUseFashion(id) then
        local characterId = XRobotManager.GetCharacterId(id)
        local isOwn  = XDataCenter.CharacterManager.IsOwnCharacter(characterId)
        if not isOwn then
            XUiManager.TipText("CharacterLock")
            return
        else
            XLuaUiManager.Open("UiFashion", characterId, nil, nil, XUiConfigs.OpenUiType.RobotFashion)
        end
    else
        XLuaUiManager.Open("UiFashion", id)
    end
end

function XUiRoomCharacter:OnBtnBtnTeachingClick()
    local id = self.CurCharacter.Id
    XDataCenter.PracticeManager.OpenUiFubenPractice(id, true)
end

function XUiRoomCharacter:GetTeamCharacterType()
    for k, v in pairs(self.TeamCharIdMap) do
        if v ~= 0 then
            return XCharacterConfigs.GetCharacterType(v)
        end
    end
end

function XUiRoomCharacter:GetCharacterId(id)
    if XRobotManager.CheckIsRobotId(id) then
        return XRobotManager.GetRobotTemplate(id).CharacterId
    else
        return id
    end
end

function XUiRoomCharacter:GetAbility(id)
    if XRobotManager.CheckIsRobotId(id) then
        return XRobotManager.GetRobotAbility(id)
    else
        return XDataCenter.CharacterManager.GetCharacter(id).Ability
    end
end

function XUiRoomCharacter:GetLevel(id)
    if XRobotManager.CheckIsRobotId(id) then
        return XRobotManager.GetRobotTemplate(id).CharacterLevel
    else
        return XDataCenter.CharacterManager.GetCharacter(id).Level
    end
end

function XUiRoomCharacter:GetQuality(id)
    if XRobotManager.CheckIsRobotId(id) then
        return XRobotManager.GetRobotTemplate(id).CharacterQuality
    else
        return XDataCenter.CharacterManager.GetCharacter(id).Quality
    end
end

function XUiRoomCharacter:Filter(selectTagGroupDic, sortTagId, isThereFilterDataCb)

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
            XLog.Error(string.format("XUiRoomCharacter:Filter函数错误，没有处理排序组：%s的逻辑", groupId))
            return false
        end
    end

    XDataCenter.RoomCharFilterTipsManager.Filter(self.TagCacheDic, selectTagGroupDic, self.AllCharIdList, judgeCb,
    function(filteredData)
        self:FilterRefresh(filteredData, sortTagId)
    end,
    isThereFilterDataCb)
end

function XUiRoomCharacter:FilterRefresh(filteredData, sortTagId)
    self.CharIdList = filteredData

    if not next(filteredData) then
        self:SetPanelEmptyList(true)
        return
    end
    self:SetPanelEmptyList(false)

    if self.SortFunction[sortTagId] then
        table.sort(filteredData, self.SortFunction[sortTagId])
    else
        XLog.Error(string.format("XUiRoomCharacter:FilterRefresh函数错误，没有定义标签：%s的排序函数", sortTagId))
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

function XUiRoomCharacter:CheckIsInChessPursuit(characterId)
    if not self:IsChessPursuitType() then
        return false
    end

    local isIn, gridId, teamDataIndex = XDataCenter.ChessPursuitManager.CheckIsInChessPursuit(self.MapId, characterId, self.TeamGridIndex)
    return isIn, gridId, teamDataIndex
end

function XUiRoomCharacter:ShowChessPursuitDialogTip(characterId, sureCallBack)
    local name = XCharacterConfigs.GetCharacterName(characterId)
    local title = CSXTextManagerGetText("BfrtDeployTipTitle")
    local content = CSXTextManagerGetText("ChessPursuitReplaceCharacterTip", name)
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, sureCallBack)
end

function XUiRoomCharacter:IsSameCharIdInTeam(characterId)
    if self:IsInTeam(characterId) then
        return false
    end

    characterId = XRobotManager.CheckIdToCharacterId(characterId)
    local inTeamCharId
    for _, charId in pairs(self.TeamCharIdMap) do
        inTeamCharId = XRobotManager.CheckIdToCharacterId(charId)
        if characterId == inTeamCharId then
            return true
        end
    end
    return false
end

--================
--接受到活动重置或结束消息时
--================
function XUiRoomCharacter:OnResetEvent(stageType)
    if self.StageType ~= stageType then return end
    if self.Proxy.OnResetEvent then self.Proxy.OnResetEvent(self) end
end