
---@type UnityEngine.Vector3
local CsVector3 = CS.UnityEngine.Vector3
local CsRandom = CS.UnityEngine.Random

---@type XRestaurantIScene
local XRestaurantIScene = require("XModule/XRestaurant/XGameObject/XRestaurantIScene")
local XRestaurantRole = require("XModule/XRestaurant/XGameObject/XRestaurantRole")
local XRestaurantCamera = require("XModule/XRestaurant/XGameObject/XRestaurantCamera")
local XRestaurantSignNpc = require("XModule/XRestaurant/XGameObject/XRestaurantSignNpc")
local XRestaurantOrderNpc = require("XModule/XRestaurant/XGameObject/XRestaurantOrderNpc")
local XRestaurantCustomer = require("XModule/XRestaurant/XGameObject/XRestaurantCustomer")


--屏幕坐标到本地坐标转换倍率
local CameraXRatio = 200

---@class XRestaurantRoom : XRestaurantIScene 餐厅房间
---@field _RestaurantCamera XRestaurantCamera
---@field _SceneSetting XSceneSetting
---@field _WalkAbleFloor UnityEngine.Transform
---@field _BlockBoard UnityEngine.Transform
---@field _RandomPoints UnityEngine.Transform[]
---@field _PointsMap table<number, number> 角色Id索引点下标
---@field _CashierModel UnityEngine.Transform
---@field _NavMeshSurface UnityEngine.AI.NavMeshSurface
---@field _CharacterMap table<number, XRestaurantRole> 角色模型
---@field _WorkBenchModel table<number, table<number, CS.XRestaurantWorkBench>> 工作台模型
---@field _UiGrid3DPivot UnityEngine.Vector2
---@field _SignNpc XRestaurantSignNpc
---@field _OrderNpc XRestaurantOrderNpc
---@field _DragBeginListener function[]
---@field _DragEndListener function[]
---@field _StartPoint UnityEngine.Vector3
---@field _StartPoint UnityEngine.Vector3
---@field _RedPoint UnityEngine.Vector3
---@field _GreenPoint UnityEngine.Vector3
---@field _RandomArea UnityEngine.Bounds
---@field _CustomerList XRestaurantCustomer[]
local XRestaurantRoom = XClass(XRestaurantIScene, "XRestaurantRoom")

function XRestaurantRoom:Init()
    self._RestaurantCamera = XRestaurantCamera.New()
    self._CharacterMap = {}
    self._DragBeginListener = {}
    self._CustomerList = {}
    self._DragEndListener = {}
    self._UiGrid3DPivot = CS.UnityEngine.Vector2(0.5, 0.5)
    
    self._NextLoadCustomer = 0
    self._CustomerIds = XRestaurantConfigs.GetCustomerNpcIds()
    self._CustomerTotal = #self._CustomerIds
    
    local min, max = XRestaurantConfigs.CustomerProperty()
    self._RandomMin = min
    self._RandomMax = max
end

--- 摄像机数据以及模型
---@return XRestaurantCamera
--------------------------
function XRestaurantRoom:GetCameraModel()
    return self._RestaurantCamera
end

--- 摄像机停止移动，回弹到对应区域
---@param beginCb function
---@param endCb function
---@return void
--------------------------
function XRestaurantRoom:OnStopMoveCamera(beginCb, endCb)
    self._RestaurantCamera:StopCamera(beginCb, endCb)
end

function XRestaurantRoom:SetAreaType(type)
    self._RestaurantCamera:SetAreaType(type)
end

function XRestaurantRoom:GetAssetPath()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local level = viewModel:GetProperty("_Level")
    level = CS.UnityEngine.Mathf.Clamp(level, XRestaurantConfigs.LevelRange.Min, XRestaurantConfigs.LevelRange.Max)
    return XRestaurantConfigs.GetRestaurantScenePrefab(level)
end

function XRestaurantRoom:OnLoadSuccess()
    if not XTool.UObjIsNil(self._Camera) then
        self:TryDestroy(self._Camera)
    end
    self:LoadGlobalSO()
    self:InitCamera()
    self:InitNavMesh()
    self:InitWorkBench()
    self:InitCustomer()
    self:InitSceneSetting()
    
    self._CashierModel = self._Transform:Find("GroupBase/@Furniture/03/BiankaCounter001")
    self._CharacterRoot = self._Transform:Find("GroupBase/@Character")
    if XTool.UObjIsNil(self._CharacterRoot) then
        local groupBase = self._Transform:Find("GroupBase")
        local go = CS.UnityEngine.GameObject("@Character")
        go.transform:SetParent(groupBase, false)
        self:TryResetTransform(go.transform)
        self._CharacterRoot = go.transform
    end
    
    self._BlockBoard = self._Transform:Find("GroupBase/@Furniture/03/Coffeeblackboard001(Clone)")
    
    local floor = self._Transform:Find("GroupBase/@Floor")
    if not XTool.UObjIsNil(floor) then
        floor.gameObject:SetLayerRecursively(CS.UnityEngine.LayerMask.NameToLayer(HomeSceneLayerMask.Room))
        local inputHandler = floor.gameObject:GetComponent(typeof(CS.XGoInputHandler))
        if not inputHandler then
            inputHandler = floor.gameObject:AddComponent(typeof(CS.XGoInputHandler))
        end
        inputHandler:AddBeginDragListener(handler(self, self.OnBeginDrag))
        inputHandler:AddDragListener(handler(self, self.OnDrag))
        inputHandler:AddEndDragListener(handler(self, self.OnEndDrag))
    end
    --if not self.Timer then
    --    self.Timer = XScheduleManager.ScheduleForever(function() 
    --        self:Simulation(XTime.GetServerNowTimestamp())
    --    end, XScheduleManager.SECOND)
    --end
    
end

function XRestaurantRoom:InitSceneSetting()
    self._SceneSetting = self._Transform:GetComponent("XSceneSetting")
    if self._SceneSetting then
        self._SceneSetting.enabled = true
        CS.XGraphicManager.BindScene(self._SceneSetting)
    end
end

function XRestaurantRoom:LoadGlobalSO()
    --场景加载完
    XUiHelper.SetSceneType(CS.XSceneType.Dormitory)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local level = viewModel:GetProperty("_Level")
    local path = XRestaurantConfigs.GetGlobalIllumination(level)
    local resource = CS.XResourceManager.Load(path)
    CS.XTool.WaitCoroutine(resource, function()
        if not (resource and resource.Asset) then
            XLog.Error("restaurant load resource error: asset path = " .. path)
            return
        end
        self._SOResource = resource
        CS.XGlobalIllumination.SetGlobalIllumSO(resource.Asset)
    end)
end

function XRestaurantRoom:InitCamera()
    local obj = self._GameObject.transform:Find("Camera")
    if XTool.UObjIsNil(obj) then
        XLog.Error(self._GameObject.name .. " not found camera, please check scene!!!")
        return
    end
    self._RestaurantCamera:SetGameObject(obj)
end

function XRestaurantRoom:InitNavMesh()
    local furniture = self._Transform:Find("GroupBase/@Furniture")
    if not XTool.UObjIsNil(furniture) then
        CS.XNavMeshUtility.AddNavMeshObstacleSizeByCollider(furniture.gameObject)
    end
    local path = self._Transform:Find("GroupBase/@Path")
    self._RandomPoints = {}
    self._PointsMap = {}
    if not XTool.UObjIsNil(path) then
        for i = 0, path.childCount - 1 do
            local transform = path:GetChild(i)
            transform.gameObject.name = "Point" .. i + 1
            table.insert(self._RandomPoints, transform)
        end
    end
    self._WalkAbleFloor = self._GameObject.transform:Find("GroupBase/@Floor")

    if not XTool.UObjIsNil(self._WalkAbleFloor) then
        self._NavMeshSurface = CS.XNavMeshUtility.SetNavMeshSurfaceAndBuild(self._WalkAbleFloor.gameObject)
    end
end

function XRestaurantRoom:InitWorkBench()
    self._WorkBenchModel = { }
    local workBenchRoot = self._Transform:Find("GroupBase/@Furniture")
    if XTool.UObjIsNil(workBenchRoot) then
        XLog.Error("init restaurant work bench error, not found GroupBase/@Furniture ")
        return
    end
    
    local init = function(components) 
        local map = {}
        if not components then
            return map
        end
        for i = 0, components.Length - 1 do
            local component = components[i]
            if component then
                map[component.Index] = component
            end
        end
        return map
    end
    local list
    list = workBenchRoot:Find("01"):GetComponentsInChildren(typeof(CS.XRestaurantWorkBench))
    self._WorkBenchModel[XRestaurantConfigs.AreaType.IngredientArea] = init(list)
    
    list = workBenchRoot:Find("02"):GetComponentsInChildren(typeof(CS.XRestaurantWorkBench))
    self._WorkBenchModel[XRestaurantConfigs.AreaType.FoodArea] = init(list)
    
    list = workBenchRoot:Find("03"):GetComponentsInChildren(typeof(CS.XRestaurantWorkBench))
    self._WorkBenchModel[XRestaurantConfigs.AreaType.SaleArea] = init(list)
end

function XRestaurantRoom:InitCustomer()
    local customer = self._Transform:Find("GroupBase/@NpcCustomer")
    local start = customer:Find("Start")
    self._StartPoint = start.position
    local green = customer:Find("Green")
    self._GreenPoint = green.position
    local red =  customer:Find("Red")
    self._RedPoint = red.position
    
    self._PointMin = customer:Find("Point1").position
    self._PointMax = customer:Find("Point2").position

    local level = 0
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    if viewModel then
        level = viewModel:GetProperty("_Level")
    end
    self._MaxCustomerCount = XRestaurantConfigs.GetCustomerLimit(level)
    if self._MaxCustomerCount > #self._CustomerIds then
        XLog.Error("最大加载顾客数大于配置的不重复顾客数，由于不放回机制，将会导致死循环！！！")

        self._MaxCustomerCount = #self._CustomerIds
    end
    
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    --不在营业期，不加载
    if not viewModel or not viewModel:IsInBusiness() then
        self._MaxCustomerCount = 0
    end
end

function XRestaurantRoom:GetObjName()
    local level = 0
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    if viewModel then
        level = viewModel:GetProperty("_Level")
    end
    return string.format("Restaurant%s", level)
end

function XRestaurantRoom:Release()
    self.Super.Release(self)
    self._RestaurantCamera:Release()
    for _, role in pairs(self._CharacterMap or {}) do
        role:Release()
    end
    if self._SOResource then
        self._SOResource:Release()
        self._SOResource = nil
    end

    self._CharacterMap = {}
    self._CustomerList = {}
    self._CashierModel = nil
    self._CharacterRoot = nil
    self._SceneSetting = nil
    self._OrderNpc = nil
    self._SignNpc = nil
    self._WorkBenchModel = {}
    self._DragBeginListener = {}
    self._DragEndListener = {}
    
    self._NextLoadCustomer = 0

    --if self.Timer then
    --    XScheduleManager.UnSchedule(self.Timer)
    --    self.Timer = nil
    --end
    --场景销毁
    XUiHelper.SetSceneType(CS.XSceneType.Ui)
end

function XRestaurantRoom:StopBusiness()
    for _, char in pairs(self._CharacterMap) do
        char:Hide()
    end

    ----商店关门了，顾客全赶出去，合理
    --for _, customer in pairs(self._CustomerList) do
    --    customer:Dispose()
    --end
    --self._NextLoadCustomer = 0

    if self:SignNpcExist() then
        self._SignNpc:Hide()
    end

    if self:OrderNpcExist() then
        self._OrderNpc:Hide()
    end

    --不允许滑动
    self._DragBeginListener = {}
    self._DragEndListener = {}
    
    self._RestaurantCamera:OnExitBusiness()
end

function XRestaurantRoom:StartBusiness()
    self._RestaurantCamera:OnEnterBusiness()
end

--- 加载角色模型
---@param characterId number 角色Id
---@param onLoadCb function 加载成功回调
---@return void
--------------------------
function XRestaurantRoom:LoadCharacter(characterId, onLoadCb)
    local role = self._CharacterMap[characterId]
    if not role then
        role = XRestaurantRole.New(self._CharacterRoot, characterId)
        self._CharacterMap[characterId] = role
    end
    role:Born(onLoadCb)
end

--- 释放角色资源
---@param characterId number 角色Id
---@return void
--------------------------
function XRestaurantRoom:ReleaseCharacter(characterId, unWorkCb)
    local role = self._CharacterMap[characterId]
    if not role then
        return
    end
    if unWorkCb then unWorkCb() end
    --role:Dispose()
end

--- 获取角色模型
---@param characterId number 角色Id
---@return XRestaurantRole
--------------------------
function XRestaurantRoom:GetCharacterModel(characterId)
    local role = self._CharacterMap[characterId]
    if not role then
        return
    end
    return role
end

--- 员工是否在场景中
---@param characterId number 角色Id
---@return boolean
--------------------------
function XRestaurantRoom:IsStaffInRoom(characterId)
    local role = self._CharacterMap[characterId]
    if not role then
        return false
    end
    return role:Exist()
end

--- 分配工作
---@param characterId number
---@param areaType number
---@param index number
---@param onLoadCb function 只有未加载时才会执行
---@return void
--------------------------
function XRestaurantRoom:AssignWork(characterId, areaType, index, onLoadCb)
    self:LoadCharacter(characterId, function()
        if not self:Exist() then
            return
        end
        if onLoadCb then onLoadCb() end
        local target = self:GetWorkBenchModel(areaType, index)
        local role = self:GetCharacterModel(characterId)
        local benchData = XRestaurantConfigs.GetWorkBenchData(areaType, index)
        local pos = benchData.WorkPosition
        if XRestaurantConfigs.CheckIsSaleArea(areaType) then
            role:TryAddNavMeshAgent()
        end
        role:SetWorkBench(target, pos, areaType)
    end)
   
end

--- 取消工作
---@param characterId number
---@return void
--------------------------
function XRestaurantRoom:UnAssignWork(characterId)
    local exist = self:IsStaffInRoom(characterId)
    if not exist then
        return
    end
    self._CharacterMap[characterId]:UnAssignWork()
    self._PointsMap[characterId] = nil
end

--- 员工状态改变
---@param characterId number 员工Id
---@param state number 员工状态，目前这个参数无效
--------------------------
function XRestaurantRoom:ChangeStaffState(characterId, state)
    local exist = self:IsStaffInRoom(characterId)
    if not exist then
        return
    end
    self._CharacterMap[characterId]:ChangeState(state)
end

---@return UnityEngine.Transform
--------------------------
function XRestaurantRoom:GetCashierModel()
    return self._CashierModel
end

function XRestaurantRoom:GetBlackBoardModel()
    return self._BlockBoard
end

--- 获取工作台变换
---@param areaType number 区域类型
---@param index number 工作台下标
---@return UnityEngine.Transform
--------------------------
function XRestaurantRoom:GetWorkBenchModel(areaType, index)
    local map = self._WorkBenchModel[areaType]
    if XTool.IsTableEmpty(map) then
        return
    end
    local work = map[index]
    return work and work.transform
end

--- 
---@param uiTransform UnityEngine.Transform
---@param targetTransform UnityEngine.Transform
---@param offset UnityEngine.Vector3
---@return void
--------------------------
function XRestaurantRoom:SetViewPosToTransformLocalPosition(uiTransform, targetTransform, offset)
    local worldCamera = self._RestaurantCamera.Camera
    if XTool.UObjIsNil(worldCamera) then
        return
    end
    CS.XUiHelper.SetViewPosToTransformLocalPosition(self._RestaurantCamera.Camera, uiTransform, targetTransform, offset, self._UiGrid3DPivot)
end

function XRestaurantRoom:GetFreePointList()
    local points = {}
    local map = {}
    for _, index in pairs(self._PointsMap) do
        map[index] = true
    end
    for _, point in ipairs(self._RandomPoints) do
        if not map[point:GetHashCode()] then
            table.insert(points, point)
        end
    end
    return points
end

function XRestaurantRoom:GetRandomPoint(characterId)
    local points = self:GetFreePointList()
    local count = #points
    local index = math.random(1, count)
    local transform = points[index]
    self._PointsMap[characterId] = transform:GetHashCode()
    
    return transform.position
end

--- 加载签到NPC
---@param signDay number 签到天数
---@param onLoadCb function 加载回调
--------------------------
function XRestaurantRoom:LoadSignNpc(signDay, onLoadCb)
    if not self._SignNpc then
        self._SignNpc = XRestaurantSignNpc.New(self._CharacterRoot, signDay)
    elseif signDay ~= self._SignNpc:GetId() then
        self._SignNpc:DisposeImmediately()
        self._SignNpc = XRestaurantSignNpc.New(self._CharacterRoot, signDay)
    end
    
    self._SignNpc:Born(onLoadCb)
end

--- 改变签到NPC状态
---@param state number
--------------------------
function XRestaurantRoom:ChangeSignNpcState(state)
    if not self._SignNpc then
        return
    end
    
    self._SignNpc:ChangeState(state)
end

function XRestaurantRoom:SignNpcExist()
    return self._SignNpc and self._SignNpc:Exist()
end

--- 加载订单Npc
---@param id number 角色id
---@param loadCb function 加载回调
--------------------------
function XRestaurantRoom:LoadOrderNpc(id, loadCb)
    if not self._OrderNpc then
        self._OrderNpc = XRestaurantOrderNpc.New(self._CharacterRoot, id)
    elseif self._OrderNpc:GetId() ~= id then
        self._OrderNpc:DisposeImmediately()
        self._OrderNpc = XRestaurantOrderNpc.New(self._CharacterRoot, id)
    end
    
    self._OrderNpc:Born(loadCb)
end

--- 改变订单NPC状态
---@param state number
--------------------------
function XRestaurantRoom:ChangeOrderNpcState(state)
    if not self._OrderNpc then
        return
    end
    
    self._OrderNpc:ChangeState(state)
end

function XRestaurantRoom:OrderNpcExist()
    return self._OrderNpc and self._OrderNpc:Exist()
end

function XRestaurantRoom:GetOrderNpcModel()
    return self._OrderNpc and self._OrderNpc:GetTransform() or nil
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XRestaurantRoom:OnBeginDrag(eventData)
    if XTool.UObjIsNil(self._GameObject) then
        return
    end
    self._RestaurantCamera:OnBeginDrag()
    for _, cb in ipairs(self._DragBeginListener or {}) do
        cb(eventData)
    end
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XRestaurantRoom:OnDrag(eventData)
    local deltaX = eventData.delta.x
    local radioX = deltaX / CameraXRatio
    if deltaX == 0 then
        return
    end
    
    self._RestaurantCamera:MoveCamera(-radioX)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XRestaurantRoom:OnEndDrag(eventData)
    if XTool.UObjIsNil(self._GameObject) then
        return
    end
    self._RestaurantCamera:OnEndDrag()
    for _, cb in ipairs(self._DragEndListener or {}) do
        cb(eventData)
    end
end

function XRestaurantRoom:AddBeginDragCb(cb)
    table.insert(self._DragBeginListener, cb)
end

function XRestaurantRoom:AddEndDragCb(cb)
    table.insert(self._DragEndListener, cb)
end

--每秒会执行一次
function XRestaurantRoom:Simulation(timeOfNow)
    self:SimulationCustomer(timeOfNow)
end

function XRestaurantRoom:SimulationCustomer(timeOfNow)
    if #self._CustomerList >= self._MaxCustomerCount then
        return
    end
    if timeOfNow > self._NextLoadCustomer then
        self:LoadCustomer(timeOfNow)
    end
end

function XRestaurantRoom:LoadCustomer(timeOfNow)
    local npcId = self:GetRandomCustomerNpcId()
    if not XTool.IsNumberValid(npcId) then
        return
    end
    local customer = XRestaurantCustomer.New(self._CharacterRoot, npcId)
    customer:SetBornPoint(self._StartPoint, self._RedPoint, self._GreenPoint)
    table.insert(self._CustomerList, customer)
    customer:Load()
    --未达到最大值时，刷新时间在加载后刷新
    local nextLoad = math.random(self._RandomMin, self._RandomMax)
    self._NextLoadCustomer = timeOfNow + nextLoad
end

function XRestaurantRoom:ClearAllCustomer()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    --不在营业期，不加载
    if not viewModel or not viewModel:IsInBusiness() then
        self._MaxCustomerCount = 0
    end
    
    for _, customer in ipairs(self._CustomerList) do
        customer:Dispose()
    end
    self._CustomerList = {}
end

function XRestaurantRoom:GetRandomCustomerNpcId()
    local index = math.random(1, self._CustomerTotal)
    local npcId = self._CustomerIds[index]
    local standingNpcId = XDataCenter.RestaurantManager.GetStandingOrderNpcId()
    --随机到站岗的Npc时
    if npcId == standingNpcId then
        --更新池子
        self:UpdateCustomerRandomPool(index, npcId)
        --重新随机
        return self:GetRandomCustomerNpcId()
    end
    local isRepeat = false
    for _, customer in pairs(self._CustomerList) do
        if customer:GetId() == npcId then
            isRepeat = true
            break
        end
    end

    --随机到重复角色
    if isRepeat then
        --更新池子
        self:UpdateCustomerRandomPool(index, npcId)
        --重新随机
        return self:GetRandomCustomerNpcId()
    end
    
    self:UpdateCustomerRandomPool(index, npcId)
    return npcId
end

function XRestaurantRoom:UpdateCustomerRandomPool(index, npcId)
    self._CustomerIds[index] = self._CustomerIds[self._CustomerTotal]
    self._CustomerIds[self._CustomerTotal] = npcId
    self._CustomerTotal = self._CustomerTotal - 1
    if self._CustomerTotal <= 0 then
        self._CustomerTotal = #self._CustomerIds
    end
end

function XRestaurantRoom:RemoveCustomer(npcId)
    local index
    for idx, customer in ipairs(self._CustomerList) do
        if customer:GetId() == npcId then
            index = idx
            break
        end
    end

    --达到最大值时，刷新时间在销毁后刷新
    if #self._CustomerList >= self._MaxCustomerCount then
        local nextLoad = math.random(self._RandomMin, self._RandomMax)
        self._NextLoadCustomer = XTime.GetServerNowTimestamp() + nextLoad
    end

    if index then
        table.remove(self._CustomerList, index)
    end
end

function XRestaurantRoom:GetCustomerRandomPoint()
    local vec3 = CsVector3.zero
    vec3.x = vec3.x + CsRandom.Range(self._PointMin.x, self._PointMax.x)
    vec3.z = vec3.z + CsRandom.Range(self._PointMin.z, self._PointMax.z)
    return vec3
end

return XRestaurantRoom