---@class XFightLevelMusicGame
local XFightLevelMusicGame = XClass(nil, "XFightLevelMusicGame")

function XFightLevelMusicGame:Ctor(mapId)
    -- cfg
    self._MapId = mapId
    self._TutorialId = 0
    ---@type table<number, number>
    self._TrackIdList = false
    
    -- Logic
    self._State = XEnumConst.FIGHT_LEVEL_MUSIC.GAME_STATE.GAMING
    --- 当前游戏状态倒计时
    ---@type number[]
    self._CurGameStateTimer = {}
    --- 当前执行track索引
    self._CurTrackIndex = 1
    self._LimitTime = 0
    self._CurTime = 0

    -- Data
    --- 判定区
    ---@type XFightLevelMusicArea[]
    self._AreaPointList = false
    --- key = trackId, value = track
    ---@type table<number, XFightLevelMusicTrack>
    self._TrackList = {}
    --- key = trackId, value = noteList, noteList.length不一定 = track.length
    ---@type table<number, XFightLevelMusicNote[]>
    self._TrackNoteList = {}
end

--region Setter
function XFightLevelMusicGame:SetTutorialId(tutorialId)
    self._TutorialId = tutorialId
end

function XFightLevelMusicGame:SetTrackIdList(trackIdList)
    self._TrackIdList = trackIdList
end

function XFightLevelMusicGame:SetLimitTime(limitTime)
    self._LimitTime = limitTime
    self._CurTime = self._LimitTime
end
--endregion

--region Getter
function XFightLevelMusicGame:GetTutorialId()
    return self._TutorialId
end

function XFightLevelMusicGame:GetCurNoteList()
    if not self._TrackIdList[self._CurTrackIndex] then
        --XLog.Error("FightLevelMusicGame TrackId in TrackIdList is null! Index = "..self._CurTrackIndex)
        return false
    end
    if not self._TrackNoteList[self._CurTrackIndex] then
        --XLog.Error("FightLevelMusicGame Track is null! TrackId = "..self._CurTrackIndex)
        return false
    end
    return self._TrackNoteList[self._CurTrackIndex]
end

---@return XFightLevelMusicTrack
function XFightLevelMusicGame:GetCurTrack()
    if not self._TrackIdList[self._CurTrackIndex] then
        --XLog.Error("FightLevelMusicGame TrackId in TrackIdList is null! Index = "..self._CurTrackIndex)
        return false
    end
    if not self._TrackList[self._CurTrackIndex] then
        --XLog.Error("FightLevelMusicGame Track is null! TrackId = "..self._CurTrackIndex)
        return false
    end
    return self._TrackList[self._CurTrackIndex]
end

function XFightLevelMusicGame:GetCurTrackLength()
    local track = self:GetCurTrack()
    if not track then
        return 0
    end
    return track:GetLength()
end

function XFightLevelMusicGame:GetTrackNoteLength(trackIndex)
    if not self._TrackNoteList[trackIndex] then
        return 0
    end
    return #self._TrackNoteList[trackIndex]
end

---@return XFightLevelMusicArea
function XFightLevelMusicGame:GetAreaPoint(index)
    if not self._AreaPointList[index] then
        XLog.Error("FightLevelMusicGame AreaPoint is null! Index = "..index)
        return false
    end
    return self._AreaPointList[index]
end

---@return XFightLevelMusicArea[]
function XFightLevelMusicGame:GetAreaPointList()
    return self._AreaPointList
end

function XFightLevelMusicGame:GetGameStateTime(state)
    return self._CurGameStateTimer[state]
end

function XFightLevelMusicGame:_LogString()
    -- 基础数据
    XLog.Error("LevelMusic 基础数据: "
            .." MapId: "..self._MapId
            .." CurTrackId: "..tostring(self._TrackIdList[self._CurTrackIndex])
            .." State: "..tostring(self._State)
            ..(self:IsLimitTime() and " LimitTime: "..tostring(self._LimitTime).." CurTime: "..tostring(self._CurTime) or "")
            .." TrackIdList: ", self._TrackIdList)
    
    -- AreaPoint
    local string = "LevelMusic 移动点:\n"
    for i, v in ipairs(self._AreaPointList) do
        string = string.."["..i.."]: "..v:ToString()
    end
    XLog.Error(string)
    
    -- Note
    string = "LevelMusic 物件:\n"
    for trackIndex, noteList in ipairs(self._TrackNoteList) do
        for i, v in ipairs(noteList) do
            string = string.."trackId: "..self._TrackIdList[trackIndex].." ["..i.."]: ".. v:ToString().."\n"
        end
        string = string.."\n"
    end
    XLog.Error(string)
    
    -- Track
    string = "LevelMusic 轨道:\n"
    for i, v in ipairs(self._TrackList) do
        string = string .. "[" .. i .. "]: " .. v:ToString()
    end
    XLog.Error(string)
end
--endregion

--region Checker
function XFightLevelMusicGame:IsLimitTime()
    return XTool.IsNumberValid(self._LimitTime)
end

function XFightLevelMusicGame:IsCurTrackOver()
    return self:GetCurTrack():IsClear()
end

function XFightLevelMusicGame:IsHaveGameStateTime(state)
    local time = self:GetGameStateTime(state)
    return time and XTool.IsNumberValid(time)
end

function XFightLevelMusicGame:IsGaming()
    return self:_IsGameState(XEnumConst.FIGHT_LEVEL_MUSIC.GAME_STATE.GAMING)
            or self:_IsGameState(XEnumConst.FIGHT_LEVEL_MUSIC.GAME_STATE.MISS)
end

function XFightLevelMusicGame:IsMiss()
    return self:_IsGameState(XEnumConst.FIGHT_LEVEL_MUSIC.GAME_STATE.MISS)
end

function XFightLevelMusicGame:IsGameStop()
    return self:IsGameClear() or self:IsGameOver()
end

function XFightLevelMusicGame:IsGameClear()
    return self:_IsGameState(XEnumConst.FIGHT_LEVEL_MUSIC.GAME_STATE.CLEAR)
end

function XFightLevelMusicGame:IsGameOver()
    return self:_IsGameState(XEnumConst.FIGHT_LEVEL_MUSIC.GAME_STATE.TIMEOUT)
end

function XFightLevelMusicGame:_IsGameState(state)
    return self._State == state
end
--endregion

--region Game - Data
---@param areaPoint XFightLevelMusicArea
function XFightLevelMusicGame:AddAreaPoint(index, areaPoint)
    if not self._AreaPointList then
        self._AreaPointList = {}
    end
    if self._AreaPointList[index] then
        return
    end
    self._AreaPointList[index] = areaPoint
end

---@param trackIndex number
---@param note XFightLevelMusicNote
function XFightLevelMusicGame:AddTrackNote(trackIndex, note)
    if not self._TrackIdList or not self._TrackIdList[trackIndex] then
        XLog.Error("XFightLevelMusicGame.AddTrackNote() Error! MapId = "..self._MapId..", trackIndex = "..trackIndex)
        return
    end
    if not self._TrackNoteList[trackIndex] then
        self._TrackNoteList[trackIndex] = {}
    end
    table.insert(self._TrackNoteList[trackIndex], note)
end

---@param trackIndex number
---@param track XFightLevelMusicTrack
function XFightLevelMusicGame:AddTrack(trackIndex,  track)
    if not self._TrackIdList or not self._TrackIdList[trackIndex] then
        XLog.Error("XFightLevelMusicGame.AddTrack() Error! MapId = "..self._MapId..", trackIndex = "..trackIndex)
        return
    end
    if not  self._TrackList[trackIndex] then
        self._TrackList[trackIndex] = {}
    end
    self._TrackList[trackIndex] = track
end

function XFightLevelMusicGame:AddGameStateTime(gameState, time)
    self._CurGameStateTimer[gameState] = time
end

function XFightLevelMusicGame:CutGameStateTime(gameState, time)
    local stateTime = self._CurGameStateTimer[gameState]
    if not stateTime then
        self._CurGameStateTimer[gameState] = 0
    end
    stateTime = stateTime - time
    self._CurGameStateTimer[gameState] = math.max(0, stateTime)
end

function XFightLevelMusicGame:RefreshAreaPointRLData(trackDistance)
    local trackLength = self:GetCurTrackLength()
    for _, areaPoint in ipairs(self._AreaPointList) do
        areaPoint:RefreshRLData(trackDistance, trackLength)
    end
end
--endregion

--region Game - Action
function XFightLevelMusicGame:Trigger(noteType, areaPointIndex)
    if self:IsHaveGameStateTime(XEnumConst.FIGHT_LEVEL_MUSIC.GAME_STATE.MISS) then
        return
    end
    local track = self:GetCurTrack()
    if not track then
        return XEnumConst.FIGHT_LEVEL_MUSIC.TRIGGER_RESULT.NONE
    end
    -- 触发情况下指针走到下一格才能继续触发
    local areaPoint = self:GetAreaPoint(areaPointIndex)
    if not areaPoint or areaPoint:IsInTrigger() then
        return XEnumConst.FIGHT_LEVEL_MUSIC.TRIGGER_RESULT.NONE
    end
    
    local triggerResult, noteIndex = track:Trigger(areaPoint:GetCurTriggerUnitIndexList(), noteType)
    areaPoint:UpdateRLDirection(true)
    if triggerResult == XEnumConst.FIGHT_LEVEL_MUSIC.TRIGGER_RESULT.CLEAR then
        areaPoint:InTrigger()
    else
        self:AddGameStateTime(XEnumConst.FIGHT_LEVEL_MUSIC.GAME_STATE.MISS, 0.5)
    end

    -- track清空
    if self:IsCurTrackOver() then
        local gameState = XEnumConst.FIGHT_LEVEL_MUSIC.GAME_STATE.TRACK_CHANGE
        self._CurTrackIndex = self._CurTrackIndex + 1
        self:AddGameStateTime(gameState, 1)
        if self._CurTrackIndex <= #self._TrackIdList then
            XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_LEVEL_MUSIC_TRACK_CHANGE, self:GetGameStateTime(gameState))
        end
    end

    self:_UpdateGameState()
    return triggerResult, noteIndex
end

function XFightLevelMusicGame:_TimeDown(time)
    self._CurTime = self._CurTime - time

    self:_UpdateGameState()
end
--endregion

--region Game - Update
function XFightLevelMusicGame:Update(time)
    self:_UpdateGameStateTimer(time)
    self:_UpdateGameState()
    
    if not self:IsGaming() then
        return
    end
    
    self:_UpdateLimitTime(time)
    self:_UpdateAreaPoint(time)
end

function XFightLevelMusicGame:_UpdateGameStateTimer(time)
    local state = XEnumConst.FIGHT_LEVEL_MUSIC.GAME_STATE.TRACK_CHANGE
    if self:_IsGameState(state) and self:IsHaveGameStateTime(state) then
        self:CutGameStateTime(state, time)
    end

    state = XEnumConst.FIGHT_LEVEL_MUSIC.GAME_STATE.MISS
    if self:_IsGameState(state) and self:IsHaveGameStateTime(state) then
        self:CutGameStateTime(state, time)
    end
end

function XFightLevelMusicGame:_UpdateLimitTime(time)
    if self:IsLimitTime() then
        self:_TimeDown(time)
    end
end

function XFightLevelMusicGame:_UpdateGameState()
    if self._CurTrackIndex > #self._TrackIdList then
        self._State = XEnumConst.FIGHT_LEVEL_MUSIC.GAME_STATE.CLEAR
        -- 延后0.5秒走完最后一个
        XScheduleManager.ScheduleOnce(function()
            XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_LEVEL_MUSIC_WIN)
        end, 500)
        return
    end

    if self:IsLimitTime() and self._CurTime <= 0 and not self:IsGameClear() then
        self._State = XEnumConst.FIGHT_LEVEL_MUSIC.GAME_STATE.TIMEOUT
        XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_LEVEL_MUSIC_FAIL)
        return
    end

    local gameState = XEnumConst.FIGHT_LEVEL_MUSIC.GAME_STATE.MISS
    if self:IsHaveGameStateTime(gameState) then
        self._State = gameState
        return
    end

    gameState = XEnumConst.FIGHT_LEVEL_MUSIC.GAME_STATE.TRACK_CHANGE
    if self:IsHaveGameStateTime(gameState) then
        self._State = gameState
        return
    end

    self._State = XEnumConst.FIGHT_LEVEL_MUSIC.GAME_STATE.GAMING
end

function XFightLevelMusicGame:_UpdateAreaPoint(time)
    for _, areaPoint in ipairs(self._AreaPointList) do
        areaPoint:UpdateRLData(time)
    end
end
--endregion

return XFightLevelMusicGame