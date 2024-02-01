---@class XUiRiftCharacter : XLuaUi 大秘境主界面
local XUiRiftCharacter = XLuaUiManager.Register(XLuaUi, "UiRiftCharacter")
local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local TipCount = 0

function XUiRiftCharacter:OnAwake()
    ---@type XCharacterAgency
    self.CharacterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    ---@type XCommonCharacterFilterAgency
    self.FiltAgecy = XMVCA:GetAgency(ModuleId.XCommonCharacterFilter)
    self:InitButton()
    self:InitModel()
    self:InitTimes()
    self.CurrSelectRole = nil
    self.SelectTabBtnIndex = 1
    self.CurrRoleListIndex = 1
    self.CurrGrid = nil
    self.GridPluginDic = {}
    self.GridRiftCore.gameObject:SetActiveEx(false)

    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_SYN, self.RefresFilter, self)
    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_FIRST_GET, self.RefresFilter, self)
end

function XUiRiftCharacter:OnStart(isMultiTeam, xTeam, teamPos, hideTeamPefabBtn)
    self.IsInit = true
    self.IsMultiTeam = isMultiTeam --是否是多队伍进入的
    self.XTeam = xTeam or XDataCenter.RiftManager.GetSingleTeamData()
    self.TeamPos = teamPos
    self.HideTeamPefabBtn = hideTeamPefabBtn
    self:InitFilter()

    if xTeam and teamPos then
        local roleId = xTeam:GetEntityIdByTeamPos(teamPos)
        local xRole = XDataCenter.RiftManager.GetEntityRoleById(roleId)
        if xRole then
            self.PanelFilter:DoSelectTag("BtnAll", true, roleId)
            self:OnRoleSelected(xRole)
        else
            self.PanelFilter:DoSelectTag("BtnAll", true)
        end
    else
        self.PanelFilter:DoSelectTag("BtnAll", true)
    end
end

function XUiRiftCharacter:InitFilter()
    self.PanelFilter = self.FiltAgecy:InitFilter(self.PanelCharacterFilter, self)

    local onSeleCb = function(character, index, grid, isFirstSelect)
        if not character then
            return
        end
        local xRole = XDataCenter.RiftManager.GetEntityRoleById(character.Id)
        self:OnRoleSelected(xRole)
    end

    local refreshFun = function(index, grid, char)
        local isInTeam = self.XTeam:GetEntityIdIsInTeam(char:GetId())
        local isSameRole = self.XTeam:CheckHasSameCharacterIdButNotEntityId(char:GetId())
        grid:SetData(char)
        grid:UpdateFight()
        grid:SetInTeamStatus(isInTeam)
        grid:SetInSameStatus(isSameRole and not isInTeam)
    end

    local checkInTeam = function(id)
        return self.XTeam:GetEntityIdIsInTeam(id)
    end

    self.PanelFilter:InitData(onSeleCb, nil, nil, refreshFun, require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid"), checkInTeam)

    self.FiltAgecy:SetNotSortTrigger()
    self:RefresFilter()
end

function XUiRiftCharacter:RefresFilter()
    local list = self.CharacterAgency:GetOwnCharacterList()
    appendArray(list, XDataCenter.RiftManager.GetRobot())
    self.PanelFilter:ImportList(list)
    self.PanelFilter:RefreshList()
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
    XUiHelper.RegisterClickEvent(self, self.BtnAdd, self.OnBtnAddClick)
    XUiHelper.RegisterClickEvent(self, self.BtnOwnedDetail, function() XLuaUiManager.Open("UiCharacterDetail", self.CurrSelectRole:GetCharacterId()) end)
    XUiHelper.RegisterClickEvent(self, self.BtnTeaching, function() XDataCenter.PracticeManager.OpenUiFubenPractice(self.CurrSelectRole:GetCharacterId()) end)
    XUiHelper.RegisterClickEvent(self, self.BtnType, self.OnBtnCareerTipsClick)
    XEventManager.AddEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.RefreshTeamData, self)
end

function XUiRiftCharacter:InitModel()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiRiftCharacter:OnEnable()
    self.Super.OnEnable(self)
    self.PanelFilter:InitFoldState()
    self:UpdateRightCharacterInfo()
    self:UpdateRoleModel()
    if not self.IsInit then
        self:RefresFilter()
    end
    self.IsInit = false
end

-- 角色被选中
function XUiRiftCharacter:OnRoleSelected(xRole)
    if xRole == self.CurrSelectRole then
        return
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
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(characterId)
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName
    self.BtnType:SetRawImage(self.CurrSelectRole:GetCareerIcon())
    self.TxtAbility.text = self:GetRoleAbility()
    local elementIcons = {}
    table.insert(elementIcons, XMVCA.XCharacter:GetCharElement(charConfig.Element).Icon)
    self:RefreshTemplateGrids(self.RImgCharElement, elementIcons, self.BtnElementDetail.transform, nil, "UiRiftCharacterElement", function(grid, data)
        grid.RImgCharElement:SetRawImage(data)
    end)

    -- 负载信息
    self.TxtLoadNum.text = CS.XTextManager.GetText("RiftPluginLoad", self.CurrSelectRole:GetCurrentLoad(), XDataCenter.RiftManager.GetMaxLoad())
    self.ImgLoadProgress.fillAmount = self.CurrSelectRole:GetCurrentLoad() / XDataCenter.RiftManager.GetMaxLoad()

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

function XUiRiftCharacter:GetRoleAbility()
    local id = self.CurrSelectRole:GetId()
    local entity = nil
    if XEntityHelper.GetIsRobot(id) then
        entity = XRobotManager.GetRobotById(id)
    else
        entity = XMVCA.XCharacter:GetCharacter(id)
    end
    if entity then
        local viewModel = entity:GetCharacterViewModel()
        if not viewModel then
            return self.CharacterAgency:GetCharacterHaveRobotAbilityById(id)
        end
        return viewModel:GetAbility()
    end
    return 0
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
        local isOwn = XMVCA.XCharacter:IsOwnCharacter(self.CurrSelectRole:GetCharacterId())
        if XRobotManager.CheckUseFashion(self.CurrSelectRole:GetId()) and isOwn then
            local character = XMVCA.XCharacter:GetCharacter(self.CurrSelectRole:GetCharacterId())
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
        local characterName = XMVCA.XCharacter:GetCharacterName(XDataCenter.RiftManager.GetEntityRoleById(targetSeleRoleId):GetCharacterId())
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
    XLuaUiManager.Remove("UiRiftCharacter") -- 这里用self:Close()的话 会在UiRoomTeamPrefab关闭时被重新打开
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

    XLuaUiManager.Open("UiRoomTeamPrefab", 
    self.XTeam:GetCaptainPos(),
    self.XTeam:GetFirstFightPos(), 
    characterLimitType,
    nil, 
    stageType, 
    nil, 
    nil,
    stageId, 
    self.XTeam)
end

function XUiRiftCharacter:OnBtnAddClick()
    XLuaUiManager.Open("UiRiftChoosePlugin", self.CurrSelectRole)
    self.CurrSelectRole:ClearUpgradePluginRedpoint()
end

function XUiRiftCharacter:OnBtnCareerTipsClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.CurrSelectRole:GetCharacterId())
end

function XUiRiftCharacter:OnDisable()
    self.Super.OnDisable(self)
end

function XUiRiftCharacter:OnDestroy()
    XDataCenter.CommonCharacterFiltManager.ClearCacheData() --清除筛选缓存数据
    XEventManager.RemoveEventListener(XEventId.EVENT_TEAM_PREFAB_SELECT, self.RefreshTeamData, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CHARACTER_SYN, self.RefresFilter, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CHARACTER_FIRST_GET, self.RefresFilter, self)
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