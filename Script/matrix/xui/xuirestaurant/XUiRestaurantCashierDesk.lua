
---@class XUiRestaurantCashierDesk : XLuaUi
local XUiRestaurantCashierDesk = XLuaUiManager.Register(XLuaUi, "UiRestaurantCashierDesk")

function XUiRestaurantCashierDesk:OnAwake()
    self:InitUi()
    self:InitCb()
end 

function XUiRestaurantCashierDesk:OnStart()
    self:InitView()
end

function XUiRestaurantCashierDesk:InitUi()
end 

function XUiRestaurantCashierDesk:InitCb()
    self.BtnClose.CallBack = function() 
        self:Close()
    end

    self.BtnCollect.CallBack = function()
        self:OnBtnCollectClick()
    end
end 

function XUiRestaurantCashierDesk:InitView()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local cashier = viewModel:GetProperty("_Cashier")
    
    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XRestaurantConfigs.ItemId.RestaurantUpgradeCoin))
    
    self:BindViewModelPropertiesToObj(cashier, function(count, limit)
        self.TxtNumber.text = string.format("%s/%s", count, limit)
        local disable = count <= 0
        self.BtnCollect:SetDisable(disable, not disable)
    end, "_Count", "_Limit")
    
    --self.TxtBill.text = viewModel:GetCashierTotalPrice()
    self.TxtBill.transform.parent.gameObject:SetActiveEx(false)
end 

function XUiRestaurantCashierDesk:OnBtnCollectClick()
    XDataCenter.RestaurantManager.RequestCollectCashier(function(rewardGoodsList)
        XLuaUiManager.CloseWithCallback("UiRestaurantCashierDesk", function()
            if not XTool.IsTableEmpty(rewardGoodsList) then
                XUiManager.OpenUiObtain(rewardGoodsList)
            end
        end)
    end)
end 