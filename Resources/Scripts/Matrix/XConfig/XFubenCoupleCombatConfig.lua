XFubenCoupleCombatConfig = XFubenCoupleCombatConfig or {}

local TABLE_COUPLE_ACTIVITY = "Share/Fuben/CoupleCombat/CoupleCombatActivity.tab"
local TABLE_COUPLE_BUFF = "Share/Fuben/CoupleCombat/CoupleCombatFeature.tab"
local TABLE_COUPLE_CHAPTER = "Share/Fuben/CoupleCombat/CoupleCombatChapter.tab"
local TABLE_COUPLE_ROBOT = "Share/Fuben/CoupleCombat/CoupleCombatRobot.tab"
local TABLE_COUPLE_STAGE = "Share/Fuben/CoupleCombat/CoupleCombatStage.tab"

local CoupleCombatActivity = {}
local CoupleCombatFeature = {}
local CoupleCombatChapter = {}
local CoupleCombatRobot = {}
local CoupleCombatStage = {}

XFubenCoupleCombatConfig.StageType = {
    Normal = 1, --普通
    Hard = 2, --挑战模式
}

function XFubenCoupleCombatConfig.Init()
    CoupleCombatActivity = XTableManager.ReadByIntKey(TABLE_COUPLE_ACTIVITY, XTable.XTableCoupleCombatActivity, "Id")
    CoupleCombatFeature = XTableManager.ReadByIntKey(TABLE_COUPLE_BUFF, XTable.XTableCoupleCombatFeature, "Id")
    CoupleCombatChapter = XTableManager.ReadByIntKey(TABLE_COUPLE_CHAPTER, XTable.XTableCoupleCombatChapter, "Id")
    CoupleCombatRobot = XTableManager.ReadByIntKey(TABLE_COUPLE_ROBOT, XTable.XTableCoupleCombatRobot, "RobotId")
    CoupleCombatStage = XTableManager.ReadByIntKey(TABLE_COUPLE_STAGE, XTable.XTableCoupleCombatStage, "Id")

end

function XFubenCoupleCombatConfig.GetStageInfo(id)
    local template = CoupleCombatStage[id]
    if not template then
        XLog.ErrorTableDataNotFound("XFubenCoupleCombatConfig.GetStageInfo", "CoupleCombatStage", TABLE_COUPLE_STAGE, "id", tostring(id))
        return
    end
    return template
end

function XFubenCoupleCombatConfig.GetStages()
    return CoupleCombatStage
end

function XFubenCoupleCombatConfig.GetChapterTemplates()
    return CoupleCombatChapter
end

function XFubenCoupleCombatConfig.GetChapterTemplate(id)
    return CoupleCombatChapter[id]
end

function XFubenCoupleCombatConfig.GetActTemplates()
    return CoupleCombatActivity
end

function XFubenCoupleCombatConfig.GetActivityTemplateById(id)
    return CoupleCombatActivity[id]
end

function XFubenCoupleCombatConfig.GetRobotInfo(id)
    return CoupleCombatRobot[id]
end

function XFubenCoupleCombatConfig.GetFeatureById(id)
    return CoupleCombatFeature[id]
end
