---@class XUiGridSelectTactics
local XUiGridSelectTactics = XClass(nil, "XUiGridSelectTactics")

function XUiGridSelectTactics:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XUiHelper.InitUiClass(self, ui)

    ---@type XEscapeTactics
    self._Tactics = false
    XUiHelper.RegisterClickEvent(self, self.BtnReceive, self.OnBtnReceiveClick)
end

---@param tactics XEscapeTactics
function XUiGridSelectTactics:Refresh(tactics, layerId, tacticsNodeId)
    self._Tactics = tactics
    self._LayerId = layerId
    self._TacticsNodeId = tacticsNodeId

    self.TxtTacticsName.text = self._Tactics:GetName()
    self.TxtTacticsExplain.text = self._Tactics:GetDesc()
    if self.RImgIcon and self._Tactics and not string.IsNilOrEmpty(self._Tactics:GetIcon()) then
        self.RImgIcon:SetRawImage(self._Tactics:GetIcon())
    end
end

function XUiGridSelectTactics:SetActive(active)
    self.GameObject:SetActiveEx(active)
end

function XUiGridSelectTactics:OnBtnReceiveClick()
    XDataCenter.EscapeManager.RequestEscapeSelectTactics(self._LayerId, self._TacticsNodeId, self._Tactics:GetId(), function()
        self.RootUi:Close()
    end)
end

return XUiGridSelectTactics