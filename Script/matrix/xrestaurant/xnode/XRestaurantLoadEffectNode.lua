
---@class XRestaurantLoadEffectNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantLoadEffectNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantLoadEffect", CsBehaviorNodeType.Action, true, false)

function XRestaurantLoadEffectNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if string.IsNilOrEmpty(self.Fields["Path"]) then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.Path = self.Fields["Path"]
    
    self.Position = CS.UnityEngine.Vector3(self.Fields["PositionX"], self.Fields["PositionY"], self.Fields["PositionZ"])
    
end

function XRestaurantLoadEffectNode:OnEnter()
    self.AgentProxy:DoLoadEffect(self.Path, self.Position)
    self.Node.Status = CsNodeStatus.SUCCESS
end