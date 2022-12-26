-- 签到礼包奖励预览，签到轮次脚本，每个签到轮次都有一个面板，面板上的背景、按钮等元素不共享，重复存在各个签到轮次界面上

local XUiPurchaseSignTipRound = XClass(nil, "XUiPurchaseSignTipRound")

local XUiPurchaseSignTipGridDay = require("XUi/XUiPurchase/XUiPurchaseSignTip/XUiPurchaseSignTipGridDay")
local RuntimePlatform = CS.UnityEngine.RuntimePlatform
local UpdateTimerTypeEnum = {
    SettOff = 1,
    SettOn = 2
}

function XUiPurchaseSignTipRound:Ctor(ui, parent, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self:InitComponent()
    self:AddListener()
end

function XUiPurchaseSignTipRound:InitComponent()
    self.DaySmallGrids = {}
    table.insert(self.DaySmallGrids, XUiPurchaseSignTipGridDay.New(self.GridDaySmall, self.RootUi))
    self.DayBigGrids = {}
    table.insert(self.DayBigGrids, XUiPurchaseSignTipGridDay.New(self.GridDayBig, self.RootUi))
    self.BtnList = {}
    table.insert(self.BtnList, self.BtnTab)

    self.PanelPrice.gameObject:SetActiveEx(true)
    self.BtnPurchase.gameObject:SetActiveEx(true)

    self.BtnReceive.gameObject:SetActiveEx(false)
    self.PanelPurchaseRemain.gameObject:SetActiveEx(false)
end

function XUiPurchaseSignTipRound:AddListener()
    self.BtnHelp.CallBack = function()
        self:OnBtnHelpClick()
    end
end

function XUiPurchaseSignTipRound:Refresh(purchaseData, round, buyCb)
    self.Round = round
    self.PurchaseData = purchaseData
    self.BtnPurchase.CallBack = function() buyCb() end
    self.UpdateTimerType = nil

    self.SignInInfos = XSignInConfigs.GetSignInInfos(purchaseData.SignInId)

    local nowTime = XTime.GetServerNowTimestamp()

    self:SetBuyDes()
    if purchaseData.PayKeySuffix then
        local key
        local Platform = Application.platform
        if Platform == RuntimePlatform.Android then
            key = string.format("%s%s", XPayConfigs.GetPlatformConfig(1), purchaseData.PayKeySuffix)
        else
            key = string.format("%s%s", XPayConfigs.GetPlatformConfig(2), purchaseData.PayKeySuffix)
        end

        local payConfig = XPayConfigs.GetPayTemplate(key)
        self.RImPrice.gameObject:SetActiveEx(true)
        local path = CS.XGame.ClientConfig:GetString("PurchaseBuyRiYuanIconPath")
        self.RImPrice:SetRawImage(path)
        self.PanelSale.gameObject:SetActiveEx(false)
        self.TxtPrice.text = payConfig.Amount
    else
        -- 货币图标与价格刷新
        local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(purchaseData)
        if purchaseData.ConsumeCount == 0 then
            -- 免费购买
            self.RImPrice.gameObject:SetActiveEx(false)
            self.TxtPrice.text = CS.XTextManager.GetText("SignGiftPackFree")
            self.PanelSale.gameObject:SetActiveEx(false)
        elseif
            XPurchaseConfigs.GetTagType(purchaseData.Tag) == XPurchaseConfigs.PurchaseTagType.Discount and disCountValue < 1 then
            -- 打折
            self.RImPrice.gameObject:SetActiveEx(true)
            local icon = XDataCenter.ItemManager.GetItemIcon(purchaseData.ConsumeId)
            if icon then
                self.RImPrice:SetRawImage(icon)
            end

            self.PanelSale.gameObject:SetActiveEx(true)
            self.TxtSale.text = purchaseData.ConsumeCount
            self.TxtPrice.text = math.modf(purchaseData.ConsumeCount * disCountValue)
        else
            -- 正常显示价格
            self.RImPrice.gameObject:SetActiveEx(true)
            local path = XDataCenter.ItemManager.GetItemIcon(purchaseData.ConsumeId)
            if path then
                self.RImPrice:SetRawImage(path)
            end
            self.TxtPrice.text = purchaseData.ConsumeCount or ""
            self.PanelSale.gameObject:SetActiveEx(false)
        end
    end

    -- 根据购买限制次数设置购买按钮的状态
    if (purchaseData.BuyLimitTimes > 0 and purchaseData.BuyTimes == purchaseData.BuyLimitTimes)
            or (purchaseData.TimeToShelve > 0 and purchaseData.TimeToShelve <= nowTime)
            or (purchaseData.TimeToUnShelve > 0 and purchaseData.TimeToUnShelve <= nowTime) then
        self.BtnPurchase:SetButtonState(XUiButtonState.Disable)
    else
        self.BtnPurchase:SetButtonState(XUiButtonState.Normal)
    end

    -- 刷新倒计时
    self.TimerId = purchaseData.Id + round
    if purchaseData.TimeToInvalid and purchaseData.TimeToInvalid > 0 then
        -- 失效时间
        self.RemainTime = purchaseData.TimeToInvalid - nowTime
        self.UpdateTimerType = UpdateTimerTypeEnum.SettOff

        if self.RemainTime > 0 then
            self.TxShelf.gameObject:SetActiveEx(true)

            self.Parent:RegisterTimerFun(self.TimerId, function()
                self:UpdateTimer()
            end)
            self.TxShelf.text = CS.XTextManager.GetText("PurchaseSetOffTime",XUiHelper.GetTime(self.RemainTime))
        else
            self.TxShelf.gameObject:SetActiveEx(false)
            self.Parent:RemoveTimerFun(self.TimerId)
        end
    else
        if (purchaseData.TimeToShelve == nil or purchaseData.TimeToShelve == 0) and (purchaseData.TimeToUnShelve == nil or purchaseData.TimeToUnShelve == 0) then
            self.TxShelf.gameObject:SetActiveEx(false)
        else
            self.TxShelf.gameObject:SetActiveEx(true)
            if purchaseData.TimeToUnShelve > 0 then
                -- 下架时间
                self.RemainTime = purchaseData.TimeToUnShelve - nowTime
                self.UpdateTimerType = UpdateTimerTypeEnum.SettOff
                self.TxShelf.text = CS.XTextManager.GetText("PurchaseSetOffTime",XUiHelper.GetTime(self.RemainTime))
            else
                -- 上架时间
                self.RemainTime = purchaseData.TimeToShelve-nowTime
                self.UpdateTimerType = UpdateTimerTypeEnum.SettOn
                self.TxShelf.text = CS.XTextManager.GetText("PurchaseSetOnTime",XUiHelper.GetTime(self.RemainTime))
            end

            if self.RemainTime > 0 then
                self.Parent:RegisterTimerFun(self.TimerId, function()
                    self:UpdateTimer()
                end)
            else
                self.Parent:RemoveTimerFun(self.TimerId)
            end
        end
    end

    self:InitTabGroup()
    self:SetRewardInfos(self.Round)
end

function XUiPurchaseSignTipRound:SetBuyDes()
    local clientResetInfo = self.PurchaseData.ClientResetInfo or {}
    if next(clientResetInfo) == nil then
        self.PanelPurchaseLimit.gameObject:SetActiveEx(false)
        self.TxtPurchaseLimit.text = ""
        return
    end

    local textKey = nil
    if clientResetInfo.ResetType == XPurchaseConfigs.RestTypeConfig.Interval then
        self.PanelPurchaseLimit.gameObject:SetActiveEx(true)
        self.TxtPurchaseLimit.text = CS.XTextManager.GetText("PurchaseRestTypeInterval", clientResetInfo.DayCount, self.PurchaseData.BuyTimes, self.PurchaseData.BuyLimitTimes)
        return
    elseif clientResetInfo.ResetType == XPurchaseConfigs.RestTypeConfig.Day then
        textKey = "PurchaseRestTypeDay"
    elseif clientResetInfo.ResetType == XPurchaseConfigs.RestTypeConfig.Week then
        textKey = "PurchaseRestTypeWeek"
    elseif clientResetInfo.ResetType == XPurchaseConfigs.RestTypeConfig.Month then
        textKey = "PurchaseRestTypeMonth"
    end

    if not textKey then
        self.TxtLimitBuy.text = ""
        self.PanelPurchaseLimit.gameObject:SetActiveEx(false)
        return
    end
    self.PanelPurchaseLimit.gameObject:SetActiveEx(true)
    self.TxtPurchaseLimit.text = CS.XTextManager.GetText(textKey, self.PurchaseData.BuyTimes, self.PurchaseData.BuyLimitTimes)
end

---
--- 更新倒计时
function XUiPurchaseSignTipRound:UpdateTimer()
    self.RemainTime = self.RemainTime - 1

    if self.RemainTime <= 0 then
        self.Parent:RemoveTimerFun(self.TimerId)
        if self.UpdateTimerType == UpdateTimerTypeEnum.SettOff then
            self.TxShelf.text = CS.XTextManager.GetText("PurchaseLBSettOff")
            return
        end
        self.TxShelf.text = ""
        return
    end

    if self.UpdateTimerType == UpdateTimerTypeEnum.SettOff then
        self.TxShelf.text = CS.XTextManager.GetText("PurchaseSetOffTime",XUiHelper.GetTime(self.RemainTime))
        return
    end
    self.TxShelf.text = CS.XTextManager.GetText("PurchaseSetOnTime",XUiHelper.GetTime(self.RemainTime))
end

---
--- 初始化轮次标签按钮组
function XUiPurchaseSignTipRound:InitTabGroup()
    for _, v in ipairs(self.BtnList) do
        v.gameObject:SetActiveEx(false)
    end
    if #self.SignInInfos <= 1 then
        return
    end

    local btnGroupList = {}
    for i = 1, #self.SignInInfos do
        local grid = self.BtnList[i]
        if not grid then
            grid = CS.UnityEngine.Object.Instantiate(self.BtnTab.gameObject)
            grid.transform:SetParent(self.PanelTabContent.gameObject.transform, false)
            table.insert(self.BtnList, grid)
        end
        local xBtn = grid.transform:GetComponent("XUiButton")
        local rowImg = XUiHelper.TryGetComponent(grid.transform, "RImgIcon", "RawImage")

        table.insert(btnGroupList, xBtn)
        xBtn:SetName(self.SignInInfos[i].RoundName)
        rowImg:SetRawImage(self.SignInInfos[i].Icon)
        xBtn.gameObject:SetActiveEx(true)
    end

    self.PanelTabContent:Init(btnGroupList, function(index)
        self:SelectPanelRound(index)
    end)
    self.PanelTabContent:SelectIndex(self.Round, false)
end

---
--- 轮次标签按钮组响应函数
function XUiPurchaseSignTipRound:SelectPanelRound(index)
    self.Parent:RefreshPanel(index)
end

---
--- 设置奖励信息
function XUiPurchaseSignTipRound:SetRewardInfos(index)
    local signInInfo = self.SignInInfos[index]
    local rewardConfigs = XSignInConfigs.GetSignInRewardConfigs(self.PurchaseData.SignInId, signInInfo.Round, false)

    for _, v in ipairs(self.DaySmallGrids) do
        v.GameObject:SetActiveEx(false)
    end

    for _, v in ipairs(self.DayBigGrids) do
        v.GameObject:SetActiveEx(false)
    end

    local smallIndex = 1
    local bigIndex = 1

    for _, config in ipairs(rewardConfigs) do
        if config.IsGrandPrix then                          -- 设置大奖励
            local dayGrid = self.DayBigGrids[bigIndex]
            if not dayGrid then
                local grid = CS.UnityEngine.GameObject.Instantiate(self.GridDayBig)
                grid.transform:SetParent(self.PanelDayContent, false)
                dayGrid = XUiPurchaseSignTipGridDay.New(grid, self.RootUi)
                table.insert(self.DayBigGrids, dayGrid)
            end

            dayGrid:Refresh(config)
            dayGrid.Transform:SetAsLastSibling()
            bigIndex = bigIndex + 1
        else                                                -- 设置小奖励
            local dayGrid = self.DaySmallGrids[smallIndex]
            if not dayGrid then
                local grid = CS.UnityEngine.GameObject.Instantiate(self.GridDaySmall)
                grid.transform:SetParent(self.PanelDayContent, false)
                dayGrid = XUiPurchaseSignTipGridDay.New(grid, self.RootUi)
                table.insert(self.DaySmallGrids, dayGrid)
            end

            dayGrid:Refresh(config)
            dayGrid.Transform:SetAsLastSibling()
            smallIndex = smallIndex + 1
        end
    end
end

---
--- 控制当前轮次面板的显示与隐藏
--- 父UI调用,其他同级的轮次脚本切换轮次时，就调用此函数显示对应轮次的面板
function XUiPurchaseSignTipRound:SetSignActive(active, round)
    if active and self.GameObject.activeSelf then
        return
    end

    if not active and not self.GameObject.activeSelf then
        return
    end

    if #self.SignInInfos > 1 then
        self.PanelTabContent:SelectIndex(round, false)
    end

    self.GameObject:SetActiveEx(active)
end

function XUiPurchaseSignTipRound:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip("Event Info", self.SignInInfos[1].Description or "")
end

function XUiPurchaseSignTipRound:OnClose()
    if self.UpdateTimerType then
        self.Parent:RemoveTimerFun(self.TimerId)
    end
end

return XUiPurchaseSignTipRound