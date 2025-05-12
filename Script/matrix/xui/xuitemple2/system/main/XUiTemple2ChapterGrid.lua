---@class XUiTemple2ChapterGrid : XUiNode
---@field _Control XTemple2Control
local XUiTemple2ChapterGrid = XClass(XUiNode, "XUiTemple2ChapterGrid")

function XUiTemple2ChapterGrid:OnStart()
    self._Data = false
    XUiHelper.RegisterClickEvent(self, self.BtnAbandon, self.OnClickGiveUp)
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick, true, 0.2)
end

---@param data XUiTemple2ChapterGridData
function XUiTemple2ChapterGrid:Update(data)
    self._Data = data
    --self.RImgChapter
    --self.ImgMask
    --self.BtnAbandon
    --self.PanelLock
    --self.TextLock
    --self.PanelOngoing
    --self.Normal
    self.Button:SetNameByGroup(0, data.Name)

    if data.IsOngoing then
        self.Button:SetButtonState(CS.UiButtonState.Normal)
        self.PanelOngoing.gameObject:SetActiveEx(true)
        return
    end

    if not data.IsUnlock then
        self.Button:SetButtonState(CS.UiButtonState.Disable)
        self.PanelOngoing.gameObject:SetActiveEx(false)
        return
    end

    self.Button:SetButtonState(CS.UiButtonState.Normal)
    self.PanelOngoing.gameObject:SetActiveEx(false)
end

function XUiTemple2ChapterGrid:OnClickGiveUp()
    self._Control:GetSystemControl():GiveUpOngoingStage(self._Data)
end

function XUiTemple2ChapterGrid:OnClick()
    self._Control:GetSystemControl():OpenStageDetail(self._Data)
end

return XUiTemple2ChapterGrid