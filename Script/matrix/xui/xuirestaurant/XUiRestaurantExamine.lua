
---@class XUiRestaurantExamine : XLuaUi
---@field PanelGroup XUiButtonGroup
local XUiRestaurantExamine = XLuaUiManager.Register(XLuaUi, "UiRestaurantExamine")

local XUiGridStatistics = require("XUi/XUiRestaurant/XUiGrid/XUiGridStatistics")

local TabIndex2AreaType = { XRestaurantConfigs.AreaType.FoodArea, XRestaurantConfigs.AreaType.IngredientArea }

function XUiRestaurantExamine:OnAwake()
    self:InitUi()
    self:InitCb()
end 

function XUiRestaurantExamine:OnStart(areaType, firstProductId)
    self.DefaultIndex = self:GetSelectIndexByType(areaType)
    self.FirstProductId = firstProductId
    
    self:InitView()
end

function XUiRestaurantExamine:InitUi()
    local tab = {
        self.BtnFood,
        self.BtnIngredient,
    }
    self.PanelGroup:Init(tab, function(index) self:OnSelect(index) end)
    
    self.DynamicTable = XDynamicTableNormal.New(self.PanelFoodList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridStatistics)
    self.GridFoods.gameObject:SetActiveEx(false)
    
    self.IsShowBubble = false
    self.BubbleFormula.gameObject:SetActiveEx(self.IsShowBubble)
end 

function XUiRestaurantExamine:OnSelect(index)
    if self.TabIndex == index then
        return
    end
    self:PlayAnimation("QieHuan")
    self.TabIndex = index
    self:RefreshTip()
    self:RefreshView()
end

function XUiRestaurantExamine:InitCb()
    self.BtnClose.CallBack = function() 
        self:Close()
    end

    self.BtnWndClose.CallBack = function()
        self:Close()
    end
    
    self.BtnHelp.CallBack = function() 
        self:OnBtnHelpClick()
    end
end 

function XUiRestaurantExamine:InitView()
    self.PanelGroup:SelectIndex(self.DefaultIndex)
end 

function XUiRestaurantExamine:RefreshView()
    if not XTool.IsNumberValid(self.TabIndex) then
        self:SetupDynamicTable({})
        return
    end
    
    local areaType = TabIndex2AreaType[self.TabIndex]
    if not areaType then
        self:SetupDynamicTable({})
        return
    end
    self.AreaType = areaType
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local list = viewModel:GetUnlockProductList(areaType)
    if XTool.IsNumberValid(self.FirstProductId) then
        table.sort(list, function(a, b) 
            local idA = a:GetProperty("_Id")
            local idB = b:GetProperty("_Id")
            
            local isA = idA == self.FirstProductId
            local isB = idB == self.FirstProductId

            if isA ~= isB then
                return isA
            end
            return idA < idB
        end)
    end
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(list))
    self:SetupDynamicTable(list)
end

function XUiRestaurantExamine:SetupDynamicTable(list)
    self.DataList = list
    self.DynamicTable:SetDataSource(list)
    self.DynamicTable:ReloadDataASync()
end

function XUiRestaurantExamine:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index], self.AreaType)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if XTool.IsNumberValid(self.FirstProductId) and not self.ShowHighlight then
            self.ShowHighlight = true
            --排序会将放到第一位
            local grid = self.DynamicTable:GetGridByIndex(1)
            grid:ShowEffect()
        end
    end
end 

function XUiRestaurantExamine:GetSelectIndexByType(areaType)
    local defaultIndex = 1
    if not XTool.IsNumberValid(areaType) then
        return defaultIndex
    end
    for idx, type in pairs(TabIndex2AreaType) do
        if type == areaType then
            return idx
        end
    end
    return defaultIndex
end 

function XUiRestaurantExamine:OnBtnHelpClick()
    self.IsShowBubble = not self.IsShowBubble
    self.BubbleFormula.gameObject:SetActiveEx(self.IsShowBubble)
    if not self.IsShowBubble then
        return
    end
    self:RefreshTip()
end

function XUiRestaurantExamine:RefreshTip()
    if not self.IsShowBubble then
        return
    end
    local areaType = TabIndex2AreaType[self.TabIndex]
    local txt1 = XRestaurantConfigs.GetStatisticsTip(areaType, 1)
    local txt2 = XRestaurantConfigs.GetStatisticsTip(areaType, 2)
    local txt3 = XRestaurantConfigs.GetStatisticsTip(areaType, 3)

    self.TxtProduce.text = txt1
    self.TxtConsume.text = txt2
    self.TxtResult.text = txt3
    self.TxtResultDetail.text = txt3
end