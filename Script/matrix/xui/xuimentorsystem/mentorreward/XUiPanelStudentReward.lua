local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPanelStudentReward = XClass(nil, "XUiPanelStudentReward")
local XUiPanelStudentGraduateReward = require("XUi/XUiMentorSystem/MentorReward/XUiPanelStudentGraduateReward")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiPanelStudentReward:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)

    self:SetButtonCallBack()
    self:InitDynamicTable()
    self:InitTaskGroup()
    self:InitGraduateReward()
end

function XUiPanelStudentReward:SetButtonCallBack()

end

function XUiPanelStudentReward:InitGraduateReward()
    self.GraduateReward = XUiPanelStudentGraduateReward.New(self.PanelRewaed, self.Base)
    self.GraduateReward:UpdatePanel()
end

function XUiPanelStudentReward:InitTaskGroup()
    self.TaskTabList = {
        [1] = self.BtnPayTab1,
        [2] = self.BtnPayTab2,
    }

    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    self.CurTaskType = XMentorSystemConfigs.StudentRewardType.Grow
    self.PanelTopTabGroup:Init(self.TaskTabList, function(index) self:SelectTaskType(index) end)
    self.PanelTopTabGroup:SelectIndex(self.CurTaskType)
end

function XUiPanelStudentReward:SelectTaskType(index)
    self.CurTaskType = index
    self:SetupDynamicTable()
    self.PanelPrompt:GetObject("Grow").gameObject:SetActiveEx(index == XMentorSystemConfigs.StudentRewardType.Grow)
    self.PanelPrompt:GetObject("Graduate").gameObject:SetActiveEx(index == XMentorSystemConfigs.StudentRewardType.Graduate)
end

function XUiPanelStudentReward:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskDailyList)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiPanelStudentReward:SetupDynamicTable()
    self.PageDatas = {}
    if self.CurTaskType == XMentorSystemConfigs.StudentRewardType.Grow then
        self.PageDatas = XDataCenter.TaskManager.GetMentorGrowFullTaskList() or {}
    elseif self.CurTaskType == XMentorSystemConfigs.StudentRewardType.Graduate then
        self.PageDatas = XDataCenter.TaskManager.GetMentorGraduateFullTaskList() or {}
    end
    
    self.PanelNoneDailyTask.gameObject:SetActiveEx(not next(self.PageDatas))
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelStudentReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid.RootUi = self.Base
        grid:ResetData(self.PageDatas[index])
    end
end

function XUiPanelStudentReward:UpdatePanel()
    self.GraduateReward:UpdatePanel()
    self:SetupDynamicTable()
    self:CheckRedDot()
end

function XUiPanelStudentReward:CheckRedDot()
    local IsGrowShow = XDataCenter.TaskManager.GetIsRewardFor(XDataCenter.TaskManager.TaskType.MentorShipGrow)
    local IsGraduateShow = XDataCenter.TaskManager.GetIsRewardFor(XDataCenter.TaskManager.TaskType.MentorShipGraduate)
    self.TaskTabList[XMentorSystemConfigs.StudentRewardType.Grow]:ShowReddot(IsGrowShow)
    self.TaskTabList[XMentorSystemConfigs.StudentRewardType.Graduate]:ShowReddot(IsGraduateShow)
end

return XUiPanelStudentReward