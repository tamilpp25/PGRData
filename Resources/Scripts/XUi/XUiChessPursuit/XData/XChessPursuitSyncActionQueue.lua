--- 管理ChessPursuitSyncActionQueue 玩法的事件处理函数的服务端数据，只能通过Get方法获取内部数据

local XChessPursuitSyncActionQueue = XClass(nil, "XChessPursuitSyncActionQueue")
local XChessPursuitSyncAction = require("XUi/XUiChessPursuit/XData/XChessPursuitSyncAction")
local CSXChessPursuitDirection = CS.XChessPursuitDirection

function XChessPursuitSyncActionQueue:Ctor()
    self.Actions = {}
end

function XChessPursuitSyncActionQueue:Push(actions)
    if actions then
        for i,v in ipairs(actions) do
            table.insert(self.Actions, XChessPursuitSyncAction.New(v))
            XLog.Debug(">>>>>>>>>>>>>>>>>>>>>>>>>> 队列新增行动类型：" .. v.Type)
        end
    end
end

function XChessPursuitSyncActionQueue:Pop()
    if next(self.Actions) then
        local action = self.Actions[1]
        table.remove(self.Actions, 1)

        --弹出时，更新服务端的缓存数据
        XDataCenter.ChessPursuitManager.RefreshDataByAction(action)
        return action
    end
end

function XChessPursuitSyncActionQueue:Clear()
    self.Actions = {}
end

function XChessPursuitSyncActionQueue:GetCount()
    return #self.Actions
end

function XChessPursuitSyncActionQueue:GetTopActions()
    return self.Actions[1]
end

return XChessPursuitSyncActionQueue