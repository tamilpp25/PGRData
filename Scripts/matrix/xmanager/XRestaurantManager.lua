--- 厨房管理器
---@return XRestaurantManager 厨房管理器
--------------------------
XRestaurantManagerCreator = function()
    local XRestaurant
    local XRestaurantRoom
    ---@class XRestaurantManager 厨房管理器
    local XRestaurantManager = { }
    ---@type XRestaurant
    local RestaurantViewModel
    ---@type XRestaurantRoom
    local RestaurantRoom
    ---@type XQueue 播报队列
    local RestaurantBroadcast = XQueue.New()
    local IsBroadcastPlaying = false
    ---是否在玩法活动界面内
    local InActivityView = false
    ---还未触发的食谱任务Id
    local RecipeTaskMap
    
    local IsRequestExitRoom = false
    
    local InitOnlyOnce = false
    
    local IsPlayOpenAnimation = false
    
    ---@type XNetworkCallCd
    local EnterRoomRequest
    ---@type XNetworkCallCd
    local AssignWorkRequest
    ---@type XNetworkCallCd
    local AccelerateRequest
    ---@type XNetworkCallCd
    local CollectCashierRequest
    ---@type XNetworkCallCd
    local LevelUpStaffRequest
    ---@type XNetworkCallCd
    local OfflineBillRequest
    ---@type XNetworkCallCd
    local ExitRoomRequest
    ---@type XNetworkCallCd
    local AllStaffStopRequest
    ---@type XNetworkCallCd
    local SwitchSectionBuffRequest
    
    --region   ------------------local function start-------------------
    local function PlayBroadcast(txtTip) 
        IsBroadcastPlaying = true
        XLuaUiManager.Open("UiRestaurantRadio", txtTip)
    end
    
    local function GetCookiesKey(key) 
        local activityId = XRestaurantManager.IsOpen() and RestaurantViewModel:GetProperty("_Id") or 0
        return string.format("Restaurant_%sth_UID_%s_%s", activityId, XPlayer.Id, key)
    end
    
    local function GetEnterAreaType()
        if not XRestaurantManager.IsOpen() then
            return XRestaurantConfigs.AreaType.SaleArea
        end
        if XRestaurantConfigs.CheckGuideAllFinish() then
            return XRestaurantConfigs.AreaType.SaleArea
        end 
        return XRestaurantConfigs.AreaType.FoodArea
    end
    
    --记录食谱任务中进度为0的任务Id
    local function UpdateRecipeTaskMap()
        if not RestaurantViewModel then
            return
        end
        RecipeTaskMap = {}
        
        local taskTimeLimitId = RestaurantViewModel:GetRecipeTaskId()
        local taskCfg = XTaskConfig.GetTimeLimitTaskCfg(taskTimeLimitId)
        for _, taskId in ipairs(taskCfg.TaskId) do
            local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
            if taskData then
                local isZero = true
                local schedule = taskData.Schedule or {}

                for _, pair in pairs(schedule) do
                    if pair.Value > 0 then
                        isZero = false
                        break
                    end
                end

                if isZero then
                    RecipeTaskMap[taskId] = taskId
                end
            end
        end
    end
    
    --检查任务是否为从 0->1
    local function CheckUnlockHideRecipe(taskId)
        if not RecipeTaskMap[taskId] then
            return false
        end
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
        if not taskData then
            return false
        end
        local biggerThanOne = true
        for _, pair in pairs(taskData.Schedule) do
            if pair.Value <= 0 then
                biggerThanOne = false
                break
            end
        end
        return biggerThanOne
    end
    
    local function InitRequire()
        if InitOnlyOnce then
            return
        end
        -- require 行为树
        CS.XLuaEngine.Import("XRestaurant")

        XRestaurant = require("XModule/XRestaurant/XRestaurant")
        XRestaurantRoom = require("XModule/XRestaurant/XGameObject/XRestaurantRoom")
        
        --带Cd的请求
        local XNetworkCallCd = require("XCommon/XNetworkCallCd")
        
        --进入餐厅
        EnterRoomRequest        = XNetworkCallCd.New("RestaurantEnterRequest", 1)
        --分配工作
        AssignWorkRequest       = XNetworkCallCd.New("RestaurantDispatchWorkRequest", 1)
        --加速
        AccelerateRequest       = XNetworkCallCd.New("RestaurantAccelerateRequest", 1)
        --收取收银台
        CollectCashierRequest   = XNetworkCallCd.New("RestaurantCashierRewardRequest", 5)
        --员工升级
        LevelUpStaffRequest     = XNetworkCallCd.New("RestaurantCharacterUpgradeRequest", 1)
        --离线收益
        OfflineBillRequest      = XNetworkCallCd.New("RestaurantOfflineBillRewardRequest", 1)
        --退出餐厅
        ExitRoomRequest         = XNetworkCallCd.New("RestaurantExitRequest", 1)
        --一键罢工
        AllStaffStopRequest     = XNetworkCallCd.New("RestaurantAllStopRequest", 1)
        --切换区域Buff
        SwitchSectionBuffRequest = XNetworkCallCd.New("RestaurantSwitchSectionBuffRequest", 1)

        InitOnlyOnce = true
    end
    --endregion------------------local function finish------------------
    
    function XRestaurantManager.IsOpen()
        if not RestaurantViewModel then
            return false
        end
        return RestaurantViewModel:IsOpen()
    end
    
    function XRestaurantManager:GetProgressTips()
        local level = XRestaurantManager.IsOpen() and RestaurantViewModel:GetProperty("_Level") or 1
        return string.format(XRestaurantConfigs.GetClientConfig("RestaurantActivityProgressText", 1), "LV" .. level)
    end
    
    function XRestaurantManager:ExOverrideBaseMethod()
        return {
            ExGetRunningTimeStr = function(proxy)
                if not RestaurantViewModel then 
                    return ""
                end
                local time = XTime.GetServerNowTimestamp()
                local isInBusiness = RestaurantViewModel and RestaurantViewModel:IsInBusiness() or false
                local endTime = isInBusiness and RestaurantViewModel:GetBusinessEndTime() or RestaurantViewModel:GetShopEndTime()
                local str = XRestaurantConfigs:GetRunningTimeStr(isInBusiness and 1 or 2)
                return string.format(str, XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY))
            end,
            ExGetProgressTip = function(proxy)
                return XRestaurantManager:GetProgressTips()
            end,
        }
    end
    
    function XRestaurantManager.EnterUiMain(shieldRequest)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Restaurant) then
            return
        end
        if not XRestaurantManager.IsOpen() then
            XUiManager.TipText("CommonActivityNotStart")
            return
        end
        
        local OnResponse = function()
            --设置全局光
            XUiHelper.SetSceneType(CS.XSceneType.Dormitory)
            --更新食谱任务
            UpdateRecipeTaskMap()
            --初始化创建数据
            RestaurantRoom = RestaurantRoom or XRestaurantRoom.New()
            XLuaUiManager.Open("UiLoading", LoadingType.Restaurant)
            --设置区域
            RestaurantRoom:SetAreaType(GetEnterAreaType())
            -- 释放无用资源
            CS.UnityEngine.Resources.UnloadUnusedAssets()
            -- 手动执行GC
            LuaGC()
            -- 在load之前记录值
            local isLevelUp = RestaurantViewModel:GetProperty("_IsLevelUp")
            RestaurantRoom:Load(function()
                if IsPlayOpenAnimation then
                    XLuaUiManager.Open("UiRestaurantOpening", isLevelUp)
                else
                    XRestaurantManager.OpenMainView(isLevelUp, false, true)
                end
                
                InActivityView = true
                RestaurantViewModel:StartSimulation()
                RestaurantViewModel:UpdateLuaMemory()
            end)
        end
        local isInBusiness = RestaurantViewModel:IsInBusiness()
        --如果营业结束，就不发协议
        shieldRequest = shieldRequest or not isInBusiness
        if shieldRequest then
            OnResponse()
        else
            XRestaurantManager.RequestEnterRoom(OnResponse)
        end
    end
    
    function XRestaurantManager.OnLeave(shieldRequest)
        if RestaurantViewModel then
            RestaurantViewModel:StopSimulation()
        end
        
        XRestaurantManager.StopBusiness()
        
        if RestaurantRoom then
            RestaurantRoom:Release()
        end
        
        XRestaurantConfigs.Clear()
        XRestaurantManager.Clear()
        
        local uiList = { "UiRestaurantCommon", "UiRestaurantMain" }
        --避免界面非正常关闭时，资源未被销毁
        for _, uiName in ipairs(uiList) do
            if XLuaUiManager.IsUiLoad(uiName) then
                XLuaUiManager.Remove(uiName)
            end
        end
    end
    
    --开始营业
    function XRestaurantManager.StartBusiness()
        if not RestaurantViewModel or not RestaurantRoom then
            return
        end
        RestaurantRoom:StartBusiness()
    end
    
    --结束营业
    function XRestaurantManager.StopBusiness()
        if RestaurantRoom then
            RestaurantRoom:StopBusiness()
        end
        InActivityView = false
    end
    
    --- 获取视图数据
    ---@return XRestaurant
    --------------------------
    function XRestaurantManager.GetViewModel()
        return RestaurantViewModel
    end
    
    --- 获取场景
    ---@return XRestaurantRoom
    --------------------------
    function XRestaurantManager.GetRoom()
        return RestaurantRoom
    end
    
    --- 正在营业的订单NPCId
    ---@return number
    --------------------------
    function XRestaurantManager.GetStandingOrderNpcId()
        if not XRestaurantManager.IsOpen() then
            return
        end
        local orderInfo = RestaurantViewModel:GetTodayOrderInfo()
        if not orderInfo then
            return
        end
        if orderInfo:IsFinish() then
            return
        end
        return XRestaurantConfigs.GetOrderNpcId(orderInfo:GetId())
    end
    
    --- 触发的食谱解锁，弹出提示
    --------------------------
    function XRestaurantManager.PopRecipeTaskTip()
        if not RestaurantViewModel then
            return
        end
        local recipeId = RestaurantViewModel:GetRecipeTaskId()
        local taskCfg = XTaskConfig.GetTimeLimitTaskCfg(recipeId)
        local taskIds = taskCfg.TaskId or {}
        local list = {}
        
        for _, taskId in ipairs(taskIds) do
            if CheckUnlockHideRecipe(taskId) then
                table.insert(list, taskId)
            end
        end

        if not XTool.IsTableEmpty(list) then
            local baseTxt = XRestaurantConfigs.GetRecipeTaskTip()
            for _, taskId in ipairs(list) do
                local template = XTaskConfig.GetTaskCfgById(taskId)
                local txt = string.format(baseTxt, template.Title)
                XUiManager.TipMsgEnqueue(txt)
                RecipeTaskMap[taskId] = nil
            end
        end
    end
    
    function XRestaurantManager.PlayNextBroadcast()
        --if not InActivityView then
        --    return
        --end
        --if not RestaurantBroadcast or RestaurantBroadcast:Count() <= 0 then
        --    return
        --end
        --local txtTip = RestaurantBroadcast:Dequeue()
        --PlayBroadcast(txtTip)
    end
    
    function XRestaurantManager.Broadcast(txtTip)
        --if IsBroadcastPlaying then
        --    RestaurantBroadcast:Enqueue(txtTip)
        --else
        --    if RestaurantBroadcast and RestaurantBroadcast:Count() > 0 then
        --        RestaurantBroadcast:Enqueue(txtTip)
        --        local tip = RestaurantBroadcast:Dequeue()
        --        PlayBroadcast(tip)
        --    else
        --        PlayBroadcast(txtTip)
        --    end
        --end
        --if IsBroadcastPlaying then
        --    XLuaUiManager.Close("UiRestaurantRadio")
        --end
        local uiName = "UiRestaurantRadio"
        if XLuaUiManager.IsUiShow(uiName) then
            XLuaUiManager.Close(uiName)
        end
        --PlayBroadcast(txtTip)
        XLuaUiManager.Open(uiName, txtTip)
    end
    
    function XRestaurantManager.SetBroadcastPlaying(isPlay)
        IsBroadcastPlaying = isPlay
    end
    
    function XRestaurantManager.OpenMainView(isLevelUp, isRemoveCurUi, isRemoveUiLoading)
        if isRemoveUiLoading then
            XLuaUiManager.Remove("UiLoading")
        end
        local uiName = isLevelUp and "UiRestaurantMain" or "UiRestaurantEntrance"
        if isRemoveCurUi then
            XLuaUiManager.PopThenOpen(uiName)
            return
        end
        XLuaUiManager.Open(uiName)
    end
    
    function XRestaurantManager.OpenPopup(title, content, itemData, cancelCb, confirmCb)
        if XLuaUiManager.IsUiLoad("UiRestaurantPopup") then
            XLuaUiManager.Remove("UiRestaurantPopup")
        end
        XLuaUiManager.Open("UiRestaurantPopup", title, content, itemData, cancelCb, confirmCb)
    end
    
    function XRestaurantManager.OpenStatistics(areaType, firstProductId)
        if XLuaUiManager.IsUiLoad("UiRestaurantExamine") then
            XLuaUiManager.Remove("UiRestaurantExamine")
        end
        XLuaUiManager.Open("UiRestaurantExamine", areaType, firstProductId)
    end
    
    function XRestaurantManager.OpenSignin()
        if not XRestaurantManager.IsOpen() then
            return
        end
        
        if not RestaurantViewModel:CheckSignActivityInTime(false) then
            XUiManager.TipError(XRestaurantConfigs.GetSignNotInTimeTxt())
            return
        end

        if RestaurantViewModel:GetIsGetSignReward() then
            XUiManager.TipError(XRestaurantConfigs.GetSignedTxt())
            return
        end
        XLuaUiManager.Open("UiRestaurantSignIn")
    end

    function XRestaurantManager.OpenTask(ignoreRequest)
        if ignoreRequest then
            XLuaUiManager.Open("UiRestaurantTask")
            return
        end
        local OnResponse = function ()
            XLuaUiManager.Open("UiRestaurantTask")
        end
        -- 加个请求再开启任务界面是为了同步任务数据
        -- 客户端和服务端的料理计算是各算各的只有在交互的时候同步数据并以服务端数据为主
        -- 导致如果一直在界面内挂机无任何交互，收菜类任务不会与服务端同步刷新状态
        -- 因此进入任务界面先同步一波数据
        ExitRoomRequest:Call(nil, nil, OnResponse)
    end
    
    function XRestaurantManager.OpenIndent(orderId, isNotStart, isOnGoing)
        local openFunc = function()
            XLuaUiManager.Open("UiRestaurantIndent")
            
        end
        if isNotStart then
            XRestaurantManager.RequestCollectOrder(orderId, openFunc)
        elseif isOnGoing then
            ExitRoomRequest:Call(nil, nil, openFunc)
        else
            openFunc()
        end
    end
    
    function XRestaurantManager.OpenShop()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
            return
        end
        local shopId = RestaurantViewModel:GetShopId()
        if not XTool.IsNumberValid(shopId) then
            return
        end
        XLuaUiManager.Open("UiRestaurantShop", shopId)
    end
    
    function XRestaurantManager.OpenMenu(tabId)
        if not XRestaurantManager.IsOpen() then
            return
        end
        XLuaUiManager.Open("UiRestaurantMenu", tabId)
    end
    
    function XRestaurantManager.OpenIngredientBubble(rectTransform, foodId)
        local uiName = "UiRestaurantBubbleNeedFood"
        if XLuaUiManager.IsUiShow(uiName) then
            XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_SHOW_INGREDIENT_BUBBLE, rectTransform, foodId)
            return
        end
        XLuaUiManager.Open(uiName, rectTransform, foodId)
    end
    
    --厨房通用奖励弹窗
    function XRestaurantManager.OpenCommonObtain(rewardGoodsList, title, closeCallback, sureCallback)
        if XUiManager.IsTableAsyncLoading() then
            XUiManager.WaitTableLoadComplete(function()
                XLuaUiManager.Open("UiRestaurantObtain", rewardGoodsList, title, closeCallback, sureCallback)
            end)
            return
        end
        XLuaUiManager.Open("UiRestaurantObtain", rewardGoodsList, title, closeCallback, sureCallback)
    end
    
    --解锁食谱
    function XRestaurantManager.OpenUnlockFood(rewardGoodsList, title)
        if XUiManager.IsTableAsyncLoading() then
            XUiManager.WaitTableLoadComplete(function()
                XLuaUiManager.Open("UiRestaurantUnlockFood", rewardGoodsList, title)
            end)
            return
        end
        XLuaUiManager.Open("UiRestaurantUnlockFood", rewardGoodsList, title)
    end
    
    function XRestaurantManager.OnActivityEnd(needRunMain)
        if RestaurantViewModel then
            RestaurantViewModel:OnActivityEnd()
        end

        if RestaurantRoom then
            RestaurantRoom:Release()
        end
        
        RestaurantViewModel = nil
        RestaurantRoom = nil
        if needRunMain then
            XLuaUiManager.RunMain()
            XUiManager.TipText("CommonActivityEnd")
        end
    end
    
    function XRestaurantManager.Clear()
    end
    
    --region   ------------------notify and request start-------------------
    
    --- 活动状态改变
    ---@param notifyData Server.NotifyRestaurantData
    ---@return void
    --------------------------
    function XRestaurantManager.NotifyRestaurantData(notifyData)
        local activityId = notifyData.ActivityId
        if XTool.IsNumberValid(activityId) then
            InitRequire()
            
            RestaurantViewModel = RestaurantViewModel or XRestaurant.New(activityId)
            RestaurantViewModel:OnNotify(notifyData)
        --else
        --    XRestaurantManager.OnActivityEnd()
        end
    end
    
    --- 结算更新
    ---@param notifyData Server.NotifyRestaurantSettleUpdate
    --------------------------
    function XRestaurantManager.NotifyRestaurantSettleUpdate(notifyData)
        if not notifyData then
            return
        end
        local activityId = notifyData.ActivityId
        if not RestaurantViewModel 
                or (XTool.IsNumberValid(activityId) and RestaurantViewModel:GetProperty("_Id") ~= activityId)
        then
            RestaurantViewModel = XRestaurant.New(activityId)
        end
        RestaurantViewModel:UpdateStorageInfo(notifyData.StorageInfos)
        RestaurantViewModel:UpdateWorkBench(notifyData.SectionInfos)
        RestaurantViewModel:UpdateSettle(notifyData.OfflineBill, notifyData.OfflineBillUpdateTime)
    end
    
    --- 进入餐厅请求
    --------------------------
    function XRestaurantManager.RequestEnterRoom(cb)
        EnterRoomRequest:Call(nil, nil, cb)
    end
    
    --- 派遣工作
    --------------------------
    function XRestaurantManager.RequestAssignWork(areaType, characterId, index, productId, cb)
        if XTool.IsNumberValid(characterId) then
            local character = RestaurantViewModel:GetStaffViewModel(characterId)
            if character and character:IsWorking() then
                local tip = XRestaurantConfigs.GetClientConfig("StaffWorkTip", 1)
                XUiManager.TipMsg(string.format(tip, character:GetName()))
                return
            end
        end
        
        local responseCb = function(res)
            if cb then cb() end
            XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_WORK_BENCH_CHANGE_STAFF)
        end
        
        local req = {
            SectionType = areaType,
            CharacterId = characterId,
            Index = index,
            ProductId = productId
        }
        
        AssignWorkRequest:Call(req, responseCb)
    end
    
    --- 请求加速
    --------------------------
    function XRestaurantManager.RequestAccelerate(areaType, index, count, cb)
        local hasCount = XDataCenter.ItemManager.GetCount(XRestaurantConfigs.ItemId.RestaurantAccelerate)
        if hasCount < count then
            return
        end
        
        local responseCb = function(res)
            local list = res.RewardGoodsList
            if not XTool.IsTableEmpty(list) then
                XRestaurantManager.OpenCommonObtain(list)
            end
        end
        
        local req = {
            SectionType = areaType,
            Index = index,
            Count = count
        }
        
        AccelerateRequest:Call(req, responseCb, cb, nil, nil, true)
    end

    --- 收取收银台
    --------------------------
    function XRestaurantManager.RequestCollectCashier(cb)
        local responseCb = function(res)
            local cashier = RestaurantViewModel:GetProperty("_Cashier")
            cashier:SetProperty("_Count", 0)
            if cb then
                cb(res.RewardGoodsList)
            end
        end
        
        CollectCashierRequest:Call(nil, responseCb)
    end
    
    --- 招募员工
    --------------------------
    function XRestaurantManager.RequestEmployStaff(characterId, cb)
        if not RestaurantViewModel then
            return
        end
        local character = RestaurantViewModel:GetStaffViewModel(characterId)
        if character:GetProperty("_IsRecruit") then
            return
        end
        local staffList = RestaurantViewModel:GetRecruitStaffList()
        local limit = XRestaurantConfigs.GetCharacterLimit(RestaurantViewModel:GetProperty("_Level"))
        if limit <= #staffList then
            local tip = XRestaurantConfigs.GetClientConfig("StaffRecruitTip", 1)
            XUiManager.TipMsg(tip)
            return
        end
        local consumeData = XRestaurantConfigs.GetCharacterEmployConsume(characterId)
        for _, data in pairs(consumeData or {}) do
            local count = XDataCenter.ItemManager.GetCount(data.ItemId)
            if count < data.Count then
                XUiManager.TipText("CommonCoinNotEnough")
                return
            end
        end
        local req = {
            CharacterId = characterId
        }
        XNetwork.Call("RestaurantEmployRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            character:Recruit()
            local tip = XRestaurantConfigs.GetClientConfig("BoardCastTips", 1)
            tip = string.format(tip, character:GetName())
            XRestaurantManager.Broadcast(tip)
            RestaurantViewModel:NotifyLevelConditionEventChange()
            if cb then cb() end
        end)
    end
    
    --- 升级员工
    --------------------------
    function XRestaurantManager.RequestLevelUpStaff(characterId, cb)
        local character = RestaurantViewModel:GetStaffViewModel(characterId)
        if not character then
            return
        end
        if not character:GetProperty("_IsRecruit") then
            return
        end
        local level = character:GetProperty("_Level")
        if level >= XRestaurantConfigs.StaffLevel.Max then
            return
        end
        local consumeData = XRestaurantConfigs.GetCharacterLevelUpConsume(characterId, level)
        for _, data in pairs(consumeData or {}) do
            local count = XDataCenter.ItemManager.GetCount(data.ItemId)
            if count < data.Count then
                XUiManager.TipText("CommonCoinNotEnough")
                return
            end
        end
        
        local responseCb = function(res)
                local tip = XRestaurantConfigs.GetClientConfig("BoardCastTips", 2)
                tip = string.format(tip, character:GetName(), character:GetLevelStr())
                XRestaurantManager.Broadcast(tip)
                RestaurantViewModel:NotifyLevelConditionEventChange()
                if cb then cb(character) end
        end
        
        local req = {
            CharacterId = characterId
        }
        
        LevelUpStaffRequest:Call(req, responseCb)
    end
    
    --- 升级餐厅
    --------------------------
    function XRestaurantManager.RequestLevelUpRestaurant(cb)
        if not RestaurantViewModel then
            return
        end
        local level = RestaurantViewModel:GetProperty("_Level")
        if level >= XRestaurantConfigs.LevelRange.Max then
            return
        end
        local upgradeCondition = XRestaurantConfigs.GetUpgradeCondition(level)
        for _, consume in pairs(upgradeCondition.ConsumeData or {}) do
            local count = XDataCenter.ItemManager.GetCount(consume.ItemId)
            if count < consume.Count then
                XUiManager.TipText("CommonCoinNotEnough")
                return
            end
        end
        
        XNetwork.Call("RestaurantUpgradeRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            RestaurantViewModel:LevelUp(res.RestaurantLv)
            --更新红点
            RestaurantViewModel:NotifyBuffRedPointChange()
            
            if cb then cb() end 
        end)
    end
    
    ---- 收取离线收益
    --------------------------
    function XRestaurantManager.RequestReceiveOfflineBill(cb)

        local responseCb = function(res)
            --local cashier = RestaurantViewModel:GetProperty("_Cashier")
            --cashier:SetProperty("_Count", 0)
            RestaurantViewModel:UpdateSettle(0, XTime.GetServerNowTimestamp())
            if cb then cb(res.RewardGoodsList) end
        end

        OfflineBillRequest:Call(nil, responseCb)
    end

    -- 请求签到
    function XRestaurantManager.RestaurantSignRequest(cb)
        XNetwork.Call("RestaurantSignRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            RestaurantViewModel:UpdateSignData(true)
            if table.nums(res.RewardGoodsList) > 0 then
                XRestaurantManager.OpenCommonObtain(res.RewardGoodsList)
            end

            if RestaurantRoom then
                RestaurantRoom:ChangeSignNpcState(XRestaurantConfigs.SignState.Complete)
            end
            
            if cb then cb() end
        end)
    end
    
    -- 退出餐厅
    function XRestaurantManager.RequestExitRoom(cb)
        if IsRequestExitRoom then
            if cb then cb() end
            return
        end
        IsRequestExitRoom = true
        local responseCb = function()
            IsRequestExitRoom = false
            if cb then cb() end
        end

        ExitRoomRequest:Call(nil, responseCb)
    end
    
    -- 领取订单
    function XRestaurantManager.RequestCollectOrder(orderId, func)
        XNetwork.Call("RestaurantTakeOrderRequest", { OrderId = orderId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            RestaurantViewModel:UpdateOrderInfo(RestaurantViewModel:GetOrderActivityId(), res.OrderInfos)
            XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_ORDER_STATE_CHANGE)
            
            if func then func() end
        end)
    end
    
    --完成订单
    function XRestaurantManager.RequestFinishOrder(orderId, func)
        XNetwork.Call("RestaurantFinishOrderRequest", { OrderId = orderId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local orderInfo = RestaurantViewModel:GetTodayOrderInfo()
            if orderInfo then
                orderInfo:SetState(XRestaurantConfigs.OrderState.Finish)
            end
            
            RestaurantRoom:ChangeOrderNpcState(XRestaurantConfigs.OrderState.Finish)

            XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_ORDER_STATE_CHANGE)

            if func then func(res.RewardGoodsList) end
            
            RestaurantViewModel:NotifyMenuRedPointChange()
        end)
    end
    
    function XRestaurantManager.RequestStopAll(cb)
        local requestCb = function()
            
            RestaurantViewModel:StopAll()
            
            if cb then cb() end
        end
        AllStaffStopRequest:Call(nil, requestCb)
    end
    
	--解锁Buff
    function XRestaurantManager.RequestUnlockBuff(buffId, cb)
        
        XNetwork.Call("RestaurantUnlockSectionBuffRequest", { BuffId = buffId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            local buff = RestaurantViewModel:GetBuff(buffId)
            buff:Unlock()
            
            if cb then cb() end
        end)
    end
    
	--切换Buff
    function XRestaurantManager.RequestSwitchBuff(areaType, buffId, cb)
        local req = {
            BuffId = buffId
        }
        local responseCb = function(res)
            --RestaurantViewModel:SetAreaBuffId(areaType, buffId)

            if cb then cb() end
        end
        SwitchSectionBuffRequest:Call(req, responseCb)
    end
    --endregion------------------notify and request finish------------------
    
    --region   ------------------red point start-------------------
    local baseCheckRedPoint = function()
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Restaurant) then
            return false
        end
        if not XRestaurantManager.IsOpen() then
            return false
        end
        return true
    end
    
    local IsInBusiness = function()
        if not RestaurantViewModel then
            return false
        end
        return RestaurantViewModel:IsInBusiness()
    end
    
    --活动入口
    function XRestaurantManager.CheckEntranceRedPoint()
        if not baseCheckRedPoint() then
            return false
        end
        
        --打烊，后续红点不判断
        if not IsInBusiness() then
            return false
        end

        if XRestaurantManager.CheckTaskRedPoint() then
            return true
        end

        if XRestaurantManager.CheckOrderRedPoint() then
            return true
        end

        local timeStamp = XTime.GetSeverNextRefreshTime()
        local key = GetCookiesKey("CashierLimitNextRefresh_" .. timeStamp)
        --每天只展示一次
        if not XSaveTool.GetData(key) and XRestaurantManager.CheckCashierLimitRedPoint() then
            return true
        end
        
        return false
    end

    --标记收银台今日已读
    function XRestaurantManager.MarkCashierLimitRedPoint()
        --未达到上限无需标记
        if not XRestaurantManager.CheckCashierLimitRedPoint() then
            return
        end
        local timeStamp = XTime.GetSeverNextRefreshTime()
        local key = GetCookiesKey("CashierLimitNextRefresh_" .. timeStamp)
        if XSaveTool.GetData(key) then
            return
        end
        XSaveTool.SaveData(key, true)
    end
    
    --任务入口
    function XRestaurantManager.CheckTaskRedPoint()
        if not baseCheckRedPoint() then
            return false
        end
        if XRestaurantManager.CheckDailyTaskRedPoint() then
            return true
        end
        if XRestaurantManager.CheckAchievementTaskRedPoint() then
            return true
        end
        if XRestaurantManager.CheckRecipeTaskRedPoint() then
            return true
        end
        return false
    end

    --每日任务红点
    function XRestaurantManager.CheckDailyTaskRedPoint()
        local timeLimitTaskIds = RestaurantViewModel:GetTimeLimitTaskIds()
        
        for _, timeLimitTaskId in ipairs(timeLimitTaskIds) do
            if XTaskConfig.IsTimeLimitTaskInTime(timeLimitTaskId) then
                local timeLimitTaskCfg = timeLimitTaskId ~= 0 and XTaskConfig.GetTimeLimitTaskCfg(timeLimitTaskId) or {}
                for _, taskId in ipairs(timeLimitTaskCfg.DayTaskId) do
                    if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                        return true
                    end
                end
            end
        end
        return false
    end

    --成就任务红点
    function XRestaurantManager.CheckAchievementTaskRedPoint()
        local timeLimitTaskIds = RestaurantViewModel:GetTimeLimitTaskIds()
        
        for _, timeLimitTaskId in ipairs(timeLimitTaskIds) do
            if XTaskConfig.IsTimeLimitTaskInTime(timeLimitTaskId) then
                local timeLimitTaskCfg = timeLimitTaskId ~= 0 and XTaskConfig.GetTimeLimitTaskCfg(timeLimitTaskId) or {}
                for _, taskId in ipairs(timeLimitTaskCfg.TaskId) do
                    if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                        return true
                    end
                end
            end
        end
        return false
    end
    
    --食谱任务红点
    function XRestaurantManager.CheckRecipeTaskRedPoint()
        if not baseCheckRedPoint() then
            return false
        end
        local recipeId = RestaurantViewModel:GetRecipeTaskId()
        local taskCfg = XTaskConfig.GetTimeLimitTaskCfg(recipeId)

        for _, taskId in ipairs(taskCfg.TaskId) do
            if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                return true
            end
        end
        return false
    end
    
    --收银台上限
    function XRestaurantManager.CheckCashierLimitRedPoint()
        if not baseCheckRedPoint() then
            return false
        end
        local cashier = RestaurantViewModel:GetProperty("_Cashier")
        return cashier:IsFull()
    end
    
    --热销
    function XRestaurantManager.CheckHotSaleRedPoint()
        if not baseCheckRedPoint() then
            return false
        end
        local curDay = RestaurantViewModel:GetProperty("_CurDay")
        local key = "HotSaleRedPoint" .. curDay
        if not XSaveTool.GetData(GetCookiesKey(key)) then
            return true
        end
        return false
    end
    
    --标记已阅读
    function XRestaurantManager.MarkHotSaleRedPoint()
        if not baseCheckRedPoint() then
            return
        end
        local curDay = RestaurantViewModel:GetProperty("_CurDay")
        local key = GetCookiesKey("HotSaleRedPoint" .. curDay)
        if XSaveTool.GetData(key) then
            return
        end
        XSaveTool.SaveData(key, true)
    end
    
    function XRestaurantManager.CheckOrderRedPoint()
        if not baseCheckRedPoint() then
            return false
        end
        return RestaurantViewModel:CheckOrderFinish()
    end
    
    --- 餐厅能否升级
    ---@param level number 可选参数，为空时则检测全部等级
    ---@return boolean
    --------------------------
    function XRestaurantManager.CheckRestaurantUpgradeRedPoint(level)
        if not baseCheckRedPoint() then
            return false
        end
        local curLv = RestaurantViewModel:GetProperty("_Level")
        local function checkCondition(lv)
            if curLv >= lv or lv <= 0 then
                return false
            end
            local levelUpgrade = XRestaurantConfigs.GetUpgradeCondition(lv - 1)
            local conditionList = XRestaurantConfigs.GetRestaurantUnlockConditionList(levelUpgrade)
            for _, condition in pairs(conditionList or {}) do
                if not condition.Finish then
                    return false
                end
            end
            return true
        end

        if XTool.IsNumberValid(level) then
            return checkCondition(level)
        end
        
        for lv = curLv + 1, XRestaurantConfigs.LevelRange.Max do
            if checkCondition(lv) then
                return true
            end
        end
        return false
    end
    
    local function CheckTabMenuRedPoint(tabId)
        if not baseCheckRedPoint() then
            return false
        end
        if not XRestaurantConfigs.CheckMenuTabInTime(tabId) then
            return false
        end
        local key = GetCookiesKey("MenuTab_" .. tostring(tabId))
        local recordCount = XSaveTool.GetData(key) or 0
        local count = 0
        if tabId == XRestaurantConfigs.MenuTabType.Food then
            count = RestaurantViewModel:GetUnlockProductCount(XRestaurantConfigs.AreaType.FoodArea)
        elseif tabId == XRestaurantConfigs.MenuTabType.Message then
            count = #RestaurantViewModel:GetUnlockOrderInfoList()
        end
        
        return recordCount ~= count
    end
    
    function XRestaurantManager.CheckMenuRedPoint(tabId)
        if XTool.IsNumberValid(tabId) then
            return CheckTabMenuRedPoint(tabId)
        else
            local list = XRestaurantConfigs.GetMenuTabList()
            for _, id in pairs(list) do
                if CheckTabMenuRedPoint(id) then
                    return true
                end
            end
        end
        
        return false
    end
    
    function XRestaurantManager.MarkMenuRedPoint(tabId)
        local key = GetCookiesKey("MenuTab_" .. tostring(tabId))
        local recordCount = XSaveTool.GetData(key) or 0
        local count = 0
        if tabId == XRestaurantConfigs.MenuTabType.Food then
            count = RestaurantViewModel:GetUnlockProductCount(XRestaurantConfigs.AreaType.FoodArea)
        elseif tabId == XRestaurantConfigs.MenuTabType.Message then
            count = #RestaurantViewModel:GetUnlockOrderInfoList()
        end
        
        if count == recordCount then
            return
        end
        
        XSaveTool.SaveData(key, count)
        RestaurantViewModel:NotifyMenuRedPointChange()
    end
    
    local function CheckSingleBuffRedPoint(buffId)
        local buff = RestaurantViewModel:GetBuff(buffId)
        --等级不足时不检查
        if not buff or not buff:IsReachLevel() then
            return
        end
        local key = GetCookiesKey("Unlock_Buff_" .. tostring(buffId))
        local data = XSaveTool.GetData(key)
        if not data then
            return true
        end
        return false
    end
    
    --- 检查buff红点
    ---@param areaType number 当不传areaType时检查所有buff
    ---@param buffId number 当传areaType, 传buffId时检查对应buff，不传时检查当前区域所有buff
    ---@return boolean
    --------------------------
    function XRestaurantManager.CheckBuffRedPoint(areaType, buffId)
        if not baseCheckRedPoint() then
            return false
        end
        if not areaType and not buffId then
            for _, aType in pairs(XRestaurantConfigs.AreaType) do
                local buffIds = XRestaurantConfigs.GetBuffIdList(aType)
                for _, bId in ipairs(buffIds) do
                    if CheckSingleBuffRedPoint(bId) then
                        return true
                    end
                end
            end
        elseif not buffId then
            local buffIds = XRestaurantConfigs.GetBuffIdList(areaType)
            for _, bId in ipairs(buffIds) do
                if CheckSingleBuffRedPoint(bId) then
                    return true
                end
            end
        else
            return CheckSingleBuffRedPoint(buffId)
        end
        
        return false
    end
    
    --- 标记红点已读
    ---@param buffId number
    ---@return void
    --------------------------
    function XRestaurantManager.MarkBuffRedPoint(buffId)
        local buff = RestaurantViewModel:GetBuff(buffId)
        if not buff or not buff:IsReachLevel() then
            return
        end
        local key = GetCookiesKey("Unlock_Buff_" .. tostring(buffId))
        local data = XSaveTool.GetData(key)
        if data then
            return
        end
        
        XSaveTool.SaveData(key, true)
        RestaurantViewModel:NotifyBuffRedPointChange()
    end
    
    --- 区域工作台红点
    ---@param areaType number
    ---@param benchId number
    ---@return boolean
    --------------------------
    function XRestaurantManager.CheckWorkBenchRedPoint(areaType, benchId)
        -- 空闲人数小于0
        local freeCount = RestaurantViewModel:GetFreeStaffCount()
        if freeCount <= 0 then
            return false
        end
        --成就任务全部完成
        local recipeId = RestaurantViewModel:GetRecipeTaskId()
        local taskCfg = XTaskConfig.GetTimeLimitTaskCfg(recipeId)

        local isFinishAll = true
        for _, taskId in ipairs(taskCfg.TaskId) do
            if not XDataCenter.TaskManager.CheckTaskFinished(taskId) then
                isFinishAll = false
                break
            end
        end

        if isFinishAll then
            return false
        end
        
        if XTool.IsNumberValid(benchId) then
            local workBench = RestaurantViewModel:GetWorkBenchViewModel(areaType, benchId)
            return workBench:IsFree()
        else
            local list = RestaurantViewModel:GetUnlockWorkBenchList(areaType)
            for _, bench in pairs(list) do
                if bench:IsFree() then
                    return true
                end
            end
        end
        return false
    end
    --endregion------------------red point finish------------------
    
    return XRestaurantManager
end

--region   ------------------Rpc start-------------------
XRpc.NotifyRestaurantData = function(notifyData) 
    XDataCenter.RestaurantManager.NotifyRestaurantData(notifyData)
end

XRpc.NotifyRestaurantSettleUpdate = function(notifyData) 
    XDataCenter.RestaurantManager.NotifyRestaurantSettleUpdate(notifyData)
end
--endregion------------------Rpc finish------------------