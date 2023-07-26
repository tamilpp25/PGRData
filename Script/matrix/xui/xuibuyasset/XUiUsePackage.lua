local XUiUsePackage = XLuaUiManager.Register(XLuaUi, "UiUsePackage")

local DefaultIndex = 1
local SelectItemList = {}

local tableInsert = table.insert

function XUiUsePackage:OnStart(id, successCallback, challengeCountData, buyAmount)
    self.SuccessCallback = successCallback
    self.BuyAmount = buyAmount
    self.ChallengeCountData = challengeCountData
    self:InitDynamicTable()
    self.Id = id
    self:SetTxtElectricNumPackage(0)
    self:Refresh(id)
    self:AddBtnCallBack()
    if self.Data.TargetId == XDataCenter.ItemManager.ItemId.ActionPoint then
        self.Timers = XScheduleManager.ScheduleForever(function() self:SetRecTime() end, XScheduleManager.SECOND)
    end
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_UIDIALOG_VIEW_ENABLE)
end

function XUiUsePackage:OnEnable()

end

function XUiUsePackage:OnDisable()

end

function XUiUsePackage:OnDestroy()
    if self.Timers then
        XScheduleManager.UnSchedule(self.Timers)
        self.Timers = nil
    end
end

function XUiUsePackage:AddBtnCallBack()
    self.BtnCancel.CallBack = function()
        self:OnBtnCancelClick()
    end
    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirmClick()
    end
    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnElectricExchange.CallBack = function()
        self:OnBtnShowTypeClick()
    end
end
-- auto
function XUiUsePackage:OnBtnShowTypeClick()
    self:Close()
    XLuaUiManager.Open("UiBuyAsset", self.Id, self.SuccessCallback, self.ChallengeCountData, self.BuyAmount)
end

function XUiUsePackage:OnBtnCloseClick()
    self:Close()
end

function XUiUsePackage:OnBtnCancelClick()
    self:Close()
end

function XUiUsePackage:SetPanelType(targetId)
    self.Data = XDataCenter.ItemManager.GetBuyAssetInfo(targetId)
    self.TxtElectricDesc.gameObject:SetActiveEx(false)
    self.TxtElectricNumPackage.gameObject:SetActiveEx(true)

    if self.Data.TargetId == XDataCenter.ItemManager.ItemId.ActionPoint then
        if not XDataCenter.ItemManager.CheckBatteryIsHave() then
            self.ImgEmpty.gameObject:SetActiveEx(true)
        else
            self.ImgEmpty.gameObject:SetActiveEx(false)
        end

        self:SetupDynamicTable()
    end
end

function XUiUsePackage:SetRecTime()
    local time = XDataCenter.ItemManager.GetActionPointsRefreshResidueSecond()
    self.TxtRecoverTime.text = CS.XTextManager.GetText("RecActPoint", XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ONLINE_BOSS))
    self.TxtCurrentElectric.text = XDataCenter.ItemManager.GetActionPointsNum() .. "/" .. XDataCenter.ItemManager.GetMaxActionPoints()
    if time == 0 then
        self.TxtRecoverTime.text = ""
    end
end

function XUiUsePackage:OnBtnConfirmClick()
    if not next(SelectItemList) then
        XUiManager.TipError(CS.XTextManager.GetText("UseBattery"))
        return
    elseif self:CheckActionPointOverLimit() then
        XUiManager.TipError(CS.XTextManager.GetText("OverLimitCanNotUse"))
        return
    end

    local lastUseIndex
    local totalRewardGoodsList = {}
    local useItemFunction = function(useIndex, count, callback)
        local selectItem = self.BatteryDatas[useIndex]
        if selectItem then
            local recycleTime = selectItem.RecycleBatch and selectItem.RecycleBatch.RecycleTime
            XDataCenter.ItemManager.Use(selectItem.Data.Id, recycleTime, count, callback)
        end
    end

    local addRewardGoodsListCallback = function(rewardGoodsList)
        if rewardGoodsList and rewardGoodsList[1] then
            tableInsert(totalRewardGoodsList, rewardGoodsList[1])
        end
    end
    for index, itemList in pairs(SelectItemList) do
        if itemList.SelectItemCount > 0 then
            if lastUseIndex then
                useItemFunction(lastUseIndex, SelectItemList[lastUseIndex].SelectItemCount, addRewardGoodsListCallback)
            end
            lastUseIndex = index
        end
    end

    local callback = function(rewardGoodsList)
        self:SetPanelType(self.Id)
        if self.SuccessCallback then
            self.SuccessCallback()
        end
        tableInsert(totalRewardGoodsList, rewardGoodsList[1])
        XUiManager.OpenUiObtain(totalRewardGoodsList)
    end
    useItemFunction(lastUseIndex, SelectItemList[lastUseIndex].SelectItemCount, callback)
end

function XUiUsePackage:Refresh(targetId)
    self:SetPanelType(targetId)
    local active = self.Data ~= nil
    self.PanelInfo.gameObject:SetActiveEx(active)
    self.TxtCurrentElectric.text = XDataCenter.ItemManager.GetActionPointsNum() .. "/" .. XDataCenter.ItemManager.GetMaxActionPoints()
end

function XUiUsePackage:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.ElectricPackageScroll)
    self.DynamicTable:SetProxy(XUiBattery)
    self.DynamicTable:SetDelegate(self)
    self.GridCommonPopUp.gameObject:SetActiveEx(false)
end

function XUiUsePackage:SetupDynamicTable()
    self.BatteryDatas = XDataCenter.ItemManager.GetCurBatterys()
    self:RefreshSelectItemList()
    self.DynamicTable:SetDataSource(self.BatteryDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiUsePackage:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.BatteryDatas[index], self, index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

function XUiUsePackage:CheckActionPointOverLimit()
    local ActionPoint = XDataCenter.ItemManager.GetItem(XDataCenter.ItemManager.ItemId.ActionPoint)
    local totalSelectItemElectricNum = 0
    for index, itemList in pairs(SelectItemList) do
        totalSelectItemElectricNum = totalSelectItemElectricNum + itemList.OnecElectricNum * itemList.SelectItemCount
    end
    if totalSelectItemElectricNum + ActionPoint:GetCount() > ActionPoint.Template.MaxCount then
        return true
    end
    return false
end

function XUiUsePackage:SetTxtElectricNumPackage(num)
    if num >= 0 then
        self.TxtElectricNumPackage.text = num
    end
end

function XUiUsePackage:SetSelectItemCount(index, selectItemCount, onecElectricNum)
    self:UpdateSelectItemList(index, selectItemCount, onecElectricNum)
    self:SetTxtElectricNumPackage(tonumber(self.TxtElectricNumPackage.text) + onecElectricNum)
end

function XUiUsePackage:UpdateSelectItemList(index, selectItemCount, onecElectricNum)
    if not SelectItemList[index] then
        SelectItemList[index] = {}
    end
    SelectItemList[index]["SelectItemCount"] = selectItemCount
    SelectItemList[index]["OnecElectricNum"] = onecElectricNum
end

function XUiUsePackage:GetSelectItemCountByIndex(index)
    return SelectItemList[index] and SelectItemList[index]["SelectItemCount"] or 0
end

function XUiUsePackage:GetOnecElectricNumByIndex(index)
    return SelectItemList[index] and SelectItemList[index]["OnecElectricNum"] or 0
end

function XUiUsePackage:SubSelectItemCountByIndex(index)
    local selectItemCount = self:GetSelectItemCountByIndex(index)
    if selectItemCount <= 0 then
        return
    end
    local onecElectricNum = self:GetOnecElectricNumByIndex(index)
    self:UpdateSelectItemList(index, selectItemCount - 1, onecElectricNum)
    self:SetTxtElectricNumPackage(tonumber(self.TxtElectricNumPackage.text) - onecElectricNum)
    if self:GetSelectItemCountByIndex(index) <= 0 then
        SelectItemList[index] = nil
    end
end

function XUiUsePackage:ClearSelectItemCountByIndex(index)
    local onecElectricNum = self:GetOnecElectricNumByIndex(index)
    local selectItemCount = self:GetSelectItemCountByIndex(index)
    self:SetTxtElectricNumPackage(tonumber(self.TxtElectricNumPackage.text) - onecElectricNum * selectItemCount)
    SelectItemList[index] = nil
end

function XUiUsePackage:RefreshSelectItemList()
    self:SetTxtElectricNumPackage(0)
    SelectItemList = {}
    if self.BatteryDatas and self.BatteryDatas[DefaultIndex] then
        local goodsId = 1
        local rewardIndex = 2
        local goodsList = XRewardManager.GetRewardList(self.BatteryDatas[DefaultIndex].Data.Template.SubTypeParams[rewardIndex])
        self:SetSelectItemCount(DefaultIndex, 1, goodsList[goodsId].Count)
    end
end