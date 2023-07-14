local BtnAnswerMaxCount = 3
local tableInsert = table.insert
local tableRemove = table.remove
local CSXTextManagerGetText = CS.XTextManager.GetText
local Vector2 = CS.UnityEngine.Vector2
local ButtonStateDisable = CS.UiButtonState.Disable
local IsNumberValid = XTool.IsNumberValid

local XUiMoeWarChatPools = require("XUi/XUiMoeWar/Recruit/XUiMoeWarChatPools")
local XUiPanelMsgItem = require("XUi/XUiMoeWar/Recruit/XUiPanelMsgItem")
local XUiPanelLineItem = require("XUi/XUiMoeWar/Recruit/XUiPanelLineItem")

local XUiMoeWarRecruitMsgPanel = XClass(nil, "XUiMoeWarRecruitMsgPanel")

function XUiMoeWarRecruitMsgPanel:Ctor(ui, data)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.RefreshContactButtonCb = data.RefreshContactButtonCb   --刷新选择的角色回调
    self.PlayAnimation = data.PlayAnimation  --播放动画方法
    self.ContactButtonClickCallBack = data.ContactButtonClickCallBack    --联络请求回调
    self.ResetCurrSelectContactBtnIndexCb = data.ResetCurrSelectContactBtnIndexCb    --重置当前选择的角色回调

    self.BtnHelp.gameObject:SetActiveEx(false)  --v1.28版本屏蔽援助
    self.PanelTip.gameObject:SetActiveEx(false)
    self:AutoAddListener()

    self.DynamicListManager = XDynamicList.New(self.PanelChatView.transform, self)
    self.DynamicListManager:SetReverse(true)

    self.PanelChatPools = XUiMoeWarChatPools.New(self.PanelSocialPools)
    self.PanelChatPools:InitData(self.DynamicListManager)

    self.InsertDynamicData = {}
    self.PanelChatViewDefaultHeight = self.PanelChatView.rect.height

    self.TempExcludeAnima = {}   --缓存当前问题已播放动画的错误答案

    self:CheckBtnHuifuIsClick()
end

function XUiMoeWarRecruitMsgPanel:OnDisable()
    self:StopInsertDynamicTimer()
    self:StopTimer()
    self:CancelPauseInsertDynamicTimer()
end

function XUiMoeWarRecruitMsgPanel:AutoAddListener()
    self.BtnHelp.CallBack = function() self:OnBtnHelpClick() end
    self.BtnReplyAgain.CallBack = function() self:OnBtnReplyAgainClick() end
    self.BtnGiftGive.CallBack = function() self:OnBtnGiftGiveClick() end

    for i = 1, BtnAnswerMaxCount do
        self["BtnRecord" .. i].CallBack = function() self:OnBtnClickRequestHelperAnswer(i) end
    end
end

function XUiMoeWarRecruitMsgPanel:OnBtnReplyAgainClick()
    self:OnBtnHuifuClickContinueContact()
end

function XUiMoeWarRecruitMsgPanel:OnBtnGiftGiveClick()
    local receiveChatHandlerCb = function(chatData)
        self:ReceiveChatHandler(chatData)
        self:CheckBtnGiftGiveDisable()
    end
    XLuaUiManager.Open("UiMoeWarGiftTips", self.HelperId, receiveChatHandlerCb)
end

function XUiMoeWarRecruitMsgPanel:CheckBtnGiftGiveDisable()
    local helperId = self.HelperId
    local moodValue = XDataCenter.MoeWarManager.GetMoodValue(helperId)
    local moodUpLimit = XMoeWarConfig.GetPreparationHelperMoodUpLimit(helperId)
    local isDisable = moodValue >= moodUpLimit
    self.BtnGiftGive:SetDisable(isDisable, not isDisable)
end

function XUiMoeWarRecruitMsgPanel:SetHelperId(helperId)
    self.HelperId = helperId
    self.BtnHuifu.CallBack = function() self:OnBtnHuifuClick() end
    self.BtnHuifu:SetName(CSXTextManagerGetText("MoeWarRecruitSelectReply"))

    local isDefaultLock = XTool.IsNumberValid(helperId) and XMoeWarConfig.GetPreparationHelperDefaultLock(helperId)
    self.BtnReplyAgain:SetName(not isDefaultLock and CSXTextManagerGetText("MoeWarRecruitNotContact") or CSXTextManagerGetText("MoeWarRecruitReplyAgain"))
end

function XUiMoeWarRecruitMsgPanel:Refresh()
    if not self.HelperId then
        self:SetMsgListPanelIsNone(true)
        return
    end
    
    self.InsertDynamicData = {}
    self.PanelTip.gameObject:SetActiveEx(false)
    self:ChangePanelChatViewHeight(false)
    self:StopInsertDynamicTimer()
    self:CancelPauseInsertDynamicTimer()
    self:SetMsgListPanelIsNone(false)
    
    self:RefreshAnswerRecord()
    self:RefreshPanelChat()
    self:CheckBtnHuifuIsClick()
    self:CheckBtnGiftGiveDisable()
end

function XUiMoeWarRecruitMsgPanel:RefreshAnswerRecord()
    if not self.HelperId then
        return
    end
    self.AnswerRecordsTemplate = XDataCenter.MoeWarManager.GetAnswerRecordsTemplate(self.HelperId)

    local totalCount = XMoeWarConfig.GetMoeWarPreparationHelperTotalQuestionCount(self.HelperId)
    local currCount = XDataCenter.MoeWarManager.GetCurrQuestionCount(self.HelperId)
    local rightCount = XDataCenter.MoeWarManager.GetFinishQuestionCount(self.HelperId)
    self.TextAnswerRecordPerctnt.text = CSXTextManagerGetText("MoeWarAnswerRecordPerctnt", currCount, totalCount)
    self.TextAnswerRecordRightCount.text = CSXTextManagerGetText("MoeWarAnswerRecordRightCount", rightCount)
end

function XUiMoeWarRecruitMsgPanel:RefreshPanelChat()
    local allQuestionTemplate = XDataCenter.MoeWarManager.GetAllQuestionTemplateByHelperId(self.HelperId)
    self:InitWorldChatDynamicList(allQuestionTemplate)
    self:SetBtnHuifuDisable(false)
end

--每间隔一段时间插入一条对话
function XUiMoeWarRecruitMsgPanel:ReceiveChatHandler(chatData)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    for _, v in ipairs(chatData) do
        tableInsert(self.InsertDynamicData, v)
    end

    self:SetBtnHuifuDisable(true)
    self.PanelTip.gameObject:SetActiveEx(false)
    self:ChangePanelChatViewHeight(false)
    self:SetMsgListPanelIsNone(false)
    self:RefreshAnswerRecord()

    self:StartInsertDynamicTimer()
end

function XUiMoeWarRecruitMsgPanel:CheckInsertDynamicDataIsEmptyAndRefresh()
    if XTool.IsTableEmpty(self.InsertDynamicData) then
        self:CheckBtnHuifuIsClick()
        self:StopInsertDynamicTimer()
        return true
    end
    return false
end

function XUiMoeWarRecruitMsgPanel:StartInsertDynamicTimer()
    self:StopInsertDynamicTimer()
    if self.IsPauseInsertDynamicTimer then
        return
    end
    if self:CheckInsertDynamicDataIsEmptyAndRefresh() then
        return
    end
    self.InsertDynamicTimer = XScheduleManager.ScheduleForever(function()
        if not XTool.IsTableEmpty(self.InsertDynamicData) then
            local newChatData = tableRemove(self.InsertDynamicData, 1)
            self.DynamicListManager:InsertData({ newChatData }, DLInsertDataDir.Head, true)
            return
        end
        self:CheckInsertDynamicDataIsEmptyAndRefresh()
    end, 500)
end

function XUiMoeWarRecruitMsgPanel:StopInsertDynamicTimer()
    if self.InsertDynamicTimer then
        XScheduleManager.UnSchedule(self.InsertDynamicTimer)
        self.InsertDynamicTimer = nil
    end
end

function XUiMoeWarRecruitMsgPanel:PauseInsertDynamicTimer()
    self.IsPauseInsertDynamicTimer = true
    self:StopInsertDynamicTimer()
end

function XUiMoeWarRecruitMsgPanel:CancelPauseInsertDynamicTimer(isStartInsertDynamicTimer)
    self.IsPauseInsertDynamicTimer = false
    if isStartInsertDynamicTimer then
        self:StartInsertDynamicTimer()
    end
end

function XUiMoeWarRecruitMsgPanel:InitWorldChatDynamicList(msgData)
    --初始化动态列表数据
    msgData = msgData or {}
    self.DynamicListManager:SetData(msgData, function(data, cb)
        local poolName = nil
        local ctor = nil
        local recruitMsgType = data.RecruitMsgType
        if recruitMsgType == XMoeWarConfig.RecruitMsgType.MyMsg then
            poolName = "myMsg"
            ctor = XUiPanelMsgItem.New
        elseif recruitMsgType == XMoeWarConfig.RecruitMsgType.OtherMsg or recruitMsgType == XMoeWarConfig.RecruitMsgType.GiftThank then
            poolName = "otherMsg"
            ctor = XUiPanelMsgItem.New
        elseif recruitMsgType == XMoeWarConfig.RecruitMsgType.MyNo then
            poolName = "myNo"
            ctor = XUiPanelMsgItem.New
        elseif recruitMsgType == XMoeWarConfig.RecruitMsgType.MyYes then
            poolName = "myYes"
            ctor = XUiPanelMsgItem.New
        elseif recruitMsgType == XMoeWarConfig.RecruitMsgType.Line then
            poolName = "line"
            ctor = XUiPanelLineItem.New
        end
        if cb and poolName and ctor then
            local item = cb(poolName, ctor)
            item.RootUi = self
            item.PauseInsertDynamicTimer = handler(self, self.PauseInsertDynamicTimer)
            item.CancelPauseInsertDynamicTimer = handler(self, self.CancelPauseInsertDynamicTimer)
            item:Refresh(data, self.HelperId)
        else
            XLog.Error("------Init MoeWarRecruitMsg item is error!------")
        end
    end)
end

function XUiMoeWarRecruitMsgPanel:SetMsgListPanelIsNone(isNone)
    self.PanelJindu.gameObject:SetActiveEx(XMoeWarConfig.GetPreparationHelperDefaultLock(self.HelperId) and not isNone)
    self.Content.gameObject:SetActiveEx(not isNone)
    self.PanelNone.gameObject:SetActiveEx(isNone)
    if isNone then
        self.PanelTip.gameObject:SetActiveEx(false)
        self:SetBtnHuifuDisable(true)
    end
end

function XUiMoeWarRecruitMsgPanel:OnBtnHuifuClick()
    local activeSelf = self.PanelTip.gameObject.activeSelf
    self:RefreshHuifuPanel(not activeSelf)
    self:ChangePanelChatViewHeight(not activeSelf)
    self.PanelTip.gameObject:SetActiveEx(not activeSelf)
    if self.PanelTipCanvasGroup and not activeSelf then
        self.PanelTipCanvasGroup.alpha = 0
    end
    if self.PlayAnimation and not activeSelf then
        self.PlayAnimation("PanelTipEnable")
    end
end

function XUiMoeWarRecruitMsgPanel:OnBtnHuifuClickContinueContact()
    if self.ContactButtonClickCallBack then
        self:SetBtnReplyAgainDisable(true)
        self.ContactButtonClickCallBack(self.HelperId)
    end
end

function XUiMoeWarRecruitMsgPanel:OnBtnHuifuClickClose()
    self.BtnHuifu.CallBack = function() self:OnBtnHuifuClick() end
    self:SetMsgListPanelIsNone(true)
    self.HelperId = nil
    self:CheckBtnHuifuIsClick()
    if self.ResetCurrSelectContactBtnIndexCb then
        self.ResetCurrSelectContactBtnIndexCb()
    end
end

function XUiMoeWarRecruitMsgPanel:ChangePanelChatViewHeight(activeSelf)
    local defaultWidth = self.PanelChatView.rect.width
    local height = activeSelf and self.PanelChatViewDefaultHeight * 0.6 or self.PanelChatViewDefaultHeight
    self.PanelChatView:SetInsetAndSizeFromParentEdge(CS.UnityEngine.RectTransform.Edge.Top, 0, height)
    self.DynamicListManager:SetViewSize(Vector2(defaultWidth, height), true)
end

--刷新回答问题
function XUiMoeWarRecruitMsgPanel:RefreshHuifuPanel(activeSelf)
    if not activeSelf or not self.AnswerRecordsTemplate then
        return
    end

    local questionId
    local questionType
    for _, template in ipairs(self.AnswerRecordsTemplate) do
        local tempQuestionId = template:GetQuestionId()
        questionType = XMoeWarConfig.GetPreparationQuestionType(tempQuestionId)
        if questionType == XMoeWarConfig.QuestionType.RandomQuestion and template:GetAnswerId() == 0 then
            questionId = tempQuestionId
            break
        end
    end
    if not questionId then return end

    if not self.TempExcludeAnima[questionId] then
        self.TempExcludeAnima = {}
        self.TempExcludeAnima[questionId] = {}
    end

    local answers = XMoeWarConfig.GetPreparationQuestionAnswers(questionId)
    local isExcludeWrongAnswer
    for i = 1, BtnAnswerMaxCount do
        if answers[i] then
            local btnRecord = self["BtnRecord" .. i]
            btnRecord:SetNameByGroup(0, answers[i])
            isExcludeWrongAnswer = XDataCenter.MoeWarManager.IsExcludeWrongAnswer(i)
            btnRecord:SetDisable(isExcludeWrongAnswer, not isExcludeWrongAnswer)
            btnRecord.gameObject:SetActiveEx(true)
            if not self.TempExcludeAnima[questionId][i] and isExcludeWrongAnswer and self.PlayAnimation then
                self.TempExcludeAnima[questionId][i] = true
            end
        else
            self["BtnRecord" .. i].gameObject:SetActiveEx(false)
        end
    end

    local assistanceCount = XDataCenter.MoeWarManager.GetAssistanceCount()
    local assistanceMaxCount = XMoeWarConfig.GetPreparationAssistanceSupportMaxCount()
    self.BtnHelp:SetNameByGroup(1, assistanceCount .. "/" .. assistanceMaxCount)
    self.BtnHelp:SetDisable(assistanceCount == 0)

    local recoveryTime = XDataCenter.MoeWarManager.GetAssistanceRecoveryTime()
    if recoveryTime > 0 then
        self:RefreshRecoveryTime(recoveryTime)
        self:StartTimer(recoveryTime)
    else
        self:StopTimer()
        self.TextTime.text = ""
    end
end

function XUiMoeWarRecruitMsgPanel:RefreshRecoveryTime(recoveryTime)
    local nowServerTime = XTime.GetServerNowTimestamp()
    local lastTime = recoveryTime - nowServerTime
    if lastTime <= 0 then
        self.TextTime.text = ""
        self:StopTimer()
        self:RefreshHuifuPanel(true)
        return
    end

    local timeStr = XUiHelper.GetTime(lastTime, XUiHelper.TimeFormatType.DEFAULT)
    self.TextTime.text = CSXTextManagerGetText("MoeWarAssistanceRecoveryTime", timeStr)
end

function XUiMoeWarRecruitMsgPanel:StartTimer(recoveryTime)
    self:StopTimer()
    local recoveryTime = recoveryTime
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:RefreshRecoveryTime(recoveryTime)
    end, XScheduleManager.SECOND)
end

function XUiMoeWarRecruitMsgPanel:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiMoeWarRecruitMsgPanel:OnBtnHelpClick()
    XDataCenter.MoeWarManager.RequestMoeWarPreparationAssistance(self.HelperId, function()
        self:RefreshHuifuPanel(true)
    end)
end

function XUiMoeWarRecruitMsgPanel:OnBtnClickRequestHelperAnswer(answerIndex)
    self:OnBtnHuifuClick()
    local refreshCb = function()
        if self.RefreshContactButtonCb then
            self.RefreshContactButtonCb()
        end
    end

    local receiveChatHandlerCb = function(chatData)
        self:ReceiveChatHandler(chatData)
    end

    XDataCenter.MoeWarManager.RequestMoeWarPreparationHelperAnswer(self.HelperId, answerIndex, refreshCb, receiveChatHandlerCb)
end

function XUiMoeWarRecruitMsgPanel:CheckBtnHuifuIsClick()
    local helperId = self.HelperId

    if not IsNumberValid(helperId) then
        self.PanelTip.gameObject:SetActiveEx(false)
        self:SetHelperId(helperId)
        self:SetBtnHuifuDisable(true)
        self:SetPanelBtnActive(XMoeWarConfig.PreparationHelperStatus.NotCommunicating)
        return
    end

    local status = XDataCenter.MoeWarManager.GetRecruitHelperStatus(helperId)
    self:SetPanelBtnActive(status)

    --招募失败，设置按钮为继续联络
    if status == XMoeWarConfig.PreparationHelperStatus.CommunicationEnd then
        self.BtnHuifu:SetName(CSXTextManagerGetText("MoeWarRecruitContinueContact"))
        self.BtnHuifu.CallBack = function() self:OnBtnHuifuClickContinueContact() end
        self:SetBtnHuifuDisable(false)
        return
    end

    self:SetHelperId(helperId)
    if status ~= XMoeWarConfig.PreparationHelperStatus.Communicating and status ~= XMoeWarConfig.PreparationHelperStatus.RecruitFinishAndCommunicating then
        self.PanelTip.gameObject:SetActiveEx(false)
        self:SetBtnHuifuDisable(true)
    else
        self:SetBtnHuifuDisable(false)
    end
end

function XUiMoeWarRecruitMsgPanel:SetBtnHuifuDisable(isDisable)
    self.BtnHuifu:SetDisable(isDisable, not isDisable)
end

function XUiMoeWarRecruitMsgPanel:SetBtnReplyAgainDisable(isDisable)
    self.BtnReplyAgain:SetDisable(isDisable, not isDisable)
end

function XUiMoeWarRecruitMsgPanel:SetPanelBtnActive(status)
    local helperId = self.HelperId
    if not IsNumberValid(helperId) then
        self.BtnHuifu.gameObject:SetActiveEx(true)
        self.PanelBtnCommunicationEnd.gameObject:SetActiveEx(false)
        return
    end

    local isDefaultLock = XMoeWarConfig.GetPreparationHelperDefaultLock(helperId)
    local isRecruitFinish = status == XMoeWarConfig.PreparationHelperStatus.RecruitFinish or not isDefaultLock
    self.BtnHuifu.gameObject:SetActiveEx(not isRecruitFinish)
    self.PanelBtnCommunicationEnd.gameObject:SetActiveEx(isRecruitFinish)

    --默认解锁的角色不可点击再次答题
    self:SetBtnReplyAgainDisable(not isDefaultLock)
end

function XUiMoeWarRecruitMsgPanel:NotifyRefreshHuifuPanel()
    local activeSelf = self.PanelTip.gameObject.activeSelf
    if activeSelf then
        self:RefreshHuifuPanel(true)
    end
end

return XUiMoeWarRecruitMsgPanel