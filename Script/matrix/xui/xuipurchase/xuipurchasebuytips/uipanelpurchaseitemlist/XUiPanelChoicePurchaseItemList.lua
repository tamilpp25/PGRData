local XUiPanelPurchaseItemListBase = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPanelPurchaseItemList/XUiPanelPurchaseItemListBase')
local XUiGridPurchaseChoiceItem = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPanelPurchaseItemList/XUiGridPurchaseChoiceItem')

---@class XUiPanelChoicePurchaseItemList: XUiPanelPurchaseItemListBase
local XUiPanelChoicePurchaseItemList = XClass(XUiPanelPurchaseItemListBase, 'XUiPanelChoicePurchaseItemList')

function XUiPanelChoicePurchaseItemList:OnStart()
    self:HideSelectList()
    self.ImgTitle.CallBack = handler(self, self.OnTipsClick)
    self.ImgBtnClose.CallBack = handler(self, self.HideSelectList)
    self.ImgBtnClose.gameObject:SetActiveEx(false)
end

function XUiPanelChoicePurchaseItemList:Refresh(data, showBuyTimes)
    self.Data = data

    -- 是否还可购买
    self._CanBuy = not XTool.IsNumberValid(self.Data.BuyTimes) or self.Data.BuyTimes < showBuyTimes
    self._ShowBuyTimes = showBuyTimes
    
    -- 按组的数量初始化格子
    self:_RefreshItemList()

    self.ImgTitle:SetNameByGroup(0, XUiHelper.GetText('PurchaseSelfChoiceProgressTitle', 0, XTool.GetTableCount(self.Data.SelectDataForClient.SelectGroups)))
    
    -- 可购买必不存在记录，显示玩家的选择
    if self._CanBuy then
        ---@type XPurchaseSelectionData
        local selectionData = XDataCenter.PurchaseManager.GetPurchaseSelectionData()

        if not XTool.IsTableEmpty(selectionData) and not XTool.IsTableEmpty(selectionData.SelfChoices) then
            self:_ShowPlayerSelection()
        end
        return
    end
    
    -- 再判断有没有上次购买的选择
    if XTool.IsNumberValid(self.Data.BuyTimes) then
        self:_ShowLastBuyResult(showBuyTimes)
    end
end

function XUiPanelChoicePurchaseItemList:SetIsNormalAllOwn(isNormalAllOwn)
    self._IsNormalAllOwn = isNormalAllOwn

    if not XTool.IsTableEmpty(self._ItemList) then
        for i, v in pairs(self._ItemList) do
            v:SetIsNormalAllOwn(self._IsNormalAllOwn)
        end
    end
end

function XUiPanelChoicePurchaseItemList:_RefreshItemList()
    local groups = self.Data.SelectDataForClient.SelectGroups

    --- lua实例与gameobject映射字典，需要长期缓存
    if self._ItemMap == nil then
        self._ItemMap = {}
    end

    --- lua实例的索引列表，每次刷新都重新映射一遍
    if not XTool.IsTableEmpty(self._ItemList) then
        for i, v in pairs(self._ItemList) do
            v:Close()
        end
    end
    self._ItemList = {}
    
    XUiHelper.RefreshCustomizedList(self.PanelReward, self.PanelPropItem, groups and #groups or 0, function(index, go)
        local item = self._ItemMap[go]

        if not item then
            item = XUiGridPurchaseChoiceItem.New(go, self)
            item:Init(self.Parent)
            self._ItemMap[go] = item
        end

        self._ItemList[groups[index].GroupId] = item

        item:SetShowHistroySelection(false)
        item:SetEnableSelect(self._CanBuy)
        item:SetIsNormalAllOwn(self._IsNormalAllOwn)
        item:SetGroupIndex(index)
        item:Open()
    end)
end

function XUiPanelChoicePurchaseItemList:_ShowPlayerSelection()
    -- 先全隐藏
    if not XTool.IsTableEmpty(self._ItemList) then
        for i, v in pairs(self._ItemList) do
            v:SetShowHistroySelection(false)
        end
    end
    
    -- 显示选择了的内容
    ---@type XPurchaseSelectionData
    local selectData = XDataCenter.PurchaseManager.GetPurchaseSelectionData()

    for groupId, id in pairs(selectData.SelfChoices) do
        local item = self._ItemList[groupId]
        -- 显示对应组内的物品
        local group = self.Data.SelectDataForClient.SelectGroups[groupId]

        for i, v in pairs(self.Data.SelectDataForClient.SelectGroups) do
            if v.GroupId == groupId then
                group = v
                break
            end
        end
        
        if group and item then
            for index2, rewardData in pairs(group.SelectGoods) do
                if rewardData.Id == id then
                    item:OnRefresh(rewardData.RewardGoods)
                    break
                end
            end
        end
    end
    
    -- 刷新选择进度
    self.ImgTitle:SetNameByGroup(0, XUiHelper.GetText('PurchaseSelfChoiceProgressTitle', XTool.GetTableCount(selectData.SelfChoices), XTool.GetTableCount(self.Data.SelectDataForClient.SelectGroups)))
end

function XUiPanelChoicePurchaseItemList:_ShowLastBuyResult(showRecordIndex)
    --- lua实例与gameobject映射字典，需要长期缓存
    if self._ItemMap == nil then
        self._ItemMap = {}
    end

    --- lua实例的索引列表，每次刷新都重新映射一遍
    self._ItemList = {}

    local selectRecordData = self.Data.SelectDataForClient.SelectData
    if not XTool.IsTableEmpty(selectRecordData) then
        if not XTool.IsTableEmpty(selectRecordData.SelectGoodsIdRecords) then
            -- 显示指定次的记录
            local index = XMath.Clamp(showRecordIndex, 1, #selectRecordData.SelectGoodsIdRecords)
            local selectRecordData = selectRecordData.SelectGoodsIdRecords[index]
            -- 构建组-商品映射表
            local group2GoodsMap = {}
            for i, v in pairs(selectRecordData.SelectGroups) do
                group2GoodsMap[v] = selectRecordData.SelectGroupGoodsIds[i]
            end
            
            -- 显示
            local groups = self.Data.SelectDataForClient.SelectGroups
            
            XUiHelper.RefreshCustomizedList(self.PanelReward, self.PanelPropItem, groups and #groups or 0, function(index, go)
                local item = self._ItemMap[go]

                if not item then
                    item = XUiGridPurchaseChoiceItem.New(go, self)
                    item:Init(self.Parent)
                    self._ItemMap[go] = item
                end

                local groupId = groups[index].GroupId
                
                self._ItemList[groupId] = item

                item:SetShowHistroySelection(true)
                item:SetEnableSelect(self._CanBuy)
                item:SetGroupIndex(index)
                item:SetIsNormalAllOwn(self._IsNormalAllOwn)
                local goodsId = group2GoodsMap[groupId]

                for i, v in pairs(groups[index].SelectGoods) do
                    if v.Id == goodsId then
                        item:OnRefresh(v.RewardGoods)
                        break
                    end
                end
                item:Open()
            end)
        end
    end
    
    local groupCount = XTool.GetTableCount(self.Data.SelectDataForClient.SelectGroups)

    self.ImgTitle:SetNameByGroup(0, XUiHelper.GetText('PurchaseSelfChoiceProgressTitle', groupCount, groupCount))

end

--region 选择界面
function XUiPanelChoicePurchaseItemList:ShowSelectList(groupIndex, selectGrid)
    self.PanelRewardSelectList.gameObject:SetActiveEx(true)
    self.BgMask.gameObject:SetActiveEx(true)
    self:RefreshItemInGroup(groupIndex)
    self.ImgBtnClose.gameObject:SetActiveEx(true)
    
    local followRect = self.ImgBtnCloseRectFollower.transform.rect
    self.ImgBtnClose.transform.position = self.ImgBtnCloseRectFollower.transform.position
    self.ImgBtnClose.transform.sizeDelta = followRect.size
    
    self.IsOpenSelfSelectPanel = true

    self._CurSelectGridItem = selectGrid

    if self._CurSelectGridItem then
        self._CurSelectGridItem:SetIsSelected(true)
    end
end

function XUiPanelChoicePurchaseItemList:RefreshItemInGroup(groupIndex)
    local group = self.Data.SelectDataForClient.SelectGroups[groupIndex]

    if XTool.IsTableEmpty(group) then
        XLog.Error('读取的组数据为空，组索引:'..tostring(groupIndex))
        return
    end

    --- lua实例与gameobject映射字典，需要长期缓存
    if self._ItemMapInGroup == nil then
        self._ItemMapInGroup = {}
    end

    --- lua实例的索引列表，每次刷新都重新映射一遍
    if not XTool.IsTableEmpty(self._ItemInGroupList) then
        for i, v in pairs(self._ItemInGroupList) do
            v:Close()
        end
    end
    self._ItemInGroupList = {}

    XUiHelper.RefreshCustomizedList(self.PanelSelectReward.transform, self.PanelSelectPropItem, group.SelectGoods and #group.SelectGoods or 0, function(index, go)
        local item = self._ItemMapInGroup[go]

        if not item then
            item = XUiGridPurchaseChoiceItem.New(go, self)
            item:Init(self.Parent)
            self._ItemMapInGroup[go] = item
        end
        
        item:SetGroupId(group.GroupId, group.SelectGoods[index].Id)
        item:OnRefresh(group.SelectGoods[index].RewardGoods)
        item:SetShowHistroySelection(true)
        item:Open()

        table.insert(self._ItemInGroupList, item)
    end)
end

function XUiPanelChoicePurchaseItemList:OnGroupSelect()
    self:HideSelectList()
    self:_ShowPlayerSelection()
    self.Parent:RefreshBuyButtonStatus()
    self.Parent:RefreshRewardContainsOwnShow()
end

function XUiPanelChoicePurchaseItemList:HideSelectList()
    self.PanelRewardSelectList.gameObject:SetActiveEx(false)
    self.BgMask.gameObject:SetActiveEx(false)

    if not XTool.IsTableEmpty(self._ItemInGroupList) then
        for i, v in pairs(self._ItemInGroupList) do
            v:Close()
        end
    end
    self.ImgBtnClose.gameObject:SetActiveEx(false)

    self.IsOpenSelfSelectPanel = false

    if self._CurSelectGridItem then
        self._CurSelectGridItem:SetIsSelected(false)
    end
end
--endregion

function XUiPanelChoicePurchaseItemList:OnTipsClick()
    if self.IsOpenSelfSelectPanel then
        return
    end
    XLuaUiManager.Open('UiPurchaseChoiceRewardTips')
end

return XUiPanelChoicePurchaseItemList