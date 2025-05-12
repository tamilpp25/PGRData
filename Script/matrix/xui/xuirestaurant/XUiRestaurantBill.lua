
---@class XUiRestaurantBill : XLuaUi
---@field _Control XRestaurantControl
local XUiRestaurantBill = XLuaUiManager.Register(XLuaUi, "UiRestaurantBill")

function XUiRestaurantBill:OnAwake()
    self:InitUi()
    self:InitCb()
end 

function XUiRestaurantBill:OnStart()
    self:InitView()
end

function XUiRestaurantBill:OnDestroy()
    self._Control:GetBusiness():ClearBind(self:GetHashCode())
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
    local business = self._Control:GetBusiness()
    local offlineTime = self._Control:GetOfflineTimeNow()
    local hashCode = self:GetHashCode()
    business:BindViewModelPropertyToObj(hashCode, 
            business.Property.OfflineBillUpdateTime, function(settleTime)
        local subTime = math.max(0, offlineTime - settleTime)
        self.TxtMassage.text = business:GetSubTimeTip(subTime)
    end)
    
    business:BindViewModelPropertyToObj(hashCode, 
            business.Property.OfflineBill, function(billCount)
                self.BillCount = billCount
                self.TxtBill.text = math.floor(billCount)
            end)
    
    
    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XMVCA.XRestaurant.ItemId.RestaurantUpgradeCoin))
end 

function XUiRestaurantBill:OnBtnReceiveClick()
    --if self.BillCount <= 0 then
    --    self:Close()
    --    return
    --end
    self._Control:RequestReceiveOfflineBill(function(rewardGoodsList)
        XLuaUiManager.CloseWithCallback("UiRestaurantBill", function()
            if not XTool.IsTableEmpty(rewardGoodsList) then
                XUiManager.OpenUiObtain(rewardGoodsList)
            end
        end)
    end)
end

function XUiRestaurantBill:GetHashCode()
    return self.GameObject:GetHashCode()
end