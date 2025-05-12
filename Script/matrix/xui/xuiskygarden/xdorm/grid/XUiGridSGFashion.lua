---@class XUiGridSGFashion : XUiNode
---@field _Control XSkyGardenDormControl
---@field Parent XUiSkyGardenDormCoating
local XUiGridSGFashion = XClass(XUiNode, "XUiGridSGFashion")

function XUiGridSGFashion:OnStart()
    self:InitUi()
    self:InitCb()
end

function XUiGridSGFashion:Refresh(fashionId, selectId)
    self._Id = fashionId
    self.TxtName.text = self._Control:GetFashionName(fashionId)
    self.PanelSelect.gameObject:SetActiveEx(fashionId == selectId)
    self.PanelNow.gameObject:SetActiveEx(self._Control:IsCurrentFashionId(fashionId))
    self._IsUnlock = self._Control:IsFashionUnlock(fashionId)
    self.PanelDisable.gameObject:SetActiveEx(not self._IsUnlock)

    self.RImgIcon:SetRawImage(self._Control:GetFashionIcon(fashionId))
    
    self:Open()
end

function XUiGridSGFashion:InitUi()
    self.UiBigWorldRed.gameObject:SetActiveEx(false)
    self._IsSelect = false
end

function XUiGridSGFashion:InitCb()
end

function XUiGridSGFashion:OnBtnClick()
    if not self._IsUnlock then
        XUiManager.TipMsg(self._Control:GetFashionLockDesc(self._Id))
    end
    if self._IsSelect then
        return
    end
    self.PanelSelect.gameObject:SetActiveEx(true)
    self._IsSelect = true
    self.Parent:OnSelectFashion(self._Id, self)
end

function XUiGridSGFashion:CancelSelect()
    self._IsSelect = false
    self.PanelSelect.gameObject:SetActiveEx(false)
end

return XUiGridSGFashion