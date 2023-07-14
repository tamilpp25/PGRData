local CSXTextManagerGetText = CS.XTextManager.GetText
local ShopHintText = CS.XTextManager.GetText("ActivityNierShopLock")
local XUiMoeWarShop = XLuaUiManager.Register(XLuaUi, "UiMoeWarShop")
local Dropdown = CS.UnityEngine.UI.Dropdown


function XUiMoeWarShop:OnAwake()
    self.GridShop.gameObject:SetActiveEx(false)
    self.TxtTime.gameObject:SetActiveEx(false)
    self.HintTxt.gameObject:SetActiveEx(false)
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelActivityAsset, true)
    self:InitDynamicTable()
    self:InitPanels()
end

function XUiMoeWarShop:OnStart()

    self.IsCanCheckLock = false
    self.ShopIdList = XDataCenter.MoeWarManager.GetActivityShopIds()
    self.ShopItemTextColor = {}
    self.ShopItemTextColor.CanBuyColor = CS.XGame.ClientConfig:GetString("NierShopItemTextCanBuyColor")
    self.ShopItemTextColor.CanNotBuyColor = CS.XGame.ClientConfig:GetString("NierShopItemTextCanNotBuyColor")

    --self.TextName.text = CS.XTextManager.GetText("NieRShopNameStr")
    XShopManager.GetShopInfoList(self.ShopIdList, function()
        self.IsCanCheckLock = true
        self:CheckShopLock()
        self:InitShopButton()
        self:SetButtonLock()
    end, XShopManager.ActivityShopType.MoeWarShop)
end

function XUiMoeWarShop:OnEnable()

    if self.IsCanCheckLock then
        self:CheckShopLock()
        self:SetButtonLock()
        self:RefreshBuy()
    end
    self.FromEnable = true
    self.EffectRefresh.gameObject:SetActiveEx(false)
end

function XUiMoeWarShop:InitShopButton()
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
            --shopBtn:SetNameByGroup(0, XDataCenter.NieRManager.GetActivityShopBtnNameById(self.ShopIdList[index]))
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

function XUiMoeWarShop:CheckShopLock()
    self.IsShopLock = {}
    self.ShopLockDecs = {}
    for k, v in pairs(self.ShopIdList) do
        local conditions = XShopManager.GetShopConditionIdList(v)
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

function XUiMoeWarShop:SetButtonLock()
    for k, v in pairs(self.ShopBtn or {}) do
        v:ShowTag(self.IsShopLock[k])
    end
end

function XUiMoeWarShop:InitPanels()
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

function XUiMoeWarShop:UpdatePanels()
    local shopId = self.ShopIdList[self.CurIndex]
    local shopGoods = XShopManager.GetShopGoodsList(shopId)
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

function XUiMoeWarShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiMoeWarShop:UpdateDynamicTable()
    local shopId = self.ShopIdList[self.CurIndex]
    local shopGoods
    if self:IsShowDropdown() then
        shopGoods = XShopManager.GetScreenGoodsListByTag(self:GetCurShopId(), self.ScreenGroupIDList[1], self.BtnScreenWords.captionText.text)
    else
        shopGoods = XShopManager.GetShopGoodsList(shopId)
    end

    self.ShopGoods = shopGoods
    self.DynamicTable:SetDataSource(shopGoods)
    self.DynamicTable:ReloadDataASync()
end

function XUiMoeWarShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopGoods[index]
        self:SetShopItemLock(grid)
        --self:SetShopItemBg(grid)
        grid:UpdateData(data, self.ShopItemTextColor)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

function XUiMoeWarShop:InitDropdown()
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

function XUiMoeWarShop:IsShowDropdown()
    if self.ScreenGroupIDList and next(self.ScreenGroupIDList) then
        return true
    else
        return false
    end
end

function XUiMoeWarShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, cb)
    self:PlayAnimation("ShopItemEnable")
end

function XUiMoeWarShop:GetCurShopId()
    return self.ShopIdList[self.CurIndex]
end

function XUiMoeWarShop:RefreshBuy()
    local shopId = self:GetCurShopId()
    self.AssetActivityPanel:Refresh(XShopManager.GetShopShowIdList(shopId))
    self:UpdateDynamicTable()
end

function XUiMoeWarShop:SetShopItemBg(grid)
    local shopId = self:GetCurShopId()
    local bg = XDataCenter.NieRManager.GetActivityShopItemBgById(shopId)
    if grid.ItemBg and bg then
        grid.ItemBg:SetRawImage(bg)
    end
end

function XUiMoeWarShop:SetShopItemLock(grid)
    grid.IsShopLock = self.IsShopLock[self.CurIndex]
    grid.ShopLockDecs = ShopHintText
    if grid.ImgLock then
        grid.ImgLock.gameObject:SetActiveEx(self.IsShopLock[self.CurIndex])
    end
end

function XUiMoeWarShop:SelectShop(index)
    self.CurIndex = index
    local shopId = self:GetCurShopId()
    self:PlayAnimation("AnimQieHuan")
    self.HintTxt.gameObject:SetActiveEx(self.IsShopLock[self.CurIndex])
    self.HintTxt.text = self.ShopLockDecs[self.CurIndex]

    --local bg = XDataCenter.NieRManager.GetActivityShopBgById(shopId)
    --self.RImgBg:SetRawImage(bg)
    --
    --local icon = XDataCenter.NieRManager.GetActivityShopIconById(shopId)
    --self.RImgShopIcon:SetRawImage(icon)

    XShopManager.GetShopInfoList(self.ShopIdList, function()
        self:UpdatePanels()
        self:RefreshBuy()
        self:InitDropdown()
    end, XShopManager.ActivityShopType.MoeWarShop)
end