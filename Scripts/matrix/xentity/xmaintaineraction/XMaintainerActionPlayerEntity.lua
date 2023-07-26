local XMaintainerActionPlayerEntity = XClass(nil, "XMaintainerActionPlayerEntity")
local CSTextManagerGetText = CS.XTextManager.GetText

function XMaintainerActionPlayerEntity:Ctor(id)
    self.PlayerId = id
    self.PlayerName = ""
    self.HeadPortraitId = 0
    self.HeadFrameId = 0
    self.NodeId = 0
    self.Reverse = false
    self.IsNodeTriggered = false
end

function XMaintainerActionPlayerEntity:UpdateData(Data)
    for key, value in pairs(Data) do
        self[key] = value
    end
end

function XMaintainerActionPlayerEntity:GetPlayerId()
    return self.PlayerId
end

function XMaintainerActionPlayerEntity:GetPlayerName()
    return self.PlayerName
end

function XMaintainerActionPlayerEntity:GetHeadPortraitId()
    return self.HeadPortraitId
end

function XMaintainerActionPlayerEntity:GetHeadFrameId()
    return self.HeadFrameId
end

function XMaintainerActionPlayerEntity:GetPosNodeId()
    return self.NodeId
end

function XMaintainerActionPlayerEntity:GetIsReverse()--是否反向
    return self.Reverse
end

function XMaintainerActionPlayerEntity:GetIsNodeTriggered()--所在格子是否已被触发
    return self.IsNodeTriggered
end

function XMaintainerActionPlayerEntity:DoChangeDirection()
    self.Reverse = not self.Reverse 
end

function XMaintainerActionPlayerEntity:MarkNodeEvent()
    self.IsNodeTriggered = true
    XDataCenter.MaintainerActionManager.ClearRecordData()
end

function XMaintainerActionPlayerEntity:UnMarkNodeEvent()
    self.IsNodeTriggered = false
end

function XMaintainerActionPlayerEntity:MoveTo(nodeId)
    self.NodeId = nodeId
end

return XMaintainerActionPlayerEntity