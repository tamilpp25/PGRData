XItemManagerCreator = function()

    local XItemManager = {}

    local tableInsert = table.insert
    local tableRemove = table.remove
    local tableSort = table.sort
    local mathCeil = math.ceil
    local mathMin = math.min

    local Items = {}                                -- 所有道具数据
    local RecItemIds = {}                           -- 恢复类道具
    local SuppliesItems = {}                        -- 补给类道具
    local BuyAssetTemplates = {}                    -- 购买资源配置表
    local BuyAssetDailyLimit = {}                   -- 购买资源每日限制
    local ItemTemplates = {}
    local ItemFirstGetCheckTable = {}
    local RedEnvelopeInfos = {}                      -- 红包道具使用记录

    local BuyAssetCoinBase    = 0
    local BuyAssetCoinMul    = 0
    -- local BuyAssetCoinCritProb = 0
    -- local BuyAssetCoinCritMul = 0
    -- item 参数下表
    -- local PARAM_ACTIONPOINT_INTERVAL = 1
    -- local PARAM_ACTIONPOINT_NUM = 2
    local RecTimer

    XItemManager.ItemId = {
        Coin = 1,
        PaidGem = 2,
        FreeGem = 3,
        ActionPoint = 4,
        HongKa = 5,
        TeamExp = 7,
        AndroidHongKa = 8,
        IosHongKa = 10,
        SkillPoint = 12,
        DailyActiveness = 13,
        WeeklyActiveness = 14,
        HostelElectric = 15,
        HostelMat = 16,
        OnlineBossTicket = 17,
        BountyTaskExp = 18,
        DormCoin = 30,
        FurnitureCoin = 31,
        DormEnterIcon = 36,
        BaseEquipCoin = 300,
        InfestorActionPoint = 50,
        InfestorMoney = 51,
        PokemonLevelUpItem = 56,
        PokemonStarUpItem = 57,
        PokemonLowStarUpItem = 58,
        PassportExp = 60,
        TRPGTalen = 61000,
        TRPGMoney = 61001,
        TRPGEXP = 61002,
        TRPGEndurance = 61003,
        UniversalWord = 62309,
        EquipRecycleItemId = CS.XGame.Config:GetInt("EquipRecycleItemId"),
        MoeWarRespondItemId = 62501, --萌战应援票
        MoeWarPreparationItemId = 62505, --萌战筹备度
        MoeWarCommunicateItemId = 62506, --萌战通讯次数
        PokerGuessingItemId = 62711, --翻牌比大小活动物品
        SuperTowerBagItemId = 62801, --超级爬塔背包扩容道具Id
    }

    --时效性道具初始时间计算方式
    XItemManager.TimelinessType = {
        Invalid = 0,
        FromConfig = 1, --通过配置
        AfterGet = 2, --获取后
        Batch = 3, --按时间分批次
    }

    --礼包类型
    XItemManager.GiftItemUseType = {
        Reward = 1,
        Drop = 2,
        OptionalReward = 3,
        RedEnvelope = 4,
    }

    --特殊补给道具
    XItemManager.SuppliesItemType = {
        Battery = 90000,
        CoinPackage = 91000
    }

    XItemManager.SubType_1 = {
        Reward = 1,
    }

    XItemManager.SUBTYPE_EXP = 2

    XItemManager.PageRecordCache = XItemConfigs.PageType.Equip -- 仓库默认选择标签

    local METHOD_NAME = {
        Sell = "ItemSellRequest",
        Use = "ItemUseRequest",
        BuyAsset = "ItemBuyAssetRequest",
        MultiplyUse = "ItemUseMultipleRequest",
    }

    local BAG_ITEM_SORT_FUNC = function(a, b)
        local aItemId = a.Data.Id
        local bItemId = b.Data.Id

        --优先级排序
        local aPriority = XItemManager.GetItemPriority(aItemId)
        local bPriority = XItemManager.GetItemPriority(bItemId)
        if aPriority ~= bPriority then
            return aPriority > bPriority
        end

        --溢出排序
        local aIsCanConvert = XItemManager.IsCanConvert(aItemId)
        local bIsCanConvert = XItemManager.IsCanConvert(bItemId)
        if aIsCanConvert ~= bIsCanConvert then
            return aIsCanConvert
        end

        --可使用排序
        local aIsUseable = XItemManager.IsUseable(aItemId)
        local bIsUseable = XItemManager.IsUseable(bItemId)
        if aIsUseable ~= bIsUseable then
            return aIsUseable
        end

        --时效性排序
        local aIsTimeLimit = XItemManager.IsTimeLimit(aItemId)
        local bIsTimeLimit = XItemManager.IsTimeLimit(bItemId)
        if aIsTimeLimit ~= bIsTimeLimit then
            return aIsTimeLimit
        elseif aIsTimeLimit then
            --剩余时间排序
            local nowTime = XTime.GetServerNowTimestamp()
            local aleftTime = a.RecycleBatch and a.RecycleBatch.RecycleTime - nowTime or XDataCenter.ItemManager.GetRecycleLeftTime(aItemId)
            local bleftTime = b.RecycleBatch and b.RecycleBatch.RecycleTime - nowTime or XDataCenter.ItemManager.GetRecycleLeftTime(bItemId)
            if aleftTime ~= bleftTime then
                return aleftTime < bleftTime
            end
        end

        --品质排序
        local aQuality = XItemManager.GetItemQuality(aItemId)
        local bQuality = XItemManager.GetItemQuality(bItemId)
        if aQuality ~= bQuality then
            return aQuality > bQuality
        end

        --Id排序
        if aItemId ~= bItemId then
            return aItemId < bItemId
        end

        --数量排序
        if a.Count ~= b.Count then
            return a.Count > b.Count
        end

        return false
    end

    local CONSUMABLES_ITEM_SORT_FUNC = function(a, b)
        local aItemId = a.Data.Id
        local bItemId = b.Data.Id

        --溢出排序
        local aIsCanConvert = XItemManager.IsCanConvert(aItemId)
        local bIsCanConvert = XItemManager.IsCanConvert(bItemId)
        if aIsCanConvert ~= bIsCanConvert then
            return aIsCanConvert
        end

        --可使用排序
        local aIsUseable = XItemManager.IsUseable(aItemId)
        local bIsUseable = XItemManager.IsUseable(bItemId)
        if aIsUseable ~= bIsUseable then
            return aIsUseable
        end

        --时效性排序
        local aIsTimeLimit = XItemManager.IsTimeLimit(aItemId)
        local bIsTimeLimit = XItemManager.IsTimeLimit(bItemId)
        if aIsTimeLimit ~= bIsTimeLimit then
            return aIsTimeLimit
        elseif aIsTimeLimit then
            --剩余时间排序
            local nowTime = XTime.GetServerNowTimestamp()
            local aleftTime = a.RecycleBatch and a.RecycleBatch.RecycleTime - nowTime or XDataCenter.ItemManager.GetRecycleLeftTime(aItemId)
            local bleftTime = b.RecycleBatch and b.RecycleBatch.RecycleTime - nowTime or XDataCenter.ItemManager.GetRecycleLeftTime(bItemId)
            if aleftTime ~= bleftTime then
                return aleftTime < bleftTime
            end
        end

        --优先级排序
        local aPriority = XItemManager.GetItemPriority(aItemId)
        local bPriority = XItemManager.GetItemPriority(bItemId)
        if aPriority ~= bPriority then
            return aPriority > bPriority
        end

        --品质排序
        local aQuality = XItemManager.GetItemQuality(aItemId)
        local bQuality = XItemManager.GetItemQuality(bItemId)
        if aQuality ~= bQuality then
            return aQuality > bQuality
        end

        --Id排序
        if aItemId ~= bItemId then
            return aItemId < bItemId
        end

        --数量排序
        if a.Count ~= b.Count then
            return a.Count > b.Count
        end

        return false
    end

    local EXP_ITEM_SORT_CMP = function(a, b)
        if a.Template.Id ~= b.Template.Id then
            if a.Template.Id == XDataCenter.ItemManager.ItemId.EquipRecycleItemId then
                return true
            end
            if b.Template.Id == XDataCenter.ItemManager.ItemId.EquipRecycleItemId then
                return false
            end
        end

        if a.Template.Quality ~= b.Template.Quality then
            return a.Template.Quality < b.Template.Quality
        end

        if a.Template.GetExp() ~= b.Template.GetExp() then
            return a.Template.GetExp() < b.Template.GetExp()
        end

        if a.Template.Priority ~= b.Template.Priority then
            return a.Template.Priority > b.Template.Priority
        end

        if a.Count ~= b.Count then
            return a.Count > b.Count
        end

        return false
    end

    function XItemManager.Init()
        ItemTemplates = XItemConfigs.GetItemTemplates()
        BuyAssetDailyLimit = XItemConfigs.GetBuyAssetDailyLimit()
        BuyAssetTemplates = XItemConfigs.GetBuyAssetTemplates()
        BuyAssetCoinBase    = CS.XGame.Config:GetInt("BuyAssetCoinBase")
        BuyAssetCoinMul    = CS.XGame.Config:GetInt("BuyAssetCoinMul")
        -- BuyAssetCoinCritProb = CS.XGame.Config:GetInt("BuyAssetCoinCritProb")
        -- BuyAssetCoinCritMul = CS.XGame.Config:GetInt("BuyAssetCoinCritMul")

        XItemManager.PageRecordCache = XItemConfigs.PageType.Equip

        XEventManager.AddEventListener(XEventId.EVENT_USER_LOGOUT, function()
            if RecTimer then
                XScheduleManager.UnSchedule(RecTimer)
            end
        end)

        XItemManager.InitAllItems()
    end

    function XItemManager.InitAllItems()
        Items = {}
        for id, template in pairs(ItemTemplates) do
            local item
            if template.RecType == XResetManager.ResetType.NoNeed then
                item = XItem.New(nil, template)
            else
                item = XRecItem.New(nil, template)
                tableInsert(RecItemIds, id)
            end
            -- 存储补给包相关数据（电池、螺母包）
            if template.SubTypeParams[1] == XItemManager.SubType_1.Reward then
                local subType3 = template.SubTypeParams[3]
                if subType3 == XItemManager.SuppliesItemType.Battery then
                    SuppliesItems[XItemManager.SuppliesItemType.Battery] = SuppliesItems[XItemManager.SuppliesItemType.Battery] or {}
                    tableInsert(SuppliesItems[XItemManager.SuppliesItemType.Battery], item.Id)
                elseif subType3 == XItemManager.SuppliesItemType.CoinPackage then
                    SuppliesItems[XItemManager.SuppliesItemType.CoinPackage] = SuppliesItems[XItemManager.SuppliesItemType.CoinPackage] or {}
                    tableInsert(SuppliesItems[XItemManager.SuppliesItemType.CoinPackage], item.Id)
                end
            end
            Items[item.Id] = item
        end
    end

    function XItemManager.AddItemListener()
        RecTimer = XScheduleManager.ScheduleForever(function()
            for _, id in pairs(RecItemIds) do
                Items[id]:CheckCount()
            end
        end, XScheduleManager.SECOND, 0)
    end

    function XItemManager.InitItemData(items)
        for _, itemData in pairs(items) do
            if Items[itemData.Id] then
                Items[itemData.Id]:RefreshItem(itemData)
                ItemFirstGetCheckTable[itemData.Id] = true
            else
                XLog.ErrorTableDataNotFound("XItemManager.InitItemData", "Item", " Share/Item/Item.tab", "Id", tostring(itemData.Id))
            end
        end

        XItemManager.AddItemListener()
    end

    function XItemManager.InitItemRecycle(list)
        -- 回收道具时限表
        if not list then return end
        for id, itemRecycleList in pairs(list) do
            Items[id].ItemRecycleList = itemRecycleList
        end
    end

    function XItemManager.InitBatchItemRecycle(data)
        if not data or not next(data) then return end
        XItemManager.NotifyBatchItemRecycle(data)
    end

    -- 获取数据
    function XItemManager.GetItemTemplate(id)
        local tab = ItemTemplates[id]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XItemManager.GetItemTemplate", "ItemTemplate", " Share/Item/Item.tab", "id", tostring(id))
        end
        return tab
    end

    function XItemManager.GetItemQuality(id)
        local tab = ItemTemplates[id]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XItemManager.GetItemQuality", "ItemTemplate", " Share/Item/Item.tab", "id", tostring(id))
            return
        end
        return tab.Quality
    end

    function XItemManager.GetItemType(id)
        local tab = ItemTemplates[id]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XItemManager.GetItemType", "ItemTemplate", " Share/Item/Item.tab", "id", tostring(id))
            return
        end
        return tab.ItemType
    end

    function XItemManager.GetItemPriority(id)
        local tab = ItemTemplates[id]
        if tab == nil then
            XLog.ErrorTableDataNotFound("XItemManager.GetItemPriority", "ItemTemplate", " Share/Item/Item.tab", "id", tostring(id))
            return
        end
        return tab.Priority
    end

    function XItemManager.GetItemBigIcon(id)
        local tab = XItemManager.GetItemTemplate(id)
        if tab == nil then
            XLog.ErrorTableDataNotFound("XItemManager.GetItemBigIcon", "ItemTemplate", " Share/Item/Item.tab", "id", tostring(id))
            return
        end

        return tab.BigIcon
    end

    function XItemManager.GetItemIcon(id)
        local tab = XItemManager.GetItemTemplate(id)
        if tab == nil then
            XLog.ErrorTableDataNotFound("XItemManager.GetItemIcon", "ItemTemplate", " Share/Item/Item.tab", "id", tostring(id))
            return nil
        end

        return tab.Icon
    end

    function XItemManager.GetItemDescription(id)
        local tab = XItemManager.GetItemTemplate(id)
        if tab == nil then
            XLog.ErrorTableDataNotFound("XItemManager.GetItemDescription", "ItemTemplate", " Share/Item/Item.tab", "id", tostring(id))
            return
        end

        return tab.Description
    end

    function XItemManager.GetItemWorldDesc(id)
        local tab = XItemManager.GetItemTemplate(id)
        if tab == nil then
            XLog.ErrorTableDataNotFound("XItemManager.GetItemWorldDesc", "ItemTemplate", " Share/Item/Item.tab", "id", tostring(id))
            return
        end

        return tab.WorldDesc
    end

    function XItemManager.GetItemSkipIdParams(id)
        local tab = XItemManager.GetItemTemplate(id)
        if tab == nil then
            XLog.ErrorTableDataNotFound("XItemManager.GetItemSkipIdParams", "ItemTemplate", " Share/Item/Item.tab", "id", tostring(id))
            return
        end

        return tab.SkipIdParams
    end

    function XItemManager.GetBuyAssetTemplate(targetId, times, notTipError)
        local template = BuyAssetTemplates[targetId]

        if template == nil then
            if not notTipError then
                XLog.ErrorTableDataNotFound("XItemManager.GetBuyAssetTemplate", "template", "Share/Item/BuyAsset.tab", "targetId", tostring(targetId))
            end
            return
        end

        local config = template[1]
        for i = 1, #template do
            if template[i].Times > times then
                return config
            end
            config = template[i]
        end

        return config
    end

    function XItemManager.GetAllBuyAssetTemplate()
        return BuyAssetTemplates
    end

    function XItemManager.GetBuyAssetTemplateById(id)
        if not BuyAssetTemplates then
            return nil
        end

        return BuyAssetTemplates[id]
    end

    function XItemManager.GetRedEnvelopeCertainNpcItemCount(activityId, npcId, itemId)
        local count = 0

        local redEnvelope = RedEnvelopeInfos[activityId]
        if not redEnvelope then
            return count
        end

        local reward = redEnvelope[npcId]
        count = reward and reward[itemId] or count

        return count
    end

    function XItemManager.GetItem(id)
        if (id == XItemManager.ItemId.FreeGem or id == XItemManager.ItemId.PaidGem) then
            local freeGem = Items[XItemManager.ItemId.FreeGem]
            local paidGem = Items[XItemManager.ItemId.PaidGem]

            local mergeGem = XItem.New(nil, freeGem.Template)
            mergeGem.Count = mergeGem.Count + freeGem.Count + paidGem.Count

            return mergeGem
        else
            return Items[id]
        end
    end

    function XItemManager.GetCount(id)
        if (id == XItemManager.ItemId.FreeGem or id == XItemManager.ItemId.PaidGem) then
            return Items[XItemManager.ItemId.FreeGem]:GetCount() +
            Items[XItemManager.ItemId.PaidGem]:GetCount()
        elseif id == XGuildConfig.GuildContributeCoin then
            return XDataCenter.GuildManager.GetGuildContributeLeft() or 0
        elseif id == XItemManager.ItemId.TRPGEXP then
            return XDataCenter.TRPGManager.GetExploreCurExp()
        end
        return Items[id] and Items[id]:GetCount() or 0
    end

    function XItemManager.GetFreeGemCount()
        return Items[XItemManager.ItemId.FreeGem]:GetCount()
    end

    function XItemManager.GetPaidGemCount()
        return Items[XItemManager.ItemId.PaidGem]:GetCount()
    end

    function XItemManager.GetMaxCount(id)
        return Items[id] and Items[id]:GetMaxCount() or 0
    end

    function XItemManager.GetItemsByType(itemType)
        local list = {}

        for _, item in pairs(Items) do
            if item.Template.ItemType == itemType and item:GetCount() > 0 then
                tableInsert(list, item)
            end
        end

        return list
    end

    function XItemManager.GetItemsByTypeAndSuitId(itemType, suitId)
        local list = {}

        for _, item in pairs(Items) do
            local isSuit = suitId == nil
            local cfg = XItemManager.GetItemTemplate(item.Id)
            if not isSuit then
                isSuit = suitId == XItemConfigs.SuitAllType.All or suitId == XItemConfigs.SuitAllType.DefaultAll or suitId == cfg.SuitId
            end

            if cfg.ItemType == itemType and item:GetCount() > 0 and isSuit then
                tableInsert(list, item)
            end
        end

        return list
    end

    function XItemManager.GetCardExpItems()
        local list = XItemManager.GetItemsByType(XItemConfigs.ItemType.CardExp)
        tableSort(list, function(a, b)
            return a.Template.Exp < b.Template.Exp
        end)
        return list
    end

    function XItemManager.GetEquipExpItems(equipClassify)
        local result = {}

        for _, item in pairs(Items) do
            if (item.Template.ItemType == XItemConfigs.ItemType.EquipExp
            or item.Template.ItemType == XItemConfigs.ItemType.EquipExpNotInBag)
            and item.Template.Classify == equipClassify
            and item:GetCount() > 0
            then
                tableInsert(result, item)
            end
        end
        tableSort(result, EXP_ITEM_SORT_CMP)

        return result
    end

    function XItemManager.GetPartnerExpItems()
        local list = XItemManager.GetItemsByType(XItemConfigs.ItemType.PartnerExp)
        tableSort(list, function(a, b)
            return a.Template.Exp < b.Template.Exp
        end)
        return list
    end

    function XItemManager.GetCharExp(id, subType)
        local template = XItemManager.GetItemTemplate(id)
        return template.GetExp(subType)
    end

    function XItemManager.GetItemsAddEquipExp(id, count)
        count = count or 1
        local template = XItemManager.GetItemTemplate(id)
        return template.GetExp() * count
    end

    function XItemManager.GetItemsAddEquipCost(id, count)
        count = count or 1
        local template = XItemManager.GetItemTemplate(id)
        return template.GetCost() * count
    end

    function XItemManager.GetTeamExp(id)
        local PARAM_EXP = 1
        local template = XItemManager.GetItemTemplate(id)
        return template.SubTypeParams[PARAM_EXP]
    end

    function XItemManager.GetBuyAssetInfo(targetId)
        if not targetId then
            return
            XLog.Error("XItemManager.GetBuyAssetInfo函数参数错误, 参数targetId不能为空")
        end

        -- 获取购买次数
        local times = 0
        if Items[targetId] then
            times = Items[targetId].BuyTimes or 0
        end

        -- 检查是否达到每日上限,读表
        local dayLimit = BuyAssetDailyLimit[targetId]
        local template
        if dayLimit and dayLimit > 0 and times >= dayLimit then
            template = XItemManager.GetBuyAssetTemplate(targetId, dayLimit)
        else
            template = XItemManager.GetBuyAssetTemplate(targetId, times + 1)
        end


        local targetCount = template.GainCount

        -- 计算消耗量
        if targetId == XItemManager.ItemId.Coin then
            targetCount = (BuyAssetCoinBase + XPlayer.Level * BuyAssetCoinMul) * targetCount
        end

        -- 返回
        return {
            LeftTimes = dayLimit > 0 and dayLimit - times or nil,
            TargetId = targetId,
            TargetCount = targetCount,
            ConsumeId = template.ConsumeId,
            ConsumeCount = template.ConsumeCount,
        }
    end

    function XItemManager.GetItemsByTypes(types, useConsumableSort)
        local result = {}
        for i = 1, #types do
            local items = XItemManager.GetItemsByType(types[i])
            for i2 = 1, #items do
                tableInsert(result, items[i2])
            end
        end

        local bagItems = XDataCenter.ItemManager.ConvertToGridData(result)
        local sortFunc = useConsumableSort and CONSUMABLES_ITEM_SORT_FUNC or BAG_ITEM_SORT_FUNC
        tableSort(bagItems, sortFunc)
        return bagItems
    end

    function XItemManager.GetCanSellItemsByTypes(types, useConsumableSort)
        local result = {}
        for i = 1, #types do
            local items = XItemManager.GetItemsByType(types[i])
            for i2 = 1, #items do
                if XItemManager.IsCanSell(items[i2].Id) then
                    tableInsert(result, items[i2])
                end
            end
        end

        local bagItems = XDataCenter.ItemManager.ConvertToGridData(result)
        local sortFunc = useConsumableSort and CONSUMABLES_ITEM_SORT_FUNC or BAG_ITEM_SORT_FUNC
        tableSort(bagItems, sortFunc)
        return bagItems
    end

    function XItemManager.GetCanConvertItemsByTypes(types)
        local result = {}
        for i = 1, #types do
            local items = XItemManager.GetItemsByType(types[i])
            for i2 = 1, #items do
                if XItemManager.IsCanConvert(items[i2].Id) then
                    tableInsert(result, items[i2])
                end
            end
        end

        local bagItems = XDataCenter.ItemManager.ConvertToGridData(result)
        tableSort(bagItems, BAG_ITEM_SORT_FUNC)
        return bagItems
    end

    --获得出售道具获得的奖励信息
    function XItemManager.GetSellReward(id, count)
        local reward = {}

        if not id then return reward end
        count = count or 1

        local tab = XItemManager.GetItemTemplate(id)
        local templateId = tab.SellForId
        if templateId > 0 then
            reward.TemplateId = templateId
            reward.Count = tab.SellForCount * count
        end

        return reward
    end

    function XItemManager.GetSelectGiftRewardId(id)
        local template = XItemManager.GetItemTemplate(id)
        return template.RewardId
    end

    function XItemManager.GetItemName(id)
        local template = XItemManager.GetItemTemplate(id)
        if not template then
            return nil
        end
        return template.Name
    end

    -- 战斗复活ui调用
    function XItemManager.GetCostItemText(id)
        return CS.XTextManager.GetText("RebootCostText", XItemManager.GetItemName(id))  --"消耗{0}"
    end

    -- 战斗复活ui调用
    function XItemManager.CanRebootBuyItem(id)
        return (id ~= XItemManager.ItemId.Coin and id ~= XItemManager.ItemId.FreeGem and id ~= XItemManager.ItemId.PaidGem)
    end

    function XItemManager.GetItemSuit(id)
        local template = XItemManager.GetItemTemplate(id)
        if not template then
            return nil
        end
        return template.Suit
    end

    function XItemManager.GetDailyActiveness()
        return XItemManager.GetItem(XItemManager.ItemId.DailyActiveness)
    end

    function XItemManager.GetWeeklyActiveness()
        return XItemManager.GetItem(XItemManager.ItemId.WeeklyActiveness)
    end

    function XItemManager.CheckItemTemplateExist(id)
        return id and ItemTemplates[id] and true or false
    end

    function XItemManager.IsCanSell(id)
        if XItemManager.IsTimeLimitBatch(id) then return false end  --时效批次性道具不可出售
        local template = XItemManager.GetItemTemplate(id)
        return template.SellForId > 0 and template.SellForCount > 0
    end

    function XItemManager.IsUseable(id)
        local template = XItemManager.GetItemTemplate(id)
        return template.ItemType == XItemConfigs.ItemType.Gift
    end

    function XItemManager.IsWeaponFashion(id)
        if not XItemManager.CheckItemTemplateExist(id) then return false end
        local template = XItemManager.GetItemTemplate(id)
        return template.ItemType == XItemConfigs.ItemType.WeaponFashion
    end

    function XItemManager.IsWeaponFashionTimeLimit(id)
        if not XItemManager.IsWeaponFashion(id) then
            return true
        end

        local weaponFashionId = XItemManager.GetWeaponFashionId(id)
        if XDataCenter.WeaponFashionManager.CheckFashionTimeLimit(weaponFashionId) then
            return true
        end

        local addTime = XItemManager.GetWeaponFashionAddTime(id)
        if addTime and addTime > 0 then
            return true
        end

        return false
    end

    function XItemManager.GetWeaponFashionId(id)
        if not XItemManager.IsWeaponFashion(id) then return end
        local template = XItemManager.GetItemTemplate(id)
        return template.SubTypeParams[1]
    end

    function XItemManager.GetWeaponFashionAddTime(id)
        if not XItemManager.IsWeaponFashion(id) then return end
        local template = XItemManager.GetItemTemplate(id)
        return template.SubTypeParams[2]
    end

    ---
    --- 储存仓库页签选择
    function XItemManager.SetPageRecordCache(page)
        XItemManager.PageRecordCache = page
    end

    -- 是否溢出（碎片是否可转化）
    function XItemManager.IsCanConvert(id)
        local template = XItemManager.GetItemTemplate(id)
        if template.ItemType ~= XItemConfigs.ItemType.Fragment then
            return false
        end

        --角色已经满级
        local characterId = XCharacterConfigs.GetCharcterIdByFragmentItemId(id)
        local charcter = XDataCenter.CharacterManager.GetCharacter(characterId)
        return charcter and XDataCenter.CharacterManager.IsMaxQuality(charcter)
    end

    -- 背包材料
    function XItemManager.IsBagMaterial(id)
        local template = XItemManager.GetItemTemplate(id)
        local itemType = template.ItemType
        for _, materialType in pairs(XItemConfigs.Materials) do
            if itemType == materialType then return true end
        end
        return false
    end

    -- 时效性道具
    function XItemManager.IsTimeLimit(id)
        local template = XItemManager.GetItemTemplate(id)
        return template.TimelinessType > XItemManager.TimelinessType.Invalid
    end

    -- 时效分批次性道具
    function XItemManager.IsTimeLimitBatch(id)
        local template = XItemManager.GetItemTemplate(id)
        return template.TimelinessType == XItemManager.TimelinessType.Batch
    end

    -- 可选礼包
    function XItemManager.IsSelectGift(id)
        if not XItemManager.IsUseable(id) then return false end
        local template = XItemManager.GetItemTemplate(id)
        return template.GiftType == XItemManager.GiftItemUseType.OptionalReward
    end

    -- 红包
    function XItemManager.IsRedEnvelope(id)
        if not XItemManager.IsUseable(id) then return false end
        local template = XItemManager.GetItemTemplate(id)
        return template.GiftType == XItemManager.GiftItemUseType.RedEnvelope
    end

    -- 检查数据
    function XItemManager.CheckItemCount(item, count)
        return item and item:GetCount() >= count
    end

    function XItemManager.CheckItemCountById(id, count)
        local item = XItemManager.GetItem(id)
        return XItemManager.CheckItemCount(item, count)
    end

    function XItemManager.CheckItemsCount(items)
        for _, item in pairs(items) do
            if not XItemManager.CheckItemCountById(item.Id, item.Count) then
                return false
            end
        end
        return true
    end

    function XItemManager.CheckItemsCountByTimes(items, times)
        for _, item in pairs(items) do
            if not XItemManager.CheckItemCountById(item.Id, item.Count * times) then
                return false
            end
        end
        return true
    end

    function XItemManager.CheckItemType(item, type)
        return item.Template.ItemType == type
    end

    -- 修改数据
    function XItemManager.CreateItem(itemData)
        local template = XItemManager.GetItemTemplate(itemData.Id)
        if template == nil then
            XLog.ErrorTableDataNotFound("XItemManager.CreateItem", "ItemTemplate", " Share/Item/Item.tab", "id", tostring(itemData.Id))
        end

        local item
        if template.RecType == XResetManager.ResetType.NoNeed then
            item = XItem.New(itemData, template)
        else
            item = XRecItem.New(itemData, template)
        end

        Items[item.Id] = item
        return item
    end

    function XItemManager.SetItemCount(id, count, validTime)
        local item = Items[id]
        if not item then
            item = XItemManager.CreateItem(id, count, validTime, 0)
        end
        item:SetCount(count)
        return item
    end

    function XItemManager.SetItemCountDelta(id, delta, validTime)
        local item = Items[id]
        if item then
            XItemManager.SetItemCount(id, item.Count + delta, validTime)
        else
            XItemManager.SetItemCount(id, delta, validTime)
        end
    end

    -- 回收相关
    function XItemManager.GetRecycleLeftTime(id)
        local leftTime = 0

        local item = XItemManager.GetItem(id)
        if not item then return leftTime end

        local startTime
        if item.Template.TimelinessType == XItemManager.TimelinessType.FromConfig then
            startTime = XTime.ParseToTimestamp(item.Template.StartTime)
        elseif item.Template.TimelinessType == XItemManager.TimelinessType.AfterGet then
            startTime = item.CreateTime
        end

        if startTime then
            local endTime = startTime + item.Template.Duration
            leftTime = endTime - XTime.GetServerNowTimestamp()
        end

        return leftTime
    end

    -- 此接口只检测回收类型 XItemManager.TimelinessType.FromConfig/XItemManager.TimelinessType.AfterGet
    -- XItemManager.TimelinessType.Batch类型回收时间列表需手动检查
    function XItemManager.IsTimeOver(id)
        if XItemManager.IsTimeLimit(id) then
            local leftTime = XItemManager.GetRecycleLeftTime(id)
            if leftTime and leftTime <= 0 then
                return true
            end
        end

        return false
    end

    -- 服务端交互
    function XItemManager.PackItemList(items)
        local rpcData = {}
        for id, count in pairs(items) do
            local data = {}
            data.Id = id
            data.Count = count
            tableInsert(rpcData, data)
        end

        return rpcData
    end

    function XItemManager.Use(id, recycleTime, count, callback, rewardIds)
        local req = { Id = id, RecycleTime = recycleTime, Count = count, SelectRewardIds = rewardIds }

        XNetwork.Call(METHOD_NAME.Use, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if callback then
                callback(res.RewardGoodsList)
            end

            if XItemManager.IsTimeLimit(id) then
                XEventManager.DispatchEvent(XEventId.EVENT_TIMELIMIT_ITEM_USE, id)
            end
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_ITEM_USE, id)
        end)
    end

    function XItemManager.Sell(datas, callback)
        XMessagePack.MarkAsTable(datas)
        local req = { SellItems = datas }
        XNetwork.Call(METHOD_NAME.Sell, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            else
                if callback then
                    callback(res.ObtainItems)
                end
            end
        end)
    end

    function XItemManager.BuyAsset(targetId, callback, failCallback, times, consumeId)
        local req = { ItemId = targetId, ConsumeId = consumeId, Times = times }
        XNetwork.Call(METHOD_NAME.BuyAsset, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if failCallback then
                    failCallback()
                end

                return
            end

            -- if res.IsCrit then
            -- end
            if callback then
                callback(targetId, res.Count, res.IsCrit)
            end

            XEventManager.DispatchEvent(XEventId.EVENT_ITEM_BUYASSET, targetId)
        end)
    end

    function XItemManager.MultiplyUse(useList, callback)
        local req = { UseList = useList }

        XNetwork.Call(METHOD_NAME.MultiplyUse, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if callback then
                callback(res.RewardGoodsList)
            end

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_ITEM_MULTIPLY_USE)
        end)
    end

    -- 角色需要的基础属性
    function XItemManager.GetCoinsNum()
        return Items[XItemManager.ItemId.Coin]:GetCount()
    end

    function XItemManager.GetTotalGemsNum()
        return Items[XItemManager.ItemId.FreeGem]:GetCount() + Items[XItemManager.ItemId.PaidGem]:GetCount()
    end

    function XItemManager.GetActionPointsNum()
        return Items[XItemManager.ItemId.ActionPoint]:GetCount()
    end

    function XItemManager.GetMaxActionPoints()
        return XPlayerManager.GetMaxActionPoint(XPlayer.GetLevelOrHonorLevel(), XPlayer.IsHonorLevelOpen())
    end

    function XItemManager.GetActionPointsRefreshResidueSecond()
        return Items[XItemManager.ItemId.ActionPoint]:GetRefreshResidueSecond()
    end

    function XItemManager.GetSkillPointNum()
        return Items[XItemManager.ItemId.SkillPoint]:GetCount()
    end

    function XItemManager.GetBatterys()
        local tmp = {}
        for _, v in pairs(SuppliesItems[XItemManager.SuppliesItemType.Battery]) do
            if Items[v] then
                tableInsert(tmp, Items[v])
            end
        end
        return XItemManager.ConvertToGridData(tmp)
    end

    function XItemManager.GetCoinPackages()
        local result = {}
        for _, v in pairs(SuppliesItems[XItemManager.SuppliesItemType.CoinPackage]) do
            if Items[v] then
                tableInsert(result, Items[v])
            end
        end
        return XItemManager.ConvertToGridData(result)
    end

    function XItemManager.GetCurBatterys()
        local CurBatterys = {}

        local nowTime = XTime.GetServerNowTimestamp()
        for _, v in pairs(XItemManager.GetBatterys()) do
            local item = v.Data
            if item:GetCount() > 0 then
                local recycleBatch = v.RecycleBatch
                if recycleBatch then
                    if recycleBatch.RecycleTime > nowTime then
                        tableInsert(CurBatterys, v)
                    end
                elseif not XItemManager.IsTimeOver(item.Id) then
                    tableInsert(CurBatterys, v)
                end
            end
        end

        tableSort(CurBatterys, function(a, b)
            local aTemplate = a.Data.Template
            local bTemplate = b.Data.Template

            if aTemplate.TimelinessType == bTemplate.TimelinessType then
                if a.RecycleBatch and b.RecycleBatch then
                    if a.RecycleBatch.RecycleTime == b.RecycleBatch.RecycleTime then
                        return aTemplate.Priority > bTemplate.Priority
                    else
                        return a.RecycleBatch.RecycleTime < b.RecycleBatch.RecycleTime
                    end
                else
                    return aTemplate.Priority > bTemplate.Priority
                end
            else
                return aTemplate.TimelinessType > bTemplate.TimelinessType
            end
        end)

        return CurBatterys
    end

    function XItemManager.GetCurrentCoinPackages()
        local result = {}
        local nowTime = XTime.GetServerNowTimestamp()
        for _, value in ipairs(XItemManager.GetCoinPackages()) do
            local item = value.Data
            if item:GetCount() > 0 then
                -- RecycleBatch这个数据是服务器返回的，来源于InitItemRecycle
                local recycleBatch = value.RecycleBatch
                if recycleBatch then
                    if recycleBatch.RecycleTime > nowTime then
                        tableInsert(result, value)
                    end
                elseif not XItemManager.IsTimeOver(item.Id) then
                    tableInsert(result, value)
                end
            end
        end
        tableSort(result, function(a, b)
            local aItemConfig = a.Data.Template
            local bItemConfig = b.Data.Template
            if aItemConfig.Priority == bItemConfig.Priority then
                return aItemConfig.Id > bItemConfig.Id
            else
                return aItemConfig.Priority > bItemConfig.Priority
            end
        end)
        return result
    end

    function XItemManager.GetBatteryMinLeftTime()
        local minLeftTime = 0

        local nowTime = XTime.GetServerNowTimestamp()
        local batterys = XItemManager.GetBatterys()
        for _, v in pairs(batterys) do
            local itemId = v.Data.Id
            if XItemManager.IsTimeLimit(itemId) then
                local recycleBatch = v.RecycleBatch
                if recycleBatch then
                    if recycleBatch.RecycleCount > 0 then
                        local leftTime = recycleBatch.RecycleTime - nowTime
                        leftTime = leftTime > 0 and leftTime or 0
                        if minLeftTime == 0 or minLeftTime > leftTime then
                            minLeftTime = leftTime
                        end
                    end
                else
                    if v.Data:GetCount() > 0 and not XItemManager.IsTimeOver(itemId) then
                        local leftTime = XItemManager.GetRecycleLeftTime(itemId)
                        if leftTime then
                            if minLeftTime == 0 or minLeftTime > leftTime then
                                minLeftTime = leftTime
                            end
                        end
                    end
                end
            end
        end

        return minLeftTime
    end

    function XItemManager.GetTimeLimitItemsMinLeftTime()
        local minLeftTime = 0

        local nowTime = XTime.GetServerNowTimestamp()
        for _, v in pairs(Items) do
            local itemId = v.Id
            if XItemManager.IsTimeLimit(itemId) and v:GetCount() > 0 and XItemManager.IsBagMaterial(itemId) then
                local itemRecycleList = v.ItemRecycleList
                if itemRecycleList then
                    for _, recycleBatch in pairs(itemRecycleList) do
                        if recycleBatch.RecycleCount > 0 then
                            local leftTime = recycleBatch.RecycleTime - nowTime
                            leftTime = leftTime > 0 and leftTime or 0
                            if minLeftTime == 0 or minLeftTime > leftTime then
                                minLeftTime = leftTime
                            end
                        end
                    end
                else
                    if not XItemManager.IsTimeOver(itemId) then
                        local leftTime = XItemManager.GetRecycleLeftTime(itemId)
                        if leftTime then
                            if minLeftTime == 0 or minLeftTime > leftTime then
                                minLeftTime = leftTime
                            end
                        end
                    end
                end
            end
        end

        return minLeftTime
    end

    function XItemManager.GetBagItemListMinLeftTime(bagDatas)
        local minLeftTime = 0

        local nowTime = XTime.GetServerNowTimestamp()
        for _, gridData in pairs(bagDatas) do
            local itemId = gridData.Data.Id
            if XItemManager.IsTimeLimit(itemId) and gridData.Count > 0 then
                local leftTime = gridData.RecycleBatch and gridData.RecycleBatch.RecycleTime - nowTime or XDataCenter.ItemManager.GetRecycleLeftTime(itemId)
                leftTime = leftTime > 0 and leftTime or 0
                if minLeftTime == 0 or minLeftTime > leftTime then
                    minLeftTime = leftTime
                end
            end
        end

        return minLeftTime
    end

    function XItemManager.CheckBatteryIsHave()
        for _, v in pairs(XItemManager.GetBatterys()) do
            if v.Data:GetCount() > 0 then
                return true
            end
        end
        return false
    end

    function XItemManager.CheckCoinPackageIsHave()
        for _, v in pairs(XItemManager.GetCoinPackages()) do
            if v.Data:GetCount() > 0 then
                return true
            end
        end
        return false
    end

    function XItemManager.CheckBatteryIsHaveByIdAndRecycleTime(id, recycleTime)
        for _, v in pairs(XItemManager.GetBatterys()) do
            if v.Data:GetCount() > 0 and v.Data.Id == id then
                if (not recycleTime or v.RecycleBatch.RecycleTime == recycleTime) then
                    return true
                end
            end
        end
        return false
    end

    function XItemManager.DoNotEnoughBuyAsset(useItemId, useItemCount, buyCount, callBack, errorTxt)
        local ownItemCount = XDataCenter.ItemManager.GetCount(useItemId)
        local lackItemCount = useItemCount * buyCount - ownItemCount
        if lackItemCount > 0 then
            local template = XDataCenter.ItemManager.GetBuyAssetTemplate(useItemId, 0, true)
            if template ~= nil then
                if BuyAssetTemplates[useItemId] and #BuyAssetTemplates[useItemId] > 1 then
                    XItemManager.SelectBuyAssetType(useItemId, callBack, nil, 1, true)
                else
                    lackItemCount = mathCeil(lackItemCount / template.GainCount)
                    XItemManager.SelectBuyAssetType(useItemId, callBack, nil, lackItemCount, true)
                end
            else
                XUiManager.TipError(CS.XTextManager.GetText(errorTxt))
            end
            return false
        end
        return true
    end
    function XItemManager.SelectBuyAssetType(useItemId, callBack, challengeCountData, buyAmount, isAutoClose)
        if useItemId == XDataCenter.ItemManager.ItemId.ActionPoint and
        XDataCenter.ItemManager.CheckBatteryIsHave() then
            XLuaUiManager.Open("UiUsePackage", useItemId, callBack, challengeCountData, buyAmount)
        elseif useItemId == XDataCenter.ItemManager.ItemId.Coin
        and XDataCenter.ItemManager.CheckCoinPackageIsHave() then
            XLuaUiManager.Open("UiUseCoinPackage")
        else
            XLuaUiManager.Open("UiBuyAsset", useItemId, callBack, challengeCountData, buyAmount, isAutoClose)
        end
    end
    function XItemManager.NotifyItemDataList(data)
        local list = data.ItemDataList
        if not list then
            return
        end
        for _, tmpData in pairs(list) do
            local id = tmpData.Id

            if not Items[id] then
                Items[id] = XItemManager.CreateItem(tmpData)
            else
                Items[id]:RefreshItem(tmpData)
            end



            if not ItemFirstGetCheckTable[id] then
                ItemFirstGetCheckTable[id] = true
            end
        end

        -- 回收道具时限表
        XItemManager.InitItemRecycle(data.ItemRecycleDict)
    end

    function XItemManager.GetMaxCount(id)
        if id == XItemManager.ItemId.ActionPoint then
            return XItemManager.GetMaxActionPoints()
        else
            local template = XItemManager.GetItemTemplate(id)
            if template then
                if template.MaxCount <= 0 then
                    return XMath.IntMax() -- int.MaxValue，和服务端相同
                else
                    return template.MaxCount
                end
            else
                return -1
            end
        end
    end

    function XItemManager.ConvertToGridData(originDatas)
        local bagDatas = {}
        for i = 1, #originDatas do
            local data = originDatas[i]
            if data.Count > 0 then
                -- 按限时道具到期时间拆分（优先）
                if XItemManager.IsTimeLimitBatch(data.Id) then
                    local list = data.ItemRecycleList
                    if list then
                        for index, info in ipairs(list) do
                            if info.RecycleCount > 0 then
                                local gridData = {}
                                gridData.Data = data
                                gridData.GridIndex = index
                                gridData.RecycleBatch = info
                                gridData.Count = info.RecycleCount
                                tableInsert(bagDatas, gridData)
                            end
                        end
                    end
                    -- 按最大堆叠数拆分
                elseif data.Template.GridCount <= 0 then
                    local gridData = {}
                    gridData.Data = data
                    gridData.GridIndex = 1
                    gridData.Count = data.Count
                    tableInsert(bagDatas, gridData)
                else
                    local gridCount = data.Template.GridCount
                    local gridNum = mathCeil(data.Count / gridCount)
                    for j = 1, gridNum do
                        local gridData = {}
                        gridData.Data = data
                        gridData.GridIndex = j
                        gridData.Count = mathMin(data.Count - (j - 1) * gridCount, gridCount)
                        tableInsert(bagDatas, gridData)
                    end
                end
            end
        end
        return bagDatas
    end
    -------------------------道具事件相关-------------------------
    --==============================--
    --desc: 道具数量变化监听
    --@ids: 道具id或者道具id列表
    --@func: 事件回调
    --@ui: ui节点
    --@obj: UI对象，可为空
    --==============================--
    function XItemManager.AddCountUpdateListener(ids, func, ui, obj)
        if type(ids) == "number" then
            if ids == XItemManager.ItemId.FreeGem or ids == XItemManager.ItemId.PaidGem then
                ids = { XItemManager.ItemId.FreeGem, XItemManager.ItemId.PaidGem }
            else
                ids = { ids }
            end
        end


        for _, id in pairs(ids) do
            if not Items[id] then
                XLog.ErrorTableDataNotFound("XItemManager.AddCountUpdateListener", "Items", "Share/Item/Item.tab", "Id", tostring(id))
                return
            end
        end

        if not ui then
            XLog.Error("XItemManager.AddCountUpdateListener函数参数错误: 参数ui不能为空")
            return
        end

        for _, id in pairs(ids) do
            XEventManager.BindEvent(ui, XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. id, func, obj)
        end
    end

    --==============================--
    --desc: 购买次数变化监听
    --@ids: 道具id或者道具id列表
    --@func: 事件回调
    --@ui: ui节点
    --@obj: UI对象，可为空
    --==============================--
    function XItemManager.AddBuyTimesUpdateListener(ids, func, ui, obj)
        if type(ids) == "number" then
            if ids == XItemManager.ItemId.FreeGem or ids == XItemManager.ItemId.PaidGem then
                ids = { XItemManager.ItemId.FreeGem, XItemManager.ItemId.PaidGem }
            else
                ids = { ids }
            end
        end

        for _, id in pairs(ids) do
            if not Items[id] then
                XLog.ErrorTableDataNotFound("XItemManager.AddBuyTimesUpdateListener", "Items", "Share/Item/Item.tab", "Id", tostring(id))
                return
            end
        end

        if not ui then
            XLog.Error("XItemManager.AddBuyTimesUpdateListener函数参数错误: 参数ui不能为空")
            return
        end

        for _, id in pairs(ids) do
            XEventManager.BindEvent(ui, XEventId.EVENT_ITEM_BUYTIEMS_UPDATE_PREFIX .. id, func, obj)
        end
    end

    function XItemManager.GetCookieKeyStr()
        return string.format("RecycleItemList_%s", XPlayer.Id)
    end

    function XItemManager.IsFastTrading(id)
        local fastTrading = XItemConfigs.GetFastTrading(id)
        if not fastTrading or fastTrading == XItemConfigs.FastTrading.NotFastTrading then
            return false
        end

        return true
    end

    function XItemManager.JudjeCanFastTrading(uiName)
        local FastTradingUiList = XItemConfigs.GetUiBuyAsset()
        for _, v in pairs(FastTradingUiList) do
            if v.UiName == uiName then
                return true
            end
        end

        return false
    end

    function XItemManager.NotifyItemRecycle(data)
        if not next(data.RecycleIds) then return end

        for _, id in pairs(data.RecycleIds) do
            Items[id] = nil
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ITEM_RECYCLE)
    end

    function XItemManager.NotifyBatchItemRecycle(data)
        if not next(data.ItemRecycleList) then return end

        for _, recycleInfo in pairs(data.ItemRecycleList) do
            local id = recycleInfo.Id

            local item = Items[id]
            local itemRecycleList = item and item.ItemRecycleList
            if itemRecycleList then
                for k, v in pairs(itemRecycleList) do
                    if v.RecycleTime == recycleInfo.RecycleTime then
                        tableRemove(itemRecycleList, k)
                        break
                    end
                end

                if not next(itemRecycleList) then
                    Items[id] = nil
                end
            end
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ITEM_RECYCLE)
    end

    function XItemManager.NotifyAllRedEnvelope(data)
        if not next(data.Envelopes) then return end

        RedEnvelopeInfos = {}
        for _, envelope in pairs(data.Envelopes) do
            local activityId = envelope.ActivityId
            RedEnvelopeInfos[activityId] = RedEnvelopeInfos[activityId] or {}

            local npcId = envelope.NpcId
            RedEnvelopeInfos[activityId][npcId] = RedEnvelopeInfos[activityId][npcId] or {}

            local rewards = envelope.Rewards
            for _, reward in pairs(rewards) do
                local itemId = reward.ItemId
                local itemCount = reward.ItemCount
                local oldCount = RedEnvelopeInfos[activityId][npcId][itemId] or 0
                RedEnvelopeInfos[activityId][npcId][itemId] = oldCount + itemCount
            end
        end
    end

    function XItemManager.NotifyRedEnvelopeUse(data)
        local envelopeId = data.EnvelopeId
        if not envelopeId or not XItemManager.IsRedEnvelope(envelopeId) then return end

        local envelopes = data.Envelopes
        if not next(envelopes) then return end

        for _, envelope in pairs(envelopes) do
            local activityId = envelope.ActivityId
            RedEnvelopeInfos[activityId] = RedEnvelopeInfos[activityId] or {}

            local npcId = envelope.NpcId
            RedEnvelopeInfos[activityId][npcId] = RedEnvelopeInfos[activityId][npcId] or {}

            local itemId = envelope.ItemId
            local itemCount = envelope.ItemCount
            local oldCount = RedEnvelopeInfos[activityId][npcId][itemId] or 0
            RedEnvelopeInfos[activityId][npcId][itemId] = oldCount + itemCount
        end

        XLuaUiManager.Open("UiRedEnvelope", envelopeId, envelopes)
    end
    -------------------------道具事件相关-------------------------
    XItemManager.Init()
    return XItemManager
end

XRpc.NotifyItemDataList = function(data)
    XDataCenter.ItemManager.NotifyItemDataList(data)
end

XRpc.NotifyItemRecycle = function(data)
    XDataCenter.ItemManager.NotifyItemRecycle(data)
end

XRpc.NotifyBatchItemRecycle = function(data)
    XDataCenter.ItemManager.NotifyBatchItemRecycle(data)
end

XRpc.NotifyAllRedEnvelope = function(data)
    XDataCenter.ItemManager.NotifyAllRedEnvelope(data)
end

XRpc.NotifyRedEnvelopeUse = function(data)
    XDataCenter.ItemManager.NotifyRedEnvelopeUse(data)
end