local XAEventNode = require("XEntity/XBiancaTheatre/Adventure/Node/Event/XAEventNode")
local XAGlobalRewardEventNode = XClass(XAEventNode, "XAGlobalRewardEventNode")

function XAGlobalRewardEventNode:Ctor()
    
end

function XAGlobalRewardEventNode:GetItemId()
    return self.EventConfig.StepRewardItemId[1]
end

function XAGlobalRewardEventNode:GetItemCount()
    return self.EventConfig.StepRewardItemCount[1]
end

function XAGlobalRewardEventNode:GetStepRewardItemType()
    return self.EventConfig.StepRewardItemType
end

return XAGlobalRewardEventNode