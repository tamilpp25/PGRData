local XUiGridResourceCollection = require("XUi/XUiFuben/ResourceCollection/XUiGridResourceCollection")  -- Chapter列表Grid
local XUiGridResourceCollectionTab = require("XUi/XUiFuben/ResourceCollection/XUiGridResourceCollectionTab")  -- 左侧边栏Grid
local XUiFubenSideDynamicTable = require("XUi/XUiFuben/UiDynamicList/XUiFubenSideDynamicTable")     --左侧边栏动态列表 

local XUiPanelResourceCollection = XClass(XSignalData, "XUiPanelResourceCollection")
-- 资源收集 主界面(副本入口翻新)

function XUiPanelResourceCollection.CheckHasRedPoint(config)
    if not config or config.Id then return end
    -- 资源收集界面没有红点
    return false
end

function XUiPanelResourceCollection:Ctor(ui, parent, config)
    self.RootUi = parent
    self.Config = config
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnFilter, self.OnBtnFilterClick)

    self:InitData() -- 基础数据，包括加载标签数据，标签对应的管理器数据
    self:InitLeftTabBtn()   -- 初始化侧边栏
    self:InitDynamicTable() -- 初始化副本入口动态列表
    self:SetupDynamicTable(nil, self.CurrentLeftTabIndex or 0)
end

function XUiPanelResourceCollection:SetData(firstTagId, secondTagIndex)
    self.CurrentLeftTabIndex = secondTagIndex or self.CurrentLeftTabIndex or self.FisrtUnlockTagIndex
    self.BtnTabGroupDyn:RefreshList(self.AllSecondTag, self.CurrentLeftTabIndex - 1)  -- 侧边栏下标从0，lua下标从1开始
    self:RefreshDataByLeftTabChange(self.CurrentLeftTabIndex) -- tab的刷新并不会调用点击切页的回调，所以要手动调
    -- 背景底图刷新
    self.RootUi:ChangeBgBySecondTag(self.AllSecondTag[self.CurrentLeftTabIndex].Bg)
    self:AddTimer()
end

function XUiPanelResourceCollection:OnEnable()
    -- 播放grid的Enable动画，onenable强制播放
    self:SetGridPlayAnimHasPlay(false)
    self:PlayGridEnableAnime()
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
end

function XUiPanelResourceCollection:InitDynamicTable()
    -- 该界面是一个标签对应一个table
    self.DynamicTableList = {}
    for index, v in ipairs(self.AllSecondTag) do
        local dyGo = self["PanelList"..index]
        local dynamicTable = XDynamicTableNormal.New(dyGo)
        self.DynamicTableList[index] = dynamicTable
        dynamicTable:SetProxy(XUiGridResourceCollection)
        dynamicTable:SetDelegate(self)
        dyGo.transform:Find("Viewport/GridBanner").gameObject:SetActiveEx(false)
    end

    self.CurrManager = self.TagManagerDic[self.AllSecondTag[1].Id]  -- 默认使用第一个标签的managerList
    self.ChapterViewModels = self.CurrManager:ExGetChapterViewModels()
end

function XUiPanelResourceCollection:InitLeftTabBtn()
    self.BtnTabGroupDyn = XUiFubenSideDynamicTable.New(self.PanelSideList, XUiGridResourceCollectionTab
    , handler(self, self.OnClickTabCallBack))
    self.BtnTabGroupDyn:ConnectSignal("DYNAMIC_TWEEN_OVER", self, self.OnSideDynamicTableTweenOver)
end

function XUiPanelResourceCollection:OnClickTabCallBack(index) -- 点击切换的回调
    if self.BtnTabGroupDyn:GetCurrentSelectedIndex() == index then
        return
    end
    self.BtnTabGroupDyn:TweenToIndex(index)

    -- 根据点击的二级标签拿到当前的挑战副本类型列表
    self:RefreshDataByLeftTabChange(index + 1)
end

function XUiPanelResourceCollection:OnSideDynamicTableTweenOver(index) -- 滑动切换的回调
    -- 滑动回调也要判断锁定
    local tagId = self.AllSecondTag[index + 1].Id
    local isOpen, lockTip = XDataCenter.FubenManagerEx.CheckHasOpenBySecondTagId(tagId)
    if not isOpen then
        XUiManager.TipMsg(lockTip)
        -- 回弹
        local backIndex = XDataCenter.FubenManagerEx.GetUnLockMostNearSecondTagIndex(tagId) -- (lua下标)
        self.BtnTabGroupDyn:TweenToIndex(backIndex - 1)
        return
    end
    -- 背景底图刷新
    local currClickTag = self.AllSecondTag[index + 1]
    self.RootUi:ChangeBgBySecondTag(currClickTag.Bg)
    self:RefreshDataByLeftTabChange(index + 1, self.CurrentLeftTabIndex - 1 == index)
end

function XUiPanelResourceCollection:RefreshDataByLeftTabChange(index, isClicked) -- 根据左侧栏变化刷新数据
    if isClicked then --如果是通过点击切换的，则滑动切换的回调就不执行了
        return
    end
    local tagId = self.AllSecondTag[index].Id
    self.CurrManager = self.TagManagerDic[tagId]    -- 决定列表显示的List
    self.ChapterViewModels = self.CurrManager:ExGetChapterViewModels()  -- 当前类型下的所有chapter， eg:{作战补给，后勤保养 ...}
    -- 切页后重置可播放
    self:SetGridPlayAnimHasPlay(false)
    -- 再刷新数据
    self:SetupDynamicTable(nil, index)
    --当前选择的侧边栏index
    self.CurrentLeftTabIndex = index 
    -- 缓存记录选择的标签
    self:EmitSignal("SetMainUiFirstIndexArgs", self.FirstTagId, self.CurrentLeftTabIndex)
end

--动态列表事件
function XUiPanelResourceCollection:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self:GetUseModelView()[index], index, self.DynamicTableList[self.CurrentLeftTabIndex]:GetFirstUseGridIndexAndUseCount())
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickChapterGrid(self:GetUseModelView()[index])
    end
end

--设置动态列表
function XUiPanelResourceCollection:SetupDynamicTable(bReload, targetTabIndex)
    for index, dynamicTable in pairs(self.DynamicTableList) do -- tab的index对应自己的动态列表
        if index == targetTabIndex then -- cs下标从0开始，这里偏移+1
            dynamicTable:SetDataSource(self:GetUseModelView()) -- 如果有缓存的筛选列表则用缓存的
            dynamicTable:ReloadDataSync(bReload and 1 or -1)
            dynamicTable.Imp.gameObject:SetActiveEx(true)
        else
            dynamicTable.Imp.gameObject:SetActiveEx(false)  --其他不显示的则隐藏，且格子也要隐藏（alpha设为0）
            for index, grid in pairs(dynamicTable:GetGrids()) do
                grid:SetAlphaOne()
            end
        end
    end
end

--获取当前使用的列表
function XUiPanelResourceCollection:GetUseModelView()
    return self.CurrManager.GetCharacterListIdByChapterViewModels and self.FinalFiltraedOrSortedList or self.ChapterViewModels
end

function XUiPanelResourceCollection:SetGridPlayAnimHasPlay(flag)
    local dynamicTable = self.DynamicTableList[self.CurrentLeftTabIndex]
    for index, grid in pairs(dynamicTable:GetGrids()) do
        grid:SetHasPlay(flag)
    end
end

-- 播放动态列表动画
function XUiPanelResourceCollection:PlayGridEnableAnime()
    -- 先找到使用中的grid里序号最小的
    local dynamicTable = self.DynamicTableList[self.CurrentLeftTabIndex]
    local allUseGird = dynamicTable:GetGrids()
    local minIndex, useNum = dynamicTable:GetFirstUseGridIndexAndUseCount()

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
    if not self.CurrManager or not self.CurrManager.GetCharacterListIdByChapterViewModels then
        return
    end

    -- 转换构造体列表
    local charaList = self.CurrManager:GetCharacterListIdByChapterViewModels()
  
    -- 打开筛选器
    XLuaUiManager.Open("UiCommonCharacterFilterTipsOptimization", charaList, self.GameObject.name, function (afterFiltList)
        self.FinalFiltraedOrSortedList = self.CurrManager:SortModelViewByCharacterList(afterFiltList)
        local currDynamicTable = self.DynamicTableList[self.CurrentLeftTabIndex]
        currDynamicTable:SetDataSource(self.FinalFiltraedOrSortedList)
        currDynamicTable:ReloadDataSync(-1)
    end, CharacterFilterGroupType.Fragment)
end

function XUiPanelResourceCollection:AddTimer()
    local checkpointTime = XDataCenter.PrequelManager.GetNextCheckPointTime()
    local remainTime = checkpointTime - XTime.GetServerNowTimestamp()
    if remainTime > 0 then
        XCountDown.CreateTimer(self.GameObject.name, remainTime)
        XCountDown.BindTimer(self.GameObject, self.GameObject.name, function(v)
            self.TextTime.text = CS.XTextManager.GetText("PrequelFragmentTimeReset", XUiHelper.GetTime(v, XUiHelper.TimeFormatType.SHOP))
            if v == 0 then self:RemoveTimer() end
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

function XUiPanelResourceCollection:PlaySwithChapterListAnim()
end


return XUiPanelResourceCollection