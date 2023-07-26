local XUiGridCollegeStudy = require("XUi/XUiFuben/CollegeStudy/XUiGridCollegeStudy")
local XUiPanelCollegeStudy = XClass(nil, "XUiPanelCollegeStudy")
-- 研习课程 主界面(副本入口翻新)

function XUiPanelCollegeStudy.CheckHasRedPoint(config)
    if not config or not XTool.IsNumberValid(config.Id) then return end
    local allSecondTag = XFubenConfigs.GetSecondTagConfigsByFirstTagId(config.Id)
    for _, secondTagconfig in pairs(allSecondTag) do
        for k, chapterType in pairs(secondTagconfig.ChapterType) do
            for k, manager in pairs(XDataCenter.FubenManagerEx.GetManagers(chapterType)) do
                if manager:ExCheckIsShowRedPoint() then return true end
            end
        end
    end
    return false
end

--- func desc
---@param config 一级标签的数据
function XUiPanelCollegeStudy:Ctor(ui, parent, config)
    self.RootUi = parent
    self.Config = config
    XUiHelper.InitUiClass(self, ui)

    self:InitData()
    self:InitDynamicTable()
end

function XUiPanelCollegeStudy:SetData()
    -- 设为可播放
    self:SetGridPlayAnimHasPlay(false)
    self:SetupDynamicTable()
    -- 背景底图刷新
    self.RootUi:ChangeBgBySecondTag(self.AllSecondTag[1].Bg)
end

function XUiPanelCollegeStudy:OnEnable()
    for i = 1, #self.CurrentManagerList do
        local grid = self.DynamicTable:GetGridByIndex(i)
        if grid then
            grid:RefreshRedPoint()
        end
    end
    -- 播放grid的Enable动画
    self:SetGridPlayAnimHasPlay()
    self:PlayGridEnableAnime()
end

function XUiPanelCollegeStudy:InitData()
    self.FirstTagId = self.Config.Id
    self.AllSecondTag = XFubenConfigs.GetSecondTagConfigsByFirstTagId(self.FirstTagId) -- 拿到该模式下所有的二级标签
    self.TagManagerDic = {}
    for _, secondTagconfig in pairs(self.AllSecondTag) do
        if not self.TagManagerDic[secondTagconfig.Id] then
            self.TagManagerDic[secondTagconfig.Id] = {}
        end
        for k, chapterType in pairs(secondTagconfig.ChapterType) do
            for k, manager in pairs(XDataCenter.FubenManagerEx.GetManagers(chapterType)) do
                table.insert(self.TagManagerDic[secondTagconfig.Id], manager) -- 根据2级标签拿到所有manager
            end
        end
        table.sort(self.TagManagerDic[secondTagconfig.Id], function (managerA, managerB)
            return managerA:ExGetConfig().Priority < managerB:ExGetConfig().Priority
        end)
    end
end

function XUiPanelCollegeStudy:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelChapterList)
    self.DynamicTable:SetProxy(XUiGridCollegeStudy)
    self.DynamicTable:SetDelegate(self)
    self.GridCollegeBanner.gameObject:SetActive(false)
    self.CurrentManagerList = self.TagManagerDic[self.AllSecondTag[1].Id]  -- 目前只有一个二级标签，所有不显示二级标签
end

--动态列表事件
function XUiPanelCollegeStudy:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.CurrentManagerList[index], index, self.DynamicTable:GetFirstUseGridIndexAndUseCount())
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickChapterGrid(self.CurrentManagerList[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
    end
end

function XUiPanelCollegeStudy:SetGridPlayAnimHasPlay(flag)
    for index, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:SetHasPlay(flag)
    end
end

-- 播放动态列表动画
function XUiPanelCollegeStudy:PlayGridEnableAnime()
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

--设置动态列表
function XUiPanelCollegeStudy:SetupDynamicTable(bReload)
    self.DynamicTable:SetDataSource(self.CurrentManagerList)
    self.DynamicTable:ReloadDataSync(bReload and 1 or -1)
end

function XUiPanelCollegeStudy:OnClickChapterGrid(manager)
    manager:ExOpenMainUi()
end

function XUiPanelCollegeStudy:AutoAddListener()
end

return XUiPanelCollegeStudy