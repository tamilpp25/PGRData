XFubenAssignConfigs = XFubenAssignConfigs or {}

local ChapterTemplates = {}
local GroupTemplates = {}
local TeamInfoTemplates = {}

-- 字典
local GroupChapterIdDic = {}

function XFubenAssignConfigs.Init()
    ChapterTemplates = XTableManager.ReadByIntKey("Share/Fuben/Assign/AssignChapter.tab", XTable.XTableAssignChapter, "ChapterId")
    GroupTemplates = XTableManager.ReadAllByIntKey("Share/Fuben/Assign/AssignGroup.tab", XTable.XTableAssignGroup, "GroupId")
    TeamInfoTemplates = XTableManager.ReadByIntKey("Share/Fuben/Assign/AssignTeamInfo.tab", XTable.XTableAssignTeamInfo, "Id")

    XFubenAssignConfigs.CreateChapterGroupIdDic()
end

function XFubenAssignConfigs.GetChapterTemplates()
    return ChapterTemplates
end

function XFubenAssignConfigs.GetGroupTemplates()
    return GroupTemplates
end

function XFubenAssignConfigs.GetTeamInfoTemplates()
    return TeamInfoTemplates
end

function XFubenAssignConfigs.GetChapterTemplateById(id)
    local config = ChapterTemplates[id]
    if not config then
        XLog.ErrorTableDataNotFound("XFubenAssignConfigs.GetChapterTemplateById",
        "AssignChapter", "Share/Fuben/Assign/AssignChapter.tab", "Id", tostring(id))
    end
    return config
end

function XFubenAssignConfigs.GetGroupTemplateById(id)
    local config = GroupTemplates[id]
    if not config then
        XLog.ErrorTableDataNotFound("XFubenAssignConfigs.GetGroupTemplateById",
        "AssignGroup", "Share/Fuben/Assign/AssignGroup.tab", "Id", tostring(id))
    end
    return config
end

function XFubenAssignConfigs.GetTeamInfoTemplateById(id)
    local config = TeamInfoTemplates[id]
    if not config then
        XLog.ErrorTableDataNotFound("XFubenAssignConfigs.GetTeamInfoTemplateById",
        "AssignTeamInfo", "Share/Fuben/Assign/AssignTeamInfo.tab", "Id", tostring(id))
    end
    return config
end

-- 构建/获取自定义字典

function XFubenAssignConfigs.CreateChapterGroupIdDic()
    for chapterId, v in pairs(ChapterTemplates) do
        for _, groupId in pairs(v.GroupId) do
            GroupChapterIdDic[groupId] = chapterId
        end
    end
end

function XFubenAssignConfigs.GetChapterIdByGroupId(groupId)
    return GroupChapterIdDic[groupId]
end
