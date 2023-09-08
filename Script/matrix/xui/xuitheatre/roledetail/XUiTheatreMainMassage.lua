local CsXTextManager = CS.XTextManager
local Vector2 = CS.UnityEngine.Vector2
local XUiTheatreMassageGrid = require("XUi/XUiTheatre/RoleDetail/XUiTheatreMassageGrid")
local XUiTheatreOwnedInfoPanel = require("XUi/XUiTheatre/RoleDetail/XUiTheatreOwnedInfoPanel")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

--肉鸽成员列表界面
---@class XUiTheatreMainMassage:XLuaUi
local XUiTheatreMainMassage = XLuaUiManager.Register(XLuaUi, "UiTheatreMainMassage")

function XUiTheatreMainMassage:OnAwake()
    self:AddBtnListener()
end

function XUiTheatreMainMassage:OnStart()
    self:Init()
end

function XUiTheatreMainMassage:OnEnable()
    if XTool.IsNumberValid(self._CurSelectIndex) then
        self._PanelFilter:DoSelectIndex(self._CurSelectIndex)
    end
end

function XUiTheatreMainMassage:OnDestroy()
    self:RemovePanelAsset()
end

function XUiTheatreMainMassage:Init()
    ---@type XTheatreAdventureManager
    self.AdventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    
    self:InitPanelAsset()
    self:InitFilter()
    self:InitRoleDetail()
    
    self:InitModel()
end

--region Data - Getter
---@return XCharacterViewModel
function XUiTheatreMainMassage:GetCharacterViewModelByEntityId(entityId)
    local role = self.AdventureManager:GetRole(entityId)
    if role == nil then return nil end
    return role:GetCharacterViewModel()
end

---@return number
function XUiTheatreMainMassage:GetCurrentCharacterId()
    local entityId = self._CurrentEntityId
    local adventureRole = self.AdventureManager:GetRole(entityId)
    return adventureRole:GetCharacterId()
end
--endregion

--region Ui - PanelAsset
function XUiTheatreMainMassage:InitPanelAsset()
    self._PanelAsset = XUiHelper.NewPanelActivityAssetSafe(XDataCenter.TheatreManager.GetAdventureAssetItemIds(), self.PanelSpecialTool, self)
end

function XUiTheatreMainMassage:RemovePanelAsset()
    XDataCenter.ItemManager.RemoveCountUpdateListener(self._PanelAsset)
end
--endregion

--region Ui - Filter
function XUiTheatreMainMassage:InitFilter()
    if not self.PanelZuo then
        return
    end
    local checkInTeam = function(id)
        return true
    end
    
    ---招募角色当前显示的是试玩角色或自己的角色，false显示试玩角色，true显示对应自己的角色
    self._RoleSelectStateDic = {}
    
    ---@type XCommonCharacterFiltAgency
    self.FiltAgecy = XMVCA:GetAgency(ModuleId.XCommonCharacterFilt)
    self._PanelFilter = self.FiltAgecy:InitFilter(self.PanelZuo, self)

    local clickTag = function()
        self:_RefreshEmptyPanel()
    end
    self._PanelFilter:InitData(handler(self, self._OnSelectTab), clickTag, nil, nil, XUiTheatreMassageGrid, checkInTeam)
    self._PanelFilter:ImportList(self:_GetCharacterList())
    self._PanelFilter:RefreshList()
end

function XUiTheatreMainMassage:_GetCharacterList()
    local roles = self.AdventureManager:GetCurrentRoles(true)
    local result = {}
    for _, role in ipairs(roles) do
        local entityId = role:GetCharacterId()
        if self._RoleSelectStateDic[entityId] == nil then
            self._RoleSelectStateDic[entityId] = false
        end
        if role:GetIsLocalRole() and self._RoleSelectStateDic[entityId] then
            table.insert(result, role)
        elseif not role:GetIsLocalRole() and not self._RoleSelectStateDic[entityId] then
            table.insert(result, role)
        end
    end
    return result
end

---@param character XTheatreAdventureRole
function XUiTheatreMainMassage:_OnSelectTab(character, index, grid)
    self._CurrentEntityId = character:GetId()
    self._CurSelectIndex = index
    self:RefreshModel()
    self:_RefreshRoleDetail()
end

function XUiTheatreMainMassage:_RefreshEmptyPanel()
    self.UiOwnedInfo.gameObject:SetActiveEx(not self._PanelFilter:IsCurListEmpty())
    self.BtnFashion.gameObject:SetActiveEx(not self._PanelFilter:IsCurListEmpty())
    self.BtnOwnedDetail.gameObject:SetActiveEx(not self._PanelFilter:IsCurListEmpty())
    self.BtnTeaching.gameObject:SetActiveEx(not self._PanelFilter:IsCurListEmpty())
end
--endregion

--region Ui - RoleDetail
function XUiTheatreMainMassage:InitRoleDetail()
    ---@type XUiTheatreOwnedInfoPanel
    self._OwnedInfoPanel = XUiTheatreOwnedInfoPanel.New(self.UiOwnedInfo, handler(self, self.SwitchRoleState), self)
end

function XUiTheatreMainMassage:SwitchRoleState(entityId)
    self._OwnedInfoPanel:InitPanelActiveState()
    self:PlayAnimationWithMask("RoleQieHuan")

    local characterId = self:GetCurrentCharacterId(entityId)
    local state = self._RoleSelectStateDic[characterId]
    self._RoleSelectStateDic[characterId] = not state
    
    self._PanelFilter:ImportList(self:_GetCharacterList())
    self._PanelFilter:RefreshList()
    self._PanelFilter:DoSelectIndex(self._CurSelectIndex)
    self:RefreshModel()
    self:_RefreshRoleDetail()
end

function XUiTheatreMainMassage:_RefreshRoleDetail()
    local entityId = self._CurrentEntityId
    local adventureRole = self.AdventureManager:GetRole(entityId)
    local isOwnRole = self._RoleSelectStateDic[entityId]
    local characterId = adventureRole:GetCharacterId()
    if isOwnRole then
        adventureRole = self.AdventureManager:GetRole(characterId)
    end
    self._OwnedInfoPanel:SetData(adventureRole, entityId)
    self.BtnFashion.gameObject:SetActiveEx(self._RoleSelectStateDic[characterId] or false)
end
--endregion

--region Scene - Model
function XUiTheatreMainMassage:InitModel()
    local panelRoleModel = self.UiModelGo.transform:FindTransform("PanelRoleModel")
    ---@type UnityEngine.Transform
    self.ImgEffectHuanren = self.UiModelGo.transform:FindTransform("ImgEffectHuanren")
    ---@type UnityEngine.Transform
    self.ImgEffectHuanren1 = self.UiModelGo.transform:FindTransform("ImgEffectHuanren1")
    
    ---@type XUiPanelRoleModel
    self._UiPanelRoleModel = XUiPanelRoleModel.New(panelRoleModel, self.Name, nil, true)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
end

function XUiTheatreMainMassage:RefreshModel()
    local entityId = self._CurrentEntityId
    local adventureRole = self.AdventureManager:GetRole(entityId)
    local characterViewModel = self._RoleSelectStateDic[entityId] and self:GetCharacterViewModelByEntityId(adventureRole:GetCharacterId()) or self:GetCharacterViewModelByEntityId(entityId)
    if not characterViewModel then
        return
    end

    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    local finishedCallback = function(model)
        self.PanelDrag.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(characterViewModel:GetCharacterType() == XCharacterConfigs.CharacterType.Normal)
        self.ImgEffectHuanren1.gameObject:SetActiveEx(characterViewModel:GetCharacterType() == XCharacterConfigs.CharacterType.Isomer)
    end

    local sourceEntityId = characterViewModel:GetSourceEntityId()
    if XRobotManager.CheckIsRobotId(sourceEntityId) then
        local robot2CharId = XRobotManager.GetCharacterId(sourceEntityId)
        local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(robot2CharId)
        if XRobotManager.CheckUseFashion(sourceEntityId) and isOwn then
            local character = XDataCenter.CharacterManager.GetCharacter(robot2CharId)
            local robot2CharViewModel = character:GetCharacterViewModel()
            self._UiPanelRoleModel:UpdateCharacterModel(robot2CharId, nil, nil, finishedCallback, nil, robot2CharViewModel:GetFashionId())
        else
            local robotConfig = XRobotManager.GetRobotTemplate(sourceEntityId)
            self._UiPanelRoleModel:UpdateRobotModel(sourceEntityId, robotConfig.CharacterId, nil, robotConfig.FashionId, robotConfig.WeaponId, finishedCallback)
        end
    else
        self._UiPanelRoleModel:UpdateCharacterModel(sourceEntityId,nil,nil, finishedCallback,nil, characterViewModel:GetFashionId())
    end
end
--endregion

--region Ui - BtnListener
function XUiTheatreMainMassage:AddBtnListener()
    self:BindHelpBtn(self.BtnHelp, "Theatre")
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    
    self:RegisterClickEvent(self.BtnFashion, self.OnBtnFashionClick)
    self:RegisterClickEvent(self.BtnOwnedDetail, self.OnBtnOwnedDetailClick)
    self:RegisterClickEvent(self.BtnTeaching, self.OnBtnTeachingClick)
end

function XUiTheatreMainMassage:OnBtnOwnedDetailClick()
    XLuaUiManager.Open("UiCharacterDetail", self:GetCurrentCharacterId())
end

function XUiTheatreMainMassage:OnBtnTeachingClick()
    XDataCenter.PracticeManager.OpenUiFubenPractice(self:GetCurrentCharacterId())
end

function XUiTheatreMainMassage:OnBtnFashionClick()
    XLuaUiManager.Open("UiFashion", self:GetCurrentCharacterId())
end
--endregion

--region Old
--function XUiTheatreMainMassage:OnAwake()
--    self.TheatreManager = XDataCenter.TheatreManager
--    ---@type XTheatreAdventureManager
--    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()
--    self.RoleSelectStateDic = {} --招募角色当前显示的是试玩角色或自己的角色，false显示试玩角色，true显示对应自己的角色
--
--    self.CurrentEntityId = nil
--    self.CurrentSelectTagGroup = {
--        [XCharacterConfigs.CharacterType.Normal] = {},
--        [XCharacterConfigs.CharacterType.Isomer] = {}
--    }
--
--    self.CurrentCharacterType = self:GetDefaultCharacterType()
--
--    -- 角色列表
--    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
--    self.DynamicTable:SetProxy(XUiTheatreMassageGrid)
--    self.DynamicTable:SetDelegate(self)
--    self.GridCharacterNew.gameObject:SetActiveEx(false)
--    self:RegisterUiEvents()
--
--    -- 模型初始化
--    local panelRoleModel = self.UiModelGo.transform:FindTransform("PanelRoleModel")
--    self.ImgEffectHuanren = self.UiModelGo.transform:FindTransform("ImgEffectHuanren")
--    self.ImgEffectHuanren1 = self.UiModelGo.transform:FindTransform("ImgEffectHuanren1")
--    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
--    self.UiPanelRoleModel = XUiPanelRoleModel.New(panelRoleModel, self.Name, nil, true)
--    XUiHelper.NewPanelActivityAsset(XDataCenter.TheatreManager.GetAdventureAssetItemIds(), self.PanelSpecialTool)
--
--    self.OwnedInfoPanel = XUiTheatreOwnedInfoPanel.New(self.UiOwnedInfo, handler(self, self.SwitchRoleState), self)
--
--    self.IsAscendOrder = false   --初始降序
--    self:CheckBtnFilterActive()
--    self:InitBtnTabShougezhe()
--end
--
--function XUiTheatreMainMassage:OnEnable()
--    self.PanelCharacterTypeBtns:SelectIndex(self.CurrentCharacterType)
--end
--
--function XUiTheatreMainMassage:InitBtnTabShougezhe()
--    local lockShougezhe = not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer)
--    local roles = self.AdventureManager:GetCurrentRoles()
--    local isHaveIsomer = false
--    for _, role in ipairs(roles) do
--        if role:GetCharacterViewModel():GetCharacterType() == XCharacterConfigs.CharacterType.Isomer then
--            isHaveIsomer = true
--            break
--        end
--    end
--    self.BtnTabShougezhe:SetDisable(lockShougezhe and not isHaveIsomer)
--end
--
--function XUiTheatreMainMassage:GetDefaultCharacterType()
--    local roles
--    for characterType in ipairs(self.CurrentSelectTagGroup) do
--        roles = self:GetAdventureRoles(characterType)
--        if not XTool.IsTableEmpty(roles) then
--            return characterType
--        end
--    end
--end
--
--function XUiTheatreMainMassage:Filter(selectTagGroupDic, sortTagId, isThereFilterDataCb)
--    if self.TagCacheDic == nil then
--        self.TagCacheDic = {}
--    end
--    XDataCenter.RoomCharFilterTipsManager.Filter(
--    self.TagCacheDic,
--    selectTagGroupDic,
--    self:GetAdventureRoles(self.CurrentCharacterType),
--    handler(self, self.GetFilterJudge),
--    function(filteredData)
--        self.CurrentSelectTagGroup[self.CurrentCharacterType].TagGroupDic = selectTagGroupDic
--        self.CurrentSelectTagGroup[self.CurrentCharacterType].SortType = sortTagId
--        self:FilterRefresh(filteredData, sortTagId)
--    end,
--    isThereFilterDataCb
--    )
--end
--
--function XUiTheatreMainMassage:GetFilterJudge(groupId, tagValue, entity)
--    if not entity.GetCharacterViewModel then return false end
--    local characterViewModel = entity:GetCharacterViewModel()
--    -- 职业筛选
--    if groupId == XRoomCharFilterTipsConfigs.EnumFilterTagGroup.Career then
--        if tagValue == characterViewModel:GetCareer() then
--            return true
--        end
--        -- 能量元素筛选
--    elseif groupId == XRoomCharFilterTipsConfigs.EnumFilterTagGroup.Element then
--        local obtainElementList = characterViewModel:GetObtainElements()
--        for _, element in pairs(obtainElementList) do
--            if element == tagValue then
--                return true
--            end
--        end
--    else
--        XLog.Error(string.format("XUiTheatreMainMassage:GetFilterJudge函数错误，没有处理排序组：%s的逻辑", groupId))
--        return false
--    end
--end
--
--function XUiTheatreMainMassage:FilterRefresh(filteredData, sortTagType)
--    if self.IsAscendOrder then
--        filteredData = XTool.ReverseList(filteredData)
--    end
--    self:RefreshRoleList(filteredData)
--end
--
--function XUiTheatreMainMassage:CheckBtnFilterActive()
--    self.BtnShengxu.gameObject:SetActiveEx(self.IsAscendOrder)
--    self.BtnJiangxu.gameObject:SetActiveEx(not self.IsAscendOrder)
--end
--
--function XUiTheatreMainMassage:GetAdventureRoles(characterType)
--    local roles = self.AdventureManager:GetCurrentRoles()
--    local result = {}
--    for _, role in ipairs(roles) do
--        if role:GetCharacterViewModel():GetCharacterType() == characterType then
--            local entityId = role:GetId()
--            table.insert(result, role)
--
--            if self.RoleSelectStateDic[entityId] == nil then
--                self.RoleSelectStateDic[entityId] = false
--            end
--        end
--    end
--    return result
--end
--
---- characterType : XCharacterConfigs.CharacterType
--function XUiTheatreMainMassage:OnPanelCharacterTypeBtnsClicked(characterType)
--    self.CurrentCharacterType = characterType
--    local selectTagGroupDic = self.CurrentSelectTagGroup[characterType].TagGroupDic or {}
--    local sortTagId =    self.CurrentSelectTagGroup[characterType].SortType or XRoomCharFilterTipsConfigs.EnumSortTag.Default
--    local roles = self:GetAdventureRoles(self.CurrentCharacterType)
--    if XTool.IsTableEmpty(roles) then
--        XUiManager.TipError(XUiHelper.GetText("IsomerLimitTip"))
--        local defaultType = self:GetDefaultCharacterType()
--        roles = self:GetAdventureRoles(defaultType)
--        if not XTool.IsTableEmpty(roles) then
--            self.PanelCharacterTypeBtns:SelectIndex(defaultType)
--        end
--        return
--    end
--
--    self:Filter(
--    selectTagGroupDic,
--    sortTagId,
--    function(roles)
--        return true
--    end
--    )
--end
--
--function XUiTheatreMainMassage:RefreshRoleList(roleEntities)
--    local searchEntityId = self.CurrentEntityId
--    local index = 1
--    if searchEntityId ~= nil or searchEntityId ~= 0 then
--        for i, v in ipairs(roleEntities) do
--            if v:GetId() == searchEntityId then
--                index = i
--                break
--            end
--        end
--    end
--    self.CurrentEntityId = roleEntities[index]:GetId()
--    self.DynamicTable:SetDataSource(roleEntities)
--    self.DynamicTable:ReloadDataSync(index)
--    self:RefreshModel()
--    self:RefreshDetailPanel()
--end
--
--function XUiTheatreMainMassage:OnDynamicTableEvent(event, index, grid)
--    if index <= 0 or index > #self.DynamicTable.DataSource then
--        return
--    end
--    local entity = self.DynamicTable.DataSource[index]
--    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
--        grid:SetSelect(self.CurrentEntityId == entity:GetId())
--        if self.RoleSelectStateDic[entity:GetId()] then
--            local characterId = entity:GetCharacterId()
--            entity = self.AdventureManager:GetRole(characterId)
--        end
--        grid:UpdateGrid(entity)
--    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
--        self.CurrentEntityId = entity:GetId()
--        for _, tmpGrid in pairs(self.DynamicTable:GetGrids()) do
--            tmpGrid:SetSelect(false)
--        end
--        grid:SetSelect(true)
--        self:RefreshModel()
--        self:RefreshDetailPanel()
--    end
--end
--
--function XUiTheatreMainMassage:RefreshModel()
--    local entityId = self.CurrentEntityId
--    local adventureRole = self.AdventureManager:GetRole(entityId)
--    local characterViewModel = self.RoleSelectStateDic[entityId] and self:GetCharacterViewModelByEntityId(adventureRole:GetCharacterId()) or self:GetCharacterViewModelByEntityId(entityId)
--    if not characterViewModel then
--        return
--    end
--
--    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
--    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
--    local finishedCallback = function(model)
--        self.PanelDrag.Target = model.transform
--        self.ImgEffectHuanren.gameObject:SetActiveEx(
--        self.CurrentCharacterType == XCharacterConfigs.CharacterType.Normal
--        )
--        self.ImgEffectHuanren1.gameObject:SetActiveEx(
--        self.CurrentCharacterType == XCharacterConfigs.CharacterType.Isomer
--        )
--    end
--
--    local sourceEntityId = characterViewModel:GetSourceEntityId()
--    if XRobotManager.CheckIsRobotId(sourceEntityId) then
--        local robot2CharId = XRobotManager.GetCharacterId(sourceEntityId)
--        local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(robot2CharId)
--        if XRobotManager.CheckUseFashion(sourceEntityId) and isOwn then
--            local character = XDataCenter.CharacterManager.GetCharacter(robot2CharId)
--            local robot2CharViewModel = character:GetCharacterViewModel()
--            self.UiPanelRoleModel:UpdateCharacterModel(robot2CharId, nil, nil, finishedCallback, nil, robot2CharViewModel:GetFashionId())
--        else
--            local robotConfig = XRobotManager.GetRobotTemplate(sourceEntityId)
--            self.UiPanelRoleModel:UpdateRobotModel(sourceEntityId, robotConfig.CharacterId, nil, robotConfig.FashionId, robotConfig.WeaponId, finishedCallback)
--        end
--    else
--        self.UiPanelRoleModel:UpdateCharacterModel(
--        sourceEntityId,
--        nil,
--        nil,
--        finishedCallback,
--        nil,
--        characterViewModel:GetFashionId()
--        )
--    end
--end
--
--function XUiTheatreMainMassage:GetCharacterViewModelByEntityId(entityId)
--    local role = self.AdventureManager:GetRole(entityId)
--    if role == nil then return nil end
--    return role:GetCharacterViewModel()
--end
--
--function XUiTheatreMainMassage:RefreshDetailPanel()
--    local entityId = self.CurrentEntityId
--    local adventureRole = self.AdventureManager:GetRole(entityId)
--    local isOwnRole = self.RoleSelectStateDic[entityId]
--    if isOwnRole then
--        local characterId = adventureRole:GetCharacterId()
--        adventureRole = self.AdventureManager:GetRole(characterId)
--    end
--    self.OwnedInfoPanel:SetData(adventureRole, entityId)
--    self.BtnFashion.gameObject:SetActiveEx(isOwnRole or false)
--end
--
--function XUiTheatreMainMassage:SwitchRoleState(entityId)
--    self.OwnedInfoPanel:InitPanelActiveState()
--    self:PlayAnimationWithMask("RoleQieHuan")
--
--    local state = self.RoleSelectStateDic[entityId]
--    self.RoleSelectStateDic[entityId] = not state
--
--    for i, entity in ipairs(self.DynamicTable.DataSource) do
--        if entityId == entity:GetId() then
--            local grid = self.DynamicTable:GetGridByIndex(i)
--            if grid then
--                grid:PlaySwitchAnima()
--
--                if self.RoleSelectStateDic[entity:GetId()] then
--                    local characterId = entity:GetCharacterId()
--                    entity = self.AdventureManager:GetRole(characterId)
--                end
--                grid:UpdateGrid(entity)
--            end
--        end
--    end
--    self:RefreshModel()
--    self:RefreshDetailPanel()
--end
--
--function XUiTheatreMainMassage:PlayAnima(animaName, cb)
--    self:PlayAnimationWithMask(animaName, function()
--        if cb then
--            cb()
--        end
--    end)
--end
--
--function XUiTheatreMainMassage:RegisterUiEvents()
--    self:RegisterClickEvent(self.BtnBack, self.Close)
--    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
--    self:RegisterClickEvent(self.BtnFashion, self.OnBtnFashionClick)
--    self:RegisterClickEvent(self.BtnOwnedDetail, self.OnBtnOwnedDetailClick)
--    self:RegisterClickEvent(self.BtnTeaching, self.OnBtnTeachingClick)
--    self:BindHelpBtn(self.BtnHelp, "Theatre")
--
--    self:RegisterClickEvent(self.BtnFilter, self.OnBtnFilterClicked)
--    self:RegisterClickEvent(self.BtnShengxu, self.OnBtnOrderClick)
--    self:RegisterClickEvent(self.BtnJiangxu, self.OnBtnOrderClick)
--    -- 角色类型按钮组
--    self.PanelCharacterTypeBtns:Init(
--            {
--                [XCharacterConfigs.CharacterType.Normal] = self.BtnTabGouzaoti,
--                [XCharacterConfigs.CharacterType.Isomer] = self.BtnTabShougezhe
--            },
--            function(tabIndex)
--                self:OnPanelCharacterTypeBtnsClicked(tabIndex)
--            end
--    )
--end
--
--function XUiTheatreMainMassage:GetCurrentCharacterId()
--    local entityId = self.CurrentEntityId
--    local adventureRole = self.AdventureManager:GetRole(entityId)
--    return adventureRole:GetCharacterId()
--end
--
--function XUiTheatreMainMassage:OnBtnOwnedDetailClick()
--    XLuaUiManager.Open("UiCharacterDetail", self:GetCurrentCharacterId())
--end
--
--function XUiTheatreMainMassage:OnBtnTeachingClick()
--    XDataCenter.PracticeManager.OpenUiFubenPractice(self:GetCurrentCharacterId())
--end
--
--function XUiTheatreMainMassage:OnBtnFashionClick()
--    XLuaUiManager.Open("UiFashion", self:GetCurrentCharacterId())
--end
--
--function XUiTheatreMainMassage:OnBtnFilterClicked()
--    XLuaUiManager.Open(
--            "UiRoomCharacterFilterTips",
--            self,
--            XRoomCharFilterTipsConfigs.EnumFilterType.Common,
--            XRoomCharFilterTipsConfigs.EnumSortType.Common,
--            self.CurrentCharacterType
--    )
--end
--
--function XUiTheatreMainMassage:OnBtnOrderClick()
--    self.IsAscendOrder = not self.IsAscendOrder
--    self:CheckBtnFilterActive()
--    self:OnPanelCharacterTypeBtnsClicked(self.CurrentCharacterType)
--end
--endregion

return XUiTheatreMainMassage