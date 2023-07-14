local XUiGridPurchaseYK = XClass(nil, "XUiGridPurchaseYK")

local TextManager = CS.XTextManager
local Next = _G.next

local UiType =
{
    BgMonth = 2,
    BgWeek = 13,
    BgDay = 14,
}

local BuyState = {
    CanBuy = 1,
    NotCanBuy = 2
}

local TotalCountLimit
local CountLimit
local TotalCountLimitWeek
local TotalCountLimitDay
local CountLimitWeek

local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

function XUiGridPurchaseYK:Ctor(ui, uiroot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiroot

    TotalCountLimit = CS.XGame.ClientConfig:GetInt("PurchaseYKTotalCount") or 1
    CountLimit = CS.XGame.ClientConfig:GetInt("PurchaseYKLimtCount") or 30
    TotalCountLimitWeek = CS.XGame.ClientConfig:GetInt("PurchaseYKTotalCountWeek") or 1
    TotalCountLimitDay = CS.XGame.ClientConfig:GetInt("PurchaseYKTotalCountDay") or 1
    CountLimitWeek = CS.XGame.ClientConfig:GetInt("PurchaseYKLimtCountWeek") or 7

    XTool.InitUiObject(self)
    self:InitUi()
    self.RewardItems = {}
    self.DailyRewardItems = {}
end

function XUiGridPurchaseYK:SetBuyClickCallBack(uiroot, callback)
    self.UiRoot = uiroot
    self.CallBack = callback
end

function XUiGridPurchaseYK:InitUi()
    self.BtnYkBuy.CallBack = function()
        self:OnBtnYKBuyClick()
    end
end

function XUiGridPurchaseYK:Refresh(data, needUpdateId)
    if data == nil then
        return
    end

    self.Data = data

    --根据类型判断显示的内容
    self.TextPromptlyGet.gameObject:SetActiveEx(self.Data.UiType == UiType.BgMonth)
    self.TextDayGet.gameObject:SetActiveEx(self.Data.UiType == UiType.BgMonth)
    self.TextDayGetNotMonth.gameObject:SetActiveEx(self.Data.UiType ~= UiType.BgMonth)
    self.PanelNowGet.gameObject:SetActiveEx(self.Data.UiType == UiType.BgMonth)
    self.PanelDayGet.gameObject:SetActiveEx(self.Data.UiType == UiType.BgMonth)
    self.PanelDayGetNotMonth.gameObject:SetActiveEx(self.Data.UiType ~= UiType.BgMonth)
    --self.GetNotMonthPanel.gameObject:SetActiveEx(self.Data.UiType ~= UiType.BgMonth)
    
    --根据类型显示对应的背景图
    local icon = XPurchaseConfigs.GetPurchaseYKIconById(self.Data.Id)
    local bgPathConfig = XPurchaseConfigs.GetIconPathByIconName(icon.Path)
    self.ImgMonth:SetRawImage(bgPathConfig.AssetPath)

    if self.Data.UiType == UiType.BgDay then
        self.TxtDay.gameObject:SetActiveEx(false)
        --self.TxtDay.text = self.Data.MailCount and self.Data.MailCount or 0
    else
        self.TxtDay.gameObject:SetActiveEx(false)
    end
    
    local totalCount
    local countLimit
    if self.Data.UiType == UiType.BgDay then
        totalCount = TotalCountLimitDay
        countLimit = self.Data.MailCount and self.Data.MailCount or 1
    elseif self.Data.UiType == UiType.BgWeek then
        totalCount = TotalCountLimitWeek
        countLimit = CountLimitWeek
    elseif self.Data.UiType == UiType.BgMonth then
        totalCount = self.Data.MailCount > 0 and 1 or TotalCountLimit
        countLimit = CountLimit
    end
    local isMutexPur = XDataCenter.PurchaseManager.CheckMutexPurchaseYKBuy(self.Data.UiType, self.Data.Id)
    self.IsMutexPur = isMutexPur
    if self.Data.BuyTimes > 0 or isMutexPur then
        local curlimitcount = math.ceil(self.Data.DailyRewardRemainDay / countLimit)
        self.Txtlimit.text = TextManager.GetText("PurchaseYKBuyLimt", curlimitcount, totalCount)
        local clientResetInfo = self.Data.ClientResetInfo
        if not isMutexPur and clientResetInfo and clientResetInfo.DayCount >= self.Data.DailyRewardRemainDay and curlimitcount < totalCount then
            if self.Data.DailyRewardRemainDay > 0 then
                self.BtnYkBuy:SetName(TextManager.GetText("PurchaseYKBuyText2"))
            else
                local name
                local count
                if self.Data.PayKeySuffix then
                    name = TextManager.GetText("PurchaseRiYuanName")
                    local key
                    if Platform == RuntimePlatform.Android then
                        key = string.format("%s%s", XPayConfigs.GetPlatformConfig(1), self.Data.PayKeySuffix)
                    else
                        key = string.format("%s%s", XPayConfigs.GetPlatformConfig(2), self.Data.PayKeySuffix)
                    end
                    local payConfig = XPayConfigs.GetPayTemplate(key)
                    count = payConfig.Amount
                else
                    name = XDataCenter.ItemManager.GetItemName(self.Data.ConsumeId)
                    count = self.Data.ConsumeCount
                end
                self.BtnYkBuy:SetName(TextManager.GetText("PurchaseYKBuyText1", count, name))
            end
            self.CurBuyState = BuyState.CanBuy
        else
            self.CurBuyState = BuyState.NotCanBuy
            self.BtnYkBuy:SetName(TextManager.GetText("PurchaseYKBuyText3"))
        end

        if self.Data.UiType == UiType.BgMonth then
            self.TxtSurplus.text = TextManager.GetText("PurchaseYKSurplusDay", self.Data.DailyRewardRemainDay > 0 and self.Data.DailyRewardRemainDay - 1 or 0)
        else
            self.TxtSurplus.text = TextManager.GetText("PurchaseYKSurplusMail", self.Data.DailyRewardRemainDay > 0 and self.Data.DailyRewardRemainDay - 1 or 0)
        end
    else
        self.Txtlimit.text = TextManager.GetText("PurchaseYKBuyLimt", 0, totalCount)
        self.CurBuyState = BuyState.CanBuy

        local name
        local count
        if self.Data.PayKeySuffix then
            name = TextManager.GetText("PurchaseRiYuanName")
            local key
            if Platform == RuntimePlatform.Android then
                key = string.format("%s%s", XPayConfigs.GetPlatformConfig(1), self.Data.PayKeySuffix)
            else
                key = string.format("%s%s", XPayConfigs.GetPlatformConfig(2), self.Data.PayKeySuffix)
            end
            local payConfig = XPayConfigs.GetPayTemplate(key)
            count = payConfig.Amount
        else
            name = XDataCenter.ItemManager.GetItemName(self.Data.ConsumeId)
            count = self.Data.ConsumeCount
        end
        self.BtnYkBuy:SetName(TextManager.GetText("PurchaseYKBuyText1", count, name))
        
        if self.Data.UiType == UiType.BgMonth then
            self.TxtSurplus.text = TextManager.GetText("PurchaseYKSurplusDay", 0)
        else
            self.TxtSurplus.text = TextManager.GetText("PurchaseYKSurplusMail", 0)
        end
    end

    if needUpdateId and needUpdateId == self.Data.Id then
        self.BtnYkBuy:SetName(TextManager.GetText("BuyLimitYKButtonTips"))
    end

    self.Txtlimit.gameObject:SetActiveEx(true)
    self.TxtSurplus.gameObject:SetActiveEx(true)
    self.TxtTotalLimit.gameObject:SetActiveEx(false)
    --多日卡并且限购次数为1
    if self.Data.UiType == XPurchaseConfigs.YKType.Day and self.Data.BuyLimitTimes == 1 then
        self.TxtSurplus.gameObject:SetActiveEx(false)
        self.Txtlimit.gameObject:SetActiveEx(false)
        self.TxtTotalLimit.gameObject:SetActiveEx(true)
        self.TxtTotalLimit.text = TextManager.GetText("PurchaseYKBuyLimitDayCardTips", self.Data.BuyLimitTimes)
    end

    self.TxtYuan.text = self.Data.ConsumeCount

    for i = 1, #self.RewardItems do
        self.RewardItems[i].GameObject:SetActiveEx(false)
    end

    for i = 1, #self.DailyRewardItems do
        self.DailyRewardItems[i].GameObject:SetActiveEx(false)
    end

    --显示奖励物品
    if self.Data.RewardGoodsList and next(self.Data.RewardGoodsList) then
        local parent = self.Data.UiType == UiType.BgMonth and self.PanelNowGet or self.PanelNowGetNotMonth
        for i = 1, #self.Data.RewardGoodsList do
            local grid
            if not self.RewardItems[i] then
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                grid = XUiGridCommon.New(self.UiRoot, ui)
                grid.Transform:SetParent(parent, false)
                self.RewardItems[i] = grid
            else
                grid = self.RewardItems[i]
                grid.Transform:SetParent(parent, false)
            end
            grid:Refresh(self.Data.RewardGoodsList[i])
            grid.GameObject:SetActiveEx(true)
        end
        if self.Data.UiType ~= UiType.BgMonth then
            self.NowGetNotMonthRoot.gameObject:SetActiveEx(true)
        end
    else
        if self.Data.UiType ~= UiType.BgMonth then
            self.NowGetNotMonthRoot.gameObject:SetActiveEx(false)
        end
    end
    
    if self.Data.DailyRewardGoodsList and next(self.Data.DailyRewardGoodsList) then
        local parent = self.Data.UiType == UiType.BgMonth and self.PanelDayGet or self.PanelDayGetNotMonth
        for i = 1, #self.Data.DailyRewardGoodsList do
            local grid
            if not self.DailyRewardItems[i] then
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                grid = XUiGridCommon.New(self.UiRoot, ui)
                grid.Transform:SetParent(parent, false)
                self.DailyRewardItems[i] = grid
            else
                grid = self.DailyRewardItems[i]
                grid.Transform:SetParent(parent, false)
            end
            grid:Refresh(self.Data.DailyRewardGoodsList[i])
            grid.GameObject:SetActiveEx(true)
        end
        if self.Data.UiType ~= UiType.BgMonth then
            self.DayGetNotMonthRoot.gameObject:SetActiveEx(true)
        end
    else
        if self.Data.UiType ~= UiType.BgMonth then
            self.DayGetNotMonthRoot.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridPurchaseYK:OnBtnYKBuyClick()
    if self.CallBack then
        self.CallBack(self.Data)
    end
end

return XUiGridPurchaseYK