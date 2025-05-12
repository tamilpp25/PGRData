local XUiDlcMultiPlayerCompetitionCamp = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMultiPlayerDiscussion/XUiDlcMultiPlayerCompetitionCamp")

---@class XUiDlcMultiPlayerCompetition : XLuaUi
---@field BtnClose XUiComponent.XUiButton
---@field BtnVote XUiComponent.XUiButton
---@field TxtTitle UnityEngine.UI.Text
---@field TxtTime UnityEngine.UI.Text
---@field TxtBpTips UnityEngine.UI.Text
---@field TxtVote UnityEngine.UI.Text
---@field BtnBlue XUiComponent.XUiButton
---@field BtnRed XUiComponent.XUiButton
---@field BlueCampPanel UnityEngine.RectTransform
---@field RedCampPanel UnityEngine.RectTransform
---@field _Control XDlcMultiMouseHunterControl
---@field BlueSelectObject UnityEngine.RectTransform
---@field RedSelectObject UnityEngine.RectTransform
local XUiDlcMultiPlayerCompetition = XLuaUiManager.Register(XLuaUi, "UiDlcMultiPlayerCompetition")

local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMultiplayerDiscussionCamp
local StatusEnum = XMVCA.XDlcMultiMouseHunter.DlcMultiplayerDiscussionStatus

function XUiDlcMultiPlayerCompetition:OnAwake()
    --变量声明
    self._CurSelectCamp = nil
    self._DiscussionTimer = nil
    self._CurDiscussionStatus = StatusEnum.None
    self._IsShowRewardUi = false
    ---@type XUiDlcMultiPlayerCompetitionCamp
    self._BlueCamp = XUiDlcMultiPlayerCompetitionCamp.New(self.BlueCampPanel, self, CampEnum.Camp1)
    ---@type XUiDlcMultiPlayerCompetitionCamp
    self._RedCamp = XUiDlcMultiPlayerCompetitionCamp.New(self.RedCampPanel, self, CampEnum.Camp2)
end

function XUiDlcMultiPlayerCompetition:OnStart()
    --注册点击事件
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
    self:RegisterClickEvent(self.BtnBlue, self.OnBtnBlueClick, true)
    self:RegisterClickEvent(self.BtnRed, self.OnBtnRedClick, true)
    self:RegisterClickEvent(self.BtnVote, self.OnBtnVoteClick, true)
end

function XUiDlcMultiPlayerCompetition:OnEnable()
    --注册事件监听
    XEventManager.AddEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_DISCUSSION_DATA, self._RefreshDiscussion, self)

    --业务初始化
    self:_RefreshDiscussion()
end

function XUiDlcMultiPlayerCompetition:OnDisable()
    --移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_DISCUSSION_DATA, self._RefreshDiscussion, self)

    --业务数据还原
    if self._IsShowRewardUi then
        XLuaUiManager.SafeClose("UiObtain")    
    end
    self:_ResetUserData()
    self._CurDiscussionStatus = StatusEnum.None

    --移除定时器
    self:_RemoveDiscussionTimer()
end

function XUiDlcMultiPlayerCompetition:_ResetUserData()
    self._CurSelectCamp = nil
    self._IsShowRewardUi = false
end

-- region 业务逻辑
function XUiDlcMultiPlayerCompetition:_RefreshDiscussion()
    self:_RemoveDiscussionTimer()

    local discussion = self._Control:GetDiscussion()
    if not discussion:HasDiscussionData() and not discussion:HasPlayerData() then
        self:Close()
        return
    end

    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()
    if not discussionConfig then
        self:Close()
        return
    end

    local discussionStatus = discussion:IsSameDiscussion() and discussion:GetStatus() or StatusEnum.Show
    if discussionStatus == StatusEnum.None then
        self:Close()
        return
    end

    if self._CurDiscussionStatus ~= discussionStatus then
        self._CurDiscussionStatus = discussionStatus
        self:_ResetUserData()
    end

    self.TxtTitle.text = discussionConfig.Discussion
    self.TxtTime.text = ""

    local discussionPlayerCamp = discussion:GetPlayerCamp()
    if discussionStatus == StatusEnum.Vote then --投票期
        if discussionPlayerCamp == CampEnum.None then --未选择阵营
            self:_RefreshVoteUnSelect(discussion)
        else --已经选择阵营
            self:_RefreshVoteSelect(discussion)
        end
    elseif discussionStatus == StatusEnum.Show then --展示期
        self:_RefreshDisplay(discussion)
    end
end

function XUiDlcMultiPlayerCompetition:_RefreshSelectCamp(selectCamp, enableClick, voteTxt, btnTxt)
    local discussion = self._Control:GetDiscussion()

    self._CurSelectCamp = selectCamp
    if selectCamp == CampEnum.Camp1 then
        self.BtnVote:SetButtonState(CS.UiButtonState.Normal)
        self.BtnVote.enabled = enableClick
        self.BlueSelectObject.gameObject:SetActiveEx(true)
        self.BtnBlue.enabled = false
        self.RedSelectObject.gameObject:SetActiveEx(false)
        self.BtnRed.enabled = enableClick
        if btnTxt then
            self.BtnBlue:SetName(btnTxt)
            self.BtnRed:SetName(XUiHelper.GetText("MultiMouseHunterSubUnVote"))
            self.BtnBlue:SetButtonState(CS.UiButtonState.Select)
            self.BtnRed:SetButtonState(CS.UiButtonState.Normal)
        end
    elseif selectCamp == CampEnum.Camp2 then
        self.BtnVote:SetButtonState(CS.UiButtonState.Normal)
        self.BtnVote.enabled = enableClick
        self.BlueSelectObject.gameObject:SetActiveEx(false)
        self.BtnBlue.enabled = enableClick
        self.RedSelectObject.gameObject:SetActiveEx(true)
        self.BtnRed.enabled = false
        if btnTxt then
            self.BtnBlue:SetName(XUiHelper.GetText("MultiMouseHunterSubUnVote"))
            self.BtnRed:SetName(btnTxt)
            self.BtnBlue:SetButtonState(CS.UiButtonState.Normal)
            self.BtnRed:SetButtonState(CS.UiButtonState.Select)
        end
    else
        self.BtnVote:SetButtonState(CS.UiButtonState.Disable)
        self.BtnVote.enabled = false
        self.BlueSelectObject.gameObject:SetActiveEx(false)
        self.BtnBlue.enabled = enableClick
        self.RedSelectObject.gameObject:SetActiveEx(false)
        self.BtnRed.enabled = enableClick
        if btnTxt then
            self.BtnBlue:SetName(XUiHelper.GetText("MultiMouseHunterSubUnVote"))
            self.BtnRed:SetName(XUiHelper.GetText("MultiMouseHunterSubUnVote"))
            self.BtnBlue:SetButtonState(CS.UiButtonState.Normal)
            self.BtnRed:SetButtonState(CS.UiButtonState.Normal)
        end
    end

    local camp = discussion:GetPlayerCamp()
    if camp ~= CampEnum.None then
        self.BtnVote:SetButtonState(CS.UiButtonState.Disable)
        self.BtnVote.enabled = false
    end

    if voteTxt then
        self.BtnVote:SetName(voteTxt)
        self.BtnVote.gameObject:SetActiveEx(true)
    else
        self.BtnVote.gameObject:SetActiveEx(false)
    end

    if not btnTxt then
        self.BtnBlue:SetButtonState(CS.UiButtonState.Disable)
        self.BtnRed:SetButtonState(CS.UiButtonState.Disable)
    end
end

function XUiDlcMultiPlayerCompetition:_RefreshTxtDiscussionTime(endTimestamp)
    if XTool.UObjIsNil(self.TxtTime) then
        return
    end

    local timestamp = endTimestamp - XTime.GetServerNowTimestamp()
    timestamp = timestamp >= 0 and timestamp or 0
    self.TxtTime.text = XUiHelper.GetText("MultiMouseHunterVoteRemainTime", XUiHelper.GetTime(timestamp, XUiHelper.TimeFormatType.ACTIVITY))
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetition:_RefreshVoteUnSelect(discussion)
    self.TxtTime.gameObject:SetActiveEx(true)
    self.TxtBpTips.gameObject:SetActiveEx(true)
    self.TxtBpTips.text = XUiHelper.GetText("MultiMouseHunterVoteBP", self._Control:GetBpLevel())
    self._BlueCamp:VoteUnSelect(discussion)
    self._RedCamp:VoteUnSelect(discussion)
    self:_RefreshSelectCamp(self._CurSelectCamp, true, XUiHelper.GetText("MultiMouseHunterUnVote"), XUiHelper.GetText("MultiMouseHunterSubUnVote"))
    self:_RefreshDiscussionTimer(function()
        self:_RefreshTxtDiscussionTime(discussion:GetVoteEndTimestamp())
    end)
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetition:_RefreshVoteSelect(discussion)
    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()
    self.TxtTime.gameObject:SetActiveEx(true)
    self.TxtBpTips.gameObject:SetActiveEx(true)
    self.TxtBpTips.text = XUiHelper.GetText("MultiMouseHunterVoteCount", self._Control:GetBpLevel())
    self._BlueCamp:VoteSelect(discussion)
    self._RedCamp:VoteSelect(discussion)
    local camp = discussion:GetPlayerCamp()
    local campStr = camp == CampEnum.Camp1 and discussionConfig.Camp1 or discussionConfig.Camp2
    self:_RefreshSelectCamp(camp, false, XUiHelper.GetText("MultiMouseHunterVoted", campStr), XUiHelper.GetText("MultiMouseHunterSubVoted"))
    self:_RefreshDiscussionTimer(function()
        self:_RefreshTxtDiscussionTime(discussion:GetVoteEndTimestamp())
    end)
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetition:_RefreshDisplay(discussion)
    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()
    self.TxtTime.gameObject:SetActiveEx(true)
    self.TxtTime.text = XUiHelper.GetText("MultiMouseHunterVoteEnd")

    if discussion:IsPlayerCamp1Vectory() then
        self._BlueCamp:DisplayVictory(discussion)
        self._RedCamp:DisplayFail(discussion)
    elseif discussion:IsPlayerCamp2Vectory() then
        self._BlueCamp:DisplayFail(discussion)
        self._RedCamp:DisplayVictory(discussion)
    else
        self._BlueCamp:DisplayFail(discussion)
        self._RedCamp:DisplayFail(discussion)
    end

    local camp = discussion:GetPlayerCamp()
    if camp ~= CampEnum.None then
        self.TxtBpTips.gameObject:SetActiveEx(true)
        self.TxtBpTips.text = XUiHelper.GetText("MultiMouseHunterVoteCount", self._Control:GetBpLevel())
        local campStr = camp == CampEnum.Camp1 and discussionConfig.Camp1 or discussionConfig.Camp2
        self:_RefreshSelectCamp(camp, false, XUiHelper.GetText("MultiMouseHunterVoted", campStr), nil)
    else
        self.TxtBpTips.gameObject:SetActiveEx(false)
        self:_RefreshSelectCamp(camp, false, nil, nil)
    end

    self:_CheckGetReward()
end

function XUiDlcMultiPlayerCompetition:_CheckGetReward()
    local discussion = self._Control:GetDiscussion()
    if not discussion:CanGetReward() or self._IsShowRewardUi then
        return
    end
    self._IsShowRewardUi = true

    local discussion = self._Control:GetDiscussion()
    local activityConfig = self._Control:GetDlcMultiplayerActivityConfig()
    local rewardCount = discussion:IsPlayerVectory() and activityConfig.DiscussionWinExp or activityConfig.DiscussionFailExp

    XUiManager.OpenUiObtain({ {
        RewardType = XRewardManager.XRewardType.Item,
        TemplateId = activityConfig.BpExpItem,
        Count = rewardCount
    } })
end
-- endregion

-- region 按钮事件
function XUiDlcMultiPlayerCompetition:OnBtnCloseClick()
    local discussion = self._Control:GetDiscussion()
    if discussion:CanGetReward() and self._IsShowRewardUi then
        local lastDiscussionId = discussion:GetId()
        XMVCA.XDlcMultiMouseHunter:RequestGetDiscussionVoteReward(function()
            if lastDiscussionId == discussion:GetId() and discussion:GetStatus() == StatusEnum.Show then
                self:Close()
            end
        end)
    else
        self:Close()
    end
end

function XUiDlcMultiPlayerCompetition:OnBtnBlueClick()
    if not self:_IsCanSelectCamp() then
        return
    end
    local discussion = self._Control:GetDiscussion()
    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()
    self:_RefreshSelectCamp(CampEnum.Camp1, true, XUiHelper.GetText("MultiMouseHunterVote", discussionConfig.Camp1), XUiHelper.GetText("MultiMouseHunterSubVote", discussionConfig.Camp1))
    self._BlueCamp:VoteUnSelect_Select(discussion)
    self._RedCamp:VoteUnSelect_UnSelect(discussion)
end

function XUiDlcMultiPlayerCompetition:OnBtnRedClick()
    if not self:_IsCanSelectCamp() then
        return
    end
    local discussion = self._Control:GetDiscussion()
    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()
    self:_RefreshSelectCamp(CampEnum.Camp2, true, XUiHelper.GetText("MultiMouseHunterVote", discussionConfig.Camp2), XUiHelper.GetText("MultiMouseHunterSubVote", discussionConfig.Camp2))
    self._BlueCamp:VoteUnSelect_UnSelect(discussion)
    self._RedCamp:VoteUnSelect_Select(discussion)
end

function XUiDlcMultiPlayerCompetition:_IsCanSelectCamp()
    local discussion = self._Control:GetDiscussion()
    return discussion:GetPlayerCamp() == CampEnum.None and discussion:GetStatus() == StatusEnum.Vote
end

function XUiDlcMultiPlayerCompetition:OnBtnVoteClick()
    if not self:_IsCanSelectCamp() then 
        return
    end
    
    if not self._CurSelectCamp or self._CurSelectCamp == CampEnum.None then
        return
    end
    XMVCA.XDlcMultiMouseHunter:RequestPlayerDiscussionVote(self._CurSelectCamp)
end
-- endregion

-- region 定时器
function XUiDlcMultiPlayerCompetition:_RemoveDiscussionTimer()
    if self._DiscussionTimer then
        XScheduleManager.UnSchedule(self._DiscussionTimer)
        self._DiscussionTimer = nil
    end
end

function XUiDlcMultiPlayerCompetition:_RefreshDiscussionTimer(func)
    self:_RemoveDiscussionTimer()
    if func then
        self._DiscussionTimer = XScheduleManager.ScheduleForever(func, 1000)
    end
end
-- endregion

return XUiDlcMultiPlayerCompetition