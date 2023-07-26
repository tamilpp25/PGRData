--已完成课程弹窗
local XUiCourseFinishCourse = XLuaUiManager.Register(XLuaUi,"UiCourseFinishCourse")

function XUiCourseFinishCourse:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnStand, self.Close)
end

-- @chapterId: 当前完成的章节
function XUiCourseFinishCourse:OnStart(chapterId, closeCb)
    self.ChapterId = chapterId
    self.CloseCb = closeCb
    self.TxtTitle.text = string.format(XCourseConfig.GetCourseOrExamFinishTips(1), XCourseConfig.GetCourseChapterName(chapterId))
    self.TextTips.text = XCourseConfig.GetCourseOrExamFinishTips(2)
end

function XUiCourseFinishCourse:OnEnable()
end

function XUiCourseFinishCourse:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end