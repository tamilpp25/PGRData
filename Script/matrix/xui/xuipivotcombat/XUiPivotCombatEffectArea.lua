local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--===========================================================================
 ---@desc 供能详情界面
--===========================================================================
local XUiPivotCombatEffectArea = XLuaUiManager.Register(XLuaUi, "UiPivotCombatEffectArea")
local XUiPivotCombatEnergyGrid = require("XUi/XUiPivotCombat/XUiGrid/XUiPivotCombatEnergyGrid")

local TabButtonIndex = {
    Entirety    = 1, --汇总效果
    Secondary   = 2, --次级效果起始位置
}

function XUiPivotCombatEffectArea:OnAwake()
    self:InitUI()
    self:InitCB()
end 

function XUiPivotCombatEffectArea:OnStart(region)
    self.SecondaryRegions = XDataCenter.PivotCombatManager.GetSecondaryRegions()

    self.TabIndexToRegion = {}
    self.RegionIdToTabIndex = {}
    self.EnergyData = {}
    --默认让“汇总展示”按钮放在第一个
    local tabGroup = { self.BtnTab01 }
    local tabGroupIndex = TabButtonIndex.Secondary --页签下标开始位置，1固定为：self.BtnTab01
    for _, tmpRegion in ipairs(self.SecondaryRegions or {}) do
        local btnSecondary = CS.UnityEngine.Object.Instantiate(self.BtnTab01)
        btnSecondary.transform:SetParent(self.PanelButtonGroup.transform, false)
        btnSecondary.gameObject:SetActiveEx(true)
        btnSecondary:SetNameByGroup(0, tmpRegion:GetRegionName())
        local regionId = tmpRegion:GetRegionId()
        self["BtnTabRegion"..regionId] = btnSecondary
        self.TabIndexToRegion[tabGroupIndex] = tmpRegion
        self.RegionIdToTabIndex[regionId] = tabGroupIndex
        table.insert(tabGroup, btnSecondary)
        tabGroupIndex = tabGroupIndex + 1
    end

    self.TabGroup:Init(tabGroup, function(tabIndex)
        self:OnClickTabGroup(tabIndex)
    end)
end

function XUiPivotCombatEffectArea:OnEnable(region)
    self.OriRegion = region
    local selectIndex = TabButtonIndex.Entirety
    --通关次级区域跳转进入
    if  region then
        selectIndex = self.RegionIdToTabIndex[region:GetRegionId()] or TabButtonIndex.Entirety
    end
    
    self.TabGroup:SelectIndex(selectIndex)
end

function XUiPivotCombatEffectArea:OnDisable()
    self.SelectIndex = nil
end


function XUiPivotCombatEffectArea:InitUI()
    self.GridBuff.gameObject:SetActiveEx(false)
    self.TabGroup = self.PanelButtonGroup:GetComponent("XUiButtonGroup")
    
    self:InitDynamicTable()
end 

function XUiPivotCombatEffectArea:InitCB()
    
    self.BtnClose.CallBack = function() 
        self:Close()
    end
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
end 

function XUiPivotCombatEffectArea:OnClickTabGroup(tabIndex)
    if tabIndex == self.SelectIndex then return end
    self.SelectIndex = tabIndex
    self:PlayAnimation("QieHuan", nil, function()
        self:RefreshDynamicTable()
    end)
end 

function XUiPivotCombatEffectArea:RefreshDynamicTable()
    local curEnergyLv = 0
    local maxEnergyLv = 0
    local dataSource = {}
    if self.SelectIndex == TabButtonIndex.Entirety then
        curEnergyLv = XDataCenter.PivotCombatManager.GetSecondaryRegionTotalCurEnergy()
        maxEnergyLv = XDataCenter.PivotCombatManager.GetSecondaryRegionTotalMaxEnergy()
        dataSource = self.SecondaryRegions
    else
        local region = self.TabIndexToRegion[self.SelectIndex]
        if region then
            curEnergyLv = region:GetCurSupplyEnergy()
            maxEnergyLv = region:GetMaxSupplyEnergy()
        end
        for idx = 1, maxEnergyLv do
            dataSource[idx] = region
        end
    end
    self.TextLevelMax.text = "/"..maxEnergyLv
    self.TextLevelNum.text = curEnergyLv
    self.CurEnergyLv = curEnergyLv
    self.MaxEnergyLv = maxEnergyLv
    self.EnergyData = dataSource
    self.DynamicTable:SetDataSource(dataSource)
    self.DynamicTable:ReloadDataSync()
end

function XUiPivotCombatEffectArea:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelBufftList)
    self.DynamicTable:SetProxy(XUiPivotCombatEnergyGrid)
    self.DynamicTable:SetDelegate(self)
end 

function XUiPivotCombatEffectArea:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.OriRegion)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        --是否 “汇总展示”
        local isEntirety = self.SelectIndex == TabButtonIndex.Entirety
        grid:Refresh(isEntirety, self.EnergyData[index], index)
    end
end 

return XUiPivotCombatEffectArea