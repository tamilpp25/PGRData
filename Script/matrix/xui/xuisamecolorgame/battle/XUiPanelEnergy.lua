local XUiPanelEnergy = XClass(nil, "XUiPanelEnergy")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiPanelEnergy:Ctor(ui, base, role)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Role = role
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self.PanelEnergyChange.gameObject:SetActiveEx(false)
    self.PanelEnergyChange:GetObject("EnergyCountText"):TextToSprite("0",0)
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
    self.EnergyText.text = CSTextManagerGetText("SameColorGameEnergyCount", self.Role:GetEnergyInit(), self.Role:GetEnergyLimit())
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
        self.EnergyText.text = CSTextManagerGetText("SameColorGameEnergyCount", self.BattleManager:GetCurEnergy(), self.Role:GetEnergyLimit())

        self.PanelEnergyChange.gameObject:SetActiveEx(true)
        --self.Base:PlayAnimation("ComboCountTextEnable")-----------TODO张爽，动画非正式

        local energyChangeStr = ""
        if data.EnergyChange > 0 then
            energyChangeStr = string.format("+%d", math.abs(data.EnergyChange))
        else
            energyChangeStr = string.format("-%d", math.abs(data.EnergyChange))
        end

        local changeFrom = ""
        if data.EnergyChangeFrom == XSameColorGameConfigs.EnergyChangeFrom.Self then
            changeFrom = 0
        elseif data.EnergyChangeFrom == XSameColorGameConfigs.EnergyChangeFrom.Boss then
            changeFrom = 1
        end

        self.PanelEnergyChange:GetObject("EnergyCountText"):TextToSprite(energyChangeStr,changeFrom)
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

function XUiPanelEnergy:ShowEnergyEffect(IsPlus)
    for index,effect in pairs(self.EffectEnergy or {}) do
        effect.gameObject:SetActiveEx(index == IsPlus)
    end
end

function XUiPanelEnergy:OnBtnEnergyHelpClick()
    XUiManager.UiFubenDialogTip(CSTextManagerGetText("SameColorGameEnergyDescTitle"), CSTextManagerGetText("SameColorGameEnergyDescText"))
end

return XUiPanelEnergy