local XBaseController = require("XFSM/XBaseController")

---@field RefProxy XUiRhythmGameTaiko
---@class XRhythmGameTaikoController:XBaseController
local XRhythmGameTaikoController = XClass(XBaseController, "XRhythmGameTaikoController")

function XRhythmGameTaikoController:OnPlayingUpdate()
    self.RefProxy:PlayingUpdateCallByFSM()
end

function XRhythmGameTaikoController:OnPauseUpdate()
end

function XRhythmGameTaikoController:EnterPause()
    self.RefProxy:EnterPauseCallByFSM()
end

function XRhythmGameTaikoController:LeavePause()
    self.RefProxy:LeavePauseCallByFSM()
end

function XRhythmGameTaikoController:EnterPlay()
    self.RefProxy:EnterPlayCallByFSM()
end

-- condition
function XRhythmGameTaikoController:PauseConditon()
    -- return self.RefProxy.IsPause
end

function XRhythmGameTaikoController:ResumePlayingConditon()
    return not self.RefProxy.IsPause
end

-- 必须创建字段
-- Initial 初始化后进入的状态
-- Events 定义transition的Event列表
function XRhythmGameTaikoController:CreateData()
    -- 初始化后进入的状态
    self.Initial = 'playing'

    -- transition的条件
    self.ConditionDic = {
        -- Pause = self.PauseConditon,
        -- ResumePlaying = self.ResumePlayingConditon,
    }

    -- state的回调
    self.StateCallbackDic = {
        playing = {
            on_enter = self.EnterPlay,
            on_leave = function(self, refProxy)
            end,
            on_pre_update = self.OnPlayingUpdate,
        },
        pause = {
            on_enter = self.EnterPause,
            on_leave = self.LeavePause,
            on_pre_update = self.OnPauseUpdate,
        }
    }

    self.TransitionCallBackDic = {
        Pause = {
            on_before = function(self, refProxy)
            end,
            on_after = function(self, refProxy)
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
        { name = 'Pause', from = 'playing', to = 'pause' },
        { name = 'ResumePlaying', from = 'pause', to = 'playing' },
        { name = 'Settle', from = 'playing', to = 'settlement' },
    }
end

return XRhythmGameTaikoController
