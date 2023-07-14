local XUiArchiveStoryDetail = XLuaUiManager.Register(XLuaUi, "UiArchiveStoryDetail")
local FirstIndex = 1

function XUiArchiveStoryDetail:OnStart(dataList, index)
    self:SetButtonCallBack()
    self:InitDynamicTable()
    self:Init(dataList, index)
end

function XUiArchiveStoryDetail:OnDestroy()
end

function XUiArchiveStoryDetail:Init(dataList, index)
    local data = dataList and dataList[index]
    if data then
        self.Data = data
        self.DataList = dataList
        self.DataIndex = index
        self.UnLockCount = 0
        self:SetupDynamicTable()
        self:SetStoryData()
        self:CheckNextMonsterAndPreMonster()
    end
end

function XUiArchiveStoryDetail:SetStoryData()
    for _, story in pairs(self.PageDatas) do
        if not story:GetIsLock() then
            self.UnLockCount = self.UnLockCount + 1
        end
    end

    self.StoryTitleTxt.text = self.Data:GetName()
    self.LevelText.text = string.format("%d/%d", self.UnLockCount, #self.PageDatas)
    local width = self.Data:GetBgWidth() ~= 0 and self.Data:GetBgWidth() or 1
    local high = self.Data:GetBgHigh() ~= 0 and self.Data:GetBgHigh() or 1
    self.StoryImgAspect.aspectRatio = width / high
    self.StoryImg:SetRawImage(self.Data:GetBg())
end

function XUiArchiveStoryDetail:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.StoryChapterDetailScrollView)
    self.DynamicTable:SetProxy(XUiGridArchiveStoryDetail)
    self.DynamicTable:SetDelegate(self)
    self.ChapterDetailItem.gameObject:SetActiveEx(false)
end

function XUiArchiveStoryDetail:SetupDynamicTable()
    self.PageDatas = XDataCenter.ArchiveManager.GetArchiveStoryDetailList(self.Data:GetId())
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiArchiveStoryDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas and self.PageDatas[index] or nil, self)
    end
end

function XUiArchiveStoryDetail:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnRight.CallBack = function()
        self:OnBtnNextClick()
    end
    self.BtnLeft.CallBack = function()
        self:OnBtnLastClick()
    end
end

function XUiArchiveStoryDetail:OnBtnBackClick()
    self:Close()
end

function XUiArchiveStoryDetail:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiArchiveStoryDetail:OnBtnNextClick()
    if self.NextIndex == 0 then
        return
    end
    self:Init(self.DataList, self.NextIndex)
end

function XUiArchiveStoryDetail:OnBtnLastClick()
    if self.PreviousIndex == 0 then
        return
    end
    self:Init(self.DataList, self.PreviousIndex)
end

function XUiArchiveStoryDetail:CheckNextMonsterAndPreMonster()
    self.NextIndex = self:CheckNext(self.DataIndex + 1)
    self.PreviousIndex = self:CheckPrevious(self.DataIndex - 1)

    if self.NextIndex == 0 then
        self.NextIndex = self:CheckNext(FirstIndex)
    end

    if self.PreviousIndex == 0 then
        self.PreviousIndex = self:CheckPrevious(#self.DataList)
    end
end

function XUiArchiveStoryDetail:CheckNext(index)
    local next = 0
    for i = index , #self.DataList , 1 do
        local tmpData = self.DataList[i]
        if tmpData and not tmpData:GetIsLock() then
            next = i
            break
        end
    end
    return next
end

function XUiArchiveStoryDetail:CheckPrevious(index)
    local previous = 0
    for i = index , FirstIndex , -1 do
        local tmpData = self.DataList[i]
        if tmpData and not tmpData:GetIsLock() then
            previous = i
            break
        end
    end
    return previous
end