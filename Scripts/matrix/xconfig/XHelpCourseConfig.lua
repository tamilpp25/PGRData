XHelpCourseConfig = XHelpCourseConfig or {}

local TABLE_HELP_COURSE_PATH = "Client/HelpCourse/HelpCourse.tab"
local HelpCourseTemplate = {}
local HelpCourseTemplateIndex = {}

function XHelpCourseConfig.Init()
    HelpCourseTemplate = XTableManager.ReadByIntKey(TABLE_HELP_COURSE_PATH, XTable.XTableHelpCourse, "Id")
    for _,v in pairs(HelpCourseTemplate) do
        HelpCourseTemplateIndex[v.Function] = v
    end
 end

--获取帮助教程表
function XHelpCourseConfig.GetHelpCourseTemplate()
    return HelpCourseTemplate
end

--通过Id获取
function XHelpCourseConfig.GetHelpCourseTemplateById(id)
    if HelpCourseTemplate == nil then
        return
    end

    if not HelpCourseTemplate[id] then
        XLog.ErrorTableDataNotFound("XHelpCourseConfig.GetHelpCourseTemplateById", "HelpCourse", TABLE_HELP_COURSE_PATH, "Id", tostring(id))
    end

    return HelpCourseTemplate[id]
end

--通过功能获取
function XHelpCourseConfig.GetHelpCourseTemplateByFunction(key)
    if HelpCourseTemplateIndex == nil then
        return
    end

    if not HelpCourseTemplateIndex[key] then
        XLog.ErrorTableDataNotFound("XHelpCourseConfig.GetHelpCourseTemplateByFunction",
        "HelpCourse", TABLE_HELP_COURSE_PATH, "Function", tostring(key))
    end

    return HelpCourseTemplateIndex[key]
end

function XHelpCourseConfig.GetImageAssetCount(id)
    local template = XHelpCourseConfig.GetHelpCourseTemplateByFunction(id)
    if not template then
        return 0
    end
    return #template.ImageAsset
end 