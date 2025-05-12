local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridResourceCollection = require("XUi/XUiFuben/ResourceCollection/XUiGridResourceCollection")  -- Chapter列表Grid

local XUiPanelResourceCollection = XClass(XSignalData, "XUiPanelResourceCollection")
-- 资源收集 主界面(副本入口翻新)

function XUiPanelResourceCollection.CheckHasRedPoint(config)
    if not config or config.Id then
        return
    end
    -- 资源收集界面没有红点
    return false
end

function XUiPanelResourceCollection:Ctor(ui, parent, config)
    self.RootUi = parent
    self.Config = config
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnFilter, self.OnBtnFilterClick)

    self:InitData() -- 基础数据，包括加载标签数据，标签对应的管理器数据
    self:InitResourcePanel()
    self:InitDynamicTable() -- 初始化副本入口动态列表
end

function XUiPanelResourceCollection:SetData(firstTagId, secondTagIndex)
    -- 背景底图刷新
    self.RootUi:ChangeBgBySecondTag(self.AllSecondTag[1].Bg)
    self:AddTimer()
end

function XUiPanelResourceCollection:OnEnable()
    self.PanelResource:UpdateGrid(self.StrengthUpUseModelView[1], 1)
    self:RefreshDynamicTable()
    -- 播放grid的Enable动画，onenable强制播放
    self:SetGridPlayAnimHasPlay(false)
    self:PlayGridEnableAnime()
    self:RefreshAllRedPoints()
end

function XUiPanelResourceCollection:InitData()
    self.FirstTagId = self.Config.Id
    self.AllSecondTag = XFubenConfigs.GetSecondTagConfigsByFirstTagId(self.FirstTagId) -- 拿到该模式下所有的二级标签 k = 1(二级tag表的id), v = 常规挑战 (tagName)
    -- 根据二级tag分类索引到对应的manager，
    self.TagManagerDic = {} -- k = secondTagId, v = {XManager1, XManager2 ... } ...
    local fisrtUnlockTagIndex = nil
    for _, secondTagconfig in pairs(self.AllSecondTag) do
        if not fisrtUnlockTagIndex and XDataCenter.FubenManagerEx.CheckHasOpenBySecondTagId(secondTagconfig.Id) then
            fisrtUnlockTagIndex = secondTagconfig.Order -- 第一个已解锁的标签
        end
        for k, chapterType in pairs(secondTagconfig.ChapterType) do
            self.TagManagerDic[secondTagconfig.Id] = XDataCenter.FubenManagerEx.GetManager(chapterType) -- 根据二级标签查找到对应的manager(这个标签只配置一个manager)
        end
    end
    self.FisrtUnlockTagIndex = fisrtUnlockTagIndex

    -- 战力提升相关数据
    self.StrengthUpUseModelView = self.TagManagerDic[self.AllSecondTag[1].Id]:ExGetChapterViewModels()
    -- 角色碎片相关数据
    self.CharacterFragmentManager = self.TagManagerDic[self.AllSecondTag[2].Id]
    if self.CharacterFragmentManager then
        self.CharacterFragmentUseModelView = self.CharacterFragmentManager:ExGetChapterViewModels()
    end
end

function XUiPanelResourceCollection:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicTable:SetProxy(XUiGridResourceCollection)
    self.DynamicTable:SetDelegate(self)
    self.PanelList.transform:Find("Viewport/GridBanner").gameObject:SetActiveEx(false)
end

function XUiPanelResourceCollection:InitResourcePanel()
    self.PanelResource = XUiGridResourceCollection.New(self.PanelResource)
    --self.PanelResource:UpdateGrid(self.StrengthUpUseModelView[1], 1)
    if self.PanelResource.BtnEnter then
        XUiHelper.RegisterClickEvent(self, self.PanelResource.BtnEnter, function()
            self:OnClickChapterGrid(self.StrengthUpUseModelView[1])
        end)
    end
end

function XUiPanelResourceCollection:RefreshDynamicTable()
    local data = self.FinalFiltraedOrSortedList ~= nil and self.FinalFiltraedOrSortedList or self.CharacterFragmentUseModelView
    if XTool.IsTableEmpty(data) then
        self.PanelNone.gameObject:SetActiveEx(true)
        self.DynamicTable.Imp.gameObject:SetActiveEx(false)
    else
        self.DynamicTable:SetDataSource(data)
        self.DynamicTable:ReloadDataSync(1)
        self.PanelNone.gameObject:SetActiveEx(false)
        self.DynamicTable.Imp.gameObject:SetActiveEx(true)
    end
end

--动态列表事件
function XUiPanelResourceCollection:OnDynamicTableEvent(event, index, grid)
    local modelView = XTool.IsTableEmpty(self.FinalFiltraedOrSortedList) and self.CharacterFragmentUseModelView or self.FinalFiltraedOrSortedList
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(modelView[index], index, self.DynamicTable:GetFirstUseGridIndexAndUseCount())
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickChapterGrid(modelView[index])
    end
end

function XUiPanelResourceCollection:SetGridPlayAnimHasPlay(flag)
    for _, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:SetHasPlay(flag)
    end
end

-- 播放动态列表动画
function XUiPanelResourceCollection:PlayGridEnableAnime()
    local allUseGird = self.DynamicTable:GetGrids()
    local minIndex, useNum = self.DynamicTable:GetFirstUseGridIndexAndUseCount()

    local playOrder = 1 -- 播放顺序
    for i = minIndex, minIndex + useNum - 1 do
        local grid = allUseGird[i]
        grid:PlayEnableAnime(playOrder)
        playOrder = playOrder + 1
    end
end

function XUiPanelResourceCollection:OnClickChapterGrid(ChapterViewModel)
    if ChapterViewModel:GetIsLocked() then
        XUiManager.TipError(ChapterViewModel:GetLockTip())
        return
    end

    if ChapterViewModel:IsDayLock() then
        XUiManager.TipError(CS.XTextManager.GetText("FubenDailyOpenHint",
                ChapterViewModel:GetOpenDayString()))
        return
    end
    if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.SUBPACKAGE.ENTRY_TYPE.MATERIAL_COLLECTION, ChapterViewModel:GetId()) then
        return
    end
    ChapterViewModel:OpenUi()
end

-- 角色筛选
function XUiPanelResourceCollection:OnBtnFilterClick()
    if not self.CharacterFragmentManager or not self.CharacterFragmentManager.GetCharacterListIdByChapterViewModels then
        return
    end

    -- 转换构造体列表
    local charaList = self.CharacterFragmentManager:GetCharacterListIdByChapterViewModels()

    -- 打开筛选器
    XLuaUiManager.Open("UiCommonCharacterFilterTipsOptimization", charaList, self.GameObject.name, function(afterFiltList)
        self.FinalFiltraedOrSortedList = self.CharacterFragmentManager:SortModelViewByCharacterList(afterFiltList)
        self.DynamicTable:SetDataSource(self.FinalFiltraedOrSortedList)
        self.DynamicTable:ReloadDataSync(-1)
    end, CharacterFilterGroupType.Fragment)
end

function XUiPanelResourceCollection:AddTimer()
    local checkpointTime = XDataCenter.PrequelManager.GetNextCheckPointTime()
    local remainTime = checkpointTime - XTime.GetServerNowTimestamp()
    if remainTime > 0 then
        XCountDown.CreateTimer(self.GameObject.name, remainTime)
        XCountDown.BindTimer(self.GameObject, self.GameObject.name, function(v)
            self.TextTime.text = CS.XTextManager.GetText("PrequelFragmentTimeReset", XUiHelper.GetTime(v, XUiHelper.TimeFormatType.SHOP))
            if v == 0 then
                self:RemoveTimer()
            end
        end)
    end
end

function XUiPanelResourceCollection:RemoveTimer()
    XCountDown.RemoveTimer(self.GameObject.name)
end

function XUiPanelResourceCollection:OnDestroy()
    self:RemoveTimer()
    self.FinalFiltraedOrSortedList = nil  -- 筛选或排序后的缓存列表
    XDataCenter.CommonCharacterFiltManager.ClearCacheData() --清除筛选缓存数据
    if self.BtnTabGroupDyn and self.BtnTabGroupDyn.OnDestroy then
        self.BtnTabGroupDyn:OnDestroy()
    end
end

function XUiPanelResourceCollection:RefreshAllRedPoints()
    -- 第一次打开的时候无需手动刷新
    if not self._CanRefreshRedPoint then
        self._CanRefreshRedPoint = true
        return
    end

    local allUseGird = self.DynamicTable:GetGrids()
    local minIndex, useNum = self.DynamicTable:GetFirstUseGridIndexAndUseCount()

    for i = minIndex, minIndex + useNum - 1 do
        local grid = allUseGird[i]
        grid:RefreshRedPoint(self.CharacterFragmentUseModelView[i])
    end
end

return XUiPanelResourceCollection