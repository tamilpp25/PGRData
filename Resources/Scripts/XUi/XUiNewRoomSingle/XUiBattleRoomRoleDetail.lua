local CsXTextManager = CS.XTextManager
local Vector2 = CS.UnityEngine.Vector2
local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiBattleRoomRoleDetail = XLuaUiManager.Register(XLuaUi, "UiBattleRoomRoleDetail")

function XUiBattleRoomRoleDetail:OnAwake()
    -- XTeam
    self.Team = nil
    self.StageId = nil
    self.Pos = nil
    self.CurrentEntityId = nil
    self.CurrentCharacterType = XCharacterConfigs.CharacterType.Normal
    self.ChildPanelData = nil
    self.RoleDynamicGrid = self.GridCharacter
    self.CurrentSelectTagGroup = {
        [XCharacterConfigs.CharacterType.Normal] = {},
        [XCharacterConfigs.CharacterType.Isomer] = {},
    }
    -- 角色列表
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiBattleRoomRoleGrid)
    self.DynamicTable:SetDelegate(self)
    self:RegisterUiEvents()
    self.BtnTabShougezhe:SetDisable(not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer))
    -- 模型初始化
    local panelRoleModel = self.UiModelGo.transform:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = self.UiModelGo.transform:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = self.UiModelGo.transform:FindTransform("ImgEffectHuanren1")
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    self.UiPanelRoleModel = XUiPanelRoleModel.New(panelRoleModel, self.Name, nil, true)
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem
    , XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

-- team : XTeam
function XUiBattleRoomRoleDetail:OnStart(stageId, team, pos, proxy)
    if proxy == nil then proxy = XUiBattleRoomRoleDetailDefaultProxy end
    self.StageId = stageId
    self.Team = team
    self.Pos = pos
    self.Proxy = proxy.New()
    local isStop = self.Proxy:AOPOnStartBefore(self)
    if isStop then return end
    self.CurrentEntityId = self.Team:GetEntityIdByTeamPos(self.Pos)
    local gridProxy = self.Proxy:GetGridProxy() or XUiBattleRoomRoleGrid
    self.RoleDynamicGrid = self.Proxy:GetRoleDynamicGrid(self) or self.GridCharacter
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetGrid(self.RoleDynamicGrid)
    self.DynamicTable:SetGridSize(Vector2(self.RoleDynamicGrid.transform.rect.width, self.RoleDynamicGrid.transform.rect.height))
    self.CurrentCharacterType = self.Team:GetCharacterType()
    -- 注册自动关闭
    local openAutoClose, autoCloseEndTime, callback = self.Proxy:GetAutoCloseInfo()
    if openAutoClose then
        self:SetAutoCloseInfo(autoCloseEndTime, callback)
    end
    self.Proxy:AOPOnStartAfter(self)
end

function XUiBattleRoomRoleDetail:OnEnable()
    XUiBattleRoomRoleDetail.Super.OnEnable(self)
    -- 设置子面板配置
    self.ChildPanelData = self.Proxy:GetChildPanelData()
    self:LoadChildPanelInfo()
    self.BtnGroupCharacterType:SelectIndex(self.CurrentCharacterType)
end

function XUiBattleRoomRoleDetail:OnDisable()
    XUiBattleRoomRoleDetail.Super.OnDisable(self)
end

function XUiBattleRoomRoleDetail:Filter(selectTagGroupDic, sortTagId, isThereFilterDataCb)
    if self.TagCacheDic == nil then self.TagCacheDic = {} end
    XDataCenter.RoomCharFilterTipsManager.Filter(self.TagCacheDic, selectTagGroupDic
    , self.Proxy:GetEntities(self.CurrentCharacterType)
    , self.Proxy:GetFilterJudge()
    , function(filteredData)
        self.CurrentSelectTagGroup[self.CurrentCharacterType].TagGroupDic = selectTagGroupDic
        self.CurrentSelectTagGroup[self.CurrentCharacterType].SortType = sortTagId
        self:FilterRefresh(filteredData, sortTagId)
    end
    , isThereFilterDataCb)
end

function XUiBattleRoomRoleDetail:FilterRefresh(filteredData, sortTagType)
    filteredData = self.Proxy:SortEntitiesWithTeam(self.Team, filteredData, sortTagType)
    -- self.CurrentEntityId = nil
    self:RefreshRoleList(filteredData)
end

--######################## 私有方法 ########################

function XUiBattleRoomRoleDetail:RegisterUiEvents()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    -- 角色类型按钮组
    self.BtnGroupCharacterType:Init({
        [XCharacterConfigs.CharacterType.Normal] = self.BtnTabGouzaoti,
        [XCharacterConfigs.CharacterType.Isomer] = self.BtnTabShougezhe
    }, function(tabIndex) self:OnBtnGroupCharacterTypeClicked(tabIndex) end)
    self.BtnJoinTeam.CallBack = function() self:OnBtnJoinTeamClicked() end
    self.BtnQuitTeam.CallBack = function() self:OnBtnQuitTeamClicked() end
    self.BtnPartner.CallBack = function() self:OnBtnPartnerClicked() end
    self.BtnFashion.CallBack = function() self:OnBtnFashionClicked() end
    self.BtnConsciousness.CallBack = function() self:OnBtnConsciousnessClicked() end
    self.BtnWeapon.CallBack = function() self:OnBtnWeaponClicked() end
    self.BtnFilter.CallBack = function() self:OnBtnFilterClicked() end
end

function XUiBattleRoomRoleDetail:OnBtnFilterClicked()
    XLuaUiManager.Open("UiRoomCharacterFilterTips", self,
    XRoomCharFilterTipsConfigs.EnumFilterType.SuperTower,
    XRoomCharFilterTipsConfigs.EnumSortType.SuperTower,
    self.CurrentCharacterType, nil, nil,
    self.Proxy:GetHideSortTagDic())
end

function XUiBattleRoomRoleDetail:OnBtnJoinTeamClicked()
    local isStop = self.Proxy:AOPOnBtnJoinTeamClickedBefore(self)
    if isStop then return end
    local finishedCallback = function()
        self.Team:UpdateEntityTeamPos(self.CurrentEntityId, self.Pos, true)
        self.Proxy:AOPOnBtnJoinTeamClickedAfter(self)
        self:Close()
    end
    if not self:CheckCanJoin(self.CurrentEntityId, finishedCallback) then
        return
    end
    finishedCallback()
end

function XUiBattleRoomRoleDetail:CheckCanJoin(entityId, finishedCallback)
    -- 检查队伍里是否拥有同样的角色（同时兼容机器人）
    if self.Proxy:CheckTeamHasSameCharacterId(self.Team, entityId) then
        XUiManager.TipError(XUiHelper.GetText("SameCharacterInTeamTip"))
        return false
    end
    -- 检查是否为角色类型不一致，不一致清空
    local currentCharacterType = self.Proxy:GetCharacterType(entityId)
    local teamCharacterType = self.Team:GetCharacterType()
    if currentCharacterType ~= teamCharacterType and not self.Team:GetIsEmpty() then
        XUiManager.DialogTip(nil
            , CsXTextManager.GetText("TeamCharacterTypeNotSame")
            , XUiManager.DialogType.Normal, nil, function()
            -- 清空
            self.Team:ClearEntityIds()
            if finishedCallback then 
                finishedCallback()
            end
        end)
        return false
    end
    return true
end

function XUiBattleRoomRoleDetail:OnBtnQuitTeamClicked()
    self.Team:UpdateEntityTeamPos(self.CurrentEntityId, self.Pos, false)
    self:Close()
end

function XUiBattleRoomRoleDetail:OnBtnPartnerClicked()
    XDataCenter.PartnerManager.GoPartnerCarry(self.CurrentEntityId, false)
end

function XUiBattleRoomRoleDetail:OnBtnFashionClicked()
    XLuaUiManager.Open("UiFashion", self.CurrentEntityId)
end

function XUiBattleRoomRoleDetail:OnBtnConsciousnessClicked()
    XLuaUiManager.Open("UiEquipAwarenessReplace", self.CurrentEntityId, nil, true)
end

function XUiBattleRoomRoleDetail:OnBtnWeaponClicked()
    XLuaUiManager.Open("UiEquipReplaceNew", self.CurrentEntityId, nil, true)
end

-- characterType : XCharacterConfigs.CharacterType
function XUiBattleRoomRoleDetail:OnBtnGroupCharacterTypeClicked(characterType)
    if characterType == XCharacterConfigs.CharacterType.Isomer
        and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Isomer) then
        return 
    end
    self.CurrentCharacterType = characterType
    local selectTagGroupDic = self.CurrentSelectTagGroup[characterType].TagGroupDic or {}
    local sortTagId = self.CurrentSelectTagGroup[characterType].SortType or XRoomCharFilterTipsConfigs.EnumSortTag.Default
    local roles = self.Proxy:GetEntities(self.CurrentCharacterType)
    if #roles <= 0 then
        XUiManager.TipError(XUiHelper.GetText("IsomerLimitTip"))
        self.BtnGroupCharacterType:SelectIndex(XCharacterConfigs.CharacterType.Normal)
        return
    end
    self:Filter(selectTagGroupDic, sortTagId, function(roles)
        if #roles <= 0 then
            XUiManager.TipError(XUiHelper.GetText("IsomerLimitTip"))
            self.BtnGroupCharacterType:SelectIndex(XCharacterConfigs.CharacterType.Normal)
            return false
        end
        return true
    end)
end

-- characterType : XCharacterConfigs.CharacterType
function XUiBattleRoomRoleDetail:RefreshRoleList(roleEntities)
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
    self.CurrentEntityId = roleEntities[index]:GetId()
    self:SetJoinBtnIsActive(not self.Team:GetEntityIdIsInTeam(self.CurrentEntityId))
    self.DynamicTable:SetDataSource(roleEntities)
    self.DynamicTable:ReloadDataSync(index)
    self:RefreshModel()
    self:RefreshOperationBtns()
end

function XUiBattleRoomRoleDetail:OnDynamicTableEvent(event, index, grid)
    if index <= 0 or index > #self.DynamicTable.DataSource then return end
    local entity = self.DynamicTable.DataSource[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(entity, self.Team, self.StageId)
        grid:SetSelectStatus(self.CurrentEntityId == entity:GetId())
        grid:SetInTeamStatus(self.Team:GetEntityIdIsInTeam(entity:GetId()))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurrentEntityId = entity:GetId()
        for _, tmpGrid in pairs(self.DynamicTable:GetGrids()) do
            tmpGrid:SetSelectStatus(false)
        end
        grid:SetSelectStatus(true)
        self:SetJoinBtnIsActive(not self.Team:GetEntityIdIsInTeam(self.CurrentEntityId))
        self:RefreshModel()
        self:RefreshOperationBtns()
        self:RefreshChildPanel()
    end
end

function XUiBattleRoomRoleDetail:SetJoinBtnIsActive(value)
    self.BtnJoinTeam.gameObject:SetActiveEx(value)
    self.BtnQuitTeam.gameObject:SetActiveEx(not value)
end

function XUiBattleRoomRoleDetail:RefreshModel(entityId)
    if entityId == nil then entityId = self.CurrentEntityId end
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    local finishedCallback = function(model)
        self.PanelDrag.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(self.CurrentCharacterType == XCharacterConfigs.CharacterType.Normal)
        self.ImgEffectHuanren1.gameObject:SetActiveEx(self.CurrentCharacterType == XCharacterConfigs.CharacterType.Isomer)
    end
    local characterViewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
    if XRobotManager.CheckIsRobotId(entityId) then
        local robotConfig = XRobotManager.GetRobotTemplate(entityId)
        self.UiPanelRoleModel:UpdateRobotModel(entityId, robotConfig.CharacterId
            , nil, robotConfig.FashionId, robotConfig.WeaponId, finishedCallback)
    else
        self.UiPanelRoleModel:UpdateCharacterModel(entityId, nil, nil, finishedCallback, nil, characterViewModel:GetFashionId())
    end
end

function XUiBattleRoomRoleDetail:RefreshOperationBtns()
    local isRobot = XRobotManager.CheckIsRobotId(self.CurrentEntityId)
    self.BtnPartner.gameObject:SetActiveEx(not isRobot)
    self.BtnFashion.gameObject:SetActiveEx(not isRobot)
    self.BtnConsciousness.gameObject:SetActiveEx(not isRobot)
    self.BtnWeapon.gameObject:SetActiveEx(not isRobot)
end

function XUiBattleRoomRoleDetail:LoadChildPanelInfo()
    if not self.ChildPanelData then return end
    local childPanelData = self.ChildPanelData
    -- 加载panel asset
    local instanceGo = childPanelData.instanceGo
    if XTool.UObjIsNil(instanceGo) then
        instanceGo = self.PanelChildContainer:LoadPrefab(childPanelData.assetPath)
        childPanelData.instanceGo = instanceGo
        -- 加载panel proxy
        childPanelData.instanceProxy = childPanelData.proxy.New(instanceGo)
    end
    -- 加载proxy参数
    local proxyArgs = {}
    if childPanelData.proxyArgs then
        for _, argName in ipairs(childPanelData.proxyArgs) do
            if type(argName) == "string" then
                proxyArgs[#proxyArgs + 1] = self[argName]
            else
                proxyArgs[#proxyArgs + 1] = argName
            end
        end
    end
    childPanelData.instanceProxy:SetData(table.unpack(proxyArgs))
end

function XUiBattleRoomRoleDetail:RefreshChildPanel()
    if not self.ChildPanelData then return end
    if not self.ChildPanelData.instanceProxy then return end
    if not self.ChildPanelData.instanceProxy.Refresh then return end
    self.ChildPanelData.instanceProxy:Refresh(self.CurrentEntityId)
end

return XUiBattleRoomRoleDetail