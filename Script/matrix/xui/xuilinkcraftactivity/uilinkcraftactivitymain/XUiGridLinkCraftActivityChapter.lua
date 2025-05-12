---@class XUiGridLinkCraftActivityChapter
---@field private _Control XLinkCraftActivityControl
local XUiGridLinkCraftActivityChapter = XClass(XUiNode,'XUiGridLinkCraftActivityChapter')

function XUiGridLinkCraftActivityChapter:OnStart(chapterId)
    self._ChapterId = chapterId
    --章节名称
    self.TxtTitle.text = self._Control:GetChapterNameById(self._ChapterId)
    --todo:根据配置设置底图？
    
    self.ChapterBtn.CallBack = handler(self,self.OnChapterClickEvent)
end

function XUiGridLinkCraftActivityChapter:Refresh()
    --解锁情况
    self._IsLock,self._LockDesc = XMVCA.XLinkCraftActivity:CheckChapterIsLockById(self._ChapterId)
    
    self.ChapterBtn:SetButtonState(self._IsLock and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    self.PanelRate.gameObject:SetActiveEx(not self._IsLock)

    if not self._IsLock then
        --更新通关进度
        self.TxtSchedule.text = self._Control:GetChapterScheduleDescById(self._ChapterId)
        self.PanelPassedLine2.fillAmount = self._Control:GetChapterSchedulePercentById(self._ChapterId)
        --显示章节新旧情况
        self.ChapterBtn:ShowReddot(XMVCA.XLinkCraftActivity:CheckChapterIsNewById(self._ChapterId))
    else
        if self.TxtLock then
            self.TxtLock.text = self._LockDesc
        end
    end
end

function XUiGridLinkCraftActivityChapter:OnChapterClickEvent()
    if not XTool.IsNumberValid(self._ChapterId) then
        return
    end
    if self._IsLock then
        XUiManager.TipMsg(self._LockDesc)
    else
        self._Control:SetCurChapterById(self._ChapterId)
        XLuaUiManager.Open('UiLinkCraftActivityChapter',self._ChapterId)
    end
end

return XUiGridLinkCraftActivityChapter