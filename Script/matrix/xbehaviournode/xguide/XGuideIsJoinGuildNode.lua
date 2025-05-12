---@class XGuideIsJoinGuildNode : XLuaBehaviorNode 检测是否加入公会
local XGuideIsJoinGuildNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "IsJoinGuild", CsBehaviorNodeType.Condition, true, false)

function XGuideIsJoinGuildNode:OnEnter()
    if XDataCenter.GuildManager.IsJoinGuild() then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end