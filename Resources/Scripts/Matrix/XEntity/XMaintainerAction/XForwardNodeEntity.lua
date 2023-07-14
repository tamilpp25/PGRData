local XMaintainerActionNodeEntity = require("XEntity/XMaintainerAction/XMaintainerActionNodeEntity")
local XForwardNodeEntity = XClass(XMaintainerActionNodeEntity, "XForwardNodeEntity")
local CSTextManagerGetText = CS.XTextManager.GetText

function XForwardNodeEntity:Ctor()
    self.Step = 0
    self.TargetNodeId = 0
end

function XForwardNodeEntity:GetStep()
    return self.Step
end

function XForwardNodeEntity:GetTargetNodeId()
    return self.TargetNodeId
end

function XForwardNodeEntity:GetName()
    return string.format(self:GetCfg().Name,self.Step)
end

function XForwardNodeEntity:GetDesc()
    return string.format(self:GetCfg().DescText,self.Step)
end

function XForwardNodeEntity:OpenHintTip(cb)
    if self:GetHint() then
        XUiManager.TipMsg(string.format(self:GetHint(),self.Step), nil, cb)
    else
        if cb then cb() end
    end
end

function XForwardNodeEntity:DoEvent(data)
    if not data then return end
    local targetNodeId = self:GetTargetNodeId()
    if data.cb then data.cb() end
    data.mainUi.IntermediatePanel:MovePlayerById(XPlayer.Id,targetNodeId,function ()
            data.mainUi:CheckEvent(targetNodeId, true, function ()
                    if data.cb then data.cb() end
                end)
        end)
end

return XForwardNodeEntity