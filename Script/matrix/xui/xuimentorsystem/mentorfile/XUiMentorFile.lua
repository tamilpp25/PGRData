local XUiMentorFile = XLuaUiManager.Register(XLuaUi, "UiMentorFile")
local XUiPanelTeacher = require("XUi/XUiMentorSystem/MentorFile/XUiPanelTeacher")
local XUiPanelStudent = require("XUi/XUiMentorSystem/MentorFile/XUiPanelStudent")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiMentorFile:OnStart()
    self:SetButtonCallBack()
    self:InitPanel()
    self.GridPlayer.gameObject:SetActiveEx(false)
end

function XUiMentorFile:OnDestroy()
   
end

function XUiMentorFile:OnEnable()
    self:UpdatePanel()
end

function XUiMentorFile:OnDisable()
    
end

function XUiMentorFile:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self:BindHelpBtn(self.BtnHelp, "MentorSystemHelp")
end

function XUiMentorFile:InitPanel()
    local nameList = XDataCenter.MentorSystemManager.GetMentorShipNameList()
    self.TeacherPanel = XUiPanelTeacher.New(self.PanelTeacher)
    self.StudentPanel = XUiPanelStudent.New(self.PanelStudent)
    self.GrandsonStudentPanel = XUiPanelStudent.New(self.PanelGrandsonStudent)
end

function XUiMentorFile:UpdatePanel()
    local nameList = XDataCenter.MentorSystemManager.GetMentorShipNameList()
    self.TeacherPanel:UpdatePanel(nameList.MyTeacher)
    self.StudentPanel:UpdatePanel(nameList.MySchoolmate)
    self.GrandsonStudentPanel:UpdatePanel(nameList.MyStudents)
    
    local myIndex = self.StudentPanel:GetMyIndex()
    local studentNode = self.TeacherPanel:GetParentNode()
    local grandsonStudentNode = self.StudentPanel:GetParentNode(myIndex)
    
    self.StudentPanel:SetParentNode(studentNode)
    self.GrandsonStudentPanel:SetParentNode(grandsonStudentNode)
end

function XUiMentorFile:OnBtnBackClick()
    self:Close()
end

function XUiMentorFile:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end