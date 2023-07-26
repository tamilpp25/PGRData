local XMaintainerActionNodeEntity = require("XEntity/XMaintainerAction/XMaintainerActionNodeEntity")
local XStartNodeEntity = XClass(XMaintainerActionNodeEntity, "XStartNodeEntity")
local CSTextManagerGetText = CS.XTextManager.GetText

function XStartNodeEntity:Ctor()
    self.ExtraActionPoint = 0
end

function XStartNodeEntity:GetExtraActionCount()
    return self.ExtraActionPoint
end

function XStartNodeEntity:GetName()
    return string.format(self:GetCfg().Name,self.ExtraActionPoint)
end

function XStartNodeEntity:GetDesc()
    return string.format(self:GetCfg().DescText,self.ExtraActionPoint)
end

function XStartNodeEntity:OpenHintTip(cb)
    if self:GetHint() then
        XUiManager.TipMsg(string.format(self:GetHint(),self.ExtraActionPoint), nil, cb)
    else
        if cb then cb() end
    end
end

function XStartNodeEntity:DoEvent(data)
    if not data then return end
    local gameData = XDataCenter.MaintainerActionManager.GetGameData()
    gameData:PlusExtraActionCount(self:GetExtraActionCount())
    data.player:MarkNodeEvent()
    if data.cb then data.cb() end
end

return XStartNodeEntity