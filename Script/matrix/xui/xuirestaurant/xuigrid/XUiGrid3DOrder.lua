local XUiGrid3DBase = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DBase")

---@class XUiGrid3DOrder : XUiGrid3DBase
---@field BtnClick XUiComponent.XUiButton
local XUiGrid3DOrder = XClass(XUiGrid3DBase, "XUiGrid3DOrder")

function XUiGrid3DOrder:InitUi()
    --self.BtnClick = self.Transform:GetComponent(typeof(CS.XUiComponent.XUiButton))
end

function XUiGrid3DOrder:InitCb()
    self.BtnClick.CallBack = function() 
        self:OnBtnClick()
    end
end

function XUiGrid3DOrder:OnBtnClick()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local orderInfo = viewModel:GetTodayOrderInfo()
    if not orderInfo or orderInfo:IsFinish() then
        self:Hide()
        return
    end
    
    XDataCenter.RestaurantManager.OpenIndent(orderInfo:GetId(), orderInfo:IsNotStart(), orderInfo:IsOnGoing())
end

function XUiGrid3DOrder:OnRefresh()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    if not viewModel then
        self:Hide()
        return
    end
    local orderInfo = viewModel:GetTodayOrderInfo()
    if not orderInfo or orderInfo:IsFinish() then
        self:Hide()
        return
    end
    local finish = viewModel:CheckOrderFinish()
    local isNotStart = orderInfo:IsNotStart()
    local isOnGoing = orderInfo:IsOnGoing()
    
    self.PanelComplete.gameObject:SetActiveEx(finish)
    self.PanelOnGoing.gameObject:SetActiveEx(isOnGoing and not finish)
    self.PanelNotStart.gameObject:SetActiveEx(isNotStart)
end

return XUiGrid3DOrder