local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiMentorTask = XLuaUiManager.Register(XLuaUi, "UiMentorTask")
local XUiPanelTeacherTask = require("XUi/XUiMentorSystem/MentorTask/XUiPanelTeacherTask")
local XUiPanelStudentTask = require("XUi/XUiMentorSystem/MentorTask/XUiPanelStudentTask")

function XUiMentorTask:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:SetButtonCallBack()
    
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    self.PanelTeacherTask = {}
    self.PanelStudentTask = {}

    if mentorData:IsTeacher() then
        self.PanelTeacherTask = XUiPanelTeacherTask.New(self.PanelMentor, self)
    elseif mentorData:IsStudent() then
        self.PanelStudentTask = XUiPanelStudentTask.New(self.PanelStudent, self)
    end
    
    XDataCenter.MentorSystemManager.MarkFirstShowTaskGetRedDot()
    XEventManager.DispatchEvent(XEventId.EVENT_MENTOR_INTASKUI)
end

function XUiMentorTask:OnDestroy()
   
end

function XUiMentorTask:OnEnable()
    self:UpdatePanel()
    XDataCenter.MentorSystemManager.ShowMentorShipComplete()
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_TEACHER_STUDENTSYSTEMTASK_CHANGE, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_TEACHER_STUDENTWEEKLYTASK_CHANGE, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_STUDENT_WEEKLYTASK_CHANGE, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_STUDENT_SYSTEMTASK_CHANGE, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_TEACHER_CHANGECOUNT_PLUS, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_DAY_RESET, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_WEEK_RESET, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_GETREWARD, self.UpdatePanel, self)
end

function XUiMentorTask:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_TEACHER_STUDENTSYSTEMTASK_CHANGE, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_TEACHER_STUDENTWEEKLYTASK_CHANGE, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_STUDENT_WEEKLYTASK_CHANGE, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_STUDENT_SYSTEMTASK_CHANGE, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_TEACHER_CHANGECOUNT_PLUS, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_DAY_RESET, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_WEEK_RESET, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_GETREWARD, self.UpdatePanel, self)
end

function XUiMentorTask:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self:BindHelpBtn(self.BtnHelp, "MentorSystemTaskHelp")
end

function XUiMentorTask:UpdatePanel()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    self.PanelMentor.gameObject:SetActiveEx(mentorData:IsTeacher())
    self.PanelStudent.gameObject:SetActiveEx(mentorData:IsStudent())
    
    if mentorData:IsTeacher() then
        self.PanelTeacherTask:UpdatePanel()
        self:CheckTeacherGift()
    elseif mentorData:IsStudent() then
        self.PanelStudentTask:UpdatePanel()
    end
end

function XUiMentorTask:OnBtnBackClick()
    self:Close()
end

function XUiMentorTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiMentorTask:CheckTeacherGift()
    local giftData = XDataCenter.MentorSystemManager.ShowTeacherGift()
    if giftData then
        local reward = XRewardManager.CreateRewardGoods(giftData.ItemId, giftData.Count)
        XUiManager.OpenUiObtain({reward})
    end
end