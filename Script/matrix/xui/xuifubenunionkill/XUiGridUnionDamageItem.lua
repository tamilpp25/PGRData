local XUiGridUnionDamageItem = XClass(nil, "XUiGridUnionDamageItem")

function XUiGridUnionDamageItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridUnionDamageItem:Init(rootUi)
    self.RootUi = rootUi
end

function XUiGridUnionDamageItem:Refresh(damageInfo)
    local playerName = damageInfo.PlayerName
    local playerHeadPortraitId = damageInfo.HeadPortraitId
    local playerHeadFrameId = damageInfo.HeadFrameId
    local damageHp = damageInfo.KillBossHp

    XUiPlayerHead.InitPortrait(playerHeadPortraitId, playerHeadFrameId, self.Head)

    self.TxtPlayerName.text = playerName
    self.TxtLevel.text = damageInfo.Position

    self.TxtDescriptionLeft.text = CS.XTextManager.GetText("UnionDamageToBoss")

    if damageInfo.IsMax then
        local maxColor = CS.XTextManager.GetText("UnionDamageMax")
        self.TxtDescriptionRight.text = string.format("<color=%s>%d</color>", maxColor, damageHp)
    else
        local notmaxColor = CS.XTextManager.GetText("UnionDamageNotMax")
        self.TxtDescriptionRight.text = string.format("<color=%s>%d</color>", notmaxColor, damageHp)
    end
end

return XUiGridUnionDamageItem