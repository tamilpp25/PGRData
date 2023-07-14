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
function XUiReformTaskGrid:SetData(data, nextData, maxScore)
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

--######################## XUiReformStageGrid ########################
local XUiReformStageGrid = XClass(nil, "XUiReformStageGrid")

function XUiReformStageGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BaseStage = nil
    self.ClickProxy = nil
    self.ClickCallback = nil
    self.Index = nil
    self.Score = nil
    self.BtnSelf.CallBack = function() self:OnBtnSelfClicked() end
end

function XUiReformStageGrid:SetData(baseStage, index)
    self.BaseStage = baseStage
    self.Index = index
    -- 名字
    self.BtnSelf:SetNameByGroup(0, baseStage:GetName())
    self:RefreshStatus()
    -- 是否选中
    local isSelected = baseStage:GetId() == XDataCenter.ReformActivityManager.GetCurrentBaseStageId()
    self:SetSelectStatus(isSelected)
    self.Red.gameObject:SetActiveEx(XDataCenter.ReformActivityManager.CheckBaseStageIsShowRedDot(baseStage:GetId()))
end

function XUiReformStageGrid:RefreshStatus()
    local isUnlock = self.BaseStage:GetIsUnlock()
    local score = self.BaseStage:GetAccumulativeScore()
    local isSelected = self.BaseStage:GetId() == XDataCenter.ReformActivityManager.GetCurrentBaseStageId()
    self.Score = score
    self.Currency.gameObject:SetActiveEx(isUnlock and score > 0 and not isSelected)
    self.Currency2.gameObject:SetActiveEx(isUnlock and score > 0 and isSelected)
    self.Lock.gameObject:SetActiveEx(not isUnlock)
    if isUnlock then
        -- 分数
        self.TxtScore.text = score
        self.TxtScore2.text = score
    else
        -- 解锁时间
        self.TxtUnlockTime.text = CsXTextManager.GetText("ReformBaseStageUnlockText", self.BaseStage:GetUnlockTimeStr())
    end
end

function XUiReformStageGrid:SetClickCallBack(clickProxy, clickCallback)
    self.ClickProxy = clickProxy
    self.ClickCallback = clickCallback
end

function XUiReformStageGrid:SetSelectStatus(value)
    self.Select.gameObject:SetActiveEx(value)
    local isUnlock = self.BaseStage:GetIsUnlock()
    if isUnlock and self.Score > 0 then
        self.Currency.gameObject:SetActiveEx(not value)
        self.Currency2.gameObject:SetActiveEx(value)
    end
end

function XUiReformStageGrid:OnBtnSelfClicked()
    if self.ClickCallback then
        self.ClickCallback(self.ClickProxy, self.Index)
    end
    if self.BaseStage:GetIsUnlock() then
        XDataCenter.ReformActivityManager.SetBaseStageRedDotHistory(self.BaseStage:GetId())
        self.Red.gameObject:SetActiveEx(XDataCenter.ReformActivityManager.CheckBaseStageIsShowRedDot(self.BaseStage:GetId()))
    end
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
    self.TxtTitle.text = CsXTextManager.GetText("ReformReadyTitleText", baseStage:GetName()
    , baseStage:GetCurrentEvolvableStage():GetName())
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
    -- 提示
    local tips = baseStage:GetShowTips()
    for i = 1, self.PanelTips.childCount do
        if tips[i] then
            self["TxtTip" .. i].gameObject:SetActiveEx(true)
            self["TxtTip" .. i].text = tips[i]
        else
            self["TxtTip" .. i].gameObject:SetActiveEx(false)
        end
    end
    -- 首通奖励 PanelDropContent
    local isPassed = baseStage:GetIsPassed()
    self.PanelIntegral.gameObject:SetActiveEx(isPassed)
    self.UireformIcon.gameObject:SetActiveEx(isPassed)
    self.PanelAwardList.gameObject:SetActiveEx(not isPassed)
    if isPassed then
        local currentEvolvableStage = baseStage:GetCurrentEvolvableStage()
        self.TxtFirstDrop.text = CsXTextManager.GetText("ReformReadyScoreDropText")
        self.TxtScore.text = CsXTextManager.GetText("ReformReadyPanelMaxScoreTip"
        , currentEvolvableStage:GetChallengeScore()
        , currentEvolvableStage:GetMaxChallengeScore())
    else
        self.TxtFirstDrop.text = CsXTextManager.GetText("ReformReadyFirstDropText")
        for i = 2, self.PanelDropContent.childCount do
            CS.UnityEngine.Object.Destroy(self.PanelDropContent:GetChild(i - 1).gameObject)
        end
        local rewardList = baseStage:GetFirstRewards()
        local gridCommont = nil
        local go = nil
        for _, reward in ipairs(rewardList) do
            go = CS.UnityEngine.Object.Instantiate(self.GridCommon, self.PanelDropContent)
            go.gameObject:SetActiveEx(false)
            gridCommont = XUiGridCommon.New(self.RootUi, go)
            gridCommont:Refresh(reward)
        end
    end
end

function XUiReformReadyPanel:Open(baseStage)
    local showTip, evolvableStage = baseStage:GetIsShowEvolvableDiffTip()
    if showTip then
        XUiManager.TipError(CsXTextManager.GetText("ReformEvolvableDiffOpenTip", baseStage:GetName()
        , evolvableStage:GetName()))
    end
    self.EnterAnim:Play()
    self.GameObject:SetActiveEx(true)
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
    -- XLuaUiManager.Open("UiNewRoomSingle", self.BaseStage:GetId())
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
local XUiReform = XLuaUiManager.Register(XLuaUi, "UiReform")

function XUiReform:OnAwake()
    self.CurrentBaseStage = nil
    self.CurrentEvolvableBaseStage = nil
    self.ActivityTimer = nil
    self:RegisterUiEvents()
    self.UiReformReadyPanel = XUiReformReadyPanel.New(self.PanelStageDetail, self)
    self.MosterHideParts = {}
    self.MosterEffects = {}
    XUiNewRoomSingleProxy.RegisterProxy(XDataCenter.FubenManager.StageType.Reform,
    require("XUi/XUiReform/XUiReformNewRoomSingle"))
    -- 关卡列表
    self.UiReformStageGridDic = {}
    self.GridStage.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelStageList)
    self.DynamicTable:SetProxy(XUiReformStageGrid)
    self.DynamicTable:SetDelegate(self)
    -- 初始化任务
    self.UiReformTaskGrids = {}
    self:InitTaskDataGrid()
    -- 模型初始化
    local panelRoleModel = self.UiModelGo.transform:FindTransform("PanelRoleModel")
    self.UiPanelRoleModel = XUiPanelRoleModel.New(panelRoleModel, self.Name, nil, true)
    -- 资源
    self.UiPanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem
    , XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.EffectReformUnlock.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren = self.UiModelGo.transform:FindTransform("ImgEffectHuanren")
    -- 自动关闭
    local endTime = XDataCenter.ReformActivityManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.ReformActivityManager.HandleActivityEndTime()
        else
            self.TxtRemainTime.text = XDataCenter.ReformActivityManager.GetLeaveTimeStr()
            for _, grid in pairs(self.UiReformStageGridDic) do
                grid:RefreshStatus()
            end
        end
    end)
end

function XUiReform:OnStart()
    local reformActivityManager = XDataCenter.ReformActivityManager
    self.CurrentBaseStage = reformActivityManager.GetCurrentBaseStage()
    self.CurrentEvolvableBaseStage = self.CurrentBaseStage:GetCurrentEvolvableStage()
    -- 名字
    self.TxtTitle.text = reformActivityManager.GetActivityName()
    self.TxtMaxScoreTitle.text = CsXTextManager.GetText("ReformMaxScoreTitle")
end

function XUiReform:OnEnable()
    XUiReform.Super.OnEnable(self)
    self.TxtRemainTime.text = XDataCenter.ReformActivityManager.GetLeaveTimeStr()
    -- 基础关卡列表
    self:RefreshDynamicTable()
    self:RefreshBaseStageInfo(self.CurrentBaseStage)
    self:RefreshTaskDataGrid()
    -- XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.RefreshTaskDataGrid, self)
end

function XUiReform:OnDisable()
    XUiReform.Super.OnDisable(self)
    -- XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.RefreshTaskDataGrid, self)
end

--######################## 私有方法 ########################
function XUiReform:OnCheckBtnReformRedPoint(count)
    self.BtnReform:ShowReddot(count >= 0)
end

function XUiReform:InitTaskDataGrid()
    self.GridCourse.gameObject:SetActiveEx(false)
    local taskDatas = XDataCenter.ReformActivityManager.GetTaskDatas()
    local go = nil
    local grid = nil
    for index, taskData in ipairs(taskDatas) do
        go = CS.UnityEngine.Object.Instantiate(self.GridCourse, self.PanelCourseContainer)
        go.gameObject:SetActiveEx(true)
        grid = XUiReformTaskGrid.New(go, self)
        self.UiReformTaskGrids[index] = grid
    end
end

function XUiReform:RefreshTaskDataGrid()
    local taskDatas = XDataCenter.ReformActivityManager.GetTaskDatas()
    local maxScore = XDataCenter.ReformActivityManager.GetTaskMaxScore()
    local scrollIndex = nil
    local tmpTaskData = nil
    local lastFinishIndex = 0
    for index, grid in ipairs(self.UiReformTaskGrids) do
        tmpTaskData = taskDatas[index]
        -- 一进来去到开始能完成的任务
        if tmpTaskData.State == XDataCenter.TaskManager.TaskState.Achieved and scrollIndex == nil then
            scrollIndex = index
        elseif tmpTaskData.State == XDataCenter.TaskManager.TaskState.Finish then
            lastFinishIndex = index
        end
        grid:SetData(tmpTaskData, taskDatas[math.min(index + 1, #taskDatas)], maxScore)
    end
    if scrollIndex == nil then
        scrollIndex = math.min(lastFinishIndex + 1, #taskDatas)
    end
    local firstTaskData = taskDatas[1]
    self.TxtTaskScore.text = maxScore
    local nextScore = XDataCenter.ReformActivityManager.GetTaskFinishScore(firstTaskData.Id)
    local progress = maxScore / nextScore
    self.ImgFirstPassedLine.fillAmount = progress
    XScheduleManager.ScheduleOnce(function()
        self:ScrollTaskGrid(scrollIndex)
    end, 0.01)
end

function XUiReform:RegisterUiEvents()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnReform.CallBack = function() self:OnBtnReformClicked() end
    self.BtnEnterStage.CallBack = function() self:OnBtnEnterStageClicked() end
    self.BtnPreview.CallBack = function() self:OnBtnPreviewClicked() end
    self:BindHelpBtn(self.BtnHelp, XDataCenter.ReformActivityManager.GetHelpName())
    self:BindHelpBtn(self.BtnScoreHelp, XDataCenter.ReformActivityManager.GetScoreHelpName())
end

function XUiReform:RefreshBaseStageInfo(baseStage)
    self.CurrentBaseStage = baseStage
    self.CurrentEvolvableBaseStage = self.CurrentBaseStage:GetCurrentEvolvableStage()
    -- 累计积分
    self.TxtAccumulativeScore.text = self.CurrentBaseStage:GetAccumulativeScore()
    -- 本次挑战积分
    self.TxtChallengeScore.text = self.CurrentEvolvableBaseStage:GetChallengeScore()
    -- 当前改造等级名称
    self.TxtGrade.text = self.CurrentEvolvableBaseStage:GetName()
    -- 刷新模型
    self:RefreshModel(baseStage:GetShowNpcId())
    self.BtnReform:SetDisable(not baseStage:GetIsPassed())
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
    local transDatas = XArchiveConfigs.GetMonsterTransDatas(npcId, 1)
    local effectDatas = XArchiveConfigs.GetMonsterEffectDatas(npcId, 1)
    local modelId = XArchiveConfigs.GetMonsterModel(npcId)
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

function XUiReform:RefreshDynamicTable()
    local index = 1
    local baseStages = XDataCenter.ReformActivityManager.GetBaseStages()
    for i, baseStage in ipairs(baseStages) do
        if baseStage:GetId() == XDataCenter.ReformActivityManager.GetCurrentBaseStageId() then
            index = i
            break
        end
    end
    self.DynamicTable:SetDataSource(XDataCenter.ReformActivityManager.GetBaseStages())
    self.DynamicTable:ReloadDataSync(index)
    XDataCenter.ReformActivityManager.SetBaseStageRedDotHistory(baseStages[index]:GetId())
end

function XUiReform:OnDynamicTableEvent(event, index, grid)
    self.UiReformStageGridDic[index] = grid
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.DynamicTable.DataSource[index], index)
        grid:SetClickCallBack(self, self.OnStageGridClicked)
    end
end

function XUiReform:OnStageGridClicked(selectedIndex)
    local baseStage = self.DynamicTable.DataSource[selectedIndex]
    if not baseStage:GetIsUnlock() then
        XUiManager.TipError(CsXTextManager.GetText("ReformStageTimeLockTip"))
        return
    end
    XDataCenter.ReformActivityManager.SetCurrentBaseStageId(baseStage:GetId())
    self:RefreshBaseStageInfo(self.DynamicTable.DataSource[selectedIndex])
    for i, stageGrid in pairs(self.UiReformStageGridDic) do
        stageGrid:SetSelectStatus(selectedIndex == i)
    end
    self.UiReformStageGridDic[selectedIndex]:SetSelectStatus(true)
end

function XUiReform:OnBtnReformClicked()
    if not self.CurrentBaseStage:GetIsPassed() then
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

function XUiReform:OnBtnPreviewClicked()
    if not self.CurrentBaseStage:GetIsPassed() then
        XUiManager.TipError(CsXTextManager.GetText("ReformPreviewLimitTip"))
        return
    end
    XLuaUiManager.Open("UiReformPreview", self.CurrentEvolvableBaseStage)
end

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