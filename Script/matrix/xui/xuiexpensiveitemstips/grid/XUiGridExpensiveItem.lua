local XUiGridExpensiveItem = XClass(XUiNode, "XUiGridExpensiveItem")

function XUiGridExpensiveItem:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnGo, self.OnBtnGoClick)
end

function XUiGridExpensiveItem:OnBtnGoClick()
    if not self.Data then
        return
    end

    local itemId = self.Data.ItemId
    if XDataCenter.ItemManager.IsSelectGift(itemId) then
        local canSelectRewardCount = XDataCenter.ItemManager.GetItem(itemId).Template.SelectCount
        local ownItemCount = XDataCenter.ItemManager.GetCount(itemId)
        if ownItemCount and ownItemCount > 1 and canSelectRewardCount == 1 then
            XLuaUiManager.Open("UiReplicatedGift", itemId, ownItemCount * canSelectRewardCount)
        else
            XLuaUiManager.Open("UiGift", itemId)
        end
        
        return
    end


    local itemSkipParams = XDataCenter.ItemManager.GetItemSkipIdParams(itemId)
    if not XTool.IsTableEmpty(itemSkipParams) then
        XFunctionManager.SkipInterface(itemSkipParams[1])
        return
    end

    if XTool.IsNumberValid(self.Data.SkipId) then
        XFunctionManager.SkipInterface(self.Data.SkipId)
        return
    end

    -- XLuaUiManager.Open("UiTip", self.Data.ItemId)
    local itemData = XDataCenter.ItemManager.GetItem(itemId)
    XLuaUiManager.Open("UiBagItemInfoPanel", {Data = itemData})
end

function XUiGridExpensiveItem:Refresh(data)
    self.Data = data
    self:RefreshByTime()
end

function XUiGridExpensiveItem:RefreshByTime()
    if not self.Data then
        return
    end

    local itemData = XDataCenter.ItemManager.GetItem(self.Data.ItemId)
    self.TxtGrid.text = XDataCenter.ItemManager.GetItemName(self.Data.ItemId)

    local grid = XUiGridCommon.New(self.Parent, self.Grid256New)
    grid:Refresh(itemData)

    local leftTime = XDataCenter.ItemManager.GetRecycleLeftTime(self.Data.ItemId)
    local leftTimeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.PIVOT_COMBAT)
    self.TxtTime.text = leftTimeStr
end

return XUiGridExpensiveItem