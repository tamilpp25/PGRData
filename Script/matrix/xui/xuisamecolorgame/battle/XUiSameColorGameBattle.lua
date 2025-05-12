---@class XUiSameColorGameBattle:XLuaUi
---@field _Control XSameColorControl
local XUiSameColorGameBattle = XLuaUiManager.Register(XLuaUi, "UiSameColorGameBattle")
local XUiPanelBoard = require("XUi/XUiSameColorGame/Battle/XUiPanelBoard")
local XUiPanelSkill = require("XUi/XUiSameColorGame/Battle/XUiPanelSkill")
local XUiPanelCondition = require("XUi/XUiSameColorGame/Battle/XUiPanelCondition")
local XUiPanelBuff = require("XUi/XUiSameColorGame/Battle/XUiPanelBuff")
local XUiPanelBossSkill = require("XUi/XUiSameColorGame/Battle/XUiPanelBossSkill")
local XUiPanelEnergy = require("XUi/XUiSameColorGame/Battle/XUiPanelEnergy")
local XUiPanelBlackScreen = require("XUi/XUiSameColorGame/Battle/XUiPanelBlackScreen")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local CSXAudioManager = CS.XAudioManager
local AudioControlOpen = 1
local AudioControlClose = 2

---@param role XSCRole
---@param boss XSCBoss
function XUiSameColorGameBattle:OnStart(role, boss)
    self._Role = role
    self._Boss = boss
    self._BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self._BattleManager:Init()
    self._IsShowMask = false

    self:InitPanel()
    self:InitAutoClose()
    self:InitAudioVolume()
    self:InitScene()
    self:AddBtnListener()
end

function XUiSameColorGameBattle:OnEnable()
    XUiSameColorGameBattle.Super.OnEnable(self)
    self:OnEnablePanel()
    self:CheckBattleOver()
    self:RefreshBtnPause()
    self:AddEventListener()
end

function XUiSameColorGameBattle:OnDisable()
    XUiSameColorGameBattle.Super.OnDisable(self)

    self:RevertVolume()
    self:UpdateBossData()
    self:OnDisableMask()
    self:OnDisablePanel()
    self:OnDisableScene()
    self:RemoveEventListener()
end

function XUiSameColorGameBattle:OnDestroy()
    self:OnDestroyScene()
    XDataCenter.SameColorActivityManager.StopRecordRunningTime()
end

--region Data - Boss
function XUiSameColorGameBattle:UpdateBossData()
    self._Boss:UpdateMaxScore(self._BattleManager:GetDamageCount())
    self._Boss:UpdateMaxCombo(self._BattleManager:GetMaxComboCount())
end
--endregion

--region Ui - AutoClose
function XUiSameColorGameBattle:InitAutoClose()
    --local endTime = XDataCenter.SameColorActivityManager.GetEndTime()
    --self:SetAutoCloseInfo(endTime, function(isClose)
    --    if isClose then
    --        XDataCenter.SameColorActivityManager.HandleActivityEndTime()
    --    end
    --end)
end
--endregion

--region Ui - Panel
function XUiSameColorGameBattle:InitPanel()
    ---@type XUiSCBattlePanelBoard
    self.BoardPanel = XUiPanelBoard.New(self.PanelBoard, self, self._Role, self._Boss)
    ---@type XUiSCBattlePanelCondition
    self.ConditionPanel = XUiPanelCondition.New(self.PanelCondition, self, self._Boss)
    ---@type XUiSCBattlePanelBuff
    self.BuffPanel = XUiPanelBuff.New(self.PanelBuff, self)
    ---@type XUiSCBattlePanelBossSkill
    self.BossSkillPanel = XUiPanelBossSkill.New(self.PanelBossSkill, self, self._Boss)
    ---@type XUiSCBattlePanelEnergy
    self.EnergyPanel = XUiPanelEnergy.New(self.PanelEnergy, self, self._Role)
    ---@type XUiSCBattlePanelBlackScreen
    self.BlackScreenPanel = XUiPanelBlackScreen.New(self.PanelBlackScreen, self, self._Role)
    ---@type XUiSCBattlePanelRoleSkill
    self.SkillPanel = XUiPanelSkill.New(self.PanelSkill, self, self._Role)
end

function XUiSameColorGameBattle:OnEnablePanel()
    self.BoardPanel:OnEnable()
    self.BlackScreenPanel:OnEnable()
    self.SkillPanel:OnEnable()
    self.ConditionPanel:OnEnable()
    self.EnergyPanel:OnEnable()
    self.BuffPanel:OnEnable()
    self.BossSkillPanel:OnEnable()

    self._BattleManager:CheckActionList()
end

function XUiSameColorGameBattle:OnDisablePanel()
    self.BoardPanel:OnDisable()
    self.BlackScreenPanel:OnDisable()
    self.SkillPanel:OnDisable()
    self.ConditionPanel:OnDisable()
    self.EnergyPanel:OnDisable()
    self.BuffPanel:OnDisable()
    self.BossSkillPanel:OnDisable()
end
--endregion

--region Ui - Audio
-- 初始化音量设置
function XUiSameColorGameBattle:InitAudioVolume()
    self.MusicVolume = CSXAudioManager.MusicVolume
    self.SoundVolume = CSXAudioManager.SoundVolume
    self.Control = CS.XAudioManager.Control

    local musicKey = self:GetMusicVolumeSaveKey()
    local isMusicClose = XSaveTool.GetData(musicKey) == true or self.Control == AudioControlClose
    self:CloseMusicVolume(isMusicClose, true)

    local soundKey = self:GetSoundVolumeSaveKey()
    local isSoundClose = XSaveTool.GetData(soundKey) == true or self.Control == AudioControlClose
    self:CloseSoundVolume(isSoundClose, true)
end

function XUiSameColorGameBattle.GetMusicVolumeSaveKey()
    return string.format("XUiSameColorGameBattle_GetMusicVolumeSaveKey_XPlayer.Id:%s", XPlayer.Id)
end

function XUiSameColorGameBattle.GetSoundVolumeSaveKey()
    return string.format("XUiSameColorGameBattle_GetSoundVolumeSaveKey_XPlayer.Id:%s", XPlayer.Id)
end

-- 打开/关闭背景音乐
function XUiSameColorGameBattle:CloseMusicVolume(isClose, isNotSave)
    self.IsMusicClose = isClose
    -- local volume = isClose and 0 or self.MusicVolume
    -- CSXAudioManager.MusicVolume = volume
    XLuaAudioManager.MuteAisacByPlayType(XLuaAudioManager.SoundType.Music, isClose)
    if isClose then
        XLuaAudioManager.StopCurrentBGM()
    else
        local musicId = self._Control:GetCfgBossBattleBgmCueId()
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, musicId and musicId or XEnumConst.SAME_COLOR_GAME.SOUND.BATTLE_BG)
    end

    if isNotSave then return end
    local musicKey = self:GetMusicVolumeSaveKey()
    XSaveTool.SaveData(musicKey, isClose)
end

-- 打开/关闭对局音效
function XUiSameColorGameBattle:CloseSoundVolume(isClose, isNotSave)
    self.IsSoundClose = isClose
    -- local volume = isClose and 0 or self.SoundVolume
    -- CSXAudioManager.SoundVolume = volume
    XLuaAudioManager.MuteAisacByPlayType(XLuaAudioManager.SoundType.SFX, isClose)

    if isNotSave then return end
    local soundKey = self:GetSoundVolumeSaveKey()
    XSaveTool.SaveData(soundKey, isClose)
end

-- 恢复音量设置
function XUiSameColorGameBattle:RevertVolume()
    -- local musicVolume = self.Control == AudioControlOpen and self.MusicVolume or 0
    -- local soundVolume = self.Control == AudioControlOpen and self.SoundVolume or 0
    XLuaAudioManager.MuteAisacByPlayType(XLuaAudioManager.SoundType.Music, false)
    -- CSXAudioManager.MusicVolume = self.MusicVolume
    XLuaAudioManager.MuteAisacByPlayType(XLuaAudioManager.SoundType.SFX, false)
    -- CSXAudioManager.SoundVolume = self.SoundVolume
end

function XUiSameColorGameBattle:PlayGameSound(soundName)
    self.SoundParent:GetObject(soundName).gameObject:SetActiveEx(false)
    self.SoundParent:GetObject(soundName).gameObject:SetActiveEx(true)
end
--endregion

--region Ui - Mask
function XUiSameColorGameBattle:ShowBossAtkMask(IsShow)
    self.BoardMask.gameObject:SetActiveEx(IsShow)
    self.SkillMask.gameObject:SetActiveEx(IsShow)
end

-- 设置遮罩
function XUiSameColorGameBattle:SetMask(isShowMask)
    if self._IsShowMask == isShowMask then
        return
    end

    XLuaUiManager.SetMask(isShowMask)
    self._IsShowMask = isShowMask
end

function XUiSameColorGameBattle:OnDisableMask()
    if not self._BattleManager:CheckAnimeAndActionIsAllFinish() then
        self:SetMask(false)
    end
end
--endregion

--region Ui - Anim
function XUiSameColorGameBattle:PlayBattleShowComboAnime(count)
    local skill = self._BattleManager:GetPrepSkill()
    -- 5期策划需求露娜的技能连击仅播放一次动作，先这样硬凹处理
    local isSkipAnim = skill and skill:GetSkillGroupId() == 507 and skill:GetUsedCount() > 1
    if count > 0 and not isSkipAnim then
        self._BattleManager:SetIsAnimeFinish(false)
        local preSkill = self._BattleManager:GetPrepSkill()
        local comboType = preSkill and preSkill:GetSkillComboType() or XEnumConst.SAME_COLOR_GAME.SKILL_COMBO_TYPE.DEFAULT

        local callBack = function()
            self._BattleManager:SetIsAnimeFinish(true)
            self._BattleManager:CheckCloseMask()
        end

        -- 触发即释放一次技能的combo，允许连续多次点击触发多个技能连续释放，直接执行技能结束回调
        if comboType == XEnumConst.SAME_COLOR_GAME.SKILL_COMBO_TYPE.ONCE then
            callBack()
            callBack = nil
        end

        self.CharacterRoleProxy:PlayComboAnime(count, comboType, callBack, nil, nil)
    end
end

function XUiSameColorGameBattle:PlayBattleShowHitAnime(cb)
    self.CharacterRoleProxy:DoCameraShake()
    self.BossRoleProxy:PlayHitAnime(function ()
        if cb then cb() end
    end)
end

function XUiSameColorGameBattle:PlayBattleShowSpecialAttackAnime(cb)
    local bossSkill = self._BattleManager:GetBossSkill()
    local bossSkillIndex = self._BattleManager:GetBossSkillIndex()
    if bossSkill and bossSkill > 0 then
        self:ShowBossAtkMask(true)
        self._BattleManager:ClearBossSkill()
        self.BossRoleProxy:PlaySpecialAttackEffect(bossSkillIndex)
        self.BossRoleProxy:PlaySpecialAttackAnime(bossSkillIndex)
        self:ShowBossAtkMask(false)
        if cb then cb() end
    else
        if cb then cb() end
    end
end
--endregion

--region Ui - BtnRefresh
-- 刷新暂停按钮
function XUiSameColorGameBattle:RefreshBtnPause()
    local isPause = XDataCenter.SameColorActivityManager.GetIsPause()
    self.BtnPause.gameObject:SetActiveEx(not isPause)
    self.BtnContinue.gameObject:SetActiveEx(isPause)
end
--endregion

--region Ui - BtnListener
function XUiSameColorGameBattle:AddBtnListener()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self:BindHelpBtn(self.BtnHelp, self._Control:GetCfgHelpId())
    XUiHelper.RegisterClickEvent(self, self.BtnPause, self.OnClickBtnPause)
    XUiHelper.RegisterClickEvent(self, self.BtnContinue, self.OnClickBtnContinue)
    self:RegisterClickEvent(self.BtnExplain, self.OnClickBtnExplain)
end

function XUiSameColorGameBattle:OnClickBtnExplain()
    XLuaUiManager.Open("UiSameColorGameIconDetails", self._Role)
end

function XUiSameColorGameBattle:OnBtnBackClick()
    self:DoGiveUp(function ()
        self:Close()
    end)
end

function XUiSameColorGameBattle:OnBtnMainUiClick()
    self:DoGiveUp(function ()
        XLuaUiManager.RunMain()
    end)
end

function XUiSameColorGameBattle:OnClickBtnPause()
    local preSkill = self._BattleManager:GetPrepSkill()
    if preSkill then
        return
    end

    local sendProto = self._Boss:IsTimeType()
    XDataCenter.SameColorActivityManager.RequestPauseResume(true, sendProto, function()
        self:RefreshBtnPause()
    end)

    local closeMusicFunc = function(isClose) self:CloseMusicVolume(isClose) end
    local closeSoundFunc = function(isClose) self:CloseSoundVolume(isClose) end
    local backFunc = function()
        XDataCenter.SameColorActivityManager.RequestGiveUp(self._Boss:GetId())
        self:Close()
    end
    local rePlayFunc = function() self:RePlayGame() end
    local continueFunc = function() self:OnClickBtnContinue() end
    XLuaUiManager.Open("UiSameColorGameSetUp", self.IsMusicClose, self.IsSoundClose, closeMusicFunc, closeSoundFunc,
            backFunc, rePlayFunc, continueFunc)
end

function XUiSameColorGameBattle:OnClickBtnContinue()
    local sendProto = self._Boss:IsTimeType()
    XDataCenter.SameColorActivityManager.RequestPauseResume(false, sendProto, function()
        self:RefreshBtnPause()
    end)
end
--endregion

--region Scene
function XUiSameColorGameBattle:InitScene()
    local root = self.UiModelGo.transform
    ---@type UnityEngine.Transform
    self.CameraFar = root:FindTransform("FarCameraCombat")
    ---@type UnityEngine.Transform
    self.CameraNear = root:FindTransform("NearCameraCombat")
    self:InitSceneRoleModel()
    self:InitSceneBossModel()
    self:InitSceneShadow()
    self:ClearSceneEffect()
end

function XUiSameColorGameBattle:OnDisableScene()
    self:ClearSceneEffect()
end

function XUiSameColorGameBattle:OnDestroyScene()
    self:_ResumeSceneShadow()
    self:ClearSceneEffect()
end
--endregion

--region Scene - Model
function XUiSameColorGameBattle:InitSceneRoleModel()
    local panelCharacterModel = self.UiModelGo.transform:FindTransform("PanelCharacterModel")
    if not panelCharacterModel then
        return
    end
    ---@type XUiPanelRoleModel
    self.CharacterModelPanel = XUiPanelRoleModel.New(panelCharacterModel, self.Name, nil, true, nil, true)

    -- 开场动画开启遮罩表示不能动棋盘
    --self:SetMask(true)
    local weaponIds = self._Control:GetCfgBattleShowRoleWeaponIdList(self._Role:GetBattleModelId())
    self.CharacterModelPanel:UpdateSCBattleShowModel(self._Role:GetBattleModelId(), weaponIds, XModelManager.MODEL_UINAME.XUiSameColorGameBattle, nil, 
        function(model)
            ---@type SameColorGame.XUiBattleShowRole
            self.CharacterRoleProxy = CS.SameColorGame.XUiBattleShowManager.Get3DRoleProxy(model.gameObject, self._Role:GetBattleModelId(), self.CameraFar.gameObject, self.CameraNear.gameObject)
            self.CharacterRoleProxy:PlayBornAnime(function ()
                self:SetMask(false)
                self._BattleManager:DoAutoEnergyHint()
            end)
        end, false, true, true)

    -- 隐藏模型部分节点
    self._Control:HandleModelHideNode(self.CharacterModelPanel:GetModelInfoByName(self._Role:GetBattleModelId()), self._Role:GetBattleModelId())
end

function XUiSameColorGameBattle:InitSceneBossModel()
    local panelBossModel = self.UiModelGo.transform:FindTransform("PanelBossModel")
    if not panelBossModel then
        return
    end
    
    ---@type XUiPanelRoleModel
    self.BossModelPanel = XUiPanelRoleModel.New(panelBossModel, self.Name, nil, true, nil, true)
    local weaponIds = self._Control:GetCfgBattleShowRoleWeaponIdList(self._Boss:GetBattleModelId())
    self.BossModelPanel:UpdateSCBattleShowModel(self._Boss:GetBattleModelId(), weaponIds, XModelManager.MODEL_UINAME.XUiSameColorGameBattle, nil, 
        function(model)
            ---@type SameColorGame.XUiBattleShowRole
            self.BossRoleProxy = CS.SameColorGame.XUiBattleShowManager.Get3DRoleProxy(model.gameObject, self._Boss:GetBattleModelId(), nil, nil)
            self.BossRoleProxy:PlayBornAnime()
        end, false, true, true)
    
    -- 隐藏模型部分节点
    self._Control:HandleModelHideNode(self.BossModelPanel:GetModelInfoByName(self._Boss:GetBattleModelId()), self._Boss:GetBattleModelId())
end
--endregion

--region Scene - FightEffect
---v1.31 清除特效池，避免因加载模型时销毁原有模型及战斗动作特效导致特效池残留战斗动作池特效的材质丢失
function XUiSameColorGameBattle:ClearSceneEffect()
    if CS.XEffectFullPlayManager.Instance then
        CS.XEffectFullPlayManager.Instance:ClearEffects()
    end
end
--endregion

--region Scene - Shadow
function XUiSameColorGameBattle:InitSceneShadow()
    CS.XShadowHelper.SetDisableUIGlobalShadowMeshHeight(true)
end

function XUiSameColorGameBattle:_ResumeSceneShadow()
    CS.XShadowHelper.SetDisableUIGlobalShadowMeshHeight(false)
end
--endregion

--region Game - Control
function XUiSameColorGameBattle:CheckBattleOver()
    local isOver = false
    if self._Boss:IsRoundType() then
        local step = self._BattleManager:GetBattleStep(self._Boss)
        isOver = isOver or step <= 0
    end
    if self._Boss:IsTimeType() then
        local leftTime = self._BattleManager:GetLeftTime()
        isOver = isOver or leftTime <= 0
    end

    if isOver and not XLuaUiManager.IsUiShow("UiSameColorGameSettlement") then
        local replayCb = function()
            XDataCenter.SameColorActivityManager.RequestEnterStage(self._Role:GetId(), self._Boss:GetId(), self._Role:GetUsingSkillGroupIds(true), function (actionsList)
                XLuaUiManager.PopThenOpen("UiSameColorGameBattle", self._Role, self._Boss)
            end)
        end
        local backCb = function()
            self:Close()
        end

        if self._BattleManager:GetPrepSkill() then
            XEventManager.DispatchEvent(XEventId.EVENT_SC_SKILL_USED)
        end
        XLuaUiManager.Close("UiSameColorGameGiveUp")
        XLuaUiManager.Close("UiSameColorGameSkillDetails")
        XLuaUiManager.Close("UiSameColorGameEffectDetails")
        XLuaUiManager.Close("UiSameColorGameDialog")
        XLuaUiManager.Close("UiSameColorGameRankDetails")
        XLuaUiManager.Close("UiSameColorGameChangeColor")
        XLuaUiManager.Open("UiSameColorGameSettlement", self._Boss, replayCb, backCb)
    end
end

-- 时间变化回调
function XUiSameColorGameBattle:OnLeftTimeChange()
    -- 限时模式 & 时间<=0 & 不在表演过程中，则打开结算界面
    if self._Boss:IsTimeType() then
        local leftTime = self._BattleManager:GetLeftTime()
        if leftTime <= 0 then
            local isPlaying = self._BattleManager:CheckActionPlaying()
            if not isPlaying then
                self:CheckBattleOver()
            end
        end
    end
end

-- action列表执行完毕回调
function XUiSameColorGameBattle:OnActionListOver()
    -- 播放boss技能
    self:PlayBattleShowSpecialAttackAnime()
    self._BattleManager:ShowBossSkill()
    self._BattleManager:ShowBossBuff()
    self._BattleManager:DoAutoEnergyHint()
    self._BattleManager:ShowEnergyChange(XEnumConst.SAME_COLOR_GAME.ENERGY_CHANGE_FROM.ROUND, 1)--环境回能
    self._BattleManager:ShowEnergyChange(XEnumConst.SAME_COLOR_GAME.ENERGY_CHANGE_FROM.BOSS, 1)--boss伤害耗能

    self:CheckBattleOver()
end

function XUiSameColorGameBattle:DoGiveUp(backCb)
    local replayCb = function()
        self:RePlayGame()
    end
    XLuaUiManager.Open("UiSameColorGameGiveUp", self._Boss, replayCb, backCb)
end

function XUiSameColorGameBattle:RePlayGame()
    XDataCenter.SameColorActivityManager.RequestEnterStage(self._Role:GetId(), self._Boss:GetId(), self._Role:GetUsingSkillGroupIds(true), function (actionsList)
        XLuaUiManager.PopThenOpen("UiSameColorGameBattle", self._Role, self._Boss)
    end)
end

function XUiSameColorGameBattle:UiClose()
    self._BattleManager:OnGameInterrupt()
    self:Close()
end
--endregion

function XUiSameColorGameBattle:GetRoundChangeEffect()
    return self._Control:GetClientCfgStringValue("RoundChangeEffect")
end

--region Event
function XUiSameColorGameBattle:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SC_BATTLE_SHOW_COMBO, self.PlayBattleShowComboAnime, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_INTERRUPT, self.UiClose, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_LEFT_TIME_CHANGE, self.OnLeftTimeChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_BATTLE_SHOW_MASK, self.SetMask, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_LIST_OVER, self.OnActionListOver, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_GAME_SOUND_PLAY, self.PlayGameSound, self)
end

function XUiSameColorGameBattle:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_BATTLE_SHOW_COMBO, self.PlayBattleShowComboAnime, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_INTERRUPT, self.UiClose, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_LEFT_TIME_CHANGE, self.OnLeftTimeChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_BATTLE_SHOW_MASK, self.SetMask, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_LIST_OVER, self.OnActionListOver, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_GAME_SOUND_PLAY, self.PlayGameSound, self)
end
--endregion