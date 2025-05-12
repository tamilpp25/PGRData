---@class XUiDlcMultiPlayerDiscussion
---@field CtrlDiscussion XUiComponent.XUiStateControl
---@field TxtDiscussionTime UnityEngine.UI.Text
---@field TxtDiscussionStatus UnityEngine.UI.Text
---@field TxtDiscussionRate UnityEngine.UI.Text
---@field TxtDiscussionTitle UnityEngine.UI.Text
---@field TxtChoice UnityEngine.UI.Text
---@field BtnDiscussion XUiComponent.XUiButton
---@field _Control XDlcMultiMouseHunterControl
---@field ImgBg UnityEngine.UI.RawImage
local XUiDlcMultiPlayerDiscussion = XClass(XUiNode, "XUiDlcMultiPlayerDiscussion")

local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMultiplayerDiscussionCamp
local StatusEnum = XMVCA.XDlcMultiMouseHunter.DlcMultiplayerDiscussionStatus

function XUiDlcMultiPlayerDiscussion:OnStart()
    --变量声明
    self._DiscussionTimer = nil

    --注册点击事件
    XUiHelper.RegisterClickEvent(self, self.BtnDiscussion, self.OnBtnDiscussionClick)
end

function XUiDlcMultiPlayerDiscussion:OnEnable()
    --注册事件监听
    XEventManager.AddEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_DISCUSSION_DATA, self._RefreshDiscussion, self)

    --业务初始化
    self:_RefreshDiscussion()
end

function XUiDlcMultiPlayerDiscussion:OnDisable()
    --移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_DISCUSSION_DATA, self._RefreshDiscussion, self)

    --移除定时器
    self:_RemoveDiscussionTimer()
end

-- region 业务逻辑
function XUiDlcMultiPlayerDiscussion:_RefreshDiscussion()
    self:_RemoveDiscussionTimer()

    local discussion = self._Control:GetDiscussion()
    if not discussion:HasDiscussionData() or not discussion:HasPlayerData() then
        self.GameObject:SetActiveEx(false)
        return
    end

    -- local discussionConfig = discussion:GetTable()
    local discussionStatus = discussion:GetStatus()
    local discussionPlayerCamp = discussion:GetPlayerCamp()
    if discussionStatus == StatusEnum.None then
        self.GameObject:SetActiveEx(false)
        return
    end

    self.GameObject:SetActiveEx(true)
    -- self.TxtDiscussionTitle.text = discussionConfig.Discussion
    self.TxtChoice.text = XUiHelper.GetText("MultiMouseHunterChoice")

    if discussionStatus == StatusEnum.Vote then --投票期
        if discussionPlayerCamp == CampEnum.None then --未选择阵营
            self:_RefreshVoteUnSelect(discussion)
        else --已经选择阵营
            self:_RefreshVoteSelect(discussion)
        end
    elseif discussionStatus == StatusEnum.Show then --展示期
        if discussionPlayerCamp == CampEnum.None then --未选择阵营
            self:_RefreshDisplayUnSelect(discussion)
        else --已经选择阵营
            if discussion:IsPlayerVectory() then --胜利
                self:_RefreshDisplayVictory(discussion)
            else -- 失败
                self:_RefreshDisplayFail(discussion)
            end
        end
    end
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerDiscussion:_RefreshVoteUnSelect(discussion)
    self.CtrlDiscussion:ChangeState("VoteUnSelect")
    self.TxtDiscussionStatus.text = XUiHelper.GetText("MultiMouseHunterVoteStatus")
    self.TxtDiscussionRate.text = XUiHelper.GetText("MultiMouseHunterVoteUnSelect")
    self.ImgBg:SetRawImage(self._Control:GetDlcMultiplayerConfigConfigByKey("DiscussionNormalIcon").Values[1])
    self:_RefreshDiscussionTimer(function()
        self:_RefreshTxtDiscussionTime(discussion:GetVoteEndTimestamp())
    end)
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerDiscussion:_RefreshVoteSelect(discussion)
    local titleStr, rateStr = self:_GetPlayerDiscussionText(discussion)
    self.CtrlDiscussion:ChangeState("VoteSelect")
    self.TxtDiscussionStatus.text = XUiHelper.GetText("MultiMouseHunterVoteStatus")
    self.TxtDiscussionTitle.text = titleStr
    self.TxtDiscussionRate.text = rateStr
    self.ImgBg:SetRawImage(self._Control:GetDlcMultiplayerConfigConfigByKey("DiscussionChoiceIcon").Values[1])
    self:_RefreshDiscussionTimer(function()
        self:_RefreshTxtDiscussionTime(discussion:GetVoteEndTimestamp())
    end)
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerDiscussion:_RefreshDisplayUnSelect(discussion)
    self.CtrlDiscussion:ChangeState("DisplayUnSelect")
    self.TxtDiscussionStatus.text = XUiHelper.GetText("MultiMouseHunterDisplayStatus")
    self.TxtDiscussionRate.text = XUiHelper.GetText("MultiMouseHunterVoteUnSelect")
    self.ImgBg:SetRawImage(self._Control:GetDlcMultiplayerConfigConfigByKey("DiscussionNormalIcon").Values[1])
    self:_RefreshDiscussionTimer(function()
        self:_RefreshTxtDiscussionTime(discussion:GetDiscussionEndTimestamp())
    end)
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerDiscussion:_RefreshDisplayVictory(discussion)
    local titleStr, rateStr = self:_GetPlayerDiscussionText(discussion)
    self.CtrlDiscussion:ChangeState("DisplayVictory")
    self.TxtDiscussionStatus.text = XUiHelper.GetText("MultiMouseHunterDisplayStatus")
    self.TxtDiscussionTitle.text = titleStr
    self.TxtDiscussionRate.text = rateStr
    self.ImgBg:SetRawImage(self._Control:GetDlcMultiplayerConfigConfigByKey("DiscussionWinIcon").Values[1])
    self:_RefreshDiscussionTimer(function()
        self:_RefreshTxtDiscussionTime(discussion:GetDiscussionEndTimestamp())
    end)
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerDiscussion:_RefreshDisplayFail(discussion)
    local titleStr, rateStr = self:_GetPlayerDiscussionText(discussion)
    self.CtrlDiscussion:ChangeState("DisplayFail")
    self.TxtDiscussionStatus.text = XUiHelper.GetText("MultiMouseHunterDisplayStatus")
    self.TxtDiscussionTitle.text = titleStr
    self.TxtDiscussionRate.text = rateStr
    self.ImgBg:SetRawImage(self._Control:GetDlcMultiplayerConfigConfigByKey("DiscussionNormalIcon").Values[1])
    self:_RefreshDiscussionTimer(function()
        self:_RefreshTxtDiscussionTime(discussion:GetDiscussionEndTimestamp())
    end)
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerDiscussion:_GetPlayerDiscussionText(discussion)
    local discussionConfig = discussion:GetTable()
    local isCamp1 = discussion:GetPlayerCamp() == CampEnum.Camp1

    local discussionPlayerCampTitle = isCamp1 and discussionConfig.Camp1 or discussionConfig.Camp2
    local discussionPlayerCampRateStr
    if discussion:IsStatistics() then
        discussionPlayerCampRateStr = XUiHelper.GetText("MultiMouseHunterStatistics")
    else
        discussionPlayerCampRateStr = isCamp1 and discussion:GetCamp1RatioStr() or discussion:GetCamp2RatioStr()
    end
    return discussionPlayerCampTitle, discussionPlayerCampRateStr
end

function XUiDlcMultiPlayerDiscussion:_RefreshTxtDiscussionTime(endTimestamp)
    if XTool.UObjIsNil(self.TxtDiscussionTime) then
        return
    end

    local timestamp = endTimestamp - XTime.GetServerNowTimestamp()
    timestamp = timestamp >= 0 and timestamp or 0
    self.TxtDiscussionTime.text = XUiHelper.GetText("MultiMouseHunterVoteRemainTime", XUiHelper.GetTime(timestamp, XUiHelper.TimeFormatType.ACTIVITY))
end
-- endregion

-- region 按钮事件
function XUiDlcMultiPlayerDiscussion:OnBtnDiscussionClick()
    self._Control:OpenUiDlcMultiPlayerCompetition(self.Parent._BeginMatchTime)
end
-- endregion

-- region 定时器
function XUiDlcMultiPlayerDiscussion:_RemoveDiscussionTimer()
    if self._DiscussionTimer then
        XScheduleManager.UnSchedule(self._DiscussionTimer)
        self._DiscussionTimer = nil
    end
end

function XUiDlcMultiPlayerDiscussion:_RefreshDiscussionTimer(func)
    self:_RemoveDiscussionTimer()
    if func then
        self._DiscussionTimer = XScheduleManager.ScheduleForever(func, 1000)
    end
end
-- endregion

return XUiDlcMultiPlayerDiscussion