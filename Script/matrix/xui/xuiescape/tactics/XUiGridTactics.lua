---@class XUiGridTactics
local XUiGridTactics = XClass(nil, "XUiGridTactics")

function XUiGridTactics:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
    
    ---@type XEscapeTactics
    self._Tactics = false
    XUiHelper.RegisterClickEvent(self, self.RImgTacticsIcon, self.OnTacticsClick)
end

---@param tactics XEscapeTactics
function XUiGridTactics:Refresh(tactics)
    self._Tactics = tactics
    
    if self.RImgTacticsIcon and self._Tactics and not string.IsNilOrEmpty(self._Tactics:GetIcon()) then
        self.RImgTacticsIcon:SetRawImage(self._Tactics:GetIcon())
    end
end

function XUiGridTactics:SetActive(active)
    self.GameObject:SetActiveEx(active)
end

function XUiGridTactics:OnTacticsClick()
    if not self._Tactics then
        return
    end
    XUiManager.UiFubenDialogTip(self._Tactics:GetName(), self._Tactics:GetDesc())
end

return XUiGridTactics