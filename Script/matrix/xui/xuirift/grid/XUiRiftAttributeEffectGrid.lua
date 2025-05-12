---@class XUiRiftAttributeEffectGrid : XUiNode
---@field Parent XUiRiftAttribute
---@field _Control XRiftControl
local XUiRiftAttributeEffectGrid = XClass(XUiNode, "UiRiftAttributeEffectGrid")

local Color = {
    black = XUiHelper.Hexcolor2Color("E5635E"),
    red = XUiHelper.Hexcolor2Color("d11227"),
    blue = XUiHelper.Hexcolor2Color("00FFD6"),
}

function XUiRiftAttributeEffectGrid:Refresh(index, effectData)
    local isPercent
    if effectData.PropType == XEnumConst.Rift.PropType.Battle then
        local battleEffectTypeCfg = self._Control:GetTeamAttributeEffectConfigById(effectData.EffectType)
        isPercent = battleEffectTypeCfg.ShowType == XEnumConst.Rift.AttributeFixEffectType.Percent
        self.TxtEffect.text = battleEffectTypeCfg.Name
    elseif effectData.PropType == XEnumConst.Rift.PropType.System then
        local systemEffectTypeCfg = self._Control:GetSystemAttributeEffectConfigById(effectData.EffectType)
        isPercent = systemEffectTypeCfg.ShowType == XEnumConst.Rift.AttributeFixEffectType.Percent
        self.TxtEffect.text = systemEffectTypeCfg.Desc
    end

    if isPercent then
        self.TxtZuo.text = effectData.OriginValue .. "%"
        self.TxtYou.text = effectData.CurValue .. "%"
    else
        self.TxtZuo.text = effectData.OriginValue
        self.TxtYou.text = effectData.CurValue
    end

    local showLeft = effectData.OriginValue ~= effectData.CurValue
    self.TxtZuo.gameObject:SetActiveEx(showLeft)
    self.ImgJianTou.gameObject:SetActiveEx(showLeft)

    if effectData.OriginValue < effectData.CurValue then
        self.TxtYou.color = Color.blue
    elseif effectData.OriginValue > effectData.CurValue then
        self.TxtYou.color = Color.red
    else
        self.TxtYou.color = Color.black
    end
end

return XUiRiftAttributeEffectGrid
