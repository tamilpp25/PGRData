---@class XWheelchairManualAgency : XAgency
---@field private _Model XWheelchairManualModel
local XWheelchairManualAgency = XClass(XAgency, "XWheelchairManualAgency")
local ReddotIdMartix = XMath.ToMinInt(math.pow(2, 32)) -- 红点Id的位数计算（与服务端对应，long，前四位记录类型，后四位则是任意类型配置的Id）

-- 页签类型-红点映射表
local TabTypeToRedPointMap = {
    [XEnumConst.WheelchairManual.TabType.StepReward] = XRedPointConditions.Types.CONDITION_WHEELCHAIRMANUAL_PLANREWARD,
    [XEnumConst.WheelchairManual.TabType.StepTask] = XRedPointConditions.Types.CONDITION_WHEELCHAIRMANUAL_PLANTASK,
    [XEnumConst.WheelchairManual.TabType.BPReward] = XRedPointConditions.Types.CONDITION_WHEELCHAIRMANUAL_BP,
    [XEnumConst.WheelchairManual.TabType.Lotto] = XRedPointConditions.Types.CONDITION_WHEELCHAIRMANUAL_LOTTO,
    [XEnumConst.WheelchairManual.TabType.Gift] = XRedPointConditions.Types.CONDITION_WHEELCHAIRMANUAL_GIFT,
    [XEnumConst.WheelchairManual.TabType.Teaching] = XRedPointConditions.Types.CONDITION_WHEELCHAIRMANUAL_TEACHING,
    [XEnumConst.WheelchairManual.TabType.Guide] = XRedPointConditions.Types.CONDITION_WHEELCHAIRMANUAL_GUIDE,
}

function XWheelchairManualAgency:OnInit()

end

function XWheelchairManualAgency:InitRpc()
    XRpc.NotifyWheelchairManualActivity = handler(self, self.OnNotifyWheelchairManualActivity)
    XRpc.NotifyWheelchairManualActivityUpdate = handler(self, self.OnNotifyWheelchairManualGuideActivityUpdate)
end

function XWheelchairManualAgency:InitEvent()

end

--- 判断该活动是否开启
function XWheelchairManualAgency:GetIsOpen(activityId, noTips)
    -- 提审屏蔽
    if XUiManager.IsHideFunc then
        return false
    end
    
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.WheelchairManual, false, noTips) then
        local curActivityId = self._Model:GetActivityId()
        if XTool.IsNumberValid(curActivityId) then
            -- 如果有指定活动Id，则需要判断当前开启的活动id是否与指定的一致
            if XTool.IsNumberValid(activityId) and curActivityId ~= activityId then
                return false, XUiHelper.GetText('CommonActivityNotStart')
            end
            
            -- 判断是否倒计时结束
            local hasLeftTime, leftTime = self._Model:GetLeftTime()
            if not hasLeftTime or leftTime > 0 then
                if not self:CheckIsCurActivityAllRewardGot() then
                    return true
                end
            end
        end
        return false, XUiHelper.GetText('CommonActivityNotStart')
    else
        return false, XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.WheelchairManual)
    end
end



--- 打开轮椅手册自己独立的界面
---@param activityId @判断指定的活动是否开启，传0或nil则不限定活动Id
---@param tabIndex @指定初始选择的页签，传0或nil则不指定
function XWheelchairManualAgency:OpenMainUi(activityId, tabIndex)
    local isOpen, lockdesc = self:GetIsOpen(activityId)

    if isOpen then
        XLuaUiManager.Open('UiWheelchairManualMain', tabIndex)
    else
        XUiManager.TipMsg(lockdesc)
    end
end

--region ActivityData
function XWheelchairManualAgency:GetCurActivityId()
    return self._Model:GetCurActivityId()
end

function XWheelchairManualAgency:GetPlanProcess(planId)
    if XTool.IsNumberValid(planId) then
        local taskIds = self._Model:GetManualPlanRewardTaskIds(planId)

        if not XTool.IsTableEmpty(taskIds) then
            local taskDataList = XDataCenter.TaskManager.GetTaskIdListData(taskIds)

            if not XTool.IsTableEmpty(taskDataList) then
                return XDataCenter.TaskManager.GetTaskProgressByTaskList(taskDataList)
            end
        end
    end

    return 0, 0
end

function XWheelchairManualAgency:GetPlanAnyTaskCanFinish(planId)
    if XTool.IsNumberValid(planId) then
        local taskIds = self._Model:GetManualPlanRewardTaskIds(planId)

        if not XTool.IsTableEmpty(taskIds) then
            for i, v in pairs(taskIds) do
                if XDataCenter.TaskManager.CheckTaskAchieved(v) then
                    return true
                end
            end
        end
    end

    return false
end

function XWheelchairManualAgency:CheckManualAnyRewardCanGet()
    local curLevel = self._Model:GetBpLevel()
    -- 先检查普通手册有没可领取的
    local commonRewardIds = self._Model:GetCurActivityCommanManualRewardCfgIds()
    for i, v in ipairs(commonRewardIds) do
        local rewardCfg = self._Model:GetWheelchairManualBattlePassRewardCfg(v)

        if rewardCfg and rewardCfg.Level <= curLevel then
            if not self._Model:CheckManualRewardIsGet(v) then
                return true
            end
        end
    end
    -- 再检查高级手册
    if self._Model:GetIsSeniorManualUnLock() then
        local seniorRewardIds = self._Model:GetCurActivitySeniorManualRewardCfgIds()
        for i, v in ipairs(seniorRewardIds) do
            local rewardCfg = self._Model:GetWheelchairManualBattlePassRewardCfg(v)

            if rewardCfg and rewardCfg.Level <= curLevel then
                if not self._Model:CheckManualRewardIsGet(v) then
                    return true
                end
            end
        end
    end

    return false
end

-- 判断当前活动引导里是否有任意一个活动是开启显示的
function XWheelchairManualAgency:CheckManualGuideHasAnyActivity()
    local list = self._Model:GetActivityDataList()

    if XTool.IsTableEmpty(list) then
        return false
    end

    local hasAnyActivityOpen = false
    ---@param v XWheelchairManualGuideViewData
    for i, v in pairs(list) do
        if v:IsTimelimitActivity() then
            if v:GetTimelimitActivityIsOpen() then
                hasAnyActivityOpen = true
            end
        else
            if self._Model:CheckWeekIsShow(v:GetMainId()) then
                hasAnyActivityOpen = true
            end
        end
    end
    
    return hasAnyActivityOpen
end

-- 判断当前活动引导入口位置是否已经从主界面左上角转移到版本活动公告内
function XWheelchairManualAgency:CheckCurActivityEntranceChanged()
    -- 倒计时需未结束
    local hasLeftTime, leftTime = self._Model:GetLeftTime()
    if hasLeftTime and leftTime <= 0 then
        return false
    end
    
    -- 阶段奖励和普通手册奖励领取完毕
    if self:CheckAllPlanRewardIsGot() and self:CheckCommonPassportAllGet() then
        return true
    end
    
    return false
end

function XWheelchairManualAgency:CheckAllPlanRewardIsGot()
    local planIds = self._Model:GetCurActivityPlanIds()

    if not XTool.IsTableEmpty(planIds) then
        for i, v in pairs(planIds) do
            if not self._Model:CheckPlanIsGetReward(v) then
                return false
            end
        end        
    end
    
    return true
end

function XWheelchairManualAgency:CheckCommonPassportAllGet()
    -- 获取普通手册的id范围
    local beginIndex, endIndex = self._Model:GetCurActivityCommanManualRewardIdRange()
    
    if not XTool.IsNumberValid(beginIndex) or not XTool.IsNumberValid(endIndex) then
        XLog.Error('普通手册奖励范围存在无效配置，起始索引:'..tostring(beginIndex)..' 末尾索引:'..tostring(endIndex))
        return false
    end
    
    local isAllGot = self._Model:CheckManualRewardIsAllGotInRange(beginIndex, endIndex)
    return isAllGot
end

function XWheelchairManualAgency:CheckSeniorPassportAllGet()
    -- 获取高级手册的id范围
    local beginIndex, endIndex = self._Model:GetCurActivitySeniorManualRewardIdRange()

    if not XTool.IsNumberValid(beginIndex) or not XTool.IsNumberValid(endIndex) then
        XLog.Error('高级手册奖励范围存在无效配置，起始索引:'..tostring(beginIndex)..' 末尾索引:'..tostring(endIndex))
        return false
    end

    local isAllGot = self._Model:CheckManualRewardIsAllGotInRange(beginIndex, endIndex)
    return isAllGot
end

function XWheelchairManualAgency:CheckCurActivityTeachingAllTaskRewardGot()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualActivityCfg(activityId)
        if cfg then
            local taskIds = cfg.TeachTaskIds

            if not XTool.IsTableEmpty(taskIds) then
                local taskList = XDataCenter.TaskManager.GetTaskIdListData(taskIds)

                if not XTool.IsTableEmpty(taskList) then
                    ---@param v XTaskData
                    for i, v in pairs(taskList) do
                        if v.State ~= XDataCenter.TaskManager.TaskState.Finish then
                            return false
                        end
                    end
                end
            end
        end
    end

    return true
end

function XWheelchairManualAgency:CheckCurActivityGiftPackAllSellOut()
    local datas = XDataCenter.PurchaseManager.GetDatasByUiType(self._Model:GetCurActivityPurchaseUiType())
    
    if not XTool.IsTableEmpty(datas) then
        local showPackageIds = self._Model:GetCurActivityShowPurchaseIds()

        if not XTool.IsTableEmpty(showPackageIds) then
            -- 筛选
            local showPackageIdsMap = {}
            for i, v in pairs(showPackageIds) do
                showPackageIdsMap[v] = true
            end

            local newDatas = {}

            for _,v in pairs(datas) do
                if showPackageIdsMap[v.Id] then
                    table.insert(newDatas, v)
                end
            end

            datas = newDatas
        end
        
        
        local nowTime = XTime.GetServerNowTimestamp()
        for _,v in pairs(datas) do
            if v and not v.IsSelloutHide then
                if v.TimeToUnShelve > 0 and v.TimeToUnShelve <= nowTime then--下架了
                    
                elseif v.TimeToShelve > 0 and v.TimeToShelve > nowTime then--待上架中, 即上架后可以买
                    return false
                elseif v.BuyTimes > 0 and v.BuyLimitTimes > 0 and v.BuyTimes >= v.BuyLimitTimes then--买完了
                    
                else        --上架中或锁定状态都表示没卖完，其中锁定状态因为会解锁所以等于后面还能买                                        
                    return false
                end
            end
        end    
        return true
    end
    return true
end

--- 判断是否有免费礼包可领取（没领完且解锁）
function XWheelchairManualAgency:CheckCurActivityAnyFreeGiftPackCanGet()
    local datas = XDataCenter.PurchaseManager.GetDatasByUiType(self._Model:GetCurActivityPurchaseUiType())

    if not XTool.IsTableEmpty(datas) then
        local showPackageIds = self._Model:GetCurActivityShowPurchaseIds()

        if not XTool.IsTableEmpty(showPackageIds) then
            -- 筛选
            local showPackageIdsMap = {}
            for i, v in pairs(showPackageIds) do
                showPackageIdsMap[v] = true
            end

            local newDatas = {}

            for _,v in pairs(datas) do
                if showPackageIdsMap[v.Id] then
                    table.insert(newDatas, v)
                end
            end

            datas = newDatas
        end
        

        local nowTime = XTime.GetServerNowTimestamp()
        local hasFreePackCanBuy = false
        for _,v in pairs(datas) do
            if v and not v.IsSelloutHide then
                local consumeCount = v.ConsumeCount or 0
                --- 必须是免费礼包
                if consumeCount == 0 then
                    if not XDataCenter.PurchaseManager.IsLBLock(v) then
                        if v.TimeToUnShelve > 0 and v.TimeToUnShelve <= nowTime then--下架了

                        elseif v.TimeToShelve > 0 and v.TimeToShelve > nowTime then--待上架中
                            
                        elseif v.BuyTimes > 0 and v.BuyLimitTimes > 0 and v.BuyTimes >= v.BuyLimitTimes then--买完了

                        else        --在上架中,还能买。                                               
                            hasFreePackCanBuy = true
                            break
                        end
                    end
                end
            end
        end
        return hasFreePackCanBuy
    end
    return false
end


function XWheelchairManualAgency:CheckLottoAllDrawGot()
    local lottoGroupData = XDataCenter.LottoManager.GetLottoGroupDataByGroupId(self._Model:GetCurActivityLottoId())

    if not XTool.IsTableEmpty(lottoGroupData) then
        local drawData = lottoGroupData:GetDrawData()
        return drawData:IsLottoCountFinish()
    end
    
    return true
end

---@return boolean, number @是否有倒计时，剩余时间
function XWheelchairManualAgency:GetLeftTime()
    return self._Model:GetLeftTime()
end

function XWheelchairManualAgency:CheckIsCurActivityAllRewardGot()
    -- 所有阶段奖励领取
    if self:CheckAllPlanRewardIsGot() then
        -- 所有BP奖励领取
        if self:CheckCommonPassportAllGet() and self:CheckSeniorPassportAllGet() then
            -- 所有教学任务奖励、礼包、卡池领取
            if self:CheckCurActivityTeachingAllTaskRewardGot() and self:CheckCurActivityGiftPackAllSellOut() and self:CheckLottoAllDrawGot() then
                return true
            end
        end
    end
    return false
end
--endregion

--region ActivityData-Configs
function XWheelchairManualAgency:GetCurActivityTabs()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualActivityShowCfg(activityId)
        if cfg then
            return cfg.TabIds
        end
    end
end

function XWheelchairManualAgency:GetCurActivityTabIdAndPanelUrlByTabType(tabType)
    local tabIds = self:GetCurActivityTabs()

    if not XTool.IsTableEmpty(tabIds) then
        for i, v in pairs(tabIds) do
            local tabCfg = self._Model:GetWheelchairManualTabsCfg(v)
            
            if tabCfg then
                if tabCfg.Type == tabType then
                    return tabCfg.Id, tabCfg.UIPrefabUrl
                end    
            end
        end
    end
end

function XWheelchairManualAgency:GetCurActivityTabIndexByTabType(tabType)
    local tabIds = self:GetCurActivityTabs()

    if not XTool.IsTableEmpty(tabIds) then
        for i, v in pairs(tabIds) do
            local tabCfg = self._Model:GetWheelchairManualTabsCfg(v)

            if tabCfg then
                if tabCfg.Type == tabType then
                    return i
                end
            end
        end
    end
end

function XWheelchairManualAgency:GetCurActivityTabTypeByTabIndex(tabIndex)
    local tabIds = self:GetCurActivityTabs()

    if not XTool.IsTableEmpty(tabIds) then
        local tabId = tabIds[tabIndex]

        if XTool.IsNumberValid(tabId) then
            local tabCfg = self._Model:GetWheelchairManualTabsCfg(tabId)
            if tabCfg then
                return tabCfg.Type
            end
        end
    end
end

function XWheelchairManualAgency:CheckCurActivityHasCountDown()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualActivityCfg(activityId)
        if cfg then
            return XTool.IsNumberValid(cfg.CountDown)
        end
    end
    return false
end

function XWheelchairManualAgency:GetCurActivityLeftTime()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualActivityCfg(activityId)
        if cfg then
            local leftTime = cfg.CountDown
        end
    end
    return 0
end
--endregion

--region Configs
function XWheelchairManualAgency:GetManualTabTypeAndPanelUrl(tabId)
    local cfg = self._Model:GetWheelchairManualTabsCfg(tabId)
    if cfg then
        return cfg.Type, cfg.UIPrefabUrl
    end
end

---ClientConfig
function XWheelchairManualAgency:GetWheelchairManualConfigNum(key, index)
    return self._Model:GetWheelchairManualConfigNum(key, index)
end

function XWheelchairManualAgency:GetWheelchairManualConfigString(key, index)
    return self._Model:GetWheelchairManualConfigString(key, index)
end
--endregion

--region Network
function XWheelchairManualAgency:RequestWheelchairManualPurchase(manualId, cb)
    if not XTool.IsNumberValid(manualId) then
        return
    end
    
    XNetwork.Call("WheelchairManualPurchaseRequest", { ManualId = manualId }, function(res)
        local success = res.Code == XCode.Success

        if not success then
            XUiManager.TipCode(res.Code)
        end

        if cb then
            cb(success)
        end
        
    end)
end

function XWheelchairManualAgency:RequestWheelchairManualGetPlanReward(cb)
    XNetwork.Call("WheelchairManualGetPlanRewardRequest", nil, function(res)
        local success = res.Code == XCode.Success

        if not success then
            XUiManager.TipCode(res.Code)
        end

        if cb then
            cb(success, res.RewardList)
        end
    end)
end

function XWheelchairManualAgency:RequestWheelchairManualGetManualReward(manualId, cb)
    XNetwork.Call("WheelchairManualGetManualRewardRequest", {ManualId = manualId}, function(res) 
        local success = res.Code == XCode.Success

        if not success then
            XUiManager.TipCode(res.Code)
        end

        if cb then
            cb(success, res.RewardList)
        end
    end)
end

--- 请求消除首次未点击蓝点
function XWheelchairManualAgency:RequestWheelchairManualClickBluePoint(type, cb)
    XNetwork.Call("WheelchairManualClickBluePointRequest", {Type = type}, function(res)
        local success = res.Code == XCode.Success

        if not success then
            XUiManager.TipCode(res.Code)
        end

        if cb then
            cb(success)
        end
    end)
end

--- 请求消除新解锁蓝点
function XWheelchairManualAgency:RequestWheelchairManualClickRedPoint(id, cb)
    XNetwork.Call("WheelchairManualClickRedPointRequest", {Id = id}, function(res)
        local success = res.Code == XCode.Success

        if not success then
            XUiManager.TipCode(res.Code)
        end

        if cb then
            cb(success)
        end
    end)
end

--endregion

--region RPC
function XWheelchairManualAgency:OnNotifyWheelchairManualActivity(data)
    self._Model:UpdateManualData(data)

    if not XTool.IsTableEmpty(data) then
        --lotto数据要提前请求
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Lotto, false, true) then
            XDataCenter.LottoManager.GetLottoRewardInfoRequest(nil, true)
        end
        
        XDataCenter.PurchaseManager.GetPurchaseListRequest({ self._Model:GetCurActivityPurchaseUiType() }, function() 
            -- 请求完礼包数据后通过事件触发入口的红点检测
            XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_MAINLEFTENTRANCE_REDDOT)
        end)
    end
end

function XWheelchairManualAgency:OnNotifyWheelchairManualGuideActivityUpdate(data)
    self._Model:UpdateGuideData(data)
end
--endregion

--region RedPoint
function XWheelchairManualAgency:CheckLocalReddotShow(key)
    return self._Model:CheckLocalReddotIsShow(key)
end

function XWheelchairManualAgency:SetLocalReddotAsOld(key)
    self._Model:SetLocalReddotAsOld(key)
end

function XWheelchairManualAgency:CheckSubActivityIsNew(key)
    return self._Model:CheckBulePointIsNew(key)
end

---@return boolean @是否将红点点掉（如果之前已经点掉了，或者失败，则返回false）
function XWheelchairManualAgency:SetSubActivityIsOld(key)
    if self._Model:SetBulePointAsOld(key) then
        self:RequestWheelchairManualClickBluePoint(key)
        return true
    end
    return false
end

function XWheelchairManualAgency:CheckNewUnlockReddotIsShow(key)
    return self._Model:CheckUnlockBulePointIsNew(key)
end

---@return boolean @是否将红点点掉（如果之前已经点掉了，或者失败，则返回false）
function XWheelchairManualAgency:SetNewUnlockReddotIsOld(key)
    if self._Model:SetUnlockBulePointAsOld(key) then
        self:RequestWheelchairManualClickRedPoint(key)
        return true
    end
    return false
end

function XWheelchairManualAgency:CheckPlanCanGetReward(planId)
    -- 进度显示
    local passCount, allCount = self:GetPlanProcess(planId)
    local isProcessValid = XTool.IsNumberValid(allCount)
    -- 奖励领取情况
    local isFinish = true
    local isAchieved = false
    if isProcessValid then
        isFinish = passCount == allCount
        isAchieved = self._Model:CheckPlanIsGetReward(planId)
    end

    return isFinish and not isAchieved
end

function XWheelchairManualAgency:CheckCurActivityAnyPlanCanGetReward()
    local planIds = self._Model:GetCurActivityPlanIds()

    if not XTool.IsTableEmpty(planIds) then
        for i, v in pairs(planIds) do
            if self:CheckPlanCanGetReward(v) then
                return true
            end
        end
    end

    return false
end

function XWheelchairManualAgency:CheckCurActivityAnyPlanCanGetTaskReward()
    local planIds = self._Model:GetCurActivityPlanIds()

    if not XTool.IsTableEmpty(planIds) then
        for i, v in pairs(planIds) do
            if self:GetPlanAnyTaskCanFinish(v) then
                return true
            end
        end
    end

    return false
end

function XWheelchairManualAgency:CheckCurActivityTeachingAnyTaskCanReward()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualActivityCfg(activityId)
        if cfg then
            local taskIds = cfg.TeachTaskIds

            if not XTool.IsTableEmpty(taskIds) then
                local taskList = XDataCenter.TaskManager.GetTaskIdListData(taskIds)

                if not XTool.IsTableEmpty(taskList) then
                    ---@param v XTaskData
                    for i, v in pairs(taskList) do
                        if v.State == XDataCenter.TaskManager.TaskState.Achieved then
                            return true
                        end
                    end
                end
            end
        end
    end
    
    return false
end

--- 检查是否有关卡有新解锁蓝点
function XWheelchairManualAgency:CheckCurActivityTeachingAnyStageNewUnlock()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualActivityCfg(activityId)
        if cfg then
            local typeVal = XEnumConst.WheelchairManual.TabType.Teaching * ReddotIdMartix

            if XMVCA.XFuben:CheckStageIsUnlock(cfg.TeachConnectivityStageId) and self:CheckNewUnlockReddotIsShow(typeVal + cfg.TeachConnectivityStageId) then
                return true
            end

            for i, v in pairs(cfg.TeachCommonStageIds) do
                if XMVCA.XFuben:CheckStageIsUnlock(v) and self:CheckNewUnlockReddotIsShow(typeVal + v) then
                    return true
                end
            end
        end
    end

    return false
end

--- 检查是否有活动有新解锁蓝点
function XWheelchairManualAgency:CheckCurActivityAnyGuideNewUnlock()
    local list = self._Model:GetActivityDataList()

    if XTool.IsTableEmpty(list) then
        return false
    end

    ---@param v XWheelchairManualGuideViewData
    for i, v in pairs(list) do
        if v:IsTimelimitActivity() then
            if v:GetTimelimitActivityIsOpen() then
                local skipId = v:GetSkipId()
                if XTool.IsNumberValid(skipId) and XFunctionManager.IsCanSkip(skipId) then
                    local id = v:GetId()
                    local reddotId = XEnumConst.WheelchairManual.TabType.Guide * ReddotIdMartix + id
                    if self:CheckNewUnlockReddotIsShow(reddotId) then
                        return true
                    end
                end
            end
        else
            if self._Model:CheckWeekIsShow(v:GetMainId()) then
                local skipId = v:GetSkipId()
                if XTool.IsNumberValid(skipId) and XFunctionManager.IsCanSkip(skipId) then
                    local id = v:GetMainId()
                    local reddotId = XEnumConst.WheelchairManual.TabType.Guide * ReddotIdMartix + id
                    if self:CheckNewUnlockReddotIsShow(reddotId) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

--- 判断是否有新解锁的礼包
function XWheelchairManualAgency:CheckCurActivityAnyNewUnlockGiftPack()
    local datas = XDataCenter.PurchaseManager.GetDatasByUiType(self._Model:GetCurActivityPurchaseUiType())

    if not XTool.IsTableEmpty(datas) then
        local showPackageIds = self._Model:GetCurActivityShowPurchaseIds()

        if not XTool.IsTableEmpty(showPackageIds) then
            -- 筛选
            local showPackageIdsMap = {}
            for i, v in pairs(showPackageIds) do
                showPackageIdsMap[v] = true
            end

            local newDatas = {}

            for _,v in pairs(datas) do
                if showPackageIdsMap[v.Id] then
                    table.insert(newDatas, v)
                end
            end

            datas = newDatas
        end

        local nowTime = XTime.GetServerNowTimestamp()
        for _,v in pairs(datas) do
            if v and not v.IsSelloutHide then
                if not XDataCenter.PurchaseManager.IsLBLock(v) then
                    if v.TimeToUnShelve > 0 and v.TimeToUnShelve <= nowTime then--下架了

                    elseif v.TimeToShelve > 0 and v.TimeToShelve > nowTime then--待上架中

                    elseif v.BuyTimes > 0 and v.BuyLimitTimes > 0 and v.BuyTimes >= v.BuyLimitTimes then--买完了

                    else        --在上架中,还能买。                                               
                        local id = XEnumConst.WheelchairManual.TabType.Gift * ReddotIdMartix + v.Id
                        if self:CheckNewUnlockReddotIsShow(id) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

function XWheelchairManualAgency:GetRedPointConditionTypeByTabType(tabType)
    return TabTypeToRedPointMap[tabType]
end
--endregion

return XWheelchairManualAgency