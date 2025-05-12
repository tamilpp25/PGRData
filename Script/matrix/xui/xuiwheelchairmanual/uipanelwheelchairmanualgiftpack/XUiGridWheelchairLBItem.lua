local XUiPurchaseLBListItem = require("XUi/XUiPurchase/XUiPurchaseLBListItem")

local XUiGridWheelchairLBItem = XClass(XUiPurchaseLBListItem, 'XUiGridWheelchairLBItem')
local ReddotIdMartix = XMath.ToMinInt(math.pow(2, 32)) -- 红点Id的位数计算（与服务端对应，long，前四位记录类型，后四位则是任意类型配置的Id）

function XUiGridWheelchairLBItem:PlayAnimation(animeName, finCb, beginCb)
    if XTool.UObjIsNil(self.Transform) then
        return
    end

    local animRoot = self.Transform:Find("Animation")
    if XTool.UObjIsNil(animRoot) then
        return
    end

    local animTrans = animRoot:FindTransform(animeName)
    if not animTrans or not animTrans.gameObject.activeInHierarchy then
        return
    end
    if beginCb then
        beginCb()
    end
    animTrans:PlayTimelineAnimation(finCb)
end

function XUiGridWheelchairLBItem:SetRootCanvasGroupAlpha(alpha)
    if self.CanvasGroup then
        self.CanvasGroup.alpha = alpha
    end
end

-- 更新数据
---@overload
function XUiGridWheelchairLBItem:OnRefresh(itemData)
    self.Super.OnRefresh(self, itemData)
    self:RefreshReddot()
end

function XUiGridWheelchairLBItem:RefreshReddot()
    local consumeCount = self.ItemData.ConsumeCount or 0
    self.RedPoint.gameObject:SetActive(false)
    local nowTime = XTime.GetServerNowTimestamp()
    
    -- 免费的蓝点
    if consumeCount == 0 then -- 免费的
        local isShowRedPoint = (self.ItemData.BuyTimes == 0 or self.ItemData.BuyTimes < self.ItemData.BuyLimitTimes) and not XDataCenter.PurchaseManager.IsLBLock(self.ItemData)
                and (self.ItemData.TimeToShelve == 0 or self.ItemData.TimeToShelve < nowTime)
                and (self.ItemData.TimeToUnShelve == 0 or self.ItemData.TimeToUnShelve > nowTime)
        self.RedPoint.gameObject:SetActive(isShowRedPoint)
    end
    
    -- 首次解锁的蓝点
    if not XDataCenter.PurchaseManager.IsLBLock(self.ItemData) then
        local id = XEnumConst.WheelchairManual.TabType.Gift * ReddotIdMartix + self.ItemData.Id

        if XMVCA.XWheelchairManual:CheckNewUnlockReddotIsShow(id) then
            self.RedPoint.gameObject:SetActive(true)
        end
    end
end

function XUiGridWheelchairLBItem:OnTouched()
    if not XDataCenter.PurchaseManager.IsLBLock(self.ItemData) then
        local id = XEnumConst.WheelchairManual.TabType.Gift * ReddotIdMartix + self.ItemData.Id

        if XMVCA.XWheelchairManual:SetNewUnlockReddotIsOld(id) then
            self:RefreshReddot()
            XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_TABS_REDDOT)
        end
    end
end

return XUiGridWheelchairLBItem