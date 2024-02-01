local XBaseController = require("XFSM/XBaseController")

---@class XTestController:XBaseController
local XTestController = XClass(XBaseController, "XTestController")
local input = CS.UnityEngine.Input

function XTestController:TestPirnt()
    print("hyx TestPirnt success")
end

function XTestController:TestConditon()
    if input.GetMouseButtonDown(0) then
        self:TestPirnt()
        return true
    end
    return false
end

-- 必须创建字段
-- Initial 初始化后进入的状态
-- Events 定义transition的Event列表
function XTestController:CreateData()
    -- 初始化后进入的状态
    self.Initial = 'green'

    -- transition的条件
    self.ConditionDic = {
        GTY = self.TestConditon,
        YTR = function(self, refProxy)
            if input.GetMouseButtonDown(1) then
                return true
            end
            return false
        end,
        RTY = function(self, refProxy)
            if input.GetMouseButtonDown(2) then
                return true
            end
            return false
        end,
    }

    -- state的回调
    self.StateCallbackDic = {
        green = {
            on_enter = function(self, refProxy)
                print("hyx on_enter Green")
            end,
            on_leave = function(self, refProxy)
                print("hyx on_leave Green")
            end,
            on_pre_update = nil,
        },
        yellow = {
            on_enter = function(self, refProxy)
                print("hyx on_enter yellow")
            end,
            on_leave = function(self, refProxy)
                print("hyx on_leave yellow")
            end,
            on_pre_update = nil,
        }
    }

    self.TransitionCallBackDic = {
        GTY = {
            on_before = function(self, refProxy)
                print("hyx on_before GTY")
            end,
            on_after = function(self, refProxy)
                print("hyx on_after GTY")
            end,
        }
    } 

    self.WholeStateCallbackDic = {
        on_enter_state = nil,
        on_leave_state = nil,
    }

    self.WholeTransitionCallbackDic = {
        on_before_event = nil,
        on_after_event = nil,
    }

    self.Events = {
        { name = 'GTY', from = 'green', to = 'yellow', priority = 1 },
        { name = 'YTR', from = 'yellow', to = 'red' },
        { name = 'RTY', from = 'red', to = 'green' },
    }
end

return XTestController
