XPracticeConfigs = XPracticeConfigs or {}

local CLIENT_PRACTICE_CHAPTERDETAIL = "Client/Fuben/Practice/PracticeChapterDetail.tab"
local CLIENT_PRACTICE_SKILLDETAIL = "Client/Fuben/Practice/PracticeSkillDetails.tab"

local SHARE_PRACTICE_CHAPTER = "Share/Fuben/Practice/PracticeChapter.tab"
local SHARE_PRACTICE_ACTIVITY = "Share/Fuben/Practice/PracticeActivity.tab"

local PracticeChapterDetails = {}
local PracticeSkillDetails = {}
local PracticeActivityInfo = {}

local PracticeChapters = {}

XPracticeConfigs.PracticeType = {
    Basics = 1,
    Advanced = 2,
    Character = 3,
}

function XPracticeConfigs.Init()
    PracticeChapterDetails = XTableManager.ReadByIntKey(CLIENT_PRACTICE_CHAPTERDETAIL, XTable.XTablePracticeChapterDetail, "Id")
    PracticeSkillDetails = XTableManager.ReadByIntKey(CLIENT_PRACTICE_SKILLDETAIL, XTable.XTablePracticeSkillDetails, "StageId")
    PracticeChapters = XTableManager.ReadByIntKey(SHARE_PRACTICE_CHAPTER, XTable.XTablePracticeChapter, "Id")
    PracticeActivityInfo = XTableManager.ReadByIntKey(SHARE_PRACTICE_ACTIVITY, XTable.XTablePracticeActivity, "StageId")
end

function XPracticeConfigs.GetPracticeChapters()
    return PracticeChapters
end

function XPracticeConfigs.GetPracticeChapterById(id)
    local currentChapter = PracticeChapters[id]

    if not currentChapter then
        XLog.ErrorTableDataNotFound("XPracticeConfigs.GetPracticeChapterById", "currentChapter", SHARE_PRACTICE_CHAPTER, "id", tostring(id))
        return
    end

    return currentChapter
end

function XPracticeConfigs.GetPracticeChapterConditionById(id)
    local currentChapter = XPracticeConfigs.GetPracticeChapterById(id)
    return currentChapter.ConditionId
end

function XPracticeConfigs.GetPracticeChapterDetails()
    return PracticeChapterDetails
end

function XPracticeConfigs.GetPracticeChapterDetailById(id)
    local currentChapterDetail = PracticeChapterDetails[id]

    if not currentChapterDetail then
        XLog.ErrorTableDataNotFound("XPracticeConfigs.GetPracticeChapterDetailById", "currentChapterDetail", CLIENT_PRACTICE_CHAPTERDETAIL, "id", tostring(id))
        return
    end

    return currentChapterDetail
end

function XPracticeConfigs.GetPracticeDescriptionById(id)
    local details = XPracticeConfigs.GetPracticeChapterDetailById(id)
    if not details then return "" end
    return details.Description or ""
end

function XPracticeConfigs.GetPracticeChapterTypeById(id)
    local details = XPracticeConfigs.GetPracticeChapterDetailById(id)
    if not details then return end
    return details.Type
end

function XPracticeConfigs.GetPracticeActivityInfo(stageId)
    return PracticeActivityInfo[stageId]
end

function XPracticeConfigs.GetPracticeSkillDetailById(id)
    local currentDetail = PracticeSkillDetails[id]
    if not currentDetail then
        XLog.ErrorTableDataNotFound("XPracticeConfigs.GetPracticeSkillDetailById", "currentDetail", CLIENT_PRACTICE_SKILLDETAIL, "id", tostring(id))
        return
    end
    return currentDetail
end