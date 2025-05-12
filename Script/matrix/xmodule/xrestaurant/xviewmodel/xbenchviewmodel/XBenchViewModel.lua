local XRestaurantViewModel = require("XModule/XRestaurant/XViewModel/XRestaurantViewModel")

--服务端工作状态
local ServerWorkState = {
    Normal = 0,
    WaitForStorage = 1,
    WaitForConsume = 2,
}

---@class XBenchViewModel : XRestaurantViewModel 工作台基类
---@field _Model XRestaurantModel 
---@field _OwnControl XRestaurantControl
---@field Data XRestaurantWorkbench 
---@field Property XRestaurantWorkbenchProperty 
local XBenchViewModel = XClass(XRestaurantViewModel, "XBenchViewModel")

function XBenchViewModel:UpdateViewModel()
    local productId = self:GetProductId()
    if XTool.IsNumberValid(productId) then
        self:AddProduct(productId)
    else
        self:DelProduct()
    end
    local characterId = self:GetCharacterId()
    if XTool.IsNumberValid(characterId) then
        self:AddStaff(characterId)
    else
        self:DelStaff()
    end
    self:UpdateTimeAndConsume()
end

--- 模拟生产
---@param workSecond number 生产间隔
--------------------------
function XBenchViewModel:Simulation(workSecond)
    if not self:IsRunning() then
        return
    end
    --未消耗材料
    if not self:IsConsume() then
        --材料不足
        if self:IsInsufficient() then
            self:DoPause()
            return
        end
        self:DoWork()
        self:PreviewConsume(1)
        self.Data:UpdateSimulationSecond(0)
    end
    
    local simulationTime = self:GetSimulationSecond()
    local tolerances = self:GetTolerances()
    if tolerances > 0 then
        simulationTime = simulationTime + tolerances
        self.Data:UpdateTolerances(0)
    end
    local produceNeedTime = self:GetProduceSingleTime()
    local subTime =  produceNeedTime - simulationTime
    if ((subTime >= 0 and subTime <= 1) or subTime > produceNeedTime) and self:IsFull() then

        --结算时，如果库存满了，会暂停在最后一秒
        self.Data:UpdateSimulationSecond(produceNeedTime - 1)
        self:UpdateCountDown(produceNeedTime)
        self:DoPause()
        return
    else
        --由暂停转为工作，这时的暂停为满的最后一秒
        if self:IsPause() then
            self.Data:UpdateSimulationSecond(produceNeedTime - 1)
        end
        self:DoWork()
    end

    -- workSecond 可能的值为 0，1
    simulationTime = simulationTime + workSecond
    local count = math.floor(simulationTime / produceNeedTime)
    if count > 0 then
        self:EndOfRound(simulationTime - (count * produceNeedTime))
    else
        self.Data:UpdateSimulationSecond(simulationTime)
    end
    self:UpdateCountDown(produceNeedTime)
end

--- 预先扣除材料
--------------------------
function XBenchViewModel:PreviewConsume(count)
    if self:IsConsume() then
        return
    end
    self:UpdateIsConsume(true)
end

--- 工作一个轮回结束
---@param tolerances number
--------------------------
function XBenchViewModel:EndOfRound(tolerances)
    self.Data:UpdateTolerances(tolerances)
    self:UpdateIsConsume(false)
    self.Data:UpdateUpdateTime(XTime.GetServerNowTimestamp())
    self.Data:UpdateSimulationSecond(0)
end

function XBenchViewModel:SwitchStaffOrProduct(oldCharId, newCharId, oldProductId, newProductId)
    --先将当前工作台上的角色放下去
    if XTool.IsNumberValid(oldCharId) and oldCharId ~= newCharId then
        local oldStaff = self._OwnControl:GetCharacter(oldCharId)
        oldStaff:Stop()
    end
    --将目标角色从工作台上放下去
    local newStaff = self._OwnControl:GetCharacter(newCharId)
    if newStaff and (not newStaff:IsFree()) then
        local workbenchId, areaType = newStaff:GetWorkBenchId(), newStaff:GetAreaType()
        local bench = self._OwnControl:GetWorkbench(areaType, workbenchId)
        bench:Stop()
    end
    --只有在运行中的才会处理，避免消耗异常
    if self:IsRunning() then
        self:Stop()
    end
    self:AddProduct(newProductId)
    self:AddStaff(newCharId)
    self:TryDoWork()
end

function XBenchViewModel:TryDoWork()
    if self:IsFree() then
        return false
    end

    if self:IsConsume() then
        self:DoWork()
    else
        self:DoPause()
        self:UpdateIsConsume(false)
    end
    local character = self:GetCharacter()
    if not character then
        return false
    end

    character:Produce(self:GetWorkbenchId(), self:GetAreaType())
    self:Simulation(0)

    return true
end

function XBenchViewModel:DoWork()
    if self:IsFree() then
        return
    end

    if self:IsWorking() then
        return
    end
    
    local character = self:GetCharacter()
    character:ReWork()
    self:ChangeStateAndMarkSort(XMVCA.XRestaurant.WorkState.Working)
end

function XBenchViewModel:DoPause()
    if self:IsFree() then
        return
    end

    if self:IsPause() then
        return
    end
    local character = self:GetCharacter()
    character:Pause()
    self:ChangeStateAndMarkSort(XMVCA.XRestaurant.WorkState.Pause)
end

function XBenchViewModel:DoFree()
    if self:GetClientState() == XMVCA.XRestaurant.WorkState.Free then
        return
    end
    self:ChangeStateAndMarkSort(XMVCA.XRestaurant.WorkState.Free)
end

--- 手动停止工作
--------------------------
function XBenchViewModel:Stop()
    self:DelProduct()
    self:DelStaff()
end

function XBenchViewModel:ChangeStateAndMarkSort(state)
    self.Data:UpdateClientState(state)
    self._OwnControl:SetAreaSort(self:GetAreaType(), true)
end

function XBenchViewModel:AddProduct(productId)
    productId = productId or 0
    self.Data:UpdateProductId(productId)
end

function XBenchViewModel:DelProduct()
    local characterId = self:GetCharacterId()

    self.Data:UpdateProductId(0)
    self.Data:UpdateProgress(0)

    if XTool.IsNumberValid(characterId) then
        local staff = self._OwnControl:GetCharacter(characterId)
        if staff:IsFree() or staff:IsInWorkBench(self:GetAreaType(), self:GetWorkbenchId()) then
            staff:Stop()
        end
    end
    self:DoFree()
end

function XBenchViewModel:AddStaff(characterId)
    characterId = characterId or 0
    self.Data:UpdateCharacterId(characterId)
end

function XBenchViewModel:DelStaff()
    local characterId = self:GetCharacterId()
    self.Data:UpdateCharacterId(0)
    self.Data:UpdateProgress(0)

    if XTool.IsNumberValid(characterId) then
        local staff = self._OwnControl:GetCharacter(characterId)
        if staff:IsFree() or staff:IsInWorkBench(self:GetAreaType(), self:GetWorkbenchId()) then
            staff:Stop()
        end
    end
    self:DoFree()
end

function XBenchViewModel:UpdateTimeAndConsume()
    local updateTime, sState = self:GetUpdateTime(), self:GetServerState()
    if updateTime <= 0 or not (self:IsCharacterValid() and self:IsProductValid()) then
        self.Data:UpdateUpdateTime(0)
        self.Data:UpdateSimulationSecond(0)
        self:UpdateIsConsume(false)
        return
    end
    
    local produceNeedTime = self:GetProduceSingleTime()
    local now = XTime.GetServerNowTimestamp()
    local subTime = math.max(0, now - updateTime)

    if sState == ServerWorkState.WaitForConsume then --等待材料满足
        self.Data:UpdateSimulationSecond(0)
        self:UpdateIsConsume(false)
    elseif sState == ServerWorkState.Normal then --正常工作状态
        self:UpdateIsConsume(true)
        self.Data:UpdateSimulationSecond(math.min(subTime, produceNeedTime))
    elseif sState == ServerWorkState.WaitForStorage then --等待库存消耗
        self:UpdateIsConsume(true)
        self.Data:UpdateSimulationSecond(math.min(subTime, produceNeedTime - 1))
    end
end

function XBenchViewModel:UpdateCountDown(produceNeedTime)
    local totalTime = self:GetSimulationSecond() + self:GetTolerances()
    local countDown = math.max(0, produceNeedTime - totalTime)
    local progress = math.min(1, totalTime / produceNeedTime)
    self.Data:UpdateCountDown(countDown)
    self.Data:UpdateProgress(progress)
end

function XBenchViewModel:UpdateIsConsume(value) 
    self.Data:UpdateIsConsume(value)
end

function XBenchViewModel:GetProductId()
    return self.Data:GetProductId()
end

function XBenchViewModel:GetCharacterId()
    return self.Data:GetCharacterId()
end

function XBenchViewModel:GetWorkbenchId()
    return self.Data:GetWorkbenchId()
end

function XBenchViewModel:GetAreaType()
    return self.Data:GetAreaType()
end

--- 获取加速提示与加速道具提示
---@return string, table
--------------------------
function XBenchViewModel:GetAccelerateContentAndItemData(accelerateTime)
end

--- 材料不足提示
---@return string, string
--------------------------
function XBenchViewModel:GetInsufficientTitleAndContent()
end

--- 库存满提示
---@return string, string
--------------------------
function XBenchViewModel:GetFullTitleAndContent()
    local key = "StorageFullTip"
    local title = self._Model:GetClientConfigValue(key, 3)
    local content = self._Model:GetClientConfigValue(key, 4)
    local productName = self:GetProductName()
    content = XUiHelper.ReplaceTextNewLine(string.format(content, productName, productName))
    
    return title, content
end

--- 终止工作 提示标题，提示文案
---@return string, string
--------------------------
function XBenchViewModel:GetStopTipTitleAndContent()
    return "", ""
end

--- 工作台优先级
---@return number
--------------------------
function XBenchViewModel:GetWorkPriority()
    if not self:IsProductValid() then
        return 0
    end
    local product = self:GetProduct()
    return product and product:GetPriority() or 0
end

--- 检查能否加速
---@return boolean
--------------------------
function XBenchViewModel:CheckCanAccelerate()
    --使用达到上限
    if self._Model:IsAccelerateUpperLimit() then
        return false
    end
    --道具不够
    if self._Model:GetAccelerateCount() <= 0 then
        return false
    end
    --未工作
    if not self:IsWorking() then
        return false
    end
    --仓库满或材料不足
    if self:IsFull() or self:IsInsufficient() then
        return false
    end
    return true
end

function XBenchViewModel:ToString()
    if self._ObjString then
        return self._ObjString
    end
    self._ObjString = self._Model:GetCameraAuxiliaryTemplate(self:GetAreaType()) .. ", Index:" .. self:GetWorkbenchId()
    return self._ObjString
end

--- 生产单个需要的时间（s）
---@return number
--------------------------
function XBenchViewModel:GetBaseProduceSpeed()
    return 0
end

function XBenchViewModel:GetProductiveness(timeUnit)
    timeUnit = timeUnit or XMVCA.XRestaurant.TimeUnit.Hour
    if self:IsFree() then
        return 0
    end
    local produceNeedTime = self:GetProduceSingleTime()
    if produceNeedTime == 0 then
        return timeUnit
    end
    return self._OwnControl:GetAroundValue(timeUnit / produceNeedTime, XMVCA.XRestaurant.Digital.One)
end

--- 消耗力
---@param productId number 产品Id
---@param timeUnit number 生产单位时间，默认为小时
---@return number
--------------------------
function XBenchViewModel:GetConsumption(productId, timeUnit)
    return 0
end

--- 生产单个产品需要的时间，子类去实现
---@return number
--------------------------
function XBenchViewModel:GetProduceSingleTime()
    return 0
end

--- 产品排序
---@return XRestaurantProductVM[]
--------------------------
function XBenchViewModel:SortProduct()
    XLog.Error("子类未实现该方法")
end

--- 获取产品
---@return XRestaurantProductVM
--------------------------
function XBenchViewModel:GetProduct()
    if not self:IsProductValid() then
        return
    end
    return self._OwnControl:GetProduct(self:GetAreaType(), self:GetProductId())
end

--- 工作台上的员工
---@return XRestaurantStaffVM
--------------------------
function XBenchViewModel:GetCharacter()
    if not self:IsCharacterValid() then
        return
    end
    return self._OwnControl:GetCharacter(self:GetCharacterId())
end

--- 产品名
---@return string
--------------------------
function XBenchViewModel:GetStaffName()
    if not self:IsCharacterValid() then
        return ""
    end
    local character = self:GetCharacter()
    if not character then
        return ""
    end
    return character:GetName()
end

--- 工作台所处区域的Buff
---@return XRestaurantBuffVM
--------------------------
function XBenchViewModel:GetBuff()
    return self._OwnControl:GetAreaBuff(self:GetAreaType())
end

--- 产品名
---@return string
--------------------------
function XBenchViewModel:GetProductName()
    if not self:IsProductValid() then
        return ""
    end
    local product = self:GetProduct()
    if not product then
        return ""
    end
    return product:GetName()
end

--- 产品数
---@return number
--------------------------
function XBenchViewModel:GetProductCount()
    if not self:IsProductValid() then
        return ""
    end
    local product = self:GetProduct()
    if not product then
        return ""
    end
    return product:GetCount()
end

--- 产品图标
---@return string
--------------------------
function XBenchViewModel:GetProductIcon()
    if not self:IsProductValid() then
        return ""
    end
    local product = self:GetProduct()
    if not product then
        return ""
    end
    return product:GetProductIcon()
end

function XBenchViewModel:GetServerState()
    return self.Data:GetServerState()
end

function XBenchViewModel:GetClientState()
    return self.Data:GetClientState()
end

function XBenchViewModel:GetUpdateTime()
    return self.Data:GetUpdateTime()
end

function XBenchViewModel:GetSimulationSecond()
    return self.Data:GetSimulationSecond()
end

function XBenchViewModel:GetTolerances()
    return self.Data:GetTolerances()
end

function XBenchViewModel:IsCharacterValid()
    return XTool.IsNumberValid(self:GetCharacterId())
end

function XBenchViewModel:IsProductValid()
    return XTool.IsNumberValid(self:GetProductId())
end

function XBenchViewModel:IsConsume()
    return self.Data:IsConsume()
end

function XBenchViewModel:GetWorkProgress()
    return self.Data:GetProgress()
end

function XBenchViewModel:GetCountDown()
    return self.Data:GetCountDown()
end

function XBenchViewModel:CheckHasBuff()
    local buff = self:GetBuff()
    if not buff then
        return false
    end
    return buff:CheckBenchEffect(self:GetAreaType(), self:GetCharacterId(), self:GetProductId())
end

function XBenchViewModel:GetAddition()
    if self:IsFree() then
        return 0
    end
    return self:GetCharacterAddition() + self:GetBuffAddition()
end

function XBenchViewModel:GetCharacterAddition()
    if self:IsFree() then
        return 0
    end
    local character = self:GetCharacter()
    if not character then
        return 0
    end
    return character:GetSkillAddition(self:GetAreaType(), self:GetProductId())
end

function XBenchViewModel:GetBuffAddition()
    if self:IsFree() then
        return 0
    end
    local buff = self:GetBuff()
    if not buff then
        return 0
    end
    return buff:GetEffectAddition(self:GetAreaType(), self:GetCharacterId(), self:GetProductId())
end

--- 工作台上的产品是否已满
---@return boolean
--------------------------
function XBenchViewModel:IsFull()
    if not self:IsProductValid() then
        return false
    end
    local product = self:GetProduct()
    return product and product:IsFull() or false
end

--- 材料不足
---@return boolean
--------------------------
function XBenchViewModel:IsInsufficient()
    return false
end

--- 工作台是否运行
---@return boolean
--------------------------
function XBenchViewModel:IsRunning()
    return self:IsWorking() or self:IsPause()
end

--- 是否暂停
---@return boolean
--------------------------
function XBenchViewModel:IsPause()
    return self:GetClientState() == XMVCA.XRestaurant.WorkState.Pause
end

--- 是否工作中
---@return boolean
--------------------------
function XBenchViewModel:IsWorking()
    return self:GetClientState() == XMVCA.XRestaurant.WorkState.Working
end

--- 是否空闲
---@return boolean
--------------------------
function XBenchViewModel:IsFree()
    return not self:IsCharacterValid() or not self:IsProductValid()
end

return XBenchViewModel