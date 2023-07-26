local XMaintainerActionNodeEntity = require("XEntity/XMaintainerAction/XMaintainerActionNodeEntity")
local XFallBackNodeEntity = XClass(XMaintainerActionNodeEntity, "XFallBackNodeEntity")
local CSTextManagerGetText = CS.XTextManager.GetText

function XFallBackNodeEntity:Ctor()
    self.Step = 0
    self.TargetNodeId = 0
end

function XFallBackNodeEntity:GetStep()
    return self.Step
end

function XFallBackNodeEntity:GetTargetNodeId()
    return self.TargetNodeId
end

function XFallBackNodeEntity:GetName()
    return string.format(self:GetCfg().Name,self.Step)
end

function XFallBackNodeEntity:GetDesc()
    return string.format(self:GetCfg().DescText,self.Step)
end

function XFallBackNodeEntity:OpenHintTip(cb)
    if self:GetHint() then
        XUiManager.TipMsg(string.format(self:GetHint(),self.Step), nil, cb)
    else
        if cb then cb() end
    end
end

function XFallBackNodeEntity:DoEvent(data)
    if not data then return end
    local targetNodeId = self:GetTargetNodeId()
    if data.cb then data.cb() end
    data.mainUi.IntermediatePanel:ReverseMovePlayerById(XPlayer.Id,targetNodeId,function ()
            data.mainUi:CheckEvent(targetNodeId, true, function ()
                    if data.cb then data.cb() end
                end)
        end)
end

return XFallBackNodeEntity