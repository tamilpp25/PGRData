---@class XFSMCallback
---@field on_before function
---@field on_leave function
---@field on_after function
---@field on_enter function
---@field on_pre_update function

---@class XFSMEvent
---@field name string
---@field from
---@field to
---@field priority number
---@field conditions function[]

---@class XFSMControllerConfig
---@field Initial
---@field Terminal
---@field Events XFSMEvent
---@field StateCallbackDic

---@class XBaseController
local XBaseController = XClass(nil, "XBaseController")

-- 必须创建字段
-- Initial 初始化后进入的状态
-- Events 定义transition的Event列表
function XBaseController:CreateData()
    self.Initial = 'Red'
    self.Terminal = nil
    ---@type function[]
    self.ConditionDic = {
        RedToGreen = nil -- fun
    }

    ---@type XFSMCallback[]
    self.StateCallbackDic = {
        Red = {
            on_before = nil,
            on_leave = nil,
            on_after = nil,
            on_enter = nil,
            on_pre_update = nil,
        }
    }
    
    self.WholeStateCallbackDic = {
        on_before_event = nil,
        on_enter_state = nil,
        on_leave_state = nil,
        on_after_event = nil,
    }

    ---@type XFSMEvent[]
    self.Events = {
        { name = "RedToGreen", from = "Ron_leave_stateed", to = "Green", priority = 0 }
    }
end

function XBaseController:GetConditionFun(name)
    return self.ConditionDic[name]
end

function XBaseController:InitData()
    for k, v in pairs(self.Events) do
        ---@type XFSMEvent
        local event = XTool.Clone(v)
        local conditions = self:GetConditionFun(v.name)
        event.conditions = conditions
        table.insert(self.Config.Events, event)
    end
    if not XTool.IsTableEmpty(self.StateCallbackDic) then
        self.Config.StateCallbackDic = self.StateCallbackDic
    end
    if not XTool.IsTableEmpty(self.WholeStateCallbackDic) then
        self.Config.WholeStateCallbackDic = self.WholeStateCallbackDic
    end
    if not XTool.IsTableEmpty(self.TransitionCallBackDic) then
        self.Config.TransitionCallBackDic = self.TransitionCallBackDic
    end
    if not XTool.IsTableEmpty(self.WholeTransitionCallbackDic) then
        self.Config.WholeTransitionCallbackDic = self.WholeTransitionCallbackDic
    end
    self.Config.Initial = self.Initial
    self.Config.Terminal = self.Terminal
end

function XBaseController:CreateStateVo(name, from, to, priority)
    local conditions = self:GetConditionFun(name)
    ---@type XFSMEvent
    local event = { }
    event.name = name
    event.from = from
    event.to = to
    event.conditions = conditions
    event.priority = priority
    table.insert(self.Config.Events, event)
end

function XBaseController:Ctor()
    ---@type XFSMControllerConfig
    self.Config = {
        Initial = nil, -- 初始化进入的状态
        Terminal = nil, -- 运行到该状态，状态机会暂停Update
        Events = {},
        StateCallbackDic = {},
        WholeStateCallbackDic = {},
        TransitionCallBackDic = {},
        WholeTransitionCallbackDic = {},
    }
    self:CreateData()
    self:InitData()
end

function XBaseController:GetConfig()
    return self.Config
end

return XBaseController
