---@class XUiSCBattlePanelCondition
local XUiPanelCondition = XClass(nil, "XUiPanelCondition")

function XUiPanelCondition:Ctor(ui, base, boss)
    ---@type XUiSameColorGameBattle
    self.Base = base
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
    ---@type XSCBoss
    self.Boss = boss
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self.TxtDamage.gameObject:SetActiveEx(false)
    self.TxtDamage:GetObject("ComboCountText"):TextToSprite("0",0)
    self.OldDamageRank = 0
    self:Init()
    self:SetButtonCallBack()
end

function XUiPanelCondition:OnEnable()
    self:AddEventListener()
end

function XUiPanelCondition:OnDisable()
    self:RemoveEventListener()
end

function XUiPanelCondition:Init()
    self:InitEffect()
    self:SetStep()
    self:UpdateLeftTime()
    self:SetDamage()
end

function XUiPanelCondition:InitEffect()
    self.EffectDamage.gameObject:SetActiveEx(false)
    self.EffectStep.gameObject:SetActiveEx(false)

    self.EffectRank = {
        [1] = self.EffectRankE,
        [3] = self.EffectRankD,
        [5] = self.EffectRankC,
        [7] = self.EffectRankB,
        [9] = self.EffectRankA,
        [11] = self.EffectRankSSS,
    }
    
    self.EffectRankSSS.gameObject:SetActiveEx(false)
    self.EffectRankA.gameObject:SetActiveEx(false)
    self.EffectRankB.gameObject:SetActiveEx(false)
    self.EffectRankC.gameObject:SetActiveEx(false)
    self.EffectRankD.gameObject:SetActiveEx(false)

    self.EffectRound.gameObject:SetActiveEx(false)
    self.EffectRound:LoadUiEffect(self.Base:GetRoundChangeEffect(), false, false)
end

function XUiPanelCondition:SetButtonCallBack()
    self.BtnRankClick.CallBack = function()
        self:OnBtnRankClick()
    end
    self.BtnRankHelp.CallBack = function()
        self:OnBtnRankClick()
    end
end

function XUiPanelCondition:SetStep()
    local isRoundType = self.Boss:IsRoundType()
    self.StepText.gameObject:SetActiveEx(isRoundType)
    if isRoundType then
        local step = self.BattleManager:GetBattleStep(self.Boss)
        if XTool.IsNumberValid(self._CurStep) and self._CurStep ~= step then
            self.EffectRound.gameObject:SetActiveEx(false)
            self.EffectRound.gameObject:SetActiveEx(true)
        end
        self._CurStep = step
        self.StepText.text = tostring(self._CurStep)
    end
end

function XUiPanelCondition:SetDamage(data)
    local damage = data and data.TotalScore or 0
    self.DamageText.text = tostring(damage)
    self.ImgDamageRank:SetRawImage(self.Boss:GetCurGradeIcon(damage))
    self:ShowRankEffect(damage)
end

function XUiPanelCondition:UpdateStep(data)
    self:SetStep()
    self:ShowStepEffect()
    self.BattleManager:DoActionFinish(data.ActionType)
end

function XUiPanelCondition:UpdateLeftTime()
    local isTimeType = self.Boss:IsTimeType()
    self.StepLeftTime.gameObject:SetActiveEx(isTimeType)
    if isTimeType then
        local leftTime = self.BattleManager:GetLeftTime()
        self.StepLeftTime.text = leftTime
    end
end

function XUiPanelCondition:UpdateDamage()
    local scoreData = self.BattleManager:GetScoreData()
    if not next(scoreData) then
        return
    end
    self:SetDamage(scoreData)
    self:ShowDamageEffect()
    self.TxtDamage.gameObject:SetActiveEx(true)
    self.Base:PlayAnimation("ComboCountTextEnable")
    self.TxtDamage:GetObject("ComboCountText"):TextToSprite(string.format("+%d", scoreData.CurrentScore or 0),0)

    self.Addition.gameObject:SetActiveEx(false)
    self.AdditionColor1.gameObject:SetActiveEx(false)
    self.AdditionColor2.gameObject:SetActiveEx(false)
    self.AdditionColor3.gameObject:SetActiveEx(false)
    self.AdditionColor4.gameObject:SetActiveEx(false)

    -- 触发被动技能 伤害强化
    for _, damage in pairs(scoreData.PassiveSkillMoreDamages) do
        local buff = self.BattleManager:GetBuff(damage.BuffId, damage.BuffUid)
        local addTips = "*" .. tostring(buff:GetDamagePercent()) .. "%"
        local additionGo = self["AdditionColor"..damage.TargetColor]
        if additionGo then
            additionGo.gameObject:SetActiveEx(true)
            additionGo:GetObject("BallTex").text = addTips
        end
    end

    -- 触发被动技能 暴击
    if scoreData.PassiveSkillMoreScoreFactor > 0 then
        local addTips = "*" .. tostring(scoreData.PassiveSkillMoreScoreFactor*100) .. "%"
        self.Addition.gameObject:SetActiveEx(true)
        self.Addition:GetObject("BallTex").text = addTips
    end
end

function XUiPanelCondition:ShowDamageEffect()
    -- 显示黑幕的时候不显示特效
    local isShowEffect = self.Base.BlackScreenPanel:IsNoneMask()
    if not isShowEffect then
        return
    end

    self.EffectDamage.gameObject:SetActiveEx(false)
    self.EffectDamage.gameObject:SetActiveEx(true)
end

function XUiPanelCondition:ShowStepEffect()
    self.EffectStep.gameObject:SetActiveEx(false)
    self.EffectStep.gameObject:SetActiveEx(true)
end

function XUiPanelCondition:ShowRankEffect(damage)
    local damageRank = self.Boss:GetScoreGradeIndex(damage)
    if self.OldDamageRank ~= damageRank then
        local tagIndex = 1
        for index,effect in pairs(self.EffectRank or {}) do
            if index <= damageRank then
                tagIndex = index
            else
                break
            end
        end
        
        for index,effect in pairs(self.EffectRank or {}) do
            effect.gameObject:SetActiveEx(false)
            effect.gameObject:SetActiveEx(index == tagIndex)
        end
    end
    self.OldDamageRank = damageRank
end

--region Btn - Listener
function XUiPanelCondition:AddBtnListener()
    self.BtnRankClick.CallBack = function()
        self:OnBtnRankClick()
    end
    self.BtnRankHelp.CallBack = function()
        self:OnBtnRankClick()
    end
end

function XUiPanelCondition:OnBtnRankClick()
    XLuaUiManager.Open("UiSameColorGameRankDetails", self.Boss)
end
--endregion

--region Event
function XUiPanelCondition:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ROUND_CHANGE, self.SetStep, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_SETTLE_SCORE, self.UpdateDamage, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ADD_STEP, self.UpdateStep, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_SUB_STEP, self.UpdateStep, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_LEFT_TIME_CHANGE, self.UpdateLeftTime, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_MAP_INIT, self.UpdateLeftTime, self)
end

function XUiPanelCondition:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ROUND_CHANGE, self.SetStep, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_SETTLE_SCORE, self.UpdateDamage, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ADD_STEP, self.UpdateStep, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_SUB_STEP, self.UpdateStep, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_LEFT_TIME_CHANGE, self.UpdateLeftTime, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_MAP_INIT, self.UpdateLeftTime, self)
end
--endregion

return XUiPanelCondition