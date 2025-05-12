---@class XUiGridTerminalTeamQuest
local XUiGridTerminalTeamQuest = XClass(nil, "XUiGridTerminalTeamQuest")

---@param rootUi XUiDormTerminalSystem
function XUiGridTerminalTeamQuest:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)

    self.TeamState = {
        [XDormQuestConfigs.TerminalTeamState.Dispatching] = { GameObject = self.PanelTerminalState.gameObject },
        [XDormQuestConfigs.TerminalTeamState.Dispatched] = { GameObject = self.TerminalFinish.gameObject },
        [XDormQuestConfigs.TerminalTeamState.Empty] = { GameObject = self.TerminalVacant.gameObject },
        [XDormQuestConfigs.TerminalTeamState.Lock] = { GameObject = self.TerminalLock.gameObject },
    }
    self.GridTeamCharacter = {}
end

function XUiGridTerminalTeamQuest:Refresh(data)
    if not data.QuestAccept then
        self.CurState = data.State
        self:SwitchState()
        return
    end
    ---@type XDormQuestAcceptInfo
    self.QuestAccept = data.QuestAccept
    self.QuestId = self.QuestAccept:GetQuestId()
    self.Index = self.QuestAccept:GetIndex()
    self.ResetCount = self.QuestAccept:GetResetCount()
    ---@type XDormQuest
    self.DormQuestViewModel = XDataCenter.DormQuestManager.GetDormQuestViewModel(self.QuestId)
    self:UpdateUiData()
    if self.CurState == XDormQuestConfigs.TerminalTeamState.Dispatched then
        XEventManager.DispatchEvent(XEventId.EVENT_DORM_QUEST_FINISH, true)
    end
end

function XUiGridTerminalTeamQuest:UpdateUiData()
    self.CurState = XDataCenter.DormQuestManager.GetQuestAcceptTeamState(self.QuestAccept)
    self:SwitchState(self.CurState)
    if self.CurState == XDormQuestConfigs.TerminalTeamState.Dispatching then
        self.TxtRank.text = XDormQuestConfigs.GetQuestQualityNameById(self.DormQuestViewModel:GetQuestQuality())
        self.TxtRank.color = XDormQuestConfigs.GetQuestQualityColorById(self.DormQuestViewModel:GetQuestQuality())
        self.TxtTerminalName.text = self.DormQuestViewModel:GetQuestName()
        self:UpdateTeamHead()
        self.FinishTime = self.DormQuestViewModel:GetQuestNeedTime() + self.QuestAccept:GetAcceptTime()
        self:StartTimer()
    else
        self:StopTimer()
    end
end

function XUiGridTerminalTeamQuest:UpdateTeamHead()
    local teamCharacter = self.QuestAccept:GetTeamCharacter()
    for i = 1, #teamCharacter do
        local head = self.GridTeamCharacter[i]
        if not head then
            local go = i == 1 and self.PanelCharacterHead or XUiHelper.Instantiate(self.PanelCharacterHead, self.UiContent)
            head = {}
            XTool.InitUiObjectByUi(head, go)
            self.GridTeamCharacter[i] = head
        end
        head.GameObject:SetActiveEx(true)
        local memberId = teamCharacter[i]
        head.RImgIcon:SetRawImage(XDormConfig.GetCharacterStyleConfigQIconById(memberId))
    end

    for i = #teamCharacter + 1, #self.GridTeamCharacter do
        self.GridTeamCharacter[i].GameObject:SetActiveEx(false)
    end
end

function XUiGridTerminalTeamQuest:SwitchState()
    self.PanelTerminalState.gameObject:SetActiveEx(false)
    self.TerminalFinish.gameObject:SetActiveEx(false)
    self.TerminalVacant.gameObject:SetActiveEx(false)
    self.TerminalLock.gameObject:SetActiveEx(false)
    local go = self.TeamState[self.CurState].GameObject
    if go then
        go:SetActiveEx(true)
    end
end

-- 一键领取奖励
function XUiGridTerminalTeamQuest:OnBtnClick()
    if self.CurState == XDormQuestConfigs.TerminalTeamState.Dispatched and XTool.IsNumberValid(self.QuestId) then
        XDataCenter.DormQuestManager.QuestGetAllRewardRequest(function(finishQuestInfos)
            self.RootUi:QuestFinishReceiveReward(finishQuestInfos)
        end)
    end
end

-- 召回
function XUiGridTerminalTeamQuest:OnBtnCloseClick()
    if self.CurState == XDormQuestConfigs.TerminalTeamState.Dispatching and XTool.IsNumberValid(self.QuestId) then
        self.RootUi:ShowRecallTeamUi(self.Index, self.ResetCount)
    end
end

function XUiGridTerminalTeamQuest:StartTimer()
    if self.Timer then
        self:StopTimer()
    end

    self:UpdateTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTimer()
    end, XScheduleManager.SECOND)
end

function XUiGridTerminalTeamQuest:UpdateTimer()
    if XTool.UObjIsNil(self.TxtTerminalTime) then
        self:StopTimer()
        return
    end

    local endTime = self.FinishTime
    local leftTime = endTime - XTime.GetServerNowTimestamp()
    if leftTime <= 0 then
        self:StopTimer()
        self.CurState = XDormQuestConfigs.TerminalTeamState.Dispatched
        self:SwitchState()
        XEventManager.DispatchEvent(XEventId.EVENT_DORM_QUEST_FINISH, true)
        return
    end
    local timeText = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.DEFAULT)
    self.TxtTerminalTime.text = timeText
end

function XUiGridTerminalTeamQuest:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiGridTerminalTeamQuest:OnClose()
    self:StopTimer()
end

return XUiGridTerminalTeamQuest