
---@class XUiRestaurantUnlockFood : XLuaUi
local XUiRestaurantUnlockFood = XLuaUiManager.Register(XLuaUi, "UiRestaurantUnlockFood")

function XUiRestaurantUnlockFood:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantUnlockFood:OnStart(rewardGoodsList)
    self.GoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    self:InitView()
end

function XUiRestaurantUnlockFood:InitUi()
end

function XUiRestaurantUnlockFood:InitCb()
    self.BtnClose.CallBack = function() 
        self:Close()
    end
    
    self.BtnYes.CallBack = function() 
        self:Close()
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
    --
    local foodTemplate = XRestaurantConfigs.GetFoodTemplateByItemId(templateId)
    if foodTemplate then
        self.TxtName.text = foodTemplate.Name
        self.RImgIcon:SetRawImage(foodTemplate.Icon)
    else
        local data = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(templateId)
        self.TxtName.text = data.Name
        self.RImgIcon:SetRawImage(data.Icon)
    end
    
end