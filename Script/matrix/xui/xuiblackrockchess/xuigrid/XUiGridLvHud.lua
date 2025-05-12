---@class XUiGridLvHud : XUiNode
---@field Parent XUiBlackRockChessComponent
---@field _Control XBlackRockChessControl
local XUiGridLvHud = XClass(XUiNode, "XUiGridLvHud")

local CsVector3One = CS.UnityEngine.Vector3.one

function XUiGridLvHud:OnStart()

end

function XUiGridLvHud:OnEnable()
    self:RefreshView()
end

function XUiGridLvHud:OnDestroy()
    self.Target = nil
end

function XUiGridLvHud:SetScale(scale)
    self.Transform.localScale = CsVector3One * scale
end

function XUiGridLvHud:BindTarget(target, offset, pieceId)
    self.PieceId = pieceId
    self.Pivot = self.Pivot or CS.UnityEngine.Vector2(0.5, 0.5)
    self.Target = target
    self.Offset = offset or CS.UnityEngine.Vector3.zero
    self.Config = self._Control:GetPartnerPieceById(pieceId)
end

function XUiGridLvHud:RefreshView()
    if not self.Config then
        return
    end
    XUiHelper.RefreshCustomizedList(self.GridStar.parent, self.GridStar, self.Config.Level)
end

function XUiGridLvHud:UpdateTransform()
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

return XUiGridLvHud
