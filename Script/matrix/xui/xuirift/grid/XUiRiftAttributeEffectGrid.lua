local XUiRiftAttributeEffectGrid = XClass(nil, "UiRiftAttributeEffectGrid")

local Color = {
    black = CS.UnityEngine.Color.black,
    red = XUiHelper.Hexcolor2Color("d11227"),
    blue = XUiHelper.Hexcolor2Color("0f70bc"),
}

function XUiRiftAttributeEffectGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiRiftAttributeEffectGrid:Refresh(index, effectData)
    local isShowBlack = index % 2 == 1
    self.ImgBlack.gameObject:SetActiveEx(isShowBlack)

    local effectTypeCfg = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftTeamAttributeEffectType, effectData.EffectType)
    self.TxtEffect.text = effectTypeCfg.Name
    if effectTypeCfg.ShowType == XRiftConfig.AttributeFixEffectType.Percent then
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
