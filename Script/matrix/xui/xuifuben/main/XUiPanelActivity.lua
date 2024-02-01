local XChapterViewModel = require("XEntity/XFuben/XChapterViewModel")

--######################## XUiGridActivity ########################
local XUiGridActivity = XClass(nil, "XUiGridActivity")

function XUiGridActivity:Ctor(ui)
    self.Data = nil
    XUiHelper.InitUiClass(self, ui)
end

-- data : XExFubenBaseManager | XChapterViewModel
function XUiGridActivity:SetData(data)
    self.Data = data
    if XDataCenter.FubenManagerEx.IsFubenBase(data) then
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
    if XDataCenter.FubenManagerEx.IsFubenBase(self.Data) then
        self.Red.gameObject:SetActiveEx(self.Data:ExCheckIsShowRedPoint())
    elseif CheckClassSuper(self.Data, XChapterViewModel) then
        self.Red.gameObject:SetActiveEx(self.Data:CheckHasRedPoint())
    end
end

function XUiGridActivity:RefreshTimeTips()
    local runningTimeStr
    if XDataCenter.FubenManagerEx.IsFubenBase(self.Data) then
        runningTimeStr = self.Data:ExGetRunningTimeStr()
    elseif CheckClassSuper(self.Data, XChapterViewModel) then
        runningTimeStr = self.Data:GetTimeTips()
    end
    self.PanelLeftTime.gameObject:SetActiveEx(not string.IsNilOrEmpty(runningTimeStr))
    self.TxtLeftTime.text = runningTimeStr
end

function XUiGridActivity:IsActivityEnd()
    local onGoing
    if XDataCenter.FubenManagerEx.IsFubenBase(self.Data) then
        onGoing = self.Data:ExCheckInTime()
    elseif CheckClassSuper(self.Data, XChapterViewModel) then
        onGoing = self.Data:CheckInTime()
    end
    return not onGoing
end

--######################## XUiPanelActivity ########################
local XUiPanelActivity = XClass(XSignalData, "XUiPanelActivity")

function XUiPanelActivity:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    self.RootUi = rootUi
    self.FubenManagerEx = XDataCenter.FubenManagerEx
    self.DynamicTable = XDynamicTableNormal.New(self.PanelChapterList)
    self.DynamicTable:SetProxy(XUiGridActivity)
    self.DynamicTable:SetDelegate(self)
    self.GridActivityBanner.gameObject:SetActive(false)
    self.GetManagerByIndexFunc = nil
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

function XUiPanelActivity:SetData(managerIndex)
    self:RefreshActivityList(managerIndex)
end

function XUiPanelActivity:OnEnable()
    -- 刷新所有格子的红点
    for i = 1, self.DynamicTable:GetImpl().TotalCount do
        local grid = self.DynamicTable:GetGridByIndex(i)
        if grid then
            grid:RefreshRedPoint()
        end
    end
end

function XUiPanelActivity:TimeUpdate()
    for i, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:RefreshTimeTips()
        if grid:IsActivityEnd() then
            self:RefreshActivityList(i)
        end
    end
end

function XUiPanelActivity:GetDataOrder(data)
    local order = nil
    if self.FubenManagerEx.IsFubenBase(data) then
        order = data:ExGetConfig().Order
    elseif CheckClassSuper(data, XChapterViewModel) then
        order = data:GetConfig().ChapterCofig.FubenActivityOrder
    end
    
    return order
end

function XUiPanelActivity:RefreshActivityList(index)
    if index == nil then index = 1 end
    local datas = {}
    -- 活动管理器
    datas = appendArray(datas, self.FubenManagerEx.GetActivityManagers())
    -- 节日活动章节
    local festivalManager = self.FubenManagerEx.GetManager(XFubenConfigs.ChapterType.Festival)
    datas = appendArray(datas, festivalManager:ExGetChapterViewModels(XFestivalActivityConfig.UiType.Activity))
    -- 这两个表配置了共同的order进行排序
    table.sort(datas, function (dataA, dataB)
        return self:GetDataOrder(dataA) < self:GetDataOrder(dataB)
    end)

    local festivalManagerIndex = #datas
    index = math.min(index, #datas)
    self.DynamicTable:SetDataSource(datas)
    self.DynamicTable:ReloadDataSync(index)
    self.GetManagerByIndexFunc = function(value)
        if festivalManagerIndex >= value then
            return festivalManager
        end
    end
end

function XUiPanelActivity:OnDynamicTableEvent(event, index, grid)
    local data = self.DynamicTable.DataSource[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:EmitSignal("SetMainUiFirstIndexArgs", index)
        if self.FubenManagerEx.IsFubenBase(data) then
            data:ExOpenMainUi()
        elseif CheckClassSuper(data, XChapterViewModel) then
            local manager = self.GetManagerByIndexFunc(index)
            manager:ExOpenChapterUi(data)
        end
    end
end

function XUiPanelActivity:Open()
    self.GameObject:SetActiveEx(true)
    self.RootUi.RImgFestivalBg.gameObject:SetActiveEx(true)
end

function XUiPanelActivity:Close()
    self.RootUi.RImgFestivalBg.gameObject:SetActiveEx(false)
    self:EmitSignal("SetMainUiFirstIndexArgs", 0)
    self.GameObject:SetActiveEx(false)
    self:EmitSignal("Close")
end

return XUiPanelActivity