---@class XUiArenaFightResult : XLuaUi
---@field _Control XArenaControl
local XUiArenaFightResult = XLuaUiManager.Register(XLuaUi, "UiArenaFightResult")

function XUiArenaFightResult:OnAwake()
    self:_RegisterClickEvents()
end

function XUiArenaFightResult:OnStart(resultData)
    self._ResultData = resultData
end

function XUiArenaFightResult:OnEnable()
    self:_Refresh()
end

function XUiArenaFightResult:_RegisterClickEvents()
    self:RegisterClickEvent(self.BtnReFight, self.OnBtnReFightClick)
    self:RegisterClickEvent(self.BtnExitFight, self.OnBtnExitFightClick)
end

function XUiArenaFightResult:OnBtnReFightClick()
    if self._Control:CheckRunMainWhenFightOver() then
        return
    end

    self:_StopAudio()

    -- 检查是否在结算期间
    if self._Control:GetActivityStatus() == XEnumConst.Arena.ActivityStatus.Over then
        XUiManager.TipText("ArenaActivityStatusWrong")
        XLuaUiManager.SafeClose("UiArenaChapterDetail")
        self:Close()
        return
    end

    local areaId = self._Control:GetCurrentEnterAreaId()
    local stageId = self._Control:GetAreaStageLastStageIdById(areaId)

    self._Control:SetCurrentEnterAreaId(areaId)
    self._Control:OpenBattleRoleRoom(stageId, true)
end

function XUiArenaFightResult:OnBtnExitFightClick()
    if self._Control:CheckRunMainWhenFightOver() then
        return
    end

    self:_StopAudio()

    -- 检查是否在结算期间
    if self._Control:GetActivityStatus() == XEnumConst.Arena.ActivityStatus.Over then
        XLuaUiManager.SafeClose("UiArenaChapterDetail")
    end

    self:Close()
end

function XUiArenaFightResult:_StopAudio()
    if self._AudioInfo then
        self._AudioInfo:Stop()
    end
end

function XUiArenaFightResult:_SetMaxDesc(text, point)
    if point > 0 then
        text.text = XUiHelper.GetText("ArenaMaxSingleScore", point)
    else
        text.text = XUiHelper.GetText("ArenaMaxSingleNoScore")
    end
end

function XUiArenaFightResult:_Refresh()
    if not self._ResultData then
        return
    end

    local data = self._ResultData
    local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    local areaId = self._Control:GetCurrentEnterAreaId()
    local markId = self._Control:GetMarkIdByAreaId(areaId)
    local markMaxPoint = self._Control:GetMarkMaxPointByMarkId(markId)
    local isShowEnemyHp = self._Control:IsMarkShowEnemyHp(markId)
    local isShowMyHp = self._Control:IsMarkShowMyHp(markId)
    local isShowLeftTime = self._Control:IsMarkShowLeftTime(markId)
    local isShowGourp = self._Control:IsMarkShowGourp(markId)
    
    self.TxtTile.text = self._Control:GetCurrentEnterAreaStageName()
    self.BtnReFight.gameObject:SetActiveEx(true)
    self.PanelNewRecord.gameObject:SetActiveEx(data.Point > data.OldPoint)
    self.PanelBossLoseHp.gameObject:SetActiveEx(isShowEnemyHp)
    self.PanelSurplusHp.gameObject:SetActiveEx(isShowMyHp)
    self.PanelLeftTime.gameObject:SetActiveEx(isShowLeftTime)
    self.PanelGroupCount.gameObject:SetActiveEx(isShowGourp)

    self:_SetMaxDesc(self.TxtHitSocreMax, self._Control:GetMarkMaxEnemyHpPointByMarkId(markId))
    self:_SetMaxDesc(self.TxtRemainHpScoreMax, self._Control:GetMarkMaxMyHpPointByMarkId(markId))
    self:_SetMaxDesc(self.TxtRemainTimeScoreMax, self._Control:GetMarkMaxTimePointByMarkId(markId))
    self:_SetMaxDesc(self.TxtGroupCountScoreMax, self._Control:GetMarkMaxNpcGroupPointByMarkId(markId))

    if self._Control:IsHasMark(markId) and data.Point > data.OldPoint then
        self._Control:SetAreaDataStagePoint(areaId, data.Point)
    end
    -- 刷新副本入口数据
    self._Control:SetIsRefreshMainPage(true)
    -- 播放音效
    self._AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiSettle_Win_Number)

    XUiHelper.Tween(time, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        -- 歼敌奖励
        if isShowEnemyHp then
            local hitCombo = math.floor(f * data.EnemyHurt)
            local hitScore = "+" .. math.floor(f * data.EnemyPoint)
            self.TxtHitCombo.text = hitCombo
            self.TxtHitScore.text = hitScore
        end

        -- 我方血量
        if isShowMyHp then
            local remainHp = math.floor(f * data.MyHpLeft) .. "%"
            local remainHpScore = "+" .. math.floor(f * data.MyHpPoint)
            self.TxtRemainHp.text = remainHp
            self.TxtRemainHpScore.text = remainHpScore
        end

        -- 剩余时间
        if isShowLeftTime then
            local remainTime = XUiHelper.GetTime(math.floor(f * data.TimeLeft), XUiHelper.TimeFormatType.SHOP)
            local remainTimeSacore = "+" .. math.floor(f * data.TimePoint)
            self.TxtRemainTime.text = remainTime
            self.TxtRemainTimeScore.text = remainTimeSacore
        end

        -- 波次奖励
        if isShowGourp then
            local groupCount = XUiHelper.GetText("ArenaGrouplScore", math.floor(f * data.NpcGroup))
            local groupCountSacore = "+" .. math.floor(f * data.NpcGroupPoint)
            self.TxtGroupCount.text = groupCount
            self.TxtGroupCountScore.text = groupCountSacore
        end

        -- 通关时间
        local costTime = XUiHelper.GetTime(math.floor(f * data.FightTime), XUiHelper.TimeFormatType.SHOP)
        self.TxtCostTime.text = costTime

        -- 当前总分
        local point = math.floor(f * data.Point)
        if data.Point >= markMaxPoint and markMaxPoint > 0 then
            self.TxtPoint.text = XUiHelper.GetText("ArenaMaxAllScore", point)
        else
            self.TxtPoint.text = point
        end

        -- 历史最高分
        local highScore = math.floor(f * data.OldPoint)
        if data.OldPoint >= markMaxPoint and markMaxPoint > 0 then
            self.TxtHighScore.text = highScore .. "/" .. markMaxPoint
        else
            self.TxtHighScore.text = highScore
        end
    end, function()
        self:_StopAudio()
    end)
end

return XUiArenaFightResult
