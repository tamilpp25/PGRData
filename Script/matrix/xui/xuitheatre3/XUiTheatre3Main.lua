---@class XUiTheatre3Main : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3Main = XLuaUiManager.Register(XLuaUi, "UiTheatre3Main")

function XUiTheatre3Main:OnAwake()
    self:RegisterUiEvents()
    self.Grid256New.gameObject:SetActiveEx(false)
end

function XUiTheatre3Main:OnStart()
    self:InitReward()
end

function XUiTheatre3Main:OnEnable()
    self:Refresh()
    self:CheckOpenSettleTip()
end

function XUiTheatre3Main:OnGetEvents()
    return {
        XEventId.EVENT_THEATRE3_BATTLE_PASS_EXP_CHANGE,
    }
end

function XUiTheatre3Main:OnNotify(event, ...)
    if event == XEventId.EVENT_THEATRE3_BATTLE_PASS_EXP_CHANGE then
        self:RefreshReward()
    end
end

function XUiTheatre3Main:InitReward()
    -- 奖励
    local rewardId = self._Control:GetClientConfig("MainViewShowRewardId")
    rewardId = rewardId and tonumber(rewardId)
    if not XTool.IsNumberValid(rewardId) then
        return
    end
    local rewards = XRewardManager.GetRewardList(rewardId)
    local rewardsNum = #rewards
    for i = 1, rewardsNum do
        local go = i == 1 and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.PanelReward)
        local grid = XUiGridCommon.New(self, go)
        grid:Refresh(rewards[i])
        grid.GameObject:SetActiveEx(true)
        if grid.BtnClick then
            XUiHelper.RegisterClickEvent(grid, grid.BtnClick, function()
                XLuaUiManager.Open("UiTheatre3Tips", rewards[i].TemplateId)
            end)
        end
    end
    -- 物品图片
    local icon = XDataCenter.ItemManager.GetItemIcon(XEnumConst.THEATRE3.Theatre3OutCoin)
    self.IconPoints:SetRawImage(icon)
end

function XUiTheatre3Main:Refresh()
    self:RefreshView()
    self:RefreshReward()
    self:RefreshMainTask()
    self:RefreshGameBtn()
    self:RefreshRedPoint()
end

function XUiTheatre3Main:RefreshView()
    -- 活动名
    self.TxtTitle.text = self._Control:GetActivityName()
end

function XUiTheatre3Main:RefreshReward()
    -- 当前奖励等级
    local level = self._Control:GetCurBattlePassLevel()
    self.TxtLvNum.text = level
    -- 进度
    local isMaxlevel = self._Control:CheckBattlePassMaxLevel(level)
    if isMaxlevel then
        self.TxtPointsNum.text = self._Control:GetClientConfig("RewardTips", 3)
        self.ImgProgress.fillAmount = 1
    else
        local curLevelExp = self._Control:GetCurLevelExp(level)
        local nextLevelExp = self._Control:GetNextLevelExp(level + 1)
        self.TxtPointsNum.text = string.format("%s/%s", curLevelExp, nextLevelExp)
        local progress = XTool.IsNumberValid(nextLevelExp) and curLevelExp / nextLevelExp or 1
        self.ImgProgress.fillAmount = progress
    end
end

function XUiTheatre3Main:RefreshMainTask()
    local taskId = self._Control:GetMainShowTaskId()
    if not XTool.IsNumberValid(taskId) or XDataCenter.TaskManager.IsTaskFinished(taskId) then
        self:HideMainTask()
        return
    end
    local config = XDataCenter.TaskManager.GetTaskTemplate(taskId)
    local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
    if not config or not taskData then
        self:HideMainTask()
        return
    end
    -- 标题
    self.TxtTaskTitle.text = config.Title
    -- 描述
    self.TxtTaskDescribe.text = config.Desc
    -- 显示进度
    if #config.Condition < 2 then
        if self.TxtTaskNum then
            self.TxtTaskNum.gameObject:SetActive(true)
        end
        local result = config.Result > 0 and config.Result or 1
        XTool.LoopMap(taskData.Schedule, function(_, pair)
            pair.Value = (pair.Value >= result) and result or pair.Value
            if self.TxtTaskNum then
                self.TxtTaskNum.text = pair.Value .. "/" .. result
            end
        end)
    else
        if self.TxtTaskNum then
            self.TxtTaskNum.gameObject:SetActive(false)
        end
    end
    -- 显示奖励
    local rewards = XRewardManager.GetRewardList(config.RewardId)
    if not rewards then
        self.BtnReward.gameObject:SetActiveEx(false)
        return
    end
    local reward = rewards[1]
    if not self.MainTaskReward then
        self.MainTaskReward = XUiGridCommon.New(self, self.BtnReward)
    end
    self.MainTaskReward:Refresh(reward)
    self.MainTaskReward:SetClickCallback(function()
        XLuaUiManager.Open("UiTheatre3Tips", reward.TemplateId)
    end)
end

function XUiTheatre3Main:RefreshGameBtn()
    local isInGame = self._Control:IsHaveAdventure()
    local btnIcon = self._Control:GetClientConfig("MainBtnIcon", isInGame and 1 or 2)
    self.BtnRetreat.gameObject:SetActiveEx(isInGame)
    if self.BtnBattle.RawImageList.Count > 0 and not string.IsNilOrEmpty(btnIcon) then
        self.BtnBattle:SetRawImage(btnIcon)
    end
end

function XUiTheatre3Main:RefreshRedPoint()
    -- bp奖励红点
    local level = self._Control:GetCurBattlePassLevel()
    local isBpRedPoint = self._Control:CheckIsHaveReward(level)
    self.BtnBP:ShowReddot(isBpRedPoint)
    -- 任务红点
    local isMaxlevel = self._Control:CheckBattlePassMaxLevel(level)
    ---@type XTheatre3Agency
    local theatre3Agency = XMVCA:GetAgency(ModuleId.XTheatre3)
    local isTaskAchieved = theatre3Agency:CheckAllTaskAchieved()
    self.BtnTask:ShowReddot(not isMaxlevel and isTaskAchieved)
    -- 图鉴红点
    local isItemRedPoint = self._Control:CheckAllItemRedPoint()
    local isSuitRedPoint = self._Control:CheckAllEquipSuitRedPoint()
    self.BtnHandBook:ShowReddot(isItemRedPoint or isSuitRedPoint)
    -- 精通红点
    local isTreeRedPoint = self._Control:CheckAllStrengthenTreeRedPoint()
    self.BtnMaster:ShowReddot(isTreeRedPoint)
end

function XUiTheatre3Main:HideMainTask()
    self.TxtTaskTitle.text = self._Control:GetClientConfig("Theatre3MainTaskCompleteTitle")
    self.TxtTaskDescribe.text = self._Control:GetClientConfig("Theatre3MainTaskCompleteDesc")
    self.TxtTaskNum.gameObject:SetActive(false)
    self.BtnReward.gameObject:SetActiveEx(false)
end

--region Ui - BtnListener
function XUiTheatre3Main:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBP, self.OnBtnBPClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTask, self.OnBtnTaskClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMaster, self.OnBtnMasterClick)
    XUiHelper.RegisterClickEvent(self, self.BtnHandBook, self.OnBtnHandBookClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRetreat, self.OnBtnRetreat)
    XUiHelper.RegisterClickEvent(self, self.BtnBattle, self.OnBtnBattle)

    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiTheatre3Main:OnBtnBackClick()
    self:Close()
end

function XUiTheatre3Main:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTheatre3Main:OnBtnBPClick()
    XLuaUiManager.Open("UiTheatre3LvReward")
end

function XUiTheatre3Main:OnBtnTaskClick()
    XLuaUiManager.Open("UiTheatre3Task")
end

function XUiTheatre3Main:OnBtnMasterClick()
    XLuaUiManager.Open("UiTheatre3Master")
end

function XUiTheatre3Main:OnBtnHandBookClick()
    XLuaUiManager.Open("UiTheatre3Handbook")
end

function XUiTheatre3Main:OnBtnRetreat()
    self:PlayAnimationWithMask("BtnRetreatDianji", function()
        self._Control:AdventureGiveUp(function()
            ---@type XTheatre3Agency
            local agency = XMVCA:GetAgency(ModuleId.XTheatre3)
            agency:CheckAndOpenSettle()
        end)
    end)
end

function XUiTheatre3Main:OnBtnBattle()
    self:PlayAnimationWithMask("BtnBattleDianji", function()
        if not self._Control:IsHaveAdventure() then
            self._Control:AdventureStart()
        else
            self._Control:AdventureContinue()
        end
    end)
end
--endregion

function XUiTheatre3Main:CheckOpenSettleTip()
    local settle = self._Control:GetSettleData()
    if not settle or not settle.IsNeedShowTip then
        return
    end

    self._Control:SignSettleTip()

    local asynOpen = asynTask(XLuaUiManager.Open)
    RunAsyn(function()
        local uiDatas = self._Control:GetSettleTips()
        for _, v in pairs(uiDatas) do
            asynOpen(v.uiName, v.uiParam)
        end
    end)
end

return XUiTheatre3Main