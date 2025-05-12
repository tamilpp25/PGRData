local XDynamicTableIrregular = {}

function XDynamicTableIrregular.New(gameObject)
    if gameObject == nil then
        XLog.Error("XDynamicTableIrregular.New->gameObject == nil, Please check the object is instancing")
        return nil
    end

    local dynamicTable = {}
    setmetatable(dynamicTable, { __index = XDynamicTableIrregular })

    local imp = dynamicTable:Init(gameObject)

    if not imp then
        XLog.Error("XDynamicTableIrregular.New->can not find the object imp, Please check the Component type is right!")
        return nil
    end

    return dynamicTable
end

--初始化
function XDynamicTableIrregular:Init(gameObject)
    local imp = gameObject:GetComponent(typeof(CS.XDynamicTableIrregular))
    if not imp then
        return false
    end

    self.Proxy = nil
    self.ProxyMap = {}
    self.ProxyImpMap = {}
    self.DataSource = {}
    self.DynamicEventDelegate = nil

    self.Imp = imp
    self.Imp:SetViewSize(imp.rectTransform.rect.size)
    self.Imp.DynamicTableGridDelegate = function(event, index, grid)
        self:OnDynamicTableEvent(event, index, grid)
    end

    return true
end

---@param proxy XUiNode
function XDynamicTableIrregular:SetProxyDisplay(proxy, isShow)
    if CheckClassSuper(proxy, XUiNode) then
        if isShow then
            proxy:Open()
        else
            if proxy:IsValid() then
                proxy:Close()
            end
        end
    end
end

--事件回调
function XDynamicTableIrregular:OnDynamicTableEvent(event, index)

    if not self.Proxy then
        XLog.Warning("XDynamicTableIrregular Proxy is nil,Please Setup First!!")
        return
    end

    if not self.Delegate then
        XLog.Warning("XDynamicTableIrregular Delegate is nil,Please Setup First!!")
        return
    end

    if not self.Delegate.OnDynamicTableEvent and not self.DynamicEventDelegate then
        XLog.Warning("XDynamicTableIrregular Delegate func OnDynamicTableEvent is nil,Please Setup First!!")
        return
    end

    if not self.Delegate.GetProxyType then
        XLog.Warning("XDynamicTableIrregular Delegate func GetProxyType is nil,Please Setup First!!")
        return
    end

    --获取当前代理的类型
    local proxy = self:GetGridByIndex(index)

    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then

        local proxyType = self.Delegate:GetProxyType(index)
        local grid = self.Imp:PreDequeueGrid(proxyType, index)

        if not self.Proxy[proxyType] then
            XLog.Error(string.format("XDynamicTableIrregular Proxy Type: %s not exist,Please Setup First!!", proxyType))
            return
        end

        --使用代理器，Lua代理器是一个 Table,IL使用C#脚本
        if grid ~= nil then
            proxy = self.ProxyMap[grid]
            if not proxy then
                proxy = self.Proxy[proxyType].New(grid, table.unpack(self.ProxyArgs))
                self.ProxyMap[grid] = proxy
                --初始化只调动一次
                proxy.Index = index
                proxy.DynamicGrid = grid

                if self.DynamicEventDelegate then
                    self.DynamicEventDelegate(DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT, index, proxy)
                else
                    self.Delegate:OnDynamicTableEvent(DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT, index, proxy)
                end

            end
        end

        proxy.Index = index
        proxy.DynamicGrid = grid
        self.ProxyImpMap[index] = proxy
        self:SetProxyDisplay(proxy, true)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        proxy.Index = -1
        proxy.DynamicGrid = nil
        self.ProxyImpMap[index] = nil
        self:SetProxyDisplay(proxy, false)
    end
    if self.DynamicEventDelegate then
        self.DynamicEventDelegate(event, index, proxy)
    else
        self.Delegate:OnDynamicTableEvent(event, index, proxy)
    end

end

-- 兼容XUiNode
function XDynamicTableIrregular:SetActive(flag)
    if not self.Imp then
        return
    end
    self.Imp.gameObject:SetActiveEx(flag)
    local allGrid = self:GetGrids()
    for k, grid in pairs(allGrid or {}) do
        if flag then
            grid:Open()
        else
            grid:Close()
        end
    end
end

--回收所有节点
function XDynamicTableIrregular:RecycleAllTableGrid()
    if not self.Imp then
        return
    end

    self.Imp:RecycleAllGrids()
end


--获取实体组件
function XDynamicTableIrregular:GetImpl()
    return self.Imp
end


--设置回调主体
function XDynamicTableIrregular:SetDelegate(delegate)
    if not self.Imp then
        return
    end

    self.Delegate = delegate
end

--设置事件回调
function XDynamicTableIrregular:SetDynamicEventDelegate(fun)
    self.DynamicEventDelegate = fun
end

--设置代理器
function XDynamicTableIrregular:SetProxy(proxyType, proxy, prefab, ...)
    if not self.Imp or not self.Imp.ObjectPool then
        return
    end

    self.Proxy = self.Proxy or {}
    self.Proxy[proxyType] = proxy
    self.Imp.ObjectPool:Add(proxyType, prefab)
    self.ProxyArgs = { ... }
end

--设置总数
function XDynamicTableIrregular:SetTotalCount(totalCout)
    if not self.Imp then
        return
    end

    self.Imp.TotalCount = totalCout
end

--设置总数
function XDynamicTableIrregular:SetDataSource(datas)
    if not datas or not self.Imp then
        return
    end

    self.DataSource = datas
    local count = #self.DataSource
    self.IndexForceReset = self.TotalCount and count < self.TotalCount 
    self.TotalCount = count
    self.Imp.TotalCount = count
end

--获取代理器
function XDynamicTableIrregular:GetGridByIndex(index)
    return self.ProxyImpMap[index]
end

--设置可视区域
function XDynamicTableIrregular:SetViewSize(viewSize)
    if not self.Imp then
        return
    end

    self.Imp:SetViewSize(viewSize)
end

--同步重载数据
function XDynamicTableIrregular:ReloadDataSync(startIndex)
    startIndex = startIndex or -1
    -- 当更换数据源并且总数更少时，将startIndex置为1，避免触发越界atindex的事件
    startIndex = self.IndexForceReset and 1 or startIndex
    self.IndexForceReset = false
    if not self.Imp then
        return
    end

    self.Imp:ReloadDataSync(startIndex)
end

--异步重载数据
function XDynamicTableIrregular:ReloadDataASync(startIndex)
    startIndex = startIndex or -1
    -- 当更换数据源并且总数更少时，将startIndex置为1，避免触发越界atindex的事件
    startIndex = self.IndexForceReset and 1 or startIndex
    self.IndexForceReset = false
    if not self.Imp then
        return
    end

    self.Imp:ReloadDataAsync(startIndex)
end


--清空节点
function XDynamicTableIrregular:Clear()
    if not self.Imp then
        return
    end

    self.Imp:Clear()
end

--todo 其他布局接口这里暂时不一一实现，因为布局属性在编辑阶段已经设置过
return XDynamicTableIrregular