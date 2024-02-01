XAreaWarManagerCreator = function()
    local tableInsert = table.insert
    local pairs = pairs
    local tonumber = tonumber
    local stringFormat = string.format
    local tableUnpack = table.unpack

    ---@class XAreaWarManager
    local XAreaWarManager = require("XEntity/XFuben/XExFubenActivityManager").New(XFubenConfigs.ChapterType.AreaWar, "AreaWarManager")

    -----------------活动入口 begin----------------
    local _ActivityId = XAreaWarConfigs.GetDefaultActivityId() --当前开放活动Id
    local _IsOpening = false --活动是否开启中（根据服务端下发活动有效Id判断）
    local _ActivityEnd = false --活动是否结束
    local _PerformanceTesting = false --性能测试
    local _IsPlayMovie = false --是否播放开场剧情

    local MAIN_UI_NEWBIE_GUIDE_ID = 61230 --主界面新手引导Id

    local function UpdateActivityId(activityId)
        XCountDown.RemoveTimer(XCountDown.GTimerName.AreaWar)

        if not XTool.IsNumberValid(activityId) then
            _ActivityId = XAreaWarConfigs.GetDefaultActivityId()
            return
        end

        _ActivityId = activityId

        local nowTime = XTime.GetServerNowTimestamp()
        local leftTime = XAreaWarManager.GetEndTime() - nowTime
        if leftTime > 0 then
            XCountDown.CreateTimer(XCountDown.GTimerName.AreaWar, leftTime)
        end

        _IsOpening = true
    end

    function XAreaWarManager.GetActivityName()
        return XAreaWarConfigs.GetActivityName(_ActivityId)
    end

    function XAreaWarManager.GetActivityChapters()
        if not XAreaWarManager.IsOpen() then
            return
        end

        local chapters = {}
        tableInsert(
            chapters,
            {
                Id = _ActivityId,
                Type = XDataCenter.FubenManager.ChapterType.AreaWar,
                BannerBg = XAreaWarConfigs.GetActivityBanner(_ActivityId),
                Name = XAreaWarManager.GetActivityName()
            }
        )
        return chapters
    end

    function XAreaWarManager.IsOpen()
        if not XTool.IsNumberValid(_ActivityId) then
            return false
        end

        if not _IsOpening then
            return false
        end

        local nowTime = XTime.GetServerNowTimestamp()
        local beginTime = XAreaWarManager.GetStartTime()
        local endTime = XAreaWarManager.GetEndTime()
        return beginTime <= nowTime and nowTime < endTime
    end

    function XAreaWarManager.GetStartTime()
        return XAreaWarConfigs.GetActivityStartTime(_ActivityId) or 0
    end

    function XAreaWarManager.GetEndTime()
        return XAreaWarConfigs.GetActivityEndTime(_ActivityId) or 0
    end

    --可挑战标签条件Cookie
    local function GetChallengeTagCookieKey()
        return stringFormat("ActionPointReachCookieKey_%d", XTime.GetSeverNextRefreshTime())
    end

    --活动面板入口可挑战标签显示条件（每次上线触发一次）
    --点击可挑战标签后需要调用SetChallengeTagCookie()接口设置每日Cookie
    function XAreaWarManager.CheckEntranceChallangeTag()
        --每日检查一次
        if XAreaWarManager.CheckCookieExist(GetChallengeTagCookieKey()) then
            return false
        end
        --当活动体力拥有的数量大于某个数字（可配置）时
        return XAreaWarManager.CheckActionPointReach()
    end

    --设置体力是否达到可挑战条件Cookie（每日检查，点击活动面板可挑战标签后调用）
    function XAreaWarManager.SetChallengeTagCookie()
        XAreaWarManager.SetCookie(GetChallengeTagCookieKey())
    end

    --获取活动开启到现在持续时长（秒）
    function XAreaWarManager.GetContinueSeconds()
        local startTime = XAreaWarManager.GetStartTime()
        if not XTool.IsNumberValid(startTime) then
            return 0
        end

        local nowTime = XTime.GetServerNowTimestamp()
        return startTime - nowTime
    end

    function XAreaWarManager.SetActivityEnd()
        _ActivityEnd = true

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_AREA_WAR_ACTIVITY_END)
        CsXGameEventManager.Instance:Notify(
            XEventId.EVENT_ACTIVITY_ON_RESET,
            XDataCenter.FubenManager.StageType.AreaWar
        )
    end

    function XAreaWarManager.ClearActivityEnd()
        _ActivityEnd = nil
    end

    function XAreaWarManager.OnActivityEnd()
        if not _ActivityEnd then
            return false
        end

        if
            CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") or XLuaUiManager.IsUiLoad("UiSettleLose") or
                XLuaUiManager.IsUiLoad("UiSettleWin")
         then
            return false
        end

        --延迟是为了防止打断UI动画
        XScheduleManager.ScheduleOnce(
            function()
                XLuaUiManager.RunMain()
                XUiManager.TipText("AreaWarActivityEnd")
            end,
            1000
        )

        XAreaWarManager.ClearActivityEnd()

        return true
    end

    --请求打开活动主界面
    local _CDReqActivityData = 30 --CD(s)
    local _LastTimeReqActivityData = 0
    function XAreaWarManager.EnterUiMain(beforeOpenUiCb)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.AreaWar) then
            return
        end

        if not XAreaWarManager.IsOpen() then
            XUiManager.TipText("AreaWarActivityNotOpen")
            return
        end
        
        local beforeOpenUi = function(cb)
            if beforeOpenUiCb then beforeOpenUiCb() end
            if cb then cb() end
        end
        
        local asynBeforeOpenFunc = asynTask(beforeOpenUi)
        
        local asynReq = asynTask(XAreaWarManager.AreaWarGetActivityDataRequest)
        --主动gc一次
        LuaGC()
        
        RunAsyn(
            function()
                --检查CD，未过CD直接使用缓存信息打开界面
                if _LastTimeReqActivityData + _CDReqActivityData - XTime.GetServerNowTimestamp() <= 0 then
                    asynReq()
                    _LastTimeReqActivityData = XTime.GetServerNowTimestamp()
                end

                asynBeforeOpenFunc()

                local storyId = XAreaWarConfigs.GetFirstPlayStoryId()
                if XAreaWarManager.CheckIsFirstPlay() and not string.IsNilOrEmpty(storyId) then
                    _IsPlayMovie = true
                    XDataCenter.MovieManager.PlayMovie(XAreaWarConfigs.GetFirstPlayStoryId(), function()
                        XLuaUiManager.Open("UiAreaWarMain")
                        XDataCenter.AreaWarManager.MarkFirstPlay()
                    end, nil, nil, false)

                else
                    XLuaUiManager.Open("UiAreaWarMain")
                end
            end
        )
    end
    
    function XAreaWarManager.IsPlayMovieOnEnter()
        return _IsPlayMovie
    end

    local _LastCameraFollowPointPos  --退出界面后记录相机上次滑动到的位置（本次登录有效）
    function XAreaWarManager.GetLastCameraFollowPointPos()
        return _LastCameraFollowPointPos
    end

    --记录相机跟随点最后位置
    function XAreaWarManager.SaveLastCameraFollowPointPos(pos)
        _LastCameraFollowPointPos = pos
    end
    
    local _LastWarLogTabIndex = 1
    function XAreaWarManager.GetLastWarLogTabIndex()
        return _LastWarLogTabIndex
    end
    
    function XAreaWarManager.SaveLastWarLogTabIndex(index)
        _LastWarLogTabIndex = index
    end
    -----------------活动入口 end------------------
    -----------------活动道具 begin------------------
    local _ActionPointItemId = XDataCenter.ItemManager.ItemId.AreaWarActionPoint --体力
    local _CoinItemId = XDataCenter.ItemManager.ItemId.AreaWarCoin --货币
    local _MaxActionPoint = CS.XGame.Config:GetInt("AreaWarMaxActionPoint") --自然恢复最大体力
    local _ToChallengeActionPoint = CS.XGame.ClientConfig:GetInt("AreaWarToChallengeActionPoint") --体力超过此值后活动入口显示可挑战标签
    local _CanBuyCoin = CS.XGame.ClientConfig:GetInt("AreaWarCanBuyCoin") --货币达到此值后显示红点
    local _FirstOpenShop = "_FirstOpenShop"
    local _ShopItemIdMap = {}

    --获取体力自然恢复上限
    function XAreaWarManager.GetMaxActionPoint()
        return _MaxActionPoint
    end

    --检查体力是否达到配置的值
    function XAreaWarManager.CheckActionPoint(count)
        return XDataCenter.ItemManager.CheckItemCountById(_ActionPointItemId, count)
    end

    --检查体力是否达到配置的值
    function XAreaWarManager.CheckActionPointReach()
        return XAreaWarManager.CheckActionPoint(_ToChallengeActionPoint)
    end

    --检查货币是否达到配置的值
    function XAreaWarManager.CheckCoinReach()
        return XDataCenter.ItemManager.CheckItemCountById(_CoinItemId, _CanBuyCoin)
    end
    
    local function UpdateShopRedPoint(checkCb)
        local list = {}
        for _, shopId in pairs(XAreaWarManager.GetActivityShopIds()) do
            list = appendArray(list, XShopManager.GetShopGoodsList(shopId, nil, true))
        end
        _ShopItemIdMap = {}
        for _, data in ipairs(list) do
            local conditions = data.ConditionIds
            --没有条件
            if XTool.IsTableEmpty(conditions) then
                _ShopItemIdMap[data.Id] = true
            else
                local unlock = true
                for _, conditionId in ipairs(conditions) do
                    local res, _ = XConditionManager.CheckCondition(conditionId)
                    if not res then
                        unlock = false
                        break
                    end
                end
                if unlock then
                    _ShopItemIdMap[data.Id] = true
                end
            end
        end
        
        local result = false
        for id in pairs(_ShopItemIdMap) do
            local key = XAreaWarManager.GetCookieKey(_FirstOpenShop .. id)
            if not XSaveTool.GetData(key) then
                result = true 
                break
            end
        end

        if checkCb then checkCb(result) end
    end
    
    function XAreaWarManager.CheckShopRedPoint(checkCb)
        if not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.ShopCommon) then
            if checkCb then checkCb(false) end
            return
        end
        local firstKey = XAreaWarManager.GetCookieKey(_FirstOpenShop)
        if not XSaveTool.GetData(firstKey) then
            if checkCb then checkCb(true) end
            return
        end
        XShopManager.GetShopInfoList(XAreaWarManager.GetActivityShopIds(), function()
            UpdateShopRedPoint(checkCb)
        end, XShopManager.ActivityShopType.AreaWar)
    end
    
    function XAreaWarManager.MarkShopRedPoint()
        local firstKey = XAreaWarManager.GetCookieKey(_FirstOpenShop)
        if not XSaveTool.GetData(firstKey) then
            XSaveTool.SaveData(firstKey, true)
        end
        for id in pairs(_ShopItemIdMap or {}) do
            local key = XAreaWarManager.GetCookieKey(_FirstOpenShop .. id)
            if not XSaveTool.GetData(key) then
                XSaveTool.SaveData(key, true)
            end
        end
    end

    --获取活动货币ItemId
    function XAreaWarManager.GetCoinItemId()
        return _CoinItemId
    end

    --获取活动货币图标
    function XAreaWarManager.GetCoinItemIcon()
        return XItemConfigs.GetItemIconById(_CoinItemId)
    end

    --获取活动体力图标
    function XAreaWarManager.GetActionPointItemIcon()
        return XItemConfigs.GetItemIconById(_ActionPointItemId)
    end
    -----------------活动道具 end------------------
    -----------------活动任务 begin------------------
    --获取任务组Id（多组，分多个页签展示）
    function XAreaWarManager.GetActivityTaskList(index)
        local groupId = XAreaWarConfigs.GetActivityTimeLimitTaskId(_ActivityId, index)
        if not XTool.IsNumberValid(groupId) then
            return {}
        end
        return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId)
    end

    --检查是否有任务可领取奖励（对应页签的一批任务）
    function XAreaWarManager.CheckTaskHasRewardToGet(index)
        local taskId = XAreaWarConfigs.GetActivityTimeLimitTaskId(_ActivityId, index)
        if not XTool.IsNumberValid(taskId) then
            return false
        end
        return XDataCenter.TaskManager.CheckLimitTaskList(taskId)
    end

    --检查是否有任务可领取奖励（所有任务）
    function XAreaWarManager.CheckAllTaskHasRewardToGet()
        local taskIds = XAreaWarConfigs.GetActivityTimeLimitTaskIds(_ActivityId)
        for _, taskId in pairs(taskIds) do
            if XDataCenter.TaskManager.CheckLimitTaskList(taskId) then
                return true
            end
        end
        return false
    end

    --获取下一个未完成的进度任务（index = 1）的提示文本（任务描述）
    function XAreaWarManager.GetNextTaskProgressTip()
        local tipStr = ""
        local index = 1 --固定读取第一个页签的任务作为进度展示
        local taskList = XAreaWarManager.GetActivityTaskList(index) --排过序了
        local nextTask
        for _, task in ipairs(taskList) do
            if task.State == XDataCenter.TaskManager.TaskState.Active then
                nextTask = task
                break
            end
        end
        if not XTool.IsTableEmpty(nextTask) then
            local config = XDataCenter.TaskManager.GetTaskTemplate(nextTask.Id)
            tipStr = config.Desc
        end
        return tipStr
    end
    -----------------活动任务 end------------------
    -----------------活动商店 begin------------------
    function XAreaWarManager.GetActivityShopIds()
        return XAreaWarConfigs.GetActivityShopIds(_ActivityId)
    end

    function XAreaWarManager.OpenUiShop()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
            return
        end

        local shopIds = XAreaWarManager.GetActivityShopIds()
        local asyncReq = asynTask(XShopManager.GetShopInfoList, nil, 2)
        RunAsyn(
            function()
                if not XTool.IsTableEmpty(shopIds) then
                    asyncReq(shopIds, nil, XShopManager.ActivityShopType.AreaWar)
                end

                XLuaUiManager.Open("UiAreaWarShop")
            end
        )
    end
    -----------------活动商店 end------------------
    -----------------净化加成/插件相关 begin------------------
    local XAreaWarSelfPurification = require("XEntity/XAreaWar/XAreaWarSelfPurification")
    local XAreaWarPlugin = require("XEntity/XAreaWar/XAreaWarPlugin")

    local _SelfPurifyData = {} --净化等级数据
    local _PluginDic = {} --插件（aka：词缀）信息

    local function GetPlugin(pluginId)
        if not XTool.IsNumberValid(pluginId) then
            return
        end

        local plugin = _PluginDic[pluginId]
        if not plugin then
            plugin = XAreaWarPlugin.New(pluginId)
            _PluginDic[pluginId] = plugin
        end
        return plugin
    end

    local function CheckSlot(slot)
        if not slot or slot <= 0 or slot > XAreaWarConfigs.PluginSlotCount then
            XLog.Error("XAreaWarManager CheckSlot error: 插件槽位非法, slot: ", slot)
            return false
        end
        return true
    end

    --解锁插件
    local function UnlockPlugin(pluginId)
        if not XTool.IsNumberValid(pluginId) then
            return
        end
        GetPlugin(pluginId):Unlock()
    end

    local function UpdateUnlockPlugins(data)
        if XTool.IsTableEmpty(data) then
            return
        end

        for _, pluginId in pairs(data) do
            UnlockPlugin(pluginId)
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_AREA_WAR_PLUGIN_UNLOCK)
        XEventManager.DispatchEvent(XEventId.EVENT_AREA_WAR_PLUGIN_UNLOCK)
    end

    local function InitSelfPurification()
        _SelfPurifyData = XAreaWarSelfPurification.New()
    end

    local function UpdateSelfPurification(level, exp)
        _SelfPurifyData:UpdateLevelExp(level, exp)
        XAreaWarManager.UpdateNewPurificationLevel(level)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_AREA_WAR_PURIFICATION_LEVEL_CHANGE)
    end

    --是否有可解锁的插件
    function XAreaWarManager.HasPluginToUnlock()
        local pluginIds = XAreaWarConfigs.GetAllPluginIds()
        for _, pluginId in pairs(pluginIds) do
            if XAreaWarManager.IsPluginCanUnlock(pluginId) then
                return true
            end
        end
        return false
    end

    --插件是否可解锁
    function XAreaWarManager.IsPluginCanUnlock(pluginId)
        if not XTool.IsNumberValid(pluginId) then
            return false
        end
        if XAreaWarManager.IsPluginUnlock(pluginId) then
            return false
        end
        local requireLevel = XAreaWarConfigs.GetPfLevelByPluginId(pluginId)
        if not XTool.IsNumberValid(requireLevel) then
            return false
        end
        local pfLevel = XAreaWarManager.GetSelfPurificationLevel()
        return pfLevel >= requireLevel
    end

    --插件是否已解锁
    function XAreaWarManager.IsPluginUnlock(pluginId)
        if not XTool.IsNumberValid(pluginId) then
            return false
        end
        return GetPlugin(pluginId):IsUnlock()
    end
    
    function XAreaWarManager.GetPluginUnlockCount()
        local unlock = 0
        for key, pluginData in pairs(_PluginDic) do
            if pluginData._Unlock then
                unlock = unlock + 1
            end
        end
        return unlock
    end
    
    --插件是否使用中
    function XAreaWarManager.IsPluginUsing(pluginId)
        return XTool.IsNumberValid(XAreaWarManager.GetPluginUsingSlot(pluginId))
    end

    --净化加成功能是否解锁（净化区块数量大于1且净化等级大于0级）
    function XAreaWarManager.IsPurificationLevelUnlock()
        local clearCount = XAreaWarManager.GetBlockProgress()
        local level = XAreaWarManager.GetSelfPurificationLevel()
        return clearCount > 0 and level > 0
    end

    --获取净化等级
    function XAreaWarManager.GetSelfPurificationLevel()
        return _SelfPurifyData:GetLevel()
    end

    --获取净化经验
    function XAreaWarManager.GetSelfPurificationExp()
        return _SelfPurifyData:GetExp()
    end

    --获取净化进度（当前累积净化经验，总净化经验）
    function XAreaWarManager.GetSelfPurificationProgress()
        local level = XAreaWarManager.GetSelfPurificationLevel()
        local maxLevel = XAreaWarConfigs.GetMaxPfLevel()
        return XAreaWarConfigs.GetAccumulatedPfExp(level) + XAreaWarManager.GetSelfPurificationExp(), XAreaWarConfigs.GetAccumulatedPfExp(
            maxLevel
        )
    end

    --打开净化加成界面
    function XAreaWarManager.OpenUiPurificationLevel()
        if not XAreaWarManager.IsPurificationLevelUnlock() then
            XUiManager.TipText("AreaWarPurificationLevelLock")
            return
        end
        XLuaUiManager.Open("UiAreaWarJingHua")
    end
    
    --打开聊天界面
    function XAreaWarManager.OpenUiChat()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SocialChat) then
            return
        end
        XLuaUiManager.Open("UiChatServeMain", false, ChatChannelType.World)
    end

    --请求解锁插件
    function XAreaWarManager.AreaWarUnlockPurificationBuffRequest(pluginId, cb)
        local req = {BuffId = pluginId}
        XNetwork.Call(
            "AreaWarUnlockPurificationBuffRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateUnlockPlugins({pluginId})

                if cb then
                    cb()
                end
            end
        )
    end
    
    -----------------净化加成/插件相关 end------------------
    -----------------挂机收益 begin------------------
    local _HangUpRewardCount = 0 --挂机收益奖励数量（大于0时代表有奖励可领取，实际数量打开界面时请求）
    local _HangUpRewardFlag = false --挂机收益奖励数量是否有变更（服务端通知）
    local _HangUpUnlockCookieKey = "_HangUpUnlockCookieKey" --首次解锁弹窗Cookie

    local function UpdateHangUpRewardFlag(count)
        _HangUpRewardFlag = count and count > 0 or false

        --通知UI请求最新的服务端挂机收益
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_AREA_WAR_HANG_UP_REWARD_REMIND_CHANGE)
        XEventManager.DispatchEvent(XEventId.EVENT_AREA_WAR_HANG_UP_REWARD_REMIND_CHANGE)
    end

    local function UpdateHangUpRewardCount(count)
        _HangUpRewardCount = count or _HangUpRewardCount

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_AREA_WAR_HANG_UP_REWARD_COUNT_CHANGE)
        XEventManager.DispatchEvent(XEventId.EVENT_AREA_WAR_HANG_UP_REWARD_COUNT_CHANGE)
    end

    --检查挂机解锁弹窗是否需要弹出（存Cookie，只弹一次）
    function XAreaWarManager.CheckHangUpUnlockPopUp()
        if not XAreaWarManager.IsHangUpUnlock() then
            return false
        end
        return not XAreaWarManager.CheckCookieExist(_HangUpUnlockCookieKey)
    end

    --设置首次解锁弹窗Cookie
    function XAreaWarManager.SetHangUpUnlockPopUpCookie()
        XAreaWarManager.SetCookie(_HangUpUnlockCookieKey)
    end

    --挂机收益功能是否解锁
    function XAreaWarManager.IsHangUpUnlock()
        return XAreaWarManager.GetHangUpLevel() > 0
    end

    --获取当前挂机等级
    function XAreaWarManager.GetHangUpLevel()
        local level = 0
        local ids = XAreaWarConfigs.GetAllHangUpIds()
        for _, id in ipairs(ids) do
            if not XAreaWarManager.IsHangUpLevelUnlock(id) then
                break
            end
            level = id
        end
        return level
    end

    --指定挂机等级是否解锁
    function XAreaWarManager.IsHangUpLevelUnlock(id)
        local blockId = XAreaWarConfigs.GetHangUpUnlockBlockId(id)
        if not XTool.IsNumberValid(blockId) then
            return true
        end
        return XAreaWarManager.IsBlockClear(blockId)
    end

    --是否有挂机奖励可以领取（只用于是否向服务端请求最新数量）
    function XAreaWarManager.HasHangUpRewardRemind()
        return _HangUpRewardFlag
    end

    --是否有挂机奖励可以领取
    function XAreaWarManager.HasHangUpRewardToGet()
        return XAreaWarManager.GetHangUpRewardCount() > 0
    end

    --获取挂机奖励物品数量
    function XAreaWarManager.GetHangUpRewardCount()
        return _HangUpRewardCount
    end

    --通知挂机奖励物品数量变更
    function XAreaWarManager.NotifyAreaWarHangUpReward(data)
        UpdateHangUpRewardFlag(data.HangUpRewardCount)
    end

    --打开挂机收益界面
    function XAreaWarManager.OpenUiHangUp()
        if not XAreaWarManager.IsHangUpUnlock() then
            XUiManager.TipText("AreaWarHangUpLock")
            return
        end
        local asyncReq = asynTask(XAreaWarManager.AreaWarOpenHangUpRequest)
        RunAsyn(
            function()
                asyncReq()
                XLuaUiManager.Open("UiAreaWarHangUp")
            end
        )
    end

    --请求挂机收益奖励最新数量
    function XAreaWarManager.AreaWarOpenHangUpRequest(cb)
        XNetwork.Call(
            "AreaWarOpenHangUpRequest",
            nil,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateHangUpRewardCount(res.Count)

                if cb then
                    cb()
                end
            end
        )
    end

    --请求领取挂机收益
    function XAreaWarManager.AreaWarGetHangUpRewardRequest(cb)
        XNetwork.Call(
            "AreaWarGetHangUpRewardRequest",
            nil,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateHangUpRewardFlag(0)
                UpdateHangUpRewardCount(0)

                local rewardGoods = res.RewardGoods
                if cb then
                    cb(rewardGoods)
                end
            end
        )
    end
    -----------------挂机收益 end------------------
    -----------------历史记录 begin------------------
    local XAreaWarRecord = require("XEntity/XAreaWar/XAreaWarRecord")

    local _HistoryRecord = {} --历史奖励汇总（已经弹窗展示过）
    local _NewRecord = {} --最新奖励（需要弹窗展示）

    local function InitRecord()
        _HistoryRecord = XAreaWarRecord.New()
        _NewRecord = XAreaWarRecord.New()
    end

    --更新历史奖励记录
    local function UpdateHistroyRcord(data)
        _HistoryRecord:UpdateData(data)
    end

    --清除已经弹窗展示过的最新记录
    function XAreaWarManager.ClearNewRecord()
        _NewRecord:Clear()
    end

    --更新最新净化的区块Id记录
    function XAreaWarManager.UpdateNewClearBlockId(blockId)
        if _HistoryRecord:CheckblockIdExist(blockId) then
            return
        end
        _NewRecord:RecordBlockId(blockId)
    end

    --获取需要弹窗展示的最新净化区块奖励列表
    function XAreaWarManager.GetRecordNewClearBlockRewards()
        local allRewards = {}

        local blockIdDic = _NewRecord:GetBlockIdDic()
        for blockId in pairs(blockIdDic) do
            local rewardId = XAreaWarConfigs.GetBlockShowRewardId(blockId)
            if XTool.IsNumberValid(rewardId) then
                tableInsert(allRewards, XRewardManager.GetRewardList(rewardId))
            end
        end

        allRewards = XTool.MergeArray(tableUnpack(allRewards))
        allRewards = XRewardManager.MergeAndSortRewardGoodsList(allRewards)

        return allRewards
    end

    --获取弹窗展示的净化区块数（老）、净化区块数（新）
    function XAreaWarManager.GetRecordClearBlockCount()
        local clearCount = XAreaWarManager.GetBlockProgress()
        return _HistoryRecord:GetClearBlockCount(), clearCount
    end

    --获取弹窗展示的解锁角色数（老）、解锁角色数（新）
    function XAreaWarManager.GetRecordUnlockSpecialRoleCount()
        local unlockCount = XAreaWarManager.GetSpecialRoleProgress()
        return _HistoryRecord:GetUnlockSpecialRoleCount(), unlockCount
    end

    --检查是否有未弹窗展示过的最新净化的区块Id记录
    function XAreaWarManager.CheckHasNewClearBlockId()
        return not XTool.IsTableEmpty(_NewRecord:GetBlockIdDic())
    end

    --获取未弹窗展示过的最新解锁的区块Id记录
    function XAreaWarManager.GetNewUnlockBlockIdDic()
        local blockIdDic = {}

        local fightingBlockIds = XAreaWarManager.GetFightingBlockIds()
        for index, blockId in pairs(fightingBlockIds) do
            local keyStr = XAreaWarManager.GetCookieKey(blockId)
            if not XAreaWarManager.CheckCookieExist(keyStr) then
                blockIdDic[blockId] = blockId
            end
        end

        return blockIdDic
    end
    
    local IgnorePlayBlockId = {
        [1] = 1, --屏蔽初始关
        [2] = 2, --屏蔽第二关
    }
    function XAreaWarManager.GetNotPlayUnlockAnimBlockIds()
        local ids = {}
        local playId = 0
        local chapterIds = XAreaWarConfigs.GetChapterIds()
        for _, chapterId in ipairs(chapterIds) do
            if XAreaWarManager.IsChapterUnlock(chapterId) then
                local blockIds = XAreaWarConfigs.GetBlockIdsByChapterId(chapterId)
                for _, blockId in ipairs(blockIds) do
                    if not IgnorePlayBlockId[blockId] and XAreaWarManager.IsBlockUnlock(blockId) then
                        local key = XAreaWarManager.GetCookieKey("UnlockAnim" .. blockId)
                        if not XAreaWarManager.CheckCookieExist(key) then
                            table.insert(ids, blockId)
                            playId = math.max(playId, blockId)
                        end
                    end
                end
            end
        end
        return playId, ids
    end
    
    function XAreaWarManager.MarkPlayUnlockAnimBlockId(blockId)
        local key = XAreaWarManager.GetCookieKey("UnlockAnim" .. blockId)
        if XAreaWarManager.CheckCookieExist(key) then
            return
        end
        XAreaWarManager.SetCookie(key, 1)
    end
    
    local IgnorePlayPlateId = {
        [1] = 1, --屏蔽第一板块
        [2] = 2, --屏蔽第二板块
    }
    local _PlateUpAnimKey = "PlateUpAnimKey"
        function XAreaWarManager.CheckIsPlayPlateAnim(plateId)
        if IgnorePlayPlateId[plateId] then
            return false
        end
        if not XAreaWarManager.IsPlateUnlock(plateId) then
            return false
        end
        local key = XAreaWarManager.GetCookieKey(_PlateUpAnimKey .. plateId)
        if not XAreaWarManager.CheckCookieExist(key) then
            return true
        end
        return false
    end
    
    function XAreaWarManager.MarkPlayPlateAnim(plateId)
        if IgnorePlayPlateId[plateId] then
            return
        end
        if not XAreaWarManager.IsPlateUnlock(plateId) then
            return
        end
        local key = XAreaWarManager.GetCookieKey(_PlateUpAnimKey .. plateId)
        if XAreaWarManager.CheckCookieExist(key) then
            return
        end
        XAreaWarManager.SetCookie(key, true)
    end
    
    local _PopupRewardKey = "PopupRewardKey"
    function XAreaWarManager.CheckNeedPopReward()
        local key = XAreaWarManager.GetCookieKey(_PopupRewardKey)
        if not XSaveTool.GetData(key) then
            return true
        end
        local recordTime = XSaveTool.GetData(key)
        local nextPopTime = XTime.GetSeverNextRefreshTime()
        return recordTime ~= nextPopTime
    end
    
    function XAreaWarManager.MarkPopReward()
        local key = XAreaWarManager.GetCookieKey(_PopupRewardKey)
        local recordTime = XSaveTool.GetData(key)
        local nextPopTime = XTime.GetSeverNextRefreshTime()
        if recordTime == nextPopTime then
            return
        end
        XSaveTool.SaveData(key, nextPopTime)
    end

    function XAreaWarManager.SetNewUnlockBlockIdDicCookie(blockIdDic)
        for blockId in pairs(blockIdDic) do
            local keyStr = XAreaWarManager.GetCookieKey(blockId)
            XAreaWarManager.SetCookie(keyStr, 1)
        end
    end

    --更新最新解锁的角色Id记录
    function XAreaWarManager.UpdateNewUnlockRoleId(roleId)
        if not XTool.IsNumberValid(roleId) then
            return
        end
        if _HistoryRecord:CheckRoleIdExist(roleId) then
            return
        end
        _NewRecord:RecordRoleId(roleId)
    end

    --获取弹窗展示的新解锁特攻角色Id列表
    function XAreaWarManager.GetRecordSpecialRoleIds()
        return _NewRecord:GetSpecialRoleIds()
    end

    --检查是否有未弹窗展示过的新解锁特攻角色
    function XAreaWarManager.CheckHasRecordSpecialRole()
        return not XTool.IsTableEmpty(XAreaWarManager.GetRecordSpecialRoleIds())
    end

    --更新最新净化等级记录
    function XAreaWarManager.UpdateNewPurificationLevel(level)
        if _HistoryRecord:CheckPurificationLvExist(level) then
            return
        end
        _NewRecord:RecordPurificationLv(level)
    end

    --获取弹窗展示的净化等级（老）、净化等级（新）
    function XAreaWarManager.GetRecordPurificationLevel()
        return _HistoryRecord:GetPurificationLevel(), _NewRecord:GetPurificationLevel()
    end

    --检查是否有未弹窗展示过的净化等级变更
    function XAreaWarManager.CheckHasRecordPfLevel()
        local oldLv, newLv = XAreaWarManager.GetRecordPurificationLevel()
        return newLv > 0 and oldLv ~= newLv
    end

    --请求更新历史记录
    function XAreaWarManager.AreaWarPopupRequest(cb)
        XNetwork.Call(
            "AreaWarPopupRequest",
            nil,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateHistroyRcord(res.PopupRecord)

                if cb then
                    cb()
                end
            end
        )
    end
    -----------------历史记录 end------------------
    -----------------区块相关 begin------------------
    local XAreaWarBlock = require("XEntity/XAreaWar/XAreaWarBlock")

    local _BlockDic = {} --全区块信息

    local function GetBlock(blockId)
        if not XTool.IsNumberValid(blockId) then
            XLog.Error("XAreaWarManager GetBlock error: 获取区块信息失败, blockId: ", blockId)
            return
        end

        local block = _BlockDic[blockId]
        if not block then
            block = XAreaWarBlock.New(blockId)
            _BlockDic[blockId] = block
        end
        return block
    end
    XAreaWarManager.GetBlock = GetBlock

    local function UpdateBlock(data)
        local blockId = data.BlockId
        GetBlock(blockId):UpdateData(data)
    end

    local function UpdataBlocks(data)
        for _, info in pairs(data) do
            UpdateBlock(info)
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE)
    end

    local function UpdateBlockSelfPurification(data)
        local blockId = data.BlockId
        GetBlock(blockId):UpdateBlockSelfPurification(data.Purification)
    end

    --更新我的所有区块净化贡献
    local function UpdateBlockSelfPurifications(data)
        for _, info in pairs(data) do
            UpdateBlockSelfPurification(info)
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_AREA_WAR_SELF_BLOCK_PURIFICATION_CHANGE)
    end

    --净化区块
    local function UpdateClearedBlock(blockId)
        local block = GetBlock(blockId)

        --净化度设置为最大值
        block:SetPurificationMax()

        --检查新解锁区块
        XAreaWarManager.UpdateNewClearBlockId(blockId)

        --检查新解锁特攻角色
        local unlockRoleId = XAreaWarConfigs.GetUnlockSpecialRoleIdByBlockId(blockId)
        XAreaWarManager.UnlockSpecialRole(unlockRoleId)

        --检查灯塔类型
        if XAreaWarConfigs.CheckBlockShowType(blockId, XAreaWarConfigs.BlockShowType.NormalBeacon) then
            --照亮整个区域内所有区块
            local chapterId = XAreaWarConfigs.GetBlockChapterId(blockId)
            local blockIds = XAreaWarConfigs.GetBlockIdsByChapterId(chapterId)
            for _, inBlockId in pairs(blockIds) do
                GetBlock(inBlockId):LightUp()
            end
        end
    end

    --更新已净化区块
    local function UpdateClearedBlocks(blockIds)
        for _, blockId in pairs(blockIds or {}) do
            UpdateClearedBlock(blockId)
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE)
    end

    --区块是否解锁（前置区块净化且达到开放时间）
    function XAreaWarManager.IsBlockUnlock(blockId)
        local passed = false

        if not XTool.IsNumberValid(blockId) then
            return false
        end

        --判断前置区块是否通关
        local alternativeList = XAreaWarConfigs.GetBlockPreBlockIdsAlternativeList(blockId)
        if XTool.IsTableEmpty(alternativeList) then
            passed = true
        else
            for _, preIds in pairs(alternativeList) do
                local allClear = true
                for _, preId in pairs(preIds) do
                    if not XAreaWarManager.IsBlockClear(preId) then
                        allClear = false
                        break
                    end
                end
                if allClear then
                    passed = true
                    break
                end
            end
        end
        if not passed then
            return false
        end

        --判断区块开放时间
        if XAreaWarManager.GetBlockUnlockLeftTime(blockId) > 0 then
            return false
        end

        return true
    end

    --获取区块前置区块未解锁提示文本
    function XAreaWarManager.GetBlockUnlockTips(blockId)
        local needTip = true

        local alternativeList = XAreaWarConfigs.GetBlockPreBlockIdsAlternativeList(blockId)

        --如果已经满足前置区块解锁条件，则不需要提示
        for _, preIds in pairs(alternativeList) do
            local allClear = true
            local blockStr = ""
            for _, preId in pairs(preIds) do
                if not XAreaWarManager.IsBlockClear(preId) then
                    allClear = false
                    break
                end
            end
            if allClear then
                needTip = false
                break
            end
        end
        if not needTip then
            return false, ""
        end

        --拼凑出包含所有前置区块的提示文本（e.g.完成区块1，区块2或完成区块3 区块4 解锁）
        local totalBlockStr
        for _, preIds in pairs(alternativeList) do
            local blockStr
            for _, preId in pairs(preIds) do
                if not blockStr then
                    blockStr = XAreaWarConfigs.GetBlockNameEn(preId)
                else
                    blockStr = blockStr .. "," .. XAreaWarConfigs.GetBlockNameEn(preId)
                end
            end

            if not totalBlockStr then
                totalBlockStr = blockStr
            else
                totalBlockStr = totalBlockStr .. CsXTextManagerGetText("AreaWarBlockLockTipsOr", blockStr)
            end
        end

        return needTip, CsXTextManagerGetText("AreaWarBlockLockTips", totalBlockStr)
    end

    --获取区块解锁剩余时间(s)
    function XAreaWarManager.GetBlockUnlockLeftTime(blockId)
        return XAreaWarConfigs.GetBlockOpenSeconds(blockId)
    end

    --获取区块解锁时间戳（活动开启时间 + 配置延迟时间）
    function XAreaWarManager.GetBlockUnlockTime(blockId)
        if not XTool.IsNumberValid(blockId) then
            return 0
        end

        --local startTime = XAreaWarManager.GetStartTime()
        --if not XTool.IsNumberValid(startTime) then
        --    return 0
        --end
        --return XAreaWarConfigs.GetBlockOpenSeconds(blockId)
        local chapterId = XAreaWarConfigs.GetBlockChapterId(blockId)
        local timeId = XAreaWarConfigs.GetChapterTimeId(chapterId)
        return XFunctionManager.GetStartTimeByTimeId(timeId)
    end

    --获取区块进度（已净化区块，总区块）
    function XAreaWarManager.GetBlockProgress()
        local clearCount, totalCount = 0, 0
        local blockIds = XAreaWarConfigs.GetAllBlockIds()
        for _, blockId in pairs(blockIds) do
            --初始区块不算入净化进度
            if not XAreaWarConfigs.IsInitBlock(blockId) then
                if XAreaWarManager.IsBlockClear(blockId) then
                    clearCount = clearCount + 1
                end
                totalCount = totalCount + 1
            end
        end
        return clearCount, totalCount
    end
    
    --章节进度
    function XAreaWarManager.GetChapterProgress(chapterId)
        local blockIds = XAreaWarConfigs.GetBlockIdsByChapterId(chapterId) or {}
        local value, total = 0, 0
        for _, blockId in pairs(blockIds) do
            --初始区块不算入净化进度
            if XAreaWarConfigs.IsInitBlock(blockId) then
                goto continue
            end
            local block = XAreaWarManager.GetBlock(blockId)
            if not block then
                goto continue
            end
            value = value + block:GetProgress()
            total = total + 1
            ::continue::
        end

        if total == 0 then
            return 0
        end
        return math.min(1, value / total)
    end

    --区块是否净化
    function XAreaWarManager.IsBlockClear(blockId)
        --初始区块不算作被净化
        if XAreaWarConfigs.IsInitBlock(blockId) then
            return true
        end

        local requirePurification = XAreaWarConfigs.GetBlockRequirePurification(blockId)

        --如果未配置需求净化度, 通过区块是否解锁判断净化
        if not XTool.IsNumberValid(requirePurification) then
            return XAreaWarManager.IsBlockUnlock(blockId)
        end

        --判断区块净化度是否达到需求净化度
        local block = GetBlock(blockId)
        return block:GetPurification() >= requirePurification
    end

    --区块是否可见
    function XAreaWarManager.IsBlockVisible(blockId)
        if not XTool.IsNumberValid(blockId) then
            return false
        end
        --已解锁区块均可见
        if XAreaWarManager.IsBlockUnlock(blockId) then
            return true
        end
        --灯塔和BOSS区块类型均可见
        --if
        --    XAreaWarConfigs.CheckBlockShowType(blockId, XAreaWarConfigs.BlockShowType.NormalBeacon) or
        --        XAreaWarConfigs.CheckBlockShowType(blockId, XAreaWarConfigs.BlockShowType.WorldBoss) or
        --        XAreaWarConfigs.CheckBlockShowType(blockId, XAreaWarConfigs.BlockShowType.NormalBoss)
        -- then
        --    return true
        --end
        --只显示灯塔
        if XAreaWarConfigs.CheckBlockShowType(blockId, XAreaWarConfigs.BlockShowType.NormalBeacon) then
            return true
        end
        --板块区域解锁
        local plateId = XAreaWarConfigs.GetPlateIdByBlockId(blockId)
        if plateId and plateId > 0 and XAreaWarManager.IsPlateUnlock(plateId) then
            return XAreaWarManager.IsPlateUnlock(plateId)
        end
        --特殊条件下未解锁区块也可见（受灯塔影响）
        return GetBlock(blockId):IsVisible()
    end

    --获取所有可见区块Id
    function XAreaWarManager.GetVisibleBlockIds()
        local visibleblockIds = {}
        local blockIds = XAreaWarConfigs.GetAllBlockIds()
        for _, blockId in pairs(blockIds) do
            if XAreaWarManager.IsBlockVisible(blockId) then
                tableInsert(visibleblockIds, blockId)
            end
        end
        return visibleblockIds
    end

    function XAreaWarManager.GetFightingBlockIds()
        local fightingBlockIds = {}
        local blockIds = XAreaWarConfigs.GetAllBlockIds()
        for _, blockId in ipairs(blockIds) do
            if XAreaWarManager.IsBlockFighting(blockId) then
                tableInsert(fightingBlockIds, blockId)
            end
        end
        return fightingBlockIds
    end

    --获取指定区块Id的下一个正在战斗中的区块Id
    function XAreaWarManager.GetNextFightingBlockId(blockId)
        local fightingBlockIds = XAreaWarManager.GetFightingBlockIds()
        if #fightingBlockIds <= 1 then
            return fightingBlockIds[1]
        end

        local findIndex = 0
        for index, inBlockId in pairs(fightingBlockIds) do
            if inBlockId == blockId then
                findIndex = index
                break
            end
        end

        return fightingBlockIds[findIndex + 1] or fightingBlockIds[1]
    end

    --区块是否挑战中(已解锁 && 未净化)
    function XAreaWarManager.IsBlockFighting(blockId)
        if not XTool.IsNumberValid(blockId) then
            return false
        end
        return XAreaWarManager.IsBlockUnlock(blockId) and not XAreaWarManager.IsBlockClear(blockId)
    end

    --区块是否未开放(未解锁 && 未净化)
    function XAreaWarManager.IsBlockLock(blockId)
        if not XTool.IsNumberValid(blockId) then
            return false
        end
        return not XAreaWarManager.IsBlockUnlock(blockId) and not XAreaWarManager.IsBlockClear(blockId)
    end

    --获取区域世界Boss开启/结束时间戳（开启/结束在区块开启时间后一天，具体在几点读配置）
    function XAreaWarManager.GetBlockWorldBossTime(blockId)
        if not XTool.IsNumberValid(blockId) then
            return 0, 0
        end

        local block = GetBlock(blockId)
        local worldBossOpenTime = block:GetWorldBossOpenTime()
        if not XTool.IsNumberValid(worldBossOpenTime) then
            return 0, 0
        end

        local startHour, endHour = XAreaWarConfigs.GetBlockWorldBossHour(blockId)
        local worldBossEndTime = worldBossOpenTime + (endHour - startHour) * 60 * 60
        return worldBossOpenTime, worldBossEndTime
    end

    --区块世界Boss是否开放
    function XAreaWarManager.IsBlockWorldBossOpen(blockId)
        if not XAreaWarManager.IsBlockUnlock(blockId) then
            return false
        end
        local nowTime = XTime.GetServerNowTimestamp()
        local openTime, endTime = XAreaWarManager.GetBlockWorldBossTime(blockId)
        return openTime <= nowTime and nowTime < endTime
    end

    --区块世界Boss是否结束
    function XAreaWarManager.IsBlockWorldBossFinish(blockId)
        --已经净化
        if XAreaWarManager.IsBlockClear(blockId) then
            return true
        end

        --超过活动结束时间
        local nowTime = XTime.GetServerNowTimestamp()
        local beginTime, endTime = XAreaWarManager.GetBlockWorldBossTime(blockId)
        return XTool.IsNumberValid(beginTime) and nowTime >= endTime
    end

    --请求打开世界Boss界面(UiAreaWarBoss)
    function XAreaWarManager.OpenUiWorldBoss(blockId, closeCb)
        local uiName = XAreaWarConfigs.GetBlockWorldBossUiName(blockId)
        XLuaUiManager.Open(uiName, blockId, closeCb)
    end

    function XAreaWarManager.NotifyAreaWarBlockPurification(data)
        UpdateBlockSelfPurifications(data.BlockPurification)
    end
    
    -----------------区块相关 end------------------
    -----------------排行榜（世界Boss排行/总净化度排行） begin------------------
    local XAreaWarRank = require("XEntity/XAreaWar/XAreaWarRank")

    local _WorldBossBolokRankDic = {} --世界Boss区块排行榜缓存
    local _WorldRank = {} --总净化度世界排行缓存

    local function InitRank()
        _WorldBossBolokRankDic = {}
        _WorldRank = XAreaWarRank.New()
    end

    --更新世界排行
    local function UpdateWorldRank(data)
        _WorldRank:UpdateData(data.RankList, data.MyRankInfo)
    end

    local function GetWorldBossBlockRank(blockId)
        local rank = _WorldBossBolokRankDic[blockId]
        if not rank then
            rank = XAreaWarRank.New()
            _WorldBossBolokRankDic[blockId] = rank
        end
        return rank
    end

    --更新世界Boss区块排行
    local function UpdateWorldBossBlockRank(blockId, data)
        if not XTool.IsNumberValid(blockId) then
            XLog.Error("XAreaWarManager UpdateWorldBossBlockRank error: Invalid blockId: ", blockId)
            return
        end
        GetWorldBossBlockRank(blockId):UpdateData(data.RankList, data.MyRankInfo)
    end

    --请求排行信息（总排行榜blockId发0）
    local function AreaWarOpenRankRequest(blockId, cb)
        local req = {BlockId = blockId or 0}
        XNetwork.Call(
            "AreaWarOpenRankRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                if XTool.IsNumberValid(blockId) then
                    UpdateWorldBossBlockRank(blockId, res)
                else
                    UpdateWorldRank(res)
                end

                if cb then
                    cb()
                end
            end
        )
    end

    --请求查看世界排行信息
    local _CDReqWorldRank = 30 --CD(s)
    local _LastTimeReqWorldRank = 0
    function XAreaWarManager.OpenUiWorldRank(openUiCb)
        --检查CD，未过CD直接使用缓存信息打开界面
        if _LastTimeReqWorldRank + _CDReqWorldRank - XTime.GetServerNowTimestamp() > 0 then
            openUiCb()
            return
        end
        _LastTimeReqWorldRank = XTime.GetServerNowTimestamp()

        AreaWarOpenRankRequest(0, openUiCb)
    end

    --获取世界排行列表
    function XAreaWarManager.GetWorldRankList()
        return _WorldRank:GetRankList()
    end

    --获取世界排行中我的排行信息
    function XAreaWarManager.GetWorldRankGetMyRankItem()
        return _WorldRank:GetMyRankItem()
    end

    --获取世界Boss区块排行列表
    function XAreaWarManager.GetWorldBossBlockRankList(blockId)
        return GetWorldBossBlockRank(blockId):GetRankList()
    end

    --获取世界Boss区块排行中我的排行信息
    function XAreaWarManager.GetWorldBossBlockRankMyRankItem(blockId)
        return GetWorldBossBlockRank(blockId):GetMyRankItem()
    end

    --请求打开世界Boss区块排行界面
    local _CDReqWorldBossBlockRank = 30 --CD(s)
    local _LastTimeReqWorldBossBlockRank = 0
    function XAreaWarManager.OpenUiWorldBossBlockRank(blockId)
        --未开启
        if
            not XDataCenter.AreaWarManager.IsBlockWorldBossOpen(blockId) and
                not XDataCenter.AreaWarManager.IsBlockWorldBossFinish(blockId)
         then
            XUiManager.TipText("AreaWarWorldBossRankNotOpen")
            return
        end

        local openUiCb = function()
            XLuaUiManager.Open("UiAreaWarRankingList", blockId)
        end

        --检查CD，未过CD直接使用缓存信息打开界面
        if _LastTimeReqWorldBossBlockRank + _CDReqWorldBossBlockRank - XTime.GetServerNowTimestamp() > 0 then
            openUiCb()
            return
        end
        _LastTimeReqWorldBossBlockRank = XTime.GetServerNowTimestamp()

        AreaWarOpenRankRequest(blockId, openUiCb)
    end
    -----------------排行榜（世界Boss排行/总净化度排行） end------------------
    -----------------区域相关 begin------------------
    --- 是否鞭尸期
    ---@return boolean
    --------------------------
    function XAreaWarManager.IsRepeatChallengeTime()
        local chapterIds = XAreaWarConfigs.GetChapterIds()
        local chapterCount = #chapterIds
        if chapterCount <= 0 then
            return false
        end
        for i = chapterCount, 1, -1 do
            local chapterId = chapterIds[i]
            if not XAreaWarConfigs.CheckChapterInTime(chapterId) then
                goto continue
            end
            local blockIds = XAreaWarConfigs.GetBlockIdsByChapterId(chapterId)
            for _, blockId in pairs(blockIds) do
                --非初始关卡 & 未净化
                if not XAreaWarConfigs.IsInitBlock(blockId) and
                        not XAreaWarManager.IsBlockClear(blockId) then
                    return false
                end
            end
            ::continue::
        end

        return true
    end

    --- 所有章节开启
    ---@return boolean
    --------------------------
    function XAreaWarManager.IsAllChapterOpen()
        local chapterIds = XAreaWarConfigs.GetChapterIds()
        local chapterCount = #chapterIds
        if chapterCount <= 0 then
            return true
        end
        for i = chapterCount, 1, -1 do
            local chapterId = chapterIds[i]
            if not XAreaWarManager.IsChapterUnlock(chapterId) then
                return false
            end
        end
        return true
    end

    --- 如果章节没全开启，获取首个未开启的章节Id
    ---@return number
    --------------------------
    function XAreaWarManager.GetFirstNotOpenChapterId()
        local chapterIds = XAreaWarConfigs.GetChapterIds()
        for _, chapterId in ipairs(chapterIds) do
            if not XAreaWarManager.IsChapterUnlock(chapterId) then
                return chapterId
            end
        end
    end

    --- 获取最新解锁章节Id
    ---@return number
    --------------------------
    function XAreaWarManager.GetBranchNewChapterId()
        local chapterIds = XAreaWarConfigs.GetChapterIds()
        local newId = chapterIds[1]
        for _, chapterId in pairs(chapterIds) do
            if not XAreaWarManager.IsChapterUnlock(chapterId) then
                break
            end
            newId = chapterId
        end
        return newId
    end

    --- 获取最新解锁章节名
    ---@return string
    --------------------------
    function XAreaWarManager.GetBranchNewChapterName()
        local chapterId = XAreaWarManager.GetBranchNewChapterId()
        return XAreaWarConfigs.GetChapterName(chapterId)
    end

    --章节是否解锁
    function XAreaWarManager.IsChapterUnlock(chapterId)
        local firstBlockId = XAreaWarConfigs.GetFirstBlockIdInChapter(chapterId)
        if not XAreaWarManager.IsBlockUnlock(firstBlockId) then
            return false
        end
        return XAreaWarConfigs.CheckChapterInTime(chapterId, false)
    end
    
    --区块是否解锁 1.配置的Block全部通关 2.配置的Block全部可见
    function XAreaWarManager.IsPlateUnlock(plateId)
        local unlockBlockIds = XAreaWarConfigs.GetUnlockBlockIds(plateId)
        local unlock = true
        local visible = true
        for _, blockId in pairs(unlockBlockIds) do
            if not XAreaWarManager.IsBlockClear(blockId) then
                unlock = false
            end
            local block = XAreaWarManager.GetBlock(blockId)
            if not block or not block:IsVisible() then
                visible = false
            end
        end
        return unlock or visible
    end
    
    function XAreaWarManager.IsPlateCanPlay(plateId)
        if not XAreaWarManager.IsPlateUnlock(plateId) then
            return false
        end
        local blockIds = XAreaWarConfigs.GetContainBlockIds(plateId)
        for _, blockId in pairs(blockIds) do
            if XAreaWarManager.IsBlockUnlock(blockId) then
                return false
            end
        end
        return true
    end

    --获取区域解锁剩余时间(s)
    function XAreaWarManager.GetChapterUnlockLeftTime(chapterId)
        local timeOfNow = XTime.GetServerNowTimestamp()
        local timeOfBgn = XFunctionManager.GetStartTimeByTimeId(XAreaWarConfigs.GetChapterTimeId(chapterId))
        return math.max(0, timeOfBgn - timeOfNow)
    end
    -----------------区域相关 end------------------
    -----------------特攻角色 begin------------------
    local XRobot = require("XEntity/XRobot/XRobot")

    local _UnlockSpecialRoleIdDic = {} --已解锁特攻角色Id
    local _SpecialRoleGotRewardIdDic = {} --已领取特攻角色奖励Id
    local _SpecialRoleRobots = {} --已解锁特攻角色机器人缓存

    local function GetRobot(robotId)
        local robot = _SpecialRoleRobots[robotId]
        if not robot then
            robot = XRobot.New(robotId)
            _SpecialRoleRobots[robotId] = robot
        end
        return robot
    end

    local function UpdateUnlockSpecialRoles(roleIds)
        for _, roleId in pairs(roleIds or {}) do
            XAreaWarManager.UnlockSpecialRole(roleId)
        end
    end

    local function UpdateUnlockSpecialRoleRewards(rewardIds)
        for _, rewardId in pairs(rewardIds or {}) do
            _SpecialRoleGotRewardIdDic[rewardId] = rewardId
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_AREA_WAR_SPECIAL_ROLE_REWARD_GOT)
    end

    function XAreaWarManager.UnlockSpecialRole(roleId)
        if not XTool.IsNumberValid(roleId) then
            return
        end
        if XAreaWarManager.IsSpecialRoleUnlock(roleId) then
            return
        end
        _UnlockSpecialRoleIdDic[roleId] = roleId
        XAreaWarManager.UpdateNewUnlockRoleId(roleId)
    end

    --打开特攻角色界面
    function XAreaWarManager.OpenUiSpecialRole()
        if not XAreaWarManager.IsAnySpecialRoleUnlock() then
            XUiManager.TipText("AreaWarSpecialRoleLock")
            return
        end
        XLuaUiManager.Open("UiAreaWarSpecialRole")
    end

    --特攻角色是否解锁
    function XAreaWarManager.IsSpecialRoleUnlock(roleId)
        if not XTool.IsNumberValid(roleId) then
            return false
        end
        return _UnlockSpecialRoleIdDic[roleId] and true or false
    end

    --特攻角色功能是否解锁（解锁第一个角色）
    function XAreaWarManager.IsAnySpecialRoleUnlock()
        return XAreaWarManager.GetUnlockSpecialRoleCount() > 0
    end

    --获取已解锁特攻角色数量
    function XAreaWarManager.GetUnlockSpecialRoleCount()
        return XTool.GetTableCount(_UnlockSpecialRoleIdDic)
    end

    --获取特攻角色解锁进度（已解锁，全部）
    function XAreaWarManager.GetSpecialRoleProgress()
        return XAreaWarManager.GetUnlockSpecialRoleCount(), #XAreaWarConfigs.GetAllSpecialRoleIds()
    end

    --特攻角色奖励是否已领取
    function XAreaWarManager.IsSpecialRoleRewardHasGot(rewardId)
        return _SpecialRoleGotRewardIdDic[rewardId] and true or false
    end

    --特攻角色奖励是否可领取
    function XAreaWarManager.IsSpecialRoleRewardCanGet(rewardId)
        local unlockCount = XAreaWarManager.GetUnlockSpecialRoleCount()
        local requireCount = XAreaWarConfigs.GetSpecialRoleRewardUnlockCount(rewardId)
        return unlockCount >= requireCount
    end

    --是否有特攻角色奖励可领取
    function XAreaWarManager.HasSpecialRoleRewardToGet()
        local rewardIds = XAreaWarConfigs.GetAllSpecialRoleUnlockRewardIds()
        for _, rewardId in pairs(rewardIds) do
            if
                not XAreaWarManager.IsSpecialRoleRewardHasGot(rewardId) and
                    XAreaWarManager.IsSpecialRoleRewardCanGet(rewardId)
             then
                return true
            end
        end
        return false
    end

    --获取可上阵机器人Id（根据已解锁特攻角色索引）
    function XAreaWarManager.GetCanUseRobotIds()
        local robotIds = {}
        local allRoleIds = XAreaWarConfigs.GetAllSpecialRoleIds()
        for _, roleId in pairs(allRoleIds) do
            if XAreaWarManager.IsSpecialRoleUnlock(roleId) then
                local robotId = XAreaWarConfigs.GetSpecialRoleRobotId(roleId)
                if XTool.IsNumberValid(robotId) then
                    tableInsert(robotIds, robotId)
                end
            end
        end
        return robotIds
    end

    --获取可上阵机器人（根据已解锁特攻角色索引）
    function XAreaWarManager.GetCanUseRobots()
        local robotIds = {}
        local allRoleIds = XAreaWarConfigs.GetAllSpecialRoleIds()
        for _, roleId in pairs(allRoleIds) do
            if XAreaWarManager.IsSpecialRoleUnlock(roleId) then
                local robotId = XAreaWarConfigs.GetSpecialRoleRobotId(roleId)
                if XTool.IsNumberValid(robotId) then
                    tableInsert(robotIds, GetRobot(robotId))
                end
            end
        end
        return robotIds
    end

    --获取指定区域解锁特攻角色解锁进度（return:已解锁，全部）
    function XAreaWarManager.GetAreaSpecialRolesUnlockProgress(areaId)
        local unlockCount, totalCount = 0, 0
        local roleIds = XAreaWarConfigs.GetChapterSpecialRoleIds(areaId)
        for _, roleId in ipairs(roleIds) do
            if XAreaWarManager.IsSpecialRoleUnlock(roleId) then
                unlockCount = unlockCount + 1
            end
            totalCount = totalCount + 1
        end
        return unlockCount, totalCount
    end

    --请求领取特攻角色奖励
    function XAreaWarManager.AreaWarGetSpecialRoleRewardRequest(rewardId, cb)
        local req = {RewardIndex = rewardId}
        XNetwork.Call(
            "AreaWarGetSpecialRoleRewardRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateUnlockSpecialRoleRewards({rewardId})

                if cb then
                    cb(res.RewardGoodsList)
                end
            end
        )
    end
    -----------------特攻角色 end------------------
    -----------------派遣 begin------------------
    local XTeam = require("XEntity/XTeam/XTeam")

    local _DispatchConditionDic = {} --派遣条件（由服务端随机，和blockId绑定，当前区块条件未派遣成功之前不会改变，但不影响其他区块）
    local _DispatchTeamKey = "_DispatchTeamKey"
    local _DispatchTeam  --派遣队伍

    local function CheckDispatchConditionExist(blockId)
        return not XTool.IsTableEmpty(_DispatchConditionDic[blockId])
    end

    local function UpdateDispatchCondition(blockId, conditions)
        _DispatchConditionDic[blockId] = conditions
    end

    --获取当前区块派遣条件
    function XAreaWarManager.GetDispatchConditions(blockId)
        return _DispatchConditionDic[blockId] or {}
    end

    --检查指定角色是否满足当前区块派遣条件
    function XAreaWarManager.CheckDispatchConditionsFitCharacter(blockId, characterId)
        --2.5 版本去除角色条件判断
        --local conditionIdCheckDic = XAreaWarConfigs.GetDispatchCharacterCondtionIdCheckDic({characterId})
        --local conditionIds = XAreaWarManager.GetDispatchConditions(blockId)
        --for _, conditionId in pairs(conditionIds) do
        --    if conditionIdCheckDic[conditionId] then
        --        return true
        --    end
        --end
        --return false
        return true
    end

    --获取派遣队伍缓存
    function XAreaWarManager.GetDispatchTeam()
        local teamId = XAreaWarManager.GetCookieKey(_DispatchTeamKey)
        
        --如果缓存为空，则找其他数据
        if not _DispatchTeam then
            --首先找队伍本地数据
            local localXTeam=XTeam.New(teamId)
            --判断本地数据是否存在
            if not localXTeam:GetIsEmpty() then
                _DispatchTeam=localXTeam
            else
                --获取作战队伍配置
                _DispatchTeam=XAreaWarManager.GetTeam()
            end
        end
        
        return _DispatchTeam
    end
    
    function XAreaWarManager.SaveTeam()
        if not _DispatchTeam then
            return
        end
        _DispatchTeam:Save()
    end

    function XAreaWarManager.ClearDispatchTeam()
        if not _DispatchTeam then
            return
        end
        _DispatchTeam:Clear()
    end

    --请求派遣条件（服务端）
    local function AreaWarOpenDetachRequest(blockId, cb)
        local req = {BlockId = blockId}
        XNetwork.Call(
            "AreaWarOpenDetachRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateDispatchCondition(blockId, res.Conditions)

                if cb then
                    cb()
                end
            end
        )
    end

    --请求打开派遣界面
    function XAreaWarManager.OpenUiDispatch(blockId)
        --检查消耗体力
        local costCount = XAreaWarConfigs.GetBlockDetachActionPoint(blockId)
        if not XDataCenter.AreaWarManager.CheckActionPoint(costCount) then
            XUiManager.TipText("AreaWarActionPointNotEnought")
            return
        end

        if XLuaUiManager.IsUiShow("UiAreaWarDispatch") or XLuaUiManager.IsUiLoad("UiAreaWarDispatch") then
            return
        end

        XLuaUiManager.Open("UiAreaWarDispatch", blockId)
        
    end

    --请求派遣(robotIds为上阵特攻角色对应的robotId，characterIds为上阵的自己拥有成员的characterId)
    function XAreaWarManager.AreaWarDetachRequest(blockId, characterIds, robotIds, cb)
        local req = {BlockId = blockId, CardIds = characterIds, RobotIds = robotIds}
        XNetwork.Call(
            "AreaWarDetachRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateDispatchCondition(blockId, nil)

                if cb then
                    cb(res.RewardGoodsList)
                end
            end
        )
    end
    -----------------派遣 end------------------
    ---------------------副本相关 begin------------------
    local _TeamCookieKey = "_TeamCookieKey" --编队Cookie

    function XAreaWarManager.InitStageInfo()
        XAreaWarManager.InitStageType()
        --XAreaWarManager.RegisterEditBattleProxy()
    end

    function XAreaWarManager.InitStageType()
        local stageIds = XAreaWarConfigs.GetAllBlockStageIds()
        for _, stageId in pairs(stageIds) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.AreaWar
            end
        end
    end
    
    ---@return XTeam
    function XAreaWarManager.GetTeam()
        ---@type XTeam
        local team = XAreaWarManager.GetCookie(_TeamCookieKey)
        if not team then
            team = XTeam.New(XAreaWarManager.GetCookieKey(_TeamCookieKey))
        end
        local lookUpTable = {}
        
        local robotIdList = XAreaWarManager.GetCanUseRobotIds()
        for _, id in pairs(robotIdList) do
            lookUpTable[id] = id
        end

        for index, id in pairs(team:GetEntityIds()) do
            if XRobotManager.CheckIsRobotId(id) then
                if not XTool.IsNumberValid(lookUpTable[id]) then
                    team:UpdateEntityTeamPos(0, index, true)
                end
            else
                --清库之后本地缓存角色失效
                if not XMVCA.XCharacter:IsOwnCharacter(id) then
                    team:UpdateEntityTeamPos(0, index, true)
                end
            end
        end
        
        return team
    end
    
    --- 替换战斗前获取数据方法
    function XAreaWarManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        local preFight = {
            CardIds  ={0, 0, 0},
            RobotIds = {0, 0, 0},
            StageId = stage.StageId,
            IsHasAssist = isAssist and true or false,
            ChallengeCount = challengeCount or 1,
            CaptainPos = 0,
            FirstFightPos = 0,
        }
        
        local robotIds = stage.RobotId
        -- 教学关适配
        if not XTool.IsTableEmpty(robotIds) then
            for i, id in ipairs(preFight.RobotIds) do
                local robotId = robotIds[i]
                if XTool.IsNumberValid(robotId) then
                    preFight.CaptainPos = i
                    preFight.FirstFightPos = i
                    preFight.RobotIds[i] = robotId
                else
                    preFight.RobotIds[i] = 0
                end
            end
        else
            local team = XAreaWarManager.GetTeam()
            local entities = team:GetEntityIds()
            for pos, id in pairs(entities) do
                if XRobotManager.CheckIsRobotId(id) then
                    preFight.RobotIds[pos] = id
                else
                    preFight.CardIds[pos] = id
                end
            end
            preFight.FirstFightPos = team:GetFirstFightPos()
            preFight.CaptainPos = team:GetCaptainPos()
        end
        
        return preFight
    end

    --请求作战（打开编队界面）
    function XAreaWarManager.TryEnterFight(blockId)
        local costActionPoint = XAreaWarConfigs.GetBlockActionPoint(blockId)
        if not XAreaWarManager.CheckActionPoint(costActionPoint) then
            XUiManager.TipText("AreaWarActionPointNotEnought")
            return
        end

        local stageId = XAreaWarConfigs.GetBlockStageId(blockId)
        --XLuaUiManager.Open("UiBattleRoleRoom", stageId)
        XLuaUiManager.Open(
                "UiBattleRoleRoom", 
                stageId, 
                XAreaWarManager.GetTeam(), 
                require("XUi/XUiAreaWar/XUiAreaWarBattleRoleRoom")
        )
    end

    -- 获取能够参战的角色数据
    -- return : XCharacter/XRobot混合列表
    function XAreaWarManager.GetCanFightEntities(characterType)
        local result = {}

        local characters = XMVCA.XCharacter:GetOwnCharacterList() --自己拥有的角色
        for _, character in ipairs(characters) do
            if character:GetCharacterViewModel():GetCharacterType() == characterType then
                tableInsert(result, character)
            end
        end

        local robots = XAreaWarManager.GetCanUseRobots() --特攻角色机器人
        for _, character in ipairs(robots) do
            if character:GetCharacterViewModel():GetCharacterType() == characterType then
                tableInsert(result, character)
            end
        end

        return result
    end

    function XAreaWarManager.ShowReward(winData)
        XLuaUiManager.Open("UiAreaWarFightResult", winData)
    end

    --确认战斗结果
    function XAreaWarManager.AreaWarConfirmFightResultRequest(stageId, cb)
        local req = {StageId = stageId}
        XNetwork.Call(
            "AreaWarConfirmFightResultRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                local rewardGoods = res.RewardGoods
                if cb then
                    cb(rewardGoods)
                end
            end
        )
    end
    ---------------------副本相关 end------------------
    -----------------Cookie begin------------------
    function XAreaWarManager.GetCookieKey(keyStr)
        if not keyStr then
            return
        end
        if not XTool.IsNumberValid(_ActivityId) then
            return
        end
        return stringFormat("XAreaWarManager_%d_%d_%s", XPlayer.Id, _ActivityId, keyStr)
    end

    --检查Cookie是否存在
    function XAreaWarManager.CheckCookieExist(keyStr)
        return XAreaWarManager.GetCookie(keyStr) and true or false
    end

    --获取Cookie
    function XAreaWarManager.GetCookie(keyStr)
        local key = XAreaWarManager.GetCookieKey(keyStr)
        if not key then
            return
        end
        return XSaveTool.GetData(key)
    end

    --设置Cookie
    function XAreaWarManager.SetCookie(keyStr, value)
        local key = XAreaWarManager.GetCookieKey(keyStr)
        if not key then
            return
        end
        value = value or 1
        XSaveTool.SaveData(key, value)
    end
    -----------------Cookie end------------------
    
    function XAreaWarManager.CheckIsFirstPlay()
        local key = XAreaWarManager.GetCookieKey("FirstPlayAreaWar")
        --非首次
        if XSaveTool.GetData(key) then
            return false
        end
        return true
    end
    
    function XAreaWarManager.MarkFirstPlay()
        local key = XAreaWarManager.GetCookieKey("FirstPlayAreaWar")
        if XSaveTool.GetData(key) then
            return
        end
        XSaveTool.SaveData(key, true)
    end
    
    --region   ------------------全服战况 start-------------------
    local XAreaWarArticleGroup = require("XEntity/XAreaWar/XAreaWarArticleGroup")
    ---@type table<number, XAreaWarArticleGroup>
    local _AreaWarArticleGroup = {}
    local _LikedArticleMap
    local _LastRequestOpenArticle = 0
    local _RequestOpenArticleTimeInterval = 2
    
    local _AreaWarArticleKey = "AreaWarArticleKey_"
    
    local InitArticleGroup = function()
        local map = XAreaWarConfigs.GetArticleGroupMap()
        for groupId in pairs(map) do
            _AreaWarArticleGroup[groupId] = XAreaWarArticleGroup.New(groupId)
        end
    end
    
    --打开全服战况
    function XAreaWarManager.RequestWarLog(cb)
        local timeOfNow = XTime.GetServerNowTimestamp()
        if timeOfNow - _LastRequestOpenArticle < _RequestOpenArticleTimeInterval then
            if cb then cb() end
            return
        end
        
        XNetwork.Call("AreaWarOpenArticleRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local articleGroups = res.ArticleGroups or {}
            for _, articleGroup in pairs(articleGroups) do
                local group = _AreaWarArticleGroup[articleGroup.GroupId]
                if not group then
                    group = XAreaWarArticleGroup.New(articleGroup.GroupId)
                    _AreaWarArticleGroup[articleGroup.GroupId] = group
                end
                group:Update(articleGroup.IsUnlock, articleGroup.Articles)
            end

            --已点赞的文章列表
            local likeArticles = res.LikeArticleRecord or {}
            _LikedArticleMap = {}
            for _, articleId in pairs(likeArticles) do
                _LikedArticleMap[articleId] = true
            end
            
            --判断有没有文章解锁
            local allLock = true
            for _, group in pairs(_AreaWarArticleGroup) do
                if group:CheckGroupIsUnlock() and not group:IsArticleEmpty() then
                    allLock = false
                    break
                end
            end
            --没有一篇文章解锁
            if allLock then
                XUiManager.TipMsg(XAreaWarConfigs.GetArticleGroupLockTip())
                return
            end
            
            _LastRequestOpenArticle = timeOfNow
            if cb then cb() end
        end)
    end
    
    --请求点赞文章
    function XAreaWarManager.RequestLikeArticle(articleId, cb)
        if not XAreaWarManager.CheckArticleUnlock(articleId) then
            XUiManager.TipMsg(XAreaWarConfigs.GetArticleLockTips())
            return
        end
        local groupId = XAreaWarConfigs.GetArticleGroupId(articleId)
        XNetwork.Call("AreaWarLikeArticleRequest", { ArticleId = articleId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local data = XAreaWarManager.GetArticleData(articleId)
            if data then
                data:Like()
            end
            _LikedArticleMap[articleId] = true
            
            if cb then cb() end
        end)
    end
    
    --文章组是否解锁
    function XAreaWarManager.CheckArticleGroupUnlock(groupId)
        local data = _AreaWarArticleGroup[groupId]
        if not data then
            return false
        end
        return data:CheckGroupIsUnlock()
    end
    
    --文章是否解锁
    function XAreaWarManager.CheckArticleUnlock(articleId)
        local groupId = XAreaWarConfigs.GetArticleGroupId(articleId)
        if not XAreaWarManager.CheckArticleGroupUnlock(groupId) then
            return false
        end
        local blockId, progress = XAreaWarConfigs.GetArticleUnlockBlockIdAndProgress(articleId)
        if XAreaWarConfigs.IsInitBlock(blockId) then
            return true
        end
        local unlock = XAreaWarManager.IsBlockUnlock(blockId)
        if not unlock then
            return false
        end
        local block = XDataCenter.AreaWarManager.GetBlock(blockId)
        if not block then
            return false
        end
        return block:GetPercentProgress() >= progress
    end
    
    --获取文章数据
    function XAreaWarManager.GetArticleData(articleId)
        local groupId = XAreaWarConfigs.GetArticleGroupId(articleId)
        local data = _AreaWarArticleGroup[groupId]
        if not data then
            XLog.Error("获取文章组失败, 文章组数据不存在! GroupId = " .. tostring(groupId))
            return
        end
        return data:GetArticleData(articleId)
    end
    
    function XAreaWarManager.GetUnlockArticleList(groupId)
        local data = _AreaWarArticleGroup[groupId]
        if not data then
            XLog.Error("获取文章组失败, 文章组数据不存在! GroupId = " .. tostring(groupId))
            return
        end
        return data:GetUnlockArticleList()
    end
    
    local function CheckSingleArticle(groupId, articleId)
        local group = _AreaWarArticleGroup[groupId]
        if not group or not group:CheckGroupIsUnlock() then
            return false
        end
        local unlock = XAreaWarManager.CheckArticleUnlock(articleId)
        if not unlock then
            return false
        end
        
        local key = XAreaWarManager.GetCookieKey(_AreaWarArticleKey .. tostring(articleId))
        --已经展示过红点
        if XSaveTool.GetData(key) then
            return false
        end
        
        return true
    end
    
    function XAreaWarManager.CheckIsNewUnlockArticle(articleId)
        if XTool.IsNumberValid(articleId) then
            local groupId = XAreaWarConfigs.GetArticleGroupId(articleId)
            if not XTool.IsNumberValid(groupId) then
                return false
            end
            return CheckSingleArticle(groupId, articleId)
        else
            local map = XAreaWarConfigs.GetArticleGroupMap()
            for groupId, articleIds in pairs(map) do
                for _, articleId in pairs(articleIds) do
                    if CheckSingleArticle(groupId, articleId) then
                        return true
                    end
                end
            end
        end
    end
    
    function XAreaWarManager.CheckIsNewUnlockArticleByGroupId(groupId)
        if not XTool.IsNumberValid(groupId) then
            return false
        end
        local data = _AreaWarArticleGroup[groupId]
        if not data or not data:CheckGroupIsUnlock() then
            return false
        end
        local map = XAreaWarConfigs.GetArticleGroupMap()
        local list = map[groupId] or {}
        for _, articleId in pairs(list) do
            if CheckSingleArticle(groupId, articleId) then
                return true
            end
        end
        
        return false
    end
    
    --标记新解锁
    function XAreaWarManager.MarkNewUnlockArticle(articleId)
        local key = XAreaWarManager.GetCookieKey(_AreaWarArticleKey .. tostring(articleId))
        if XSaveTool.GetData(key) then
            return
        end
        XSaveTool.SaveData(key, true)
    end
    
    --文章是否已经点赞
    function XAreaWarManager.CheckIsLiked(articleId)
        return _LikedArticleMap[articleId] and true or false
    end
    
    --endregion------------------全服战况 finish------------------
    
    function XAreaWarManager:ExGetProgressTip()
        return XAreaWarManager.GetBranchNewChapterName()
    end
    
    local _NewChapterOpenKey = "NewChapterOpenKey_"
    function XAreaWarManager.IsNewChapterOpen()
        local chapterId = XAreaWarManager.GetBranchNewChapterId()
        local key = XAreaWarManager.GetCookieKey(_NewChapterOpenKey .. tostring(chapterId))
        if XSaveTool.GetData(key) then
            return false
        end
        
        return true
    end
    
    function XAreaWarManager.MarkNewChapterOpen()
        local chapterId = XAreaWarManager.GetBranchNewChapterId()
        local key = XAreaWarManager.GetCookieKey(_NewChapterOpenKey .. tostring(chapterId))
        if XSaveTool.GetData(key) then
            return
        end
        
        XSaveTool.SaveData(key, true)
    end

    --检测主界面的引导是否完成，策划需要在引导未完成时，不展示相关弹窗
    function XAreaWarManager.IsMainUiGuideFinish()
        return XDataCenter.GuideManager.CheckIsGuide(MAIN_UI_NEWBIE_GUIDE_ID)
    end
    
    local _NewOpenHelpUi = "NewOpenHelpUi_"
    --当期活动首次打开图文教程
    function XAreaWarManager.IsFirstOpenHelp()
        local key = XAreaWarManager.GetCookieKey(_NewOpenHelpUi)
        if XSaveTool.GetData(key) then
            return false
        end
        return true
    end
    
    function XAreaWarManager.MarkFirstOpenHelp()
        local key = XAreaWarManager.GetCookieKey(_NewOpenHelpUi)
        if XSaveTool.GetData(key) then
            return
        end
        XSaveTool.SaveData(key, true)
    end
    
    --region   ------------------性能测试 start-------------------
    
    function XAreaWarManager.IsPerformanceTesting()
        return XMain.IsDebug and _PerformanceTesting
    end
    
    function XAreaWarManager.SetPerformanceTesting(value)
        if not XMain.IsDebug then
            return
        end
        _PerformanceTesting = value
    end
    --endregion------------------性能测试 finish------------------

    local function ResetData()
        XAreaWarManager.SetActivityEnd()

        _ActivityId = 0 --当前开放活动Id
        _IsOpening = false -- 活动是否开启中（根据服务端下发活动有效Id判断）
        _BlockDic = {} --全区块信息
        _UnlockSpecialRoleIdDic = {} --已解锁特攻角色Id
        _SpecialRoleGotRewardIdDic = {} --已领取特攻角色奖励Id
        _SpecialRoleRobots = {} --已解锁特攻角色机器人缓存
        _HangUpRewardCount = 0 --挂机收益奖励数量（大于0时代表有奖励可领取，实际数量打开界面时请求）
        _HangUpRewardFlag = false --挂机收益奖励数量是否有变更（服务端通知）
        _PluginDic = {} --插件（aka：词缀）信息
        --_PluginSlotDic = {0, 0, 0} --插件槽信息
        _DispatchConditionDic = {} --派遣条件（由服务端随机，和blockId绑定，当前区块条件未派遣成功之前不会改变，但不影响其他区块）
        _DispatchTeam = nil --派遣队伍

        XAreaWarManager.Init()
    end

    local function UpdateActivityData(data)
        if XTool.IsTableEmpty(data) then
            return
        end
        UpdataBlocks(data.BlockInfos)
        UpdateClearedBlocks(data.CleanBlockIds)
        UpdateUnlockSpecialRoles(data.SpecialRole)
        UpdateSelfPurification(data.PurificationLv, data.PurificationExp)
    end

    --登录下发
    function XAreaWarManager.NotifyAreaWarActivityData(data)
        local activityId = data.ActivityNo
        if XTool.IsNumberValid(_ActivityId) and activityId ~= _ActivityId then
            ResetData()
        end

        UpdateActivityId(activityId)
        UpdateHistroyRcord(data.PopupRecord)
        UpdateHangUpRewardFlag(data.HangUpRewardCount)
        UpdateActivityData(data.ActivityData)
        UpdateBlockSelfPurifications(data.BlockPurification)
        UpdateUnlockPlugins(data.UnlockBuffId)
        --UpdateUsingPlugins(data.MountBuff)
        UpdateUnlockSpecialRoleRewards(data.SpecialRoleReward)
    end

    --主动请求活动数据， Code等于success才发
    function XAreaWarManager.AreaWarGetActivityDataRequest(cb)
        local req = nil
        XNetwork.Call(
                "AreaWarGetActivityDataRequest",
                req,
                function(res)
                    if res.Code ~= XCode.Success then
                        return
                    end

                    UpdateActivityData(res.ActivityData)

                    if cb then
                        cb()
                    end
                end
        )
    end

    --有新区块被净化时通知
    function XAreaWarManager.NotifyAreaWarBlockClean(data)
        UpdateClearedBlocks(data.CleanBlockIds)
        UpdateSelfPurification(data.PurificationLv, data.PurificationExp)
    end

    function XAreaWarManager.Init()
        InitSelfPurification()
        InitRecord()
        InitRank()
        InitArticleGroup()
    end

    XAreaWarManager.Init()

    return XAreaWarManager
end
---------------------Notify begin------------------
XRpc.NotifyAreaWarActivityData = function(data)
    XDataCenter.AreaWarManager.NotifyAreaWarActivityData(data)
end

XRpc.NotifyAreaWarBlockClean = function(data)
    XDataCenter.AreaWarManager.NotifyAreaWarBlockClean(data)
end

XRpc.NotifyAreaWarBlockPurification = function(data)
    XDataCenter.AreaWarManager.NotifyAreaWarBlockPurification(data)
end

XRpc.NotifyAreaWarHangUpReward = function(data)
    XDataCenter.AreaWarManager.NotifyAreaWarHangUpReward(data)
end
---------------------Notify end------------------
