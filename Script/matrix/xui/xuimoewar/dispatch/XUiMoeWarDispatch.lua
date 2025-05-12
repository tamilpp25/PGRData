local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXTextManagerGetText = CS.XTextManager.GetText
local GRID_CONDITION_MAX_COUNT = 3
local IsNumberValid = XTool.IsNumberValid

local XUiMoeWarPrepareConditionGrid = require("XUi/XUiMoeWar/Prepare/XUiMoeWarPrepareConditionGrid")
local XUiGridHelper = require("XUi/XUiMoeWar/ChildItem/XUiGridHelper")

--派遣弹窗
local XUiMoeWarDispatch = XLuaUiManager.Register(XLuaUi, "UiMoeWarDispatch")

function XUiMoeWarDispatch:OnAwake()
    self.GridConditions = {}
    self.RewardGrids = {}
    self.ExtraRewardGrids = {}
    self.GridCondition.gameObject:SetActiveEx(false)
    self.RewardGrid.gameObject:SetActiveEx(false)
    self.ExtraRewardGrid.gameObject:SetActiveEx(false)
    self.FillConditionCount = 0     --当前选择的角色符合条件的数量
    self.FillConditionIndexDic = {} --当前选择的角色符合条件的index字典
    self.HelperGrid = XUiGridHelper.New(self.PanelOccupy, handler(self, self.OpenCharacter))
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_RESULT_WIN, self.HandlerFightResult, self)
end

function XUiMoeWarDispatch:OnStart(stageId, currSelectStageIndex)
    self.CurrSelectStageIndex = currSelectStageIndex --当前选择的关卡下标
    self.AllOpenStageIdList = XDataCenter.MoeWarManager.GetPreparationAllOpenStageIdList()

    self:AutoAddListener()
    self:UpdateStageId(stageId)
end

function XUiMoeWarDispatch:OnEnable()
    if self.IsFightWinCloseView then
        self:Close()
        return
    end
    self:CheckHelperOverExpiredHint()
    XDataCenter.MoeWarManager.CheckAllOwnHelpersIsResetStatus()
    self:Refresh()
    XDataCenter.MoeWarManager.JudgeGotoMainWhenFightOver()
end

function XUiMoeWarDispatch:OnDisable()
    self:StopLastTimer()
end

function XUiMoeWarDispatch:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_RESULT_WIN, self.Close, self)
end

function XUiMoeWarDispatch:OnGetEvents()
    return {
        XEventId.EVENT_MOE_WAR_PREPARATION_UPDATE,
    }
end

function XUiMoeWarDispatch:OnNotify(event, ...)
    if event == XEventId.EVENT_MOE_WAR_PREPARATION_UPDATE then
        self:Close()
    end
end

function XUiMoeWarDispatch:AutoAddListener()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnChoubei, self.OnBtnAutoFight)
    self:RegisterClickEvent(self.BtnArrorLeft, self.OnBtnArrorLeftClick)
    self:RegisterClickEvent(self.BtnArrorRight, self.OnBtnArrorRightClick)
    self:RegisterClickEvent(self.BtnAssist, self.OnBtnAssistClick)
end

function XUiMoeWarDispatch:HandlerFightResult()
    self.IsFightWinCloseView = true
end

function XUiMoeWarDispatch:UpdateStageId(stageId)
    self.StageId = stageId
    self.IsFightWinCloseView = false
    if self.TextTitle then
        self.TextTitle.text = XFubenConfigs.GetStageName(stageId)
    end
end

function XUiMoeWarDispatch:OpenCharacter()
    local robotIdList = XDataCenter.MoeWarManager.GetPreparationOwnHelperRobotIdList()
    if XTool.IsTableEmpty(robotIdList) then
        XUiManager.TipText("MoeWarPrepareNotHelpter")
        return
    end

    local selectHelperCb = function(helperId)
        self.HelperId = helperId
        self:Refresh()
    end

    XLuaUiManager.Open("UiMoeWarDispatchSelectedRoles", {
        CurSelectHelperId = self.HelperId,
        SelectHelperCb = selectHelperCb,
        StageId = self.StageId,
    })
end

--派遣（扫荡）
function XUiMoeWarDispatch:OnBtnAutoFight()
    if XDataCenter.MoeWarManager.CheckRespondItemIsMax() then
        return
    end

    local stageId = self.StageId
    local helperId = self.HelperId

    if not XTool.IsNumberValid(helperId) then
        XDataCenter.MoeWarManager.RequestMoeWarPreparationHelperSweep(helperId, stageId)
        return
    end

    local curMoodValue = XDataCenter.MoeWarManager.GetMoodValue(helperId)
    local costMoodNum = XMoeWarConfig.GetStageCostMoodNum(stageId, helperId)
    if curMoodValue < costMoodNum then
        XUiManager.DialogTip(CSXTextManagerGetText("TipTitle"), CSXTextManagerGetText("MoeWarDispatchMoodLack"), XUiManager.DialogType.Normal, nil, function()
            XLuaUiManager.Open("UiMoeWarRecruit", helperId)
        end)
        return
    end

    local labelIds = XMoeWarConfig.GetPreparationStageLabelIds(stageId)
    if #labelIds ~= self.FillConditionCount then
        XUiManager.DialogTip(CSXTextManagerGetText("TipTitle"), CSXTextManagerGetText("MoeWarConditionNotAllComplete"), XUiManager.DialogType.Normal, nil, function()
            self:Close()
            XDataCenter.MoeWarManager.RequestMoeWarPreparationHelperSweep(helperId, stageId)
        end)
        return
    end

    self:Close()
    XDataCenter.MoeWarManager.RequestMoeWarPreparationHelperSweep(helperId, stageId)
end

function XUiMoeWarDispatch:OnBtnArrorLeftClick()
    self:OnBtnArrorClick(self.CurrSelectStageIndex - 1)
end

function XUiMoeWarDispatch:OnBtnArrorRightClick()
    self:OnBtnArrorClick(self.CurrSelectStageIndex + 1)
end

function XUiMoeWarDispatch:OnBtnArrorClick(stageIndex)
    if self:CheckStageIndexOutOfRange(stageIndex) then
        return
    end
    self:PlayAnimation("QieHuan")
    self.CurrSelectStageIndex = stageIndex
    self:UpdateStageId(self.AllOpenStageIdList[stageIndex])
    self:Refresh()
end

function XUiMoeWarDispatch:OnBtnAssistClick()
    XLuaUiManager.Open("UiMoeWarRecruit")
end

function XUiMoeWarDispatch:CheckStageIndexOutOfRange(stageIndex)
    if stageIndex <= 0 then
        return true
    end

    local maxStageCount = #self.AllOpenStageIdList
    if stageIndex > maxStageCount then
        return true
    end

    return false
end

function XUiMoeWarDispatch:Refresh()
    -- self:CheckClearPrepareTeamData()
    self:RefreshBtnArror()
    self:RefreshHelperCondition()
    self:RefreshReward()
    self:RefreshOccupy()
    -- self:CheckLastTimer()
end

function XUiMoeWarDispatch:RefreshBtnArror()
    local maxStageCount = #self.AllOpenStageIdList
    self.BtnArrorLeft.gameObject:SetActiveEx(self.CurrSelectStageIndex > 1)
    self.BtnArrorRight.gameObject:SetActiveEx(self.CurrSelectStageIndex < maxStageCount)
end

--刷新当前选择的角色
function XUiMoeWarDispatch:RefreshOccupy()
    self.HelperGrid:Refresh({
        HelperId = self.HelperId,
        StageId = self.StageId,
    })
end

function XUiMoeWarDispatch:CheckClearPrepareTeamData()
    if not IsNumberValid(self.HelperId) then
        return
    end

    local expirationTime = XDataCenter.MoeWarManager.GetRecruitHelperExpirationTime(self.HelperId)
    local nowServerTime = XTime.GetServerNowTimestamp()
    if IsNumberValid(expirationTime) and nowServerTime >= expirationTime then
        XDataCenter.MoeWarManager.ClearPrepareTeamData()
    end
end

function XUiMoeWarDispatch:CheckLastTimer()
    self:StopLastTimer()

    local helperId = self.HelperId
    local expirationTime = XDataCenter.MoeWarManager.GetRecruitHelperExpirationTime(helperId)
    local nowServerTime = XTime.GetServerNowTimestamp()
    if not XTool.IsNumberValid(helperId) or nowServerTime >= expirationTime then
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

function XUiMoeWarDispatch:SetImgLastTimeIsActive(isActive)
    if self.ImgLastTime then
        self.ImgLastTime.gameObject:SetActiveEx(isActive)
    end
end

function XUiMoeWarDispatch:StopLastTimer()
    if self.LastTimer then
        XScheduleManager.UnSchedule(self.LastTimer)
        self.LastTimer = nil
    end
end

function XUiMoeWarDispatch:RefreshExtraReward()
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

function XUiMoeWarDispatch:RefreshReward()
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

function XUiMoeWarDispatch:RefreshHelperCondition()
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

function XUiMoeWarDispatch:CheckHelperOverExpiredHint()
    local teamData = XDataCenter.MoeWarManager.GetPrepareTeamData(self.StageId)
    local charId = teamData[1]
    local helperId = XDataCenter.MoeWarManager.GetPrepareOwnHelperId(charId)
    if XDataCenter.MoeWarManager.IsHelperExpired(helperId) then
        XUiManager.TipText("MoeWarHelperOverExpired")
    end
end