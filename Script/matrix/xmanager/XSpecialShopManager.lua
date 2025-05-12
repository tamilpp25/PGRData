XSpecialShopManagerCreator = function()
    local ScreenAll = CS.XTextManager.GetText("ScreenAll")
    local XSpecialShopManager = {}

    ---
    --- 根据商品数据，得到对应的配置Id
    local function GetFashionId(shopGoodsData)
        local templateId = 0

        if type(shopGoodsData.RewardGoods) == "number" then
            templateId = shopGoodsData.RewardGoods
        else
            templateId = (shopGoodsData.RewardGoods.TemplateId and shopGoodsData.RewardGoods.TemplateId > 0) and
                    shopGoodsData.RewardGoods.TemplateId or
                    shopGoodsData.RewardGoods.Id
        end

        local isWeaponFashion = XDataCenter.ItemManager.IsWeaponFashion(templateId)
        local id = isWeaponFashion and XDataCenter.ItemManager.GetWeaponFashionId(templateId) or templateId
        return id
    end

    ---
    --- 排序角色涂装数据
    --- 涂装系列Id从小到大，0为最后
    --- 可购买优于不可购买
    --- 角色Id从小到大
    local function Sort(a, b)
        local aFashionId = GetFashionId(a)
        local bFashionId = GetFashionId(b)

        -- 涂装系列Id排序，从小到大，0为末尾
        local aSeries = XDataCenter.FashionManager.GetFashionSeries(aFashionId)
        local bSeries = XDataCenter.FashionManager.GetFashionSeries(bFashionId)
        if aSeries ~= bSeries then
            if aSeries == 0 then
                return false
            end
            if bSeries == 0 then
                return true
            end
            return aSeries < bSeries
        end

        -- 购买条件排序，满足条件的排前面
        local aMeetCondition = 1
        local bMeetCondition = 1
        local aConditionIds = a.ConditionIds
        if aConditionIds and #aConditionIds > 0 then
            for _, id in pairs(aConditionIds) do
                local ret = XConditionManager.CheckCondition(id)
                if not ret then
                    aMeetCondition = 0
                end
            end
        end
        local bConditionIds = b.ConditionIds
        if bConditionIds and #bConditionIds > 0 then
            for _, id in pairs(bConditionIds) do
                local ret = XConditionManager.CheckCondition(id)
                if not ret then
                    bMeetCondition = 0
                end
            end
        end
        if aMeetCondition ~= bMeetCondition then
            return aMeetCondition > bMeetCondition
        end

        -- 售罄排序，已售罄的排后面
        local aSellOut = 0
        local bSellOut = 0
        if a.BuyTimesLimit > 0 then
            if a.TotalBuyTimes >= a.BuyTimesLimit then
                aSellOut = 1
            end
        end
        if b.BuyTimesLimit > 0 then
            if b.TotalBuyTimes >= b.BuyTimesLimit then
                bSellOut = 1
            end
        end
        if aSellOut ~= bSellOut then
            return aSellOut < bSellOut
        end

        -- 角色Id排序，从小到大
        -- local aCharacterId = XDataCenter.FashionManager.GetCharacterId(aFashionId)
        -- local bCharacterId = XDataCenter.FashionManager.GetCharacterId(bFashionId)
        -- return aCharacterId < bCharacterId

        -- 按照商品Id（GoodsId）升序
        return a.Id < b.Id
    end

    -- 角色涂装商店：获取所有系列id列表
    function XSpecialShopManager.GetSeriesIdList(shopId)
       local goodsList = XShopManager.GetShopGoodsList(shopId)
       local seriesIdDic = {}
       for _, good in ipairs(goodsList) do
            local fashionId = GetFashionId(good)
            local seriesId = XDataCenter.FashionManager.GetFashionSeries(fashionId)
            seriesIdDic[seriesId] = true
       end

       local seriesIdList = {}
       for id, _ in pairs(seriesIdDic) do
           table.insert(seriesIdList, id)
       end
       table.sort(seriesIdList)
       return seriesIdList
    end

    -- 角色涂装商店：获取对应系列的商品
    function XSpecialShopManager.GetFashionListBySeriesId(shopId, seriesId, tagTxt)
        local screenData = XShopManager.GetShopScreenGroupDataById(XShopManager.ScreenType.FashionType)
        local allGoodList = XShopManager.GetShopGoodsList(shopId)
        local goodList = {}
        for _, good in ipairs(allGoodList) do
            local fashionId = GetFashionId(good)
            local goodSeriesId = XDataCenter.FashionManager.GetFashionSeries(fashionId)
            if goodSeriesId == seriesId then
                if tagTxt and tagTxt ~= ScreenAll then 
                    local charId = XDataCenter.FashionManager.GetCharacterId(good.RewardGoods.TemplateId)
                    for index, screenID in pairs(screenData.ScreenID) do
                        if charId == screenID then
                            local screenName = screenData.ScreenName[index]
                            if screenName == tagTxt then
                                table.insert(goodList, good)
                            end
                            break
                        end
                    end
                else 
                    table.insert(goodList, good)
                end
            end
        end
        table.sort(goodList, Sort)
        return goodList
    end

    -- 角色涂装商店：获取系列的所有标签
    function XSpecialShopManager.GetTagListBySeriesId(shopId, seriesId)
        local tagDic = {}
        local goodList = XSpecialShopManager.GetFashionListBySeriesId(shopId, seriesId)
        local screenData = XShopManager.GetShopScreenGroupDataById(XShopManager.ScreenType.FashionType)
        for _, good in pairs(goodList) do
            local charId = XDataCenter.FashionManager.GetCharacterId(good.RewardGoods.TemplateId)
            for index, screenID in pairs(screenData.ScreenID) do
                if charId == screenID then
                    local screenName = screenData.ScreenName[index]
                    local tag = tagDic[screenName]
                    if not tag then
                        tag = {}
                        tag.Text = screenName
                        tag.Key = index
                        tagDic[screenName] = tag
                    end
                    break
                end
            end
        end

        -- 全部页签
        local minCount = 0
        local allTag = {}
        allTag.Text = ScreenAll
        allTag.Key = minCount
        tagDic[allTag.Text] = allTag

        -- 转成list并排序
        local tagList = {}
        for _, tag in pairs(tagDic) do
            table.insert(tagList, tag)
        end
        table.sort(tagList, function(a, b)
            return a.Key < b.Key
        end)

        return tagList
    end

    -- 武器涂装商店：获取对应标签的武器涂装商品
    function XSpecialShopManager.GetWeaponFashionListByTag(shopId, tagTxt)
        local screenData = XShopManager.GetShopScreenGroupDataById(XShopManager.ScreenType.WeaponType)
        local allGoodList = XShopManager.GetShopGoodsList(shopId)
        local goodList = {}
        for _, good in ipairs(allGoodList) do
            if tagTxt and tagTxt ~= ScreenAll then
                local equipType = XDataCenter.WeaponFashionManager.GetEquipTypeByTemplateId(good.RewardGoods.TemplateId)
                for index, screenID in pairs(screenData.ScreenID) do
                    if equipType == screenID then
                        local screenName = screenData.ScreenName[index]
                        if screenName == tagTxt then
                            table.insert(goodList, good)
                        end
                        break
                    end
                end
            else 
                table.insert(goodList, good)
            end
        end
        return goodList
    end

    ---
    --- 判断是否显示活动商店入口
    function XSpecialShopManager:IsShowEntrance()
        local timeId = XSpecialShopConfigs.GetTimeId()
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end

    return XSpecialShopManager
end