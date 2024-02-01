local XUiMultiDimSettle = XLuaUiManager.Register(XLuaUi, "UiMultiDimSettle")

function XUiMultiDimSettle:OnStart(data, isSingleStage)
    self.IsFirst = true
    self.winData = data
    self.IsSingleStage = isSingleStage
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(self.winData.StageId)
    self.GridRewardList = {}
    
    self:RegisterBtnClick()
    self.PanelCount.gameObject:SetActive(not isSingleStage) --积分
    self.BtnAgain.gameObject:SetActive(isSingleStage) --再次挑战按钮
    self:InitInfo(data)
end

function XUiMultiDimSettle:OnDestroy()
    XDataCenter.AntiAddictionManager.EndFightAction()
end

function XUiMultiDimSettle:InitInfo(data)
    if data.SettleData then
        local passTimeLimit = self.StageCfg.PassTimeLimit
        local leftTime = data.SettleData.LeftTime
        self:SetTime(math.max(0, passTimeLimit - leftTime))
    end

    if data.PlayerList and data.PlayerList[XPlayer.Id] then
        local CharacterId = data.PlayerList[XPlayer.Id].CharacterId
        if CharacterId and CharacterId ~= 0 then
            self:SetRoleImg(CharacterId)
        end
    elseif data.SettleData.NpcHpInfo and data.SettleData.NpcHpInfo[1].CharacterId then
        local CharacterId = data.SettleData.NpcHpInfo[1].CharacterId
        if CharacterId and CharacterId ~= 0 then
            self:SetRoleImg(CharacterId)
        end
    end
    if data.SettleData and data.SettleData.MultiDimFightResult then
        self.TxtRecord.text = data.SettleData.MultiDimFightResult.StageScore
    end
    if not self.IsSingleStage then
        local rewardList = {}
        local dailyCount = 0
        if data.SettleData.MultiDimFightResult.DailyRewardGoods then
            dailyCount = #data.SettleData.MultiDimFightResult.DailyRewardGoods
            for _, reward in pairs(data.SettleData.MultiDimFightResult.DailyRewardGoods) do
                table.insert(rewardList,reward)
            end
        end
        if data.SettleData.MultiDimFightResult.DifficultyRewardGoods then
            for _, reward in pairs(data.SettleData.MultiDimFightResult.DifficultyRewardGoods) do
                table.insert(rewardList,reward)
            end
        end
        self:InitRewardList(rewardList)
        for i = dailyCount + 1,#rewardList do
            self.GridRewardList[i]:SetPanelFirst(false)
        end
    else
        self:InitRewardList(data.RewardGoodsList)
    end
end

-- 通关记录
function XUiMultiDimSettle:SetTime(seconds)
    self.TxtTime.text = XUiHelper.GetTime(seconds)
end

-- 角色半身图
function XUiMultiDimSettle:SetRoleImg(roldId)
    local path = XMVCA.XCharacter:GetCharHalfBodyBigImage(roldId)
    self.RImgRole:SetRawImage(path)
end

function XUiMultiDimSettle:RegisterBtnClick()
    self:RegisterClickEvent(self.BtnAgain, self.OnBtnAgainClick)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
end

-- 物品奖励列表
function XUiMultiDimSettle:InitRewardList(rewardGoodsList)
    rewardGoodsList = rewardGoodsList or {}
    local rewards = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    for i, item in ipairs(rewards) do
        local ui =
        self["GridReward" .. i] or
                CS.UnityEngine.Object.Instantiate(self.GridReward1, self.GridReward1.transform.parent)
        local grid = XUiGridCommon.New(self, ui)
        grid:Refresh(item, nil, nil, true)
        if self.IsSingleStage then
            grid:SetPanelFirst(false)
        end
        table.insert(self.GridRewardList, grid)
    end
    for i = #rewards + 1, 99 do
        local ui = self["GridReward" .. i]
        if not ui then
            break
        end
        ui.gameObject:SetActiveEx(false)
    end
end

function XUiMultiDimSettle:OnBtnAgainClick()
    if self.IsSingleStage then  -- 仅单人可用
        XLuaUiManager.PopThenOpen("UiBattleRoleRoom",
        self.StageCfg.StageId,
        XDataCenter.TeamManager.GetXTeamByTypeId(CS.XGame.Config:GetInt("TypeIdMultiDimSingle")),
        require("XUi/XUiMultiDim/XUiMultiDimSingleCopyRoleRoom"))
    end
end

function XUiMultiDimSettle:OnBtnBackClick()
    self:Close()
end

--endregion copy from UiSettleWin

return XUiMultiDimSettle