local TABLE_MOVIE_PATH_PREFIX = "Client/Movie/Movies/Movie%s.tab"
local TABLE_MOVIE_ACTOR_PATH = "Client/Movie/MovieActor.tab"
local TABLE_MOVIE_ROLE_FACE_PATH = "Client/Movie/MovieRoleFace.tab"
local TABLE_MOVIE_SKIP_PATH = "Client/Movie/MovieSkips"
local TABLE_MOVIE_STAFF_PATH = "Client/Movie/MovieStaffs"

local stringFormat = string.format
local checkTableExist = CS.XTableManager.CheckTableExist
local vector = CS.UnityEngine.Vector2
local tableInsert = table.insert
local pairs = pairs
local stringGsub = string.gsub

local MovieTemplates = {}
local MovieActorTemplates = {}
local MovieRoleFaceTemplates = {}
local MovieSkipTemplates = {}
local MovieStaffTemplates = {}

XMovieConfigs = XMovieConfigs or {}

XMovieConfigs.PLAYER_NAME_REPLACEMENT = "【kuroname】"
XMovieConfigs.TYPE_WRITER_SPEED = 0.04    --打字机打一字速度
XMovieConfigs.AutoPlayDelay = 1000  --自动播放对话默认停留时间
--为方便后续扩展 和策划约定 
--1-5为默认原有actor 
--6-10为中间插入横幅actor 
--11-12 为左边分屏actor 
--13-14为右边分屏actor
XMovieConfigs.MAX_ACTOR_NUM = 14
XMovieConfigs.MAX_ACTOR_ROLE_NUM = 14

local InitStaffConfigs = function()
    local paths = CS.XTableManager.GetPaths(TABLE_MOVIE_STAFF_PATH)
    XTool.LoopCollection(paths, function(path)
        local key = XTool.GetFileNameWithoutExtension(path)
        MovieStaffTemplates[key] = XTableManager.ReadByIntKey(path, XTable.XTableMovieStaff, "Id")
    end)
end

function XMovieConfigs.Init()
    MovieActorTemplates = XTableManager.ReadByIntKey(TABLE_MOVIE_ACTOR_PATH, XTable.XTableMovieActor, "RoleId")
    MovieRoleFaceTemplates = XTableManager.ReadByIntKey(TABLE_MOVIE_ROLE_FACE_PATH, XTable.XTableMovieRoleFace, "RoleId")
    MovieSkipTemplates = {}--= XTableManager.ReadByStringKey(TABLE_MOVIE_SKIP_PATH, XTable.XTableMovieSkip, "Id")

    InitStaffConfigs()
end

local function InitMovieTemplate(movieId)
    local path = stringFormat(TABLE_MOVIE_PATH_PREFIX, movieId)
    MovieTemplates[movieId] = XTableManager.ReadByIntKey(path, XTable.XTableMovieNew, "Id")
end

function XMovieConfigs.CheckMovieConfigExist(movieId)
    local path = stringFormat(TABLE_MOVIE_PATH_PREFIX, movieId)
    return checkTableExist(path)
end

function XMovieConfigs.GetMovieCfg(movieId)
    if not MovieTemplates[movieId] then
        InitMovieTemplate(movieId)
    end

    local config = MovieTemplates[movieId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetMovieCfg", "MovieConfig", stringFormat(TABLE_MOVIE_PATH_PREFIX, movieId), "Id", tostring(movieId))
        return
    end
    return config
end

function XMovieConfigs.DeleteMovieCfgs()
    MovieTemplates = {}
end

function XMovieConfigs.GetActorImgPath(actorId)
    local config = MovieActorTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetActorImgPath", "MovieActor", TABLE_MOVIE_ACTOR_PATH, "actorId", tostring(actorId))
        return
    end
    return config.RoleIcon
end

function XMovieConfigs.GetActorFacePosVector2(actorId)
    local config = MovieActorTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetActorFacePosVector2", "MovieActor", TABLE_MOVIE_ACTOR_PATH, "actorId", tostring(actorId))
        return
    end
    return vector(config.FacePosX, config.FacePosY)
end

function XMovieConfigs.GetActorFaceImgPath(actorId, faceId)
    local config = MovieRoleFaceTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetActorFaceImgPath", "MovieRoleFace", TABLE_MOVIE_ROLE_FACE_PATH, "actorId", tostring(actorId))
        return
    end

    local face = config.FaceLook[faceId]
    if not face then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetActorFaceImgPath", "FaceLook", TABLE_MOVIE_ROLE_FACE_PATH, "actorId", tostring(actorId) .. " faceId :" .. tostring(faceId))
        return
    end

    return face
end

local function GetMovieSkipConfig(movieId)
    local config = MovieSkipTemplates[movieId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetMovieSkipHaveSkipDesc", "MovieSkip", TABLE_MOVIE_SKIP_PATH, "movieId", tostring(movieId))
        return
    end
    return config
end

function XMovieConfigs.GetMovieSkipSkipDesc(movieId)
    if not XMovieConfigs.IsMovieSkipHaveSkipDesc(movieId) then return "" end

    local config = GetMovieSkipConfig(movieId)
    local skipDesc = config.SkipDesc
    if not skipDesc then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetMovieSkipHaveSkipDesc", "SkipDesc", TABLE_MOVIE_SKIP_PATH, "movieId", tostring(movieId))
        return ""
    end
    return string.gsub(skipDesc, "\\n", "\n")
end

--C#这边也有调用
function XMovieConfigs.IsMovieSkipHaveSkipDesc(movieId)
    return MovieSkipTemplates[movieId] and true or false
end

--职员表 begin--
local GetStaffConfigs = function(staffPath)
    local config = MovieStaffTemplates[staffPath]
    if not config then
        XLog.Error("XMovieConfigs GetStaffConfig error:配置不存在, Id: " .. staffPath .. ", 配置路径: " .. TABLE_MOVIE_STAFF_PATH)
        return
    end
    return config
end

local GetStaffConfig = function(staffPath, staffId)
    local configs = GetStaffConfigs(staffPath)
    local config = configs[staffId]
    if not config then
        XLog.Error("XMovieConfigs GetStaffConfig error:配置不存在, Id: " .. staffId .. ", 配置路径: " .. TABLE_MOVIE_STAFF_PATH)
        return
    end
    return config
end

function XMovieConfigs.GetStaffIdList(staffPath)
    local staffIds = {}

    local config = GetStaffConfigs(staffPath)
    for staffId in pairs(config) do
        tableInsert(staffIds, staffId)
    end

    return staffIds
end

function XMovieConfigs.GetStaffName(staffPath, staffId)
    local config = GetStaffConfig(staffPath, staffId)
    return stringGsub(config.Name, "\\n", "\n")
end
--职员表 end--
