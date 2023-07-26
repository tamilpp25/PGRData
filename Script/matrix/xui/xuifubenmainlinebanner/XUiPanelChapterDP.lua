--故事集
local XUiGridChapterDP = require("XUi/XUiFubenMainLineBanner/XUiGridChapterDP")
local XUiPanelChapterDP = XClass(nil,"XUiPanelChapterDP")

function XUiPanelChapterDP:Ctor(ui, parentUi)
    self.gameObject = ui.gameObject
    self.transform = ui.transform
    self.ParentUi = parentUi
    self.GridMainLineBanner = self.transform:Find("Viewport/GridMainLineBanner")
    self.GridMainLineBanner.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

function XUiPanelChapterDP:InitDynamicTable()
    self.ChapterDynamicTable = XDynamicTableNormal.New(self.gameObject)
    self.ChapterDynamicTable:SetProxy(XUiGridChapterDP)
    self.ChapterDynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiPanelChapterDP:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.ChapterIds[index] then
            grid:Refresh(self.ChapterIds[index], self.currentDifficult)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnChapterCoverClick(self.ChapterIds[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        XEventManager.DispatchEvent(XEventId.EVENT_GUIDE_STEP_OPEN_EVENT)
    end
end

function XUiPanelChapterDP:UpdateCoverData(difficult)
    self.currentDifficult = difficult
    self.ChapterIds = XDataCenter.ShortStoryChapterManager.GetShortStoryChapterCfg(difficult)
    self.ChapterDynamicTable:SetDataSource(self.ChapterIds)
    self.ChapterDynamicTable:ReloadDataASync()
end

-- 章节点击事件
function XUiPanelChapterDP:OnChapterCoverClick(chapterCfg)
    if not chapterCfg then
        return
    end
    local chapterId = chapterCfg.ChapterId
    local isUnlock = XDataCenter.ShortStoryChapterManager.IsUnlock(chapterId)
    local isActivity = XDataCenter.ShortStoryChapterManager.IsActivity(chapterId)
    local firstStage = XDataCenter.ShortStoryChapterManager.GetFirstStageByChapterId(chapterId)
    local chapterMainId = XFubenShortStoryChapterConfigs.GetChapterMainIdByChapterId(chapterId)
    local hideDiffTog = XDataCenter.ShortStoryChapterManager.IsHaveHardDifficult(chapterMainId)
   
    if isUnlock then
        self.ParentUi:PushUi(function()
            XLuaUiManager.Open("UiFubenMainLineChapterDP", chapterId, nil, not hideDiffTog)
        end)
    elseif isActivity then
        local ret, desc = XDataCenter.ShortStoryChapterManager.CheckActivityCondition(chapterId)
        if not ret then
            XUiManager.TipError(desc)
        end
    else
        local ret, desc = XDataCenter.ShortStoryChapterManager.CheckOpenCondition(chapterId)
        if not ret then
            XUiManager.TipError(desc)
            return
        end
        local tipMsg = XDataCenter.FubenManager.GetFubenOpenTips(firstStage)
        XUiManager.TipMsg(tipMsg)
    end
end

return XUiPanelChapterDP