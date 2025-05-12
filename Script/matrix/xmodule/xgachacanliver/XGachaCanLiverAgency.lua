--- 可肝卡池，利用了Gacha的数据，但有自己独立的逻辑
---@class XGachaCanLiverAgency : XAgency
---@field private _Model XGachaCanLiverModel
local XGachaCanLiverAgency = XClass(XAgency, "XGachaCanLiverAgency")
function XGachaCanLiverAgency:OnInit()

end

function XGachaCanLiverAgency:InitRpc()
    XRpc.NotifyGachaCanLiverData = handler(self, self.OnNotifyGachaCanLiverData)
end

function XGachaCanLiverAgency:InitEvent()

end

---@param activityId @判断指定的活动是否开启，传0或nil则不限定活动Id
function XGachaCanLiverAgency:GetIsOpen(activityId)
    -- 功能开启、有活动数据、未满足关闭条件
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ActivityDrawCard, true, true) then
        local curActivityId = self._Model:GetCurActivityId()
        local hasActivityData = XTool.IsNumberValid(curActivityId)

        if XTool.IsNumberValid(activityId) then
            hasActivityData = hasActivityData and activityId == curActivityId
        end

        if hasActivityData then
            if not self:CheckActivityCanOver() then
                -- 至少需要常驻卡池开启才能进去
                local residentGachaId = self._Model:GetCurActivityResidentGachaId()

                if XTool.IsNumberValid(residentGachaId) then
                    if XDataCenter.GachaManager.CheckGachaIsOpenById(residentGachaId) then
                        return true
                    end
                else
                    XLog.Error('活动常驻GachaId无效：'..tostring(residentGachaId)..' 当前活动Id:'..tostring(curActivityId))
                end
               
            end
        end

        return false, XUiHelper.GetText('CommonActivityNotStart')
    else
        return false, XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.ActivityDrawCard)
    end
    return true
end

--- 打开独立的界面
---@param activityId @判断指定的活动是否开启，传0或nil则不限定活动Id
function XGachaCanLiverAgency:OpenMainUi(activityId)
    local isOpen, lockdesc = self:GetIsOpen(activityId)

    if isOpen then
        -- 默认进入常驻卡池
        local gachaId = self._Model:GetCurActivityResidentGachaId()
        local isTimelimit = false
        -- 如果常驻卡池抽完了，且有开启的限时卡池，则改成前往最新的限时卡池
        if self:CheckGachaIsSellOutRare(gachaId) and not self:CheckTimeLimitDrawIsOutTime() then
            local timelimitGachaId = self._Model:GetCurActivityLatestTimelimitGachaId()

            if XTool.IsNumberValid(timelimitGachaId) then
                gachaId = timelimitGachaId
                isTimelimit = true
            end
        end
        
        XDataCenter.GachaManager.GetGachaRewardInfoRequest(gachaId, function()
            XLuaUiManager.Open('UiGachaCanLiverMain', gachaId, isTimelimit)
        end)
    else
        XUiManager.TipMsg(lockdesc)
    end
end

--region ActivityData -- 与服务端数据直接关联的读写逻辑

--- 检查当前活动限时卡池因过了开放时间而关闭
function XGachaCanLiverAgency:CheckTimeLimitDrawIsOutTime()
    local curActivityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(curActivityId) then
        local gachaIds = self._Model:GetCurActivityTimeLimitGachaIds()
        if not XTool.IsTableEmpty(gachaIds) then
            for i, v in pairs(gachaIds) do
                if not XDataCenter.GachaManager.CheckGachaIsOutTimeById(v, true) then
                    return false
                end
            end
        end
    end
    
    return true
end

--- 检查限时卡池是否解锁（同时满足在时间内及其他条件）
---@param drawId @如果指定了Id，则只判断对应卡池，否则当期所有卡池都判断
---@param any @表示全判断下，各卡池的结果叠加是‘或’还是‘且’
function XGachaCanLiverAgency:CheckTimeLimitDrawIsUnlock(drawId, any)
    if XTool.IsNumberValid(drawId) then
        -- 指定Id时仅判断一个卡池
        return self:_CheckTimeLimitDrawIsUnlock(drawId)
    else
        -- 否则判断所有卡池
        local drawIds = self._Model:GetCurActivityTimeLimitGachaIds()

        if not XTool.IsTableEmpty(drawIds) then
            if any then
                for i, id in pairs(drawIds) do
                    local isUnlock, desc = self:_CheckTimeLimitDrawIsUnlock(id)

                    if isUnlock then
                        return isUnlock, desc
                    end
                end
                return false
            else
                for i, id in pairs(drawIds) do
                    local isUnlock, desc = self:_CheckTimeLimitDrawIsUnlock(id)

                    if not isUnlock then
                        return isUnlock, desc
                    end
                end
                return true
            end
            
        else
            XLog.Error('检查限时卡池是否解锁时，id列表配置为空，当前活动Id：'..tostring(self:GetCurActivityId()))
        end
    end
end

--- 检查指定限时卡池是否解锁（同时满足在时间内及其他条件）
---@param drawId @如果指定了Id，则只判断对应卡池，否则当期所有卡池都判断
function XGachaCanLiverAgency:_CheckTimeLimitDrawIsUnlock(drawId)
    if XTool.IsNumberValid(drawId) then
        -- 先检查是否在活动
        local isOpen = XDataCenter.GachaManager.CheckGachaIsOpenById(drawId, false)

        if isOpen then
            -- 检查condition是否满足
            local gachaIndex = self._Model:GetCurActivityTimeLimitGachaIdIndex(drawId)

            if XTool.IsNumberValid(gachaIndex) then
                local conditionId = self._Model:GetCurActivityTimeLimitGachaConditionByIndex(gachaIndex)

                if XTool.IsNumberValid(conditionId) then
                    return XConditionManager.CheckCondition(conditionId)
                else
                    return true
                end
            end
        else
            return false, XUiHelper.GetText('CommonActivityNotStart')
        end
    else
        XLog.Error('检查限时卡池是否解锁时，指定的Id无效：'..tostring(drawId))
    end
end

--- 检查卡池是否都抽完（指抽完特殊奖励）
---@param drawId @未指定Id时全判断（包括常驻和限时）
---@return boolean @指定卡池抽完/所有卡池都抽完
function XGachaCanLiverAgency:CheckDrawIsComplete(drawId)
    return XDataCenter.GachaManager.GetGachaIsSoldOutRare(drawId)
end

--- 检查当前活动是否可结束（尚有活动数据，但满足关闭条件）
--- 关闭条件：所有卡池抽完、代币兑换完
function XGachaCanLiverAgency:CheckActivityCanOver()
    return self._Model:GetCurActivityIsClose()
end

--- 检查当前活动是否有可领取奖励的任务
function XGachaCanLiverAgency:CheckAnyTaskCanFinish()
    if self:CheckTaskFinishAchieveLimit() then
        return false
    end
    
    -- 常驻任务
    local taskIds = self._Model:GetCurActivityTaskIds()

    if not XTool.IsTableEmpty(taskIds) then
        for i, v in pairs(taskIds) do
            if XDataCenter.TaskManager.CheckTaskAchieved(v) then
                return true
            end
        end
    end
    
    -- 限时任务
    local taskTimeLimitGroupIds = self._Model:GetCurActivityTaskTimeLimitGroupIds()
    if not XTool.IsTableEmpty(taskTimeLimitGroupIds) then
        for i, groupId in pairs(taskTimeLimitGroupIds) do
            if XDataCenter.TaskManager.CheckTimeLimitTaskAnyCanFinishByGroupId(groupId) then
                return true
            end
        end
    end
    
    return false
end

--- 检查任务领取是否达到上限
function XGachaCanLiverAgency:CheckTaskFinishAchieveLimit()
    local freeCoinLimit = self._Model:GetCurActivityFreeItemGainUpLimit() or 0
    local hasGotFreeCount = self._Model:GetCurActivityFreeItemIdGainTimes() or 0
    local leftCanGetCount = freeCoinLimit - hasGotFreeCount

    return leftCanGetCount <= 0
end

function XGachaCanLiverAgency:GetCurActivityResidentGachaId()
    return self._Model:GetCurActivityResidentGachaId()
end

function XGachaCanLiverAgency:CheckGachaIsSellOutRare(gachaId)
    return self._Model:CheckGachaIsSellOutRare(gachaId)
end
--endregion

--region ActivityData-Config -- 基于服务端数据的配置表读取逻辑
function XGachaCanLiverAgency:GetCurActivityId()
    return self._Model:GetCurActivityId()
end

function XGachaCanLiverAgency:GetCurActivityMainPrefabAddress()
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        ---@type XTableGachaCanLiverShow
        local cfg = self._Model:GetGachaCanLiverShowCfgById(activityId)
        
        return cfg.MainPrefabAddress
    else
        XLog.Error('尝试获取GachaCanLiver卡池活动的抽卡界面预制体路径，但没有有效的开启活动，Id：'..tostring(activityId))
    end
end
--endregion

--region Network

--endregion

--region RPC
function XGachaCanLiverAgency:OnNotifyGachaCanLiverData(data)
    self._Model:RefreshActivityData(data)
    
    -- 有活动数据时，需要提前请求商店数据
    if not XTool.IsTableEmpty(data) then
        --因为需要商店数据进行蓝点判定，当活动开启时就请求获取商店数据
        --仅当玩家商店权限开放和需要蓝点判定时才主动提前请求数据
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon,false,true) then
            local shopIds = self._Model:GetCurActivityShopIds(true)

            if not XTool.IsTableEmpty(shopIds) then
                XShopManager.GetShopInfoList(shopIds, function()
                    self:InitShopGoodsReddotCache(shopIds)
                end, XShopManager.ShopType.Activity, true)
            end
        end
    end
end
--endregion

--region Reddot

--- 获取唯一指向该卡池活动的红点key
function XGachaCanLiverAgency:GetReddotKey(key)
    return self._Model:GetActivityUniqueKey()..tostring(key)
end

--- 通过检查指定key在客户端的缓存，无缓存则表明需要显示红点
function XGachaCanLiverAgency:CheckReddotShowByKey(key)
    local fullKey = self:GetReddotKey(key)
    
    return not XSaveTool.GetData(fullKey) and true or false
end

--- 将指定key缓存在客户端中，表明该红点已被点掉
function XGachaCanLiverAgency:SetReddotHideByKey(key)
    local fullKey = self:GetReddotKey(key)

    if not XSaveTool.GetData(fullKey) then
        XSaveTool.SaveData(fullKey, true)
    end
end

--- 初始化商品红点缓存：有解锁条件且未解锁的记录缓存
function XGachaCanLiverAgency:InitShopGoodsReddotCache(shopIds)
    if not XTool.IsTableEmpty(shopIds) then
        for i, shopId in pairs(shopIds) do
            local goodsList = XShopManager.GetShopGoodsList(shopId, true, true)

            if not XTool.IsTableEmpty(goodsList) then
                for i, goods in pairs(goodsList) do
                    if not XTool.IsTableEmpty(goods.ConditionIds) then
                        local isSatisfyConditions = true
                        for i, conditionId in pairs(goods.ConditionIds) do
                            if not XConditionManager.CheckCondition(conditionId) then
                                isSatisfyConditions = false
                                break
                            end
                        end

                        local reddotKey = self:GetReddotKey(goods.Id)
                        if not isSatisfyConditions and not XSaveTool.GetData(reddotKey) then
                            XSaveTool.SaveData(reddotKey, true)
                        end
                    end
                end
            end
        end
    end
end

function XGachaCanLiverAgency:CheckShopGoodsReddot()
    local shopIds = self._Model:GetCurActivityShopIds(true)
    
    if not XTool.IsTableEmpty(shopIds) then
        for i, shopId in pairs(shopIds) do
            local goodsList = XShopManager.GetShopGoodsList(shopId, true, true)

            if not XTool.IsTableEmpty(goodsList) then
                for i, goods in pairs(goodsList) do
                    if not XTool.IsTableEmpty(goods.ConditionIds) then
                        local isSatisfyConditions = true
                        for i, conditionId in pairs(goods.ConditionIds) do
                            if not XConditionManager.CheckCondition(conditionId) then
                                isSatisfyConditions = false
                                break
                            end
                        end

                        local reddotKey = self:GetReddotKey(goods.Id)
                        --- 一个商品解锁了，但有记录它的缓存，说明是新解锁，需要红点提示
                        if isSatisfyConditions and XSaveTool.GetData(reddotKey) then
                            return true
                        end
                    end
                end
            end
        end
    end
    
    return false
end

function XGachaCanLiverAgency:ClearShopGoodsReddot()
    local shopIds = self._Model:GetCurActivityShopIds(true)

    if not XTool.IsTableEmpty(shopIds) then
        for i, shopId in pairs(shopIds) do
            local goodsList = XShopManager.GetShopGoodsList(shopId, true, true)

            if not XTool.IsTableEmpty(goodsList) then
                for i, goods in pairs(goodsList) do
                    if not XTool.IsTableEmpty(goods.ConditionIds) then
                        local isSatisfyConditions = true
                        for i, conditionId in pairs(goods.ConditionIds) do
                            if not XConditionManager.CheckCondition(conditionId) then
                                isSatisfyConditions = false
                                break
                            end
                        end

                        local reddotKey = self:GetReddotKey(goods.Id)
                        --- 一个商品解锁了，但有记录它的缓存，则清除它的缓存
                        if isSatisfyConditions and XSaveTool.GetData(reddotKey) then
                            XSaveTool.RemoveData(reddotKey)
                        end
                    end
                end
            end
        end
    end

    return false
end

--- 判断是否有代币
function XGachaCanLiverAgency:CheckHasItemCoin()
    local itemId = self._Model:GetCurActivityCoinItemId()

    if XTool.IsNumberValid(itemId) then
        return XDataCenter.ItemManager.GetCount(itemId) > 0
    end
    
    return false
end
--endregion

return XGachaCanLiverAgency