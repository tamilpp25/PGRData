-- 委托完成界面
---@class XUiDormTerminalCompleteDetail : XLuaUi
local XUiDormTerminalCompleteDetail = XLuaUiManager.Register(XLuaUi, "UiDormTerminalCompleteDetail")

local MAX_CHAT_WIDTH = 153

function XUiDormTerminalCompleteDetail:OnAwake()
    self:RegisterUiEvents()
    self.GridTeamMemberList = {}
    self.GridRewardList = {}
end

function XUiDormTerminalCompleteDetail:OnStart(finishQuestInfo, cb)
    self:PlayAnimation("AnimEnableOnScript")
    self.QuestId = finishQuestInfo.QuestId
    self.TeamCharacter = finishQuestInfo.TeamCharacter
    self.FinishReward = finishQuestInfo.FinishReward
    self.ExtraReward = finishQuestInfo.ExtraReward
    self.FileId = finishQuestInfo.FileId
    self.CloseCb = cb
    ---@type XDormQuest
    self.DormQuestViewModel = XDataCenter.DormQuestManager.GetDormQuestViewModel(self.QuestId)
    self:InitUiData()
    self:InitTeamMember()
    self:InitRewards()
    self:InitFileData()
end

function XUiDormTerminalCompleteDetail:InitUiData()
    -- 委托名
    self.TxtTerminalName.text = self.DormQuestViewModel:GetQuestName()
    -- 发布者名
    self.TxtName.text = XDormQuestConfigs.GetQuestAnnouncerNameById(self.DormQuestViewModel:GetQuestAnnouncer())
    -- 等级
    self.TxtRank.text = XDormQuestConfigs.GetQuestQualityNameById(self.DormQuestViewModel:GetQuestQuality())
    self.TxtRank.color = XDormQuestConfigs.GetQuestQualityColorById(self.DormQuestViewModel:GetQuestQuality())
end

function XUiDormTerminalCompleteDetail:InitTeamMember()
    local memberCount = #self.TeamCharacter
    for i = 1, memberCount do
        local grid = self.GridTeamMemberList[i]
        if not grid then
            local go = i == 1 and self.GridTeamMember or XUiHelper.Instantiate(self.GridTeamMember, self.PanelTeamMembers)
            grid = {}
            XTool.InitUiObjectByUi(grid, go)
            self.GridTeamMemberList[i] = grid
        end
        local memberId = self.TeamCharacter[i]
        grid.Members:SetRawImage(XDormConfig.GetCharacterStyleConfigQIconById(memberId))
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiDormTerminalCompleteDetail:InitRewards()
    -- 固定奖励
    local finishRewards = XRewardManager.GetRewardList(self.FinishReward)
    self:CreateRewardGrid(finishRewards, false, 0)
    -- 额外奖励
    if XTool.IsNumberValid(self.ExtraReward) then
        local extraRewards = XRewardManager.GetRewardList(self.ExtraReward)
        self:CreateRewardGrid(extraRewards, true, #finishRewards)
    end
end

function XUiDormTerminalCompleteDetail:CreateRewardGrid(rewards, isExtra, startIndex)
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

function XUiDormTerminalCompleteDetail:InitFileData()
    local isFileId = XTool.IsNumberValid(self.FileId)
    self.NoFile.gameObject:SetActiveEx(not isFileId)
    self.FileList.gameObject:SetActiveEx(isFileId)
    if isFileId then
        if not self.GridFileReward then
            self.GridFileReward = {}
            XTool.InitUiObjectByUi(self.GridFileReward, self.GridFile)
        end
        ---@type XDormQuestFile
        local dormQuestFileViewModel = XDataCenter.DormQuestManager.GetDormQuestFileViewModel(self.FileId)
        self.GridFileReward.RImgeFile:SetRawImage(dormQuestFileViewModel:GetQuestFileDetailCover())
        self.GridFileReward.TxtFileName.text = dormQuestFileViewModel:GetQuestFileDetailName()
        -- 超出显示...
        self.GridFileReward.TxtMessageLabel.gameObject:SetActiveEx(XUiHelper.CalcTextWidth(self.GridFileReward.TxtFileName) > MAX_CHAT_WIDTH)
        -- 添加点击事件
        CsXUiHelper.RegisterClickEvent(self.GridFileReward.BtnClick, function()
            XLuaUiManager.Open("UiDormArchivesCenterDetails", self.FileId)
        end)
    end
end

function XUiDormTerminalCompleteDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBg, self.OnBtnCloseClick)
    CS.XUiPc.XUiButtonContainerHelper.RegisterAction("XUiDormTerminalCompleteDetail", self.GameObject, CS.XUiPc.XUiPcCustomKeyEnum.Backward, function() self:OnBtnCloseClick() end)
end

function XUiDormTerminalCompleteDetail:OnBtnCloseClick()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
        CS.XUiPc.XUiButtonContainerHelper.UnregisterAction("XUiDormTerminalCompleteDetail", self.GameObject, CS.XUiPc.XUiPcCustomKeyEnum.Backward)
    end
end

return XUiDormTerminalCompleteDetail