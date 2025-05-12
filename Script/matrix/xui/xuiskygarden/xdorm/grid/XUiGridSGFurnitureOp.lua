
---@class XUiGridSGFurnitureOp : XUiNode
---@field _Control XSkyGardenDormControl
---@field _Slot XDormitory.XFurnitureSlot
---@field CanvasGroup UnityEngine.CanvasGroup
---@field EmptyRaycast UnityEngine.UI.XEmpty4Raycast
local XUiGridSGFurnitureOp = XClass(XUiNode, "XUiGridSGFurnitureOp")

function XUiGridSGFurnitureOp:OnStart(slot)
    self._Slot = slot
    self._Index = -1
    self._Id = 0
    self:InitUi()
    self:InitCb()
end

function XUiGridSGFurnitureOp:Refresh(index, id, visible)
end

function XUiGridSGFurnitureOp:InitUi()
end

function XUiGridSGFurnitureOp:InitCb()
end

function XUiGridSGFurnitureOp:SetVisible(value)
    local progress = value and 1 or 0
    self.CanvasGroup.alpha = progress
    self._IsVisible = value
    self._Slot:SetVisible(value)
end

function XUiGridSGFurnitureOp:SetRaycast(value)
    self.CanvasGroup.blocksRaycasts = value
end

function XUiGridSGFurnitureOp:GetIndex()
    return self._Index
end

function XUiGridSGFurnitureOp:GetId()
    return self._Id
end

function XUiGridSGFurnitureOp:IsVisible()
    if not self._Slot or not self._Slot.gameObject.activeInHierarchy then
        self._IsVisible = false
        return false
    end
    
    return self._IsVisible
end

function XUiGridSGFurnitureOp:GetSlot()
    return self._Slot
end

return XUiGridSGFurnitureOp