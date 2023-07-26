---@class XDynamicTableCurve
XDynamicTableCurve = {}

function XDynamicTableCurve.New(gameObject)
    if gameObject == nil then
        return nil
    end

    local dynamicTable = {}
    setmetatable(dynamicTable, { __index = XDynamicTableCurve })

    local imp = dynamicTable:Init(gameObject)

    if not imp then
        return nil
    end

    return dynamicTable
end

--初始化
function XDynamicTableCurve:Init(gameObject)
    local imp = gameObject:GetComponent(typeof(CS.XDynamicTableCurve))
    if not imp then
        return false
    end

    self.Proxy = nil
    self.ProxyArgs = nil
    self.ProxyMap = {}
    self.ProxyImpMap = {}
    self.DataSource = {}
    self.DynamicEventDelegate = nil

    self.Imp = imp
    self.Imp.DynamicTableGridDelegate = function(event, index, grid)
        self:OnDynamicTableEvent(event, index, grid)
    end

    return true
end

--获取实体组件
function XDynamicTableCurve:GetImpl()
    return self.Imp
end


--设置回调主体
function XDynamicTableCurve:SetDelegate(delegate)
    if not self.Imp then
        return
    end

    if self.Imp.SetDelegate then
        self.Imp:SetDelegate(self) 
    end
    self.Delegate = delegate
end

function XDynamicTableCurve:SetProxyDisplay(proxy, isShow)
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
function XDynamicTableCurve:OnDynamicTableEvent(event, index, grid)

    if not self.Proxy then
        XLog.Warning("XDynamicTableCurve Proxy is nil,Please Setup First!!")
        return
    end

    if not self.Delegate then
        XLog.Warning("XDynamicTableCurve Delegate is nil,Please Setup First!!")
        return
    end

    if not self.Delegate.OnDynamicTableEvent then
        XLog.Warning("XDynamicTableCurve Delegate func OnDynamicTableEvent is nil,Please Setup First!!")
        return
    end

    --使用代理器，Lua代理器是一个 Table,IL使用C#脚本
    local proxy = nil
    if grid ~= nil then
        proxy = self.ProxyMap[grid]
        if not proxy then
            proxy = self.Proxy.New(grid, table.unpack(self.ProxyArgs))
            self.ProxyMap[grid] = proxy
            --初始化只调动一次
            proxy.Index = index
            proxy.DynamicGrid = grid

            if self.DynamicEventDelegate then
                self.DynamicEventDelegate(DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT, index, proxy)
            else
                self.Delegate.OnDynamicTableEvent(self.Delegate, DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT, index, proxy)
            end

        end
    end

    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
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
        self.Delegate.OnDynamicTableEvent(self.Delegate, event, index, proxy)
    end
end


--设置事件回调
function XDynamicTableCurve:SetDynamicEventDelegate(fun)
    self.DynamicEventDelegate = fun
end

--设置代理器
function XDynamicTableCurve:SetProxy(proxy, ...)
    self.ProxyMap = {}
    self.ProxyImpMap = {}
    self.Proxy = proxy
    self.ProxyArgs = {...}
end

--设置总数
function XDynamicTableCurve:SetTotalCount(totalCout)
    if not self.Imp then
        return
    end

    self.Imp.TotalCount = totalCout
end

--设置总数
function XDynamicTableCurve:SetDataSource(datas)
    if not datas or not self.Imp then
        return
    end

    self.DataSource = datas
    self.Imp.TotalCount = #self.DataSource
end

--获取代理器
function XDynamicTableCurve:GetGridByIndex(index)
    return self.ProxyImpMap[index]
end

--获取所有代理器
function XDynamicTableCurve:GetGrids()
    return self.ProxyImpMap
end

--设置可视区域
function XDynamicTableCurve:SetViewSize(viewSize)
    if not self.Imp then
        return
    end

    self.Imp:SetViewSize(viewSize)
end


--重载数据
function XDynamicTableCurve:ReloadData(startIndex)
    startIndex = startIndex or -1
    if not self.Imp then
        return
    end


    self.Imp:ReloadData(startIndex)
end


--回收所有节点
function XDynamicTableCurve:RecycleAllTableGrid()
    if not self.Imp then
        return
    end

    self.Imp:RecycleAllTableGrid()
end

--清空节点
function XDynamicTableCurve:Clear()
    if not self.Imp then
        return
    end

    self.Imp:Clear()
end

--设置节点大小
function XDynamicTableCurve:SetGridSize(GridSize)
    if not self.Imp then
        return
    end

    self.Imp.OriginGridSize = GridSize
end

function XDynamicTableCurve:GetGridSize()
    return self.Imp and self.Imp.GridSize
end

-- 跳转到指定节点
function XDynamicTableCurve:TweenToIndex(index)
    if not self.Imp then
        return
    end

    self.Imp:TweenToIndex(index)
end

function XDynamicTableCurve:GetTweenIndex()
    if not self.Imp then
        return 0
    end
    return self.Imp.StartIndex
end

function XDynamicTableCurve:SetChapterGuide()
    self.ChapterGuide = true
end

function XDynamicTableCurve:GuideGetDynamicTableIndex(key, id)
    if not self.DataSource then
        return -1
    end

    for i, v in ipairs(self.DataSource) do
        if (type(v) ~= "table" and tostring(v) == id) or (type(v) == "table" and tostring(v[key]) == id) then
            return i - 1
        end
    end

    XLog.Error("Can not find key:" .. key .. " Value:" .. tostring(id) .. " in DataSource ")

    return -1
end

--todo 其他布局接口这里暂时不一一实现，因为布局属性在编辑阶段已经设置过
return XDynamicTableCurve