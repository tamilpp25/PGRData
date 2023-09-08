---@class XDynamicTableNormal
XDynamicTableNormal = {}

    DYNAMIC_DELEGATE_EVENT = {
    DYNAMIC_GRID_RELOAD_COMPLETED = 1,--加载完成
    DYNAMIC_GRID_TOUCHED = 2,--点击
    DYNAMIC_GRID_ATINDEX = 3,--更新
    DYNAMIC_GRID_RECYCLE = 4,--回收
    DYNAMIC_TWEEN_OVER = 5,
    DYNAMIC_BEGIN_DRAG = 6,
    DYNAMIC_END_DRAG = 7,

    DYNAMIC_GRID_INIT = 100
}

--- 初始化动态列表
---@param gameObject UnityEngine.GameObject
---@return XDynamicTableNormal
--------------------------
function XDynamicTableNormal.New(gameObject)
    if gameObject == nil then
        XLog.Error("XDynamicTableNormal.New->gameObject == nil, Please check the object is instancing")
        return nil
    end

    local dynamicTable = {}
    setmetatable(dynamicTable, { __index = XDynamicTableNormal })

    local imp = dynamicTable:Init(gameObject)

    if not imp then
        XLog.Error("XDynamicTableIrregular.New->can not find the object imp, Please check the Component type is right!")
        return nil
    end

    return dynamicTable
end

--初始化
function XDynamicTableNormal:Init(gameObject)
    local imp = gameObject:GetComponent(typeof(CS.XDynamicTableNormal))
    if not imp then
        return false
    end

    self.Proxy = nil
    self.ProxyMap = {}
    self.ProxyImpMap = {}
    self.DataSource = {}
    self.DynamicEventDelegate = nil

    self.Imp = imp
    self.Imp:SetViewSize(imp.ScrRect.viewport.rect.size)
    self.Imp.DynamicTableGridDelegate = function(event, index, grid)
        self:OnDynamicTableEvent(event, index, grid)
    end

    return true
end

--获取实体组件
function XDynamicTableNormal:GetImpl()
    return self.Imp
end


--设置回调主体
function XDynamicTableNormal:SetDelegate(delegate)
    if not self.Imp then
        return
    end

    self.Imp:SetDelegate(self)
    self.Delegate = delegate
end

---@param proxy XUiNode
function XDynamicTableNormal:SetProxyDisplay(proxy, isShow)
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
function XDynamicTableNormal:OnDynamicTableEvent(event, index, grid)

    if not self.Proxy then
        XLog.Warning("XDynamicTableNormal Proxy is nil,Please Setup First!!")
        return
    end

    if not self.Delegate then
        XLog.Warning("XDynamicTableNormal Delegate is nil,Please Setup First!!")
        return
    end

    if not self.Delegate.OnDynamicTableEvent and not self.DynamicEventDelegate then
        XLog.Warning("XDynamicTableNormal Delegate func OnDynamicTableEvent is nil,Please Setup First!!")
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
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        XEventManager.DispatchEvent(XEventId.EVENT_GUIDE_STEP_OPEN_EVENT, self.Imp.name)
    end

    if self.DynamicEventDelegate then
        self.DynamicEventDelegate(event, index, proxy)
    else
        self.Delegate.OnDynamicTableEvent(self.Delegate, event, index, proxy)
    end
end

-- 兼容XUiNode
function XDynamicTableNormal:SetActive(flag)
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

--设置事件回调
function XDynamicTableNormal:SetDynamicEventDelegate(fun)
    self.DynamicEventDelegate = fun
end

--设置代理器
function XDynamicTableNormal:SetProxy(proxy, ...)
    self.ProxyMap = {}
    self.ProxyImpMap = {}
    self.Proxy = proxy
    self.ProxyArgs = {...}
end

--设置总数
function XDynamicTableNormal:SetTotalCount(totalCout)
    if not self.Imp then
        return
    end

    self.Imp:SetTotalCount(totalCout)
end

--设置总数
function XDynamicTableNormal:SetDataSource(datas)
    if not datas or not self.Imp then
        return
    end

    self.DataSource = datas
    self.Imp:SetTotalCount(#self.DataSource)
end

--获取代理器
function XDynamicTableNormal:GetGridByIndex(index)
    return self.ProxyImpMap[index]
end

--获取所有代理器
function XDynamicTableNormal:GetGrids()
    return self.ProxyImpMap
end

--设置可视区域
function XDynamicTableNormal:SetViewSize(viewSize)
    if not self.Imp then
        return
    end

    self.Imp:SetViewSize(viewSize)
end

--刷新可视区域
function XDynamicTableNormal:UpdateViewSize()
    if not self.Imp then
        return
    end

    self.Imp:SetViewSize(self.Imp.rectTransform.rect.size)
end

--同步重载数据
function XDynamicTableNormal:ReloadDataSync(startIndex, forceReload)
    startIndex = startIndex or -1
    if not self.Imp then
        return
    end

    if forceReload == nil then
        forceReload = true
    end

    self.Imp:ReloadDataSync(startIndex, forceReload)
end

--异步重载数据
function XDynamicTableNormal:ReloadDataASync(startIndex, forceReload)
    -- 刷新前进行等待 （因异步方式会导致表现空缺）
    if XUiManager.IsBgAsyncLoading() then
        XUiManager.WaitBgLoadComplete(function()
            self:__ReloadDataASync(startIndex, forceReload)
        end)
    else
        self:__ReloadDataASync(startIndex, forceReload)
    end
end

function XDynamicTableNormal:__ReloadDataASync(startIndex, forceReload)
    startIndex = startIndex or -1
    if not self.Imp then
        return
    end

    if forceReload == nil then
        forceReload = true
    end

    self.Imp:ReloadDataAsync(startIndex, forceReload)
end

--是否异步加载中
function XDynamicTableNormal:IsAsyncLoading()
    return self.Imp.IsAsyncLoading and true or false
end

--回收所有节点
function XDynamicTableNormal:RecycleAllTableGrid()
    if not self.Imp then
        return
    end

    self.Imp:RecycleAllTableGrid()
end

--清空节点
function XDynamicTableNormal:Clear()
    if not self.Imp then
        return
    end

    self.Imp:Clear()
end

--设置节点大小
function XDynamicTableNormal:SetGridSize(GridSize)
    if not self.Imp then
        return
    end

    self.Imp.OriginGridSize = GridSize
end

function XDynamicTableNormal:GetGridSize()
    return self.Imp and self.Imp.GridSize
end

function XDynamicTableNormal:CenterToSelected(gameObject,time,cb)
    if not self.Imp then
        return
    end
    self.Imp:CenterToSelected(gameObject,time,cb)
end

function XDynamicTableNormal:GuideGetDynamicTableIndex(key, id)
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

function XDynamicTableNormal:SetPadding(left,right,top,bottom)
    if not self.Imp then
        return
    end
    self.Imp.Padding.left = left or self.Imp.Padding.left
    self.Imp.Padding.right = right or self.Imp.Padding.right
    self.Imp.Padding.top = top or self.Imp.Padding.top
    self.Imp.Padding.bottom = bottom or self.Imp.Padding.bottom
end

function XDynamicTableNormal:Freeze()
    if not self.Imp then
        return
    end
    self.Imp:Freeze()
end

function XDynamicTableNormal:SetGrid(grid)
    self.Imp.Grid = grid
end

function XDynamicTableNormal:GetGrid()
    return self.Imp.Grid
end

function XDynamicTableNormal:GetData(index)
    return self.DataSource[index]
end

-- 获得当前使用的格子中第一个格子的index
function XDynamicTableNormal:GetFirstUseGridIndexAndUseCount()
    local minIndex = 1000
    local useNum = 0
    for index, grid in pairs(self:GetGrids()) do
        if index < minIndex then
            minIndex = index
        end
        useNum = useNum + 1
    end

    return minIndex, useNum
end

function XDynamicTableNormal:GetStartIndex()
    if not self.Imp then
        return
    end
    return self.Imp:GetStartIndex()
end

function XDynamicTableNormal:GetEndIndex()
    if not self.Imp then
        return
    end
    local totalCount = self.Imp.TotalCount
    local endIndex = self:GetStartIndex() + self.Imp.AvailableViewCount - 1
    endIndex = endIndex > totalCount and totalCount or endIndex
    return endIndex
end

function XDynamicTableNormal:DynamicGridAtIndex(index)
    if not self.Imp then
        return
    end
    return self.Imp:DynamicGridAtIndex(index)
end 

---计算当前索引容器的开始位置
---@return UnityEngine.Vector3
function XDynamicTableNormal:CalulateStartPosByIndex(index)
    if not self.Imp then
        return
    end
    return self.Imp:CalulateStartPosByIndex(index)
end

function XDynamicTableNormal:ScrollToIndex(index, duration, beginCb, endCb)
    if not self.Imp then
        return
    end
    local pos = self.Imp:CalulateStartPosByIndex(index)
    local newPosX = CS.UnityEngine.Mathf.Clamp01(pos.x)
    local newPosY = CS.UnityEngine.Mathf.Clamp01(pos.y)
    local oldPosX = self.Imp.ScrRect.horizontalNormalizedPosition
    local oldPosY = self.Imp.ScrRect.verticalNormalizedPosition
    if newPosX == oldPosX and newPosY == oldPosY then
        return
    end
    if beginCb then
        beginCb()
    end
    local timer
    timer = XUiHelper.Tween(duration, function(f)
        if XTool.UObjIsNil(self.Imp) then
            XScheduleManager.UnSchedule(timer)
            if endCb then
                endCb()
            end
            return
        end
        self.Imp.ScrRect.horizontalNormalizedPosition = oldPosX + (newPosX - oldPosX) * f
        self.Imp.ScrRect.verticalNormalizedPosition = oldPosY + (newPosY - oldPosY) * f
    end, function()
        self.Imp.ScrRect.horizontalNormalizedPosition = newPosX
        self.Imp.ScrRect.verticalNormalizedPosition = newPosY
        if endCb then
            endCb()
        end
    end)
end

--todo 其他布局接口这里暂时不一一实现，因为布局属性在编辑阶段已经设置过
return XDynamicTableNormal