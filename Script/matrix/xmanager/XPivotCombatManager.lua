XPivotCombatManagerCreator = function()

    --region 局部变量
    
    --数据结构
    local XPivotCombatManager   = {} -- 管理类
    local _ActivityId           = 0 --当前开放的活动Id
    local _IsOpening            = true --活动是否开放(能否进入活动)
    local _IsReceiveAgreement   = false --是否收到协议
    local _SecondaryRegion      = {} --次级区域配置
    local _RegionId2Region      = {} --次级区域Id-对应配置
    local _CenterRegion         = {} --中心区域配置
    local _StageInfo            = {} --关卡信息
    local _RegionDifficult      = 0 --区域难度
    local _LockCharacterIdDic   = {} --被锁定的角色
    
    local _MaxRankMember        = 100 --排行榜显示最大的人数
    local _MaxScore             = 0 --中心枢纽最高分
    local _FightTimeScore       = XPivotCombatConfigs.FightTimeScoreInitialValue --通关时间积分
    local _HightestLevel        = 0 --中心枢纽最高评级
    local _LastRefreshScore     = -1 --上次进入排行榜时的分数
    local _HistoryScore         = 0 --历史最高分数
    local _HistoryHightestLevel = 0 --历史最高评级
    local _TeamDict             = {} --各区域队伍数据队伍
    local _Robots               = {} --机器人配置
    local _MaxTeamMember        = 3 --最大队员数量
    local _LastSyncServerTimes  = {} --上次请求排行榜时间
    local _SyncServerTime       = 20 --同步时长
    local _RankData             = {} --排行榜数据缓存
    local _EventCache           = {} --事件缓存
    
    --请求后端函数名
    local REQUEST_FUNC_NAME = {
        CancelLockCharacterPivotCombatRequest   = "CancelLockCharacterPivotCombatRequest",
        GetRankInfoPivotCombatRequest           = "GetRankInfoPivotCombatRequest",
        SelectDifficultyPivotCombatRequest      = "SelectDifficultyPivotCombatRequest",
    }
    
    --引用
    local XPivotCombatRankItem      = require("XEntity/XPivotCombat/XPivotCombatRankItem")
    local XTeam                     = require("XEntity/XTeam/XTeam")
    local XRobot                    = require("XEntity/XRobot/XRobot")
    local XPivotCombatRegionItem    = require("XEntity/XPivotCombat/XPivotCombatRegionItem")
    
    --key相关
    local _StagePrefabKey       = "UiPivotCombatChapterGrid" --关卡预制体key
    local _StageLockPrefabKey   = "UiPivotCombatFinalChapterGrid" --锁角色关卡预制体key
    local _TeamDataKey          = "_TeamDataKey" --队伍数据key
    local _NoLearnSkillKey      = "_NoLearnSkillKey" --未学独域技能key
    
    --endregion
    
    --region 局部函数
    
    --===========================================================================
     ---@desc 根据活动id初始化配置
    --===========================================================================
    local InitConfigs = function(activityId)
        if not XTool.IsNumberValid(activityId) then
            _ActivityId = XPivotCombatConfigs.GetDefaultActivityId()
        else
            _ActivityId = activityId
        end
        
        XPivotCombatConfigs.InitConfigsByActivity(_ActivityId)
    end

    --===========================================================================
     ---@desc 获取当前活动，切为当前难度下的区域配置
    --===========================================================================
    local InitRegionConfig = function()
        ----获取当期活动开放的区域配置
        if not XTool.IsNumberValid(_RegionDifficult) then
            return
        end
        local regions = XPivotCombatConfigs.GetCurRegionConfigs()
        for regionId, config in pairs(regions[_RegionDifficult] or {}) do
            local regionItem = XPivotCombatRegionItem.New(regionId)
            regionItem:InitData(config)
            if regionItem:IsCenterRegion() then
                _CenterRegion = regionItem
            else
                table.insert(_SecondaryRegion, regionItem)
            end
            _RegionId2Region[regionId] = regionItem
        end 
    end

    --===========================================================================
     ---@desc 获取或新创建机器人
    --===========================================================================
    local GetRobot = function(robotId) 
        local robot = _Robots[robotId]
        if not robot then
            robot = XRobot.New(robotId)
            _Robots[robotId] = robot
        end
        return robot
    end
    
    local GetRegionKey = function(regionId)
        return "Region_"..regionId.."_IsOpen"
    end
     
    --检查活动开启状态
    local CheckActivityState = function(activityId)
        local func = function()
            if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") or XLuaUiManager.IsUiLoad("UiSettleLose") or
                    XLuaUiManager.IsUiLoad("UiSettleWin") then
                table.insert(_EventCache, true)
                return
            end
            XEventManager.DispatchEvent(XEventId.EVENT_PIVOTCOMBAT_ACTIVITY_END)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_ON_RESET, XDataCenter.FubenManager.StageType.PivotCombat)
        end
        
        --服务端发送了小于0的活动id
        if not _IsOpening then
            func()
            return
        end

        --在线开启了新一期活动
        if activityId > 0 and activityId ~= _ActivityId then
            func()
            return
        end
    end
    
    --===========================================================================
     ---@desc 初始化历史评分相关
    --===========================================================================
    local InitHistoryScore = function()
        _HistoryScore = _MaxScore
        _HistoryHightestLevel = _HightestLevel
        
    end

    --endregion
    
    --region 活动入口相关
    
    --===========================================================================
     ---@desc 获取当前开放的活动信息
     ---@return {table} 活动信息
    --===========================================================================
    function XPivotCombatManager.GetActivityChapters()
        --未收到协议,且不在活动开放时间内
        if not ( _IsReceiveAgreement and XPivotCombatManager.IsDuringOpenTime()) then
            return {}
        end
        local chapters = {}
        table.insert(chapters, {
            Id          = _ActivityId,
            Type        = XDataCenter.FubenManager.ChapterType.PivotCombat,
            BannerBg    = XPivotCombatConfigs.GetActivityBanner(_ActivityId),
            Name        = XPivotCombatConfigs.GetActivityName(_ActivityId)
        })
        return chapters
    end
    
    --===========================================================================
     ---@desc 当前活动总体进度
     ---@return {string} 总体进度
    --===========================================================================
    function XPivotCombatManager.GetActivityProgress()
        local taskList = XDataCenter.PivotCombatManager.GetTaskList()
        local finished = 0
        for _, task in ipairs(taskList) do
            if task.State == XDataCenter.TaskManager.TaskState.Finish then
                finished = finished + 1
            end
        end
        return CSXTextManagerGetText("PivotCombatProgress", finished, #taskList)
    end

    --===========================================================================
     ---@desc 当前活动名
     ---@return {string} 当前活动名
    --===========================================================================
    function XPivotCombatManager.GetActivityName()
        return XPivotCombatConfigs.GetActivityName(_ActivityId)
    end

    --==============================
     ---@desc 活动代币
     ---@return number 物品Id
    --==============================
    function XPivotCombatManager.GetActivityCoinId()
        return XPivotCombatConfigs.GetCoinId(_ActivityId)
    end
    
    --==============================
     ---@desc 商店类型
     ---@return number 商店type
    --==============================
    function XPivotCombatManager.GetActivityShopType()
        return XPivotCombatConfigs.GetShopType(_ActivityId)
    end
    
    --===========================================================================
    ---@desc 当前活动剩余时间，例：23天
    ---@return {string} 显示规则为XUiHelper.TimeFormatType.ACTIVITY
    --===========================================================================
    function XPivotCombatManager.GetActivityLeftTime()
        local timeOfNow = XTime.GetServerNowTimestamp()
        local timeOfEnd = XPivotCombatConfigs.GetActivityEndTime(_ActivityId)
        return XUiHelper.GetTime(timeOfEnd - timeOfNow, XUiHelper.TimeFormatType.PIVOT_COMBAT)
    end

    --===========================================================================
    ---@desc 检测活动是否开启
    ---@return [bool] 是否开启
    --===========================================================================
    function XPivotCombatManager.IsOpen()
        if not XTool.IsNumberValid(_ActivityId) then
            return false
        end

        if not _IsOpening then
            return false
        end

        return XPivotCombatManager.IsDuringOpenTime()
    end
    
    --===========================================================================
     ---@desc 是否在活动开放时间内
    --===========================================================================
    function XPivotCombatManager.IsDuringOpenTime()
        local timeOfNow     = XTime.GetServerNowTimestamp()
        local timeOfBegin   = XPivotCombatConfigs.GetActivityStartTime(_ActivityId)
        local timeOfEnd     = XPivotCombatConfigs.GetActivityEndTime(_ActivityId)
        return timeOfBegin <= timeOfNow and timeOfNow < timeOfEnd
    end

    --===========================================================================
    ---@desc 获取当前活动开放时间
    ---@return {int} 当前活动开放时间戳
    --===========================================================================
    function XPivotCombatManager.GetActivityBeginTime()
        return XPivotCombatConfigs.GetActivityStartTime(_ActivityId)
    end

    --===========================================================================
    ---@desc 获取当前活动结束时间
    ---@return {int} 当前活动结束时间戳
    --===========================================================================
    function XPivotCombatManager.GetActivityEndTime()
        return XPivotCombatConfigs.GetActivityEndTime(_ActivityId)
    end

    --===========================================================================
    ---@desc 跳转到活动主界面
    --===========================================================================
    function XPivotCombatManager.JumpTo()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.PivotCombat) then
            return
        end
        if not XPivotCombatManager.IsOpen() then
            XUiManager.TipText("FubenRepeatNotInActivityTime")
            return
        end
        if XDataCenter.PivotCombatManager.IsShowSelectDifficult() then
            XLuaUiManager.Open("UiPivotCombatSelectDifficult")
        else
            XLuaUiManager.Open("UiPivotCombatMain")
        end
    end

    --===========================================================================
    ---@desc 活动结束回调
    --===========================================================================
    function XPivotCombatManager.OnActivityEnd()
        XPivotCombatManager.ResetData()
        XLuaUiManager.RunMain()
        XUiManager.TipText("CommonActivityEnd")
    end
    
    --==============================
     ---@desc 根据事件缓存判断是否需要关闭活动
    --==============================
    function XPivotCombatManager.CheckNeedClose()
        local isEmpty = XTool.IsTableEmpty(_EventCache)
        if isEmpty then return end
        XDataCenter.PivotCombatManager.OnActivityEnd()
    end

    --==============================
     ---@desc 清除本期活动的缓存
    --==============================
    function XPivotCombatManager.ResetData()
        _SecondaryRegion      = {}
        _RegionId2Region      = {}
        _CenterRegion         = {}
        _LockCharacterIdDic   = {}
        _HistoryHightestLevel = 0
        _LastRefreshScore     = -1
        _StageInfo        = {}
        _RankData         = {}
        _HightestLevel    = 0
        _HistoryScore     = 0
        _MaxScore         = 0
        _EventCache       = {}
        _FightTimeScore   = XPivotCombatConfigs.FightTimeScoreInitialValue
    end
    
    --===========================================================================
     ---@desc 刷新头像通用接口
     ---@param {charIds}  通关角色id
     ---@param {headList} 头像控件列表
     ---@param {targetUiList} 用于初始化Ui
    --===========================================================================
    function XPivotCombatManager.RefreshHeadIcon(charIds, headList, targetUiList)
        charIds = charIds or {}
        for idx = 1, _MaxTeamMember do
            local charId = charIds[idx]
            local head = headList[idx]
            if not head then
                head = {}
                XTool.InitUiObjectByUi(head, targetUiList[idx])
                head.PanelWenhao.gameObject:SetActiveEx(false)
                table.insert(headList, head)
            end
            if XTool.IsNumberValid(charId) then
                head.StandIcon.gameObject:SetActiveEx(true)
                head.PanelLose.gameObject:SetActiveEx(false)
                local icon = XDataCenter.CharacterManager.GetCharSmallHeadIcon(charId)
                head.StandIcon:SetRawImage(icon)
            else
                --head.StandIcon.gameObject:SetActiveEx(false)
                --head.PanelLose.gameObject:SetActiveEx(true)
                head.GameObject:SetActiveEx(false)
            end
        end
        return headList
    end
    
    --===========================================================================
     ---@desc 所有次级区域是否全部开放
    --===========================================================================
    function XPivotCombatManager.IsAllSecondaryOpen()
        for _, region in ipairs(_SecondaryRegion) do
            local isOpen, _ = region:IsOpen()
            if not isOpen then
                return false
            end
        end
        return true
    end
    
    --endregion
    
    --region 红点检测条件
    --===========================================================================
     ---@desc 检查任务奖励是否显示红点
     ---@return {bool} 是否显示红点
    --===========================================================================
    function XPivotCombatManager.CheckTaskRewardRedPoint()
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.PivotCombat) then
            return false
        end
        if not XPivotCombatManager.IsOpen() then
            return false
        end
        local taskList = XDataCenter.PivotCombatManager.GetTaskList()
        for _, task in ipairs(taskList) do
            --有任务已经完成但是未领取
            if task.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end
        return false
    end
    
    --===========================================================================
     ---@desc 检查是否是新开放的区域
     ---@return {bool} 是否是新开放区域
    --===========================================================================
    function XPivotCombatManager.CheckNewAreaOpenRedPoint(regionId)
        if not XTool.IsNumberValid(regionId) or regionId == 0 then
            return false
        end
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.PivotCombat) then
            return false
        end
        if not XPivotCombatManager.IsOpen() then
            return false
        end
        local region = _RegionId2Region[regionId]
        if not region then
            return false
        end
        local isOpen, _ = region:IsOpen()
        --有供能，可能清除了缓存数据
        if not isOpen or region:GetCurSupplyEnergy() > 0 then
            return false
        end
        local key = XPivotCombatManager.GetCookieKey(GetRegionKey(regionId))
        if not XSaveTool.GetData(key) then
            return true
        end
        return false
    end
    
    --endregion
    
    --region 区域配置


    --===========================================================================
    ---@desc 中心区域最高分
    ---@return {int} 最高分
    --===========================================================================
    function XPivotCombatManager.GetMaxScore()
        return _MaxScore
    end
    
    --==============================
     ---@desc 战斗时间积分
     ---@return number
    --==============================
    function XPivotCombatManager.GetFightTimeScore()
        return _FightTimeScore
    end

    --===========================================================================
    ---@desc 更新最大分数
    --===========================================================================
    function XPivotCombatManager.RefreshMaxScore(score, fightTimeScore)
        if score < _MaxScore then return end
        _MaxScore = score
        _FightTimeScore = fightTimeScore
    end
    
    --===========================================================================
     ---@desc 获取历史最高分数，跟最大积分区分开来
    --===========================================================================
    function XPivotCombatManager.GetHistoryScore()
 
        return _HistoryScore
    end
    
    --===========================================================================
     ---@desc 刷新历史最高积分
    --===========================================================================
    function XPivotCombatManager.RefreshHistoryScore(score)
        if score < _HistoryScore then return end
        _HistoryScore = score
    end

    --===========================================================================
    ---@desc 获取历史最高评分
    --===========================================================================
    function XPivotCombatManager.GetHistoryRankingLevel()

        return _HistoryHightestLevel
    end

    --===========================================================================
    ---@desc 刷新历史最高评分
    --===========================================================================
    function XPivotCombatManager.RefreshHistoryRankingLevel(score)
        if score < _HistoryHightestLevel then return end
        _HistoryHightestLevel = score
    end

    --===========================================================================
    ---@desc 刷新最高评分
    --===========================================================================
    function XPivotCombatManager.RefreshHightestRankingLevel(score)
        if score < _HightestLevel then return end
        _HightestLevel = score
    end

    --===========================================================================
     ---@desc 获取当前活动的次级区域配置
     ---@return {XPivotCombatRegionItem}
    --===========================================================================
    function XPivotCombatManager.GetSecondaryRegions()
        return _SecondaryRegion
    end
    
    --===========================================================================
     ---@desc 根据区域id获取对应的实体类
     ---@param {regionId} 区域Id 
     ---@return {XPivotCombatRegionItem}
    --===========================================================================
    function XPivotCombatManager.GetRegion(regionId)
        return _RegionId2Region[regionId]
    end

    --===========================================================================
    ---@desc 获取中心区域配置
    ---@return {XPivotCombatRegionItem}
    --===========================================================================
    function XPivotCombatManager.GetCenterRegion()
        return _CenterRegion
    end
    
    --===========================================================================
     ---@desc 获取次级区域的区域id列表
    --===========================================================================
    function XPivotCombatManager.GetSecondaryRegionIds()
        local regionIds = {}
        for _, region in ipairs(_SecondaryRegion) do
            local regionId = region:GetRegionId()
            if XTool.IsNumberValid(regionId) then
                table.insert(regionIds, regionId)
            end
        end
        return regionIds
    end

    --===========================================================================
     ---@desc 获取排行榜最大显示人数
    --===========================================================================
    function XPivotCombatManager.GetMaxRankMember()
        return _MaxRankMember
    end
    
    --===========================================================================
     ---@desc 获取难度
    --===========================================================================
    function XPivotCombatManager.GetDifficulty()
        return _RegionDifficult
    end
    
    --==============================
     ---@desc 是否需要显示难度选择
     ---@return boolean
    --==============================
    function XPivotCombatManager.IsShowSelectDifficult()
        return not XTool.IsNumberValid(_RegionDifficult)
    end

    --===========================================================================
    ---@desc 检查次级区域供能是否满足进入中枢战区
    --===========================================================================
    function XPivotCombatManager.IsSecondaryEnergySupplyEnough()
        --次级区域的供能必须大于1才能进入中枢
        for _, region in ipairs(_SecondaryRegion) do
            if region:GetCurSupplyEnergy() < 1 then
                return false
            end
        end
        return true
    end

    --===========================================================================
    ---@desc 根据关卡库Id获取对应的关卡列表
    ---@param {stageLibId} 关卡库id 
    ---@return {table} 对应的配置
    --===========================================================================
    function XPivotCombatManager.GetStageConfigs(stageLibId)
        if not XTool.IsNumberValid(stageLibId) then
            return {}
        end
        return XPivotCombatConfigs.GetStageLibConfig(stageLibId)
    end
    
    --===========================================================================
     ---@desc 获取普通关卡预制体
    --===========================================================================
    function XPivotCombatManager.GetStagePrefabPath()
        return XUiConfigs.GetComponentUrl(_StagePrefabKey)
    end

    --===========================================================================
    ---@desc 获取锁角色关卡预制体
    --===========================================================================
    function XPivotCombatManager.GetLockRoleStagePrefabPath()
        return XUiConfigs.GetComponentUrl(_StageLockPrefabKey)
    end

    --===========================================================================
     ---@desc 所有次级区域能够提供的最大能量
     ---@return {int} 提供的能源等级
    --===========================================================================
    function XPivotCombatManager.GetSecondaryRegionTotalMaxEnergy()
        local totalEnergy = 0
        for _, region in ipairs(_SecondaryRegion) do
            totalEnergy = totalEnergy + region:GetMaxSupplyEnergy()
        end
        return totalEnergy
    end
    
    --===========================================================================
     ---@desc 所有次级区域当前提供的能量
     ---@return {int} 提供的能源等级
    --===========================================================================
    function XPivotCombatManager.GetSecondaryRegionTotalCurEnergy()
        local totalEnergy = 0
        for _, region in ipairs(_SecondaryRegion) do
            totalEnergy = totalEnergy + region:GetCurSupplyEnergy()
        end
        return totalEnergy
    end
    
    --===========================================================================
     ---@desc 刷新区域数据
     ---@param {regionData} 枢纽作战区域数据，具体内容查看XPivotCombatRegionItem的XPivotCombatRegionData
    --===========================================================================
    function XPivotCombatManager.RefreshRegionData(regionData)
        if XTool.IsTableEmpty(regionData) then
            return
        end
        for _, data in ipairs(regionData) do
            local regionId = data.RegionId
            local item = _RegionId2Region[regionId]
            if item then
                item:RefreshRegionData(data)
            end
        end
    end
    
    --===========================================================================
     ---@desc 刷新锁定角色字典
    --===========================================================================
    function XPivotCombatManager.RefreshLockCharacterDict(dict)
        for id, tbId in pairs(dict or {}) do
            if XTool.IsNumberValid(id) and XTool.IsNumberValid(tbId) then
                _LockCharacterIdDic[id] = tbId
            end
        end
    end

    --===========================================================================
    ---@desc 移除锁定角色字典
    --===========================================================================
    function XPivotCombatManager.RemoveLockCharacterDict(dict)
        for id, _ in pairs(dict or {}) do
            _LockCharacterIdDic[id] = nil
        end
    end
    
    --===========================================================================
     ---@desc 获取锁定角色字典
    --===========================================================================
    function XPivotCombatManager.GetLockCharacterDict()
        return _LockCharacterIdDic
    end
    
    --===========================================================================
     ---@desc 界面处理通用事件
    --===========================================================================
    function XPivotCombatManager.OnNotify(evt, args)
        if evt == XEventId.EVENT_PIVOTCOMBAT_ACTIVITY_END then
            XDataCenter.PivotCombatManager.OnActivityEnd()
        elseif evt == XEventId.EVENT_ACTIVITY_ON_RESET then
            if args[1] ~= XDataCenter.FubenManager.StageType.PivotCombat then return end
            XDataCenter.PivotCombatManager.OnActivityEnd()
        end
    end
    
    --===========================================================================
     ---@desc 获取次级区域的积分加成(万分比)
    --===========================================================================
    function XPivotCombatManager.GetTotalScoreAddition()
        local totalScoreAddition = 0
        for _, region in ipairs(_SecondaryRegion) do
            totalScoreAddition = totalScoreAddition + region:GetScoreAddition()
        end
        return totalScoreAddition / 10000
    end
    
    --===========================================================================
     ---@desc 是否是教学关
    --===========================================================================
    function XPivotCombatManager.CheckIsTeachStage(stageId)
        return stageId == XPivotCombatConfigs.TeachStageId or stageId == XPivotCombatConfigs.DynamicScoreTeachStageId
    end


    --===========================================================================
    ---@desc 进入次级界面
    --===========================================================================
    function XPivotCombatManager.OnEnterRegion(region)
        if not region then return end
        local regionId = region:GetRegionId()
        local key = XPivotCombatManager.GetCookieKey(GetRegionKey(regionId))
        if not XSaveTool.GetData(key) then
            XSaveTool.SaveData(key, true)
        end
        XLuaUiManager.Open("UiPivotCombatSecondary", region)
    end

    --===========================================================================
    ---@desc 获取当前期数的任务
    --===========================================================================
    function XPivotCombatManager.GetTaskList()
        if XTool.IsTableEmpty(_CenterRegion) then return {} end
        
        return XDataCenter.TaskManager.GetTaskList(TaskType.PivotCombat, _CenterRegion:GetTaskGroupId())
    end
    
    function XPivotCombatManager.ShowDialogHintTip(characterId, negativeCb, positiveCb)
        if XPivotCombatManager.IsShowedDialogHintTip() then
            return
        end
        local title = CSXTextManagerGetText("PivotCombatNoSpecialSkillTitle")
        local content = CSXTextManagerGetText("PivotCombatNoSpecialSkillContent")
        local status = XDataCenter.PivotCombatManager.IsShowedDialogHintTip()
        local hintInfo = {
            SetHintCb = XDataCenter.PivotCombatManager.SetDialogHintCookie,
            Status = status,
            IsNeedClose = false,
        }
        
        XUiManager.DialogHintTip(title, content, "", negativeCb, positiveCb, hintInfo)
    end
    
    --==============================
     ---@desc 获取战斗时间
     ---@fightScoreTime 通关时间积分
     ---@return string format 00:00
    --==============================
    function XPivotCombatManager.GetFightTime(fightScoreTime)
        if not XTool.IsNumberValid(fightScoreTime) then return "00:00" end
        -- 计算公式  时间积分 = 初始值 - 通关时间秒数
        local time = XPivotCombatConfigs.FightTimeScoreInitialValue - fightScoreTime
        local min = math.floor(time / 60)
        local sec = math.floor(time % 60)
        return string.format("%02d:%02d", min, sec)
    end
    
    --endregion
    
    --region 队伍信息
  
    --===========================================================================
     ---@desc 获取队伍信息
    --===========================================================================
    function XPivotCombatManager.GetTeam(regionId)
        local key = regionId.._TeamDataKey
        local teamId = XPivotCombatManager.GetCookieKey(key)
        local team = _TeamDict[teamId]
        if not team then
            team = XTeam.New(teamId)
            _TeamDict[teamId] = team
        end
        --检查服务端是否被清档，本地team仍然存在这个角色的情况
        local entityIds = team:GetEntityIds()
        for _, id in ipairs(entityIds or {}) do
            if not XTool.IsNumberValid(id) then
                goto CONTINUE
            end
            if XRobotManager.CheckIsRobotId(id) then
                goto CONTINUE
            end
            local isOwnerCharacter = XDataCenter.CharacterManager.IsOwnCharacter(id)
            --如果这个角色在队伍中,
            if not isOwnerCharacter then
                team:Clear()
                break
            end
            ::CONTINUE::
        end
        return team
    end
    
    --===========================================================================
     ---@desc 清空队伍信息
    --===========================================================================
    function XPivotCombatManager.ClearTeam()
        for _, team in pairs(_TeamDict) do
            if team then
                team:Clear()
            end
        end
    end
    
    --===========================================================================
     ---@desc 获取所有能够参战角色信息
     ---@param {characterType}角色类型 
     ---@return {table} 角色列表
    --===========================================================================
    function XPivotCombatManager.GetFightEntities(characterType)
        local result = {}
        --玩家拥有的角色
        local characters = XDataCenter.CharacterManager.GetOwnCharacterList()
        for _, character in ipairs(characters or {}) do
            if character:GetCharacterViewModel():GetCharacterType() == characterType then
                table.insert(result, character)
            end
        end
        --配置机器人
        local robots = XPivotCombatManager.GetFightRobots()
        for _, robot in ipairs(robots or {}) do
            if robot:GetCharacterViewModel():GetCharacterType() == characterType then
                table.insert(result, robot)
            end
        end
        return result
    end
    
    --===========================================================================
     ---@desc 获取配置的机器人
    --===========================================================================
    function XPivotCombatManager.GetFightRobots()
        local robots = {}
        local allRobots = XPivotCombatConfigs.GetRobotSources()
        for _, config in ipairs(allRobots) do
            local robotId = config.RobotId
            if XTool.IsNumberValid(robotId) and XRobotManager.CheckIsRobotId(robotId) then
                local robot = GetRobot(robotId)
                table.insert(robots, robot)
            end
        end
        return robots
    end
    
    --endregion
    
    --region 本地缓存
    
    function XPivotCombatManager.GetCookieKey(key)
        if not key then return end
        
        if not XTool.IsNumberValid(_ActivityId) then
            return
        end
        return string.format("XPivotCombatManager_%d_%d_%s", XPlayer.Id, _ActivityId, key)
    end
    
    --===========================================================================
     ---@desc 是否已经显示每日提示
    --===========================================================================
    function XPivotCombatManager.IsShowedDialogHintTip()
        local key = XPivotCombatManager.GetCookieKey(_NoLearnSkillKey)
        
        local updateTime = XSaveTool.GetData(key)
        if not updateTime then
            return false
        end
        return XTime.GetServerNowTimestamp() < updateTime
    end
    
    --===========================================================================
     ---@desc 选中今日不再提示，isSelect 是否选择今日不再提示
    --===========================================================================
    function XPivotCombatManager.SetDialogHintCookie(isSelect)
        local key = XPivotCombatManager.GetCookieKey(_NoLearnSkillKey)
        if not isSelect then
            XSaveTool.RemoveData(key)
        else
            if XPivotCombatManager.IsShowedDialogHintTip() then return end
            local updateTime = XTime.GetSeverTomorrowFreshTime()
            XSaveTool.SaveData(key, updateTime)
        end
    end
    
    --endregion

    --region 适配FubenManager内的方法
    
    --===========================================================================
     ---@desc 初始化StageInfo
    --===========================================================================
    function XPivotCombatManager.InitStageInfo()
        local stageIds = XPivotCombatConfigs.GetAllStageIds()
        for _, stageId in ipairs(stageIds) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.PivotCombat
            end
        end
    end

    --===========================================================================
     ---@desc 战斗前的检查与数据准备
    --===========================================================================
    function XPivotCombatManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        local preFight = {}
        preFight.CardIds = {0, 0, 0}
        preFight.RobotIds = {0, 0, 0}
        preFight.StageId = stage.StageId
        preFight.IsHasAssist = isAssist and true or false
        preFight.ChallengeCount = challengeCount or 1
        local team = _TeamDict[teamId]
        if not team then
            team = XTeam.New(teamId)
            _TeamDict[teamId] = team
        end
        local teamData = team:GetEntityIds()
        for teamIndex, characterId in pairs(teamData) do
            if XRobotManager.CheckIsRobotId(characterId) then
                preFight.RobotIds[teamIndex] = characterId
            else
                preFight.CardIds[teamIndex] = characterId
            end
        end
        preFight.CaptainPos = team:GetCaptainPos()
        preFight.FirstFightPos = team:GetFirstFightPos()
        return preFight
    end
    
    --===========================================================================
     ---@desc 自定义进入战斗
    --===========================================================================
    function XPivotCombatManager.CustomOnEnterFight(preFight, callback)
        local stageId = preFight.StageId
        if XPivotCombatManager.CheckIsTeachStage(stageId) then
            XPivotCombatManager.DoEnterFightWithLocal(preFight)
        else
            XPivotCombatManager.DoEnterFightWithNetwork(preFight, callback)
        end
    end
    
    --===========================================================================
     ---@desc 本地构造战斗
    --===========================================================================
    function XPivotCombatManager.DoEnterFightWithLocal(preFight)
        local stageId = preFight.StageId
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)

        local fightData = {}
        fightData.RoleData = {}
        fightData.FightId = 1
        fightData.Online = false
        fightData.Seed = 1
        fightData.StageId = stageId

        local roleData = {}
        roleData.NpcData = {}
        table.insert(fightData.RoleData, roleData)
        roleData.Id = XPlayer.Id
        roleData.Name = CSXTextManagerGetText("Aha")
        roleData.Camp = 1

        for idx, robotId in ipairs(stageCfg.RobotId or {}) do
            if XRobotManager.CheckIsRobotId(robotId) then
                local robot = XRobotManager.GetRobotById(robotId)
                local npcData = robot:GetNpcData()
                npcData.Character.FashionId = robot:GetCharacterViewModel().FashionId
                roleData.NpcData[idx - 1] = npcData
            end
        end

        fightData.RebootId = stageCfg.RebootId

        local endFightCb = function()
            if stageCfg.EndStoryId then
                XDataCenter.MovieManager.PlayMovie(stageCfg.EndStoryId)
            end
        end

        local enterFightFunc = function()
            XDataCenter.FubenManager.CallOpenFightLoading(stageId)

            local args = CS.XFightClientArgs()
            args.RoleId = XPlayer.Id
            args.CloseLoadingCb = function()
                XDataCenter.FubenManager.CallCloseFightLoading(stageId)
            end
            args.FinishCbAfterClear = function()
                endFightCb()
            end
            args.ClientOnly = true
            CS.XFight.Enter(fightData, args)
        end
        enterFightFunc()
    end
    
    --===========================================================================
     ---@desc 联网战斗
    --===========================================================================
    function XPivotCombatManager.DoEnterFightWithNetwork(preFight, callback)
        XNetwork.Call("PreFightRequest", { PreFightData = preFight }, function(res)
            if callback then callback(res) end
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local fightData = res.FightData
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(fightData.StageId)
            local stage = XDataCenter.FubenManager.GetStageCfg(fightData.StageId)
            local isKeepPlayingStory = stage and XFubenConfigs.IsKeepPlayingStory(stage.StageId) and (stage.BeginStoryId)
            local isNotPass = stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed)
            if isKeepPlayingStory or isNotPass then
                -- 播放剧情，进入战斗
                XDataCenter.FubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId)
            else
                -- 直接进入战斗
                XDataCenter.FubenManager.EnterRealFight(preFight, fightData)
            end
        end)
    end
    
    --===========================================================================
     ---@desc 检查关卡是否通关
    --===========================================================================
    function XPivotCombatManager.CheckPassedByStageId(stageId)
        local stage = _StageInfo[stageId]
        if not stage then
            return false
        end
        return stage:GetPassed()
    end
    
    --===========================================================================
     ---@desc 检查关卡是否解锁
    --===========================================================================
    function XPivotCombatManager.CheckUnlockByStageId(stageId)
        --教学关卡默认开启
        if XPivotCombatManager.CheckIsTeachStage(stageId) then
            return true
        end
        local stage = _StageInfo[stageId]
        if not stage then
            return false
        end
        return stage:CheckIsUnlock()
    end
    
    --===========================================================================
     ---@desc 刷新关卡状态
    --===========================================================================
    function XPivotCombatManager.RefreshStageInfo(stageId, stage)
        _StageInfo[stageId] = stage
    end

    --===========================================================================
     ---@desc 获取关卡配置
    --===========================================================================
    function XPivotCombatManager.GetStage(stageId)
        return _StageInfo[stageId]
    end

    --===========================================================================
     ---@desc 处理战斗结束
    --===========================================================================
    function XPivotCombatManager.FinishFight(settle)
        if settle.IsWin then
            local stage = XPivotCombatManager.GetStage(settle.StageId)
            if stage then
                stage:SetPassed(true)
            end
            XDataCenter.FubenManager.ChallengeWin(settle)
        else
            XDataCenter.FubenManager.ChallengeLose(settle)
        end
    end
    
    --===========================================================================
     ---@desc 处理战斗胜利界面
    --===========================================================================
    function XPivotCombatManager.ShowReward(winData)
        local stageId = winData.StageId
        local stage = _StageInfo[stageId]
        if stage and stage:CheckIsScoreStage() then
            XLuaUiManager.Open("UiPivotCombatCenterSettle", winData)
        else
            XDataCenter.FubenManager.ShowReward(winData)
        end
    end
    
    --endregion
    
    --region 双端交互
    
    --===========================================================================
     ---@desc 推送枢纽作战数据信息, 登录下发
     ---@param {data} 枢纽作战基础数据 (XPivotCombatBaseData)
        --[[    data = {
                    int ActivityId; 活动Id
                    int Difficulty; 难度
                    int Score; 中心区域最高分
                    List<XPivotCombatRegionData> RegionDataList; 区域数据列表
                }
        ]]--
    --===========================================================================
    function XPivotCombatManager.NotifyPivotCombatData(data)
        --收到协议，需要显示活动入口
        _IsReceiveAgreement = true
        local pivotData = data.PivotCombatData
        local activityId = pivotData.ActivityId
        _IsOpening = activityId > 0 and true or false
        --检查活动是否结束，或者更换期数
        CheckActivityState(activityId)
        InitConfigs(activityId)
        _RegionDifficult = pivotData.Difficulty
        InitRegionConfig()
        XPivotCombatManager.RefreshRegionData(pivotData.RegionDataList)
        
        --刷新评分相关
        InitHistoryScore()
    end
    
    --===========================================================================
     ---@desc 推送区域供能等级变更信息
     ---@param {data} {int RegionId; int SupplyEnergyLevel; 变更后供能等级} 
     ---@return nil
    --===========================================================================
    function XPivotCombatManager.NotifyRegionDataChangeInfo(data)
        local regionId = data.RegionId
        local item = _RegionId2Region[regionId]
        if item then
            item:RefreshSingleStage(data)
        end
    end
    
    --===========================================================================
     ---@desc 取消锁定角色请求
     ---@param {cb} 收到服务器回应成功后的回调
     ---@param {regionId} 区域ID
     ---@param {stageId} 关卡ID
    --===========================================================================
    function XPivotCombatManager.CancelLockCharacterPivotCombatRequest(regionId, stageId, cb)
        local request = {
            RegionId = regionId,
            StageId = stageId,
        }
        
        XNetwork.Call(REQUEST_FUNC_NAME.CancelLockCharacterPivotCombatRequest, request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local rgId = res.RegionId
            local item = _RegionId2Region[rgId]
            if item then
                item:CancelLockCharacter(res.SupplyEnergyLevel, res.StageId)
            end
            if cb then
                cb()
            end
        end)
    end
    
    --===========================================================================
     ---@desc 获取指定难度排行信息响应
     ---@param {difficulty} 难度 
    --===========================================================================
    function XPivotCombatManager.GetRankInfoPivotCombatRequest(difficulty, cb)
        local timeOfNow = XTime.GetServerNowTimestamp()
        local timeOfLast = _LastSyncServerTimes[difficulty]
        if timeOfLast and timeOfLast + _SyncServerTime >= timeOfNow then
            local data = _RankData[difficulty]
            if not data then
                XLog.Warning("No Rank Data, difficulty = "..difficulty)
                return
            end
            if cb then
                cb(data.RankList, data.Ranking, data.TotalCount)
            end
            return
        end
        --排行榜的难度是玩家本期活动难度，只有玩家分数突破记录才刷新
        if difficulty == _RegionDifficult and _MaxScore <= _LastRefreshScore then
            local data = _RankData[difficulty]
            if not data then
                XLog.Warning("No Rank Data, difficulty = "..difficulty)
                return
            end
            if cb then
                cb(data.RankList, data.Ranking, data.TotalCount)
            end
            return
        end
        local request = { Difficulty = difficulty }
        --[[
            res = {
                XCode Code; 状态码
                int Ranking; 自己排名
                long TotalCount; 排行榜总人数（参与玩法的人数，可能量很大）
                List<XPivotCombatRankPlayerInfo> RankPlayerInfoList; 排行榜玩家信息列表（索引就是排名,从零开始）
            }
        ]]
        XNetwork.Call(REQUEST_FUNC_NAME.GetRankInfoPivotCombatRequest, request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            _LastSyncServerTimes[difficulty] = timeOfNow
            local totalCount = res.TotalCount
            local tmpCount = totalCount > _MaxRankMember and _MaxRankMember or totalCount
            local rankList = {}
            for idx, info in ipairs(res.RankPlayerInfoList or {}) do
                if idx > tmpCount then break end
                local item = XPivotCombatRankItem.New(info, idx, totalCount)
                table.insert(rankList, item)
            end
            
            if cb then
                cb(rankList, res.Ranking, totalCount)
            end
            
            --更新缓存
            _RankData[difficulty] = {
                RankList   = rankList,
                Ranking    = res.Ranking,
                TotalCount = totalCount
            }
            --刷新上次进入排行榜的分数
            if difficulty == _RegionDifficult then
                _LastRefreshScore = _MaxScore
            end
        end)
    end
    
    --==============================
     ---@desc 选择难度
     ---@difficulty 难度参数 
     ---@cb 选择难度回调
    --==============================
    function XPivotCombatManager.SelectDifficultyPivotCombatRequest(difficulty, cb)
        local request = { Difficulty = difficulty }
        -- res = { XCode Code }
        
        XNetwork.Call(REQUEST_FUNC_NAME.SelectDifficultyPivotCombatRequest, request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code) 
                return
            end
            _RegionDifficult = difficulty
            InitRegionConfig()
            
            if cb then
                cb()
            end
        end)
    end
    
    --endregion
    
    return XPivotCombatManager
end

--region S2CFunction
XRpc.NotifyPivotCombatData = function(data) 
    XDataCenter.PivotCombatManager.NotifyPivotCombatData(data)
end
XRpc.NotifyRegionDataChangeInfo = function(data) 
    XDataCenter.PivotCombatManager.NotifyRegionDataChangeInfo(data)
end
--endregion