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
function XUiSameColorGameBattle:OnStart(role, boss)
    self.Role = role
    self.Boss = boss
    self:SetButtonCallBack()
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self.BattleManager:Init()

    CS.XShadowHelper.SetDisableUIGlobalShadowMeshHeight(true)
    self:InitSceneRoot()
    self:InitPanel()

    self:ShowBossAtkMask(false)
    
    local endTime = XDataCenter.SameColorActivityManager.GetEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
            if isClose then
                XDataCenter.SameColorActivityManager.HandleActivityEndTime()
            end
        end)

end

function XUiSameColorGameBattle:OnDestroy()
    CS.XShadowHelper.SetDisableUIGlobalShadowMeshHeight(false)
end

function XUiSameColorGameBattle:OnEnable()
    XUiSameColorGameBattle.Super.OnEnable(self)
    self:AddEventListener()
    self.BattleManager:CheckActionList()
    self:CheckBattleStepOver()
end

function XUiSameColorGameBattle:OnDisable()
    XUiSameColorGameBattle.Super.OnDisable(self)
    self:RemoveEventListener()
    self.BoardPanel:StopBallTween()

    if not self.BattleManager:CheckAnimeAndActionIsAllFinish() then
        XLuaUiManager.SetMask(false)
    end

    self:UpdateBossMaxScore()
end

function XUiSameColorGameBattle:UpdateBossMaxScore()
    self.Boss:UpdateMaxScore(self.BattleManager:GetDamageCount())
end

function XUiSameColorGameBattle:InitPanel()
    self.BoardPanel = XUiPanelBoard.New(self.PanelBoard, self, self.Role)
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
end

function XUiSameColorGameBattle:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self:BindHelpBtn(self.BtnHelp, XDataCenter.SameColorActivityManager.GetHelpId())
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

    XLuaUiManager.SetMask(true)
    local weaponIds = XSameColorGameConfigs.GetBattleShowRoleConfig(self.Role:GetBattleModelId()).WeaponId or {}
    self.CharacterModelPanel:UpdateSCBattleShowModel(self.Role:GetBattleModelId(), weaponIds, XModelManager.MODEL_UINAME.XUiSameColorGameBattle, nil, function(model)
            self.CharacterRoleProxy = CS.SameColorGame.XUiBattleShowManager.Get3DRoleProxy(model.gameObject, self.Role:GetBattleModelId(), self.CameraFar.gameObject, self.CameraNear.gameObject)
            self.CharacterRoleProxy:PlayBornAnime(function ()
                    XLuaUiManager.SetMask(false)
                    self.BattleManager:DoAutoEnergyHint()
                end)
        end, false, true, true)

    weaponIds = XSameColorGameConfigs.GetBattleShowRoleConfig(self.Boss:GetBattleModelId()).WeaponId or {}
    self.BossModelPanel:UpdateSCBattleShowModel(self.Boss:GetBattleModelId(), weaponIds, XModelManager.MODEL_UINAME.XUiSameColorGameBattle, nil, function(model)
            self.BossRoleProxy = CS.SameColorGame.XUiBattleShowManager.Get3DRoleProxy(model.gameObject, self.Boss:GetBattleModelId(), nil, nil)
            self.BossRoleProxy:PlayBornAnime()
        end, false, true, true)
end

function XUiSameColorGameBattle:CheckBattleStepOver()
    local step = self.BattleManager:GetBattleStep(self.Boss)
    if step <= 0 then
        local replayCb = function()
            XDataCenter.SameColorActivityManager.RequestEnterStage(self.Role:GetId(), self.Boss:GetId(), self.Role:GetUsingSkillGroupIds(true), function (actionsList)
                    XLuaUiManager.PopThenOpen("UiSameColorGameBattle", self.Role, self.Boss)
                end)
        end
        local backCb = function()
            self:Close()
        end
        XLuaUiManager.Open("UiSameColorGameSettlement", self.Boss, replayCb, backCb)
    end
end

function XUiSameColorGameBattle:DoGiveUp(backCb)
    local replayCb = function()
        XDataCenter.SameColorActivityManager.RequestEnterStage(self.Role:GetId(), self.Boss:GetId(), self.Role:GetUsingSkillGroupIds(true), function (actionsList)
                XLuaUiManager.PopThenOpen("UiSameColorGameBattle", self.Role, self.Boss)
            end)
    end
    XLuaUiManager.Open("UiSameColorGameGiveUp", self.Boss, replayCb, backCb)
end

function XUiSameColorGameBattle:PlayBattleShowComboAnime(count)
    if count > 0 then
        self.BattleManager:SetIsAnimeFinish(false)
        self.CharacterRoleProxy:PlayComboAnime(count,
            function ()
                self:PlayBattleShowSpecialAttackAnime(function ()
                        self.BattleManager:SetIsAnimeFinish(true)
                        self.BattleManager:CheckCloseMask()
                        self.BattleManager:ShowBossSkill()
                        self.BattleManager:ShowBossBuff()
                        self.BattleManager:DoAutoEnergyHint()
                        self.BattleManager:ShowEnergyChange(XSameColorGameConfigs.EnergyChangeFrom.Round, 1)--环境回能
                        self:CheckBattleStepOver()
                    end)
            end,
            function ()
                self:PlayBattleShowHitAnime(function ()end)
            end,
            function ()
                self.BattleManager:ShowSettleScore()
            end)
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
self:CheckBattleStepOver()
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
        self.BossRoleProxy:PlaySpecialAttackAnime(bossSkillIndex, function ()
                self:ShowBossAtkMask(false)
                self.BattleManager:ShowEnergyChange(XSameColorGameConfigs.EnergyChangeFrom.Boss, 1)--boss伤害耗能
                if cb then cb() end
            end)
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