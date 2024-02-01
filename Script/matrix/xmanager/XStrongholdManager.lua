local XStrongholdMineRecord = require("XEntity/XStronghold/XStrongholdMineRecord")
local XStrongholdGroupInfo = require("XEntity/XStronghold/XStrongholdGroupInfo")
local XStrongholdTeam = require("XEntity/XStronghold/XStrongholdTeam")
local XStrongholdAssistantRecord = require("XEntity/XStronghold/XStrongholdAssistantRecord")
local XExFubenSimulationChallengeManager = require("XEntity/XFuben/XExFubenSimulationChallengeManager")
local _ActivityTimer

XStrongholdManagerCreator = function()
    local tableInsert = table.insert
    local tableSort = table.sort
    local tableRemove = table.remove
    local tonumber = tonumber
    local mathFloor = math.floor
    local mathMax = math.max
    local mathCeil = math.ceil
    local ipairs = ipairs
    local pairs = pairs
    local CsXTextManagerGetText = CsXTextManagerGetText
    local stringFormat = string.format
    local stringIsNilOrEmpty = string.IsNilOrEmpty
    local IsNumberValid = XTool.IsNumberValid
    local IsTableEmpty = XTool.IsTableEmpty
    local Clone = XTool.Clone

    ---@class XStrongholdManager
    local XStrongholdManager = XExFubenSimulationChallengeManager.New(XFubenConfigs.ChapterType.Stronghold)
    XStrongholdManager.IsomerTeamElementId = -1 --异构体/感染体的队伍属性Id
    XStrongholdManager.SpTeamElementId = -2 --SP区的队伍属性Id

    -----------------功能入口 begin----------------
    local ACTIVITY_STATUS = {
        DEFAULT = 0, --未开启
        ACTIVITY_BEGIN = 1, --挑战开始前
        FIGHT_BEGIN = 2, --战斗开启
        FIGHT_END = 3, --战斗结束
        ACTIVITY_END = 4 --已结束
    }

    local _ActivityStatus = ACTIVITY_STATUS.DEFAULT --活动状态
    local _ActivityId = 0 --活动期数
    local _BeginTime = 0 --活动开启时间
    local _FightBeginTime = 0 --挑战开启时间
    local _FightAutoBeginTime = 0 --挑战自动开启时间
    local _FightEndTime = 0 --挑战结束时间
    local _EndTime = 0 --活动结束时间
    local _CurDay = 0 --当前天数（挑战开始后）
    local _TotalDay = 0 --挑战总天数（挑战开始后）
    local _TargetCountDownTime = 0 -- 倒计时的目标时间戳
    local _ActivityEnd = false --活动是否重置
    local _HasReqAssistCharacterList = false

    local function ClearActivityTimer()
        if _ActivityTimer then
            XScheduleManager.UnSchedule(_ActivityTimer)
            _ActivityTimer = nil
        end
    end

    local UpdateActivityStatus
    UpdateActivityStatus = function()
        local leftTime = 0 --距离下一阶段剩余时间
        XCountDown.RemoveTimer(XCountDown.GTimerName.Stronghold)

        --活动未开启
        if not IsNumberValid(_BeginTime) or not IsNumberValid(_ActivityId) then
            _ActivityStatus = ACTIVITY_STATUS.DEFAULT
            leftTime = 0
        end

        local nowTime = XTime.GetServerNowTimestamp()
        leftTime = _EndTime - nowTime
        if leftTime > 0 then
            _ActivityStatus = ACTIVITY_STATUS.FIGHT_BEGIN
        else
            _ActivityStatus = ACTIVITY_STATUS.ACTIVITY_END
        end

        _TargetCountDownTime = leftTime + nowTime
        XCountDown.RemoveTimer(XCountDown.GTimerName.Stronghold)
        XCountDown.CreateTimer(XCountDown.GTimerName.Stronghold, leftTime)

        ClearActivityTimer()

        -- 当时间大于24.85天时, 定时器*1000会溢出int上限
        leftTime = math.min(leftTime, 100000)
        if leftTime > 0 then
            _ActivityTimer =
                XScheduleManager.ScheduleOnce(
                function()
                    UpdateActivityStatus()
                end,
                leftTime * XScheduleManager.SECOND
            )
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_ACTIVITY_STATUS_CHANGE)
        XEventManager.DispatchEvent(XEventId.EVENT_STRONGHOLD_ACTIVITY_STATUS_CHANGE)

        -- 状态更改通知周历刷新
        XEventManager.DispatchEvent(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE)
    end

    local function UpdateActivityInfo(activityId, beginTime, fightBeginTime)
        _ActivityId = activityId
        _BeginTime = beginTime
        _FightBeginTime = fightBeginTime
        _EndTime = _BeginTime + XStrongholdConfigs.GetActivityOneCycleSeconds(_ActivityId)
        _TotalDay = XStrongholdConfigs.GetActivityFightTotalDay(activityId)
    end

    local function UpdateCurDay(data, fightBeginTime)
        if not data then
            return
        end

        local totalDay = XStrongholdManager.GetTotalDay()
        _CurDay = data <= totalDay and data or _CurDay
        _FightBeginTime = fightBeginTime or _FightBeginTime

        UpdateActivityStatus()

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_CUR_DAY_CHANGE)
    end

    local function CheckActivityReset(activityId)
        return IsNumberValid(_ActivityId) and _ActivityId ~= activityId
    end

    function XStrongholdManager.ClearActivityEnd()
        _ActivityEnd = nil
    end

    function XStrongholdManager.OnActivityEnd()
        if not _ActivityEnd then
            return false
        end

        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return false
        end

        --延迟是为了防止打断UI动画
        XScheduleManager.ScheduleOnce(
            function()
                XLuaUiManager.RunMain()
                XUiManager.TipText("ActivityBranchOver")
            end,
            1000
        )

        XStrongholdManager.ClearActivityEnd()

        return true
    end

    --活动开启
    function XStrongholdManager.IsOpen()
        return _ActivityStatus ~= ACTIVITY_STATUS.DEFAULT and _ActivityStatus ~= ACTIVITY_STATUS.ACTIVITY_END
    end

    --挑战开始前
    function XStrongholdManager.IsActivityBegin()
        return _ActivityStatus == ACTIVITY_STATUS.ACTIVITY_BEGIN
    end

    --挑战开始
    function XStrongholdManager.IsFightBegin()
        return _ActivityStatus == ACTIVITY_STATUS.FIGHT_BEGIN
    end

    --挑战结束
    function XStrongholdManager.IsFightEnd()
        return _ActivityStatus == ACTIVITY_STATUS.ACTIVITY_END
    end

    --活动结束
    function XStrongholdManager.IsEnd()
        return not XStrongholdManager.IsOpen()
    end

    function XStrongholdManager.CheckActivityStatus(status)
        return IsNumberValid(status) and status == _ActivityStatus
    end

    function XStrongholdManager.GetStartTime()
        if not IsNumberValid(_BeginTime) then
            return XStrongholdConfigs.GetActivityDefaultOpenTime()
        end

        return _BeginTime
    end

    function XStrongholdManager.GetEndTime()
        if not IsNumberValid(_BeginTime) then
            return XStrongholdConfigs.GetActivityDefaultEndTime()
        end

        return _EndTime
    end

    --获取挑战时间
    function XStrongholdManager.GetFightTime()
        return _FightBeginTime, _FightEndTime
    end

    --获取挑战开启时长
    function XStrongholdManager.GetFightPassingTime()
        if not XTool.IsNumberValid(_FightBeginTime) then
            return 0
        end
        local now = XTime.GetServerNowTimestamp()
        return now - _FightBeginTime
    end

    --获取挑战自动开启时间
    function XStrongholdManager.GetFightAutoBeginTime()
        return _FightAutoBeginTime
    end

    function XStrongholdManager.GetCurDay()
        return _CurDay
    end

    function XStrongholdManager.GetTotalDay()
        return _TotalDay
    end

    --获取每日结算时间 HH:mm
    function XStrongholdManager.GetCountTimeStr()
        local fightBeginTime = XStrongholdManager.GetFightTime()
        if not IsNumberValid(fightBeginTime) then
            return ""
        end
        return XTime.TimestampToGameDateTimeString(fightBeginTime, "HH:mm")
    end

    --获取延后结算时间 X月X日HH:mm
    function XStrongholdManager.GetDelayCountTimeStr()
        local fightBeginTime = XStrongholdManager.GetFightTime()
        local countDay = XStrongholdManager.GetCurDay() + XStrongholdManager.GetDelayDays()
        local countTime = fightBeginTime + countDay * 3600 * 24
        return XTime.TimestampToGameDateTimeString(countTime, CsXTextManagerGetText("StrongholdTimeFormat"))
    end

    function XStrongholdManager.EnterUiMain(beforeOpenUiCb)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Stronghold) then
            return
        end

        if not XStrongholdManager.IsOpen() then
            XUiManager.TipText("StrongholdActivityNotOpen")
            return
        end

        --分包资源检测
        if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.Stronghold) then
            return
        end

        local callFunc = function()
            if beforeOpenUiCb then
                beforeOpenUiCb(
                    function()
                        XLuaUiManager.Open("UiStrongholdMain")
                    end
                )
            else
                XLuaUiManager.Open("UiStrongholdMain")
            end
        end

        if not XStrongholdManager.IsSelectedLevelId() then
            XLuaUiManager.Open("UiStrongholdChooseLevelType", callFunc)
        else
            callFunc()
        end
    end
    -----------------功能入口 end------------------
    -----------------矿场相关 begin------------------
    local _TotalMineral = 0 --历史累计矿石数量
    local _MineralLeft = 0 --可领矿石
    local _MinerItemId = 0 --矿工物品Id
    local _MineralItemId = 0 --矿石物品Id
    local _MinerEfficiency = 0 --矿工效率
    local _MinerGrowRate = 0 --矿工增殖百分比
    local _MineRecords = {} --产出记录
    local _MineRecordSynDic = {} --产出历史记录（服务端同步）
    local _OldMineralItemCount = 0 --缓存旧的矿石物品数量
    local _OldTotalMineralCount = 0 --缓存旧的预期总产出
    local _BatteryItemId = 0 --电池道具Id

    local function InitMine()
        _MinerItemId = XStrongholdConfigs.GetCommonConfig("MinerId")
        _MineralItemId = XStrongholdConfigs.GetCommonConfig("MineralId")
        _MinerEfficiency = XStrongholdConfigs.GetCommonConfig("MinerEfficiency")
        _MinerGrowRate = XStrongholdConfigs.GetCommonConfig("MinerGrowRate")
        _BatteryItemId = XStrongholdConfigs.GetCommonConfig("BatteryItemId")
    end

    local function UpdateTotalMineral(data)
        if not data then
            return
        end
        _TotalMineral = data
    end

    local function UpdateMineralLeft(data)
        if not data then
            return
        end
        _MineralLeft = data

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_MINERAL_LEFT_CHANGE)
    end

    local function GetMineRecord(day)
        local record = _MineRecords[day]
        if not record then
            record = XStrongholdMineRecord.New(day)
            _MineRecords[day] = record
        end
        return record
    end

    local function CalcMineRecords()
        local totalMineralCount = 0
        local totalDay = XStrongholdManager.GetTotalDay()
        for day = 1, totalDay do
            local minerCount, mineralCount = 0, 0

            local synRecord = _MineRecordSynDic[day]
            if synRecord then
                minerCount = synRecord.MinerCount
                mineralCount = synRecord.MineralCount
            else
                minerCount = XStrongholdManager.GetPredictMinerCount(day)
                mineralCount = XStrongholdManager.GetPredictMineralCount(day)
            end

            totalMineralCount = totalMineralCount + mineralCount

            local record = GetMineRecord(day)
            record:UpdateData(minerCount, mineralCount, totalMineralCount)
        end
    end

    local function UpdateMineRecords(data)
        _MineRecordSynDic = {}
        for _, synRecord in pairs(data or {}) do
            local synDay = synRecord.Day
            _MineRecordSynDic[synDay] = synRecord
        end

        CalcMineRecords()
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_MINERAL_RECORD_CHANGE)
    end

    local function CatchOldData()
        local itemId = XStrongholdManager.GetMineralItemId()
        local itemCount = XDataCenter.ItemManager.GetCount(itemId)
        local minerCount = XStrongholdManager.GetMinerCount()
        XStrongholdManager.CatchOldMineralItemCount(itemCount)
        XStrongholdManager.CatchOldTotalMineralCount()
        XStrongholdManager.SetCookieMinerCount(minerCount)
    end

    function XStrongholdManager.HasMineralLeft()
        if not XStrongholdManager.IsOpen() or XStrongholdManager.IsFightEnd() then
            return false
        end

        return _MineralLeft > 0
    end

    function XStrongholdManager.EnterUiMine()
        XLuaUiManager.Open("UiStrongholdMining")
    end

    function XStrongholdManager.GetMinerItemId()
        return _MinerItemId
    end

    --获取当前矿工人数
    function XStrongholdManager.GetMinerCount()
        return XDataCenter.ItemManager.GetCount(_MinerItemId)
    end

    --预期矿工人数 = 当前矿工人数 + 当前矿工人数 * 增殖百分比
    function XStrongholdManager.GetPredictMinerCount(day)
        local predictMinerCount = XStrongholdManager.GetMinerCount()

        local curDay = XStrongholdManager.GetCurDay()
        day = day or curDay

        --修改为由矿产日志最后一次记录开始推算
        local lastRecordDay = curDay
        for i = 1, day do
            if not _MineRecordSynDic[i] then
                lastRecordDay = i
                break
            end
        end

        for i = lastRecordDay, day - 1 do
            predictMinerCount = mathCeil(predictMinerCount + predictMinerCount * _MinerGrowRate * 0.01)
        end

        return predictMinerCount
    end

    --预期矿产数
    function XStrongholdManager.GetPredictMineralCount(day)
        day = day or XStrongholdManager.GetCurDay()
        local predictMinerCount = XStrongholdManager.GetPredictMinerCount(day)
        return XStrongholdManager.GetMineralOutput(predictMinerCount)
    end

    --获取上一次查看的矿工人数
    function XStrongholdManager.GetCookieMinerCount()
        local key = XStrongholdManager.GetMinerCountCookieKey()
        return XSaveTool.GetData(key) or 0
    end

    function XStrongholdManager.SetCookieMinerCount(count)
        local key = XStrongholdManager.GetMinerCountCookieKey()
        XSaveTool.SaveData(key, count)
    end

    function XStrongholdManager.ClearCookieMinerCount()
        local key = XStrongholdManager.GetMinerCountCookieKey()
        XSaveTool.RemoveData(key)
    end

    function XStrongholdManager.GetMinerCountCookieKey()
        if not IsNumberValid(_ActivityId) then
            return
        end
        return XPlayer.Id .. _ActivityId .. "_XStrongholdManager_CookieMinerCount"
    end

    function XStrongholdManager.GetMineralItemId()
        return _MineralItemId
    end

    function XStrongholdManager.GetMineralCount()
        return XDataCenter.ItemManager.GetCount(_MinerItemId)
    end

    function XStrongholdManager.GetTotalMineralCount()
        return _TotalMineral or 0
    end

    function XStrongholdManager.GetTotalMinerEfficiency()
        return _MinerEfficiency or 0
    end

    function XStrongholdManager.GetTotalMinerGrowRate()
        return _MinerGrowRate or 0
    end

    --产出矿石 = 矿工数量 * 矿工效率（向上取整）
    function XStrongholdManager.GetMineralOutput(minerCount)
        minerCount = minerCount or XStrongholdManager.GetMinerCount()
        return mathCeil(minerCount * _MinerEfficiency)
    end

    function XStrongholdManager.GetMineRecordsForShow()
        local showRecords = {}
        CalcMineRecords()
        --修改为获取时实时计算

        for _, record in ipairs(_MineRecords) do
            local showRecord = {}
            showRecord.Day = record:GetDay()
            showRecord.MinerCount = record:GetMinerCount()
            showRecord.MineralCount = record:GetMineralCount()
            showRecord.TotalMineralCount = record:GetTotalMineralCount()

            tableInsert(showRecords, showRecord)
        end

        return showRecords
    end

    --预期总产出 = 矿产记录最后一天总产出
    function XStrongholdManager.GetPredictTotalMineralCount()
        CalcMineRecords()
        --修改为获取时实时计算
        local totalDay = XStrongholdManager.GetTotalDay()
        local record = GetMineRecord(totalDay)
        return record:GetTotalMineralCount()
    end

    function XStrongholdManager.NotifyStrongholdTotalMineral(data)
        UpdateTotalMineral(data.TotalMineral)
    end

    --领取矿石
    function XStrongholdManager.GetStrongholdMineralRequest(cb)
        XNetwork.Call(
            "GetStrongholdMineralRequest",
            nil,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateMineralLeft(0)

                local mineralCount = res.MineralCount
                if cb then
                    cb(mineralCount)
                end
            end
        )
    end

    function XStrongholdManager.CatchOldMineralItemCount(itemCount)
        _OldMineralItemCount = itemCount
    end

    function XStrongholdManager.GetOldItemCount()
        return _OldMineralItemCount
    end

    function XStrongholdManager.CatchOldTotalMineralCount()
        _OldTotalMineralCount = XStrongholdManager.GetPredictTotalMineralCount()
    end

    function XStrongholdManager.GetOldTotalMineralCount()
        return _OldTotalMineralCount
    end
    -----------------矿场相关 end------------------
    -----------------电场相关 begin------------------
    local _MaxElectricEnergy = 0 --电能上限
    local _ElectricTeamMaxCharacterNum = 0 --电能队伍最大人数
    local _ElectricCharacterIdDic = {} --电能队伍

    local function InitElectric()
        _ElectricTeamMaxCharacterNum = XStrongholdConfigs.GetCommonConfig("MaxElectricTeamMemberCount")
    end

    local function UpdateMaxElectricEnergy(data)
        _MaxElectricEnergy = data or _MaxElectricEnergy

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_MAX_ELECTRIC_CHANGE)
    end

    local function UpdateElectricCharacters(data)
        _ElectricCharacterIdDic = {}

        local count = 0
        for _, characterId in ipairs(data or {}) do
            if count > _ElectricTeamMaxCharacterNum then
                XLog.Error(
                    "XStrongholdManager UpdateElectricCharacters error: 同步电能队伍数据出错，超出最大队伍人数上限: " ..
                        _ElectricTeamMaxCharacterNum .. ", data: ",
                    data
                )
                break
            end

            if characterId > 0 then
                _ElectricCharacterIdDic[characterId] = characterId
                count = count + 1
            end
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_MAX_ELECTRIC_CHANGE)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_ELECTRIC_CHARACTER_CHANGE)
    end

    function XStrongholdManager.GetMaxElectricEnergy()
        return _MaxElectricEnergy
    end

    --电能队伍战力达到要求后会额外增加电能上限
    function XStrongholdManager.GetExtraElectricEnergy()
        local totalAbility = XStrongholdManager.GetElectricCharactersTotalAbility()
        return XStrongholdConfigs.GetTeamAbilityToExtraElectric(totalAbility)
    end

    --总电能上限
    function XStrongholdManager.GetTotalElectricEnergy()
        return _MaxElectricEnergy + XStrongholdManager.GetExtraElectricEnergy()
    end

    --根据GroupId获得章节限制使用电能上限
    function XStrongholdManager.GetChapterMaxElectricUseByGroupId(groupId)
        if not XTool.IsNumberValid(groupId) then
            return 0
        end
        local chapterId = XStrongholdConfigs.GetChapterIdByGroupId(groupId)
        if not XTool.IsNumberValid(chapterId) then
            return 0
        end
        return XStrongholdConfigs.GetChapterMaxElectricUse(chapterId)
    end

    --当前章节可使用总电能上限
    function XStrongholdManager.GetTotalCanUseElectricEnergy(groupId)
        local totalElectric = XStrongholdManager.GetTotalElectricEnergy()
        if not XTool.IsNumberValid(groupId) then
            return totalElectric
        end
        local limitElectric = XStrongholdManager.GetChapterMaxElectricUseByGroupId(groupId)
        if not XTool.IsNumberValid(limitElectric) then
            return totalElectric
        end
        return XMath.Clamp(totalElectric, totalElectric, limitElectric)
    end

    function XStrongholdManager.GetAddElectricEnergy()
        local day = XStrongholdManager.GetCurDay()
        local levelId = XStrongholdManager.GetLevelId()

        if XStrongholdManager.IsAnyDayPaused() then
            --暂停时获取电能上限累积
            local totalCount = 0
            local totalDay = XStrongholdManager.GetTotalDay()
            local isContinuePaused = false
            for countDay = 1, totalDay do
                if XStrongholdManager.IsDayPaused(countDay) then
                    isContinuePaused = true
                    totalCount = totalCount + XStrongholdConfigs.GetElectricAdd(countDay, levelId)
                else
                    if isContinuePaused then
                        isContinuePaused = false
                        totalCount = totalCount + XStrongholdConfigs.GetElectricAdd(countDay, levelId)
                    end
                end
            end
            return totalCount
        else
            return XStrongholdConfigs.GetElectricAdd(day, levelId)
        end
    end

    --检查已使用电能是否溢出
    function XStrongholdManager.CheckElectricOverLimit(cancelCharacterId, teamList, groupId)
        local totalElectric = 0
        if IsNumberValid(cancelCharacterId) then
            --撤回电能支援队员时电力减少值
            local ability = XMVCA.XCharacter:GetCharacterAbilityById(cancelCharacterId)
            local totalAbility = XStrongholdManager.GetElectricCharactersTotalAbility() - ability
            totalElectric = XStrongholdConfigs.GetTeamAbilityToExtraElectric(totalAbility) + _MaxElectricEnergy
        else
            totalElectric = XStrongholdManager.GetTotalCanUseElectricEnergy(groupId)
        end

        local useElectric = XStrongholdManager.GetTotalUseElectricEnergy(teamList)
        return useElectric > totalElectric
    end

    --获得推荐电力的文本颜色、是否需要弹窗提示
    function XStrongholdManager.GetSuggestElectricColor(groupId, teamList, useElectric)
        local chapterId = XTool.IsNumberValid(groupId) and XStrongholdConfigs.GetChapterIdByGroupId(groupId)
        local isHavechapterId = XTool.IsNumberValid(chapterId)
        local levelId = XDataCenter.StrongholdManager.GetLevelId()
        local suggestElectric = isHavechapterId and XStrongholdConfigs.GetChapterSuggestElectric(chapterId, levelId) or 0
        useElectric = useElectric or XStrongholdManager.GetTotalUseElectricEnergy(teamList)
        local totalElectricEnergy = XStrongholdManager.GetTotalCanUseElectricEnergy(groupId)
        local color, isTips

        if XTool.IsNumberValid(suggestElectric) then
            if useElectric > totalElectricEnergy then
                color = CS.UnityEngine.Color.red
            elseif useElectric > suggestElectric + XStrongholdManager.GetExtraElectricEnergy() then
                color = XUiHelper.Hexcolor2Color("FF9008")
                isTips = true
            else
                color = XUiHelper.Hexcolor2Color("188649")
            end
        else
            color = XUiHelper.Hexcolor2Color("188649")
        end
        return color, isTips
    end

    --获取电能队伍总战力
    function XStrongholdManager.GetElectricCharactersTotalAbility()
        local totalAbility = 0
        for _, characterId in pairs(_ElectricCharacterIdDic) do
            local ability = XMVCA.XCharacter:GetCharacterAbilityById(characterId)
            totalAbility = totalAbility + ability
        end
        return totalAbility
    end

    --获取可上阵电能支援角色
    function XStrongholdManager.GetCanElectricCharacters(characterType)
        local characterList = XMVCA.XCharacter:GetOwnCharacterList(characterType)
        tableSort(
            characterList,
            function(a, b)
                --电能支援
                local aIsElectric = XStrongholdManager.CheckInElectricTeam(a.Id)
                local bIsElectric = XStrongholdManager.CheckInElectricTeam(b.Id)
                if aIsElectric ~= bIsElectric then
                    return aIsElectric
                end

                --已经上阵
                local aIsInTeam = XStrongholdManager.CheckInTeamList(a.Id)
                local bIsInTeam = XStrongholdManager.CheckInTeamList(b.Id)
                if aIsInTeam ~= bIsInTeam then
                    return not aIsInTeam
                end

                return false
            end
        )

        return characterList
    end

    function XStrongholdManager.GetCookieElectricEnergy()
        local key = XStrongholdManager.GetElectricEnergyCookieKey()
        return XSaveTool.GetData(key) or 0
    end

    function XStrongholdManager.SetCookieElectricEnergy(count)
        local key = XStrongholdManager.GetElectricEnergyCookieKey()
        XSaveTool.SaveData(key, count)
    end

    function XStrongholdManager.ClearCookieElectricEnergy()
        local key = XStrongholdManager.GetElectricEnergyCookieKey()
        XSaveTool.RemoveData(key)
    end

    function XStrongholdManager.GetElectricEnergyCookieKey()
        if not IsNumberValid(_ActivityId) then
            return
        end
        return XPlayer.Id .. _ActivityId .. "_XStrongholdManager_MaxElectricEnergy"
    end

    function XStrongholdManager.GetElectricCharacterIds()
        local characterIds = {}
        for _, characterId in pairs(_ElectricCharacterIdDic) do
            tableInsert(characterIds, characterId)
        end
        return characterIds
    end

    function XStrongholdManager.GetElectricTeamMaxCharacterNum()
        return _ElectricTeamMaxCharacterNum
    end

    function XStrongholdManager.CheckInElectricTeam(characterId)
        return _ElectricCharacterIdDic[characterId] and true or false
    end

    function XStrongholdManager.CheckElectricMaxNum()
        local curNum = 0
        for _, characterId in pairs(_ElectricCharacterIdDic) do
            if characterId > 0 then
                curNum = curNum + 1
            end
        end
        local maxNum = XStrongholdManager.GetElectricTeamMaxCharacterNum()
        return curNum >= maxNum
    end

    --设置电能队伍
    function XStrongholdManager.SetStrongholdElectricTeamRequest(characterIds, cb)
        local req = {CharacterIds = characterIds}
        XNetwork.Call(
            "SetStrongholdElectricTeamRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateElectricCharacters(characterIds)

                if cb then
                    cb()
                end
            end
        )
    end

    function XStrongholdManager.GetBatteryItemId()
        return _BatteryItemId
    end
    -----------------电场相关 end------------------
    -----------------耐力相关 begin------------------
    local _Endurance = 0 --耐力值

    local function UpdateEndurance(data)
        _Endurance = data or 0

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_ENDURANCE_CHANGE)
    end

    --当据点为章节关底时，消耗耐力应为之前未通关的关卡数之和
    function XStrongholdManager.GetGroupCostEndurance(groupId)
        if XStrongholdManager.IsGroupFinished(groupId) or XStrongholdManager.CheckGroupHasFinishedStage(groupId) then
            return 0
        end

        local costEndurance = XStrongholdConfigs.GetGroupCostEndurance(groupId)

        local allGroupIds = {}

        local recurFunc
        recurFunc = function(tb)
            if IsTableEmpty(tb) then
                return
            end

            for _, toFinisheGroupId in pairs(tb) do
                if not XStrongholdManager.IsGroupFinished(toFinisheGroupId) then
                    allGroupIds[toFinisheGroupId] = toFinisheGroupId
                end

                local toFinishGroupIds = XStrongholdConfigs.GetGroupFinishRelatedId(toFinisheGroupId)
                recurFunc(toFinishGroupIds)
            end
        end
        local toFinishGroupIds = XStrongholdConfigs.GetGroupFinishRelatedId(groupId)
        recurFunc(toFinishGroupIds)

        for _, groupId in pairs(allGroupIds) do
            costEndurance = costEndurance + XStrongholdConfigs.GetGroupCostEndurance(groupId)
        end

        return costEndurance
    end

    -- 需要完成前置关卡的则为深巢关
    function XStrongholdManager.IsChapterLastGroup(groupId)
        if not XTool.IsNumberValid(groupId) then
            return false
        end
        local ids = XStrongholdConfigs.GetGroupFinishRelatedId(groupId)
        return not XTool.IsTableEmpty(ids)
    end

    function XStrongholdManager.GetMaxEndurance()
        local curDay = XStrongholdManager.GetCurDay()
        local levelId = XStrongholdManager.GetLevelId()
        return XStrongholdConfigs.GetMaxEndurance(curDay - 1, levelId) +
            XStrongholdConfigs.GetLevelInitEndurance(levelId)
    end

    function XStrongholdManager.GetMaxLimitEndurance()
        local totalDay = XStrongholdManager.GetTotalDay()
        local levelId = XStrongholdManager.GetLevelId()
        return XStrongholdConfigs.GetMaxEndurance(totalDay, levelId) + XStrongholdConfigs.GetLevelInitEndurance(levelId)
    end

    function XStrongholdManager.GetCurEndurance()
        return _Endurance
    end

    function XStrongholdManager.NotifyStrongholdEnduranceData(data)
        UpdateEndurance(data.Endurance)
    end
    -----------------耐力相关 end------------------
    -----------------据点相关 begin------------------
    local _FinishGroupIdDic = {}
    --已完成据点Id字典
    local _NewFinishGroupIds = {}
    --最新完成据点Id列表
    local _GroupInfos = {}
    --历史完成据点Id列表
    local _HistoryGroupInfos = {}
    --已经打印的据点Id字典
    local _LogGroupIdDic = {}
    --据点信息
    local _CurrentSelectGroupId = 0 --当前选择的据点Id，用于检查队伍是否符合条件
    local _DelayTipChapterId = 0 --已通关前置据点，但未满足解锁条件的章节Id(通过条件后弹出解锁提示)

    local function InitGroupInfos()
        local groupIds = XStrongholdConfigs.GetAllGroupIds()

        for _, groupId in pairs(groupIds) do
            local groupInfo = XStrongholdGroupInfo.New(groupId)
            _GroupInfos[groupId] = groupInfo
        end
    end

    ---@return XStrongholdGroupInfo
    local function GetGroupInfo(groupId)
        local groupInfo = _GroupInfos[groupId]
        if not groupInfo and not _LogGroupIdDic[groupId] then
            _LogGroupIdDic[groupId] = true
            local groupInfosIds = {}
            for groupId in pairs(_GroupInfos) do
                table.insert(groupInfosIds, groupId)
            end
            XLog.Error(
                "XStrongholdManager GetGroupInfo error, groupId与服务端数据不对应, groupId: ",
                groupId .. ", _GroupInfos: ",
                groupInfosIds
            )
        end
        return groupInfo
    end

    local function GetHistoryGroupInfo(groupId)
        return _HistoryGroupInfos[groupId]
    end

    local function ResetGroupInfo(groupId, stageId)
        if not IsNumberValid(groupId) then
            return
        end
        local groupInfo = GetGroupInfo(groupId)

        if XTool.IsNumberValid(stageId) then
            groupInfo:ResetFinishStage(stageId)
        else
            groupInfo:ResetFinishStages()
        end
    end

    local function UpdateGroupStageDatas(data)
        if IsTableEmpty(data) then
            return
        end

        for _, stageData in pairs(data) do
            local groupId = stageData.Id
            if not IsNumberValid(groupId) then
                XLog.Error("XStrongholdManager UpdateGroupStageDatas error, groupId非法, data: ", data)
            end

            local stageIds = stageData.StageIds
            local stageBuffIdDic = stageData.StageBuffId
            local supportId = stageData.SupportId
            local groupInfo = GetGroupInfo(groupId, true)

            if groupInfo then
                groupInfo:InitStageData(stageIds, stageBuffIdDic, supportId, stageData.ExtendBuffId)
            end
        end

        XStrongholdManager.InitStageInfo()
    end

    local function UpdateGroupInfos(data)
        if IsTableEmpty(data) then
            return
        end

        for _, groupData in pairs(data) do
            local groupId = groupData.Id
            local finishStageIds = groupData.FinishStageIds
            local groupInfo = GetGroupInfo(groupId)
            groupInfo:UpdateFinishStages(finishStageIds)
        end
    end

    local function UpdateFinishGroupIds(data)
        _FinishGroupIdDic = {}
        for _, groupId in pairs(data) do
            if XTool.IsNumberValid(groupId) then
                _FinishGroupIdDic[groupId] = groupId
            end
        end

        --触发新手引导
        XDataCenter.GuideManager.CheckGuideOpen()

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE)
    end

    local function UpdateFinishGroupUseElectricEnergy(finishGroupInfos, historyFinishGroupInfos)
        local groupId
        local groupInfoTemp
        for _, groupInfo in pairs(finishGroupInfos or {}) do
            groupId = groupInfo.Id
            groupInfoTemp = XTool.IsNumberValid(groupId) and GetGroupInfo(groupId)
            if groupInfoTemp then
                groupInfoTemp:UpdatePassUseElectric(groupInfo.UsedElectricEnergy, groupInfo.UsedSystemElectricEnergy)
            end
        end

        for _, groupInfo in pairs(historyFinishGroupInfos or {}) do
            groupId = groupInfo.Id
            groupInfoTemp = GetHistoryGroupInfo(groupId)
            if not groupInfoTemp then
                groupInfoTemp = XStrongholdGroupInfo.New(groupId, true)
                _HistoryGroupInfos[groupId] = groupInfoTemp
            end
            groupInfoTemp:UpdatePassUseElectric(groupInfo.UsedElectricEnergy, groupInfo.UsedSystemElectricEnergy)
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_FINISH_GROUP_USE_ELECTRIC_CHANGE)
    end

    local function UpdateNewFinishGroupIds(data)
        if IsTableEmpty(data) then
            return
        end

        _NewFinishGroupIds = {}
        for _, groupId in pairs(data) do
            if groupId > 0 and not _FinishGroupIdDic[groupId] then
                tableInsert(_NewFinishGroupIds, groupId)
            end
        end
    end

    --据点进度变更时章节界面检查
    function XStrongholdManager.CheckNewFinishGroupIds()
        --有需要延迟检查条件是否通过的章节
        if XTool.IsNumberValid(_DelayTipChapterId) then
            if XDataCenter.StrongholdManager.CheckChapterUnlock(_DelayTipChapterId) then
                local chapterName = XStrongholdConfigs.GetChapterName(_DelayTipChapterId)
                local msg = CsXTextManagerGetText("StrongholdtipNewChapter", chapterName)
                XUiManager.TipMsg(msg)
                _DelayTipChapterId = 0
                return
            end
        end

        if IsTableEmpty(_NewFinishGroupIds) then
            return
        end

        local tipChapterId
        local tipLastGroupDebuff = false
        --配置了StageBuff字段且非关底的据点通过时提示关底被削弱
        local tipNewChapter = false
        --通过关底据点时提示解锁新章节(此条弹出时忽略上一条提示)
        for _, groupId in pairs(_NewFinishGroupIds) do
            local chapterId = XStrongholdConfigs.GetChapterIdByGroupId(groupId)
            if XStrongholdConfigs.IsChapterLastGroupId(groupId) then
                local nextChapterId = XStrongholdConfigs.GetNextChapterId(chapterId)
                if XStrongholdManager.CheckChapterUnlock(nextChapterId) then
                    tipNewChapter = true
                    tipChapterId = nextChapterId
                    break
                else
                    _DelayTipChapterId = nextChapterId
                end
            end

            if XStrongholdConfigs.CheckHasGroupBossBuffId(groupId, _ActivityId) then
                tipLastGroupDebuff = true
                tipChapterId = chapterId
            end
        end

        if XTool.IsNumberValid(tipChapterId) then
            --新章节开启提示
            if tipNewChapter then
                local chapterName = XStrongholdConfigs.GetChapterName(tipChapterId)
                local msg = CsXTextManagerGetText("StrongholdtipNewChapter", chapterName)
                XUiManager.TipMsg(msg)
            elseif tipLastGroupDebuff then
                --关底BUFF削弱提示
                local lastGroupId = XStrongholdConfigs.GetChapterLastGroupId(tipChapterId)
                local groupOrder = XStrongholdConfigs.GetGroupOrder(lastGroupId)
                local msg = CsXTextManagerGetText("StrongholdTipLastGroupDebuff", groupOrder)
                XUiManager.TipMsg(msg)
            end
        end

        _NewFinishGroupIds = {}
    end

    function XStrongholdManager.GetGroupStageIds(groupId)
        local groupInfo = GetGroupInfo(groupId)
        return groupInfo and groupInfo:GetStageIds() or {}
    end

    function XStrongholdManager.GetTeamProps()
        local allTeamProps = {}
        local groupId = XStrongholdManager.GetLastGroupId()
        local teamPropId = XStrongholdManager.GetTeamPropsByGroupId(groupId)[1]
        -- id都是安装 1 2 3 4 5或者3 4 5 1 2这样的规律顺序排的
        for i = 0, 4 do
            table.insert(allTeamProps, teamPropId)
            teamPropId = teamPropId >= 5 and 1 or teamPropId + 1
        end
        return allTeamProps
    end

    function XStrongholdManager.GetTeamPropsByGroupId(groupId)
        local teamPropIds = {}
        local stageIds = XStrongholdManager.GetGroupStageIds(groupId)
        for _, stageId in pairs(stageIds) do
            local index = XStrongholdConfigs.GetGroupStageIdGroupIndex(groupId, stageId)
            table.insert(teamPropIds, index)
        end
        return teamPropIds
    end

    ---通过队伍属性（物理/暗）获取队伍在关卡里的索引（1，2，3...）
    function XStrongholdManager.GetTeamIndexByProp(groupId, teamPropId)
        local stageIds = XStrongholdManager.GetGroupStageIds(groupId)
        for i, stageId in ipairs(stageIds) do
            local prop = XStrongholdConfigs.GetGroupStageIdGroupIndex(groupId, stageId)
            if prop == teamPropId then
                return i
            end
        end
        return nil
    end

    --检查通关指定据点时使用的电量是否小于等于指定值
    function XStrongholdManager.CheckGroupPassUseElectric(groupId, requireUseElectric, elType, isHistory)
        if not XTool.IsNumberValid(groupId) then
            return false
        end

        local groupInfo
        if isHistory then
            groupInfo = GetHistoryGroupInfo(groupId)
        elseif XStrongholdManager.IsGroupFinished(groupId) then
            groupInfo = GetGroupInfo(groupId)
        end
        if not groupInfo then
            return false
        end

        local passUseElectric, usedSystemElectricEnergy = groupInfo:GetPassUseElectric()
        if IsNumberValid(elType) then
            return usedSystemElectricEnergy <= requireUseElectric --elType不为0时，用通关当前据点使用的系统电量判断
        else
            return passUseElectric <= requireUseElectric
        end
    end

    function XStrongholdManager.GetAllGroupStageIds()
        local allStageIds = {}
        for groupId in pairs(_GroupInfos) do
            local stageIds = XStrongholdManager.GetGroupStageIds(groupId)
            for _, stageId in pairs(stageIds) do
                tableInsert(allStageIds, stageId)
            end
        end
        return allStageIds
    end

    function XStrongholdManager.GetGroupStageId(groupId, stageIndex)
        if not groupId then
            return nil
        end
        local groupInfo = GetGroupInfo(groupId)
        return groupInfo and groupInfo:GetStageId(stageIndex) or nil
    end

    function XStrongholdManager.GetGroupStageName(groupId, stageIndex)
        local stageId = XStrongholdManager.GetGroupStageId(groupId, stageIndex)
        return stageId ~= 0 and XDataCenter.FubenManager.GetStageName(stageId) or ""
    end

    function XStrongholdManager.GetGroupStageBuffDesc(groupId, stageIndex)
        local groupInfo = GetGroupInfo(groupId)
        local buffId = groupInfo:GetStageBuffId(stageIndex)
        return buffId > 0 and XStrongholdConfigs.GetBuffDesc(buffId) or ""
    end

    function XStrongholdManager.GetGroupStageExtendBuffDesc(groupId, stageIndex)
        local groupInfo = GetGroupInfo(groupId)
        local buffId = groupInfo:GetStageExtendBuffId(stageIndex)
        return buffId > 0 and XStrongholdConfigs.GetBuffDesc(buffId) or ""
    end

    --获取据点BaseBuff
    function XStrongholdManager.GetGroupBaseBuffIds(groupId)
        return XStrongholdConfigs.GetGroupBaseBuffIds(groupId, _ActivityId)
    end

    --获取据点BossBuff
    function XStrongholdManager.GetGroupBossBuffIds(groupId)
        return XStrongholdConfigs.GetGroupBossBuffIds(groupId, _ActivityId)
    end

    --获取据点首通奖励Id
    function XStrongholdManager.GetGroupRewardId(groupId)
        local levelId = XStrongholdManager.GetLevelId()
        return XStrongholdConfigs.GetGroupRewardId(groupId, levelId)
    end

    function XStrongholdManager.CheckAnyGroupHasFinishedStage()
        for groupId, groupInfo in pairs(_GroupInfos) do
            if groupInfo:CheckHasStageFinished() then
                return groupId
            end
        end
        return false
    end

    --检查据点是否有挑战中的关卡进度
    function XStrongholdManager.CheckGroupHasFinishedStage(groupId)
        local groupInfo = GetGroupInfo(groupId)
        return groupInfo and groupInfo:CheckHasStageFinished() or false
    end

    --检查章节是否有挑战中的关卡进度
    function XStrongholdManager.CheckChapterHasFinishedStage(chapterId)
        local groupIds = XStrongholdConfigs.GetGroupIds(chapterId)
        for _, groupId in pairs(groupIds) do
            if XStrongholdManager.CheckGroupHasFinishedStage(groupId) then
                return true
            end
        end
        return false
    end

    function XStrongholdManager.IsGroupStageFinished(groupId, stageIndex)
        if not IsNumberValid(groupId) or not IsNumberValid(stageIndex) then
            return false
        end

        local requireTeamMemberDic = XStrongholdManager.GetGroupRequireTeamMemberDic(groupId)
        if not requireTeamMemberDic[stageIndex] then
            return false
        end

        local groupInfo = GetGroupInfo(groupId)
        return groupInfo and groupInfo:IsStageFinished(stageIndex) or false
    end

    function XStrongholdManager.GetGroupNextFightStageIndex(groupId)
        local groupInfo = GetGroupInfo(groupId)
        return groupInfo and groupInfo:GetNextFightStageIndex() or 0
    end

    function XStrongholdManager.GetGroupStageNum(groupId)
        return #XStrongholdManager.GetGroupStageIds(groupId)
    end

    function XStrongholdManager.GetGroupSupportId(groupId)
        local groupInfo = GetGroupInfo(groupId)
        return groupInfo and groupInfo:GetSupportId() or 0
    end

    --获取据点要求梯队数量
    function XStrongholdManager.GetGroupRequireTeamNum(groupId)
        local groupInfo = GetGroupInfo(groupId)
        return groupInfo and groupInfo:GetRequireTeamNum() or 0
    end

    --获取据点要求梯队数量
    function XStrongholdManager.GetGroupRequireTeamIds(groupId)
        local requireTeamIds = {}

        if not groupId then
            --预设模式下返回默认最大数量
            local maxTeamNum = XStrongholdConfigs.GetMaxTeamNum()
            for teamId = 1, maxTeamNum do
                tableInsert(requireTeamIds, teamId)
            end
        else
            --读取战斗关卡要求队伍成员数量
            local requireTeamNum = XStrongholdManager.GetGroupRequireTeamNum(groupId)
            for teamId = 1, requireTeamNum do
                tableInsert(requireTeamIds, teamId)
            end
        end

        return requireTeamIds
    end

    function XStrongholdManager.GetGroupRequireTeamMemberDic(groupId)
        local requireTeamMemberDic = {}
        local requireTeamNum = XStrongholdManager.GetGroupRequireTeamNum(groupId)
        for teamId = 1, requireTeamNum do
            local requireCount = XStrongholdConfigs.GetGroupRequireTeamMemberNum(groupId, teamId)
            if requireCount > 0 then
                requireTeamMemberDic[teamId] = requireCount
            end
        end
        return requireTeamMemberDic
    end

    function XStrongholdManager.GetGroupRequireAbility(groupId)
        if not IsNumberValid(groupId) then
            return 0
        end
        local supportId = XStrongholdManager.GetGroupSupportId(groupId)
        return supportId > 0 and XStrongholdConfigs.GetSupportRequireAbility(supportId) or 0
    end

    --检查完美战术是否激活
    function XStrongholdManager.CheckSupportActive(supportId, teamList)
        if not XTool.IsNumberValid(supportId) then
            return false
        end
        local conditionIds = XStrongholdConfigs.GetSupportConditionIds(supportId)
        for _, conditionId in pairs(conditionIds) do
            if not XConditionManager.CheckCondition(conditionId, teamList) then
                return false
            end
        end
        return true
    end

    function XStrongholdManager.CheckGroupSupportAcitve(groupId, teamList)
        local supportId = XStrongholdManager.GetGroupSupportId(groupId)
        return XStrongholdManager.CheckSupportActive(supportId, teamList)
    end

    function XStrongholdManager.OpenUiSupport(groupId, teamList)
        local supportId = XStrongholdManager.GetGroupSupportId(groupId)
        if not IsNumberValid(supportId) then
            XLog.Error("XUiStrongholdDetail:OnClickBtnAssitantBuff error: 支援方案Id未配置, groupId: ", groupId)
            return
        end
        XLuaUiManager.Open("UiStrongholdSupportTips", supportId, teamList)
    end

    --获取据点章节类型
    function XStrongholdManager.GetGroupChapterType(groupId)
        local groupInfo = GetGroupInfo(groupId)
        return groupInfo and groupInfo:GetChapterType() or XStrongholdConfigs.ChapterType.Normal
    end

    --困难章节是否可显示
    function XStrongholdManager.IsChapterHardCanShow()
        local conditionId = XStrongholdConfigs.GetCommonConfig("MaintainChapterCondition")
        if not XTool.IsNumberValid(conditionId) then
            return true
        end
        return XConditionManager.CheckCondition(conditionId)
    end

    --困难章节是否可显示,且普通章节全部通关
    function XStrongholdManager.IsChapterHardCanFight()
        if not XStrongholdManager.IsChapterHardCanShow() then
            return false
        end
        local finishCount = XStrongholdManager.GetFinishGroupCount(XStrongholdConfigs.ChapterType.Normal)
        local totalCount = XStrongholdManager.GetAllGroupCount(XStrongholdConfigs.ChapterType.Normal)
        return finishCount >= totalCount
    end

    --获取据点进度
    function XStrongholdManager.GetGroupProgress()
        local finishCount = XStrongholdManager.GetFinishGroupCount(XStrongholdConfigs.ChapterType.Normal)
        local totalCount = XStrongholdManager.GetAllGroupCount(XStrongholdConfigs.ChapterType.Normal)
        return finishCount, totalCount
    end

    function XStrongholdManager.GetAllGroupCount(chapterType)
        local count = 0
        for _, groupInfo in pairs(_GroupInfos) do
            if not chapterType or groupInfo:GetChapterType() == chapterType then
                count = count + 1
            end
        end
        return count
    end

    function XStrongholdManager.GetFinishGroupCount(chapterType)
        local count = 0
        for groupId in pairs(_FinishGroupIdDic) do
            if groupId > 0 and (not chapterType or XStrongholdManager.GetGroupChapterType(groupId) == chapterType) then
                count = count + 1
            end
        end
        return count
    end

    function XStrongholdManager.IsGroupFinished(groupId)
        return _FinishGroupIdDic[groupId] and true or false
    end

    --据点解锁条件为前置据点是否通关
    function XStrongholdManager.IsGroupUnlock(groupId)
        local preGroupId = XStrongholdConfigs.GetGroupPreGroupId(groupId)
        if not IsNumberValid(preGroupId) then
            return true
        end
        return XStrongholdManager.IsGroupFinished(preGroupId)
    end

    --章节是否解锁
    function XStrongholdManager.CheckChapterUnlock(chapterId)
        local isUnlock, conditionDes = false, ""

        if not XTool.IsNumberValid(chapterId) then
            return false
        end

        --检查条件Id
        local conditionId = XStrongholdConfigs.GetChapterUnlockCondition(chapterId)
        if XTool.IsNumberValid(conditionId) then
            isUnlock, conditionDes = XConditionManager.CheckCondition(conditionId)
            if not isUnlock then
                return isUnlock, conditionDes
            end
        end

        --检查章节的第一个据点的前置据点是否通关
        local firstGroupId = XStrongholdConfigs.GetChapterFirstGroupId(chapterId)
        isUnlock = XStrongholdManager.IsGroupUnlock(firstGroupId)
        local preGroupId = XStrongholdConfigs.GetGroupPreGroupId(firstGroupId)
        if IsNumberValid(preGroupId) then
            local groupName = XStrongholdConfigs.GetGroupOrder(preGroupId)
            conditionDes = CsXTextManagerGetText("StrongholdChapterUnlockCondition", groupName)
        end

        return isUnlock, conditionDes
    end

    --章节是否需要消耗行动点
    function XStrongholdManager.CheckChapterNotCostEndurance(chapterId)
        if not XTool.IsNumberValid(chapterId) then
            return false
        end
        
        local groupIdList = XStrongholdConfigs.GetGroupIds(chapterId)
        for _, groupId in ipairs(groupIdList) do
            if XTool.IsNumberValid(XStrongholdConfigs.GetGroupCostEndurance(groupId)) then
                return false
            end
        end

        return true
    end

    --获取单章节进度
    function XStrongholdManager.GetChapterGroupProgress(chapterId)
        local finishCount, totalCount = 0, 0

        local groupIds = XStrongholdConfigs.GetGroupIds(chapterId)
        totalCount = #groupIds
        for _, groupId in pairs(groupIds) do
            if XStrongholdManager.IsGroupFinished(groupId) then
                finishCount = finishCount + 1
            end
        end

        return finishCount, totalCount
    end

    ---已解锁战区是否全部通关
    function XStrongholdManager.CheckAllChapterIsClear(chapterType)
        local chapterIds = XStrongholdConfigs.GetAllChapterIds(chapterType)
        for _, chapterId in pairs(chapterIds) do
            if XStrongholdManager.CheckChapterUnlock(chapterId) then
                local finishCount, totalCount = XStrongholdManager.GetChapterGroupProgress(chapterId)
                if finishCount < totalCount then
                    return false
                end
            end
        end
        return true
    end

    function XStrongholdManager.CheckChapterNoUseEnduranceIsClear(chapterType)
        local chapterIds = XStrongholdConfigs.GetAllChapterIds(chapterType)
        for _, chapterId in pairs(chapterIds) do
            if XStrongholdManager.CheckChapterNotCostEndurance(chapterId) and XStrongholdManager.CheckChapterUnlock(chapterId) then
                local finishCount, totalCount = XStrongholdManager.GetChapterGroupProgress(chapterId)
                if finishCount < totalCount then
                    return false
                end
            end
        end
        return true
    end

    function XStrongholdManager.CheckChapterIsClear()
        local chapterIds = XDataCenter.StrongholdManager.GetChaptersByLevel()
        for _, chapterId in pairs(chapterIds) do
            if XStrongholdManager.CheckChapterUnlock(chapterId) then
                local finishCount, totalCount = XStrongholdManager.GetChapterGroupProgress(chapterId)
                if finishCount < totalCount then
                    return false
                end
            end
        end
        return true
    end

    --检查词缀是否激活
    function XStrongholdManager.CheckBuffActive(buffId, isBossBuff)
        local ret, desc = true, ""
        local conditionId = XStrongholdConfigs.GetBuffConditionId(buffId)
        if IsNumberValid(conditionId) then
            ret, desc = XConditionManager.CheckCondition(conditionId)
        end
        return ret, desc
    end

    function XStrongholdManager.GetCurrentSelectGroupId()
        return _CurrentSelectGroupId
    end

    function XStrongholdManager.SetCurrentSelectGroupId(groupId)
        _CurrentSelectGroupId = groupId or 0
    end

    --检查是否有未完成的据点,并有足够耐力挑战
    function XStrongholdManager.CheckHasUnFinishedCanFightGroup()
        --当日首次登陆，且困难章节有可挑战据点
        if XStrongholdManager.CheckHardChapterCanFight() then
            return true
        end

        local groupIds = XStrongholdConfigs.GetAllGroupIds(XStrongholdConfigs.ChapterType.Normal)
        for _, groupId in pairs(groupIds) do
            if not XStrongholdManager.IsGroupFinished(groupId) then
                local costEndurance = XStrongholdManager.GetGroupCostEndurance(groupId)
                local curEndurance = XStrongholdManager.GetCurEndurance()
                return costEndurance <= curEndurance
            end
        end

        return false
    end

    function XStrongholdManager.SetCookieChapterHard()
        local key = XStrongholdManager.GetChapterHardCookieKey()
        XSaveTool.SaveData(key, 1)
    end

    function XStrongholdManager.GetCookieChapterHard()
        local key = XStrongholdManager.GetChapterHardCookieKey()
        return XSaveTool.GetData(key)
    end

    function XStrongholdManager.GetChapterHardCookieKey()
        if not IsNumberValid(_ActivityId) then
            return ""
        end
        local refreshTime = XTime.GetSeverNextRefreshTime()
        return string.format("XStrongholdManager_ChapterHard_%d_%d_%d", XPlayer.Id, _ActivityId, refreshTime)
    end

    function XStrongholdManager.SetCookieChapterHardFirstOpen()
        local key = XStrongholdManager.GetChapterHardFirstOpenCookieKey()
        XSaveTool.SaveData(key, 1)
    end

    function XStrongholdManager.GetCookieChapterHardFirstOpen()
        local key = XStrongholdManager.GetChapterHardFirstOpenCookieKey()
        return XSaveTool.GetData(key)
    end

    function XStrongholdManager.GetChapterHardFirstOpenCookieKey()
        if not IsNumberValid(_ActivityId) then
            return ""
        end
        return string.format("XStrongholdManager_ChapterHard_%d_%d", XPlayer.Id, _ActivityId)
    end

    --困难章节首次开启
    function XStrongholdManager.CheckHardChapterFirstOpen()
        if not XStrongholdManager.IsChapterHardCanShow() then
            return false
        end

        if XStrongholdManager.GetCookieChapterHardFirstOpen() then
            return false
        end

        XUiManager.TipText("StrongholdActivityChapterHardFirstOpen")
        XStrongholdManager.SetCookieChapterHardFirstOpen()
    end

    --当日首次登陆，且困难章节有可挑战据点
    function XStrongholdManager.CheckHardChapterCanFight()
        if not XStrongholdManager.IsChapterHardCanShow() then
            return false
        end

        if XStrongholdManager.GetCookieChapterHard() then
            return false
        end

        local chapterIds = XStrongholdConfigs.GetAllChapterIds(XStrongholdConfigs.ChapterType.Hard)
        for _, chapterId in pairs(chapterIds) do
            if XStrongholdManager.CheckChapterUnlock(chapterId) then
                local groupIds = XStrongholdConfigs.GetAllGroupIds(XStrongholdConfigs.ChapterType.Hard)
                for _, groupId in pairs(groupIds) do
                    if not XStrongholdManager.IsGroupFinished(groupId) then
                        return true
                    end
                end
            end
        end

        return false
    end

    --重置据点进度
    function XStrongholdManager.ResetStrongholdGroupRequest(groupId, cb)
        local req = {Id = groupId}
        XNetwork.Call(
            "ResetStrongholdGroupRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                ResetGroupInfo(groupId)
                XStrongholdManager.KickOutInvalidMembersInTeamList()
                --队伍信息中的援助角色也已经失效，需要清理
                XStrongholdManager.ResetCurFightInfo()

                CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE)

                if cb then
                    cb()
                end
            end
        )
    end

    --重置关卡进度
    function XStrongholdManager.ResetStrongholdStageRequest(groupId, stageId, cb)
        local req = {GroupId = groupId, StageId = stageId}
        XNetwork.Call(
            "ResetStrongholdStageRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                ResetGroupInfo(groupId, stageId)
                XStrongholdManager.KickOutInvalidMembersInTeamList()
                --队伍信息中的援助角色也已经失效，需要清理
                XStrongholdManager.ResetCurFightInfo()

                CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE)

                if cb then
                    cb()
                end
            end
        )
    end

    --更新完成过的据点列表
    function XStrongholdManager.NotifyStrongholdFinishGroupId(data)
        UpdateNewFinishGroupIds(data.FinishGroupIds)
        UpdateFinishGroupIds(data.FinishGroupIds)
        UpdateMaxElectricEnergy(data.ElectricEnergy)
        UpdateFinishGroupUseElectricEnergy(data.FinishGroupInfos, data.HistoryFinishGroupInfos)
    end

    --更新复刷据点使用的电量
    function XStrongholdManager.NotifyStrongholdFinishGroupInfo(data)
        UpdateFinishGroupUseElectricEnergy(data.FinishGroupInfos, data.HistoryFinishGroupInfos)
    end

    --更新据点信息
    function XStrongholdManager.NotifyUpdateStrongholdGroupData(data)
        UpdateGroupInfos({data.GroupInfo})
    end

    --删除据点信息
    function XStrongholdManager.NotifyDeleteStrongholdGroupData(data)
        ResetGroupInfo(data.Id)
    end

    --据点组是否可以扫荡
    function XStrongholdManager.IsAutoFightByGroupId(groupId)
        local isOpen, desc = false, ""
        if not XStrongholdManager.IsSelectedLevelId() then
            return isOpen, desc
        end

        local conditionId = XStrongholdConfigs.GetGroupSweepCondition(groupId, XStrongholdManager.GetLevelId())
        local isFinished = XDataCenter.StrongholdManager.IsGroupFinished(groupId)
        if not isFinished and XTool.IsNumberValid(conditionId) then
            isOpen, desc = XConditionManager.CheckCondition(conditionId)
        end
        return isOpen, desc
    end
    
    --配置扫荡条件且未满足则显示条件文本
    function XStrongholdManager.GetAutoFightConditionDesc(groupId)
        local conditionId = XStrongholdConfigs.GetGroupSweepCondition(groupId, XStrongholdManager.GetLevelId())
        if XTool.IsNumberValid(conditionId) then
            local isOpen, desc = XConditionManager.CheckCondition(conditionId)
            return isOpen and "" or desc
        end
        return ""
    end
    
    -----------------据点相关 end------------------
    -----------------队伍相关 begin------------------
    ---@type XStrongholdTeam[]
    local _TeamList = {} --队伍列表
    local _MaxTeamNum = 0 --最大队伍数量

    local function InitTeamList()
        _MaxTeamNum = XStrongholdConfigs.GetMaxTeamNum()

        for teamId = 1, _MaxTeamNum do
            local team = XStrongholdTeam.New(teamId)
            _TeamList[teamId] = team
        end
    end

    local function GetTeam(teamId)
        local team = _TeamList[teamId]
        if not team then
            XLog.Error("XStrongholdManager GetTeam error, 找不到队伍数据, teamId: ", teamId .. ", _TeamList: ", _TeamList)
            return
        end
        return team
    end

    local function ClearTeamList()
        for teamId, team in pairs(_TeamList) do
            team:Reset()
        end
    end

    --原始需求：
    --战斗队伍的修改要同步到预设队伍
    --战斗队伍的修改不能影响到预设队伍其他未使用梯队
    --需求冲突：
    --无法保证被部分修改后的预设队伍合法性
    local function UpdateTeamList(data)
        ClearTeamList()
        if IsTableEmpty(data) then
            return
        end

        -- local synedTeamIdCheckDic = {}
        --从服务端同步的真实队伍信息
        for _, teamInfo in pairs(data) do
            local teamId = teamInfo.Id
            -- synedTeamIdCheckDic[teamId] = teamId
            local team = GetTeam(teamId)
            team:Reset()
            team:SetCaptainPos(teamInfo.CaptainPos)
            team:SetFirstPos(teamInfo.FirstPos)
            team:SetRune(teamInfo.RuneId, teamInfo.SubRuneId)
            team:SetElementId(teamInfo.ElementId)

            for _, memberInfo in pairs(teamInfo.CharacterInfos) do
                team:SetMember(
                    memberInfo.Pos,
                    memberInfo.Id,
                    memberInfo.PlayerId,
                    memberInfo.RobotId,
                    memberInfo.Ability
                )
            end

            for _, pluginInfo in pairs(teamInfo.PluginInfos) do
                team:SetPlugin(pluginInfo.Id, pluginInfo.Count)
            end
        end

        -- --同步完毕后对本地缓存队伍进行队员重复性检查
        -- for teamId, team in pairs(_TeamList) do
        --     if not synedTeamIdCheckDic[teamId] then
        --     end
        -- end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_TEAMLIST_CHANGE)
    end

    --从队伍列表生成原始服务端队伍数据
    local function GenerateOriginalTeamInfos(teamList)
        local teamInfos = {}

        local stageIdList = XDataCenter.StrongholdManager.GetMostStageIdList()

        for index, team in pairs(teamList) do
            local teamInfo = {}

            teamInfo.Id = team:GetId()
            teamInfo.CaptainPos = team:GetCaptainPos()
            teamInfo.FirstPos = team:GetFirstPos()
            teamInfo.RuneId, teamInfo.SubRuneId = team:GetRune()

            local stageId = stageIdList[index]
            local recommendType = XTool.IsNumberValid(stageId) and XFubenConfigs.GetStageRecommendCharacterType(stageId) or 0
            local element
            if recommendType == XEnumConst.CHARACTER.CharacterType.Isomer then
                element = XStrongholdManager.IsomerTeamElementId
            elseif recommendType == XEnumConst.CHARACTER.CharacterType.Sp then
                element = XStrongholdManager.SpTeamElementId
            else
                element = XTool.IsNumberValid(stageId) and XFubenConfigs.GetStageRecommendCharacterElement(stageId) or 0
            end
            teamInfo.ElementId = element

            teamInfo.CharacterInfos = {}
            local members = team:GetAllMembers()

            --一队固定3角色
            for i = 1, 3 do
                local member = members[i]
                local characterInfo = {}
                characterInfo.Pos = member and member:GetPos() or i
                local robotId = member and member:GetRobotId() or 0
                characterInfo.RobotId = robotId
                local characterId = member and member:GetCharacterId() or 0
                characterInfo.Id = IsNumberValid(characterId) and characterId or XRobotManager.GetCharacterId(robotId)
                --服务端他一定要kt.
                characterInfo.PlayerId = member and member:GetPlayerId() or 0
                characterInfo.Ability = member and member:GetAbility() or 0
                tableInsert(teamInfo.CharacterInfos, characterInfo)
            end

            teamInfo.PluginInfos = {}
            local plugins = team:GetAllPlugins()
            for _, plugin in pairs(plugins) do
                local pluginInfo = {}
                pluginInfo.Id = plugin:GetId()
                pluginInfo.Count = plugin:GetCount()
                tableInsert(teamInfo.PluginInfos, pluginInfo)
            end

            tableInsert(teamInfos, teamInfo)
        end

        return teamInfos
    end

    --把上一期的编队根据这一期的关卡元素推荐设置
    local function CheckUpdateTeam()
        if not XStrongholdManager.IsOpen() then
            return
        end

        local curActivityId = _ActivityId
        local levelId = XStrongholdManager.GetLevelId()
        if not XTool.IsNumberValid(curActivityId) or not XTool.IsNumberValid(levelId) then
            return
        end

        local teamActivityIdCookieKey = XPlayer.Id .. "_XStrongholdManager_TeamActivityId"
        local lastActivityId = XSaveTool.GetData(teamActivityIdCookieKey) or XStrongholdManager.GetLastActivityId()
        if lastActivityId == curActivityId then
            return
        end

        XSaveTool.SaveData(teamActivityIdCookieKey, curActivityId)
        local stageIdList = XDataCenter.StrongholdManager.GetMostStageIdList()
        local teamList = XDataCenter.StrongholdManager.GetTeamListTemp()

        for i, team in ipairs(teamList) do
            local stageId = stageIdList[i]
            if not XTool.IsNumberValid(stageId) then
                goto continue
            end

            for j = 1, #teamList do
                local recommendElement = XFubenConfigs.GetStageRecommendCharacterElement(stageId)
                local recommendType = XFubenConfigs.GetStageRecommendCharacterType(stageId)
                local teamTemp = teamList[j]
                local teamElementId = teamTemp:GetElementId()
                if (teamElementId == recommendElement) or
                    (recommendType == XEnumConst.CHARACTER.CharacterType.Sp and teamElementId == XStrongholdManager.SpTeamElementId) or
                    (recommendType == XEnumConst.CHARACTER.CharacterType.Isomer and teamElementId == XStrongholdManager.IsomerTeamElementId)
                 then
                    if i ~= j then
                        local teamIdTemp = team:GetId()
                        team:SetId(teamTemp:GetId())
                        teamTemp:SetId(teamIdTemp)
                        teamList[i], teamList[j] = teamList[j], teamList[i]
                    end
                    goto continue
                end
            end
            :: continue ::
        end

        XDataCenter.StrongholdManager.SetStrongholdTeamRequest(teamList)
    end

    function XStrongholdManager.GetTeamListTemp()
        return Clone(_TeamList)
    end
    
    --据说TeamList的数据会直接保存至服务器，为了解决预设梯队跟当前关卡队伍不一样的问题新建一个FighterTeamList
    ---@return XStrongholdTeam[]
    function XStrongholdManager.GetFighterTeamListTemp(teamList,groupId)
        if not XTool.IsNumberValid(groupId) then
            return teamList
        end
        local requireTeamIds = XStrongholdManager.GetTeamPropsByGroupId(groupId)
        local fighterTeamList = {}
        for index, teamId in ipairs(requireTeamIds) do
            table.insert(fighterTeamList, teamList[teamId])
        end
        return fighterTeamList
    end

    --获取根据据点人数要求裁剪后的队伍列表Clone(bad performance cause GC)
    function XStrongholdManager.GetTeamListClipTemp(groupId, teamList)
        ---@type XStrongholdTeam[]
        local teamList = teamList and Clone(teamList) or Clone(_TeamList)
        local fightTeamList = {}

        local isPrefab = not IsNumberValid(groupId)

        if not isPrefab then
            --战斗编队模式下按照关卡队伍要求修整队伍
            local requireTeamMemberDic = XStrongholdManager.GetTeamPropsByGroupId(groupId)

            --剔除不在配置的队伍要求人数字典中的队伍
            for _, team in pairs(teamList) do
                local id = team:GetId()
                if table.indexof(requireTeamMemberDic, id) then
                    --按照队伍要求人数裁剪每个队伍中多余的队员
                    local requireCount = XStrongholdConfigs.GetGroupRequireTeamMemberNum(groupId, id)
                    local index = XStrongholdManager.GetTeamIndexByProp(groupId, id)
                    team:ClipMembers(requireCount)
                    fightTeamList[index] = team
                end
            end
        else
            --预设模式下剔除掉自己拥有的角色以外的队伍成员
            for _, team in pairs(teamList) do
                team:KickOutOtherMembers()
            end
            fightTeamList = teamList
        end

        XStrongholdManager.KickOutInvalidMembersInTeamList(fightTeamList, groupId)

        return fightTeamList
    end

    --剔除队伍列表中已经失效的援助角色和试玩角色
    function XStrongholdManager.KickOutInvalidMembersInTeamList(teamList, groupId)
        teamList = teamList or _TeamList
        local levelId = XStrongholdManager.GetLevelId()
        local robotIdList, canUseRobotIdDic
        if groupId and XTool.IsNumberValid(levelId) then
            robotIdList, canUseRobotIdDic = XStrongholdConfigs.GetGroupCanUseRobotIds(groupId, nil, levelId)
        end
        if XTool.IsNumberValid(groupId) then
            local teamPropIds = XStrongholdManager.GetTeamPropsByGroupId(groupId)
            for _, teamPropId in pairs(teamPropIds) do
                local stageIndex = XStrongholdManager.GetTeamIndexByProp(groupId, teamPropId)
                --有关卡挑战进度的角色不清
                if not XStrongholdManager.IsGroupStageFinished(groupId, stageIndex) then
                    local team = XStrongholdManager.GetTeamByPropId(teamList, teamPropId)
                    if team then
                        team:KickOutInvalidMembers(canUseRobotIdDic)
                    end
                end
            end
        else
            -- 预设界面groupId为空
            for stageIndex, team in pairs(teamList) do
                if not XStrongholdManager.IsGroupStageFinished(groupId, stageIndex) then
                    team:KickOutInvalidMembers(canUseRobotIdDic)
                end
            end
        end
    end

    function XStrongholdManager.GetTeamByPropId(teamList, teamPropId)
        for _, team in pairs(teamList) do
            if team:GetId() == teamPropId then
                return team
            end
        end
        return nil
    end

    --重置队伍列表
    function XStrongholdManager.ClearTeamList(teamList)
        teamList = teamList or _TeamList
        for _, team in pairs(teamList) do
            team:Clear()
        end
    end

    --自动编队
    --依照玩家拥有的角色进行填充，自队伍1至队伍5
    --填充时先按照最后一个关卡组中的每个关卡对应的优势属性，优先上阵推荐属性的角色
    --然后按照玩家拥有角色的战力高低进行填充
    --支援和试用角色不会自动上阵
    --未设置符文的梯队自左至右，按照符文表的ID依次填充，全部使用第一个子符文
    function XStrongholdManager.AutoTeam(teamList)
        teamList = teamList or _TeamList

        XStrongholdManager.ClearTeamList(teamList)

        --自动编队仅上阵已拥有构造体
        local ownCharacters = XMVCA.XCharacter:GetOwnCharacterList()
        tableSort(
            ownCharacters,
            function(a, b)
                return a.Ability > b.Ability
            end
        )

        local waitCharacterIds = {}
        for _, character in ipairs(ownCharacters) do
            local characterId = character.Id
            --不能在电能支援队伍中
            if not XStrongholdManager.CheckInElectricTeam(characterId) then
                tableInsert(waitCharacterIds, characterId)
            end
        end

        local requireTeamIds = XStrongholdManager.GetGroupRequireTeamIds()

        --每支队伍先上阵推荐属性的角色
        for _, teamId in ipairs(requireTeamIds) do
            local team = teamList[teamId]
            local stageId = XStrongholdConfigs.GetReserveTeamStageId(teamId)
            local memberNum = XStrongholdConfigs.GetMaxTeamMemberNum()
            for pos = 1, memberNum do
                if stageId then
                    for index, characterId in ipairs(waitCharacterIds) do
                        if XFubenConfigs.IsStageRecommendCharacterType(stageId, characterId) then
                            local member = team:GetMember(pos)
                            member:SetCharacterId(characterId)
                            tableRemove(waitCharacterIds, index)
                            break
                        end
                    end
                end
            end
        end

        for _, teamId in ipairs(requireTeamIds) do
            local team = teamList[teamId]
            local memberNum = XStrongholdConfigs.GetMaxTeamMemberNum()
            for pos = 1, memberNum do
                local member = team:GetMember(pos)
                if member:IsEmpty() then
                    for index, characterId in ipairs(waitCharacterIds) do
                        local characterType = XMVCA.XCharacter:GetCharacterType(characterId)
                        if not team:ExistDifferentCharacterType(characterType) then
                            member:SetCharacterId(characterId)
                            tableRemove(waitCharacterIds, index)
                            break
                        end
                    end
                end
            end
        end

        XStrongholdManager.AutoRune(teamList)
    end

    function XStrongholdManager.GetLastGroupId()
        local allChapterIds = XStrongholdConfigs.GetAllChapterIds()
        local lastChapter = allChapterIds[#allChapterIds]
        local groupIds = XStrongholdConfigs.GetGroupIds(lastChapter)
        return groupIds[#groupIds]
    end

    --获得数量最多的关卡Id列表
    function XStrongholdManager.GetMostStageIdList()
        local allChapterIds = XStrongholdConfigs.GetAllChapterIds()
        local groupIds
        local stageIdList
        local stageIdListTemp
        for _, chapterId in ipairs(allChapterIds) do
            groupIds = XStrongholdConfigs.GetGroupIds(chapterId)
            for index, groupId in ipairs(groupIds) do
                stageIdListTemp = XStrongholdManager.GetGroupStageIds(groupId)
                if not stageIdList or #stageIdListTemp >= #stageIdList then
                    stageIdList = stageIdListTemp
                end
            end
        end
        return stageIdList or {}
    end

    --获取已使用电能总和
    function XStrongholdManager.GetTotalUseElectricEnergy(teamList)
        local useElectric = 0

        teamList = teamList or _TeamList
        for _, team in pairs(teamList) do
            useElectric = useElectric + team:GetUseElectricEnergy()
        end

        return useElectric
    end

    --检查队伍是否符合当前挑战的关卡中的队伍人数要求
    function XStrongholdManager.CheckCurGroupTeamFull(teamList)
        local groupId = XStrongholdManager.GetCurrentSelectGroupId()
        if not IsNumberValid(groupId) then
            return false
        end

        teamList = teamList or _TeamList
        local requireTeamNum = XStrongholdManager.GetTeamPropsByGroupId(groupId)
        for _, teamId in pairs(requireTeamNum) do
            local team = teamList[teamId]
            local requireTeamMemberNum = XStrongholdConfigs.GetGroupRequireTeamMemberNum(groupId, teamId)
            for pos = 1, requireTeamMemberNum do
                local member = team:GetMember(pos)
                if not member or member:IsEmpty() then
                    return false
                end
            end
        end

        return true
    end

    --获取队伍列表战力总和
    function XStrongholdManager.GetTeamListTotalAbility(teamList)
        local totalAbility = 0
        teamList = teamList or _TeamList
        for _, team in pairs(teamList) do
            local ability = team:GetTeamAbility()
            totalAbility = totalAbility + ability
        end
        return totalAbility
    end

    --检查队伍列表平均战力是否符合要求
    ---@param teamList XStrongholdTeam[]
    function XStrongholdManager.CheckTeamListAverageAbility(requireAbility, teamList)
        local groupId = XStrongholdManager.GetCurrentSelectGroupId()
        if not IsNumberValid(groupId) then
            return false
        end

        local totalAbility, memberCount = 0, 0

        teamList = teamList or _TeamList
        local requireTeamNum = XStrongholdManager.GetTeamPropsByGroupId(groupId)
        for _, teamId in pairs(requireTeamNum) do
            local team = teamList[teamId]
            local requireTeamMemberNum = XStrongholdConfigs.GetGroupRequireTeamMemberNum(groupId, teamId)
            for pos = 1, requireTeamMemberNum do
                if not team:CheckPosEmpty(pos) then
                    totalAbility = totalAbility + team:GetTeamMemberAbility(pos) + team:GetPluginAddAbility()
                    memberCount = memberCount + 1
                end
            end
        end

        local averageAbility = memberCount > 0 and totalAbility / memberCount or 0
        return averageAbility >= requireAbility, averageAbility
    end

    --检查队伍列表内的队伍中每名成员是否符合战力要求
    function XStrongholdManager.CheckTeamListEveryMemberAbility(requireAbility, teamList)
        local groupId = XStrongholdManager.GetCurrentSelectGroupId()
        if not IsNumberValid(groupId) then
            return false
        end

        teamList = teamList or _TeamList
        local requireTeamNum = XStrongholdManager.GetGroupRequireTeamNum(groupId)
        for teamId = 1, requireTeamNum do
            local team = teamList[teamId]
            local requireTeamMemberNum = XStrongholdConfigs.GetGroupRequireTeamMemberNum(groupId, teamId)
            if not team:CheckTeamEveryMemberAbility(requireAbility, requireTeamMemberNum) then
                return false
            end
        end

        return true
    end

    --检查角色是否在队伍列表中
    function XStrongholdManager.CheckInTeamList(characterId, teamList, playerId, notCheckTeamId)
        if not IsNumberValid(characterId) then
            return false
        end
        teamList = teamList or _TeamList
        for _, team in pairs(teamList) do
            if team:GetId() ~= notCheckTeamId and team:CheckInTeam(characterId, playerId) then
                return true
            end
        end
        return false
    end

    function XStrongholdManager.GetCharacterInTeamId(characterId, teamList, playerId)
        if not IsNumberValid(characterId) then
            return 0
        end
        teamList = teamList or _TeamList
        local isInTeam, pos
        for teamId, team in pairs(teamList) do
            isInTeam, pos = team:CheckInTeam(characterId, playerId)
            if isInTeam then
                return teamId, pos
            end
        end
        return 0, 0
    end

    function XStrongholdManager.GetTeamCaptinPosAndFirstPos(teamId, teamList)
        local team = teamList and teamList[teamId] or GetTeam(teamId)
        return team:GetCaptainPos(), team:GetFirstPos()
    end

    function XStrongholdManager.GetTeamShowCharacterIds(teamId, teamList)
        local team = teamList and teamList[teamId] or GetTeam(teamId)
        return team:GetShowCharacterIds()
    end

    --检查角色是否在队伍列表中并存在通关记录
    function XStrongholdManager.CheckInTeamListLock(groupId, characterId, teamList, playerId)
        if not IsNumberValid(groupId) then
            return false
        end
        local teamPropId = XStrongholdManager.GetCharacterInTeamId(characterId, teamList, playerId)
        if not IsNumberValid(teamPropId) then
            return false
        end
        local stageIndex = XDataCenter.StrongholdManager.GetTeamIndexByProp(groupId, teamPropId)
        return XStrongholdManager.IsGroupStageFinished(groupId, stageIndex)
    end

    --检查队伍列表中是否已上阵相同型号角色
    function XStrongholdManager.CheckTeamListExistSameCharacter(
        waitCharacterId,
        teamList,
        playerId,
        selectTeamId,
        selectMemberIndex)
        if not IsNumberValid(waitCharacterId) then
            return false
        end
        teamList = teamList or _TeamList

        local count = 1

        --在队伍中找到的相同型号角色的位置
        local findTeamId, findMemberIndex = 0, 0
        for teamId, team in pairs(teamList) do
            findMemberIndex = team:GetSameCharacterPos(waitCharacterId)
            if IsNumberValid(findMemberIndex) then
                findTeamId = teamId
                break
            end
        end

        --存在相同型号角色
        local existSameCharacter = IsNumberValid(findTeamId) and IsNumberValid(findMemberIndex)
        if existSameCharacter then
            count = count + 1

            --找到的角色位置即将被替换掉
            if selectTeamId == findTeamId and selectMemberIndex == findMemberIndex then
                count = count - 1
            end
        end

        --在队伍中找到的待操作角色的位置
        local waitTeamId, waitMemberIndex = 0, 0
        for teamId, team in pairs(teamList) do
            waitMemberIndex = team:GetInTeamMemberIndex(waitCharacterId, playerId)
            if IsNumberValid(waitMemberIndex) then
                waitTeamId = teamId
                break
            end
        end

        --待操作角色已经在队伍中
        local waitCharacterInTeam = IsNumberValid(waitTeamId) and IsNumberValid(waitMemberIndex)
        if waitCharacterInTeam then
            --找到的位置和待操作角色的位置相同
            local samePos = findTeamId == waitTeamId and findMemberIndex == waitMemberIndex
            if samePos then
                count = count - 1
            end
        end

        return count > 1
    end

    --检查队伍列表中是否已上阵支援角色（只能上阵一个）
    function XStrongholdManager.CheckTeamListExistAssitantCharacter(teamList)
        teamList = teamList or _TeamList
        for teamId, team in pairs(teamList) do
            if team:CheckExistAssitantCharacter() then
                return true
            end
        end
        return false
    end

    --检查队伍列表是否为空
    function XStrongholdManager.CheckTeamListEmpty(teamList, groupId)
        teamList = teamList or _TeamList
        for teamId, team in pairs(teamList) do
            local requireTeamMemberNum = XStrongholdConfigs.GetGroupRequireTeamMemberNum(groupId, teamId)
            for pos = 1, requireTeamMemberNum do
                if not team:CheckPosEmpty(pos) then
                    return false
                end
            end
        end
        return true
    end

    --检查队伍列表中所有队伍是否均有队长/首发
    function XStrongholdManager.CheckTeamListAllHasCaptainAndFirstPos(groupId, teamList)
        local allHasCaptain, allHasFirstPos = true, true

        local requireTeamNum = XStrongholdManager.GetGroupRequireTeamNum(groupId)
        teamList = teamList or _TeamList
        for teamId = 1, requireTeamNum do
            local team = teamList[teamId]
            if not team then
                return false, false
            end

            if not team:CheckHasCaptain() then
                allHasCaptain = false
            end
            if not team:CheckHasFirstPos() then
                allHasFirstPos = false
            end
        end

        return allHasCaptain, allHasFirstPos
    end

    -- 获取所有的可选角色 不分角色类型
    function XStrongholdManager.GetAllCanUseCharacterOrRobotIds(groupId)
        local isPrefab = not IsNumberValid(groupId)
        local levelId = XStrongholdManager.GetLevelId()
        local robotIds = not isPrefab and XStrongholdConfigs.GetGroupCanUseRobotIds(groupId, nil, levelId) or {}
        local res = {}

        for k, id in pairs(robotIds) do
            table.insert(res, {Id = id})
        end

        local characterList = XMVCA.XCharacter:GetOwnCharacterList()
        for k, v in pairs(characterList) do
            table.insert(res, v)
        end

        return res
    end

    function XStrongholdManager.GotOverrideSortList(initSelectCharId, groupId, teamId)
        local stageId = nil
        if IsNumberValid(groupId) then
            stageId = XStrongholdManager.GetGroupStageId(groupId, teamId)
        end
        local sortOverride = 
        {
            CheckFunList = 
            {   
                -- 选中角色
                [CharacterSortFunType.Custom1] = function (idA, idB)
                    local isASele = initSelectCharId == idA
                    local isBSele = initSelectCharId == idB
                    if isASele ~= isBSele then
                        return true
                    end
                end,
                -- 推荐角色
                [CharacterSortFunType.Custom2] = function (idA, idB)
                    if not IsNumberValid(stageId) then
                        return false
                    end
                    local isA = XFubenConfigs.IsStageRecommendCharacterType(stageId, idA)
                    local isB = XFubenConfigs.IsStageRecommendCharacterType(stageId, idB)
                    if isA ~= isB then
                        return true
                    end
                end,
                -- 非电能支援靠前
                [CharacterSortFunType.Custom3] = function (idA, idB)
                    local aIsElectric = XDataCenter.StrongholdManager.CheckInElectricTeam(idA)
                    local bIsElectric = XDataCenter.StrongholdManager.CheckInElectricTeam(idB)
                    if aIsElectric ~= bIsElectric then
                        return true
                    end
                end,
            },
            SortFunList = 
            {
                [CharacterSortFunType.Custom1] = function (idA, idB)
                    local isASele = initSelectCharId == idA
                    local isBSele = initSelectCharId == idB
                    if isASele ~= isBSele then
                        return isASele
                    end
                end,
                [CharacterSortFunType.Custom2] = function (idA, idB)
                    local isA = XFubenConfigs.IsStageRecommendCharacterType(stageId, idA)
                    local isB = XFubenConfigs.IsStageRecommendCharacterType(stageId, idB)
                    if isA ~= isB then
                        return isA
                    end
                end,
                [CharacterSortFunType.Custom3] = function (idA, idB)
                    local aIsElectric = XDataCenter.StrongholdManager.CheckInElectricTeam(idA)
                    local bIsElectric = XDataCenter.StrongholdManager.CheckInElectricTeam(idB)
                    if aIsElectric ~= bIsElectric then
                        return not aIsElectric
                    end
                end,
            }
        }
    
        return sortOverride
    end
    

    --获取可上阵已拥有角色/机器人
    function XStrongholdManager.GetCanUseCharacterOrRobotIds(groupId, stageIndex, characterType, teamList)
        local isPrefab = not IsNumberValid(groupId)
        local levelId = XStrongholdManager.GetLevelId()
        local ids = not isPrefab and XStrongholdConfigs.GetGroupCanUseRobotIds(groupId, characterType, levelId) or {}

        local characterList = XMVCA.XCharacter:GetOwnCharacterList(characterType)
        for _, character in pairs(characterList) do
            tableInsert(ids, character.Id)
        end

        local stageId = groupId and XStrongholdManager.GetGroupStageId(groupId, stageIndex) or nil
        teamList = teamList or _TeamList
        tableSort(
            ids,
            function(aId, bId)
                --电能支援
                local aIsElectric = XStrongholdManager.CheckInElectricTeam(aId)
                local bIsElectric = XStrongholdManager.CheckInElectricTeam(bId)
                if aIsElectric ~= bIsElectric then
                    return not aIsElectric
                end

                --已经上阵
                local aIsInTeam = XStrongholdManager.CheckInTeamList(aId, teamList)
                local bIsInTeam = XStrongholdManager.CheckInTeamList(bId, teamList)
                if aIsInTeam ~= bIsInTeam then
                    return not aIsInTeam
                end

                --关卡推荐排序
                if stageId then
                    local aIsStageRecomend = XFubenConfigs.IsStageRecommendCharacterType(stageId, aId)
                    local bIsStageRecomend = XFubenConfigs.IsStageRecommendCharacterType(stageId, bId)
                    if aIsStageRecomend ~= bIsStageRecomend then
                        return aIsStageRecomend
                    end
                end

                --自己战力比试玩推荐角色高的优先
                if stageId then
                    local aIsMediumRecommend = XStrongholdManager.CheckIsMediumRecommend(aId, stageId)
                    local bIsMediumRecommend = XStrongholdManager.CheckIsMediumRecommend(bId, stageId)
                    if aIsMediumRecommend ~= bIsMediumRecommend then
                        return aIsMediumRecommend
                    end
                end

                --试玩角色
                local aIsRobot = XRobotManager.CheckIsRobotId(aId)
                local bIsRobot = XRobotManager.CheckIsRobotId(bId)
                if aIsRobot ~= bIsRobot then
                    return aIsRobot
                end

                --战力排序
                local aAbility =
                    aIsRobot and XRobotManager.GetRobotAbility(aId) or
                    XMVCA.XCharacter:GetCharacterAbilityById(aId)
                local bAbility =
                    bIsRobot and XRobotManager.GetRobotAbility(bId) or
                    XMVCA.XCharacter:GetCharacterAbilityById(bId)
                if aAbility ~= bAbility then
                    return aAbility > bAbility
                end

                return false
            end
        )

        return ids
    end

    --检查是否中等推荐
    function XStrongholdManager.CheckIsMediumRecommend(charId, stageId)
        if not stageId then
            return false
        end

        local isStageRecomend = XFubenConfigs.IsStageRecommendCharacterType(stageId, charId)
        if not isStageRecomend then
            return false
        end

        local isRobot = XRobotManager.CheckIsRobotId(charId)
        if not isRobot then
            return true
        end

        local notRobotCharacterId = XRobotManager.GetCharacterId(charId)
        local notRobotCharAbility = XMVCA.XCharacter:GetCharacterAbilityById(notRobotCharacterId)
        local robotCharAbility = XRobotManager.GetRobotAbility(charId)
        return robotCharAbility > notRobotCharAbility
    end

    function XStrongholdManager.CompareTeamLists(teamList1, teamList2)
        if IsTableEmpty(teamList1) and IsTableEmpty(teamList2) then
            return true
        end

        if not teamList1 then
            return false
        end
        if not teamList2 then
            return false
        end

        for teamId, team1 in pairs(teamList1) do
            local team2 = teamList2[teamId]
            if not team1:Compare(team2) then
                return false
            end
        end

        return true
    end

    --设置预设队伍
    function XStrongholdManager.SetStrongholdTeamRequest(teamList, isOwn, cb)
        if not XStrongholdManager.IsOpen() then
            return
        end

        local teamInfos = GenerateOriginalTeamInfos(teamList)
        if isOwn == nil then
            isOwn = false
        --是否仅保存自己拥有的角色
        end

        --队伍数据未变动时不同步服务端
        if XStrongholdManager.CompareTeamLists(teamList, _TeamList) then
            UpdateTeamList(teamInfos)
            if cb then
                cb()
            end

            return
        end

        local req = {TeamInfos = teamInfos, Own = isOwn}
        XNetwork.Call(
            "SetStrongholdTeamRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateTeamList(teamInfos)

                if cb then
                    cb()
                end
            end
        )
    end

    --检查耐力
    function XStrongholdManager.CheckEndurance(groupId)
        local costEndurance = XStrongholdManager.GetGroupCostEndurance(groupId)
        local curEndurance = XStrongholdManager.GetCurEndurance()
        if costEndurance > curEndurance then
            XUiManager.TipText("StrongholdEnterFightEnduranceLack")
            return false
        end
        return true
    end

    --设置战斗队伍
    function XStrongholdManager.SetStrongholdFightTeamRequest(groupId, teamList, cb, ignoreRepeatCheck)
        if not XStrongholdManager.IsOpen() then
            return
        end

        --检查耐力
        if not XStrongholdManager.CheckEndurance(groupId) then
            return
        end

        --检查电能是否溢出
        if XStrongholdManager.CheckElectricOverLimit(nil, teamList, groupId) then
            XUiManager.TipText("StrongholdEnterFightElectricOver")
            return
        end

        --检查队伍列表中所有需要的队伍是否均有队长/首发
        local allHasCaptain, allHasFirstPos =
            XStrongholdManager.CheckTeamListAllHasCaptainAndFirstPos(groupId, teamList)
        if not allHasCaptain then
            XUiManager.TipText("StrongholdEnterFightTeamListNoCaptain")
            return
        end
        if not allHasFirstPos then
            XUiManager.TipText("StrongholdEnterFightTeamListNoFirstPos")
            return
        end

        --使用了支援角色
        if XStrongholdManager.CheckTeamListExistAssitantCharacter(teamList) then
            --支援次数不足
            local times = XStrongholdManager.GetBorrowCount()
            local maxTimes = XStrongholdConfigs.GetBorrowMaxTimes()
            if times >= maxTimes then
                XUiManager.TipText("StrongholdBorrowMaxTimes")
                return
            end

            --支援消耗不足
            local itemId, count = XStrongholdConfigs.GetBorrowCostItemInfo(times)
            if not XDataCenter.ItemManager.CheckItemCountById(itemId, count) then
                XUiManager.TipText("StrongholdBorrowCostLack")
                return
            end
        end

        local temp = {}
        local teamInfos = GenerateOriginalTeamInfos(teamList)

        --队伍数据未变动时不同步服务端
        if not ignoreRepeatCheck and XStrongholdManager.CompareTeamLists(teamList, _TeamList) then
            UpdateTeamList(teamInfos)
            if cb then
                cb()
            end

            return
        end

        local req = {Id = groupId, TeamInfos = teamInfos}
        XNetwork.Call(
            "SetStrongholdFightTeamRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                CatchOldData()

                if cb then
                    cb()
                end
            end
        )
    end
    -----------------队伍相关 end------------------
    -----------------援助角色（来自于其他玩家） begin------------------
    local _BorrowCount = 0 --援助次数
    local _AssistantCharacters = {} --援助角色列表（来自于其他玩家）

    local function UpdateBorrowCount(data)
        _BorrowCount = data or _BorrowCount

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_BORROW_COUNT_CHANGE)
    end

    --[[ // 援助角色详情
[MessagePackObject(keyAsPropertyName: true)]
public class StrongholdAssistCharacterDetail
{
    public int Id;
    public string Name;
    public XCharacterData Character;
    public List<XEquipData> Equips = new List<XEquipData>(); 
}
    ]]
    local function UpdateAssistantCharacters(data)
        _AssistantCharacters = {}
        for _, info in pairs(data) do
            local id = info.Id
            _AssistantCharacters[id] = info
        end
    end

    local function GetAssistantInfo(playerId)
        if not IsNumberValid(playerId) then
            return
        end
        return _AssistantCharacters[playerId]
    end
    XStrongholdManager.GetAssistantInfo = GetAssistantInfo

    function XStrongholdManager.GetBorrowCount()
        return _BorrowCount
    end

    function XStrongholdManager.GetAssistantPlayerIds(groupId, stageIndex, teamList)
        local playerIds = {}
        for playerId in pairs(_AssistantCharacters) do
            tableInsert(playerIds, playerId)
        end

        teamList = teamList or _TeamList
        local stageId = groupId and XStrongholdManager.GetGroupStageId(groupId, stageIndex) or nil
        tableSort(
            playerIds,
            function(aPlayerId, bPlayerId)
                local aId = XStrongholdManager.GetAssistantPlayerCharacterId(aPlayerId)
                local bId = XStrongholdManager.GetAssistantPlayerCharacterId(bPlayerId)

                --已经上阵
                local aIsInTeam = XStrongholdManager.CheckInTeamList(aId, teamList, aPlayerId)
                local bIsInTeam = XStrongholdManager.CheckInTeamList(bId, teamList, bPlayerId)
                if aIsInTeam ~= bIsInTeam then
                    return not aIsInTeam
                end

                --关卡推荐排序
                if stageId then
                    local aIsStageRecomend = XFubenConfigs.IsStageRecommendCharacterType(stageId, aId)
                    local bIsStageRecomend = XFubenConfigs.IsStageRecommendCharacterType(stageId, bId)
                    if aIsStageRecomend ~= bIsStageRecomend then
                        return aIsStageRecomend
                    end
                end

                --战力排序
                local aAbility = XStrongholdManager.GetAssistantPlayerAbiility(aPlayerId)
                local bAbility = XStrongholdManager.GetAssistantPlayerAbiility(bPlayerId)
                if aAbility ~= bAbility then
                    return aAbility > bAbility
                end

                return false
            end
        )

        return playerIds
    end

    function XStrongholdManager.GetAssistantPlayerInfo(playerId)
        local info = GetAssistantInfo(playerId)
        return info and info.Character or nil
    end

    function XStrongholdManager.GetAssistantPlayerCharacterId(playerId)
        local info = GetAssistantInfo(playerId)
        return info and info.Character.Id or 0
    end

    function XStrongholdManager.GetAssistantPlayerFashionId(playerId)
        local info = GetAssistantInfo(playerId)
        return info and info.Character.FashionId or 0
    end

    function XStrongholdManager.GetAssistantPlayerLiberateLv(playerId)
        local info = GetAssistantInfo(playerId)
        return info and info.Character.LiberateLv or 0
    end

    function XStrongholdManager.GetAssistantPlayerAbiility(playerId)
        local info = GetAssistantInfo(playerId)
        return info and info.Character and info.Character.Ability or 0
    end

    function XStrongholdManager.CreateAssistantViewModel(id, playerId)
        local data = XStrongholdManager.GetAssistantPlayerInfo(playerId)
        local ability = XStrongholdManager.GetAssistantPlayerAbiility(playerId)
        local fashionId = XStrongholdManager.GetAssistantPlayerFashionId(playerId)
        local liberateLv = XStrongholdManager.GetAssistantPlayerLiberateLv(playerId)
        local characterId = XStrongholdManager.GetAssistantPlayerCharacterId(playerId)

        local characterViewModel = require("XEntity/XCharacter/XCharacterViewModel").New(characterId)
        characterViewModel:UpdateWithData(data)
        characterViewModel:UpdateAbility(ability)
        characterViewModel:UpdateFashionId(fashionId)
        characterViewModel:UpdateLiberateLv(liberateLv)
        characterViewModel:UpdateSourceEntityId(id)
        return characterViewModel
    end

    function XStrongholdManager.CheckAssitantValid(playerId, characterId)
        local info = GetAssistantInfo(playerId)
        if IsTableEmpty(info) then
            return false
        end
        return IsNumberValid(characterId) and XStrongholdManager.GetAssistantPlayerCharacterId(playerId) == characterId
    end

    function XStrongholdManager.CheckAssitantListWaitInit()
        return IsTableEmpty(_AssistantCharacters) and XStrongholdManager.CheckAssitantRefreshCD()
    end

    local _LastTimeGetStrongholdAssistCharacterListRequest = 0
    local _CDGetStrongholdAssistCharacterListRequest =
        XStrongholdConfigs.GetCommonConfig("RefreshAssistCharacterInterval")
    function XStrongholdManager.CheckAssitantRefreshCD()
        local now = XTime.GetServerNowTimestamp()
        local lastCd =
            mathCeil(
            _LastTimeGetStrongholdAssistCharacterListRequest + _CDGetStrongholdAssistCharacterListRequest - now
        )
        if lastCd > 0 then
            local desc = CS.XTextManager.GetText("StrongholdRefershAssistCharacterInCD", lastCd)
            return false, desc
        end
        return true, ""
    end

    ---第一次进活动界面时请求援助列表
    function XStrongholdManager.ReqAssistCharacterList()
        if not _HasReqAssistCharacterList then
            XStrongholdManager.GetStrongholdAssistCharacterListRequest()
            _HasReqAssistCharacterList = true
        end
    end

    --请求援助角色列表
    function XStrongholdManager.GetStrongholdAssistCharacterListRequest(cb)
        local now = XTime.GetServerNowTimestamp()
        local isRefreshCd, desc = XStrongholdManager.CheckAssitantRefreshCD()
        if not isRefreshCd then
            XUiManager.TipMsg(desc)
            return
        end
        _LastTimeGetStrongholdAssistCharacterListRequest = XTime.GetServerNowTimestamp()

        XNetwork.Call(
            "GetStrongholdAssistCharacterListRequest",
            nil,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateAssistantCharacters(res.CharacterDetails)

                if cb then
                    cb()
                end
            end
        )
    end

    --通知借用次数
    function XStrongholdManager.NotifyStrongholdBorrowCount(data)
        UpdateBorrowCount(data.BorrowCount)
    end
    -----------------援助角色（来自于其他玩家） end------------------
    -----------------支援相关（共享角色） begin------------------
    local _AssistantCharacterId = 0 --共享角色Id
    local _AssistantRecords = {} --支援记录

    local function UpdateShareCharacterId(data)
        if not IsNumberValid(data) then
            return
        end
        _AssistantCharacterId = data

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_SHARE_CHARACTER_CHANGE)
    end

    local function ClearAssitantRecords()
        _AssistantRecords = {}
    end

    local function UpdateAssistantRecords(data)
        ClearAssitantRecords()

        if not IsNumberValid(data) then
            return
        end

        for _, recordInfo in pairs(data) do
            local day = recordInfo.Id
            local record = XStrongholdAssistantRecord.New(day)
            record:UpdateData(recordInfo)
            _AssistantRecords[day] = record
        end
    end

    local function CheckHaveAssistantRecord()
        return not IsTableEmpty(_AssistantRecords)
    end

    function XStrongholdManager.GetAssitantRecordStrList()
        local recordStrList = {}

        local recordStr, record = ""
        local totalDay = XStrongholdManager.GetTotalDay()
        for day = 1, totalDay do
            record = _AssistantRecords[day]
            if record then
                if record:IsPause() then
                    recordStr = record:GetDelayRecordString()
                    if not stringIsNilOrEmpty(recordStr) then
                        tableInsert(recordStrList, recordStr)
                    end
                else
                    recordStr = record:GetDurationRewardRecordString()
                    if not stringIsNilOrEmpty(recordStr) then
                        tableInsert(recordStrList, recordStr)
                    end

                    recordStr = record:GetLendRewardRecordString()
                    if not stringIsNilOrEmpty(recordStr) then
                        tableInsert(recordStrList, recordStr)
                    end
                end
            end
        end

        return recordStrList
    end

    --援助开启
    function XStrongholdManager.CheckAssistantOpen()
        local conditionId = XStrongholdConfigs.GetCommonConfig("SetAssistCharacterCondition")
        return XConditionManager.CheckCondition(conditionId)
    end

    function XStrongholdManager.CheckCookieAssistantFirstOpen()
        if not XStrongholdManager.CheckAssistantOpen() then
            return
        end
        if XStrongholdManager.GetCookieAssistantFirstOpen() then
            return
        end

        XUiManager.TipText("StrongholdAssistantFirstOpen")
        XStrongholdManager.SetCookieAssistantFirstOpen()
    end

    function XStrongholdManager.SetCookieAssistantFirstOpen()
        local key = XStrongholdManager.GetAssistantFirstOpenCookieKey()
        XSaveTool.SaveData(key, true)
    end

    function XStrongholdManager.GetCookieAssistantFirstOpen()
        local key = XStrongholdManager.GetAssistantFirstOpenCookieKey()
        return XSaveTool.GetData(key) and true or false
    end

    function XStrongholdManager.GetAssistantFirstOpenCookieKey()
        if not IsNumberValid(_ActivityId) then
            return
        end
        return XPlayer.Id .. _ActivityId .. "_XStrongholdManager_CookieAssistantFirstOpen"
    end

    function XStrongholdManager.IsHaveAssistantCharacter()
        return _AssistantCharacterId > 0
    end

    function XStrongholdManager.GetAssistantCharacterId()
        return _AssistantCharacterId
    end

    function XStrongholdManager.CheckIsAssistantCharacter(characterId)
        return IsNumberValid(characterId) and _AssistantCharacterId == characterId
    end

    function XStrongholdManager.EnterUiAssistant()
        if not XStrongholdManager.CheckAssistantOpen() then
            return
        end

        --未拥有支援角色时直接打开UI
        if not XStrongholdManager.IsHaveAssistantCharacter() then
            XLuaUiManager.Open("UiStrongholdHelp")
            return
        end

        --拥有支援角色记录时直接打开UI
        if CheckHaveAssistantRecord() then
            XLuaUiManager.Open("UiStrongholdHelp")
            return
        end

        --未拥有支援角色记录时先请求记录
        local cb = function()
            XLuaUiManager.Open("UiStrongholdHelp")
        end
        XStrongholdManager.GetStrongholdLendDetailRequest(cb)
    end

    --设置共享角色
    local _LastTimeSetStrongholdAssistCharacterRequest = 0
    local _CDSetStrongholdAssistCharacterRequest = XStrongholdConfigs.GetCommonConfig("SetAssistCharacterInterval")
    function XStrongholdManager.SetStrongholdAssistCharacterRequest(characterId, cb)
        local now = XTime.GetServerNowTimestamp()
        local lastCd =
            mathCeil(_LastTimeSetStrongholdAssistCharacterRequest + _CDSetStrongholdAssistCharacterRequest - now)
        if lastCd > 0 then
            local desc = CS.XTextManager.GetText("StrongholdSetAssistCharacterInCD", lastCd)
            XUiManager.TipMsg(desc)
            return
        end
        _LastTimeSetStrongholdAssistCharacterRequest = now

        local req = {CharacterId = characterId}
        XNetwork.Call(
            "SetStrongholdAssistCharacterRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateShareCharacterId(characterId)

                CsXGameEventManager.Instance:Notify(
                    XEventId.EVENT_STRONGHOLD_ASSISTANT_CHARACTER_SET_CHANGE,
                    characterId
                )

                if cb then
                    cb()
                end
            end
        )
    end

    --查询借出奖励记录
    function XStrongholdManager.GetStrongholdLendDetailRequest(cb)
        XNetwork.Call(
            "GetStrongholdLendDetailRequest",
            nil,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateAssistantRecords(res.LendDayInfos)

                if cb then
                    cb()
                end
            end
        )
    end
    -----------------支援相关（共享角色） end------------------
    -----------------奖励（任务） begin------------------
    local _FinishedRewardIdDic = {}
    --已领取奖励Id字典

    local function UpdateFinishedRewardIds(data)
        if IsTableEmpty(data) then
            return
        end

        for _, rewardId in pairs(data) do
            if rewardId and rewardId > 0 then
                _FinishedRewardIdDic[rewardId] = rewardId
            end
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_FINISH_REWARDS_CHANGE)
    end

    function XStrongholdManager.GetAllRewardIds(levelId, rewardType)
        levelId = levelId or XStrongholdManager.GetLevelId()
        local rewardIds = XStrongholdConfigs.GetAllRewardIds(levelId, rewardType)

        tableSort(
            rewardIds,
            function(aId, bId)
                local aCanGet = XStrongholdManager.IsRewardCanGet(aId)
                local bCanGet = XStrongholdManager.IsRewardCanGet(bId)
                if aCanGet ~= bCanGet then
                    return aCanGet
                end

                local aIsFinished = XStrongholdManager.IsRewardFinished(aId)
                local bIsFinished = XStrongholdManager.IsRewardFinished(bId)
                if aIsFinished ~= bIsFinished then
                    return not aIsFinished
                end

                return aId < bId
            end
        )

        return rewardIds
    end

    function XStrongholdManager.GetCanReceiveReward()
        local rewardIds = {}
        for _, rewardId in pairs(XStrongholdManager.GetAllRewardIds()) do
            if XStrongholdManager.IsRewardCanGet(rewardId) then
                table.insert(rewardIds, rewardId)
            end
        end
        return rewardIds
    end

    function XStrongholdManager.IsRewardFinished(rewardId)
        return _FinishedRewardIdDic[rewardId]
    end

    function XStrongholdManager.IsRewardCanGet(rewardId)
        if not XStrongholdManager.IsOpen() or XStrongholdManager.IsFightEnd() then
            return
        end

        local conditionId = XStrongholdConfigs.GetRewardConditionId(rewardId)
        local ret, des, haveCount, requireCount = XConditionManager.CheckCondition(conditionId)
        return ret and not XStrongholdManager.IsRewardFinished(rewardId)
    end

    function XStrongholdManager.IsAnyRewardCanGet(rewardType)
        if not XStrongholdManager.IsOpen() then
            return
        end

        local rewardIds = XStrongholdManager.GetAllRewardIds(nil, rewardType)
        for _, rewardId in pairs(rewardIds) do
            if XStrongholdManager.IsRewardCanGet(rewardId) then
                return true
            end
        end
        return false
    end

    --领取奖励
    function XStrongholdManager.GetStrongholdRewardRequest(rewardIds, cb)
        local req = { Ids = rewardIds }
        XNetwork.Call(
            "GetStrongholdRewardRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateFinishedRewardIds(res.SuccessIds)

                local rewardGoods = res.RewardGoodsList
                if cb then
                    cb(rewardGoods)
                end
            end
        )
    end
    -----------------奖励（任务） end------------------
    -----------------上期战报 begin------------------
    local _LastActivityId = 0 --活动id
    local _LastMinerCount = 0 --矿工数量
    local _LastMineralCount = 0 --矿石数量
    local _LastAssistCount = 0 --支援次数
    local _LastAssistRewardValue = 0 --支援奖励
    local _LastFinishCount = 0 --完成据点数量

    local function UpdateLastAcitivityRecord(data)
        if IsTableEmpty(data) then
            return
        end

        _LastActivityId = data.Id or 0
        _LastMinerCount = data.MinerCount or 0
        _LastMineralCount = data.MineralCount or 0
        _LastAssistCount = data.AssistCount or 0
        _LastAssistRewardValue = data.AssistRewardValue or 0
        _LastFinishCount = data.FinishCount or 0

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_ACTIVITY_RESULT_CHANGE)
    end

    function XStrongholdManager.CheckShowLastActivityRecord()
        if not IsNumberValid(_LastActivityId) then
            return false
        end
        if XStrongholdManager.GetCookieLastActivityRecord() ~= 0 then
            return false
        end
        if _LastActivityId ~= _ActivityId then
            return true
        end
        return false
    end

    function XStrongholdManager.GetCookieLastActivityRecord()
        local key = XStrongholdManager.GetLastActivityRecordCookieKey()
        return XSaveTool.GetData(key) or 0
    end

    function XStrongholdManager.SetCookieGetCookieLastActivityRecord()
        local key = XStrongholdManager.GetLastActivityRecordCookieKey()
        XSaveTool.SaveData(key, 1)
    end

    function XStrongholdManager.GetLastActivityRecordCookieKey()
        if not IsNumberValid(_LastActivityId) then
            return
        end
        return XPlayer.Id .. _LastActivityId .. "_XStrongholdManager_CookieLastActivityRecord"
    end

    --获取当期/上期进度
    function XStrongholdManager.GetLastAcitivityFinishProgress()
        local finishCount, totalCount = 0, 0
        finishCount = _LastFinishCount or 0
        totalCount = XStrongholdManager.GetAllGroupCount(XStrongholdConfigs.ChapterType.Normal)
        return finishCount, totalCount
    end

    function XStrongholdManager.GetLastMinerCount()
        return _LastMinerCount or 0
    end

    function XStrongholdManager.GetLastMineralCount()
        return _LastMineralCount or 0
    end

    function XStrongholdManager.GetLastAssistCount()
        return _LastAssistCount or 0
    end

    function XStrongholdManager.GetLastAssistRewardValue()
        return _LastAssistRewardValue or 0
    end

    --通知战报信息
    function XStrongholdManager.NotifyStrongholdResultRecord(data)
        UpdateLastAcitivityRecord(data.Record)
    end

    function XStrongholdManager.GetLastActivityId()
        return _LastActivityId
    end
    -----------------上期战报 end------------------
    -----------------副本相关 begin------------------
    local _CurFightGroupId = 0
    local _CurFightStageIndex = 0
    local _SingleFight = false --是否挑战单关卡

    local function InitStageType(stageId)
        stageId = tonumber(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo then
            stageInfo.Type = XDataCenter.FubenManager.StageType.Stronghold
        end
    end

    function XStrongholdManager.InitStageInfo()
        local stageIds = XStrongholdManager.GetAllGroupStageIds()
        for _, stageId in pairs(stageIds) do
            InitStageType(stageId)
        end
    end

    function XStrongholdManager.ResetCurFightInfo()
        _CurFightGroupId = 0
        _CurFightStageIndex = 0
    end

    function XStrongholdManager.OpenFightLoading(stageId)
        if _SingleFight then
            XDataCenter.FubenManager.OpenFightLoading(stageId)
            return
        end

        local groupId = _CurFightGroupId
        local stageIndex = _CurFightStageIndex
        if stageIndex == 1 and XStrongholdConfigs.IsChapterLastGroupId(groupId) then
            return
        end
        XLuaUiManager.Open("UiStrongholdInfo", groupId, stageIndex)
    end

    function XStrongholdManager.CloseFightLoading(stageId)
        if _SingleFight then
            XDataCenter.FubenManager.CloseFightLoading(stageId)
        else
            XLuaUiManager.Remove("UiStrongholdInfo")
        end
    end

    function XStrongholdManager.ShowReward(winData)
        local groupId = _CurFightGroupId
        local stageCount = XStrongholdManager.GetGroupStageNum(groupId)
        local stageIndex = _CurFightStageIndex
        local allFinished = winData.SettleData.StrongholdFightResult.AllFinished --当前据点所有关卡是否都挑战通过

        if _SingleFight then
            --单关卡挑战
            _SingleFight = false
        else
            --多波连续挑战
            if not allFinished and stageIndex < stageCount then
                _CurFightStageIndex = stageIndex + 1
                XStrongholdManager.EnterFight(groupId, nil, nil, true)
            end
        end

        if allFinished then
            XStrongholdManager.ResetCurFightInfo()
            XLuaUiManager.Remove("UiStrongholdDeploy")
            if XStrongholdManager.IsChapterLastGroup(groupId) then -- 通关深巢后直接返回主界面
                XLuaUiManager.Remove("UiStrongholdFightMain")
            end
            XLuaUiManager.Open("UiStrongholdFightSettleWin", winData)
        end
    end

    function XStrongholdManager.ChallengeLose()
        XStrongholdManager.ResetCurFightInfo()
        _SingleFight = false
    end

    function XStrongholdManager.TryEnterFight(groupId, teamId, oTeamList)
        local callFunc = function()
            local teamList = XStrongholdManager.GetTeamListClipTemp(groupId, oTeamList)

            local enterFunc = function()
                local cb = function()
                    XStrongholdManager.EnterFight(groupId, teamList, teamId)
                end
                local setStrongholdTeamCb = function()
                    local ignoreRepeatCheck = true
                    XStrongholdManager.SetStrongholdFightTeamRequest(groupId, teamList, cb, ignoreRepeatCheck)
                end
                XStrongholdManager.SetStrongholdTeamRequest(oTeamList, nil, setStrongholdTeamCb)
            end

            local checkRuneFunc = function()
                local notRune = false
                if XTool.IsNumberValid(teamId) then
                    --单梯队作战
                    local team = teamList[teamId]
                    notRune = not team:HasRune()
                else
                    for _, team in pairs(teamList) do
                        if not team:HasRune() then
                            notRune = true
                            break
                        end
                    end
                end

                if notRune then
                    --符文配置不全提示
                    local title = CSXTextManagerGetText("StrongholdTeamAutoRuneConfirmTitle")
                    local content = CSXTextManagerGetText("StrongholdTeamAutoRuneConfirmContent")
                    local setRuneFunc = function()
                        XStrongholdManager.AutoRune(teamList)

                        --拷贝符文到队伍预设
                        for _, team in pairs(teamList) do
                            local oTeam = oTeamList[team:GetId()]
                            if not XTool.IsTableEmpty(oTeam) then
                                local runeId, subRuneId = team:GetRune()
                                oTeam:SetRune(runeId, subRuneId)
                            end
                        end

                        enterFunc()
                    end
                    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, setRuneFunc)
                else
                    enterFunc()
                end
            end

            --超出推荐电力弹窗
            local FighterTeamList = XDataCenter.StrongholdManager.GetFighterTeamListTemp(oTeamList, groupId)
            local color, isShowTips = XStrongholdManager.GetSuggestElectricColor(groupId, FighterTeamList)
            if isShowTips then
                local chapterId = XStrongholdConfigs.GetChapterIdByGroupId(groupId)
                local teamClipList = XStrongholdManager.GetFighterTeamListTemp(oTeamList, groupId)
                local useElectric = XDataCenter.StrongholdManager.GetTotalUseElectricEnergy(teamClipList)
                local levelId = XDataCenter.StrongholdManager.GetLevelId()
                local suggestElectric = XStrongholdConfigs.GetChapterSuggestElectric(chapterId, levelId)
                local title = CSXTextManagerGetText("TipTitle")
                local content2 = CSXTextManagerGetText("StrongholdSuggestElectricTipsDesc", suggestElectric)
                local content3 = CSXTextManagerGetText("StrongholdSuggestElectricTipsDesc2", useElectric)
                local extraData = {["Content2"] = content2, ["Content3"] = content3}
                XUiManager.DialogTip(title, "", XUiManager.DialogType.Normal, nil, checkRuneFunc, extraData)
            else
                checkRuneFunc()
            end
        end

        callFunc()
    end

    function XStrongholdManager.EnterFight(groupId, teamList, stageIndex, isContinueFight)
        local teamList = XStrongholdManager.GetTeamListClipTemp(groupId, teamList)

        --单队挑战单关卡
        if XTool.IsNumberValid(stageIndex) then
            _SingleFight = true
        end

        _CurFightGroupId = groupId

        stageIndex = stageIndex or _CurFightStageIndex
        if not IsNumberValid(stageIndex) or XStrongholdManager.IsGroupStageFinished(groupId, stageIndex) then
            stageIndex = XStrongholdManager.GetGroupNextFightStageIndex(groupId)
        end
        _CurFightStageIndex = stageIndex

        local stageId = XStrongholdManager.GetGroupStageId(groupId, stageIndex)
        local enterFight = function()
            local teamId = stageIndex
            local captainPos, firstFightPos = XStrongholdManager.GetTeamCaptinPosAndFirstPos(teamId, teamList)
            local characterIds = XStrongholdManager.GetTeamShowCharacterIds(teamId, teamList)
            XDataCenter.FubenManager.EnterStrongholdFight(stageId, characterIds, captainPos, firstFightPos)
        end

        if XStrongholdConfigs.IsChapterLastGroupId(groupId) then
            if not _SingleFight then
                XLuaUiManager.Open("UiStrongholdInfo", groupId, stageIndex)
            end

            --连续挑战不显示词缀界面
            if isContinueFight then
                enterFight()
            else
                XLuaUiManager.Open("UiStrongholdAnimation", groupId, enterFight)
            end
        else
            enterFight()
        end
    end

    --扫荡
    local _SweepStrongholdStageRequestLock = false
    function XStrongholdManager.RequestSweepStrongholdStage(groupId, cb)
        if not XStrongholdManager.CheckEndurance(groupId) or _SweepStrongholdStageRequestLock then
            return
        end

        _SweepStrongholdStageRequestLock = true
        CatchOldData()

        local lastLevel = XPlayer.GetLevelOrHonorLevel()
        local lastExp = XPlayer.Exp
        XNetwork.Call(
            "SweepStrongholdStageRequest",
            {GroupId = groupId},
            function(res)
                _SweepStrongholdStageRequestLock = false
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                if cb then
                    cb()
                end

                local data = {
                    SettleData = res,
                    RoleLevel = lastLevel,
                    RoleExp = lastExp
                }
                XLuaUiManager.Open("UiStrongholdFightSettleWin", data)
            end
        )
    end
    -----------------副本相关 end------------------
    -----------------等级分区 begin------------------
    local _LevelId = 0
    --当前选择的分区

    function XStrongholdManager.GetLevelId()
        return _LevelId
    end

    local function UpdateLevelId(levelId)
        _LevelId = levelId or _LevelId

        --根据分区初始化关卡信息
        InitGroupInfos()
    end

    function XStrongholdManager.GetChaptersByLevel()
        return XStrongholdConfigs.GetLevelChapterIds(_LevelId)
    end

    --是否已经选择过分区
    function XStrongholdManager.IsSelectedLevelId()
        return IsNumberValid(_LevelId)
    end

    --选择等级分区
    function XStrongholdManager.SelectStrongholdLevelRequest(levelId, cb)
        if XStrongholdManager.IsSelectedLevelId() then
            XUiManager.tiptext("StrongholdAlreadySelectLevel")
            return
        end

        local req = {LevelId = levelId}
        XNetwork.Call(
            "SelectStrongholdLevelRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateLevelId(levelId)
                UpdateGroupStageDatas(res.GroupStageDatas)
                UpdateMaxElectricEnergy(res.ElectricEnergy)
                UpdateEndurance(res.Endurance)
                --CheckUpdateTeam()

                if cb then
                    cb()
                end
            end
        )
    end
    -----------------等级分区 end------------------
    -----------------暂停结算 begin------------------
    local _PauseDays = {}
    --暂停结算的天数(下次结算后清除)

    local function InitPauseDays()
        _PauseDays = {}
        local totalDay = XStrongholdManager.GetTotalDay()
        for day = 1, totalDay do
            _PauseDays[day] = false
        end
    end

    local function UpdatePauseDays(days)
        InitPauseDays()

        for _, day in pairs(days or {}) do
            _PauseDays[day] = true
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_PAUSE_DAY_CHANGE)
    end

    --该天数是否暂停了结算
    function XStrongholdManager.IsDayPaused(day)
        day = day or XStrongholdManager.GetCurDay()
        return _PauseDays[day] and true or false
    end

    --是否有处于暂停中的天数（昨天/前天/...）
    function XStrongholdManager.IsAnyDayPaused()
        for _, isPause in pairs(_PauseDays) do
            if isPause then
                return true
            end
        end
        return false
    end

    --获取暂停天数（from curDay）
    function XStrongholdManager.GetDelayDays()
        local delayDays = 0

        local curDay = XStrongholdManager.GetCurDay()
        local totalDay = XStrongholdManager.GetTotalDay()
        for day = curDay, totalDay do
            if not XStrongholdManager.IsDayPaused(day) then
                break
            end
            delayDays = delayDays + 1
        end

        return delayDays
    end

    --挑战开始后48小时不可设置暂停
    local PAUSE_DELAY_AFTER_FIGHT_BEGIN = 48 * 3600
    function XStrongholdManager.CheckPauseTimeAfterFightBegin()
        local nowTime = XTime.GetServerNowTimestamp()
        local fightBeginTime = XStrongholdManager.GetFightTime()
        return nowTime - fightBeginTime >= PAUSE_DELAY_AFTER_FIGHT_BEGIN
    end

    --挑战结束前24小时不可设置暂停
    local PAUSE_DELAY_BEFORE_FIGHT_END = 24 * 3600
    function XStrongholdManager.CheckPauseTimeBeforeFightEnd()
        local nowTime = XTime.GetServerNowTimestamp()
        local delayDays = XStrongholdManager.GetDelayDays()
        local _, fightEndTime = XStrongholdManager.GetFightTime()
        return fightEndTime - nowTime - delayDays * 24 * 3600 >= PAUSE_DELAY_BEFORE_FIGHT_END
    end

    --是否可以暂停结算
    function XStrongholdManager.IsCanPaused()
        return XStrongholdManager.IsFightBegin() and --作战期开始
            XStrongholdManager.CheckPauseTimeAfterFightBegin() and
            XStrongholdManager.CheckPauseTimeBeforeFightEnd()
    end

    local _LastTimeSetStrongholdStayRequest = 0
    local _CDSetStrongholdStayRequest = 3
    function XStrongholdManager.CheckSetStrongholdStayRequestCD()
        local now = XTime.GetServerNowTimestamp()
        local lastCd = _LastTimeSetStrongholdStayRequest + _CDSetStrongholdStayRequest - now
        if lastCd > 0 then
            return false
        end
        return true
    end

    --设置暂停
    function XStrongholdManager.SetStrongholdStayRequest(cb)
        if not XStrongholdManager.IsCanPaused() then
            return
        end

        if not XStrongholdManager.CheckSetStrongholdStayRequestCD() then
            return
        end

        XNetwork.Call(
            "SetStrongholdStayRequest",
            nil,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                _LastTimeSetStrongholdStayRequest = XTime.GetServerNowTimestamp()

                UpdatePauseDays(res.StayDays)

                if cb then
                    cb()
                end
            end
        )
    end
    -----------------暂停结算 end------------------
    -----------------符文 begin------------------
    local _RuneIdList = {} --本期符文Id列表
    local _RuneIdDic = {} --本期符文Id字典
    local _UsingRuneIdDic = {} --使用中符文Id字典
    local _UsingSubRuneIdDic = {} --使用中子符文Id字典

    local function UpdateRuneIds(data)
        _RuneIdList = {}
        for _, runeId in pairs(data or {}) do
            if XTool.IsNumberValid(runeId) then
                tableInsert(_RuneIdList, runeId)
                _RuneIdDic[runeId] = true
            end
        end

        tableSort(
            _RuneIdList,
            function(a, b)
                return a < b
            end
        )
    end

    function XStrongholdManager.GetAllRuneIds()
        return XTool.Clone(_RuneIdList)
    end

    function XStrongholdManager.UseRune(runeId, subRuneId, teamId)
        if XTool.IsNumberValid(runeId) then
            _UsingRuneIdDic[runeId] = teamId
        end
        if XTool.IsNumberValid(subRuneId) then
            _UsingSubRuneIdDic[subRuneId] = teamId
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_RUNE_CHANGE)
    end

    function XStrongholdManager.TakeOffRune(runeId, subRuneId)
        if XTool.IsNumberValid(runeId) then
            _UsingRuneIdDic[runeId] = nil
        end
        if XTool.IsNumberValid(subRuneId) then
            _UsingSubRuneIdDic[subRuneId] = nil
        end
    end

    function XStrongholdManager.GetRuneUsingTeamId(runeId)
        return _UsingRuneIdDic[runeId]
    end

    --符文是否锁定(被有通关记录的队伍使用)
    function XStrongholdManager.IsRuneLock(runeId, groupId, subRuneId)
        if not XTool.IsNumberValid(groupId) then
            return false
        end

        if XTool.IsNumberValid(subRuneId) and not XStrongholdManager.IsSubRuneUsing(subRuneId) then
            return false
        end

        local itemIndex = XStrongholdManager.GetRuneUsingTeamId(runeId)
        local teamPropIds = XStrongholdManager.GetTeamPropsByGroupId(groupId)
        local usingTeamId = table.indexof(teamPropIds, itemIndex)
        if not XTool.IsNumberValid(usingTeamId) then
            return false
        end
        return XStrongholdManager.IsGroupStageFinished(groupId, usingTeamId)
    end

    function XStrongholdManager.IsRuneUsing(runeId)
        return _UsingRuneIdDic[runeId] and true or false
    end

    function XStrongholdManager.IsSubRuneUsing(subRuneId)
        return _UsingSubRuneIdDic[subRuneId] and true or false
    end

    function XStrongholdManager.GetNextCanUseRuneId()
        for _, runeId in ipairs(_RuneIdList) do
            if not XStrongholdManager.IsRuneUsing(runeId) then
                return runeId
            end
        end
        return 0
    end

    function XStrongholdManager.AutoRune(teamList)
        teamList = teamList or _TeamList

        for _, team in pairs(teamList) do
            if not team:HasRune() then
                local runeId = XStrongholdManager.GetNextCanUseRuneId()
                if XTool.IsNumberValid(runeId) then
                    local subRuneId = XStrongholdConfigs.GetSubRuneIds(runeId)[1]
                    team:SetRune(runeId, subRuneId)
                end
            end
        end
    end

    --是否为本期的符文
    function XStrongholdManager.IsCurActivityRune(runeId)
        return _RuneIdDic[runeId]
    end
    -----------------符文 end------------------
    --登录通知
    function XStrongholdManager.NotifyStrongholdLoginData(data)
        if CheckActivityReset(data.Id) then
            XStrongholdManager.Reset()
        end

        XStrongholdManager.Init()

        UpdateActivityInfo(data.Id, data.BeginTime, data.FightBeginTime)
        UpdateLevelId(data.LevelId)
        UpdatePauseDays(data.StayDays)
        UpdateCurDay(data.CurDay, data.FightBeginTime)
        UpdateTotalMineral(data.TotalMineral)
        UpdateMineralLeft(data.MineralLeft)
        UpdateEndurance(data.Endurance)
        UpdateMaxElectricEnergy(data.ElectricEnergy)
        UpdateElectricCharacters(data.ElectricCharacterIds)
        UpdateBorrowCount(data.BorrowCount)
        UpdateFinishGroupIds(data.FinishGroupIds)
        UpdateFinishGroupUseElectricEnergy(data.FinishGroupInfos, data.HistoryFinishGroupInfos)
        UpdateFinishedRewardIds(data.RewardIds)
        UpdateMineRecords(data.MineRecords)
        UpdateGroupStageDatas(data.GroupStageDatas)
        UpdateGroupInfos(data.GroupInfos)
        UpdateLastAcitivityRecord(data.LastResultRecord)
        UpdateRuneIds(data.RuneList)
        UpdateTeamList(data.TeamInfos)
        UpdateShareCharacterId(data.AssistCharacterId)
        --CheckUpdateTeam()
    end

    --活动结束
    function XStrongholdManager.NotifyStrongholdEnd()
        local uiNameList = { "UiStrongholdMain", "UiStrongholdFightMain", "UiStrongholdDeploy" }
        --处于玩法界面内
        for _, uiName in ipairs(uiNameList) do
            if XLuaUiManager.IsUiShow(uiName) then
                XLuaUiManager.Open("UiNewFuben")
                XUiManager.TipText("CommonActivityEnd")
                return
            end
        end
        --通过玩法跳转到其他界面
        for _, uiName in ipairs(uiNameList) do
            XLuaUiManager.Remove(uiName)
        end
        XStrongholdManager.Reset()
    end

    --通知天数改变
    function XStrongholdManager.NotifyStrongholdChangeDay(data)
        UpdateCurDay(data.CurDay, data.FightBeginTime)
        UpdatePauseDays(data.StayDays)
        UpdateMineralLeft(data.MineralLeft)
        UpdateEndurance(data.Endurance)
        UpdateMaxElectricEnergy(data.ElectricEnergy)
        UpdateMineRecords(data.MineRecords)
        UpdateBorrowCount(data.BorrowCount)
        ClearAssitantRecords()
    end

    --在线重置
    function XStrongholdManager.Reset()
        _ActivityStatus = ACTIVITY_STATUS.DEFAULT --活动状态
        _ActivityId = 0 --活动期数
        _BeginTime = 0 --活动开启时间
        _FightBeginTime = 0 --挑战开启时间
        _FightAutoBeginTime = 0 --挑战自动开启时间
        _FightEndTime = 0 --挑战结束时间
        _EndTime = 0 --活动结束时间
        _CurDay = 0 --当前天数（挑战开始后）
        _TotalDay = 0 --挑战总天数（挑战开始后）
        _TotalMineral = 0 --历史累计矿石数量
        _MineralLeft = 0 --可领矿石
        _MineRecords = {} --产出记录
        _MineRecordSynDic = {} --产出历史记录（服务端同步）
        _Endurance = 0 --耐力值
        _MaxElectricEnergy = 0 --电能上限
        _BorrowCount = 0 --援助次数
        _FinishGroupIdDic = {}
        --已完成据点Id字典
        _NewFinishGroupIds = {}
        --最新完成据点Id列表
        _FinishedRewardIdDic = {}
        --已领取奖励Id字典
        _GroupInfos = {}
        --据点信息
        XStrongholdManager.ResetTeamList()
        --队伍列表
        _AssistantCharacters = {} --援助角色列表（来自于其他玩家）
        _AssistantCharacterId = 0 --共享角色Id
        _PauseDays = {}
        --暂停结算的天数
        _LevelId = 0
        --当前选择的分区
        _RuneIdList = {} --本期符文Id列表
        _UsingRuneIdDic = {} --使用中符文Id字典
        _UsingSubRuneIdDic = {} --使用中子符文Id字典

        if XLuaUiManager.IsUiLoad("UiStrongholdMain") or XLuaUiManager.IsUiLoad("UiStrongholdFightMain") or XLuaUiManager.IsUiLoad("UiStrongholdDeploy") then
            -- _ActivityEnd是活动关闭时返回主界面的标记
            _ActivityEnd = true
            XStrongholdManager.OnActivityEnd()
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_ACTIVITY_END)
    end

    --只重置队伍列表中的符文和插件
    function XStrongholdManager.ResetTeamList()
        for _, team in ipairs(_TeamList) do
            team:ClearRune()
            team:InitPlugins()
        end
    end

    function XStrongholdManager.Init()
        InitMine()
        InitTeamList()
        InitElectric()
        InitPauseDays()

        XEventManager.AddEventListener(XEventId.EVENT_FIGHT_FINISH_LOSEUI_CLOSE, XStrongholdManager.ChallengeLose)
    end

    ------------------副本入口扩展 start-------------------------
    function XStrongholdManager:ExGetChapterType()
        return XDataCenter.FubenManager.ChapterType.Stronghold
    end

    function XStrongholdManager:ExCheckIsShowRedPoint()
        return XRedPointConditions.Check(XRedPointConditions.Types.XRedPointConditionStrongholdRewardCanGet)
    end

    -- 获取进度提示
    function XStrongholdManager:ExGetProgressTip() 
        local str = ""
        if not self:ExGetIsLocked() then 
            local finishCount, totalCount = XStrongholdManager.GetGroupProgress()
            str = CsXTextManagerGetText("StrongholdActivityProgress", finishCount, totalCount)
        end
        return str
    end

    -- 获取剩余进行时间 eg: 距离结束还有x天x小时
    function XStrongholdManager:ExGetRunningTimeStr()
        local str = ""
        local time = _TargetCountDownTime - XTime.GetServerNowTimestamp()
        local timeText = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.STRONGHOLD)
        if XStrongholdManager.IsActivityBegin() then
            str = CsXTextManagerGetText("StrongholdActivityTimeActivityBegin", timeText)
        elseif XStrongholdManager.IsFightBegin() then
            str = CsXTextManagerGetText("StrongholdActivityTimeFightBegin", timeText)
        elseif XStrongholdManager.IsFightEnd() then
            str = CsXTextManagerGetText("StrongholdActivityTimeFightEnd", timeText)
        end

        return str
    end

    function XStrongholdManager:ExCheckIsFinished(cb)
        if _ActivityStatus ~= ACTIVITY_STATUS.ACTIVITY_BEGIN and _ActivityStatus ~= ACTIVITY_STATUS.FIGHT_BEGIN then -- 特殊，只要不在战斗期就一定显示Clear
            if cb then
                cb(true)
            end
            self.IsClear = true
            return true
        end

        local result = false
        if not XStrongholdManager.IsFightBegin() then
            result = false
        else  -- 1.没有可领取奖励 2.作战点数用完 3.如果本次作战中驱逐作战中存在不用作战点数的关卡通关了才算完成
            if not XStrongholdManager.IsAnyRewardCanGet() and XStrongholdManager.CheckChapterIsClear() then
                result = true
            end
        end

        self.IsClear = result
        if cb then
            cb(result)
        end

        return result
    end

    function XStrongholdManager:ExOpenMainUi()
        XStrongholdManager.EnterUiMain()
    end

    -- 获取倒计时（周历专用）
    function XStrongholdManager:ExGetCalendarRemainingTime()
        if not XTool.IsNumberValid(_TargetCountDownTime) then
            return ""
        end
        local remainTime = _TargetCountDownTime - XTime.GetServerNowTimestamp()
        if remainTime < 0 then
            remainTime = 0
        end
        local timeText = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.NEW_CALENDAR)
        if XStrongholdManager.IsActivityBegin() then
            return XUiHelper.GetText("UiNewActivityCalendarBeginCountDown", timeText)
        elseif XStrongholdManager.IsFightBegin() then
            return XUiHelper.GetText("UiNewActivityCalendarEndCountDown", timeText)
        end
        return ""
    end

    -- 获取解锁时间（周历专用）
    function XStrongholdManager:ExGetCalendarEndTime()
        if not XTool.IsNumberValid(_TargetCountDownTime) then
            return 0
        end
        return _TargetCountDownTime
    end

    -- 是否在周历里显示
    function XStrongholdManager:ExCheckShowInCalendar()
        if not XTool.IsNumberValid(_TargetCountDownTime) then
            return false
        end
        if _TargetCountDownTime - XTime.GetServerNowTimestamp() <= 0 then
            return false
        end
        if XStrongholdManager.IsActivityBegin() or XStrongholdManager.IsFightBegin() then
            return true
        end
        return false
    end
    
    -- 是否显示提示信息（周历专用）
    function XStrongholdManager:ExCheckWeekIsShowTips()
        if XStrongholdManager.IsActivityBegin() and not XTool.IsNumberValid(XStrongholdManager.GetLevelId()) then
            return true
        end
        return false
    end
    
    ------------------副本入口扩展 end-------------------------

    return XStrongholdManager
end
---------------------(服务器推送)begin------------------
XRpc.NotifyStrongholdLoginData = function(data)
    XDataCenter.StrongholdManager.NotifyStrongholdLoginData(data)
end

XRpc.NotifyStrongholdChangeDay = function(data)
    XDataCenter.StrongholdManager.NotifyStrongholdChangeDay(data)
end

XRpc.NotifyStrongholdTotalMineral = function(data)
    XDataCenter.StrongholdManager.NotifyStrongholdTotalMineral(data)
end

XRpc.NotifyStrongholdResultRecord = function(data)
    XDataCenter.StrongholdManager.NotifyStrongholdResultRecord(data)
end

XRpc.NotifyStrongholdBorrowCount = function(data)
    XDataCenter.StrongholdManager.NotifyStrongholdBorrowCount(data)
end

XRpc.NotifyStrongholdFinishGroupId = function(data)
    XDataCenter.StrongholdManager.NotifyStrongholdFinishGroupId(data)
end

XRpc.NotifyStrongholdFinishGroupInfo = function(data)
    XDataCenter.StrongholdManager.NotifyStrongholdFinishGroupInfo(data)
end

XRpc.NotifyUpdateStrongholdGroupData = function(data)
    XDataCenter.StrongholdManager.NotifyUpdateStrongholdGroupData(data)
end

XRpc.NotifyDeleteStrongholdGroupData = function(data)
    XDataCenter.StrongholdManager.NotifyDeleteStrongholdGroupData(data)
end

XRpc.NotifyStrongholdEnduranceData = function(data)
    XDataCenter.StrongholdManager.NotifyStrongholdEnduranceData(data)
end

XRpc.NotifyStrongholdEnd = function(data)
    XDataCenter.StrongholdManager.NotifyStrongholdEnd(data)
end
---------------------(服务器推送)end------------------
