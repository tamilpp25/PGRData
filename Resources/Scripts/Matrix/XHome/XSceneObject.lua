---
--- 场景基类对象
---
local XSceneObject = XClass(nil, "XSceneObject")

function XSceneObject:Ctor()
    --
end

function XSceneObject:Dispose()
    XSceneEntityManager.RemoveEntity(self.GameObject)

    if self.GameObject and self.GameObject:Exist() then
        CS.UnityEngine.GameObject.Destroy(self.GameObject)
        self.GameObject = nil
        self.Transform = nil
    end

    if self.Resource then
        self.Resource:Release()
        self.Resource = nil
    end

    --if self.ModelPath then
    --XSceneResourceManager.ReturnGoToPool(self.ModelPath, self.GameObject)
    --end
    self.ModelPath = nil
end

function XSceneObject:SetModel(go, loadtype)
    self.GameObject = go
    self.Transform = go.transform

    XSceneEntityManager.AddEntity(self.GameObject, self)
    self:OnLoadComplete(loadtype)
end

function XSceneObject:LoadModel(modelPath, root)
    self.ModelPath = modelPath
    --local model = XSceneResourceManager.GetGoFromPool(modelPath)
    local resource = CS.XResourceManager.Load(modelPath)

    if resource == nil or not resource.Asset then
        XLog.Error(string.format("加载宿舍SceneObject:%s失败", modelPath))
        return
    end

    self.Resource = resource

    local model = CS.UnityEngine.Object.Instantiate(resource.Asset)
    self:BindToRoot(model, root)
    self:SetModel(model)
end

function XSceneObject:BindToRoot(model, root)
    model.transform:SetParent(root)
    model.transform.localPosition = CS.UnityEngine.Vector3.zero
    model.transform.localEulerAngles = CS.UnityEngine.Vector3.zero
    model.transform.localScale = CS.UnityEngine.Vector3.one
end

function XSceneObject:OnLoadComplete()
    -- body
end

return XSceneObject