---@class XUiTheatre3GridFightResult : XUiNode
---@field _Control XTheatre3Control
---@field TxtNow UnityEngine.UI.Text
---@field ImgNow UnityEngine.UI.Image
---@field TxtPrev UnityEngine.UI.Text
---@field ImgPrev UnityEngine.UI.Image
---@field PanelNow UnityEngine.Transform
---@field PanelPrev UnityEngine.Transform
---@field PanelEmpty UnityEngine.Transform
local XUiTheatre3GridFightResult = XClass(XUiNode, "XUiTheatre3GridFightResult")

function XUiTheatre3GridFightResult:RefreshBySlotId(slotId)
    self:_Refresh(self._Control:GetAdventureFightResultBySlotId(slotId))
end

function XUiTheatre3GridFightResult:RefreshByEquipSuitId(slotId, equipSuitId)
    local baseAllNowValue, basePrevAllValue = self._Control:GetAdventureFightResultBySlotId(slotId)
    local nowValue, prevValue = self._Control:GetAdventureFightResultByEquipSuitId(slotId, equipSuitId)
    self:_Refresh(nowValue, prevValue, baseAllNowValue, basePrevAllValue)
end

function XUiTheatre3GridFightResult:_Refresh(nowValue, prevValue, baseNowValue, basePrevAllValue)
    if nowValue == 0 and prevValue == 0 then
        self.PanelNow.gameObject:SetActiveEx(false)
        self.PanelPrev.gameObject:SetActiveEx(false)
        self.PanelEmpty.gameObject:SetActiveEx(true)
        return
    end
    self.PanelNow.gameObject:SetActiveEx(true)
    self.PanelPrev.gameObject:SetActiveEx(true)
    self.PanelEmpty.gameObject:SetActiveEx(false)
    local allValue = nowValue + prevValue
    self.TxtNow.text = XUiHelper.GetText("Theatre3TxtFightResult", math.floor(nowValue / 10000))
    self.TxtPrev.text = XUiHelper.GetText("Theatre3TxtFightResult", math.floor(prevValue / 10000))
    self.ImgNow.fillAmount = nowValue / (baseNowValue and baseNowValue or allValue)
    self.ImgPrev.fillAmount = prevValue / (basePrevAllValue and basePrevAllValue or allValue)
end

return XUiTheatre3GridFightResult