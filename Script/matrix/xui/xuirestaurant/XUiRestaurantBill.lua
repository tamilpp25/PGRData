
---@class XUiRestaurantBill : XLuaUi
local XUiRestaurantBill = XLuaUiManager.Register(XLuaUi, "UiRestaurantBill")

function XUiRestaurantBill:OnAwake()
    self:InitUi()
    self:InitCb()
end 

function XUiRestaurantBill:OnStart()
    self:InitView()
end

function XUiRestaurantBill:InitUi()
    self.BtnReceive.gameObject:SetActiveEx(false)
end 

function XUiRestaurantBill:InitCb()
    self.BtnClose.CallBack = function() 
        self:OnBtnReceiveClick()
    end
    
    self.BtnReceive.CallBack = function() 
        self:OnBtnReceiveClick()
    end
end 

function XUiRestaurantBill:InitView()
    
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    
    self:BindViewModelPropertyToObj(viewModel, function(settleTime) 
        local timeNow = XTime.GetServerNowTimestamp()
        local subTime = timeNow - settleTime
        local tip = XRestaurantConfigs.GetClientConfig("OfflineBillText", 1)
        tip = string.format(tip, XUiHelper.GetTime(subTime, XUiHelper.TimeFormatType.DAILY_TASK))
        self.TxtMassage.text = tip
    end, "_OfflineBillUpdateTime")
    
    self:BindViewModelPropertyToObj(viewModel, function(billCount)
        self.BillCount = billCount
        self.TxtBill.text = billCount
    end, "_OfflineBill")
    
    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XRestaurantConfigs.ItemId.RestaurantUpgradeCoin))
end 

function XUiRestaurantBill:OnBtnReceiveClick()
    --if self.BillCount <= 0 then
    --    self:Close()
    --    return
    --end
    XDataCenter.RestaurantManager.RequestReceiveOfflineBill( function(rewardGoodsList) 
        XLuaUiManager.CloseWithCallback("UiRestaurantBill", function()
            if not XTool.IsTableEmpty(rewardGoodsList) then
                XUiManager.OpenUiObtain(rewardGoodsList)
            end
        end)
    end)
end