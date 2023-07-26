local XUiShop = require("XUi/XUiShop/XUiShop")

---@class XUiDlcHuntShop:XUiShop
local XUiDlcHuntShop = XLuaUiManager.Register(XUiShop, "UiDlcHuntShop")

function XUiDlcHuntShop:Ctor()
    self.UiParams = {
        CanBuyColor = "FFFFFFFF",
        CanNotBuyColor = "E53E3EFF",
    }
end

function XUiDlcHuntShop:OnStart(typeId, cb, configShopId, screenId)
    if type(typeId) == "function" then
        cb = typeId
        typeId = nil
    end

    if typeId then
        self.Type = typeId
    else
        self.Type = XShopManager.ShopType.DlcHunt
    end

    self.cb = cb
    self.ConfigShopId = configShopId
    self.ScreenId = screenId

    local itemIdList = { XDataCenter.ItemManager.ItemId.DlcHunt, XDataCenter.ItemManager.ItemId.DlcHuntCoin1, XDataCenter.ItemManager.ItemId.DlcHuntCoin2 }
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.DlcHunt, XDataCenter.ItemManager.ItemId.DlcHuntCoin1, XDataCenter.ItemManager.ItemId.DlcHuntCoin2)
    local funcOpenDetailList = {}
    for i = 1, #itemIdList do
        local funcOpenDetail = function()
            --展示物品详情
            local itemId = itemIdList[i]
            local item = XDataCenter.ItemManager.GetItem(itemId)
            local data = {
                Id = itemId,
                Count = item ~= nil and tostring(item.Count) or "0"
            }
            XLuaUiManager.Open("UiDlcHuntTip", data)
        end
        funcOpenDetailList[i] = funcOpenDetail
    end
    self.AssetPanel:RegisterJumpCallList(funcOpenDetailList)
    self.ItemList = XUiPanelItemList.New(self.PanelItemList, self, nil, self.UiParams)

    --self.AssetActivityPanel:HidePanel()
    self.ItemList:HidePanel()

    self.CallSerber = false
    self.BtnGoList = {}
    self.ShopTables = {}
    self.tagCount = 1
    self.shopGroup = {}

    self.ScreenGroupIDList = {}
    self.ScreenNum = 1
    self.IsHasScreen = false
    self.RefreshBuyTime = 0

    XShopManager.ClearBaseInfoData()
    self.GridShop.gameObject:SetActiveEx(false)
end

function XUiDlcHuntShop:OnAwake()
    self:BindExitBtns()
    XUiDlcHuntShop.Super.OnAwake(self)
end

function XUiDlcHuntShop:OnEnable()
    XUiShop.Super.OnEnable(self)
    XShopManager.GetBaseInfo(function()
        local infoList = XShopManager.GetShopBaseInfoByType(XShopManager.ShopType.DlcHunt)
        local info = infoList[1]
        if info then
            local id = info.Id
            self.CurShopId = id
            XShopManager.GetShopInfo(id, function()
                self.ItemList:ShowPanel(id)
            end)
        end
    end)
end

function XUiDlcHuntShop:OnDestroy()
    --self.AssetActivityPanel:HidePanel()
    self.ItemList:HidePanel()
end

function XUiDlcHuntShop:AutoAddListener()
end

function XUiDlcHuntShop:UpdateBuy(data, cb, proxy)
    --XLuaUiManager.Open("UiShopItem", self, data, cb, nil, proxy)
    XLuaUiManager.Open("UiDlcShopTip", self, data, cb, nil, proxy)
end

function XUiDlcHuntShop:RefreshBuy(is4RequestRefresh)
    self.RefreshBuyTime = os.clock()
    --self.AssetActivityPanel:Refresh(XShopManager.GetShopShowIdList(self.CurShopId))
    self:UpdateList(self.CurShopId, is4RequestRefresh)
end

function XUiDlcHuntShop:UpdateList(shopId, is4RequestRefresh)
    local isKeepOrder = os.clock() - self.RefreshBuyTime < 0.5 -- 刚购买之后0.5秒内的刷新, 不改变商品顺序
    if is4RequestRefresh then
        isKeepOrder = falses
    end
    --self.AssetActivityPanel:Refresh(XShopManager.GetShopShowIdList(shopId))
    self.ItemList:ShowPanel(shopId)
    self:UpdateRefreshTips(shopId)
end

function XUiDlcHuntShop:UpdateRefreshTips(shopId)
end

return XUiDlcHuntShop