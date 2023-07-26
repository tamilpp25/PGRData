local MAX_GUARD_GRID_COUNT = XDoubleTowersConfigs.GetGuardPluginMaxCount()  --守卫插件最大格子数

local XUiDeploySlotGrid = require("XUi/XUiDoubleTowers/Deploy/XUiDeploySlotGrid")
local XUiDeployDynamicGrid = require("XUi/XUiDoubleTowers/Deploy/XUiDeployDynamicGrid")

local XUiGuardDeployPanel = XClass(nil, "XUiGuardDeployPanel")

--动作塔防养成界面角色的布局
function XUiGuardDeployPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.BaseInfo = XDataCenter.DoubleTowersManager.GetBaseInfo()
    self.TeamDb = self.BaseInfo:GetTeamDb()
    self.SlotGrids = {} --插槽格子
    self.CurSelectSlotGrid = nil   --当前选择的插槽
    self.CurSelectPluginGrid = nil  --当前选择的插件
    self.CurSelectSlotIndex = -1 --当前插槽下标
    self.BtnIcon = self.Icon:GetComponent("XUguiEventListener")
    self:AutoAddListener()
    self:InitDynamicTable()
end

function XUiGuardDeployPanel:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelAwarenessSkillDes)
    local callBack = function(grid) self:UpdateSelectPluginGrid(grid) end
    self.DynamicTable:SetProxy(XUiDeployDynamicGrid, callBack)
    self.DynamicTable:SetDelegate(self)
end

function XUiGuardDeployPanel:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnSwitch, self.OnBtnSwitchClick)
    
    if self.BtnIcon then
        self.BtnIcon.OnClick = function() self:OnBtnSwitchClick() end
    end
end

function XUiGuardDeployPanel:Refresh()
    local teamDb = self.TeamDb
    local basePluginLevelId = teamDb:GetGuardBasePluginId()
    --可能未装备插件
    local isPlugin = XTool.IsNumberValid(basePluginLevelId)
    self.Icon.gameObject:SetActiveEx(isPlugin)
    --local bastPluginId = XDoubleTowersConfigs.GetPluginId(basePluginLevelId)
    --基础插件的图标
    if isPlugin then
        local basePluginIcon = teamDb:GetGuardBasePluginIcon()
        self.Icon:SetRawImage(basePluginIcon)
    end
    --基础插件的名字
    self.TxtName.text = isPlugin and XDoubleTowersConfigs.GetPluginLevelName(basePluginLevelId) or ""
    --基础插件的描述
    self.TxtDesc.text = isPlugin and XDoubleTowersConfigs.GetPluginLevelDesc(basePluginLevelId) or ""
    --插槽
    self:UpdateSlot()
    --插件
    self:UpdatePlugin()
end

function XUiGuardDeployPanel:UpdatePlugin()
    self.PluginIdList = XDoubleTowersConfigs.GetDoubleTowerPluginIdList(XDoubleTowersConfigs.ModuleType.Guard)
    self.DynamicTable:SetDataSource(self.PluginIdList)
    self.DynamicTable:ReloadDataASync()
end

function XUiGuardDeployPanel:UpdateSlot()
    local slotGrid
    local maxCount = XDoubleTowersConfigs.GetGuardPluginMaxCount()
    local plugIdList = self.TeamDb:GetGuardPluginList()
    for i = 1, maxCount do
        slotGrid = self.SlotGrids[i]
        if not slotGrid then
            local grid = self["SkillsToStrengthen" .. i]
            slotGrid = XUiDeploySlotGrid.New(grid, i, false, XDoubleTowersConfigs.ModuleType.Guard)
            slotGrid:SetSelectCb(handler(self, self.UpdateSlotSelect))
            slotGrid:SetSlotChangeCb(handler(self, self.SlotChangeCallback))
            self.SlotGrids[i] = slotGrid
        end
        slotGrid:Refresh(plugIdList[i])
        slotGrid.GameObject:SetActiveEx(true)
        if self.CurSelectSlotIndex == -1 and i == 1 then
            self:UpdateSlotSelect(slotGrid)
        end
    end

    for i = maxCount + 1, MAX_GUARD_GRID_COUNT do
        local grid = self["SkillsToStrengthen" .. i]
        if grid then
            grid.gameObject:SetActiveEx(false)
        end
    end
end

--==============================
 ---@desc 插槽选择回调
--==============================
function XUiGuardDeployPanel:UpdateSlotSelect(grid)
    if self.CurSelectSlotGrid then
        self.CurSelectSlotGrid:SetSelect(false)
    end
    if grid then
        grid:SetSelect(true)
        self.CurSelectSlotIndex = grid.Index
    end
    self.CurSelectSlotGrid = grid
end

function XUiGuardDeployPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.PluginIdList[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:UpdateSelectPluginGrid(grid)
    end
end

--选中选择的插件格子，并弹出详情弹窗
--grid为nil清除选中
function XUiGuardDeployPanel:UpdateSelectPluginGrid(grid)
    if self.CurSelectPluginGrid then
        self.CurSelectPluginGrid:SetSelect(false)
    end

    if grid then
        local slotChangeCb = handler(self, self.SlotChangeCallback)
        grid:SetSelect(true)
        XLuaUiManager.Open("UiDoubleTowersSkillDetails", grid:GetPluginId(), slotChangeCb, self.CurSelectSlotIndex)
    end
    self.CurSelectPluginGrid = grid
end

--插槽发生变化回调
function XUiGuardDeployPanel:SlotChangeCallback()
    self:UpdateSelectPluginGrid()
    self:UpdateSlot()
    self:UpdatePlugin()
end

function XUiGuardDeployPanel:OnBtnSwitchClick()
    --选择插件，关闭界面时更新
    RunAsyn(function ()
        XLuaUiManager.Open("UiDoubleTowersChoose", XDoubleTowersConfigs.ModuleType.Guard)
        local signalCode = XLuaUiManager.AwaitSignal("UiDoubleTowersChoose", "Close", self)
        if signalCode ~= XSignalCode.SUCCESS then return end
        self:Refresh()
    end)
end

return XUiGuardDeployPanel