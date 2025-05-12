---@class XUiTopClickCloseArea : XLuaUi
---@field ClickArea XUiComponent.XUiButton
local XUiTopClickCloseArea = XLuaUiManager.Register(XLuaUi, "UiTopClickCloseArea")

--region 生命周期
function XUiTopClickCloseArea:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiTopClickCloseArea:OnStart(targetTransform, cb)
    self._CloseCallback = cb

    self._TargetTransform = targetTransform
    self._LastSiblingIndex = targetTransform:GetSiblingIndex()
    self._TransformParent = targetTransform.parent

    targetTransform:SetParent(self.Transform)
end

function XUiTopClickCloseArea:OnDestroy()
    self._CloseCallback = nil
    self._TargetTransform = nil
    self._LastSiblingIndex = nil
    self._TransformParent = nil
end
--endregion

--region 按钮事件
function XUiTopClickCloseArea:OnClickAreaClick()
    self._TargetTransform:SetParent(self._TransformParent)
    self._TargetTransform:SetSiblingIndex(self._LastSiblingIndex)

    if self._CloseCallback then self._CloseCallback() end
    self:Close()
end

--endregion

--region 私有方法
function XUiTopClickCloseArea:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.ClickArea.CallBack = function() self:OnClickAreaClick() end
end
--endregion

return XUiTopClickCloseArea
