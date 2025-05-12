local XUiTransfiniteUtil = {}

---@param ui XLuaUi
function XUiTransfiniteUtil.HideEffectHuan(ui)
    local uiFarRootObj = ui.UiModel.UiFarRoot
    local effectHuan = XUiHelper.TryGetComponent(uiFarRootObj, "FxUiTransfinite3dHuan", "Transform")
    if effectHuan then
        effectHuan.gameObject:SetActiveEx(false)
    end
end

return XUiTransfiniteUtil