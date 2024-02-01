local CsXTextManager = CS.XTextManager
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

--######################## XUiReformTaskGrid ########################
local XUiReformTaskGrid = XClass(nil, "XUiReformTaskGrid")

function XUiReformTaskGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.Data = nil
    self.RootUi = rootUi
    self.UiGridCommon = XUiGridCommon.New(rootUi, self.GridCommon)
    self.BtnClick.CallBack = function() self:OnBtnClicked() end
end

-- data : TaskData
function XUiReformTaskGrid:SetData(data, nextData, maxScore, normalMaxScore)
    -- if normalMaxScore == nil then normalMaxScore = 0 end 
    self.Data = data
    -- 分数
    local score = XDataCenter.ReformActivityManager.GetTaskFinishScore(data.Id)
    self.TxtScore.text = score
    -- 完成状态
    self.PanelFinish.gameObject:SetActiveEx(data.State == XDataCenter.TaskManager.TaskState.Finish)
    -- 物品信息
    local rewardId = XTaskConfig.GetTaskRewardId(data.Id)
    local rewardList = XRewardManager.GetRewardList(rewardId)
    self.UiGridCommon:Refresh(rewardList[1])
    -- 红点
    self.Red.gameObject:SetActiveEx(data.State == XDataCenter.TaskManager.TaskState.Achieved)
    -- self.ImgEffect.gameObject:SetActiveEx(data.State == XDataCenter.TaskManager.TaskState.Achieved)
    -- 任务进度
    local nextScore = XDataCenter.ReformActivityManager.GetTaskFinishScore(nextData.Id)
    -- local progress = (maxScore + normalMaxScore - score) / (nextScore - score)
    local progress = (maxScore - score) / (nextScore - score)
    self.PanelPassedLine.fillAmount = progress
end

function XUiReformTaskGrid:OnBtnClicked()
    if not XDataCenter.ReformActivityManager.GetIsOpen() then
        XLuaUiManager.RunMain()
        XUiManager.TipError(CsXTextManager.GetText("ReformAtivityTimeEnd"))
        return
    end
    if self.Data.State == XDataCenter.TaskManager.TaskState.Achieved then
        XDataCenter.ReformActivityManager.RequestFinishAllTask(function(rewardGoodsList)
            XUiManager.OpenUiObtain(rewardGoodsList)
            self.RootUi:RefreshTaskDataGrid()
        end)
        return
    end
    XUiManager.OpenUiTipRewardByRewardId(XTaskConfig.GetTaskRewardId(self.Data.Id))
end

--######################## XUiReformReadyPanel ########################
local XUiReformReadyPanel = XClass(nil, "XUiReformReadyPanel")

function XUiReformReadyPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.BaseStage = nil
    self.GridBuff.gameObject:SetActiveEx(false)
    self.GridCommon.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    -- 资源
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem
    , XDataCenter.ItemManager.ItemId.ActionPoint)
end

function XUiReformReadyPanel:SetData(baseStage)
    self.BaseStage = baseStage
    -- 关卡名称
    local evolableStage = baseStage:GetCurrentEvolvableStage()
    self.TxtTitle.text = CsXTextManager.GetText("ReformReadyTitleText", baseStage:GetName()
    , evolableStage:GetName())
    -- 词缀
    local fightEvents = baseStage:GetShowFightEvents()
    self.PanelBuffContent.gameObject:SetActiveEx(#fightEvents > 0)
    self.PanelBuffNone.gameObject:SetActiveEx(#fightEvents <= 0)
    if #fightEvents > 0 then
        for i = 2, self.PanelBuffContent.childCount do
            CS.UnityEngine.Object.Destroy(self.PanelBuffContent:GetChild(i - 1).gameObject)
        end
        local go
        for i, v in ipairs(fightEvents) do
            go = CS.UnityEngine.Object.Instantiate(self.GridBuff, self.PanelBuffContent)
            go.gameObject:SetActiveEx(true)
            go.transform:Find("Buff"):GetComponent("RawImage"):SetRawImage(v.Icon)
        end
    end
    -- 奖励面板
    local isPassed = baseStage:GetIsPassed()
    self.PanelPassed.gameObject:SetActiveEx(true)
    self.PanelNotPassed.gameObject:SetActiveEx(not isPassed)
    self.TxtRecommendScoreTip1.text = XUiHelper.GetText("ReformChallengeScoreTip", self.BaseStage:GetMaxChallengeScore())
    self.TxtRecommendScoreTip2.text = self.TxtRecommendScoreTip1.text
    self.TxtScoreTip1.text = XUiHelper.GetText("ReformRecommendScoreTip", self.BaseStage:GetAccumulativeScore()
        , self.BaseStage:GetRecommendScore())
    self.TxtScoreTip2.text = self.TxtScoreTip1.text
    -- 显示的首通奖励
    local rewardList = baseStage:GetFirstRewards()
    XUiHelper.RefreshCustomizedList(self.PanelReward, self.GridCommon, #rewardList, function(index, go)
        local gridCommont = XUiGridCommon.New(self.RootUi, go)
        gridCommont:Refresh(rewardList[index])
    end)
    -- local reward = baseStage:GetFirstRewards()[1]
    -- self.GridCommon.gameObject:SetActiveEx(reward ~= nil)
    -- if reward then
    --     local gridCommont = XUiGridCommon.New(self.RootUi, self.GridCommon)
    --     gridCommont:Refresh(reward)
    --     gridCommont:SetProxyClickFunc(function()
    --         XUiManager.OpenUiTipRewardByRewardId(self.BaseStage:GetFirstRewardId())
    --     end)
    -- end
    -- 显示的推荐角色
    local icons = self.BaseStage:GetRecommendCharacterIcons()
    local icon
    for i = 1, 3 do
        icon = icons[i]
        self["PanelHead" .. i].gameObject:SetActiveEx(icon ~= nil)
        if icon then
            self["RImgHeadIcon" .. i]:SetRawImage(icon)
        end
    end
    self.TxtRecommendTip.gameObject:SetActiveEx(evolableStage:GetChallengeScore() 
        < baseStage:GetRecommendScore())
end

function XUiReformReadyPanel:Open(baseStage)
    local showTip, evolvableStage = baseStage:GetIsShowEvolvableDiffTip()
    if showTip then
        XUiManager.TipError(CsXTextManager.GetText("ReformEvolvableDiffOpenTip", baseStage:GetName()
        , evolvableStage:GetName()))
    end
    self.EnterAnim:Play()
    self.GameObject:SetActiveEx(true)
    XDataCenter.ReformActivityManager.SetCurrentBaseStageId(baseStage:GetId(), baseStage:GetStageType())
end

function XUiReformReadyPanel:Close()
    self.EnterAnim:Stop()
    self.GameObject:SetActiveEx(false)
    -- self.RootUi.UiPanelAsset.GameObject:SetActiveEx(true)
end

--######################## 私有方法 ########################
function XUiReformReadyPanel:RegisterUiEvents()
    self.BtnClose.CallBack = function() self:Close() end
    self.BtnEnter.CallBack = function() self:OnBtnEnterClicked() end
    self.BtnBuffTip.CallBack = function() self:OnBtnBuffTipClicked() end
end

function XUiReformReadyPanel:OnBtnEnterClicked()
    self:Close()
    local evolvableStage = self.BaseStage:GetCurrentEvolvableStage()
    local diff = evolvableStage:GetDifficulty()
    -- 非基础关从上一关难度继承队伍
    if diff > 1 then
        evolvableStage:InheritTeamFromEvolableStage(self.BaseStage:GetEvolvableStageByDiffIndex(diff - 1))
    end
    XLuaUiManager.Open("UiBattleRoleRoom",
    self.BaseStage:GetId(),
    evolvableStage:GetTeam(),
    require("XUi/XUiReform/XUiReformBattleRoleRoom"))
end

function XUiReformReadyPanel:OnBtnBuffTipClicked()
    local showFightEvents = self.BaseStage:GetShowFightEvents()
    if #showFightEvents > 0 then
        XLuaUiManager.Open("UiReformBuffTips", showFightEvents, CsXTextManager.GetText("ReformMainBuffTipsTitle"))
    end
end

--######################## XUiReform ########################
local XUiReformStageGridContainer = require("XUi/XUiReform/XUiReformStageGridContainer")
local XUiReform = XLuaUiManager.Register(XLuaUi, "UiReform")

function XUiReform:OnAwake()
    self.ReformActivityManager = XDataCenter.ReformActivityManager
    self.CurrentStageType = XReformConfigs.StageType.Normal
    self.CurrentBaseStage = nil
    self.CurrentEvolvableBaseStage = nil
    self.ActivityTimer = nil
    self:RegisterUiEvents()
    self.UiReformReadyPanel = XUiReformReadyPanel.New(self.PanelStageDetail, self)
    self.MosterHideParts = {}
    self.MosterEffects = {}
    -- 关卡列表
    self.UiReformStageGridDic = {}
    self.GridStage.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelStageList)
    self.DynamicTable:SetProxy(XUiReformStageGridContainer)
    self.DynamicTable:SetDelegate(self)
    -- 初始化任务
    self.UiReformTaskGrids = {}
    -- self:InitTaskDataGrid()
    -- 模型动画播放
    self.ModelAnimEnter = self.UiModelGo.transform:FindTransform("CamNearAnimation"):GetComponent("PlayableDirector")
    self.ModelAnimEnter:Play()
    -- 模型初始化
    local panelRoleModel = self.UiModelGo.transform:FindTransform("PanelRoleModel")
    self.UiPanelRoleModel = XUiPanelRoleModel.New(panelRoleModel, self.Name, nil, true)
    -- 资源
    self.UiPanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem
    , XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.EffectReformUnlock.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren = self.UiModelGo.transform:FindTransform("ImgEffectHuanren")
    -- 自动关闭
    local endTime = self.ReformActivityManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self.ReformActivityManager.HandleActivityEndTime()
        else
            self.TxtRemainTime.text = self.ReformActivityManager.GetLeaveTimeStr()
            self.TxtRemainTimeHard.text = self.TxtRemainTime.text            
            for _, grid in pairs(self.UiReformStageGridDic) do
                grid:RefreshStatus()
            end
        end
    end, nil, 1500)
end

function XUiReform:OnStart()
    self.CurrentStageType = self.ReformActivityManager.GetCurrentStageType()
    self.CurrentBaseStage = self.ReformActivityManager.GetCurrentBaseStage(self.CurrentStageType)
    self.CurrentEvolvableBaseStage = self.CurrentBaseStage:GetCurrentEvolvableStage()
    self.TxtMaxScoreTitle.text = CsXTextManager.GetText("ReformMaxScoreTitle")
    self.PanelNormal.gameObject:SetActiveEx(self.CurrentStageType == XReformConfigs.StageType.Normal)
    self.PanelHard.gameObject:SetActiveEx(self.CurrentStageType == XReformConfigs.StageType.Challenge)
end

function XUiReform:OnEnable()
    XUiReform.Super.OnEnable(self)
    self:RefreshUiScene(self.CurrentStageType, function()
        self.TxtRemainTime.text = self.ReformActivityManager.GetLeaveTimeStr()
        -- 基础关卡列表
        self:RefreshDynamicTable()
        self:RefreshBaseStageInfo(self.CurrentBaseStage)
        self:RefreshTaskDataGrid()
        -- XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.RefreshTaskDataGrid, self)
        self.BtnHard:SetDisable(not self.ReformActivityManager.CheckIsUnlockChallenge())
    end)
end

function XUiReform:OnDisable()
    XUiReform.Super.OnDisable(self)
    -- XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.RefreshTaskDataGrid, self)
end

--######################## 私有方法 ########################
function XUiReform:OnCheckBtnReformRedPoint(count)
    self.BtnReform:ShowReddot(count >= 0)
    self.BtnReformHard:ShowReddot(count >= 0)
end

function XUiReform:RefreshTaskDataGridGo()
    local taskDatas = self.ReformActivityManager.GetTaskDatas(self.CurrentStageType)
    self.UiReformTaskGrids = {}
    XUiHelper.RefreshCustomizedList(self.PanelCourseContainer, self.GridCourse, #taskDatas + 1, function(index, go)
        if index > 1 then
            local grid = XUiReformTaskGrid.New(go, self)
            self.UiReformTaskGrids[index - 1] = grid
        end
    end)
end

function XUiReform:RefreshTaskDataGrid()
    self:RefreshTaskDataGridGo()
    local taskDatas = self.ReformActivityManager.GetTaskDatas(self.CurrentStageType)
    local maxScore = self.ReformActivityManager.GetTaskMaxScore()
    local scrollIndex = nil
    local tmpTaskData = nil
    local lastFinishIndex = 0
    local noramlTasks, normalMaxScore
    if self.CurrentStageType == XReformConfigs.StageType.Challenge then
        noramlTasks = self.ReformActivityManager.GetTaskDatas(XReformConfigs.StageType.Normal)
        normalMaxScore = self.ReformActivityManager.GetTaskFinishScore(noramlTasks[#noramlTasks].Id)
    end
    for index, grid in ipairs(self.UiReformTaskGrids) do
        tmpTaskData = taskDatas[index]
        -- 一进来去到开始能完成的任务
        if tmpTaskData.State == XDataCenter.TaskManager.TaskState.Achieved and scrollIndex == nil then
            scrollIndex = index
        elseif tmpTaskData.State == XDataCenter.TaskManager.TaskState.Finish then
            lastFinishIndex = index
        end
        grid:SetData(tmpTaskData, taskDatas[math.min(index + 1, #taskDatas)], maxScore, normalMaxScore)
    end
    if scrollIndex == nil then
        scrollIndex = math.min(lastFinishIndex + 1, #taskDatas)
    end
    local firstTaskData = taskDatas[1]
    self.TxtTaskScore.text = maxScore
    local nextScore = self.ReformActivityManager.GetTaskFinishScore(firstTaskData.Id)
    local progress = maxScore / nextScore
    if self.CurrentStageType == XReformConfigs.StageType.Challenge then
        progress = (maxScore -  normalMaxScore) / (nextScore - normalMaxScore) 
    end
    self.ImgFirstPassedLine.fillAmount = progress
    XScheduleManager.ScheduleOnce(function()
        self:ScrollTaskGrid(scrollIndex)
    end, 0.01)
end

function XUiReform:RegisterUiEvents()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnReform.CallBack = function() self:OnBtnReformClicked() end
    self.BtnReformHard.CallBack = function() self:OnBtnReformClicked() end
    self.BtnEnterStage.CallBack = function() self:OnBtnEnterStageClicked() end
    self.BtnEnterStageHard.CallBack = function() self:OnBtnEnterStageClicked() end
    -- self.BtnPreview.CallBack = function() self:OnBtnPreviewClicked() end
    self:BindHelpBtn(self.BtnHelp, self.ReformActivityManager.GetHelpName())
    self:BindHelpBtn(self.BtnScoreHelp, self.ReformActivityManager.GetScoreHelpName())
    if self.BtnScoreHelp2 then -- 防打包
        self:BindHelpBtn(self.BtnScoreHelp2, self.ReformActivityManager.GetScoreHelpName())    
    end
    XUiHelper.RegisterClickEvent(self, self.BtnNormal, self.OnBtnNormalClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnHard, self.OnBtnHardClicked)
end

function XUiReform:OnBtnNormalClicked()
    self.CurrentStageType = XReformConfigs.StageType.Normal
    self:RefreshUiScene(self.CurrentStageType, function()
        self:RefreshDynamicTable()
        self:RefreshBaseStageInfo(self.ReformActivityManager.GetCurrentBaseStage(self.CurrentStageType))
        self.PanelNormal.gameObject:SetActiveEx(true)
        self.PanelHard.gameObject:SetActiveEx(false)
        self.AnimSwitch:Play()
        self:RefreshTaskDataGrid()
    end)
end

function XUiReform:OnBtnHardClicked()
    if not self.ReformActivityManager.CheckIsUnlockChallenge() then
        XUiManager.TipErrorWithKey("ReformLockChallengeTip", self.ReformActivityManager.GetUnlockChallengeScores())
        return
    end
    self.CurrentStageType = XReformConfigs.StageType.Challenge
    self:RefreshUiScene(self.CurrentStageType, function()
        self:RefreshDynamicTable()
        self:RefreshBaseStageInfo(self.ReformActivityManager.GetCurrentBaseStage(self.CurrentStageType))
        self.PanelNormal.gameObject:SetActiveEx(false)
        self.PanelHard.gameObject:SetActiveEx(true)
        self.AnimSwitch:Play()
        self:RefreshTaskDataGrid()
    end)
end

function XUiReform:RefreshUiScene(stageType, cb)
    local sceneUrl, modelUrl = self.ReformActivityManager.GetSceneUrlAndModelUrl(self.CurrentStageType)
    self:LoadUiScene(sceneUrl, modelUrl, function()
        self.ModelAnimEnter = self.UiModelGo.transform:FindTransform("CamNearAnimation"):GetComponent("PlayableDirector")
        local panelRoleModel = self.UiModelGo.transform:FindTransform("PanelRoleModel")
        self.UiPanelRoleModel = XUiPanelRoleModel.New(panelRoleModel, self.Name, nil, true)
        self.ImgEffectHuanren = self.UiModelGo.transform:FindTransform("ImgEffectHuanren")
        if cb then cb() end
    end)
end

function XUiReform:RefreshBaseStageInfo(baseStage)
    self.CurrentBaseStage = baseStage
    self.CurrentEvolvableBaseStage = self.CurrentBaseStage:GetCurrentEvolvableStage()
    -- 累计积分
    self.TxtAccumulativeScore.text = self.CurrentBaseStage:GetAccumulativeScore()
    self.TxtAccumulativeScoreHard.text = self.TxtAccumulativeScore.text
    -- 本次挑战积分
    self.TxtChallengeScore.text = self.CurrentEvolvableBaseStage:GetChallengeScore()
    self.TxtChallengeScoreHard.text = self.TxtChallengeScore.text
    -- 推荐积分
    self.TxtRecommendScore.text = self.CurrentBaseStage:GetRecommendScore()
    self.TxtRecommendScoreHard.text = self.TxtRecommendScore.text
    -- -- 当前改造等级名称
    -- self.TxtGrade.text = self.CurrentEvolvableBaseStage:GetName()
    -- 刷新模型
    self:RefreshModel(baseStage:GetShowNpcId())
    self.BtnReform:SetDisable(not baseStage:CheckIsCanReform())
    self.BtnReformHard:SetDisable(not baseStage:CheckIsCanReform())
    -- 播放开锁特效
    if baseStage:GetIsPlayReformUnlockEffect() then
        XScheduleManager.ScheduleOnce(function()
            if self == nil then return end
            if XTool.UObjIsNil(self.EffectReformUnlock) then
                return
            end
            self.EffectReformUnlock.gameObject:SetActiveEx(false)
            self.EffectReformUnlock.gameObject:SetActiveEx(true)
        end, 1000)
    end
    -- 检查改造关卡小红点
    XRedPointManager.CheckOnce(self.OnCheckBtnReformRedPoint, self, { XRedPointConditions.Types.CONDITION_REFORM_EVOLVABLE_STAGE_UNLOCK }, {
        BaseStageId = self.CurrentBaseStage:GetId(),
        EvolvableDiffIndex = nil
    })
end

function XUiReform:RefreshModel(npcId)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    for _, prats in pairs(self.MosterHideParts) do
        if not XTool.UObjIsNil(prats) then
            prats.gameObject:SetActiveEx(true)
        end
    end
    for _, effect in pairs(self.MosterEffects) do
        if not XTool.UObjIsNil(effect) then
            effect.gameObject:SetActiveEx(false)
        end
    end
    self.MosterHideParts = {}
    self.MosterEffects = {}
    local transDatas = XMVCA.XArchive:GetMonsterTransDatas(npcId, 1)
    local effectDatas = XMVCA.XArchive:GetMonsterEffectDatas(npcId, 1)
    local modelId = XMVCA.XArchive:GetMonsterModel(npcId)
    self.UiPanelRoleModel:SetDefaultAnimation(transDatas and transDatas.StandAnime)
    self.UiPanelRoleModel:UpdateArchiveMonsterModel(modelId, XModelManager.MODEL_UINAME.UiReform)
    self.UiPanelRoleModel:ShowRoleModel()
    local modelInfo = self.UiPanelRoleModel:GetModelInfoByName(modelId)
    local modelGo = modelInfo.Model
    if transDatas then
        for _, node in pairs(transDatas.HideNodeName or {}) do
            local parts = modelGo.gameObject:FindTransform(node)
            if not XTool.UObjIsNil(parts) then
                parts.gameObject:SetActiveEx(false)
                table.insert(self.MosterHideParts, parts)
            else
                XLog.Error("HideNodeName Is Wrong :" .. node)
            end
        end
    end
    if effectDatas then
        for node, effectPath in pairs(effectDatas) do
            local parts = modelGo.gameObject:FindTransform(node)
            if not XTool.UObjIsNil(parts) then
                local effect = parts.gameObject:LoadPrefab(effectPath, false)
                if effect then
                    effect.gameObject:SetActiveEx(true)
                    table.insert(self.MosterEffects, effect)
                end
            else
                XLog.Error("EffectNodeName Is Wrong :" .. node)
            end
        end
    end
end

function XUiReform:RefreshDynamicTable(baseStages)
    local index = 1
    if baseStages == nil then
        baseStages = self.ReformActivityManager.GetBaseStages(self.CurrentStageType)
    end
    for i, baseStage in ipairs(baseStages) do
        if baseStage:GetId() == self.ReformActivityManager.GetCurrentBaseStageId(self.CurrentStageType) then
            index = i
            break
        end
    end
    self.UiReformStageGridDic = {}
    self.DynamicTable:SetDataSource(baseStages)
    self.DynamicTable:ReloadDataSync(index)
    self.ReformActivityManager.SetBaseStageRedDotHistory(baseStages[index]:GetId())
end

function XUiReform:OnDynamicTableEvent(event, index, grid)
    if index <= 0 then return end
    local baseStage = self.DynamicTable.DataSource[index]
    if baseStage == nil then return end
    self.UiReformStageGridDic[baseStage:GetId()] = grid
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(baseStage, index)
        grid:SetClickCallBack(self, self.OnStageGridClicked)
        grid:RefreshStatus()
    end
end

function XUiReform:OnStageGridClicked(selectedIndex)
    local baseStage = self.DynamicTable.DataSource[selectedIndex]
    if not baseStage:GetIsUnlock() then
        XUiManager.TipError(CsXTextManager.GetText("ReformStageTimeLockTip"))
        return
    end
    self.ReformActivityManager.SetCurrentBaseStageId(baseStage:GetId(), baseStage:GetStageType())
    self:RefreshBaseStageInfo(self.DynamicTable.DataSource[selectedIndex])
    for id, stageGrid in pairs(self.UiReformStageGridDic) do
        stageGrid:SetSelectStatus(baseStage:GetId() == id)
    end
    self.UiReformStageGridDic[baseStage:GetId()]:SetSelectStatus(true)
end

function XUiReform:OnBtnReformClicked()
    if not self.CurrentBaseStage:CheckIsCanReform() then
        XUiManager.TipError(CsXTextManager.GetText("ReformStagePassLockTip"))
        return
    end
    XLuaUiManager.Open("UiReformList", self.CurrentBaseStage)
end

function XUiReform:OnBtnEnterStageClicked()
    self.UiReformReadyPanel:Open(self.CurrentBaseStage)
    self.UiReformReadyPanel:SetData(self.CurrentBaseStage)
    -- self.UiPanelAsset.GameObject:SetActiveEx(false)
end

-- function XUiReform:OnBtnPreviewClicked()
--     if not self.CurrentBaseStage:CheckIsCanReform() then
--         XUiManager.TipError(CsXTextManager.GetText("ReformPreviewLimitTip"))
--         return
--     end
--     XLuaUiManager.Open("UiReformPreview", self.CurrentEvolvableBaseStage)
-- end

function XUiReform:ScrollTaskGrid(index)
    local grid = self.UiReformTaskGrids[index]
    if grid == nil then return end
    local targetPos = self.PanelCourseContainer.localPosition
    local viewPortWidthHalf = self.PanelCourseContainer.parent.rect.width / 2
    local maxValue = (self.PanelCourseContainer.rect.width - viewPortWidthHalf) * -1
    targetPos.x = math.max(maxValue, -grid.Transform.localPosition.x + grid.Transform.rect.width / 2 - viewPortWidthHalf + 50)
    XUiHelper.DoMove(self.PanelCourseContainer, targetPos, 0.3, XUiHelper.EaseType.Sin)
end

return XUiReform