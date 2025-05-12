---@class XQuestBase
local XQuestBase = XClass(nil,"QuestBase")

---@param proxy StatusSyncFight.XFightScriptProxy
function XQuestBase:Ctor(proxy)
    self._proxy = proxy
end

function XQuestBase:SetStepIdList(idList)
    self.StepIdList = idList
end

---@return boolean
function XQuestBase:ExtraStepCheck(id)--此处由于step激活逻辑调整到了服务器上，后续使用需要重新设计
    local isActive = true
    if self.StepExtraCheckFuncs[id] ~= nil then
        isActive = self.StepExtraCheckFuncs[id](self)
    end
    return isActive
end

function XQuestBase:OnEnable(id)
    if self.StepEnterFuncs[id] ~= nil then
        self.StepEnterFuncs[id](self)
    end
end

function XQuestBase:OnDisable(id)
    if self.StepExitFuncs[id] ~= nil then
        self.StepExitFuncs[id](self)
    end
end

---此函数暂不在C#中调用，因为暂不考虑给策划开放Update这个阶段，让他们习惯用事件流解决问题，而不是轮询。
---轮询检测的时机容易不精准还可能重复执行处理，性能也不好。
---@param dt number @ delta time
function XQuestBase:Update(dt)
    if self.StepIdList == nil then
        return
    end

    XTool.LoopCollection(self.StepIdList, function(v)
        if self.StepUpdateFuncs[v] ~= nil then
            self.StepUpdateFuncs[v](self, dt)
        end
    end)
end

---@param eventType number
---@param eventArgs userdata
function XQuestBase:HandleEvent(eventType, eventArgs)
    if self.StepIdList == nil then
        return
    end

    XTool.LoopCollection(self.StepIdList, function(v)
        if self.StepHandleEventFuncs[v] ~= nil then
            self.StepHandleEventFuncs[v](self, eventType, eventArgs)
        end
    end)
end

XQuestBase.StepExtraCheckFuncs = {}
XQuestBase.StepEnterFuncs = {}
XQuestBase.StepExitFuncs = {}
XQuestBase.StepUpdateFuncs = {}
XQuestBase.StepHandleEventFuncs = {}

return XQuestBase
