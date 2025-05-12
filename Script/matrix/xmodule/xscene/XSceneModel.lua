---@class XSceneModel : XModel
local XSceneModel = XClass(XModel, "XSceneModel")

local TableKey = {
    Scene = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal }
}

function XSceneModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("Scene", TableKey)
end

function XSceneModel:ClearPrivate()
end

function XSceneModel:ResetAll()
end

---@return XTableScene
function XSceneModel:GetSceneTemplate(sceneId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Scene, sceneId)
end

return XSceneModel