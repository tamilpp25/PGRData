-- local XUiGridFubenChapter = require("XUi/XUiFuben/UiDynamicList/XUiGridFubenChapter")
-- local XUiGridFubenSideTab = require("XUi/XUiFuben/UiDynamicList/XUiGridFubenSideTab")
local XUiGridMainLineChapter = require("XUi/XUiFuben/MainLine/XUiGridMainLineChapter")
local XUiGridMainLineTab = require("XUi/XUiFuben/MainLine/XUiGridMainLineTab")
local XUiFubenChapterDynamicTable = require("XUi/XUiFuben/UiDynamicList/XUiFubenChapterDynamicTable")
local XUiFubenSideDynamicTable = require("XUi/XUiFuben/UiDynamicList/XUiFubenSideDynamicTable")

local XUiPanelMainLine = XClass(XSignalData, "XUiPanelMainLine")

--######################## 静态方法 BEGIN ########################

function XUiPanelMainLine.CheckHasRedPoint()
    return XDataCenter.FubenManagerEx.GetMainLineManager():ExCheckIsShowRedPoint()
end

--######################## 静态方法 END ########################

function XUiPanelMainLine:Ctor(ui, parent)
    XUiHelper.InitUiClass(self, ui)
    self.RootUi = parent
    self.MainLineManager = XDataCenter.FubenManagerEx.GetMainLineManager()
    -- 动态列表
    self.UiFubenChapterDynamicTableCurrent = XUiFubenChapterDynamicTable.New(self, self.PanelChapterListCurrent, XUiGridMainLineChapter
        , handler(self, self.OnBtnChapterClicked))
    self.CurrentChapterListControl = self.UiFubenChapterDynamicTableCurrent
    self.PanelChapterListNext.gameObject:SetActiveEx(false)
    -- 侧边列表
    self.UiFubenSideDynamicTable = XUiFubenSideDynamicTable.New(self.PanelSideList, XUiGridMainLineTab
        , handler(self, self.OnBtnTabClicked))
    self.UiFubenSideDynamicTable:ConnectSignal("DYNAMIC_TWEEN_OVER", self, self.OnSideDynamicTableTweenOver)
    -- 当前章节组id
    self.CurrentGroupId = 1
    self.CurrentChapterIndex = 1
    -- 当前章节限时难度
    self.CurrentFubenDifficulty = XDataCenter.FubenManager.DifficultNormal
    self.FirstTagIndex = nil
end

function XUiPanelMainLine:SetData(firstTagId, groupIndex, chapterIndex)
    self.FirstTagIndex = firstTagId
    if groupIndex == nil then
        local g, i = self.MainLineManager:ExGetCurrentGroupIndexAndChapterIndex()
        groupIndex = g
    end
    self.CurrentGroupId = groupIndex
    self.CurrentChapterIndex = chapterIndex
    -- 背景底图刷新
    self.RootUi:ChangeBgBySecondTag(self.MainLineManager:ExGetChapterGroupConfigs()[self.CurrentGroupId].Bg)
    -- 侧边栏卷刷新
    self:RefreshTabList(self.CurrentGroupId)
    -- -- 章节列表刷新
    -- self:RefreshChapterList(self.CurrentChapterIndex)
end

function XUiPanelMainLine:OnEnable()
    
    local gridDic = self.CurrentChapterListControl:GetGridDic()
    for _, grid in pairs(gridDic) do
        grid:RefreshRedPoint()
    end
    gridDic = self.UiFubenSideDynamicTable:GetGridDic()
    for _, grid in pairs(gridDic) do
        grid:RefreshRedPoint()
    end
    -- 章节列表刷新
    self:RefreshChapterList(self.CurrentChapterIndex, true)
end

function XUiPanelMainLine:RefreshChapterList(index, isFirstChange)
    if index == nil then
        local _, i = self.MainLineManager:ExGetCurrentGroupIndexAndChapterIndex(self.CurrentGroupId)
        index = i
    end
    local chapterViewModels = self.MainLineManager:ExGetChapterViewModels(self.CurrentGroupId, self.CurrentFubenDifficulty)
    self.CurrentChapterListControl:RefreshList(chapterViewModels, index - 1, isFirstChange)
end

function XUiPanelMainLine:RefreshTabList(index)
    local groupConfigs = self.MainLineManager:ExGetChapterGroupConfigs()
    self.UiFubenSideDynamicTable:RefreshList(groupConfigs, index - 1)
end

function XUiPanelMainLine:OnBtnTabClicked(index, groupConfig)
    if self.UiFubenSideDynamicTable:GetCurrentSelectedIndex() == index then
        return
    end
    local isUp = groupConfig.Id > self.CurrentGroupId
    self.UiFubenSideDynamicTable:TweenToIndex(index)
    self.CurrentGroupId = groupConfig.Id
    self:EmitSignal("SetMainUiFirstIndexArgs", self.FirstTagIndex, self.CurrentGroupId, self:GetHistoryChapterIndex(self.CurrentGroupId)) -- 点击侧边栏不记录chapter，只记录2级标签
    self:RefreshChapterList(self:GetHistoryChapterIndex(self.CurrentGroupId))
end

function XUiPanelMainLine:OnBtnChapterClicked(index, viewModel)
    self.CurrentChapterIndex = index + 1 
    self:EmitSignal("SetMainUiFirstIndexArgs", self.FirstTagIndex, self.CurrentGroupId, self.CurrentChapterIndex)
    self:SetHistoryChapterIndex(self.CurrentGroupId, self.CurrentChapterIndex)
    -- 只有是选中的，才直接打开界面
    if self.CurrentChapterListControl:GetCurrentSelectedIndex() == index then
        self.MainLineManager:ExOpenChapterUi(viewModel, self.CurrentFubenDifficulty)
        return
    end
    self.Mask.gameObject:SetActiveEx(true)
    -- 未选中要先跳过去播动画
    self.CurrentChapterListControl:TweenToIndex(index, XFubenConfigs.MainLineWaitTime, function ()
        self.Mask.gameObject:SetActiveEx(false)
    end)
end

function XUiPanelMainLine:OnSideDynamicTableTweenOver(index)
    self.Mask.gameObject:SetActiveEx(false)
    local groupConfig = self.MainLineManager:ExGetChapterGroupConfigs()[index + 1]
    -- 背景底图刷新
    self.Transform:Find("Animation/QieHuan"):PlayTimelineAnimation()
    self.RootUi:ChangeBgBySecondTag(groupConfig.Bg) 
    if self.CurrentGroupId == groupConfig.Id then return end
    local isUp = groupConfig.Id > self.CurrentGroupId
    self.CurrentGroupId = groupConfig.Id
    self:RefreshChapterList(self:GetHistoryChapterIndex(self.CurrentGroupId))
end

function XUiPanelMainLine:SetHistoryChapterIndex(groupId, chapterIndex)
    if self.__HistoryChapterIndexDic == nil then
        self.__HistoryChapterIndexDic = {}
    end
    self.__HistoryChapterIndexDic[groupId] = chapterIndex
end

function XUiPanelMainLine:GetHistoryChapterIndex(groupId)
    if self.__HistoryChapterIndexDic == nil then return nil end
    return self.__HistoryChapterIndexDic[groupId]
end

function XUiPanelMainLine:OnDestroy()
    if self.CurrentChapterListControl and self.CurrentChapterListControl.OnDestroy then
        self.CurrentChapterListControl:OnDestroy()
    end
    if self.UiFubenSideDynamicTable and self.UiFubenSideDynamicTable.OnDestroy then
        self.UiFubenSideDynamicTable:OnDestroy()
    end
end

function XUiPanelMainLine:OnDisable()
    self.CurrentChapterListControl:SetCurrGridOpen() -- 退出时要强设一遍展开样式，防止在滑动侧边栏过程中，快速切换底部标签再切回来导致open动画播放错误
end

return XUiPanelMainLine