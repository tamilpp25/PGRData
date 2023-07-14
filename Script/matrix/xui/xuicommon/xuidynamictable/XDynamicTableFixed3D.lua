XDynamicTableFixed3D = {}
--------------------------
--- 初始化动态列表
---@class XDynamicTableFixed3D
---@param gameObject UnityEngine.GameObject
---@return XDynamicTableFixed3D
function XDynamicTableFixed3D.New(gameObject)
    if gameObject == nil then
        XLog.Error("XDynamicTableFixed3D.New->gameObject == nil, Please check the object is instancing")
        return nil
    end

    local dynamicTable = {}
    setmetatable(dynamicTable, { __index = XDynamicTableFixed3D })

    local imp = dynamicTable:Init(gameObject)

    if not imp then
        XLog.Error("XDynamicTableIrregular.New->can not find the object imp, Please check the Component type is right!")
        return nil
    end

    return dynamicTable
end

--初始化
function XDynamicTableFixed3D:Init(gameObject)
    local imp = gameObject:GetComponent(typeof(CS.XDynamicTableFixed3D))
    if not imp then
        return false
    end

    self.Proxy = nil
    self.ProxyMap = {}
    self.ProxyImpMap = {}
    self.DataSource = {}
    self.DynamicEventDelegate = nil

    self.Imp = imp
    self.Imp.DynamicTableGridDelegate = function(event, csIndex)
        local gridGo = self.Imp.UsingGridsList[csIndex]
        local luaIndex = csIndex + 1
        self:OnDynamicTableEvent(event, luaIndex, gridGo)
    end

    return true
end

--获取实体组件
function XDynamicTableFixed3D:GetImpl()
    return self.Imp
end

--设置回调主体
function XDynamicTableFixed3D:SetDelegate(delegate)
    if not self.Imp then
        return
    end

    self.Imp:SetDelegate(self)
    self.Delegate = delegate
end

--设置预设列表开始下标
function XDynamicTableFixed3D:SetStartGridLuaIndex(index)
    if not self.Imp then
        return
    end

    self.Imp:SetStartGridLuaIndex(index)
end

function XDynamicTableFixed3D:SetProxyDisplay(proxy, isShow)
    if CheckClassSuper(proxy, XUiNode) then
        if isShow then
            proxy:Open()
        else
            if not XTool.UObjIsNil(proxy.GameObject) then
                proxy:Close()
            end
        end
    end
end

--事件回调
--- func desc
---@param index number luaIndex
function XDynamicTableFixed3D:OnDynamicTableEvent(event, index, gridGo)

    if not self.Proxy then
        XLog.Warning("XDynamicTableFixed3D Proxy is nil,Please Setup First!!")
        return
    end

    if not self.Delegate then
        XLog.Warning("XDynamicTableFixed3D Delegate is nil,Please Setup First!!")
        return
    end

    if not self.Delegate.OnDynamicTableEvent and not self.DynamicEventDelegate then
        XLog.Warning("XDynamicTableFixed3D Delegate func OnDynamicTableEvent is nil,Please Setup First!!")
        return
    end

    --使用代理器，Lua代理器是一个 Table,IL使用C#脚本
    local proxy = nil
    if gridGo ~= nil then
        proxy = self.ProxyMap[gridGo]
        if not proxy then
            proxy = self.Proxy.New(gridGo, table.unpack(self.ProxyArgs))
            self.ProxyMap[gridGo] = proxy
            --初始化只调动一次
            proxy.Index = index
            proxy.DynamicGrid = gridGo

            if self.DynamicEventDelegate then
                self.DynamicEventDelegate(DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT, index, proxy)
            else
                self.Delegate.OnDynamicTableEvent(self.Delegate, DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT, index, proxy)
            end

        end
    end

    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        proxy.Index = index
        proxy.DynamicGrid = gridGo
        self.ProxyImpMap[index] = proxy
        self:SetProxyDisplay(proxy, true)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        proxy.Index = -1
        proxy.DynamicGrid = nil
        self.ProxyImpMap[index] = nil
        self:SetProxyDisplay(proxy, false)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        XEventManager.DispatchEvent(XEventId.EVENT_GUIDE_STEP_OPEN_EVENT, self.Imp.name)
    end

    if self.DynamicEventDelegate then
        self.DynamicEventDelegate(event, index, proxy)
    else
        self.Delegate.OnDynamicTableEvent(self.Delegate, event, index, proxy)
    end
end


--设置事件回调
function XDynamicTableFixed3D:SetDynamicEventDelegate(fun)
    self.DynamicEventDelegate = fun
end

--设置代理器
function XDynamicTableFixed3D:SetProxy(proxy, ...)
    self.ProxyMap = {}
    self.ProxyImpMap = {}
    self.Proxy = proxy
    self.ProxyArgs = {...}
end

--设置总数
function XDynamicTableFixed3D:SetDataSource(datas)
    if not datas or not self.Imp then
        return
    end

    self.DataSource = datas
end

--获取代理器
function XDynamicTableFixed3D:GetGridByIndex(index)
    return self.ProxyImpMap[index]
end

--获取所有代理器(key为gameObject，只能使用pair遍历)
function XDynamicTableFixed3D:GetGrids()
    return self.ProxyImpMap
end

--同步重载数据 
-- startIndex number luaIndex
-- force:强制清除格子后再刷新
function XDynamicTableFixed3D:ReloadDataSync(startIndex, force)
    startIndex = startIndex or -1
    if not self.Imp then
        return
    end

    self.Imp:ReloadDataSync(startIndex, force)
end

--回收所有节点
function XDynamicTableFixed3D:ClearGrids()
    if not self.Imp then
        return
    end

    self.Imp:ClearGrids()
end

function XDynamicTableFixed3D:GuideGetDynamicTableIndex(key, id)
    if not self.DataSource then
        return -1
    end

    if (not key or key == "") then
        return self.Delegate:GuideGetDynamicTableIndex(id)
    end


    for i, v in ipairs(self.DataSource) do
        if (type(v) ~= "table" and tostring(v) == id) or (type(v) == "table" and tostring(v[key]) == id) then
            return i
        end
    end

    XLog.Error("Can not find key:" .. key .. " Value:" .. tostring(id) .. " in DataSource ")

    return -1
end

function XDynamicTableFixed3D:GetData(index)
    return self.DataSource[index]
end

--- func desc
---@param v3 localPos
function XDynamicTableFixed3D:FocusPos(v3, time, cb)
    self.Imp:FocusIndex(v3, time, cb)
end

--- func desc
---@param index number csIndex
---@param time number
---@param cb function
function XDynamicTableFixed3D:FocusIndex(index, time, cb)
    self.Imp:FocusIndex(index, time, cb)
end

--todo 其他布局接口这里暂时不一一实现，因为布局属性在编辑阶段已经设置过
return XDynamicTableFixed3D