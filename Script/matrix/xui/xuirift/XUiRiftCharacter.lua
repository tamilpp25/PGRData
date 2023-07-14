--大秘境主界面
local XUiRiftCharacter = XLuaUiManager.Register(XLuaUi, "UiRiftCharacter")
local XUiGridRiftCharacter = require("XUi/XUiRift/Grid/XUiGridRiftCharacter")
local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local TipCount = 0
local TabBtnIndex = {
    Normal = 1, --构造体
    Isomer = 2, --授格者
}

function XUiRiftCharacter:OnAwake()
    self:InitButton()
    self:InitModel()
    self:InitDynamicTable()
    self:InitTimes()
    self.CurrSelectRole = nil
    self.SelectTabBtnIndex = 1
    self.CurrRoleListIndex = 1
    self.CurrGrid = nil
    self.GridPluginDic = {}
    self.GridRiftCore.gameObject:SetActiveEx(false)
    
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.RiftGold, XDataCenter.ItemManager.ItemId.RiftCoin)
    self.AssetPanel:HideBtnBuy()
end

function XUiRiftCharacter:OnStart(isMultiTeam, xTeam, teamPos, hideTeamPefabBtn)
    self.IsMultiTeam = isMultiTeam --是否是多队伍进入的
    self.XTeam = xTeam or XDataCenter.RiftManager.GetSingleTeamData()
    self.TeamPos = teamPos
    self.HideTeamPefabBtn = hideTeamPefabBtn

    if xTeam and teamPos then
        local roleId = xTeam:GetEntityIdByTeamPos(teamPos)
        local xRole = XDataCenter.RiftManager.GetEntityRoleById(roleId)
        if xRole then
            local charaType = xRole:GetCharacterType()
            self.InitCharacterType = charaType
            self.LastSelectNormalCharacter = charaType == TabBtnIndex.Normal and xRole or self.LastSelectNormalCharacter 
            self.LastSelectIsomerCharacter = charaType == TabBtnIndex.Isomer and xRole or self.LastSelectIsomerCharacter 
        end
    end
end

function XUiRiftCharacter:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnFashion, self.OnBtnFashionClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPartner, self.OnBtnPartnerClick)
    XUiHelper.RegisterClickEvent(self, self.BtnConsciousness, self.OnBtnConsciousnessClick)
    XUiHelper.RegisterClickEvent(self, self.BtnWeapon, self.OnBtnWeaponClick)
    XUiHelper.RegisterClickEvent(self, self.BtnJoinTeam, self.OnBtnJoinTeamClick)
    XUiHelper.RegisterClickEvent(self, self.BtnQuitTeam, self.OnBtnQuitTeamClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTeamPrefab, self.OnBtnTeamPrefabClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFilter, self.OnBtnFilterClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAdd, self.OnBtnAddClick)
    XUiHelper.RegisterClickEvent(self, self.BtnOwnedDetail, function() XLuaUiManager.Open("UiCharacterDetail", self.CurrSelectRole:GetCharacterId()) end)
    XUiHelper.RegisterClickEvent(self, self.BtnTeaching, function() XDataCenter.PracticeManager.OpenUiFubenPractice(self.CurrSelectRole:GetCharacterId()) end)

    local tabBtns = { self.BtnTabGouzaoti, self.BtnTabShougezhe }
    self.PanelCharacterTypeBtns:Init(tabBtns, function(index) self:OnSelectCharacterType(index) end)

    XEventManager.AddEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.RefreshTeamData, self)
end

function XUiRiftCharacter:OnSelectCharacterType(index)
    if index == TabBtnIndex.Isomer and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Isomer) then
        return
    end

    self.SelectTabBtnIndex = index
    if index == TabBtnIndex.Normal then
        self.ImgEffectHuanren.gameObject:SetActiveEx(false)
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        self:UpdateCharacters(self.LastSelectNormalCharacter)
    elseif index == TabBtnIndex.Isomer then
        self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
        self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
        self:UpdateCharacters(self.LastSelectIsomerCharacter)
    end
end

function XUiRiftCharacter:InitModel()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiRiftCharacter:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiGridRiftCharacter, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiRiftCharacter:OnEnable()
    self.Super.OnEnable(self)
    -- 进入默认选择泛用机体
    self.PanelCharacterTypeBtns:SelectIndex(self.InitCharacterType or TabBtnIndex.Normal)
    self:UpdateRightCharacterInfo()
    self:UpdateRoleModel()
end

function XUiRiftCharacter:RoleSortFun(list)
    local inTeamList = {}
    local unInTeamList = {}
    local inOtherTeamList = {}
    for k, xRole in pairs(list) do
        local isIn, xTeam
        if self.XTeam then
            if self.IsMultiTeam then
                isIn, xTeam = XDataCenter.RiftManager.CheckRoleInTeam(xRole:GetId())
            else
                xTeam = self.XTeam
                isIn = xTeam:GetEntityIdIsInTeam(xRole:GetId())
            end
        end
        if isIn and xTeam:GetId() == self.XTeam:GetId()  then
            table.insert(inTeamList, xRole)
        elseif isIn and xTeam:GetId() ~= self.XTeam:GetId() then
            table.insert(inOtherTeamList, xRole)
        else
            table.insert(unInTeamList, xRole)
        end 
    end
    table.sort(inTeamList, function (a, b)
        return a:GetFinalShowAbility() > b:GetFinalShowAbility()
    end)
    table.sort(inOtherTeamList, function (a, b)
        return a:GetFinalShowAbility() > b:GetFinalShowAbility()
    end)
    table.sort(unInTeamList, function (a, b)
        return a:GetFinalShowAbility() > b:GetFinalShowAbility()
    end)
    inTeamList = appendArray(inTeamList, unInTeamList)
    inTeamList = appendArray(inTeamList, inOtherTeamList)

    return inTeamList
end

-- 刷新左边角色列表
function XUiRiftCharacter:UpdateCharacters(xRole)
    local characterType = self.SelectTabBtnIndex
    local filterList = XDataCenter.CommonCharacterFiltManager.GetSelectListData(characterType)
    local roleList = filterList or XDataCenter.RiftManager.GetEntityRoleListByCharaType(characterType)
    roleList = self:RoleSortFun(roleList)
    local index = 1
    if xRole then
        local isIn, curIndex = table.contains(roleList, xRole)
        index = isIn and curIndex or index
    end
    
    self.CurrRoleListIndex = index
    self:UpdateDynamicTable(roleList, index)
end

function XUiRiftCharacter:UpdateDynamicTable(list, index)
    self.CurrShowList = list
    self.DynamicTable:SetDataSource(list)
    self.DynamicTable:ReloadDataASync(index or 1)
end

-- 角色被选中
function XUiRiftCharacter:OnRoleSelected(xRole)
    if xRole == self.CurrSelectRole then
        return
    end
    if xRole:GetCharacterType() == TabBtnIndex.Normal then
        self.LastSelectNormalCharacter = xRole
    else 
        self.LastSelectIsomerCharacter = xRole
    end

    self.CurrSelectRole = xRole
    self:UpdateRightCharacterInfo()
    self:UpdateRoleModel()
end

-- 刷新右边角色信息
function XUiRiftCharacter:UpdateRightCharacterInfo()
    if not self.CurrSelectRole then
        return
    end
    
    local characterId = self.CurrSelectRole:GetCharacterId()
    local charConfig = XCharacterConfigs.GetCharacterTemplate(characterId)
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName

    self.RImgTypeIcon:SetRawImage(self.CurrSelectRole:GetCareerIcon())

    -- 负载信息
    self.TxtLoadNum.text = CS.XTextManager.GetText("RiftPluginLoad", self.CurrSelectRole:GetCurrentLoad(), XDataCenter.RiftManager.GetMaxLoad())
    self.ImgLoadProgress.fillAmount = self.CurrSelectRole:GetCurrentLoad() / XDataCenter.RiftManager.GetMaxLoad()

    -- 倾向
    self.TxtAttribute.text = self.CurrSelectRole:GetAttrTypeName()

    -- 插件信息
    -- 刷新插件前先隐藏
    for k, grid in pairs(self.GridPluginDic) do
        grid.GameObject:SetActiveEx(false)
    end
    for k, xPlugin in pairs(self.CurrSelectRole:GetPlugIns()) do
        local grid = self.GridPluginDic[k]
        if not grid then
            local uiGo = CS.UnityEngine.Object.Instantiate(self.GridRiftCore, self.GridRiftCore.parent)
            grid = XUiRiftPluginGrid.New(uiGo)
            grid:Init(function ()
                self:OnBtnAddClick()
            end) -- 加号和格子点击功能一致
            self.GridPluginDic[k] = grid
        end
        grid:Refresh(xPlugin)
        grid.GameObject:SetActiveEx(true)
    end
    self.BtnAdd.transform:SetAsLastSibling()
    self.BtnAdd:ShowReddot(self.CurrSelectRole:CheckHasUpgradePluginRedpoint())

    -- 按钮状态
    local isRobot = self.CurrSelectRole:GetIsRobot()
    self.BtnFashion:SetDisable(isRobot)
    self.BtnPartner:SetDisable(isRobot)
    self.BtnConsciousness:SetDisable(isRobot)
    self.BtnWeapon:SetDisable(isRobot)
    if self.TeamPos then
        local isInTeam = self.XTeam:GetEntityIdIsInTeam(self.CurrSelectRole:GetId())
        self.BtnJoinTeam.gameObject:SetActiveEx(not isInTeam)
        self.BtnQuitTeam.gameObject:SetActiveEx(isInTeam)
    else
        self.BtnTeamPrefab.gameObject:SetActiveEx(false)
        self.BtnJoinTeam.gameObject:SetActiveEx(false)
        self.BtnQuitTeam.gameObject:SetActiveEx(false)
    end
    
    if self.HideTeamPefabBtn then
        self.BtnTeamPrefab.gameObject:SetActiveEx(false)
    end
end

-- 刷新3D模型
function XUiRiftCharacter:UpdateRoleModel()
    if not self.CurrSelectRole then
        return
    end

    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    local cb = function(model)
        self.PanelDrag.Target = model.transform
        if not self.CurrSelectRole:CheckIsIsomer() then
            self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        else
            self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
        end
    end
    
    if self.CurrSelectRole:GetIsRobot() then
        local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(self.CurrSelectRole:GetCharacterId())
        if XRobotManager.CheckUseFashion(self.CurrSelectRole:GetId()) and isOwn then
            local character = XDataCenter.CharacterManager.GetCharacter(self.CurrSelectRole:GetCharacterId())
            local robot2CharViewModel = character:GetCharacterViewModel()
            self.RoleModelPanel:UpdateRobotModel(self.CurrSelectRole:GetId(), self.CurrSelectRole:GetCharacterId(), nil, robot2CharViewModel:GetFashionId(), self.CurrSelectRole:GetUsingWeaponId(), cb)
        else
            self.RoleModelPanel:UpdateRobotModel(self.CurrSelectRole:GetId(), self.CurrSelectRole:GetCharacterId(), nil, self.CurrSelectRole:GetFashionId(), self.CurrSelectRole:GetUsingWeaponId(), cb)
        end
    else
        --MODEL_UINAME对应UiModelTransform表，设置模型位置
        self.RoleModelPanel:UpdateCharacterModel(self.CurrSelectRole:GetCharacterId(), self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiSuperSmashBrosCharacter, cb)
    end
end

function XUiRiftCharacter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local isCurrSelected = self.CurrRoleListIndex == index
        grid:Refresh(self.CurrShowList[index], self.IsMultiTeam)
        grid:SetSelect(isCurrSelected)
        if isCurrSelected then
            self.CurrGrid = grid
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurrGrid:SetSelect(false)
        grid:SetSelect(true)
        self.CurrGrid = grid
        self.CurrRoleListIndex = index
    end
end

function XUiRiftCharacter:CheckLimitBeforeChangeTeam(roleId, pos)
    local isTip = false

    local isInTeam, seleRoleTeam, seleRolePos = XDataCenter.RiftManager.CheckRoleInTeam(roleId)
    if self.XTeam ~= XDataCenter.RiftManager.GetSingleTeamData() then -- 多队伍需要进行的检测
        -- 多队伍压制锁定
        local isMultiEditLock = XDataCenter.RiftManager.CheckRoleInMultiTeamLock(seleRoleTeam)
        if isInTeam and isMultiEditLock then 
            XUiManager.TipError(CS.XTextManager.GetText("StrongholdElectricDeployInTeamLock"))
            return true
        end

        -- 多队伍其他队伍已持有同角色id锁定(不是roleId)
        for k, xTeam in pairs(XDataCenter.RiftManager.GetMultiTeamData()) do
            if xTeam ~= self.XTeam and xTeam:CheckHasSameCharacterIdButNotEntityId(roleId) then
                XUiManager.TipError(CS.XTextManager.GetText("StrongholdElectricDeploySameCharacter"))
                return true
            end
        end
    end

    -- 本队伍已持有同角色id锁定(不是roleId)
    local isHasSameCharid, sameCharIdInPos = self.XTeam:CheckHasSameCharacterIdButNotEntityId(roleId)
    if isHasSameCharid then
        if sameCharIdInPos ~= self.TeamPos then --不是替换就拦截，替换不管
            XUiManager.TipError(CS.XTextManager.GetText("StrongholdElectricDeploySameCharacter"))
            return true
        end
    end

    -- 确认是否把在其他队伍的角色替换了
    if self.IsMultiTeam and isInTeam and seleRoleTeam ~= self.XTeam then
        -- 弹提示
        isTip = true
        local inTeamId = seleRoleTeam:GetId()
        local title = CsXTextManagerGetText("StrongholdDeployTipTitle")
        local targetSeleRoleId = seleRoleTeam:GetEntityIdByTeamPos(seleRolePos)
        local characterName = XCharacterConfigs.GetCharacterName(XDataCenter.RiftManager.GetEntityRoleById(targetSeleRoleId):GetCharacterId())
        local content = CsXTextManagerGetText("StrongholdDeployTipContent", characterName, inTeamId, self.XTeam:GetId())
        local CloseTeamPrefabCb = function ()
            if XLuaUiManager.IsUiShow("UiRoomTeamPrefab") and TipCount == 0 then
                XLuaUiManager.Close("UiRoomTeamPrefab")
            end
        end
        TipCount = TipCount + 1
        XUiManager.DialogTip(
                title,
                content,
                XUiManager.DialogType.Normal,
                function ()
                    TipCount = TipCount - 1
                    CloseTeamPrefabCb()
                end,
                function ()
                    TipCount = TipCount - 1
                    -- 在别的队伍中，可以交换
                    XDataCenter.RiftManager.SwapMultiTeamMember(seleRoleTeam:GetId(), seleRolePos, self.XTeam:GetId(), pos)
                    CloseTeamPrefabCb()
                end
        )
    end

    if isTip then
        return true
    end

    return false
end

-- 通过队伍预设换人
function XUiRiftCharacter:RefreshTeamData(teamdata)
    if XTool.IsTableEmpty(teamdata) then
        return
    end
    local isLimit = false -- 被拦截了
    for k, id in pairs(teamdata.TeamData) do
        if XTool.IsNumberValid(id) and self:CheckLimitBeforeChangeTeam(id, k) then
            isLimit = true
        end
    end

    if not isLimit then
        self.XTeam:UpdateFromTeamData(teamdata)
    end
    self:Close()
end

function XUiRiftCharacter:OnBtnJoinTeamClick()
    if self:CheckLimitBeforeChangeTeam(self.CurrSelectRole:GetId(), self.TeamPos) then
        return
    end
    self.XTeam:UpdateEntityTeamPos(self.CurrSelectRole:GetId(), self.TeamPos, true)
    self:Close()
end

function XUiRiftCharacter:OnBtnQuitTeamClick()
    local curRolePos = self.XTeam:GetEntityIdPos(self.CurrSelectRole:GetId())
    self.XTeam:UpdateEntityTeamPos(nil, curRolePos, true)
    self:Close()
end

function XUiRiftCharacter:OnBtnConsciousnessClick()
    if self.CurrSelectRole:GetIsRobot() then return end
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwareness(self.CurrSelectRole:GetCharacterId())
end

function XUiRiftCharacter:OnBtnWeaponClick()
    if self.CurrSelectRole:GetIsRobot() then return end
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self.CurrSelectRole:GetCharacterId(), nil, true)
end

function XUiRiftCharacter:OnBtnFashionClick()
    if self.CurrSelectRole:GetIsRobot() then return end
    XLuaUiManager.Open("UiFashion", self.CurrSelectRole:GetCharacterId())
end

function XUiRiftCharacter:OnBtnPartnerClick()
    if self.CurrSelectRole:GetIsRobot() then return end
    XDataCenter.PartnerManager.GoPartnerCarry(self.CurrSelectRole:GetCharacterId(), false)
end

-- 队伍预设
function XUiRiftCharacter:OnBtnTeamPrefabClick()
    local stageId = XDataCenter.RiftManager.GetCurrSelectRiftStageGroup():GetAllEntityStages()[1].StageId
    local characterLimitType = XTool.IsNumberValid(stageId) and XFubenConfigs.GetStageCharacterLimitType(stageId)
    local limitBuffId = XTool.IsNumberValid(stageId) and XFubenConfigs.GetStageCharacterLimitBuffId(stageId)
    local stageInfo = XTool.IsNumberValid(stageId) and XDataCenter.FubenManager.GetStageInfo(stageId) or {}
    local stageType = stageInfo.Type

    local closeCb = function()
        self:Close()
    end

    XLuaUiManager.Open("UiRoomTeamPrefab", 
    self.XTeam:GetCaptainPos(),
    self.XTeam:GetFirstFightPos(), 
    characterLimitType,
    nil, 
    stageType, 
    nil, 
    closeCb, 
    stageId, 
    self.XTeam)
end

function XUiRiftCharacter:OnBtnAddClick()
    XLuaUiManager.Open("UiRiftChoosePlugin", self.CurrSelectRole)
    self.CurrSelectRole:ClearUpgradePluginRedpoint()
end

function XUiRiftCharacter:OnBtnFilterClick()
    local characterType = self.SelectTabBtnIndex
    local characterList = XDataCenter.RiftManager.GetEntityRoleListByCharaType(characterType)
    XLuaUiManager.Open("UiCommonCharacterFilterTipsOptimization", characterList, characterType, function (afterFiltList)
        self.CurrRoleListIndex = 1
        self:UpdateDynamicTable(afterFiltList)
    end, characterType)
end

function XUiRiftCharacter:OnDisable()
    self.Super.OnDisable(self)
end

function XUiRiftCharacter:OnDestroy()
    XDataCenter.CommonCharacterFiltManager.ClearCacheData() --清除筛选缓存数据
    XEventManager.RemoveEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.RefreshTeamData, self)
end

function XUiRiftCharacter:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.RiftManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

return XUiRiftCharacter