
---@class XUiGrid3DBase : XUiNode
---@field Transform UnityEngine.Transform
---@field GameObject UnityEngine.GameObject
---@field Offset UnityEngine.Vector3
---@field Target UnityEngine.Transform
---@field _Control XRestaurantControl
local XUiGrid3DBase = XClass(XUiNode, "XUiGrid3D")

local LocalSize = Vector3.one

function XUiGrid3DBase:OnStart(parent, offset)
    self:InitUi()
    self:InitCb()

    if not XTool.UObjIsNil(parent) then
        self.Transform:SetParent(parent)
    end
    self.Parent = parent
    self.Offset = offset or Vector3.zero
end

function XUiGrid3DBase:SetTarget(target)
    self.Target = target
end

function XUiGrid3DBase:Show(...)
    self:Open()
    self:OnRefresh(...)
end

function XUiGrid3DBase:Hide()
    self:Close()
end

function XUiGrid3DBase:IsShow()
    if XTool.UObjIsNil(self.GameObject) then
        return false
    end
    return self.GameObject.activeInHierarchy
end

function XUiGrid3DBase:SetName(name)
    self.GameObject.name = name
end

function XUiGrid3DBase:InitUi()
end

function XUiGrid3DBase:InitCb()
end

function XUiGrid3DBase:OnRefresh(...)
end

local flag

--- 更新Ui位置
---@param room XRestaurantRoom
---@return void
--------------------------
function XUiGrid3DBase:UpdateTransform(room)
    if not room or not self:IsShow() then
        self:Hide()
        return
    end

    if XTool.UObjIsNil(self.Transform) 
            or XTool.UObjIsNil(self.Target) then
        self:Hide()
        return
    end
    
    room:SetViewPosToTransformLocalPosition(self.Transform, self.Target.transform, self.Offset)
    self.Transform.localScale = LocalSize
end

return XUiGrid3DBase