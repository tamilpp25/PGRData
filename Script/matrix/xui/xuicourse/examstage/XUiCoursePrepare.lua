local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local MAX_STAR_COUNT
local XUiCourseAssetPanel = require("XUi/XUiCourse/XUiCourseAssetPanel")
--战斗执照-关卡说明弹窗
local XUiCoursePrepare = XLuaUiManager.Register(XLuaUi, "UiCoursePrepare")

function XUiCoursePrepare:OnAwake()
    self:RegisterButtonEvent()
    --self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XCourseConfig.GetPointItemId())
end

function XUiCoursePrepare:OnStart(pcCloseCb)
    self.PcCloseCb = pcCloseCb
    --self.JumpStageCb = jumpStageCb  --跳转至课程关卡关卡回调
    self.PanelAsset = XUiCourseAssetPanel.New(self.PanelAsset)
end

function XUiCoursePrepare:PcClose()
    if self.PcCloseCb then
        self.PcCloseCb()
    end
end

function XUiCoursePrepare:OnEnable()
    self:Refresh()
end

function XUiCoursePrepare:UpdateData(stageId, chapterId)
    self.StageId = stageId
    self.ChapterId = chapterId
end

function XUiCoursePrepare:Refresh()
    self.PanelAsset:Refresh()
    local stageId = self.StageId
    local chapterId = self.ChapterId

    --标题和提示
    self.TextName.text = XCourseConfig.GetCourseChapterName(chapterId)
    self.TxtTitle.text = XFubenConfigs.GetStageName(stageId)
    self.TexBecareful.text = XDataCenter.FubenManager.GetStageDes(stageId)

    --目标
    local grid, panelUnActive, panelActive, txtUnActive, txtActive
    local starDesc = XFubenConfigs.GetStarDesc(stageId)
    local flagMap = XDataCenter.CourseManager.GetStageStarsFlagMap(stageId)
    for index, desc in ipairs(starDesc) do
        grid = self["GridStageStar" .. index]
        if grid then
            panelActive = XUiHelper.TryGetComponent(grid.transform, "PanelActive")
            panelUnActive = XUiHelper.TryGetComponent(grid.transform, "PanelUnActive")
            txtActive = XUiHelper.TryGetComponent(panelActive.transform, "TxtActive", "Text")
            txtUnActive = XUiHelper.TryGetComponent(panelUnActive.transform, "TxtUnActive", "Text")
            txtActive.text = desc
            txtUnActive.text = desc
            panelActive.gameObject:SetActiveEx(flagMap[index])
            panelUnActive.gameObject:SetActiveEx(not flagMap[index])
            grid.gameObject:SetActiveEx(true)
        end
    end
    --隐藏多余的控件
    local index = #starDesc + 1
    grid = self["GridStageStar" .. index]
    while not XTool.UObjIsNil(grid) do
        grid.gameObject:SetActiveEx(false)
        index = index + 1
        grid = self["GridStageStar" .. index]
    end

    --前置关卡
    self.LessonStageId = XCourseConfig.GetCourseLessonStageIdById(stageId)
    local isHaveLessonStage = XTool.IsNumberValid(self.LessonStageId)
    self.TextPreStageName.text = isHaveLessonStage and XFubenConfigs.GetStageName(self.LessonStageId) or ""
    self.TextPreStageTitle.gameObject:SetActiveEx(isHaveLessonStage)
    local chapterIsOpen, stageIsOpen
    if isHaveLessonStage then
        local lessonChapterId = XCourseConfig.GetChapterIdByStageId(self.LessonStageId)
        chapterIsOpen = XDataCenter.CourseManager.CheckChapterIsOpen(lessonChapterId)
        stageIsOpen = XDataCenter.CourseManager.CheckStageIsOpen(self.LessonStageId)
    end
    self.BtnReceive.gameObject:SetActiveEx(isHaveLessonStage and chapterIsOpen and stageIsOpen)
end

function XUiCoursePrepare:RegisterButtonEvent()
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
    self:RegisterClickEvent(self.BtnReceive, self.OnBtnReceiveClick)
    self:RegisterClickEvent(self.BtnAutoFight, self.OnBtnAutoFightClick)
end

--跳转至前置关卡
function XUiCoursePrepare:OnBtnReceiveClick()
    --local title = XUiHelper.GetText("TipTitle")
    --local content = XCourseConfig.GetCourseClientConfig("ReturnPreStageTipsDesc").Values[1]
    --local sureCallback = function()
    --    --self:Close()
    --    --if self.JumpStageCb then
    --    --    self.JumpStageCb(self.LessonStageId)
    --    --end
    --    
    --end
    --XUiManager.DialogTip(title, content, nil, nil, sureCallback)
    XLuaUiManager.Open("UiCourseTutorial", XCourseConfig.GetChapterIdByStageId(self.LessonStageId), self.LessonStageId)
end

--进入战斗编队界面
function XUiCoursePrepare:OnBtnEnterClick()
    XLuaUiManager.Open("UiBattleRoleRoom", self.StageId)
end

--首通奖励界面
function XUiCoursePrepare:OnBtnAutoFightClick()
    XLuaUiManager.Open("UiCourseObtain", self.StageId)
end 