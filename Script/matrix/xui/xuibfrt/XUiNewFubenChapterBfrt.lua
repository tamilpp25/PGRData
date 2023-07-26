local XUiNewFubenChapterBfrt = XLuaUiManager.Register(XLuaUi, "UiNewFubenChapterBfrt")
local XUiGridChapterBfrt = require("XUi/XUiFubenMainLineBanner/XUiGridChapterBfrt")
-- 新副本入口独立出来的据点主界面

function XUiNewFubenChapterBfrt:OnAwake()
    self:RegisterUiEvents()
end

function XUiNewFubenChapterBfrt:OnStart()
    self:InitDynamicTable()
end

function XUiNewFubenChapterBfrt:OnEnable()
    self:SetupBfrtChapters()
end

function XUiNewFubenChapterBfrt:InitDynamicTable()
    self.ChapterDynamicTable = XDynamicTableNormal.New(self.PanelChapterBfrt)
    self.ChapterDynamicTable:SetProxy(XUiGridChapterBfrt)
    self.ChapterDynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiNewFubenChapterBfrt:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.ChapterIds[index] then
            grid:RefreshDatas(self.ChapterIds[index])
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnChapterCoverClick(self.ChapterIds[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        XEventManager.DispatchEvent(XEventId.EVENT_GUIDE_STEP_OPEN_EVENT)
    end
end

-- 章节点击事件
function XUiNewFubenChapterBfrt:OnChapterCoverClick(chapterId)
    local chapterCfg = XDataCenter.BfrtManager.GetChapterCfg(chapterId)
    XLuaUiManager.Open("UiFubenMainLineChapter", chapterCfg, nil, true)
end

-- 设置数据
function XUiNewFubenChapterBfrt:SetupBfrtChapters()
    self.ChapterIds = self.ChapterIds or XDataCenter.BfrtManager.GetChapterList()
    self.ChapterDynamicTable:SetDataSource(self.ChapterIds)
    self.ChapterDynamicTable:ReloadDataASync()
end

function XUiNewFubenChapterBfrt:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiNewFubenChapterBfrt:OnBtnBackClick()
    self:Close()
end

function XUiNewFubenChapterBfrt:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiNewFubenChapterBfrt