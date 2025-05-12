local XUiPanelPurchaseItemListBase = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPanelPurchaseItemList/XUiPanelPurchaseItemListBase')

---@class XUiPanelRandomSelectPurchaseItemList: XUiPanelPurchaseItemListBase
local XUiPanelRandomSelectPurchaseItemList = XClass(XUiPanelPurchaseItemListBase, 'XUiPanelRandomSelectPurchaseItemList')
local XUiGridPurchaseChoiceItem = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPanelPurchaseItemList/XUiGridPurchaseChoiceItem')

function XUiPanelRandomSelectPurchaseItemList:OnStart()
    self.PanelAdd.CallBack = handler(self, self.OnAddClick)
    self.ImgTitle.CallBack = handler(self, self.OnTipsClick)
    self.BtnReceiveBlueLight.CallBack = handler(self, self.OnAddClick)
end

function XUiPanelRandomSelectPurchaseItemList:Refresh(data, showBuyTimes)
    if data then
        self.Data = data
    end

    if XTool.IsTableEmpty(self.Data) then
        return
    end

    if XTool.IsNumberValid(showBuyTimes) then
        self._ShowBuyTimes = showBuyTimes
    end

    -- 是否还可购买
    self._CanBuy = not XTool.IsNumberValid(self.Data.BuyTimes) or self.Data.BuyTimes < self._ShowBuyTimes
    
    local isEmpty = true
    
    -- 可购买一定显示玩家选择
    local showSelect = self._CanBuy
    ---@type XPurchaseSelectionData
    local selectionData = XDataCenter.PurchaseManager.GetPurchaseSelectionData()

    if showSelect then
        if not XTool.IsTableEmpty(selectionData) and not XTool.IsTableEmpty(selectionData.RandomBoxChoices) then -- 先判断有没有选择，优先显示玩家的选择
            isEmpty = false
        end
    else
        isEmpty = false
    end

    self.PanelHksd.gameObject:SetActiveEx(not isEmpty)
    self.PanelAdd.gameObject:SetActiveEx(isEmpty)
    
    self.BtnReceiveBlueLight.gameObject:SetActiveEx(false)
    --self.BtnReceiveBlueLight.transform:SetParent(self.RootForResetBtn.transform)

    if not isEmpty then
        if showSelect then
            self:_ShowPlayerSelection()
        else
            self:_ShowLastBuyResult(self._ShowBuyTimes)
        end
    end
end

function XUiPanelRandomSelectPurchaseItemList:SetIsNormalAllOwn(isNormalAllOwn)
    self._IsNormalAllOwn = isNormalAllOwn
end

function XUiPanelRandomSelectPurchaseItemList:_ShowPlayerSelection()
    --- lua实例与gameobject映射字典，需要长期缓存
    if self._ItemMap == nil then
        self._ItemMap = {}
    end

    --- lua实例的索引列表，每次刷新都重新映射一遍
    self._ItemList = {}
    
    ---@type XPurchaseSelectionData
    local selectData = XDataCenter.PurchaseManager.GetPurchaseSelectionData()
    local rewardGoods = self.Data.SelectDataForClient.RandomGoods
    
    XUiHelper.RefreshCustomizedList(self.PanelReward, self.PanelPropItem, selectData.RandomBoxChoices and #selectData.RandomBoxChoices or 0, function(index, go)
        local item = self._ItemMap[go]

        if not item then
            item = XUiGridPurchaseChoiceItem.New(go, self)
            item:Init(self.Parent)
            self._ItemMap[go] = item
        end

        local id = selectData.RandomBoxChoices[index]

        self._ItemList[index] = item
        item:SetShowHistroySelection(true)
        item:SetItemStatus(false, false, true)
        for i, v in pairs(rewardGoods) do
            if v.Id == id then
                item:OnRefresh(v.RewardGoods)
                break
            end
        end
    end)
    
    -- 如果有道具，则需要显示更换图标，且更换图标在首位
    if not XTool.IsTableEmpty(selectData.RandomBoxChoices) then
        --self.BtnReceiveBlueLight.transform:SetParent(self.PanelReward)
        --self.BtnReceiveBlueLight.transform:SetAsFirstSibling()
        self.BtnReceiveBlueLight.gameObject:SetActiveEx(true)
    end
end

function XUiPanelRandomSelectPurchaseItemList:_ShowLastBuyResult(showBuyTimes)
    --- lua实例与gameobject映射字典，需要长期缓存
    if self._ItemMap == nil then
        self._ItemMap = {}
    end

    --- lua实例的索引列表，每次刷新都重新映射一遍
    self._ItemList = {}

    local selectRecordData = self.Data.SelectDataForClient.SelectData
    if not XTool.IsTableEmpty(selectRecordData) then
        if not XTool.IsTableEmpty(selectRecordData.RandomSelectRecords) then
            -- 显示指定次的记录
            local index = XMath.Clamp(showBuyTimes, 1, #selectRecordData.RandomSelectRecords)
            local randomRecordData = selectRecordData.RandomSelectRecords[index]
            -- 拷贝顶层的表, 用于排序操作
            local rewardGoods = {}
            for i, v in pairs(self.Data.SelectDataForClient.RandomGoods) do
                local goodsDataClone = {
                    Id = v.Id,
                    RewardGoods = v.RewardGoods
                }
                table.insert(rewardGoods, goodsDataClone)
            end
            -- 排序：抽出>选择>未选择
            table.sort(rewardGoods, function(a, b)
                a.IsGet = a.Id == randomRecordData.RandomGoodsId
                b.IsGet = b.Id == randomRecordData.RandomGoodsId

                if a.IsGet ~= b.IsGet then
                    a.IsSelect = a.IsGet and true or a.IsSelect
                    b.IsSelect = b.IsGet and true or b.IsSelect
                    return a.IsGet
                end

                a.IsSelect = table.contains(randomRecordData.SelectIds, a.Id)
                b.IsSelect = table.contains(randomRecordData.SelectIds, b.Id)

                if a.IsSelect ~= b.IsSelect then
                    return a.IsSelect
                end
                
                return a.Id > b.Id
            end)
            
            -- 所有可选都展示
            XUiHelper.RefreshCustomizedList(self.PanelReward, self.PanelPropItem, rewardGoods and #rewardGoods or 0, function(index, go)
                local item = self._ItemMap[go]

                if not item then
                    item = XUiGridPurchaseChoiceItem.New(go, self)
                    item:Init(self.Parent)
                    self._ItemMap[go] = item
                end
                
                self._ItemList[index] = item
                
                local goodsData = rewardGoods[index]
                
                item:SetShowHistroySelection(true)
                item:OnRefresh(goodsData.RewardGoods)
                item:SetItemStatus(goodsData.IsGet or false, goodsData.IsSelect or false)
            end)
        end
    end
end

function XUiPanelRandomSelectPurchaseItemList:OnAddClick()
    if self._IsNormalAllOwn then
        return
    end
    
    XLuaUiManager.OpenWithCloseCallback('UiPurchaseRandomBoxSelection', function()
        self:Refresh()
        self.Parent:RefreshBuyButtonStatus()
        self.Parent:RefreshRewardContainsOwnShow()
    end, self.Data, self._ShowBuyTimes)
end

function XUiPanelRandomSelectPurchaseItemList:OnTipsClick()
    XLuaUiManager.Open('UiPurchaseRandomRewardTips', self.Data, self._ShowBuyTimes)
end

return XUiPanelRandomSelectPurchaseItemList