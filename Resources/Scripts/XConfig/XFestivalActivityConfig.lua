XFestivalActivityConfig = XFestivalActivityConfig or {}

local CLIENT_FESTIVAL_STAGE = "Client/Fuben/Festival/FestivalStage.tab" --庆典关卡客户端表
local SHARE_FESTIVAL = "Share/Fuben/Festival/FestivalActivity.tab"

local ShareFestival = {}
local ClientFestivalStages = {}

--活动名称Id
XFestivalActivityConfig.ActivityId = {
    Christmas = 1,
    MainLine = 2,
    NewYear = 3,
    FoolsDay = 4,
}

function XFestivalActivityConfig.Init()
    ClientFestivalStages = XTableManager.ReadByIntKey(CLIENT_FESTIVAL_STAGE, XTable.XTableFestivalStage, "StageId")
    ShareFestival = XTableManager.ReadByIntKey(SHARE_FESTIVAL, XTable.XTableFestivalActivity, "Id")
end

function XFestivalActivityConfig.GetFestivalsTemplates()
    return ShareFestival
end

function XFestivalActivityConfig.GetFestivalById(id)
    if not id then return end
    local festivalDatas = ShareFestival[id]
    if not festivalDatas then
        XLog.ErrorTableDataNotFound("XFestivalActivityConfig.GetFestivalById", "FestivalActivity", SHARE_FESTIVAL, "Id", tostring(id))
        return
    end
    return festivalDatas
end

function XFestivalActivityConfig.GetFestivalTime(id)
    local config = XFestivalActivityConfig.GetFestivalById(id)
    return XFunctionManager.GetTimeByTimeId(config.TimeId)
end

function XFestivalActivityConfig.IsOffLine(id)
    local config = XFestivalActivityConfig.GetFestivalById(id)
    return not XTool.IsNumberValid(config.TimeId)
end

--====================
--获取庆典活动关卡配置
--@param stageId:关卡ID
--@return 庆典活动关卡配置
--====================
function XFestivalActivityConfig.GetFestivalStageCfgByStageId(stageId)
    if not ClientFestivalStages[stageId] then
        --[[
        XLog.ErrorTableDataNotFound(
            "XFestivalActivityConfig.GetFestivalStageCfgByStageId",
            "庆典活动关卡",
            CLIENT_FESTIVAL_STAGE,
            "StageId",
            tostring(stageId))
        ]]
        return nil
    end
    return ClientFestivalStages[stageId]
end