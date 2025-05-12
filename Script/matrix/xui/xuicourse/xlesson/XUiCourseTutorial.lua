--关卡界面
local XUiCourseTutorial = XLuaUiManager.Register(XLuaUi,"UiCourseTutorial")
local XUiLessonChapter = require("XUi/XUiCourse/XLesson/XUiLessonChapter")
local XUiGridRewardItem = require("XUi/XUiCourse/XLesson/XUiGridRewardItem")
local XUiCourseAssetPanel = require("XUi/XUiCourse/XUiCourseAssetPanel")
local CourseLessonStagePrfab = CS.XGame.ClientConfig:GetString("CourseLessonStagePrfab")

function XUiCourseTutorial:OnAwake()
    self:AddButtonListenr()
    self.RewardUiTable = {}
    self.CurLessonStagePrefab = nil
end

function XUiCourseTutorial:OnStart(chapterId, defaultStageId)
    self.ChapterId = chapterId
    self.DefaultStageId = defaultStageId
    -- 资产
    -- XUiHelper.NewPanelActivityAsset( { XCourseConfig.GetPointItemId() }, self.PanelSpecialTool)
    self.PanelAsset = XUiCourseAssetPanel.New(self.PanelSpecialTool)
end

function XUiCourseTutorial:OnEnable()
    self:UpdateData()
    self:RefreshUi()
    XEventManager.AddEventListener(XEventId.EVENT_COURSE_DATA_NOTIFY, self.DataNotifyFunc, self)

    --策划调整为不自动领取
    --XDataCenter.CourseManager.CheckOpenFinishCourse(handler(self, self.CloseFinishCourseCb))
    XDataCenter.CourseManager.CheckOpenFinishCourse()
end

function XUiCourseTutorial:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_COURSE_DATA_NOTIFY, self.DataNotifyFunc, self)
end

function XUiCourseTutorial:CloseFinishCourseCb()
    self:Close()
    XDataCenter.CourseManager.CheckRewardAutoDrawByChapterId(self.ChapterId)
end

function XUiCourseTutorial:UpdateData()
    local chapterId = self.ChapterId
    self.CurPoint = XDataCenter.CourseManager.GetChapterCurPoint(chapterId)
    self.MaxPoint = XDataCenter.CourseManager.GetChapterMaxPoint(chapterId)
end

function XUiCourseTutorial:RefreshUi()
    self.PanelAsset:Refresh()
    self:RefreshTxt()
    self:RefreshStage()
    self:RefreshReward()
    self:CheckRewardRedDot()
    self:SelectDefaultStage()
end

function XUiCourseTutorial:RefreshTxt()
    self.TxtChapter.text = XCourseConfig.GetCourseChapterName(self.ChapterId)
end

function XUiCourseTutorial:RefreshStage()
    local data = {
        HideStageCb = handler(self, self.HideStageDetail),
        ShowStageCb = handler(self, self.ShowStageDetail),
        ChapterId = self.ChapterId,
    }
    if not self.LessonActivity then
        local gameObject = self.PanelChapter:LoadPrefab(CourseLessonStagePrfab)
        if gameObject == nil or not gameObject:Exist() then
            return
        end

        self.LessonActivity = XUiLessonChapter.New(gameObject, self)
        self.LessonActivity.Transform:SetParent(self.PanelChapter, false)
    end
    self.LessonActivity:Refresh(data, not XTool.IsNumberValid(self.DefaultStageId))
    self.LessonActivity:Show()
end

function XUiCourseTutorial:RefreshReward()
    self.ImgJindu.fillAmount = self.CurPoint / self.MaxPoint
    self.ImgLingqu.gameObject:SetActiveEx(XDataCenter.CourseManager.CheckRewardAllDraw(self.ChapterId))
    self.TxtStarNum.text = XUiHelper.GetText("Fract", self.CurPoint, self.MaxPoint)
end

function XUiCourseTutorial:SelectDefaultStage()
    if not XTool.IsNumberValid(self.DefaultStageId) then
        return
    end
    self.LessonActivity:SelectDefaultStage(self.DefaultStageId)
end

-- 关闭关卡详情
function XUiCourseTutorial:HideStageDetail()
    local closeFunc = function()
        if XLuaUiManager.IsUiShow("UiCourseStageDetailDP") then
            self:CloseChildUi("UiCourseStageDetailDP")
        end
    end
    -- 课程重温
    if XTool.IsNumberValid(self.DefaultStageId)
            and XLuaUiManager.IsUiLoad("UiCourseManagement") then
        self.DefaultStageId = nil
        local content = XCourseConfig.GetCourseClientConfig("ReturnPreStageTipsDesc").Values[2]
        XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), content, nil, closeFunc, function()
            --self:Close()
            self.Super.Close(self)
        end)
    else
        closeFunc()
    end
end

-- 开启关卡详情
function XUiCourseTutorial:ShowStageDetail(stageId)
    self.ChildUiCourseStageDetailDP:UpdateData(stageId)
    if XLuaUiManager.IsUiShow("UiCourseStageDetailDP") then
        self:CloseChildUi("UiCourseStageDetailDP")
    end
    self:OpenOneChildUi("UiCourseStageDetailDP", stageId)
end

-- 打开奖励
function XUiCourseTutorial:OpenReward()
    self:RefreshPanelReward()
    self.PanelTreasure.gameObject:SetActiveEx(true)
end

-- 关闭奖励
function XUiCourseTutorial:CloseReward()
    self.PanelTreasure.gameObject:SetActiveEx(false)
end

function XUiCourseTutorial:RefreshPanelReward()
    self.TxtTreasureTitle.text = XUiHelper.GetText("CourseGPARewardTitle")

    local courseRewardIdList = XCourseConfig.GetRewardIdListByChapterId(self.ChapterId)
    for i, courseRewardId in ipairs(courseRewardIdList) do
        if XTool.IsTableEmpty(self.RewardUiTable[courseRewardId]) then
            local grid = XUiGridRewardItem.New(XUiHelper.Instantiate(self.GridTreasureGrade, self.PanelGradeContent))
            grid.GameObject.name = string.format("%s%d", self.GridTreasureGrade.gameObject.name, i)
            self.RewardUiTable[courseRewardId] = grid
        end
        self.RewardUiTable[courseRewardId]:RefreshUi(courseRewardId, self.ChapterId)
    end
    self.GridTreasureGrade.gameObject:SetActiveEx(false)
end

function XUiCourseTutorial:CheckRewardRedDot()
    local chapterId = self.ChapterId
    self.ImgRedProgress.gameObject:SetActiveEx(XDataCenter.CourseManager.CheckChapterRewardReddot(chapterId))
end

function XUiCourseTutorial:DataNotifyFunc()
    self:RefreshReward()
    self:CheckRewardRedDot()
end

function XUiCourseTutorial:AddButtonListenr()
    self:BindExitBtns()
    self:RegisterClickEvent(self.BtnTreasure, self.OpenReward)
    self:RegisterClickEvent(self.BtnTreasureBg, self.CloseReward)
end

function XUiCourseTutorial:Close()
    if self.PanelTreasure.gameObject.activeSelf then
        self:CloseReward()
        return
    end
    
    if XLuaUiManager.IsUiShow("UiCourseStageDetailDP") then
        self.LessonActivity:CancelSelect()
        return
    end
    self.Super.Close(self)
end 