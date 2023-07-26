--战斗执照-执照说明弹窗
local XUiCourseB4Tips = XLuaUiManager.Register(XLuaUi, "UiCourseB4Tips")
local MAX_TEXT_COUNT = 3    --最大文本数量

function XUiCourseB4Tips:OnAwake()
    self:RegisterButtonEvent()
end

function XUiCourseB4Tips:OnStart(chapterId, closeCb)
    self.ChapterId = chapterId
    self.CloseCb = closeCb

    local chapterIsOpen = XDataCenter.CourseManager.CheckChapterIsOpen(chapterId)
    local lockColor, unlockColor = XCourseConfig.GetChapterTipsDescColor()

    --标题
    self.TextTitle.text = XCourseConfig.GetCourseChapterName(chapterId)

    --参与条件
    self.TextUnlockTitle.text = XCourseConfig.GetCourseClientConfig("ExamChapterTipsPanelTitle").Values[1]
    local unlockLessonPoint = XCourseConfig.GetCourseChapterUnlockLessonPoint(chapterId)
    local prevChapterIdList = XCourseConfig.GetCourseChapterPrevChapterId(chapterId)
    local lessonPointDesc, prevChapterDesc = XCourseConfig.GetChapterTipsUnlockDesc()
    local txtObj, desc, isActive, color, imgGou, line
    for i = 1, MAX_TEXT_COUNT do
        isActive = true
        txtObj = self["TxtUnlock" .. i]
        imgGou = self["ImgGou" .. i]
        line = self["UnlockLine" .. i]

        if i == 1 then
            --条件1：解锁需要总课程绩点
            desc = string.format(lessonPointDesc, unlockLessonPoint)
            color = XDataCenter.CourseManager.IsChapterUnlockPoint(chapterId) and unlockColor or lockColor
        elseif XTool.IsNumberValid(prevChapterIdList[i - 1]) then
            local chapterName = XCourseConfig.GetCourseChapterName(prevChapterIdList[i - 1])
            desc = string.format(prevChapterDesc, chapterName)
            color = XDataCenter.CourseManager.IsChapterUnlockPrevChapter(chapterId, i - 1) and unlockColor or lockColor
        else
            isActive = false
        end
        
        txtObj.text = desc or ""
        if color then
            txtObj.color = color
            imgGou.color = color
        end
        txtObj.gameObject:SetActiveEx(isActive)
        if line then
            line.gameObject:SetActiveEx(isActive)
        end
    end

    --考试科目
    self.TextStageTitle.text = XCourseConfig.GetCourseClientConfig("ExamChapterTipsPanelTitle").Values[2]
    local stageIdList = XCourseConfig.GetCourseChapterStageIdsById(chapterId)
    local txtStageNumber, txtStageProgress, stageId, starPointList
    for i = 1, MAX_TEXT_COUNT do
        isActive = true
        txtObj = self["TxtStage" .. i]
        txtStageNumber = self["TxtStageNumber" .. i]
        txtStageProgress = self["TxtStageProgress" .. i]
        stageId = stageIdList[i]
        starPointList = XCourseConfig.GetCourseStageStarPointById(stageId)
        
        if XTool.IsNumberValid(stageId) then
            desc = XFubenConfigs.GetStageName(stageId, true)
            txtStageNumber.text = string.format("%d/%d", XDataCenter.CourseManager.GetStageStarsCount(stageId), #starPointList)
        else
            isActive = false
        end

        txtObj.text = desc or ""
        if color then
            txtObj.color = color
            txtStageNumber.color = color
            txtStageProgress.color = color
        end
        txtObj.gameObject:SetActiveEx(isActive)
    end

    --通过条件
    self.TextClearTitle.text = XCourseConfig.GetCourseClientConfig("ExamChapterTipsPanelTitle").Values[3]
    local clearDesc = XCourseConfig.GetCourseClientConfig("ExamChapterTipsClearPointDesc").Values[1]
    local clearPoint = XCourseConfig.GetCourseChapterClearPoint(chapterId)
    self.TxtCumulativeAcquisition.text = string.format(clearDesc, clearPoint)

    --按钮名
    local btnUnlockName, btnLockName = XCourseConfig.GetChapterTipsBtnName()
    self.BtnOpenChapter:SetName(chapterIsOpen and btnUnlockName or btnLockName)
    self.BtnOpenChapter:SetDisable(not chapterIsOpen, chapterIsOpen)
end

function XUiCourseB4Tips:OnEnable()

end

function XUiCourseB4Tips:OnDisable()

end

function XUiCourseB4Tips:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiCourseB4Tips:RegisterButtonEvent()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnFullClose, self.Close)
    self.BtnOpenChapter.CallBack = handler(self, self.OnBtnOpenChapterClick)
end

function XUiCourseB4Tips:OnBtnOpenChapterClick()
    XLuaUiManager.Open("UiCourseManagement", self.ChapterId)
end