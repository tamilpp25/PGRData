---@class XUiTheatre3PanelMain : XUiNode
---@field Parent XUiTheatre3Main
---@field _Control XTheatre3Control
local XUiTheatre3PanelMain = XClass(XUiNode, "XUiTheatre3PanelMain")

function XUiTheatre3PanelMain:OnStart(isA)
    self._IsA = isA
    self:InitReward()
    self:InitCanvasGroup()
    self:AddBtnListener()
end

function XUiTheatre3PanelMain:OnEnable()
    self:RefreshView()
    self:RefreshReward()
    self:RefreshMainTask()
    self:RefreshGameBtn()
    self:RefreshRedPoint()
    self:RefreshLucky()
    self:CheckOpenSettleTip()
    self:AddEventListener()
end

function XUiTheatre3PanelMain:OnDisable()
    self:RemoveEventListener()
end

--region Ui - CanvasGroup
function XUiTheatre3PanelMain:InitCanvasGroup()
    ---@type UnityEngine.CanvasGroup
    self._CanvasGroup = XUiHelper.TryGetComponent(self.Transform, "", "CanvasGroup")
end

function XUiTheatre3PanelMain:RefreshCanvasGroup()
    if not self._CanvasGroup then
        return
    end
    self._CanvasGroup.alpha = 1
end
--endregion

--region Ui - Title
function XUiTheatre3PanelMain:RefreshView()
    -- 活动名
    self.TxtTitle.text = self._Control:GetActivityName()
end
--endregion

--region Ui - RewardPanel
function XUiTheatre3PanelMain:InitReward()
    self.Grid256New.gameObject:SetActiveEx(false)
    -- 奖励
    local rewardId = self._Control:GetClientConfigNumber("MainViewShowRewardId")
    if not XTool.IsNumberValid(rewardId) then
        return
    end
    local rewards = XRewardManager.GetRewardList(rewardId)
    local rewardsNum = #rewards
    for i = 1, rewardsNum do
        local go = i == 1 and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.PanelReward)
        ---@type XUiGridCommon
        local grid = XUiGridCommon.New(self.Parent, go)
        grid:Refresh(rewards[i])
        grid.GameObject:SetActiveEx(true)
        if grid.BtnClick then
            XUiHelper.RegisterClickEvent(grid, grid.BtnClick, function()
                self._Control:OpenAdventureTips(rewards[i].TemplateId)
            end)
        end
    end
    -- 物品图片
    local icon = XDataCenter.ItemManager.GetItemIcon(XEnumConst.THEATRE3.Theatre3OutCoin)
    self.IconPoints:SetRawImage(icon)
end

function XUiTheatre3PanelMain:RefreshReward()
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
--endregion

--region Ui - TaskPanel
function XUiTheatre3PanelMain:RefreshMainTask()
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
        self.MainTaskReward = XUiGridCommon.New(self.Parent, self.BtnReward)
    end
    self.MainTaskReward:Refresh(reward)
    self.MainTaskReward:SetClickCallback(function()
        XLuaUiManager.Open("UiTheatre3Tips", reward.TemplateId)
    end)
end

function XUiTheatre3PanelMain:HideMainTask()
    self.TxtTaskTitle.text = self._Control:GetClientConfig("Theatre3MainTaskCompleteTitle")
    self.TxtTaskDescribe.text = self._Control:GetClientConfig("Theatre3MainTaskCompleteDesc")
    self.TxtTaskNum.gameObject:SetActive(false)
    self.BtnReward.gameObject:SetActiveEx(false)
end
--endregion

--region Ui - RedPoint
function XUiTheatre3PanelMain:RefreshRedPoint()
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
    -- 成就红点
    local isHaveAchievemenet = self._Control:CheckHaveAnyAchievementTaskFinish()
    self.BtnAchievement:ShowReddot(isHaveAchievemenet)
end
--endregion

--region Ui - BtnRefresh
function XUiTheatre3PanelMain:RefreshGameBtn()
    local isInGame = self._Control:IsHaveAdventure()
    local btnIcon
    if isInGame then
        btnIcon = self._Control:GetClientConfig("MainBtnIcon", self._IsA and 1 or 3)
    else
        btnIcon = self._Control:GetClientConfig("MainBtnIcon", self._IsA and 2 or 4)
    end
    local conditionId = self._Control:GetClientConfigNumber("AchievementShowCondition")
    if XTool.IsNumberValid(conditionId) then
        local isTrue, _ = XConditionManager.CheckCondition(conditionId)
        self.BtnAchievement.gameObject:SetActiveEx(isTrue)
    end
    self.BtnRetreat.gameObject:SetActiveEx(isInGame)
    if self.BtnBattle.RawImageList.Count > 0 and not string.IsNilOrEmpty(btnIcon) then
        self.BtnBattle:SetRawImage(btnIcon)
    end
end
--endregion

--region Ui - LuckyCharacter
function XUiTheatre3PanelMain:RefreshLucky()
    local luckyValuePercent = self._Control:GetLuckyValuePercent()
    self.ImgLuckBar.fillAmount = luckyValuePercent
    self.TxtLuckNum.text = XUiHelper.GetText("MainFubenProgress", math.ceil(luckyValuePercent * 100))
    self.TxtLuckDetail.text = XUiHelper.ReplaceUnicodeSpace(self._Control:GetClientConfigTxtByConvertLine("TxtLuckCharacterDetail"))
    self:CloseLuckyDetail()
end

function XUiTheatre3PanelMain:OpenLuckyDetail()
    self._LuckyDetailOpen = true
    self.LuckBubbleDetail.gameObject:SetActiveEx(self._LuckyDetailOpen)
end

function XUiTheatre3PanelMain:CloseLuckyDetail()
    self._LuckyDetailOpen = false
    self.LuckBubbleDetail.gameObject:SetActiveEx(self._LuckyDetailOpen)
end
--endregion

--region Ui - Settle
function XUiTheatre3PanelMain:CheckOpenSettleTip()
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
--endregion

--region Ui - BtnListener
function XUiTheatre3PanelMain:AddBtnListener()
    self._Control:RegisterClickEvent(self, self.BtnBP, self.OnBtnBPClick)
    self._Control:RegisterClickEvent(self, self.BtnTask, self.OnBtnTaskClick)
    self._Control:RegisterClickEvent(self, self.BtnMaster, self.OnBtnMasterClick)
    self._Control:RegisterClickEvent(self, self.BtnHandBook, self.OnBtnHandBookClick)
    self._Control:RegisterClickEvent(self, self.BtnRetreat, self.OnBtnRetreat)
    self._Control:RegisterClickEvent(self, self.BtnBattle, self.OnBtnBattle)
    self._Control:RegisterClickEvent(self, self.BtnAchievement, self.OnBtnAchievement)
    self._Control:RegisterClickEvent(self, self.BtnLuckyHelp, self.OnBtnDestinyHelpClick)
end

function XUiTheatre3PanelMain:OnBtnBPClick()
    XLuaUiManager.Open("UiTheatre3LvReward")
end

function XUiTheatre3PanelMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiTheatre3Task")
end

function XUiTheatre3PanelMain:OnBtnMasterClick()
    XLuaUiManager.Open("UiTheatre3Master")
end

function XUiTheatre3PanelMain:OnBtnHandBookClick()
    XLuaUiManager.Open("UiTheatre3Handbook")
end

function XUiTheatre3PanelMain:OnBtnRetreat()
    self.Parent:PlayAnimationWithMask("BtnRetreatDianji", function()
        self._Control:AdventureGiveUp(function()
            ---@type XTheatre3Agency
            local agency = XMVCA:GetAgency(ModuleId.XTheatre3)
            agency:CheckAndOpenSettle()
        end)
    end)
end

function XUiTheatre3PanelMain:OnBtnBattle()
    self.Parent:PlayAnimationWithMask("BtnBattleDianji", function()
        if not self._Control:IsHaveAdventure() then
            self._Control:AdventureStart()
        else
            self._Control:AdventureContinue()
        end
    end)
end

function XUiTheatre3PanelMain:OnBtnAchievement()
    XLuaUiManager.Open("UiTheatre3Achievement")
end

function XUiTheatre3PanelMain:OnBtnDestinyHelpClick()
    if self._LuckyDetailOpen then
        self:CloseLuckyDetail()
    else
        self:OpenLuckyDetail()
    end
end
--endregion

--region Event
function XUiTheatre3PanelMain:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_BATTLE_PASS_EXP_CHANGE, self.RefreshReward, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_LUCK_VALUE_UPDATE, self.RefreshLucky, self)
end

function XUiTheatre3PanelMain:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_BATTLE_PASS_EXP_CHANGE, self.RefreshReward, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_LUCK_VALUE_UPDATE, self.RefreshLucky, self)
end
--endregion

return XUiTheatre3PanelMain