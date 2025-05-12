local XUiDlcMultiPlayerTitleCommon = require(
    "XUi/XUiDlcMultiPlayer/XUiDlcMultiPlayerCommon/XUiDlcMultiPlayerTitleCommon")

---@class XUiDlcMultiPlayerTitleGrid : XUiNode
---@field ImgRoleSelect UnityEngine.RectTransform
---@field PanelNow UnityEngine.RectTransform
---@field Red UnityEngine.RectTransform
---@field ImgLock UnityEngine.UI.RawImage
---@field TitleGrid UnityEngine.RectTransform
---@field TitleEffect UnityEngine.RectTransform
local XUiDlcMultiPlayerTitleGrid = XClass(XUiNode, "XUiDlcMultiPlayerTitleGrid")

--region 生命周期

function XUiDlcMultiPlayerTitleGrid:OnStart()
    self._Title = nil
    self._TitleGrid = nil
end

--endregion

---@param title XDlcMultiplayerTitle
function XUiDlcMultiPlayerTitleGrid:Refresh(title, isSelect)
    self._Title = title
    self._TitleGrid = XUiDlcMultiPlayerTitleCommon.New(self.TitleGrid, self, title:GetId())
    self.TitleEffect.gameObject:SetActiveEx(isSelect)
    self.PanelNow.gameObject:SetActiveEx(title:GetIsWear())
    self.ImgLock.gameObject:SetActiveEx(not title:GetIsUnlock())
    self:OnTouched(isSelect)
end

function XUiDlcMultiPlayerTitleGrid:OnTouched(isSelect)
    if isSelect and self._Title then
        self._Title:ChangeFirstUnlock()
    end
    self.Red.gameObject:SetActiveEx(self._Title:GetIsFirstUnlock())
    self.ImgRoleSelect.gameObject:SetActiveEx(isSelect)
end

return XUiDlcMultiPlayerTitleGrid
