XMentorSystemConfigs = XMentorSystemConfigs or {}

local TABLE_MENTORSYSTEM = "Share/Mentorship/MentorConfig.tab"
local TABLE_MANIFESTO_TAG = "Share/Mentorship/ManifestoTag.tab"
local TABLE_ONLINE_TAG = "Share/Mentorship/OnlineTag.tab"
local TABLE_MASTER_STAGEREWARD = "Share/Mentorship/MasterStageReward.tab"
local TABLE_STUDENT_WEEKLYREWARD = "Share/Mentorship/StudentWeeklyReward.tab"
local TABLE_TEACHER_WEEKLYTASKREWARD = "Share/Mentorship/MasterWeeklyTaskReward.tab"
local TABLE_TEACHER_CHALLENGEREWARD = "Share/Mentorship/StudentChallengeReward.tab"
local TABLE_CANNOTGIVE_WAFER = "Share/Mentorship/CanNotGiveWafer.tab"

local MentorSystemCfg = {}
local ManifestoTagCfg = {}
local OnlineTagCfg = {}
local MasterStageRewardCfg = {}
local StudentWeeklyRewardCfg = {}
local TeacherWeeklyTaskRewardCfg = {}
local TeacherChallengeRewardCfg = {}
local CanNotGiveWaferCfg = {}

XMentorSystemConfigs.IdentityType = {
    None = 0,
    Teacher = 1,
    Student = 2,
}

XMentorSystemConfigs.MessageType = {
    GetTeacher = 0,
    GetStudent = 1,
    LoseTeacher = 2,--被老师开除
    LoseStudent = 3,--被学生解雇
    GraduateStudent = 3,--学生毕业
}

XMentorSystemConfigs.TagType = {
    Normal = 1,
    Time = 2,
}

XMentorSystemConfigs.StudentRewardType = {
    Grow = 1,
    Graduate = 2,
}

XMentorSystemConfigs.TeacherTaskType = {
    Assist = 1,
    Reward = 2,
}

XMentorSystemConfigs.TaskStatus = {
    Init = 0,--未领取
    Received = 1,--已领取任务
    Completed = 2,--徒弟已完成任务
    GetReward = 3,--师傅已领取奖励
    GiveEquip = 4,--已赠送意识
    ReceiveEquip = 5--已领取意识
}

XMentorSystemConfigs.MySelfIndex = 1

function XMentorSystemConfigs.Init()
    MentorSystemCfg = XTableManager.ReadByStringKey(TABLE_MENTORSYSTEM, XTable.XTableMentorConfig, "Key")
    ManifestoTagCfg = XTableManager.ReadByIntKey(TABLE_MANIFESTO_TAG, XTable.XTableMentorTag, "Id")
    OnlineTagCfg = XTableManager.ReadByIntKey(TABLE_ONLINE_TAG, XTable.XTableMentorTag, "Id")
    MasterStageRewardCfg = XTableManager.ReadByIntKey(TABLE_MASTER_STAGEREWARD, XTable.XTableMasterStageReward, "Count")
    StudentWeeklyRewardCfg = XTableManager.ReadByIntKey(TABLE_STUDENT_WEEKLYREWARD, XTable.XTableStudentWeeklyReward, "Id")
    TeacherWeeklyTaskRewardCfg = XTableManager.ReadByIntKey(TABLE_TEACHER_WEEKLYTASKREWARD, XTable.XTableMasterWeeklyTaskReward, "TaskId")
    TeacherChallengeRewardCfg = XTableManager.ReadByIntKey(TABLE_TEACHER_CHALLENGEREWARD, XTable.XTableStudentChallengeReward, "TaskId")
    CanNotGiveWaferCfg = XTableManager.ReadByIntKey(TABLE_CANNOTGIVE_WAFER, XTable.XTableCanNotGiveWafer, "WaferId")
end

function XMentorSystemConfigs.GetMentorSystemData(key)
    if not MentorSystemCfg[key] then
        XLog.Error(key.." Is Not Existence By :Share/Mentorship/MentorConfig.tab")
        return 0
    end
    return MentorSystemCfg[key].Value
end

function XMentorSystemConfigs.GetManifestoTags()
    return ManifestoTagCfg
end

function XMentorSystemConfigs.GetOnlineTags()
    return OnlineTagCfg
end

function XMentorSystemConfigs.GetMasterStageRewards()
    return MasterStageRewardCfg
end

function XMentorSystemConfigs.GetStudentWeeklyRewards()
    return StudentWeeklyRewardCfg
end

function XMentorSystemConfigs.GetManifestoTagById(id)
    if not ManifestoTagCfg[id] then
        XLog.Error(id.." Is Not Existence By :Share/Mentorship/ManifestoTag.tab")
        return 0
    end
    return ManifestoTagCfg[id]
end

function XMentorSystemConfigs.GetOnlineTagById(id)
    if not OnlineTagCfg[id] then
        XLog.Error(id.." Is Not Existence By :Share/Mentorship/OnlineTag.tab")
        return 0
    end
    return OnlineTagCfg[id]
end

function XMentorSystemConfigs.GetTeacherWeeklyTaskRewardById(id)
    if not TeacherWeeklyTaskRewardCfg[id] then
        XLog.Error(id.." Is Not Existence By :Share/Mentorship/MasterWeeklyTaskReward.tab")
        return 0
    end
    return TeacherWeeklyTaskRewardCfg[id]
end

function XMentorSystemConfigs.GetTeacherChallengeRewardById(id)
    if not TeacherChallengeRewardCfg[id] then
        XLog.Error(id.." Is Not Existence By :Share/Mentorship/StudentChallengeReward.tab")
        return 0
    end
    return TeacherChallengeRewardCfg[id]
end

function XMentorSystemConfigs.IsCanNotGiveWafer(id)
    if not CanNotGiveWaferCfg[id] then
        return false
    else
       return true 
    end
end