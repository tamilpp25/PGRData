---@class XUiSCBattlePanelEnergy
local XUiPanelEnergy = XClass(nil, "XUiPanelEnergy")
local EnoughEnergyTextColor = XUiHelper.GetClientConfig("SCEnoughEnergyTextColor", XUiHelper.ClientConfigType.String)
local NoEnoughEnergyTextColor = XUiHelper.GetClientConfig("SCNoEnoughEnergyTextColor", XUiHelper.ClientConfigType.String)

function XUiPanelEnergy:Ctor(ui, base, role)
    ---@type XUiSameColorGameBattle
    self.Base = base
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    ---@type XSCRole
    self.Role = role
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self.PanelEnergyChange.gameObject:SetActiveEx(false)
    self.PanelEnergyChange:GetObject("EnergyCountText").text = "0"
    self:Init()
    self:AddBtnListener()
end

function XUiPanelEnergy:OnEnable()
    self:AddEventListener()
end

function XUiPanelEnergy:OnDisable()
    self:RemoveEventListener()
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
        if energyInfo.Type == XEnumConst.SAME_COLOR_GAME.ENERGY_CHANGE_TYPE.ADD then
            if energyInfo.Count > 0 then
                str = XUiHelper.GetText("SameColorGameEnergyPlus",energyInfo.Count)
            else
                str = XUiHelper.GetText("SameColorGameEnergyMinus",energyInfo.Count)
            end
        elseif energyInfo.Type == XEnumConst.SAME_COLOR_GAME.ENERGY_CHANGE_TYPE.PERCENT then
            if energyInfo.Count > 0 then
                str = XUiHelper.GetText("SameColorGameEnergyMultiply",math.abs(math.floor(energyInfo.Count / 1000)))
            else
                str = XUiHelper.GetText("SameColorGameEnergyDivide",math.abs(math.floor(energyInfo.Count / 1000)))
            end
        end
        XUiManager.TipMsg(XUiHelper.GetText("SameColorGameAutoEnergy", str))
    end
end

function XUiPanelEnergy:SetEnergyCountText(curEnerguy, energyCost)
    local countColor = curEnerguy >= energyCost and EnoughEnergyTextColor or NoEnoughEnergyTextColor
    self.EnergyText.text = XUiHelper.GetText("SameColorGameEnergyCount", countColor, curEnerguy, energyCost)
end

function XUiPanelEnergy:ShowEnergyEffect(IsPlus)
    for index,effect in pairs(self.EffectEnergy or {}) do
        effect.gameObject:SetActiveEx(index == IsPlus)
    end
end

--region Btn - Listener
function XUiPanelEnergy:AddBtnListener()
    self.BtnEnergyHelp.CallBack = function()
        self:OnBtnEnergyHelpClick()
    end
end

function XUiPanelEnergy:OnBtnEnergyHelpClick()
    local mainSkill = self.BattleManager:GetBattleRoleSkill(self.Role:GetMainSkillGroupId())
    XLuaUiManager.Open("UiSameColorGameSkillDetails", mainSkill, nil, true)
end
--endregion

--region Event
function XUiPanelEnergy:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ENERGY_CHANGE, self.UpdateEnergy, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_BATTLE_AUTO_ENERGY, self.CheckAutoEnergy, self)
end

function XUiPanelEnergy:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ENERGY_CHANGE, self.UpdateEnergy, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_BATTLE_AUTO_ENERGY, self.CheckAutoEnergy, self)
end
--endregion

return XUiPanelEnergy