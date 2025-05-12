---@class XUiPanelPurchaseRandomGotDetail: XUiNode
local XUiPanelPurchaseRandomGotDetail = XClass(XUiNode, 'XUiPanelPurchaseRandomGotDetail')
local XUiGridPurchaseRandomGotDetail = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPurchaseRandomRewardTips/XUiGridPurchaseRandomGotDetail')

---@param rootUi XLuaUi
function XUiPanelPurchaseRandomGotDetail:OnStart(data, showBuyTimes, rootUi)
    self.Data = data
    self._ShowBuyTimes = showBuyTimes or 1

    -- 是否还可购买
    self._HadBuy = XTool.IsNumberValid(self.Data.BuyTimes) and self.Data.BuyTimes >= self._ShowBuyTimes
    self.RootUi = rootUi
end

function XUiPanelPurchaseRandomGotDetail:OnEnable()
    self:Refresh()
end

function XUiPanelPurchaseRandomGotDetail:Refresh()
    --- lua实例与gameobject映射字典，需要长期缓存
    if self._ItemMap == nil then
        self._ItemMap = {}
    end

    --- lua实例的索引列表，每次刷新都重新映射一遍
    self._ItemList = {}
    
    -- 拷贝顶层的表, 用于排序操作
    local rewardGoods = {}
    for i, v in pairs(self.Data.SelectDataForClient.RandomGoods) do
        local goodsDataClone = {
            Id = v.Id,
            RewardGoods = v.RewardGoods,
        }
        table.insert(rewardGoods, goodsDataClone)
    end

    if not self._HadBuy then
        -- 展示选择
        local selectionData = XDataCenter.PurchaseManager.GetPurchaseSelectionData()
        if not XTool.IsTableEmpty(selectionData.RandomBoxChoices) then
            -- 排序：选择>未选择
            table.sort(rewardGoods, function(a, b)
                a.IsSelect = table.contains(selectionData.RandomBoxChoices, a.Id)
                b.IsSelect = table.contains(selectionData.RandomBoxChoices, b.Id)

                if a.IsSelect ~= b.IsSelect then
                    return a.IsSelect
                end

                return a.Id > b.Id
            end)
        end
    else
        -- 否则展示上一次的结果
        local selectRecordData = self.Data.SelectDataForClient.SelectData
        if not XTool.IsTableEmpty(selectRecordData) then
            if not XTool.IsTableEmpty(selectRecordData.RandomSelectRecords) then
                -- 只显示最后一个
                local index = XMath.Clamp(self._ShowBuyTimes, 1, #selectRecordData.RandomSelectRecords)
                local randomRecordData = selectRecordData.RandomSelectRecords[index]
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
            end
        end
    end
    
    -- 处理概率展示
    local rewardCount = self.Data.SelectDataForClient.RandomSelectCount
    local percent = XTool.IsNumberValid(rewardCount) and (1 / rewardCount) or 0
    local percentContent = string.format("%.2f%%", percent * 100, "%")


    -- 所有可选都展示
    XUiHelper.RefreshCustomizedList(self.PanelTxtParent.transform.parent, self.PanelTxtParent, rewardGoods and #rewardGoods or 0, function(index, go)
        local item = self._ItemMap[go]

        if not item then
            item = XUiGridPurchaseRandomGotDetail.New(go, self)
            item:SetRootUi(self.RootUi)
            self._ItemMap[go] = item
        end

        self._ItemList[index] = item

        local goodsData = rewardGoods[index]

        item:Refresh(goodsData.RewardGoods, percentContent, goodsData.IsGet or false, goodsData.IsSelect or false, self._HadBuy)
    end)
end

return XUiPanelPurchaseRandomGotDetail