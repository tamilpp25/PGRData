local XUiGridExtralLineChapter = require("XUi/XUiFuben/ExtralLine/XUiGridExtralLineChapter")
local XUiGridExtralLineTab = require("XUi/XUiFuben/ExtralLine/XUiGridExtralLineTab")
local XUiFubenExtralLineChapterDynamicTable = require("XUi/XUiFuben/ExtralLine/XUiFubenExtralLineChapterDynamicTable")
local XUiFubenSideDynamicTable = require("XUi/XUiFuben/UiDynamicList/XUiFubenSideDynamicTable")

local XUiPanelExtralLine = XClass(XSignalData, "XUiPanelExtralLine")

-- 需要展示筛选器的章节
local ShowFilterChapterTypeCollection = {
    XFubenConfigs.ChapterType.Prequel,
    XFubenConfigs.ChapterType.NewCharAct,
}

--######################## 静态方法 BEGIN ########################

function XUiPanelExtralLine.CheckHasRedPoint(config)
    local secondTagConfigs = XFubenConfigs.GetSecondTagConfigsByFirstTagId(config.Id)
    local managers = {}
    for _, config in ipairs(secondTagConfigs) do
        for _, chapterType in ipairs(config.ChapterType) do
            table.insert(managers, XDataCenter.FubenManagerEx.GetManager(chapterType))
        end
    end
    managers = appendArray(managers, XDataCenter.FubenManagerEx.GetManagers(XFubenConfigs.ChapterType.Festival))
    for _, manager in ipairs(managers) do
        if manager:ExGetChapterType() == XFubenConfigs.ChapterType.Festival 
            and manager:ExCheckIsShowRedPoint(XFestivalActivityConfig.UiType.ExtralLine) then
            return true
        elseif manager:ExCheckIsShowRedPoint() then
            return true
        end
    end
    return false
end

--######################## 静态方法 END ########################

function XUiPanelExtralLine:Ctor(ui, parent)
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnFilter, self.OnBtnFilterClick)
    self.RootUi = parent
    self.FubenManagerEx = XDataCenter.FubenManagerEx
    -- 动态列表
    self.GridBranchContent.gameObject:SetActiveEx(false)
    self.UiFubenChapterDynamicTableCurrent = XUiFubenExtralLineChapterDynamicTable.New(self, self.PanelChapterListCurrent, XUiGridExtralLineChapter
        , handler(self, self.OnBtnChapterClicked), handler(self, self.OnPlayOpened))
    self.CurrentChapterListControl = self.UiFubenChapterDynamicTableCurrent
    self.PanelChapterListNext.gameObject:SetActiveEx(false)
    -- 侧边列表
    self.UiFubenSideDynamicTable = XUiFubenSideDynamicTable.New(self.PanelSideList, XUiGridExtralLineTab
        , handler(self, self.OnBtnTabClicked))
    self.UiFubenSideDynamicTable:ConnectSignal("DYNAMIC_TWEEN_OVER", self, self.OnSideDynamicTableTweenOver)
    -- 当前managers
    self.Managers = nil
    self.CurrentManagerIndex = 1
    self.SecondTagConfigs = nil
    self.FirstTagIndex = nil
    self.CurrentChapterIndex = 1
end

-- firstTagId : 一级标签下标
function XUiPanelExtralLine:SetData(firstTagId, managerIndex, chapterIndex, characterId)
    self.FirstTagIndex = firstTagId
    self.SecondTagConfigs = XFubenConfigs.GetSecondTagConfigsByFirstTagId(firstTagId)
    self.RecordCharacterId = characterId
    local managers = {}
    local tempManager = nil
    local fisrtUnlockTagIndex = nil
    for _, config in ipairs(self.SecondTagConfigs) do
        if not fisrtUnlockTagIndex and XDataCenter.FubenManagerEx.CheckHasOpenBySecondTagId(config.Id) then
            fisrtUnlockTagIndex = config.Order -- 第一个已解锁的标签
        end
        for _, managerType in ipairs(config.ChapterType) do
            tempManager = self.FubenManagerEx.GetManager(managerType)
            tempManager:ExSetCustomName(config.TagName)
            table.insert(managers, tempManager)
        end
    end
    self.FisrtUnlockTagIndex = fisrtUnlockTagIndex
    self.Managers = managers
    self.CurrentManagerIndex = managerIndex or self.FisrtUnlockTagIndex
    self.CurrentChapterIndex = chapterIndex or self.Managers[self.CurrentManagerIndex]:ExGetCurrentChapterIndex()
    -- 背景底图刷新
    self.RootUi:ChangeBgBySecondTag(self.SecondTagConfigs[self.CurrentManagerIndex].Bg)
    -- 侧边栏卷刷新
    self:RefreshTabList(self.CurrentManagerIndex)
    -- -- 章节列表刷新
    -- self:RefreshChapterList(self.CurrentChapterIndex)
    self:UpdateBtnFilterActive()
end

function XUiPanelExtralLine:OnEnable()
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

function XUiPanelExtralLine:RefreshChapterList(index, isFirstChange)
    local manager = self.Managers[self.CurrentManagerIndex]
    if index == nil then index = manager:ExGetCurrentChapterIndex() end
    local viewModels = nil
    if manager:ExGetChapterType() == XFubenConfigs.ChapterType.Festival then
        viewModels = manager:ExGetChapterViewModels(XFestivalActivityConfig.UiType.ExtralLine)
    else
        viewModels = manager:ExGetChapterViewModels()
    end
    -- 再判断有没有筛选缓存列表
    local seleIndex = index - 1
    if manager.GetCharacterListIdByChapterViewModels and self.FinalFiltraedOrSortedList then
        viewModels = self.FinalFiltraedOrSortedList
    end
    -- 缓存筛选项下标。因为筛选记录了下标，如果这时退出战斗筛选列表清除了但是筛选下标没清除会导致定位不正确。所以如果是筛选过后再返回到这里，定位到原筛选对应的角色Id的下标
    if self.RecordCharacterId and manager.GetCharacterListIdByChapterViewModels then
        for index, v in pairs(viewModels) do
            if self.RecordCharacterId == v:GetConfig().CharacterId then
                seleIndex = index - 1
                break
            end
        end
        self.RecordCharacterId = nil
    end
    self.CurrentChapterListControl:SetCurrentManager(manager)
    self.CurrentChapterListControl:RefreshList(viewModels, seleIndex, isFirstChange)
    self.CurrentChapterIndex = index
end

function XUiPanelExtralLine:RefreshTabList(index)
    if index == nil then index = self.CurrentManagerIndex end
    self.CurrentManagerIndex = index
    self.UiFubenSideDynamicTable:RefreshList(self.SecondTagConfigs, index - 1)
end

function XUiPanelExtralLine:OnBtnTabClicked(index, manager)
    -- 如果已经是选中的，直接打开界面
    if self.UiFubenSideDynamicTable:GetCurrentSelectedIndex() == index then
        return
    end
    self.UiFubenSideDynamicTable:TweenToIndex(index)
    self:ClearFilterData(self.CurrentManagerIndex)
    self.CurrentManagerIndex = index + 1
    self:RefreshChapterList(self:GetHistoryChapterIndex(self.CurrentManagerIndex))
    self:EmitSignal("SetMainUiFirstIndexArgs", self.FirstTagIndex, self.CurrentManagerIndex, self.CurrentChapterIndex)
    self:UpdateBtnFilterActive()
end

function XUiPanelExtralLine:OnBtnChapterClicked(index, viewModel)
    self.CurrentChapterIndex = index + 1
    local currManager = self.Managers[self.CurrentManagerIndex]
    local characterId = currManager.GetCharacterListIdByChapterViewModels and viewModel:GetConfig().CharacterId or nil
    self:EmitSignal("SetMainUiFirstIndexArgs", self.FirstTagIndex, self.CurrentManagerIndex, self.CurrentChapterIndex, characterId)
    -- 只有是选中的，才直接打开界面
    if self.CurrentChapterListControl:GetCurrentSelectedIndex() == index then
        currManager:ExOpenChapterUi(viewModel)
        return
    end
    self.Mask.gameObject:SetActiveEx(true)
    -- 未选中要先跳过去播动画
    self.CurrentChapterListControl:TweenToIndex(index, XFubenConfigs.ExtralLineWaitTime,function ()
        self.Mask.gameObject:SetActiveEx(false)
    end)
end

function XUiPanelExtralLine:OnPlayOpened(index)
    self:SetHistoryChapterIndex(self.CurrentManagerIndex, index + 1)
end

function XUiPanelExtralLine:SetHistoryChapterIndex(managerIndex, chapterIndex)
    if self.__HistoryChapterIndexDic == nil then
        self.__HistoryChapterIndexDic = {}
    end
    self.__HistoryChapterIndexDic[managerIndex] = chapterIndex
end

function XUiPanelExtralLine:GetHistoryChapterIndex(managerIndex)
    return self.__HistoryChapterIndexDic[managerIndex]
end

function XUiPanelExtralLine:OnSideDynamicTableTweenOver(index)
    self.Mask.gameObject:SetActiveEx(false)
    local currClickTag = self.SecondTagConfigs[index + 1]
    -- 滑动回调也要判断锁定
    local tagId = currClickTag.Id
    local isOpen, lockTip = XDataCenter.FubenManagerEx.CheckHasOpenBySecondTagId(tagId)
    if not isOpen then
        XUiManager.TipMsg(lockTip)
        -- 回弹
        local backIndex = XDataCenter.FubenManagerEx.GetUnLockMostNearSecondTagIndex(tagId) -- (lua下标)
        self.UiFubenSideDynamicTable:TweenToIndex(backIndex - 1)
        return
    end
    -- 切换背景
    self.Transform:Find("Animation/QieHuan"):PlayTimelineAnimation()
    self.RootUi:ChangeBgBySecondTag(currClickTag.Bg) 
    if self.CurrentManagerIndex == index + 1 then return end
    local oldIndex = self.CurrentManagerIndex
    self.CurrentManagerIndex = index + 1
    self:ClearFilterData(oldIndex)
    self:RefreshChapterList(self:GetHistoryChapterIndex(self.CurrentManagerIndex))
    self:UpdateBtnFilterActive()
end

function XUiPanelExtralLine:UpdateBtnFilterActive()
    local needShowFilter = table.contains(ShowFilterChapterTypeCollection, self.Managers[self.CurrentManagerIndex]:ExGetChapterType() or 0)
    self.PanelShaixuan.gameObject:SetActiveEx(needShowFilter)
end

function XUiPanelExtralLine:OnBtnFilterClick()
    local manager = self.Managers[self.CurrentManagerIndex]
    if not manager or not manager.GetCharacterListIdByChapterViewModels then
        return
    end

    local charaList = manager:GetCharacterListIdByChapterViewModels()
    -- 打开筛选器
    XLuaUiManager.Open("UiCommonCharacterFilterTipsOptimization", charaList, self.GameObject.name, function (afterFiltList)
        self.FinalFiltraedOrSortedList = manager:SortModelViewByCharacterList(afterFiltList)
        self.CurrFilterIndex = #self.FinalFiltraedOrSortedList - 1 --必须要设置一个初始选择Index
        self.CurrentChapterListControl:RefreshList(self.FinalFiltraedOrSortedList, self.CurrFilterIndex)
    end, CharacterFilterGroupType.Prequel)
end

function XUiPanelExtralLine:OnDestroy()
    self:ClearFilterData()
    if self.CurrentChapterListControl and self.CurrentChapterListControl.OnDestroy then
        self.CurrentChapterListControl:OnDestroy()
    end
    if self.UiFubenSideDynamicTable and self.UiFubenSideDynamicTable.OnDestroy then
        self.UiFubenSideDynamicTable:OnDestroy()
    end
end

function XUiPanelExtralLine:OnDisable()
    self.CurrentChapterListControl:SetCurrGridOpen()
end

function XUiPanelExtralLine:ClearFilterData(oldIndex)
    local hasFilterData = false

    if self.FinalFiltraedOrSortedList or self.CurrFilterIndex then
        hasFilterData = true
        -- 如果上一个管理器是有筛选的，需要清空筛选下的选择索引
        if XTool.IsNumberValid(oldIndex) then
            local needShowFilter = table.contains(ShowFilterChapterTypeCollection, self.Managers[oldIndex]:ExGetChapterType() or 0)

            if needShowFilter then
                self:SetHistoryChapterIndex(oldIndex, nil)
            end
        end
    end
    
    self.FinalFiltraedOrSortedList = nil  -- 筛选或排序后的缓存列表
    self.CurrFilterIndex = nil
    XDataCenter.CommonCharacterFiltManager.ClearCacheData() --清除筛选缓存数据
    
    return hasFilterData
end

return XUiPanelExtralLine