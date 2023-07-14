XMovieAssembleManagerCreator = function ()
    local XMovieAssembleManager = {}

    function XMovieAssembleManager.CheckMovieIsWatched(movieId)
        local movieWatchState = XSaveTool.GetData(string.format("%s%s%s", XMovieAssembleConfig.MovieAssembleWatchedKey, XPlayer.Id, movieId))
        if not movieWatchState or movieWatchState == XMovieAssembleConfig.MovieWatchedState.NotWatch then
            return false
        elseif movieWatchState == XMovieAssembleConfig.MovieWatchedState.Watched then
            return true
        end
        return false
    end

    function XMovieAssembleManager.CheckMovieTmpRedPoint(movieId)
        if not movieId then
            return false
        end
        local conditionId = XMovieAssembleConfig.GetMovieConditionIdById(movieId)
        if not conditionId or conditionId == 0 then
            return not XMovieAssembleManager.CheckMovieIsWatched(movieId)
        end

        return XConditionManager.CheckCondition(conditionId) and not XMovieAssembleManager.CheckMovieIsWatched(movieId)
    end

    function XMovieAssembleManager.CheckMovieAssembleRedPoint(assembleId)
        local movieIds = XMovieAssembleConfig.GetMovieTmpIdsById(assembleId)
        for _, movieId in ipairs(movieIds) do
            if XMovieAssembleManager.CheckMovieTmpRedPoint(movieId) then
                return true
            end
        end

        return false
    end

    return XMovieAssembleManager
end