---@class XRestaurantData 餐厅数据基类
---@field ViewModel XRestaurantViewModel
---@field Data table
local XRestaurantData = XClass(nil, "XRestaurantData")

function XRestaurantData:Ctor(...)
    self.BindFunc = {}
    self:InitData(...)
end

function XRestaurantData:InitData(...)
end

function XRestaurantData:SetViewModel(viewModel)
    self.ViewModel = viewModel
end

--界面关闭时，释放的数据
function XRestaurantData:Release()
    self.ViewModel = nil
    self.BindFunc = {}
end

function XRestaurantData:ReleaseFunc(hashCode)
    if XTool.IsTableEmpty(self.BindFunc) then
        return
    end
    for _, dict in pairs(self.BindFunc) do
        if dict[hashCode] then
            dict[hashCode] = nil
        end
    end
end

function XRestaurantData:UpdateData(data)
    self.Data = data
end

function XRestaurantData:BindViewModelPropertyToObj(hashCode, propertyName, func)
    if not self.BindFunc[propertyName] then
        self.BindFunc[propertyName] = {}
    end

    self.BindFunc[propertyName][hashCode] = func
    --绑定时就执行一次
    func(self:GetProperty(propertyName))
end

function XRestaurantData:BindViewModelPropertiesToObj(hashCode, properties, func)
    local multiParamFunc = function() 
        local values = {}
        for _, property in ipairs(properties) do
            table.insert(values, self:GetProperty(property))
        end
        func(table.unpack(values))
    end
    for _, p in ipairs(properties) do
        self:BindViewModelPropertyToObj(hashCode, p, multiParamFunc)
    end
    --绑定时就执行一次
    multiParamFunc()
end

function XRestaurantData:SetProperty(propertyName, value)
    if not self.Data then
        self.Data = {}
    end
    local oldValue = self.Data[propertyName]
    self.Data[propertyName] = value
    local callBackDict = self.BindFunc[propertyName]
    if oldValue ~= value and not XTool.IsTableEmpty(callBackDict) then
        for _, func in pairs(callBackDict) do
            func(value)
        end
    end
end

function XRestaurantData:GetProperty(propertyName)
    if not self.Data then
        XLog.Error("数据类:" .. self.__name .. "未初始化数据")
        return
    end
    return self.Data[propertyName]
end

---@return table<string, string>
function XRestaurantData:GetPropertyNameDict()
    XLog.Error("子类请实现此方法")
end

return XRestaurantData