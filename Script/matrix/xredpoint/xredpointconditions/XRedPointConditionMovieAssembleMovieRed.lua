local XRedPointConditionMovieAssembleMovieRed = {}
local Events = nil
function XRedPointConditionMovieAssembleMovieRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_MOVIE_ASSEMBLE_WATCH_MOVIE),
    }
    return Events
end

function XRedPointConditionMovieAssembleMovieRed.Check(movieId)
    return XDataCenter.MovieAssembleManager.CheckMovieTmpRedPoint(movieId)
end

return XRedPointConditionMovieAssembleMovieRed