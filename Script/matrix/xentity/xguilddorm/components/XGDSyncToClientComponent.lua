local MathLerp = CS.UnityEngine.Mathf.Lerp
local XGDComponet = require("XEntity/XGuildDorm/Components/XGDComponet")
local Quaternion = CS.UnityEngine.Quaternion
local Vector3 = CS.UnityEngine.Vector3
local XGDSyncToClientComponent = XClass(XGDComponet, "XGDSyncToClientComponent")

function XGDSyncToClientComponent:Ctor(role, room)
    self.Role = role 
    self.Room = room
    self.Transform = nil
    -- 位置
    self.LastPosition = Vector3.zero
    self.CurrentPosition = Vector3.zero
    -- 旋转
    self.LastRotation = Quaternion.identity
    self.CurrentRotation = Quaternion.identity
    -- 更新当前位置时间
    self.UpdateTime = 0
    self.State = XGuildDormConfig.SyncState.None 
    self.Prediction = false
    self.Predicting = false
    self.IsMoveNearWall = false
    self.PredictionTime = 0
    self.MaxPredictionTime = XGuildDormConfig.GetMaxPredictionTime()
    self.ClosePredictionDistance = XGuildDormConfig.GetClosePredictionDistance()
    self.IsOpenPrediction = XGuildDormConfig.GetIsOpenPrediction()
end

function XGDSyncToClientComponent:UpdateCurrentSyncData(position, rotation, state)
    self.State = state
    -- 判断是否移动时接近碰撞
    self.IsMoveNearWall = self.Transform:EqualsPosition(position, self.ClosePredictionDistance)
        and state == XGuildDormConfig.SyncState.Move and self.IsOpenPrediction
    -- 判断是否需要开启预测，不接近碰撞同时时移动状态
    self.Prediction = (state == XGuildDormConfig.SyncState.Move) and not self.IsMoveNearWall
        and self.IsOpenPrediction
    self.Predicting = false
    self.PredictionTime = 0
    self.LastPosition = self.Transform.position
    self.CurrentPosition = position
    self.LastRotation = self.Transform.rotation
    self.CurrentRotation = rotation
    self.UpdateTime = self.Room:GetRunTime()
end

function XGDSyncToClientComponent:Init()
    XGDSyncToClientComponent.Super.Init(self)
    self:UpdateRoleDependence()
    self.LastPosition = self.Transform.position
    self.CurrentPosition = self.Transform.position
    self.Role:ChangeStateMachine(XGuildDormConfig.RoleFSMType.IDLE)
end

function XGDSyncToClientComponent:UpdateRoleDependence()
    self.Transform = self.Role:GetRLRole():GetTransform()
end

function XGDSyncToClientComponent:DoPredict(dt)
    self.LastPosition = self.Transform.position
    self.CurrentPosition = self.CurrentPosition + (self.CurrentRotation * Vector3.forward).normalized 
        * XGuildDormConfig.GetRoleMoveSpeed() * self.Room:GetSyncTime()
    self.LastRotation = self.Transform.rotation
    self.CurrentRotation = self.Transform.rotation
    self.UpdateTime = self.Room:GetRunTime() - dt
    self.Predicting = true
end

function XGDSyncToClientComponent:CheckPredictionTime()
    if self.PredictionTime >= self.MaxPredictionTime then
        self.Prediction = false
        self.IsMoveNearWall = false
        self.PredictionTime = 0
        self.Predicting = false
    end
end

function XGDSyncToClientComponent:Update(dt)
    -- 交互中自己触发逻辑，不需要跑这里
    if self.Role:GetIsInteracting() then
        return
    end
    -- 正在播放行为，不处理同步
    if self.Role:CheckIsInStateMachine(XGuildDormConfig.RoleFSMType.PLAY_ACTION) then
        return
    end
    -- 切换动画
    if self.Transform:EqualsPosition(self.CurrentPosition, 0.03) then
        -- 正在顶墙走，不处理移动
        if self.State == XGuildDormConfig.SyncState.MoveWall then
            self.Role:ChangeStateMachine(XGuildDormConfig.RoleFSMType.MOVE)
            return
        end
        if self.Prediction then
            -- 同方向预测
            self:DoPredict(dt)
        elseif self.IsMoveNearWall then
            self.Role:ChangeStateMachine(XGuildDormConfig.RoleFSMType.MOVE)
            return
        else
            self.Role:ChangeStateMachine(XGuildDormConfig.RoleFSMType.IDLE)
            return
        end
    end
    self.Role:ChangeStateMachine(XGuildDormConfig.RoleFSMType.MOVE)
    local doTime = self.Room:GetSyncTime() * 2
    local weight = math.min((self.Room:GetRunTime() - self.UpdateTime) * (1 / doTime), 1)
    CS.XGuildDormHelper.SlerpPositionAndRotation(self.Transform
        , self.LastPosition, self.CurrentPosition, self.LastRotation, self.CurrentRotation, weight)
    if self.Prediction and self.Predicting then
        self.PredictionTime = self.PredictionTime + dt
        self:CheckPredictionTime()
    end
end

return XGDSyncToClientComponent