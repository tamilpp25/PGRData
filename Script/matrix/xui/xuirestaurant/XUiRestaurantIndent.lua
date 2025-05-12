local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")


---@class XUiRestaurantIndent : XLuaUi
---@field _Control XRestaurantControl
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
    local indent = self._Control:GetRunningIndent()
    if not indent then
        self:Close()
        return
    end
    
    local icon = indent:GetPerformIcon()
    if not string.IsNilOrEmpty(icon) then
        self.RImgRole:SetRawImage(icon)
    end
    
    local npcName = indent:GetIndentNpcName()
    self.TxtName.text = npcName
    self.TxtTitle.text = indent:GetIndentTitleText()
    
    self.TxtDetail.text = indent:GetDescription()
    
    local foodInfos = indent:GetIndentFoodInfo()
    
    local disable = false
    self:RefreshTemplateGrids(self.GridFood, foodInfos, self.PanelFood, nil, "GridFood", function(grid, info) 
        local id = info.Id
        local food = self._Control:GetProduct(XMVCA.XRestaurant.AreaType.FoodArea, id)
        local count = food:GetCount()
        if not disable then
            disable = count < info.Count
        end
        local colorStr = disable and ColorStr.NotEnough or ColorStr.Enough
        grid.TxtNeed.text = string.format("<color=%s>%d</color>/%d", colorStr, count, info.Count)
        grid.TxtName.text = food:GetName()
        grid.RImgFood:SetRawImage(food:GetProductIcon())
    end)
    local isNoStart, isOnGoing = indent:IsNotStart(), indent:IsOnGoing()
    self.BtnAccept.gameObject:SetActiveEx(isNoStart)
    self.BtnPay.gameObject:SetActiveEx(isOnGoing)
    self.BtnPay:SetDisable(disable, not disable)
    self.Enough = not disable
    local rewardList = XRewardManager.GetRewardList(indent:GetPerformRewardId())

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
    local indent = self._Control:GetRunningIndent()
    if not indent or not indent:IsOnGoing() then
        return
    end

    self._Control:RequestFinishOrder(indent:GetPerformId(), function(rewardGoodsList)
        self:Close()

        if not XTool.IsTableEmpty(rewardGoodsList) then
            XUiManager.OpenUiObtain(rewardGoodsList)
        end
    end)
end

function XUiRestaurantIndent:OnBtnAcceptClick()
    local indent = self._Control:GetRunningIndent()
    if not indent or not indent:IsNotStart() then
        return
    end
    
    self._Control:RequestCollectOrder(indent:GetPerformId(), function() 
        self:Close()
    end)
end