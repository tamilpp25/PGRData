local XCTGameData = require("XEntity/XColorTable/Game/XCTGameData")
local XCTEvent = require("XEntity/XColorTable/Game/XCTEvent")
local XCTEffect = require("XEntity/XColorTable/Game/XCTEffect")

local XCTGameManager = XClass(nil, "XCTGameManager")

local RequsetName = {
    RequestStartFight = "ColorTableStartFightRequest",        --开始地图玩法
    RequestContinueGame = "ColorTableContinueGameRequest",    --继续游戏
    RequestTargetPoint = "ColorTableTargetPointRequest",      --查看目标消耗与寻路
    RequestMove = "ColorTableMoveRequest",                    --移动
    RequestEndRound = "ColorTableEndRoundRequest",            --玩家结束回合
    RequestExecute = "ColorTableExecuteRequest",              --执行行动
    RequestGiveUp = "ColorTableGiveUpRequest",                --失败后放弃
    RequestReboot = "ColorTableRebootRequest",                --失败后重启
    RequestRoll = "ColorTableRollRequest",                    --Roll数据
    RequestReRoll = "ColorTableReRollRequest",                --重Roll数据
}

XCTGameManager.DoAction = {
    [XColorTableConfigs.ActionType.BlockSettle] = function(self, action)
        XLuaUiManager.SetMask(false)
        XLuaUiManager.Open("UiColorTableStageBoss", action.SettleType, action.LevelChanges, function()
            XLuaUiManager.SetMask(true)
            self.GameData:SetBossLevels(action.LevelChanges)
            XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_BLOCKSETTLE, action.LevelChanges)
            self:SetActionFinish(action.ActionType)
        end)
    end,

    [XColorTableConfigs.ActionType.BurstSettle] = function(self, action)
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_BURSTSETTLE, action.Settles, function()
            self:SetActionFinish(action.ActionType)
        end)
    end,

    [XColorTableConfigs.ActionType.TimeBlockChange] = function(self, action)
        self.GameData:SetTimelineId(action.TimelineId)
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_TIMEBLOCKCHANGE, function ()
            self:SetActionFinish(action.ActionType)
        end)
    end,

    [XColorTableConfigs.ActionType.RemoveEvent] = function(self, action)
        self:SetActionFinish(action.ActionType)
    end,

    [XColorTableConfigs.ActionType.AddEvent] = function(self, action)
        local eventId = action.ColorTableEvent.EventId
        XLuaUiManager.SetMask(false)
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_ADDEVENT, eventId, function ()
            XLuaUiManager.SetMask(true)
            self:SetActionFinish(action.ActionType)
        end)
    end,

    -- 事件效果触发，右上角提示后马上消失
    [XColorTableConfigs.ActionType.EffectTakeEffect] = function(self, action)
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_EFFECTTAKEEFFECT, self.ShowEffectDic)
        self:SetActionFinish(action.ActionType)
    end,

    [XColorTableConfigs.ActionType.GameLose] = function(self, action)
        self.GameData:SetIsLose(1)
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_GAMELOSE)
        self:SetActionFinish(action.ActionType)
    end,

    [XColorTableConfigs.ActionType.StudyLevelChange] = function(self, action)
        XLuaUiManager.SetMask(false)
        self.GameData:SetStudyLevels(action.StudyLevels)
        local dealLevelCount = 0
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_STUDYLEVELCHANGE, action.StudyLevels, function ()
            dealLevelCount = dealLevelCount + 1
            if dealLevelCount >= self.LabCount then
                XLuaUiManager.SetMask(true)
                self:SetActionFinish(action.ActionType)
            end
        end)
    end,

    -- 游戏地图阶段胜利，弹窗
    [XColorTableConfigs.ActionType.GameWin] = function(self, action)
        self.GameData:SetCurStage(XColorTableConfigs.CurStageType.Fight)
        self.GameData:SetWinConditionId(action.WinConditionId)
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_MAPWIN)
        self:SetActionFinish(action.ActionType)
    end,

    [XColorTableConfigs.ActionType.RemoveEffect] = function(self, action)
        if self.EffectDir[action.EffectUid] ~= nil then
            self.EffectDir[action.EffectUid] = nil
            local index
            for i, effectUid in ipairs(self.ShowEffectDic) do
                if effectUid == action.EffectUid then
                    index = i
                end
            end
            table.remove(self.ShowEffectDic, index)
        end
        self:SetActionFinish(action.ActionType)
    end,

    [XColorTableConfigs.ActionType.NewRound] = function(self, action)
        self.GameData:SetRoundId(action.CurRoundId)
        self.GameData:SetActionPoint(action.CurActionPoint)
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_NEWROUND, action, function ()
            self:SetActionFinish(action.ActionType)
        end)
    end,

    [XColorTableConfigs.ActionType.TriggerDrama] = function(self, action)
        XLuaUiManager.SetMask(false)
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_TRIGGERDRAMA, action.DramaId, function ()
            XLuaUiManager.SetMask(true)
            self:SetActionFinish(action.ActionType)
        end)
    end,

    [XColorTableConfigs.ActionType.StageSettle] = function(self, action)
        XLuaUiManager.SetMask(false)
        self.GameData:SetWinConditionId(action.WinConditionId)
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_STAGESETTLE, action, function ()
            XLuaUiManager.SetMask(true)
            self:SetActionFinish(action.ActionType)
        end)
    end,

    [XColorTableConfigs.ActionType.TimeBlockReset] = function(self, action)
        self.GameData:SetTimeBlock(action.TimeBlock)
        self.GameData:SetTimelineId(action.TimelineId)
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_TIMEBLOCKRESET, function ()
            self:SetActionFinish(action.ActionType)
        end)
    end,

    [XColorTableConfigs.ActionType.ActionPointChange] = function(self, action)
        self.GameData:SetActionPoint(action.CurActionPoint)
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_ACTIONPOINTCHANGE, action.CurActionPoint)
        self:SetActionFinish(action.ActionType)
    end,

    [XColorTableConfigs.ActionType.StudyDataChange] = function(self, action)
        self.GameData:SetStudyDatas(action.StudyDatas)
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_STUDYDATACHANGE, action.StudyDatas)
        self:SetActionFinish(action.ActionType)
    end,

    [XColorTableConfigs.ActionType.BossLevelChange] = function(self, action)
        self.GameData:SetBossLevels(action.BossLevels)
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_BOSSLEVELCHANGE, action.BossLevels)
        self:SetActionFinish(action.ActionType)
    end,
}

function XCTGameManager:Ctor()
    self.GameData = XCTGameData.New()
    self:Init()
    self.DontShowRollAnim = false         -- setting-不再播放Roll点动画(每次登录默认为关)
end

function XCTGameManager:Init()
    self.GameData:Init()
    self.Paths = {}                 -- 移动路径
    self.EventDir = {}              -- 本局游戏事件字典
    self.EffectDir = {}             -- 本局游戏效果字典
    self.ShowEffectDic = {}         -- 触发效果字典(右上角显示)
    self.ShowEventIdDic = {}        -- 关卡详情面板显示
    self.DramaConditionDic = {}     -- 关卡客户端吐槽判断字典
    self.EsayActionMode = false     -- setting-便捷模式(每关开始默认为关)
    self.CurMainInfoTipType = 0     -- setting-当前打开的关卡说明界面类型
    self.LabCount = 0               -- 本局游戏研究所数量

    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_ACTIONFINISH, self.SetActionFinish, self)
end

function XCTGameManager:UpdateGameData(data)
    self.GameData:UpdateData(data)
    if data.Events ~= nil then
        for _, event in ipairs(data.Events) do
            if not XTool.IsTableEmpty(event) then
                self:AddEvent(event.Uid, event)
            end
        end
        self:UpdateShowEventDir()
    end
    if data.Effects ~= nil then
        for _, effect in ipairs(data.Effects) do
            if not XTool.IsTableEmpty(effect) then
                self:AddEffect(effect.Uid, effect)
            end
        end
    end
end


-- Client Action
--============================================================================

function XCTGameManager:GetActionList()
    return self.ActionList
end

function XCTGameManager:ClearActionList()
    self.ActionList = nil
end

function XCTGameManager:SetActionList(actions)
    self.ActionList = actions
    self.ActionListIndex = 1
    self.IsActionDoingDic = {}
    self:SetPreData()
end

function XCTGameManager:SetPreData()
    for _, action in pairs(self.ActionList or {}) do
        if action.ActionType == XColorTableConfigs.ActionType.AddEvent then
            local colorTableEvent = action.ColorTableEvent
            local colorTableEffects = action.ColorTableEffects
            self:AddEvent(colorTableEvent.Uid, colorTableEvent)
            for _, colorTableEffect in ipairs(colorTableEffects) do
                self:AddEffect(colorTableEffect.Uid, colorTableEffect)
            end
            self:UpdateShowEventDir()
        end
        if action.ActionType == XColorTableConfigs.ActionType.RemoveEvent then
            if self.EventDir[action.EventUid] ~= nil then
                self.EventDir[action.EventUid] = nil
            end
            self:UpdateShowEventDir()
        end
        if action.ActionType == XColorTableConfigs.ActionType.EffectTakeEffect then
            if self.EffectDir[action.EffectUid] ~= nil then
                if XTool.IsNumberValid(self.EffectDir[action.EffectUid]:GetShowType()) then
                    table.insert(self.ShowEffectDic, self.EffectDir[action.EffectUid]:GetEffectId())
                end
            end
        end
    end
end

function XCTGameManager:SetActionFinish(actionType)
    self.IsActionDoingDic[actionType] = nil
    self:CheckActionList()
end

-- 行动执行
function XCTGameManager:CheckActionList()
    if self.ActionList and not self:CheckActionIsDoing() then
        local action = self.ActionList[self.ActionListIndex]

        if self.ActionListIndex == 1 then
            XLuaUiManager.SetMask(true)
            self.IsActionAllFinish = false
        end

        if action then
            self.ActionListIndex = self.ActionListIndex + 1
            self.IsActionDoingDic[action.ActionType] = true
            self.DoAction[action.ActionType](self, action)
        else
            self.ActionList = nil
            self.ActionListIndex = 1
            self.IsActionAllFinish = true
            self:CheckCloseMask()
            XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_OVER)
        end
    end
end

function XCTGameManager:CheckActionIsDoing()
    for _,plaing in pairs(self.IsActionDoingDic or {}) do
        if plaing then
            return true
        end
    end
    return false
end

function XCTGameManager:CheckCloseMask()
    if self.IsActionAllFinish then
        XLuaUiManager.SetMask(false)
    end
end

--============================================================================



-- Client Switch
--============================================================================

function XCTGameManager:SetEsayActionMode(active)
    self.EsayActionMode = active
end

function XCTGameManager:GetEsayActionMode()
    return self.EsayActionMode
end

function XCTGameManager:SetDontShowRollBoss(active)
    self.DontShowRollAnim = active
end

function XCTGameManager:GetDontShowRollBoss()
    return self.DontShowRollAnim
end

--============================================================================



-- Client DramaCondition
--============================================================================

-- 客户端队长对话类剧情倒计时ConditionType
local idleTriggerTypeDic = {
    XColorTableConfigs.DramaConditionType.IdleTimeAndBoss,
    XColorTableConfigs.DramaConditionType.IdleTimeAndData,
    XColorTableConfigs.DramaConditionType.IdleTimeAndAllData,
}

function XCTGameManager:InitDramaConditionData()
    local dramaGroupId = XColorTableConfigs.GetMapDramaGroupId(self.GameData:GetMapId())
    if not XTool.IsNumberValid(dramaGroupId) then
        return
    end
    local dramaIdList = XColorTableConfigs.GetDramaByGroup(dramaGroupId)
    for _, dramaId in ipairs(dramaIdList) do
        local conditionType = XColorTableConfigs.GetDramaConditionType(dramaId)
        if conditionType >= XColorTableConfigs.DramaConditionType.HelpCondition then
            if XTool.IsTableEmpty(self.DramaConditionDic[conditionType]) then
                self.DramaConditionDic[conditionType] = {}
            end
            table.insert(self.DramaConditionDic[conditionType], dramaId)
            self.GameData:AddTalkDramaData(dramaId, 0)
        end
    end
    self.GameData:SaveData()
end

function XCTGameManager:AddDramaConditionCount(conditionType, value)
    if XTool.IsTableEmpty(self.DramaConditionDic[conditionType]) then
        return
    end
    for _, dramaId in ipairs(self.DramaConditionDic[conditionType]) do
        local params = XColorTableConfigs.GetDramaParams(dramaId)
        local data = self.GameData:GetTalkDramaData(dramaId)
        self.GameData:AddTalkDramaData(dramaId, value)
        if data.Count >= params[1] and not data.IsRead then
            self:StopDramaIdleTimer()
            XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_TRIGGERDRAMA, dramaId, function ()
                self:StartDramaIdleTimer()
            end)
            data.IsRead = true
        end
    end
    self.GameData:SaveData()
end

function XCTGameManager:StartDramaIdleTimer()
    self:StopDramaIdleTimer()
    if not self:ChenckIsHaveIdleTimer() then
        return
    end

    local time = 0
    self.DramaIdleTimer = XScheduleManager.ScheduleForever(function ()
        if not self:ChenckIsHaveIdleTimer() then
            self:StopDramaIdleTimer()
        end
        if XLuaUiManager.GetTopUiName() ~= "UiColorTableStageMain" then
            time = 0
            return
        end
        if CS.UnityEngine.Input:GetMouseButtonDown(0) then
            time = 0
            return
        end
        time = time + CS.UnityEngine.Time.deltaTime
        for _, type in pairs(idleTriggerTypeDic) do
            if self:IsTriggerIdleTimeDrama(type, time) then
                return
            end
        end
    end, 0)
end

function XCTGameManager:StopDramaIdleTimer()
    if self.DramaIdleTimer then
        XScheduleManager.UnSchedule(self.DramaIdleTimer)
        self.DramaIdleTimer = nil
    end
end

function XCTGameManager:ChenckIsHaveIdleTimer()
    -- 仅在阶段一计时
    if self.GameData:GetCurStage() ~= XColorTableConfigs.CurStageType.PlayGame or XTool.IsNumberValid(self.GameData:GetIsLose()) then
        return false
    end
    if not XLuaUiManager.IsUiShow("UiColorTableStageMain") then
        return false
    end
    -- 没有idletime类型的condition或已经都触发了也不计时
    for _, type in pairs(idleTriggerTypeDic) do
        if not XTool.IsTableEmpty(self.DramaConditionDic[type]) then
            for _, dramaId in ipairs(self.DramaConditionDic[type]) do
                local data = self.GameData:GetTalkDramaData(dramaId)
                if data and not data.IsRead then
                    return true
                end
            end
        end
    end
    return false
end

function XCTGameManager:IsTriggerIdleTimeDrama(dramaConditionType, time)
    if XTool.IsTableEmpty(self.DramaConditionDic[dramaConditionType]) then return false end
    local randomList = {}
    -- 未触发的加入随机表
    for _, dramaId in ipairs(self.DramaConditionDic[dramaConditionType]) do
        local data = self.GameData:GetTalkDramaData(dramaId)
        if data and not data.IsRead then
            table.insert(randomList, dramaId)
        end
    end
    if XTool.IsTableEmpty(randomList) then return false end

    local index = math.random(1, #randomList)
    local dramaId = randomList[index]
    local params = XColorTableConfigs.GetDramaParams(dramaId)
    local data = self.GameData:GetTalkDramaData(dramaId)
    local isTrigger = false

    if dramaConditionType == XColorTableConfigs.DramaConditionType.IdleTimeAndBoss then
        local bossLevels = self.GameData:GetBossLevels()
        for _, value in ipairs(bossLevels) do
            if value >= params[2] then isTrigger = true end
        end
    elseif dramaConditionType == XColorTableConfigs.DramaConditionType.IdleTimeAndData then
        local datas = self.GameData:GetStudyDatas()
        for _, value in ipairs(datas) do
            if value >= params[2] then isTrigger = true end
        end
    elseif dramaConditionType == XColorTableConfigs.DramaConditionType.IdleTimeAndAllData then
        local datas = self.GameData:GetStudyDatas()
        isTrigger = true
        for _, value in ipairs(datas) do
            if value > params[2] then isTrigger = false end
        end
    end
    self.GameData:SaveData()

    if time >= params[1] and isTrigger and not data.IsRead then
        if XColorTableConfigs.GetDramaRepeatable(dramaId) then
            data.Count = 0
            data.IsRead = false
        else
            data.IsRead = true
        end
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_TRIGGERDRAMA, dramaId)
        return true
    end
    return false
end

--============================================================================



-- Client Data
--============================================================================

function XCTGameManager:AddEvent(eventUid, data)
    local event = self.EventDir[eventUid]
    if event == nil then
        event = XCTEvent.New(data)
        self.EventDir[eventUid] = event
    end
end

function XCTGameManager:AddEffect(effectUid, data)
    local effect = self.EffectDir[effectUid]
    if effect == nil then
        effect = XCTEffect.New(data)
        self.EffectDir[effectUid] = effect
    end
end

function XCTGameManager:GetGameData()
    return self.GameData
end

function XCTGameManager:GetCurMovePaths()
    return self.Paths
end

function XCTGameManager:GetShowEvent()
    return self.ShowEventIdDic
end

-- 获取操作弹窗的EffectId
function XCTGameManager:GetPointEffectList(pointType, colorType)
    local effectIds = {}
    for _, effect in pairs(self.EffectDir) do
        local effectId = effect:GetEffectId()

        local isPointType = XColorTableConfigs.IsShowOnPointType(effectId, pointType)
        local isColorType = pointType == XColorTableConfigs.PointType.Tower and true or XColorTableConfigs.IsShowOnColor(effectId, colorType)
        if isPointType and isColorType then
            table.insert(effectIds, effectId)
        end
    end
    return effectIds
end

-- 判断某点位在Effect影响下是否可用
function XCTGameManager:GetPointIsDiable(pointType, colorType)
    for _, effect in pairs(self.EffectDir) do
        local isPointType = false
        local isColorType = false
        local effectType = effect:GetEffectType()
        local params = effect:GetEffectParams()

        if effectType == XColorTableConfigs.EffectType.Type7 then
            isPointType = pointType == XColorTableConfigs.PointType.Hospital
            isColorType = colorType == params[1]
        elseif effectType == XColorTableConfigs.EffectType.Type20 then
            isPointType = true
            isColorType = colorType == params[1]
        end

        if (isPointType and isColorType)then
            return true
        end
    end
    return false
end

-- 获取操作弹窗按钮显示状态
function XCTGameManager:GetPointActionState(pointType, colorType)
    local canDo, canDSpecial, canKill, canCure = true, false, false, false
    local mapId = self.GameData:GetMapId()

    if pointType == XColorTableConfigs.PointType.Hospital then
        canDo = not self.GameData:CheckIsStudyLevelMax(colorType)
        canDSpecial = not self.GameData:CheckIsStudyLevelMax(colorType)
        canCure = self.GameData:CheckIsStudyLevelMax(colorType)
        canKill = self.GameData:CheckIsStudyLevelMax(colorType) and XTool.IsNumberValid(XColorTableConfigs.GetMapClearable(mapId))
    end

    return canDo, canDSpecial, canKill, canCure
end

function XCTGameManager:GetReRollState()
    for _, effect in pairs(self.EffectDir) do
        local effectType = effect:GetEffectType()
        if effectType == XColorTableConfigs.EffectType.Type27 then
            return true
        end
    end
    return false
end

-- 获取在关卡详情面板展示的事件
function XCTGameManager:UpdateShowEventDir()
    local EventIds = {}
    for _, event in pairs(self.EventDir) do
        if event ~= nil and  XTool.IsNumberValid(event:GetEventShowType()) then
            table.insert(EventIds, event:GetEventId())
        end
    end
    self.ShowEventIdDic = EventIds
    XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_REFRESHEVENT, self.ShowEventIdDic)
end

-- 判断某事件是否是下回合生效(用于面板显示)
function XCTGameManager:CheckEventIsNextRound(eventId)
    local effectUidIds
    for _, event in pairs(self.EventDir) do
        if event:GetEventId() == eventId then
            effectUidIds = event:GetEffectUids()
        end
    end
    if XTool.IsTableEmpty(effectUidIds) then
        return
    end
    for _, effectUidId in ipairs(effectUidIds) do
        if self.EffectDir[effectUidId] ~= nil then
            local lifeType = self.EffectDir[effectUidId]:GetLifeType()
            if lifeType == XColorTableConfigs.EffectLifeType.NextRoundNow or lifeType == XColorTableConfigs.EffectLifeType.NextRoundPersisit then
                return true
            end
        end
    end
    return false
end

-- 判断某节点颜色是否在引导第一关隐藏
function XCTGameManager:CheckIsHideInGuildStage(color)
    return self.GameData:CheckIsFirstGuideStage() and (XColorTableConfigs.GetGuideStageColor() == color)
end

function XCTGameManager:SetCurMainInfoTipType(type)
    self.CurMainInfoTipType = type
    XDataCenter.GuideManager.CheckGuideOpen()	-- 触发引导
end

function XCTGameManager:GetCurMainInfoTipType()
    return self.CurMainInfoTipType
end

function XCTGameManager:AddLabCount()
    self.LabCount = self.LabCount + 1
end

--============================================================================



-- Server Request
--============================================================================

-- 进入地图战斗
-- @captainId：队长ID，默认的队长发0
function XCTGameManager:RequestStartFight(stageId, captainId, callback)
    local requestBody = {
        StageId = stageId,
        CaptainId = captainId,
    }
    XNetwork.Call(RequsetName.RequestStartFight, requestBody, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self:UpdateGameData(res.GameData)
        self.GameData:InitTalkDramaData()
        self:InitDramaConditionData()

        if callback then
            callback()
        end
    end)
end

function XCTGameManager:RequestContinueGame(callback)
    XNetwork.Call(RequsetName.RequestContinueGame, nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self:UpdateGameData(res.GameData)
        self.GameData:LoadData()
        self:InitDramaConditionData()

        if callback then
            callback()
        end
    end)
end

-- 查看目标地点消耗与寻路路径：用于弹窗展示以及移动动画
function XCTGameManager:RequestTargetPoint(positionId, callback)
    local requestBody = {
        PositionId = positionId
    }
    XNetwork.Call(RequsetName.RequestTargetPoint, requestBody, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local temp
        for i = 1, math.floor(#res.Paths / 2), 1 do
            temp = res.Paths[i]
            res.Paths[i] = res.Paths[#res.Paths + 1 - i]
            res.Paths[#res.Paths + 1 - i] = temp
        end
        self.Paths = res.Paths

        if callback then
            callback(res)
        end
    end)
end

-- 正式移动请求，移动前先RequestTargetPoint得到移动路径
function XCTGameManager:RequestMove(positionId, callback)
    local requestBody = {
        PositionId = positionId
    }
    XNetwork.Call(RequsetName.RequestMove, requestBody, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local temp
        for i = 1, math.floor(#res.Paths / 2), 1 do
            temp = res.Paths[i]
            res.Paths[i] = res.Paths[#res.Paths + 1 - i]
            res.Paths[#res.Paths + 1 - i] = temp
        end
        self.Paths = res.Paths

        self.GameData:SetCurPosition(res.CurPositionId)
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_PALYER_MOVE_ANIM, callback)
        self:SetActionList(res.Actions)

        self:CheckActionList()
    end)
end

function XCTGameManager:RequestEndRound(callback)
    XNetwork.Call(RequsetName.RequestEndRound, nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self:SetActionList(res.Actions)

        if callback then
            callback()
        end

        self:CheckActionList()
    end)
end

function XCTGameManager:RequestExecute(isSpecial, callback)
    local requestBody = {
        IsSpecial = isSpecial
    }
    XNetwork.Call(RequsetName.RequestExecute, requestBody, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self:SetActionList(res.Actions)

        if callback then
            callback()
        end

        self:CheckActionList()
    end)
end

-- 失败后放弃
function XCTGameManager:RequestGiveUp(callback)
    local func = function ()
        XNetwork.Call(RequsetName.RequestGiveUp, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            self:SetActionList(res.Actions)

            if callback then
                callback(res)
            end

            self:CheckActionList()
        end)
    end

    if not XTool.IsNumberValid(self.GameData:GetCaptainId()) then
        self:RequestContinueGame(func)
    else
        func()
    end
end

function XCTGameManager:RequestReboot(callback)
    XNetwork.Call(RequsetName.RequestReboot, nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self:SetActionList(res.Actions)
        self.GameData:SetIsLose(0)

        if callback then
            callback()
        end

        self:CheckActionList()
    end)
end

function XCTGameManager:RequestRoll(colorType)
    XNetwork.Call(RequsetName.RequestRoll, nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local canReRoll = self:GetReRollState()
        XLuaUiManager.Open("UiColorTableStageRoll", colorType, res.RollResult, canReRoll)
    end)
end

function XCTGameManager:RequestReRoll(callback)
    XNetwork.Call(RequsetName.RequestReRoll, nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local canReRoll = self:GetReRollState()
        if callback then
            callback(res.RollResult, canReRoll)
        end
    end)
end

--============================================================================

return XCTGameManager