XVideoConfig = XVideoConfig or {}

local TABLE_MOIVE_CONFIG = "Client/Video/VideoConfig.tab"
local VideoTemplate = {}
function XVideoConfig.Init()
    VideoTemplate = XTableManager.ReadByIntKey(TABLE_MOIVE_CONFIG, XTable.XTableVideoConfig, "Id")
end


function XVideoConfig.GetMovieById(id)
    if not VideoTemplate or not VideoTemplate[id] then
        XLog.ErrorTableDataNotFound("XVideoConfig.GetMovieById", "VideoConfig", TABLE_MOIVE_CONFIG, "Id", tostring(id))
        return
    end
    return VideoTemplate[id]
end

function XVideoConfig.GetMovieUrlById(id)
    if not VideoTemplate or not VideoTemplate[id] then
        XLog.ErrorTableDataNotFound("XVideoConfig.GetMovieUrlById", "VideoConfig", TABLE_MOIVE_CONFIG, "Id", tostring(id))
        return
    end
    if XDataCenter.UiPcManager.IsPc() and VideoTemplate[id].VideoUrlPc then
        return VideoTemplate[id].VideoUrlPc
     end
    return VideoTemplate[id].VideoUrl
end


function XVideoConfig.GetMovieAspectRatio(id)
    if not VideoTemplate or not VideoTemplate[id] then
        XLog.ErrorTableDataNotFound("XVideoConfig.GetMovieUrlById", "VideoConfig", TABLE_MOIVE_CONFIG, "Id", tostring(id))
        return
    end
    local temp = VideoTemplate[id]
    if not temp or temp.Height == 0 or temp.Width == 0 then
        return 0
    end

    return temp.Width / temp.Height
end