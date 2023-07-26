---@class XGoldenMinerComponentHook
local XGoldenMinerComponentHook = XClass(nil, "XGoldenMinerComponentHook")

function XGoldenMinerComponentHook:Ctor()
    self.Type = 0
    
    self.Status = XGoldenMinerConfigs.GAME_HOOK_STATUS.NONE

    ---@type UnityEngine.Transform
    self.Transform = false
    ---@type UnityEngine.Transform
    self.GrabPoint = false
    ---@type UnityEngine.Transform
    self.HookObj = false
    ---@type UnityEngine.Vector3[]
    self.HookObjStartLocalPosition = Vector3.zero
    ---@type UnityEngine.Transform[]
    self.RopeObjList = {}
    ---第一段绳子起始位置坐标
    ---@type UnityEngine.Vector3[]
    self.RopeObjStartLocalPosition = Vector3.zero
    
    ---@type boolean
    self.IsAim = false
    ---@type UnityEngine.Transform[]
    self.AimTranList = {}
    ---@type UnityEngine.Collider2D[]
    self.ColliderList = {}
    ---@type UnityEngine.Collider2D
    self.RopeCollider = false
    ---@type XGoInputHandler
    self.RopeInputHandler = false
    
    self.IdleSpeed = 0
    ---@type UnityEngine.Vector3
    self.IdleRotateDirection = Vector3.zero
    ---@type UnityEngine.Vector3
    self.CurIdleRotateAngle = Vector3.zero
    
    ---当前移动路径起点(localPosition)
    ---@type UnityEngine.Vector3[]
    self.CurMoveStartPointList = {}
    ---撞到转向点时线段总长度字典
    self.CurMoveHitPointLengthList = {}
    ---Z轴角度
    ---@type UnityEngine.Vector3[]
    self.CurMoveAngleList = {}
    
    self.ShootSpeed = 0
    self.CurShootSpeed = 0
    
    self.CurRevokeSpeedPercent = 1

    self.RopeLength = 0
    self.RopeMinLength = 0
    self.RopeMaxLength = 0
    
    ---@type XGoInputHandler
    self.GoInputHandlerList = {}
end

return XGoldenMinerComponentHook