local XAEventNode = require("XEntity/XTheatre/Adventure/Node/Event/XAEventNode")
local XAGlobalRewardEventNode = XClass(XAEventNode, "XAGlobalRewardEventNode")

function XAGlobalRewardEventNode:Ctor()
    
end

function XAGlobalRewardEventNode:GetItemId()
    return self.EventConfig.StepRewardItemId
end

function XAGlobalRewardEventNode:GetItemCount()
    return self.EventConfig.StepRewardItemCount
end

return XAGlobalRewardEventNode