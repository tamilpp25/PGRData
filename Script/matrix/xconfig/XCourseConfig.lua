XCourseConfig = XCourseConfig or {}

local TABLE_COURSE_SHARE = "Share/Fuben/Course/"
local TABLE_COURSE_CLINET = "Client/Fuben/Course/"

-- 面板页签类型，对应CourseActivity的SystemType
XCourseConfig.SystemType = {
    Lesson = 1,         -- 课程
    Exam = 2,           -- 考级
}

function XCourseConfig.Init()
    XConfigCenter.CreateGetProperties(XCourseConfig, {
        "CourseActivity",
        "CourseChapter",
        "CourseChapterDetail",
        "CourseStage",
        "CourseStageShowType",
        "CourseClientConfig",
        "CourseReward",
        "CourseChapterGroup",
        "CourseExamChapter",
        "CourseLessonChapter"
    }, { 
        "ReadByIntKey", TABLE_COURSE_CLINET .. "CourseActivity.tab", XTable.XTableCourseActivity, "StageType",
        "ReadByIntKey", TABLE_COURSE_SHARE .. "CourseChapter.tab", XTable.XTableCourseChapter, "ChapterId",
        "ReadByIntKey", TABLE_COURSE_CLINET .. "CourseChapterDetail.tab", XTable.XTableCourseChapterDetail, "ChapterId",
        "ReadByIntKey", TABLE_COURSE_SHARE .. "CourseStage.tab", XTable.XTableCourseStage, "StageId",
        "ReadByIntKey", TABLE_COURSE_CLINET .. "CourseStageShowType.tab", XTable.XTableCourseStageShowType, "StageShowType",
        "ReadByStringKey", TABLE_COURSE_CLINET .. "CourseClientConfig.tab", XTable.XTableCourseClientConfig, "Key",
        "ReadByIntKey", TABLE_COURSE_SHARE .. "CourseReward.tab", XTable.XTableCourseReward, "Id",
        "ReadByIntKey", TABLE_COURSE_CLINET .. "CourseChapterGroup.tab", XTable.XTableCourseChapterGroup, "GroupId",
        "ReadByIntKey", TABLE_COURSE_CLINET .. "CourseExamChapter.tab", XTable.XTableCourseExamChapter, "ChapterId",
        "ReadByIntKey", TABLE_COURSE_CLINET .. "CourseLessonChapter.tab", XTable.XTableCourseLessonChapter, "ChapterId",
    })
end


--==============================CourseActivity 考级页签==============================
-- 读取功能开启TimeId
function XCourseConfig.GetActivityTimeId(stageType)
    local config = XCourseConfig.GetCourseActivity(stageType)
    return config.TimeId
end

-- 读取章节组Id列表
function XCourseConfig.GetActivityGroupIds(stageType)
    local config = XCourseConfig.GetCourseActivity(stageType)
    return config.GroupIds
end
--==================================================================================



--===============================CourseChapter 课程=================================
local StageTypeToChapterIdList = {} --key: 章节类型，value: 章节Id列表
local StageIdToChapterIdMap = {}    --key：CourseStage表的Id，value：CourseChapter表的Id
local IsInitChapterConfig = false
local InitChapterConfig = function()
    if IsInitChapterConfig then
        return
    end

    local stageIds
    local stageType
    local configs = XCourseConfig.GetCourseChapter()
    for chapterId, config in pairs(configs) do
        stageType = config.StageType
        if not StageTypeToChapterIdList[stageType] then
            StageTypeToChapterIdList[stageType] = {}
        end
        table.insert(StageTypeToChapterIdList[stageType], chapterId)

        stageIds = config.StageIds
        for index, stageId in ipairs(stageIds) do
            StageIdToChapterIdMap[stageId] = chapterId
        end
    end
    for _, chapterIdList in ipairs(StageTypeToChapterIdList) do
        table.sort(chapterIdList, function(a, b)
            local orderA = XCourseConfig.GetChapterOrder(a)
            local orderB = XCourseConfig.GetChapterOrder(b)
            if XTool.IsNumberValid(orderA) and XTool.IsNumberValid(orderB) and orderA ~= orderB then
                if not XTool.IsNumberValid(orderA) then
                    return false
                end
                if not XTool.IsNumberValid(orderB) then
                    return true
                end
                return orderA < orderB
            end
            return a < b
        end)
    end
    
    IsInitChapterConfig = true
end

function XCourseConfig.GetChapterIdByStageId(stageId)
    InitChapterConfig()
    return StageIdToChapterIdMap[stageId]
end

function XCourseConfig.GetChapterOrder(id)
    local config = XCourseConfig.GetCourseChapterById(id)
    return config and config.OrderId
end

-- 读取章节列表
function XCourseConfig.GetChapterIdListByStageType(stageType)
    InitChapterConfig()
    return StageTypeToChapterIdList[stageType] or {}
end

function XCourseConfig.GetCourseChapterById(chapterId)
    return XCourseConfig.GetCourseChapter(chapterId, true)
end

function XCourseConfig.GetChapterStageType(chapterId)
    local config = XCourseConfig.GetCourseChapterById(chapterId)
    return not XTool.IsTableEmpty(config) and config.StageType or nil
end

function XCourseConfig.GetCourseChapterNeedPointById(chapterId)
    local config = XCourseConfig.GetCourseChapterById(chapterId)
    return not XTool.IsTableEmpty(config) and config.NeedPoint or nil
end

function XCourseConfig.GetCourseChapterPrevIdById(chapterId)
    local config = XCourseConfig.GetCourseChapterById(chapterId)
    return not XTool.IsTableEmpty(config) and config.PrevChapterId or nil
end

function XCourseConfig.GetCourseChapterStageIdsById(chapterId)
    local config = XCourseConfig.GetCourseChapterById(chapterId)
    return not XTool.IsTableEmpty(config) and config.StageIds or nil
end

function XCourseConfig.GetCourseChapterUnlockLessonPoint(chapterId)
    local config = XCourseConfig.GetCourseChapterById(chapterId)
    return not XTool.IsTableEmpty(config) and config.UnlockLessonPoint or nil
end

function XCourseConfig.GetCourseChapterPrevChapterId(chapterId)
    local config = XCourseConfig.GetCourseChapterById(chapterId)
    return not XTool.IsTableEmpty(config) and config.PrevChapterIds or {}
end

function XCourseConfig.GetCourseChapterClearPoint(chapterId)
    local config = XCourseConfig.GetCourseChapterById(chapterId)
    return not XTool.IsTableEmpty(config) and config.ClearPoint or nil
end

function XCourseConfig.GetCourseChapterName(chapterId)
    local config = XCourseConfig.GetCourseChapterById(chapterId)
    return not XTool.IsTableEmpty(config) and config.Name or nil
end

function XCourseConfig.GetCourseChapterShortName(chapterId, startPos, endPos)
    startPos = startPos or 1
    endPos = endPos or 4
    local name = XCourseConfig.GetCourseChapterName(chapterId)
    return string.sub(name, startPos, endPos)
end

function XCourseConfig.GetCourseChapterLockDesc(chapterId)
    local config = XCourseConfig.GetCourseChapterById(chapterId)
    return not XTool.IsTableEmpty(config) and config.LockDesc or nil
end

function XCourseConfig.GetCourseChapterUnlockLv(chapterId)
    local config = XCourseConfig.GetCourseChapterById(chapterId)
    return not XTool.IsTableEmpty(config) and config.UnlockLv or 0
end

--获得章节所有星星的数量
function XCourseConfig.GetTotalStarPointCount(chapterId)
    local stageIdList = XCourseConfig.GetCourseChapterStageIdsById(chapterId)
    local totalPointCount = 0
    for index, stageId in ipairs(stageIdList) do
        totalPointCount = totalPointCount + #XCourseConfig.GetCourseStageStarPointById(stageId)
    end
    return totalPointCount
end
--==================================================================================



--===================CourseLessonChapter 课程章节前端配置===========================
function XCourseConfig.GetLessonChapterGridNormalBg(id)
    local config = XCourseConfig.GetCourseLessonChapter(id, true)
    return config.GridNormalBg
end

function XCourseConfig.GetLessonChapterImgNum(id)
    local config = XCourseConfig.GetCourseLessonChapter(id, true)
    return config.ImgNum
end

function XCourseConfig.GetLessonChapterSortBg(id)
    local config = XCourseConfig.GetCourseLessonChapter(id, true)
    return config.SortBg
end

function XCourseConfig.GetLessonShowReward(id)
    local config = XCourseConfig.GetCourseLessonChapter(id, true)
    return config.ShowReward
end
--==================================================================================

--===================CourseExamChapter 执照章节前端配置===========================
function XCourseConfig.GetExamChapterGridNormalBg(id)
    local config = XCourseConfig.GetCourseExamChapter(id, true)
    return config.GridNormalBg
end

function XCourseConfig.GetExamChapterGridDisableBg(id)
    local config = XCourseConfig.GetCourseExamChapter(id, true)
    return config.GridDisableBg
end

function XCourseConfig.GetExamChapterGridShowReward(id)
    local config = XCourseConfig.GetCourseExamChapter(id, true)
    return config.ShowReward
end

function XCourseConfig.GetExamChapterGridShowRewardIcon(id)
    local config = XCourseConfig.GetCourseExamChapter(id, true)
    return config.RewardIcon
end
--==================================================================================



--===========================CourseChapterDetail 关卡详情=============================
function XCourseConfig.GetCourseChapterDetailById(chapterId)
    return XCourseConfig.GetCourseChapterDetail(chapterId, true)
end

function XCourseConfig.GetCourseLessonDetailBgById(chapterId)
    local config = XCourseConfig.GetCourseChapterDetailById(chapterId)
    return not XTool.IsTableEmpty(config) and config.Bg or nil
end

function XCourseConfig.GetCourseLessonDetailDescTitleById(chapterId)
    local config = XCourseConfig.GetCourseChapterDetailById(chapterId)
    return not XTool.IsTableEmpty(config) and config.DescTitle or nil
end

function XCourseConfig.GetCourseLessonDetailDescById(chapterId)
    local config = XCourseConfig.GetCourseChapterDetailById(chapterId)
    return not XTool.IsTableEmpty(config) and config.Desc or nil
end
--==================================================================================



--================================CourseStage 课程==================================
function XCourseConfig.GetCourseStageById(stageId)
    return XCourseConfig.GetCourseStage(stageId, true)
end

function XCourseConfig.GetCourseStagePrevStageIdById(stageId)
    local config = XCourseConfig.GetCourseStageById(stageId)
    return not XTool.IsTableEmpty(config) and config.PrevStageId
end

function XCourseConfig.GetCourseStageStarPointById(stageId)
    local config = XCourseConfig.GetCourseStageById(stageId)
    return not XTool.IsTableEmpty(config) and config.StarPoint or {}
end

function XCourseConfig.GetCourseStageShowTypeByStageId(stageId)
    local config = XCourseConfig.GetCourseStageById(stageId)
    return not XTool.IsTableEmpty(config) and config.StageShowType
end

function XCourseConfig.GetCourseStageNameById(stageId)
    return XFubenConfigs.GetStageName(stageId)
end

function XCourseConfig.GetCourseStageDescById(stageId)
    local config = XCourseConfig.GetCourseStageById(stageId)
    return not XTool.IsTableEmpty(config) and config.Desc
end

function XCourseConfig.GetCourseLessonStageIdById(stageId)
    local config = XCourseConfig.GetCourseStageById(stageId)
    return not XTool.IsTableEmpty(config) and config.LessonStageId
end
--==================================================================================



--=====================CourseStageShowType 关卡类型展示=============================
function XCourseConfig.GetCourseStageShowTypeById(id)
    return XCourseConfig.GetCourseStageShowType(id, true)
end

function XCourseConfig.GetStageShowTypeName(id)
    local config = XCourseConfig.GetCourseStageShowTypeById(id)
    return not XTool.IsTableEmpty(config) and config.TypeName or nil
end

function XCourseConfig.GetStageShowTypeTxtRewardTitle(id)
    local config = XCourseConfig.GetCourseStageShowTypeById(id)
    return not XTool.IsTableEmpty(config) and config.TxtRewardTitle or nil
end

function XCourseConfig.GetStageShowTypeTxtDescTitle(id)
    local config = XCourseConfig.GetCourseStageShowTypeById(id)
    return not XTool.IsTableEmpty(config) and config.TxtDescTitle or nil
end

function XCourseConfig.GetStageShowTypeIconPath(id)
    local config = XCourseConfig.GetCourseStageShowTypeById(id)
    return not XTool.IsTableEmpty(config) and config.IconPath or nil
end

function XCourseConfig.GetStageShowTypePrefabPath(id)
    local config = XCourseConfig.GetCourseStageShowTypeById(id)
    return not XTool.IsTableEmpty(config) and config.PrefabPath
end
--==================================================================================



--==========================CourseReward 奖励=======================================
local StageTypeToRewardIdList = {} --key: 章节类型，value: CourseRewardId列表
local StageTypeToRewardTotalPoint = {}  --key：章节类型，value：总绩点
local ChapterIdToRewardId = {}  --key：章节Id，value：CourseReward表的Id
local ChapterIdToRewardIdList = {}  --key：章节Id，value：CourseReward表的Id列表
local IsInitCourseRewardConfig = false
local InitCourseRewardConfig = function()
    if IsInitCourseRewardConfig then
        return
    end

    local chapterId
    local stageType
    local configs = XCourseConfig.GetCourseReward()
    for id, config in pairs(configs) do
        chapterId = config.ChapterId

        ChapterIdToRewardId[chapterId] = id
        if not ChapterIdToRewardIdList[chapterId] then
            ChapterIdToRewardIdList[chapterId] = {}
        end
        table.insert(ChapterIdToRewardIdList[chapterId], id)

        stageType = XCourseConfig.GetChapterStageType(chapterId)
        if not stageType then
            XLog.Error(string.format("CourseReward配置中，chapterId：%d不存在", chapterId))
            goto continue
        end
        if not StageTypeToRewardIdList[stageType] then
            StageTypeToRewardIdList[stageType] = {}
        end
        table.insert(StageTypeToRewardIdList[stageType], id)

        if not StageTypeToRewardTotalPoint[stageType] then
            StageTypeToRewardTotalPoint[stageType] = 0
        end
        StageTypeToRewardTotalPoint[stageType] = StageTypeToRewardTotalPoint[stageType] + config.Point

        :: continue ::
    end
    
    IsInitCourseRewardConfig = true
end

function XCourseConfig.GetRewardIdListByChapterId(chapterId)
    InitCourseRewardConfig()
    return ChapterIdToRewardIdList[chapterId] or {}
end

function XCourseConfig.GetRewardIdByChapterId(chapterId)
    InitCourseRewardConfig()
    return ChapterIdToRewardId[chapterId] or 0
end

function XCourseConfig.GetCourseRewardIdList(stageType)
    InitCourseRewardConfig()
    return StageTypeToRewardIdList[stageType] or {}
end

function XCourseConfig.GetRewardTotalPoint(stageType)
    InitCourseRewardConfig()
    return StageTypeToRewardTotalPoint[stageType] or 0
end

function XCourseConfig.GetRewardId(id)
    local config = XCourseConfig.GetCourseReward(id, true)
    return config.RewardId
end

function XCourseConfig.GetRewardPoint(id)
    local config = XCourseConfig.GetCourseReward(id, true)
    return config.Point
end

function XCourseConfig.GetRewardClearTipsTitle(id)
    local config = XCourseConfig.GetCourseReward(id, true)
    return config.ClearTipsTitle
end

function XCourseConfig.GetRewardChapterId(id)
    local config = XCourseConfig.GetCourseReward(id, true)
    return config.ChapterId
end

function XCourseConfig.GetRewardName(id)
    local config = XCourseConfig.GetCourseReward(id, true)
    return config.Name
end
--==================================================================================

--==========================CourseClientConfig 前端配置==============================
--获得章节弹窗的说明文本颜色（Values[1]：未达成；Values[2]：已达成）
function XCourseConfig.GetChapterTipsDescColor()
    local values = XCourseConfig.GetCourseClientConfig("ChapterTipsDescColor").Values
    return XUiHelper.Hexcolor2Color(values[1]), XUiHelper.Hexcolor2Color(values[2])
end

--获得章节弹窗的解锁条件文本（1：绩点；2：前置章节）
function XCourseConfig.GetChapterTipsUnlockDesc()
    local values = XCourseConfig.GetCourseClientConfig("ChapterTipsUnlockDesc").Values
    return values[1], values[2]
end

--获得战斗执照章节说明弹窗的按钮名（1：已解锁；2：未解锁）
function XCourseConfig.GetChapterTipsBtnName()
    local values = XCourseConfig.GetCourseClientConfig("ExamChapterTipsBtnName").Values
    return values[1], values[2]
end

--获得绩点道具Id
function XCourseConfig.GetPointItemId()
    local values = XCourseConfig.GetCourseClientConfig("PointItemId").Values
    return tonumber(values[1])
end

--获得课程关卡第几个格子的数字资源路径
function XCourseConfig.GetLessonStageImgNum(index)
    return XCourseConfig.GetCourseClientConfig("LessonStageImgNum").Values[index]
end

--课程/考级结算提示
function XCourseConfig.GetCourseOrExamFinishTips(index)
    local tips = XCourseConfig.GetCourseClientConfig("CourseOrExamFinishTips").Values[index]
    return tips or ""
end

function XCourseConfig.GetRewardTips(index)
    local tips = XCourseConfig.GetCourseClientConfig("RewardTips").Values[index]
    return tips or ""
end
--==================================================================================

--==============================CourseChapterGroup 章节组===========================
function XCourseConfig.GetChapterIds(id)
    local config = XCourseConfig.GetCourseChapterGroup(id, true)
    return config.ChapterIds
end

function XCourseConfig.GetChapterGroupPrevChapterIds(id)
    local config = XCourseConfig.GetCourseChapterGroup(id, true)
    return config.PrevChapterIds
end

function XCourseConfig.GetChapterGroupUnlockLv(id)
    local config = XCourseConfig.GetCourseChapterGroup(id, true)
    return config.UnlockLv
end

function XCourseConfig.GetChapterGroupLockDesc(id)
    local config = XCourseConfig.GetCourseChapterGroup(id, true)
    return config.LockDesc
end

function XCourseConfig.GetChapterGroupBg(id)
    local config = XCourseConfig.GetCourseChapterGroup(id, true)
    return config.Bg
end
--==================================================================================