local Base = require("Character/BigWorld/XBigWorldPlayerCharBase")

---首席指挥官角色脚本
---@class XCharTest : XBigWorldPlayerCharBase
local XCharTest = XDlcScriptManager.RegCharScript(3005, "XCharTest", Base)

---@param proxy StatusSyncFight.XFightScriptProxy
function XCharTest:Ctor(proxy)
    self.Super.Ctor(self, proxy)
end

function XCharTest:Init()
    self.Super.Init(self)
    
    self:InitHandleJumpTurnSpeedParams()
    -- 这其实是每个Npc都在调用Camera的全局开关, 行为树版本也一样，待v0.3或v0.4版本优化
    self._proxy:SetCameraIgnoreHeightLerpOnAir(false)
end

---@param dt number @ delta time
function XCharTest:Update(dt)
    self.Super.Update(self, dt)
    
    if self._proxy:IsNpcBackState(self._uuid) then -- 在后台不触发逻辑
        return
    end
    
    self:ProcessSwitchNpc()
    self:ProcessChangeMoveState()
    self:ProcessResetSprintMoveTypeOnJump()
    self:ProcessHandleJumpTurnSpeed()
    self:ProcessChangeJumpState()
end

---@param eventType number
---@param eventArgs userdata
function XCharTest:HandleEvent(eventType, eventArgs)
    self.Super.HandleEvent(self, eventType, eventArgs)
end

function XCharTest:Terminate()
    self.Super.Terminate(self)
end


--region Checker
function XCharTest:CheckNpcCanChangeAction()
    if self._proxy:CheckNpcOnAir(self._uuid) then   -- 角色在空中不切换
        return false
    end 
    if self._proxy:CheckNpcAction(self._uuid, ENpcAction.Jump) then -- 角色在跳跃中不切换
        return false
    end
    return true
end
--endregion


--region SwitchNpc 空花角色切换逻辑
function XCharTest:ProcessSwitchNpc()
    -- Check Can Do
    if not self:CheckNpcCanChangeAction() then
        return
    end
    -- Select & Do
    if self._proxy:IsKeyDown(ENpcOperationKey.SwitchNpc1) then
        self._proxy:SwitchPlayerNpc(self._uuid, ENpcOperationKey.SwitchNpc1)
    elseif self._proxy:IsKeyDown(ENpcOperationKey.SwitchNpc2) then
        self._proxy:SwitchPlayerNpc(self._uuid, ENpcOperationKey.SwitchNpc2)
    elseif self._proxy:IsKeyDown(ENpcOperationKey.SwitchNpc3) then
        self._proxy:SwitchPlayerNpc(self._uuid, ENpcOperationKey.SwitchNpc3)
    end
end
--endregion


--region ChangeMoveState 空花角色移动状态逻辑
function XCharTest:ProcessChangeMoveState()
    -- Try Do = Check Can Do + Select Do What
    local isChange, nextMoveType = self:TryDoChangeMoveState()
    -- Do
    if not isChange then
        return
    end
    self._proxy:SetNpcMoveType(self._uuid, nextMoveType)
end

---决策将要切换的移动状态
---@return boolean,number isChange, ENpcMoveType
function XCharTest:TryDoChangeMoveState()
    -- Check Can Do
    if not self:CheckNpcCanChangeAction() then
        return false
    end
    -- Select Do What
    local curMoveType = self._proxy:GetNpcMoveType(self._uuid)      -- Npc当前移动状态
    local nextMoveType = curMoveType                                -- Npc将要切换的移动状态
    local moveNormalizedDist = self._proxy:GetMoveNormalizedDist()  -- 摇杆用力量化长度
    local normalizedWalk2Run = 0.4                                  -- 慢走阈值
    local normalizedRun2Sprint = 1                                  -- 疾跑阈值
    if curMoveType == ENpcMoveType.Walk then
        if moveNormalizedDist >= normalizedWalk2Run and moveNormalizedDist < normalizedRun2Sprint then                  -- 摇杆大于慢走阈值则切换为普通跑
            nextMoveType = ENpcMoveType.Run
        elseif self._proxy:IsKeyDown(ENpcOperationKey.SwitchWalk) then                                                  -- 点击了慢走切换按键则切换为普通跑
            nextMoveType = ENpcMoveType.Run
        elseif self._proxy:IsKeyDown(ENpcOperationKey.SwitchSprint) and moveNormalizedDist >= normalizedRun2Sprint then -- PC键盘摁住方向且点击疾跑则切换为疾跑
            nextMoveType = ENpcMoveType.Sprint
        end
    elseif curMoveType == ENpcMoveType.Run then
        if moveNormalizedDist > 0 and moveNormalizedDist <= normalizedWalk2Run then                                     -- 摇杆小于慢走阈值且不为0则切换为慢走
            nextMoveType = ENpcMoveType.Walk
        elseif self._proxy:IsKeyDown(ENpcOperationKey.SwitchWalk) then                                                  -- 点击了慢走切换按键则切换为慢走
            nextMoveType = ENpcMoveType.Walk
        elseif self._proxy:IsKeyDown(ENpcOperationKey.SwitchSprint) and moveNormalizedDist >= normalizedRun2Sprint then -- 点击了疾跑切换则切换为疾跑
            nextMoveType = ENpcMoveType.Sprint
        end
    elseif curMoveType == ENpcMoveType.Sprint then
        if moveNormalizedDist == 0 then                                                                                 -- 停止输入切换到普通跑
            nextMoveType = ENpcMoveType.Run
        elseif moveNormalizedDist <= normalizedWalk2Run and moveNormalizedDist > normalizedWalk2Run then                -- 摇杆小于慢走阈值且不为0则切换为慢走
            nextMoveType = ENpcMoveType.Walk
        elseif self._proxy:IsKeyDown(ENpcOperationKey.SwitchWalk) then                                                  -- 点击了慢走切换按键则切换为慢走
            nextMoveType = ENpcMoveType.Walk
        elseif self._proxy:IsKeyDown(ENpcOperationKey.SwitchSprint) then                                                -- 点击了疾跑切换则切换为普通跑
            nextMoveType = ENpcMoveType.Run
        end
    end
    return curMoveType ~= nextMoveType, nextMoveType
end
--endregion


--region ChangeJumpMoveState 空花角色空中根据输入重置冲刺移动状态
function XCharTest:ProcessResetSprintMoveTypeOnJump()
    -- Check Can Do
    if not self._proxy:CheckNpcAction(self._uuid, ENpcAction.Jump) then -- 角色不在跳跃不重置
        return false
    end
    if not (self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.None) or
            self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpToStand) or
            self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpToStand)) then    -- 除跳跃落地阶段外外，其它状态无法跳跃
        return false
    end
    -- Select Do What
    local curMoveType = self._proxy:GetNpcMoveType(self._uuid)          -- Npc当前移动状态
    local moveNormalizedDist = self._proxy:GetMoveNormalizedDist()      -- 摇杆用力量化长度
    local normalizedRun2Sprint = 1                                      -- 疾跑阈值
    
    if curMoveType == ENpcMoveType.Sprint and moveNormalizedDist < normalizedRun2Sprint then
        self._proxy:SetNpcMoveType(self._uuid, ENpcMoveType.Run)
    end
end
--endregion


--region ChangeJumpState 空花角色跳跃状态逻辑
function XCharTest:ProcessChangeJumpState()
    -- Check Can Do
    if not self._proxy:IsKeyDown(ENpcOperationKey.Jump) then                                -- 没有按键也不跳 (低频条件可优先判断)
        return false
    end
    if self._proxy:CheckNpcOnAir(self._uuid) then                                           -- 空中没有二段跳
        return false
    end
    if not (self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.None) or
            self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpToStand) or
            self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpToStand)) then    -- 除跳跃落地阶段外外，其它状态无法跳跃
        return false
    end
    -- Select Do What
    local isHasMoveInput = self._proxy:HasMoveInput()
    -- Do Jump
    if isHasMoveInput then
        self._proxy:Jump(self._uuid, true)
    else
        self._proxy:Jump(self._uuid, false)
    end
end
--endregion


--region HandleJumpTurnSpeed 空花角色处理跳跃转向速度【此处逻辑具有明显规律, 可以考虑优化成配置】
function XCharTest:InitHandleJumpTurnSpeedParams()
    self._proxy:SetNpcJumpLookAtSpeed(self._uuid, 0)--初始甚至成0
    self._jumpTurnSpeed_IdleJumpUp = 700
    self._jumpTurnSpeed_IdleJumpOnAir = 700
    self._jumpTurnSpeed_IdleJumpUpToDown = 550
    self._jumpTurnSpeed_IdleJumpDown = 0
    self._jumpTurnSpeed_IdleJumpDownLoop = 0
    self._jumpTurnSpeed_MoveJumpUp = 700
    self._jumpTurnSpeed_MoveJumpOnAir = 700
    self._jumpTurnSpeed_MoveJumpUpToDown = 550
    self._jumpTurnSpeed_MoveJumpDown = 0
    self._jumpTurnSpeed_MoveJumpDownLoop = 0
end

function XCharTest:ProcessHandleJumpTurnSpeed()
    -- Check Can Do
    if not self._proxy:CheckNpcAction(self._uuid, ENpcAction.Jump) then -- 不是跳跃状态不设置速度
        return
    end
    -- Select & Do
    if self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpUp) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_IdleJumpUp)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpOnAir) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_IdleJumpOnAir)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpUpToDown) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_IdleJumpUpToDown)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpDown) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_IdleJumpDown)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpDownLoop) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_IdleJumpDownLoop)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpUp) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_MoveJumpUp)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpOnAir) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_MoveJumpOnAir)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpUpToDown) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_MoveJumpUpToDown)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpDown) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_MoveJumpDown)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpDownLoop) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_MoveJumpDownLoop)
    end
end
--endregion

return XCharTest
