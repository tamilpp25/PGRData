local XUiMentorMain = XLuaUiManager.Register(XLuaUi, "UiMentorMain")
local XUiGridTeacher = require("XUi/XUiMentorSystem/MentorMain/XUiGridTeacher")
local XUiGridStudent = require("XUi/XUiMentorSystem/MentorMain/XUiGridStudent")
local CSTextManagerGetText = CS.XTextManager.GetText
local MAX_CHAT_WIDTH = 395
function XUiMentorMain:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:SetButtonCallBack()
    self:InitMentorShip()
    self:InitChatMsg()
    XRedPointManager.AddRedPointEvent(self.PanelInfo, self.OnCheckMentorApplyNews, self, { XRedPointConditions.Types.CONDITION_MENTOR_APPLY_RED})
    XRedPointManager.AddRedPointEvent(self.BtnReward.ReddotObj, self.OnCheckMentorRewardNews, self, { XRedPointConditions.Types.CONDITION_MENTOR_REWARD_RED})
    XRedPointManager.AddRedPointEvent(self.BtnTask.ReddotObj, self.OnCheckMentorTaskNews, self, { XRedPointConditions.Types.CONDITION_MENTOR_TASK_RED})
end

function XUiMentorMain:OnDestroy()
   
end

function XUiMentorMain:OnEnable()
    self:UpdateMentorShip()
    XDataCenter.MentorSystemManager.ShowMentorShipComplete()
    XEventManager.AddEventListener(XEventId.EVENT_CHAT_RECEIVE_MENTOR_MSG, self.RefreshChatMsg, self)
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_TEACHERORSTUDENT_CHANGE, self.UpdateMentorShip, self)
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_MEMBERLEVEL_CHANGE, self.UpdateMentorShip, self)
    XEventManager.AddEventListener(XEventId.EVENT_MENTOR_MESSAGE_UPDATE, self.UpdateMentorShip, self)
end

function XUiMentorMain:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_RECEIVE_MENTOR_MSG, self.RefreshChatMsg, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_TEACHERORSTUDENT_CHANGE, self.UpdateMentorShip, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_MEMBERLEVEL_CHANGE, self.UpdateMentorShip, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MENTOR_MESSAGE_UPDATE, self.UpdateMentorShip, self)
end

function XUiMentorMain:SetButtonCallBack()
    self.BtnTask.CallBack = function()
        self:OnBtnTaskClick()
    end
    self.BtnReward.CallBack = function()
        self:OnBtnRewardClick()
    end
    self.BtnContents.CallBack = function()
        self:OnBtnContentsClick()
    end
    self.BtnRecruit.CallBack = function()
        self:OnBtnRecruitClick()
    end
    self.BtnChat.CallBack = function()
        self:OnBtnChatClick()
    end
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.PanelMessage:GetObject("BtnOpen").CallBack = function()
        self:OnBtnPanelOpenClick()
    end
    self.PanelMessage:GetObject("BtnClose").CallBack = function()
        self:OnBtnPanelCloseClick()
    end
    self.PanelMessage:GetObject("BtnAnnounce").CallBack = function()
        self:OnBtnCreateMessageClick()
    end
    self:BindHelpBtn(self.BtnHelp, "MentorSystemHelp")
end

function XUiMentorMain:InitMentorShip()
    self.GridStudentObj = {
        [1] = self.GridStudentObj1,
        [2] = self.GridStudentObj2,
        [3] = self.GridStudentObj3,
    }

    self.GridStudent = {}
    for index,obj in pairs(self.GridStudentObj or {}) do
        self.GridStudent[index] = XUiGridStudent.New(obj)
    end

    self.GridTutor = XUiGridTeacher.New(self.GridTutorObj)
end

function XUiMentorMain:UpdateMentorShip()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local curChangeTaskCount = mentorData:GetDailyChangeTaskCount()
    local maxChangeTaskCount = XMentorSystemConfigs.GetMentorSystemData("ChangeTaskCount")
    local IsTeacher = mentorData:IsTeacher()
    local IsStudent = mentorData:IsStudent()
    local IsHasQualification = mentorData:CheckIdentity(false)
    local IsShowMessage = IsTeacher or ( IsStudent and mentorData:IsHasTeacher())
    local IsCanUseChat = mentorData:CheckCanUseChat(false) and
    XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SocialChat)
    
    self.PanelLeft.gameObject:SetActiveEx(IsHasQualification)
    self.PanelRight.gameObject:SetActiveEx(IsHasQualification)
    self.PanelLeftBottom.gameObject:SetActiveEx(IsHasQualification)
    self.PanelMessage.gameObject:SetActiveEx(IsShowMessage)
    self.PanelChangeCount.gameObject:SetActiveEx(false)
    self.PanelChangeCount:GetObject("TitleText").text = CSTextManagerGetText("MentorTeacherDayCanChangeTask")
    self.PanelChangeCount:GetObject("CountText").text = maxChangeTaskCount - curChangeTaskCount
    self.PanelMessage:GetObject("BtnAnnounce").gameObject:SetActiveEx(IsTeacher)
    self.BtnChat:SetDisable(not IsCanUseChat)
    self.GridTutor:UpdateGrid(mentorData:GetTeacherData())--师父信息更新
    
    self:UpdatePanelMessage(mentorData)
    
    for index,grid in pairs(self.GridStudent or {}) do--徒弟信息更新
        grid:UpdateGrid(mentorData:GetNotGraduateStudentDataByIndex(index))
    end
end

function XUiMentorMain:UpdatePanelMessage(mentorData)
    local messageData = mentorData:GetMessageData()
    self.MessageText = messageData and messageData.MessageText
    local messageTime = messageData and messageData.PublishTime or 0
    local IsNewMessage = XDataCenter.MentorSystemManager.CheckHasNewMessage(messageTime)
    local IsHasMessage = not string.IsNilOrEmpty(self.MessageText)
    
    self:SetPanelMessageState(IsNewMessage)
    self.PanelMessage:GetObject("TextMessage").text = IsHasMessage and self.MessageText or ""
    self.PanelMessage:GetObject("TextMessage").gameObject:SetActiveEx(IsHasMessage)
    self.PanelMessage:GetObject("TextNone").gameObject:SetActiveEx(not IsHasMessage)
end

function XUiMentorMain:SetPanelMessageState(IsOpen)
    self.PanelMessage:GetObject("PanelShow").gameObject:SetActiveEx(IsOpen)
    self.PanelMessage:GetObject("BtnOpen").gameObject:SetActiveEx(not IsOpen)
end

function XUiMentorMain:OnBtnTaskClick()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    if not mentorData:IsTeacher() then
        local studentData = mentorData:GetStudentDataByIndex(XMentorSystemConfigs.MySelfIndex)
        if not studentData.SystemTask or not next(studentData.SystemTask) then
            XUiManager.TipText("MentorStudentLevelLimitHInt")
            return
        end
    end
    XLuaUiManager.Open("UiMentorTask")
end

function XUiMentorMain:OnBtnRewardClick()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    if mentorData:IsTeacher() then
        XDataCenter.MentorSystemManager.MentorRefreshGraduateTaskRequest(function ()
                XLuaUiManager.Open("UiMentorReward")
            end,false)
    elseif mentorData:IsStudent() then
        XLuaUiManager.Open("UiMentorReward")
    end
end

function XUiMentorMain:OnBtnContentsClick()
    XDataCenter.MentorSystemManager.MentorGetNameListRequest(function ()
            XLuaUiManager.Open("UiMentorFile")
        end)
end

function XUiMentorMain:OnBtnRecruitClick()
    XDataCenter.MentorSystemManager.GetMentorRecommendPlayerListRequest(function ()
        XLuaUiManager.Open("UiMentorRecommendation")
    end)
end

function XUiMentorMain:OnBtnChatClick()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local IsCanUseChat = mentorData:CheckCanUseChat(false)

    if not IsCanUseChat then
        XUiManager.TipText("MentorCanNotUseChatText")
        return
    end 
    
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SocialChat) then
        return
    end
    
    XUiHelper.OpenUiChatServeMain(false, ChatChannelType.Mentor, ChatChannelType.World)
end

function XUiMentorMain:OnBtnBackClick()
    self:Close()
end

function XUiMentorMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiMentorMain:OnBtnPanelOpenClick()
    self:SetPanelMessageState(true)
end

function XUiMentorMain:OnBtnPanelCloseClick()
    self:SetPanelMessageState(false)
end

function XUiMentorMain:OnBtnCreateMessageClick()
    XLuaUiManager.Open("UiMentorAnnouncement", self.MessageText)
end

--更新聊天
function XUiMentorMain:RefreshChatMsg(chatDataLua)
    if not chatDataLua then return end
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SocialChat) then
        return
    end

    self.TxtMessageType.text = CSTextManagerGetText("ChatMentorMsg")

    local name = XDataCenter.SocialManager.GetPlayerRemark(chatDataLua.SenderId, chatDataLua.NickName)
    if chatDataLua.MsgType == ChatMsgType.Emoji then
        self.TxtMessageContent.text = string.format("%s:%s", name, CSTextManagerGetText("EmojiText"))
    else
        self.TxtMessageContent.text = string.format("%s:%s", name, chatDataLua.Content)
    end
    self.TxtMessageLabel.gameObject:SetActiveEx(XUiHelper.CalcTextWidth(self.TxtMessageContent) > MAX_CHAT_WIDTH)
end

function XUiMentorMain:InitChatMsg()
    self.TxtMessageType.text = ""
    self.TxtMessageContent.text = ""
end

function XUiMentorMain:OnCheckMentorApplyNews(count)
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    if mentorData:IsTeacher() then
        for index,grid in pairs(self.GridStudent or {}) do
            grid:ShowReddot(count >= 0)
        end
    else
        self.GridTutor:ShowReddot(count >= 0)
    end
end

function XUiMentorMain:OnCheckMentorRewardNews(count)
    self.BtnReward:ShowReddot(count >= 0)
end

function XUiMentorMain:OnCheckMentorTaskNews(count)
    self.BtnTask:ShowReddot(count >= 0)
end