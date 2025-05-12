local XUiPanelActive = require("XUi/XUiTask/XUiPanelActive")
local XDynamicTableCurve = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableCurve")
local textManager = CS.XTextManager
local tableInsert = table.insert
local XUiGridClickClearGamePage = require("XUi/XUiClickClearGame/XUiGridClickClearGamePage")
local XUiClickClearPanelGameTask = require("XUi/XUiClickClearGame/XUiClickClearPanelGameTask")
local XUiClickClearPanelGameBookMark = require("XUi/XUiClickClearGame/XUiClickClearPanelGameBookMark")

local XUiClickClearPanelGame = XClass(nil, "XUiClickClearPanelGame")

function XUiClickClearPanelGame:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiClickClearPanelGame:Init()
    self.TaskPanel = XUiClickClearPanelGameTask.New(self.PanelTask, self)
    self.BookMarkPanel = XUiClickClearPanelGameBookMark.New(self.PanelBookMark, self)

    self:AutoAddBtnListener()
    self:InitDynamicTable()
end

function XUiClickClearPanelGame:Show()
    self.GameObject:SetActiveEx(true)
    self.DynamicTableCurve:Clear()
    local gameInfo = XDataCenter.XClickClearGameManager.GetGameInfo()
    self.TaskPanel:Show()
    self.BookMarkPanel:Show()
    self.DynamicTableCurve:SetDataSource(gameInfo.HeadInfoPageList)
    self.DynamicTableCurve:ReloadData(0)
end

function XUiClickClearPanelGame:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiClickClearPanelGame:AutoAddBtnListener()
    self:RegisterClickEvent(self.BtnLast, function () self:OnClickLastBtn() end)
    self:RegisterClickEvent(self.BtnNext, function () self:OnClickNextBtn() end)
end

function XUiClickClearPanelGame:OnClickLastBtn()
    local nextIndex = XDataCenter.XClickClearGameManager.GetLastPageIndex()
    self.DynamicTableCurve:TweenToIndex(nextIndex)
    
end

function XUiClickClearPanelGame:OnClickNextBtn()
    local lastIndex = XDataCenter.XClickClearGameManager.GetNextPageIndex()
    self.DynamicTableCurve:TweenToIndex(lastIndex)
    
end

function XUiClickClearPanelGame:InitDynamicTable()
    self.DynamicTableCurve = XDynamicTableCurve.New(self.PageParent)
    self.DynamicTableCurve:SetProxy(XUiGridClickClearGamePage)
    self.DynamicTableCurve:SetDelegate(self)
end

function XUiClickClearPanelGame:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(index)
    end
end

function XUiClickClearPanelGame:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelActive:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelActive:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

return XUiClickClearPanelGame