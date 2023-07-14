local CsXTextManager = CS.XTextManager
local Vector2 = CS.UnityEngine.Vector2
local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiBattleRoomRoleDetail = XLuaUiManager.Register(XLuaUi, "UiBattleRoomRoleDetail")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
--[[
    基本描述：通用编队界面，支持所有类型角色编队（XCharacter, XRobot, 其他自定义实体）
    参数说明：stageId : Stage表的Id
             team : XTeam 队伍数据，可通过XTeamManager相关接口获取对应的队伍或自己系统创建的队伍
             pos : 当前编辑的角色在队伍中的位置
             proxy : 代理定义，必须传入继承自XUiBattleRoomRoleDetailDefaultProxy的类定义或传入匿名类(如下)
                -- 偷懒的一种写法，来源于1.只想实现一个接口而不想创建整个文件 2.修正旧编队界面带来的耦合逻辑写法
                匿名类：{
                    -- proxy : 等同于self, 属于代理实例, 是匿名类重写的接口的第一个参数
                    GetRoleAbility = function(proxy, entityId)
                        -- eg : 根据id处理自己的角色战力
                    end
                }
    使用规则：1.可参考XUiBattleRoomRoleDetailDefaultProxy文件去重写自己玩法需要的接口，接口已基本写明注释，或查询该文件看相关实现
             2.当前页面增加功能时，如果不是通用编队的功能或不是所有玩法大概率能够使用的功能尽量不要直接加，可通过AOP接口切上下去加自己的功能
             3.可任意追加AOP接口，比如AOPOnStartBefore，AOPOnStartAfter，只切上下面去处理自己的逻辑
]]
function XUiBattleRoomRoleDetail:OnAwake()
    -- XTeam
    self.Team = nil
    self.StageId = nil
    self.Pos = nil
    self.CurrentEntityId = nil
    self.CurrentCharacterType = XCharacterConfigs.CharacterType.Normal
    --[[        
        {
            assetPath : 子面板资源路径，
            proxy : 子面板代理，
            proxyArgs : 子面板需要使用的参数
        }
    ]]
    self.ChildPanelData = nil
    self.RoleDynamicGrid = self.GridCharacter
    self.CurrentSelectTagGroup = {
        [XCharacterConfigs.CharacterType.Normal] = {},
        [XCharacterConfigs.CharacterType.Isomer] = {}
    }
    -- 角色列表
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiBattleRoomRoleGrid)
    self.DynamicTable:SetDelegate(self)
    self:RegisterUiEvents()
    self.BtnTabShougezhe:SetDisable(not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer))
    -- 模型初始化
    self.PanelRoleModelGo = self.UiModelGo.transform:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = self.UiModelGo.transform:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = self.UiModelGo.transform:FindTransform("ImgEffectHuanren1")
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    self.UiPanelRoleModel = XUiPanelRoleModel.New(self.PanelRoleModelGo, self.Name, nil, true)
    XUiPanelAsset.New(
    self,
    self.PanelAsset,
    XDataCenter.ItemManager.ItemId.FreeGem,
    XDataCenter.ItemManager.ItemId.ActionPoint,
    XDataCenter.ItemManager.ItemId.Coin
    )
end

-- team : XTeam 如果是旧系统改过来，可以参考下XTeamManager后面新加的接口去处理旧队伍数据
function XUiBattleRoomRoleDetail:OnStart(stageId, team, pos, proxy)
    self.StageId = stageId
    self.Team = team
    self.Pos = pos
    local proxyInstance = nil -- 代理实例
    if proxy == nil then -- 使用默认的
        proxyInstance = XUiBattleRoomRoleDetailDefaultProxy.New(stageId, team, pos)
    elseif not CheckIsClass(proxy) then -- 使用匿名类
        proxyInstance = CreateAnonClassInstance(proxy, XUiBattleRoomRoleDetailDefaultProxy, stageId, team, pos)
    else -- 使用自定义类
        proxyInstance = proxy.New(stageId, team, pos)
    end
    self.Proxy = proxyInstance
    -- 避免其他系统队伍数据错乱，预先清除
    XEntityHelper.ClearErrorTeamEntityId(team, function(entityId)
        return self.Proxy:GetCharacterViewModelByEntityId(entityId) ~= nil
    end)
    local isStop = self.Proxy:AOPOnStartBefore(self)
    if isStop then
        return
    end
    self:UpdateCurrentEntityId(self.Team:GetEntityIdByTeamPos(self.Pos))
    local gridProxy = self.Proxy:GetGridProxy() or XUiBattleRoomRoleGrid
    self.RoleDynamicGrid = self.Proxy:GetRoleDynamicGrid(self) or self.GridCharacter
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetGrid(self.RoleDynamicGrid)
    self.DynamicTable:SetGridSize(
    Vector2(self.RoleDynamicGrid.transform.rect.width, self.RoleDynamicGrid.transform.rect.height)
    )
    self.CurrentCharacterType = self.CurrentEntityId > 0
    and self.Proxy:GetCharacterType(self.CurrentEntityId)
    or self.Proxy:GetDefaultCharacterType() --self.Team:GetCharacterType()
    -- 刷新限制切换按钮状态
    local limitType = self:GetCharacterLimitType()
    if limitType == XFubenConfigs.CharacterLimitType.Normal then
        self.BtnTabShougezhe:SetButtonState(CS.UiButtonState.Disable)
    elseif limitType == XFubenConfigs.CharacterLimitType.Isomer then
        self.BtnTabGouzaoti:SetButtonState(CS.UiButtonState.Disable)
    end
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
    -- -- 更新教学功能是否已开启
    -- self.BtnTeaching.gameObject:SetActiveEx(XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Practice))
end

function XUiBattleRoomRoleDetail:OnDisable()
    XUiBattleRoomRoleDetail.Super.OnDisable(self)
end

function XUiBattleRoomRoleDetail:Filter(selectTagGroupDic, sortTagId, isThereFilterDataCb)
    if self.TagCacheDic == nil then
        self.TagCacheDic = {}
    end
    XDataCenter.RoomCharFilterTipsManager.Filter(
    self.TagCacheDic,
    selectTagGroupDic,
    self.Proxy:GetEntities(self.CurrentCharacterType),
    self.Proxy:GetFilterJudge(),
    function(filteredData)
        self.CurrentSelectTagGroup[self.CurrentCharacterType].TagGroupDic = selectTagGroupDic
        self.CurrentSelectTagGroup[self.CurrentCharacterType].SortType = sortTagId
        self:FilterRefresh(filteredData, sortTagId)
    end,
    isThereFilterDataCb
    )
end

function XUiBattleRoomRoleDetail:FilterRefresh(filteredData, sortTagType)
    filteredData = self.Proxy:SortEntitiesWithTeam(self.Team, filteredData, sortTagType)
    self:RefreshRoleList(filteredData)
end

--######################## 私有方法 ########################
function XUiBattleRoomRoleDetail:RegisterUiEvents()
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
    -- 角色类型按钮组
    self.BtnGroupCharacterType:Init(
    {
        [XCharacterConfigs.CharacterType.Normal] = self.BtnTabGouzaoti,
        [XCharacterConfigs.CharacterType.Isomer] = self.BtnTabShougezhe
    },
    function(tabIndex)
        self:OnBtnGroupCharacterTypeClicked(tabIndex)
    end
    )
    self.BtnJoinTeam.CallBack = function()
        self:OnBtnJoinTeamClicked()
    end
    self.BtnQuitTeam.CallBack = function()
        self:OnBtnQuitTeamClicked()
    end
    self.BtnPartner.CallBack = function()
        self:OnBtnPartnerClicked()
    end
    self.BtnFashion.CallBack = function()
        self:OnBtnFashionClicked()
    end
    self.BtnConsciousness.CallBack = function()
        self:OnBtnConsciousnessClicked()
    end
    self.BtnWeapon.CallBack = function()
        self:OnBtnWeaponClicked()
    end
    self.BtnFilter.CallBack = function()
        self:OnBtnFilterClicked()
    end
    self.BtnTeaching.CallBack = function()
        self:OnBtnTeachingClicked()
    end
    XUiHelper.RegisterClickEvent(self, self.BtnElementDetail, self.OnBtnElementDetailClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnCareerTips, self.OnBtnCareerTipsClicked)
end

function XUiBattleRoomRoleDetail:OnBtnElementDetailClicked()
    XLuaUiManager.Open("UiCharacterElementDetail"
    , self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId):GetId())
end

function XUiBattleRoomRoleDetail:OnBtnCareerTipsClicked()
    XLuaUiManager.Open("UiCharacterCarerrTips"
    , self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId):GetId())
end

function XUiBattleRoomRoleDetail:OnBtnTeachingClicked()
    XDataCenter.PracticeManager.OpenUiFubenPractice(
    self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId):GetSourceEntityId(), true)
end

function XUiBattleRoomRoleDetail:OnBtnFilterClicked()
    local enumFilterType, sortType = self.Proxy:GetFilterTypeAndSortType()
    XLuaUiManager.Open(
    "UiRoomCharacterFilterTips",
    self,
    enumFilterType,
    sortType,
    self.CurrentCharacterType,
    nil,
    nil,
    self.Proxy:GetHideSortTagDic(),
    false
    )
end

function XUiBattleRoomRoleDetail:OnBtnJoinTeamClicked()
    local isStop = self.Proxy:AOPOnBtnJoinTeamClickedBefore(self)
    if isStop then
        return
    end
    local finishedCallback = function()
        self.Team:UpdateEntityTeamPos(self.CurrentEntityId, self.Pos, true)
        self.Proxy:AOPOnBtnJoinTeamClickedAfter(self)
        self:Close(true)
    end
    if not self:CheckCanJoin(self.CurrentEntityId, finishedCallback) then
        return
    end
    if self.Proxy:CheckIsNeedPractice() then
        XDataCenter.PracticeManager.OnJoinTeam(self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId):GetSourceEntityId()
        , handler(self, self.OnBtnTeachingClicked)
        , finishedCallback)
    else
        finishedCallback()
    end
end

function XUiBattleRoomRoleDetail:CheckCanJoin(entityId, finishedCallback)
    -- 检查队伍里是否拥有同样的角色（同时兼容机器人）
    if self.Proxy:CheckTeamHasSameCharacterId(self.Team, entityId) then
        XUiManager.TipError(XUiHelper.GetText("SameCharacterInTeamTip"))
        return false
    end
    local limitType = XFubenConfigs.GetStageCharacterLimitType(self.StageId)
    if limitType == XFubenConfigs.CharacterLimitType.Isomer or
    limitType == XFubenConfigs.CharacterLimitType.Normal then
        -- 检查是否为角色类型不一致，不一致清空
        local currentCharacterType = self.Proxy:GetCharacterType(entityId)
        local teamCharacterType = self.Team:GetCharacterType()
        if currentCharacterType ~= teamCharacterType and not self.Team:GetIsEmpty() then
            XUiManager.DialogTip(
            nil,
            CsXTextManager.GetText("TeamCharacterTypeNotSame"),
            XUiManager.DialogType.Normal,
            nil,
            function()
                -- 清空
                self.Team:ClearEntityIds()
                if finishedCallback then
                    finishedCallback()
                end
            end
            )
            return false
        end
    end
   -- 检查玩法自定义限定条件
   if self.Proxy:CheckCustomLimit(entityId) then
        return false
    end
    return true
end

function XUiBattleRoomRoleDetail:OnBtnQuitTeamClicked()
    self.Team:UpdateEntityTeamPos(self.CurrentEntityId, self.Pos, false)
    self:Close(true)
end

function XUiBattleRoomRoleDetail:OnBtnPartnerClicked()
    XDataCenter.PartnerManager.GoPartnerCarry(self.CurrentEntityId, false)
end

function XUiBattleRoomRoleDetail:OnBtnFashionClicked()
    local isRobot = self.Proxy:CheckIsRobot(self.CurrentEntityId)
    if isRobot then
        local sourceEntityId = self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId):GetSourceEntityId()
        local characterId = XRobotManager.GetCharacterId(sourceEntityId)
        local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(characterId)
        if not isOwn then
            XUiManager.TipText("CharacterLock")
            return
        else
            XLuaUiManager.Open("UiFashion", characterId, nil, nil, XUiConfigs.OpenUiType.RobotFashion)
        end
    else
        XLuaUiManager.Open("UiFashion", self.CurrentEntityId)
    end
end

function XUiBattleRoomRoleDetail:OnBtnConsciousnessClicked()
    XLuaUiManager.Open("UiEquipAwarenessReplace", self.CurrentEntityId, nil, true)
end

function XUiBattleRoomRoleDetail:OnBtnWeaponClicked()
    XLuaUiManager.Open("UiEquipReplaceNew", self.CurrentEntityId, nil, true)
end

-- characterType : XCharacterConfigs.CharacterType
function XUiBattleRoomRoleDetail:OnBtnGroupCharacterTypeClicked(characterType)
    -- 检查角色限制
    local limitType = self:GetCharacterLimitType()
    if limitType == XFubenConfigs.CharacterLimitType.Normal
    and characterType == XCharacterConfigs.CharacterType.Isomer then
        XUiManager.TipText("TeamSelectCharacterTypeLimitTipNormal")
        self.BtnGroupCharacterType:SelectIndex(XCharacterConfigs.CharacterType.Normal)
        return
    elseif limitType == XFubenConfigs.CharacterLimitType.Isomer
    and characterType == XCharacterConfigs.CharacterType.Normal then
        XUiManager.TipText("TeamSelectCharacterTypeLimitTipIsomer")
        self.BtnGroupCharacterType:SelectIndex(XCharacterConfigs.CharacterType.Isomer)
        return
    end
    -- 检查功能是否开启
    if characterType == XCharacterConfigs.CharacterType.Isomer and
    not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Isomer)
    then
        return
    end
    self.CurrentCharacterType = characterType
    local selectTagGroupDic = self.CurrentSelectTagGroup[characterType].TagGroupDic or {}
    local sortTagId =    self.CurrentSelectTagGroup[characterType].SortType or XRoomCharFilterTipsConfigs.EnumSortTag.Default
    local roles = self.Proxy:GetEntities(self.CurrentCharacterType)
    if characterType == XCharacterConfigs.CharacterType.Normal and #roles <= 0 then
        return
    end
    if #roles <= 0 then
        XUiManager.TipError(XUiHelper.GetText("IsomerLimitTip"))
        self.BtnGroupCharacterType:SelectIndex(XCharacterConfigs.CharacterType.Normal)
        return
    end
    self:Filter(
    selectTagGroupDic,
    sortTagId,
    function(roles)
        if #roles <= 0 then
            XUiManager.TipError(XUiHelper.GetText("IsomerLimitTip"))
            self.BtnGroupCharacterType:SelectIndex(XCharacterConfigs.CharacterType.Normal)
            return false
        end
        return true
    end
    )
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
    self:UpdateCurrentEntityId(roleEntities[index]:GetId())
    self:SetJoinBtnIsActive(not self.Team:GetEntityIdIsInTeam(self.CurrentEntityId))
    self.DynamicTable:SetDataSource(roleEntities)
    self.DynamicTable:ReloadDataSync(index)
    self:RefreshModel()
    self:RefreshOperationBtns()
    self:RefreshChildPanel()
end

function XUiBattleRoomRoleDetail:OnDynamicTableEvent(event, index, grid)
    if index <= 0 or index > #self.DynamicTable.DataSource then
        return
    end
    local entity = self.DynamicTable.DataSource[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetAbility(self.Proxy:GetRoleAbility(entity:GetId()))
        grid:SetData(entity, self.Team, self.StageId)
        local isInTeam = self.Team:GetEntityIdIsInTeam(entity:GetId())
        local isSameRole = self.Proxy:CheckTeamHasSameCharacterId(self.Team, entity:GetId())
        grid:SetSelectStatus(self.CurrentEntityId == entity:GetId())
        grid:SetInTeamStatus(isInTeam)
        grid:SetInSameStatus(isSameRole and not isInTeam)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:UpdateCurrentEntityId(entity:GetId())
        for _, tmpGrid in pairs(self.DynamicTable:GetGrids()) do
            tmpGrid:SetSelectStatus(false)
        end
        grid:SetSelectStatus(true)
        self:SetJoinBtnIsActive(not self.Team:GetEntityIdIsInTeam(self.CurrentEntityId))
        self:RefreshModel()
        self:RefreshOperationBtns()
        self:RefreshChildPanel()
    end
    self.Proxy:AOPOnDynamicTableEventAfter(self, event, index, grid)
end

function XUiBattleRoomRoleDetail:SetJoinBtnIsActive(value)
    self.BtnJoinTeam.gameObject:SetActiveEx(value)
    self.BtnQuitTeam.gameObject:SetActiveEx(not value)
    self.Proxy:AOPSetJoinBtnIsActiveAfter(self)
end

function XUiBattleRoomRoleDetail:RefreshModel(entityId)
    if entityId == nil then
        entityId = self.CurrentEntityId
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
    local characterViewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
    local sourceEntityId = characterViewModel:GetSourceEntityId()
    if XRobotManager.CheckIsRobotId(sourceEntityId) then
        local robot2CharEntityId = XRobotManager.GetCharacterId(sourceEntityId)
        local isOwen = XDataCenter.CharacterManager.IsOwnCharacter(robot2CharEntityId)
        if XRobotManager.CheckUseFashion(sourceEntityId) and isOwen then
            local character = XDataCenter.CharacterManager.GetCharacter(robot2CharEntityId)
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

function XUiBattleRoomRoleDetail:RefreshOperationBtns()
    if self.Proxy:AOPRefreshOperationBtnsBefore(self) then
        return
    end
    local isRobot = self.Proxy:CheckIsRobot(self.CurrentEntityId)
    local sourceEntityId = self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId):GetSourceEntityId()
    local useFashion = true
    if isRobot then
        useFashion = XRobotManager.CheckUseFashion(sourceEntityId)
    end
    self.BtnPartner:SetDisable(isRobot, not isRobot)
    self.BtnFashion:SetDisable(not useFashion, useFashion)
    self.BtnConsciousness:SetDisable(isRobot, not isRobot)
    self.BtnWeapon:SetDisable(isRobot, not isRobot)
end

function XUiBattleRoomRoleDetail:LoadChildPanelInfo()
    if not self.ChildPanelData then
        return
    end
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
    if childPanelData.instanceProxy.SetData then
        childPanelData.instanceProxy:SetData(table.unpack(proxyArgs))
    end
end

function XUiBattleRoomRoleDetail:RefreshChildPanel()
    if not self.ChildPanelData then
        return
    end
    if not self.ChildPanelData.instanceProxy then
        return
    end
    if not self.ChildPanelData.instanceProxy.Refresh then
        return
    end
    self.ChildPanelData.instanceProxy:Refresh(self.CurrentEntityId)
end

-- 刷新提示
function XUiBattleRoomRoleDetail:RefreshTipGrids()
    -- 将所有的限制，职业，试用提示隐藏
    self.PanelCharacterLimit.gameObject:SetActiveEx(false)
    self.PanelCharacterCareer.gameObject:SetActiveEx(false)
    local viewModels = { }
    for pos, entityId in ipairs(self.Team:GetEntityIds()) do
        if entityId > 0 and pos ~= self.Pos and self.CurrentEntityId ~= entityId then -- 排除当前的打开位置+选中的在队伍里的
            table.insert(viewModels, self.Proxy:GetCharacterViewModelByEntityId(entityId))
        end
    end
    local currentInTeam = self.Team:GetEntityIdIsInTeam(self.CurrentEntityId)
    if not currentInTeam then -- 如果不在里面，直接加入检查
        table.insert(viewModels, self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId))
    else
        local currentPosEntityId = self.Team:GetEntityIdByTeamPos(self.Pos)
        if currentPosEntityId > 0 
            and self.Team:GetEntityIdIsInTeam(currentPosEntityId) 
            and currentPosEntityId ~= self.CurrentEntityId then  -- 在里面并选中的位置也在里面，加入原本位置的
            table.insert(viewModels, self.Proxy:GetCharacterViewModelByEntityId(currentPosEntityId))
        end
    end
    -- 检查是否满足角色限制条件
    if #viewModels > 0 and XEntityHelper.CheckIsNeedRoleLimit(self.StageId, viewModels) then
        self:RefreshRoleLimitTip()
        return
    end
    -- 检查职业推荐
    local needCareerTip, types, indexDic = XEntityHelper.CheckIsNeedCareerLimit(self.StageId, viewModels)
    if needCareerTip then
        self.PanelCharacterCareer.gameObject:SetActiveEx(true)
        XUiHelper.RefreshCustomizedList(self.PanelCharacterCareer, self.GridCareer, #types + 1, function(index, grid)
            if index <= 1 then return end
            index = index - 1
            local uiObject = grid.transform:GetComponent("UiObject")
            local isActive = indexDic[index] or false
            local professionIcon = XCharacterConfigs.GetNpcTypeIcon(types[index])
            uiObject:GetObject("RImgNormalIcon").gameObject:SetActiveEx(isActive)
            uiObject:GetObject("RImgDisableIcon").gameObject:SetActiveEx(not isActive)
            uiObject:GetObject("RImgNormalIcon"):SetRawImage(professionIcon)
            uiObject:GetObject("RImgDisableIcon"):SetRawImage(professionIcon)
        end)
        XUiHelper.MarkLayoutForRebuild(self.PanelCharacterCareer.transform)
        return
    end
    -- 检查试用角色
    if XFubenConfigs.GetStageAISuggestType(self.StageId) ~= XFubenConfigs.AISuggestType.Robot then
        return
    end
    local compareAbility = false
    -- 拿到相同角色的战力字典
    local currentCharacterId = self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId):GetId()
    local currentAbility = self.Proxy:GetRoleAbility(self.CurrentEntityId)
    local viewModel
    for _, entity in ipairs(self.Proxy:GetEntities()) do
        viewModel = self.Proxy:GetCharacterViewModelByEntityId(entity:GetId())
        if XEntityHelper.GetIsRobot(viewModel:GetSourceEntityId()) -- 机器人
            and viewModel:GetId() == currentCharacterId  -- 相同角色id
            and self.Proxy:GetRoleAbility(entity:GetId()) > currentAbility then -- 机器人战力更高
            compareAbility = true   -- 开启使用角色提示
            break
        end
    end
    if compareAbility then
        self.PanelCharacterLimit.gameObject:SetActiveEx(true)
        self.ImgCharacterLimit.gameObject:SetActiveEx(false)
        self.TxtCharacterLimit.text = XUiHelper.GetText("TeamRobotTips")
    end
end

function XUiBattleRoomRoleDetail:RefreshRoleLimitTip()
    -- XFubenConfigs.CharacterLimitType
    local limitType = self:GetCharacterLimitType()
    local isShow = XFubenConfigs.IsStageCharacterLimitConfigExist(limitType)
    self.PanelCharacterLimit.gameObject:SetActiveEx(isShow)
    if not isShow then return end
    -- 图标
    self.ImgCharacterLimit:SetSprite(XFubenConfigs.GetStageCharacterLimitImageTeamEdit(limitType))
    -- 文案
    if limitType == XFubenConfigs.CharacterLimitType.IsomerDebuff or 
        limitType == XFubenConfigs.CharacterLimitType.NormalDebuff then
        self.TxtCharacterLimit.text = XFubenConfigs.GetStageMixCharacterLimitTips(limitType
        , self:GetTeamDynamicCharacterTypes(), true)
        return
    end
    local limitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(self.StageId)
    self.TxtCharacterLimit.text = XFubenConfigs.GetStageCharacterLimitTextSelectCharacter(limitType
    , self.Proxy:GetCharacterType(self.CurrentEntityId), limitBuffId)
end

function XUiBattleRoomRoleDetail:GetTeamDynamicCharacterTypes()
    local result = { }
    for pos, entityId in ipairs(self.Team:GetEntityIds()) do
        if entityId > 0 and pos ~= self.Pos and self.CurrentEntityId ~= entityId then
            table.insert(result, self.Proxy:GetCharacterViewModelByEntityId(entityId):GetCharacterType())
        end
    end
    local currentInTeam = self.Team:GetEntityIdIsInTeam(self.CurrentEntityId)
    if not currentInTeam then -- 如果不在里面，直接加入检查
        table.insert(result, self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId):GetCharacterType())
    else
        local currentPosEntityId = self.Team:GetEntityIdByTeamPos(self.Pos)
        if currentPosEntityId > 0 
            and self.Team:GetEntityIdIsInTeam(currentPosEntityId) 
            and currentPosEntityId ~= self.CurrentEntityId then  -- 在里面并选中的位置也在里面，加入原本位置的
            table.insert(result, self.Proxy:GetCharacterViewModelByEntityId(currentPosEntityId):GetCharacterType())
        end
    end
    return result
end

function XUiBattleRoomRoleDetail:GetCharacterLimitType()
    return XFubenConfigs.GetStageCharacterLimitType(self.StageId)
end

function XUiBattleRoomRoleDetail:UpdateCurrentEntityId(value)
    self.CurrentEntityId = value
    if self.CurrentEntityId > 0 then
        self:RefreshTipGrids()
        self:RefreshRoleDetail()
        -- 检查教学功能按钮红点
        XRedPointManager.CheckOnceByButton(self.BtnTeaching, { XRedPointConditions.Types.CONDITION_CELICA_TEACH }
        , self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId):GetSourceEntityId())
    end
end

function XUiBattleRoomRoleDetail:RefreshRoleDetail()
    local isShow = self.Proxy:GetIsShowRoleDetail()
    self.PanelRoleDetail.gameObject:SetActiveEx(isShow)
    if not isShow then return end
    local viewModel = self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId)
    self.PanelRoleDetail.gameObject:SetActiveEx(viewModel ~= nil)
    if viewModel == nil then return end
    self.RImgTypeIcon:SetRawImage(viewModel:GetProfessionIcon())
    self.TxtName.text = viewModel:GetName()
    self.TxtTradeName.text = viewModel:GetTradeName()
    self.TxtAbility.text = self.Proxy:GetRoleAbility(self.CurrentEntityId)
    local elementIcons = viewModel:GetObtainElementIcons()
    XUiHelper.RefreshCustomizedList(self.BtnElementDetail.transform, self.RImgCharElement, #elementIcons, function(index, grid)
        grid:GetComponent("RawImage"):SetRawImage(elementIcons[index])
    end)
end

function XUiBattleRoomRoleDetail:Close(updated)
    local isStop = self.Proxy:AOPCloseBefore(self)
    if isStop then return end
    if updated then
        self:EmitSignal("UpdateEntityId", self.CurrentEntityId)
    end
    self.Super.Close(self)
end

return XUiBattleRoomRoleDetail