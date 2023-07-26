-- 章节格子
-- ================================================================================
local XUiGridChapter = XClass(nil, "XUiGridChapter")
function XUiGridChapter:Ctor(ui, rootUi)
    self.Ui = ui
    self.GameObject = ui.gameObject
    self.RootUi = rootUi
    XUiHelper.InitUiClass(self, self.Ui)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XUiGridChapter:Refresh(chapterId, isHaveNextGrid)
    self.ChapterId = chapterId
    local normalBg = XCourseConfig.GetLessonChapterGridNormalBg(chapterId)
    self.RImgBg:SetRawImage(normalBg)
    self.RootUi:SetUiSprite(self.ImgNum, XCourseConfig.GetLessonChapterImgNum(chapterId))
    self.TxtName.text = XCourseConfig.GetCourseChapterName(chapterId)
    --绩点进度
    local curPoint = XDataCenter.CourseManager.GetChapterCurPoint(chapterId)
    local maxPoint = XDataCenter.CourseManager.GetChapterMaxPoint(chapterId)
    self.TxtPointNum.text = string.format("%d/%d", curPoint, maxPoint)
    --绩点图标
    self.RImgIcon:SetRawImage(XItemConfigs.GetItemIconById(XCourseConfig.GetPointItemId()))
    --连接下一个章节的线
    self.PanelXian.gameObject:SetActiveEx(isHaveNextGrid)
    --未解锁
    local isOpen = XDataCenter.CourseManager.CheckChapterIsOpen(chapterId)
    self.PanelDisable.gameObject:SetActiveEx(not isOpen)
    self.TxtSuo.text = XCourseConfig.GetCourseChapterLockDesc(chapterId)
    --通关状态
    local isMaxPointClear = XDataCenter.CourseManager.CheckChapterIsMaxPointClear(chapterId)
    local isClear = XDataCenter.CourseManager.CheckChapterIsComplete(chapterId)
    local isStarting = XDataCenter.CourseManager.IsChapterStarting(chapterId)
    self.TxtGraduate.gameObject:SetActiveEx(isClear and not isMaxPointClear)
    self.TxtProceed.gameObject:SetActiveEx(not (isMaxPointClear or isClear) and isStarting)
    self.CommonFuBenClear.gameObject:SetActiveEx(isClear and isMaxPointClear)
    --检查红点
    self.Red.gameObject:SetActiveEx(XDataCenter.CourseManager.CheckCourseChapterReddot(chapterId))

    self:SetActive(true)
end

function XUiGridChapter:OnBtnClick()
    local chapterId = self.ChapterId
    if XDataCenter.CourseManager.CheckCourseChapterReddot(chapterId) then
        XDataCenter.CourseManager.SetCatchReddotData(chapterId)
        --self.Red.gameObject:SetActiveEx(false)
    end
    XLuaUiManager.Open("UiCourseIntroduce", self.ChapterId)
end

function XUiGridChapter:SetActive(isAcitve)
    self.GameObject:SetActiveEx(isAcitve)
end


-- 课程主界面-章节布局
-- ================================================================================
local XUiCourseMainPanel = XClass(nil, "XUiCourseMainPanel")

function XUiCourseMainPanel:Ctor(ui, rootUi)
    self.Ui = ui
    self.Transform = ui.transform
    self.RootUi = rootUi
    XUiHelper.InitUiClass(self, self.Ui)
    self.GridChapters = {}
    self.GridLevel.gameObject:SetActiveEx(false)
end

function XUiCourseMainPanel:Refresh(chapterGroupId, index)
    local chapterIds = XDataCenter.CourseManager.CheckChapterGroupIsOpen(chapterGroupId) and XCourseConfig.GetChapterIds(chapterGroupId) or {}
    local totalChapter = #chapterIds
    for index, chapterId in ipairs(chapterIds) do
        if not self.GridChapters[index] then
            local grid = index == 1 and self.GridLevel or XUiHelper.Instantiate(self.GridLevel, self.Transform)
            self.GridChapters[index] = XUiGridChapter.New(grid, self.RootUi)
        end
        self.GridChapters[index]:Refresh(chapterId, index < totalChapter)
    end

    for i = totalChapter + 1, #self.GridChapters do
        if self.GridChapters[i] then
            self.GridChapters[i]:SetActive(false)
        end
    end
end

return XUiCourseMainPanel