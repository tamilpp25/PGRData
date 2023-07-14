local XMaintainerActionNodeEntity = require("XEntity/XMaintainerAction/XMaintainerActionNodeEntity")
local XExtraActionNodeEntity = XClass(XMaintainerActionNodeEntity, "XExtraActionNodeEntity")
local CSTextManagerGetText = CS.XTextManager.GetText

function XExtraActionNodeEntity:Ctor()
    self.ExtraActionPoint = 0
end

function XExtraActionNodeEntity:GetExtraActionCount()
    return self.ExtraActionPoint
end

function XExtraActionNodeEntity:GetName()
    return string.format(self:GetCfg().Name,self.ExtraActionPoint)
end

function XExtraActionNodeEntity:GetDesc()
    return string.format(self:GetCfg().DescText,self.ExtraActionPoint)
end

function XExtraActionNodeEntity:OpenHintTip(cb)
    if self:GetHint() then
        XUiManager.TipMsg(string.format(self:GetHint(),self.ExtraActionPoint), nil, cb)
    else
        if cb then cb() end
    end
end

function XExtraActionNodeEntity:DoEvent(data)
    if not data then return end
    local gameData = XDataCenter.MaintainerActionManager.GetGameData()
    gameData:PlusExtraActionCount(self:GetExtraActionCount())
    data.player:MarkNodeEvent()
    if data.cb then data.cb() end
end

return XExtraActionNodeEntity