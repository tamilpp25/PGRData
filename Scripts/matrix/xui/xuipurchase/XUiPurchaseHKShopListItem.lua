local XUiPurchaseHKShopListItem = XClass(nil, "XUiPurchaseHKShopListItem")
local TextManager = CS.XTextManager
local RestTypeConfig
local Next = _G.next

function XUiPurchaseHKShopListItem:Ctor(ui,uiRoot)
    RestTypeConfig = XPurchaseConfigs.RestTypeConfig
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
end

-- 更新数据
function XUiPurchaseHKShopListItem:OnRefresh(itemData)
    if not itemData then
        return
    end
    self.ItemData = itemData
    self:SetData()
end

function XUiPurchaseHKShopListItem:Init(uiRoot,parent)
    self.UiRoot = uiRoot
    self.Parent = parent
end

function XUiPurchaseHKShopListItem:SetData()
    if self.ItemData.Icon then
        local path = XPurchaseConfigs.GetIconPathByIconName(self.ItemData.Icon)
        if path and path.AssetPath then
            self.ImgIconLb:SetRawImage(path.AssetPath)
        end
    end
    self.TxtName.text = self.ItemData.Name

    -- 上架时间
    if self.ItemData.TimeToShelve > 0 then
        self.TxtPutawayTime.gameObject:SetActive(true)
        self.TxtHk.gameObject:SetActive(false)
        self.TxtFree.gameObject:SetActive(false)
        self.TxtQuota.gameObject:SetActive(true)
        self:SetBuyDes()
        return
    end

    -- 达到限购次数
    if self.ItemData.BuyTimes == self.ItemData.BuyLimitTimes then
        self.ImgSellout.gameObject:SetActive(true)
        self.PanelLabel.gameObject:SetActive(false)
        self.TxtFree.gameObject:SetActive(false)
        self.TxtQuota.gameObject:SetActive(false)
        return
    end

    -- 下架时间
    self.TxtPutawayTime.gameObject:SetActive(false)
    if self.ItemData.TimeToUnShelve > 0 then
        self.TxtUnShelveTime.gameObject:SetActive(true)
        self.TxtUnShelveTime.text = TextManager.GetText("PurchaseSetOffTime",XUiHelper.GetTime(self.ItemData.TimeToUnShelve - XTime.GetServerNowTimestamp()))
    else
        self.TxtUnShelveTime.gameObject:SetActive(false)
    end

    self.TxtQuota.gameObject:SetActive(true)
    self:SetBuyDes()

    local consumeCount = self.ItemData.ConsumeCount or 0
    if consumeCount == 0 then -- 免费的
        self.TxtHk.gameObject:SetActive(false)
        self.TxtFree.gameObject:SetActive(true)
        return
    end

    self.TxtFree.gameObject:SetActive(false)
    self.TxtHk.gameObject:SetActive(true)

    self.RawConsumeImage:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.ItemData.ConsumeId))
    self.TxtHk.text = self.ItemData.ConsumeCount or ""
end

function XUiPurchaseHKShopListItem:SetBuyDes()
    local clientResetInfo = self.ItemData.ClientResetInfo or {}
    if Next(clientResetInfo) == nil then
        self.TxtQuota.text = ""
    end
    local textKey = ""
    if clientResetInfo.ResetType == RestTypeConfig.Interval then
        self.TxtQuota.text = TextManager.GetText("PurchaseRestTypeInterval",clientResetInfo.DayCount, self.ItemData.BuyTimes,self.ItemData.BuyLimitTimes)
        return
    elseif clientResetInfo.ResetType == RestTypeConfig.Day then
        textKey = "PurchaseRestTypeDay"
    elseif clientResetInfo.ResetType == RestTypeConfig.Week then
        textKey = "PurchaseRestTypeWeek"
    elseif clientResetInfo.ResetType == RestTypeConfig.Month then
        textKey = "PurchaseRestTypeMonth"
    end
    self.TxtQuota.text = TextManager.GetText(textKey,self.ItemData.BuyTimes,self.ItemData.BuyLimitTimes)
end
return XUiPurchaseHKShopListItem