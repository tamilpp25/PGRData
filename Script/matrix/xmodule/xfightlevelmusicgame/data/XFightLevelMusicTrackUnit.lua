---@class XFightLevelMusicTrackUnit
local XFightLevelMusicTrackUnit = XClass(nil, "XFightLevelMusicTrackUnit")
XFightLevelMusicTrackUnit.Uid = 1

function XFightLevelMusicTrackUnit:Ctor(index, trackId)
    self._Uid = XFightLevelMusicTrackUnit.Uid
    self._Index = index
    self._TrackId = trackId
    
    ---@type XFightLevelMusicNote
    self._Note = false
    self._State = XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_STATE.NONE

    XFightLevelMusicTrackUnit.Uid = XFightLevelMusicTrackUnit.Uid + 1
end

--region Setter
---@param note XFightLevelMusicNote
function XFightLevelMusicTrackUnit:SetNote(note)
    self._Note = note
    self._State = XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_STATE.UNCLEAR
end
--endregion

--region Getter
function XFightLevelMusicTrackUnit:GetIndex()
    return self._Index
end

function XFightLevelMusicTrackUnit:GetNoteIndex()
    if not self:IsHaveNote() then
        return 0
    end
    return self._Note:GetNoteIndex()
end

function XFightLevelMusicTrackUnit:GetNoteState()
    if not self:IsHaveNote() then
        return XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_STATE.NONE
    end
    return self._Note:GetTrackUnitIndex()
end

function XFightLevelMusicTrackUnit:ToString()
    local string = "TrackUnit: { "
            .." Uid = "..self._Uid
            .." TrackId = "..self._TrackId
            .." Index = "..self._Index
            .." State = "..self._State
            ..(self._Note and " \n\t"..self._Note:ToString().." \n\t}" or " Note: none }")
    return string
end
--endregion

--region Checker
---@return boolean
function XFightLevelMusicTrackUnit:IsClear()
    if not self:IsHaveNote() then
        return true
    end
    return self._Note:IsClear()
end

function XFightLevelMusicTrackUnit:IsHaveNote()
    return self._Note ~= false
end

function XFightLevelMusicTrackUnit:IsNoteType(type)
    if not self:IsHaveNote() then
        return false
    end
    return self._Note:IsType(type)
end
--endregion

--region Game - Action
function XFightLevelMusicTrackUnit:Trigger()
    if not self:IsHaveNote() then
        return
    end
    self._Note:Trigger()
end
--endregion

return XFightLevelMusicTrackUnit