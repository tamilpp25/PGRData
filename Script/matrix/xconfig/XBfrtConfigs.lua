local TABLE_BFRT_CHAPTER_PATH = "Share/Fuben/Bfrt/BfrtChapter.tab"
local TABLE_BFRT_GROUP_PATH = "Share/Fuben/Bfrt/BfrtGroup.tab"
local TABLE_ECHELON_INFO_PATH = "Share/Fuben/Bfrt/EchelonInfo.tab"
local TABLE_BFRT_COURSE_REWARD_PATH = "Share/Fuben/Bfrt/BfrtCourseReward.tab"

---@type XTableBfrtChapter[]
local BfrtChapterTemplates = {}
---@type XTableBfrtGroup[]
local BfrtGroupTemplates = {}
---@type XTableEchelonInfo[]
local EchelonInfoTemplates = {}
---@type XTableBfrtCourseReward[]
local CourseRewardTemplates = {}

XBfrtConfigs = XBfrtConfigs or {}

function XBfrtConfigs.Init()
    BfrtChapterTemplates = XTableManager.ReadAllByIntKey(TABLE_BFRT_CHAPTER_PATH, XTable.XTableBfrtChapter, "ChapterId")
    BfrtGroupTemplates = XTableManager.ReadAllByIntKey(TABLE_BFRT_GROUP_PATH, XTable.XTableBfrtGroup, "GroupId")
    EchelonInfoTemplates = XTableManager.ReadByIntKey(TABLE_ECHELON_INFO_PATH, XTable.XTableEchelonInfo, "Id")
    CourseRewardTemplates = XTableManager.ReadByIntKey(TABLE_BFRT_COURSE_REWARD_PATH, XTable.XTableBfrtCourseReward, "Id")
end

function XBfrtConfigs.GetBfrtChapterTemplates()
    return BfrtChapterTemplates
end

function XBfrtConfigs.GetEchelonInfoTemplates()
    return EchelonInfoTemplates
end

---@return XTableBfrtGroup
local function GetGroupCfg(groupId)
    local groupCfg = BfrtGroupTemplates[groupId]
    if not groupCfg then
        XLog.ErrorTableDataNotFound("GetGroupCfg", "groupCfg", "Share/Fuben/Bfrt/BfrtGroup.tab", "groupId", tostring(groupId))
        return
    end
    return groupCfg
end

function XBfrtConfigs.GetBfrtGroupTemplates()
    return BfrtGroupTemplates
end

function XBfrtConfigs.GetBfrtPreGroupId(groupId)
    local config = GetGroupCfg(groupId)
    return config.PreGroupId
end

--region CourseReward
---@return XTableBfrtCourseReward[]
function XBfrtConfigs.GetBfrtRewardTemplates()
    return CourseRewardTemplates
end

---@return XTableBfrtCourseReward
function XBfrtConfigs.GetBfrtRewardTemplateById(id)
    return CourseRewardTemplates[id]
end
--endregion