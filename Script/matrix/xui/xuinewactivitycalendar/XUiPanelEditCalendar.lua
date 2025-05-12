local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridEditCalendar = require("XUi/XUiNewActivityCalendar/XUiGridEditCalendar")

---@class XUiPanelEditCalendar : XUiNode
---@field _Control XNewActivityCalendarControl
---@field Parent XUiMainLeftCalendar
local XUiPanelEditCalendar = XClass(XUiNode, "XUiPanelEditCalendar")

function XUiPanelEditCalendar:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnTips, self.OnBtnTipsClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSave, self.OnBtnSaveClick)
    XUiHelper.RegisterClickEvent(self, self.BtnResetting, self.OnBtnResettingClick)

    self.GridActivity.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
    self.IsEdited = false
end

function XUiPanelEditCalendar:OnEnable()
    self.EditDataList = self._Control:GetWeekEditInfos()
    self.EditCount = table.nums(self.EditDataList)
    self.IsEdited = false
end

function XUiPanelEditCalendar:Refresh()
    self:SetupDynamicTable()
end

function XUiPanelEditCalendar:OnDisable()
    self.EditDataList = {}
    self.DataList = {}
    self.EditCount = 0
    self.IsEdited = false
end

function XUiPanelEditCalendar:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEditList)
    self.DynamicTable:SetProxy(XUiGridEditCalendar, self, handler(self, self.OnBtnUpClick), handler(self, self.OnBtnTogClick))
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelEditCalendar:GetEditDataList()
    local dataList = {}
    for _, data in pairs(self.EditDataList) do
        dataList[data.Index] = data.MainId
    end
    return dataList
end

function XUiPanelEditCalendar:SetupDynamicTable()
    self.DataList = self:GetEditDataList()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridEditCalendar
function XUiPanelEditCalendar:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateTheme(self.Parent.ThemeData)
        local mainId = self.DataList[index]
        local isShow = self.EditDataList[mainId].IsShow or false
        grid:Refresh(mainId, index, isShow)
    end
end

-- 上移按钮点击处理
function XUiPanelEditCalendar:OnBtnUpClick(index)
    local lastIndex = index - 1
    local curIndex = index
    local lastMainId = self.DataList[lastIndex]
    local curMainId = self.DataList[curIndex]
    self.EditDataList[curMainId].Index = lastIndex
    self.EditDataList[lastMainId].Index = curIndex
    self.IsEdited = true
    self:SetupDynamicTable()
end

-- 是否显示按钮点击处理
function XUiPanelEditCalendar:OnBtnTogClick(index, isShow)
    local curMainId = self.DataList[index]
    if not isShow then
        for i = index + 1, self.EditCount do
            local mainId = self.DataList[i]
            self.EditDataList[mainId].Index = i - 1
        end
        self.EditDataList[curMainId].Index = self.EditCount
    else
        local maxShowIndex = 0
        for i, mainId in ipairs(self.DataList) do
            if self.EditDataList[mainId].IsShow and i > maxShowIndex then
                maxShowIndex = i
            end
        end
        for i = maxShowIndex + 1, index - 1 do
            local mainId = self.DataList[i]
            self.EditDataList[mainId].Index = i + 1
        end
        self.EditDataList[curMainId].Index = maxShowIndex + 1
    end
    self.EditDataList[curMainId].IsShow = isShow
    self.IsEdited = true
    self:SetupDynamicTable()
end

function XUiPanelEditCalendar:GetIsEdited()
    return self.IsEdited
end

function XUiPanelEditCalendar:SaveEditDataList()
    if XMain.IsEditorDebug then
        local maxIndex = 0
        for _, data in pairs(self.EditDataList) do
            if data.Index > maxIndex then
                maxIndex = data.Index
            end
        end
        if maxIndex ~= self.EditCount then
            XLog.Error("编辑数据排序有问题", self.EditDataList)
        end
    end
    self._Control:SaveWeekEditActivityInfos(self.EditDataList)
    XUiManager.TipMsg(self._Control:GetClientConfig("CalendarEditSaveTipContent", 1))
end

function XUiPanelEditCalendar:OnBtnTipsClick()
    XUiManager.ShowHelpTip(self._Control:GetClientConfig("CalendarHelpKey"))
end

function XUiPanelEditCalendar:OnBtnSaveClick()
    self:SaveEditDataList()
    self.Parent:OpenActivityCalendar()
end

function XUiPanelEditCalendar:OnBtnResettingClick()
    local title = self._Control:GetClientConfig("CalendarEditResetTitle")
    local content = self._Control:GetClientConfig("CalendarEditResetContent")
    XUiManager.DialogTip(title, content, nil, nil, function()
        self.IsEdited = false
        self._Control:SaveWeekEditActivityInfos({})
        self.EditDataList = self._Control:GetWeekEditInfos()
        self.EditCount = table.nums(self.EditDataList)
        self:SetupDynamicTable()
    end)
end

return XUiPanelEditCalendar