
---@class XUiRestaurantUnlockFood : XLuaUi
---@field _Control XRestaurantControl
local XUiRestaurantUnlockFood = XLuaUiManager.Register(XLuaUi, "UiRestaurantUnlockFood")

function XUiRestaurantUnlockFood:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantUnlockFood:OnStart(rewardGoodsList, onCloseCb)
    self.GoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    self.OnCloseCb = onCloseCb
    self:InitView()
end

function XUiRestaurantUnlockFood:InitUi()
end

function XUiRestaurantUnlockFood:InitCb()
    self.BtnClose.CallBack = function() 
        self:Close()
        if self.OnCloseCb then self.OnCloseCb() end
    end
    
    self.BtnYes.CallBack = function() 
        self:Close()
        if self.OnCloseCb then self.OnCloseCb() end
    end
end

function XUiRestaurantUnlockFood:InitView()
    local isEmpty = XTool.IsTableEmpty(self.GoodsList)
    self.PanelFood.gameObject:SetActiveEx(not isEmpty)
    if isEmpty then
        return
    end
    local goods = self.GoodsList[1]
    local templateId
    if type(goods) == "number" then
        templateId = goods
    else
        templateId = (goods.TemplateId and goods.TemplateId > 0) and goods.TemplateId or goods.Id
    end
    local foodTemplate = self._Control:GetFoodTemplateByItemId(templateId)
    if foodTemplate then
        self.TxtName.text = foodTemplate.Name
        self.RImgIcon:SetRawImage(foodTemplate.Icon)
    else
        local data = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(templateId)
        self.TxtName.text = data.Name
        self.RImgIcon:SetRawImage(data.Icon)
    end
    
end