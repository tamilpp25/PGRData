local XMaintainerActionNodeEntity = require("XEntity/XMaintainerAction/XMaintainerActionNodeEntity")
local XExploreNodeEntity = XClass(XMaintainerActionNodeEntity, "XExploreNodeEntity")
local CSTextManagerGetText = CS.XTextManager.GetText

function XExploreNodeEntity:Ctor()
    self.Node = {}
end

function XExploreNodeEntity:GetNode()
    return self.Node
end

function XExploreNodeEntity:DoEvent(data)
    if not data then return end
    data.player:MarkNodeEvent()
    XDataCenter.MaintainerActionManager.CreateNode(self:GetNode())
    if data.cb then data.cb() end
end

return XExploreNodeEntity