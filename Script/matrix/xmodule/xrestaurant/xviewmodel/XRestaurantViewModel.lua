---@class XRestaurantViewModel : XEntity 视图数据
---@field Data XRestaurantData
---@field Property table
---@field _Model XRestaurantModel
local XRestaurantViewModel = XClass(XEntity, "XRestaurantViewModel")

function XRestaurantViewModel:OnInit(data)
    self.Data = data
    if self.Data then
        self.Data:SetViewModel(self)
        self.Property = self.Data:GetPropertyNameDict()
    end
    self:InitData()
    self:UpdateViewModel()
end

function XRestaurantViewModel:InitData()
    
end

function XRestaurantViewModel:UpdateViewModel()

end

--- 绑定界面数据
---@param hashCode string 节点GameObject的hashCode，一个界面只能对同一个viewModel的属性进行绑定
---@param propertyName string 属性名称
---@param func function 属性回调
--------------------------
function XRestaurantViewModel:BindViewModelPropertyToObj(hashCode, propertyName, func)
    if not self.Data then
        return
    end
    self.Data:BindViewModelPropertyToObj(hashCode, propertyName, func)
end

function XRestaurantViewModel:BindViewModelPropertiesToObj(hashCode, properties, func)
    if not self.Data then
        return
    end
    self.Data:BindViewModelPropertiesToObj(hashCode, properties, func)
end

function XRestaurantViewModel:OnRelease()
    if self.Data then
        self.Data:Release()
    end
    self.Data = nil
end

function XRestaurantViewModel:ClearBind(hashCode)
    if not self.Data then
        return
    end
    self.Data:ReleaseFunc(hashCode)
end

return XRestaurantViewModel