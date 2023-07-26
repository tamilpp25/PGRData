

---@class XUiRestaurantIndent : XLuaUi
local XUiRestaurantIndent = XLuaUiManager.Register(XLuaUi, "UiRestaurantIndent")

local ColorStr = {
    Enough = "#FFFFFF",
    NotEnough = "#FB7272"
}

function XUiRestaurantIndent:OnAwake()
    self:InitCb()
    self:InitUi()
end

function XUiRestaurantIndent:OnStart()
    self:InitView()
end

function XUiRestaurantIndent:InitUi()
    self.GridRewards = {}
    
    local component = self.Transform:Find("SafeAreaContentPane/PanelTitle/Img2/TxtTittle")
    if component then
        self.TxtTitle = component:GetComponent("Text")
    end
end

function XUiRestaurantIndent:InitCb()
    self.BtnClose.CallBack = function()
        self:Close()
    end

    self.BtnWndClose.CallBack = function()
        self:Close()
    end
    
    self.BtnPay.CallBack = function() 
        self:OnBtnPayClick()
    end
    
    self.BtnAccept.CallBack = function() 
        self:OnBtnAcceptClick()
    end
    
end

function XUiRestaurantIndent:InitView()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    
    local info = viewModel:GetTodayOrderInfo()
    if not info then
        self:Close()
        return
    end
    local orderId = info:GetId()
    
    local npcId = XRestaurantConfigs.GetOrderNpcId(orderId)
    self.RImgRole:SetRawImage(XRestaurantConfigs.GetOrderNpcIcon(npcId))
    
    local npcName = XRestaurantConfigs.GetOrderNpcName(npcId)
    self.TxtName.text = npcName
    self.TxtTitle.text = XRestaurantConfigs.GetOrderTitleText(npcName)
    
    self.TxtDetail.text = XRestaurantConfigs.GetOrderDesc(orderId)
    
    local foodInfos = XRestaurantConfigs.GetOrderFoodInfos(orderId)
    
    local disable = false
    self:RefreshTemplateGrids(self.GridFood, foodInfos, self.PanelFood, nil, "GridFood", function(grid, info) 
        local id = info.Id
        local food = viewModel:GetProduct(XRestaurantConfigs.AreaType.FoodArea, id)
        local count = food:GetProperty("_Count")
        if not disable then
            disable = count < info.Count
        end
        local colorStr = disable and ColorStr.NotEnough or ColorStr.Enough
        grid.TxtNeed.text = string.format("<color=%s>%d</color>/%d", colorStr, count, info.Count)
        grid.TxtName.text = XRestaurantConfigs.GetFoodName(id)
        grid.RImgFood:SetRawImage(XRestaurantConfigs.GetFoodIcon(id))
    end)
    local isNoStart, isOnGoing = info:IsNotStart(), info:IsOnGoing()
    self.BtnAccept.gameObject:SetActiveEx(isNoStart)
    self.BtnPay.gameObject:SetActiveEx(isOnGoing)
    self.BtnPay:SetDisable(disable, not disable)
    self.Enough = not disable
    local rewardList = XRewardManager.GetRewardList(XRestaurantConfigs.GetOrderRewardId(orderId))

    for idx, reward in ipairs(rewardList) do
        local grid = self.GridRewards[idx]
        if not grid then
            local ui = idx == 1 and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.ListReward)
            grid = XUiGridCommon.New(self, ui)
            self.GridRewards[idx] = grid
        end
        grid:Refresh(reward)
    end
end

function XUiRestaurantIndent:OnBtnPayClick()
    if not self.Enough then
        return
    end
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local info = viewModel:GetTodayOrderInfo()
    if not info or not info:IsOnGoing() then
        return
    end
    XDataCenter.RestaurantManager.RequestFinishOrder(info:GetId(), function(rewardGoodsList)
        self:Close()

        if not XTool.IsTableEmpty(rewardGoodsList) then
            XUiManager.OpenUiObtain(rewardGoodsList)
        end
    end)
end

function XUiRestaurantIndent:OnBtnAcceptClick()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local info = viewModel:GetTodayOrderInfo()
    if not info or not info:IsNotStart() then
        return
    end
    
    XDataCenter.RestaurantManager.RequestCollectOrder(info:GetId(), function()
        self:Close()
    end)
end