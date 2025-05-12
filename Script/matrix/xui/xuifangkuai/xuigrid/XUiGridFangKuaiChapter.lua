---@class XUiGridFangKuaiChapter : XUiNode
---@field Parent XUiFangKuaiMain
---@field _Control XFangKuaiControl
local XUiGridFangKuaiChapter = XClass(XUiNode, "XUiGridFangKuaiChapter")

function XUiGridFangKuaiChapter:OnStart(chapter)
    ---@type XTableFangKuaiChapter
    self._Chapter = chapter
    XUiHelper.RegisterClickEvent(self, self.GridChapter, self.OnClickChapter)
end

function XUiGridFangKuaiChapter:Update()
    self._IsPlaying = self._Control:IsChapterPlaying(self._Chapter.Id)
    self._IsUnlock, self._CondStr = self._Control:IsChapterTimeUnlock(self._Chapter.Id)

    --self.GridChapter:SetRawImage(self._Chapter.Icon)
    self.GridChapter:SetButtonState(self._IsUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.TxtCondition.text = self._CondStr

    self.PanelOngoing.gameObject:SetActiveEx(self._IsPlaying)
    --self.Effect.gameObject:SetActiveEx(self._IsPlaying)
    self.TxtName.text = self._IsUnlock and self._Chapter.Name or ""

    local isRed = self._Control:CheckChapterRedPoint(self._Chapter.Id)
    self.GridChapter:ShowReddot(isRed)
end

function XUiGridFangKuaiChapter:OnClickChapter()
    if not self._IsUnlock then
        XUiManager.TipError(self._CondStr)
        return
    end
    XLuaUiManager.Open("UiFangKuaiChapter", self._Chapter.Id)
end

return XUiGridFangKuaiChapter