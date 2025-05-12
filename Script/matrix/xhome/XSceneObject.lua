---@class XSceneObject  场景基类对象
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Resource XIResource
---@field ModelPath string
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
    
    if self.ModelPath then
        XSceneResourceManager.Unload(self.ModelPath)
    end

    self.ModelPath = nil
end

function XSceneObject:SetModel(go, loadtype)
    self.GameObject = go
    self.Transform = go.transform

    XSceneEntityManager.AddEntity(self.GameObject, self)
    self:OnLoadComplete(loadtype)
end

--同步加载
function XSceneObject:LoadModel(modelPath, root)
    if string.IsNilOrEmpty(modelPath) then
        XLog.Error("宿舍模型加载失败，Url为空")
        return
    end
    self.ModelPath = modelPath
    if not self:CheckBeforeLoad() then
        return
    end
    local asset = XSceneResourceManager.LoadSync(modelPath)
    if not asset then
        XLog.Error(string.format("加载宿舍SceneObject:%s失败", modelPath))
        return
    end

    local model = CS.UnityEngine.Object.Instantiate(asset)
    self:BindToRoot(model, root)
    self:SetModel(model)
end

--异步加载
function XSceneObject:LoadModelAsync(modelPath, root)
    if string.IsNilOrEmpty(modelPath) then
        XLog.Error("宿舍模型加载失败，Url为空")
        return
    end
    self.ModelPath = modelPath
    if not self:CheckBeforeLoad() then
        return
    end
    XSceneResourceManager.LoadAsync(modelPath, function(asset)
        if not asset then
            XLog.Error(string.format("加载宿舍SceneObject:%s失败", modelPath))
            return
        end
        local model = CS.UnityEngine.Object.Instantiate(asset)
        self:BindToRoot(model, root)
        self:SetModel(model)
    end)
end

function XSceneObject:BindToRoot(model, root)
    model.transform:SetParent(root)
    model.transform.localPosition = CS.UnityEngine.Vector3.zero
    model.transform.localEulerAngles = CS.UnityEngine.Vector3.zero
    model.transform.localScale = CS.UnityEngine.Vector3.one
end

function XSceneObject:CheckBeforeLoad()
    return true
end

function XSceneObject:OnLoadComplete()
    -- body
end

function XSceneObject:GetObjType()
    return XHomeSceneObjType.None
end

return XSceneObject