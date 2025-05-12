local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--######################## XUiShopItem ########################
local XUiShopItem = XClass(XUiNode, "XUiShopItem")

--function XUiShopItem:Ctor(ui, rootUi)
--    self.RootUi = rootUi
--    XUiHelper.InitUiClass(self, ui)
--    -- XAShopItem
--    self.Data = nil
--end

-- data : XAShopItem
function XUiShopItem:SetData(data, isLock)
    self.Data = data
    self.Lock.gameObject:SetActiveEx(isLock)
    if isLock then return end
    local price = data:GetPrice()
    local count = data:GetCount()
    self.TxtCostCount.text = string.format( "X%s", price)
    local costTextColor = XDataCenter.ItemManager.GetCount(XTheatreConfigs.TheatreCoin) < price and "FF0000" or "2C2929"
    self.TxtCostCount.color = XUiHelper.Hexcolor2Color(costTextColor)
    self.RImgCostIcoin:SetRawImage(XEntityHelper.GetItemIcon(XTheatreConfigs.TheatreCoin))
    self.RImgIcon:SetRawImage(data:GetIcon())
    self.RImgIcon2:SetRawImage(data:GetIcon())
    self.TxtCount.text = string.format( "x%s", count)
    self.PanelCount.gameObject:SetActiveEx(count >= 1)
    self.TxtName.text = data:GetName()
    self.ImgHave.gameObject:SetActiveEx(not data:GetIsCanBuy())
    local itemId = data:GetItemId()
    if itemId then
        XUiGridCommon.New(self.Parent, self.ItemGrid):Refresh({
            TemplateId = itemId,
            Count = data:GetCount(),
        })
    else
        XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClicked)
    end
    local itemType = data:GetItemType()
    self.RImgIcon.gameObject:SetActiveEx(itemType ~= XTheatreConfigs.AdventureRewardType.SelectSkill)
    self.RImgIcon2.gameObject:SetActiveEx(itemType == XTheatreConfigs.AdventureRewardType.SelectSkill)
end

function XUiShopItem:OnBtnClicked()
    local rewardType = self.Data:GetItemType()
    local configNname
    if rewardType == XTheatreConfigs.AdventureRewardType.SelectSkill then
        configNname = "SelectSkillDetail"
    elseif rewardType == XTheatreConfigs.AdventureRewardType.LevelUp then
        configNname = "LevelUpDetail"
    else
        return
    end
    local powerId = self.Data:GetPowerId()
    local icon = XTheatreConfigs.GetClientConfig(configNname, 1)
    local title = XTheatreConfigs.GetClientConfig(configNname, 2)
    local content = XTheatreConfigs.GetClientConfig(configNname, 3)
    if rewardType == XTheatreConfigs.AdventureRewardType.SelectSkill then
        icon = string.format(icon, XTheatreConfigs.GetClientConfig("SelectSkillDetailIcon", powerId))
        content = string.format(content, XTheatreConfigs.GetClientConfig("SelectSkillDetailDesc", powerId))
    end
    XLuaUiManager.Open("UiTheatreGroupTip", icon, self.Data:GetName(), title, content
    , rewardType == XTheatreConfigs.AdventureRewardType.SelectSkill)
end

--######################## XUiShopNodePanel ########################
---@class XUiShopNodePanel:XUiNode
local XUiShopNodePanel = XClass(XUiNode, "XUiShopNodePanel")

function XUiShopNodePanel:OnStart(ui, rootUi)
    --XUiHelper.InitUiClass(self, ui)
    --self.RootUi = rootUi
    self.Node = nil
    -- 商店列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelShopList)
    self.DynamicTable:SetProxy(XUiShopItem, self.Parent)
    self.DynamicTable:SetDelegate(self)
    self.ShopGrid.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnBackOut, self.OnBtnBackOutClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnEnd, self.OnBtnEndClicked)
    -- 注册资源面板
    XUiHelper.NewPanelActivityAssetSafe(XDataCenter.TheatreManager.GetAdventureAssetItemIds(), self.PanelAssetitems, self)
end

-- node : XAShopNode
function XUiShopNodePanel:SetData(node)
    self.Node = node
    -- 描述
    self.TxtContent.text = node:GetDesc()
    self:RefreshShopItems()
end

function XUiShopNodePanel:RefreshShopItems()
    -- 刷新商品
    local shopItems = XTool.Clone(self.Node:GetShopItems())
    local totalCount = #shopItems
    if totalCount < XTheatreConfigs.ShopMaxItemCount then
        for i = 1, XTheatreConfigs.ShopMaxItemCount - totalCount do
            table.insert(shopItems, {})
        end
    end
    self.DynamicTable:SetDataSource(shopItems)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiShopNodePanel:OnDynamicTableEvent(event, index, grid)
    local data = self.DynamicTable.DataSource[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(data, table.nums(data) <= 0)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        -- 空的，占位用的，不处理
        if table.nums(data) <= 0 then return end
        -- 已经买过了，不处理
        if not data:GetIsCanBuy() then return end
        -- 二次确认
        local buyTips = XUiHelper.GetText("TheatreAdventureShopBuyTips"
            , data:GetPrice(), XEntityHelper.GetItemName(XTheatreConfigs.TheatreCoin)
            , math.max(data:GetCount(), 1), data:GetName(), data:GetDesc())
        XLuaUiManager.Open("UiDialog", nil, buyTips, XUiManager.DialogType.Normal, nil
            , function()
                self.Node:RequestBuyItem(data, function()
                    self:RefreshShopItems()
                    XDataCenter.TheatreManager.GetCurrentAdventureManager():ShowNextOperation()
                end)
            end)
    end
end

function XUiShopNodePanel:OnBtnBackOutClicked()
    self.Parent:Close()
end

function XUiShopNodePanel:OnBtnEndClicked()
    XLuaUiManager.Open("UiDialog", nil, XUiHelper.GetText("TheatreEndShopTip"), XUiManager.DialogType.Normal, nil
    , function()
        self.Node:RequestEndBuy(function()
            self.Parent:SwitchComfirmPanel(self.Node:GetEndDesc(), self.Node:GetEndComfirmText()
                , function() self.Parent:Close() end)
        end)
    end)
end

return XUiShopNodePanel
