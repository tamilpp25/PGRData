local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
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
    self.CurrentCharacterType = XEnumConst.CHARACTER.CharacterType.Normal
    self.FiltSortListTypeDic = {} -- 缓存筛选列表
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
        [XEnumConst.CHARACTER.CharacterType.Normal] = {},
        [XEnumConst.CHARACTER.CharacterType.Isomer] = {}
    }
    -- 角色列表
    -- self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    -- self.DynamicTable:SetProxy(XUiBattleRoomRoleGrid)
    -- self.DynamicTable:SetDelegate(self)
    self:RegisterUiEvents()
    self.BtnTabShougezhe:SetDisable(not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer))
    -- 模型初始化
    self.PanelRoleModelGo = self.UiModelGo.transform:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = self.UiModelGo.transform:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = self.UiModelGo.transform:FindTransform("ImgEffectHuanren1")
    self.UiPanelRoleModel = XUiPanelRoleModel.New(self.PanelRoleModelGo, self.Name, nil, true)
    XUiPanelAsset.New(
    self,
    self.PanelAsset,
    XDataCenter.ItemManager.ItemId.FreeGem,
    XDataCenter.ItemManager.ItemId.ActionPoint,
    XDataCenter.ItemManager.ItemId.Coin
    )

    self.BtnFashion.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
    self.BtnPartner.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
    self.BtnConsciousness.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
    self.BtnWeapon.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
    self.BtnFilter.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
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

    -- 判断是否走特殊编队规则
    ---@type XTableStageLineupType
    self._CanStageRobotBlendUse, self._StageLineupConfig = XMVCA.XFuben:GetConfigStageLineupType(self.StageId)
    
    ---@type XUiBattleRoomRoleDetailDefaultProxy
    self.Proxy = proxyInstance
    if team then
        -- 避免其他系统队伍数据错乱，预先清除
        XEntityHelper.ClearErrorTeamEntityId(team, function(entityId)
            return self.Proxy:GetCharacterViewModelByEntityId(entityId) ~= nil
        end)
    end
    local isStop = self.Proxy:AOPOnStartBefore(self)
    if isStop then
        return
    end
    if self.Team then
        self:UpdateCurrentEntityId(self.Team:GetEntityIdByTeamPos(self.Pos))
    else
        self.CurrentEntityId = 0
    end
    -- local gridProxy = self.Proxy:GetGridProxy() or XUiBattleRoomRoleGrid
    self.RoleDynamicGrid = self.Proxy:GetRoleDynamicGrid(self) or self.GridCharacter
    self:InitFilter()

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
    -- self.BtnGroupCharacterType:SelectIndex(self.CurrentCharacterType)
    if XUiManager.IsHideFunc then
        self.BtnTeaching.gameObject:SetActiveEx(false)
    end
    -- -- 更新教学功能是否已开启
    -- self.BtnTeaching.gameObject:SetActiveEx(XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Practice))
    
    -- 刷新数据
    self.PanelFilter:RefreshList()
end

function XUiBattleRoomRoleDetail:OnDisable()
    XUiBattleRoomRoleDetail.Super.OnDisable(self)
end

function XUiBattleRoomRoleDetail:OnDestroy()
    XDataCenter.CommonCharacterFiltManager.ClearCacheData() --清除筛选缓存数据
end

function XUiBattleRoomRoleDetail:InitFilter()
    ---@type XCommonCharacterFilterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCommonCharacterFilter)
    local forceConfig = self.Proxy:GetFilterControllerConfig()
    self.PanelFilter = ag:InitFilter(self.PanelCharacterFilter, self, forceConfig)
    -- 是否屏蔽效应筛选
    self.PanelFilter:SetHideGeneralSkill(self:IsHideGeneralSkill())
    -- 选中角色回调
    local onSeleCb = function (entity)
        self:UpdateCurrentEntityId(entity:GetId())
        self:RefreshEntityInfo()
    end

    local onSeleTagCb = function (tagBtn)
        local isEmpty = self.PanelFilter:IsCurListEmpty()
        self.CharList.gameObject:SetActiveEx(not isEmpty)
        self.BtnTeaching.gameObject:SetActiveEx(not isEmpty)
    end

    -- 刷新格子回调
    ---@param grid XUiBattleRoomRoleGrid 或继承了XUiBattleRoomRoleGrid的Grid
    local refreshGridsFun = function (index, grid, data)
        if self.Team then
            local isInTeam = self.Team:GetEntityIdIsInTeam(data:GetId())
            local isSameRole = self.Proxy:CheckTeamHasSameCharacterId(self.Team, data:GetId())
            grid:SetData(data, self.Team, self.StageId, index, table.unpack(self.Proxy:GetGridExParams()))
            grid:UpdateFight()
            grid:SetInTeamStatus(isInTeam)
            if self._CanStageRobotBlendUse then
                grid:SetInSameStatus(isSameRole and not isInTeam and self._StageLineupConfig.Type[self.Pos] ~= XEnumConst.FuBen.StageLineupType.CharacterOnly)
            else
                grid:SetInSameStatus(isSameRole and not isInTeam)
            end
        else
            grid:SetData(data, self.Team, self.StageId, index, table.unpack(self.Proxy:GetGridExParams()))
        end
    end

    -- 自定义格子proxy
    local gridProxy = self.Proxy:GetGridProxy() or XUiBattleRoomRoleGrid
    local checkInTeam = function (id)
        if self.Proxy.CheckInTeam then
            return self.Proxy:CheckInTeam(self.Team, id)
        end
        if not self.Team then
            return false
        end
        return self.Team:GetEntityIdIsInTeam(id)
    end
    -- 覆写排序算法
    local sortOverrideFunTable = self.Proxy:GetFilterSortOverrideFunTable()
    self.PanelFilter:InitData(onSeleCb, onSeleTagCb, self.StageId, refreshGridsFun, gridProxy, checkInTeam, sortOverrideFunTable)
    self.PanelFilter:SetGetCharIdFun(
    function (entity)
            return self.Proxy:GetFilterCharIdFun(entity)
    end)
    self.DynamicTable = self.PanelFilter.DynamicTable
    self.PanelCharacterFilter.gameObject:SetActiveEx(true)
    self.Transform:FindTransform("CharInfo").gameObject:SetActiveEx(false)
    self.Transform:FindTransform("BtnFilter").gameObject:SetActiveEx(false)
    local list = self.Proxy:GetEntities()
    list = self:FilterEntitiesWithRobotBlendRule(list)
    local currentEntityId = self.Proxy.GetCurrentEntityId and self.Proxy:GetCurrentEntityId(self.CurrentEntityId) or self.CurrentEntityId
    self.PanelFilter:ImportList(list, currentEntityId) -- 自动选择点进来的角色
end

function XUiBattleRoomRoleDetail:RefreshEntityInfo()
    if not XTool.IsNumberValid(self.CurrentEntityId) then
        return
    end

    if self.Team then
        -- 当启用机器人队伍混编时，锁角色位不能下阵当前角色
        local curEntityInTeam = self.Team:GetEntityIdIsInTeam(self.CurrentEntityId)

        if self._CanStageRobotBlendUse then
            self:SetLockBtnIsActiveInBlendMode(curEntityInTeam)
        else
            self:SetJoinBtnIsActive(not curEntityInTeam)
        end
    else
        self.BtnJoinTeam.gameObject:SetActiveEx(false)
        self.BtnQuitTeam.gameObject:SetActiveEx(false)
    end
    self:RefreshRoleDetail()
    self:RefreshModel()
    self:RefreshOperationBtns()
    self:RefreshChildPanel()
end

--######################## 私有方法 ########################
function XUiBattleRoomRoleDetail:RegisterUiEvents()
    self.BtnBack.CallBack = function()
        if self.Proxy:AOPOnClickBtnBack(self) then return end
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
    -- 角色类型按钮组 屏蔽旧筛选器相关
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
    XUiHelper.RegisterClickEvent(self, self.BtnUniframeTip, self.OnBtnUniframeTipClick)
    XUiHelper.RegisterClickEvent(self, self.BtnType, self.OnBtnCareerTipsClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGeneralSkill1, function ()
        self:OnBtnGeneralSkillClick(1)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnGeneralSkill2, function ()
        self:OnBtnGeneralSkillClick(2)
    end)
end

function XUiBattleRoomRoleDetail:OnBtnGeneralSkillClick(index)
    local characterId = self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId):GetSourceEntityId()

    local activeGeneralSkillIds = XMVCA.XCharacter:GetCharactersActiveGeneralSkillIdList(characterId)
    local curId = activeGeneralSkillIds[index]
    local realIndex = XMVCA.XCharacter:GetIndexInCharacterGeneralSkillIdsById(characterId, curId)

    XLuaUiManager.Open("UiCharacterAttributeDetail", characterId, XEnumConst.UiCharacterAttributeDetail.BtnTab.GeneralSkill, realIndex)
end

function XUiBattleRoomRoleDetail:OnBtnTeachingClicked()
    XDataCenter.PracticeManager.OpenUiFubenPractice(
    self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId):GetSourceEntityId(), true)
end

function XUiBattleRoomRoleDetail:OnBtnUniframeTipClick()
    XLuaUiManager.Open("UiCharacterUniframeBubbleV2P6")
end

function XUiBattleRoomRoleDetail:OnBtnElementDetailClicked()
    XLuaUiManager.Open("UiCharacterAttributeDetail"
    , self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId):GetId(), XEnumConst.UiCharacterAttributeDetail.BtnTab.Element)
end

function XUiBattleRoomRoleDetail:OnBtnCareerTipsClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId):GetId())
end

function XUiBattleRoomRoleDetail:OnBtnFilterClicked()
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
    -- 机器人混编锁角色位的变更可以直接换
    if not self._CanStageRobotBlendUse or self._StageLineupConfig.Type[self.Pos] ~= XEnumConst.FuBen.StageLineupType.CharacterOnly then
        -- 检查队伍里是否拥有同样的角色（同时兼容机器人）
        if self.Proxy:CheckTeamHasSameCharacterId(self.Team, entityId) then
            XUiManager.TipError(XUiHelper.GetText("SameCharacterInTeamTip"))
            return false
        end
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
        local isOwn = XMVCA.XCharacter:IsOwnCharacter(characterId)
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
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwareness(self.CurrentEntityId)
end

function XUiBattleRoomRoleDetail:OnBtnWeaponClicked()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self.CurrentEntityId, nil, true)
end

function XUiBattleRoomRoleDetail:SetJoinBtnIsActive(value)
    if self.Proxy:AOPSetJoinBtnIsActiveBefore(self) then
        return
    end
    self.BtnJoinTeam.gameObject:SetActiveEx(value)
    self.BtnQuitTeam.gameObject:SetActiveEx(not value)
    self.Proxy:AOPSetJoinBtnIsActiveAfter(self)
end

--- 机器人混编模式下按钮显隐情况
function XUiBattleRoomRoleDetail:SetLockBtnIsActiveInBlendMode(inTeam)
    if self.Proxy:AOPSetJoinBtnIsActiveBefore(self) then
        return
    end
    
    local freeAndSame = false
    --检查是不是其他坑位非自由编辑的角色
    if self._StageLineupConfig.Type[self.Pos] == XEnumConst.FuBen.StageLineupType.Free then
        freeAndSame = self.Team:GetEntityIdByTeamPos(self.Pos) == self.CurrentEntityId
        -- 移除该位置配置角色以外的实体
        for i, v in pairs(self.Team:GetEntityIds()) do
            if i ~= self.Pos then
                local characterId = XRobotManager.GetCharacterId(v)
                local curCharacterId = XRobotManager.GetCharacterId(self.CurrentEntityId)
                if self._StageLineupConfig.Type[i] == XEnumConst.FuBen.StageLineupType.Free then
                    -- 如果该角色所在的是自由位，那么该角色是可以随意上下阵的
                    if characterId == curCharacterId then
                        freeAndSame = true
                    end
                end
                if characterId == curCharacterId then
                    inTeam = true
                    break
                end
            end
        end
    end
    
    self.BtnJoinTeam.gameObject:SetActiveEx(not inTeam)
    self.BtnQuitTeam.gameObject:SetActiveEx(freeAndSame)
    self.BtnLock.gameObject:SetActiveEx(inTeam and not freeAndSame)
    self.Proxy:AOPSetJoinBtnIsActiveAfter(self)
end

function XUiBattleRoomRoleDetail:RefreshModel(entityId)
    if entityId == nil then
        entityId = self.CurrentEntityId
    end
    if not XTool.IsNumberValid(entityId) then
        return
    end
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    local finishedCallback = function(model)
        local isSomer = self.Proxy:CheckEntityIdIsIsomer(entityId)
        if isSomer then
            self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
            self.ImgEffectHuanren:GetComponent("XPrefabLoader").Delay = 0  -- 因为开屏黑幕太久了 所以首次特效延后加载
        else
            self.ImgEffectHuanren.gameObject:SetActiveEx(true)
            self.ImgEffectHuanren1:GetComponent("XPrefabLoader").Delay = 0
        end
    end
    local characterViewModel = self.Proxy:GetCharacterViewModelByEntityId(entityId)
    local sourceEntityId = characterViewModel:GetSourceEntityId()

    if self.Proxy:AOPRefreshModelBefore(self,characterViewModel,sourceEntityId,finishedCallback) then
        return
    end
    
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

    local isSomer = self.Proxy:CheckEntityIdIsIsomer(self.CurrentEntityId)
    self.BtnUniframeTip.gameObject:SetActiveEx(isSomer)
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
    if self.Team then
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
    end
    -- 检查是否满足角色限制条件
    if self.StageId then
        if #viewModels > 0 and XEntityHelper.CheckIsNeedRoleLimit(self.StageId, viewModels) then
            self:RefreshRoleLimitTip()
            return
        end
    end
    -- 检查职业推荐
    if self.StageId then
        local needCareerTip, types, indexDic = XEntityHelper.CheckIsNeedCareerLimit(self.StageId, viewModels)
        if needCareerTip then
            self.PanelCharacterCareer.gameObject:SetActiveEx(true)
            XUiHelper.RefreshCustomizedList(self.PanelCharacterCareer, self.GridCareer, #types + 1, function(index, grid)
                if index <= 1 then return end
                index = index - 1
                local uiObject = grid.transform:GetComponent("UiObject")
                local isActive = indexDic[index] or false
                local professionIcon = XMVCA.XCharacter:GetNpcTypeIcon(types[index])
                uiObject:GetObject("RImgNormalIcon").gameObject:SetActiveEx(isActive)
                uiObject:GetObject("RImgDisableIcon").gameObject:SetActiveEx(not isActive)
                uiObject:GetObject("RImgNormalIcon"):SetRawImage(professionIcon)
                uiObject:GetObject("RImgDisableIcon"):SetRawImage(professionIcon)
            end)
            XUiHelper.MarkLayoutForRebuild(self.PanelCharacterCareer.transform)
            return
        end
    end
    -- 检查试用角色
    if self.StageId then
        if XFubenConfigs.GetStageAISuggestType(self.StageId) ~= XFubenConfigs.AISuggestType.Robot then
            return
        end
    end
    local compareAbility = false
    -- 拿到相同角色的战力字典
    local currentCharacterId = self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId):GetId()
    local currentAbility = self.Proxy:GetRoleAbility(self.CurrentEntityId)
    local viewModel
    local list = self.Proxy:GetEntities()
    list = self:FilterEntitiesWithRobotBlendRule(list)
    for _, entity in ipairs(list) do
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
    if not self.StageId then
        limitBuffId = 0
    end
    self.TxtCharacterLimit.text = XFubenConfigs.GetStageCharacterLimitTextSelectCharacter(limitType
    , self.Proxy:GetCharacterType(self.CurrentEntityId), limitBuffId)
end

function XUiBattleRoomRoleDetail:GetTeamDynamicCharacterTypes()
    local result = { }
    if self.Team then
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
        -- 检查教学功能按钮红点
        XRedPointManager.CheckOnceByButton(self.BtnTeaching, { XRedPointConditions.Types.CONDITION_CELICA_TEACH }
        , self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId):GetSourceEntityId())
    end
end

function XUiBattleRoomRoleDetail:RefreshRoleDetail()
    local isShow = self.Proxy:GetIsShowRoleDetail()
    self.PanelRoleDetail.gameObject:SetActiveEx(isShow)
    if not isShow then return end
    ---@type XCharacterViewModel
    local viewModel = self.Proxy:GetCharacterViewModelByEntityId(self.CurrentEntityId)
    self.PanelRoleDetail.gameObject:SetActiveEx(viewModel ~= nil)
    if viewModel == nil then return end
    local viewModelId = viewModel:GetSourceEntityId()
    local charId = XRobotManager.GetCharacterId(viewModelId)
    local careerId = XMVCA.XCharacter:GetCharacterCareer(charId)
    self.BtnType:SetRawImage(XMVCA.XCharacter:GetNpcTypeIcon(careerId))
    self.TxtName.text = viewModel:GetName()
    self.TxtTradeName.text = viewModel:GetTradeName()
    self.TxtAbility.text = self.Proxy:GetRoleAbility(self.CurrentEntityId)
    -- 初始品质
    local initQuality = XMVCA.XCharacter:GetCharacterInitialQuality(charId)
    local initColor = XMVCA.XCharacter:GetModelCharacterQualityIcon(initQuality).InitColor
    self.QualityRail.color = XUiHelper.Hexcolor2Color(initColor)

    -- 元素
    local isHide = self:IsHideGeneralSkill()
    local elementList = isHide and XMVCA.XCharacter:GetCharDetailObtainElementList(viewModelId) or XMVCA.XCharacter:GetCharacterAllElement(viewModelId, true)
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if elementList[i] then
            rImg.gameObject:SetActiveEx(true)
            local elementConfig = XMVCA.XCharacter:GetCharElement(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        else
            rImg.gameObject:SetActiveEx(false)
        end
    end

    -- 机制
    if isHide then
        self.ListGeneralSkillDetail.gameObject:SetActiveEx(false)
    else
        self.ListGeneralSkillDetail.gameObject:SetActiveEx(true)
        local generalSkillIds = XMVCA.XCharacter:GetCharactersActiveGeneralSkillIdList(viewModelId)
        for i = 1, self.ListGeneralSkillDetail.childCount, 1 do
            local id = generalSkillIds[i]
            self["BtnGeneralSkill" .. i].gameObject:SetActiveEx(id)
            if id then
                local generalSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[id]
                self["BtnGeneralSkill" .. i]:SetRawImage(generalSkillConfig.Icon)
            end
        end
    end
end

function XUiBattleRoomRoleDetail:IsHideGeneralSkill()
    if self.Proxy.IsHideGeneralSkill then
        return self.Proxy:IsHideGeneralSkill()
    end
    return false
end

function XUiBattleRoomRoleDetail:Close(updated)
    local isStop = self.Proxy:AOPCloseBefore(self)
    if isStop then return end
    if updated then
        self:EmitSignal("UpdateEntityId", self.CurrentEntityId)
    end
    self.Super.Close(self)
end

--- 根据关卡机器人混用功能剔除角色
function XUiBattleRoomRoleDetail:FilterEntitiesWithRobotBlendRule(list)
    local isUseBlendRule, config = XMVCA.XFuben:GetConfigStageLineupType(self.StageId)

    if isUseBlendRule then
        local type = config.Type[self.Pos]
        if type ~= XEnumConst.FuBen.StageLineupType.Free then
            -- 移除该位置配置角色以外的实体
            local stageCfg = XMVCA.XFuben:GetStageCfg(self.StageId)
            local robotId = stageCfg.RobotId[self.Pos]

            if XTool.IsNumberValid(robotId) then
                -- 获取对应角色Id
                local characterId = XRobotManager.GetCharacterId(robotId)
                if XTool.IsNumberValid(characterId) then
                    local newlist = {}
                    --判断有没相同的机器人，一般关卡配置的机器人不会出现在代理获取的列表里，但可能存在例外
                    local hasSameRobot = false
                    for i, v in pairs(list) do
                        local entityId = v.Id
                        if XRobotManager.CheckIsRobotId(entityId) then
                            if entityId == robotId then
                                hasSameRobot = true
                            end
                            entityId = XRobotManager.GetCharacterId(entityId)
                        end

                        if entityId == characterId then
                            table.insert(newlist, v)
                        end
                    end

                    if not hasSameRobot then
                        table.insert(newlist, XRobotManager.GetRobotById(robotId))
                    end

                    return newlist
                end
            end
        else
            -- 自由坑位的关卡机器人也加上
            local stageCfg = XMVCA.XFuben:GetStageCfg(self.StageId)
            if not XTool.IsTableEmpty(stageCfg.RobotId) then
                for i, v in pairs(stageCfg.RobotId) do
                    table.insert(list, XRobotManager.GetRobotById(v))
                end
            end
        end
    end
    
    return list
end

return XUiBattleRoomRoleDetail