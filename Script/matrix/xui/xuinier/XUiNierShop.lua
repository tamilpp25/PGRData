local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
local CSXTextManagerGetText = CS.XTextManager.GetText
local ShopHintText = CS.XTextManager.GetText("ActivityNierShopLock")
local XUiNierShop = XLuaUiManager.Register(XLuaUi, "UiNierShop")
local Dropdown = CS.UnityEngine.UI.Dropdown

function XUiNierShop:OnAwake()
    self.GridShop.gameObject:SetActiveEx(false)
    self.TxtTime.gameObject:SetActiveEx(false)
    self.HintTxt.gameObject:SetActiveEx(false)
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelActivityAsset, self, true)
    self:InitDynamicTable()
    self:InitPanels()
end

function XUiNierShop:OnStart()

    self.IsCanCheckLock = false
    self.ShopIdList = XDataCenter.NieRManager.GetActivityShopIds()
    self.ShopItemTextColor = {}
    self.ShopItemTextColor.CanBuyColor = CS.XGame.ClientConfig:GetString("NierShopItemTextCanBuyColor")
    self.ShopItemTextColor.CanNotBuyColor = CS.XGame.ClientConfig:GetString("NierShopItemTextCanNotBuyColor")

    self.TextName.text = CS.XTextManager.GetText("NieRShopNameStr")
    XShopManager.GetShopInfoList(self.ShopIdList, function()
        self.IsCanCheckLock = true
        self:CheckShopLock()
        self:InitShopButton()
        self:SetButtonLock()
    end, XShopManager.ActivityShopType.NieRShop)
end

function XUiNierShop:OnEnable()

    if self.IsCanCheckLock then
        self:CheckShopLock()
        self:SetButtonLock()
        self:RefreshBuy()
    end
    self.FromEnable = true
    self.EffectRefresh.gameObject:SetActiveEx(false)
end

function XUiNierShop:InitShopButton()
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
        if index <= btnNum then
            shopBtn.gameObject:SetActiveEx(true)
            shopBtn:SetButtonState(CS.UiButtonState.Normal)
            shopBtn:SetNameByGroup(0, XDataCenter.NieRManager.GetActivityShopBtnNameById(self.ShopIdList[index]))
        else
            shopBtn.gameObject:SetActiveEx(false)
        end

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
        if index > btnNum then
            return
        end
        self:SelectShop(index)
    end)
    self.BtnTab:SelectIndex(self.CurIndex)
end

function XUiNierShop:CheckShopLock()
    self.IsShopLock = {}
    self.ShopLockDecs = {}
    for k, v in pairs(self.ShopIdList) do
        local conditions = XDataCenter.NieRManager.GetActivityShopConditionByShopId(v)
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

function XUiNierShop:SetButtonLock()
    for k, v in pairs(self.ShopBtn or {}) do
        v:ShowTag(self.IsShopLock[k])
    end
end

function XUiNierShop:InitPanels()
    self.ImgEmpty.gameObject:SetActiveEx(true)
    self.AssetActivityPanel.GameObject:SetActiveEx(false)
    self.BtnBack.CallBack = function()
        self:Close()
    end

    self.BtnScreenWords.onValueChanged:AddListener(function()
        -- self.SelectBtnScreenWordsCaptionText = 
        self:UpdateDynamicTable()
    end)
end

function XUiNierShop:UpdatePanels()
    local shopId = self.ShopIdList[self.CurIndex]
    local shopGoods = XDataCenter.NieRManager.GetActivityShopGoodsByShopId(shopId)
    local isEmpty = not next(shopGoods or {})
    self.ImgEmpty.gameObject:SetActiveEx(isEmpty)
    self.AssetActivityPanel.GameObject:SetActiveEx(not isEmpty)


    local shopTimeInfo = XShopManager.GetShopTimeInfo(shopId)
    local leftTime = shopTimeInfo.ClosedLeftTime
    if leftTime and leftTime > 0 then
        local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtTime.text = CSXTextManagerGetText("ActivityNierShopLeftTime", timeStr)
        self.TxtTime.gameObject:SetActiveEx(true)
    else
        self.TxtTime.gameObject:SetActiveEx(false)
    end
end

function XUiNierShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiNierShop:UpdateDynamicTable()
    local shopId = self.ShopIdList[self.CurIndex]
    local shopGoods
    if self:IsShowDropdown() then
        shopGoods = XShopManager.GetScreenGoodsListByTag(self:GetCurShopId(), self.ScreenGroupIDList[1], self.BtnScreenWords.captionText.text)
    else
        shopGoods = XDataCenter.NieRManager.GetActivityShopGoodsByShopId(shopId)
    end

    self.ShopGoods = shopGoods
    self.DynamicTable:SetDataSource(shopGoods)
    self.DynamicTable:ReloadDataASync()
end

function XUiNierShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopGoods[index]
        self:SetShopItemLock(grid)
        self:SetShopItemBg(grid)
        grid:UpdateData(data, self.ShopItemTextColor)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

function XUiNierShop:InitDropdown()
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

function XUiNierShop:IsShowDropdown()
    if self.ScreenGroupIDList and next(self.ScreenGroupIDList) then
        return true
    else
        return false
    end
end

function XUiNierShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, cb)
    self:PlayAnimation("ShopItemEnable")
end

function XUiNierShop:GetCurShopId()
    return self.ShopIdList[self.CurIndex]
end

function XUiNierShop:RefreshBuy()
    local shopId = self:GetCurShopId()
    self.AssetActivityPanel:Refresh(XShopManager.GetShopShowIdList(shopId))
    self:UpdateDynamicTable()
end

function XUiNierShop:SetShopItemBg(grid)
    local shopId = self:GetCurShopId()
    local bg = XDataCenter.NieRManager.GetActivityShopItemBgById(shopId)
    if grid.ItemBg and bg then
        grid.ItemBg:SetRawImage(bg)
    end
end

function XUiNierShop:SetShopItemLock(grid)
    grid.IsShopLock = self.IsShopLock[self.CurIndex]
    grid.ShopLockDecs = ShopHintText
    if grid.ImgLock then
        grid.ImgLock.gameObject:SetActiveEx(self.IsShopLock[self.CurIndex])
    end
end

function XUiNierShop:SelectShop(index)
    self.CurIndex = index
    local shopId = self:GetCurShopId()
    self:PlayAnimation("AnimQieHuan")
    self.HintTxt.gameObject:SetActiveEx(self.IsShopLock[self.CurIndex])
    self.HintTxt.text = self.ShopLockDecs[self.CurIndex]

    local bg = XDataCenter.NieRManager.GetActivityShopBgById(shopId)
    self.RImgBg:SetRawImage(bg)

    local icon = XDataCenter.NieRManager.GetActivityShopIconById(shopId)
    self.RImgShopIcon:SetRawImage(icon)

    XShopManager.GetShopInfoList(self.ShopIdList, function()
        self:UpdatePanels()
        self:RefreshBuy()
        self:InitDropdown()
    end, XShopManager.ActivityShopType.NieRShop)
end