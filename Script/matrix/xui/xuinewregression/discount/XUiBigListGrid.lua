local XUiBigListGridItem = require("XUi/XUiNewRegression/Discount/XUiBigListGridItem")

local RestTypeConfig = XPurchaseConfigs.RestTypeConfig
local LBGetTypeConfig = XPurchaseConfigs.LBGetTypeConfig
local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

local XUiBigListGrid = XClass(nil, "XUiBigListGrid")

function XUiBigListGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.TitleGoPool = {}
    self.ItemPool = {}
    self.ImgTitle.gameObject:SetActiveEx(false)
    self.PanelPropItem.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClick)
    self.CheckBuyFun = function(count, disCountCouponIndex) return self:CheckBuy(count, disCountCouponIndex) end
end

function XUiBigListGrid:Init(rootUi, buyCb)
    self.RootUi = rootUi
    self.BuyCallback = buyCb    --购买成功回调
end

function XUiBigListGrid:Refresh(data)
    self.Data = data
    self:UpdatePanel()
    self:UpdateRewardList()
end

function XUiBigListGrid:UpdateRewardList()
    local data = self.Data

    -- 直接获得的道具
    local listDirData = {}
    local listDayData = {}
    local rewards0 = data.RewardGoodsList or {}
    for _, v in pairs(rewards0) do
        v.LBGetType = LBGetTypeConfig.Direct
        table.insert(listDirData, v)
    end
    -- 每日获得的道具
    local rewards1 = data.DailyRewardGoodsList or {}
    for _, v in pairs(rewards1) do
        v.LBGetType = LBGetTypeConfig.Day
        table.insert(listDayData, v)
    end

    self:ClearPoolObj()

    local index1 = 1
    local index2 = 1

    if not XTool.IsTableEmpty(listDirData) then
        local obj = self:GetTitleGo(index1)
        local textTitle = XUiHelper.TryGetComponent(obj.transform, "Imgsekuai01/TxtTitle", "Text")
        if textTitle then
            textTitle.text = CsXTextManagerGetText("PurchaseDirGet")
        end
        for _,v in pairs(listDirData)do
            local item = self:GetItemObj(index2)
            item:OnRefresh(v)
            index2 = index2 + 1
        end
    end

    if not XTool.IsTableEmpty(listDayData) then
        index1 = index1 + 1
        local obj = self:GetTitleGo(index1)
        local textTitle = XUiHelper.TryGetComponent(obj.transform, "Imgsekuai01/TxtTitle", "Text")
        if textTitle then
            textTitle.text = data.Desc or ""
        end
        for _,v in pairs(listDayData)do
            local item = self:GetItemObj(index2)
            item:OnRefresh(v)
            index2 = index2 + 1
        end
    end
end

function XUiBigListGrid:GetTitleGo(index)
    if self.TitleGoPool[index] then
        self.TitleGoPool[index].gameObject:SetActiveEx(true)
        self.TitleGoPool[index]:SetParent(self.PanelReward)
        return self.TitleGoPool[index]
    end

    local obj = XUiHelper.Instantiate(self.ImgTitle, self.PanelReward)
    obj.gameObject:SetActiveEx(true)
    table.insert(self.TitleGoPool, obj)
    return obj
end

function XUiBigListGrid:GetItemObj(index)
    if self.ItemPool[index] then
        self.ItemPool[index].GameObject:SetActiveEx(true)
        self.ItemPool[index].Transform:SetParent(self.PanelReward)
        return self.ItemPool[index]
    end  

    local itemObj = XUiHelper.Instantiate(self.PanelPropItem, self.PanelReward)
    itemObj.gameObject:SetActiveEx(true)
    local item = XUiBigListGridItem.New(itemObj, self.RootUi)
    table.insert(self.ItemPool, item)
    return item
end

function XUiBigListGrid:ClearPoolObj()
    for _, obj in pairs(self.TitleGoPool) do
        XUiHelper.Destroy(obj.gameObject)
    end
    for _, obj in pairs(self.ItemPool) do
        XUiHelper.Destroy(obj.GameObject)
    end
    self.TitleGoPool = {}
    self.ItemPool = {}
end

function XUiBigListGrid:UpdatePanel()
    local data = self.Data

    --礼包名
    self.TxtItemName.text = data.Name

    --礼包图标
    local assetpath = XPurchaseConfigs.GetIconPathByIconName(data.Icon)
    if assetpath and assetpath.AssetPath then
        self.ImgItemIcon:SetRawImage(assetpath.AssetPath)
    end

    --礼包价格
    local consumeCount = data.ConsumeCount
    self.BtnBuy:SetName(XTool.IsNumberValid(consumeCount) and consumeCount or CsXTextManagerGetText("PurchaseFreeText"))

    --礼包价格的图标
    local consumeId = data.ConsumeId
    local icon = XTool.IsNumberValid(consumeId) and XDataCenter.ItemManager.GetItemIcon(consumeId)
    if icon then
        self.RawImageConsume:SetRawImage(icon)
        self.RawImageConsume.gameObject:SetActiveEx(true)
    else
        self.RawImageConsume.gameObject:SetActiveEx(false)
    end

    if self.Data.PayKeySuffix then --海外修改，直购价格显示
        local key = XPayConfigs.GetProductKey(self.Data.PayKeySuffix)
        local payConfig = XPayConfigs.GetPayTemplate(key)
        self.RawImageConsume.gameObject:SetActiveEx(true)
        local path = CS.XGame.ClientConfig:GetString("PurchaseBuyRiYuanIconPath")
        self.RawImageConsume:SetRawImage(path)
        self.BtnBuy:SetName(payConfig.Amount)
    end

    --礼包限购
    local isSellOut = data.BuyLimitTimes and data.BuyLimitTimes > 0 and data.BuyTimes == data.BuyLimitTimes
    self.TxtPurchaselimit.text = (not isSellOut and data.BuyLimitTimes and data.BuyLimitTimes > 0) and CsXTextManagerGetText("PurchaseLimitBuy", data.BuyTimes, data.BuyLimitTimes) or ""
    self.ImgSellOut.gameObject:SetActiveEx(isSellOut)
    self.BtnBuy.gameObject:SetActiveEx(not isSellOut)
end

function XUiBigListGrid:OnBtnBuyClick()
    local data = self.Data
    local id = data and data.Id
    if not id then
        return
    end

    --免费的礼包不二次弹窗
    if not self.Data.PayKeySuffix then
        local costItemCount = data.ConsumeCount
        if not XTool.IsNumberValid(costItemCount) then
            XDataCenter.PurchaseManager.PurchaseRequest(id, self.BuyCallback)
            return 
        end
    end

    XLuaUiManager.Open("UiPurchaseBuyTips", data, self.CheckBuyFun, self.BuyCallback, nil, XPurchaseConfigs.GetLBUiTypesList())
end

function XUiBigListGrid:CheckBuy(count, disCountCouponIndex)
    local data = self.Data
    count = count or 1
    disCountCouponIndex = disCountCouponIndex or 0

    if data.BuyLimitTimes > 0 and data.BuyTimes == data.BuyLimitTimes then --卖完了，不管。
        XUiManager.TipText("PurchaseLiSellOut")
        return false
    end

    if data.TimeToShelve > 0 and data.TimeToShelve > XTime.GetServerNowTimestamp() then --没有上架
        XUiManager.TipText("PurchaseBuyNotSet")
        return false
    end

    if data.TimeToUnShelve > 0 and data.TimeToUnShelve < XTime.GetServerNowTimestamp() then --下架了
        XUiManager.TipText("PurchaseSettOff")
        return false
    end

    if data.TimeToInvalid > 0 and data.TimeToInvalid < XTime.GetServerNowTimestamp() then --失效了
        XUiManager.TipText("PurchaseSettOff")
        return false
    end

    if data.ConsumeCount > 0 and data.ConvertSwitch <= 0 then -- 礼包内容全部拥有
        XUiManager.TipText("PurchaseRewardAllHaveErrorTips")
        return false
    end

    local consumeCount = data.ConsumeCount
    if disCountCouponIndex and disCountCouponIndex ~= 0 then
        local disCountValue = XDataCenter.PurchaseManager.GetLBCouponDiscountValue(data, disCountCouponIndex)
        consumeCount = math.floor(disCountValue * consumeCount)
    else
        if data.ConvertSwitch and consumeCount > data.ConvertSwitch then -- 已经被服务器计算了抵扣和折扣后的钱
            consumeCount = data.ConvertSwitch
        end

        if XPurchaseConfigs.GetTagType(data.Tag) == XPurchaseConfigs.PurchaseTagType.Discount then -- 计算打折后的钱(普通打折或者选择了打折券)
            local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(data)
            consumeCount = math.floor(disCountValue * consumeCount)
        end
    end

    if consumeCount > 0 and consumeCount > XDataCenter.ItemManager.GetCount(data.ConsumeId) then --钱不够
        local name = XDataCenter.ItemManager.GetItemName(data.ConsumeId) or ""
        local tips = CSXTextManagerGetText("PurchaseBuyKaCountTips", name)
        XUiManager.TipMsg(tips,XUiManager.UiTipType.Wrong)
        if data.ConsumeId == XDataCenter.ItemManager.ItemId.PaidGem then
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK, false)
        elseif data.ConsumeId == XDataCenter.ItemManager.ItemId.HongKa then
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay, false)
        end
        return false
    end

    return true
end

return XUiBigListGrid