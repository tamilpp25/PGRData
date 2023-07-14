local Base = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
local COST_MAX_NUM = 9
--=====================
--爬塔掉落页面详细信息面板
--=====================
local XUiStCpPluginListPanel = XClass(Base, "XUiStCpPluginListPanel")

--=====================
--插件排序方法
--=====================
local SortPlugin = function(dataA, dataB)
    --先比较插件品质
    local qualityA = dataA.Plugin:GetQuality()
    local qualityB = dataB.Plugin:GetQuality()
    if qualityA ~= qualityB then
        return qualityA > qualityB
    end
    --再比较适合的角色战力
    if dataA.AbilityIndex ~= dataB.AbilityIndex then
        return dataA.AbilityIndex > dataB.AbilityIndex
    end
    --最后比较排序配置
    return dataA.Plugin:GetPriority() < dataB.Plugin:GetPriority()
    end
function XUiStCpPluginListPanel:InitPanel()
    COST_MAX_NUM = XSuperTowerConfigs.GetBaseConfigByKey("MaxTeamPluginCount")
    self:InitDynamicTable()
end

function XUiStCpPluginListPanel:InitDynamicTable()
    local GridProxy = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(GridProxy)
    self.DynamicTable:SetDelegate(self)
end

--=============
--动态列表事件
--=============
function XUiStCpPluginListPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, function(pluginGrid) self:OnGridClick(pluginGrid) end)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.DataList and self.DataList[index] then
            grid:RefreshData(self.DataList[index].Plugin, index)
            if self.DataList[index].IsCost then
                grid:SetFloorLock(true)
                grid:SetLockText(CS.XTextManager.GetText("STPcLockText"))
            else
                grid:SetFloorLock(false)
            end
            if self.SelectIndex[index] then
                grid:SetSelectStatus(true)
            else
                grid:SetSelectStatus(false)
            end
        end
    end
end
--==================
--设置选择列表
--==================
function XUiStCpPluginListPanel:SetList()
    --获取背包的所有插件列表
    local bagPluginList = XDataCenter.SuperTowerManager.GetBagManager():GetPlugins(true)
    local havePlugin = next(bagPluginList) ~= nil
    self.PanelNoPlugin.gameObject:SetActiveEx(not havePlugin)
    self.DataList = {}--最终的插件数据列表
    if havePlugin then
        local targetStage = XDataCenter.SuperTowerManager.GetTargetStageByStageId(self.RootUi.StageId)
        --获取目标关卡的所有关卡
        local stageIds = targetStage:GetStageId()
        --获取所有现在要调整的队伍以外的所有其他队伍
        local teams = {}
        for index, stageId in pairs(stageIds) do
            --若StageId不是当前队伍所属的关卡即为其他队伍
            if stageId ~= self.RootUi.StageId then
                teams[index] = XDataCenter.SuperTowerManager.GetTeamByStageId(stageId)
            end
        end
        --创建选择其他队的装备插件槽汇总对象
        local script = require("XEntity/XSuperTower/XSuperTowerPluginSlotManager")
        local costTotalSlot = script.New()
        --设置插件槽的总容量
        costTotalSlot:SetMaxCapacity(COST_MAX_NUM * #stageIds)
        --把其他队的装备插件汇总
        for _, team in pairs(teams) do
            costTotalSlot:AddSlot(team:GetExtraData())
        end
        --获取合并后的消耗插件列表
        local costPluginList = costTotalSlot:GetPluginsNotSplit()
        --生成后面比照用的消耗插件字典
        local costCountDic = {}
        for _, costPlugin in pairs(costPluginList) do
            costCountDic[costPlugin:GetId()] = costPlugin:GetCount()
        end
        --获取角色ID对应的战力排行顺序字典(战力越高越大)
        local roleDic = self:GetCurrentTeamRoleDic()
        for _, plugin in pairs(bagPluginList) do
            --遍历背包所有插件列表，对照消耗插件字典，标记被消耗的插件
            local costCount = costCountDic[plugin:GetId()]
            local charaId = plugin:GetCharacterId()
            local data = {
                Plugin = plugin,
                IsCost = costCount and costCount > 0 or false,
                AbilityIndex = ((not charaId or charaId == 0) and 0) or roleDic[charaId] or 0--根据当前队伍角色的战力排序对应插件
            }
            if data.IsCost then costCountDic[plugin:GetId()] = costCount - 1 end
            table.insert(self.DataList, data)
        end
        table.sort(self.DataList, SortPlugin)
    end
    --初始化当前队伍已经装备的插件状态
    self:InitSelectIndex()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end
--===============
--根据当前队伍获取角色ID对应的战力排行顺序字典(战力越高越大)
--===============
function XUiStCpPluginListPanel:GetCurrentTeamRoleDic()
    --获取当前队伍，用于后面排序操作
    local currentTeam = XDataCenter.SuperTowerManager.GetTeamByStageId(self.RootUi.StageId)
    --队伍角色列表(按战力从小到大排列，无上阵的视为战力最小)
    local teamRoles = {}
    for _, entityId in pairs(currentTeam:GetEntityIds()) do
        if entityId > 0 then
            local role = XDataCenter.SuperTowerManager.GetRoleManager():GetRole(entityId)
            table.insert(teamRoles, role)
        else
            table.insert(teamRoles, 0)
        end
    end
    --按战力排序
    table.sort(teamRoles, function(roleA, roleB)
            if roleA == 0 then
                return true
            end
            if roleB == 0 then
                return false
            end
            return roleA:GetCharacterViewModel():GetAbility() < roleB:GetCharacterViewModel():GetAbility()
        end)
    local roleDic = {}
    for index, role in pairs(teamRoles) do
        if role ~= 0 then
            roleDic[role:GetCharacterId()] = index
        end
    end
    return roleDic
end
--===============
--初始化当前队伍已经装备的插件状态
--===============
function XUiStCpPluginListPanel:InitSelectIndex()
    self.SelectIndex = {}
    local team = XDataCenter.SuperTowerManager.GetTeamByStageId(self.RootUi.StageId)
    --获取当前队伍以及装备的合并插件列表
    local teamPlugins = team:GetExtraData():GetPluginsNotSplit()
    for _, teamPlugin in pairs(teamPlugins) do
        for index, plugin in ipairs(self.DataList or {}) do
            if not plugin.IsCost and teamPlugin:GetId() == plugin.Plugin:GetId() and teamPlugin:GetCount() > 0 then
                if not self.SelectIndex[index] then
                    self.SelectIndex[index] = true
                    teamPlugin:UpdateCount(teamPlugin:GetCount() - 1)
                end
            end
        end
    end
end

function XUiStCpPluginListPanel:OnShowPanel()
    self:SetList()
    for index, plugin in ipairs(self.DataList or {}) do
        if self.SelectIndex[index] then
            self.RootUi:EquipPlugin(index, plugin.Plugin)
        end
    end
end

function XUiStCpPluginListPanel:OnGridClick(pluginGrid)
    if pluginGrid.IsLock or pluginGrid.IsSelect then return end
    self.EquipGrid = pluginGrid
    self.EquipGrid:SetActiveStatus(true)
    XLuaUiManager.Open("UiSuperTowerPluginDetails",
        self.EquipGrid.Plugin, 0,
        function()
            if not XTool.UObjIsNil(self.Transform) then
                self.EquipGrid:SetActiveStatus(false)
                self.EquipGrid = nil
            end
        end, true,
        function()
            self:OnEquip()
        end)
end

function XUiStCpPluginListPanel:OnEquip()
    local count = 0
    for _, isSelect in pairs(self.SelectIndex) do
        if isSelect then
            count = count + 1
        end
    end
    if count >= COST_MAX_NUM then
        XUiManager.TipMsg(CS.XTextManager.GetText("STCostPluginNumberOver"))
        return
    end
    self.EquipGrid:SetSelectStatus(true)
    self.SelectIndex[self.EquipGrid.Index] = true
    self.RootUi:EquipPlugin(self.EquipGrid.Index, self.EquipGrid.Plugin)
end

function XUiStCpPluginListPanel:OnUnEquip(gridIndex)
    local grid = self.DynamicTable:GetGridByIndex(gridIndex)
    if grid then
        grid:SetSelectStatus(false)
    end
    self.SelectIndex[gridIndex] = false
end

return XUiStCpPluginListPanel