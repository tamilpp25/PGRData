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
    if self.Data.TemplateId and self.Data.TemplateId == 3 then --这里的3是指黑卡
        self:ShowSpecialRegulationForJP() --日服特定商吸引法弹窗链接显示
    end
end

--######################## 私有方法 ########################

function XUiExchangeItem:ShowSpecialRegulationForJP() --海外修改
    local isShow = CS.XGame.ClientConfig:GetInt("ShowRegulationEnable")
    if isShow and isShow == 1 then
        local url = CS.XGame.ClientConfig:GetString("RegulationPrefabUrl")
        if url then
            local obj = self.CardImg.transform:LoadPrefab(url)
            local data = {type = 1,consumeId = 3}
            self.ShowSpecialRegBtn = obj.transform:GetComponent("XHtmlText")
            self.ShowSpecialRegBtn.text = CSXTextManagerGetText("JPBusinessLawsDetailsEnter")
            self.ShowSpecialRegBtn.HrefUnderLineColor = CS.UnityEngine.Color(1, 45 / 255, 45 / 255, 1)
            self.ShowSpecialRegBtn.transform.localPosition = CS.UnityEngine.Vector3(132, -86, 0)
            self.ShowSpecialRegBtn.fontSize = 30
            self.ShowSpecialRegBtn.HrefListener = function(link)
                XLuaUiManager.Open("UiSpecialRegulationShow",data)
            end
        end
    end
end

function XUiExchangeItem:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnItemDetail, self.OnBtnItemDetailClicked)
end

function XUiExchangeItem:OnBtnBuyClicked()
    -- if self.Data.TemplateId and self.Data.TemplateId ~= 3 then --这里的3是指黑卡
    --     XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.LB, nil, 1)
    --     return
    -- end
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
            -- BuyAssetHKNotEnoughTipsEN 
            local textKey = "BuyAssetHKNotEnoughTips"
            if itemId == itemManager.ItemId.HongKa then
                textKey = "BuyAssetHKNotEnoughTipsEN"
            end
            XUiManager.DialogDragTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText(textKey, itemName), XUiManager.DialogType.Normal, nil
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
        local msg = string.format("%s %s", name, XUiHelper.GetText("BuySuccess"))
        XUiManager.TipMsg(msg, XUiManager.UiTipType.Tip)
        self:EmitSignal("BuySuccess")
    end
    itemManager.BuyAsset(self.TargetId, callback, nil, self.BuyTime, self.Data.TemplateId)
end

function XUiExchangeItem:OnBtnItemDetailClicked()
    -- if self.Data.TemplateId and self.Data.TemplateId == 3 then --这里的3是指黑卡
        XLuaUiManager.Open("UiTip", self.Data.TemplateId)
    -- else
    --     XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.LB, nil, 1)
    -- end
end

return XUiExchangeItem