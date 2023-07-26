local XUiLoginVerification = XLuaUiManager.Register(XLuaUi, "UiLoginVerification")

local SelectionSerial = {'A','B','C','D','E','F'}
local SplitChar = CsXTextManagerGetText("LoginUserAgreeItemAnd")
--local LimitedLoginQuizState = {
--    UnAnswered = 0,
--    Correct = 1,
--    InCorrect = 2,
--}

function XUiLoginVerification:OnAwake()
    self:AutoAddListener()
    self:InitUiView()
    self.GridOptionNoImageList = {}
    self.GridOptionList = {}
end

function XUiLoginVerification:OnStart(quizList)
    self.QuizList = quizList
    self.QuizIndex = 1
    self:Refresh()
end

function XUiLoginVerification:OnEnable()
end

function XUiLoginVerification:AutoAddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClick() end
end

function XUiLoginVerification:InitUiView()
    self.TxtTip.text = XUiHelper.ReadTextWithNewLine("LoginLimitTip")
end

function XUiLoginVerification:Refresh()
    self.LastTime = XTime.GetServerNowTimestamp()
    local quiz = self.QuizList[self.QuizIndex]
    --while quiz and quiz.State == LimitedLoginQuizState.Correct do
    --    self.QuizIndex = self.QuizIndex + 1
    --    quiz = self.QuizList[self.QuizIndex]
    --end

    if not quiz then
        self:Close()
        return
    end

    self.TxtNo.text = self.QuizIndex .. SplitChar
    self.TxtQuestion.text = quiz.Title
    self.TxtProgress.text = CsXTextManagerGetText("LoginLimitProgress", self.QuizIndex, #self.QuizList)
    local noImage = string.IsNilOrEmpty(quiz.ImagePath)
    self.PanelOptionNoImage.gameObject:SetActiveEx(noImage)
    self.PanelOptionWithImage.gameObject:SetActiveEx(not noImage)

    self:MessUpOptions(quiz.Answers)
    if noImage then
        self:ShowOption(self.PanelOptionNoImage, self.GridOptionNoImageList)
    else
        self.RImgIcon:SetRawImage(quiz.ImagePath)
        self:ShowOption(self.PanelOption, self.GridOptionList)
    end
end

function XUiLoginVerification:MessUpOptions(answers)
    self.SelectIndex = nil
    self.OptionList = {}
    for i, v in ipairs(answers) do
        self.OptionList[i] = {Index = i, Content = v}
    end

    XTool.RandomBreakTableOrder(self.OptionList)
end

function XUiLoginVerification:ShowOption(panel, gridList)
    local gridOption = panel:Find("GridOption")
    local btnList = {}
    for i, v in ipairs(self.OptionList) do
        local item = gridList[i]
        if not item then
            item = CS.UnityEngine.GameObject.Instantiate(gridOption, panel)
            gridList[i] = item
        end
        item:Find("TxtOption"):GetComponent("Text").text = SelectionSerial[i] .. SplitChar .. v.Content
        btnList[i] = item:Find("BtnOption"):GetComponent("XUiButton")
        btnList[i]:SetButtonState(XUiButtonState.Normal)
        item.gameObject:SetActiveEx(true)
    end

    for i = #self.OptionList + 1, #gridList do
        gridList[i].gameObject:SetActiveEx(false)
    end
    gridOption.gameObject:SetActiveEx(false)

    self.BtnGroup:Init(btnList, function(index) self:OnSelectOption(index) end)
end

function XUiLoginVerification:OnSelectOption(index)
    self.SelectIndex = index
end

function XUiLoginVerification:OnAnswerRight()
    if self.QuizIndex >= #self.QuizList then
        XUiManager.TipText("LoginLimitPass")
        self:Close()
        XScheduleManager.ScheduleOnce(function()
            XLoginManager.ClearLimitLogin()
        end, 1500)
    else
        XUiManager.TipText("LoginLimitRightAnswer")
        self.QuizIndex = self.QuizIndex + 1
        self:Refresh()
    end
end

function XUiLoginVerification:OnAnswerWrong()
    XUiManager.TipText("LoginLimitWrongAnswer")
    XScheduleManager.ScheduleOnce(function()
        self:Close()
        XLoginManager.DoDisconnect()
    end, 1500)
end

-- auto
function XUiLoginVerification:OnBtnCloseClick()
    self:Close()
end

function XUiLoginVerification:OnBtnConfirmClick()
    if not self.SelectIndex then
        XUiManager.TipText("LoginLimitNoSelection")
        return
    end

    local nowTime = XTime.GetServerNowTimestamp()
    XLoginManager.SendLoginVerify(self.QuizIndex, self.OptionList[self.SelectIndex].Index, nowTime - self.LastTime,function(result)
        if result == true then
            self:OnAnswerRight()
        else
            self:OnAnswerWrong()
        end
    end)
end
