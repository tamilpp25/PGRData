XFubenAssignConfigs = XFubenAssignConfigs or {}

local ChapterTemplates = {}
local GroupTemplates = {}
local TeamInfoTemplates = {}

function XFubenAssignConfigs.Init()
    ChapterTemplates = XTableManager.ReadByIntKey("Share/Fuben/Assign/AssignChapter.tab", XTable.XTableAssignChapter, "ChapterId")
    GroupTemplates = XTableManager.ReadAllByIntKey("Share/Fuben/Assign/AssignGroup.tab", XTable.XTableAssignGroup, "GroupId")
    TeamInfoTemplates = XTableManager.ReadByIntKey("Share/Fuben/Assign/AssignTeamInfo.tab", XTable.XTableAssignTeamInfo, "Id")
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