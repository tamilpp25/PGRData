local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridSimulationChallenge = require("XUi/XUiFuben/XUiFubenSimulation/XUiGridSimulationChallenge")    -- Chapter列表Grid
local XUiGridSimulationChallengeTab = require("XUi/XUiFuben/XUiFubenSimulation/XUiGridSimulationChallengeTab")  -- 左侧边栏Grid
local XUiFubenSideDynamicTable = require("XUi/XUiFuben/UiDynamicList/XUiFubenSideDynamicTable")     --左侧边栏动态列表 

local XUiPanelSimulationChallenge = XClass(XSignalData, "XUiPanelSimulationChallenge")

function XUiPanelSimulationChallenge.CheckHasRedPoint(config)
    if not config or not XTool.IsNumberValid(config.Id) then
        return
    end
    local allSecondTag = XFubenConfigs.GetSecondTagConfigsByFirstTagId(config.Id)
    for _, secondTagconfig in pairs(allSecondTag) do
        for k, chapterType in pairs(secondTagconfig.ChapterType) do
            for k, manager in pairs(XDataCenter.FubenManagerEx.GetManagers(chapterType)) do
                if manager:ExCheckIsShowRedPoint() then
                    return true
                end
            end
        end
    end
    return false
end

--- func desc
---@param config 一级标签的数据
-- 模拟挑战 主界面(副本入口翻新)
function XUiPanelSimulationChallenge:Ctor(ui, parent, config)
    self.RootUi = parent
    self.Config = config
    XUiHelper.InitUiClass(self, ui)

    self:InitData() -- 基础数据，包括加载标签数据，标签对应的管理器数据
    self:InitLeftTabBtn()   -- 初始化侧边栏
    self:InitDynamicTable() -- 初始化副本入口动态列表
    self:SetupDynamicTable()
end

function XUiPanelSimulationChallenge:SetData(firstTagId, secondTagIndex)
    self.CurrentLeftTabIndex = secondTagIndex or self.CurrentLeftTabIndex or self.FisrtUnlockTagIndex
    self.BtnTabGroupDyn:RefreshList(self.AllSecondTag, self.CurrentLeftTabIndex - 1)  -- 侧边栏下标从0，lua下标从1开始
    self:RefreshDataByLeftTabChange(self.CurrentLeftTabIndex) -- tab的刷新并不会调用点击切页的回调，所以要手动调
    -- 背景底图刷新
    self.RootUi:ChangeBgBySecondTag(self.AllSecondTag[self.CurrentLeftTabIndex].Bg)

    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_DAILY_REFRESH, self.SetupDynamicTable, self)
    XEventManager.AddEventListener(XEventId.EVENT_URGENTEVENT_SYNC, self.SetupDynamicTable, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SYNC, self.SetupDynamicTable, self)
end

function XUiPanelSimulationChallenge:OnEnable()
    for i = 1, #self.CurrentChanllengeManagers do
        local grid = self.DynamicTable:GetGridByIndex(i)
        if grid then
            grid:RefreshRedPoint()
            grid:RefreshProgress()
        end
    end

    local gridDic = self.BtnTabGroupDyn:GetGridDic()
    for _, grid in pairs(gridDic) do
        grid:RefreshRedPoint()
    end
    -- 播放grid的Enable动画
    self:SetGridPlayAnimHasPlay(false)
    self:PlayGridEnableAnime()
end

function XUiPanelSimulationChallenge:InitData()
    XDataCenter.FubenManager.EnterChallenge()

    self.FirstTagId = self.Config.Id
    self.AllSecondTag = XFubenConfigs.GetSecondTagConfigsByFirstTagId(self.FirstTagId) -- 拿到该模式下所有的二级标签
    self.TagManagerDic = {} -- k = 周常(二级tagId), v = { 战区，囚笼... }, k = 特殊挑战, v = {宣叙妄想... }
    self.TagManagerShowConditionDic = {}
    local UNLOCK_SORT_TAG_ID = 9 -- 指定只有第二个页签需要先根据解锁排序，再按配置顺序排序
    local fisrtUnlockTagIndex = nil
    for _, secondTagconfig in pairs(self.AllSecondTag) do
        local tagId = secondTagconfig.Id
        if not fisrtUnlockTagIndex and XDataCenter.FubenManagerEx.CheckHasOpenBySecondTagId(secondTagconfig.Id) then
            fisrtUnlockTagIndex = secondTagconfig.Order -- 第一个已解锁的标签
        end

        if not self.TagManagerDic[secondTagconfig.Id] then
            self.TagManagerDic[secondTagconfig.Id] = {}
        end
        if not self.TagManagerShowConditionDic[secondTagconfig.Id] then
            self.TagManagerShowConditionDic[secondTagconfig.Id] = {}
        end

        for index, chapterType in pairs(secondTagconfig.ChapterType) do
            for _, manager in pairs(XDataCenter.FubenManagerEx.GetManagers(chapterType)) do
                if manager:ExCheckInTime() then
                    table.insert(self.TagManagerDic[secondTagconfig.Id], manager) -- 根据2级标签拿到所有manager
                    self.TagManagerShowConditionDic[secondTagconfig.Id][manager] = secondTagconfig.ChapterTypeShowCondition[index]
                end
            end
        end

        if tagId == UNLOCK_SORT_TAG_ID then
            -- 先根据解锁排序，再按配置顺序排序
            table.sort(self.TagManagerDic[tagId], function(managerA, managerB)
                local priorityA = managerA:ExGetIsLocked() and 0 or 1
                local priorityB = managerB:ExGetIsLocked() and 0 or 1
                if priorityA ~= priorityB then
                    return priorityA > priorityB
                end
                return managerA:ExGetConfig().Priority < managerB:ExGetConfig().Priority
            end)
        else
            table.sort(self.TagManagerDic[tagId], function(managerA, managerB)
                return managerA:ExGetConfig().Priority < managerB:ExGetConfig().Priority
            end)
        end
    end
    self.FisrtUnlockTagIndex = fisrtUnlockTagIndex
end

function XUiPanelSimulationChallenge:GetFiltShowConditionManagers(challengeManagers, tagId)
    local curTagManagerShowConditions = self.TagManagerShowConditionDic[tagId]
    local managers = {}

    for _, manager in ipairs(challengeManagers) do
        if manager:ExGetIsLocked() then
            local showConditions = curTagManagerShowConditions[manager]
            if XTool.IsNumberValid(showConditions) and not XConditionManager.CheckCondition(showConditions) then
            else
                table.insert(managers, manager)
            end
        else
            table.insert(managers, manager)
        end
    end

    return managers
end

function XUiPanelSimulationChallenge:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelChapterList)
    self.DynamicTable:SetProxy(XUiGridSimulationChallenge)
    self.DynamicTable:SetDelegate(self)
    self.GridChallengeBanner.gameObject:SetActive(false)
    self.CurrentChanllengeManagers = self:GetFiltShowConditionManagers(self.TagManagerDic[self.AllSecondTag[1].Id], self.AllSecondTag[1].Id)  -- 默认使用第一个标签的managerList  
end

function XUiPanelSimulationChallenge:InitLeftTabBtn()
    self.BtnTabGroupDyn = XUiFubenSideDynamicTable.New(self.PanelSideList, XUiGridSimulationChallengeTab
    , handler(self, self.OnClickTabCallBack))
    self.BtnTabGroupDyn:ConnectSignal("DYNAMIC_TWEEN_OVER", self, self.OnSideDynamicTableTweenOver)
end

function XUiPanelSimulationChallenge:OnClickTabCallBack(index)
    if self.BtnTabGroupDyn:GetCurrentSelectedIndex() == index then
        return
    end
    self.BtnTabGroupDyn:TweenToIndex(index)

    -- 根据点击的二级标签拿到当前的挑战副本类型列表
    self:RefreshDataByLeftTabChange(index + 1)
end

function XUiPanelSimulationChallenge:OnSideDynamicTableTweenOver(index)
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
    self:RefreshDataByLeftTabChange(index + 1, self.CurrentLeftTabIndex - 1 == index)   -- cs下标偏移
end

function XUiPanelSimulationChallenge:RefreshDataByLeftTabChange(index, isClicked)
    if isClicked then
        --如果是通过点击切换的，则滑动切换的回调就不执行了
        return
    end

    --当前选择的侧边栏index
    self.CurrentLeftTabIndex = index

    local tagId = self.AllSecondTag[index].Id
    self.CurrentChanllengeManagers = self:GetFiltShowConditionManagers(self.TagManagerDic[tagId], tagId)

    -- 切页后重置可播放
    self:SetGridPlayAnimHasPlay(false)
    -- 再刷新数据
    self:SetupDynamicTable()
    -- 缓存记录选择的标签
    self:EmitSignal("SetMainUiFirstIndexArgs", self.FirstTagId, self.CurrentLeftTabIndex)
end

--动态列表事件
function XUiPanelSimulationChallenge:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.CurrentChanllengeManagers[index], index, self.DynamicTable:GetFirstUseGridIndexAndUseCount())
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickChapterGrid(self.CurrentChanllengeManagers[index], grid)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnDestroy()
    end
end

--设置动态列表
function XUiPanelSimulationChallenge:SetupDynamicTable(bReload)
    self.DynamicTable:SetDataSource(self.CurrentChanllengeManagers)
    self.DynamicTable:ReloadDataSync(bReload and 1 or -1)
end

function XUiPanelSimulationChallenge:SetGridPlayAnimHasPlay(flag)
    for index, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:SetHasPlay(flag)
    end
end

-- 播放动态列表动画
function XUiPanelSimulationChallenge:PlayGridEnableAnime()
    -- 先找到使用中的grid里序号最小的
    local minIndex, useNum = self.DynamicTable:GetFirstUseGridIndexAndUseCount()
    local allUseGird = self.DynamicTable:GetGrids()

    local playOrder = 1 -- 播放顺序
    for i = minIndex, minIndex + useNum - 1 do
        local grid = allUseGird[i]
        grid:PlayEnableAnime(playOrder)
        playOrder = playOrder + 1
    end
end

-- 周常入口由各自的manger管理，manger里有格子的数据
function XUiPanelSimulationChallenge:OnClickChapterGrid(manager, grid)
    if grid and grid.OnClickSelf then
        grid:OnClickSelf()
        return
    end
    manager:ExOpenMainUi()
end

function XUiPanelSimulationChallenge:PlaySwithChapterListAnim()
end

function XUiPanelSimulationChallenge:OnDestroy()
    if self.BtnTabGroupDyn and self.BtnTabGroupDyn.OnDestroy then
        self.BtnTabGroupDyn:OnDestroy()
    end

    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_DAILY_REFRESH, self.SetupDynamicTable, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_URGENTEVENT_SYNC, self.SetupDynamicTable, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SYNC, self.SetupDynamicTable, self)
end

return XUiPanelSimulationChallenge