---@class XFightLevelMusicTrack
local XFightLevelMusicTrack = XClass(nil, "XFightLevelMusicTrack")
XFightLevelMusicTrack.Uid = 1

function XFightLevelMusicTrack:Ctor(trackId, length)
    self._Uid = XFightLevelMusicTrack.Uid
    self._TrackId = trackId
    self._Length = length
    
    ---@type XFightLevelMusicTrackUnit[]
    self._TrackUnitList = {}

    XFightLevelMusicTrack.Uid = XFightLevelMusicTrack.Uid + 1
end

--region Getter
---@return XFightLevelMusicTrackUnit
function XFightLevelMusicTrack:GetUnit(unitIndex)
    return self._TrackUnitList[unitIndex]
end

function XFightLevelMusicTrack:GetUnitList()
    return self._TrackUnitList
end

function XFightLevelMusicTrack:GetLength()
    return self._Length
end

function XFightLevelMusicTrack:ToString()
    local string = "Track:{"
            .." Uid = "..self._Uid
            .." TrackId = "..self._TrackId
            .." TrackUnitList = {"
    for i, v in ipairs(self._TrackUnitList) do
        string = string.."\n        ["..i.."]: "..v:ToString()
    end
    string = string.."\n    }\n"
    string = string.."}\n"
    return string
end
--endregion

--region Checker
function XFightLevelMusicTrack:IsClear()
    for _, unit in ipairs(self._TrackUnitList) do
        if unit:IsHaveNote() and not unit:IsClear() then
            return false
        end
    end
    return true
end
--endregion

--region Game - Data
---@param unitIndex number
---@param unit XFightLevelMusicTrackUnit
function XFightLevelMusicTrack:AddTrackUnit(unitIndex, unit)
    if not self._TrackUnitList then
        self._TrackUnitList = {}
    end
    self._TrackUnitList[unitIndex] = unit
end
--endregion

--region Game - Action
---@return number, number triggerResult, noteIndex
function XFightLevelMusicTrack:Trigger(beCheckUnitIndexList, noteType)
    for _, unitIndex in ipairs(beCheckUnitIndexList) do
        local unit = self:GetUnit(unitIndex)
        if unit:IsHaveNote() and not unit:IsClear() then
            if unit:IsNoteType(noteType) then
                unit:Trigger()
                return XEnumConst.FIGHT_LEVEL_MUSIC.TRIGGER_RESULT.CLEAR, unit:GetNoteIndex()
            else
                return XEnumConst.FIGHT_LEVEL_MUSIC.TRIGGER_RESULT.MISS, unit:GetNoteIndex()
            end
        end
    end

    return XEnumConst.FIGHT_LEVEL_MUSIC.TRIGGER_RESULT.MISS, beCheckUnitIndexList[1]
end
--endregion

return XFightLevelMusicTrack