local XUiGridWeeklyManager = XClass(nil, "XUiGridWeeklyManager")
local XUiBtnDownload = require("XUi/XUiDlcDownload/XUiBtnDownload")

---@class XUiGridWeeklyManager
function XUiGridWeeklyManager:Ctor(ui)
    self.Manager = nil
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnChapter, self.OnBtnChapterClicked)
    ---@type XUiBtnDownload
    self.GirdBtnDownload = XUiBtnDownload.New(self.BtnDownload)
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
    
    self.GirdBtnDownload:Init(XDlcConfig.EntryType.Challenge, self.Manager:ExGetChapterType(), nil, handler(self, self.OnDownloadComplete))
    self.GirdBtnDownload:RefreshView()
    
    local locked = manager:ExGetIsLocked()
    self.PanelLock.gameObject:SetActiveEx(locked or self.GirdBtnDownload:CheckNeedDownload())
    self.TxtLock.gameObject:SetActiveEx(locked)
end

function XUiGridWeeklyManager:OnBtnChapterClicked()
    if self.GirdBtnDownload:CheckNeedDownload() then
        self.GirdBtnDownload:OnBtnClick()
        return
    end
    self.Manager:ExOpenMainUi()
end

function XUiGridWeeklyManager:RefreshTimeTips()
    self.TxtTimeTips.text = self.Manager:ExGetRunningTimeStr()
end

function XUiGridWeeklyManager:OnDownloadComplete()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    local locked = self.Manager:ExGetIsLocked()
    self.PanelLock.gameObject:SetActiveEx(locked or self.GirdBtnDownload:CheckNeedDownload())
    self.TxtLock.gameObject:SetActiveEx(locked)
end

return XUiGridWeeklyManager