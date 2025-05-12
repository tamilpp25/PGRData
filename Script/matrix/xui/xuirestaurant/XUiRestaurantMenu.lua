local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiGridRestaurantMenu : XUiNode
---@field _Control XRestaurantControl
local XUiGridRestaurantMenu = XClass(XUiNode, "XUiGridRestaurantMenu")

function XUiGridRestaurantMenu:OnStart()
    self.TipAnimation = self.Transform:Find("Animation/TipsEnable")
    if self.TipAnimation then
        self.TipAnimation.gameObject:SetActiveEx(false)
    end
end

function XUiGridRestaurantMenu:RefreshFood(foodId)
    self.Id = foodId
    local food = self._Control:GetProduct(XMVCA.XRestaurant.AreaType.FoodArea, foodId)
    local unlock = food:IsUnlock()
    self.Unlock = unlock
    self.Normal.gameObject:SetActiveEx(unlock)
    self.Disable.gameObject:SetActiveEx(not unlock)
    if not unlock then
        return
    end
    self.RImgIcon:SetRawImage(food:GetProductIcon())
    self.TxtName.text = food:GetName()
    self.ImgQualityBg:SetSprite(food:GetQualityIcon(false))
end

function XUiGridRestaurantMenu:RefreshIndent(indentId)
    self.Id = indentId
    local indent = self._Control:GetPerform(indentId)
    local isLock = indent:IsNotStart()
    self.Unlock = not isLock
    self.PanelOngoing.gameObject:SetActiveEx(indent:IsOnGoing())
    self.PanelComplete.gameObject:SetActiveEx(indent:IsFinish())
    self.PanelLock.gameObject:SetActiveEx(isLock)
    
    self.BtnClick:SetNameByGroup(0, indent:GetPerformTitleWithStory())
    self.BtnClick:SetRawImage(indent:GetPerformIcon())
    self:SetRedPointState(self._Control:CheckPerformRedPoint(indentId))
end

function XUiGridRestaurantMenu:RefreshPerform(performId)
    self:RefreshIndent(performId)
end

function XUiGridRestaurantMenu:IsUnLock()
    return self.Unlock
end

function XUiGridRestaurantMenu:SetRedPointState(state)
    if self.BtnClick then
        self.BtnClick:ShowReddot(state)
    end
end

function XUiGridRestaurantMenu:GetId()
    return self.Id
end

function XUiGridRestaurantMenu:PlayTip()
    if not self.TipAnimation then
        return
    end
    if not self:IsNodeShow() then
        return
    end
    self.TipAnimation.gameObject:SetActiveEx(false)
    self.TipAnimation.gameObject:SetActiveEx(true)
end


---@class XUiRestaurantMenu : XLuaUi 图鉴
---@field PanelGroup XUiButtonGroup
---@field _Control XRestaurantControl
local XUiRestaurantMenu = XLuaUiManager.Register(XLuaUi, "UiRestaurantMenu")

local DefaultTabId = 1 --默认选中页签

local TabIndex = {
    Perform = 1,
    Indent  = 2,
    Food    = 3,
}

local XUiPanelBubbleIngredient = require("XUi/XUiRestaurant/XUiPanel/XUiPanelBubbleIngredient")

function XUiRestaurantMenu:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantMenu:OnStart(tabId, defaultParam)
    self.DefaultTabId = tabId or DefaultTabId
    self.DefaultParam = defaultParam
    self:InitView()
end

function XUiRestaurantMenu:InitUi()
    --Tab
    local tab = {
        self.BtnStory,
        self.BtnIndent,
        self.BtnFood
    }
    local business = self._Control:GetBusiness()
    local menuList = business:GetMenuTabList()
    for i, tabId in ipairs(menuList) do
        local btn = tab[i]
        if btn then
            btn:SetNameByGroup(0, self:GetBtnTabName(tabId))
            local inTime = XFunctionManager.CheckInTimeByTimeId(business:GetTabMenuTimeId(tabId), true)
            btn:SetDisable(not inTime)
            btn:ShowReddot(self:CheckRedPoint(tabId))
        end
    end
    
    self.PanelGroup:Init(tab, function(tabIndex) self:OnSelectTab(tabIndex) end)
    self.MenuList = menuList
    self.TabList = tab
    
    --dynamicTab
    self.DynamicFoodTable = XDynamicTableNormal.New(self.PanelFoodList)
    self.DynamicFoodTable:SetProxy(XUiGridRestaurantMenu, self)
    self.DynamicFoodTable:SetDelegate(self)
    self.DynamicFoodTable:SetDynamicEventDelegate(handler(self, self.OnFoodTableEvent))
    self.GridFoods.gameObject:SetActiveEx(false)

    self.DynamicIndentTable = XDynamicTableNormal.New(self.PanelIndent)
    self.DynamicIndentTable:SetProxy(XUiGridRestaurantMenu, self)
    self.DynamicIndentTable:SetDelegate(self)
    self.DynamicIndentTable:SetDynamicEventDelegate(handler(self, self.OnMessageTableEvent))
    self.GridIndent.gameObject:SetActiveEx(false)
    
    self.DynamicStoryTable = XDynamicTableNormal.New(self.PanelStory)
    self.DynamicStoryTable:SetProxy(XUiGridRestaurantMenu, self)
    self.DynamicStoryTable:SetDelegate(self)
    self.DynamicStoryTable:SetDynamicEventDelegate(handler(self, self.OnStoryTableEvent))
    self.GridStory.gameObject:SetActiveEx(false)
    
    self.PanelBubbleLeft = XUiPanelBubbleIngredient.New(self.PanelLeft, self)
    self.PanelBubbleRight = XUiPanelBubbleIngredient.New(self.PanelRight, self)
    
    self.PanelBubbleLeft:Hide()
    self.PanelBubbleRight:Hide()
end

function XUiRestaurantMenu:InitCb()
    local closeFunc = function() 
        self:CloseIngredientBubble()
        self:Close() 
    end
    
    self.BtnClose.CallBack = closeFunc
    
    self.BtnWndClose.CallBack = closeFunc

    local proxy = self.PanelFoodList.gameObject:AddComponent(typeof(CS.XUguiDragProxy))
    proxy:RegisterHandler(handler(self, self.OnDragProxy))
    
    self:RegisterClickEvent(self.RImgBg, self.CloseIngredientBubble)
end

function XUiRestaurantMenu:InitView()
    self.PanelGroup:SelectIndex(self.DefaultTabId)
end

function XUiRestaurantMenu:OnSelectTab(tabIndex)
    if self.TabIndex == tabIndex then
        return
    end
    local business = self._Control:GetBusiness()
    local tabId = self.MenuList[tabIndex]
    
    local isInTime = XFunctionManager.CheckInTimeByTimeId(business:GetTabMenuTimeId(tabId), true)
    if not isInTime then
        XUiManager.TipMsg(string.format(self._Control:GetCommonUnlockText(1), business:GetMenuTabUnlockTimeStr(tabId)))
        return
    end
    local btn = self.TabList[tabIndex]
    if btn then
        btn:ShowReddot(false)
    end
    self._Control:MarkMenuRedPoint(tabId)
    
    self.TabIndex = tabIndex
    if tabIndex ~= TabIndex.Food then
        self:CloseIngredientBubble()
    end
    self:PlayAnimation("QieHuan")
    self:SetupDynamicTab()
end

function XUiRestaurantMenu:SetupDynamicTab()
    local isPerform = self.TabIndex == TabIndex.Perform
    local isIndent = self.TabIndex == TabIndex.Indent
    local isMenu = self.TabIndex == TabIndex.Food
    self.PanelStory.gameObject:SetActiveEx(isPerform)
    self.PanelIndent.gameObject:SetActiveEx(isIndent)
    self.PanelFoodList.gameObject:SetActiveEx(isMenu)

    local dynamic
    if isPerform then
        self.DataList = self:GetPerformList()
        dynamic = self.DynamicStoryTable
        self._Control:MarkPerformListRedPoint(self.DataList)
    elseif isIndent then
        self.DataList = self:GetIndentList()
        dynamic = self.DynamicIndentTable
        self._Control:MarkPerformListRedPoint(self.DataList)
    else
        self.DataList = self:GetFoodIdList()
        dynamic = self.DynamicFoodTable
    end
    
    dynamic:SetDataSource(self.DataList)
    local startIndex = 1
    if self.DefaultParam then
        startIndex = self:GetGridIndex(self.DefaultParam)
    end
    dynamic:ReloadDataSync(startIndex)
    
end

function XUiRestaurantMenu:OnFoodTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshFood(self.DataList[index])
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:CloseIngredientBubble()
        if not grid:IsUnLock() then
            XUiManager.TipMsg(self._Control:GetCommonUnlockText(3))
            return
        end
        local x = grid.Transform.position.x
        local isLeft = x > 1
        if isLeft then
            self.PanelBubbleLeft:Show(grid.Transform, self.DataList[index], isLeft)
        else
            self.PanelBubbleRight:Show(grid.Transform, self.DataList[index], isLeft)
        end
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlaySelectTip(self.DynamicFoodTable)
        self.DefaultParam = nil
    end
end

function XUiRestaurantMenu:OnMessageTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshIndent(self.DataList[index])
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickPerform(grid)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlaySelectTip(self.DynamicIndentTable)
        self.DefaultParam = nil
    end
end

function XUiRestaurantMenu:OnStoryTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshPerform(self.DataList[index])
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickPerform(grid)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlaySelectTip(self.DynamicStoryTable)
        self.DefaultParam = nil
    end
end

function XUiRestaurantMenu:PlaySelectTip(dynamic)
    if not self.DefaultParam then
        return
    end
    local grids = dynamic:GetGrids()
    local grid = grids[self:GetGridIndex(self.DefaultParam)]
    if not grid then
        return
    end
    grid:PlayTip()
end

function XUiRestaurantMenu:GetGridIndex(param)
    for index, value in ipairs(self.DataList) do
        if value == param then
            return index
        end
    end
    return 1
end

function XUiRestaurantMenu:OnClickPerform(grid)
    if not grid then
        return
    end
    local performId = grid:GetId()
    local perform = self._Control:GetPerform(performId)
    if perform:IsNotStart() then
        XUiManager.TipMsg(perform:GetUnlockConditionDesc())
        return
    end
    grid:SetRedPointState(false)
    self._Control:MarkPerformRedPoint(performId)
    self._Control:OpenPerformUi(performId)
end

function XUiRestaurantMenu:OnFoodScroll()
    self:CloseIngredientBubble()
end

function XUiRestaurantMenu:GetFoodIdList()
    if not self.FoodIdList then
        self.FoodIdList = self._Control:GetAllFoodIds()
    end
    return self.FoodIdList
end

function XUiRestaurantMenu:GetIndentList()
    if not self.IndentList then
        self.IndentList = self._Control:GetAllIndentIds()
    end
    return self.IndentList
end

function XUiRestaurantMenu:GetPerformList()
    if not self.PerformList then
        self.PerformList = self._Control:GetAllPerformIds()
    end
    return self.PerformList
end

function XUiRestaurantMenu:CheckRedPoint(tabId)
    return self._Control:CheckMenuRedPoint(tabId)
end

function XUiRestaurantMenu:CloseIngredientBubble()
    self.PanelBubbleLeft:Hide()
    self.PanelBubbleRight:Hide()
end

function XUiRestaurantMenu:OnDragProxy(int, eventData)
    if int == 0 then
        self:CloseIngredientBubble()
    end
end

function XUiRestaurantMenu:GetBtnTabName(tabId)
    local btnTabName = self._Control:GetBusiness():GetTabMenuName(tabId)
    local unlock, total = 0, 0
    if tabId == TabIndex.Perform then
        unlock = self._Control:GetUnlockPerformCount()
        total = #self:GetPerformList()
    elseif tabId == TabIndex.Indent then
        unlock = self._Control:GetUnlockIndentCount()
        total = #self:GetIndentList()
    else
        unlock = self._Control:GetUnlockProductListCount(XMVCA.XRestaurant.AreaType.FoodArea)
        total = #self:GetFoodIdList()
    end
    return string.format("%s %s/%s", btnTabName, unlock, total)
end