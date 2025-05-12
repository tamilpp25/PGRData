local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiBossInshotSettlement:XLuaUi
---@field private _Control XBossInshotControl
local XUiBossInshotSettlement = XLuaUiManager.Register(XLuaUi, "UiBossInshotSettlement")

function XUiBossInshotSettlement:OnAwake()
    self.GridScore.gameObject:SetActiveEx(false)
    self.TxtScoreNum:TextToSprite("0")
    self.BtnExit.gameObject:SetActiveEx(true)
    self.BtnAgain.gameObject:SetActiveEx(true)
    self:RegisterUiEvents()
    self:InitDynamicTable()

    if CS.XRLManager.RLScene then
        CS.XRLManager.RLScene:SetUiEffectRootActive(false)
    end
    
    self:CheckMaskActive()

    local uiObj = self.UiSceneInfo.Transform:GetComponent("UiObject")
    if not uiObj then
        return
    end
    local screenShotEffect = uiObj:GetObject("CTVergil03pingfenwin")
    if screenShotEffect then
        screenShotEffect.gameObject:SetActiveEx(false)
    end
end

function XUiBossInshotSettlement:OnStart(settleData, isCheckActivityEnd)
    self.StageId = settleData.StageId
    self.SettleData = settleData
    self.IsCheckActivityEnd = isCheckActivityEnd == true

    -- 提前缓存IntToIntRecord数据，弹结算界面未退出战斗场景，仍在跑行为树逻辑，IntToIntRecord会产生变化
    self.FightIntToIntRecord = {}
    local result = XMVCA.XFuben:GetCurFightResult()
    local e = result.IntToIntRecord:GetEnumerator()
    while e:MoveNext() do
        self.FightIntToIntRecord[e.Current.Key] = e.Current.Value
    end
    e:Dispose()
end

function XUiBossInshotSettlement:OnEnable()
    self:Refresh()
    self:RemoveTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        if self.TxtScoreNum.gameObject.activeSelf then
            self:PlayScoreAnimation()
            self:RemoveTimer()
        end
    end, 1000)
end

function XUiBossInshotSettlement:OnDisable()
    self:RemoveTimer()
end

function XUiBossInshotSettlement:OnDestroy()
    self:ClearDynamicTimer()
    self:ClearGridsTimer()
    XMVCA:GetAgency(ModuleId.XBossInshot):ExitFight()
end

-- 检查黑边是否需要显示
function XUiBossInshotSettlement:CheckMaskActive()
    local currentWidth = CS.UnityEngine.Screen.width
    local currentHeight = CS.UnityEngine.Screen.height
    local scale = 1920 / 1010
    self.Mask.gameObject:SetActiveEx(currentWidth / currentHeight > scale)
end

function XUiBossInshotSettlement:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

-- 刷新场景特效
function XUiBossInshotSettlement:RefreshMarkEffectActive()
    local uiObj = self.UiSceneInfo.Transform:GetComponent("UiObject")
    if not uiObj then
        return
    end
    
    local screenShotEffect = uiObj:GetObject("FxUiDMCPingfenJieping")
    if screenShotEffect then
        screenShotEffect.gameObject:SetActiveEx(true)
    end

    -- 带截屏脚本的节点显示需要一帧，截屏也需要一帧，故延迟2帧等截屏完再开启其他节点
    local loop = 2
    XScheduleManager.Schedule(function()
        loop = loop - 1
        if loop > 0 or XTool.UObjIsNil(self.GameObject) then
            return
        end

        --因为播完之后会直接退出, 这里先提前结束特殊特效, 避免影响光照
        CS.XRenderFeatureManager.ExitFight()
        
        local team = self._Control:GetTeam()
        local id = team:GetCaptainPosEntityId()
        local effectName = self._Control:GetMarkEffectName(id)
        local markEffectObj = uiObj:GetObject(effectName)
        if markEffectObj then
            markEffectObj.gameObject:SetActiveEx(true)
        end
        
        local timelineObj = uiObj:GetObject("CTVergil03pingfenwin")
        if timelineObj then
            timelineObj.gameObject:SetActiveEx(true)
        end

        XScheduleManager.ScheduleOnce(function()
            if XTool.UObjIsNil(self.GameObject) then
                return
            end
            
            local levelEffectName
            if self._Control:IsFestivalActivityStage(self.StageId) then
                levelEffectName = "FxUiDMCPingfenS"
            else
                levelEffectName = self._Control:GetScoreLevelEffectName(self.Difficulty, self.Score)
            end
            
            local levelEffectObjet = uiObj:GetObject(levelEffectName)
            if levelEffectObjet then
                levelEffectObjet.gameObject:SetActiveEx(true)
            end
        end, 6200)
    end, 0, loop)
end

function XUiBossInshotSettlement:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnAgain, self.OnBtnAgainClick)
    self:RegisterClickEvent(self.BtnExit, self.OnBtnExitClick)
    self:RegisterClickEvent(self.BtnReplay, self.OnBtnReplayClick)
    self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick)
end

function XUiBossInshotSettlement:OnBtnAgainClick()
    -- 玩法结束
    local isOpen, tips = self._Control:IsActivityOpen()
    if not isOpen then
        self._Control:HandleActivityEnd()
        return
    end
    
    local stageId = self.StageId
    local team = self._Control:GetTeam()
    self._Control:SetAgainFight(true)

    -- 重新挑战，无须还原UI栈
    CsXUiManager.Instance:SetRevertAllLock(true)
    
    self:Close()
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    fubenAgency:EnterFightByStageId(stageId, team:GetId())
end

function XUiBossInshotSettlement:OnBtnExitClick()
    if self.IsCheckActivityEnd then
        -- 玩法结束
        local isOpen, tips = self._Control:IsActivityOpen()
        if not isOpen then
            self._Control:HandleActivityEnd()
            return
        end
    end
    
    self._Control:SetAgainFight(false)
    self:Close()
end

function XUiBossInshotSettlement:OnBtnReplayClick()
    if not self.PlaybackData then
        local scoreLevelIcon = self._Control:GetScoreLevelIcon(self.Difficulty, self.Score)
        self.PlaybackData = self._Control:GenLastPlaybackData(self.BossId, self.Score, scoreLevelIcon, self.Difficulty)
    end
    XLuaUiManager.Open("UiBossInshotPlayback", self.BossId, self.PlaybackData)
end

function XUiBossInshotSettlement:OnBtnHelpClick()
    XLuaUiManager.Open("UiBossInshotTip", self.FightIntToIntRecord)
end

-- 特殊关卡显示内容
function XUiBossInshotSettlement:RefreshByFestivalActivity()
    self.BtnReplay.gameObject:SetActiveEx(false)
    self.BtnHelp.gameObject:SetActiveEx(false)
    self.PanelNew.gameObject:SetActiveEx(false)
    self.BtnAgain.gameObject:SetActiveEx(false)
    
    self.TxtNext.text = XUiHelper.GetText("MissionComplete")
    self.TxtName.text = XMVCA.XFuben:GetStageName(self.StageId)
    self.BtnExit:SetName(XUiHelper.GetText("Continue"))
    self.TxtScore:SetSprite(CS.XGame.ClientConfig:GetString("UiBossInshotSettlementFestivalActivityTitle"))

    -- 得分列表固定显示文本内容
    self:ClearDynamicTimer()
    self:ClearGridsTimer()
    self.PanelPop.gameObject:SetActiveEx(true)
    self.ScoreInfos = {{Desc = XUiHelper.GetText("StageClear")}}
    self.DynamicTable:SetDataSource(self.ScoreInfos)
    self.DynamicTable:ReloadDataSync()

    self:RefreshMarkEffectActive()
end

function XUiBossInshotSettlement:Refresh()
    if self._Control:IsFestivalActivityStage(self.StageId) then
        self:RefreshByFestivalActivity()
        return
    end
    
    -- 回放按钮
    local isShowPlayback = self._Control:GetIsShowPlayback(self.StageId)
    self.BtnReplay.gameObject:SetActiveEx(isShowPlayback)
    
    -- 总分
    local isNewRecord = self.SettleData.BossInshotSettleResult.IsNewRecord
    local inshotStageId = self._Control:GetInshotStageIdByStageId(self.StageId)
    self.BossId = self._Control:GetStageBossId(inshotStageId)
    self.Difficulty = self._Control:GetStageDifficulty(inshotStageId)
    self.Score = self.SettleData.BossInshotSettleResult.Score
    self.ScoreLevelIcon = self._Control:GetScoreLevelBigIcon(self.Difficulty, self.Score)
    local nextLevelTips = self._Control:GetNextScoreLevelTips(self.Difficulty, self.Score)
    self.RImgScore:SetRawImage(self.ScoreLevelIcon)
    self.PanelNew.gameObject:SetActiveEx(isNewRecord)
    self.TxtNext.text = nextLevelTips
    -- 关卡名
    self.TxtName.text = XMVCA.XFuben:GetStageName(self.StageId)

    -- 得分列表
    self:ClearDynamicTimer()
    --self.DynamicTimer = XScheduleManager.ScheduleOnce(function()
        self:ClearGridsTimer()
        self.PanelPop.gameObject:SetActiveEx(true)
        self.ScoreInfos = self:GetScoreInfos()
        self.DynamicTable:SetDataSource(self.ScoreInfos)
        self.DynamicTable:ReloadDataSync()
    --end, 6800)
    
    self:RefreshMarkEffectActive()
end

-- 获取得分列表
function XUiBossInshotSettlement:GetScoreInfos()
    local result = XMVCA.XFuben:GetCurFightResult()
    if not result or not result.IsWin or not result.IntToIntRecord then
        return {}
    end

    local scoreInfos = {}
    local scoreCfgs = self._Control:GetConfigBossInshotScore()
    local e = result.IntToIntRecord:GetEnumerator()
    while e:MoveNext() do
        local scoreCfg = scoreCfgs[e.Current.Key]
        if scoreCfg then
            local isShow = e.Current.Value ~= 0 and (scoreCfg.Type == XEnumConst.BOSSINSHOT.SCORE_TYPE.Add or scoreCfg.Type == XEnumConst.BOSSINSHOT.SCORE_TYPE.MULTIPLY)
            if isShow then
                local scoreInfo = { Id = e.Current.Key, Value = e.Current.Value, Score = scoreCfg.Score, Type = scoreCfg.Type, Desc = scoreCfg.Desc, Order = scoreCfg.Order }
                table.insert(scoreInfos, scoreInfo)
            end
        end
    end
    e:Dispose()

    -- 按照Order排序
    table.sort(scoreInfos, function(a, b)
        return a.Order < b.Order
    end)

    return scoreInfos
end

function XUiBossInshotSettlement:InitDynamicTable()
    local XUiGridBossInshotScore = require("XUi/XUiBossInshot/XUiGridBossInshotScore")
    self.DynamicTable = XDynamicTableNormal.New(self.ScoreList)
    self.DynamicTable:SetProxy(XUiGridBossInshotScore, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiBossInshotSettlement:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local info = self.ScoreInfos[index]
        grid:Refresh(info)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local grids = self.DynamicTable:GetGrids()
        for _, g in pairs(grids) do
            g.GameObject:SetActive(false)
        end
        self:ClearGridsTimer()
        self.GridIndex = 1
        self.GridsTimer = XScheduleManager.Schedule(function()
            local item = grids[self.GridIndex]
            if item then
                item.GameObject:SetActive(true)
            end
            self.GridIndex = self.GridIndex + 1
        end, 100, #grids)
    end
end

function XUiBossInshotSettlement:ClearDynamicTimer()
    if self.DynamicTimer then
        XScheduleManager.UnSchedule(self.DynamicTimer)
        self.DynamicTimer = nil
    end
end

function XUiBossInshotSettlement:ClearGridsTimer()
    if self.GridsTimer then
        XScheduleManager.UnSchedule(self.GridsTimer)
        self.GridsTimer = nil
    end
end

-- 播放滚动效果
function XUiBossInshotSettlement:PlayScoreAnimation()
    if self.IsPopClose then
        return
    end

    self.IsPopClose = true
    local time = 2
    if self._Control:IsFestivalActivityStage(self.StageId) then
        -- 播放通关时间滚动效果
        local result = XMVCA.XFuben:GetCurFightResult()
        local costTime = (result.SettleFrame - result.PauseFrame - result.StartFrame) / CS.XFightConfig.FPS
        self:Tween(time, function(f)
            self.TxtScoreNum:TextToSprite(XUiHelper.GetTime(costTime * f, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME))
        end, function()
            self.TxtScoreNum:TextToSprite(XUiHelper.GetTime(costTime, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME))
        end)
        return
    end
    
    -- 播放分数滚动效果
    self:Tween(time, function(f)
        self.TxtScoreNum:TextToSprite(tostring(XMath.ToMinInt(self.Score * f)))
    end, function()
        self.TxtScoreNum:TextToSprite(tostring(self.Score))
    end)
end

return XUiBossInshotSettlement