local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiDeploySlotGrid = require("XUi/XUiDoubleTowers/Deploy/XUiDeploySlotGrid")
local XUiDeployDynamicGrid = require("XUi/XUiDoubleTowers/Deploy/XUiDeployDynamicGrid")

local XUiRoleDeployPanel = XClass(nil, "XUiRoleDeployPanel")

local MAX_ROLE_GRID_COUNT = XDoubleTowersConfigs.GetRolePluginMaxCount()   --角色插件最大格子数

--动作塔防养成界面角色的布局
function XUiRoleDeployPanel:Ctor(ui)
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

function XUiRoleDeployPanel:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelAwarenessSkillDes)
    local callBack = function(grid) self:UpdateSelectPluginGrid(grid) end
    self.DynamicTable:SetProxy(XUiDeployDynamicGrid, callBack)
    self.DynamicTable:SetDelegate(self)
end

function XUiRoleDeployPanel:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnSwitch, self.OnBtnSwitchClick)

    if self.BtnIcon then
        self.BtnIcon.OnClick = function() self:OnBtnSwitchClick() end
    end
end

function XUiRoleDeployPanel:Refresh()
    
    local teamDb = self.TeamDb
    local basePluginLevelId = teamDb:GetRoleBasePluginId()
    --是否拥有插件
    local isPlugin = XTool.IsNumberValid(basePluginLevelId)
    self.Icon.gameObject:SetActiveEx(isPlugin)
    self.TxtName.text = isPlugin and XDoubleTowersConfigs.GetPluginLevelName(basePluginLevelId) or ""
    self.TxtDesc.text = isPlugin and XDoubleTowersConfigs.GetPluginLevelDesc(basePluginLevelId) or ""

    if isPlugin then
        local basePluginIcon = teamDb:GetRoleBasePluginIcon()
        self.Icon:SetRawImage(basePluginIcon)
    end

    --插槽
    self:UpdateSlot()
    --插件
    self:UpdatePlugin()
end

function XUiRoleDeployPanel:UpdatePlugin()
    self.PluginIdList = XDoubleTowersConfigs.GetDoubleTowerPluginIdList(XDoubleTowersConfigs.ModuleType.Role)
    self.DynamicTable:SetDataSource(self.PluginIdList)
    self.DynamicTable:ReloadDataASync()
end

function XUiRoleDeployPanel:UpdateSlot()
    local slotGrid
    local maxCount = XDoubleTowersConfigs.GetRolePluginMaxCount()
    local plugIdList = self.TeamDb:GetRolePluginList()
    for i = 1, maxCount do
        slotGrid = self.SlotGrids[i]
        if not slotGrid then
            local grid = self["SkillsToStrengthen" .. i]
            slotGrid = XUiDeploySlotGrid.New(grid, i, false, XDoubleTowersConfigs.ModuleType.Role)
            slotGrid:SetSelectCb(handler(self, self.UpdateSlotSelect))
            slotGrid:SetSlotChangeCb(handler(self, self.SlotChangeCallback))
            self.SlotGrids[i] = slotGrid
        end
        --角色带有默认插件
        slotGrid:Refresh(plugIdList[i])
        slotGrid.GameObject:SetActiveEx(true)
        if self.CurSelectSlotIndex == -1 and i == 1 then
            self:UpdateSlotSelect(slotGrid)
        end
    end

    for i = maxCount + 1, MAX_ROLE_GRID_COUNT do
        local grid = self["SkillsToStrengthen" .. i]
        if grid then
            grid.gameObject:SetActiveEx(false)
        end
    end
end

function XUiRoleDeployPanel:UpdateSlotSelect(grid)
    if self.CurSelectSlotGrid then
        self.CurSelectSlotGrid:SetSelect(false)
    end
    if grid then
        grid:SetSelect(true)
        self.CurSelectSlotIndex = grid.Index
    end
    self.CurSelectSlotGrid = grid
end

function XUiRoleDeployPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.PluginIdList[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:UpdateSelectPluginGrid(grid)
    end
end

--选中选择的插件格子，并弹出详情弹窗
--grid为nil清除选中
function XUiRoleDeployPanel:UpdateSelectPluginGrid(grid)
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
function XUiRoleDeployPanel:SlotChangeCallback()
    self:UpdateSelectPluginGrid()
    self:UpdateSlot()
    self:UpdatePlugin()
end

function XUiRoleDeployPanel:OnBtnSwitchClick()
    RunAsyn(function ()
        XLuaUiManager.Open("UiDoubleTowersChoose", XDoubleTowersConfigs.ModuleType.Role)
        local signalCode = XLuaUiManager.AwaitSignal("UiDoubleTowersChoose", "Close", self)
        if signalCode ~= XSignalCode.SUCCESS then return end
        self:Refresh()
    end)
end

return XUiRoleDeployPanel