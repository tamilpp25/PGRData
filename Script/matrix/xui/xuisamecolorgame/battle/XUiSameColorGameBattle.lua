--===========================
--三消战斗
--===========================
local XUiSameColorGameBattle = XLuaUiManager.Register(XLuaUi, "UiSameColorGameBattle")
local XUiPanelBoard = require("XUi/XUiSameColorGame/Battle/XUiPanelBoard")
local XUiPanelSkill = require("XUi/XUiSameColorGame/Battle/XUiPanelSkill")
local XUiPanelCondition = require("XUi/XUiSameColorGame/Battle/XUiPanelCondition")
local XUiPanelBuff = require("XUi/XUiSameColorGame/Battle/XUiPanelBuff")
local XUiPanelBossSkill = require("XUi/XUiSameColorGame/Battle/XUiPanelBossSkill")
local XUiPanelEnergy = require("XUi/XUiSameColorGame/Battle/XUiPanelEnergy")
local XUiPanelBlackScreen = require("XUi/XUiSameColorGame/Battle/XUiPanelBlackScreen")
local tableUnpack = table.unpack
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local CSXAudioManager = CS.XAudioManager
local AudioControlOpen = 1
local AudioControlClose = 2

function XUiSameColorGameBattle:OnStart(role, boss)
    self.Role = role
    self.Boss = boss
    self:SetButtonCallBack()
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self.BattleManager:Init()
    self:InitVolume()
    self.IsShowMask = false

    XDataCenter.SameColorActivityManager.ClearFightAniEffect()

    CS.XShadowHelper.SetDisableUIGlobalShadowMeshHeight(true)
    self:InitSceneRoot()
    self:InitPanel()
    
    local endTime = XDataCenter.SameColorActivityManager.GetEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
            if isClose then
                XDataCenter.SameColorActivityManager.HandleActivityEndTime()
            end
        end)

end

function XUiSameColorGameBattle:OnDestroy()
    CS.XShadowHelper.SetDisableUIGlobalShadowMeshHeight(false)
    XDataCenter.SameColorActivityManager.ClearFightAniEffect()
end

function XUiSameColorGameBattle:OnEnable()
    XUiSameColorGameBattle.Super.OnEnable(self)
    self:AddEventListener()
    self.BattleManager:CheckActionList()
    self:CheckBattleOver()
    self:RefreshBtnPause()
end

function XUiSameColorGameBattle:OnDisable()
    XUiSameColorGameBattle.Super.OnDisable(self)
    self:RemoveEventListener()
    self.BoardPanel:OnDisable()

    self:RevertVolume()
    if not self.BattleManager:CheckAnimeAndActionIsAllFinish() then
        self:SetMask(false)
    end

    self:UpdateBossData()
    XDataCenter.SameColorActivityManager.ClearFightAniEffect()
end

function XUiSameColorGameBattle:UpdateBossData()
    self.Boss:UpdateMaxScore(self.BattleManager:GetDamageCount())
    self.Boss:UpdateMaxCombo(self.BattleManager:GetMaxComboCount())
end

function XUiSameColorGameBattle:InitPanel()
    self.BoardPanel = XUiPanelBoard.New(self.PanelBoard, self, self.Role, self.Boss)
    self.ConditionPanel = XUiPanelCondition.New(self.PanelCondition, self, self.Boss)
    self.BuffPanel = XUiPanelBuff.New(self.PanelBuff, self)
    self.BossSkillPanel = XUiPanelBossSkill.New(self.PanelBossSkill, self, self.Boss)
    self.EnergyPanel = XUiPanelEnergy.New(self.PanelEnergy, self, self.Role)
    self.BlackScreenPanel = XUiPanelBlackScreen.New(self.PanelBlackScreen, self, self.Role)
    self.SkillPanel = XUiPanelSkill.New(self.PanelSkill, self, self.Role)
end

function XUiSameColorGameBattle:AddEventListener()
    self.BoardPanel:AddEventListener()
    self.BlackScreenPanel:AddEventListener()
    self.SkillPanel:AddEventListener()
    self.ConditionPanel:AddEventListener()
    self.EnergyPanel:AddEventListener()
    self.BuffPanel:AddEventListener()
    self.BossSkillPanel:AddEventListener()

    XEventManager.AddEventListener(XEventId.EVENT_SC_BATTLESHOW_COMBOPLAY, self.PlayBattleShowComboAnime, self)
    --XEventManager.AddEventListener(XEventId.EVENT_SC_BATTLESHOW_SINGLECOMBOPLAY, self.PlayBattleShowSingleComboAnime, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_INTERRUPT, self.UiClose, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_LEFTTIME_CHANGE, self.OnLeftTimeChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_BATTLESHOW_MASK, self.SetMask, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ACTIONLIST_OVER, self.OnActionListOver, self)
end

function XUiSameColorGameBattle:RemoveEventListener()
    self.BoardPanel:RemoveEventListener()
    self.BlackScreenPanel:RemoveEventListener()
    self.SkillPanel:RemoveEventListener()
    self.ConditionPanel:RemoveEventListener()
    self.EnergyPanel:RemoveEventListener()
    self.BuffPanel:RemoveEventListener()
    self.BossSkillPanel:RemoveEventListener()

    XEventManager.RemoveEventListener(XEventId.EVENT_SC_BATTLESHOW_COMBOPLAY, self.PlayBattleShowComboAnime, self)
    --XEventManager.RemoveEventListener(XEventId.EVENT_SC_BATTLESHOW_SINGLECOMBOPLAY, self.PlayBattleShowSingleComboAnime, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_INTERRUPT, self.UiClose, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_LEFTTIME_CHANGE, self.OnLeftTimeChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_BATTLESHOW_MASK, self.SetMask, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ACTIONLIST_OVER, self.OnActionListOver, self)
end

function XUiSameColorGameBattle:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self:BindHelpBtn(self.BtnHelp, XDataCenter.SameColorActivityManager.GetHelpId())
    XUiHelper.RegisterClickEvent(self, self.BtnPause, self.OnClickBtnPause)
    XUiHelper.RegisterClickEvent(self, self.BtnContinue, self.OnClickBtnContinue)
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
    local preSkill = self.BattleManager:GetPrepSkill()
    if preSkill then 
        return
    end

    local sendProto = self.Boss:IsTimeType()
    XDataCenter.SameColorActivityManager.RequestPauseResume(true, sendProto, function()
        self:RefreshBtnPause()
    end)

    local closeMusicFunc = function(isClose) self:CloseMusicVolume(isClose) end
    local closeSoundFunc = function(isClose) self:CloseSoundVolume(isClose) end
    local backFunc = function()
        XDataCenter.SameColorActivityManager.RequestGiveUp(self.Boss:GetId())
        self:Close() 
    end
    local rePlayFunc = function() self:RePlayGame() end
    local continueFunc = function() self:OnClickBtnContinue() end
    XLuaUiManager.Open("UiSameColorGameSetUp", self.IsMusicClose, self.IsSoundClose, closeMusicFunc, closeSoundFunc,
    backFunc, rePlayFunc, continueFunc)
end

function XUiSameColorGameBattle:OnClickBtnContinue()
    local sendProto = self.Boss:IsTimeType()
    XDataCenter.SameColorActivityManager.RequestPauseResume(false, sendProto, function()
        self:RefreshBtnPause()
    end)
end

function XUiSameColorGameBattle:UiClose()
    self:Close()
end

function XUiSameColorGameBattle:InitSceneRoot()
    local root = self.UiModelGo.transform

    self.PanelCharacterModel = root:FindTransform("PanelCharacterModel")
    self.PanelBossModel = root:FindTransform("PanelBossModel")

    self.CameraFar = root:FindTransform("FarCameraCombat")
    self.CameraNear = root:FindTransform("NearCameraCombat")

    self.CharacterModelPanel = XUiPanelRoleModel.New(self.PanelCharacterModel, self.Name, nil, true, nil, true)
    self.BossModelPanel = XUiPanelRoleModel.New(self.PanelBossModel, self.Name, nil, true, nil, true)

    -- 开场动画开启遮罩表示不能动棋盘
    self:SetMask(true)
    --self:ShowBossAtkMask(true)
    local weaponIds = XSameColorGameConfigs.GetBattleShowRoleConfig(self.Role:GetBattleModelId()).WeaponId or {}
    self.CharacterModelPanel:UpdateSCBattleShowModel(self.Role:GetBattleModelId(), weaponIds, XModelManager.MODEL_UINAME.XUiSameColorGameBattle, nil, function(model)
            self.CharacterRoleProxy = CS.SameColorGame.XUiBattleShowManager.Get3DRoleProxy(model.gameObject, self.Role:GetBattleModelId(), self.CameraFar.gameObject, self.CameraNear.gameObject)
            self.CharacterRoleProxy:PlayBornAnime(function ()
                    self:SetMask(false)
                    --self:ShowBossAtkMask(false)
                    self.BattleManager:DoAutoEnergyHint()
                end)
        end, false, true, true)

    weaponIds = XSameColorGameConfigs.GetBattleShowRoleConfig(self.Boss:GetBattleModelId()).WeaponId or {}
    self.BossModelPanel:UpdateSCBattleShowModel(self.Boss:GetBattleModelId(), weaponIds, XModelManager.MODEL_UINAME.XUiSameColorGameBattle, nil, function(model)
            self.BossRoleProxy = CS.SameColorGame.XUiBattleShowManager.Get3DRoleProxy(model.gameObject, self.Boss:GetBattleModelId(), nil, nil)
            self.BossRoleProxy:PlayBornAnime()
        end, false, true, true)
    -- v1.31 隐藏模型部分节点
    XDataCenter.SameColorActivityManager.HandleModelHideNode(self.BossModelPanel:GetModelInfoByName(self.Boss:GetBattleModelId()), self.Boss:GetBattleModelId())
end

function XUiSameColorGameBattle:CheckBattleOver()
    local isOver = false
    if self.Boss:IsRoundType() then
        local step = self.BattleManager:GetBattleStep(self.Boss)
        isOver = isOver or step <= 0
    end
    if self.Boss:IsTimeType() then
        local leftTime = self.BattleManager:GetLeftTime()
        isOver = isOver or leftTime <= 0
    end

    if isOver and not XLuaUiManager.IsUiShow("UiSameColorGameSettlement") then
        local replayCb = function()
            XDataCenter.SameColorActivityManager.RequestEnterStage(self.Role:GetId(), self.Boss:GetId(), self.Role:GetUsingSkillGroupIds(true), function (actionsList)
                    XLuaUiManager.PopThenOpen("UiSameColorGameBattle", self.Role, self.Boss)
                end)
        end
        local backCb = function()
            self:Close()
        end

        if self.BattleManager:GetPrepSkill() then
            XEventManager.DispatchEvent(XEventId.EVENT_SC_SKILL_USED)
        end
        XLuaUiManager.Close("UiSameColorGameGiveUp")
        XLuaUiManager.Close("UiSameColorGameSkillDetails")
        XLuaUiManager.Close("UiSameColorGameEffectDetails")
        XLuaUiManager.Close("UiSameColorGameDialog")
        XLuaUiManager.Close("UiSameColorGameRankDetails")
        XLuaUiManager.Close("UiSameColorGameChangeColor")
        XLuaUiManager.Open("UiSameColorGameSettlement", self.Boss, replayCb, backCb)
    end
end

-- 时间变化回调
function XUiSameColorGameBattle:OnLeftTimeChange()
    -- 限时模式 & 时间<=0 & 不在表演过程中，则打开结算界面
    if self.Boss:IsTimeType() then
        local leftTime = self.BattleManager:GetLeftTime()
        if leftTime <= 0 then
            local isPlaying = self.BattleManager:CheckActionPlaying()
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
    self.BattleManager:ShowBossSkill()
    self.BattleManager:ShowBossBuff()
    self.BattleManager:DoAutoEnergyHint()
    self.BattleManager:ShowEnergyChange(XSameColorGameConfigs.EnergyChangeFrom.Round, 1)--环境回能
    self.BattleManager:ShowEnergyChange(XSameColorGameConfigs.EnergyChangeFrom.Boss, 1)--boss伤害耗能

    self:CheckBattleOver()
end

function XUiSameColorGameBattle:DoGiveUp(backCb)
    local replayCb = function()
        self:RePlayGame()
    end
    XLuaUiManager.Open("UiSameColorGameGiveUp", self.Boss, replayCb, backCb)
end

function XUiSameColorGameBattle:RePlayGame()
    XDataCenter.SameColorActivityManager.RequestEnterStage(self.Role:GetId(), self.Boss:GetId(), self.Role:GetUsingSkillGroupIds(true), function (actionsList)
        XLuaUiManager.PopThenOpen("UiSameColorGameBattle", self.Role, self.Boss)
    end)
end

function XUiSameColorGameBattle:PlayBattleShowComboAnime(count)
    if count > 0 then
        self.BattleManager:SetIsAnimeFinish(false)
        local preSkill = self.BattleManager:GetPrepSkill()
        local comboType = preSkill and preSkill:GetSkillComboType() or XSameColorGameConfigs.SkillComboType.Default

        local callBack = function()
            self.BattleManager:SetIsAnimeFinish(true)
            self.BattleManager:CheckCloseMask()
        end
        --[[
        local hitCallBack = function ()
            self:PlayBattleShowHitAnime(function()end)
        end
        ]]

        -- 触发即释放一次技能的combo，允许连续多次点击触发多个技能连续释放，直接执行技能结束回调
        if comboType == XSameColorGameConfigs.SkillComboType.Once then 
            callBack()
            callBack = nil
        end

        self.CharacterRoleProxy:PlayComboAnime(count, comboType, callBack, nil, nil)
    end
end

--[[function XUiSameColorGameBattle:PlayBattleShowSingleComboAnime()
local removeMaxCount = self.BattleManager:GetBallRemoveMaxCount()
local removeCurCount = self.BattleManager:GetBallRemoveCurCount()

local IsFirstCombo = removeCurCount == 1
local IsEndCombo = removeCurCount == removeMaxCount
local comboName = IsEndCombo and "RedAttack" or "NormalAttack"

if IsFirstCombo then
self.BattleManager:SetIsAnimeFinish(false)
end

self.CharacterRoleProxy:PlaySingleComboAnime(comboName, removeCurCount,function ()
self:PlayBattleShowSpecialAttackAnime(function ()
self.BattleManager:SetIsAnimeFinish(true)
self.BattleManager:CheckCloseMask()
self.BattleManager:ShowBossSkill()
self.BattleManager:ShowBossBuff()
self:CheckBattleOver()
end)
end,
function ()
self:PlayBattleShowHitAnime(function ()end)
end,
function ()
self.BattleManager:ShowSettleScore()
end, IsFirstCombo, IsEndCombo)
end]]

function XUiSameColorGameBattle:PlayBattleShowHitAnime(cb)
    self.CharacterRoleProxy:DoCameraShake()
    self.BossRoleProxy:PlayHitAnime(function ()
            if cb then cb() end
        end)
end

function XUiSameColorGameBattle:PlayBattleShowSpecialAttackAnime(cb)
    local bossSkill = self.BattleManager:GetBossSkill()
    local bossSkillIndex = self.BattleManager:GetBossSkillIndex()
    if bossSkill and bossSkill > 0 then
        self:ShowBossAtkMask(true)
        self.BattleManager:ClearBossSkill()
        self.BossRoleProxy:PlaySpecialAttackEffect(bossSkillIndex)
        self.BossRoleProxy:PlaySpecialAttackAnime(bossSkillIndex)
                self:ShowBossAtkMask(false)
                if cb then cb() end
    else
        if cb then cb() end
    end
end

function XUiSameColorGameBattle:PlayGameSound(soundName)
    self.SoundParent:GetObject(soundName).gameObject:SetActiveEx(false)
    self.SoundParent:GetObject(soundName).gameObject:SetActiveEx(true)
end

function XUiSameColorGameBattle:ShowBossAtkMask(IsShow)
    self.BoardMask.gameObject:SetActiveEx(IsShow)
    self.SkillMask.gameObject:SetActiveEx(IsShow)
end

-- 刷新暂停按钮
function XUiSameColorGameBattle:RefreshBtnPause()
    local isPause = XDataCenter.SameColorActivityManager.GetIsPause()
    self.BtnPause.gameObject:SetActiveEx(not isPause)
    self.BtnContinue.gameObject:SetActiveEx(isPause)
end

-- 初始化音量设置
function XUiSameColorGameBattle:InitVolume()
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
    local volume = isClose and 0 or self.MusicVolume
    CSXAudioManager.MusicVolume = volume
    CSXAudioManager.ChangeMusicVolume(volume)
    if isClose then 
        CSXAudioManager.StopMusic()
    else
        CSXAudioManager.PlayMusic(XSameColorGameConfigs.Sound.BattleBg)
    end

    if isNotSave then return end
    local musicKey = self:GetMusicVolumeSaveKey()
    XSaveTool.SaveData(musicKey, isClose)
end

-- 打开/关闭对局音效
function XUiSameColorGameBattle:CloseSoundVolume(isClose, isNotSave)
    self.IsSoundClose = isClose
    local volume = isClose and 0 or self.SoundVolume
    CSXAudioManager.SoundVolume = volume
    CSXAudioManager.ChangeSoundVolume(volume)

    if isNotSave then return end
    local soundKey = self:GetSoundVolumeSaveKey()
    XSaveTool.SaveData(soundKey, isClose)
end

-- 恢复音量设置
function XUiSameColorGameBattle:RevertVolume()
    local musicVolume = self.Control == AudioControlOpen and self.MusicVolume or 0
    local soundVolume = self.Control == AudioControlOpen and self.SoundVolume or 0
    CSXAudioManager.ChangeMusicVolume(musicVolume)
    CSXAudioManager.MusicVolume = self.MusicVolume
    CSXAudioManager.ChangeSoundVolume(soundVolume)
    CSXAudioManager.SoundVolume = self.SoundVolume
end

-- 设置遮罩
function XUiSameColorGameBattle:SetMask(isShowMask)
    if self.IsShowMask == isShowMask then
        return
    end

    XLuaUiManager.SetMask(isShowMask)
    self.IsShowMask = isShowMask
end