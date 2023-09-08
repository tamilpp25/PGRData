local pairs = pairs
local table = table
local tableInsert = table.insert
local tableSort = table.sort
local MinCount = 0
local MaxCount = 999
XShopManager = XShopManager or {}

local CSUnityEnginePlayerPrefs = CS.UnityEngine.PlayerPrefs

local SYNC_SHOP_SECOND = 5

-- local ShopBaseInfosTemplates = {}            -- Tap显示信息(普通+活动)
local LastSyncShopTimes = {}               -- 商店刷新时间
local ActivityLastSyncShopTime = {}               -- 活动商店刷新时间

-- local LastSyncBaseInfoTime = 0             -- 商店基础信息同步时间
local ShopBaseInfoDict = {}             -- 商店基础信息
local ShopDict = {}                     -- 商店详细信息
local ShopGroup = {}

local ScreenGoodsList = {}
local ScreenTagList = {}

local ScreenAll = CS.XTextManager.GetText("ScreenAll")
local ScreenOther = CS.XTextManager.GetText("ScreenOther")

local COOKIE_DAILYSHOPNEWSUIT_KEY = "DailyShopNewSuit"

local METHOD_NAME = {
    GetShopInfoList = "GetFixedShopListRequest",
    GetShopInfo = "GetShopInfoRequest",
    RefreshShop = "RefreshShopRequest",
    GetShopBaseInfo = "GetShopBaseInfoRequest",
    Buy = "BuyRequest",
}

XShopManager.ShopType = {
    Common = 1, -- 普通商店
    Activity = 2, -- 活动商店
    Points = 3, -- 活动商店
    Dorm = 101,
    Boss = 102,
    Arena = 103,
    Guild = 301,
    FubenDaily = 401,
    WorldBoss = 501, --世界Boss
    SameColorGame = 601,    -- 三消游戏
    PickFlip = 602,    -- 涂装抽卡
    Theatre = 603,  --肉鸽玩法
    AccumulateConsume = 701,  --累消活动
    DlcHunt = 502, --Dlc
}

XShopManager.ShopTags = {
    Not = 0, --无
    HotSale = 1, --热销
    Recommend = 2, --推荐
    TimeLimit = 3, --限时
    DisCount = 4, --打折
    New = 5, --上新
}

XShopManager.SecondTagType = {
    Top = 0, --顶部
    Mid = 1, --中间
    Btm = 2, --底部
    All = 3, --唯一
}

XShopManager.ScreenType = {
    SuitPos = 1, --意识位置
    SuitName = 2, --意识套装
    WeaponType = 3, --武器种类
    FashionType = 4, --涂装所属
    ItemType = 5, --道具种类
    AwakeItemType = 6, --超频道具种类
    ActivitySuitName = 8, --活动套装商店
}

--活动商店
XShopManager.ActivityShopType = {
    BriefShop = 1, --活动界面商店
    NieRShop = 2, --尼尔活动商店
    MoeWarShop = 3, --萌战活动商店
    AreaWar = 4, --全服决战商店
    ColortableShop = 5, --调色板战争商店
    Maverick2 = 6, --异构阵线2.0
    TheatreShop = 7, --肉鸽1商店
    PlanetShop = 8, --行星商店
    RiftShop = 9, --大秘境商店
    CerberusShop = 10, --三头犬小队商店
    BlackRockChessShop = 11, --国际战旗商店
}

--分解商店分类
XShopManager.DecompositionShopId = {
    [XEquipConfig.Classify.Weapon] = {
        [4] = 401,
        [5] = 402,
        [6] = 403,
    },
    [XEquipConfig.Classify.Awareness] = {
        [4] = 404,
        [5] = 405,
        [6] = 406,
    }
}

function XShopManager.ClearBaseInfoData()
    ShopBaseInfoDict = {}
end

function XShopManager.GetShopBaseInfoByType(type)
    local list = {}
    for _, info in pairs(ShopBaseInfoDict) do
        if info.Type == type then
            tableInsert(list, info)
        end
    end

    tableSort(list, function(a, b)
        if a.SecondType == b.SecondType then
            return a.Priority > b.Priority
        else
            return a.SecondType < b.SecondType
        end
    end)

    return list
end

function XShopManager.GetShopBaseInfoByTypeAndTag(type)
    local tmp = {}
    local list = {}
    local tagList = {}
    local shopGroup = XShopManager.GetShopGroup()

    for _, info in pairs(ShopBaseInfoDict) do
        if info.Type == type and not XShopManager.GetShopIsHide(info.Id) then
            tableInsert(tmp, info)
        end
    end

    tableSort(tmp, function(a, b)
        if a.SecondType == b.SecondType then
            return a.Priority > b.Priority
        else
            return a.SecondType < b.SecondType
        end
    end)

    for _, v in pairs(tmp) do
        local tagData = {}
        if v.SecondType > 0 then
            if shopGroup[v.SecondType] then
                if not tagList[v.SecondType] then
                    for i, d in pairs(v) do
                        tagData[i] = d
                    end
                    tagData.Id = 0
                    tagData.SecondType = 0
                    tagData.Name = shopGroup[v.SecondType].TagName
                    tagData.IsHasSnd = true
                    tableInsert(list, tagData)
                    tagList[v.SecondType] = v.SecondType
                end
            else
                v.SecondType = 0
                v.IsHasSnd = false
            end
        else
            v.IsHasSnd = false
        end
        tableInsert(list, v)
    end

    for k, v in pairs(list) do
        if v.SecondType > 0 then
            if list[k - 1].SecondType == 0 then
                v.SecondTagType = XShopManager.SecondTagType.Top
            else
                v.SecondTagType = XShopManager.SecondTagType.Mid
            end

            if list[k + 1] then
                if list[k + 1].SecondType == 0 then
                    if v.SecondTagType == XShopManager.SecondTagType.Mid then
                        v.SecondTagType = XShopManager.SecondTagType.Btm
                    else
                        v.SecondTagType = XShopManager.SecondTagType.All
                    end
                end
            else
                if v.SecondTagType == XShopManager.SecondTagType.Mid then
                    v.SecondTagType = XShopManager.SecondTagType.Btm
                else
                    v.SecondTagType = XShopManager.SecondTagType.All
                end
            end
        end
    end


    return list
end

function XShopManager.GetShopType(shopId)
    local info = ShopBaseInfoDict[shopId]
    if not info then
        XLog.Error("XShopManager.GetShopType error: can not found info, id is " .. shopId)
        return
    end

    return info.Type
end

function XShopManager.GetShopShowIdList(shopId)
    local info = ShopDict[shopId]
    if not info then
        XLog.Error("XShopManager.GetShopShowIdList error: can not found info, id is " .. shopId)
        return
    end

    local list = {}
    if info.ShowIds and #info.ShowIds > 0 then
        list = info.ShowIds
    end

    return list
end

function XShopManager.GetShopName(shopId)
    local info = ShopDict[shopId]
    if not info then
        XLog.Error("XShopManager.GetShopName error: can not found info, id is " .. shopId)
        return
    end
    return info.Name
end

function XShopManager.GetShopConditionIdList(shopId)
    local info = ShopDict[shopId]
    if not info then
        XLog.Error("XShopManager.GetShopConditionIdList error: can not found info, id is " .. shopId)
        return
    end

    local list = {}
    if info.ConditionIds and #info.ConditionIds > 0 then
        list = info.ConditionIds
    end

    return list
end

function XShopManager.GetShopScreenGroupIDList(shopId)
    local info = ShopDict[shopId]
    if not info then
        XLog.Error("XShopManager.GetShopScreenGroupIDList error: can not found info, id is " .. shopId)
        return
    end

    local list = {}
    if info.ScreenGroupList and #info.ScreenGroupList > 0 and info.ScreenGroupList[1] ~= 0 then
        list = info.ScreenGroupList
    end

    return list
end

function XShopManager.GetManualRefreshCost(shopId)
    local shop = ShopDict[shopId]
    if not shop then
        XLog.Error("XShopManager.GetManualRefreshCost error: can not found shop, id is " .. shopId)
        return
    end

    local costInfo = {}
    if shop.RefreshCostId and shop.RefreshCostId > 0 then
        costInfo.RefreshCostId = shop.RefreshCostId
        costInfo.RefreshCostCount = shop.RefreshCostCount
    end

    if shop.ManualResetTimesLimit and shop.ManualResetTimesLimit ~= 0 then
        costInfo.ManualRefreshTimes = shop.ManualRefreshTimes
        costInfo.ManualResetTimesLimit = shop.ManualResetTimesLimit
    end

    return costInfo
end

function XShopManager.GetShopBuyInfo(shopId)
    local shop = ShopDict[shopId]
    if not shop then
        XLog.Error("XShopManager.GetShopBuyInfo error: can not found shop, id is " .. shopId)
        return
    end

    return {
        TotalBuyTimes = shop.TotalBuyTimes,
        BuyTimesLimit = shop.BuyTimesLimit
    }
end

function XShopManager.GetShopLeftBuyTimes(shopId)
    local shop = ShopDict[shopId]
    if not shop then
        XLog.Error("XShopManager.GetShopBuyInfo error: can not found shop, id is " .. shopId)
        return
    end

    local buyTimesLimit = shop.BuyTimesLimit
    if not buyTimesLimit or buyTimesLimit <= 0 then
        return
    end

    local totalBuyTimes = shop.TotalBuyTimes and shop.TotalBuyTimes or 0

    return buyTimesLimit - totalBuyTimes
end

function XShopManager.GetShopTimeInfo(shopId)
    local shop = ShopDict[shopId]
    if not shop then
        XLog.Error("XShopManager.GetShopTimeInfo error: can not found shop, id is " .. shopId)
        return
    end

    local info = {}
    local now = XTime.GetServerNowTimestamp()

    if shop.RefreshTime and shop.RefreshTime > 0 then
        info.RefreshLeftTime = shop.RefreshTime > now and shop.RefreshTime - now or 0
    end

    if shop.ClosedTime and shop.ClosedTime > 0 then
        info.ClosedLeftTime = shop.ClosedTime > now and shop.ClosedTime - now or 0
    end

    return info
end

function XShopManager.GetShopRewardGoods(shopId, itemId)
    local shop = ShopDict[shopId]
    if not shop then
        XLog.Error("XShopManager.GetShopGoods error: can not found shop, id is " .. shopId)
        return
    end
    local tempGoods
    for _, goods in pairs(shop.GoodsList) do
        if goods and goods.RewardGoods and goods.RewardGoods.TemplateId == itemId then
            tempGoods = goods
            break
        end
    end
    return tempGoods
end

function XShopManager.GetLeftTime(endTime)
    return endTime > 0 and endTime - XTime.GetServerNowTimestamp() or endTime
end

function XShopManager.IsShopExist(shopId)
    return ShopBaseInfoDict[shopId] ~= nil
end

function XShopManager.GetShopGoodsList(shopId, notDebugError, ignoreSort)
    local shop = ShopDict[shopId]
    if not shop then
        if not notDebugError then
            XLog.Error("XShopManager.GetShopGoodsList error: can not found shop, id is " .. shopId)
        end
        return {}
    end

    local list = {}
    for _, goods in pairs(shop.GoodsList) do
        local IsLock = false
        for _, v in pairs(goods.ConditionIds) do
            local ret = XConditionManager.CheckCondition(v)
            if not ret then
                IsLock = true
                break
            end
        end

        if not (IsLock and goods.IsHideWhenConditionLimit) then
            tableInsert(list, goods)
        end
    end
    
    if ignoreSort then
        return list
    end
    
    --排序优先级
    tableSort(list, function(a, b)
        -- 是否卖光
        if a.BuyTimesLimit > 0 or b.BuyTimesLimit > 0 then
            -- 如果商品有次数限制，并且达到次数限制，则判断为售罄
            local isSellOutA = a.BuyTimesLimit == a.TotalBuyTimes and a.BuyTimesLimit > 0
            local isSellOutB = b.BuyTimesLimit == b.TotalBuyTimes and b.BuyTimesLimit > 0
            if isSellOutA ~= isSellOutB then
                return isSellOutB
            end
        end

        --是否条件受限
        local IsLockA = false
        local IsLockB = false
        for _, v in pairs(a.ConditionIds) do
            local ret = XConditionManager.CheckCondition(v)
            if not ret then
                IsLockA = true
                break
            end
        end
        for _, v in pairs(b.ConditionIds) do
            local ret = XConditionManager.CheckCondition(v)
            if not ret then
                IsLockB = true
                break
            end
        end
        if IsLockA ~= IsLockB then
            return IsLockB
        end

        -- 是否限时
        if a.SelloutTime ~= b.SelloutTime then
            if a.SelloutTime > 0 and b.SelloutTime > 0 then
                return a.SelloutTime < b.SelloutTime
            elseif a.SelloutTime > 0 and b.SelloutTime <= 0 then
                return XShopManager.GetLeftTime(a.SelloutTime) > 0
            elseif a.SelloutTime <= 0 and b.SelloutTime > 0 then
                return XShopManager.GetLeftTime(b.SelloutTime) < 0
            end
        end

        if a.Tags ~= b.Tags and a.Tags ~= 0 and b.Tags ~= 0 then
            return a.Tags < b.Tags
        end

        if a.Priority ~= b.Priority then
            return a.Priority > b.Priority
        end
    end)
    return list
end

function XShopManager.GetShopGoodsListDoNotSortCondition(shopId)
    local shop = ShopDict[shopId]
    if not shop then
        XLog.Error("XShopManager.GetShopGoodsList error: can not found shop, id is " .. shopId)
        return {}
    end

    local list = {}
    for _, goods in pairs(shop.GoodsList) do
        local IsLock = false
        for _, v in pairs(goods.ConditionIds) do
            local ret = XConditionManager.CheckCondition(v)
            if not ret then
                IsLock = true
                break
            end
        end

        if not (IsLock and goods.IsHideWhenConditionLimit) then
            tableInsert(list, goods)
        end
    end

    --排序优先级
    tableSort(list, function(a, b)
        -- 是否卖光
        if a.BuyTimesLimit > 0 or b.BuyTimesLimit > 0 then
            -- 如果商品有次数限制，并且达到次数限制，则判断为售罄
            local isSellOutA = a.BuyTimesLimit == a.TotalBuyTimes and a.BuyTimesLimit > 0
            local isSellOutB = b.BuyTimesLimit == b.TotalBuyTimes and b.BuyTimesLimit > 0
            if isSellOutA ~= isSellOutB then
                return isSellOutB
            end
        end

        -- 是否限时
        if a.SelloutTime ~= b.SelloutTime then
            if a.SelloutTime > 0 and b.SelloutTime > 0 then
                return a.SelloutTime < b.SelloutTime
            elseif a.SelloutTime > 0 and b.SelloutTime <= 0 then
                return XShopManager.GetLeftTime(a.SelloutTime) > 0
            elseif a.SelloutTime <= 0 and b.SelloutTime > 0 then
                return XShopManager.GetLeftTime(b.SelloutTime) < 0
            end
        end

        if a.Tags ~= b.Tags and a.Tags ~= 0 and b.Tags ~= 0 then
            return a.Tags < b.Tags
        end

        if a.Priority ~= b.Priority then
            return a.Priority > b.Priority
        end
    end)
    return list
end

function XShopManager.GetDefaultShopId()
    local list = XShopManager.GetShopBaseInfoByTypeAndTag(XShopManager.ShopType.Common)
    return list[1].Id
end

local function AddBuyTimes(shopId, goodsId, count)
    local shop = ShopDict[shopId]
    if not shop then
        XLog.Error("XShopManager AddBuyTimes Error: can not found shop, shopId is " .. shopId)
        return
    end

    shop.TotalBuyTimes = shop.TotalBuyTimes + count

    for _, goods in pairs(shop.GoodsList) do
        if goods.Id == goodsId then
            goods.TotalBuyTimes = goods.TotalBuyTimes + count
            break
        end
    end
end

local function SetShop(shop)
    ShopDict[shop.Id] = shop
    LastSyncShopTimes[shop.Id] = XTime.GetServerNowTimestamp()
end

local function SetShopBaseInfoList(shopBaseInfoList)
    -- LastSyncBaseInfoTime = XTime.GetServerNowTimestamp()
    for _, info in pairs(shopBaseInfoList) do
        ShopBaseInfoDict[info.Id] = info
    end
end

function XShopManager.GetShopInfo(shopId, cb, pleaseDoNotTip)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        return
    end
    local now = XTime.GetServerNowTimestamp()
    local syscTime = LastSyncShopTimes[shopId]

    if syscTime and now - syscTime < SYNC_SHOP_SECOND then
        if cb then
            cb()
            return
        end
    end

    XNetwork.Call(METHOD_NAME.GetShopInfo, { Id = shopId }, function(res)
        if res.Code ~= XCode.Success then
            if not pleaseDoNotTip then
                XUiManager.TipCode(res.Code)
            end
            return
        end
        SetShop(res.ClientShop)
        XShopManager.SetScreenData(res.ClientShop.Id)
        if cb then cb() end
    end)
end

---@param shopType number XShopManager.ActivityShopType 每个商店列表都要定义，用于缓存上一次的请求时间，在SYNC_SHOP_SECOND时间内则不重复请求
function XShopManager.GetShopInfoList(shopIdList, cb, shopType, notTip)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        return
    end

    if not shopType then
        XLog.Error("XShopManager.GetShopInfoList() 请求商店列表需要传参shopType")
        return
    end

    local now = XTime.GetServerNowTimestamp()
    local syscTime = ActivityLastSyncShopTime[shopType] or 0
    if syscTime and now - syscTime < SYNC_SHOP_SECOND then
        if cb then
            cb()
            return
        end
    end
    XNetwork.Call(METHOD_NAME.GetShopInfoList, { IdList = shopIdList }, function(res)
        if res.Code ~= XCode.Success then
            if not notTip then
                XUiManager.TipCode(res.Code)
            end
            return
        end
        ActivityLastSyncShopTime[shopType] = XTime.GetServerNowTimestamp()
        for _, v in pairs(res.ClientShopList) do
            SetShop(v)
            XShopManager.SetScreenData(v.Id)
        end
        if cb then cb() end
    end)
end

local function CheckResfreshShopLimit(shopId)
    local shop = ShopDict[shopId]
    if not shop then
        XUiManager.TipCode(XCode.ShopManagerShopNotExist)
        return false
    end

    if shop.BuyTimesLimit and shop.BuyTimesLimit > 0 then
        if shop.TotalBuyTimes >= shop.BuyTimesLimit then
            XUiManager.TipCode(XCode.ShopManagerShopNotBuyTimes)
            return false
        end
    end

    if shop.ManualResetTimesLimit and shop.ManualResetTimesLimit >= 0 then
        if shop.ManualRefreshTimes >= shop.ManualResetTimesLimit then
            XUiManager.TipError(CS.XTextManager.GetText("DifferentRefreshTimes"))
            return false
        end
    end

    if shop.RefreshCostId and shop.RefreshCostId > 0 then
        if shop.RefreshCostCount > XDataCenter.ItemManager.GetItem(shop.RefreshCostId):GetCount() then
            XUiManager.TipError(CS.XTextManager.GetText("RefreshShopItemNotEnough"))
            return false
        end
    end
    return true
end

function XShopManager.RefreshShopGoods(shopId, cb)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        return
    end
    if not CheckResfreshShopLimit(shopId) then
        return
    end

    XNetwork.Call(METHOD_NAME.RefreshShop, { Id = shopId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        SetShop(res.ClientShop)
        if cb then cb() end
    end)
end

function XShopManager.GetBaseInfo(cb)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        return
    end
    XNetwork.Call(METHOD_NAME.GetShopBaseInfo, nil, function(res)
        SetShopBaseInfoList(res.ShopBaseInfoList)
        if cb then cb() end
    end)
end

function XShopManager.BuyShop(shopId, goodsId, count, cb, err_cb)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        return
    end
    local req = { ShopId = shopId, GoodsId = goodsId, Count = count }
    XNetwork.Call(METHOD_NAME.Buy, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if err_cb then
                err_cb()
            end
            return
        end
        AddBuyTimes(shopId, goodsId, count)
        cb()
    end)
end

function XShopManager.GetShopGroup()
    ShopGroup = XShopConfigs.GetShopGroupTemplate()
    return ShopGroup
end

function XShopManager.GetShopTypeDatas()
    local typeData = XShopConfigs.GetShopTypeNameTemplate()
    return typeData
end

function XShopManager.GetShopTypeDataById(id)
    local typeData = XShopConfigs.GetShopTypeNameTemplate()
    return typeData[id]
end

function XShopManager.GetShopScreenGroupDataById(id)
    local screenData = XShopConfigs.GetShopScreenGroupTemplate()
    return screenData[id]
end

function XShopManager.GetShopScreenGroupNameById(id)
    local screenData = XShopConfigs.GetShopScreenGroupTemplate()
    if not screenData[id] then
        return ""
    end
    return screenData[id].GroupName
end

function XShopManager.GetShopScreenGroupIconById(id)
    local screenData = XShopConfigs.GetShopScreenGroupTemplate()
    if (not id) or (not screenData[id]) then
        return nil
    end
    return screenData[id].GroupIcon
end

function XShopManager.GetScreenGoodsListByTag(shopId, group, tag)
    local goodsList = ScreenGoodsList[shopId][group]
    if not goodsList then
        return XShopManager.GetShopGoodsList(shopId)
    end
    if not goodsList[tag] then
        return XShopManager.GetShopGoodsList(shopId)
    end
    return goodsList[tag]
end

function XShopManager.GetScreenTagListById(shopId, groupId)
    return ScreenTagList[shopId][groupId]
end

function XShopManager.SetScreenData(id)
    local GoodsList = XShopManager.GetShopGoodsList(id)
    local ScreenGroupIDList = XShopManager.GetShopScreenGroupIDList(id)
    ScreenGoodsList[id] = {}
    ScreenTagList[id] = {}

    if ScreenGroupIDList then
        for _, screenGroupId in pairs(ScreenGroupIDList) do
            local screenGroup = ScreenGoodsList[id][screenGroupId]
            if not screenGroup then ScreenGoodsList[id][screenGroupId] = {} end

            local tagGroup = ScreenTagList[id][screenGroupId]
            if not tagGroup then ScreenTagList[id][screenGroupId] = {} end

            for _, goods in pairs(GoodsList or {}) do
                if screenGroupId == XShopManager.ScreenType.SuitPos then
                    XShopManager.DoScreen(id, XArrangeConfigs.Types.Wafer,
                    screenGroupId,
                    goods,
                    function()
                        return { XDataCenter.EquipManager.GetEquipSiteByTemplateId(goods.RewardGoods.TemplateId) }
                    end
                    )
                elseif screenGroupId == XShopManager.ScreenType.SuitName
                or screenGroupId == XShopManager.ScreenType.ActivitySuitName then
                    XShopManager.DoScreen(id, XArrangeConfigs.Types.Wafer,
                    screenGroupId,
                    goods,
                    function()
                        return { XDataCenter.EquipManager.GetSuitIdByTemplateId(goods.RewardGoods.TemplateId) }
                    end
                    )
                elseif screenGroupId == XShopManager.ScreenType.WeaponType then
                    XShopManager.DoScreen(id, XArrangeConfigs.Types.Weapon,
                    screenGroupId,
                    goods,
                    function()
                        if XArrangeConfigs.GetType(goods.RewardGoods.TemplateId) == XArrangeConfigs.Types.Weapon then 
                            return { XDataCenter.EquipManager.GetEquipTypeByTemplateId(goods.RewardGoods.TemplateId) }
                        else
                            return { XDataCenter.WeaponFashionManager.GetEquipTypeByTemplateId(goods.RewardGoods.TemplateId) }
                        end
                    end
                    )
                elseif screenGroupId == XShopManager.ScreenType.FashionType then
                    XShopManager.DoScreen(id, XArrangeConfigs.Types.Fashion,
                    screenGroupId,
                    goods,
                    function()
                        return { XDataCenter.FashionManager.GetCharacterId(goods.RewardGoods.TemplateId) }
                    end
                    )
                elseif screenGroupId == XShopManager.ScreenType.ItemType then
                    XShopManager.DoScreen(id, XArrangeConfigs.Types.Item,
                    screenGroupId,
                    goods,
                    function()
                        return { XDataCenter.ItemManager.GetItemType(goods.RewardGoods.TemplateId) }
                    end
                    )
                elseif screenGroupId == XShopManager.ScreenType.AwakeItemType then
                    XShopManager.DoScreen(id, XArrangeConfigs.Types.Item,
                    screenGroupId,
                    goods,
                    function()
                        return XDataCenter.EquipManager.GetAwakeItemApplicationScope(goods.RewardGoods.TemplateId)
                    end
                    )
                end
            end
        end
    end

    if ScreenTagList[id] then
        for index, screenTag in pairs(ScreenTagList[id]) do
            local list = {}
            for _, v in pairs(screenTag) do
                table.insert(list, v)
            end
            tableSort(list, function(a, b)
                return a.Key < b.Key
            end)
            ScreenTagList[id][index] = list
        end
    end
end

function XShopManager.DoScreen(id, goodstype, screenGroupId, goods, getkeyList)
    local tmpScreenData = XShopManager.GetShopScreenGroupDataById(screenGroupId)
    local screenGroup = ScreenGoodsList[id][screenGroupId]
    local tagGroup = ScreenTagList[id][screenGroupId]
    if XShopManager.CheckIsSameType(goods.RewardGoods.TemplateId, goodstype) then
        local IsIn = false
        local keyList = getkeyList()
        if keyList and tmpScreenData and tmpScreenData.ScreenID then
            for _, key in pairs(keyList) do
                for index, screenID in pairs(tmpScreenData.ScreenID) do
                    if key ~= screenID then
                        goto continue
                    end

                    local screenName = tmpScreenData.ScreenName[index]
                    local goodsList = screenGroup[screenName]
                    if not goodsList then
                        goodsList = {}
                        screenGroup[screenName] = goodsList
                    end
                    table.insert(goodsList, goods)

                    local tag = tagGroup[screenName]
                    if not tag then
                        tag = {}
                        tag.Text = screenName
                        tag.Key = index
                        tagGroup[screenName] = tag
                    end

                    IsIn = true
                    break

                    :: continue ::
                end
            end
        end

        if not IsIn then
            local otherGoodsList = screenGroup[ScreenOther]
            if not otherGoodsList then
                otherGoodsList = {}
                screenGroup[ScreenOther] = otherGoodsList
            end
            table.insert(otherGoodsList, goods)

            local otherTag = tagGroup[ScreenOther]
            if not otherTag then
                otherTag = {}
                otherTag.Text = ScreenOther
                otherTag.Key = MaxCount
                tagGroup[ScreenOther] = otherTag
            end
        end
    else
        local otherGoodsList = screenGroup[ScreenOther]
        if not otherGoodsList then
            otherGoodsList = {}
            screenGroup[ScreenOther] = otherGoodsList
        end
        table.insert(otherGoodsList, goods)

        local otherTag = tagGroup[ScreenOther]
        if not otherTag then
            otherTag = {}
            otherTag.Text = ScreenOther
            otherTag.Key = MaxCount
            tagGroup[ScreenOther] = otherTag
        end
    end

    local allGoodsList = screenGroup[ScreenAll]
    if not allGoodsList then
        allGoodsList = {}
        screenGroup[ScreenAll] = allGoodsList
    end
    table.insert(allGoodsList, goods)

    local allTag = tagGroup[ScreenAll]
    if not allTag then
        allTag = {}
        allTag.Text = ScreenAll
        allTag.Key = MinCount
        tagGroup[ScreenAll] = allTag
    end
end

function XShopManager.CheckIsSameType(templateId, type)
    if XArrangeConfigs.GetType(templateId) == type then  
        return true
    end

    -- 1.31新增武器涂装
    if type == XShopManager.ScreenType.WeaponType and XArrangeConfigs.GetType(templateId) == XArrangeConfigs.Types.Item then 
        local subTypeParams = XItemConfigs.GetItemSubTypeParams(templateId)
        if subTypeParams and #subTypeParams > 0 then
            local isWeaponFashion = XWeaponFashionConfigs.IsWeaponFashion(subTypeParams[1])
            if isWeaponFashion then  
                return true
            end
        end
    end

    return false
end


function XShopManager.CheckDailyShopSuitIsNew(suitId, suitShopItemList)
    for _, v in ipairs(suitShopItemList) do
        if v.Tags == XShopManager.ShopTags.New then
            local key = COOKIE_DAILYSHOPNEWSUIT_KEY .. suitId
            return not XShopManager.ReadCookie(key)
        end
    end

    return false
end

function XShopManager.SetDailyShopSuitNotNew(suitId)
    local key = COOKIE_DAILYSHOPNEWSUIT_KEY .. suitId
    CSUnityEnginePlayerPrefs.SetInt(XShopManager.GetCookieKeyStr(key), 1)
    CSUnityEnginePlayerPrefs.Save()
end

function XShopManager.CheckDailyShopHasNewSuit(shopItemList)
    if not shopItemList then
        return false
    end

    for _, data in ipairs(shopItemList) do
        if data.Tags == XShopManager.ShopTags.New then
            local suitId = XDataCenter.EquipManager.GetSuitIdByTemplateId(data.RewardGoods.TemplateId)
            local key = COOKIE_DAILYSHOPNEWSUIT_KEY .. suitId
            if not XShopManager.ReadCookie(key) then
                return true
            end
        end
    end
    return false
end

function XShopManager.GetCookieKeyStr(key)
    local str = string.format("%s%s%s", "SHOP_COOKIE", XPlayer.Id, key)
    return str
end

function XShopManager.ReadCookie(key)
    return CSUnityEnginePlayerPrefs.HasKey(XShopManager.GetCookieKeyStr(key))
end

function XShopManager.GetShopIsHide(shopId)
    if not XUiManager.IsHideFunc then
        return false
    end
    return XShopConfigs.CheckShopIdIsHide(shopId)
end

-- region v1.29 商店优化
-- 在shop表里新增字段refreshtips，控制对应的商店页签倒计时旁是否显示刷新tips，以及tips文本内容，若填写内容则显示tips按钮以及点击按钮后显示配置文本，若未填写，则不显示按钮。
function XShopManager.GetShopShowRefreshTips(shopId)
    local info = ShopDict[shopId]
    if not info then
        XLog.Error("XShopManager.GetShopShowRefreshTips error: can not found info, id is " .. shopId)
        return
    end
    local refreshTips = info.RefreshTips
    if not refreshTips or refreshTips == "" then
        return false
    end
    return refreshTips
end

function XShopManager.GetTagScreenAll()
    return ScreenAll
end

function XShopManager.GetTagScreenOther()
    return ScreenOther
end

function XShopManager.SaveGoodsOrder(goodsList, goodsOrder)
    for i = 1, # goodsList do
        local id = goodsList[i].Id
        local order = i
        goodsOrder[id] = order
    end
end

function XShopManager.SortByOldGoodsOrder(goodsList, goodsOrder)
    -- clone是因为这是从shopManager拿的数据,不能修改manager里保存的顺序
    goodsList = XTool.Clone(goodsList)
    table.sort(goodsList, function(a, b)
        local orderA = goodsOrder[a.Id] or math.huge
        local orderB = goodsOrder[b.Id] or math.huge
        return orderB > orderA
    end)
    return goodsList
end

function XShopManager.GetScreenGoodsListByTagEx(shopId, group, tag)
    local goodsList = ScreenGoodsList[shopId][group]
    if not goodsList then
        return {}
    end
    return goodsList[tag] or {}
end

--endregion

--===================v1.31【商店优化】大额消费二次确认=======================
-- 二次确认弹窗
-- @consumeId:货币ItemId
-- @consumeCount:商品单价
-- @buyCount:商品购买数量
-- @rewardGoods:商品
function XShopManager.OpenBuySecondConfirm(consumeId, consumeCount, buyCount, rewardGoods, closeCallBack, confirmCallBack)
    local secondConfirmData = {
        ConsumeId = consumeId,
        ConsumeCount = consumeCount,
        BuyCount = buyCount,
        RewardGoods = rewardGoods,
        CancelCB = closeCallBack,
        ConfirmCB = confirmCallBack
    }
    XLuaUiManager.Open("UiBuySecondConfirm", secondConfirmData)
end

-- 判断是否需要二级弹窗确认购买
-- @consumeId:货币ItemId
-- @consumeCount:商品单价
-- @buyCount:商品购买数量
function XShopManager.IsNeedSecondConfirm(consumeId, consumeCount)
    local costNum = XShopConfigs.GetCostNumByItemId(consumeId)
    if XTool.IsNumberValid(costNum) and consumeCount >= costNum then
        return true
    else
        return false
    end
end

-- 获取购买后货币剩余值
-- @consumeId:货币ItemId
-- @consumeCount:商品单价
-- @buyCount:商品购买数量
function XShopManager.GetAfterSecondConfirmCoin(consumeId, consumeCount)
    local costNum = consumeCount
    local nowNum = XDataCenter.ItemManager.GetCount(consumeId)
    return nowNum - costNum
end
--==========================================================================

function XShopManager.GetShopScreenGroupSelectValueAndScreenNum(shopId, screenId)
    local screenGroupIDList = XShopManager.GetShopScreenGroupIDList(shopId) 
    if XTool.IsTableEmpty(screenGroupIDList) then 
        return nil 
    end
    
    local screenNum
    local text
    for index, screenGroupId in ipairs(screenGroupIDList) do
        local screenGroup = XShopConfigs.GetShopScreenGroupTemplate()[screenGroupId]
        for i, id in ipairs(screenGroup.ScreenID) do
            if screenId == id then
                text = screenGroup.ScreenName[i]
                screenNum = index
            end
        end
    end

    local info = XShopManager.GetScreenTagListById(shopId, screenGroupIDList[screenNum])
    if not info then return nil end
    if not string.IsNilOrEmpty(text) then
        for index, item in ipairs(info) do
            if text == item["Text"] then
                return index, screenNum
            end
        end
    end
    return nil
end
