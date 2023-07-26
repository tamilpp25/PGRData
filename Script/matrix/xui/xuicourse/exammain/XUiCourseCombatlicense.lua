local XUiChapterPanel = require("XUi/XUiCourse/ExamMain/XUiChapterPanel")
local XUiRewardGrid = require("XUi/XUiCourse/ExamMain/XUiRewardGrid")
local XUiCourseAssetPanel = require("XUi/XUiCourse/XUiCourseAssetPanel")
local STAGE_TYPE = XCourseConfig.SystemType.Exam

local CSMathf = CS.UnityEngine.Mathf

--战斗执照主界面
local XUiCourseCombatlicense = XLuaUiManager.Register(XLuaUi, "UiCourseCombatlicense")

function XUiCourseCombatlicense:OnAwake()
    self.CourseData = XDataCenter.CourseManager.GetCourseData()
    
    self.ImgBgList = {}
    self:InitButtonCallBack()
    self:InitPanelChapter()
    self:InitRewardList()
end

function XUiCourseCombatlicense:OnStart()
    self:InitImgBgSize()
    self:InitImgBgList()
    
    -- 资产
    -- XUiHelper.NewPanelActivityAsset( { XCourseConfig.GetPointItemId() }, self.PanelSpecialTool)
    self.PanelAsset = XUiCourseAssetPanel.New(self.PanelSpecialTool)
    -- 红点监听
    XDataCenter.CourseManager.AddDataUpdataListener(function() self:CheckRedPoint() end, self)
end

function XUiCourseCombatlicense:OnEnable()
    XUiCourseCombatlicense.Super.OnEnable(self)
    --self.UpdateImgBgPosSchedule = XScheduleManager.ScheduleForeverEx(handler(self, self.UpdateImgBgPos), 0, 0)
    self:InitImgBgList()
    self:Refresh()
    self:CheckRedPoint()
end

function XUiCourseCombatlicense:OnDisable()
    XUiCourseCombatlicense.Super.OnDisable(self)
    --if self.UpdateImgBgPosSchedule then
    --    XScheduleManager.UnSchedule(self.UpdateImgBgPosSchedule)
    --    self.UpdateImgBgPosSchedule = nil
    --end
    self:RemoveMoveAnimaTimer()
end

function XUiCourseCombatlicense:RemoveMoveAnimaTimer()
    if self.MoveAnimaTimer then
        XScheduleManager.UnSchedule(self.MoveAnimaTimer)
        self.MoveAnimaTimer = nil
    end
end

--更新背景位置
local Offset
function XUiCourseCombatlicense:UpdateImgBgPos()
    if XTool.UObjIsNil(self.PanelStageContent) or 
        XTool.UObjIsNil(self.PanelBg) then
        return
    end
    local contentSize = self.PanelStageContent.sizeDelta
    local tmpOffset = self.PanelStageContent.anchoredPosition - Offset
    tmpOffset.y = CSMathf.Clamp(tmpOffset.y, -contentSize.x, 0)
    self.PanelBg.anchoredPosition = tmpOffset
end

function XUiCourseCombatlicense:InitRewardList()
    --self.CourseRewardIdList = XCourseConfig.GetCourseRewardIdList(STAGE_TYPE)
    self.CourseRewardIdList = XCourseConfig.GetChapterIdListByStageType(STAGE_TYPE)
    self.UiReformTaskGrids = {}
    XUiHelper.RefreshCustomizedList(self.PanelGift, self.PanelActive, #self.CourseRewardIdList, function(index, go)
        self.UiReformTaskGrids[index] = XUiRewardGrid.New(go, self)
        self.UiReformTaskGrids[index]:SetData(self.CourseRewardIdList[index])
    end)
end

function XUiCourseCombatlicense:InitImgBgSize()
    self.ImgBgRectSize = self.RImgBg:GetComponent("RectTransform").rect.size
    self.RectSize = self.Ui.GameObject:GetComponent("RectTransform").rect.size
    self.ImgBgHeightLerp = (self.ImgBgRectSize.y - self.RectSize.y) / 2 --锚点在中心
end

function XUiCourseCombatlicense:InitChapterBgCount()
    self.ChapterBgCount = math.ceil(#self.ChapterGroupIdList / 2) --每隔2个章节设置一张背景
end

function XUiCourseCombatlicense:InitPanelChapter()
    self.ChapterGroupIdList = XCourseConfig.GetChapterIdListByStageType(STAGE_TYPE)

    local asset = XCourseConfig.GetCourseClientConfig("ExamChapterPanel").Values[1]
    local prefab = self.Panelxianduan:LoadPrefab(asset)
    self.PanelChapter = XUiChapterPanel.New(prefab)
    self.PanelChapter:SetScrollCallBack(handler(self, self.UpdateImgBgPos))
    self.PanelStageContent = self.PanelChapter:GetPanelStageContent()

    self:InitChapterBgCount()
end

function XUiCourseCombatlicense:InitButtonCallBack()
    self:BindExitBtns()
    self:RegisterClickEvent(self.BtnTcanchaungBlack, handler(self, self.OpenLesson))
    local helpDataKey = XCourseConfig.GetCourseClientConfig("HelpKey").Values[2]
    self:BindHelpBtn(self.BtnHelp, helpDataKey)
end

function XUiCourseCombatlicense:Refresh()
    self.PanelAsset:Refresh()
    self:UpdateReward()
    self.PanelChapter:Refresh()
end

function XUiCourseCombatlicense:UpdateReward()
    self:UpdateRewardList()
    self:UpdateRewardProgress()
    --检查是否有奖励可自动领取, 策划屏蔽自动领取奖励逻辑
    --XDataCenter.CourseManager.CheckRewardAutoDraw(STAGE_TYPE, handler(self, self.UpdateRewardList))
end

function XUiCourseCombatlicense:UpdateRewardList()
    local courseRewardIdList = self.CourseRewardIdList
    local courseRewardId
    local gridCount = #self.UiReformTaskGrids
    for index, grid in ipairs(self.UiReformTaskGrids) do
        --格子与数据顺序相反
        courseRewardId = courseRewardIdList[gridCount - index + 1]
        grid:SetData(courseRewardId)
    end
end

function XUiCourseCombatlicense:UpdateRewardProgress()
    --奖励进度
    --local totalPoint = XCourseConfig.GetRewardTotalPoint(STAGE_TYPE)
    --local curPoint = self.CourseData:GetTotalPointByStageType(STAGE_TYPE)
    
    local totalChapter = #(XCourseConfig.GetChapterIdListByStageType(STAGE_TYPE))
    local passChapter = self.CourseData:GetChapterAllCanDrawNumber(STAGE_TYPE)
    self.ImgProgress.fillAmount = XUiHelper.GetFillAmountValue(passChapter, totalChapter)
end

function XUiCourseCombatlicense:InitImgBgList()
    local imgBg
    local imgBgPath
    for index = 1, self.ChapterBgCount do
        imgBg = self.ImgBgList[index]
        imgBgPath = XCourseConfig.GetCourseClientConfig("ExamMainBg").Values[index]
        if not imgBg then
            imgBg = index == 1 and self.RImgBg or XUiHelper.Instantiate(self.RImgBg, self.PanelBg)
            self.ImgBgList[index] = imgBg
        end
        if index ~= 1 then
            imgBg.transform.localPosition = Vector3(0, self.ImgBgRectSize.y / 2 * index, 0)
        end
        if imgBgPath then
            imgBg:SetRawImage(imgBgPath)
        end
    end
    Offset = self.PanelStageContent.anchoredPosition - self.PanelBg.anchoredPosition
end

--切换到课程界面
function XUiCourseCombatlicense:OpenLesson()
    XLuaUiManager.PopThenOpen("UiCourseMain")
end

-- 设置红点
function XUiCourseCombatlicense:CheckRedPoint()
    self.BtnTcanchaungBlack:ShowReddot(XDataCenter.CourseManager.CheckCourseLessonReddot())
end