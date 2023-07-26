--######################## XUiExchangeItem ########################
local XUiExchangeItem = XClass(XSignalData, "XUiExchangeItem")

function XUiExchangeItem:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    -- 重定义 begin
    self.PanelDiscount = self.Sale
    self.TxtDiscount = self.SaleText
    self.RImgIcon = self.CardImg
    self.BtnItemDetail = self.ImgBtn
    self.TxtCostCount = self.CostNum
    self.TxtCurrentCount = self.CurNum
    -- 重定义 end
    self.Data = nil
    self.TargetId = nil
    self.BuyTime = 1
    self:RegisterUiEvents()
end

--[[
    data : {
        TemplateId, -- 物品id
        CostCount,  -- 消耗数量
        Discount,   -- 显示折扣
        CustomIcon, -- 自定义图标
    }
]]
function XUiExchangeItem:SetData(data, targetId, buyTime)
    self.Data = data
    self.TargetId = targetId
    self.BuyTime = buyTime
    -- 折扣
    local showDiscount = data.Discount ~= nil and data.Discount > 0
    self.PanelDiscount.gameObject:SetActiveEx(showDiscount)
    if showDiscount then
        -- todo
        self.TxtDiscount.text = XUiHelper.GetText("BuyAssetDiscountText", data.Discount)
    end
    self.TxtCostCount.text = data.CostCount
    self.TxtCurrentCount.text = XDataCenter.ItemManager.GetCount(data.TemplateId)
    self.RImgIcon:SetRawImage(data.CustomIcon or XEntityHelper.GetItemIcon(data.TemplateId))
end

--######################## 私有方法 ########################

function XUiExchangeItem:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnItemDetail, self.OnBtnItemDetailClicked)
end

function XUiExchangeItem:OnBtnBuyClicked()
    local itemManager = XDataCenter.ItemManager
    -- todo 购买前各种判断
    local currentExchangeData = itemManager.GetBuyAssetInfo(self.TargetId)
    -- 剩余次数不足
    if currentExchangeData.LeftTimes and currentExchangeData.LeftTimes <= 0 then
        XUiManager.TipMsg(XUiHelper.GetText("BuyCountIsNotEnough", itemManager.GetItemName(self.Data.TemplateId))
            , XUiManager.UiTipType.Tip)
        return 
    end
    local item = itemManager.GetItem(self.Data.TemplateId)
    -- 检查是否在限定购买时间内
    if not item:GetIsInBuyTime() then
        XUiManager.TipMsg(XUiHelper.GetText("BuyAssetTimeLimitTip"))
        return
    end
    -- 检查已购买数量是否超过最大购买数量
    if item:CheckIsOverTotalBuyTimes() then
        XUiManager.TipMsg(XUiHelper.GetText("BuyAssetTotalLimitTip"))
        return 
    end
    -- 检查数量
    if not itemManager.CheckItemCountById(self.Data.TemplateId, self.Data.CostCount) then
        local itemName = itemManager.GetItemName(self.Data.TemplateId)
        local itemId = self.Data.TemplateId
        if itemId == itemManager.ItemId.FreeGem or itemId == itemManager.ItemId.PaidGem
            or itemId == itemManager.ItemId.HongKa then
            -- 二次确认
            XUiManager.DialogDragTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("BuyAssetHKNotEnoughTips", itemName), XUiManager.DialogType.Normal, nil
            , function ()
                local skipParams = itemManager.GetItemSkipIdParams(itemId)
                if skipParams then
                    XFunctionManager.SkipInterface(skipParams[1])
                end
            end)
        else
            XUiManager.TipMsg(XUiHelper.GetText("AssetsBuyConsumeNotEnough", itemName), XUiManager.UiTipType.Tip)
        end
        return
    end
    -- 正式开始购买
    local callback = function(targetId, targetCount)
        local name = itemManager.GetItemName(targetId)
        local msg = string.format("%s,%s%s%s%s", XUiHelper.GetText("BuySuccess"), XUiHelper.GetText("Acquire"), targetCount, XUiHelper.GetText("QuantifiersA"), name)
        XUiManager.TipMsg(msg, XUiManager.UiTipType.Tip)
        self:EmitSignal("BuySuccess")
    end
    itemManager.BuyAsset(self.TargetId, callback, nil, self.BuyTime, self.Data.TemplateId)
end

function XUiExchangeItem:OnBtnItemDetailClicked()
    XLuaUiManager.Open("UiTip", self.Data.TemplateId)
end

return XUiExchangeItem