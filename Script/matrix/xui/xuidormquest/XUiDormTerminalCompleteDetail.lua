local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local tableInsert = table.insert

-- 委托完成界面
---@class XUiDormTerminalCompleteDetail : XLuaUi
local XUiDormTerminalCompleteDetail = XLuaUiManager.Register(XLuaUi, "UiDormTerminalCompleteDetail")

local MAX_CHAT_WIDTH = 153

function XUiDormTerminalCompleteDetail:OnAwake()
    self:RegisterUiEvents()
    self.GridTeamMemberList = {}
    self.GridRewardList = {}
    self.MergeData = {}
    self.GridFileRewardList = {}
end

function XUiDormTerminalCompleteDetail:OnStart(finishQuestInfos, cb, isMergeData)
    self:PlayAnimation("AnimEnableOnScript")

    self.CloseCb = cb
    self.IsMergeData = isMergeData

    self.QuestId = finishQuestInfos[1].QuestId
    self.TeamCharacter = finishQuestInfos[1].TeamCharacter
    self.FinishReward = finishQuestInfos[1].FinishReward
    self.ExtraReward = finishQuestInfos[1].ExtraReward
    self.FileId = finishQuestInfos[1].FileId
    self.QuestCount = XTool.GetTableCount(finishQuestInfos)

    if isMergeData then
        self:InitMergeData(finishQuestInfos)
    end

    ---@type XDormQuest
    self.DormQuestViewModel = XDataCenter.DormQuestManager.GetDormQuestViewModel(self.QuestId)
    self:InitMergeState()
    self:InitUiData()
    self:InitTeamMember()
    self:InitRewards()
    self:InitFileData()
end

function XUiDormTerminalCompleteDetail:InitMergeData(finishQuestInfos)
    self.MergeData = {
        FileIdsList = {},
        QuestIdsList = {},
        TeamCharactersList = {},
        FinishRewardsDic = {},
        ExtraRewardsDic = {},
    }
    for _, finishQuestInfo in pairs(finishQuestInfos) do
        tableInsert(self.MergeData.FileIdsList, finishQuestInfo.FileId)
        tableInsert(self.MergeData.QuestIdsList, finishQuestInfo.QuestId)
        for _, characterId in ipairs(finishQuestInfo.TeamCharacter) do
            tableInsert(self.MergeData.TeamCharactersList, characterId)
        end

        if not self.MergeData.FinishRewardsDic[finishQuestInfo.FinishReward] then
            self.MergeData.FinishRewardsDic[finishQuestInfo.FinishReward] = 1
        else
            self.MergeData.FinishRewardsDic[finishQuestInfo.FinishReward] = self.MergeData.FinishRewardsDic[finishQuestInfo.FinishReward] + 1
        end

        if XTool.IsNumberValid(finishQuestInfo.ExtraReward) then
            if not self.MergeData.ExtraRewardsDic[finishQuestInfo.ExtraReward] then
                self.MergeData.ExtraRewardsDic[finishQuestInfo.ExtraReward] = 1
            else
                self.MergeData.ExtraRewardsDic[finishQuestInfo.ExtraReward] = self.MergeData.ExtraRewardsDic[finishQuestInfo.ExtraReward] + 1
            end
        end
    end
end

function XUiDormTerminalCompleteDetail:InitMergeState()
    self.TxtTerminalName.gameObject:SetActiveEx(not self.IsMergeData)
    self.TxtName.gameObject:SetActiveEx(not self.IsMergeData)
    self.TxtRank.gameObject:SetActiveEx(not self.IsMergeData)
    self.PanelTeam.gameObject:SetActiveEx(not self.IsMergeData)
    self.PanelEntrust.gameObject:SetActiveEx(self.IsMergeData)
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
    local teamCharacter = self.IsMergeData and self.MergeData.TeamCharactersList or self.TeamCharacter
    local memberCount = #teamCharacter
    if self.IsMergeData then
        self.TxtNum.text = self.QuestCount
        self.TxtRoleNum.text = memberCount
        return  -- 合并数据不再需要显示队伍角色头像列表
    end
    for i = 1, memberCount do
        local grid = self.GridTeamMemberList[i]
        if not grid then
            local go = i == 1 and self.GridTeamMember or XUiHelper.Instantiate(self.GridTeamMember, self.PanelTeamMembers)
            grid = {}
            XTool.InitUiObjectByUi(grid, go)
            self.GridTeamMemberList[i] = grid
        end
        local memberId = teamCharacter[i]
        grid.Members:SetRawImage(XDormConfig.GetCharacterStyleConfigQIconById(memberId))
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiDormTerminalCompleteDetail:InitRewards()
    local finishRewards = {}
    local extraRewards = {}

    if self.IsMergeData then
        finishRewards = self:GetMergedRewards(self.MergeData.FinishRewardsDic)
        extraRewards = self:GetMergedRewards(self.MergeData.ExtraRewardsDic)
    else
        -- 固定奖励
        finishRewards = XRewardManager.GetRewardList(self.FinishReward)
        -- 额外奖励
        if XTool.IsNumberValid(self.ExtraReward) then
            extraRewards = XRewardManager.GetRewardList(self.ExtraReward)
        end
    end
    self:CreateRewardGrid(finishRewards, false, 0)
    self:CreateRewardGrid(extraRewards, true, #finishRewards)
end

function XUiDormTerminalCompleteDetail:GetMergedRewards(mergeDataRewardsDic)
    local allRewards = {}
    local tempDic = {}
    for rewardId, count in pairs(mergeDataRewardsDic) do
        local rewards = XRewardManager.GetRewardList(rewardId)
        for _, reward in ipairs(rewards) do
            reward.Count = reward.Count * count
            if not tempDic[reward.TemplateId] then
                tempDic[reward.TemplateId] = reward
            else
                tempDic[reward.TemplateId].Count = tempDic[reward.TemplateId].Count + reward.Count
            end
        end
    end
    for _, reward in pairs(tempDic) do
        tableInsert(allRewards, reward)
    end
    return allRewards
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
    for _, gridFileReward in pairs(self.GridFileRewardList) do
        gridFileReward.GameObject:SetActiveEx(false)
    end

    if self.IsMergeData then
        local isHasFile = false
        if self.MergeData.FileIdsList and next(self.MergeData.FileIdsList) then
            for index, FileId in ipairs(self.MergeData.FileIdsList) do
                local isFileId = XTool.IsNumberValid(FileId)
                if isFileId then
                    local gridFileReward = self:GetGridFileRewardByIndex(index)
                    gridFileReward.GameObject:SetActiveEx(true)
                    self:RefreshFileReward(gridFileReward, FileId)
                    isHasFile = true
                end
            end
        end
        self.NoFile.gameObject:SetActiveEx(not isHasFile)
        self.FileList.gameObject:SetActiveEx(isHasFile)
    else
        local isFileId = XTool.IsNumberValid(self.FileId)
        self.NoFile.gameObject:SetActiveEx(not isFileId)
        self.FileList.gameObject:SetActiveEx(isFileId)
        if isFileId then
            local gridFileReward = self:GetGridFileRewardByIndex(1)
            gridFileReward.GameObject:SetActiveEx(true)
            self:RefreshFileReward(gridFileReward, self.FileId)
        end
    end
end

function XUiDormTerminalCompleteDetail:GetGridFileRewardByIndex(index)
    if self.GridFileRewardList[index] then
        return self.GridFileRewardList[index]
    else
        local tempGridFileReward = {}
        if index == 1 then
            XTool.InitUiObjectByUi(tempGridFileReward, self.GridFile)
        else
            local gridFile = XUiHelper.Instantiate(self.GridFile, self.GridFile.transform.parent)
            XTool.InitUiObjectByUi(tempGridFileReward, gridFile)
        end
        self.GridFileRewardList[index] = tempGridFileReward
        return tempGridFileReward
    end
end

function XUiDormTerminalCompleteDetail:RefreshFileReward(gridFileReward, fileId)
    ---@type XDormQuestFile
    local dormQuestFileViewModel = XDataCenter.DormQuestManager.GetDormQuestFileViewModel(fileId)
    gridFileReward.RImgeFile:SetRawImage(dormQuestFileViewModel:GetQuestFileDetailCover())
    gridFileReward.TxtFileName.text = dormQuestFileViewModel:GetQuestFileDetailName()
    -- 超出显示...
    gridFileReward.TxtMessageLabel.gameObject:SetActiveEx(XUiHelper.CalcTextWidth(gridFileReward.TxtFileName) > MAX_CHAT_WIDTH)
    -- 添加点击事件
    CsXUiHelper.RegisterClickEvent(gridFileReward.BtnClick, function()
        XLuaUiManager.Open("UiDormArchivesCenterDetails", fileId)
    end)
end

function XUiDormTerminalCompleteDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBg, self.OnBtnCloseClick)
    CS.XUiPc.XUiButtonContainerHelper.RegisterAction("XUiDormTerminalCompleteDetail", self.GameObject, CS.XUiPc.XUiPcCustomKeyEnum.Backward, function()
        self:OnBtnCloseClick()
    end)
end

function XUiDormTerminalCompleteDetail:OnBtnCloseClick()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
        CS.XUiPc.XUiButtonContainerHelper.UnregisterAction("XUiDormTerminalCompleteDetail", self.GameObject, CS.XUiPc.XUiPcCustomKeyEnum.Backward)
    end
end

return XUiDormTerminalCompleteDetail