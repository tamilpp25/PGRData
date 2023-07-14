local XRedPointConditionMovieAssembleRed = {}
local Events = nil
function XRedPointConditionMovieAssembleRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_MOVIE_ASSEMBLE_WATCH_MOVIE),
    }
    return Events
end

function XRedPointConditionMovieAssembleRed.Check(assembleId)
    return XDataCenter.MovieAssembleManager.CheckMovieAssembleRedPoint(assembleId)
end

return XRedPointConditionMovieAssembleRed