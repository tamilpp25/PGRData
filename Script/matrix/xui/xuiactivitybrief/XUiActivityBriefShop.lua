local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
local XUiActivityBriefGridLine = require("XUi/XUiActivityBrief/XUiActivityBriefGridLine")
local XUiActivityBriefShop = XLuaUiManager.Register(XLuaUi, "UiActivityBriefShop")

local CSXTextManagerGetText = CS.XTextManager.GetText
local CSInstantiate = CS.UnityEngine.Object.Instantiate
local ShopHintText = CSXTextManagerGetText("ActivityBriefShopLock")
local CanBuyColor = CS.XGame.ClientConfig:GetString("ActivityShopItemTextCanBuyColor")
local CanNotBuyColor = CS.XGame.ClientConfig:GetString("ActivityShopItemTextCanNotBuyColor")
local ActivityBriefShopNeedMarkScrollPosId = CS.XGame.ClientConfig:GetInt('ActivityBriefShopNeedMarkScrollPosId')

local ShopItemTextColor = {
    CanBuyColor = CanBuyColor,
    CanNotBuyColor = CanNotBuyColor,
}
local HIDE_GOOD_ID = 127671 -- 前期隐藏不下发，后期才下发的商品id  -- todo 下个版本提优化单支持配置

function XUiActivityBriefShop:OnAwake()
    self.SortGroup.gameObject:SetActiveEx(false)
    self.GridShop.gameObject:SetActiveEx(false)
    self.HintTxt.gameObject:SetActiveEx(false)
    self.ImgEmpty.gameObject:SetActiveEx(true)
    self.BtnTong1.gameObject:SetActiveEx(false)
    self.GridLine.gameObject:SetActiveEx(false)
    self.SortGroupContent = self.SortGroup.transform.parent:GetComponent("RectTransform")

    self.ShopLockDecs = {}
    self.SortGroupList = {}
    self.XUiGridShopList = {}

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelActivityAsset, self, true)
    self:SetButtonCallBack()
    self:InitDynamicTable()
end

function XUiActivityBriefShop:OnStart(closeCb, openCb, selectedShopId, screenId)
    self.CloseCb = closeCb
    self.OpenCb = openCb
    self.ScreenId = screenId
    self.ShopIdList = XDataCenter.ActivityBriefManager.GetActivityShopIds(true)
    self:CheckShopTabLock()
    self:InitShopTabList(selectedShopId, screenId)
    XEventManager.DispatchEvent(XEventId.EVENT_AWARD_SHOP_ENTER)
end

function XUiActivityBriefShop:OnEnable()
    self:CheckShopTabLock()
    self:RefreshShopTabLock()
    self:UpdatePanel()

    self:PlayAnimationWithMask("ShopEnable", function()
        if self.OpenCb then
            self.OpenCb()
        end
    end)

    self:StartTabTimer()
end

function XUiActivityBriefShop:OnDisable()
    if XTool.IsNumberValid(ActivityBriefShopNeedMarkScrollPosId) and ActivityBriefShopNeedMarkScrollPosId == self:GetCurShopId() then
        self._StartIndexCache = self.DynamicTable:GetStartIndex()
    end
    
    self:ClearCountDown()
    self:StopTabTimer()
    for _, grid in ipairs(self.XUiGridShopList) do
        grid:OnRecycle()
    end
    local lineGrids = self.DynamicTable:GetGrids()
    for _, lineGrid in pairs(lineGrids) do
        lineGrid:OnRecycle()
    end
end

function XUiActivityBriefShop:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnShaiXuan, self.OnBtnShaiXuanClick)
end

function XUiActivityBriefShop:OnBtnBackClick()
    self:Close()

    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiActivityBriefShop:OnBtnShaiXuanClick()
    local callBack = function(data)
        if data then
            self.SelectTag = data.text
        else
            self.SelectTag = nil    
        end
        self:UpdateGoodList()
    end

    local dataProvider = self:GetSuitScreenDataProvider()
    local selectData = nil
    for i = 1, #dataProvider do
        local data = dataProvider[i]
        if data.text == self.SelectTag then
            selectData = data
            break
        end
    end

    XLuaUiManager.Open('UiShopWaferSelect', selectData, dataProvider, callBack)
end

function XUiActivityBriefShop:InitShopTabList(selectedShopId, screenId)
    self.ShopBtn = {}
    for i, shopId in ipairs(self.ShopIdList) do
        local go = CSInstantiate(self.BtnTong1, self.BtnTong1.transform.parent)
        go.gameObject:SetActiveEx(true)
        go.gameObject.name = 'BtnTong'..tostring(shopId)
        local btn = go:GetComponent("XUiButton")
        local shopName = XShopManager.GetShopName(shopId)
        btn:SetNameByGroup(0, shopName)
        btn:SetNameByGroup(1, '')
        table.insert(self.ShopBtn, btn)
    end

    self.BtnTab:Init(self.ShopBtn, function(index)
        self:SelectShop(index)
    end)

    local selIndex = self:GetSelectShopIndex(selectedShopId, screenId)
    self.BtnTab:SelectIndex(selIndex)
end

function XUiActivityBriefShop:SelectShop(index, force)
    if self.CurIndex == index and not force then
        return
    end

    -- 如果上一个页签是需要缓存滑动位置的页签，则在这里进行缓存
    if XTool.IsNumberValid(ActivityBriefShopNeedMarkScrollPosId) and ActivityBriefShopNeedMarkScrollPosId == self:GetCurShopId() then
        self._StartIndexCache = self.DynamicTable:GetStartIndex()
    end
    
    self.CurIndex = index

    
    
    self:PlayAnimation("QieHuan")
    self:UpdatePanel()
    self.SortGroupContent.anchoredPosition = CS.UnityEngine.Vector2(0, 0)
end

-- 获取选中的商店下标
function XUiActivityBriefShop:GetSelectShopIndex(selectedShopId, screenId)
    if XTool.IsNumberValid(screenId) then
        local value, _ = XShopManager.GetShopScreenGroupSelectValueAndScreenNum(selectedShopId, screenId)
        selectedShopId = XTool.IsNumberValid(value) and selectedShopId or 0
    end

    if selectedShopId then
        for index, shopId in pairs(self.ShopIdList) do
            if shopId == selectedShopId then
                return index
            end
        end
    end

    -- 优先选中有可购商品的商店
    for i, shopId in ipairs(self.ShopIdList) do
        local goods = XShopManager.GetShopGoodsList(shopId)
        for _, good in ipairs(goods) do
            local canBuy = good.BuyTimesLimit == 0 or (good.TotalBuyTimes < good.BuyTimesLimit)
            if canBuy then
                return i
            end
        end
    end

    return 1
end

function XUiActivityBriefShop:GetCurShopId()
    return self.ShopIdList[self.CurIndex]
end

function XUiActivityBriefShop:CheckShopTabLock()
    self.ShopLockDecs = {}
    for k, shopId in pairs(self.ShopIdList) do
        local conditions = XDataCenter.ActivityBriefManager.GetActivityShopConditionByShopId(shopId)
        for _, condition in pairs(conditions or {}) do
            if condition ~= 0 then
                local isOpen, desc = XConditionManager.CheckCondition(condition)
                if not isOpen then
                    self.ShopLockDecs[shopId] = desc
                    break
                end
            end
        end
    end
end

function XUiActivityBriefShop:RefreshShopTabLock()
    for i, shopId in pairs(self.ShopIdList) do
        local shopBtn = self.ShopBtn[i]
        local isLock = self.ShopLockDecs[shopId] ~= nil
        shopBtn:ShowTag(isLock)
    end
end

function XUiActivityBriefShop:UpdatePanel()
    local shopId = self:GetCurShopId()
    local goods = XShopManager.GetShopGoodsList(shopId)

    -- 上锁提示
    local isLock = self.ShopLockDecs[shopId] ~= nil
    self.HintTxt.gameObject:SetActiveEx(isLock)
    if isLock then
        self.HintTxt.text = self.ShopLockDecs[shopId]
    end

    -- 无商品提示
    local isEmpty = not next(goods)
    self.ImgEmpty.gameObject:SetActiveEx(isEmpty)
    if not isEmpty then
        self.AssetActivityPanel:Refresh(XShopManager.GetShopShowIdList(shopId))
    end

    -- 刷新商店背景图和图标
    ---@type XTableActivityBriefShop
    local activityBriefShopCfg = XActivityBriefConfigs.GetActivityShopByShopId(shopId)

    local shopBg = activityBriefShopCfg.ShopBg
    if shopBg and self.RImgBg then
        self.RImgBg:SetRawImage(shopBg)
    end
    local shopIcon = activityBriefShopCfg.ShopIcon
    if shopIcon and self.RImgShopIcon then
        self.RImgShopIcon:SetRawImage(shopIcon)
    end

    self:InitShaiXuan()
    self:UpdateGoodList()
    self:StartCountDown()
end

-- 刷新商品列表
function XUiActivityBriefShop:UpdateGoodList()
    local shopId = self:GetCurShopId()
    local shopGoods
    if self:IsShowShaiXuan() then
        shopGoods = XShopManager.GetScreenGoodsListByTag(shopId, self.ScreenGroupIDList[1], self.SelectTag)
    else
        shopGoods = XShopManager.GetShopGoodsList(shopId)
    end

    self.PanelItemList.gameObject:SetActiveEx(false)
    self.PanelItemList2.gameObject:SetActiveEx(false)

    -- 筛选组
    local sortGroupInfoList = self:GetSortGroupInfoList(shopGoods, shopId)
    if #sortGroupInfoList > 1 then
        self.PanelItemList.gameObject:SetActiveEx(true)
        self:UpdateGoodListWithMultiGroup(sortGroupInfoList)
    elseif #sortGroupInfoList == 1 then
        self.PanelItemList2.gameObject:SetActiveEx(true)
        
        local startIndex = nil
        if XTool.IsNumberValid(ActivityBriefShopNeedMarkScrollPosId) and ActivityBriefShopNeedMarkScrollPosId == shopId then
            startIndex = self._StartIndexCache
        end
        self:UpdateGoodListWithOneGroup(sortGroupInfoList, startIndex)
    end
end

function XUiActivityBriefShop:GetSortGroupInfoList(shopGoods, shopId)
    if not shopGoods or #shopGoods == 0 then
        return {}
    end

    local shopInfo = XActivityBriefConfigs.GetActivityShopByShopId(shopId)
    if not shopInfo.GoodsSortIds or #shopInfo.GoodsSortIds == 0 then
        local sortGroupInfo = {}
        sortGroupInfo.Bg = shopInfo.ShopSortGroupBg
        sortGroupInfo.ShopGoods = shopGoods
        return { sortGroupInfo }
    end

    local sortGroupList = {}
    local shopId = self:GetCurShopId()
    local shopGoodDic = {}
    for _, good in ipairs(shopGoods) do
        shopGoodDic[good.Id] = good
    end

    -- 收集筛选组
    for i, sortId in ipairs(shopInfo.GoodsSortIds) do
        local sortcfg = XActivityBriefConfigs.GetActivityShopGoodsSortById(sortId)
        if sortcfg.ShopId ~= shopId then
            XLog.Error(string.format("请策划老师检查配置：ActivityBriefShop.tab的ShopId %s，GoodsSortIds[%s]对应到ActivityBriefShopGoodsSort.tab配置的商店ShopId为%s", shopId, i, sortcfg.ShopId))
        end

        local targetIdDic = {}
        local sortGoods = {}
        for index, targetId in ipairs(sortcfg.TargetIds) do
            local good = shopGoodDic[targetId]
            if good then
                -- 过滤不满足条件的物品
                if self:CheckGoodsConditions(good) then
                    targetIdDic[targetId] = index
                    table.insert(sortGoods, good)
                end
                shopGoodDic[targetId] = nil
            else
                if targetIdDic[targetId] then
                    XLog.Error(string.format("请策划老师检查配置：ActivityBriefShopGoodsSort.tab表，Id = %s，TargetIds[%s] = %s，商店里配置了相同的商品id", sortId, index, targetId))
                else
                    if targetId ~= HIDE_GOOD_ID and XMain.IsEditorDebug then
                        XLog.Error(string.format("请策划老师检查配置：ActivityBriefShopGoodsSort.tab表，Id = %s，TargetIds[%s] = %s，商店里无此商品id", sortId, index, targetId))
                    end
                end
            end
        end

        if #sortGoods > 0 then
            table.sort(sortGoods, function(a, b)
                local indexA = targetIdDic[a.Id]
                local indexB = targetIdDic[b.Id]
                return indexA < indexB
            end)

            local sortGroupInfo = {}
            sortGroupInfo.Bg = sortcfg.BgImg
            sortGroupInfo.ShopGoods = sortGoods
            sortGroupInfo.Index = #sortGroupList + 1
            table.insert(sortGroupList, sortGroupInfo)
        end
    end

    -- 剩下的商品自成一组
    local remainGoods = {}
    for _, good in ipairs(shopGoods) do
        if shopGoodDic[good.Id] then
            table.insert(remainGoods, good)
        end
    end
    if #remainGoods > 0 then
        local sortGroupInfo = {}
        sortGroupInfo.Bg = shopInfo.ShopSortGroupBg
        sortGroupInfo.ShopGoods = remainGoods
        sortGroupInfo.Index = #sortGroupList + 1
        table.insert(sortGroupList, sortGroupInfo)
    end

    -- 排序 全部售罄的组放在最后
    if #sortGroupList > 1 then
        for i, groupInfo in ipairs(sortGroupList) do
            local isSellOut = true
            for _, good in ipairs(groupInfo.ShopGoods) do
                local canBuy = good.BuyTimesLimit == 0 or (good.TotalBuyTimes < good.BuyTimesLimit)
                if canBuy then
                    isSellOut = false
                    break
                end
            end
            groupInfo.IsSellOut = isSellOut
        end

        table.sort(sortGroupList, function(a, b)
            local priorityA = 0
            local priorityB = 0
            priorityA = priorityA + (a.IsSellOut and 0 or 1000)
            priorityB = priorityB + (b.IsSellOut and 0 or 1000)

            priorityA = priorityA + (a.Index < b.Index and 100 or 0)
            priorityB = priorityB + (b.Index < a.Index and 100 or 0)
            return priorityA > priorityB
        end)
    end

    return sortGroupList
end

function XUiActivityBriefShop:CheckGoodsConditions(good)
    if not XTool.IsTableEmpty(good.ConditionIds) then
        for _, conditionId in ipairs(good.ConditionIds) do
            if not XConditionManager.CheckCondition(conditionId) then
                return false
            end
        end
    end

    return true
end

function XUiActivityBriefShop:UpdateGoodListWithMultiGroup(sortGroupInfoList)
    for _, sortGroup in ipairs(self.SortGroupList) do
        sortGroup.gameObject:SetActiveEx(false)
    end
    for _, gridShop in ipairs(self.XUiGridShopList) do
        gridShop.GameObject:SetActiveEx(false)
    end

    local gridIndex = 1
    for i, info in ipairs(sortGroupInfoList) do
        if not XTool.IsTableEmpty(info.ShopGoods) then
            local sortGroupGo = self.SortGroupList[i]
            if not sortGroupGo then
                sortGroupGo = CSInstantiate(self.SortGroup, self.SortGroup.transform.parent)
                table.insert(self.SortGroupList, sortGroupGo)
            end
            sortGroupGo.gameObject:SetActiveEx(true)
            local obj = sortGroupGo:GetComponent("UiObject")
            obj:GetObject("RImageBgIcon"):SetRawImage(info.Bg)

            -- 刷新组内商品
            local goodParent = obj:GetObject("GridShopList")
            for _, goodData in ipairs(info.ShopGoods) do
                local gridShop = self.XUiGridShopList[gridIndex]
                if not gridShop then
                    local go = CSInstantiate(self.GridShop, self.GridShop.transform.parent)
                    gridShop = XUiGridShop.New(go)
                    gridShop:Init(self, self.RootUi)
                    table.insert(self.XUiGridShopList, gridShop)
                end
                gridShop.GameObject:SetActiveEx(true)
                gridShop.Transform:SetParent(goodParent)
                gridShop.Transform:SetAsLastSibling()

                self:SetShopItemLock(gridShop)
                self:SetShopItemBg(gridShop)
                gridShop:UpdateData(goodData, ShopItemTextColor)
                gridShop:RefreshOnSaleTime(goodData.OnSaleTime)
                gridIndex = gridIndex + 1
            end
        end
    end
end

function XUiActivityBriefShop:UpdateGoodListWithOneGroup(sortGroupInfoList, startIndex)
    startIndex = startIndex or 1
    local info = sortGroupInfoList[1]
    self.RImageBgIcon:SetRawImage(info.Bg)

    self.ShopLineGoodsList = {}
    local cnt = #info.ShopGoods
    for i = 1, cnt, 2 do
        local lineGoods = {}
        table.insert(lineGoods, info.ShopGoods[i])

        local nextGood = info.ShopGoods[i + 1]
        if nextGood then
            table.insert(lineGoods, nextGood)
        end

        table.insert(self.ShopLineGoodsList, lineGoods)
    end

    self.DynamicTable:SetDataSource(self.ShopLineGoodsList)
    self.DynamicTable:ReloadDataASync(startIndex)
end

function XUiActivityBriefShop:InitShaiXuan()
    local shopId = self:GetCurShopId()
    self.ScreenGroupIDList = XShopManager.GetShopScreenGroupIDList(shopId)

    local goodList = XShopManager.GetShopGoodsList(shopId)
    local isShow = self:IsShowShaiXuan() and goodList and #goodList > 0
    self.BtnShaiXuan.gameObject:SetActiveEx(isShow)
    if isShow then
        self:GetSuitScreenDataProvider()
    end
end

function XUiActivityBriefShop:IsShowShaiXuan()
    if self.ScreenGroupIDList and next(self.ScreenGroupIDList) then
        return true
    else
        return false
    end
end

function XUiActivityBriefShop:GetSuitScreenDataProvider()
    local dataProvider = {}
    local hasAll = false
    local shopId = self:GetCurShopId()
    local groupId = self.ScreenGroupIDList[1]
    local screenTagList = XShopManager.GetScreenTagListById(shopId, groupId)
    local tagScreenAll = XShopManager.GetTagScreenAll()
    for _, v in pairs(screenTagList or {}) do
        if v.Text ~= tagScreenAll then
            local goodsList = XShopManager.GetScreenGoodsListByTag(shopId, groupId, v.Text)
            if #goodsList > 0 then
                local firstGood = goodsList[1]
                local templateId = firstGood.RewardGoods.TemplateId
                local suitId = XMVCA.XEquip:GetEquipSuitId(templateId)
                local suitCfg = XMVCA.XEquip:GetConfigEquipSuit(suitId)
                dataProvider[#dataProvider + 1] = {
                    text = v.Text,
                    icon = XMVCA.XEquip:GetEquipSuitIconPath(suitId),
                    description = suitCfg.Description,
                    suitQualityIcon = XMVCA.XEquip:GetSuitQualityIcon(suitId)
                }
            end
        end
    end
    if self.ScreenId then
        local value, _ = XShopManager.GetShopScreenGroupSelectValueAndScreenNum(shopId, self.ScreenId)
        --原来是通过下拉框来实现的，起点从0开始
        if XTool.IsNumberValid(value) then
            if dataProvider[value - 1] then
                self.SelectTag = dataProvider[value - 1].text
            end
        end
        self.ScreenId = nil
    end
    return dataProvider
end

function XUiActivityBriefShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, cb, "000000ff")
end

-- 购买商品成功后的刷新函数
function XUiActivityBriefShop:RefreshBuy()
    local shopId = self:GetCurShopId()
    self.AssetActivityPanel:Refresh(XShopManager.GetShopShowIdList(shopId))
    self:UpdateGoodList()
end

function XUiActivityBriefShop:SetShopItemBg(grid)
    local bg = XActivityBriefConfigs.GetActivityShopByShopId(self:GetCurShopId()).ShopItemBg
    if grid.ItemBg and bg then
        grid.ItemBg:SetRawImage(bg)
    end
end

function XUiActivityBriefShop:SetShopItemLock(grid)
    local shopId = self:GetCurShopId()
    local isLock = self.ShopLockDecs[shopId] ~= nil
    grid.IsShopLock = isLock
    grid.ShopLockDecs = ShopHintText
    if grid.ImgLock then
        grid.ImgLock.gameObject:SetActiveEx(isLock)
    end
end

function XUiActivityBriefShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList2)
    self.DynamicTable:SetProxy(XUiActivityBriefGridLine)
    self.DynamicTable:SetDelegate(self)
end

function XUiActivityBriefShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self, ShopItemTextColor)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local lineGoods = self.ShopLineGoodsList[index]
        grid:Refresh(lineGoods)
    end
end

function XUiActivityBriefShop:StartCountDown()
    self:ClearCountDown()
    local shopId = self.ShopIdList[self.CurIndex]
    local hasTimeLimit = self:CheckHasTimeLimit(shopId)
    if self.TxtTime then
        self.TxtTime.gameObject:SetActiveEx(hasTimeLimit)
    end
    if hasTimeLimit then
        self.CountDownTimer = XScheduleManager.ScheduleForever(function()
            self:UpdateCountDown()
        end, XScheduleManager.SECOND)
        self:UpdateCountDown()
    end
end

function XUiActivityBriefShop:UpdateCountDown()
    local shopId = self.ShopIdList[self.CurIndex]
    local shopTimeInfo = XShopManager.GetShopTimeInfo(shopId)
    local leftTime = shopTimeInfo.ClosedLeftTime
    if leftTime > 0 then
        if self.TxtTime then
            local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
            self.TxtTime.text = CSXTextManagerGetText("ActivityBriefShopLeftTime", timeStr)
        end
    else
        self:ClearCountDown()
    end
end

function XUiActivityBriefShop:CheckHasTimeLimit(shopId)
    local shopTimeInfo = XShopManager.GetShopTimeInfo(shopId)
    return type(shopTimeInfo.ClosedLeftTime) == 'number'
end

function XUiActivityBriefShop:ClearCountDown()
    if self.CountDownTimer then
        XScheduleManager.UnSchedule(self.CountDownTimer)
        self.CountDownTimer = nil
        if self.TxtTime then
            self.TxtTime.gameObject:SetActiveEx(false)
        end
    end
end

function XUiActivityBriefShop:StopTabTimer()
    if self._TabTimer then
        XScheduleManager.UnSchedule(self._TabTimer)
        self._TabTimer = nil
        self._TimerTabs = nil
        self._RemoveTabTimerList = nil
    end
end

function XUiActivityBriefShop:StartTabTimer()
    self:StopTabTimer()
    -- 检查是否有限时商店
    for i, shopId in pairs(self.ShopIdList) do
        if self:CheckHasTimeLimit(shopId) then
            if self._TimerTabs == nil then
                self._TimerTabs = {}
            end
            self._TimerTabs[i] = shopId
        end
    end

    if not XTool.IsTableEmpty(self._TimerTabs) then
        self._RemoveTabTimerList = {}
        self:TabTimerUpdater()
        self._TabTimer = XScheduleManager.ScheduleForever(function()
            self:TabTimerUpdater()
        end, XScheduleManager.SECOND)
    end
end

function XUiActivityBriefShop:TabTimerUpdater()
    local autoChangeShop = false
    if not XTool.IsTableEmpty(self._TimerTabs) then
        for index, shopId in pairs(self._TimerTabs) do
            local shopTimeInfo = XShopManager.GetShopTimeInfo(shopId)
            local leftTime = shopTimeInfo.ClosedLeftTime
            local btn = self.ShopBtn[index]

            if leftTime <= 0 then
                -- 隐藏并移除
                btn:SetNameByGroup(1, '')
                btn.gameObject:SetActiveEx(false)
                table.insert(self._RemoveTabTimerList, index)

                if index == self.CurIndex then
                    autoChangeShop = true
                end
            else
                local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
                btn:SetNameByGroup(1, timeStr)
            end
        end
        -- 将倒计时<=0的切页移除刷新列表
        if not XTool.IsTableEmpty(self._RemoveTabTimerList) then
            for i = #self._RemoveTabTimerList, 1, -1 do
                self._TimerTabs[self._RemoveTabTimerList[i]] = nil
                self._RemoveTabTimerList[i] = nil
            end
        end
    else
        self:StopTabTimer()
    end

    if autoChangeShop then
        -- 当前页签关闭了，需要换下一个页签
        self.ShopIdList[self.CurIndex] = nil
        -- 弹窗提示
        XUiManager.TipText('CommonShopClosedTips')
        if XTool.GetTableCount(self.ShopIdList) > 0 then
            local k, v = next(self.ShopIdList)
            self.ShopBtn[k]:SetButtonState(CS.UiButtonState.Select)
            self:SelectShop(k, true)
        else
            self:Close()
        end
    end
end 