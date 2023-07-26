

local XUiAreaWarGift = XLuaUiManager.Register(XLuaUi, "UiAreaWarGift")

function XUiAreaWarGift:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiAreaWarGift:OnStart(closeCb)
    self.CloseCb = closeCb
    self:InitView()
end

function XUiAreaWarGift:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiAreaWarGift:InitUi()
    
    self.RewardGoods = {}
    self.TemplateIdMap = {}
    self.ShopIds = XDataCenter.AreaWarManager.GetActivityShopIds()
    
    self.OnUpdateShopData = handler(self, self.UpdateShopData)
    
    self.ConfigList = XAreaWarConfigs.GetRewardData()
    for i in ipairs(self.ConfigList) do
        self["Grid" .. i].gameObject:SetActiveEx(false)
    end
end

function XUiAreaWarGift:InitCb()
    self.BtnClose.CallBack = function() 
        self:Close()
    end
end

function XUiAreaWarGift:InitView()
    local shopOpen = XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.ShopCommon)
    if shopOpen then
        XShopManager.GetShopInfoList(self.ShopIds, self.OnUpdateShopData, XShopManager.ActivityShopType.AreaWar, true)
    else
        self:RefreshReward()
    end
end

function XUiAreaWarGift:RefreshReward()
    for i, data in ipairs(self.ConfigList) do
        local item = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(data.Id)
        if XTool.IsTableEmpty(item) then
            self["Grid" .. i].gameObject:SetActiveEx(false)
            goto continue
        end
        local grid = self.RewardGoods[i]
        if not grid then
            grid = XUiGridCommon.New(self, self["Grid" .. i])
            self.RewardGoods[i] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(data.Id, {ShowReceived = self:CheckIsReceived(data.Id, data.Count)})
        grid:SetCount(data.Count)
        ::continue::
    end
end

function XUiAreaWarGift:UpdateShopData()
    local list = {}
    for _, shopId in pairs(self.ShopIds) do
        list = appendArray(list, XShopManager.GetShopGoodsList(shopId, nil, true))
    end
    for _, data in ipairs(list) do
        if not data or not data.RewardGoods then
            goto continue
        end
        local templateId = data.RewardGoods.TemplateId
        if not self.TemplateIdMap[templateId] then
            self.TemplateIdMap[templateId] = data.TotalBuyTimes * data.RewardGoods.Count
        else
            self.TemplateIdMap[templateId] = self.TemplateIdMap[templateId] + data.TotalBuyTimes * data.RewardGoods.Count
        end
        
        ::continue::
    end
    self:RefreshReward()
end

function XUiAreaWarGift:CheckIsReceived(id, count)
    if not self.TemplateIdMap[id] then
        return false
    end
    return self.TemplateIdMap[id] >= count
end

function XUiAreaWarGift:OnBtnSkipClick()
end