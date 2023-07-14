XPhotographConfigs = XPhotographConfigs or {}

XPhotographConfigs.PhotographViewState = {
    Normal = 1,
    Capture = 2,
    SDK = 3,
}

local TABLE_BACK_GROUND = "Share/PhotoMode/Background.tab"
local TABLE_PHOTOMODE_SHARE_INFO = "Client/PhotoMode/ShareInfo.tab"

-- XTablePhotoModeSdk

local SceneTemplates = {}
local ShareInfo = {}

function XPhotographConfigs.Init()
    SceneTemplates = XTableManager.ReadByIntKey(TABLE_BACK_GROUND, XTable.XTableBackground, "Id")
    ShareInfo = XTableManager.ReadByIntKey(TABLE_PHOTOMODE_SHARE_INFO, XTable.XTablePhotoModeShareInfo, "Id")
end

function XPhotographConfigs.GetSceneTemplates()
    return SceneTemplates
end

function XPhotographConfigs.GetShareInfoByType(platformType)
    return ShareInfo[platformType]
end

function XPhotographConfigs.GetSceneTemplateById(id)
    if not SceneTemplates then
        return nil
    end

    return SceneTemplates[id]
end

function XPhotographConfigs.GetBackgroundNameById(id)
    if not SceneTemplates then
        return nil
    end

    return SceneTemplates[id].Name
end

function XPhotographConfigs.GetBackgroundQualityById(id)
    if not SceneTemplates then
        return nil
    end

    return SceneTemplates[id].Quality
end

function XPhotographConfigs.GetBackgroundDescriptionById(id)
    if not SceneTemplates then
        return nil
    end

    return SceneTemplates[id].Description
end

function XPhotographConfigs.GetBackgroundWorldDescriptionById(id)
    if not SceneTemplates then
        return nil
    end

    return SceneTemplates[id].WorldDescription
end

function XPhotographConfigs.GetBackgroundIconById(id)
    if not SceneTemplates then
        return nil
    end

    return SceneTemplates[id].Icon
end

function XPhotographConfigs.GetBackgroundBigIconById(id)
    if not SceneTemplates then
        return nil
    end

    return SceneTemplates[id].BigIcon
end

function XPhotographConfigs.GetBackgroundPriorityById(id)
    if not SceneTemplates then
        return nil
    end

    return SceneTemplates[id].Priority
end