XSceneModelConfigs = XSceneModelConfigs or {}

local TABLE_SCENEMODEL_PATH = "Client/SceneModel/SceneModel.tab"

local SceneModelTemplates = {}

function XSceneModelConfigs.Init()
    SceneModelTemplates = XTableManager.ReadByIntKey(TABLE_SCENEMODEL_PATH, XTable.XTableSceneModel, "Id")
end

function XSceneModelConfigs.GetSceneAndModelPathById(id)
    if not SceneModelTemplates[id] then
        XLog.Error("Not Find Scene and Model Define In Path:"..TABLE_SCENEMODEL_PATH, "Id:"..id)
        return nil
    end

    return SceneModelTemplates[id].ScenePath, SceneModelTemplates[id].ModelPath
end

function XSceneModelConfigs.GetScenePathById(id)
    if not SceneModelTemplates[id] then
        XLog.Error("Not Find Scene and Model Define In Path:"..TABLE_SCENEMODEL_PATH, "Id:"..id)
        return nil
    end

    return SceneModelTemplates[id].ScenePath
end

function XSceneModelConfigs.GetModelPathById(id)
    if not SceneModelTemplates[id] then
        XLog.Error("Not Find Scene and Model Define In Path:"..TABLE_SCENEMODEL_PATH, "Id:"..id)
        return nil
    end

    return SceneModelTemplates[id].ModelPath
end