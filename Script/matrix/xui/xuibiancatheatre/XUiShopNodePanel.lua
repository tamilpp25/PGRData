local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--######################## XUiShopItem ########################
local XUiBiancaTheatreItemGrid = require("XUi/XUiBiancaTheatre/Common/XUiBiancaTheatreItemGrid")
local XUiShopItem = XClass(nil, "XUiShopItem")

function XUiShopItem:Ctor(ui, rootUi)
    self.RootUi = rootUi
    XUiHelper.InitUiClass(self, ui)
    -- XAShopItem
    self.Data = nil
    self.TheatreItemGrid = XUiBiancaTheatreItemGrid.New(self.ItemGrid, true)
end

-- data: XAShopNode.lua的XAShopItem
function XUiShopItem:SetData(data)
    self.Data = data
    local isLock = data:GetIsLock()
    local isSellOut = data:GetIsSellOut()
    self.Lock.gameObject:SetActiveEx(isLock and not isSellOut)
    self.TxtCostCount.text = ""
    self.ImgDiscount.gameObject:SetActiveEx(false)
    self.ItemGrid.gameObject:SetActiveEx(not isLock)
    self.TxtName.text = ""
    self.RImgCostIcoin.gameObject:SetActiveEx(not isLock)
    self.ImgHave.gameObject:SetActiveEx(isSellOut)
    self.Bg.gameObject:SetActiveEx(not isSellOut)
    if isLock or isSellOut then return end
    
    --售价
    local discountPrice = data:GetDiscountPrice()
    local count = data:GetCount()
    self.TxtCostCount.text = string.format( "X%s", discountPrice)
    local costTextColor = XDataCenter.ItemManager.GetCount(XBiancaTheatreConfigs.TheatreInnerCoin) < discountPrice and "BA5E5E" or "ABABAB"
    self.TxtCostCount.color = XUiHelper.Hexcolor2Color(costTextColor)
    --打xx折
    local price = data:GetPrice()
    local disCount = (price ~= 0 and discountPrice - price ~= 0) and discountPrice / price * 10 or 0
    local _, remainder = math.modf(disCount)
    local disCountDesc = remainder > 0 and string.format("%.1f", disCount) or disCount
    self.TxtDiscount.text = XUiHelper.GetText("BuyAssetDiscountText", disCountDesc)
    self.ImgDiscount.gameObject:SetActiveEx(XTool.IsNumberValid(disCount))
    --价格图标
    self.RImgCostIcoin:SetRawImage(XEntityHelper.GetItemIcon(XBiancaTheatreConfigs.TheatreInnerCoin))
    --出售数量
    self.TxtCount.text = string.format( "x%s", count)
    self.PanelCount.gameObject:SetActiveEx(count >= 1)
    --商品名
    self.TxtName.text = data:GetName()
    --是否已购买
    local isCanBuy = data:GetIsCanBuy()
    self.ImgHave.gameObject:SetActiveEx(not isCanBuy)
    self.Bg.gameObject:SetActiveEx(isCanBuy)
    --道具格子数据
    local itemId = data:GetItemId()
    local itemType = data:GetItemType()
    local quality = data:GetQuality()
    if itemId and itemType == XBiancaTheatreConfigs.XNodeShopItemType.Item then
        self.TheatreItemGrid:Refresh(itemId, nil, data:GetCount())
    else
        self.RImgIcon:SetRawImage(data:GetItemIcon())
        --品质图标
        if quality then
            self.ImgQuality:SetSprite(XArrangeConfigs.GeQualityPath(quality))
        end
        self.ImgQuality.gameObject:SetActiveEx(quality and true or false)
    end
    --品质颜色
    local color = XBiancaTheatreConfigs.GetQualityTextColor(quality)
    if color then
        self.TxtName.color = color
    end 
end

--######################## XUiShopNodePanel ########################
local XUiShopNodePanel = XClass(nil, "XUiShopNodePanel")

function XUiShopNodePanel:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    self.RootUi = rootUi
    self.Node = nil
    -- 商店列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelShopList)
    self.DynamicTable:SetProxy(XUiShopItem, self.RootUi)
    self.DynamicTable:SetDelegate(self)
    self.ShopGrid.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnOK, self.OnBtnEndClicked)
    self.PanelAssetitems.gameObject:SetActiveEx(false)
end

-- node : XAShopNode
function XUiShopNodePanel:SetData(node)
    self.Node = node
    self.DiscountRate = node:GetDiscountRate()
    self.TxtTitle.text = node:GetTitleContent()
    -- 描述
    self.TxtContent.text = node:GetDesc()
    self:RefreshShopItems()
end

function XUiShopNodePanel:RefreshShopItems()
    -- 刷新商品
    self.DynamicTable:SetDataSource(self.Node:GetShopItems())
    self.DynamicTable:ReloadDataSync(1)
end

function XUiShopNodePanel:OnDynamicTableEvent(event, index, grid)
    local data = self.DynamicTable.DataSource[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(data, self.DiscountRate)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        -- 未解锁不处理
        if data:GetIsLock() then return end
        -- 已经买过了，不处理
        if not data:GetIsCanBuy() then return end
        -- 二次确认
        XLuaUiManager.Open("UiBiancaTheatreShopTips", data, function()
            self.Node:RequestBuyItem(data, function()
                if not XTool.UObjIsNil(self.GameObject) then
                    self:RefreshShopItems()
                end
                XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():ShowNextOperation()
            end)
        end)
    end
end

--货币点击方法
function XUiShopNodePanel:OnBtnClick(index)
    XLuaUiManager.Open("UiBiancaTheatreTips", XBiancaTheatreConfigs.TheatreInnerCoin)
end

function XUiShopNodePanel:OnBtnEndClicked()
    XLuaUiManager.Open("UiBiancaTheatreEndTips", nil, XUiHelper.GetText("TheatreEndShopTip"), XUiManager.DialogType.Normal, nil
    , function()
        self.RootUi:SetCloseFunc(function()
            self.Node:RequestEndBuy()
        end)
        self.RootUi:SwitchComfirmPanel(self.Node:GetEndDesc(), self.Node:GetEndComfirmText(), function()
            self.RootUi:Close()
        end)
    end)
end

return XUiShopNodePanel
