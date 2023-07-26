local Normal = CS.UiButtonState.Normal
local Disable = CS.UiButtonState.Disable

--战斗执照主界面章节格子
local XUiChapterPanelGrid = XClass(nil, "XUiChapterPanelGrid")

function XUiChapterPanelGrid:Ctor(ui, parent, clickCb, closeCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.Parent = parent
    self.ClickCb = clickCb
    self.CloseCb = closeCb
    self:SetSelectStatus(false)
    XUiHelper.RegisterClickEvent(self, self.BtnOpenChapter, handler(self, self.OnBtnOpenChapterClicked))
end

--chapterId: CourseChapter表的Id
function XUiChapterPanelGrid:Refresh(chapterId)
    self.ChapterId = chapterId
    --是否通关
    local isClear = XDataCenter.CourseManager.CheckChapterIsComplete(chapterId)
    self.CommonFuBenClear.gameObject:SetActiveEx(isClear)
    --背景
    local normalBg = XCourseConfig.GetExamChapterGridNormalBg(chapterId)
    local disableBg = XCourseConfig.GetExamChapterGridDisableBg(chapterId)
    self.Normal:SetRawImage(normalBg)
    self.Disable:SetRawImage(disableBg)
    --未解锁文本
    self.TxtCondition.text = XCourseConfig.GetCourseClientConfig("ChapterLockDesc").Values[1]
    --是否解锁
    local isUnLock = XDataCenter.CourseManager.CheckChapterIsOpen(chapterId)
    self.BtnOpenChapter:SetButtonState(isUnLock and Normal or Disable)
    --红点
    self.BtnOpenChapter:ShowReddot(XDataCenter.CourseManager.CheckCourseChapterReddot(chapterId))
end

function XUiChapterPanelGrid:SetSelectStatus(value)
    self.Select.gameObject:SetActiveEx(value)
end

function XUiChapterPanelGrid:OnBtnOpenChapterClicked()
    local chapterId = self.ChapterId
    if XDataCenter.CourseManager.CheckCourseChapterReddot(chapterId) then
        XDataCenter.CourseManager.SetCatchReddotData(chapterId)
        --self.BtnOpenChapter:ShowReddot(false)
    end

    self:SetSelectStatus(true)
    XLuaUiManager.Open("UiCourseB4Tips", self.ChapterId, function()
        self:SetSelectStatus(false)
        if self.CloseCb then
            self.CloseCb()
        end
    end)

    if self.ClickCb then
        self.ClickCb(self)
    end
end

function XUiChapterPanelGrid:GetChapterId()
    return self.ChapterId
end

function XUiChapterPanelGrid:GetParentLocalPosY()
    return self.Parent.localPosition.y
end

return XUiChapterPanelGrid