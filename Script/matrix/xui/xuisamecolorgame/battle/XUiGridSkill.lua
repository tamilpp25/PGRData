local XUiGridSkill = XClass(nil, "XUiGridSkill")
local CSTextManagerGetText = CS.XTextManager.GetText

local CONDITION_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("FFFFFFFF"),
    [false] = XUiHelper.Hexcolor2Color("FF0000FF"),
}

function XUiGridSkill:Ctor(ui,base, IsMainSkill)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.IsMainSkill = IsMainSkill
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    XTool.InitUiObject(self)
    self:InitEffect()
    self:SetButtonCallBack()
end

function XUiGridSkill:InitEffect()
    self.EffectSwitch.gameObject:SetActiveEx(false)
    self.EffectCanUse.gameObject:SetActiveEx(false)
    self.EffectChange.gameObject:SetActiveEx(false)
    -- v1.31 三期终结技基础特效
    self:ShowStandByEffect(false)
    self:ShowCantImg(false)
end

function XUiGridSkill:SetButtonCallBack()
    self.BtnClick.CallBack = function()
        self:OnBtnClick()
    end
    self.BtnSwitch.CallBack = function()
        self:OnBtnSwitch()
    end
end

function XUiGridSkill:OnBtnClick()
    if self.Skill and self.BtnClick.ButtonState ~= CS.UiButtonState.Disable then
        if self.BattleManager:GetCurEnergy() >= self.Skill:GetEnergyCost() then
            self.Base:SelectSkill(self.Skill)
        else
            XUiManager.TipMsg(CSTextManagerGetText("SameColorGameEnergyNotEnough"))
        end
    end
end

function XUiGridSkill:OnBtnSwitch()
    if not self.Skill:GetIsOn() then
        self:ShowChangeEffect()
    end
    self.Skill:ChangeSwitch()
    self:UpdateGrid(self.Skill)
    self.AnimeQieHuan:PlayTimelineAnimation()
end


function XUiGridSkill:UpdateGrid(skill)
    self.Skill = skill
    if skill then
        
        self.EngText.text = string.gsub(CSTextManagerGetText("SameColorGameSkillEnergy", skill:GetEnergyCost()), "\\n", "\n")
        self.EngText.color = CONDITION_COLOR[self.BattleManager:GetCurEnergy() >= skill:GetEnergyCost()]
        
        self.BtnClick:SetRawImage(skill:GetIcon())
        self.NormalBottomOff.gameObject:SetActiveEx(not skill:GetIsOn())
        self.NormalBottomOn.gameObject:SetActiveEx(skill:GetIsOn())
        self.PressBottomOff.gameObject:SetActiveEx(not skill:GetIsOn())
        self.PressBottomOn.gameObject:SetActiveEx(skill:GetIsOn())
        self.PanelEng.gameObject:SetActiveEx(skill:GetIsOn())
        
        self:ShowEnergyEffect()
    end
    --self.BtnSwitch.gameObject:SetActiveEx(skill and skill:GetIsHasOnSkill())  --v1.31 三期不显示切换按钮
    self.BtnClick.gameObject:SetActiveEx(skill)
    self.PanelPropNot.gameObject:SetActiveEx(not skill)
end

function XUiGridSkill:ShowEnergyEffect(forceHide)
    -- 二期切换特效
    -- local IsOnCanUse = not forceHide and self.Skill:GetIsHasOnSkill() and self.BattleManager:GetCurEnergy() >= self.Skill:GetEnergyCost(self.Skill:GetOnSkillId())
    -- self:ShowSwitchEffect(not self.Skill:GetIsOn() and IsOnCanUse and self.Skill:GetCountDown() == 0)
    -- self:ShowCanUseEffect(self.Skill:GetIsOn() and IsOnCanUse and self.Skill:GetCountDown() == 0)
    -- v1.31 三期终结技需要满能量特效
    if self.IsMainSkill then
        local IsOnCanUse = self.BattleManager:GetCurEnergy() >= self.Skill:GetEnergyCost(self.Skill:GetSkillId()) and self.Skill:GetCountDown() == 0
        self:ShowCanUseEffect(not forceHide and IsOnCanUse)
        self:ShowSwitchEffect(not forceHide and IsOnCanUse)
        self:ShowStandByEffect(not forceHide and IsOnCanUse)
        self:ShowCantImg(not IsOnCanUse)
    end
end

function XUiGridSkill:SetDisable(IsDisable, excludeSkill)
    --self.BtnSwitch.gameObject:SetActiveEx(not IsDisable and self.Skill and self.Skill:GetIsHasOnSkill())  --v1.31 三期不显示切换按钮
    
    if not self.Skill then
        self.PanelPropNot:GetObject("Normal").gameObject:SetActiveEx(not IsDisable)
        self.PanelPropNot:GetObject("Disable").gameObject:SetActiveEx(IsDisable)
        return
    end
    
    if excludeSkill and self.Skill == excludeSkill then
        return
    end
    
    self:ShowEnergyEffect(IsDisable)
    if self.Skill:GetCountDown() == 0 then
        self.BtnClick:SetDisable(IsDisable)
        self.CountdownText.gameObject:SetActiveEx(false)
        self.CountdownMaskText.gameObject:SetActiveEx(false)
    else
        self.CountdownText.gameObject:SetActiveEx(not IsDisable)
        self.CountdownMaskText.gameObject:SetActiveEx(IsDisable)
    end
    
end

function XUiGridSkill:SetCountdown(skillGroupId, leftCd)
    if not self.Skill then
        return
    end
    if self.Skill:GetSkillGroupId() == skillGroupId then
        self.Skill:SetCountDown(leftCd)

        local IsShowCount = leftCd > 0
        local preSkill = self.BattleManager:GetPrepSkill()
        local isUseOtherSkill = preSkill ~= nil and preSkill ~= self.Skill
        self.BtnClick:SetDisable(IsShowCount or isUseOtherSkill)
        self.CountdownMaskText.gameObject:SetActiveEx(isUseOtherSkill and IsShowCount)
        self.CountdownText.gameObject:SetActiveEx(not isUseOtherSkill and IsShowCount)
        if IsShowCount then
            self.CountdownText.text = IsShowCount and self.Skill:GetCountDown() or ""
            self.CountdownMaskText.text = IsShowCount and self.Skill:GetCountDown() or ""
        end
        
        self:ShowEnergyEffect()
    end
end

function XUiGridSkill:ShowSwitchEffect(IsShow)
    self.EffectSwitch.gameObject:SetActiveEx(IsShow)
end

function XUiGridSkill:ShowCanUseEffect(IsShow)
    self.EffectCanUse.gameObject:SetActiveEx(IsShow)
end

function XUiGridSkill:ShowStandByEffect(IsShow)
    if XTool.UObjIsNil(self.EffectStandby) then return end
    self.EffectStandby.gameObject:SetActiveEx(IsShow)
end

function XUiGridSkill:ShowCantImg(IsShow)
    if XTool.UObjIsNil(self.ImgCantUse) then return end
    self.ImgCantUse.gameObject:SetActiveEx(IsShow)
end

function XUiGridSkill:ShowChangeEffect()
    self.EffectChange.gameObject:SetActiveEx(false)
    self.EffectChange.gameObject:SetActiveEx(true)
end

return XUiGridSkill