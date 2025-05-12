local XUiWorldBossFashion = XLuaUiManager.Register(XLuaUi, "UiWorldBossFashion")
local CSTextManagerGetText = CS.XTextManager.GetText
local FashionSkipId = 20011
local FirstIndex = 1
local ProTime = 2
local Normal = CS.UiButtonState.Normal
local Disable = CS.UiButtonState.Disable

function XUiWorldBossFashion:OnStart()
    self:InitDiscountGrid()
    self:InitSpecialSaleInfo()
    self:SetButtonCallBack()
end

function XUiWorldBossFashion:OnEnable()
    XDataCenter.WorldBossManager.CheckWorldBossActivityReset()
    self:UpdateSpecialSaleInfo()
    XEventManager.AddEventListener(XEventId.EVENT_WORLDBOSS_SYNCDATA, self.UpdateSpecialSaleInfo, self)
end

function XUiWorldBossFashion:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_WORLDBOSS_SYNCDATA, self.UpdateSpecialSaleInfo, self)
end

function XUiWorldBossFashion:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnGet.CallBack = function()
        self:OnBtnGetClick()
    end
    self.BtnHelp.CallBack = function()
        self:OnBtnHelpClick()
    end
end

function XUiWorldBossFashion:InitSpecialSaleInfo()
    local specialSale = XDataCenter.WorldBossManager.GetSpecialSaleById(FirstIndex)
    self.FashionImage:SetRawImage(specialSale:GetShopImg())
end

function XUiWorldBossFashion:InitDiscountGrid()
    local specialSale = XDataCenter.WorldBossManager.GetSpecialSaleById(FirstIndex)

    self.DiscountGrids = {}
    self.DiscountGridRects = {}
    self.SaleItem.gameObject:SetActiveEx(false)
    local discountIds = specialSale:GetDiscountIds()
    local discountCount = #discountIds
    for i = 1,discountCount do
        local grid = self.DiscountGrids[i]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.SaleItem,self.PanelReward)
            obj.gameObject:SetActiveEx(true)
            self.DiscountGrids[i] = obj.transform:GetComponent("UiObject")
            self.DiscountGridRects[i] = obj.transform:GetComponent("RectTransform")
        end
    end
end

function XUiWorldBossFashion:UpdateSpecialSaleInfo()
    local bossArea = XDataCenter.WorldBossManager.GetBossAreaById(FirstIndex)
    self.BtnGet:SetButtonState(bossArea:GetIsFinish() and Normal or Disable)
    self:UpdatePanel()
end

function XUiWorldBossFashion:UpdatePanel()
    local specialSale = XDataCenter.WorldBossManager.GetSpecialSaleById(FirstIndex)
    local bossArea = XDataCenter.WorldBossManager.GetBossAreaById(FirstIndex)
    local percent = bossArea:GetHpPercent()
    if self.Curfillamount ~= percent then
        self.ScheduleImg:DOFillAmount(1 - percent,ProTime)
        self.Curfillamount = percent
    end

    self.TxtDailyActive.text = string.format("%d%s",math.floor(percent * 100),"%")
    self.TitleText.text = CSTextManagerGetText("WorldBossBossAreaSchedule")
    local discountIds = specialSale:GetDiscountIds()
    local discountCount = #discountIds
    for i = 1, discountCount do
        local discountData = specialSale:GetDiscountById(discountIds[i])

        self.DiscountGrids[i]:GetObject("TextBlue").text = discountData.DiscountText
        self.DiscountGrids[i]:GetObject("SaleBlue").gameObject:SetActiveEx(percent <= discountData.HpPercent * 0.01)

        self.DiscountGrids[i]:GetObject("TextNone").text = discountData.DiscountText
        self.DiscountGrids[i]:GetObject("SaleNone").gameObject:SetActiveEx(percent > discountData.HpPercent * 0.01)
    end
    -- 自适应
    local activeProgressRectSize = self.PanelReward.rect.size
    for i = 1, #self.DiscountGrids do
        local discountData = specialSale:GetDiscountById(discountIds[i])
        local valOffset = 1 - discountData.HpPercent * 0.01
        local adjustPosition = CS.UnityEngine.Vector3(activeProgressRectSize.x * valOffset, 0, 0)
        self.DiscountGridRects[i].anchoredPosition3D = adjustPosition
    end
end

function XUiWorldBossFashion:OnBtnCloseClick()
    self:Close()
end

function XUiWorldBossFashion:OnBtnGetClick()
    if self.BtnGet.ButtonState == Disable then
        return
    end

    XFunctionManager.SkipInterface(FashionSkipId)
end

function XUiWorldBossFashion:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip(CS.XTextManager.GetText("WorldBossFashionHint"), CS.XTextManager.GetText("WorldBossFashionRule") or "")
end