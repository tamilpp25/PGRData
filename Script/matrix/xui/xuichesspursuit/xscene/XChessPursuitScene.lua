local XChessPursuitScene = XClass(nil, "XChessPursuitScene")

function XChessPursuitScene:Ctor(mapId, onLoadCompleteCb, onLeaveCb)
    self.OnLoadCompleteCb = onLoadCompleteCb
    self.OnLeaveCb = onLeaveCb

    self.MapId = mapId
end

function XChessPursuitScene:OnEnterScene()
    if self.GameObject then
        return
    end
    
    local config = XChessPursuitConfig.GetChessPursuitMapTemplate(self.MapId)
    local sceneAssetUrl = config.Perfab
    XLog.Error("[XResourceManager优化] 已经无法运行, 从XResourceManager改为loadPrefab")
    if not self.Resource.Asset then
        XLog.Error("XChessPursuitScene LoadScene error, instantiate error, name: " .. sceneAssetUrl)
        return
    end

    self.GameObject = CS.UnityEngine.Object.Instantiate(self.Resource.Asset)
    self.Transform = self.GameObject.transform
    self:OnLoadComplete(self.GameObject)
end

function XChessPursuitScene:OnLeaveScene()
    if self.OnLeaveCb then
        self.OnLeaveCb()
    end

    CS.UnityEngine.GameObject.Destroy(self.GameObject)
    self.GameObject = nil

    if self.Resource then
        self.Resource:Release()
    end
end

function XChessPursuitScene:OnLoadComplete()
    if self.OnLoadCompleteCb then
        self.OnLoadCompleteCb(self.GameObject)
    end
end

function XChessPursuitScene:GetSceneGameObject()
    return self.GameObject
end

function XChessPursuitScene:SetOnLeaveCb(cb)
    self.OnLeaveCb = cb
end

return XChessPursuitScene