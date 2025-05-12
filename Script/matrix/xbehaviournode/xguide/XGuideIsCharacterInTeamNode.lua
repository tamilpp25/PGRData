---@class XGuideIsCharacterInTeamNode : XLuaBehaviorNode 检测构造体是否在主线队伍中
---@field CharacterId number 构造体Id
local XGuideIsCharacterInTeamNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "IsCharacterInTeam", CsBehaviorNodeType.Condition, true, false)

function XGuideIsCharacterInTeamNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["CharacterId"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.CharacterId = self.Fields["CharacterId"]
end

function XGuideIsCharacterInTeamNode:OnEnter()
    if XDataCenter.TeamManager.CheckInTeam(self.CharacterId) then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end
