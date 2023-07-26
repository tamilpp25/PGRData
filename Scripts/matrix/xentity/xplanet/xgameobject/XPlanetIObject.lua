---@class XPlanetIObject 行星环游记场景对象接口
---@field _Resource CS.XIResource 资源
---@field _GameObject CS.UnityEngine.GameObject
---@field _Transform CS.UnityEngine.Transform
---@field _Root CS.UnityEngine.Transform 父节点，可能为空
local XPlanetIObject = XClass(nil, "XPlanetIObject")

function XPlanetIObject:Ctor(root, ...)
    self._Root = root
    self:Init()
end

--- 创建对象时初始化
function XPlanetIObject:Init()
end

--- 加载资源
---@param onLoadCb function 加载成功回调
---@return void
function XPlanetIObject:Load(onLoadCb)
    if not self:CheckBeforeLoad() then
        return
    end
    local assetPath = self:GetAssetPath()
    local resource = CS.XResourceManager.LoadAsync(assetPath)
    CS.XTool.WaitCoroutine(resource, function()
        if not (resource and resource.Asset) then
            XLog.Error("restaurant load resource error: asset path = " .. assetPath)
            return
        end

        self._Resource = resource
        self._GameObject = XUiHelper.Instantiate(resource.Asset)
        if not XTool.UObjIsNil(self._GameObject) then
            self._Transform = self._GameObject.transform
            self:ResetTransform()
            self._GameObject.name = self:GetObjName()
        end
        self:OnLoadSuccess()

        if onLoadCb then onLoadCb() end
    end)
end

--- 释放资源
---@return void
function XPlanetIObject:Release()
    self:TryDestroy(self._GameObject)
    self._GameObject = nil
    self._Transform = nil

    if self._Resource then
        self._Resource:Release()
        self._Resource = nil
    end
end

--- 加载成功回调
function XPlanetIObject:OnLoadSuccess()
end

--- 加载前检查
---@return boolean
function XPlanetIObject:CheckBeforeLoad()
    return true
end

--- 获取资源路径
---@return string
function XPlanetIObject:GetAssetPath()
    XLog.Error("XPlanetIObject:GetAssetPath: subclass must override this function")
end

--- 获取GameObject
---@return CS.UnityEngine.GameObject
function XPlanetIObject:GetGameObject()
    if not XTool.UObjIsNil(self._GameObject) then
        return self._GameObject
    end
end

--- 获取Transform
---@return CS.UnityEngine.Transform
function XPlanetIObject:GetTransform()
    if not XTool.UObjIsNil(self._Transform) then
        return self._Transform
    end
end

--- 加载物体名
---@return string
function XPlanetIObject:GetObjName()
    return "DefaultName"
end

--- 设置游戏物体为动态合批对象
function XPlanetIObject:SetGameObjectDynamicTag()
    if XTool.UObjIsNil(self._Transform) then return end
    local dynamicTag = "Dynamic"
    -- 修改tag为动态合批tag
    self._Transform.tag = dynamicTag;
    local trans = self._GameObject:GetComponentsInChildren(typeof(CS.UnityEngine.Transform))
    for i = 0, trans.Length - 1 do
        trans[i].tag = dynamicTag
    end
end

--- 重置场景变换
function XPlanetIObject:ResetTransform()
    if XTool.UObjIsNil(self._Transform) then return end
    if not XTool.UObjIsNil(self._Root) then
        self._Transform:SetParent(self._Root.transform)
    end
    self:TryResetTransform(self._Transform)
end

--- 删除游戏物体
---@param obj UnityEngine.GameObject 物体
---@return boolean 是否销毁成功
function XPlanetIObject:TryDestroy(obj)
    if XTool.UObjIsNil(obj) then
        return false
    end
    XUiHelper.Destroy(obj)
    obj = nil
    return true
end

function XPlanetIObject:TryResetTransform(transform)
    if XTool.UObjIsNil(transform) then
        return false
    end
    transform.localPosition       = Vector3.zero
    transform.localEulerAngles    = Vector3.zero
    transform.localScale          = Vector3.one
    return true
end

function XPlanetIObject:Exist()
    return not XTool.UObjIsNil(self._GameObject)
end

return XPlanetIObject