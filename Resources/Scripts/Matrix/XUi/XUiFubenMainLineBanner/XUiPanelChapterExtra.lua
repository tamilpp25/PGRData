local XUiGridChapterExtra = require("XUi/XUiFubenMainLineBanner/XUiGridChapterExtra")
local XUiPanelChapterExtra = XClass(nil, "XUiPanelChapterExtra")

function XUiPanelChapterExtra:Ctor(ui, rootUi, parentUi)
    self.gameObject = ui.gameObject
    self.transform = ui.transform
    self.rootUi = rootUi
    self.parent = parentUi
    self.GridMainLineBanner = self.transform:Find("Viewport/GridMainLineBanner")
    self.GridMainLineBanner.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

function XUiPanelChapterExtra:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_CHANGE_EXTRA_CHAPTER_DIFFICULT, self.UpdateCoverData, self)
end

function XUiPanelChapterExtra:InitDynamicTable()
    self.ChapterDynamicTable = XDynamicTableNormal.New(self.gameObject)
    self.ChapterDynamicTable:SetProxy(XUiGridChapterExtra)
    self.ChapterDynamicTable:SetDelegate(self)
end


--动态列表事件
function XUiPanelChapterExtra:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.ChapterIds[index] then
            grid:RefreshDatas(self.ChapterIds[index], self.currentDifficult)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnChapterCoverClick(self.ChapterIds[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        XEventManager.DispatchEvent(XEventId.EVENT_GUIDE_STEP_OPEN_EVENT)
    end
end

-- 章节点击事件
function XUiPanelChapterExtra:OnChapterCoverClick(chapterCfg)
    if not chapterCfg then return end
    local chapterId = chapterCfg.ChapterId[self.currentDifficult]
    local chapterInfo = XDataCenter.ExtraChapterManager.GetChapterInfo(chapterId)
    local chapterCfg = XDataCenter.ExtraChapterManager.GetChapterDetailsCfgByChapterIdAndDifficult(chapterInfo.ChapterMainId, self.currentDifficult)
    if chapterInfo.Unlock then
        self.rootUi:PushUi(function()
                XLuaUiManager.Open("UiFubenMainLineChapterFw", chapterCfg, nil, false)
            end)
    elseif chapterInfo.IsActivity then
        local ret, desc = XDataCenter.ExtraChapterManager.CheckActivityCondition(chapterId)
        if not ret then
            XUiManager.TipError(desc)
        end
    else
        local ret, desc = XDataCenter.ExtraChapterManager.CheckOpenCondition(chapterId)
        if not ret then
            XUiManager.TipError(desc)
            return
        end
        local tipMsg = XDataCenter.FubenManager.GetFubenOpenTips(chapterInfo.FirstStage)
        XUiManager.TipMsg(tipMsg)
    end
end

function XUiPanelChapterExtra:UpdateCoverData(difficult)
    self.currentDifficult = difficult
    self.ChapterIds = XDataCenter.ExtraChapterManager.GetChapterExtraCfgs(difficult)
    self.ChapterDynamicTable:SetDataSource(self.ChapterIds)
    self.ChapterDynamicTable:ReloadDataASync()
end

function XUiPanelChapterExtra:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_CHANGE_EXTRA_CHAPTER_DIFFICULT, self.UpdateCoverData, self)
end

return XUiPanelChapterExtra