local TABLE_MOVIE_PATH_PREFIX = "Client/Movie/Movies/Movie%s.tab"
local TABLE_MOVIE_ACTOR_PATH = "Client/Movie/MovieActor.tab"
local TABLE_MOVIE_SPINE_ACTOR_PATH = "Client/Movie/MovieSpineActor.tab"
local TABLE_MOVIE_ROLE_FACE_PATH = "Client/Movie/MovieRoleFace.tab"
local TABLE_MOVIE_SKIP_PATH = "Client/Movie/MovieSkips"
local TABLE_MOVIE_STAFF_PATH = "Client/Movie/MovieStaffs"
local TABLE_MOVIE_SPEED_PATH = "Client/Movie/MovieSpeed.tab"
local TABLE_MOVIE_SKIP_SUMMARY_PATH = "Client/Movie/MovieSkipSummary.tab"

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
local MovieSkipSummaryTemplates = {}

local IsLoadMovieSkipSummary = false

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
--19-21 为背景8的专属演员
XMovieConfigs.MAX_ACTOR_NUM = 21

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

    IsLoadMovieSkipSummary = false
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
    return XModelManager.GetHXRes(config.RoleIcon)
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

--region lua端弃用，C#端有调用，暂无法排查C#端相关组件是否还在使用，保留接口并增加输出提示

function XMovieConfigs.GetMovieSkipSkipDesc(movieId)
    XLog.Error('该接口已弃用，已改为XMovieConfigs.TryGetMovieSkipSummaryCfg')
    return ""
end

function XMovieConfigs.IsMovieSkipHaveSkipDesc(movieId)
    XLog.Error('该接口已弃用，已改为XMovieConfigs.CheckIsMovieSkipHaveSummary')
    return false
end

--endregion

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

function XMovieConfigs.GetMovieSkipSummaryCfgById(storyId, noTips)
    if not IsLoadMovieSkipSummary then
        MovieSkipSummaryTemplates = XTableManager.ReadByStringKey(TABLE_MOVIE_SKIP_SUMMARY_PATH, XTable.XTableMovieSkipSummary, "StoryId")
        IsLoadMovieSkipSummary = true
    end
    
    local cfg = MovieSkipSummaryTemplates[storyId]

    if not cfg and not noTips then
        XLog.Error("XMovieConfigs GetMovieSkipSummaryCfgById error:配置不存在, storyId: " .. tostring(storyId) .. ", 配置路径: " .. TABLE_MOVIE_SKIP_SUMMARY_PATH)
    end
    
    return cfg
end

function XMovieConfigs.CheckIsMovieSkipHaveSummary(storyId)
    return not XTool.IsTableEmpty(XMovieConfigs.GetMovieSkipSummaryCfgById(storyId, true)) and true or false
end

function XMovieConfigs.TryGetMovieSkipSummaryCfg(storyId)
    if not XMovieConfigs.CheckIsMovieSkipHaveSummary(storyId) then return nil end

    return XMovieConfigs.GetMovieSkipSummaryCfgById(storyId)
end