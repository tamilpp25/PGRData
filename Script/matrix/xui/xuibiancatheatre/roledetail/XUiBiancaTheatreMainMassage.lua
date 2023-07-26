local XUiTheatreMassageGrid = require("XUi/XUiBiancaTheatre/RoleDetail/XUiTheatreMassageGrid")
local XUiTheatreOwnedInfoPanel = require("XUi/XUiBiancaTheatre/RoleDetail/XUiTheatreOwnedInfoPanel")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

--肉鸽二期成员列表界面
local XUiBiancaTheatreMainMassage = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreMainMassage")

function XUiBiancaTheatreMainMassage:OnAwake()
    self.TheatreManager = XDataCenter.BiancaTheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()
    self.RoleSelectStateDic = {} --招募角色当前显示的是试玩角色或自己的角色，false显示试玩角色，true显示对应自己的角色

    XDataCenter.CommonCharacterFiltManager.ClearCacheData() --清除筛选缓存数据
    self:InitSortFunction()

    self.CurrentEntityId = nil
    self.CurrentSelectTagGroup = {
        [XCharacterConfigs.CharacterType.Normal] = {},
        [XCharacterConfigs.CharacterType.Isomer] = {}
    }

    self.CurrentCharacterType = self:GetDefaultCharacterType()

    -- 角色列表
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiTheatreMassageGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridCharacterNew.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()

    -- 模型初始化
    local panelRoleModel = self.UiModelGo.transform:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = self.UiModelGo.transform:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = self.UiModelGo.transform:FindTransform("ImgEffectHuanren1")
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    self.UiPanelRoleModel = XUiPanelRoleModel.New(panelRoleModel, self.Name, nil, true)
    XUiHelper.NewPanelActivityAsset(XDataCenter.BiancaTheatreManager.GetAdventureAssetItemIds(), self.PanelSpecialTool, nil, XDataCenter.BiancaTheatreManager.AdventureAssetItemOnBtnClick)

    self.OwnedInfoPanel = XUiTheatreOwnedInfoPanel.New(self.UiOwnedInfo, handler(self, self.SwitchRoleState), self)

    self.IsAscendOrder = false   --初始降序
    self:CheckBtnFilterActive()
    self:InitBtnTabShougezhe()
end

function XUiBiancaTheatreMainMassage:OnEnable()
    self.PanelCharacterTypeBtns:SelectIndex(self.CurrentCharacterType)
    -- 界定音效滤镜界限
    XDataCenter.BiancaTheatreManager.ResetAudioFilter()
end

function XUiBiancaTheatreMainMassage:OnDestroy()
    XDataCenter.CommonCharacterFiltManager.ClearCacheData() --清除筛选缓存数据
end

function XUiBiancaTheatreMainMassage:InitBtnTabShougezhe()
    local lockShougezhe = not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer)
    local roles = self.AdventureManager:GetCurrentRoles()
    local isHaveIsomer = false
    for _, role in ipairs(roles) do
        if role:GetCharacterViewModel():GetCharacterType() == XCharacterConfigs.CharacterType.Isomer then
            isHaveIsomer = true
            break
        end
    end
    self.BtnTabShougezhe:SetDisable(lockShougezhe and not isHaveIsomer)
end

function XUiBiancaTheatreMainMassage:GetDefaultCharacterType()
    local roles
    for characterType in ipairs(self.CurrentSelectTagGroup) do
        roles = self:GetAdventureRoles(characterType)
        if not XTool.IsTableEmpty(roles) then
            return characterType
        end
    end
end

function XUiBiancaTheatreMainMassage:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:RegisterClickEvent(self.BtnFilter, self.OnBtnFilterClicked)
    self:RegisterClickEvent(self.BtnFashion, self.OnBtnFashionClick)
    self:RegisterClickEvent(self.BtnOwnedDetail, self.OnBtnOwnedDetailClick)
    self:RegisterClickEvent(self.BtnTeaching, self.OnBtnTeachingClick)
    self:RegisterClickEvent(self.BtnShengxu, self.OnBtnOrderClick)
    self:RegisterClickEvent(self.BtnJiangxu, self.OnBtnOrderClick)
    self:BindHelpBtn(self.BtnHelp, XDataCenter.BiancaTheatreManager.GetHelpKey())
    -- 角色类型按钮组
    self.PanelCharacterTypeBtns:Init(
    {
        [XCharacterConfigs.CharacterType.Normal] = self.BtnTabGouzaoti,
        [XCharacterConfigs.CharacterType.Isomer] = self.BtnTabShougezhe
    },
    function(tabIndex)
        self:OnPanelCharacterTypeBtnsClicked(tabIndex)
    end
    )
end

function XUiBiancaTheatreMainMassage:GetCurrentCharacterId()
    local entityId = self.CurrentEntityId
    local adventureRole = self.AdventureManager:GetRole(entityId)
    return adventureRole:GetCharacterId()
end

--货币点击方法
function XUiBiancaTheatreMainMassage:OnBtnClick(index)
    XLuaUiManager.Open("UiBiancaTheatreTips", XBiancaTheatreConfigs.TheatreOutCoin)
end

function XUiBiancaTheatreMainMassage:OnBtnOwnedDetailClick()
    XLuaUiManager.Open("UiCharacterDetail", self:GetCurrentCharacterId())
end

function XUiBiancaTheatreMainMassage:OnBtnTeachingClick()
    XDataCenter.PracticeManager.OpenUiFubenPractice(self:GetCurrentCharacterId())
end

function XUiBiancaTheatreMainMassage:OnBtnFashionClick()
    XLuaUiManager.Open("UiFashion", self:GetCurrentCharacterId())
end

function XUiBiancaTheatreMainMassage:OnBtnFilterClicked()
    -- 打开筛选器(v1.30新筛选器)
    local characterType = self.CurrentCharacterType
    local characterList = self:GetAdventureRoles(characterType)

    XLuaUiManager.Open("UiCommonCharacterFilterTipsOptimization", characterList, characterType, function (afterFiltList)
        local selectTagType = XDataCenter.CommonCharacterFiltManager.GetSortData(characterType)
        self.FiltSortListTypeDic[characterType] = afterFiltList
        self:RefreshRoleList(self:DoSort(afterFiltList, selectTagType, self.IsAscendOrder))
    end, characterType)
end

function XUiBiancaTheatreMainMassage:OnBtnOrderClick()
    self.IsAscendOrder = not self.IsAscendOrder
    self:CheckBtnFilterActive()

    local characterType = self.CurrentCharacterType
    local selectTagType = XDataCenter.CommonCharacterFiltManager.GetSortData(characterType)
    local roleList = self.FiltSortListTypeDic[characterType] or self.DynamicTable.DataSource
    self:RefreshRoleList(self:DoSort(roleList, selectTagType, self.IsAscendOrder))
end

function XUiBiancaTheatreMainMassage:CheckBtnFilterActive()
    self.BtnShengxu.gameObject:SetActiveEx(self.IsAscendOrder)
    self.BtnJiangxu.gameObject:SetActiveEx(not self.IsAscendOrder)
end

function XUiBiancaTheatreMainMassage:GetAdventureRoles(characterType)
    local roles = self.AdventureManager:GetCurrentRoles(true)
    local result = {}
    for _, role in ipairs(roles) do
        if role:GetCharacterViewModel():GetCharacterType() == characterType then
            local entityId = role:GetId()
            table.insert(result, role)

            if self.RoleSelectStateDic[entityId] == nil then
                self.RoleSelectStateDic[entityId] = false
            end
        end
    end
    return result
end

-- characterType : XCharacterConfigs.CharacterType
function XUiBiancaTheatreMainMassage:OnPanelCharacterTypeBtnsClicked(characterType)
    self.CurrentCharacterType = characterType
    local roles = self:GetAdventureRoles(self.CurrentCharacterType)
    if XTool.IsTableEmpty(roles) then
        if self.CurrentCharacterType == XCharacterConfigs.CharacterType.Isomer then
            XUiManager.TipError(XUiHelper.GetText("IsomerLimitTip"))
        else
            XUiManager.TipError(XUiHelper.GetText("NormalLimitTip"))
        end
        local defaultType = self:GetDefaultCharacterType()
        roles = self:GetAdventureRoles(defaultType)
        if not XTool.IsTableEmpty(roles) then
            self.PanelCharacterTypeBtns:SelectIndex(defaultType)
        end
        return
    end

    local characterType = self.CurrentCharacterType
    local selectTagType = XDataCenter.CommonCharacterFiltManager.GetSortData(characterType)
    local roleList = self.FiltSortListTypeDic[characterType] or roles
    self:RefreshRoleList(self:DoSort(roleList, selectTagType, self.IsAscendOrder))
end

function XUiBiancaTheatreMainMassage:RefreshRoleList(roleEntities)
    local searchEntityId = self.CurrentEntityId
    local index = 1
    if searchEntityId ~= nil or searchEntityId ~= 0 then
        for i, v in ipairs(roleEntities) do
            if v:GetId() == searchEntityId then
                index = i
                break
            end
        end
    end
    self.CurAdventureRole = roleEntities[index] 
    self.CurrentEntityId = self.CurAdventureRole:GetId()
    self.DynamicTable:SetDataSource(roleEntities)
    self.DynamicTable:ReloadDataSync(index)
    self:RefreshModel()
    self:RefreshDetailPanel()
end

function XUiBiancaTheatreMainMassage:OnDynamicTableEvent(event, index, grid)
    if index <= 0 or index > #self.DynamicTable.DataSource then
        return
    end
    local entity = self.DynamicTable.DataSource[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetSelect(self.CurrentEntityId == entity:GetId())
        if self.RoleSelectStateDic[entity:GetId()] then
            local characterId = entity:GetCharacterId()
            entity = self.AdventureManager:GetRole(characterId)
        end
        grid:UpdateGrid(entity)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurrentEntityId = entity:GetId()
        self.CurAdventureRole = entity
        for _, tmpGrid in pairs(self.DynamicTable:GetGrids()) do
            tmpGrid:SetSelect(false)
        end
        grid:SetSelect(true)
        self:RefreshModel()
        self:RefreshDetailPanel()
    end
end

function XUiBiancaTheatreMainMassage:RefreshModel()
    local entityId = self.CurrentEntityId
    local adventureRole = self.AdventureManager:GetRole(entityId)
    local characterViewModel = self.RoleSelectStateDic[entityId] and self:GetCharacterViewModelByEntityId(adventureRole:GetCharacterId()) or self:GetCharacterViewModelByEntityId(entityId)
    if not characterViewModel then
        return
    end

    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    local finishedCallback = function(model)
        self.PanelDrag.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(
        self.CurrentCharacterType == XCharacterConfigs.CharacterType.Normal
        )
        self.ImgEffectHuanren1.gameObject:SetActiveEx(
        self.CurrentCharacterType == XCharacterConfigs.CharacterType.Isomer
        )
    end

    local sourceEntityId = characterViewModel:GetSourceEntityId()
    if XRobotManager.CheckIsRobotId(sourceEntityId) then
        local robot2CharId = XRobotManager.GetCharacterId(sourceEntityId)
        local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(robot2CharId)
        if XRobotManager.CheckUseFashion(sourceEntityId) and isOwn then
            local character = XDataCenter.CharacterManager.GetCharacter(robot2CharId)
            local robot2CharViewModel = character:GetCharacterViewModel()
            self.UiPanelRoleModel:UpdateCharacterModel(robot2CharId, nil, nil, finishedCallback, nil, robot2CharViewModel:GetFashionId())
        else
            local robotConfig = XRobotManager.GetRobotTemplate(sourceEntityId)
            self.UiPanelRoleModel:UpdateRobotModel(sourceEntityId, robotConfig.CharacterId, nil, robotConfig.FashionId, robotConfig.WeaponId, finishedCallback)
        end
    else
        self.UiPanelRoleModel:UpdateCharacterModel(
        sourceEntityId,
        nil,
        nil,
        finishedCallback,
        nil,
        characterViewModel:GetFashionId()
        )
    end
end

function XUiBiancaTheatreMainMassage:GetCharacterViewModelByEntityId(entityId)
    local role = self.AdventureManager:GetRole(entityId)
    if role == nil then return nil end
    return role:GetCharacterViewModel()
end

function XUiBiancaTheatreMainMassage:RefreshDetailPanel()
    local entityId = self.CurrentEntityId
    self.OwnedInfoPanel:SetData(self.CurAdventureRole, entityId)
    
    local isShowBtnFashion = false
    local adventureRole = self.AdventureManager:GetRole(entityId)
    local characterViewModel = self.RoleSelectStateDic[entityId] and self:GetCharacterViewModelByEntityId(adventureRole:GetCharacterId()) or self:GetCharacterViewModelByEntityId(entityId)
    if characterViewModel then
        local sourceEntityId = characterViewModel:GetSourceEntityId()
        local robot2CharId = XRobotManager.GetCharacterId(sourceEntityId)
        -- 机器人有配置就展示涂装按钮
        if XRobotManager.CheckIsRobotId(sourceEntityId)  then
            isShowBtnFashion = XRobotManager.CheckUseFashion(sourceEntityId)
        -- 玩家拥有角色就展示涂装按钮
        elseif XDataCenter.CharacterManager.IsOwnCharacter(robot2CharId) then
            isShowBtnFashion = true
        end
    end
    self.BtnFashion.gameObject:SetActiveEx(isShowBtnFashion)
end

function XUiBiancaTheatreMainMassage:SwitchRoleState(entityId)
    self.OwnedInfoPanel:InitPanelActiveState()
    self:PlayAnimationWithMask("RoleQieHuan")

    local state = self.RoleSelectStateDic[entityId]
    self.RoleSelectStateDic[entityId] = not state

    for i, entity in ipairs(self.DynamicTable.DataSource) do
        if entityId == entity:GetId() then
            local grid = self.DynamicTable:GetGridByIndex(i)
            if grid then
                grid:PlaySwitchAnima()

                if self.RoleSelectStateDic[entity:GetId()] then
                    local characterId = entity:GetCharacterId()
                    entity = self.AdventureManager:GetRole(characterId)
                end
                grid:UpdateGrid(entity)
            end
        end
    end
    self:RefreshModel()
    self:RefreshDetailPanel()
end

function XUiBiancaTheatreMainMassage:PlayAnima(animaName, cb)
    self:PlayAnimationWithMask(animaName, function()
        if cb then
            cb()
        end
    end)
end

function XUiBiancaTheatreMainMassage:InitSortFunction()
    self.FiltSortListTypeDic = {} --记录筛选排序缓存列表(根据独域和泛用机体类型储存)
    self.SortFunction = {}

    local QualitySort = function(idA, idB, isAscendOrder)
        local qualityA = XDataCenter.CharacterManager.GetCharacterQuality(idA)
        local qualityB = XDataCenter.CharacterManager.GetCharacterQuality(idB)
        local isSort = false
        if qualityA ~= qualityB then
            isSort = true
            if isAscendOrder then
                return isSort, qualityA < qualityB
            end
            return isSort, qualityA > qualityB
        end
        return isSort
    end

    local AbilitySort = function(adventureRoleA, adventureRoleB, isAscendOrder)
        local abilityA = adventureRoleA:GetAbility()
        local abilityB = adventureRoleB:GetAbility()
        local isSort = false
        if abilityA ~= abilityB then
            isSort = true
            if isAscendOrder then
                return isSort, abilityA < abilityB
            end
            return isSort, abilityA > abilityB
        end
        return isSort
    end

    self.SortFunction[CharacterSortTagType.Default] = function(adventureRoleA, adventureRoleB, isAscendOrder)
        local isSort, sortResult
        local idA, idB = adventureRoleA:GetId(), adventureRoleB:GetId()
        
        isSort, sortResult = AbilitySort(adventureRoleA, adventureRoleB, isAscendOrder)
        if isSort then
            return sortResult
        end
        
        isSort, sortResult = QualitySort(idA, idB, isAscendOrder)
        if isSort then
            return sortResult
        end

        local priorityA = XCharacterConfigs.GetCharacterPriority(XEntityHelper.GetCharacterIdByEntityId(idA))
        local priorityB = XCharacterConfigs.GetCharacterPriority(XEntityHelper.GetCharacterIdByEntityId(idB))
        if priorityA ~= priorityB then
            if isAscendOrder then
                return priorityA < priorityB
            end
            return priorityA > priorityB
        end

        return idA > idB
    end
end

-- 排序
---@param adventureRoleList 传入XAdventureRole的列表
---@param sortTypeName 排序标签
---@param isAscendOrder 是否升序
function XUiBiancaTheatreMainMassage:DoSort(adventureRoleList, sortTypeName, isAscendOrder)
    if not sortTypeName then
        sortTypeName = CharacterSortTagType.Default
    end
    
    table.sort(adventureRoleList, function (dataA, dataB)
        return self.SortFunction[sortTypeName](dataA, dataB, isAscendOrder)
    end)
    
    return adventureRoleList
end

return XUiBiancaTheatreMainMassage