-- 调整表战争角色界面
local XUiColorTableCharacter = XLuaUiManager.Register(XLuaUi, "UiColorTableCharacter")
local XUiGridColorTableCharacter = require("XUi/XUiColorTable/Grid/XUiGridColorTableCharacter")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local TabBtnIndex = {
    Normal = 1, --构造体
    Isomer = 2, --异构体/感染体
    Robot = 3, --试玩角色
}

function XUiColorTableCharacter:OnAwake()
    self:SetButtonCallBack()
    self:InitModel()
    self:InitDynamicTable()
    self:InitTimes()

    self.CurTabIndex = TabBtnIndex.Normal
    self.CurSelectRole = nil
    self.CurRoleIndex = 1
    self.FiltSortListTypeDic = {}
    
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.ColorTableCoin)
    self.AssetPanel:HideBtnBuy()
end

function XUiColorTableCharacter:OnStart(xTeam, teamPos, stageId)
    self.XTeam = xTeam
    self.TeamPos = teamPos
    self.StageId = stageId

    self.CurTabIndex = TabBtnIndex.Normal
    if xTeam and teamPos then
        local entityId = xTeam:GetEntityIdByTeamPos(teamPos)
        if entityId ~= 0 then 
            local xRole = XEntityHelper.GetEntityByIds({entityId})[1]
            if XEntityHelper.GetIsRobot(entityId) then 
                self.CurTabIndex = TabBtnIndex.Robot
            else
                self.CurTabIndex = XEntityHelper.GetCharacterType(entityId)
            end

            self.LastSelectNormalCharacter = self.CurTabIndex == TabBtnIndex.Normal and xRole or self.LastSelectNormalCharacter 
            self.LastSelectIsomerCharacter = self.CurTabIndex == TabBtnIndex.Isomer and xRole or self.LastSelectIsomerCharacter
            self.LastSelectRobotCharacter = self.CurTabIndex == TabBtnIndex.Robot and xRole or self.LastSelectRobotCharacter
        end
    end
end

function XUiColorTableCharacter:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnFashion, self.OnBtnFashionClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPartner, self.OnBtnPartnerClick)
    XUiHelper.RegisterClickEvent(self, self.BtnConsciousness, self.OnBtnConsciousnessClick)
    XUiHelper.RegisterClickEvent(self, self.BtnWeapon, self.OnBtnWeaponClick)
    XUiHelper.RegisterClickEvent(self, self.BtnJoinTeam, self.OnBtnJoinTeamClick)
    XUiHelper.RegisterClickEvent(self, self.BtnQuitTeam, self.OnBtnQuitTeamClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFilter, self.OnBtnFilterClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTeaching, function() XDataCenter.PracticeManager.OpenUiFubenPractice(self.CurSelectRole:GetCharacterId()) end)

    local tabBtns = { self.BtnTabGouzaoti, self.BtnTabShougezhe, self.BtnTabHelp }
    self.PanelCharacterTypeBtns:Init(tabBtns, function(index) self:OnSelectCharacterType(index) end)

    XEventManager.AddEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.RefreshTeamData, self)
end

function XUiColorTableCharacter:OnSelectCharacterType(index)
    if index == TabBtnIndex.Isomer then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Isomer) then 
            return
        end

        local characterType = index
        local entities = XMVCA.XCharacter:GetOwnCharacterList(characterType)
        if entities == nil or #entities == 0 then 
            XUiManager.TipText("DormNullInfestor")
            self.PanelCharacterTypeBtns:SelectIndex(self.CurTabIndex)
            return
        end
    end

    self.CurTabIndex = index
    if index == TabBtnIndex.Normal then
        self.ImgEffectHuanren.gameObject:SetActiveEx(false)
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        self:UpdateCharacters(self.LastSelectNormalCharacter)
    elseif index == TabBtnIndex.Isomer then
        self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
        self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
        self:UpdateCharacters(self.LastSelectIsomerCharacter)
    elseif index == TabBtnIndex.Robot then
        self:UpdateCharacters(self.LastSelectRobotCharacter)
    end
end

function XUiColorTableCharacter:InitModel()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.UiPanelRoleModel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiColorTableCharacter:InitDynamicTable()
    self.GridCharacter.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiGridColorTableCharacter, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiColorTableCharacter:OnEnable()
    self.Super.OnEnable(self)
    self.PanelCharacterTypeBtns:SelectIndex(self.CurTabIndex)
end

function XUiColorTableCharacter:OnDisable()
    self.Super.OnDisable(self)
end

function XUiColorTableCharacter:OnDestroy()
    XDataCenter.CommonCharacterFiltManager.ClearCacheData() --清除筛选缓存数据
    XEventManager.RemoveEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.RefreshTeamData, self)
end

-- 刷新左边角色列表
function XUiColorTableCharacter:UpdateCharacters(xRole)
    local roleList = self.FiltSortListTypeDic[self.CurTabIndex] or self:GetCharacterList() 
    local index = 1
    if xRole then
        local isIn, curIndex = table.contains(roleList, xRole)
        index = isIn and curIndex or index
    end
    
    self.CurRoleIndex = index
    self.CurSelectRole = xRole or roleList[index]
    self:UpdateDynamicTable(roleList, index)

    -- 刷新列表时切换角色
    self:UpdateRoleModel()
    self:UpdateRightCharacterInfo()
end

function XUiColorTableCharacter:GetCharacterList()
    local entities = {}
    if self.CurTabIndex == TabBtnIndex.Normal or self.CurTabIndex == TabBtnIndex.Isomer then
        local characterType = self.CurTabIndex
        entities = XMVCA.XCharacter:GetOwnCharacterList(characterType)
    elseif self.CurTabIndex == TabBtnIndex.Robot then
        local curStageId = XDataCenter.ColorTableManager.GetCurStageId()
        local robotIds = XColorTableConfigs.GetStageRobotIds(curStageId)

        for _, robotId in ipairs(robotIds) do
            table.insert(entities, XRobotManager.GetRobotById(robotId))
        end
    end

    return self:SortEntitiesWithTeam(self.XTeam, entities)
end

-- 排序算法，默认队伍>XDataCenter.RoomCharFilterTipsManager.GetSort
-- team : XTeam
-- sortTagType : XRoomCharFilterTipsConfigs.EnumSortTag
function XUiColorTableCharacter:SortEntitiesWithTeam(team, entities, sortTagType)
    local inTeamEntities = {}
    for i = #entities, 1, -1 do
        if team:GetEntityIdIsInTeam(entities[i]:GetId()) then
            table.insert(inTeamEntities, entities[i])
            table.remove(entities, i)
        end
    end
    table.sort(entities, function(entityA, entityB)
        return XDataCenter.RoomCharFilterTipsManager.GetSort(entityA:GetCharacterViewModel():GetId()
            , entityB:GetCharacterViewModel():GetId(), nil, false, sortTagType)
    end)
    table.sort(inTeamEntities, function(entityA, entityB)
        return XDataCenter.RoomCharFilterTipsManager.GetSort(entityA:GetCharacterViewModel():GetId()
            , entityB:GetCharacterViewModel():GetId(), nil, false, sortTagType)
    end)
    for i = #inTeamEntities, 1, -1 do
        table.insert(entities, 1, inTeamEntities[i])
    end
    return entities
end

function XUiColorTableCharacter:UpdateDynamicTable(entityList, index)
    self.RoleEntityList = entityList
    self.DynamicTable:SetDataSource(entityList)
    self.DynamicTable:ReloadDataASync(index or 1)

    local isShowEmptyTips = #entityList == 0 and self.CurTabIndex == TabBtnIndex.Isomer
    self.PanelEmptyList.gameObject:SetActiveEx(isShowEmptyTips)
end

-- 角色被选中
function XUiColorTableCharacter:OnRoleSelected(index)
    local roleList = self.FiltSortListTypeDic[self.CurTabIndex] or self:GetCharacterList()
    local xRole = roleList[index]
    if xRole == self.CurSelectRole then
        return
    end

    self.CurRoleIndex = index
    self.CurSelectRole = xRole
    if self.CurTabIndex == TabBtnIndex.Normal then
        self.LastSelectNormalCharacter = xRole
    elseif self.CurTabIndex == TabBtnIndex.Isomer then
        self.LastSelectIsomerCharacter = xRole
    elseif self.CurTabIndex == TabBtnIndex.Robot then
        self.LastSelectRobotCharacter = xRole
    end

    -- 选中页签时切换角色
    self:UpdateRoleModel()
    self:UpdateRightCharacterInfo()
end

-- 刷新右边角色信息
function XUiColorTableCharacter:UpdateRightCharacterInfo()
    if not self.CurSelectRole then
        return
    end

    local roleId = self.CurSelectRole:GetId()

    -- 处理相同characterId的robot
    local characterId = XEntityHelper.GetCharacterIdByEntityId(roleId)

    -- 战斗参数
    self.TxtRequireAbility.text = XDataCenter.ColorTableManager.GetStageAbilityTips(self.StageId)

    -- 队长加成
    local isCaptain = XDataCenter.ColorTableManager.IsCaptainRole(characterId)
    self.PanelCaptain.gameObject:SetActiveEx(isCaptain)
    if isCaptain then
        local captainId = XDataCenter.ColorTableManager.GetGameCaptainId()
        self.TxtCaptainDesc.text = XColorTableConfigs.GetCaptainCharacterDesc(captainId)
    end

    -- 特殊角色加成
    local isSpecialAtk = XDataCenter.ColorTableManager.IsSpecialRole(characterId)
    self.PanelSpecial.gameObject:SetActiveEx(isSpecialAtk)
    if isSpecialAtk then
        self.TxtSpecialDesc.text = XColorTableConfigs.GetSpecialRoleDesc(characterId)
    end

    -- 上阵类型提示
    local limitType = XFubenConfigs.GetStageCharacterLimitType(self.StageId)
    local charType = self.CurTabIndex
    local text = XFubenConfigs.GetStageCharacterLimitTextSelectCharacter(limitType, charType)
    self.TxtRequireCharacter.text = text
    local isShow = text ~= nil and text ~= ""
    self.PanelRequireCharacter.gameObject:SetActiveEx(isShow)

    -- 按钮状态
    local isRobot = XRobotManager.CheckIsRobotId(roleId)
    self.BtnFashion:SetDisable(isRobot)
    self.BtnPartner:SetDisable(isRobot)
    self.BtnConsciousness:SetDisable(isRobot)
    self.BtnWeapon:SetDisable(isRobot)
    if self.TeamPos then
        local isInTeam = self.XTeam:GetEntityIdIsInTeam(roleId)
        self.BtnJoinTeam.gameObject:SetActiveEx(not isInTeam)
        self.BtnQuitTeam.gameObject:SetActiveEx(isInTeam)
    else
        self.BtnTeamPrefab.gameObject:SetActiveEx(false)
        self.BtnJoinTeam.gameObject:SetActiveEx(false)
        self.BtnQuitTeam.gameObject:SetActiveEx(false)
    end
end

-- 刷新3D模型
function XUiColorTableCharacter:UpdateRoleModel()
    if self.CurSelectRole == nil then
        return
    end

    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    local finishedCallback = function(model)
        self.PanelDrag.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(self.CurTabIndex == XEnumConst.CHARACTER.CharacterType.Normal)
        self.ImgEffectHuanren1.gameObject:SetActiveEx(self.CurTabIndex == XEnumConst.CHARACTER.CharacterType.Isomer)
    end
    local characterViewModel = self.CurSelectRole:GetCharacterViewModel()
    local sourceEntityId = characterViewModel:GetSourceEntityId()
    if XRobotManager.CheckIsRobotId(sourceEntityId) then
        local robot2CharEntityId = XRobotManager.GetCharacterId(sourceEntityId)
        local isOwen = XMVCA.XCharacter:IsOwnCharacter(robot2CharEntityId)
        if XRobotManager.CheckUseFashion(sourceEntityId) and isOwen then
            local character = XMVCA.XCharacter:GetCharacter(robot2CharEntityId)
            local robot2CharViewModel = character:GetCharacterViewModel()
            self.UiPanelRoleModel:UpdateCharacterModel(robot2CharEntityId
            , self.PanelRoleModelGo
            , self.Name
            , finishedCallback
            , nil
            , robot2CharViewModel:GetFashionId())
        else
            local robotConfig = XRobotManager.GetRobotTemplate(sourceEntityId)
            self.UiPanelRoleModel:UpdateRobotModel(sourceEntityId
            , robotConfig.CharacterId
            , nil
            , robotConfig.FashionId
            , robotConfig.WeaponId
            , finishedCallback
            , nil
            , self.PanelRoleModelGo
            , self.Name)
        end
    else
        self.UiPanelRoleModel:UpdateCharacterModel(
        sourceEntityId,
        self.PanelRoleModelGo,
        self.Name,
        finishedCallback,
        nil,
        characterViewModel:GetFashionId()
        )
    end
end

function XUiColorTableCharacter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local entity = self.RoleEntityList[index]
        local isSelect = self.CurRoleIndex == index
        local isInTeam = self.XTeam:GetEntityIdIsInTeam(entity:GetId())
        grid:Refresh(entity)
        grid:SetSelectStatus(isSelect)
        grid:SetInTeamStatus(isInTeam)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        
        -- 刷新选中ui
        for _, tmpGrid in pairs(self.DynamicTable:GetGrids()) do
            tmpGrid:SetSelectStatus(false)
        end
        grid:SetSelectStatus(true)

        self:OnRoleSelected(index)
    end
end

function XUiColorTableCharacter:RefreshTeamData(teamdata)
    if XTool.IsTableEmpty(teamdata) then
        return
    end
    self.XTeam:UpdateFromTeamData(teamdata)
end

function XUiColorTableCharacter:OnBtnJoinTeamClick()
    -- 处理相同characterId的robot
    local characterId = XEntityHelper.GetCharacterIdByEntityId(self.CurSelectRole:GetId())
    local entityIds = self.XTeam:GetEntityIds()
    for pos, entityId in ipairs(entityIds) do
        if characterId == XEntityHelper.GetCharacterIdByEntityId(entityId) then
            self.XTeam:UpdateEntityTeamPos(nil, pos, true)
        end
    end

    self.XTeam:UpdateEntityTeamPos(self.CurSelectRole:GetId(), self.TeamPos, true)
    self:Close()
end

function XUiColorTableCharacter:OnBtnQuitTeamClick()
    self.XTeam:UpdateEntityTeamPos(self.CurSelectRole:GetId())
    self:Close()
end

function XUiColorTableCharacter:OnBtnConsciousnessClick()
    if self.CurTabIndex == TabBtnIndex.Robot then return end
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwareness(self.CurSelectRole:GetId())
end

function XUiColorTableCharacter:OnBtnWeaponClick()
    if self.CurTabIndex == TabBtnIndex.Robot then return end
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self.CurSelectRole:GetId(), nil, true)
end

function XUiColorTableCharacter:OnBtnFashionClick()
    if self.CurTabIndex == TabBtnIndex.Robot then return end
    XLuaUiManager.Open("UiFashion", self.CurSelectRole:GetId())
end

function XUiColorTableCharacter:OnBtnPartnerClick()
    if self.CurTabIndex == TabBtnIndex.Robot then return end
    XDataCenter.PartnerManager.GoPartnerCarry(self.CurSelectRole:GetId(), false)
end

function XUiColorTableCharacter:OnBtnFilterClick()
    local characterType = self.CurTabIndex
    local charList = self:GetCharacterList()
    XLuaUiManager.Open("UiCommonCharacterFilterTipsOptimization", charList, characterType, function(afterFiltList)
        self.FiltSortListTypeDic[characterType] = afterFiltList
        self:UpdateDynamicTable(afterFiltList)
    end, characterType)
end

function XUiColorTableCharacter:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.ColorTableManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end