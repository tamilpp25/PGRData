local TABLE_MOVIE_PATH_PREFIX = "Client/Movie/Movies/Movie%s.tab"
local TABLE_MOVIE_ACTOR_PATH = "Client/Movie/MovieActor.tab"
local TABLE_MOVIE_SPINE_ACTOR_PATH = "Client/Movie/MovieSpineActor.tab"
local TABLE_MOVIE_ROLE_FACE_PATH = "Client/Movie/MovieRoleFace.tab"
local TABLE_MOVIE_SKIP_PATH = "Client/Movie/MovieSkips"
local TABLE_MOVIE_STAFF_PATH = "Client/Movie/MovieStaffs"
local TABLE_MOVIE_SPEED_PATH = "Client/Movie/MovieSpeed.tab"

local stringFormat = string.format
local checkTableExist = CS.XTableManager.CheckTableExist
local vector = CS.UnityEngine.Vector2
local tableInsert = table.insert
local pairs = pairs
local stringGsub = string.gsub

local MovieTemplates = {}
local MovieActorTemplates = {}
local MovieSpineActorTemplates = {}
local MovieRoleFaceTemplates = {}
local MovieSkipTemplates = {}
local MovieStaffTemplates = {}
local MovieSpeedTemplates = {}

XMovieConfigs = XMovieConfigs or {}

XMovieConfigs.PLAYER_NAME_REPLACEMENT = "【kuroname】"
XMovieConfigs.TYPE_WRITER_SPEED = CS.XGame.ClientConfig:GetFloat("MovieWriterSpeed") or 0.04
XMovieConfigs.AutoPlayDelay = CS.XGame.ClientConfig:GetInt("AutoPlayDelay")  --自动播放对话默认停留时间
XMovieConfigs.PerWordDelay = CS.XGame.ClientConfig:GetInt("MoviePerWordDelay") --每个字的延迟时间
--为方便后续扩展 和策划约定 
--1-5为默认原有actor，层级在特效层之下
--6-10为中间插入横幅actor
--11-12 为左边分屏actor
--13-14为右边分屏actor
--15-17actor，层级在特效层之上，底部对话框之下
--18，对话旁边的头像
XMovieConfigs.MAX_ACTOR_NUM = 18

XMovieConfigs.MAX_SPINE_ACTOR_NUM = 14

-- 通用的spine动画
XMovieConfigs.SpineActorAnim = 
{
    PanelActorEnable = "PanelActorEnable",
    PanelActorDisable = "PanelActorDisable",
    PanelActorBlowUp = "PanelActorBlowUp",
    PanelActorDarkNor = "PanelActorDarkNor",
    PanelActorDarkDisable = "PanelActorDarkDisable",
}

local InitStaffConfigs = function()
    local paths = CS.XTableManager.GetPaths(TABLE_MOVIE_STAFF_PATH)
    XTool.LoopCollection(paths, function(path)
        local key = XTool.GetFileNameWithoutExtension(path)
        MovieStaffTemplates[key] = XTableManager.ReadByIntKey(path, XTable.XTableMovieStaff, "Id")
    end)
end

function XMovieConfigs.Init()
    MovieActorTemplates = XTableManager.ReadByIntKey(TABLE_MOVIE_ACTOR_PATH, XTable.XTableMovieActor, "RoleId")
    MovieSpineActorTemplates = XTableManager.ReadByIntKey(TABLE_MOVIE_SPINE_ACTOR_PATH, XTable.XTableMovieSpineActor, "RoleId")
    MovieRoleFaceTemplates = XTableManager.ReadByIntKey(TABLE_MOVIE_ROLE_FACE_PATH, XTable.XTableMovieRoleFace, "RoleId")
    MovieSkipTemplates = {}--= XTableManager.ReadByStringKey(TABLE_MOVIE_SKIP_PATH, XTable.XTableMovieSkip, "Id")
    MovieSpeedTemplates = XTableManager.ReadByIntKey(TABLE_MOVIE_SPEED_PATH, XTable.XTableMovieSpeed, "Id")
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

function XMovieConfigs.GetSpineActorSpinePath(actorId)
    local config = MovieSpineActorTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetSpineActorSpinePath", "MovieSpineActor", TABLE_MOVIE_SPINE_ACTOR_PATH, "actorId", tostring(actorId))
        return
    end

    return config.SpinePath
end

function XMovieConfigs.GetSpineActorRoleAnim(actorId, index)
    local config = MovieSpineActorTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetSpineActorRoleAnim", "MovieSpineActor", TABLE_MOVIE_SPINE_ACTOR_PATH, "actorId", tostring(actorId) .." index:", tostring(index))
        return
    end

    return config.RoleAnims[index]
end

function XMovieConfigs.GetSpineActorRoleAnim2(actorId, index)
    local config = MovieSpineActorTemplates[actorId]
    return config.RoleAnims2[index]
end

function XMovieConfigs.GetSpineActorKouIdleAnim(actorId, index)
    local config = MovieSpineActorTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetSpineActorKouIdleAnim", "MovieSpineActor", TABLE_MOVIE_SPINE_ACTOR_PATH, "actorId", tostring(actorId) .." index:", tostring(index))
        return
    end

    return config.KouIdleAnims[index]
end

function XMovieConfigs.GetSpineActorKouTalkAnim(actorId, index)
    local config = MovieSpineActorTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetSpineActorKouTalkAnim", "MovieSpineActor", TABLE_MOVIE_SPINE_ACTOR_PATH, "actorId", tostring(actorId) .." index:", tostring(index))
        return
    end

    return config.KouTalkAnims[index]
end

function XMovieConfigs.GetSpineActorTransitionAnim(actorId, index)
    local config = MovieSpineActorTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetSpineActorTransitionAnim", "MovieSpineActor", TABLE_MOVIE_SPINE_ACTOR_PATH, "actorId", tostring(actorId) .." index:", tostring(index))
        return
    end

    return config.TransitionAnims[index]
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

function XMovieConfigs.GetMovieSpeedConfig(id)
    if id then
        local config = MovieSpeedTemplates[id]
        if not config then
            XLog.Error("XMovieConfigs GetMovieSpeedConfig error:配置不存在, Id: " .. id .. ", 配置路径: " .. TABLE_MOVIE_SPEED_PATH)
            return
        end
        return config
    else
        return MovieSpeedTemplates
    end
end
