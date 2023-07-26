local XUiSuperTowerPluginGrid = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")

local XUiSuperTowerRoleLevelUpPanel = XClass(nil, "XUiSuperTowerRoleLevelUpPanel")

local AUTO_SELECT_MIN_STAR = 2
local AUTO_SELECT_MAX_STAR = 4

function XUiSuperTowerRoleLevelUpPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    -- XSuperTowerRole
    self.SuperTowerRole = nil
    -- XSuperPlugin Dic
    self.UsedSuperPluginDic = nil
    -- 插件选择状态
    self.PluginGridSelectStatusDic = nil
    -- 插件筛选星级状态
    self.PluginStarSelectStatusDic = nil
    -- 插件列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll)
    self.DynamicTable:SetProxy(XUiSuperTowerPluginGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridCore.gameObject:SetActiveEx(false)
    self.CurrentPlugins = nil
    self.ImgAscend.gameObject:SetActiveEx(true)
    self.ImgDescend.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

-- superTowerRole : XSuperTowerRole
function XUiSuperTowerRoleLevelUpPanel:SetData(superTowerRoleId)
    self.GameObject:SetActiveEx(true)
    self.SuperTowerRole = XDataCenter.SuperTowerManager.GetRoleManager():GetRole(superTowerRoleId)
    self:Reset()
end

--######################## 私有方法 ########################
function XUiSuperTowerRoleLevelUpPanel:Reset()
    self.PluginStarSelectStatusDic = {
        [2] = false,
        [3] = false,
        [4] = false,
    }
    self.UsedSuperPluginDic = {}
    self.PluginGridSelectStatusDic = {}
    self.TotalAddExp = 0
    -- 初始化toggle的状态
    for k, v in pairs(self.PluginStarSelectStatusDic) do
        self["TogStar" .. k].isOn = v
    end
    self:ResetBaseInfo()
end

function XUiSuperTowerRoleLevelUpPanel:RegisterUiEvents()
    self.BtnGetPlugins.CallBack = function() self:OnBtnGetPluginsClicked() end
    self.BtnUpgrade.CallBack = function() self:OnBtnUpgradeClicked() end
    self.BtnAutoSelect.CallBack = function() self:OnBtnAutoSelectClicked() end
    self.BtnStar4.CallBack = function() self:OnBtnTogStarValueChanged(4) end
    self.BtnStar3.CallBack = function() self:OnBtnTogStarValueChanged(3) end
    self.BtnStar2.CallBack = function() self:OnBtnTogStarValueChanged(2) end
    self.BtnOrder.CallBack = function() self:OnBtnOrderClicked() end
end

function XUiSuperTowerRoleLevelUpPanel:OnBtnOrderClicked()
    local isAscend = self.ImgAscend.gameObject.activeSelf
    self.ImgAscend.gameObject:SetActiveEx(not isAscend)
    self.ImgDescend.gameObject:SetActiveEx(isAscend)
    self:Reset()
end

function XUiSuperTowerRoleLevelUpPanel:OnBtnTogStarValueChanged(star, isOn)
    if isOn == self["TogStar" .. star].isOn then
        return
    end
    if isOn == nil then isOn = not self["TogStar" .. star].isOn end
    -- 设置toggle状态
    -- isOn为true时检查是否超过最大等级
    if isOn and self.SuperTowerRole:GetSuperLevel() >= self.SuperTowerRole:GetMaxSuperLevel() then
        XUiManager.TipError(XUiHelper.GetText("STTransfiniteMaxLevel"))
        self["TogStar" .. star].isOn = false
        return
    end
    self["TogStar" .. star].isOn = isOn
    self.PluginStarSelectStatusDic[star] = isOn
    -- 找到相同星级的做点击或取消点击的处理
    local plugins = {}
    for _, plugin in ipairs(self.CurrentPlugins) do
        if star == plugin:GetStar() then
            table.insert(plugins, plugin)
        end
    end
    self:AutoSelectPlugin(plugins, isOn)
end

function XUiSuperTowerRoleLevelUpPanel:RefreshPlugins()
    self.CurrentPlugins = XDataCenter.SuperTowerManager.GetBagManager():GetPlugins(not self.ImgAscend.gameObject.activeSelf)
    self.DynamicTable:SetDataSource(self.CurrentPlugins)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiSuperTowerRoleLevelUpPanel:OnDynamicTableEvent(event, index, grid)
    if index <= 0 or index > #self.DynamicTable.DataSource then return end
    local data = self.DynamicTable.DataSource[index]
    local pluginId = data:GetId()
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshData(data)
        grid:SetActiveStatus(self:GetPluginSelectStatus(data))
        grid:SetClickCallBack(function(selfGrid)
            self:HandlePluginClicked(selfGrid:GetPlugin(), selfGrid)
        end)
    end
end

function XUiSuperTowerRoleLevelUpPanel:HandlePluginClicked(plugin, grid, selectStatus, isShowMaxLevelTip)
    if isShowMaxLevelTip == nil then isShowMaxLevelTip = true end
    if selectStatus == nil then selectStatus = not self:GetPluginSelectStatus(plugin) end
    -- 检查是否超过最大等级
    if selectStatus then
        local showLevel = tonumber(string.Split(self.TxtLevelInfo.text, '/')[1])
        if showLevel >= self.SuperTowerRole:GetMaxSuperLevel() then
            if isShowMaxLevelTip then
                XUiManager.TipError(XUiHelper.GetText("STTransfiniteMaxLevel"))
            end
            return false
        end
    end
    local pluginId = plugin:GetId()
    -- 设置选中状态
    if grid then
        grid:SetActiveStatus(selectStatus)
    end
    -- 已经是选中的状态，不需要处理
    if selectStatus == self:GetPluginSelectStatus(plugin) then
        return true
    end
    local addExp = 0
    if selectStatus then
        addExp = plugin:GetExp()
    else
        addExp = plugin:GetExp() * -1
    end
    self.PluginGridSelectStatusDic[plugin] = selectStatus
    self.TotalAddExp = self.TotalAddExp + addExp
    local currentExp = self.SuperTowerRole:GetCurrentExp()
    local currentLevel = self.SuperTowerRole:GetSuperLevel()
    local nextLevelExp = self.SuperTowerRole:GetMaxExp(currentLevel)
    local newCurrentExp = currentExp + self.TotalAddExp
    while newCurrentExp >= nextLevelExp do
        newCurrentExp = newCurrentExp - nextLevelExp
        currentLevel = currentLevel + 1
        nextLevelExp = self.SuperTowerRole:GetMaxExp(currentLevel)
    end
    self.TxtAddExp.text = self.TotalAddExp
    if currentLevel > self.SuperTowerRole:GetSuperLevel() then
        self.ImgExpAddBar.fillAmount = 1
    else
        self.ImgExpAddBar.fillAmount = newCurrentExp / nextLevelExp
    end
    self.TxtLevelInfo.text = string.format("%s/%s", currentLevel, self.SuperTowerRole:GetMaxSuperLevel())
    self.TxtExpCompare.text = string.format("%s/%s", newCurrentExp, nextLevelExp)
    return true
end

function XUiSuperTowerRoleLevelUpPanel:OnBtnGetPluginsClicked()
    local skipIds = {}
    local index = 1
    local skipId = XSuperTowerConfigs.GetClientBaseConfigByKey("GetPluginSkipId" .. index)
    while skipId ~= nil do
        table.insert(skipIds, skipId)
        index = index + 1
        skipId = XSuperTowerConfigs.GetClientBaseConfigByKey("GetPluginSkipId" .. index, true)
    end
    XLuaUiManager.Open("UiSkipTip", skipIds)
end

function XUiSuperTowerRoleLevelUpPanel:OnBtnUpgradeClicked()
    local curLevel = self.SuperTowerRole:GetSuperLevel()
    local usedSuperPluginDic = {}
    local pluginId
    local showTip = false
    local star = XSuperTowerConfigs.GetClientBaseConfigByKey("RoleLevelUpPluginStarLevel") or 5
    for plugin, status in pairs(self.PluginGridSelectStatusDic) do
        if status then
            pluginId = plugin:GetId()
            usedSuperPluginDic[pluginId] = usedSuperPluginDic[pluginId] or 0
            usedSuperPluginDic[pluginId] = usedSuperPluginDic[pluginId] + 1
            if plugin:GetStar() >= star and not showTip then
                showTip = true
            end
        end
    end
    local okCallback = function()
        if XTool.IsTableEmpty(usedSuperPluginDic) then
            XUiManager.TipError(CS.XTextManager.GetText("STRoleLevelUpNotPluginTip"))
            return
        end
        XDataCenter.SuperTowerManager.GetRoleManager():RequestUpgradeCharacter(self.SuperTowerRole:GetCharacterId(), usedSuperPluginDic
        , function()
            if curLevel ~= self.SuperTowerRole:GetSuperLevel() then
                XLuaUiManager.Open("UiSupertowerExpansion", self.SuperTowerRole:GetId(), curLevel, self.SuperTowerRole:GetSuperLevel())
            end
            -- 刷新下页面
            self:Reset()
        end)
    end
    -- 判断是否含有5星以上的插件
    if showTip then
        XLuaUiManager.Open("UiDialog", CS.XTextManager.GetText("TipTitle")
        , CS.XTextManager.GetText("STRoleLevelUpUsePluginTip", star)
        , XUiManager.DialogType.Normal, nil, okCallback)
    else
        okCallback()
    end
end

function XUiSuperTowerRoleLevelUpPanel:ResetBaseInfo()
    -- 超限信息
    local currentExp = self.SuperTowerRole:GetCurrentExp()
    local maxExp = self.SuperTowerRole:GetMaxExp()
    local currentLevel = self.SuperTowerRole:GetSuperLevel()
    local maxLevel = self.SuperTowerRole:GetMaxSuperLevel()
    if currentLevel >= maxLevel then
        currentLevel = maxLevel
        currentExp = maxExp
    end
    self.TxtLevelInfo.text = string.format("%s/%s", currentLevel, maxLevel)
    self.TxtExpCompare.text = string.format("%s/%s", currentExp, maxExp)
    self.ImgExpBar.fillAmount = currentExp / maxExp
    self.TxtAddExp.text = 0
    self.ImgExpAddBar.fillAmount = self.ImgExpBar.fillAmount
    -- 背包插件
    self:RefreshPlugins()
end

function XUiSuperTowerRoleLevelUpPanel:OnBtnAutoSelectClicked()
    for i = AUTO_SELECT_MIN_STAR, AUTO_SELECT_MAX_STAR do
        self:OnBtnTogStarValueChanged(i, true)
    end
end

function XUiSuperTowerRoleLevelUpPanel:AutoSelectPlugin(plugins, isSelect)
    for i, plugin in ipairs(plugins) do
        if not self:HandlePluginClicked(plugin, nil, isSelect, false) then
            break
        end
    end
    local plugin
    for _, grid in pairs(self.DynamicTable:GetGrids()) do
        plugin = grid:GetPlugin()
        grid:SetActiveStatus(self.PluginGridSelectStatusDic[plugin] or false)
    end
end

function XUiSuperTowerRoleLevelUpPanel:GetPluginSelectStatus(plugin)
    if self.PluginGridSelectStatusDic[plugin] == nil then
        self.PluginGridSelectStatusDic[plugin] = false
    end
    return self.PluginGridSelectStatusDic[plugin]
end

return XUiSuperTowerRoleLevelUpPanel