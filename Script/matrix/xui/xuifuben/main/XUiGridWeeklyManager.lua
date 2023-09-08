local XUiGridWeeklyManager = XClass(nil, "XUiGridWeeklyManager")

---@class XUiGridWeeklyManager
function XUiGridWeeklyManager:Ctor(ui)
    self.Manager = nil
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnChapter, self.OnBtnChapterClicked)
end

---@param manager XExFubenBaseManager
function XUiGridWeeklyManager:SetData(manager)
    self.Manager = manager
    self.ImgRedDot.gameObject:SetActiveEx(manager:ExCheckIsShowRedPoint())
    self.PanelChapterComplete.gameObject:SetActiveEx(manager:ExCheckIsClear() and not manager:ExGetIsLocked()) -- 条件达成且不为上锁状态才显示Clear
    self.RImgChapter:SetRawImage(manager:ExGetIcon())
    self.TxtTitle.text = manager:ExGetName()
    self.TxtTips.text = manager:ExGetProgressTip()
    self.TxtTimeTips.text = manager:ExGetRunningTimeStr()
    self.PanelLock.gameObject:SetActiveEx()
    self.TxtLock.text = manager:ExGetLockTip()
    
    local locked = manager:ExGetIsLocked()
    self.PanelLock.gameObject:SetActiveEx(locked)
    self.TxtLock.gameObject:SetActiveEx(locked)
end

function XUiGridWeeklyManager:OnBtnChapterClicked()
    local chapterType
    if type(self.Manager.ExChapterType) == "number" then
        chapterType = self.Manager.ExChapterType
    elseif self.Manager.ExGetChapterType and type(self.Manager.ExGetChapterType) == "function" then
        chapterType = self.Manager:ExGetChapterType()
    end
    if not XMVCA.XSubPackage:CheckSubpackage(chapterType) then
        return
    end
    self.Manager:ExOpenMainUi()
end

function XUiGridWeeklyManager:RefreshTimeTips()
    self.TxtTimeTips.text = self.Manager:ExGetRunningTimeStr()
end

return XUiGridWeeklyManager