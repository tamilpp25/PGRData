-- 结算界面（胜利）
---@class XUiMonsterCombatFight : XLuaUi
local XUiMonsterCombatFight = XLuaUiManager.Register(XLuaUi, "UiMonsterCombatFight")

function XUiMonsterCombatFight:OnAwake()
    self:RegisterUiEvents()
    self.GridFormationMonsterList = {}
    self.GridUnlockMonsterList = {}
end

function XUiMonsterCombatFight:OnStart(data)
    self.WinData = data
    self.StageId = data.StageId
    self:SetDefaultText()
end

function XUiMonsterCombatFight:OnEnable()
    self:Refresh()
end

function XUiMonsterCombatFight:OnDisable()
    self:StopAudio()
end

function XUiMonsterCombatFight:Refresh()
    if not self.WinData then
        return
    end
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local stageEntity = XDataCenter.MonsterCombatManager.GetStageEntity(self.StageId)
    -- 挑战模式
    self.IsChallengeModel = stageEntity:CheckIsChallengeModel()
    -- 关卡名称
    self.TxtTile.text = stageCfg.Name
    -- 奖励
    self:RefreshReward()
    self:RefreshViewModel()
    self:RefreshStageStatus()

    local result = self.WinData.SettleData.MonsterCombatResult
    if not self.IsChallengeModel then
        -- 播放音效
        self.AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiSettle_Win_Number)
    end
    local time = XUiHelper.GetClientConfig("BossSingleAnimaTime", XUiHelper.ClientConfigType.Float)
    XUiHelper.Tween(time, function(f)
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        -- 通关时间
        self.TxtHitScore.text = XUiHelper.GetTime(XMath.ToInt(f * result.FightTime))
        if not self.IsChallengeModel then
            -- 分数
            self.TxtPoint.text = XUiHelper.GetText("UiMonsterCombatMaxAllScore", XMath.ToInt(f * result.Score))
        end
    end, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self:StopAudio()
        if not self.IsChallengeModel then
            self.PanelNewRecord.gameObject:SetActiveEx(result.IsNewRecord)
        end
    end)
end

function XUiMonsterCombatFight:SetDefaultText()
    self.TxtHitScore.text = XUiHelper.GetTime(0)
    self.TxtHighScore.text = 0
    self.TxtPoint.text = 0
    self.PanelNewRecord.gameObject:SetActiveEx(false)
    self.PanelScore.gameObject:SetActiveEx(false)
    self.PanelRole.gameObject:SetActiveEx(false)
end

function XUiMonsterCombatFight:RefreshViewModel()
    local viewModel = XDataCenter.MonsterCombatManager.GetViewModel()
    if not viewModel then
        self.PanelMoster.gameObject:SetActiveEx(false)
        self.PanelRole.gameObject:SetActiveEx(false)
        self.TxtHighScore.gameObject:SetActiveEx(false)
        return
    end
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    local chapterId = stageInfo.ChapterId
    -- 支援单位
    local monsterIds = viewModel:GetFormationMonsters(chapterId)
    self:RefreshFormationMonster(monsterIds)
    if self.IsChallengeModel then
        -- 角色立绘
        local entityId = viewModel:GetFormationEntityId(chapterId)
        self:RefreshRole(entityId)
    else
        -- 历史最高分
        local maxScore = viewModel:GetStageMaxScore(self.StageId)
        self.TxtHighScore.text = XUiHelper.GetText("UiMonsterCombatMaxAllHistoryScore", maxScore)
    end
end

function XUiMonsterCombatFight:RefreshFormationMonster(monsterIds)
    monsterIds = self:RemoveEmptyData(monsterIds)
    self.PanelMoster.gameObject:SetActiveEx(not XTool.IsTableEmpty(monsterIds))
    local count = #monsterIds
    for i = 1, count do
        local grid = self.GridFormationMonsterList[i]
        if not grid then
            local go = i == 1 and self.GridMonster or XUiHelper.Instantiate(self.GridMonster, self.PanelMosterList)
            grid = XTool.InitUiObjectByUi({}, go)
            self.GridFormationMonsterList[i] = grid
        end
        local monsterEntity = XDataCenter.MonsterCombatManager.GetMonsterEntity(monsterIds[i])
        grid.RImgIcon:SetRawImage(monsterEntity:GetAchieveIcon())
        grid.GameObject:SetActiveEx(true)
    end
    for i = count + 1, #self.GridFormationMonsterList do
        self.GridFormationMonsterList[i].GameObject:SetActiveEx(false)
    end
end

function XUiMonsterCombatFight:RefreshRole(entityId)
    if self.PanelRole then
        self.PanelRole:SetRawImage(XMVCA.XCharacter:GetCharHalfBodyBigImage(entityId))
    end
end

function XUiMonsterCombatFight:RefreshReward()
    local beginData = XDataCenter.FubenManager.GetFightBeginData()
    if beginData.LastPassed then
        -- 非首通不显示奖励
        self.PanelGift.gameObject:SetActiveEx(false)
        return
    end
    local stageEntity = XDataCenter.MonsterCombatManager.GetStageEntity(self.StageId)
    local unlockMonsterIds = stageEntity:GetUnlockMonsterIds()
    self.PanelGift.gameObject:SetActiveEx(not XTool.IsTableEmpty(unlockMonsterIds))
    local count = #unlockMonsterIds
    for i = 1, count do
        local grid = self.GridUnlockMonsterList[i]
        if not grid then
            local go = i == 1 and self.GridGift or XUiHelper.Instantiate(self.GridGift, self.PanelGiftList)
            grid = XTool.InitUiObjectByUi({}, go)
            self.GridUnlockMonsterList[i] = grid
        end
        local monsterEntity = XDataCenter.MonsterCombatManager.GetMonsterEntity(unlockMonsterIds[i])
        grid.RImgIcon:SetRawImage(monsterEntity:GetAchieveIcon())
        grid.GameObject:SetActiveEx(true)
    end
    for i = count + 1, #self.GridUnlockMonsterList do
        self.GridUnlockMonsterList[i].GameObject:SetActiveEx(false)
    end
end

function XUiMonsterCombatFight:RefreshStageStatus()
    self.PanelRole.gameObject:SetActiveEx(self.IsChallengeModel)
    self.PanelScore.gameObject:SetActiveEx(not self.IsChallengeModel)
end

function XUiMonsterCombatFight:RemoveEmptyData(monsterIds)
    local tempMonsterIds = {}
    for _, monsterId in pairs(monsterIds) do
        if XTool.IsNumberValid(monsterId) then
            table.insert(tempMonsterIds, monsterId)
        end
    end
    return tempMonsterIds
end

function XUiMonsterCombatFight:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
end

function XUiMonsterCombatFight:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnExitFight, self.OnBtnExitFightClick)
end

function XUiMonsterCombatFight:OnBtnExitFightClick()
    self:Close()
end

return XUiMonsterCombatFight