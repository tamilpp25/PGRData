local XUiCPActionBase = XClass(nil, "XUiCPActionBase")

function XUiCPActionBase:Ctor(actionType, params)
    self.Params = params
    self.State = "idle"
    self.IsFinish = false
    self.ActionType = actionType
end

function XUiCPActionBase:Update()
    if self.State == "idle" then
        if self:GetIsFinish() then
            self:Exit()
            return
        end

        self.State = "enter"
        self:OnEnter()
    end
    
    if self.State == "enter" then
        if self:GetIsFinish() then
            self:Exit()
            return
        end
        
        self.State = "stay"
        self:OnStay()
    end
    
    if self.State == "stay" then
       if self:GetIsFinish() then
            self:Exit()
       end
    end

    if self.State == "finish" then
        return true
    end
end

function XUiCPActionBase:Dispose()
    self:Exit()
end

function XUiCPActionBase:Exit()
    self.State = "finish"
end

--强制中断
function XUiCPActionBase:Interrupt()
    self:OnExit()
    self:Dispose()
end

function XUiCPActionBase:GetState()
    return self.State
end

function XUiCPActionBase:GetIsFinish()
    return self.IsFinish
end

function XUiCPActionBase:SetIsFinish(isFinish)
    self.IsFinish =  isFinish
end

function XUiCPActionBase:GetActionType()
    return self.ActionType
end
--@endregion


--@region 子类重写这几个方法 即可
--初始化调用
function XUiCPActionBase:OnEnter()
    XLog.Error("OnEnter 方法未重写")
end

--会一直调用
function XUiCPActionBase:OnStay()
    XLog.Error("OnStay 方法未重写")
end

--结束时调用
function XUiCPActionBase:OnExit()
    self.IsFinish = true
end
--@endregion

return XUiCPActionBase