-- baseFSM
-- luacheck: globals unpack
local unpack = table.unpack
--priority 约低约先
---@class XUpdatableFSM
local XUpdatableFSM = XClass(nil, "XUpdatableFSM")

XUpdatableFSM.WILDCARD = "*"
XUpdatableFSM.DEFERRED = 0
XUpdatableFSM.SUCCEEDED = 1
XUpdatableFSM.NO_TRANSITION = 2
XUpdatableFSM.PENDING = 3
XUpdatableFSM.CANCELLED = 4

--region Debug
local IsWindowsEditor = XMain.IsWindowsEditor

local function _DebugLog(...)
    if IsWindowsEditor then
        XLog.Warning(...)
    end
end
--endregion

local function do_callback(handler, args)
    if handler then
        return handler(unpack(args))
    end
end

---@param self XUpdatableFSM
local function before_event(self, event, _, _, args)
    -- local specific = do_callback(self["on_before_" .. event], args)
    local cb = self.TransitionCallBackDic[event] and self.TransitionCallBackDic[event].on_before
    local specific = do_callback(cb, args)
    local general = do_callback(self.WholeStateCallbackDic["on_before_event"], args)

    if specific == false or general == false then
        return false
    end
end

---@param self XUpdatableFSM
local function leave_state(self, _, from, _, args)
    -- local specific = do_callback(self["on_leave_" .. from], args)
    local cb = self.StateCallbackDic[from] and self.StateCallbackDic[from].on_leave
    local specific = do_callback(cb, args)
    local general = do_callback(self.WholeStateCallbackDic["on_leave_state"], args)
    _DebugLog("state on_leave", from)

    if specific == false or general == false then
        return false
    end
    if specific == XUpdatableFSM.DEFERRED or general == XUpdatableFSM.DEFERRED then
        return XUpdatableFSM.DEFERRED
    end
end

---@param self XUpdatableFSM
local function enter_state(self, _, _, to, args)
    -- do_callback(self["on_enter_" .. to] or self["on_" .. to], args)
    local cb = self.StateCallbackDic[to] and self.StateCallbackDic[to].on_enter
    _DebugLog("state on_enter", to)
    do_callback(cb, args)
    do_callback(self.WholeStateCallbackDic["on_enter_state"] or self["on_state"], args)
end

---@param self XUpdatableFSM
---@param event XFSMEvent
local function after_event(self, event, _, _, args)
    -- do_callback(self["on_after_" .. event] or self["on_" .. event], args)
    local cb = self.TransitionCallBackDic[event] and self.TransitionCallBackDic[event].on_after
    do_callback(cb, args)
    do_callback(self.WholeStateCallbackDic["on_after_event"] or self["on_event"], args)
end

---@param self XUpdatableFSM
local function build_transition(self, event, states)
    return function(...)
        local from = self.current
        local to = states[from] or states[XUpdatableFSM.WILDCARD] or from
        local args = { self.XController, self.RefProxy, self, event, from, to, ... }

        assert(not self:IsPending(),
                "previous transition still pending")

        assert(self:Can(event),
                "invalid transition from state '" .. from .. "' with event '" .. event .. "'")

        local before = before_event(self, event, from, to, args)
        if before == false then
            return XUpdatableFSM.CANCELLED
        end

        if from == to then
            after_event(self, event, from, to, args)
            return XUpdatableFSM.NO_TRANSITION
        end

        self.confirm = function()
            self.confirm = nil
            self.cancel = nil

            self.current = to
            -- self.on_pre_update_event = "on_pre_update_"..self.current
            self.on_pre_update_event = self.StateCallbackDic[self.current] and self.StateCallbackDic[self.current].on_pre_update

            enter_state(self, event, from, to, args)
            after_event(self, event, from, to, args)

            return XUpdatableFSM.SUCCEEDED
        end

        self.cancel = function()
            self.confirm = nil
            self.cancel = nil

            after_event(self, event, from, to, args)

            return XUpdatableFSM.CANCELLED
        end

        local leave = leave_state(self, event, from, to, args)
        if leave == false then
            return XUpdatableFSM.CANCELLED
        end
        if leave == XUpdatableFSM.DEFERRED then
            return XUpdatableFSM.PENDING
        end

        if self.confirm then
            return self.confirm()
        end
    end
end

local sort_by_priority_asc = function(a, b)
    return (a.priority or 0) < (b.priority or 0)
end

--- func desc
---@param cfg XFSMControllerConfig
---@param refProxy table 引用proxy
---@param xController XBaseController
function XUpdatableFSM:Ctor(cfg, refProxy, xController, ...)
    ---@type XFSMControllerConfig
    self.Cfg = cfg
    self.RefProxy = refProxy
    self.XController = xController
    self.ProxyArgs = { ... }

    -- Initial state.
    local initial = cfg.Initial
    -- Allow for a string, or a map like `{state = "foo", event = "setup"}`.
    initial = type(initial) == "string" and { state = initial } or initial

    -- Initial event.
    local initial_event = initial and initial.event or "startup"

    -- Terminal state.
    local Terminal = cfg.Terminal
    self.Terminal = Terminal

    -- Events.
    local events = cfg.Events or {}

    table.sort(events, sort_by_priority_asc)

    -- Callbacks.
    -- local callbacks = cfg.callbacks or {}
    ---@type XFSMCallback[]
    self.StateCallbackDic = cfg.StateCallbackDic -- stateCb字典数据
    self.WholeStateCallbackDic = cfg.WholeStateCallbackDic -- 全局stateCb字典数据
    self.TransitionCallBackDic = cfg.TransitionCallBackDic -- transitionCb字典数据
    self.WholeTransitionCallbackDic = cfg.WholeTransitionCallbackDic -- 全局transitionCbCb字典数据

    -- Track state transitions allowed for an event.
    ---@type table<XFSMEvent, string[]>
    local states_for_event = {}
    self.states_for_event = states_for_event

    -- Track events allowed from a state.
    ---@type table<string, XFSMEvent>
    local events_for_state = {}
    self.events_for_state = events_for_state

    ---@param e XFSMEvent
    local function add(e)
        -- Allow wildcard transition if `from` is not specified.
        local from = type(e.from) == "table" and e.from or (e.from and { e.from } or { XUpdatableFSM.WILDCARD })
        local to = e.to
        local event = e.name

        states_for_event[event] = states_for_event[event] or {}
        for _, fr in ipairs(from) do
            events_for_state[fr] = events_for_state[fr] or {}
            table.insert(events_for_state[fr], e)

            -- Allow no-op transition if `to` is not specified.
            states_for_event[event][fr] = to or fr
        end
    end

    if initial then
        add({ name = initial_event, from = "none", to = initial.state })
    end

    for _, event in ipairs(events) do
        add(event)
    end

    for event, states in pairs(states_for_event) do
        self[event] = build_transition(self, event, states)
    end

    -- for name, callback in pairs(callbacks) do
    --   self[name] = callback
    -- end

    self.current = "none"
    if initial and not initial.defer then
        self[initial_event]()
    end
end

function XUpdatableFSM:Is(state)
    if type(state) == "table" then
        for _, s in ipairs(state) do
            if self.current == s then
                return true
            end
        end

        return false
    end

    return self.current == state
end

function XUpdatableFSM:Can(event)
    local states = self.states_for_event[event]
    local to = states[self.current] or states[XUpdatableFSM.WILDCARD]
    return to ~= nil
end

function XUpdatableFSM:Cannot(event)
    return not self:Can(event)
end

function XUpdatableFSM:Transitions()
    return self.events_for_state[self.current]
end

function XUpdatableFSM:IsPending()
    return self.confirm ~= nil
end

function XUpdatableFSM:IsFinished()
    return self:Is(self.Terminal)
end

---@param self XUpdatableFSM
local Update = function(self)
    if self:IsFinished() then
        return
    end

    --if nil ~= self[self.on_pre_update_event] then
    --    self[self.on_pre_update_event]()
    --end

    if self.on_pre_update_event then
        self.on_pre_update_event(self.XController, self.RefProxy, table.unpack(self.ProxyArgs))
    end

    local transitions = self:Transitions()
    local transitions_count = 0
    if nil ~= transitions then
        transitions_count = #transitions
    end

    for i = 1, transitions_count do
        local e = transitions[i]
        if nil ~= e.conditions and true == e.conditions(self.XController, self.RefProxy, table.unpack(self.ProxyArgs)) then
            self[e.name](table.unpack(self.ProxyArgs))
            break
        end
    end
end

function XUpdatableFSM:UpdateAuto()
    if not self.IsAutoUpdate then
        XLog.Error("当前状态机IsAutoUpdate为false")
        return
    end
    Update(self)
end

function XUpdatableFSM:UpdateManual()
    if self.IsAutoUpdate then
        XLog.Error("当前状态机IsAutoUpdate为true，请不要执行手动Update，若要执行手动Update，请先调用XFSMAgency的SetFSMAutoUpdateFlag接口设置为true")
        return
    end
    Update(self)
end

function XUpdatableFSM:Reset()
end

function XUpdatableFSM:Release()
    self.Cfg = nil
    self.RefProxy = nil
    self.XController = nil
    self.ProxyArgs = nil
    self.StateCallbackDic = nil
    self.WholeStateCallbackDic = nil
    self.TransitionCallBackDic = nil
    self.WholeTransitionCallbackDic = nil
    XMVCA.XFSM:ReleaseFSM(self)
end

return XUpdatableFSM