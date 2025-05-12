local XRestaurantData = require("XModule/XRestaurant/XData/XRestaurantData")

---@class XRestaurantWorkbenchProperty
local Properties = {
    --区域类型
    SectionType = "SectionType",
    --工作台Id
    Id = "Id",
    --员工id
    CharacterId = "CharacterId",
    --产品id
    ProductId = "ProductId",
    --更新时间
    UpdateTime = "UpdateTime",
    --服务端工作状态
    ServerWorkState = "ServerWorkState",
    --客户端工作状态
    ClientWorkState = "ClientWorkState",
    --模拟时间
    SimulationSecond = "SimulationSecond",
    --当前进度
    Progress = "Progress",
    --倒计时
    CountDown = "CountDown",
    --工作误差，由于员工升级等造成
    Tolerances = "Tolerances",
    --是否已经消耗原材料
    IsConsume = "IsConsume"
    
}
---@class XRestaurantWorkbench : XRestaurantData 工作台数据
---@field
local XRestaurantWorkbench = XClass(XRestaurantData, "XRestaurantWorkbench")


function XRestaurantWorkbench:InitData(id)
    self.Data = {
        SectionType = XMVCA.XRestaurant.AreaType.None,
        Id = id,
        CharacterId = 0,
        ProductId = 0,
        UpdateTime = 0,
        ServerWorkState = 0,
        ClientWorkState = XMVCA.XRestaurant.WorkState.Free,
        SimulationSecond = 0,
        Progress = 0,
        CountDown = 0,
        Tolerances = 0,
        IsConsume = false
    }
end

function XRestaurantWorkbench:UpdateData(info)
    self:SetProperty(Properties.Id, info.Index)
    self:UpdateAreaType(info.SectionType)
    self:UpdateCharacterId(info.CharacterId)
    self:UpdateProductId(info.ProductId)
    self:UpdateUpdateTime(info.UpdateTime)
    self:UpdateServerState(info.State)

    if self.ViewModel then
        self.ViewModel:UpdateViewModel()
    end
end

function XRestaurantWorkbench:GetPropertyNameDict()
    return Properties
end

function XRestaurantWorkbench:UpdateAreaType(value)
    self:SetProperty(Properties.SectionType, value)
end

function XRestaurantWorkbench:GetWorkbenchId()
    return self:GetProperty(Properties.Id)
end

function XRestaurantWorkbench:GetClientState()
    return self:GetProperty(Properties.ClientWorkState)
end

function XRestaurantWorkbench:GetServerState()
    return self:GetProperty(Properties.ServerWorkState)
end

function XRestaurantWorkbench:GetAreaType()
    return self:GetProperty(Properties.SectionType)
end

function XRestaurantWorkbench:GetCharacterId()
    return self:GetProperty(Properties.CharacterId)
end

function XRestaurantWorkbench:GetProductId()
    return self:GetProperty(Properties.ProductId)
end

function XRestaurantWorkbench:GetUpdateTime()
    return self:GetProperty(Properties.UpdateTime)
end

function XRestaurantWorkbench:GetSimulationSecond()
    return self:GetProperty(Properties.SimulationSecond)
end

function XRestaurantWorkbench:GetProgress()
    return self:GetProperty(Properties.Progress)
end

function XRestaurantWorkbench:GetCountDown()
    return self:GetProperty(Properties.CountDown)
end

function XRestaurantWorkbench:GetTolerances()
    return self:GetProperty(Properties.Tolerances)
end

function XRestaurantWorkbench:IsConsume()
    return self:GetProperty(Properties.IsConsume) or false
end

function XRestaurantWorkbench:UpdateCharacterId(charId)
    self:SetProperty(Properties.CharacterId, charId)
end

function XRestaurantWorkbench:UpdateProductId(productId)
    self:SetProperty(Properties.ProductId, productId)
end

function XRestaurantWorkbench:UpdateClientState(cState)
    self:SetProperty(Properties.ClientWorkState, cState)
end

function XRestaurantWorkbench:UpdateServerState(sState)
    self:SetProperty(Properties.ServerWorkState, sState)
end

function XRestaurantWorkbench:UpdateProgress(value)
    self:SetProperty(Properties.Progress, value)
end

function XRestaurantWorkbench:UpdateCountDown(value)
    self:SetProperty(Properties.CountDown, value)
end

function XRestaurantWorkbench:UpdateUpdateTime(value)
    self:SetProperty(Properties.UpdateTime, value)
end

function XRestaurantWorkbench:UpdateSimulationSecond(value)
    self:SetProperty(Properties.SimulationSecond, value)
end

function XRestaurantWorkbench:UpdateTolerances(value)
    self:SetProperty(Properties.Tolerances, value)
end

function XRestaurantWorkbench:UpdateIsConsume(value)
    self:SetProperty(Properties.IsConsume, value)
end

---@class XRestaurantWorkbenchMgt 工作台数据管理
---@field
local XRestaurantWorkbenchMgt = XClass(nil, "XRestaurantWorkbenchMgt")

function XRestaurantWorkbenchMgt:Ctor()
    self.WorkbenchDict = {}
end

function XRestaurantWorkbenchMgt:UpdateData(sectionInfos)
    if XTool.IsTableEmpty(sectionInfos) then
        return
    end

    for _, info in ipairs(sectionInfos) do
        local bench = self:GetWorkbenchData(info.SectionType, info.Index)
        bench:UpdateData(info)
    end
end

--- 获取工作台数据
---@param areaType number 工作台区域
---@param id number 工作台Id
---@return XRestaurantWorkbench
--------------------------
function XRestaurantWorkbenchMgt:GetWorkbenchData(areaType, id)
    if not self.WorkbenchDict then
        self.WorkbenchDict = {}
    end
    if not self.WorkbenchDict[areaType] then
        self.WorkbenchDict[areaType] = {}
    end
    
    local bench = self.WorkbenchDict[areaType][id]
    if not bench then
        bench = XRestaurantWorkbench.New(id)
        self.WorkbenchDict[areaType][id] = bench
    end
    
    return bench
end


return XRestaurantWorkbenchMgt