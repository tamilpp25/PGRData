local tableInsert = table.insert

XMovieAssembleConfig = XMovieAssembleConfig or {}

local MOVIE_ASSEMBLE_PATH = "Client/MovieAssemble/MovieAssemble.tab"
local MOVIE_ASSEMBLE_TEMPLATE_PATH = "Client/MovieAssemble/MovieAssembleTemplate.tab"

XMovieAssembleConfig.MovieAssembleWatchedKey = "MOVIE_ASSEMBLE_WATCHED_KEY"
XMovieAssembleConfig.MovieWatchedState = {
    NotWatch = 0,
    Watched = 1,
}

local MovieAssembles = {}
local MovieAssembleTemplates = {}

function XMovieAssembleConfig.Init()
    MovieAssembles = XTableManager.ReadByIntKey(MOVIE_ASSEMBLE_PATH, XTable.XTableMovieAssemble, "Id")
    MovieAssembleTemplates = XTableManager.ReadByIntKey(MOVIE_ASSEMBLE_TEMPLATE_PATH, XTable.XTableMovieAssembleTemplate, "Id")
end

function XMovieAssembleConfig.GetMovieAssembleById(id)
    if not MovieAssembles or not next(MovieAssembles) or not MovieAssembles[id] then
        XLog.Error("Can't Find Movie Assemble Config By Id:"..id.." Please Check "..MOVIE_ASSEMBLE_PATH)
        return nil
    end

    return MovieAssembles[id]
end

function XMovieAssembleConfig.GetMovieAssembleTmpById(id)
    if not MovieAssembleTemplates or not next(MovieAssembleTemplates) or not MovieAssembleTemplates[id] then
        XLog.Error("Can't Find Movie Assemble Template Config By Id:"..id.." Please Check "..MOVIE_ASSEMBLE_TEMPLATE_PATH)
        return nil
    end

    return MovieAssembleTemplates[id]
end

-- MovieAssembleConfig
function XMovieAssembleConfig.GetBgImgUrlById(id)
    local movieAssebleTmp = XMovieAssembleConfig.GetMovieAssembleById(id)
    if not movieAssebleTmp then
        return nil
    end

    return movieAssebleTmp.BgImgUrl
end

function XMovieAssembleConfig.GetUiPrefabById(id)
    local movieAssebleTmp = XMovieAssembleConfig.GetMovieAssembleById(id)
    if not movieAssebleTmp then
        return nil
    end

    return movieAssebleTmp.UiPrefab
end

function XMovieAssembleConfig.GetMovieTmpPrefabById(id)
    local movieAssebleTmp = XMovieAssembleConfig.GetMovieAssembleById(id)
    if not movieAssebleTmp then
        return nil
    end

    return movieAssebleTmp.MovieTmpPrefab
end

function XMovieAssembleConfig.GetMovieTmpIdsById(id)
    local movieAssebleTmp = XMovieAssembleConfig.GetMovieAssembleById(id)
    if not movieAssebleTmp then
        return nil
    end

    return movieAssebleTmp.MovieTmpIds
end

-- MovieTemplateConfig
function XMovieAssembleConfig.GetMovieIdById(id)
    local movieTmp = XMovieAssembleConfig.GetMovieAssembleTmpById(id)
    if not movieTmp then
        return nil
    end

    return movieTmp.MovieId
end

function XMovieAssembleConfig.GetMovieConditionIdById(id)
    local movieTmp = XMovieAssembleConfig.GetMovieAssembleTmpById(id)
    if not movieTmp then
        return nil
    end
    
    return movieTmp.ConditionId
end

function XMovieAssembleConfig.GetMovieLockedBgUrlById(id)
    local movieTmp = XMovieAssembleConfig.GetMovieAssembleTmpById(id)
    if not movieTmp then
        return nil
    end
    
    return movieTmp.LockedBgUrl
end

function XMovieAssembleConfig.GetMovieUnlockBgUrlById(id)
    local movieTmp = XMovieAssembleConfig.GetMovieAssembleTmpById(id)
    if not movieTmp then
        return nil
    end

    return movieTmp.UnlockBgUrl
end