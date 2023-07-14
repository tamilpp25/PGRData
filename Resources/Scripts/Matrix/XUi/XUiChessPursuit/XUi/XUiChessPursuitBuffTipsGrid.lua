local XUiChessPursuitBuffTipsGrid = XClass(nil, "XUiChessPursuitBuffTipsGrid")
local CSXTextManagerFormatString = CS.XTextManager.FormatString

function XUiChessPursuitBuffTipsGrid:Ctor(ui, rootUi, card)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Card = card

    XTool.InitUiObject(self)
end

function XUiChessPursuitBuffTipsGrid:Refresh()
    local cardCfg = XChessPursuitConfig.GetChessPursuitCardTemplate(self.Card.CardCfgId)
    local cfgEffect = XChessPursuitConfig.GetChessPursuitCardEffectTemplate(cardCfg.EffectId)

    self.RootUi:SetUiSprite(self.RImgIconKuang, cardCfg.QualityIconTips)
    self.RImgIcon:SetRawImage(cardCfg.Icon)
    self.TxtName.text = cardCfg.Name
    self.TxtDesc.text = cardCfg.Describe

    local countDesc
    if cfgEffect.KeepType == 0 then
        countDesc = cfgEffect.KeepTypeDesc
    else
        countDesc = CSXTextManagerFormatString(cfgEffect.KeepTypeDesc, self.Card.KeepCount)
    end
    self.TxtKeepCount.text = countDesc
end

return XUiChessPursuitBuffTipsGrid