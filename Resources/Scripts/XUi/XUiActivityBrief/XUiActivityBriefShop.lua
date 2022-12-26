local XUiActivityBriefShop = XLuaUiManager.Register(XLuaUi, "UiActivityBriefShop")

local CSXTextManagerGetText = CS.XTextManager.GetText
local ShopHintText = CS.XTextManager.GetText("ActivityBriefShopLock")
local Dropdown = CS.UnityEngine.UI.Dropdown

function XUiActivityBriefShop:Init()
    self:OnAwake()
    self:OnStart()
    self:OnEnable()
end

function XUiActivityBriefShop:OnAwake()
    self.GridShop.gameObject:SetActiveEx(false)
    self.TxtTime.gameObject:SetActiveEx(false)
    self.HintTxt.gameObject:SetActiveEx(false)
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelActivityAsset, true)
    self:InitDynamicTable()
    self:InitPanels()
end

function XUiActivityBriefShop:OnStart(closeCb, openCb)
    self.CloseCb = closeCb
    self.OpenCb = openCb
    self.IsCanCheckLock = false
    self.ShopIdList = XDataCenter.ActivityBriefManager.GetActivityShopIds()
    self.ShopItemTextColor = {}
    self.ShopItemTextColor.CanBuyColor = CS.XGame.ClientConfig:GetString("ActivityShopItemTextCanBuyColor")
    self.ShopItemTextColor.CanNotBuyColor = CS.XGame.ClientConfig:GetString("ActivityShopItemTextCanNotBuyColor")

    XShopManager.GetShopInfoList(self.ShopIdList, function()
        self.IsCanCheckLock = true
        self:CheckShopLock()
        self:InitShopButton()
        self:SetButtonLock()
    end)
end

function XUiActivityBriefShop:OnEnable()
    if self.IsCanCheckLock then
        self:CheckShopLock()
        self:SetButtonLock()
        self:RefreshBuy()
    end
    self.FromEnable = true
    self.EffectRefresh.gameObject:SetActiveEx(false)

    self:PlayAnimationWithMask("ShopEnable", function()
        if self.OpenCb then self.OpenCb() end
    end)
end

function XUiActivityBriefShop:InitShopButton()
    local shopBtns = {
        self.BtnTong1,
        self.BtnTong2,
        self.BtnTong3,
        self.BtnTong4,
    }
    self.CurIndex = 1
    self.ShopBtn = shopBtns

    local btnNum = #self.ShopIdList
    for index, shopBtn in pairs(shopBtns) do
        shopBtn.gameObject:SetActiveEx(index <= btnNum)
    end

    self.FromInit = true
    self.BtnTab:Init(shopBtns, function(index)
        if not self.FromEnable then
            self.EffectRefresh.gameObject:SetActiveEx(false)
        else
            self.FromEnable = nil
        end

        if not self.FromInit and not self.FromEnable then
            self.EffectRefresh.gameObject:SetActiveEx(true)
        else
            self.FromInit = nil
        end

        self:SelectShop(index)
    end)
    self.BtnTab:SelectIndex(self.CurIndex)
end

function XUiActivityBriefShop:CheckShopLock()
    self.IsShopLock = {}
    self.ShopLockDecs = {}
    for k, v in pairs(self.ShopIdList) do
        local conditions = XDataCenter.ActivityBriefManager.GetActivityShopConditionByShopId(v)
        self.IsShopLock[k] = false
        self.ShopLockDecs[k] = ""
        for _, condition in pairs(conditions or {}) do
            if condition ~= 0 then
                self.IsShopLock[k], self.ShopLockDecs[k] = XConditionManager.CheckCondition(condition)
                self.IsShopLock[k] = not self.IsShopLock[k]
                if self.IsShopLock[k] then
                    break
                end
            end
        end
    end
end

function XUiActivityBriefShop:SetButtonLock()
    for k, v in pairs(self.ShopBtn or {}) do
        v:ShowTag(self.IsShopLock[k])
    end
end

function XUiActivityBriefShop:InitPanels()
    self.ImgEmpty.gameObject:SetActiveEx(true)
    self.AssetActivityPanel.GameObject:SetActiveEx(false)
    self.BtnBack.CallBack = function()
        self:Close()
        if self.CloseCb then self.CloseCb() end
    end

    self.BtnScreenWords.onValueChanged:AddListener(function()
        self:UpdateDynamicTable()
        self:PlayAnimation("QieHuan")
    end)
end

function XUiActivityBriefShop:UpdatePanels()
    local shopGoods = XDataCenter.ActivityBriefManager.GetActivityShopGoodsByShopIndex(self.CurIndex)
    local isEmpty = not next(shopGoods)
    self.ImgEmpty.gameObject:SetActiveEx(isEmpty)
    self.AssetActivityPanel.GameObject:SetActiveEx(not isEmpty)

    local shopId = self.ShopIdList[self.CurIndex]
    local shopTimeInfo = XShopManager.GetShopTimeInfo(shopId)
    local leftTime = shopTimeInfo.ClosedLeftTime
    if leftTime and leftTime > 0 then
        local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtTime.text = CSXTextManagerGetText("ActivityBriefShopLeftTime", timeStr)
        self.TxtTime.gameObject:SetActiveEx(true)
    else
        self.TxtTime.gameObject:SetActiveEx(false)
    end
end

function XUiActivityBriefShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiActivityBriefShop:UpdateDynamicTable()
    local shopGoods
    if self:IsShowDropdown() then
        shopGoods = XShopManager.GetScreenGoodsListByTag(self:GetCurShopId(), self.ScreenGroupIDList[1], self.BtnScreenWords.captionText.text)
    else
        shopGoods = XDataCenter.ActivityBriefManager.GetActivityShopGoodsByShopIndex(self.CurIndex)
    end

    self.ShopGoods = shopGoods
    self.DynamicTable:SetDataSource(shopGoods)
    self.DynamicTable:ReloadDataASync()
end

function XUiActivityBriefShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self, self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopGoods[index]
        self:SetShopItemLock(grid)
        self:SetShopItemBg(grid)
        grid:UpdateData(data, self.ShopItemTextColor)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

function XUiActivityBriefShop:InitDropdown()
    local shopId = self:GetCurShopId()
    self.ScreenGroupIDList = XShopManager.GetShopScreenGroupIDList(shopId)

    if self:IsShowDropdown() then
        self.BtnScreenWords.gameObject:SetActiveEx(true)

        local screenTagList = XShopManager.GetScreenTagListById(shopId, self.ScreenGroupIDList[1])
        self.BtnScreenWords:ClearOptions()
        self.BtnScreenWords.captionText.text = CSXTextManagerGetText("ScreenAll")
        for _, v in pairs(screenTagList or {}) do
            local op = Dropdown.OptionData()
            op.text = v.Text
            self.BtnScreenWords.options:Add(op)
        end
        self.BtnScreenWords.value = 0
    else
        self.BtnScreenWords.gameObject:SetActiveEx(false)
    end
end

function XUiActivityBriefShop:IsShowDropdown()
    if self.ScreenGroupIDList and next(self.ScreenGroupIDList) then
        return true
    else
        return false
    end
end

function XUiActivityBriefShop:UpdateBuy(data, cb)
    local shopId = XDataCenter.ActivityBriefManager.GetActivityShopIds()
    if shopId == nil then
        XUiManager.TipText("BriefActivityEndTipText")
        XLuaUiManager.RunMain()
        return
    end
    for _, v in pairs(shopId) do
        local shopTimeInfo = XShopManager.GetShopTimeInfo(v)
        local leftTime = shopTimeInfo.ClosedLeftTime
        if leftTime <= 0 then
            XUiManager.TipText("BriefActivityEndTipText")
            XLuaUiManager.RunMain()
            return
        end
    end
    XLuaUiManager.Open("UiShopItem", self, data, cb, "000000ff")
    -- self:PlayAnimation("ShopItemEnable")
end

function XUiActivityBriefShop:GetCurShopId()
    return self.ShopIdList[self.CurIndex]
end

function XUiActivityBriefShop:RefreshBuy()
    local shopId = self:GetCurShopId()
    self.AssetActivityPanel:Refresh(XShopManager.GetShopShowIdList(shopId))
    self:UpdateDynamicTable()
end

function XUiActivityBriefShop:SetShopItemBg(grid)
    local bg = XDataCenter.ActivityBriefManager.GetActivityShopItemBgByIndex(self.CurIndex)
    if grid.ItemBg and bg then
        grid.ItemBg:SetRawImage(bg)
    end
end

function XUiActivityBriefShop:SetShopItemLock(grid)
    grid.IsShopLock = self.IsShopLock[self.CurIndex]
    grid.ShopLockDecs = ShopHintText
    if grid.ImgLock then
        grid.ImgLock.gameObject:SetActiveEx(self.IsShopLock[self.CurIndex])
    end
end

function XUiActivityBriefShop:SelectShop(index)
    self.CurIndex = index
    self:PlayAnimation("QieHuan")
    self.HintTxt.gameObject:SetActiveEx(self.IsShopLock[self.CurIndex])
    self.HintTxt.text = self.ShopLockDecs[self.CurIndex]

    -- local bg = XDataCenter.ActivityBriefManager.GetActivityShopBgByIndex(self.CurIndex)
    -- self.RImgBg:SetRawImage(bg)
    -- local icon = XDataCenter.ActivityBriefManager.GetActivityShopIconByIndex(self.CurIndex)
    -- self.RImgShopIcon:SetRawImage(icon)
    XShopManager.GetShopInfoList(self.ShopIdList, function()
        self:UpdatePanels()
        self:RefreshBuy()
        self:InitDropdown()
    end)
end