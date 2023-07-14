local XExFubenBaseManager = require("XEntity/XFuben/XExFubenBaseManager")
local XChapterViewModel = require("XEntity/XFuben/XChapterViewModel")

--============================ XUiGridActivity ============================
local XUiGridActivity = XClass(nil, "XUiGridActivity")

function XUiGridActivity:Ctor(ui)
    self.Data = nil
    XUiHelper.InitUiClass(self, ui)
end

-- data : XExFubenBaseManager | XChapterViewModel
function XUiGridActivity:SetData(data)
    self.Data = data
    if CheckClassSuper(data, XExFubenBaseManager) then
        self:SetManager(data)
    elseif CheckClassSuper(data, XChapterViewModel) then
        self:SetChapter(data)
    end
    self:RefreshRedPoint()
end

function XUiGridActivity:SetManager(data)
    self.RImgIcon:SetRawImage(data:ExGetIcon())
    self.TxtName.text = data:ExGetName()
    self.TxtConsumeCount.text = data:ExGetProgressTip()
    self.PanelLock.gameObject:SetActiveEx(data:ExGetIsLocked())
    self.TxtLock.text = data:ExGetLockTip()
    local runningTimeStr = data:ExGetRunningTimeStr()
    self.PanelLeftTime.gameObject:SetActiveEx(not string.IsNilOrEmpty(runningTimeStr))
    self.TxtLeftTime.text = runningTimeStr
end

function XUiGridActivity:SetChapter(data)
    self.RImgIcon:SetRawImage(data:GetIcon())
    self.TxtName.text = data:GetName()
    self.TxtConsumeCount.text = data:GetProgressTips()
    self.PanelLock.gameObject:SetActiveEx(data:GetIsLocked())
    self.TxtLock.text = data:GetLockTip()
    local runningTimeStr = data:GetTimeTips()
    self.PanelLeftTime.gameObject:SetActiveEx(not string.IsNilOrEmpty(runningTimeStr))
    self.TxtLeftTime.text = runningTimeStr
end

function XUiGridActivity:RefreshRedPoint()
    if CheckClassSuper(self.Data, XExFubenBaseManager) then
        self.Red.gameObject:SetActiveEx(self.Data:ExCheckIsShowRedPoint())
    elseif CheckClassSuper(self.Data, XChapterViewModel) then
        self.Red.gameObject:SetActiveEx(self.Data:CheckHasRedPoint())
    end
end

function XUiGridActivity:RefreshTimeTips()
    local runningTimeStr
    if CheckClassSuper(self.Data, XExFubenBaseManager) then
        runningTimeStr = self.Data:ExGetRunningTimeStr()
    elseif CheckClassSuper(self.Data, XChapterViewModel) then
        runningTimeStr = self.Data:GetTimeTips()
    end
    self.PanelLeftTime.gameObject:SetActiveEx(not string.IsNilOrEmpty(runningTimeStr))
    self.TxtLeftTime.text = runningTimeStr
end

function XUiGridActivity:RefreshProgressTips()
    local progressTips
    if CheckClassSuper(self.Data, XExFubenBaseManager) then
        progressTips = self.Data:ExGetProgressTip()
    elseif CheckClassSuper(self.Data, XChapterViewModel) then
        progressTips = self.Data:GetProgressTips()
    end
    self.TxtConsumeCount.text = progressTips
end

function XUiGridActivity:IsActivityEnd()
    local onGoing
    if CheckClassSuper(self.Data, XExFubenBaseManager) then
        onGoing = self.Data:ExCheckInTime()
    elseif CheckClassSuper(self.Data, XChapterViewModel) then
        onGoing = self.Data:CheckInTime()
    end
    return not onGoing
end

--=========================== XUiActivityChapter ============================
local XUiActivityChapter = XLuaUiManager.Register(XLuaUi, "UiActivityChapter")

function XUiActivityChapter:OnAwake()
    self.FubenManagerEx = XDataCenter.FubenManagerEx
    self.DynamicTable = XDynamicTableNormal.New(self.PanelChapterList)
    self.DynamicTable:SetProxy(XUiGridActivity)
    self.DynamicTable:SetDelegate(self)
    self.GridActivityBanner.gameObject:SetActive(false)
    self.GetManagerByIndexFunc = nil
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

function XUiActivityChapter:OnStart(activityManagerIndex)
    self:RefreshActivityList(activityManagerIndex)
    self.RImgFestivalBg:SetRawImage(XFubenConfigs.GetMainFestivalBg())
end

function XUiActivityChapter:OnEnable()
    -- 刷新所有格子的红点
    for i = 1, self.DynamicTable:GetImpl().TotalCount do
        local grid = self.DynamicTable:GetGridByIndex(i)
        if grid then
            grid:RefreshRedPoint()
            grid:RefreshProgressTips()
        end
    end
    self:StartTimeUpdate()
end

function XUiActivityChapter:OnDisable()
    self:StopTimeUpdate()
end

function XUiActivityChapter:OnGetEvents()
    return { XEventId.EVENT_ACTIVITY_CHAPTER_REFRESH_RED }
end

function XUiActivityChapter:OnNotify(evt)
    if evt == XEventId.EVENT_ACTIVITY_CHAPTER_REFRESH_RED then
        -- 刷新所有格子的红点
        for i = 1, self.DynamicTable:GetImpl().TotalCount do
            local grid = self.DynamicTable:GetGridByIndex(i)
            if grid then
                grid:RefreshRedPoint()
            end
        end
    end
end

--=======================================================================
-- 私有方法
--=======================================================================
function XUiActivityChapter:StartTimeUpdate()
    self:StopTimeUpdate()
    self.Timer = XScheduleManager.ScheduleForeverEx(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:StopTimeUpdate()
            return
        end
        self:TimeUpdate()
    end, 1000, 1000)
end

function XUiActivityChapter:StopTimeUpdate()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
    end
    self.Timer = nil
end

function XUiActivityChapter:TimeUpdate()
    local gridList = self.DynamicTable:GetGrids()
    local index = next(gridList)
    local dataList = self:GetActivityData()
    local curDataList = self.DynamicTable.DataSource
    if not index or index > #dataList then
        index = -1
    end
    if #dataList ~= #curDataList then
        self:RefreshActivityList(index)
        return
    end
    
    local recordDir = {}
    for _, data in pairs(dataList) do
        recordDir[data.ExConfig.Id] = true
    end
    for _, data in pairs(curDataList) do
        if not recordDir[data.ExConfig.Id] then
            self:RefreshActivityList(index)
            return
        else
            recordDir[data.ExConfig.Id] = nil
        end
    end
    if next(recordDir) then
        self:RefreshActivityList(index)
    end
end

function XUiActivityChapter:GetDataOrder(data)
    local order = nil
    if CheckClassSuper(data, XExFubenBaseManager) then
        order = data:ExGetConfig().Order
    elseif CheckClassSuper(data, XChapterViewModel) then
        order = data:GetConfig().ChapterCofig.FubenActivityOrder
    end
    
    return order
end

function XUiActivityChapter:RefreshActivityList(index)
    if index == nil then index = 1 end
    local dataList = self:GetActivityData()

    index = math.min(index, #dataList)
    self.DynamicTable:SetDataSource(dataList)
    self.DynamicTable:ReloadDataSync(index)
end

function XUiActivityChapter:GetActivityData()
    local dataList = {}
    -- 活动管理器
    dataList = appendArray(dataList, self.FubenManagerEx.GetActivityManagers())
    -- 节日活动章节
    local festivalManager = self.FubenManagerEx.GetManager(XFubenConfigs.ChapterType.Festival)
    dataList = appendArray(dataList, festivalManager:ExGetChapterViewModels(XFestivalActivityConfig.UiType.Activity))
    -- 这两个表配置了共同的order进行排序
    table.sort(dataList, function (dataA, dataB)
        return self:GetDataOrder(dataA) < self:GetDataOrder(dataB)
    end)
    local festivalManagerIndex = #dataList
    if not self.GetManagerByIndexFunc then
        self.GetManagerByIndexFunc = function(value)
            if festivalManagerIndex >= value then
                return festivalManager
            end
        end
    end
    return dataList
end

function XUiActivityChapter:OnDynamicTableEvent(event, index, grid)
    local data = self.DynamicTable.DataSource[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:EmitSignal("SetMainUiFirstIndexArgs", index)
        local doOpenFun = function ()
            if CheckClassSuper(data, XExFubenBaseManager) then
                data:ExOpenMainUi()
            elseif CheckClassSuper(data, XChapterViewModel) then
                local manager = self.GetManagerByIndexFunc(index)
                manager:ExOpenChapterUi(data)
            end
        end
        
        local dircotr = self.Transform:Find("Animation/DarkDisable"):GetComponent("PlayableDirector")
        local id = 25 -- 2.1临时，由于这个界面打开太卡了，需要强制播放一段黑屏，后续考虑优化成字段
        if data.ExConfig and data.ExConfig.Id == id then
            local isLock = nil
            if CheckClassSuper(data, XExFubenBaseManager) then
                isLock = data:ExGetIsLocked()
            elseif CheckClassSuper(data, XChapterViewModel) then
                isLock = data:GetIsLocked()
            end
            if isLock then
                doOpenFun()
                return
            end

            dircotr:Play()
            XScheduleManager.ScheduleOnce(function()
                doOpenFun()
            end, math.round(dircotr.duration * XScheduleManager.SECOND + 200)) -- 强行加200毫秒，因为动画播不完
        else
            doOpenFun()
        end
    end
end