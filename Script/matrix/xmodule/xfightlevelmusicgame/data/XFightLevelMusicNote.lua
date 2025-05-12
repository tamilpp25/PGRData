---@class XFightLevelMusicNote
local XFightLevelMusicNote = XClass(nil, "XFightLevelMusicNote")
XFightLevelMusicNote.Uid = 1

function XFightLevelMusicNote:Ctor(noteId, type, length, noteIndex, trackUnitIndex)
    self._Uid = XFightLevelMusicNote.Uid
    self._NoteId = noteId
    self._NoteIndex = noteIndex
    self._TrackUnitIndex = trackUnitIndex
    self._Type = type
    self._Length = length
    self._State = XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_STATE.NONE
    XFightLevelMusicNote.Uid = XFightLevelMusicNote.Uid + 1
end

--region Setter

--endregion

--region Getter
function XFightLevelMusicNote:GetNoteIndex()
    return self._NoteIndex
end

function XFightLevelMusicNote:GetType()
    return self._Type
end

function XFightLevelMusicNote:GetLength()
    return self._Length
end

function XFightLevelMusicNote:GetTrackUnitIndex()
    return self._TrackUnitIndex
end

function XFightLevelMusicNote:ToString()
    local string = "Note: {"
            .." Uid = "..self._Uid
            .." NoteId = "..self._NoteId
            .." NoteIndex = "..self._NoteIndex
            .." TrackUnitIndex = "..self._TrackUnitIndex
            .." Type = "..self._Type
            .." Length = "..self._Length
            .." State = "..tostring(self._State)
            .." }"
    return string
end
--endregion

--region Checker
function XFightLevelMusicNote:IsType(type)
    return self._Type == type
end

function XFightLevelMusicNote:IsClear()
    return self._State == XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_STATE.CLEAR
end
--endregion

--region Game - Action
function XFightLevelMusicNote:Trigger()
    self._State = XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_STATE.CLEAR
end
--endregion

return XFightLevelMusicNote