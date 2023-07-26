local XUiFestivalActivityNewRoomSingle = {}

function XUiFestivalActivityNewRoomSingle.GetAutoCloseInfo(stageCfg)
    local chapterId = XDataCenter.FubenFestivalActivityManager.GetChapterIdByStageId(stageCfg.StageId)
    local chapter = XDataCenter.FubenFestivalActivityManager.GetFestivalChapterById(chapterId)
    if not chapter then return false end
    local endTime = chapter:GetEndTime()
    if type(endTime) == "number" and endTime > 0 then
        return true, endTime, function(isClose)
            if isClose then
                XLuaUiManager.RunMain()
                XUiManager.TipError(CS.XTextManager.GetText("FestivalActivityNotInActivityTime"))
            end
        end
    end
    return false
end

function XUiFestivalActivityNewRoomSingle.UpdateTeam(rootUi)
    XDataCenter.TeamManager.SetPlayerTeam(rootUi.CurTeam, false)
end

return XUiFestivalActivityNewRoomSingle