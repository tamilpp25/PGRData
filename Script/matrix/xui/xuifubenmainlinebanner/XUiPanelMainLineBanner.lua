local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridMainLineBanner = require("XUi/XUiFubenMainLineBanner/XUiGridMainLineBanner")
local XUiPanelMainLineBanner = XClass(nil, "XUiPanelMainLineBanner")

--grid里的item定位X坐标偏移量
local GRID_ITEM_OFFSET_X = 1.7

function XUiPanelMainLineBanner:Ctor(ui, parentUi)
    self.gameObject = ui.gameObject
    self.transform = ui.transform
    self.ParentUi = parentUi
    self.GridMainLineBanner = self.transform:Find("Viewport/GridMainLineBanner")
    self.PanelChapterContent = self.transform:Find("Viewport/PanelChapterContent")
    self.GridMainLineBanner.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

function XUiPanelMainLineBanner:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.gameObject)
    self.DynamicTable:SetProxy(XUiGridMainLineBanner)
    self.DynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiPanelMainLineBanner:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateChapterGrid(self.PageDatas[index], self.CurDiff)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:ClickChapterGrid(self.PageDatas[index], index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if not XDataCenter.GuideManager.CheckIsInGuide() then
            self:AutoScroll()
        end
    end
end

-- 选中一个 chapter grid，需要设置层级、状态
function XUiPanelMainLineBanner:ClickChapterGrid(chapterMain, index)
    local chapter = XDataCenter.FubenMainLineManager.GetChapterCfgByChapterMain(chapterMain.Id, self.CurDiff)
    local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfoByChapterMain(chapterMain.Id, self.CurDiff)
    if chapterInfo.Unlock then
        self.ParentUi:PushUi(function()
            if chapterMain.Id == XDataCenter.FubenMainLineManager.TRPGChapterId then
                XDataCenter.TRPGManager.PlayStartStory()
            elseif chapterMain.Id == XDataCenter.FubenMainLineManager.MainLine3DId then
                XLuaUiManager.Open("UiFubenMainLine3D")
            else
                XLuaUiManager.Open("UiFubenMainLineChapter", chapter)
            end
        end)
        self:SaveScrollPos(index)
    elseif chapterInfo.IsActivity then
        local chapterId = XDataCenter.FubenMainLineManager.GetChapterIdByChapterMain(chapterMain.Id, self.CurDiff)
        local ret, desc = XDataCenter.FubenMainLineManager.CheckActivityCondition(chapterId)
        if not ret then
            XUiManager.TipError(desc)
        end
    else
        if self.CurDiff == XDataCenter.FubenManager.DifficultNightmare then
            XUiManager.TipMsg(CS.XTextManager.GetText("BfrtChapterUnlockCondition"))
        elseif chapterMain.Id == XDataCenter.FubenMainLineManager.TRPGChapterId then
            XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.MainLineTRPG)
        else
            local chapterId = XDataCenter.FubenMainLineManager.GetChapterIdByChapterMain(chapterMain.Id, self.CurDiff)
            local isOpen, desc = XDataCenter.FubenMainLineManager.CheckOpenCondition(chapterId)
            if not isOpen then
                XUiManager.TipMsg(desc)
                return
            end
            self:ChapterLockTipMsg(chapterInfo)
        end
    end
end

--优先选择上一次操作的界面，否则选择最新的章节
function XUiPanelMainLineBanner:AutoScroll()
    local rt = self.PanelChapterContent:GetComponent("RectTransform")
    local posX = self.PlayerPrefsPosX[self.CurDiff]

    if not posX then
        posX = self:GetTheLatestChapterPosX()
    end

    rt:DOAnchorPosX(posX, 0.5)
end

--@region 动态列表自动跳转
function XUiPanelMainLineBanner:SetPlayerPrefsPosX(difficultType)
    self.PlayerPrefsPosX = {}

    for _, type in pairs(difficultType) do
        local keyX = self:GetPlayerPrefsKey(type)
        if CS.UnityEngine.PlayerPrefs.HasKey(keyX) then
            self.PlayerPrefsPosX[type] = CS.UnityEngine.PlayerPrefs.GetFloat(keyX)
        end
    end
end

function XUiPanelMainLineBanner:GetPlayerPrefsKey(curDiff)
    --CurDiff：普通副本或隐藏副本
    return string.format("%s-%s-%s", "DynamicTable_MainLineChapterPosX", tostring(XPlayer.Id), curDiff)
end

function XUiPanelMainLineBanner:GetTheLatestChapterPosX()
    if self.PageDatas then
        local index = 0
        for i, pageDatas in ipairs(self.PageDatas) do
            local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfoByChapterMain(pageDatas.Id, self.CurDiff)
            if chapterInfo.Unlock then
                index = i
            end
        end

        return self:GetChapterPosXByIndex_X(index)
    else
        return 0
    end
end

--获取grid里对应item的坐标X轴
function XUiPanelMainLineBanner:GetChapterPosXByIndex_X(index)
    if index >= 2 then
        --使其贴近最右侧显示
        index = index - GRID_ITEM_OFFSET_X
    else
        index = 0
    end

    local dynamicTableNormal = self.gameObject:GetComponent(typeof(CS.XDynamicTableNormal))
    return -1 * (dynamicTableNormal.GridSize.x + dynamicTableNormal.Spacing.x) * index
end

function XUiPanelMainLineBanner:SaveScrollPos(index)
    local keyX = self:GetPlayerPrefsKey(self.CurDiff)
    CS.UnityEngine.PlayerPrefs.SetFloat(keyX, self:GetChapterPosXByIndex_X(index))
end

function XUiPanelMainLineBanner:ChapterLockTipMsg(chapterInfo)
    local tipMsg = XDataCenter.FubenManager.GetFubenOpenTips(chapterInfo.FirstStage)
    XUiManager.TipMsg(tipMsg)
end

--设置动态列表
function XUiPanelMainLineBanner:SetupDynamicTable(difficult, index)
    self.CurDiff = difficult
    self.PageDatas = XDataCenter.FubenMainLineManager.GetChapterMainTemplates(difficult)

    -- 远程配置屏蔽，只保留第一关
    if XUiManager.IsHideFunc then
        local temp = self.PageDatas[1]
        self.PageDatas = {}
        self.PageDatas[1] = temp
    end

    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(index)
end

return XUiPanelMainLineBanner