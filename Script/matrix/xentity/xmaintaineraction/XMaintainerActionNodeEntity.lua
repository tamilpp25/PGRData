local XMaintainerActionNodeEntity = XClass(nil, "XMaintainerActionNodeEntity")
local CSTextManagerGetText = CS.XTextManager.GetText
local Json = require("XCommon/Json")
function XMaintainerActionNodeEntity:Ctor(id,type)
    self.NodeId = id
    self.NodeType = type
    self.EventId = 0
    self.Value = nil
end

function XMaintainerActionNodeEntity:UpdateData(Data)
    for key, value in pairs(Data) do
        self[key] = value
    end
    if self.Value then
        local result = Json.decode(self.Value)
        if result then
            for key, value in pairs(result) do
                self[key] = value
            end
        end
        self.Value = nil
    end
end

function XMaintainerActionNodeEntity:GetCfg()
    return XMaintainerActionConfigs.GetMaintainerActionEventTemplateById(self.EventId)
end

function XMaintainerActionNodeEntity:GetId()
    return self.NodeId
end

function XMaintainerActionNodeEntity:GetType()
    return self.NodeType
end

function XMaintainerActionNodeEntity:GetName()
    return self:GetCfg().Name
end

function XMaintainerActionNodeEntity:GetEventId()
    return self.EventId
end

function XMaintainerActionNodeEntity:GetIsUnKonwn()
    return self.NodeType == XMaintainerActionConfigs.NodeType.UnKnow
end

function XMaintainerActionNodeEntity:GetIsFight()
    return self.NodeType == XMaintainerActionConfigs.NodeType.Fight
end

function XMaintainerActionNodeEntity:GetIsNone()
    return self.NodeType == XMaintainerActionConfigs.NodeType.None
end

function XMaintainerActionNodeEntity:GetIsStart()
    return self.NodeType == XMaintainerActionConfigs.NodeType.Start
end

function XMaintainerActionNodeEntity:GetIsMentor()
    return self.NodeType == XMaintainerActionConfigs.NodeType.Mentor
end

function XMaintainerActionNodeEntity:GetIsNeedPlayAnime()
    return not self:GetIsUnKonwn() and
    not self:GetIsFight()and
    not self:GetIsStart()
end

function XMaintainerActionNodeEntity:GetHint()
    return self:GetCfg().HintText
end

function XMaintainerActionNodeEntity:GetDesc()
    return self:GetCfg().DescText
end

function XMaintainerActionNodeEntity:GetEventIcon()
    return self:GetCfg().EventIcon
end

function XMaintainerActionNodeEntity:OpenHintTip(cb)
    if self:GetHint() then
        XUiManager.TipMsg(self:GetHint(), nil, cb)
    else
        if cb then cb() end 
    end
end

function XMaintainerActionNodeEntity:OpenDescTip()
    local desc = self:GetDesc()
    if desc then
        XLuaUiManager.Open("UiFubenMaintaineractionDetailsTips", self, false)
    end
end

function XMaintainerActionNodeEntity:EventRequest(mainUi, player, cb)
    XDataCenter.MaintainerActionManager.NodeEventRequest(function (data)
            self:UpdateData(data)
            self:OpenHintTip(function ()
                    local tmpData = {
                        player = player,
                        cb = cb,
                        mainUi = mainUi
                    }
                    self:DoEvent(tmpData)
                end)
        end,function ()
            player:MarkNodeEvent()
            if cb then cb() end
        end)
end

return XMaintainerActionNodeEntity