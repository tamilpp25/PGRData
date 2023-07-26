local XUiPanelEnergy = XClass(nil, "XUiPanelEnergy")
local CSTextManagerGetText = CS.XTextManager.GetText
local EnoughEnergyTextColor = XUiHelper.GetClientConfig("SCEnoughEnergyTextColor", XUiHelper.ClientConfigType.String)
local NoEnoughEnergyTextColor = XUiHelper.GetClientConfig("SCNoEnoughEnergyTextColor", XUiHelper.ClientConfigType.String)

function XUiPanelEnergy:Ctor(ui, base, role)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Role = role
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self.PanelEnergyChange.gameObject:SetActiveEx(false)
    self.PanelEnergyChange:GetObject("EnergyCountText").text = "0"
    self:Init()
end

function XUiPanelEnergy:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ENERGYCHANGE, self.UpdateEnergy, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_BATTLESHOW_HINTAUTOENERGY, self.CheckAutoEnergy, self)
end

function XUiPanelEnergy:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ENERGYCHANGE, self.UpdateEnergy, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_BATTLESHOW_HINTAUTOENERGY, self.CheckAutoEnergy, self)
end

function XUiPanelEnergy:SetButtonCallBack()
    self.BtnEnergyHelp.CallBack = function()
        self:OnBtnEnergyHelpClick()
    end
end

function XUiPanelEnergy:Init()
    self:SetEnergyCountText(self.Role:GetEnergyInit(), self.Role:GetSkillEnergyCost())
    self.BattleManager:SetCurEnergy(self.Role:GetEnergyInit())

    self.EffectEnergy = {
        [true] = self.EffectEnergyZeng,
        [false] = self.EffectEnergyJian,
    }
    self.EffectEnergyZeng.gameObject:SetActiveEx(false)
    self.EffectEnergyJian.gameObject:SetActiveEx(false)
end

function XUiPanelEnergy:UpdateEnergy(data)
    if data then
        self:SetEnergyCountText(self.BattleManager:GetCurEnergy(), self.Role:GetSkillEnergyCost())

        self.PanelEnergyChange.gameObject:SetActiveEx(true)
        --self.Base:PlayAnimation("ComboCountTextEnable")-----------TODO张爽，动画非正式

        local energyChangeStr = ""
        if data.EnergyChange > 0 then
            energyChangeStr = string.format("+%d", math.abs(data.EnergyChange))
        else
            energyChangeStr = string.format("<color=#FF4837>-%d</color>", math.abs(data.EnergyChange))
        end

        self.PanelEnergyChange:GetObject("EnergyCountText").text = energyChangeStr
        self:ShowEnergyEffect(data.EnergyChange > 0)
        
        self.PanelEnergyChange.gameObject:SetActiveEx(true)
        self.Base:PlayAnimation("PanelEnergyChangeEnable")
    end
end

function XUiPanelEnergy:CheckAutoEnergy(round)
    local energyInfo = self.Role:GetAutoEnergyByRound(round)
    local str = ""
    if energyInfo then
        if energyInfo.Type == XSameColorGameConfigs.EnergyChangeType.Add then
            if energyInfo.Count > 0 then
                str = CSTextManagerGetText("SameColorGameEnergyPlus",energyInfo.Count)
            else
                str = CSTextManagerGetText("SameColorGameEnergyMinus",energyInfo.Count)
            end
        elseif energyInfo.Type == XSameColorGameConfigs.EnergyChangeType.Percent then
            if energyInfo.Count > 0 then
                str = CSTextManagerGetText("SameColorGameEnergyMultiply",math.abs(math.floor(energyInfo.Count / 1000)))
            else
                str = CSTextManagerGetText("SameColorGameEnergyDivide",math.abs(math.floor(energyInfo.Count / 1000)))
            end
        end
        XUiManager.TipMsg(CSTextManagerGetText("SameColorGameAutoEnergy", str))
    end
end

function XUiPanelEnergy:SetEnergyCountText(curEnerguy, energyCost)
    local countColor = curEnerguy >= energyCost and EnoughEnergyTextColor or NoEnoughEnergyTextColor
    self.EnergyText.text = CSTextManagerGetText("SameColorGameEnergyCount", countColor, curEnerguy, energyCost)
end

function XUiPanelEnergy:ShowEnergyEffect(IsPlus)
    for index,effect in pairs(self.EffectEnergy or {}) do
        effect.gameObject:SetActiveEx(index == IsPlus)
    end
end

function XUiPanelEnergy:OnBtnEnergyHelpClick()
    local mainSkill = self.BattleManager:GetBattleRoleSkill(self.Role:GetMainSkillGroupId())
    XLuaUiManager.Open("UiSameColorGameSkillDetails", mainSkill, nil, true)
end

return XUiPanelEnergy