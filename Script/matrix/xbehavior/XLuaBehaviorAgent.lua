---@class XLuaBehaviorAgent 行为代理类
---@field
XLuaBehaviorAgent = XClass(nil, "XLuaBehaviorAgent")

function XLuaBehaviorAgent:Ctor(agentName, agentProxy)
    self.Name = agentName
    self.AgentProxy = agentProxy
    self.Agent = agentProxy.BTAgent
end

function XLuaBehaviorAgent:OnAwake()
end

function XLuaBehaviorAgent:OnStart()
end

function XLuaBehaviorAgent:OnEnable()
end

function XLuaBehaviorAgent:OnDisable()
end

function XLuaBehaviorAgent:OnDestroy()
end

function XLuaBehaviorAgent:OnUpdate()

end

function XLuaBehaviorAgent:OnNotify()

end

function XLuaBehaviorAgent:OnGetEvents()

end