

--服务端工作状态
local ServerWorkState = {
    Normal = 0,
    WaitForStorage = 1,
    WaitForConsume = 2,
}


---@class XRestaurantWorkBench : XDataEntityBase 工作台基类
---@field protected _Id number 下标，或者Id
---@field protected _ProductId number 产品Id
---@field protected _CharacterId number 员工Id
---@field protected _AreaType number 区域类型
---@field protected _State XRestaurantConfigs.WorkState 工作状态
---@field protected _UpdateTime number 扣除材料时间
---@field protected _SimulationSecond number 模拟时长
---@field protected _Progress number 当前进度
---@field protected _CountDown number 倒计时
---@field protected _Tolerances number 工作误差，由于员工升级等造成
---@field protected _IsConsume boolean 是否已经消耗原材料
local XRestaurantWorkBench = XClass(XDataEntityBase, "XRestaurantWorkBench")

local default = {
    _Id = 0,
    _ProductId = 0,
    _CharacterId = 0,
    _AreaType = XRestaurantConfigs.AreaType.IngredientArea,
    _State = XRestaurantConfigs.WorkState.Free,
    _UpdateTime = 0,
    _SimulationSecond = 0,
    _Progress = 0,
    _CountDown = 0,
    _Tolerances = 0,
    _IsConsume = false,
}

function XRestaurantWorkBench:Ctor(id)
    self:Init(default, id)
end

function XRestaurantWorkBench:InitData(id)
    self:SetProperty("_Id", id)
end

function XRestaurantWorkBench:OnNotify(notifyData)
    local productId, characterId, state = notifyData.ProductId, notifyData.CharacterId, notifyData.State
    if XTool.IsNumberValid(productId) then
        self:AddProduct(productId)
    else
        self:DelProduct()
    end
    
    if XTool.IsNumberValid(characterId) then
        self:AddStaff(characterId)
    else
        self:DelStaff()
    end

    local updateTime = notifyData.UpdateTime
    self:UpdateTimeAndConsume(updateTime, state)
end

function XRestaurantWorkBench:OnWorking()
    if self:IsFree() then
        return
    end
    if self:IsWorking() then
        return
    end
    
    local character = self:GetCharacter()
    character:ReWork()
    self:ChangeStateAndMarkSort(XRestaurantConfigs.WorkState.Working)
end

function XRestaurantWorkBench:OnPause()
    if self:IsFree() then
        return
    end
    if self:IsPause() then
        return
    end
    
    local character = self:GetCharacter()
    character:Pause()
    self:ChangeStateAndMarkSort(XRestaurantConfigs.WorkState.Pause)
end

function XRestaurantWorkBench:OnFree()
    if self._State == XRestaurantConfigs.WorkState.Free then
        return
    end
    self:ChangeStateAndMarkSort(XRestaurantConfigs.WorkState.Free)
end

function XRestaurantWorkBench:UpdateCountDown(produceNeedTime)
    local totalTime = self._SimulationSecond + self._Tolerances
    local countDown = math.max(0, produceNeedTime - totalTime)
    local progress = math.min(1, totalTime / produceNeedTime)
    self:SetProperty("_CountDown", countDown)
    self:SetProperty("_Progress", progress)
end

--- 更新扣除材料时间
---@param updateTime number
---@param state number 服务器状态
---@return void
--------------------------
function XRestaurantWorkBench:UpdateTimeAndConsume(updateTime, state)
    if updateTime <= 0 or not (XTool.IsNumberValid(self._CharacterId)
            and XTool.IsNumberValid(self._ProductId)) then
        self:SetProperty("_UpdateTime", 0)
        self:SetProperty("_SimulationSecond", 0)
        self:SetProperty("_IsConsume", false)
        return
    end

    local produceNeedTime = self:GetProduceSingleTime()
    self:SetProperty("_UpdateTime", updateTime)
    local now = XTime.GetServerNowTimestamp()
    local subTime = math.max(0, now - updateTime)

    if state == ServerWorkState.WaitForConsume then --等待材料满足
        self:SetProperty("_SimulationSecond", 0)
        self:SetProperty("_IsConsume", false)
    elseif state == ServerWorkState.Normal then --正常工作状态
        self:SetProperty("_IsConsume", true)
        self:SetProperty("_SimulationSecond", math.min(subTime, produceNeedTime))
    elseif state == ServerWorkState.WaitForStorage then --等待库存消耗
        self:SetProperty("_IsConsume", true)
        self:SetProperty("_SimulationSecond", math.min(subTime, produceNeedTime - 1))
    end
end

--- 产品排序
---@return XRestaurantProduct[] 排序后的产品
--------------------------
function XRestaurantWorkBench:SortProduct()
    return {}
end

--- 开始工作, 此接口由服务端更新数据后调用
--------------------------
function XRestaurantWorkBench:TryWorking()
    if self:IsFree() then
        return false
    end

    if self._IsConsume then
        self:OnWorking()
    else
        self:OnPause()
        self:SetProperty("_IsConsume", false)
    end
    local character = self:GetCharacter()
    if character:IsWorking()
            and character:GetProperty("_WorkBenchId") ~= self._Id then
        return false
    end
    character:Produce(self._Id, self._AreaType)
    self:Simulation(0)
    return true
end

--- 工作台添加员工
---@param characterId number 员工id
---@return void
--------------------------
function XRestaurantWorkBench:AddStaff(characterId)
    characterId = characterId or 0
    self:SetProperty("_CharacterId", characterId)
end

--- 工作台添加产品
---@param productId number 产品Id
---@return void
--------------------------
function XRestaurantWorkBench:AddProduct(productId)
    productId = productId or 0
    self:SetProperty("_ProductId", productId)
end

--- 移除员工
---@return void
--------------------------
function XRestaurantWorkBench:DelStaff()
    local characterId = self._CharacterId
    self:SetProperty("_CharacterId", 0)
    self:SetProperty("_Progress", 0)
    self:SetProperty("_IsConsume", false)

    if XTool.IsNumberValid(characterId) then
        local viewModel = XDataCenter.RestaurantManager.GetViewModel()
        local staff = viewModel:GetStaffViewModel(characterId)
        staff:Stop()
    end
    self:OnFree()
end

--- 移除产品
---@return void
--------------------------
function XRestaurantWorkBench:DelProduct()
    local characterId = self._CharacterId
    self:SetProperty("_ProductId", 0)
    self:SetProperty("_Progress", 0)
    self:SetProperty("_IsConsume", false)

    if XTool.IsNumberValid(characterId) then
        local viewModel = XDataCenter.RestaurantManager.GetViewModel()
        local staff = viewModel:GetStaffViewModel(characterId)
        staff:Pause()
    end
    self:OnFree()
end

--- 手动停止工作
--------------------------
function XRestaurantWorkBench:Stop()
    self:DelProduct()
    self:DelStaff()
end

--- 产品图标
---@return string
--------------------------
function XRestaurantWorkBench:GetProductIcon()
end

--- 工作台上的产品是否已满
---@return boolean
--------------------------
function XRestaurantWorkBench:IsFull()
    if not XTool.IsNumberValid(self._ProductId) then
        return false
    end
    local product = self:GetProduct()
    return product and product:IsFull() or false
end

--- 材料不足    
---@return boolean
--------------------------
function XRestaurantWorkBench:IsInsufficient()
    return false
end

--- 工作台是否运行
---@return boolean
--------------------------
function XRestaurantWorkBench:IsRunning()
    return self:IsWorking() or self:IsPause()
end

--- 是否暂停
---@return boolean
--------------------------
function XRestaurantWorkBench:IsPause()
    return self._State == XRestaurantConfigs.WorkState.Pause
end

--- 是否工作中
---@return boolean
--------------------------
function XRestaurantWorkBench:IsWorking()
    return self._State == XRestaurantConfigs.WorkState.Working
end

--- 是否空闲
---@return boolean
--------------------------
function XRestaurantWorkBench:IsFree()
    return  not XTool.IsNumberValid(self._CharacterId) or not XTool.IsNumberValid(self._ProductId)
end

--- 员工名
---@return string
--------------------------
function XRestaurantWorkBench:GetStaffName()
    if not XTool.IsNumberValid(self._CharacterId) then
        return ""
    end
    local character = self:GetCharacter()
    return character:GetName()
end

--- 产品数
---@return number
--------------------------
function XRestaurantWorkBench:GetProductCount()
    if not XTool.IsNumberValid(self._ProductId) then
        return ""
    end
    local product = self:GetProduct()
    return product and product:GetProperty("_Count") or 0
end

--- 产品名
---@return
--------------------------
function XRestaurantWorkBench:GetProductName()
    if not XTool.IsNumberValid(self._ProductId) then
        return ""
    end
    local product = self:GetProduct()
    return product and product:GetProperty("_Name") or "nil"
end

--- 预先扣除材料
--------------------------
function XRestaurantWorkBench:PreviewConsume(count)
    if self._IsConsume then
        return
    end
    self:SetProperty("_IsConsume", true)
end

--- 生产单个需要的时间（s）
---@return number
--------------------------
function XRestaurantWorkBench:GetBaseProduceSpeed()
    return 0
end

--- 获取生产力
---@param timeUnit number 生产单位时间，默认为小时
---@return number
--------------------------
function XRestaurantWorkBench:GetProductiveness(timeUnit)
    timeUnit = timeUnit or XRestaurantConfigs.TimeUnit.Hour
    if self:IsFree() then
        return 0
    end
    local produceNeedTime = self:GetProduceSingleTime()
    if produceNeedTime == 0 then
        return timeUnit
    end
    return XRestaurantConfigs.GetAroundValue(timeUnit / produceNeedTime, XRestaurantConfigs.Digital.One)
end

--- 消耗力
---@param productId number 产品Id
---@param timeUnit number 生产单位时间，默认为小时
---@return number
--------------------------
function XRestaurantWorkBench:GetConsumption(productId, timeUnit)
    return 0
end

--- 生产单个所需时间(S)
---@return number
--------------------------
function XRestaurantWorkBench:GetProduceSingleTime()
    return 0
end

--- 模拟生产
---@param workSecond number 模拟间隔
--------------------------
function XRestaurantWorkBench:Simulation(workSecond)
    if not self:IsRunning() then
        return
    end

    -- 未消耗材料
    if not self._IsConsume then
        --材料不足
        if self:IsInsufficient() then
            self:OnPause()
            --设置工作时间为0
            return
        end
        self:OnWorking()
        self:PreviewConsume(1)
        --消耗材料，开始模拟计时
        self:SetProperty("_SimulationSecond", 0)
    end

    local simulationTime = self._SimulationSecond
    if self._Tolerances > 0 then
        simulationTime = simulationTime + self._Tolerances
        self:SetProperty("_Tolerances", 0)
    end
    local produceNeedTime = self:GetProduceSingleTime()
    local subTime =  produceNeedTime - simulationTime
    --正常跑到倒计时最后一秒 或者 角色升级增加模拟时间
    if ((subTime >= 0 and subTime <= 1) or subTime > produceNeedTime) 
            and self:IsFull() then
        --结算时，如果库存满了，会暂停在最后一秒
        self:SetProperty("_SimulationSecond", produceNeedTime - 1)
        self:UpdateCountDown(produceNeedTime)
        self:OnPause()
        return
    else
        --由暂停转为工作，这时的暂停为满的最后一秒
        if self:IsPause() then
            self:SetProperty("_SimulationSecond", produceNeedTime - 1)
        end
        self:OnWorking()
    end
    
    -- workSecond 可能的值为 0，1
    simulationTime = simulationTime + workSecond
    local count = math.floor(simulationTime / produceNeedTime)
    if count > 0 then
        self:EndOfRound(simulationTime - (count * produceNeedTime))
    else
        self:SetProperty("_SimulationSecond", simulationTime)
    end
    self:UpdateCountDown(produceNeedTime)
end

--- 工作进度
---@return number
--------------------------
function XRestaurantWorkBench:GetWorkProgress()
    return self._Progress
end

--- 倒计时
---@return number
--------------------------
function XRestaurantWorkBench:GetCountDown()
    return self._CountDown
end

--- 工作台角色
---@return XRestaurantStaff
--------------------------
function XRestaurantWorkBench:GetCharacter()
    local characterId = self._CharacterId
    if not XTool.IsNumberValid(characterId) then
        return
    end
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    return viewModel:GetStaffViewModel(characterId)
end

function XRestaurantWorkBench:GetBuff()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    return viewModel:GetAreaBuff(self._AreaType)
end

--- 工作台产品
---@return XRestaurantProduct
--------------------------
function XRestaurantWorkBench:GetProduct()
    local productId = self._ProductId
    if not XTool.IsNumberValid(productId) then
        return
    end
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    return viewModel:GetProduct(self._AreaType, productId)
end

--- 工作一个轮回结束
---@return boolean
--------------------------
function XRestaurantWorkBench:EndOfRound(tolerances)
    self:SetProperty("_Tolerances", tolerances)
    self:SetProperty("_IsConsume", false)
    self:SetProperty("_UpdateTime", XTime.GetServerNowTimestamp())
    self:SetProperty("_SimulationSecond", 0)
end

--- 获取加速提示与加速道具提示
---@return string, table
--------------------------
function XRestaurantWorkBench:GetAccelerateContentAndItemData(accelerateTime)
end

--- 材料不足提示
---@return string, string
--------------------------
function XRestaurantWorkBench:GetInsufficientTitleAndContent()
end

--- 库存满提示
---@return string, string
--------------------------
function XRestaurantWorkBench:GetFullTitleAndContent()
    local title = XRestaurantConfigs.GetClientConfig("StorageFullTip", 3)
    local content = XRestaurantConfigs.GetClientConfig("StorageFullTip", 4)
    local productName = self:GetProductName()
    content = XUiHelper.ReplaceTextNewLine(string.format(content, productName, productName))
    return title, content
end

--- 终止工作 提示标题，提示文案
---@return string, string
--------------------------
function XRestaurantWorkBench:GetStopTipTitleAndContent()
    return "", ""
end

--- 工作台优先级
---@return number
--------------------------
function XRestaurantWorkBench:GetWorkPriority()
    return 0
end

--- 检查能否加速
---@return boolean
--------------------------
function XRestaurantWorkBench:CheckCanAccelerate()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    --使用达到上限
    if viewModel:IsAccelerateUpperLimit() then
        return false
    end
    --道具不够
    if viewModel:GetAccelerateCount() <= 0 then
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

function XRestaurantWorkBench:ToString()
    return XRestaurantConfigs.GetCameraAuxiliaryAreaName(self._AreaType) .. ", Index:" ..self._Id
end

function XRestaurantWorkBench:ChangeStateAndMarkSort(state)
    self:SetProperty("_State", state)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    viewModel:MarkNewSort(self._AreaType)
end

--- 当前工作台是否拥有Buff
---@return boolean
--------------------------
function XRestaurantWorkBench:CheckHasBuff()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local buff = viewModel:GetAreaBuff(self._AreaType)
    if not buff then
        return false
    end
    return buff:CheckBenchEffect(self._AreaType, self._CharacterId, self._ProductId)
end

function XRestaurantWorkBench:GetAddition()
    if self:IsFree() then
        return 0
    end
    local character = self:GetCharacter()
    --技能加成
    local addition = character:GetSkillAddition(self._AreaType, self._ProductId)
    
    return addition + self:GetBuffAddition()
end

--- 获取buff加成，仅用于区域Buff
---@return number
--------------------------
function XRestaurantWorkBench:GetBuffAddition()
    if self:IsFree() then
        return 0
    end
    local buff = self:GetBuff()
    if not buff then
        return 0
    end
    return buff:GetEffectAddition(self._AreaType, self._CharacterId, self._ProductId)
end

return XRestaurantWorkBench