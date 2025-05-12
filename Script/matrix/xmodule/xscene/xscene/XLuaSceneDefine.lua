local XLuaSceneDefine = {}

local sceneBindControl = {
    -- SceneName -> ModuleId
    --E.G.: Restaurant = ModuleId.XUiMain
}

local sceneRegistry = {
    -- SceneName -> ModulePath
    --E.G.: Restaurant = "XModule/XRestaurant/XSceneRestaurant",
}

XLuaSceneDefine.SceneBindControl = sceneBindControl
XLuaSceneDefine.SceneRegistry = sceneRegistry

return XLuaSceneDefine