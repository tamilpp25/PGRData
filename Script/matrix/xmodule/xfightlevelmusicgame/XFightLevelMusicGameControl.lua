---@class XFightLevelMusicGameControl : XControl
---@field private _Model XFightLevelMusicGameModel
local XFightLevelMusicGameControl = XClass(XControl, "XFightLevelMusicGameControl")
function XFightLevelMusicGameControl:OnInit()
end

function XFightLevelMusicGameControl:AddAgencyEvent()
end

function XFightLevelMusicGameControl:RemoveAgencyEvent()
end

function XFightLevelMusicGameControl:OnRelease()
end

--region Game - Data
---@return XFightLevelMusicGame
function XFightLevelMusicGameControl:GetGame(mapId)
    ---@type XFightLevelMusicGame
    local game = require("XModule/XFightLevelMusicGame/Data/XFightLevelMusicGame").New(mapId)
    
    -- 限时
    game:SetLimitTime(self._Model:GetMapCfgLimitTime(mapId))
    
    -- 判定区
    local faultTolerance = self._Model:GetMapFaultTolerance(mapId)
    local areaMoveTypeList = self._Model:GetMapCfgAreaMoveTypeList(mapId)
    local areaInitPosList = self._Model:GetMapCfgAreaInitPosList(mapId)
    local areaInitMoveSpeedList = self._Model:GetMapCfgAreaInitMoveSpeedList(mapId)
    local XFightLevelMusicArea = require("XModule/XFightLevelMusicGame/Data/XFightLevelMusicArea")
    
    for index, type in ipairs(areaMoveTypeList) do
        local areaPoint = XFightLevelMusicArea.New(type, areaInitPosList[index], areaInitMoveSpeedList[index], faultTolerance)
        game:AddAreaPoint(index, areaPoint)
    end
    
    -- track
    local tempNoteId
    local trackList = self._Model:GetMapCfgTrackList(mapId)
    local XFightLevelMusicNote = require("XModule/XFightLevelMusicGame/Data/XFightLevelMusicNote")
    local XFightLevelMusicTrack = require("XModule/XFightLevelMusicGame/Data/XFightLevelMusicTrack")
    local XFightLevelMusicTrackUnit = require("XModule/XFightLevelMusicGame/Data/XFightLevelMusicTrackUnit")

    game:SetTutorialId(self._Model:GetMapCfgTutorialId(mapId))
    game:SetTrackIdList(trackList)
    for trackIndex, trackId in ipairs(trackList) do
        ---@type XFightLevelMusicTrack
        local track = XFightLevelMusicTrack.New(trackId, self._Model:GetTrackCfgLength(trackId))
        local noteList = self._Model:GetTrackCfgNoteList(trackId)
        
        for i = 1, #noteList do
            if track:GetUnit(i) then
                goto continue
            end
            tempNoteId = noteList[i]
            ---@type XFightLevelMusicTrackUnit
            local unit = XFightLevelMusicTrackUnit.New(i, trackId)
            
            track:AddTrackUnit(i, unit)
            if XTool.IsNumberValid(tempNoteId) then
                local noteLength = self._Model:GetNoteCfgLength(tempNoteId)
                local noteType = self._Model:GetNoteCfgType(tempNoteId)
                ---@type XFightLevelMusicNote
                local note = XFightLevelMusicNote.New(tempNoteId, noteType, noteLength, game:GetTrackNoteLength(trackIndex) + 1, i)
                
                unit:SetNote(note)
                game:AddTrackNote(trackIndex, note)
                -- 多格note
                while noteLength > 1 do
                    i = i + 1
                    ---@type XFightLevelMusicTrackUnit
                    local nextUnit = XFightLevelMusicTrackUnit.New(i, trackId)
                    
                    nextUnit:SetNote(note)
                    track:AddTrackUnit(i, nextUnit)
                    noteLength = noteLength - 1
                end
            end
            ::continue::
        end
        game:AddTrack(trackIndex, track)
    end
    
    return game
end
--endregion

return XFightLevelMusicGameControl