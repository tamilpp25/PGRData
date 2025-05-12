---@class XUiGridErrorHud : XUiNode
---@field Parent XUiBlackRockChessComponent
---@field _Control XBlackRockChessControl
local XUiGridErrorHud = XClass(XUiNode, "XUiGridErrorHud")

local CsVector3One = CS.UnityEngine.Vector3.one

function XUiGridErrorHud:OnStart()

end

function XUiGridErrorHud:OnDestroy()
    self.Target = nil
end

function XUiGridErrorHud:SetScale(scale)
    self.Transform.localScale = CsVector3One * scale
end

function XUiGridErrorHud:BindTarget(target, offset, pieceId)
    self.PieceId = pieceId
    self.Pivot = self.Pivot or CS.UnityEngine.Vector2(0.5, 0.5)
    self.Target = target
    self.Offset = offset or CS.UnityEngine.Vector3.zero
end

function XUiGridErrorHud:UpdateTransform()
    if XTool.UObjIsNil(self.GameObject) or XTool.UObjIsNil(self.Target) then
        return
    end

    if not self.GameObject.activeInHierarchy then
        return
    end

    if not self.Target.gameObject.activeInHierarchy then
        self:Close()
        return
    end
    self._Control:SetViewPosToTransformLocalPosition(self.Transform, self.Target.transform, self.Offset, self.Pivot)
end

return XUiGridErrorHud
