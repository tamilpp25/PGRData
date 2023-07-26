--=========================================================================
-- v1.30 考级系统 章节格子背景
--=========================================================================
local XUiBgGrid  = XClass(nil, "XUiBgGrid")

function XUiBgGrid:Ctor(ui, chapterGroupId)
    self.Ui = ui
    self.GameObject = ui.gameObject
    XUiHelper.InitUiClass(self, self.Ui)
    self.ChapterGroupId = chapterGroupId
end

function XUiBgGrid:Refresh()
    local chapterGroupId = self.ChapterGroupId
    self.RImgA:SetRawImage(XCourseConfig.GetChapterGroupBg(chapterGroupId))
    self.TxtSuo.text = XCourseConfig.GetChapterGroupLockDesc(chapterGroupId)
    self.PanelSuo.gameObject:SetActiveEx(not XDataCenter.CourseManager.CheckChapterGroupIsOpen(chapterGroupId))
end


--=========================================================================
-- v1.30 考级系统 课程主界面
--=========================================================================
local XUiCourseMain = XLuaUiManager.Register(XLuaUi,"UiCourseMain")
local XUiCourseMainPanel = require("XUi/XUiCourse/XUiCourseMainPanel")
local XUiCourseAssetPanel = require("XUi/XUiCourse/XUiCourseAssetPanel")

function XUiCourseMain:OnAwake()
    self:AddButtonListenr()
    self.ChapterGroupBgGrids = {}   --章节组背景格子列表
    self:InitPanelBg()

end

function XUiCourseMain:OnStart()
    self:InitData()
    self:InitDynamicList()
    -- 红点监听
    XDataCenter.CourseManager.AddDataUpdataListener(function() self:CheckRedPoint() end, self)
    -- 资产
    --XUiHelper.NewPanelActivityAsset( { XCourseConfig.GetPointItemId() }, self.PanelSpecialTool)
    
    self.PanelAsset = XUiCourseAssetPanel.New(self.PanelSpecialTool)
end

function XUiCourseMain:OnEnable()
    XUiCourseMain.Super.OnEnable(self)
    self:RefreshUi()
    self:CheckRedPoint()
end

function XUiCourseMain:OnDisable()
    XUiCourseMain.Super.OnDisable(self)
end

function XUiCourseMain:InitDynamicList()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelChapterList)
    self.DynamicTable:SetProxy(XUiCourseMainPanel, self)
    self.DynamicTable:SetDelegate(self)
    self.PanelAllLevel.gameObject:SetActiveEx(false)
end

function XUiCourseMain:InitData()
    local maxCount = 0
    self.ChapterGroupList = XCourseConfig.GetActivityGroupIds(XCourseConfig.SystemType.Lesson)

    --初始化章节组的背景
    local chapterIds
    for index, chapterGroupId in ipairs(self.ChapterGroupList) do
        chapterIds = XCourseConfig.GetChapterIds(chapterGroupId)
        self.ChapterGroupBgGrids[index] = XUiBgGrid.New(XUiHelper.Instantiate(self.Bg, self.PanelBg), chapterGroupId)
        maxCount = math.max(maxCount, #chapterIds)
    end
    self.Bg.gameObject:SetActiveEx(false)

    --初始化滑动列表可视区域的高度
    local height = self.GridLevel.transform.rect.height
    self.PanelChapterContentHeight = maxCount * height
end

local Offset
function XUiCourseMain:InitPanelBg()
    self.PanelChapterDynamicTable = self.PanelChapterList:GetComponent("XDynamicTableNormal")
    self.OriginPanelBgY = self.PanelBg.anchoredPosition.y
    self.PanelBg.anchoredPosition = CS.UnityEngine.Vector2(self.PanelChapterDynamicTable.Padding.left, self.OriginPanelBgY)
    Offset = self.PanelBg.anchoredPosition - self.PanelChapterContent.anchoredPosition
end

--更新章节组背景的位置
function XUiCourseMain:UpdateImgBgPos()
    if XTool.UObjIsNil(self.PanelChapterContent) 
            or not self.OriginPanelBgY 
            or not Offset then
        return
    end
    local tmpPos = self.PanelChapterContent.anchoredPosition + Offset
    tmpPos.y = self.OriginPanelBgY
    self.PanelBg.anchoredPosition = tmpPos
end

-- 刷新模块面板
function XUiCourseMain:RefreshUi()
    self.PanelAsset:Refresh()
    self:UpdateDynamicTable()
    self:UpdateBg()
end

function XUiCourseMain:UpdateBg()
    for index, grid in ipairs(self.ChapterGroupBgGrids) do
        grid:Refresh()
    end
end

function XUiCourseMain:UpdateDynamicTable()
    self.DynamicTable:SetDataSource(self.ChapterGroupList)
    self.DynamicTable:ReloadDataSync()
end

function XUiCourseMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.ChapterGroupList[index], index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local height = math.max(self.PanelChapterContentHeight, self.PanelChapterContent.transform.rect.height)
        self.PanelChapterContent:SetInsetAndSizeFromParentEdge(CS.UnityEngine.RectTransform.Edge.Top, 0, height)
        self.ScrollRect.vertical = true
    end
end

-- 设置红点
function XUiCourseMain:CheckRedPoint()
    if self.BtnEnterExam.ShowReddot then
        self.BtnEnterExam:ShowReddot(XDataCenter.CourseManager.CheckCourseExamReddot())
    end
end

function XUiCourseMain:AddButtonListenr()
    local helpDataKey = XCourseConfig.GetCourseClientConfig("HelpKey").Values[1]
    self:BindHelpBtn(self.BtnHelp, helpDataKey)
    self:BindExitBtns()
    self:RegisterClickEvent(self.BtnEnterExam, self.OnBtnEnterExamClick)
    
    self.PanelStageListScrollRect = self.PanelChapterList:GetComponent("ScrollRect")
    self.PanelStageListScrollRect.onValueChanged:AddListener(function(vec2Data)
        self:UpdateImgBgPos()
    end)
end

function XUiCourseMain:OnBtnEnterExamClick()
    XLuaUiManager.PopThenOpen("UiCourseCombatlicense")
end