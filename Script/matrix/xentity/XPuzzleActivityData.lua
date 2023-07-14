--从服务器接收的格式
local XPuzzleActivityData = XClass(nil, "XPuzzleActivityData")

function XPuzzleActivityData:Ctor(id)

    self.GroupCfg = nil
    self.PieceCfgs = {}
    self.RewardState = XPuzzleActivityConfigs.PuzzleRewardState.Unrewarded

    local activityGroupTemplates = XPuzzleActivityConfigs.GetTemplates()
    self.GroupCfg = activityGroupTemplates[id]
    if not self.GroupCfg then return end
    local pieceTemplates = XPuzzleActivityConfigs.GetPieceTemplates()
    for _, template in pairs(pieceTemplates) do
        if id == template.ActId then
             table.insert(self.PieceCfgs, template)
        end
    end
end

function XPuzzleActivityData:SetRewardState(state)
    self.RewardState = state
end

function XPuzzleActivityData:GetPieceAmount()
    return #self.PieceCfgs
end

return XPuzzleActivityData