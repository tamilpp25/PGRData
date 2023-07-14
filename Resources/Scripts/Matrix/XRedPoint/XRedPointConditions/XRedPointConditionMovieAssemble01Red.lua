local XRedPointConditionMovieAssemble01Red = {}
local Events = nil
function XRedPointConditionMovieAssemble01Red.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_MOVIE_ASSEMBLE_WATCH_MOVIE),
    }
    return Events
end

function XRedPointConditionMovieAssemble01Red.Check()
    return XDataCenter.MovieAssembleManager.CheckMovieAssembleRedPoint(1)
end

return XRedPointConditionMovieAssemble01Red