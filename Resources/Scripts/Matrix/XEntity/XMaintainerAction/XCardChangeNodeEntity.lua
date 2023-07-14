local XMaintainerActionNodeEntity = require("XEntity/XMaintainerAction/XMaintainerActionNodeEntity")
local XCardChangeNodeEntity = XClass(XMaintainerActionNodeEntity, "XCardChangeNodeEntity")
local CSTextManagerGetText = CS.XTextManager.GetText

function XCardChangeNodeEntity:Ctor()
    self.OldCard = 0
    self.NewCard = 0
end

function XCardChangeNodeEntity:GetOldCard()
    return self.OldCard
end

function XCardChangeNodeEntity:GetNewCard()
    return self.NewCard
end

function XCardChangeNodeEntity:OpenHintTip(cb)
    if self:GetHint() then
        XUiManager.TipMsg(string.format(self:GetHint(),self.OldCard,self.NewCard), nil, cb)
    else
        if cb then cb() end
    end
end

function XCardChangeNodeEntity:DoEvent(data)
    if not data then return end
    local oldCard = self:GetOldCard()
    local newCard = self:GetNewCard()
    data.mainUi.BelowPanel:ChangeCard(oldCard, newCard, data.cb)
    data.player:MarkNodeEvent()
end

return XCardChangeNodeEntity