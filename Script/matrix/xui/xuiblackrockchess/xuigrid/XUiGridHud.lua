
---@class XUiGridHud : XUiNode Hud界面
---@field _Control XBlackRockChessControl
---@field Transform UnityEngine.Transform
local XUiGridHud = XClass(XUiNode, "XUiGridHud")

local CsVector3One = CS.UnityEngine.Vector3.one

function XUiGridHud:BindTarget(target, offset, ...)
    self.Pivot = self.Pivot or CS.UnityEngine.Vector2(0.5, 0.5)
    self.Target = target
    self.Offset = offset or CS.UnityEngine.Vector3.zero
end

function XUiGridHud:ChangeOffset(offset)
    self.Offset = offset
end

function XUiGridHud:UpdateTransform()
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

function XUiGridHud:OnEnable()
    self:RefreshView()
end

function XUiGridHud:SetScale(scale)
    self.Transform.localScale = CsVector3One * scale
end

function XUiGridHud:OnDestroy()
    self.Target = nil
end

function XUiGridHud:OnGetLuaEvents()
    return {
        XEventId.EVENT_BLACK_ROCK_CHESS_ROUND_CHANGE
    }
end

function XUiGridHud:OnNotify(evt)
    if evt == XEventId.EVENT_BLACK_ROCK_CHESS_ROUND_CHANGE then
        return self:RefreshView()
    end
end

function XUiGridHud:RefreshView()
end

return XUiGridHud