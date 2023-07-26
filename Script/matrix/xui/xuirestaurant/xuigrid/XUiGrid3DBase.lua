
---@class XUiGrid3DBase 
---@field Transform UnityEngine.Transform
---@field GameObject UnityEngine.GameObject
---@field Offset UnityEngine.Vector3
---@field Target UnityEngine.Transform
local XUiGrid3DBase = XClass(nil, "XUiGrid3D")

function XUiGrid3DBase:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self:InitUi()
    self:InitCb()
    self.LocalScale = CS.UnityEngine.Vector3.one
    self.Offset = CS.UnityEngine.Vector3.zero
end

function XUiGrid3DBase:Bind(parent, target, offset)
    if not XTool.UObjIsNil(parent) then
        self.Transform:SetParent(parent)
    end
    self.Parent = parent
    self.Offset = offset or self.Offset
    self.Target = target
end

function XUiGrid3DBase:Show(...)
    self.GameObject:SetActiveEx(true)
    self:OnRefresh(...)
end

function XUiGrid3DBase:Hide()
    self.GameObject:SetActiveEx(false)
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

--- 更新Ui位置
---@param room XRestaurantRoom
---@return void
--------------------------
function XUiGrid3DBase:UpdateTransform(room)
    if not room or not self:IsShow() then
        return
    end

    if XTool.UObjIsNil(self.Transform) 
            or XTool.UObjIsNil(self.Target) then
        return
    end
    
    room:SetViewPosToTransformLocalPosition(self.Transform, self.Target.transform, self.Offset)
    self.Transform.localScale = self.LocalScale
end

return XUiGrid3DBase