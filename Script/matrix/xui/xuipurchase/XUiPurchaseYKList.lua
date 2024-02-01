local XUiPurchaseYKListItem = XClass(nil, "XUiPurchaseYKListItem")

function XUiPurchaseYKListItem:Ctor(ui, notEnoughCb)
    XUiHelper.InitUiClass(self, ui)
    self.PurchaseManager = XDataCenter.PurchaseManager
    self.PurchasePackage = nil
    self.NotEnoughCb = notEnoughCb
    self.FinishedFunc = nil
    self.YKUiItemConfig = nil
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnBtnHelpClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClicked)
end

-- data : XPurchasePackage
function XUiPurchaseYKListItem:SetData(data, finishedFunc)
    self.PurchasePackage = data
    self.FinishedFunc = finishedFunc
    self.YKUiItemConfig = XPurchaseConfigs.GetPurchasePackageYKUiConfig(data:GetId())
    self.TxtTimeTip.text = XUiHelper.GetText("PurchaseYKTimeTip", data:GetDailyRewardRemainDay())
    self.TxtTimeTip.gameObject:SetActiveEx(data:GetId() == XPurchaseConfigs.YKID)
    self.TxtCountLimit.text = XUiHelper.GetText("PurchaseYKLimitCountTip", data:GetCurrentBuyTime(), data:GetBuyLimitTime())
    local tips = self.YKUiItemConfig.Tips
    self.TxtTip1.text = tips[1]
    self.TxtTip2.text = tips[2]
    self.RImgIcon:SetRawImage(self.YKUiItemConfig.Icon)
    -- 消耗数量和图标
    self.BtnBuy:SetNameByGroup(0, data:GetConsumeCount())
    self.BtnBuy:SetRawImage(XEntityHelper.GetItemIcon(data:GetConsumeId()))
    self.BtnHelp.gameObject:SetActiveEx(not string.IsNilOrEmpty(self.YKUiItemConfig.HelpKey))
end

function XUiPurchaseYKListItem:OnBtnHelpClicked()
    XUiManager.ShowHelpTip(self.YKUiItemConfig.HelpKey)
end

function XUiPurchaseYKListItem:OnBtnBuyClicked()
    local buyFnishedFunc = function()
        if self.PurchasePackage:GetId() == XPurchaseConfigs.YKID then
            -- 设置月卡信息本地缓存
            XDataCenter.PurchaseManager.SetYKLocalCache()
        end    
        if self.FinishedFunc then
            self.FinishedFunc()
        end
    end
    local notEnoughCb = function(_, payCount)
        if self.NotEnoughCb then
            self.NotEnoughCb(XPurchaseConfigs.TabsConfig.Pay, nil, payCount)
        end
    end
    self.PurchaseManager.OpenPurchaseBuyUiByPurchasePackage(self.PurchasePackage, notEnoughCb, nil, buyFnishedFunc)
end

--######################## XUiPurchaseYKList ########################
local XUiPurchaseYKList = XClass(nil, "XUiPurchaseYKList")

function XUiPurchaseYKList:Ctor(ui, uiRoot, notEnoughCb)
    XUiHelper.InitUiClass(self, ui)
    self.NotEnoughCb = notEnoughCb
    self.PurchaseManager = XDataCenter.PurchaseManager
end

function XUiPurchaseYKList:OnRefresh(uiType)
    self:ShowPanel()
    local datas = self.PurchaseManager.GetYKTabPurchasePackages()
    table.sort(datas, function(aData, bData)
        local aWeight = XPurchaseConfigs.GetPurchasePackageYKUiConfig(aData:GetId()).SortWeight
        local bWeight = XPurchaseConfigs.GetPurchasePackageYKUiConfig(bData:GetId()).SortWeight
        return aWeight > bWeight
    end)
    self.PurchaseManager.SetYKContinueBuy()
    -- 月卡列表
    XUiHelper.RefreshCustomizedList(self.PanelContent, self.PanelYKItem, #datas, function(index, child)
        local item = XUiPurchaseYKListItem.New(child, self.NotEnoughCb)
        item:SetData(datas[index], function()
            self:OnRefresh()
        end)
    end)
end

function XUiPurchaseYKList:ShowPanel()
    self.GameObject:SetActiveEx(true)
end

function XUiPurchaseYKList:HidePanel()
    self.GameObject:SetActiveEx(false)
end

return XUiPurchaseYKList