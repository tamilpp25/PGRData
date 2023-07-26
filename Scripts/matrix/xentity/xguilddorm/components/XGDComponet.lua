---@class XGDComponet
local XGDComponet = XClass(nil, "XGDComponet")

function XGDComponet:Ctor()
    self._isInit = false
    self._UpdatedTime = 0
    self._UpdateIntervalTime = 0
end

function XGDComponet:Init()
    if self._isInit then return end
    self._isInit = true
end

function XGDComponet:GetIsInit()
    return self._isInit
end

function XGDComponet:SetUpdateIntervalTime(value)
    self._UpdateIntervalTime = value
end

function XGDComponet:CheckCanUpdate(dt)
    if self._UpdateIntervalTime <= 0 then
        return true
    end
    self._UpdatedTime = self._UpdatedTime + dt
    if self._UpdatedTime >= self._UpdateIntervalTime then
        self._UpdatedTime = 0
        return true
    end
    return false
end

function XGDComponet:Dispose()
    
end

-- 检查房间是否被显示
-- function XGDComponet:CheckRoomIsShow(value)
    
-- end

-- -- 每帧运行
-- function XGDComponet:Update(deltaTime)
    
-- end

-- 和role相关的依赖放在这里执行，每当update roleId时会调用
-- function XGDComponet:UpdateRoleDependence()
    
-- end

return XGDComponet