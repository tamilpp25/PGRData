---@class XDynamicTableCurveLaunch
local XDynamicTableCurveLaunch = {}

local DYNAMIC_DELEGATE_EVENT = {
    DYNAMIC_GRID_RELOAD_COMPLETED = 1,--加载完成
    DYNAMIC_GRID_TOUCHED = 2,--点击
    DYNAMIC_GRID_ATINDEX = 3,--更新
    DYNAMIC_GRID_RECYCLE = 4,--回收
    DYNAMIC_TWEEN_OVER = 5,
    DYNAMIC_BEGIN_DRAG = 6,
    DYNAMIC_GRID_INIT = 100
}
XDynamicTableCurveLaunch.DYNAMIC_DELEGATE_EVENT = DYNAMIC_DELEGATE_EVENT

function XDynamicTableCurveLaunch.New(gameObject)
    if gameObject == nil then
        return nil
    end

    local dynamicTable = {}
    setmetatable(dynamicTable, { __index = XDynamicTableCurveLaunch })

    local imp = dynamicTable:Init(gameObject)

    if not imp then
        return nil
    end

    return dynamicTable
end

--初始化
function XDynamicTableCurveLaunch:Init(gameObject)
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
function XDynamicTableCurveLaunch:GetImpl()
    return self.Imp
end


--设置回调主体
function XDynamicTableCurveLaunch:SetDelegate(delegate)
    if not self.Imp then
        return
    end

    if self.Imp.SetDelegate then
        self.Imp:SetDelegate(self) 
    end
    self.Delegate = delegate
end


--事件回调
function XDynamicTableCurveLaunch:OnDynamicTableEvent(event, index, grid)
    -- print("XDynamicTableCurve OnDynamicTableEvent event:" .. event .. ", index:" .. index .. ',gtrid' .. tostring(grid))

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
            local proxyInstance = {}
            setmetatable(proxyInstance, {__index = self.Proxy})
            proxy = self.Proxy.Ctor(proxyInstance, grid, table.unpack(self.ProxyArgs))
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
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        proxy.Index = -1
        proxy.DynamicGrid = nil
        self.ProxyImpMap[index] = nil
    end

    if self.DynamicEventDelegate then
        self.DynamicEventDelegate(event, index, proxy)
    else
        self.Delegate.OnDynamicTableEvent(self.Delegate, event, index, proxy)
    end
end


--设置事件回调
function XDynamicTableCurveLaunch:SetDynamicEventDelegate(fun)
    self.DynamicEventDelegate = fun
end

--设置代理器
function XDynamicTableCurveLaunch:SetProxy(proxy, ...)
    self.ProxyMap = {}
    self.ProxyImpMap = {}
    self.Proxy = proxy
    self.ProxyArgs = {...}
end

--设置总数
function XDynamicTableCurveLaunch:SetTotalCount(totalCout)
    if not self.Imp then
        return
    end

    self.Imp.TotalCount = totalCout
end

--设置总数
function XDynamicTableCurveLaunch:SetDataSource(datas)
    if not datas or not self.Imp then
        return
    end

    self.DataSource = datas
    self.Imp.TotalCount = #self.DataSource
end

--获取代理器
function XDynamicTableCurveLaunch:GetGridByIndex(index)
    return self.ProxyImpMap[index]
end

--获取所有代理器
function XDynamicTableCurveLaunch:GetGrids()
    return self.ProxyImpMap
end

--设置可视区域
function XDynamicTableCurveLaunch:SetViewSize(viewSize)
    if not self.Imp then
        return
    end

    self.Imp:SetViewSize(viewSize)
end


--重载数据
function XDynamicTableCurveLaunch:ReloadData(startIndex)
    startIndex = startIndex or -1
    if not self.Imp then
        print("not self.Imp")
        return
    end


    self.Imp:ReloadData(startIndex)
end


--回收所有节点
function XDynamicTableCurveLaunch:RecycleAllTableGrid()
    if not self.Imp then
        return
    end

    self.Imp:RecycleAllTableGrid()
end

--清空节点
function XDynamicTableCurveLaunch:Clear()
    if not self.Imp then
        return
    end
    self.Imp:Clear()
    self.Imp.DynamicTableGridDelegate = nil
end

--设置节点大小
function XDynamicTableCurveLaunch:SetGridSize(GridSize)
    if not self.Imp then
        return
    end

    self.Imp.OriginGridSize = GridSize
end

function XDynamicTableCurveLaunch:GetGridSize()
    return self.Imp and self.Imp.GridSize
end

-- 跳转到指定节点
function XDynamicTableCurveLaunch:TweenToIndex(index)
    if not self.Imp then
        return
    end

    self.Imp:TweenToIndex(index)
end

function XDynamicTableCurveLaunch:GetTweenIndex()
    if not self.Imp then
        return 0
    end
    return self.Imp.StartIndex
end

function XDynamicTableCurveLaunch:SetChapterGuide()
    self.ChapterGuide = true
end

function XDynamicTableCurveLaunch:GuideGetDynamicTableIndex(key, id)
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
return XDynamicTableCurveLaunch