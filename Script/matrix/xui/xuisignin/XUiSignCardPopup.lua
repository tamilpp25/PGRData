---@class XUiSignCardPopup : XLuaUi
local XUiSignCardPopup = XLuaUiManager.Register(XLuaUi, "UiSignCardPopup")

function XUiSignCardPopup:OnAwake()
    self:RegisterUiEvents()
end

function XUiSignCardPopup:OnStart()
    self.PanelBuy.gameObject:SetActive(false)
    self.PanelGet.gameObject:SetActive(false)
    self.BtnContinue.gameObject:SetActive(false)
end

function XUiSignCardPopup:OnEnable()
    XDataCenter.PurchaseManager.YKInfoDataReq(function()
        local isBuy = XDataCenter.PurchaseManager.IsYkBuyed()
        if isBuy then
            self:RefreshGet()
            self:AutoGetReward()
        else
            XLog.Error("未购买月卡")
        end
    end)
end

function XUiSignCardPopup:RefreshGet()
    local data = XDataCenter.PurchaseManager.GetYKInfoData()
    if not data then
        return
    end

    self.TxtLeftDay.text = data.DailyRewardRemainDay
    if data.IsDailyRewardGet then
        self.BtnGet:SetButtonState(CS.UiButtonState.Disable)
    else
        self.BtnGet:SetButtonState(CS.UiButtonState.Normal)
    end

    self.PanelGet.gameObject:SetActive(true)
end

function XUiSignCardPopup:AutoGetReward()
    local data = XDataCenter.PurchaseManager.GetYKInfoData()
    if not data or data.IsDailyRewardGet then
        return
    end

    XDataCenter.PurchaseManager.PurchaseGetDailyRewardRequest(data.Id, function(rewardItems)
        self:RefreshGet()
        XUiManager.OpenUiObtain(rewardItems)

        -- 设置月卡信息本地缓存
        XDataCenter.PurchaseManager.SetYKLocalCache()
        XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
    end)
end

function XUiSignCardPopup:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.OnBtnTanchuangCloseBigClick)
    self:RegisterClickEvent(self.BtnGet, self.OnBtnGetClick)
end

function XUiSignCardPopup:OnBtnTanchuangCloseBigClick()
    self:Close()
end

function XUiSignCardPopup:OnBtnGetClick()
    XDataCenter.PurchaseManager.YKInfoDataReq(function()
        local data = XDataCenter.PurchaseManager.GetYKInfoData()
        if not data then
            return
        end

        if data.IsDailyRewardGet then
            XUiManager.TipText("ChallengeRewardIsGetted")
        else
            XDataCenter.PurchaseManager.PurchaseGetDailyRewardRequest(data.Id, function(rewardItems)
                self:RefreshGet()
                XUiManager.OpenUiObtain(rewardItems)

                -- 设置月卡信息本地缓存
                XDataCenter.PurchaseManager.SetYKLocalCache()
                XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
            end)
        end
    end)
end

return XUiSignCardPopup
