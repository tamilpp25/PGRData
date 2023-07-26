
local XUiGridMenuFood = XClass(nil, "XUiGridMenuFood")

function XUiGridMenuFood:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridMenuFood:Refresh(foodId)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local food = viewModel:GetProduct(XRestaurantConfigs.AreaType.FoodArea, foodId)
    local unlock = food:IsUnlock()
    self.Unlock = unlock
    self.Normal.gameObject:SetActiveEx(unlock)
    self.Disable.gameObject:SetActiveEx(not unlock)
    if not unlock then
        return
    end
    self.RImgIcon:SetRawImage(food:GetProductIcon())
    self.TxtName.text = food:GetProperty("_Name")
    self.ImgQualityBg:SetSprite(food:GetQualityIcon(false))
end

function XUiGridMenuFood:IsUnLock()
    return self.Unlock
end

local XUiGridMenuMessage = XClass(nil, "XUiGridMenuMessage")

function XUiGridMenuMessage:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

---@param orderInfo XRestaurantOrderInfo
function XUiGridMenuMessage:Refresh(orderInfo)
    local npcId = XRestaurantConfigs.GetOrderNpcId(orderInfo:GetId())
    self.ImgRole:SetRawImage(XRestaurantConfigs.GetOrderNpcIcon(npcId))
    self.TxtMessage.text = XRestaurantConfigs.GetOrderNpcReplay(npcId)
    self.TxtTime.text = orderInfo:GetTimeStr()
end


---@class XUiRestaurantMenu : XLuaUi 图鉴
---@field PanelGroup XUiButtonGroup
local XUiRestaurantMenu = XLuaUiManager.Register(XLuaUi, "UiRestaurantMenu")

local DefaultTabId = 1 --默认选中页签

local TabIndex = {
    Menu    = 1,
    Message = 2,
}

local XUiPanelBubbleIngredient = require("XUi/XUiRestaurant/XUiPanel/XUiPanelBubbleIngredient")

function XUiRestaurantMenu:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantMenu:OnStart(tabId)
    self.DefaultTabId = tabId or DefaultTabId
    self:InitView()
end

function XUiRestaurantMenu:InitUi()
    --Tab
    local tab = {
        self.BtnMenu,
        self.BtnMessage
    }
    local menuList = XRestaurantConfigs.GetMenuTabList()
    for i, tabId in ipairs(menuList) do
        local btn = tab[i]
        if btn then
            btn:SetNameByGroup(0, XRestaurantConfigs.GetMenuTabName(tabId))
            local inTime = XRestaurantConfigs.CheckMenuTabInTime(tabId)
            btn:SetDisable(not inTime)
            btn:ShowReddot(self:CheckRedPoint(tabId))
        end
    end
    
    self.PanelGroup:Init(tab, function(tabIndex) self:OnSelectTab(tabIndex) end)
    self.MenuList = menuList
    self.TabList = tab
    
    --dynamicTab
    self.DynamicFoodTable = XDynamicTableNormal.New(self.PanelFoodList)
    self.DynamicFoodTable:SetProxy(XUiGridMenuFood)
    self.DynamicFoodTable:SetDelegate(self)
    self.DynamicFoodTable:SetDynamicEventDelegate(handler(self, self.OnFoodTableEvent))
    self.GridFoods.gameObject:SetActiveEx(false)

    self.DynamicMessageTable = XDynamicTableNormal.New(self.PanelMessage)
    self.DynamicMessageTable:SetProxy(XUiGridMenuMessage)
    self.DynamicMessageTable:SetDelegate(self)
    self.DynamicMessageTable:SetDynamicEventDelegate(handler(self, self.OnMessageTableEvent))
    self.GridMessage.gameObject:SetActiveEx(false)
    
    ---@type UnityEngine.UI.ScrollRect
    --self.FoodScrollRect = self.PanelFoodList:GetComponent("ScrollRect")
    --if self.FoodScrollRect then
    --    self.FoodScrollRect.onValueChanged:AddListener(handler(self, self.OnFoodScroll))
    --end
    
    self.PanelBubbleLeft = XUiPanelBubbleIngredient.New(self.PanelLeft)
    self.PanelBubbleRight = XUiPanelBubbleIngredient.New(self.PanelRight)
    
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
    local tabId = self.MenuList[tabIndex]
    local isInTime = XRestaurantConfigs.CheckMenuTabInTime(tabId)
    if not isInTime then
        XUiManager.TipMsg(string.format(XRestaurantConfigs.GetCommonUnlockText(1), XRestaurantConfigs.GetMenuTabUnlockTimeStr(tabId)))
        return
    end
    local btn = self.TabList[tabIndex]
    if btn then
        btn:ShowReddot(false)
    end
    XDataCenter.RestaurantManager.MarkMenuRedPoint(tabId)
    
    self.TabIndex = tabIndex
    if tabIndex ~= TabIndex.Menu then
        self:CloseIngredientBubble()
    end
    self:SetupDynamicTab()
end

function XUiRestaurantMenu:SetupDynamicTab()
    
    if TabIndex.Menu == self.TabIndex then
        self.PanelFoodList.gameObject:SetActiveEx(true)
        self.PanelMessage.gameObject:SetActiveEx(false)
        self.DataList = self:GetFoodIdList()
        self.DynamicFoodTable:SetDataSource(self.DataList)
        self.DynamicFoodTable:ReloadDataSync()
    elseif TabIndex.Message == self.TabIndex then
        self.PanelFoodList.gameObject:SetActiveEx(false)
        self.PanelMessage.gameObject:SetActiveEx(true)
        self.DataList = self:GetMessageList()
        self.ImgMsgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.DataList))
        self.DynamicMessageTable:SetDataSource(self.DataList)
        self.DynamicMessageTable:ReloadDataSync()
    end
end

function XUiRestaurantMenu:OnFoodTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:CloseIngredientBubble()
        if not grid:IsUnLock() then
            XUiManager.TipMsg(XRestaurantConfigs.GetCommonUnlockText(3))
            return
        end
        --XDataCenter.RestaurantManager.OpenIngredientBubble(grid.Transform, self.DataList[index])
        local x = grid.Transform.position.x
        local isLeft = x > 1
        if isLeft then
            self.PanelBubbleLeft:Show(grid.Transform, self.DataList[index], isLeft)
        else
            self.PanelBubbleRight:Show(grid.Transform, self.DataList[index], isLeft)
        end
    end
end

function XUiRestaurantMenu:OnMessageTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    end
end

function XUiRestaurantMenu:OnFoodScroll()
    self:CloseIngredientBubble()
end

function XUiRestaurantMenu:GetFoodIdList()
    if self.FoodIdList then
        return self.FoodIdList
    end
    self.FoodIdList = XRestaurantConfigs.GetFoodIdList()
    return self.FoodIdList
end

function XUiRestaurantMenu:GetMessageList()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    return viewModel:GetUnlockOrderInfoList()
end

function XUiRestaurantMenu:CheckRedPoint(tabId)
    return XDataCenter.RestaurantManager.CheckMenuRedPoint(tabId)
end

function XUiRestaurantMenu:CloseIngredientBubble()
    --XLuaUiManager.SafeClose("UiRestaurantBubbleNeedFood")
    self.PanelBubbleLeft:Hide()
    self.PanelBubbleRight:Hide()
end

function XUiRestaurantMenu:OnDragProxy(int, eventData)
    if int == 0 then
        self:CloseIngredientBubble()
    end
end