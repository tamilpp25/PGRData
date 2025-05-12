
local CsVector3 = CS.UnityEngine.Vector3

---@class XRestaurantIScene : XEntity 餐厅场景接口
---@field _GameObject UnityEngine.GameObject 模型
---@field _Transform UnityEngine.Transform 模型变换
---@field _Root UnityEngine.Transform 父节点，可能为空
---@field _IsLoading boolean
---@field _Model XRestaurantModel
---@field _OwnControl XRestaurantControl
local XRestaurantIScene = XClass(XEntity, "XRestaurantIScene")

function XRestaurantIScene:OnInit(root, ...)
    self._Root = root
    self._IsLoading = false
    self:Init()
end

--- 创建对象时初始化
--------------------------
function XRestaurantIScene:Init()
end

--- 加载资源
---@param onLoadCb function 加载成功回调
---@return void
--------------------------
function XRestaurantIScene:Load(onLoadCb)
    if not self:CheckBeforeLoad() then
        return
    end
    local assetPath = self:GetAssetPath()
    local loader = self._OwnControl:GetLoader()
    self._IsLoading = true
    loader:LoadAsync(assetPath, function(asset)
        if not asset then
            XLog.Error("restaurant load resource error: asset path = " .. assetPath)
            return
        end

        self._ResPath = assetPath
        if not self:CheckAfterLoad() then
            self:Release()
            self._IsLoading = false
            return
        end
        self._GameObject = XUiHelper.Instantiate(resource.Asset)
        if not XTool.UObjIsNil(self._GameObject) then
            self._Transform = self._GameObject.transform
            self:ResetTransform()
            self._GameObject.name = self:GetObjName()
        end
        self:OnLoadSuccess()

        if onLoadCb then onLoadCb() end

        self._IsLoading = false
    end)
end

function XRestaurantIScene:OnRelease()
    self:DoRelease()
end

--- 释放资源, Release 会执行 RemoveEntity
---@return void
--------------------------
function XRestaurantIScene:Release()
   self:DoRelease()
    if self._OwnControl then
        self._OwnControl:RemoveEntity(self)
    end
    self._OwnControl = nil
end

function XRestaurantIScene:DoRelease()
    self:TryDestroy(self._GameObject)
    self._GameObject = nil
    self._Transform = nil
    
    if not string.IsNilOrEmpty(self._ResPath) then
        local loader = self._OwnControl:GetLoader()
        loader:Unload(self._ResPath)
        self._ResPath = nil
    end
end

--- 加载成功回调
--------------------------
function XRestaurantIScene:OnLoadSuccess()
end

--- 加载前检查
---@return boolean
--------------------------
function XRestaurantIScene:CheckBeforeLoad()
    return true
end

function XRestaurantIScene:CheckAfterLoad()
    return true
end

--- 获取资源路径
---@return string
--------------------------
function XRestaurantIScene:GetAssetPath()
    XLog.Error("XRestaurantIScene:GetAssetPath: subclass must override this function")
end

--- 重置场景变换
--------------------------
function XRestaurantIScene:ResetTransform()
    if not XTool.UObjIsNil(self._Root) then
        self._Transform:SetParent(self._Root.transform)
    end
    self:TryResetTransform(self._Transform)
end

--- 加载物体名
---@return string
--------------------------
function XRestaurantIScene:GetObjName()
    return "DefaultRestaurantScene"
end

--- 删除游戏物体
---@param obj UnityEngine.GameObject 物体
---@return boolean 是否销毁成功
--------------------------
function XRestaurantIScene:TryDestroy(obj)
    if XTool.UObjIsNil(obj) then
        return false
    end
    XUiHelper.Destroy(obj)
    obj = nil
    return true
end

function XRestaurantIScene:TryResetTransform(transform)
    if XTool.UObjIsNil(transform) then
        return false
    end
    transform.localPosition       = CsVector3.zero
    transform.localEulerAngles    = CsVector3.zero
    transform.localScale          = CsVector3.one
    return true
end

function XRestaurantIScene:Exist()
    return not XTool.UObjIsNil(self._GameObject)
end

function XRestaurantIScene:IsLoading()
    return self._IsLoading
end

function XRestaurantIScene:Hide()
    if not self:Exist() then
        return
    end
    self._GameObject:SetActiveEx(false)
end

function XRestaurantIScene:Show()
    if not self:Exist() then
        return
    end

    self._GameObject:SetActiveEx(true)
end

function XRestaurantIScene:GetTransform()
    return self._Transform
end

function XRestaurantIScene:GetWorldPosition()
    return self._Transform.position
end

function XRestaurantIScene:IsHide()
    return not self._GameObject.activeInHierarchy
end

return XRestaurantIScene