---@class XUiDlcMultiPlayerCompetitionCamp
---@field CtrlDiscussion XUiComponent.XUiStateControl
---@field TxtDiscussionRate UnityEngine.UI.Text
---@field ImgDiscussionVictoryIcon UnityEngine.UI.RawImage
---@field TxtDiscussionVictory UnityEngine.UI.Text
---@field TxtDiscussionReward UnityEngine.UI.Text
---@field ImgDiscussionRewardIcon UnityEngine.UI.RawImage
---@field TxtDiscussionRewardCount UnityEngine.UI.Text
---@field TxtDiscussionTitle UnityEngine.UI.Text
---@field TxtDiscussionTitle2 UnityEngine.UI.Text
---@field TxtDiscussionSupport UnityEngine.UI.Text
---@field ImgSupport UnityEngine.UI.Image
local XUiDlcMultiPlayerCompetitionCamp = XClass(XUiNode, "XUiDlcMultiPlayerCompetitionCamp")

local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMultiplayerDiscussionCamp

function XUiDlcMultiPlayerCompetitionCamp:OnStart(camp)
    self.TitleUnSelectColor = CS.UnityEngine.Color(46 / 255, 57 / 255, 72 / 255, 200 / 255)
    self.TitleUnSelectOutlineColor = CS.UnityEngine.Color(0, 0, 0, 0)
    self.TitleSelectColor = CS.UnityEngine.Color(255 / 255, 211 / 255, 112 / 255, 255 / 255)
    self.TitleSelectOutlineColor = CS.UnityEngine.Color(0, 0, 0, 1)
    self.TitleWhiteColor = CS.UnityEngine.Color(1, 1, 1, 1)

    self._CurCamp = camp
    self.TxtDiscussionSupport.text = XUiHelper.GetText("MultiMouseHunterChoice")
    self.TxtDiscussionTitleOutline = self.TxtDiscussionTitle.gameObject:GetComponent("XUiTextOutline")
end

-- region 业务逻辑
---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetitionCamp:VoteUnSelect(discussion)
    self.CtrlDiscussion:ChangeState("VoteUnSelect")
    if self._CurCamp == CampEnum.Camp1 then
        self.TxtDiscussionTitle.text = discussion:GetTable().Camp1
        self.TxtDiscussionTitle2.text = discussion:GetTable().Camp1Des
    elseif self._CurCamp == CampEnum.Camp2 then
        self.TxtDiscussionTitle.text = discussion:GetTable().Camp2
        self.TxtDiscussionTitle2.text = discussion:GetTable().Camp2Des
    else
        self.TxtDiscussionTitle.text = ""
        self.TxtDiscussionTitle2.text = ""
    end

    self.TxtDiscussionTitleOutline.outlineColor = self.TitleSelectOutlineColor
    self.TxtDiscussionTitle.color = self.TitleWhiteColor
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetitionCamp:VoteUnSelect_Select(discussion)
    self.CtrlDiscussion:ChangeState("VoteUnSelect")
    if self._CurCamp == CampEnum.Camp1 then
        self.TxtDiscussionTitle.text = discussion:GetTable().Camp1
        self.TxtDiscussionTitle2.text = discussion:GetTable().Camp1Des
    elseif self._CurCamp == CampEnum.Camp2 then
        self.TxtDiscussionTitle.text = discussion:GetTable().Camp2
        self.TxtDiscussionTitle2.text = discussion:GetTable().Camp2Des
    else
        self.TxtDiscussionTitle.text = ""
        self.TxtDiscussionTitle2.text = ""
    end

    self.TxtDiscussionTitleOutline.outlineColor = self.TitleSelectOutlineColor
    self.TxtDiscussionTitle.color = self.TitleSelectColor
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetitionCamp:VoteUnSelect_UnSelect(discussion)
    self.CtrlDiscussion:ChangeState("VoteUnSelect")
    if self._CurCamp == CampEnum.Camp1 then
        self.TxtDiscussionTitle.text = discussion:GetTable().Camp1
        self.TxtDiscussionTitle2.text = discussion:GetTable().Camp1Des
    elseif self._CurCamp == CampEnum.Camp2 then
        self.TxtDiscussionTitle.text = discussion:GetTable().Camp2
        self.TxtDiscussionTitle2.text = discussion:GetTable().Camp2Des
    else
        self.TxtDiscussionTitle.text = ""
        self.TxtDiscussionTitle2.text = ""
    end

    self.TxtDiscussionTitleOutline.outlineColor = self.TitleUnSelectOutlineColor
    self.TxtDiscussionTitle.color = self.TitleUnSelectColor
    self.TxtDiscussionTitle.text = string.format("“%s”", self.TxtDiscussionTitle.text)
end


---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetitionCamp:VoteSelect(discussion)
    self.CtrlDiscussion:ChangeState("VoteSelect")

    local discussionConfig = discussion:GetTable()
    local isStatistics = discussion:IsStatistics()

    if self._CurCamp == CampEnum.Camp1 then
        self.TxtDiscussionTitle.text = discussionConfig.Camp1
        self.TxtDiscussionTitle2.text = discussion:GetTable().Camp1Des
        self.TxtDiscussionRate.text = isStatistics and XUiHelper.GetText("MultiMouseHunterStatistics") or discussion:GetCamp1RatioStr()
    elseif self._CurCamp == CampEnum.Camp2 then
        self.TxtDiscussionTitle.text = discussionConfig.Camp2
        self.TxtDiscussionTitle2.text = discussion:GetTable().Camp2Des
        self.TxtDiscussionRate.text = isStatistics and XUiHelper.GetText("MultiMouseHunterStatistics") or discussion:GetCamp2RatioStr()
    else
        self.TxtDiscussionTitle.text = ""
        self.TxtDiscussionTitle2.text = ""
        self.TxtDiscussionRate.text = ""
    end

    if self._CurCamp == discussion:GetPlayerCamp() then
        self.TxtDiscussionTitle.color = self.TitleSelectColor
        self.TxtDiscussionTitleOutline.outlineColor = self.TitleSelectOutlineColor
        self.ImgSupport.gameObject:SetActiveEx(true)
    else
        self.TxtDiscussionTitle.color = self.TitleUnSelectColor
        self.TxtDiscussionTitleOutline.outlineColor = self.TitleUnSelectOutlineColor
        self.TxtDiscussionTitle.text = string.format("“%s”", self.TxtDiscussionTitle.text)
        self.ImgSupport.gameObject:SetActiveEx(false)
    end
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetitionCamp:DisplayVictory(discussion)
    self.CtrlDiscussion:ChangeState("DisplayVictory")

    local activityConfig = self._Control:GetDlcMultiplayerActivityConfig()
    local bpExpIcon = XDataCenter.ItemManager.GetItemIcon(activityConfig.BpExpItem)
    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()

    self.ImgDiscussionRewardIcon:SetRawImage(bpExpIcon)

    self.TxtDiscussionReward.text = XUiHelper.GetText("MultiMouseHunterVoteVictoryGet")
    self.TxtDiscussionRewardCount.text = "*" .. tostring(activityConfig.DiscussionWinExp)

    if self._CurCamp == CampEnum.Camp1 then
        self.TxtDiscussionTitle.text = discussionConfig.Camp1
        self.TxtDiscussionRate.text = discussion:GetPlayerCamp1RatioStr()
        self.TxtDiscussionVictory.text = XUiHelper.GetText("MultiMouseHunterVoteVictory", discussionConfig.Camp1)
    elseif self._CurCamp == CampEnum.Camp2 then
        self.TxtDiscussionTitle.text = discussionConfig.Camp2
        self.TxtDiscussionRate.text = discussion:GetPlayerCamp2RatioStr()
        self.TxtDiscussionVictory.text = XUiHelper.GetText("MultiMouseHunterVoteVictory", discussionConfig.Camp2)
    else
        self.TxtDiscussionTitle.text = ""
        self.TxtDiscussionRate.text = ""
        self.TxtDiscussionVictory.text = ""
    end

    self.TxtDiscussionTitle.color = self.TitleSelectColor
    self.TxtDiscussionTitleOutline.outlineColor = self.TitleSelectOutlineColor
    self.ImgSupport.gameObject:SetActiveEx(self._CurCamp == discussion:GetPlayerCamp())
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetitionCamp:DisplayFail(discussion)
    self.CtrlDiscussion:ChangeState("DisplayFail")

    local activityConfig = self._Control:GetDlcMultiplayerActivityConfig()
    local bpExpIcon = XDataCenter.ItemManager.GetItemIcon(activityConfig.BpExpItem)
    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()

    self.ImgDiscussionRewardIcon:SetRawImage(bpExpIcon)

    self.TxtDiscussionReward.text = XUiHelper.GetText("MultiMouseHunterVoteFailGet")
    self.TxtDiscussionRewardCount.text = "*" .. tostring(activityConfig.DiscussionFailExp)

    if self._CurCamp == CampEnum.Camp1 then
        self.TxtDiscussionTitle.text = discussionConfig.Camp1
        self.TxtDiscussionTitle2.text = discussionConfig.Camp1Des
        self.TxtDiscussionRate.text = discussion:GetPlayerCamp1RatioStr()
    elseif self._CurCamp == CampEnum.Camp2 then
        self.TxtDiscussionTitle.text = discussionConfig.Camp2
        self.TxtDiscussionTitle2.text = discussionConfig.Camp2Des
        self.TxtDiscussionRate.text = discussion:GetPlayerCamp2RatioStr()
    else
        self.TxtDiscussionTitle.text = ""
        self.TxtDiscussionTitle2.text = ""
        self.TxtDiscussionRate.text = ""
    end

    self.TxtDiscussionTitle.color = self.TitleUnSelectColor
    self.TxtDiscussionTitleOutline.outlineColor = self.TitleUnSelectOutlineColor
    self.TxtDiscussionTitle.text = string.format("“%s”", self.TxtDiscussionTitle.text)
    self.ImgSupport.gameObject:SetActiveEx(self._CurCamp == discussion:GetPlayerCamp())
end
-- endregion

return XUiDlcMultiPlayerCompetitionCamp