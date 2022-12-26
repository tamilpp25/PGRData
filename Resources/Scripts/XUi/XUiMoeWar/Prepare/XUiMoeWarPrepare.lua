local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXTextManagerGetText = CS.XTextManager.GetText
local GRID_CONDITION_MAX_COUNT = 3
local IsNumberValid = XTool.IsNumberValid

local XUiMoeWarPrepareConditionGrid = require("XUi/XUiMoeWar/Prepare/XUiMoeWarPrepareConditionGrid")

--赛事筹备关卡
local XUiMoeWarPrepare = XLuaUiManager.Register(XLuaUi, "UiMoeWarPrepare")

function XUiMoeWarPrepare:OnAwake()
    self.GridConditions = {}
    self.RewardGrids = {}
    self.ExtraRewardGrids = {}
    self.GridCondition.gameObject:SetActiveEx(false)
    self.RewardGrid.gameObject:SetActiveEx(false)
    self.ExtraRewardGrid.gameObject:SetActiveEx(false)
    self.FillConditionCount = 0     --当前选择的角色符合条件的数量
    self.FillConditionIndexDic = {} --当前选择的角色符合条件的index字典
    self:AutoAddListener()
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_RESULT_WIN, self.HandlerFightResult, self)
end

function XUiMoeWarPrepare:OnStart(stageId, currSelectStageIndex)
    self.CurrSelectStageIndex = currSelectStageIndex
    self.allOpenStageIdList = XDataCenter.MoeWarManager.GetPreparationAllOpenStageIdList()
    self:UpdateStageId(stageId)
end

function XUiMoeWarPrepare:OnEnable()
    if self.IsFightWinCloseView then
        self:Close()
        return
    end
    self:CheckHelperOverExpiredHint()
    XDataCenter.MoeWarManager.CheckAllOwnHelpersIsResetStatus()
    self:Refresh()
    XDataCenter.MoeWarManager.JudgeGotoMainWhenFightOver()
end

function XUiMoeWarPrepare:OnDisable()
    self:StopLastTimer()
end

function XUiMoeWarPrepare:OnDestroy()
    XDataCenter.MoeWarManager.ClearPrepareTeamData()
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_RESULT_WIN, self.Close, self)
end

function XUiMoeWarPrepare:OnGetEvents()
    return {
        XEventId.EVENT_MOE_WAR_PREPARATION_UPDATE,
    }
end

function XUiMoeWarPrepare:OnNotify(event, ...)
    if event == XEventId.EVENT_MOE_WAR_PREPARATION_UPDATE then
        self:Close()
    end
end

function XUiMoeWarPrepare:AutoAddListener()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnChoubei, self.OnBtnChoubeiClick)
    self:RegisterClickEvent(self.BtnJoin, self.OpenCharacter)
    self:RegisterClickEvent(self.BtnOccupy, self.OpenCharacter)
    self:RegisterClickEvent(self.BtnArrorLeft, self.OnBtnArrorLeftClick)
    self:RegisterClickEvent(self.BtnArrorRight, self.OnBtnArrorRightClick)
    if self.BtnAssist then
        self:RegisterClickEvent(self.BtnAssist, self.OnBtnAssistClick)
    end
end

function XUiMoeWarPrepare:HandlerFightResult()
    self.IsFightWinCloseView = true
end

function XUiMoeWarPrepare:UpdateStageId(stageId)
    self.StageId = stageId
    self.IsFightWinCloseView = false
    if self.TextTitle then
        self.TextTitle.text = XFubenConfigs.GetStageName(stageId)
    end
end

function XUiMoeWarPrepare:OpenCharacter()
    local robotIdList = XDataCenter.MoeWarManager.GetPreparationOwnHelperRobotIdList()
    if XTool.IsTableEmpty(robotIdList) then
        XUiManager.TipText("MoeWarPrepareNotHelpter")
        return
    end

    local teamCharIdMap = XDataCenter.MoeWarManager.GetPrepareTeamData(self.StageId)
    local charPos = 1
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    local isHideQuitButton = false
    local characterLimitType = XFubenConfigs.GetStageCharacterLimitType(self.StageId)
    local limitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(self.StageId)
    XLuaUiManager.Open("UiMoeWarCharacter", teamCharIdMap, charPos, function(resTeam)
        XDataCenter.MoeWarManager.SetPrepareTeamData(resTeam)
        self:Refresh()
    end, stageInfo.Type, isHideQuitButton, characterLimitType, limitBuffId, nil, robotIdList, nil, self.StageId)
end

--进入战斗
function XUiMoeWarPrepare:OnBtnChoubeiClick()
    if XDataCenter.MoeWarManager.CheckRespondItemIsMax() then
        return
    end

    local stage = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local teamData = XDataCenter.MoeWarManager.GetPrepareTeamData(stage.StageId)
    local charId = teamData[1]
    if not charId or charId <= 0 then
        XUiManager.TipText("MoeWarPrepareFightNotCharcter")
        return
    end

    local curTeam = {
        TeamData = teamData,
        CaptainPos = 1,
        FirstFightPos = 1
    }

    local labelIds = XMoeWarConfig.GetPreparationStageLabelIds(self.StageId)
    if #labelIds ~= self.FillConditionCount then
        XUiManager.DialogTip(CSXTextManagerGetText("TipTitle"), CSXTextManagerGetText("MoeWarConditionNotAllComplete"), XUiManager.DialogType.Normal, nil, function()
            XDataCenter.FubenManager.EnterMoeWarFight(stage, curTeam)
        end)
        return
    end

    XDataCenter.FubenManager.EnterMoeWarFight(stage, curTeam)
end

function XUiMoeWarPrepare:OnBtnArrorLeftClick()
    self:OnBtnArrorClick(self.CurrSelectStageIndex - 1)
end

function XUiMoeWarPrepare:OnBtnArrorRightClick()
    self:OnBtnArrorClick(self.CurrSelectStageIndex + 1)
end

function XUiMoeWarPrepare:OnBtnArrorClick(stageIndex)
    if self:CheckStageIndexOutOfRange(stageIndex) then
        return
    end
    self:PlayAnimation("QieHuan")
    self.CurrSelectStageIndex = stageIndex
    self:UpdateStageId(self.allOpenStageIdList[stageIndex])
    self:Refresh()
end

function XUiMoeWarPrepare:OnBtnAssistClick()
    XLuaUiManager.Open("UiMoeWarRecruit")
end

function XUiMoeWarPrepare:CheckStageIndexOutOfRange(stageIndex)
    if stageIndex <= 0 then
        return true
    end

    local maxStageCount = #self.allOpenStageIdList
    if stageIndex > maxStageCount then
        return true
    end

    return false
end

function XUiMoeWarPrepare:Refresh()
    self:CheckClearPrepareTeamData()
    self:RefreshBtnArror()
    self:RefreshHelperId()
    self:RefreshHelperCondition()
    self:RefreshReward()
    self:RefreshOccupy()
    self:CheckLastTimer()
end

function XUiMoeWarPrepare:RefreshBtnArror()
    local maxStageCount = #self.allOpenStageIdList
    self.BtnArrorLeft.gameObject:SetActiveEx(self.CurrSelectStageIndex > 1)
    self.BtnArrorRight.gameObject:SetActiveEx(self.CurrSelectStageIndex < maxStageCount)
end

function XUiMoeWarPrepare:RefreshHelperId()
    local teamData = XDataCenter.MoeWarManager.GetPrepareTeamData(self.StageId)
    local charId = teamData[1]
    self.HelperId = XDataCenter.MoeWarManager.GetPrepareOwnHelperId(charId)
end

function XUiMoeWarPrepare:RefreshOccupy()
    local teamData = XDataCenter.MoeWarManager.GetPrepareTeamData(self.StageId)
    local charId = XRobotManager.GetCharacterId(teamData[1])
    local isHaveHelper = charId > 0 and true or false
    self.BtnOccupyMember.gameObject:SetActiveEx(not isHaveHelper)
    self.BtnOccupy.gameObject:SetActiveEx(isHaveHelper)

    if isHaveHelper then
        local icon = XDataCenter.CharacterManager.GetCharHalfBodyBigImage(charId)
        self.RImgRole:SetRawImage(icon)
    end
end

function XUiMoeWarPrepare:CheckClearPrepareTeamData()
    if not IsNumberValid(self.HelperId) then
        return
    end

    local expirationTime = XDataCenter.MoeWarManager.GetRecruitHelperExpirationTime(self.HelperId)
    local nowServerTime = XTime.GetServerNowTimestamp()
    if IsNumberValid(expirationTime) and nowServerTime >= expirationTime then
        XDataCenter.MoeWarManager.ClearPrepareTeamData()
    end
end

function XUiMoeWarPrepare:CheckLastTimer()
    self:StopLastTimer()

    local expirationTime = XDataCenter.MoeWarManager.GetRecruitHelperExpirationTime(self.HelperId)
    local nowServerTime = XTime.GetServerNowTimestamp()
    if not self.HelperId or self.HelperId == 0 or nowServerTime >= expirationTime then
        self.TextLastTime.text = ""
        self:SetImgLastTimeIsActive(false)
        return
    end

    self:SetImgLastTimeIsActive(true)

    local timeLimit = expirationTime - nowServerTime
    local timeLimitStr = XUiHelper.GetTime(timeLimit, XUiHelper.TimeFormatType.CHATEMOJITIMER)
    self.TextLastTime.text = CSXTextManagerGetText("MoeWarHelperTimeLimit", timeLimitStr)
    self.LastTimer = XScheduleManager.ScheduleForever(function()
        nowServerTime = XTime.GetServerNowTimestamp()
        timeLimit = expirationTime - nowServerTime
        if timeLimit <= 0 then
            self:StopLastTimer()
            self:Refresh()
            return
        end

        timeLimitStr = XUiHelper.GetTime(timeLimit, XUiHelper.TimeFormatType.CHATEMOJITIMER)
        self.TextLastTime.text = CSXTextManagerGetText("MoeWarHelperTimeLimit", timeLimitStr)
    end, XScheduleManager.SECOND)
end

function XUiMoeWarPrepare:SetImgLastTimeIsActive(isActive)
    if self.ImgLastTime then
        self.ImgLastTime.gameObject:SetActiveEx(isActive)
    end
end

function XUiMoeWarPrepare:StopLastTimer()
    if self.LastTimer then
        XScheduleManager.UnSchedule(self.LastTimer)
        self.LastTimer = nil
    end
end

function XUiMoeWarPrepare:RefreshExtraReward()
    local rewardIds = XMoeWarConfig.GetPreparationStageShowExtraRewardIds(self.StageId)
    local rewardDic = {}
    local rewards
    for index, rewardId in ipairs(rewardIds) do
        rewards = XRewardManager.GetRewardList(rewardId)
        if not rewardDic[rewardId] then
            rewardDic[rewardId] = XTool.Clone(rewards[1])
            rewardDic[rewardId].Count = 0
        end
        if self.FillConditionIndexDic[index] then
            rewardDic[rewardId].Count = rewardDic[rewardId].Count + rewards[1].Count
        end
    end
    local extraRewardGridCount = 1
    for _, reward in pairs(rewardDic) do
        local grid = self.ExtraRewardGrids[extraRewardGridCount]
        if not grid then
            grid = XUiGridCommon.New(self, self.ExtraRewardGrid)
            grid.Transform:SetParent(self.PaneExtralReward, false)
            self.ExtraRewardGrids[extraRewardGridCount] = grid
        end
        grid:Refresh(reward)
        grid.GameObject:SetActiveEx(true)
    end

    if not self.HelperId or self.HelperId == 0 then
        self.TxtBonus.gameObject:SetActiveEx(true)
        self.TxtExtraBonus.gameObject:SetActiveEx(false)
        return
    end
    self.TxtBonus.gameObject:SetActiveEx(false)
    self.TxtExtraBonus.gameObject:SetActiveEx(true)
    
    self.TxtEvaluation.text = XMoeWarConfig.GetPreparationStageEvaluationEvaluatioLabel(self.FillConditionCount)
end

function XUiMoeWarPrepare:RefreshReward()
    local rewardId = XMoeWarConfig.GetPreparationStageShowBaseRewardId(self.StageId)
    local rewards = XTool.IsNumberValid(rewardId) and XRewardManager.GetRewardList(rewardId) or {}
    local itemId = XDataCenter.ItemManager.ItemId.MoeWarCommunicateItemId
    local communicateItemCount = 0
    for i, v in ipairs(rewards) do
        local grid = self.RewardGrids[i]
        if not grid then
            local obj = i == 1 and self.RewardGrid or CSUnityEngineObjectInstantiate(self.RewardGrid, self.PanelReward)
            grid = XUiGridCommon.New(self, obj)
            grid.Transform:SetParent(self.PanelReward, false)
            self.RewardGrids[i] = grid
        end
        grid:Refresh(v)
        grid.GameObject:SetActiveEx(true)

        if v.TemplateId == itemId then
            communicateItemCount = v.Count
        end
    end

    for i = #rewards + 1, #self.RewardGrids do
        self.RewardGrids[i].GameObject:SetActiveEx(false)
    end

    local showSpecialRewardId = XMoeWarConfig.GetPreparationStageShowSpecialRewardId(self.StageId)
    local showSpecialRewardIds = showSpecialRewardId > 0 and XRewardManager.GetRewardList(showSpecialRewardId) or {}
    local showSpecialItemId = showSpecialRewardIds[1] and showSpecialRewardIds[1].TemplateId
    local showSpecialItemCount = showSpecialRewardIds[1] and showSpecialRewardIds[1].Count or 0
    if self.TxtRewardName then
        local itemName = showSpecialItemId and XDataCenter.ItemManager.GetItemName(showSpecialItemId)
        self.TxtRewardName.text = itemName and itemName .. "：" or ""
    end

    local goodsShowParams = showSpecialItemId and XGoodsCommonManager.GetGoodsShowParamsByTemplateId(showSpecialItemId)
    if XTool.IsTableEmpty(goodsShowParams) then
        self.RewardIcon.gameObject:SetActiveEx(false)
        self.TxtRewardNumber.text = ""
    else
        self.RewardIcon:SetRawImage(goodsShowParams.Icon)
        self.RewardIcon.gameObject:SetActiveEx(true)
        self.TxtRewardNumber.text = "+" .. showSpecialItemCount
    end
end

function XUiMoeWarPrepare:RefreshHelperCondition()
    local labelIds = XMoeWarConfig.GetPreparationStageLabelIds(self.StageId)
    self.FillConditionCount = 0
    self.FillConditionIndexDic = {}
    for i, stageLabelId in ipairs(labelIds) do
        local grid = self.GridConditions[i]
        if not grid then
            local gridCondition = 1 == i and self.GridCondition or CSUnityEngineObjectInstantiate(self.GridCondition, self.PanelConditions)
            grid = XUiMoeWarPrepareConditionGrid.New(gridCondition, i)
            self.GridConditions[i] = grid
        end
        grid:Refresh(self.StageId, stageLabelId, self.HelperId)
        grid:SetActive(true)
        if XMoeWarConfig.IsFillPreparationStageLabel(stageLabelId, self.HelperId) then
            self.FillConditionCount = self.FillConditionCount + 1
            self.FillConditionIndexDic[i] = true
        end
    end
    self:RefreshExtraReward()

    for i = #labelIds + 1, GRID_CONDITION_MAX_COUNT do
        if self.GridConditions[i] then
            self.GridConditions[i]:SetActive(false)
        end
    end
end

function XUiMoeWarPrepare:CheckHelperOverExpiredHint()
    local teamData = XDataCenter.MoeWarManager.GetPrepareTeamData(self.StageId)
    local charId = teamData[1]
    local helperId = XDataCenter.MoeWarManager.GetPrepareOwnHelperId(charId)
    if XDataCenter.MoeWarManager.IsHelperExpired(helperId) then
        XUiManager.TipText("MoeWarHelperOverExpired")
    end
end