XSpecialShopManagerCreator = function()
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
        local aCharacterId = XDataCenter.FashionManager.GetCharacterId(aFashionId)
        local bCharacterId = XDataCenter.FashionManager.GetCharacterId(bFashionId)
        return aCharacterId < bCharacterId
    end

    ---
    --- 将'fashionData'分成最大长度为'maxSegSize'的分段，每一段都是同一系列的涂装
    ---
    --- 'fashionData'为 按涂装系列Id排序 的数组
    --- 长度不足'maxSegSize'的分段，剩余的数据为nil
    --- 'isSeries'是否要区分系列
    local function Segment(fashionData, maxSegSize, isSeries)
        local result = {}
        local segmentation = {}
        if next(fashionData) and isSeries then
            segmentation.First = true -- 同系列的首个片段
        end

        local preSeries -- 当前片段上一个涂装所属的系列，如果为nil，说明当前片段为空

        for _, data in ipairs(fashionData) do
            if #segmentation == maxSegSize then
                -- 到达最大长度
                table.insert(result, segmentation)
                segmentation = {}
                preSeries = nil
            end

            local curFashionId = GetFashionId(data)
            local curSeries = XDataCenter.FashionManager.GetFashionSeries(curFashionId)

            -- 是否需要区分系列
            if preSeries  and isSeries then
                if  preSeries ~= curSeries then
                    -- 当前涂装与segmentation内的涂装不同系列,使用新的片段
                    table.insert(result, segmentation)
                    segmentation = {}
                    segmentation.First = true
                    preSeries = nil
                end
            end

            if not segmentation.SeriesId then
                segmentation.SeriesId = curSeries
            end

            table.insert(segmentation, data)
            preSeries = curSeries
        end

        if next(segmentation) then
            -- 把在循环中剩余的片段放入结果中
            table.insert(result, segmentation)
            segmentation = {}
            preSeries = nil
        end

        return result
    end

    ---
    --- 得到商品行的数据,一行有 XSpecialShopConfigs.MAX_COUNT 个商品
    --- 'groupId'筛选组Id
    --- 'selectTag'筛选标签
    --- 'isSeries'是否要区分系列，true区分，false不区分
    function XSpecialShopManager.GetCommodityLineData(shopId, groupId, selectTag, isSeries)
        local goodsList = XShopManager.GetScreenGoodsListByTag(shopId, groupId, selectTag)
        table.sort(goodsList, Sort)

        goodsList = Segment(goodsList, XSpecialShopConfigs.MAX_COUNT, isSeries)
        return goodsList
    end

    ---
    --- 判断是否显示活动商店入口
    function XSpecialShopManager:IsShowEntrance()
        local timeId = XSpecialShopConfigs.GetTimeId()
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end

    return XSpecialShopManager
end