---@class XGuideDispatchEvent : XLuaBehaviorNode 派发Lua端事件
---@field EventId string 事件Id
---@field Args string[] 事件携带的参数
local XGuideDispatchEvent = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideDispatchEvent", CsBehaviorNodeType.Action, true, false)

function XGuideDispatchEvent:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    if self.Fields["EventId"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    self.EventId = self.Fields["EventId"]
    self.Args = {}
    local arg = self.Fields["Args"]
    if arg and arg.Count > 0 then
        for i = 0, self.Fields["Args"].Count - 1 do
            table.insert(self.Args, arg[i])
        end
    end
end

function XGuideDispatchEvent:OnEnter()
    XEventManager.DispatchEvent(self.EventId, table.unpack(self.Args))
    self.Node.Status = CsNodeStatus.SUCCESS
end