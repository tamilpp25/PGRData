local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
-- 委托详情
---@class XUiDormTerminalLineDetail : XLuaUi
local XUiDormTerminalLineDetail = XLuaUiManager.Register(XLuaUi, "UiDormTerminalLineDetail")

function XUiDormTerminalLineDetail:OnAwake()
    self:RegisterUiEvents()
end

function XUiDormTerminalLineDetail:OnStart(ui)
    self.ParentUi = ui
    self.GridPropertyList = {}
    self.GridRewardList = {}
end

function XUiDormTerminalLineDetail:OnEnable()
    -- 动画
    self.IsPlaying = true
    self:PlayAnimation("AnimBegin", handler(self, function()
        self.IsPlaying = false
    end))
    self.IsOpen = true

end

function XUiDormTerminalLineDetail:OnDisable()
    self.IsOpen = false

end

function XUiDormTerminalLineDetail:Refresh(questId, index)
    self.QuestId = questId
    self.Index = index
    ---@type XDormQuest
    self.DormQuestViewModel = XDataCenter.DormQuestManager.GetDormQuestViewModel(self.QuestId)
    ---@type XDormTerminalTeam
    self.TerminalTeamEntity = XDataCenter.DormQuestManager.GetDormTerminalTeamEntity()
    self:RefreshUiDate()
    self:RefreshProperty()
    self:RefreshRewards()
    self:RefreshAcceptQuestBtn()
end

function XUiDormTerminalLineDetail:RefreshUiDate()
    -- 委托名
    self.TxtTitle.text = self.DormQuestViewModel:GetQuestName()
    -- 委托类型图标
    local typeIcon = XDormQuestConfigs.GetQuestTypeIconById(self.DormQuestViewModel:GetQuestType())
    self.RImgIssuer:SetRawImage(typeIcon)
    -- 发布人
    self.TxtTitleIssuerName.text = XDormQuestConfigs.GetQuestAnnouncerNameById(self.DormQuestViewModel:GetQuestAnnouncer())
    -- 委托等级
    self.TxtTitleRank.text = XDormQuestConfigs.GetQuestQualityNameById(self.DormQuestViewModel:GetQuestQuality())
    self.TxtTitleRank.color = XDormQuestConfigs.GetQuestQualityColorById(self.DormQuestViewModel:GetQuestQuality())
    -- 描述
    local content = XUiHelper.ReplaceUnicodeSpace(self.DormQuestViewModel:GetQuestContent())
    self.TxtQuestContent.text = XUiHelper.ConvertLineBreakSymbol(content)
    -- 需要成员数
    local memberCount = self.DormQuestViewModel:GetQuestMemberCount()
    self.TexTmemberNum.text = XUiHelper.GetText("DormQuestTerminalDetailMemberCount", memberCount)
    -- 花费时间
    local needTime = self.DormQuestViewModel:GetQuestNeedTime()
    self.TxtAtTime.text = XUiHelper.GetTime(needTime, XUiHelper.TimeFormatType.DEFAULT)
    -- 发布人图标
    local announcerIcon = XDormQuestConfigs.GetQuestAnnouncerIconById(self.DormQuestViewModel:GetQuestAnnouncer())
    self.RImgExhibition:SetRawImage(announcerIcon)
end

function XUiDormTerminalLineDetail:RefreshProperty()
    -- 推荐属性
    local recommendAttrib = self.DormQuestViewModel:GetQuestRecommendAttrib()
    for i = 1, #recommendAttrib do
        local attribId = recommendAttrib[i]
        local grid = self.GridPropertyList[i]
        if not grid then
            local go = i == 1 and self.GridProperty or XUiHelper.Instantiate(self.GridProperty, self.PanelPropertyContent)
            grid = {}
            XTool.InitUiObjectByUi(grid, go)
            self.GridPropertyList[i] = grid
        end
        grid.Property:SetSprite(XDormQuestConfigs.GetQuestAttribIconById(attribId))
        grid.GameObject:SetActiveEx(true)
    end

    for i = #recommendAttrib + 1, #self.GridPropertyList do
        self.GridPropertyList[i].GameObject:SetActiveEx(false)
    end
end

function XUiDormTerminalLineDetail:RefreshRewards()
    -- 固定奖励
    local finishRewardId = self.DormQuestViewModel:GetQuestFinishReward()
    local finishRewards = XRewardManager.GetRewardList(finishRewardId)
    self:CreateRewardGrid(finishRewards, false, 0)
    -- 额外奖励
    local extraRewardId = self.DormQuestViewModel:GetQuestExtraReward()
    local extraRewards = XRewardManager.GetRewardList(extraRewardId)
    self:CreateRewardGrid(extraRewards, true, #finishRewards)

    for i = #finishRewards + #extraRewards + 1, #self.GridRewardList do
        self.GridRewardList[i].GameObject:SetActiveEx(false)
    end
end

function XUiDormTerminalLineDetail:CreateRewardGrid(rewards, isExtra, startIndex)
    local rewardsNum = #rewards
    for i = startIndex + 1, rewardsNum + startIndex do
        local grid = self.GridRewardList[i]
        if not grid then
            local go = i == 1 and self.GridDrop or XUiHelper.Instantiate(self.GridDrop, self.PanelDropContent)
            grid = {}
            XTool.InitUiObjectByUi(grid, go)
            grid.ItemGrid = XUiGridCommon.New(self, grid.Item)
            self.GridRewardList[i] = grid
        end
        grid.ItemGrid:Refresh(rewards[i - startIndex])
        grid.PanelTag.gameObject:SetActiveEx(isExtra)
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiDormTerminalLineDetail:RefreshAcceptQuestBtn()
    local isLimit = self.TerminalTeamEntity:CheckHaveNewPos()
    self.BtnEnter:SetButtonState(isLimit and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

function XUiDormTerminalLineDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnEnter, self.OnBtnEnterClick)
end

-- 接取委托
function XUiDormTerminalLineDetail:OnBtnEnterClick()
    if self.IsPlaying then
        return
    end
    local isLimit = self.TerminalTeamEntity:CheckHaveNewPos()
    if not isLimit then
        XUiManager.TipText("DormQuestTerminalTeamMemberLimit")
        return
    end

    CsXGameEventManager.Instance:Notify(XEventId.EVENT_DORM_TERMINAL_ACCEPT_QUEST, self.QuestId, self.Index)
end

function XUiDormTerminalLineDetail:Hide()
    if self.IsPlaying or not self.IsOpen then
        return
    end

    self.IsPlaying = true
    self:PlayAnimation("AnimEnd", handler(self, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.IsPlaying = false
        self:Close()
    end))
end

return XUiDormTerminalLineDetail