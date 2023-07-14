local XGDComponet = require("XEntity/XGuildDorm/Components/XGDComponet")
local XGDActionPlayComponent = XClass(XGDComponet, "XGDActionPlayComponent")

function XGDActionPlayComponent:Ctor(role)
    self.Role = role
    self.IsPlaying = false
    -- 当前动画播放时间（秒）
    self.PlayDuration = 0
end

function XGDActionPlayComponent:Init()
    XGDActionPlayComponent.Super.Init(self)
end

function XGDActionPlayComponent:Update(dt)
    -- 交互中自己触发逻辑，不需要跑这里
    if self.Role:GetIsInteracting() then
        return
    end
    -- 没有需要播放的动作
    if self.Role:GetPlayActionId() <= 0 then
        return
    end
    -- 不恢复到闲置状态不播放
    if not self.IsPlaying then
        if not self.Role:CheckIsInStateMachine(XGuildDormConfig.RoleFSMType.IDLE) then
            return
        end
    end
    if self.IsPlaying then
        self.PlayDuration = self.PlayDuration - dt
        if self.PlayDuration <= 0 then
            self.Role:StopPlayAction()
        end
    else
        local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormPlayAction
            , self.Role:GetPlayActionId())
        if config == nil then return end
        if self.Role:CheckIsSelfPlayer() and not config.IsFollowCamera then
            self.Role:GetRLRole():UpdateCameraFollow(true)
        end
        self.PlayDuration = config.Duration
        self.IsPlaying = true
        self.Role:GetRLRole():PlayAnimation(config.ActionName, true, config.CrossDuration)
        self.Role:ChangeStateMachine(XGuildDormConfig.RoleFSMType.PLAY_ACTION)
    end
end

function XGDActionPlayComponent:StopPlayAction()
    if self.IsPlaying and self.Role:CheckIsSelfPlayer() then
        self.Role:GetRLRole():UpdateCameraFollow(false)
    end
    self.IsPlaying = false
    self.PlayDuration = 0
end

return XGDActionPlayComponent