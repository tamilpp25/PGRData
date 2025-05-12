---@class XFightLevelMusicArea
local XFightLevelMusicArea = XClass(nil, "XFightLevelMusicArea")
XFightLevelMusicArea.Uid = 1

function XFightLevelMusicArea:Ctor(type, pos, speed, faultTolerance)
    self._Uid = XFightLevelMusicArea.Uid
    self._MoveType = type
    self._InitPos = pos
    --- 逻辑层移动速度(格/s)
    self._LSpeed = speed
    self._FaultTolerance = faultTolerance
    self._CurUnitIndex = 1

    -- RL
    self._RLDistance = 0
    self._RLTrackUnitLength = 0
    --- 表现层移动速度
    self._RLSpeed = 0
    self._RLCurPos = 0
    self._RLMoveDirection = 0
    self._RLInTriggerIndex = 0

    XFightLevelMusicArea.Uid = XFightLevelMusicArea.Uid + 1
end

--region Setter
function XFightLevelMusicArea:RefreshRLData(rLDistance, trackUnitLength)
    self._RLDistance = rLDistance
    self._RLTrackUnitLength = trackUnitLength
    self._RLSpeed = rLDistance / trackUnitLength * self._LSpeed
    self._RLMoveDirection = self._InitPos > self._RLTrackUnitLength / 2 and XEnumConst.FIGHT_LEVEL_MUSIC.AREA_MOVE_DIRECTION.LEFT
            or XEnumConst.FIGHT_LEVEL_MUSIC.AREA_MOVE_DIRECTION.RIGHT
    self._RLCurPos = self._RLMoveDirection == XEnumConst.FIGHT_LEVEL_MUSIC.AREA_MOVE_DIRECTION.LEFT and self._InitPos * self:GetRLUnitLength()
            or (self._InitPos - 1) * self:GetRLUnitLength()
end
--endregion

--region Getter
function XFightLevelMusicArea:GetFaultTolerance()
    return self._FaultTolerance
end

function XFightLevelMusicArea:GetCurUnitIndex()
    return self._CurUnitIndex
end

---@return number[]
function XFightLevelMusicArea:GetCurTriggerUnitIndexList()
    local unitIndexList = {}
    local curIndex = self:GetCurUnitIndex()
    table.insert(unitIndexList, curIndex)
    if self._FaultTolerance > 0 then
        for i = 1, self._FaultTolerance do
            if self:IsRLMoveDirectionLeft() then
                if curIndex <= self._RLTrackUnitLength - i then
                    table.insert(unitIndexList, curIndex + i)
                end
                if curIndex > i then
                    table.insert(unitIndexList, curIndex - i)
                end
            else
                if curIndex > i then
                    table.insert(unitIndexList, curIndex - i)
                end
                if curIndex <= self._RLTrackUnitLength - i then
                    table.insert(unitIndexList, curIndex + i)
                end
            end
        end
    end
    return unitIndexList
end

function XFightLevelMusicArea:GetRLUnitLength()
    return self._RLDistance / self._RLTrackUnitLength
end

function XFightLevelMusicArea:GetRLCurPos()
    return self._RLCurPos
end

function XFightLevelMusicArea:ToString()
    local string = "Area: { "
            .."\n\tUid = "..self._Uid
            .."\n\tMoveType = "..self._MoveType
            .."\n\tInitPos = "..self._InitPos
            .."\n\tLSpeed = "..self._LSpeed .."(note/s)"
            .."\n\tFaultTolerance = "..self._FaultTolerance
            .."\n\tCurUnitIndex = "..self._CurUnitIndex
            .."\n\tRLDistance = "..self._RLDistance
            .."\n\tRLTrackUnitLength = "..self._RLTrackUnitLength
            .."\n\tRLSpeed = "..self._RLSpeed .."(posX/s)"
            .."\n\tRLCurPos = "..self._RLCurPos
            .."\n\tRLMoveDirection = "..(self:IsRLMoveDirectionLeft() and "Left" or "Right")
            .."\n}"
    return string
end
--endregion

--region Checker
function XFightLevelMusicArea:IsRLMoveDirectionLeft()
    return self._RLMoveDirection == XEnumConst.FIGHT_LEVEL_MUSIC.AREA_MOVE_DIRECTION.LEFT
end

function XFightLevelMusicArea:IsInTrigger()
    return XTool.IsNumberValid(self._RLInTriggerIndex)
end
--endregion

--region Game - Update
function XFightLevelMusicArea:UpdateRLData(time)
    self:_UpdateRLCurPos(time)
    self:UpdateRLDirection(false)
    self:_UpdateCurUnitIndex()
end

function XFightLevelMusicArea:UpdateRLDirection(isTrigger)
    if self._MoveType == XEnumConst.FIGHT_LEVEL_MUSIC.AREA_MOVE_TYPE.REBOUND then
        if self._RLCurPos >= self._RLDistance then
            self._RLMoveDirection = XEnumConst.FIGHT_LEVEL_MUSIC.AREA_MOVE_DIRECTION.LEFT
        end
        if self._RLCurPos <= 0 then
            self._RLMoveDirection = XEnumConst.FIGHT_LEVEL_MUSIC.AREA_MOVE_DIRECTION.RIGHT
        end
    elseif self._MoveType == XEnumConst.FIGHT_LEVEL_MUSIC.AREA_MOVE_TYPE.STRAIGHT then
        if self._RLCurPos >= self._RLDistance then
            self._RLCurPos = 0
        end
    elseif self._MoveType == XEnumConst.FIGHT_LEVEL_MUSIC.AREA_MOVE_TYPE.TRIGGER then
        if isTrigger then
            if self:IsRLMoveDirectionLeft() then
                self._RLMoveDirection = XEnumConst.FIGHT_LEVEL_MUSIC.AREA_MOVE_DIRECTION.RIGHT
            else
                self._RLMoveDirection = XEnumConst.FIGHT_LEVEL_MUSIC.AREA_MOVE_DIRECTION.LEFT
            end
        else
            if self._RLCurPos >= self._RLDistance then
                self._RLMoveDirection = XEnumConst.FIGHT_LEVEL_MUSIC.AREA_MOVE_DIRECTION.LEFT
            end
            if self._RLCurPos <= 0 then
                self._RLMoveDirection = XEnumConst.FIGHT_LEVEL_MUSIC.AREA_MOVE_DIRECTION.RIGHT
            end
        end
    end
end

function XFightLevelMusicArea:_UpdateRLCurPos(time)
    local speed = self._RLMoveDirection == XEnumConst.FIGHT_LEVEL_MUSIC.AREA_MOVE_DIRECTION.LEFT and -self._RLSpeed or self._RLSpeed
    self._RLCurPos = self._RLCurPos + speed * time
    self._RLCurPos = math.min(self._RLCurPos, self._RLDistance)
    self._RLCurPos = math.max(self._RLCurPos, 0)
end

function XFightLevelMusicArea:_UpdateCurUnitIndex()
    self._CurUnitIndex = math.floor(self._RLCurPos / self:GetRLUnitLength()) + 1
    if self._RLInTriggerIndex ~= self._CurUnitIndex 
            or self._CurUnitIndex >= self._RLTrackUnitLength 
            or self._CurUnitIndex <= 0 then
        self._RLInTriggerIndex = 0
    end
    self._CurUnitIndex = math.min(self._CurUnitIndex, self._RLTrackUnitLength)
    self._CurUnitIndex = math.max(self._CurUnitIndex, 0)
end
--endregion

--region Game - Action
--- 成功触发后判定点在该格中无效任何触发, 直到离开该格
function XFightLevelMusicArea:InTrigger()
    self._RLInTriggerIndex = self:GetCurUnitIndex()
end
--endregion

return XFightLevelMusicArea