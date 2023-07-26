local CsXTextManager = CS.XTextManager
local XUiSuperTowerRoleGrid = require("XUi/XUiSuperTower/Role/XUiSuperTowerRoleGrid")
local XUiSuperTowerRoleLevelUpPanel = require("XUi/XUiSuperTower/Role/XUiSuperTowerRoleLevelUpPanel")
local XUiSTFunctionButton = require("XUi/XUiSuperTower/Common/XUiSTFunctionButton")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

--######################## XUiSuperTowerRoleDetail ########################
local XUiSuperTowerRoleDetail = XLuaUiManager.Register(XLuaUi, "UiSuperTowerRoleOverrun")

local CHILD_PANEL_TYPE = {
    Default = 1,
    Level = 2
}

function XUiSuperTowerRoleDetail:OnAwake()
    self.CurrentListRoles = nil
    self.CurrentRoleId = nil
    self.CurrentPanelType = CHILD_PANEL_TYPE.Default
    self.CurrentCharacterType = XCharacterConfigs.CharacterType.Normal
    self.CurrentIsAscendOrder = true
    self.CurrentSortTagType = XRoomCharFilterTipsConfigs.EnumSortTag.Default
    self.CurrentSelectTagGroup = {
        [XCharacterConfigs.CharacterType.Normal] = {},
        [XCharacterConfigs.CharacterType.Isomer] = {},
    }
    -- XUiSuperTowerRoleLevelUpPanel
    self.UiRoleLevelUpPanel = nil
    -- 角色列表
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiSuperTowerRoleGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridCharacter.gameObject:SetActiveEx(false)
    -- 模型相关
    local root = self.UiModelGo.transform
    local panelRoleModel = root:FindTransform("PanelRoleModel")
    -- XCharacterConfigs.XUiCharacter_Camera.MAIN
    self.CameraFar = {
        root:FindTransform("CamFarMain"),
        root:FindTransform("UiCamFarLv"),
    }
    self.CameraNear = {
        root:FindTransform("CamNearMain"),
        root:FindTransform("UiCamNearLv"),
    }
    -- 子面板信息配置
    self.ChillPanelInfoDic = {
        [CHILD_PANEL_TYPE.Level] = {
            uiParent = self.PanelLevelChid,
            assetPath = XUiConfigs.GetComponentUrl("UiPanelSuperTowerChip"),
            proxy = XUiSuperTowerRoleLevelUpPanel,
            -- 代理设置参数
            proxyArgs = {
                "CurrentRoleId",
            }
        },
    }
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.UiPanelRoleModel = XUiPanelRoleModel.New(panelRoleModel, self.Name, nil, true, nil, true)
    self:RegisterUiEvents()
    self.BtnTabShougezhe:SetDisable(not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer))
    local itemIds = XSuperTowerConfigs.GetMainAssetsPanelItemIds()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(itemIds, function()
        self.AssetActivityPanel:Refresh(itemIds)
    end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh(itemIds)
    -- XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem
    -- , XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

-- currentRoleId : 默认显示的角色Id
function XUiSuperTowerRoleDetail:OnStart(currentRoleId)
    self.CurrentRoleId = currentRoleId
    -- 刷新列表
    self.BtnGroupCharacterType:SelectIndex(XCharacterConfigs.CharacterType.Normal)
    self.BtnUpSort.gameObject:SetActiveEx(not self.CurrentIsAscendOrder)
    self.BtnDownSort.gameObject:SetActiveEx(self.CurrentIsAscendOrder)
    self:SetCameraType(CHILD_PANEL_TYPE.Default)
    XRedPointManager.CheckOnceByButton(self.BtnSpecial, { XRedPointConditions.Types.CONDITION_SUPERTOWER_ROLE_INDULT })
    -- 自动关闭
    local endTime = XDataCenter.SuperTowerManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XLuaUiManager.Close("UiSuperTowerTedianUP")
            XDataCenter.SuperTowerManager.HandleActivityEndTime()
        end
    end)
end

--######################## 私有方法 ########################
function XUiSuperTowerRoleDetail:RegisterUiEvents()
    local superTowerManager = XDataCenter.SuperTowerManager
    self.BtnBack.CallBack = function() self:OnBtnBackClicked() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnCareerTips.CallBack = function() XLuaUiManager.Open("UiCharacterCarerrTips", XEntityHelper.GetCharacterIdByEntityId(self.CurrentRoleId)) end
    self.BtnPluginUnlock.CallBack = function() self:OnBtnPluginUnlockClicked() end
    self.BtnFilter.CallBack = function() self:OnBtnFilterClicked() end
    self.BtnDownSort.CallBack = function() self:OnBtnDownSortClicked() end
    self.BtnUpSort.CallBack = function() self:OnBtnUpSortClicked() end
    -- self.BtnSpecial.CallBack = function() self:OnBtnSpecialClicked() end
    XUiSTFunctionButton.New(self.BtnSpecial, function() self:OnBtnSpecialClicked() end, superTowerManager.FunctionName.BonusChara)
    -- self.BtnLevelUp.CallBack = function() self:OnBtnLevelUpClicked() end
    XUiSTFunctionButton.New(self.BtnLevelUp, function() self:OnBtnLevelUpClicked() end, superTowerManager.FunctionName.Transfinite)
    XUiSTFunctionButton.New(self.BtnUnlockPluginMask, nil, superTowerManager.FunctionName.Exclusive)
    self.BtnElementDetail.CallBack = function() self:OnBtnElementDetailClicked() end
    -- 角色类型按钮组
    self.BtnGroupCharacterType:Init({
        [XCharacterConfigs.CharacterType.Normal] = self.BtnTabGouzaoti,
        [XCharacterConfigs.CharacterType.Isomer] = self.BtnTabShougezhe
    }, function(tabIndex) self:OnBtnGroupCharacterTypeClicked(tabIndex) end)
    self:BindHelpBtn(self.BtnHelp, "SuperTowerCharaHelp")
    self.BtnPluginClick.CallBack = function() self:OnBtnPluginClicked() end
end

function XUiSuperTowerRoleDetail:OnBtnPluginClicked()
    local superTowerRole = XDataCenter.SuperTowerManager.GetRoleManager():GetRole(self.CurrentRoleId)
    XLuaUiManager.Open("UiSuperTowerPluginDetails", superTowerRole:GetTransfinitePlugin())
end

function XUiSuperTowerRoleDetail:OnBtnElementDetailClicked()
    XLuaUiManager.Open("UiCharacterElementDetail", XEntityHelper.GetCharacterIdByEntityId(self.CurrentRoleId))
end

function XUiSuperTowerRoleDetail:OnBtnBackClicked()
    if self.CurrentPanelType ~= CHILD_PANEL_TYPE.Default then
        self:OpenChildPanel(CHILD_PANEL_TYPE.Default)
    else
        self:Close()
    end
end

function XUiSuperTowerRoleDetail:OnBtnLevelUpClicked()
    local superTowerRole = XDataCenter.SuperTowerManager.GetRoleManager():GetRole(self.CurrentRoleId)
    if superTowerRole:GetSuperLevel() >= superTowerRole:GetMaxSuperLevel() then
        XUiManager.TipError(XUiHelper.GetText("STTransfiniteMaxLevel"))
        return
    end
    self:SetChildGosActive(false)
    self:OpenChildPanel(CHILD_PANEL_TYPE.Level)
end

function XUiSuperTowerRoleDetail:SetChildGosActive(value)
    self.PanelRoleOverrun.gameObject:SetActiveEx(value)
end

function XUiSuperTowerRoleDetail:OnBtnSpecialClicked()
    XLuaUiManager.Open("UiSuperTowerTedianUP")
    XRedPointManager.CheckOnceByButton(self.BtnSpecial, { XRedPointConditions.Types.CONDITION_SUPERTOWER_ROLE_INDULT })
end

function XUiSuperTowerRoleDetail:OnBtnDownSortClicked()
    self.BtnDownSort.gameObject:SetActiveEx(false)
    self.BtnUpSort.gameObject:SetActiveEx(true)
    self.CurrentIsAscendOrder = false
    local roleManager = XDataCenter.SuperTowerManager.GetRoleManager()
    self.CurrentListRoles = roleManager:SortRoles(self.CurrentListRoles, self.CurrentSortTagType, self.CurrentIsAscendOrder)
    self.CurrentRoleId = nil
    self:RefreshCharacterList(self.CurrentListRoles)
end

function XUiSuperTowerRoleDetail:OnBtnUpSortClicked()
    self.BtnUpSort.gameObject:SetActiveEx(false)
    self.BtnDownSort.gameObject:SetActiveEx(true)
    self.CurrentIsAscendOrder = true
    local roleManager = XDataCenter.SuperTowerManager.GetRoleManager()
    self.CurrentListRoles = roleManager:SortRoles(self.CurrentListRoles, self.CurrentSortTagType, self.CurrentIsAscendOrder)
    self.CurrentRoleId = nil
    self:RefreshCharacterList(self.CurrentListRoles)
end

function XUiSuperTowerRoleDetail:OnBtnFilterClicked()
    local superTowerManager = XDataCenter.SuperTowerManager
    local isOpen = superTowerManager.CheckFunctionUnlockByKey(superTowerManager.FunctionName.Transfinite)
    XLuaUiManager.Open("UiRoomCharacterFilterTips", self,
    XRoomCharFilterTipsConfigs.EnumFilterType.SuperTower,
    XRoomCharFilterTipsConfigs.EnumSortType.SuperTower,
    self.CurrentCharacterType, nil, nil,
    {[XRoomCharFilterTipsConfigs.EnumSortTag.SuperLevel] = not isOpen })
end

function XUiSuperTowerRoleDetail:Filter(selectTagGroupDic, sortTagId, isThereFilterDataCb)
    local roleManager = XDataCenter.SuperTowerManager.GetRoleManager()
    if self.TagCacheDic == nil then self.TagCacheDic = {} end
    XDataCenter.RoomCharFilterTipsManager.Filter(self.TagCacheDic, selectTagGroupDic
    , roleManager:GetCanFightRoles(self.CurrentCharacterType)
    , roleManager:GetFilterJudge()
    , function(filteredData)
        self.CurrentSelectTagGroup[self.CurrentCharacterType].TagGroupDic = selectTagGroupDic
        self.CurrentSelectTagGroup[self.CurrentCharacterType].SortType = sortTagId
        self:FilterRefresh(filteredData, sortTagId)
    end
    , isThereFilterDataCb)
end

function XUiSuperTowerRoleDetail:FilterRefresh(filteredData, sortTagType)
    local roleManager = XDataCenter.SuperTowerManager.GetRoleManager()
    filteredData = XDataCenter.SuperTowerManager.GetRoleManager():SortRoles(filteredData, sortTagType, self.CurrentIsAscendOrder)
    self.CurrentRoleId = nil
    self:RefreshCharacterList(filteredData)
end

function XUiSuperTowerRoleDetail:OnBtnPluginUnlockClicked()
    local roleManager = XDataCenter.SuperTowerManager.GetRoleManager()
    local role = roleManager:GetRole(self.CurrentRoleId)
    local plugin = role:GetTransfinitePlugin()
    -- 检查是否有足够的插件
    if not XDataCenter.SuperTowerManager.GetBagManager():GetIsHaveData(plugin:GetId()) then
        XUiManager.TipError(CS.XTextManager.GetText("STPluginCountNotEnough"))
        return false
    end
    local okCallback = function()
        roleManager:RequestMountPlugin(role:GetCharacterId(), plugin:GetId(), function()
            self:RefreshPluginInfo(role)
            self.DynamicTable:ReloadDataSync(nil, false)
            XLuaUiManager.Open("UiSuperTowerUnlocking", role)
        end)
    end
    XLuaUiManager.Open("UiDialog", CS.XTextManager.GetText("TipTitle")
    , CS.XTextManager.GetText("STPluginUnlockTipContent", plugin:GetName() .. plugin:GetStar(), role:GetCharacterViewModel():GetTradeName())
    , XUiManager.DialogType.Normal, nil, okCallback)
end

function XUiSuperTowerRoleDetail:OnBtnGroupCharacterTypeClicked(index)
    if index == XCharacterConfigs.CharacterType.Isomer
    and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Isomer) then
        return
    end
    self.CurrentCharacterType = index
    local selectTagGroupDic = self.CurrentSelectTagGroup[index].TagGroupDic or {}
    local sortTagId = self.CurrentSelectTagGroup[index].SortType or XRoomCharFilterTipsConfigs.EnumSortTag.Default
    local roles = XDataCenter.SuperTowerManager.GetRoleManager():GetCanFightRoles(self.CurrentCharacterType)
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
function XUiSuperTowerRoleDetail:RefreshCharacterList(roles)
    local index = 1
    for i, value in ipairs(roles) do
        if self.CurrentRoleId == value:GetId() then
            index = i
        end
    end
    self.CurrentRoleId = roles[index]:GetId()
    self.CurrentListRoles = roles
    self.DynamicTable:SetDataSource(roles)
    self.DynamicTable:ReloadDataSync(index)
    -- 刷新基本信息
    self:RefreshCharacterInfo(roles[index])
end

function XUiSuperTowerRoleDetail:OnDynamicTableEvent(event, index, grid)
    local data = self.CurrentListRoles[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(data)
        grid:SetSelectStatus(self.CurrentRoleId == data:GetId())
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurrentRoleId = data:GetId()
        for _, tmpGrid in pairs(self.DynamicTable:GetGrids()) do
            tmpGrid:SetSelectStatus(false)
        end
        grid:SetSelectStatus(true)
        -- 刷新基本信息
        self:RefreshCharacterInfo(data)
    end
end

function XUiSuperTowerRoleDetail:RefreshCharacterInfo(superTowerRole)
    local characterViewModel = superTowerRole:GetCharacterViewModel()
    local roleId = superTowerRole:GetId()
    -- 模型
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    local finishedCallback = function(model)
        self.PanelDrag.Target = model.transform
        self.PanelDrag2.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(self.CurrentCharacterType == XCharacterConfigs.CharacterType.Normal)
        self.ImgEffectHuanren1.gameObject:SetActiveEx(self.CurrentCharacterType == XCharacterConfigs.CharacterType.Isomer)
    end
    if XRobotManager.CheckIsRobotId(roleId) then
        local robotConfig = XRobotManager.GetRobotTemplate(roleId)
        self.UiPanelRoleModel:UpdateRobotModel(roleId, robotConfig.CharacterId
        , nil, robotConfig.FashionId, robotConfig.WeaponId, finishedCallback)
    else
        self.UiPanelRoleModel:UpdateCharacterModel(roleId, nil, nil, finishedCallback, nil, characterViewModel:GetFashionId())
    end
    -- 头部基本信息
    self.RImgTypeIcon:SetRawImage(characterViewModel:GetProfessionIcon())
    self.TxtName.text = characterViewModel:GetName()
    self.TxtNameOther.text = characterViewModel:GetTradeName()
    self.TxtFightPower.text = superTowerRole:GetAbility()
    local obtainElementIcons = characterViewModel:GetObtainElementIcons()
    local obtainElementIcon
    for i = 1, 3 do
        obtainElementIcon = obtainElementIcons[i]
        self["RImgCharElement" .. i].gameObject:SetActiveEx(obtainElementIcon ~= nil)
        if obtainElementIcon then
            self["RImgCharElement" .. i]:SetRawImage(obtainElementIcon)
        end
    end
    -- 超限信息
    local currentExp = superTowerRole:GetCurrentExp()
    local maxExp = superTowerRole:GetMaxExp()
    local currentLevel = superTowerRole:GetSuperLevel()
    local maxLevel = superTowerRole:GetMaxSuperLevel()
    if currentLevel >= maxLevel then
        currentLevel = maxLevel
        currentExp = maxExp
    end
    self.TxtRoleLevelInfo.text = string.format("%s/%s", currentLevel, maxLevel)
    self.TxtExpInfo.text = string.format("%s/%s", currentExp, maxExp)
    self.ImgExpBar.fillAmount = currentExp / maxExp
    -- 属性信息
    local attributeDic = characterViewModel:GetAttributes(superTowerRole:GetEquipViewModels())
    self.TxtLife.text = FixToInt(attributeDic[XNpcAttribType.Life]) + superTowerRole:GetAttributeValue(XNpcAttribType.Life)
    self.TxtAttack.text = FixToInt(attributeDic[XNpcAttribType.AttackNormal]) + superTowerRole:GetAttributeValue(XNpcAttribType.AttackNormal)
    self.TxtDefense.text = FixToInt(attributeDic[XNpcAttribType.DefenseNormal]) + superTowerRole:GetAttributeValue(XNpcAttribType.DefenseNormal)
    self.TxtCrit.text = FixToInt(attributeDic[XNpcAttribType.Crit]) + superTowerRole:GetAttributeValue(XNpcAttribType.Crit)
    -- 专属插件
    local plugin = superTowerRole:GetTransfinitePlugin()
    self.TxtPluginName.text = superTowerRole:GetTransfinitePluginName() --plugin:GetName()
    self.TxtPluginDes.text = superTowerRole:GetTransfinitePluginDesc()
    self.RImgPluginIcon:SetRawImage(plugin:GetIcon())
    self.ImgPluginQuality:SetSprite(plugin:GetQualityIcon())
    self.TxtLockPluginName.text = plugin:GetName()
    self:RefreshPluginInfo(superTowerRole)
    -- 超限按钮状态
    self.BtnLevelUp:SetDisable(currentLevel >= maxLevel)
    XRedPointManager.CheckOnceByButton(self.BtnLevelUp, { XRedPointConditions.Types.CONDITION_SUPERTOWER_ROLE_LEVELUP }, roleId)
    XRedPointManager.CheckOnceByButton(self.BtnPluginUnlock, { XRedPointConditions.Types.CONDITION_SUPERTOWER_ROLE_PLUGIN }, roleId)
    self.DynamicTable:ReloadDataSync(nil, false)
end

function XUiSuperTowerRoleDetail:RefreshPluginInfo(superTowerRole)
    local isActive = superTowerRole:GetTransfinitePluginIsActive()
    -- 通过特权解锁来决定
    local isUnlock = XDataCenter.SuperTowerManager.CheckFunctionUnlockByKey(XDataCenter.SuperTowerManager.FunctionName.Exclusive)
    self.BtnPluginUnlock.gameObject:SetActiveEx(isUnlock and not isActive)
    self.PanelPluginLock.gameObject:SetActiveEx(not isUnlock)
    self.ImgNormalLock.gameObject:SetActiveEx(isUnlock and not isActive)
    self.TxtPluginActive.gameObject:SetActiveEx(isUnlock and isActive)
    local hasPlugin = XDataCenter.SuperTowerManager.GetBagManager():GetIsHaveData(superTowerRole:GetTransfinitePluginId())
    self.UnlockPluginEffect.gameObject:SetActiveEx(isUnlock and not isActive and hasPlugin)
end

function XUiSuperTowerRoleDetail:OpenChildPanel(index)
    self:SetChildGosActive(index == CHILD_PANEL_TYPE.Default)
    self.PanelDrag.gameObject:SetActiveEx(index == CHILD_PANEL_TYPE.Default)
    self.PanelDrag2.gameObject:SetActiveEx(index == CHILD_PANEL_TYPE.Level)
    if index == CHILD_PANEL_TYPE.Default then
        self.CurrentPanelType = index
        self:RefreshCharacterInfo(XDataCenter.SuperTowerManager.GetRoleManager():GetRole(self.CurrentRoleId))
    end
    -- 显示/隐藏关联子面板
    for key, data in pairs(self.ChillPanelInfoDic) do
        data.uiParent.gameObject:SetActiveEx(key == index)
    end
    local childPanelData = self.ChillPanelInfoDic[index]
    self:SetCameraType(index)
    if not childPanelData then return end
    self.CurrentPanelType = index
    -- 加载panel asset
    local instanceGo = childPanelData.instanceGo
    if instanceGo == nil then
        instanceGo = childPanelData.uiParent:LoadPrefab(childPanelData.assetPath)
        childPanelData.instanceGo = instanceGo
    end
    -- 加载panel proxy
    local instanceProxy = childPanelData.instanceProxy
    if instanceProxy == nil then
        instanceProxy = childPanelData.proxy.New(instanceGo)
        childPanelData.instanceProxy = instanceProxy
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
    instanceProxy:SetData(table.unpack(proxyArgs))
end

function XUiSuperTowerRoleDetail:SetCameraType(index)
    for k, _ in pairs(self.CameraFar) do
        self.CameraFar[k].gameObject:SetActiveEx(k == index)
    end
    for k, _ in pairs(self.CameraNear) do
        self.CameraNear[k].gameObject:SetActiveEx(k == index)
    end
end

return XUiSuperTowerRoleDetail