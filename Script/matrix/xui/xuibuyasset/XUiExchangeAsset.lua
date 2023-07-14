--######################## XUiExchangeAsset ########################
local XUiExchangeTargetItem = require("XUi/XUiBuyAsset/XUiExchangeTargetItem")
local XUiExchangeItem = require("XUi/XUiBuyAsset/XUiExchangeItem")
local XUiExchangeAsset = XLuaUiManager.Register(XLuaUi, "UiLottoTanchuang2")

function XUiExchangeAsset:OnAwake()
    -- 重定义 begin
    self.BtnClose2 = self.BtnTanchuangClose
    self.UOExchangeItem1 = self.Card1
    self.UOExchangeItem2 = self.Card2
    self.UOTargetItem = self.TargetCard
    -- 重定义 end
    -- -- 兑换资源的配置
    -- self.ExchangeConfigs = nil
    self.CurrentExchangeData = nil
    self.ItemId = nil
    self.ExchangeItems = {}
    self.ExchangeTargetItem = XUiExchangeTargetItem.New(self.UOTargetItem)
    self.CurrentBuyCount = 1
    self.CustomMaxCountTextFunc = nil
    self.CustomMaxCountFunc = nil
    self.ConsumeIcons = nil
    self.TargetIcon = nil
    self:RegisterUiEvents()
end

-- itemId : Share\Item\UiBuyAsset.tab的id
--[[
    maxCountFunc : 自定义的最大限制数量（客户端软判断，不需要buyasset逻辑支持），必须和maxCountTextFunc一起设置
    maxCountTextFunc : 最大数量文本，可nil，nil会自己读取UiBuyAsset的最大限购次数
    consumeIcons : 消耗自定义的图标
    targetIcon : 目标物品自定义图标
    supportInput : 支持输入兑换数量 默认不支持
]]
function XUiExchangeAsset:OnStart(itemId, customData)
    customData = customData or {}
    self.ItemId = itemId
    self.CustomMaxCountFunc = customData.maxCountFunc
    self.CustomMaxCountTextFunc = customData.maxCountTextFunc
    self.ConsumeIcons = customData.consumeIcons
    self.TargetIcon = customData.targetIcon
    self.SupportInput = customData.supportInput or false
    -- 检查结束时间
    local timeId = XItemConfigs.GetBuyAssetTimeId(itemId) 
    if timeId > 0 then
        self:SetAutoCloseInfo(XFunctionManager.GetEndTimeByTimeId(timeId), function(isClose)
            if isClose then
                self:Close()
            end
        end, nil, 1)
    end
end

function XUiExchangeAsset:OnEnable()
    XUiExchangeAsset.Super.OnEnable(self)
    self:RefreshExchangeInfo(self.ItemId)
end

function XUiExchangeAsset:OnDisable()
    XUiExchangeAsset.Super.OnDisable(self)
end

--######################## 私有方法 ########################

function XUiExchangeAsset:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose2, self.OnBtnCloseClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnAddSelect, self.OnBtnAddSelectClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnMinusSelect, self.OnBtnMinusSelectClicked)
    self.InputBuyCount.onEndEdit:AddListener(function(count) self:OnEndEdit(count) end)
end

function XUiExchangeAsset:OnBtnAddSelectClicked()
    -- 如果有自定义最大数量限制，优先处理
    local maxCount = self.CurrentBuyCount + 1
    if self.CustomMaxCountFunc then
        maxCount = self.CustomMaxCountFunc()
    else
        local totalLimitCount = XItemConfigs.GetBuyAssetTotalLimit(self.CurrentExchangeData.TargetId)
        local hasTotal = totalLimitCount > 0
        local hasDaily = self.CurrentExchangeData.LeftTimes ~= nil
        -- 每日
        if hasDaily then
            maxCount = self.CurrentExchangeData.LeftTimes
        elseif hasTotal then
            local item = XDataCenter.ItemManager.GetItem(self.CurrentExchangeData.TargetId)
            local leftTotalCount = totalLimitCount - item.TotalBuyTimes
            maxCount = leftTotalCount
        end
    end
    -- 范围防御限制
    self.CurrentBuyCount = math.max(math.min(self.CurrentBuyCount + 1, maxCount), 1)
    self:RefreshExchangeInfo()
end

function XUiExchangeAsset:OnBtnMinusSelectClicked()
    self.CurrentBuyCount = math.max(self.CurrentBuyCount - 1, 1)
    self:RefreshExchangeInfo()
end

function XUiExchangeAsset:OnEndEdit(inputText)
    -- 如果有自定义最大数量限制，优先处理
    local maxCount = self.CurrentBuyCount + 1
    if self.CustomMaxCountFunc then
        maxCount = self.CustomMaxCountFunc()
    else
        local totalLimitCount = XItemConfigs.GetBuyAssetTotalLimit(self.CurrentExchangeData.TargetId)
        local hasTotal = totalLimitCount > 0
        local hasDaily = self.CurrentExchangeData.LeftTimes ~= nil
        -- 每日
        if hasDaily then
            maxCount = self.CurrentExchangeData.LeftTimes
        elseif hasTotal then
            local item = XDataCenter.ItemManager.GetItem(self.CurrentExchangeData.TargetId)
            local leftTotalCount = totalLimitCount - item.TotalBuyTimes
            maxCount = leftTotalCount
        end
    end
    
    -- 范围防御限制
    local count = tonumber(inputText)
    self.CurrentBuyCount = math.max(math.min(count, maxCount), 1)
    self:RefreshExchangeInfo()
end

function XUiExchangeAsset:OnBtnCloseClicked()
    self:EmitSignal("Close")
    self:Close()
end

function XUiExchangeAsset:RefreshExchangeInfo(itemId)
    if itemId == nil then itemId = self.ItemId end
    local itemManager = XDataCenter.ItemManager
    -- 当前兑换配置数据
    self.CurrentExchangeData = itemManager.GetBuyAssetInfo(itemId)
    -- 获取购买数量信息
    local costCountDic, getCount, exchangeConfigs = self:GetItemBuyAssetConsumeCountAndGetCount(itemId, self.CurrentBuyCount)
    -- 创建本次兑换数据
    local targetId = self.CurrentExchangeData.TargetId
    local exchangeDatas = {}
    for i, consumeId in ipairs(self.CurrentExchangeData.ConsumeId) do
        table.insert(exchangeDatas, {
            TemplateId = consumeId,
            CostCount = costCountDic[consumeId] or 0,
            Discount = self.CurrentExchangeData.DiscountShows[i],
            CustomIcon = self.ConsumeIcons[i]
        })
    end
    -- 创建本次目标数据
    local targetData = {
        TemplateId = targetId,
        GetCount = getCount,
        CustomIcon = self.TargetIcon ,
    }
    -- 设置交换的物品信息
    local exchangeItem
    for index, exchangeData in ipairs(exchangeDatas) do
        exchangeItem = self.ExchangeItems[index]
        if exchangeItem == nil then
            exchangeItem = XUiExchangeItem.New(self["UOExchangeItem" .. index])
            exchangeItem:ConnectSignal("BuySuccess", self, self.OnBuySuccess)
            self.ExchangeItems[index] = exchangeItem
        end
        exchangeItem:SetData(exchangeData, targetId, self.CurrentBuyCount)
    end
    -- 设置目标的物品信息
    if targetData.TemplateId == itemManager.ItemId.Coin then
        local buyAssetCoinBase = CS.XGame.Config:GetInt("BuyAssetCoinBase")
        local buyAssetCoinMul = CS.XGame.Config:GetInt("BuyAssetCoinMul")
        local newTargetCount = 0
        for _, exchangeConfig in ipairs(exchangeConfigs) do
            newTargetCount = newTargetCount + (buyAssetCoinBase + XPlayer.Level * buyAssetCoinMul) * exchangeConfig.GainCount
        end
        targetData.GetCount = newTargetCount
    end
    self.ExchangeTargetItem:SetData(targetData)
    -- 刷新购买数量
    self:RefreshBuyCountInfo(itemId)
end

function XUiExchangeAsset:OnBuySuccess()
    self:EmitSignal("BuySuccess", self.CurrentBuyCount)
    -- 发送事件，XUiBuyAsset原有逻辑，保留
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_ITEM_FAST_TRADING)
    -- 判定是否需要关闭
    if XItemConfigs.GetBuyAssetAutoClose(self.CurrentExchangeData.TargetId) ~= 0 then
        self:Close()
        return
    end
    -- 刷新下一次的数据
    self.CurrentBuyCount = 1
    self:RefreshExchangeInfo(self.ItemId)
end

function XUiExchangeAsset:GetItemBuyAssetConsumeCountAndGetCount(itemId, buyCount)
    local itemManager = XDataCenter.ItemManager
    local item = itemManager.GetItem(itemId)
    -- 获取当前购买次数
    local currentBuyTime = self.CurrentExchangeData.LeftTimes and item.BuyTimes + 1 or item.TotalBuyTimes + 1
    -- 获取该物品所有兑换的配置数据
    local exchangeConfigs = XItemConfigs.GetBuyAssetTemplateById(itemId)
    -- 待检查的兑换数据下标
    local exchangeIndex = #exchangeConfigs
    -- 根据购买次数找到合适的兑换配置
    local resultExchangeConfigs = {}
    -- 根据购买次数找到所有符合的交换配置
    local tmpConfig = nil
    while buyCount > 0 and exchangeIndex >= 1 do
        tmpConfig = exchangeConfigs[exchangeIndex]
        -- 符合直接插入配置
        if currentBuyTime >= tmpConfig.Times then
            table.insert(resultExchangeConfigs, tmpConfig)
            exchangeIndex = math.min(exchangeIndex + 1, #exchangeConfigs)
            buyCount = buyCount - 1
            currentBuyTime = currentBuyTime + 1
        else -- 不符合，倒退回去找合适的
            exchangeIndex = exchangeIndex - 1
        end
    end
    -- 该购买次数下消耗的物品数量字典
    local costCountDic = {}
    -- 该购买次数下能够获得的该物品的数量
    local getCount = 0
    for _, config in ipairs(resultExchangeConfigs) do
        getCount = getCount + config.GainCount
        for i, consumeId in ipairs(config.ConsumeId) do
            costCountDic[consumeId] = costCountDic[consumeId] or 0
            costCountDic[consumeId] = costCountDic[consumeId] + config.ConsumeCount[i]
        end
    end
    return costCountDic, getCount, resultExchangeConfigs
end

function XUiExchangeAsset:RefreshBuyCountInfo(itemId)
    -- 获取是否能够多次选择
    local canMutiply = XItemConfigs.GetBuyAssetCanMutiply(itemId) > 1
    self.PanelBuyCount.gameObject:SetActiveEx(canMutiply)
    if not canMutiply then return end
    -- 设置是否支持输入
    self.InputBuyCount.interactable = self.SupportInput
    -- 设置当前购买次数
    self.InputBuyCount.text = self.CurrentBuyCount
    -- 如果配置了自定义的数量限制，直接使用自定义的
    if self.CustomMaxCountTextFunc then
        self.TxtExchangeTip.text = self.CustomMaxCountTextFunc()
        self.TxtCanBuyCount.text = self.CustomMaxCountFunc()
    else
        local totalLimitCount = XItemConfigs.GetBuyAssetTotalLimit(itemId)
        local item = XDataCenter.ItemManager.GetItem(itemId)
        local leftTotalCount = totalLimitCount - item.TotalBuyTimes
        local hasTotal = totalLimitCount > 0
        local hasDaily = self.CurrentExchangeData.LeftTimes ~= nil
        -- 每日的 + 总共的
        if hasDaily and hasTotal then
            if self.CurrentExchangeData.LeftTimes < leftTotalCount then
                self.TxtExchangeTip.text = XUiHelper.GetText("BuyAssetDailyExchangeTip")
                self.TxtCanBuyCount.text = self.CurrentExchangeData.LeftTimes .. XUiHelper.GetText("BuyAssetTotalLeftCountTip", leftTotalCount)
            else
                self.TxtExchangeTip.text = XUiHelper.GetText("BuyAssetTotalExchangeTip")
                self.TxtCanBuyCount.text = leftTotalCount
            end
        -- 每日的
        elseif hasDaily then
            self.TxtExchangeTip.text = XUiHelper.GetText("BuyAssetDailyExchangeTip")
            self.TxtCanBuyCount.text = self.CurrentExchangeData.LeftTimes
        -- 总共的
        elseif hasTotal then
            self.TxtExchangeTip.text = XUiHelper.GetText("BuyAssetTotalExchangeTip")
            self.TxtCanBuyCount.text = leftTotalCount
        else -- 都没有配置
            self.TxtExchangeTip.gameObject:SetActiveEx(false)
            self.TxtCanBuyCount.gameObject:SetActiveEx(false)
        end
    end
end

return XUiExchangeAsset