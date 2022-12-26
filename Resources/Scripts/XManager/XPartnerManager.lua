local XPartner = require("XEntity/XPartner/XPartner")

XPartnerManagerCreator = function()
    local XPartnerManager = {}
    local PartnerEntityDic = {}
    local CSTextManagerGetText = CS.XTextManager.GetText
    local tableInsert = table.insert
    local PartnerNameMaxLength = CS.XGame.Config:GetInt("PartnerNameMaxLength")
    local PartnerLockCount = 0
    local PartnerLockCountMax = 2
    local SYNC_PARTNERLOCK_SECOND = 1
    local LastSyncPartnerLockTime = 0
    local PartnerCarrierIdDic = {}
    local PartnerUnLockStoryList = {}
    local PartnerMaxCount = CS.XGame.Config:GetInt("PartnerMaxCount")
    local PartnerAbilityConvert = CS.XGame.Config:GetFloat("PartnerAbilityConvert")
    local PartnerDecomposeExpItemRebate = CS.XGame.Config:GetString("PartnerDecomposeExpItemRebate")
    local PartnerDecomposeLevelBreakRebate = CS.XGame.Config:GetFloat("PartnerDecomposeLevelBreakRebate")
    local PartnerDecomposeEvolutionRebate = CS.XGame.Config:GetFloat("PartnerDecomposeEvolutionRebate")
    local PartnerDecomposeSkillRebate = CS.XGame.Config:GetFloat("PartnerDecomposeSkillRebate")

    local METHOD_NAME = {
        PartnerComposeRequest = "PartnerComposeRequest",--伙伴合成请求
        PartnerCarryRequest = "PartnerCarryRequest",--伙伴携带请求
        PartnerBreakAwayRequest = "PartnerBreakAwayRequest",--伙伴解除携带请求
        PartnerChangeNameRequest = "PartnerChangeNameRequest",--伙伴改名请求
        PartnerUpdateLockRequest = "PartnerUpdateLockRequest",--伙伴锁定请求
        PartnerLevelUpRequest = "PartnerLevelUpRequest",--伙伴升级请求
        PartnerBreakThroughRequest = "PartnerBreakThroughRequest",--伙伴突破请求
        PartnerStarActivateRequest = "PartnerStarActivateRequest",--伙伴升星（融合）请求
        PartnerEvolutionRequest = "PartnerEvolutionRequest",--伙伴进化请求
        PartnerSkillUpRequest = "PartnerSkillUpRequest",--伙伴技能升级请求
        PartnerSkillWearRequest = "PartnerSkillWearRequest",--伙伴技能穿戴请求
        PartnerDecomposeRequest = "PartnerDecomposeRequest",--伙伴分解请求
    }

    function XPartnerManager.Init()

    end

    function XPartnerManager.GetPartnerOverviewDataList(SelectId, partnerType, IsShowStack)--取得伙伴总览队列
        local overviewDataList = {}
        local stackCount = {}
        local overviewIndex = 1
        local indexMemo = {}
        for _,entity in pairs(PartnerEntityDic or {}) do
            local IsSameType = true
            if partnerType then
                IsSameType = entity:GetCarryCharacterType() == partnerType or entity:GetCarryCharacterType() == XPartnerConfigs.PartnerType.All
            end
            
            if IsSameType then
                if entity:GetIsByOneself() and IsShowStack then

                    -- 将可以堆叠的伙伴全部放入一个虚拟的伙伴中，如果堆叠伙伴中有在列表中被选中的那么将此伙伴ID赋给虚拟的堆叠伙伴
                    if not stackCount[entity:GetTemplateId()] then
                        stackCount[entity:GetTemplateId()] = 1
                        overviewDataList[overviewIndex] = entity
                        indexMemo[entity:GetTemplateId()] = overviewIndex
                        overviewIndex = overviewIndex + 1
                    end

                    local tmpData = {}
                    tmpData.StackCount = stackCount[entity:GetTemplateId()]
                    stackCount[entity:GetTemplateId()] = stackCount[entity:GetTemplateId()] + 1
                    
                    if SelectId and SelectId == entity:GetId() then
                        overviewDataList[indexMemo[entity:GetTemplateId()]] = entity
                    end
                    
                    overviewDataList[indexMemo[entity:GetTemplateId()]]:UpdateData(tmpData)
                else
                    overviewDataList[overviewIndex] = entity
                    overviewIndex = overviewIndex + 1
                end
            end    
        end
        
        return overviewDataList
    end

    function XPartnerManager.GetPartnerComposeDataList()--取得伙伴合成队列
        local composeDataList = {}
        local canComposeIdList = {}
        local canComposeCount = 0
        local tmpId = 1
        local templateList = XPartnerConfigs.GetPartnerTemplateCfg()
        for _,template in pairs(templateList or {}) do
            local chipCurCount = XDataCenter.ItemManager.GetCount(template.ChipItemId)
            local chipNeedCount = template.ChipNeedCount
            local count = math.floor(chipCurCount / chipNeedCount)

            if count > 0 then
                table.insert(canComposeIdList, template.Id)
                canComposeCount = canComposeCount + count
            end

            local entity = XPartner.New(tmpId, template.Id, false)
            tmpId = tmpId + 1
            entity:UpdateData({ChipBaseCount = chipCurCount})
            table.insert(composeDataList,entity)
        end

        return composeDataList, canComposeIdList, canComposeCount
    end

    function XPartnerManager.GetPartnerQualityUpDataList(partnerId)--取得进化狗粮列表
        local qualityUpDataList = {}
        local curPartnerEntity = PartnerEntityDic[partnerId]
        for _,entity in pairs(PartnerEntityDic or {}) do
            local IsCanEat = not entity:GetIsCarry() and
            not entity:GetIsLock() and
            partnerId ~= entity:GetId() and
            curPartnerEntity:GetTemplateId() == entity:GetTemplateId()

            if IsCanEat then
                table.insert(qualityUpDataList,entity)
            end
        end

        return qualityUpDataList
    end
    
    function XPartnerManager.GetPartnerDecomposionList()--取得分解列表
        local decomposionDataList = {}
        for _,entity in pairs(PartnerEntityDic or {}) do
            local IsCanDecomposion = not entity:GetIsCarry() and not entity:GetIsLock()
            if IsCanDecomposion then
                table.insert(decomposionDataList,entity)
            end
        end
        return decomposionDataList
    end
    
    function XPartnerManager.GetCarryPartnerIdByCarrierId(carrierId)--根据装备者ID获取装备的宠物ID
        return PartnerCarrierIdDic[carrierId]
    end
    
    function XPartnerManager.GetCarryPartnerEntityByCarrierId(carrierId)--根据装备者ID获取装备的宠物
        local carryPartnerId = PartnerCarrierIdDic[carrierId]
        return carryPartnerId and PartnerEntityDic[carryPartnerId]
    end
    
    function XPartnerManager.GetCarryPartnerAbilityByCarrierId(carrierId)--根据装备者ID获取装备的宠物战力
        local carryPartner = XPartnerManager.GetCarryPartnerEntityByCarrierId(carrierId)
        local partnerAbility = carryPartner and carryPartner:GetAbility() or 0
        return XMath.ToMinInt(partnerAbility * PartnerAbilityConvert)
    end
    
    function XPartnerManager.GetCarryPartnerAbility(entity)--根据宠物的数据实体获取宠物战力
        local partnerAbility = entity and entity:GetAbility() or 0
        return XMath.ToMinInt(partnerAbility * PartnerAbilityConvert)
    end
    
    function XPartnerManager.IsPartnerListEmpty()
        return (not PartnerEntityDic or not next(PartnerEntityDic)) and true or false
    end

    function XPartnerManager.GetPartnerEntityById(partnerId)
        return PartnerEntityDic[partnerId]
    end
    
    function XPartnerManager.CreatePartnerEntityByPartnerData(partnerData, IsPreview)
        if partnerData and partnerData.Id and partnerData.TemplateId then
            local entity = XPartner.New(partnerData.Id, partnerData.TemplateId, true, IsPreview)
            entity:UpdateData(partnerData)
            return entity
        end
        return nil
    end
    
    function XPartnerManager.GoPartnerCarry(characterId, IsCanSkipProperty)--跳转至伙伴装备界面
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Partner) then
            return
        end
        
        if XPartnerManager.IsPartnerListEmpty() then
            XUiManager.TipText("PartnerListIsEmpty")
            if IsCanSkipProperty then
                XLuaUiManager.Open("UiPartnerMain")
            end
            return
        end
        XLuaUiManager.Open("UiPartnerCarry", characterId, IsCanSkipProperty)
    end

    function XPartnerManager.UpdatePartnerEntity(dataList)
        for _,data in pairs(dataList or {}) do
            if not PartnerEntityDic[data.Id] then
                PartnerEntityDic[data.Id] = XPartner.New(data.Id, data.TemplateId, true)
            end
            PartnerEntityDic[data.Id]:UpdateData(data)
        end
        
        XPartnerManager.UpdateCarrierIdDic()
    end

    function XPartnerManager.UpdateCarrierIdDic()
        PartnerCarrierIdDic = {}
        for _,entity in pairs (PartnerEntityDic or {}) do
            if entity:GetIsCarry() then
                PartnerCarrierIdDic[entity:GetCharacterId()] = entity:GetId()
            end
        end
    end
    
    function XPartnerManager.RemovePartnerEntity(ids)
        for _,id in pairs(ids or {}) do
            if PartnerEntityDic[id] then
                PartnerEntityDic[id] = nil
            end
        end
    end

    function XPartnerManager.ConstructPartnerAttrMap(attrs, isIncludeZero, remainDigitTwo)
        local attrMap = {}
        for _, attrIndex in pairs(XPartnerConfigs.AttrSortType or {}) do
            local value = attrs and attrs[attrIndex]
            --默认保留两位小数
            if not remainDigitTwo then
                value = value and FixToInt(value)
            else
                value = value and tonumber(string.format("%0.2f", FixToDouble(value)))
            end

            if isIncludeZero or value and value > 0 then
                tableInsert(attrMap, {
                        AttrIndex = attrIndex,
                        Name = XAttribManager.GetAttribNameByIndex(attrIndex),
                        Value = value or 0,
                    })
            end
        end
        return attrMap
    end
    
    function XPartnerManager.UpdateAllPartnerStory()--更新所有宠物的故事列表
        local PartnerUnLockStoryList = XDataCenter.ArchiveManager.GetPartnerSettingUnLockDic()
        for _,entity in pairs(PartnerEntityDic or {}) do
            entity:UpdateStoryEntity(PartnerUnLockStoryList)
        end
    end
    
    function XPartnerManager.UpdatePartnerStoryByEntity(entity)--更新某个宠物的故事列表
        local PartnerUnLockStoryList = XDataCenter.ArchiveManager.GetPartnerSettingUnLockDic()
        entity:UpdateStoryEntity(PartnerUnLockStoryList)
    end
    
    function XPartnerManager.UpdatePartnerNameById(partnerdId, name)--更新某个宠物的名字
        if not partnerdId then return end 
        local entity = XPartnerManager.GetPartnerEntityById(partnerdId)
        if entity then
            local tmpData = {
                Name = name or ""
            }
            entity:UpdateData(tmpData)
        end
    end

    function XPartnerManager.GetCanEatItemIds()
        local itemIds = {}

        local items = XDataCenter.ItemManager.GetPartnerExpItems()
        for _, item in pairs(items or {}) do
            tableInsert(itemIds, item.Id)
        end

        return itemIds
    end

    function XPartnerManager.GetEatItemsCostMoney(itemIdDic)
        local costMoney = 0

        for itemId, count in pairs(itemIdDic or {}) do
            costMoney = costMoney + XDataCenter.ItemManager.GetItemsAddEquipCost(itemId, count)
        end

        return costMoney
    end
    
    function XPartnerManager.GetPartnerCountByTemplateId(id)
        local count = 0
        for _,entity in pairs(PartnerEntityDic or {}) do
            if entity:GetTemplateId() == id then
                count = count + 1
            end
        end
        return count
    end

    
    function XPartnerManager.GetPartnerCount()
        local count = 0
        for _,_ in pairs(PartnerEntityDic or {}) do
            count = count + 1
        end
        return count
    end
    
    function XPartnerManager.GetMaxPartnerCount()
        return PartnerMaxCount
    end
    
    function XPartnerManager.GetExpItemList()
        local expItemIdStrs = string.Split(PartnerDecomposeExpItemRebate,"|")
        local expItemList = {}
        for _,itemIdStr in pairs(expItemIdStrs) do
            if itemIdStr and type(itemIdStr) == "string" and not string.IsNilOrEmpty(itemIdStr) then
                table.insert(expItemList, XDataCenter.ItemManager.GetItemTemplate(tonumber(itemIdStr)))
            end
        end

        table.sort(expItemList, function (a, b)
                return a.GetExp() > b.GetExp()
            end)
        
        return expItemList
    end
    
    local SetDecomposeBackItem = function(itemDic, partner)
        local decomposeBackItems = partner:GetDecomposeBackItem()
        for _,item in pairs(decomposeBackItems) do
            itemDic[item.Id] = itemDic[item.Id] or {}
            itemDic[item.Id].Count = itemDic[item.Id].Count or 0
            itemDic[item.Id].Count = itemDic[item.Id].Count + item.Count
        end
    end
    
    local SetBreakthroughBackItem = function(itemDic, partner)
        local curBreakThrough = partner:GetBreakthrough()
        local breakThroughExp = 0
        for breakThrough = 1, curBreakThrough do
            local levelLimit = partner:GetBreakthroughLevelLimit(breakThrough - 1)
            breakThroughExp = breakThroughExp + partner:GetLevelUpInfoAllExp(breakThrough - 1, levelLimit)

            local breakthroughItems = partner:GetBreakthroughCostItem(breakThrough - 1)
            for _,item in pairs(breakthroughItems) do
                itemDic[item.Id] = itemDic[item.Id] or {}
                itemDic[item.Id].Count = itemDic[item.Id].Count or 0
                itemDic[item.Id].Count = itemDic[item.Id].Count + item.Count * PartnerDecomposeLevelBreakRebate
            end
        end
        -----------------------经验值道具--------------------------
        local exp = (partner:GetExp() + partner:GetLevelUpInfoAllExp() + breakThroughExp)
        local ratedExp = exp * PartnerDecomposeLevelBreakRebate
        local expItemList = XPartnerManager.GetExpItemList()
        local IsHasSurplus = true
        while(IsHasSurplus)do
            IsHasSurplus = false
            for _,item in pairs(expItemList) do
                if ratedExp - item.GetExp() >= 0 then
                    itemDic[item.Id] = itemDic[item.Id] or {}
                    itemDic[item.Id].Count = itemDic[item.Id].Count or 0
                    itemDic[item.Id].Count = itemDic[item.Id].Count + 1
                    local coin = XDataCenter.ItemManager.ItemId.Coin
                    itemDic[coin] = itemDic[coin] or {}
                    itemDic[coin].Count = itemDic[coin].Count or 0
                    itemDic[coin].Count = itemDic[coin].Count + item.GetCost()
                    ratedExp = ratedExp - item.GetExp()
                    IsHasSurplus = true
                    break
                end
            end
        end
    end
    
    local SetQualityUpBackItem = function(itemDic, partner)
        local initQuality = partner:GetInitQuality()
        local curQuality = partner:GetQuality()
        local partnerClipId = partner:GetChipItemId()

        for quality = initQuality + 1, curQuality do
            local qualityUpItems = partner:GetQualityEvolutionCostItem(quality - 1)
            for _,item in pairs(qualityUpItems) do
                itemDic[item.Id] = itemDic[item.Id] or {}
                itemDic[item.Id].Count = itemDic[item.Id].Count or 0
                itemDic[item.Id].Count = itemDic[item.Id].Count + item.Count * PartnerDecomposeEvolutionRebate
            end
        end

        if partner:GetStarSchedule() > 0 then
            itemDic[partnerClipId] = itemDic[partnerClipId] or {}
            itemDic[partnerClipId].Count = itemDic[partnerClipId].Count or 0
            itemDic[partnerClipId].Count = itemDic[partnerClipId].Count + partner:GetStarSchedule() * PartnerDecomposeEvolutionRebate 
        end
    end
    
    local SetSkillLevelUpBackItem = function(itemDic, partner)
        local miniSkillLevel = partner:GetMiniSkillLevelLimit()
        local curSkillLevel = partner:GetTotalSkillLevel()

        for skillLevel = miniSkillLevel + 1, curSkillLevel do
            local skillUpItems = partner:GetSkillUpgradeCostItem()
            for _,item in pairs(skillUpItems) do
                itemDic[item.Id] = itemDic[item.Id] or {}
                itemDic[item.Id].Count = itemDic[item.Id].Count or 0
                itemDic[item.Id].Count = itemDic[item.Id].Count + item.Count * PartnerDecomposeSkillRebate
            end
        end
    end
    
    function XPartnerManager.GetPartnerDecomposeRewards(partnerList)
        local itemInfoList = {}
        local itemDic = {}
        XTool.LoopCollection(partnerList, function(partner)
                ---------------------分解返还--------------------------
                SetDecomposeBackItem(itemDic, partner)
                --------------------突破返还--------------------------
                SetBreakthroughBackItem(itemDic, partner)
                -----------------------进化返还--------------------------
                SetQualityUpBackItem(itemDic, partner)
                -------------------------技能升级返还--------------------------
                SetSkillLevelUpBackItem(itemDic, partner)
            end)

        for id, item in pairs(itemDic) do
            item.Count = math.floor(item.Count)
            local reward = XRewardManager.CreateRewardGoods(id, item.Count)
            tableInsert(itemInfoList, reward)
        end
        itemInfoList = XRewardManager.SortRewardGoodsList(itemInfoList)

        return itemInfoList
    end
    
    function XPartnerManager.CheckIsPartnerByTemplateId(id)
        return XArrangeConfigs.GetType(id) == XArrangeConfigs.Types.Partner
    end
    
    function XPartnerManager.CheckMaxCount(count)
        if count and count > 0 then
            return XPartnerManager.GetPartnerCount() + count > PartnerMaxCount
        else
            return XPartnerManager.GetPartnerCount() >= PartnerMaxCount
        end
    end

    function XPartnerManager.CheckPartnerCount(count)
        if XPartnerManager.CheckMaxCount(count) then
            XUiManager.TipMsg(CSXTextManagerGetText("PartnerIsMaxHint"), XUiManager.UiTipType.Tip)
            return false
        end
        return true
    end
    
    function XPartnerManager.TipDialog(cancelCb, confirmCb, textKey, textParam)
        local desc = ""
        if textParam then
            desc = CSTextManagerGetText(textKey, textParam)
        else
            desc = CSTextManagerGetText(textKey)
        end
        CsXUiManager.Instance:Open("UiDialog", CSTextManagerGetText("TipTitle"), desc,
            XUiManager.DialogType.Normal, cancelCb, confirmCb)
    end
-----------------------------------------------------------------红点----------------------------------------------------   
    
    function XPartnerManager.CheckComposeRedOfAll()
        local templateCfg = XPartnerConfigs.GetPartnerTemplateCfg()
        local IsShowRed = false
        for _,template in pairs(templateCfg or {}) do
            if XPartnerManager.CheckComposeRedByTemplateId(template.Id) then
                IsShowRed = true
                break
            end
        end
        return IsShowRed
    end
    
    function XPartnerManager.CheckComposeRedByTemplateId(templateId)
        local templateCfg = XPartnerConfigs.GetPartnerTemplateCfg()
        local template = templateCfg[templateId]
        local chipCurCount = XDataCenter.ItemManager.GetCount(template.ChipItemId)
        local chipNeedCount = template.ChipNeedCount
        local count = math.floor(chipCurCount / chipNeedCount)
        return count > 0
    end
    
    function XPartnerManager.MarkedNewSkillRed(partnerId)
        if XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "PartnerSkill", partnerId)) then
            XSaveTool.RemoveData(string.format("%d%s%d", XPlayer.Id, "PartnerSkill", partnerId))
        end
    end
    
    function XPartnerManager.CheckNewSkillRedOfAll()
        local IsShowRed = false
        for _,entity in pairs(PartnerEntityDic or {}) do
            if XPartnerManager.CheckNewSkillRedByPartnerId(entity:GetId()) then
                IsShowRed = true
               break 
            end
        end
        return IsShowRed
    end

    function XPartnerManager.CheckNewSkillRedByPartnerId(partnerId)
        if XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "PartnerSkill", partnerId)) then
            return true
        end
        return false
    end

    function XPartnerManager.SetNewSkillRedByPartnerId(partnerId)
        if not XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "PartnerSkill", partnerId)) then
            XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "PartnerSkill", partnerId),true)
        end
    end
    
    function XPartnerManager.GetCheckEventIds()
        local templateCfg = XPartnerConfigs.GetPartnerTemplateCfg()
        local eventIds = {}
        for _,cfg in pairs(templateCfg or {}) do
            tableInsert(eventIds, string.format("%s%d", XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX, cfg.ChipItemId))
        end
        return eventIds
    end
-----------------------------------------------------------------服务器通讯----------------------------------------------------
    
    function XPartnerManager.PartnerComposeRequest(templateIds, isOneKey)--伙伴合成请求
        XNetwork.Call(METHOD_NAME.PartnerComposeRequest, {TemplateIds = templateIds, IsOneKey = isOneKey}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XLuaUiManager.Open("UiPartnerPopupTip", CSTextManagerGetText("PartnerComposeFinish"))
                --XUiManager.TipText("PartnerComposeFinish")
            end)
    end

    function XPartnerManager.PartnerCarryRequest(characterId, partnerId, errorCb)--伙伴携带请求
        local partnerEntity = PartnerEntityDic[partnerId]

        XNetwork.Call(METHOD_NAME.PartnerCarryRequest, {CharacterId = characterId, PartnerId = partnerId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    if errorCb then errorCb() end
                    return
                end
            end)
    end

    function XPartnerManager.PartnerBreakAwayRequest(partnerId, errorCb)--伙伴脱离请求
        local partnerEntity = PartnerEntityDic[partnerId]

        XNetwork.Call(METHOD_NAME.PartnerBreakAwayRequest, {PartnerId = partnerId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    if errorCb then errorCb() end
                    return
                end
            end)
    end

    function XPartnerManager.PartnerChangeNameRequest(partnerId, name, cb)--伙伴改名请求
        local partnerEntity = PartnerEntityDic[partnerId]

        XNetwork.Call(METHOD_NAME.PartnerChangeNameRequest, {PartnerId = partnerId, Name = name}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                local tmpData = {
                    Name = name
                }
                partnerEntity:UpdateData(tmpData)
                if cb then cb() end
            end)
    end

    function XPartnerManager.PartnerUpdateLockRequest(partnerId, isLock, cb)--伙伴更新锁定状态请求
        local partnerEntity = PartnerEntityDic[partnerId]
        local now = XTime.GetServerNowTimestamp()
        local syscTime = LastSyncPartnerLockTime

        if not PartnerLockCount or PartnerLockCount >= PartnerLockCountMax then
            if syscTime and now - syscTime < SYNC_PARTNERLOCK_SECOND then
                XUiManager.TipText("PartnerSyncPartnerError")
                PartnerLockCount = nil
                return
            end
        end

        if not PartnerLockCount then
            PartnerLockCount = 0
        end

        XNetwork.Call(METHOD_NAME.PartnerUpdateLockRequest, {PartnerId = partnerId, IsLock = isLock}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                local tmpData = {
                    IsLock = isLock
                }
                partnerEntity:UpdateData(tmpData)
                LastSyncPartnerLockTime = XTime.GetServerNowTimestamp()
                PartnerLockCount = PartnerLockCount + 1
                if cb then cb() end
            end)
    end

    function XPartnerManager.PartnerLevelUpRequest(partnerId, useItems, cb)--伙伴升级请求
        local partnerEntity = PartnerEntityDic[partnerId]
        if partnerEntity:GetIsLevelMax() then
            XUiManager.TipText("PartnerLevelUpMaxLevel")
            return
        end

        local costEmpty = true
        local costMoney = 0

        if useItems and next(useItems) then
            costEmpty = nil
            costMoney = costMoney + XPartnerManager.GetEatItemsCostMoney(useItems)
            XMessagePack.MarkAsTable(useItems)
        end

        if costEmpty then
            XUiManager.TipText("PartnerLevelUpItemEmpty")
            return
        end

        if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(XDataCenter.ItemManager.ItemId.Coin, costMoney, 1, function()
                    XPartnerManager.PartnerLevelUpRequest(partnerId, useItems, cb)
                end, "PartnerCoinNotEnough") then
            return
        end

        XNetwork.Call(METHOD_NAME.PartnerLevelUpRequest, {PartnerId = partnerId, UseItems = useItems}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                local tmpData = {
                    Level = res.Level,
                    Exp = res.Exp
                }
                partnerEntity:UpdateData(tmpData)
                XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_ABLITYCHANGE)
                if cb then cb() end
            end)
    end

    function XPartnerManager.PartnerBreakThroughRequest(partnerId, cb)--伙伴突破请求
        local partnerEntity = PartnerEntityDic[partnerId]

        if partnerEntity:GetIsMaxBreakthrough() then
            XUiManager.TipText("PartnerBreakMax")
            return
        end

        if not partnerEntity:GetIsLevelMax() then
            XUiManager.TipText("PartnerBreakMinLevel")
            return
        end

        local consumeItems = partnerEntity:GetBreakthroughItem()
        if not XDataCenter.ItemManager.CheckItemsCount(consumeItems) then
            XUiManager.TipText("PartnerItemNotEnough")
            return
        end

        local money = partnerEntity:GetBreakthroughMoney()
        if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(money.Id,
                money.Count,
                1,
                function()
                    XPartnerManager.PartnerBreakThroughRequest(partnerId, cb)
                end,
                "PartnerCoinNotEnough") then
            return
        end

        XNetwork.Call(METHOD_NAME.PartnerBreakThroughRequest, {PartnerId = partnerId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                local tmpData = {
                    BreakThrough = res.BreakTimes,
                    Level = 1,
                    Exp = 0,
                }
                partnerEntity:UpdateData(tmpData)
                XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_ABLITYCHANGE)
                if cb then cb() end
            end)
    end

    function XPartnerManager.PartnerStarActivateRequest(partnerId, costPartnerIds, cb)--伙伴星数进度激活请求
        local partnerEntity = PartnerEntityDic[partnerId]

        if not costPartnerIds or not next(costPartnerIds) then
            XUiManager.TipText("PartnerQualityUpEmpty")
            return
        end

        if partnerEntity:GetCanUpQuality() then
            XUiManager.TipText("PartnerAllStarActivate")
            return
        end
        
        XNetwork.Call(METHOD_NAME.PartnerStarActivateRequest, {PartnerId = partnerId, CostPartnerIds = costPartnerIds}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                local tmpData = {
                    StarSchedule = res.StarSchedule
                }
                partnerEntity:UpdateData(tmpData)

                local backItemList = res.RewardGoodsList
                if backItemList then
                    XUiManager.OpenUiObtain(backItemList, CSTextManagerGetText("PartnerBackItem"))
                end

                XPartnerManager.RemovePartnerEntity(costPartnerIds)
                XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_ABLITYCHANGE)
                if cb then cb() end
            end)
    end

    function XPartnerManager.PartnerEvolutionRequest(partnerId, cb)--伙伴进化请求
        local partnerEntity = PartnerEntityDic[partnerId]

        if partnerEntity:GetIsMaxQuality() then
            XUiManager.TipText("PartnerQualityMax")
            return
        end

        if not partnerEntity:GetCanUpQuality() then
            XUiManager.TipText("PartnerClipNotEnough")
            return
        end

        local money = partnerEntity:GetQualityEvolutionMoney()
        if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(money.Id,
                money.Count,
                1,
                function()
                    XPartnerManager.PartnerEvolutionRequest(partnerId, cb)
                end,
                "PartnerCoinNotEnough") then
            return
        end

        XNetwork.Call(METHOD_NAME.PartnerEvolutionRequest, {PartnerId = partnerId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                local tmpData = {
                    Quality = res.Quality
                }
                partnerEntity:UpdateData(tmpData)
                
                local backItemList = res.RewardGoodsList
                if backItemList then
                    XUiManager.OpenUiObtain(backItemList, CSTextManagerGetText("PartnerBackItem"))
                end
                if cb then cb() end
            end)
    end

    function XPartnerManager.PartnerSkillUpRequest(partnerId, count, cb, errorCb)--伙伴技能升级请求
        local partnerEntity = PartnerEntityDic[partnerId]

        if partnerEntity:GetIsTotalSkillLevelMax() then
            XUiManager.TipText("PartnerAllSkillLevelMax")
            if errorCb then errorCb() end
            return
        end
        
        if partnerEntity:GetSkillLevelGap() < count then
            XUiManager.TipText("PartnerSkillLevelOverFlow")
            if errorCb then errorCb() end
            return
        end

        local consumeItems = partnerEntity:GetSkillUpgradeItem()
        if not XDataCenter.ItemManager.CheckItemsCountByTimes(consumeItems, count) then
            XUiManager.TipText("PartnerItemNotEnough")
            if errorCb then errorCb() end
            return
        end

        local money = partnerEntity:GetSkillUpgradeMoney()
        if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(money.Id,
                money.Count * count,
                1,
                function()
                    XPartnerManager.PartnerSkillUpRequest(partnerId, cb, errorCb)
                end,
                "PartnerCoinNotEnough") then
            if errorCb then errorCb() end
            return
        end
        
        XNetwork.Call(METHOD_NAME.PartnerSkillUpRequest, {PartnerId = partnerId, Times = count}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    if errorCb then errorCb() end
                    return
                end
                if cb then cb(res.SkillUpInfo) end
            end)
    end

    function XPartnerManager.PartnerSkillWearRequest(partnerId, skillDic, skillType, errorCb)--伙伴技能穿戴请求
        local partnerEntity = PartnerEntityDic[partnerId]
        
        local skillIdToWear = {}
        for key,value in pairs(skillDic or {}) do
            table.insert(skillIdToWear,{SkillId = key, IsWear = value})
        end
        
        XNetwork.Call(METHOD_NAME.PartnerSkillWearRequest, {PartnerId = partnerId, SkillIdToWear = skillIdToWear, SkillType = skillType}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    if errorCb then errorCb() end
                    return
                end
            end)
    end
    
    function XPartnerManager.PartnerDecomposeRequest(partnerIds, cb)--伙伴分解请求
        XNetwork.Call(METHOD_NAME.PartnerDecomposeRequest, {PartnerIds = partnerIds}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                local backItemList = res.RewardGoodsList
                if backItemList then
                    XUiManager.OpenUiObtain(backItemList, CSTextManagerGetText("PartnerBackItem"))
                end

                XPartnerManager.RemovePartnerEntity(partnerIds)
                XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_DECOMPOSE)
                if cb then cb() end
            end)
    end

    XPartnerManager.Init()
    return XPartnerManager
end

XRpc.NotifyPartnerDataList = function(data)
    XDataCenter.PartnerManager.UpdatePartnerEntity(data.PartnerDataList)
    XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_DATAUPDATE)
    XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_ABLITYCHANGE)
    
    for _,type in pairs(data.OperateTypes or {}) do
        if type == XPartnerConfigs.DataSyncType.Obtain then
            local entityList = {}
            for _,partnerdata in pairs(data.PartnerDataList or {}) do
                local entity = XDataCenter.PartnerManager.GetPartnerEntityById(partnerdata.Id)
                if entity then
                    table.insert(entityList, entity)
                    XDataCenter.PartnerManager.UpdatePartnerStoryByEntity(entity)
                end
            end
            XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_OBTAIN, entityList)
        elseif type == XPartnerConfigs.DataSyncType.Skill then
            XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_SKILLCHANGE)
        elseif type == XPartnerConfigs.DataSyncType.Carry then
            XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_CARRY)
        elseif type == XPartnerConfigs.DataSyncType.UnlockSkillGroup then
            for _,partnerdata in pairs(data.PartnerDataList or {}) do
                XDataCenter.PartnerManager.SetNewSkillRedByPartnerId(partnerdata.Id)
            end
            XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_SKILLUNLOCK)
        elseif type == XPartnerConfigs.DataSyncType.QualityUp then
            XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_QUALITYUP)
        end
    end
end

XRpc.NotifyPartnerName = function(data)
    XDataCenter.PartnerManager.UpdatePartnerNameById(data.PartnerId, data.PartnerName)
end