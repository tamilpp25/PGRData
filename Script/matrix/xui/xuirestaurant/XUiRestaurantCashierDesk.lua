
---@class XUiRestaurantCashierDesk : XLuaUi
---@field _Control XRestaurantControl
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
    local cashier = self._Control:GetCashier()
    
    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XMVCA.XRestaurant.ItemId.RestaurantUpgradeCoin))
    local count, limit = cashier:GetCount(), cashier:GetLimit()
    self.TxtNumber.text = string.format("%s/%s", count, limit)
    local disable = count <= 0
    self.BtnCollect:SetDisable(disable, not disable)
    self.TxtBill.transform.parent.gameObject:SetActiveEx(false)
end 

function XUiRestaurantCashierDesk:OnBtnCollectClick()
    self._Control:RequestCollectCashier(function(rewardGoodsList) 
        local callback = function()
            if not XTool.IsTableEmpty(rewardGoodsList) then
                XUiManager.OpenUiObtain(rewardGoodsList)
            end
        end
        XLuaUiManager.CloseWithCallback("UiRestaurantCashierDesk", callback)
    end)
end 