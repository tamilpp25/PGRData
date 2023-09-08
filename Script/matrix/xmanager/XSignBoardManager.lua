local XSignBoardCamAnim = require("XEntity/XSignBoard/XSignBoardCamAnim")
local SignBoardCondition = {
    --邮件
    [XSignBoardEventType.MAIL] = function()
        ---@type XMailAgency
        local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
        return mailAgency:GetHasUnDealMail() > 0
    end,

    --任务
    [XSignBoardEventType.TASK] = function()
        if XDataCenter.TaskManager.GetIsRewardForEx(XDataCenter.TaskManager.TaskType.Story) then
            return true
        end

        if XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.TaskDay) and XDataCenter.TaskManager.GetIsRewardForEx(XDataCenter.TaskManager.TaskType.Daily) then
            return true
        end

        if XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.TaskActivity) and XDataCenter.TaskManager.GetIsRewardForEx(XDataCenter.TaskManager.TaskType.Activity) then
            return true
        end

        return false
    end,

    --日活跃
    [XSignBoardEventType.DAILY_REWARD] = function()
        return XDataCenter.TaskManager.CheckHasDailyActiveTaskReward()
    end,

    --登陆
    [XSignBoardEventType.LOGIN] = function(param)
        local loginTime = XDataCenter.SignBoardManager.GetLoginTime()
        local offset = XTime.GetServerNowTimestamp() - loginTime

        return offset <= param
    end,

    --n天没登陆
    [XSignBoardEventType.COMEBACK] = function(param)
        local lastLoginTime = XDataCenter.SignBoardManager.GetlastLoginTime()
        local todayTime = XTime.GetTodayTime()
        local offset = todayTime - lastLoginTime
        local day = math.ceil(offset / 86400)
        return day >= param
    end,

    --收到礼物
    [XSignBoardEventType.RECEIVE_GIFT] = function()
        return false
    end,

    --赠送礼物
    [XSignBoardEventType.GIVE_GIFT] = function(param, displayCharacterId, eventParam)
        if eventParam == nil then
            return false
        end

        return eventParam.CharacterId == displayCharacterId
    end,

    --战斗胜利
    [XSignBoardEventType.WIN] = function()
        local signBoardEvent = XDataCenter.SignBoardManager.GetSignBoardEvent()
        if signBoardEvent[XSignBoardEventType.WIN] then
            return true
        end
    end,

    --战斗胜利
    [XSignBoardEventType.WINBUT] = function()
        local signBoardEvent = XDataCenter.SignBoardManager.GetSignBoardEvent()
        if signBoardEvent[XSignBoardEventType.WINBUT] then
            return true
        end
    end,

    --战斗失败
    [XSignBoardEventType.LOST] = function()
        local signBoardEvent = XDataCenter.SignBoardManager.GetSignBoardEvent()
        if signBoardEvent[XSignBoardEventType.LOST] then
            return true
        end
    end,

    --战斗失败
    [XSignBoardEventType.LOSTBUT] = function()
        local signBoardEvent = XDataCenter.SignBoardManager.GetSignBoardEvent()
        if signBoardEvent[XSignBoardEventType.LOSTBUT] then
            return true
        end
    end,

    --电量
    [XSignBoardEventType.LOW_POWER] = function(param)
        return XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.ActionPoint) <= param
    end,


    --游戏时间
    [XSignBoardEventType.PLAY_TIME] = function(param)
        local loginTime = XDataCenter.SignBoardManager.GetLoginTime()
        local offset = XTime.GetServerNowTimestamp() - loginTime
        return offset >= param
    end,


    --长时间待机
    [XSignBoardEventType.IDLE] = function()
        return true
    end,

    --换人
    [XSignBoardEventType.CHANGE] = function(param, displayCharacterId)
        return displayCharacterId == XDataCenter.SignBoardManager.ChangeDisplayId
    end,

    --好感度提升
    [XSignBoardEventType.FAVOR_UP] = function()
        return true
    end,
}

local REQUEST_NAME = { --请求协议
    ClickRequest = "TouchBoardMutualRequest",
}


--看板互动
XSignBoardManagerCreator = function()
    local XSignBoardManager = {}

    XSignBoardManager.ChangeDisplayId = -1

    XSignBoardManager.ShowType = {
        Normal = 0, --可以重复播放
        PerLogin = 1, --每次登陆只会播放一次
        Daily = 2  --每日只能播放一次
    }

    local LoginTime = -1 --登录时间
    local LastLoginTime = -1 --上次登录时间
    -- local TodayFirstLoginTime = -1 --今天首次登陆时间

    --记录需要做出反馈的事件
    local SignBoarEvents = {}
    --播放器数据
    local PlayerData = nil

    --播放过的
    local PlayedList = {}

    --默认 0 普通待机，1 待机站立
    local StandType = 0

    --这次登陆已经播放过的
    local PreLoginPlayedList = {}


    --初始化
    function XSignBoardManager.Init()


        -- --记录今天首次登陆时间
        -- local key = tostring(XPlayer.Id) .. "_TodayFirstLoginTime"
        -- TodayFirstLoginTime = CS.UnityEngine.PlayerPrefs.GetInt(key, -1)
        -- if TodayFirstLoginTime < XTime.GetTodayTime(5) then
        --     CS.UnityEngine.PlayerPrefs.SetInt(key, TodayFirstLoginTime)
        -- end


        XEventManager.AddEventListener(XEventId.EVENT_LOGIN_SUCCESS, function()
            local key = tostring(XPlayer.Id) .. "_LastLoginTime"
            LastLoginTime = CS.UnityEngine.PlayerPrefs.GetInt(key, -1)
            LoginTime = XTime.GetServerNowTimestamp()
            if LastLoginTime == -1 then
                LastLoginTime = LoginTime
            end
            CS.UnityEngine.PlayerPrefs.SetInt(key, LoginTime)
        end)
    end

    --获取登陆时间
    function XSignBoardManager.GetLoginTime()
        return LoginTime
    end

    --获取上次登陆时间
    function XSignBoardManager.GetlastLoginTime()
        return LastLoginTime
    end

    --获取事件
    function XSignBoardManager.GetSignBoardEvent()
        return SignBoarEvents
    end

    --
    function XSignBoardManager.GetSignBoardPlayerData()
        if not PlayerData then
            PlayerData = {}
            PlayerData.PlayerList = {} --播放列表
            PlayerData.PlayingElement = nil --播放对象
            PlayerData.PlayedList = {} --播放过的列表
            PlayerData.LastPlayTime = -1 --上次播放时间
        end

        return PlayerData
    end


    --监听
    function XSignBoardManager.OnNotify(event, ...)
        if event == XEventId.EVENT_FIGHT_RESULT then
            local displayCharacterId = XDataCenter.DisplayManager.GetDisplayChar().Id

            local settle = ...
            local info = settle[0]
            local isExist = false

            local beginData = XDataCenter.FubenManager.GetFightBeginData()
            if beginData then
                for _, v in pairs(beginData.CharList) do
                    if v == displayCharacterId then
                        isExist = true
                        break
                    end
                end
            end

            if isExist and info.IsWin then
                SignBoarEvents[XSignBoardEventType.WIN] = SignBoarEvents[XSignBoardEventType.WIN] or {}
                SignBoarEvents[XSignBoardEventType.WIN].Time = XTime.GetServerNowTimestamp()
            elseif not isExist and info.IsWin then
                SignBoarEvents[XSignBoardEventType.WINBUT] = SignBoarEvents[XSignBoardEventType.WINBUT] or {}
                SignBoarEvents[XSignBoardEventType.WINBUT].Time = XTime.GetServerNowTimestamp()
            elseif isExist and not info.IsWin then
                SignBoarEvents[XSignBoardEventType.LOST] = SignBoarEvents[XSignBoardEventType.LOST] or {}
                SignBoarEvents[XSignBoardEventType.LOST].Time = XTime.GetServerNowTimestamp()
            elseif not isExist and not info.IsWin then
                SignBoarEvents[XSignBoardEventType.LOSTBUT] = SignBoarEvents[XSignBoardEventType.LOSTBUT] or {}
                SignBoarEvents[XSignBoardEventType.LOSTBUT].Time = XTime.GetServerNowTimestamp()
            end

        elseif event == XEventId.EVENT_FAVORABILITY_GIFT then
            local characterId = ...
            SignBoarEvents[XSignBoardEventType.GIVE_GIFT] = SignBoarEvents[XSignBoardEventType.GIVE_GIFT] or {}
            SignBoarEvents[XSignBoardEventType.GIVE_GIFT].Time = XTime.GetServerNowTimestamp()
            SignBoarEvents[XSignBoardEventType.GIVE_GIFT].CharacterId = characterId

        end


    end

    --设置待机类型
    function XSignBoardManager.SetStandType(standType)
        StandType = standType
    end

    --获取互动的事件
    function XSignBoardManager.GetPlayElements(displayCharacterId)
        local elements = XSignBoardConfigs.GetPassiveSignBoardConfig(displayCharacterId)
        if not elements then
            return
        end

        elements = XSignBoardManager.FitterPlayElementByUnlockCondition(elements)
        elements = XSignBoardManager.FitterPlayElementByStandType(elements)
        elements = XSignBoardManager.FitterPlayElementByShowTime(elements)
        elements = XSignBoardManager.FitterPlayElementByFavorLimit(elements, displayCharacterId)
        elements = XSignBoardManager.FitterCurLoginPlayed(elements)
        elements = XSignBoardManager.FitterDailyPlayed(elements)

        local all = {}

        if not elements or #elements <= 0 then
            return {}
        end

        for _, tab in ipairs(elements) do

            local param = SignBoarEvents[tab.ConditionId]

            local condition = SignBoardCondition[tab.ConditionId]

            if condition and condition(tab.ConditionParam, displayCharacterId, param) then
                local element = {}
                element.Id = tab.Id --Id
                element.AddTime = SignBoarEvents[tab.ConditionId] and SignBoarEvents[tab.ConditionId].Time or XTime.GetServerNowTimestamp()  -- 添加事件
                element.StartTime = -1 --开始播放的时间
                element.EndTime = -1 --结束时间

                -- 获取相应语言的动作持续时间
                local duration
                local defaultCvType = 1
                local cvType = CS.UnityEngine.PlayerPrefs.GetInt("CV_TYPE", defaultCvType)

                if tab.Duration[cvType] == nil then
                    if tab.Duration[defaultCvType] == nil then
                        XLog.Error(string.format("XSignBoardPlayer:Play函数错误，配置表SignboardFeedback.tab没有配置Id:%s的Duration数据", tostring(element.Id)))
                        return {}
                    end
                    duration = tab.Duration[defaultCvType]
                else
                    duration = tab.Duration[cvType]
                end

                element.Duration = duration  --播放持续时间
                element.Validity = tab.Validity --有效期
                element.CoolTime = tab.CoolTime --冷却时间
                element.Weight = tab.Weight --权重
                element.SignBoardConfig = tab

                table.insert(all, element)
            end
        end

        table.sort(all, function(a, b)
            return a.Weight > b.Weight
        end)

        XDataCenter.SignBoardManager.ChangeDisplayId = -1
        return all
    end

    --获取打断的播放
    function XSignBoardManager.GetBreakPlayElements()
        return XSignBoardConfigs.GetBreakPlayElements()
    end

    --通过点击次数获取事件
    function XSignBoardManager.GetRandomPlayElementsByClick(clickTimes, displayCharacterId)

        local configs = XSignBoardConfigs.GetSignBoardConfigByFeedback(displayCharacterId, XSignBoardEventType.CLICK, clickTimes)
        configs = XSignBoardManager.FitterPlayElementByStandType(configs)
        configs = XSignBoardManager.FitterCurLoginPlayed(configs)

        configs = XSignBoardManager.FitterPlayElementByUnlockCondition(configs)
        configs = XSignBoardManager.FitterPlayElementByShowTime(configs)
        configs = XSignBoardManager.FitterPlayElementByFavorLimit(configs, displayCharacterId)
        configs = XSignBoardManager.FitterPlayed(configs)

        local element = XSignBoardManager.WeightRandomSelect(configs)

        if element then
            PlayedList[element.Id] = element
        end

        return element
    end

    --通过摇晃获取事件
    function XSignBoardManager.GetRandomPlayElementsByRoll(time, displayCharacterId)

        local configs = XSignBoardConfigs.GetSignBoardConfigByFeedback(displayCharacterId, XSignBoardEventType.ROCK)
        configs = XSignBoardManager.FitterPlayElementByStandType(configs)
        configs = XSignBoardManager.FitterCurLoginPlayed(configs)

        configs = XSignBoardManager.FitterPlayElementByUnlockCondition(configs)
        configs = XSignBoardManager.FitterPlayElementByShowTime(configs)
        configs = XSignBoardManager.FitterPlayElementByFavorLimit(configs, displayCharacterId)
        configs = XSignBoardManager.FitterPlayed(configs)

        local element = XSignBoardManager.WeightRandomSelect(configs)

        if element then
            PlayedList[element.Id] = element
        end

        return element
    end

    --过滤播放过的
    function XSignBoardManager.FitterPlayed(elements)
        if not elements or #elements <= 0 then
            return
        end

        local configs = {}
        for _, v in ipairs(elements) do
            if not PlayedList[v.Id] then
                table.insert(configs, v)
            end
        end

        if #configs <= 0 then
            PlayedList = {}
            return elements
        end

        return configs
    end

    function XSignBoardManager.FitterCurLoginPlayed(elements)
        if not elements or #elements <= 0 then
            return
        end

        local configs = {}
        for _, v in ipairs(elements) do
            local key = XSignBoardManager.GetSignBoardKey(v)
            if not PreLoginPlayedList[key] then
                table.insert(configs, v)
            end
        end

        return configs
    end

    ---====================================
    --- 过滤当天播放过的动作,返回当天未播放过的动作
    ---@param elements table
    ---@return table
    ---====================================
    function XSignBoardManager.FitterDailyPlayed(elements)
        if not elements or #elements <= 0 then
            return
        end

        local configs = {}
        local nowTimeStamp = XTime.GetServerNowTimestamp()
        local nowTime = XTime.TimestampToLocalDateTimeString(nowTimeStamp, "yyyy-MM-dd")
        local nowTimeTable = string.Split(nowTime, "-")

        for _, v in ipairs(elements) do
            local key = XSignBoardManager.GetSignBoardKey(v)

            if CS.UnityEngine.PlayerPrefs.HasKey(key) then
                local oldPlayedTime = CS.UnityEngine.PlayerPrefs.GetString(key)
                local oldPlayedTimeTable = string.Split(oldPlayedTime, "-")

                if tonumber(oldPlayedTimeTable[1]) ~= tonumber(nowTimeTable[1])
                        or tonumber(oldPlayedTimeTable[2]) ~= tonumber(nowTimeTable[2])
                        or tonumber(oldPlayedTimeTable[3]) ~= tonumber(nowTimeTable[3]) then
                    -- 年或月或日不相等，不是同一天
                    table.insert(configs, v)
                end

            else
                table.insert(configs, v)
            end
        end

        return configs
    end

    --权重随机算法
    function XSignBoardManager.WeightRandomSelect(elements)
        if not elements or #elements <= 0 then
            return
        end

        if #elements == 1 then
            return elements[1]
        end

        --获取权重总和
        local sum = 0
        for _, v in ipairs(elements) do
            sum = sum + v.Weight
        end

        --设置随机数种子
        math.randomseed(os.time())

        --随机数加上权重，越大的权重，数值越大
        local weightList = {}
        for i, v in ipairs(elements) do
            local rand = math.random(0, sum)
            local seed = {}
            seed.Index = i
            seed.Weight = rand + v.Weight
            table.insert(weightList, seed)
        end

        --排序
        table.sort(weightList, function(x, y)
            return x.Weight > y.Weight
        end)

        --返回最大的权重值
        local index = weightList[1].Index
        return elements[index]
    end

    --通过显示时间过滤
    function XSignBoardManager.FitterPlayElementByShowTime(elements)
        if not elements or #elements <= 0 then
            return
        end

        local todayTime = XTime.GetTodayTime(0)

        local configs = {}
        local curTime = XTime.GetServerNowTimestamp()
        for _, v in ipairs(elements) do
            if not v.ShowTime then
                table.insert(configs, v)
            else
                local showTime = string.Split(v.ShowTime, "|")
                if #showTime == 2 then
                    local start = tonumber(showTime[1])
                    local stop = tonumber(showTime[2])
                    if curTime >= todayTime + start and curTime <= stop + todayTime then
                        table.insert(configs, v)
                    end
                end
            end
        end

        return configs
    end

    --通过好感度过滤
    function XSignBoardManager.FitterPlayElementByFavorLimit(elements, displayCharacterId)
        if not elements or #elements <= 0 then
            return
        end
        local configs = {}
        for _, v in ipairs(elements) do
            local isUnlock , conditionDescript = XMVCA.XFavorability:CheckCharacterActionUnlockBySignBoardActionId(v.Id)
            if isUnlock then
                table.insert(configs, v)
            end
        end

        return configs
    end

    -- 通过unlockCondition过滤
    function XSignBoardManager.FitterPlayElementByUnlockCondition(elements)
        if not elements or #elements <= 0 then
            return
        end

        local configs = {}

        for _, v in ipairs(elements) do
            local isElementPass = true
            for k, condId in pairs(v.UnlockCondition) do
                if not XConditionManager.CheckCondition(condId, tonumber(v.RoleId)) then -- 不知道为什么这个角色id在配表初期时使用string，这里将错就错转number
                    isElementPass = false
                end
            end
            if isElementPass then
                table.insert(configs, v)
            end
        end

        return configs
    end

    --通过待机状态过滤
    function XSignBoardManager.FitterPlayElementByStandType(elements)

        if not elements or #elements <= 0 then
            return
        end

        local configs = {}

        for _, v in ipairs(elements) do
            if v.StandType == StandType then
                table.insert(configs, v)
            end
        end

        return configs
    end

    function XSignBoardManager.ChangeDisplayCharacter(id)
        XSignBoardManager.ChangeDisplayId = id
        PlayedList = {}
    end

    function XSignBoardManager.ChangeStandType(standType)
        if standType == StandType then
            return
        end

        XSignBoardManager.SetStandType(standType)
        PlayedList = {}

        return true
    end

    function XSignBoardManager.GetStandType()
        return StandType
    end

    --记录播放过的看板动作
    function XSignBoardManager.RecordSignBoard(signboard)
        local showType = signboard.ShowType

        if XSignBoardManager.ShowType.PerLogin == showType then
            local key = XSignBoardManager.GetSignBoardKey(signboard)
            PreLoginPlayedList[key] = signboard

        elseif XSignBoardManager.ShowType.Daily == showType then

            local nowTimeStamp = XTime.GetServerNowTimestamp()
            local nowTime = XTime.TimestampToLocalDateTimeString(nowTimeStamp, "yyyy-MM-dd")
            local key = XSignBoardManager.GetSignBoardKey(signboard)
            CS.UnityEngine.PlayerPrefs.SetString(key, nowTime)
        end

    end

    --获取键值
    function XSignBoardManager.GetSignBoardKey(signboard)
        local key = string.format("%s_%s_%s", signboard.ShowType, signboard.ConditionId, signboard.ConditionParam)
        return key
    end

    -- v1.32 角色特殊动作动画相关
    --================================================================================
    local sceneAnim = XSignBoardCamAnim.New()
    local sceneAnimPrefab

    -- 场景动画
    ----------------------------------------------------------------------------------

    function XSignBoardManager.LoadSceneAnim(rootNode, farCam, nearCam, sceneId, signBoardId, ui)
        if not XSignBoardConfigs.CheckIsHaveSceneAnim(signBoardId) then
            return
        end
        if not sceneAnim:CheckIsSameAnim(sceneId, signBoardId, rootNode) then
            XSignBoardManager.UnLoadAnim()
            -- 由于LoadPrefab()加载同url的是相同的gameobject，当不同signBoardId配置相同prefab url时unloadanim会报错
            local prefabName = XSignBoardConfigs.GetSignBoardSceneAnim(signBoardId)
            sceneAnimPrefab = CS.XResourceManager.Load(prefabName)
            local animPrefab = XUiHelper.Instantiate(sceneAnimPrefab.Asset, rootNode)

            sceneAnim:UpdateData(sceneId, signBoardId, ui)
            sceneAnim:UpdateAnim(animPrefab, farCam, nearCam)
        end
    end

    function XSignBoardManager.UnLoadAnim()
        if sceneAnimPrefab then
            CS.XResourceManager.Unload(sceneAnimPrefab)
        end
        if not sceneAnim then
            sceneAnim = XSignBoardCamAnim.New()
        else
            sceneAnim:UnloadAnim()
        end
    end

    function XSignBoardManager.SceneAnimPlay()
        if sceneAnim then
            sceneAnim:Play()
            XEventManager.DispatchEvent(XEventId.EVENT_ACTION_HIDE_UI, sceneAnim:GetNodeTransform())
        end
    end

    function XSignBoardManager.SceneAnimPause()
        if sceneAnim then
            sceneAnim:Pause()
        end
    end

    function XSignBoardManager.SceneAnimResume()
        if sceneAnim then
            sceneAnim:Resume()
        end
    end

    function XSignBoardManager.SceneAnimStop()
        if sceneAnim then
            sceneAnim:Close()
        end
    end
    ----------------------------------------------------------------------------------


    -- 打断动画播放相关
    local Timer = nil
    local StopTime = 0
    local Delay = 10
    function XSignBoardManager.OnBreakClick()
        --垃圾unity
        --安卓模拟器不模拟Input:GetMouseButtonDown(0)
        --安卓不模拟Input:GetTouch(0)，还得加个touchCount判空
        local touchCount = CS.UnityEngine.Input.touchCount
        if CS.UnityEngine.Input:GetMouseButtonDown(0) or (touchCount >= 1 and CS.UnityEngine.Input:GetTouch(0)) then
            XSignBoardManager.StopBreakTimer()
            XEventManager.DispatchEvent(XEventId.EVENT_ROLE_ACTION_UIANIM_BREAK)
        end
    end

    -- 监控打断
    function XSignBoardManager.StartBreakTimer(stopTime)
        XSignBoardManager.StopBreakTimer()
        StopTime = stopTime
        Timer = XScheduleManager.ScheduleForeverEx(function ()
            if StopTime < 0 then
                XSignBoardManager.StopBreakTimer()
                return
            end
            StopTime = StopTime - Delay / 1000
            XSignBoardManager.OnBreakClick()
        end, Delay)
    end

    function XSignBoardManager.StopBreakTimer()
        if Timer then
            XScheduleManager.UnSchedule(Timer)
            Timer = nil
        end
        StopTime = 0
    end

    -- 添加特殊动作Ui播放事件监听
    -- Ui:LuaUi对象
    function XSignBoardManager.AddRoleActionUiAnimListener(ui)
        XEventManager.AddEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_START, ui.PlayRoleActionUiDisableAnim, ui)
        XEventManager.AddEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_END, ui.PlayRoleActionUiEnableAnim, ui)
        XEventManager.AddEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_BREAK, ui.PlayRoleActionUiBreakAnim, ui)
    end

    -- 移除特殊动作Ui播放事件监听
    -- Ui:LuaUi对象
    function XSignBoardManager.RemoveRoleActionUiAnimListener(ui)
        XEventManager.RemoveEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_START, ui.PlayRoleActionUiDisableAnim, ui)
        XEventManager.RemoveEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_END, ui.PlayRoleActionUiEnableAnim, ui)
        XEventManager.RemoveEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_BREAK, ui.PlayRoleActionUiBreakAnim, ui)
    end
    --================================================================================

    --发送周年回顾记录点击角色版请求
    local RequestTouchBoardLock = false;
    function XSignBoardManager.RequestTouchBoard(characterId)
        if RequestTouchBoardLock then return end
        RequestTouchBoardLock = true
        XScheduleManager.ScheduleOnce(function()
            RequestTouchBoardLock = false;
        end, XScheduleManager.SECOND)
        XNetwork.Call(REQUEST_NAME.ClickRequest, {
            CharacterId = characterId
        } , function(response) end)
    end
    
    XSignBoardManager.Init()
    return XSignBoardManager
end