local XUiMentorReward = XLuaUiManager.Register(XLuaUi, "UiMentorReward")
local XUiPanelTeacherReward = require("XUi/XUiMentorSystem/MentorReward/XUiPanelTeacherReward")
local XUiPanelStudentReward = require("XUi/XUiMentorSystem/MentorReward/XUiPanelStudentReward")

function XUiMentorReward:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:SetButtonCallBack()
    
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    self.PanelTeacherReward = {}
    self.PanelStudentReward = {}

    if mentorData:IsTeacher() then
        self.PanelTeacherReward = XUiPanelTeacherReward.New(self.PanelMentor, self)
    elseif mentorData:IsStudent() then
        self.PanelStudentReward = XUiPanelStudentReward.New(self.PanelStudent, self)
    end
end

function XUiMentorReward:OnDestroy()
   
end

function XUiMentorReward:OnEnable()
    self:UpdatePanel()
    XDataCenter.MentorSystemManager.ShowMentorShipComplete()
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_STUDENT_TASKCOUNT_CHANGE, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_TEACHERORSTUDENT_CHANGE, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_GETREWARD, self.UpdatePanel, self)
end

function XUiMentorReward:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_STUDENT_TASKCOUNT_CHANGE, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_TEACHERORSTUDENT_CHANGE, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_GETREWARD, self.UpdatePanel, self)
end

function XUiMentorReward:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self:BindHelpBtn(self.BtnHelp, "MentorSystemRewardHelp")
end

function XUiMentorReward:UpdatePanel()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    self.PanelMentor.gameObject:SetActiveEx(mentorData:IsTeacher())
    self.PanelStudent.gameObject:SetActiveEx(mentorData:IsStudent())
    
    if mentorData:IsTeacher() then
        self.PanelTeacherReward:UpdatePanel()
        self:PlayAnimation("PanelMentorQieHuan")
    elseif mentorData:IsStudent() then
        self.PanelStudentReward:UpdatePanel()
        self:PlayAnimation("PanelStudentQieHuan")
    end
end

function XUiMentorReward:OnBtnBackClick()
    self:Close()
end

function XUiMentorReward:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end