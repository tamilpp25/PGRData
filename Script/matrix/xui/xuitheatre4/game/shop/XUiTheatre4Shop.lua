local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTheatre4ShopGrid = require("XUi/XUiTheatre4/Game/Shop/XUiTheatre4ShopGrid")
local XUiPanelTheatre4ShopRewardCard = require("XUi/XUiTheatre4/Game/Shop/XUiPanelTheatre4ShopRewardCard")
---@class XUiTheatre4Shop : XLuaUi
---@field private _Control XTheatre4Control
---@field BtnRefresh XUiComponent.XUiButton
local XUiTheatre4Shop = XLuaUiManager.Register(XLuaUi, "UiTheatre4Shop")

function XUiTheatre4Shop:OnAwake()
    self:RegisterUiEvents()
    self.PanelGoldChange.gameObject:SetActiveEx(false)
    self.PanelRole.gameObject:SetActiveEx(false)
    self.GridCommodity.gameObject:SetActiveEx(false)
    self.GridRewardCard.gameObject:SetActiveEx(false)
    self.PanelOn.gameObject:SetActiveEx(false)
    self.PanelOff.gameObject:SetActiveEx(false)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelCoating)
    self.DynamicTable:SetProxy(XUiTheatre4ShopGrid, self)
    self.DynamicTable:SetDelegate(self)
end

---@param mapId number
---@param gridData XTheatre4Grid
---@param callback function 回调
function XUiTheatre4Shop:OnStart(mapId, gridData, callback)
    self.MapId = mapId
    self.GridData = gridData
    self.Callback = callback
    self.ShopId = gridData:GetGridShopId()
end

function XUiTheatre4Shop:OnEnable()
    self.CurSelectIndex = nil
    self:RefreshGold()
    self:RefreshShopRefreshCost()
    self:RefreshCharacterInfo()
    self:RefreshShopInfo()
    self:RefreshShopList()
end

function XUiTheatre4Shop:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE4_UPDATE_ASSET_DATA,
    }
end

function XUiTheatre4Shop:OnNotify(event, ...)
    if event == XEventId.EVENT_THEATRE4_UPDATE_ASSET_DATA then
        self:RefreshGold()
        self:RefreshShopRefreshCost()
        self:RefreshShopList()
    end
end

function XUiTheatre4Shop:OnDestroy()
    if self.Callback then
        self.Callback()
    end
end

-- 刷新金币
function XUiTheatre4Shop:RefreshGold()
    -- 金币图标
    local icon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Gold)
    if icon then
        self.RImgGold:SetRawImage(icon)
    end
    -- 金币数量
    self.TxtNum.text = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.Gold)
end

-- 商店刷新消耗
function XUiTheatre4Shop:RefreshShopRefreshCost()
    -- 是否可刷新
    local isAvailable = self._Control.EffectSubControl:GetEffectShopRefreshAvailable()
    self.BtnRefresh.gameObject:SetActiveEx(isAvailable)
    if not isAvailable then
        return
    end
    -- 已刷新次数
    local refreshTimes = self.GridData:GetGridShopRefreshTimes()
    -- 刷新次数上限
    local refreshLimit = self._Control:GetShopRefreshLimit(self.ShopId)
    self.BtnRefresh:SetNameByGroup(0, XUiHelper.GetText("Theatre4ShopRefresh", refreshTimes, refreshLimit))
    -- 刷新消耗
    local cost = self:GetShopRefreshCost()
    -- 是否满足刷新消耗
    local isEnough = self._Control.AssetSubControl:CheckAssetEnough(XEnumConst.Theatre4.AssetType.Gold, nil, cost, true)
    self.BtnRefresh:SetDisable(refreshTimes >= refreshLimit or not isEnough)
    -- 刷新消耗Ui
    local panelConsume = isEnough and self.PanelOn or self.PanelOff
    panelConsume.gameObject:SetActiveEx(true)
    local consumeUi = XTool.InitUiObjectByUi({}, panelConsume)
    local goldIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Gold)
    if goldIcon then
        consumeUi.Icon:SetRawImage(goldIcon)
    end
    consumeUi.TxtCosumeNumber.text = cost
end

-- 获取商店刷新消耗
function XUiTheatre4Shop:GetShopRefreshCost()
    -- 已刷新次数
    local refreshTimes = self.GridData:GetGridShopRefreshTimes()
    -- 免费刷新次数
    local freeRefresh = self._Control:GetShopRefreshFreeTimes(self.ShopId)
    -- 刷新消耗(配置)
    local refreshCost = self._Control:GetShopRefreshCost(self.ShopId)
    if XTool.IsTableEmpty(refreshCost) then
        return 0
    end
    if refreshTimes < freeRefresh or #refreshCost == 0 then
        return 0
    end
    local index = math.min(#refreshCost, refreshTimes - freeRefresh + 1)
    return refreshCost[index] or 0
end

-- 获取打折后的价格
---@param price number 原价
function XUiTheatre4Shop:GetDiscountPrice(price)
    -- 免费购买次数
    local freeBuyTimes = self.GridData:GetGridShopFreeBuyTimes()
    if freeBuyTimes > 0 then
        return 0
    end
    -- 折扣
    local discount = self.GridData:GetGridShopDiscount()
    return math.floor(price * discount)
end

-- 刷新角色信息
function XUiTheatre4Shop:RefreshCharacterInfo()
    local roleIcon = self._Control:GetShopRoleIcon(self.ShopId)
    if roleIcon then
        self.PanelRole.gameObject:SetActiveEx(true)
        self.RImgRole:SetRawImage(roleIcon)
    else
        self.PanelRole.gameObject:SetActiveEx(false)
        return
    end
    self.TxtRoleName.text = self._Control:GetShopRoleName(self.ShopId)
    self.TxtRoleContent.text = self._Control:GetShopRoleContent(self.ShopId)
end

-- 刷新商店信息
function XUiTheatre4Shop:RefreshShopInfo()
    local bgAsset = self._Control:GetShopBgAsset(self.ShopId)
    if bgAsset then
        self.Background:SetRawImage(bgAsset)
    end
    -- 标题
    self.TxtTitle.text = self._Control:GetShopTitle(self.ShopId)
    -- 标题内容
    self.TxtContent.text = self._Control:GetShopTitleContent(self.ShopId)
end

-- 刷新商店列表
function XUiTheatre4Shop:RefreshShopList()
    -- 商店商品列表
    self.ShopGoods = self.GridData:GetGridShopGoods()
    if XTool.IsTableEmpty(self.ShopGoods) then
        return
    end
    self.DynamicTable:SetDataSource(self.ShopGoods)
    self.DynamicTable:ReloadDataSync()
end

--动态列表事件
---@param grid XUiTheatre4ShopGrid
function XUiTheatre4Shop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.ShopGoods[index])
        grid:SetSelect(self.CurSelectIndex and self.CurSelectIndex == index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.CurSelectIndex == index then
            self:CloseRewardCard()
            return
        end
        -- 检查商品是否售完
        if grid:IsSoldOut() then
            self._Control:ShowRightTipPopup(XUiHelper.GetText("Theatre4ShopStockNotEnough"))
            return
        end
        if self.CurSelectIndex then
            local lastGrid = self.DynamicTable:GetGridByIndex(self.CurSelectIndex)
            if lastGrid then
                lastGrid:SetSelect(false)
            end
        end
        self.CurSelectIndex = index
        grid:SetSelect(true)
        self:ShowRewardCard(self.ShopGoods[index], index)
    end
end

-- 显示奖励卡
function XUiTheatre4Shop:ShowRewardCard(shopGoodsData, index)
    if not self.PanelRewardCard then
        ---@type XUiPanelTheatre4ShopRewardCard
        self.PanelRewardCard = XUiPanelTheatre4ShopRewardCard.New(self.GridRewardCard, self)
    end
    self.PanelRewardCard:Open()
    self.PanelRewardCard:Update(shopGoodsData, index)
    self.BtnOK:SetNameByGroup(0, self._Control:GetClientConfig("ShopSureText", 2))
end

-- 关闭奖励卡
function XUiTheatre4Shop:CloseRewardCard()
    if self.CurSelectIndex then
        -- 取消选择
        local grid = self.DynamicTable:GetGridByIndex(self.CurSelectIndex)
        if grid then
            grid:SetSelect(false)
        end
        self.CurSelectIndex = nil
    end
    if self.PanelRewardCard then
        self.PanelRewardCard:Close()
        self.BtnOK:SetNameByGroup(0, self._Control:GetClientConfig("ShopSureText", 1))
    end
end

-- 清理数据
function XUiTheatre4Shop:ClearData()
    self.ShopGoods = nil
    self:CloseRewardCard()
end

-- 购买商品
function XUiTheatre4Shop:BuyGoods(index)
    -- 购买商品
    local posX, posY = self.GridData:GetGridPos()
    self._Control:ShopBuyRequest(self.MapId, posX, posY, index, function(shopData)
        self.GridData:UpdateShop(shopData)
        self:ClearData()
        self:RefreshShopList()
        self._Control:CheckNeedOpenNextPopup()
    end)
end

function XUiTheatre4Shop:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGold, self.OnBtnGoldClick)
    self._Control:RegisterClickEvent(self, self.BtnOK, self.OnBtnOKClick)
    self._Control:RegisterClickEvent(self, self.BtnRefresh, self.OnBtnRefreshClick)
end

function XUiTheatre4Shop:OnBtnCloseClick()
    -- 检查奖励卡是否打开
    if self.PanelRewardCard and self.PanelRewardCard:IsNodeShow() then
        self:CloseRewardCard()
        return
    end
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_RECOVER_CAMERA_POS)
    self:Close()
end

function XUiTheatre4Shop:OnBtnGoldClick()
    -- 打开金币详情
    XLuaUiManager.Open("UiTheatre4PopupItemDetail", nil, XEnumConst.Theatre4.AssetType.Gold)
end

function XUiTheatre4Shop:OnBtnOKClick()
    if self.PanelRewardCard and self.PanelRewardCard:IsNodeShow() then
        self.PanelRewardCard:OnBtnYesClick()
    else
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_RECOVER_CAMERA_POS)
        self:Close()
    end
end

function XUiTheatre4Shop:OnBtnRefreshClick()
    -- 检查刷新次数是否足够
    local refreshTimes = self.GridData:GetGridShopRefreshTimes()
    local refreshLimit = self._Control:GetShopRefreshLimit(self.ShopId)
    if refreshTimes >= refreshLimit then
        self._Control:ShowRightTipPopup(XUiHelper.GetText("Theatre4RefreshTimesNotEnough"))
        return
    end
    -- 检查金币是否足够
    local cost = self:GetShopRefreshCost()
    if not self._Control.AssetSubControl:CheckAssetEnough(XEnumConst.Theatre4.AssetType.Gold, nil, cost) then
        return
    end
    -- 刷新商店
    local posX, posY = self.GridData:GetGridPos()
    self._Control:RefreshGoodsRequest(self.MapId, posX, posY, function(shopData)
        self.GridData:UpdateShop(shopData)
        self:ClearData()
        self:RefreshShopRefreshCost()
        self:RefreshShopList()
    end)
end

return XUiTheatre4Shop
