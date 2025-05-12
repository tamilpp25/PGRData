---@class XAnchorVisualization 锚点可视化
local XAnchorVisualization = XClass(nil, "XAnchorVisualization")

---@param proxy StatusSyncFight.XFightScriptProxy
---@param npc number
function XAnchorVisualization:Ctor(proxy, npc)
    self._proxy = proxy
    self._npc = npc

    self._camLockAnchorIndex = 25003 ---相机选中的勾点
    self._anchorUsableIndex = 250030 ---参数存在时，选中的勾点可以勾取
    self._anchorVisibleIndex = 250031 ---参数存在时，选中的勾点可以瞄准但不可勾取
    self._npcCamLock0Index = 2402 ---两个中任意一个参数存在且非0时，角色镜头锁定怪物
    self._npcCamLock1Index = 2102

    self._camLockAnchor = nil ---相机选中的勾点
    self._presentAnchorID = nil ---当前显示进度的勾点
    self._presentAnchorVisible = false ---当前是否显示进度

    self._anchorUsable = false ---选中的勾点可以勾取
    self._anchorVisible = false ---选中的勾点可以瞄准但不可勾取

    self._npcCamLock0 = false
    self._npcCamLock1 = false ---角色镜头是否锁定怪物

    self._maxDistance = 100
    self._currentDistanceIndex = 2500201 ---角色到锁定勾点的距离
    self._currentDistance = 100
    self._triggerDistanceIndex = 2500202 ---锁定勾点配置的触发距离
    self._triggerDistance = 100

    print("猎矛填充模块上线")
    self._initialized = true
end

---@param dt number @ delta time
function XAnchorVisualization:Update(dt)
    if not self._initialized then
        return
    end

    --[[    print("读表参数显示"
                .. "  camLockAnchor: " .. tostring(self._proxy:GetNpcNoteInt(self._npc, self._camLockAnchorIndex))
                .. "  anchorUsable: ".. tostring(self._proxy:CheckNpcNoteInt(self._npc, self._anchorUsableIndex))
                .."  anchorVisible: "..tostring(self._proxy:CheckNpcNoteInt(self._npc, self._anchorVisibleIndex))
                .."  npcCamLock: " .. tostring(self._proxy:GetNpcNoteInt(self._npc, self._npcCamLock0Index)).."&&"..tostring(self._proxy:GetNpcNoteInt(self._npc, self._npcCamLock1Index))
        )]]

    --- 角色镜头是否锁定怪物判断
    self._npcCamLock0 = self._proxy:GetNpcNoteInt(self._npc, self._npcCamLock0Index) ~= 0
    self._npcCamLock1 = self._proxy:GetNpcNoteInt(self._npc, self._npcCamLock1Index) ~= 0
    if (self._npcCamLock0 or self._npcCamLock1) and self._presentAnchorVisible then
        --print("————————————————————需要关闭")
        self:DisableAnchorVisible()
        return
    end

    self._anchorUsable = self._proxy:CheckNpcNoteFloat3(self._npc, self._anchorUsableIndex)
    self._anchorVisible = self._proxy:CheckNpcNoteFloat3(self._npc, self._anchorVisibleIndex)
    self._camLockAnchor = self._proxy:GetNpcNoteInt(self._npc, self._camLockAnchorIndex)

    --[[    print("执行参数显示"
                .. "  camLockAnchor: " .. tostring(self._camLockAnchor)
                .. "  anchorUsable: " .. tostring(self._anchorUsable)
                .. "  anchorVisible: " .. tostring(self._anchorVisible)
                .. "  npcCamLock: " .. tostring(self._npcCamLock0 or self._npcCamLock1)
                .. "  presentAnchorVisible: " .. tostring(self._presentAnchorVisible)
                .. "  presentAnchorID: " .. tostring(self._presentAnchorID)
        )]]

    --- 获取玩家当前和选中勾点的距离
    self._currentDistance = self._proxy:GetNpcNoteFloat(self._npc, self._currentDistanceIndex)

    if (self._anchorVisible or self._anchorUsable) and not self._presentAnchorVisible then
        --- 需要开启
        --print("————————————————————需要开启")
        self:SetAnchorVisible()
        self._maxDistance = self._currentDistance
        self._triggerDistance = self._proxy:GetNpcNoteFloat(self._npc, self._triggerDistanceIndex)

    elseif not( self._anchorVisible or self._anchorUsable) and self._presentAnchorVisible then
        --- 需要关闭
        --print("————————————————————需要关闭")
        self:DisableAnchorVisible()

    elseif self._presentAnchorVisible and self._camLockAnchor ~= self._presentAnchorID then
        --- 需要更换目标
        --print("————————————————————需要更换目标")
        self:ChangeAnchor()
        self._maxDistance = self._currentDistance
        self._triggerDistance = self._proxy:GetNpcNoteFloat(self._npc, self._triggerDistanceIndex)
    end
    --[[    print("计算参数显示"
                .. "  _currentDistance: " .. tostring(self._currentDistance)
                .. "  _maxDistance: " .. tostring(self._maxDistance)
                .. "  _triggerDistance: " .. tostring(self._triggerDistance)
        )]]

    --- 更新填充进度，算法待优化。
    if self._presentAnchorVisible then
        if self._anchorUsable then
            --处于可用范围内
            self._proxy:SetSpearPointUiProgress(self._presentAnchorID, 1)
        else
            --处于可视范围内
            if self._currentDistance > self._maxDistance then
                self._maxDistance = self._currentDistance
            end
            local activeDis = self._currentDistance - self._triggerDistance
            local maxDis = self._maxDistance - self._triggerDistance
            if maxDis < 10 then
                maxDis = 10
            end
            local progress = 1 - activeDis / maxDis
            self._proxy:SetSpearPointUiProgress(self._presentAnchorID, progress)
        end
    end
end

--- 开启锚点填充进度显示
function XAnchorVisualization:SetAnchorVisible()
    if self._camLockAnchor ~= 0 then
        --print("开启显示")
        self._proxy:SetSpearPointUiActive(self._camLockAnchor, true)
        self._presentAnchorID = self._camLockAnchor
        self._presentAnchorVisible = true
    end
end

--- 强制脱出，目标置空，关闭填充
function XAnchorVisualization:DisableAnchorVisible()
    --print("关闭显示")
    if self._presentAnchorID ~= nil then
        self._proxy:SetSpearPointUiActive(self._presentAnchorID, false)
    end
    self._presentAnchorVisible = false
    --print("目标置空")
    self._presentAnchorID = nil
end

--- 变更猎矛显示
function XAnchorVisualization:ChangeAnchor()
    --print("变更显示")
    if self._presentAnchorID ~= nil then
        self._proxy:SetSpearPointUiActive(self._presentAnchorID, false)
    end
    if self._camLockAnchor ~= nil then
        self._proxy:SetSpearPointUiActive(self._camLockAnchor, true)
        self._presentAnchorID = self._camLockAnchor
    end
end

return XAnchorVisualization