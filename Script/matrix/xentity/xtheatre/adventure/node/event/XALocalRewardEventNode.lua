local XAEventNode = require("XEntity/XTheatre/Adventure/Node/Event/XAEventNode")
local XALocalRewardEventNode = XClass(XAEventNode, "XALocalRewardEventNode")

function XALocalRewardEventNode:Ctor()
    
end

function XALocalRewardEventNode:GetItemId()
    return self.EventConfig.StepRewardItemId
end

function XALocalRewardEventNode:GetItemCount()
    return self.EventConfig.StepRewardItemCount
end

return XALocalRewardEventNode