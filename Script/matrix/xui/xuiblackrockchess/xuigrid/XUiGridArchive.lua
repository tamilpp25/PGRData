---@class XUiGridArchive : XUiNode
local XUiGridArchive = XClass(XUiNode, "XUiGridArchive")

function XUiGridArchive:OnStart()
    XUiHelper.RegisterClickEvent(self, self.StoryBtn, self.OnClickStory)
end

---@param data XTableBlackRockChessArchive
function XUiGridArchive:UpdateGrid(data)
    self._Data = data
    self._IsUnlock = XConditionManager.CheckCondition(data.Condition)
    self.StoryImg:SetRawImage(data.Icon)
    self.StoryTitle.text = data.Name
    self.TxtUnlock.text = data.UnlockTip
    self.PanelLock.gameObject:SetActiveEx(not self._IsUnlock)
    
    self.LockTip = data.UnlockTip
end

function XUiGridArchive:OnClickStory()
    if self._IsUnlock then
        XLuaUiManager.Open("UiBlackRockChessArchiveDialog", self._Data)
    else
        XUiManager.TipMsg(self.LockTip)
    end
end

return XUiGridArchive