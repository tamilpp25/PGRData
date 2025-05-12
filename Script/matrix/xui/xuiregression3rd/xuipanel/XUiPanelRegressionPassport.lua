local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridRegressionPassport = require("XUi/XUiRegression3rd/XUiGrid/XUiGridRegressionPassport")
local XUiPanelRegressionBase = require("XUi/XUiRegression3rd/XUiPanel/XUiPanelRegressionBase")

local XUiPanelRegressionPassport = XClass(XUiPanelRegressionBase, "XUiPanelRegressionPassport")

local PassportTypeIndex = {
    Normal = 1,
    Special = 2
}

local OneMinSeconds = 60

--region   ------------------重写父类方法 start-------------------
function XUiPanelRegressionPassport:OnEnable()
    self:RefreshView()
end

function XUiPanelRegressionPassport:Show()
    self:Open()
end

function XUiPanelRegressionPassport:Hide()
    self:Close()
end

function XUiPanelRegressionPassport:InitUi()
    self.PassportViewModel = self.ViewModel:GetPassportViewModel()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskDailyList)
    self.DynamicTable:SetProxy(XUiGridRegressionPassport, self.RootUi, self.PassportViewModel)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
    
    self:AddRedPointEvent(self.BtnReceiveAll, self.OnCheckBtnRedPoint, self, { XRedPointConditions.Types.CONDITION_REGRESSION3_PASSPORT })
end

function XUiPanelRegressionPassport:InitCb()
    self.BtnPay.CallBack = function() 
        self:OnBtnPayClick()
    end

    self.BtnReceiveAll.CallBack = function()
        self:OnReceiveAllClick()
    end

    self.BtnSpPreview.CallBack = function()
        local typeInfos = self.PassportViewModel:GetPassportTypeInfos()
        local rewardId = typeInfos[PassportTypeIndex.Special].PreviewRewardId
        self:OnBtnPreviewClick(rewardId, typeInfos[PassportTypeIndex.Special].Name)
    end

    self.BtnNrPreview.CallBack = function()
        local typeInfos = self.PassportViewModel:GetPassportTypeInfos()
        local rewardId = typeInfos[PassportTypeIndex.Normal].PreviewRewardId
        self:OnBtnPreviewClick(rewardId, typeInfos[PassportTypeIndex.Normal].Name)
    end
end

function XUiPanelRegressionPassport:UpdateTime()
    self.TxtTime.text = self.ViewModel:GetLeftTimeDescWithoutPrefix("236877", nil)
end

--endregion------------------重写父类方法 finish------------------

function XUiPanelRegressionPassport:RefreshView()
    if not XDataCenter.Regression3rdManager.CheckPassportLocalRedPointData() then
        XDataCenter.Regression3rdManager.MarkPassportLocalRedPointData()
    end
    self:UpdateTime()
    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XRegression3rdConfigs.Regression3rdCoinId))
    
    local passportViewModel = self.PassportViewModel
    local typeInfos = self.PassportViewModel:GetPassportTypeInfos()
    self.BtnNrPreview:SetNameByGroup(0, typeInfos[PassportTypeIndex.Normal].Name)
    self.BtnSpPreview:SetNameByGroup(0, typeInfos[PassportTypeIndex.Special].Name)


    --支付按钮
    local payTypeInfo = passportViewModel:GetPayPassportTypeInfo()
    local hasInfo = not XTool.IsTableEmpty(payTypeInfo)
    self.BtnPay.gameObject:SetActiveEx(hasInfo)
    if hasInfo then
        local itemId = payTypeInfo.CostItemId
        self.BtnPay:SetNameByGroup(0, payTypeInfo.Name)
        self.BtnPay:SetNameByGroup(1, payTypeInfo.CostItemCount)
        self.BtnPay:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemId))
    end
    
    -- 战令信息
    self.RootUi:BindViewModelPropertiesToObj(passportViewModel, function()
        
        --一键领取按钮
        local hasReward = passportViewModel:IsRewardsAvailable()
        self.BtnReceiveAll.gameObject:SetActiveEx(hasReward)
        
        --战令等级
        self:SetupDynamicTable()
        
    end, "_PassportInfoDict", "_Level")
    
    self.RootUi:BindViewModelPropertiesToObj(passportViewModel, function(accumulated, level) 
        local levelInfo = passportViewModel:GetLevelInfo(level)
        local nextLevelInfo = passportViewModel:GetLevelInfo(level + 1)
        local totalExp = nextLevelInfo and nextLevelInfo.TotalExp or string.format("%s(MAX)", levelInfo.TotalExp)
        
        self.TxtProgress.text = string.format("%s/%s", accumulated, totalExp)
    end, "_Accumulated", "_Level")
    
    
    self.RootUi:BindViewModelPropertyToObj(passportViewModel, function(rewards)
        if XTool.IsTableEmpty(rewards) then
            return
        end
        XUiManager.OpenUiObtain(rewards)
        passportViewModel:ClearAutoGetRewards()
    end, "_AutoGetRewards")
end

function XUiPanelRegressionPassport:SetupDynamicTable()
    local passportViewModel = self.PassportViewModel
    local passportData = passportViewModel:GetPassportLevelInfos()
    
    self.PassportData = passportData
    
    local receiveLevel = passportViewModel:GetAvailableRewardIndex()
    
    self.DynamicTable:SetDataSource(passportData)
    self.DynamicTable:ReloadDataSync(receiveLevel)
end

function XUiPanelRegressionPassport:OnDynamicTableEvent(evt, idx, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.PassportData[idx])
    end
end

function XUiPanelRegressionPassport:OnBtnPayClick()
    local passportViewModel = self.PassportViewModel
    local leftTime = self.ViewModel:GetLeftTime()
    local earlyEndTime = passportViewModel:GetBuyPassPortEarlyEndTime()

    --活动结束前配置秒数，禁止购买
    if leftTime < earlyEndTime then
        XUiManager.TipMsg(XRegression3rdConfigs.GetClientConfigValue("StopPayPassportTips", 1))
        return
    end
    
    local payTypeInfo = passportViewModel:GetPayPassportTypeInfo()
    if XTool.IsTableEmpty(payTypeInfo) then
        XUiManager.TipText("AlreadyBuy")
        self.BtnPay.gameObject:SetActiveEx(false)
        return
    end
    local owned = XDataCenter.ItemManager.GetCount(payTypeInfo.CostItemId)
    if owned < payTypeInfo.CostItemCount then
        if payTypeInfo.CostItemId == XDataCenter.ItemManager.ItemId.HongKa then
            XUiHelper.OpenPurchaseBuyHongKaCountTips()
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay)
        elseif payTypeInfo.CostItemId == XDataCenter.ItemManager.ItemId.PaidGem then
            XUiManager.TipText("ShopItemPaidGemNotEnough")
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK)
        end
        return
    end
    
    local title = XUiHelper.GetText("BuyConfirmTipsTitle")
    local desc = XUiHelper.ReplaceTextNewLine(string.format(payTypeInfo.BuyDesc, payTypeInfo.CostItemCount, math.floor(earlyEndTime / OneMinSeconds)))
    
    local index, _, _ = string.find(desc, "\n")
    local content, subContent
    if index > 0 then
        content = string.sub(desc, 1, index)
        subContent = string.sub(desc, index + 1)
    else
        content = desc
        subContent = ""
    end
    local buyCb = function() 
        XDataCenter.Regression3rdManager.RequestBuyPassport(payTypeInfo.Id, function()
            self.BtnPay.gameObject:SetActiveEx(false)
        end)
    end
    XLuaUiManager.Open("UiRegressionTips", payTypeInfo.RewardId, payTypeInfo.PreviewRewardId, title, content, subContent, buyCb)
end

function XUiPanelRegressionPassport:OnReceiveAllClick()
    XDataCenter.Regression3rdManager.RequestAvailablePassportReward(function()
        self.BtnReceiveAll.gameObject:SetActiveEx(false)
    end)
end

--奖励预览
function XUiPanelRegressionPassport:OnBtnPreviewClick(rewardId, preTitle)
    local content = XRegression3rdConfigs.GetClientConfigValue("TipRewardTitle", 1)
    content = "    " .. string.gsub(content, "%s+", "")
    XUiManager.OpenUiTipRewardByRewardId(rewardId,
            content, nil, nil, nil, preTitle)
end

function XUiPanelRegressionPassport:OnCheckBtnRedPoint()
    local passportViewModel = self.PassportViewModel
    local hasReward = passportViewModel:IsRewardsAvailable()
    self.BtnReceiveAll:ShowReddot(hasReward)
end

return XUiPanelRegressionPassport