local XAEventNode = require("XEntity/XBiancaTheatre/Adventure/Node/Event/XAEventNode")
local XALocalRewardEventNode = XClass(XAEventNode, "XALocalRewardEventNode")

function XALocalRewardEventNode:Ctor()
    
end

function XALocalRewardEventNode:GetItemIdList()
    return self.EventConfig.StepRewardItemId
end

function XALocalRewardEventNode:GetItemCount(index)
    return self.EventConfig.StepRewardItemCount[index] or 0
end

function XALocalRewardEventNode:GetStepRewardItemType()
    return self.EventConfig.StepRewardItemType
end

return XALocalRewardEventNode