XFubenSimulatedCombatConfig = XFubenSimulatedCombatConfig or {}

local TABLE_SIMUCOMBAT_ACTIVITY = "Share/Fuben/SimulatedCombat/SimulatedCombatActivity.tab"
local TABLE_SIMUCOMBAT_ADDITION = "Share/Fuben/SimulatedCombat/SimulatedCombatAddition.tab"
local TABLE_SIMUCOMBAT_CHALLENGE = "Share/Fuben/SimulatedCombat/SimulatedCombatChallenge.tab"
local TABLE_SIMUCOMBAT_MEMBER = "Share/Fuben/SimulatedCombat/SimulatedCombatMember.tab"
local TABLE_SIMUCOMBAT_POINT_REWARD = "Share/Fuben/SimulatedCombat/SimulatedCombatPointReward.tab"
local TABLE_SIMUCOMBAT_STAGE = "Share/Fuben/SimulatedCombat/SimulatedCombatStage.tab"
local TABLE_SIMUCOMBAT_STAR_REWARD = "Share/Fuben/SimulatedCombat/SimulatedCombatStarReward.tab"

local SimuCombatActivity = {}
local SimuCombatAddition = {}
local SimuCombatChallenge = {}
local SimuCombatMember = {}
local SimuCombatPointReward = {}
local SimuCombatStage = {}
local SimuCombatStarReward = {}
local SimuCombatStageIdToInterId = {}
local SimuCombatStageGroup = {}

XFubenSimulatedCombatConfig.Color = {
    NORMAL = XUiHelper.Hexcolor2Color("0F70BC"),
    INSUFFICIENT = XUiHelper.Hexcolor2Color("C62310"),
}

XFubenSimulatedCombatConfig.StageType = {
    Normal = 1, --普通
    Challenge = 2, --挑战模式
}

XFubenSimulatedCombatConfig.ResType = {
    Member = 1,
    Addition = 2,
}

XFubenSimulatedCombatConfig.TeamTemplate = {
    ["CaptainPos"] = 1,
    ["FirstFightPos"] = 1,
    ["TeamData"] = {},
}

function XFubenSimulatedCombatConfig.Init()
    SimuCombatActivity = XTableManager.ReadByIntKey(TABLE_SIMUCOMBAT_ACTIVITY, XTable.XTableSimulatedCombatActivity, "Id")
    SimuCombatAddition = XTableManager.ReadByIntKey(TABLE_SIMUCOMBAT_ADDITION, XTable.XTableSimulatedCombatAddition, "Id")
    SimuCombatChallenge = XTableManager.ReadByIntKey(TABLE_SIMUCOMBAT_CHALLENGE, XTable.XTableSimulatedCombatChallenge, "Id")
    SimuCombatMember = XTableManager.ReadByIntKey(TABLE_SIMUCOMBAT_MEMBER, XTable.XTableSimulatedCombatMember, "Id")
    SimuCombatPointReward = XTableManager.ReadByIntKey(TABLE_SIMUCOMBAT_POINT_REWARD, XTable.XTableSimulatedCombatPointReward, "Id")
    SimuCombatStage = XTableManager.ReadByIntKey(TABLE_SIMUCOMBAT_STAGE, XTable.XTableSimulatedCombatStage, "Id")
    SimuCombatStarReward = XTableManager.ReadByIntKey(TABLE_SIMUCOMBAT_STAR_REWARD, XTable.XTableSimulatedCombatStarReward, "Id")
    for _, v in pairs(SimuCombatStage) do
        SimuCombatStageIdToInterId[v.StageId] = v
        if not SimuCombatStageGroup[v.Type] then
            SimuCombatStageGroup[v.Type] = {}
        end
        table.insert(SimuCombatStageGroup[v.Type], v)
    end
    
    for _, grp in pairs(SimuCombatStageGroup) do
        table.sort(grp, function (a,b) 
            return a.Id < b.Id
        end)
    end
    XFubenSimulatedCombatConfig.TeamTemplate = XReadOnlyTable.Create(XFubenSimulatedCombatConfig.TeamTemplate)
end

function XFubenSimulatedCombatConfig.GetStageInterData(Id)
    local template = SimuCombatStage[Id]
    if not template then
        XLog.ErrorTableDataNotFound("XFubenSimulatedCombatConfig.GetDataById", "SimulatedCombatActivity", SHARE_NEWCHAR_TEACH, "Id", tostring(id))
        return
    end
    return template
end

function XFubenSimulatedCombatConfig.GetStageInterDataByType(type)
    return SimuCombatStageGroup[type]
end

function XFubenSimulatedCombatConfig.GetActTemplates()
    return SimuCombatActivity
end

function XFubenSimulatedCombatConfig.GetActivityTemplateById(Id)
    return SimuCombatActivity[Id]
end

function XFubenSimulatedCombatConfig.GetMemberById(Id)
    return SimuCombatMember[Id]
end

function XFubenSimulatedCombatConfig.GetAdditionById(Id)
    return SimuCombatAddition[Id]
end

function XFubenSimulatedCombatConfig.GetChallengeById(Id)
    return SimuCombatChallenge[Id]
end

function XFubenSimulatedCombatConfig.GetPointReward(Id)
    return SimuCombatPointReward
end
function XFubenSimulatedCombatConfig.GetPointRewardById(Id)
    return SimuCombatPointReward[Id]
end

function XFubenSimulatedCombatConfig.GetStarReward(Id)
    return SimuCombatStarReward
end
function XFubenSimulatedCombatConfig.GetStarRewardById(Id)
    return SimuCombatStarReward[Id]
end

