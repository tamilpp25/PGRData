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
local XRestaurantPerformer = require("XModule/XRestaurant/XGameObject/XRestaurantPerformer")

local PhotoElementType = {
    --工作中的员工
    WorkingStaff = 1,
    --判断当前区域
    AreaType = 2,
    --判断工作台
    Workbench = 3,
    --判断指定元素
    SpecifyElements = 4,
    --判断任意角色
    AnyNpc = 5,
    --判断任意元素
    AnyElements = 6
}

local OpType = {

    Less = -1,

    Equal = 0,

    Greater = 1,
}

local function CheckOp(opType, count, target)
    local sub = count - target
    if sub == 0 then
        return OpType.Equal == opType
    end

    return (sub * opType) > 0
end



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
---@field _Perform XRestaurantPerform
local XRestaurantRoom = XClass(XRestaurantIScene, "XRestaurantRoom")

function XRestaurantRoom:Init()
    self._RestaurantCamera = self._OwnControl:AddEntity(XRestaurantCamera)
    self._CharacterMap = {}
    self._DragBeginListener = {}
    self._CustomerList = {}
    self._DragEndListener = {}
    self._UiGrid3DPivot = CS.UnityEngine.Vector2(0.5, 0.5)

    self._NextLoadCustomer = 0
    self._CustomerIds = self._Model:GetCustomerIds()
    self._CustomerTotal = #self._CustomerIds

    local min, max = self._Model:GetCustomerProperty()
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
    return self._Model:GetRestaurantSceneUrl()
end

function XRestaurantRoom:SetGameObject(gameObject)
    self._GameObject = gameObject
    self._Transform = gameObject.transform
    self:ResetTransform()
    self._GameObject.name = self:GetObjName()

    self:OnLoadSuccess()
end

function XRestaurantRoom:CreateDefaultModel(modelName, parent, x, y, z)
    local model = CS.UnityEngine.GameObject(modelName)
    model.transform:SetParent(parent)
    model.transform.localPosition = Vector3(x, y, z)
    
    return model
end

function XRestaurantRoom:OnLoadSuccess()
    if not XTool.UObjIsNil(self._Camera) then
        self:TryDestroy(self._Camera)
    end
    local baseSell = self._Transform:Find("GroupBase/@Furniture/03")
    self:LoadGlobalSO()
    self:InitPerform(baseSell)
    self:InitCamera()
    self:InitNavMesh()
    self:InitWorkBench()
    self:InitCustomer()
    self:InitSceneSetting()
    self:InitPhotoFunc()
    
    local modelName = "CashierModel"
    local cashierModel = baseSell:Find(modelName)
    if not cashierModel then
        cashierModel = self:CreateDefaultModel(modelName, baseSell, -3.95, 0, 3.474)
    end
    self._CashierModel = cashierModel
    
    self._CharacterRoot = self._Transform:Find("GroupBase/@Character")
    if XTool.UObjIsNil(self._CharacterRoot) then
        local groupBase = self._Transform:Find("GroupBase")
        local go = CS.UnityEngine.GameObject("@Character")
        go.transform:SetParent(groupBase, false)
        self:TryResetTransform(go.transform)
        self._CharacterRoot = go.transform
    end

    modelName = "MenuModel"
    local boardModel = baseSell:Find(modelName)
    
    if not boardModel then
        boardModel = self:CreateDefaultModel(modelName, baseSell, -6.14, 1.15, -4.58)
    end
    self._BlockBoard = boardModel
    
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
end

function XRestaurantRoom:TryWorking()
    -- 分配工作
    local dict = self._OwnControl:GetAllWorkbenchDict()
    for _, workbenches in pairs(dict) do
        for _, bench in pairs(workbenches) do
            bench:TryDoWork()
        end
    end
end

function XRestaurantRoom:TryLoadIndent()
    local running = self._OwnControl:GetRunningIndent()
    if not running or running:IsFinish() then
        return
    end
    local performId = running:GetPerformId()
    if self._OrderNpc and self._OrderNpc:Exist() and self._OrderNpc:GetId() == performId then
        self._OrderNpc:Show()
        XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_INDENT_NPC_STATE_CHANGED, true, performId)
        return
    end
    self:LoadOrderNpc(performId, function()
        XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_INDENT_NPC_STATE_CHANGED, true, performId)
    end)
end

function XRestaurantRoom:InitPerform(baseSell)
    local modelName = "StageModel"
    local stage = baseSell:Find(modelName)
    if not stage then
        stage = self:CreateDefaultModel(modelName, baseSell, -5.498001, 0, -1.272)
    end
    self._Perform = self._OwnControl:AddEntity(require("XModule/XRestaurant/XGameObject/XRestaurantPerform"))
    self._Perform:SetGameObject(stage.gameObject)
end

function XRestaurantRoom:InitPhotoFunc()
    if self._PhotoCheckFunc then
        return
    end

    self._PhotoCheckFunc = {}
    for key, value in pairs(PhotoElementType) do
        self._PhotoCheckFunc[value] = self["CheckPhoto" .. key]
    end
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
    local path = self._Model:GetGlobalIllumination()
    local loader = self._OwnControl:GetLoader()
    local asset = loader:Load(path)
    if not asset then
        XLog.Error("restaurant load resource error: asset path = " .. path)
        return
    end
    CS.XGlobalIllumination.SetGlobalIllumSO(asset)
    self._GOPath = path
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
    local furniture = self._Transform:Find("GroupBase/@Furniture/03")
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
    self._WorkBenchModel[XMVCA.XRestaurant.AreaType.IngredientArea] = init(list)

    list = workBenchRoot:Find("02"):GetComponentsInChildren(typeof(CS.XRestaurantWorkBench))
    self._WorkBenchModel[XMVCA.XRestaurant.AreaType.FoodArea] = init(list)

    list = workBenchRoot:Find("03"):GetComponentsInChildren(typeof(CS.XRestaurantWorkBench))
    self._WorkBenchModel[XMVCA.XRestaurant.AreaType.SaleArea] = init(list)
end

function XRestaurantRoom:InitCustomer()
    local customer = self._Transform:Find("GroupBase/@NpcCustomer")
    local start = customer:Find("Start")
    self._StartPoint = start.position
    local green = customer:Find("Green")
    self._GreenPoint = green.position
    local red = customer:Find("Red")
    self._RedPoint = red.position

    self._PointMin = customer:Find("Point1").position
    self._PointMax = customer:Find("Point2").position

    self._MaxCustomerCount = self._Model:GetCustomerLimit()
    if self._MaxCustomerCount > #self._CustomerIds then
        XLog.Error("最大加载顾客数大于配置的不重复顾客数，由于不放回机制，将会导致死循环！！！")

        self._MaxCustomerCount = #self._CustomerIds
    end

    --不在营业期，不加载
    if not self._Model:IsInBusiness() then
        self._MaxCustomerCount = 0
    end
end

function XRestaurantRoom:GetObjName()
    return string.format("RestaurantLv%s", self._Model:GetRestaurantLv())
end

function XRestaurantRoom:Release()
    if not string.IsNilOrEmpty(self._GOPath) then
        local loader = self._OwnControl:GetLoader()
        loader:Unload(self._GOPath)
        self._GOPath = nil
    end
    
    self.Super.Release(self)
    self._RestaurantCamera:Release()
    for _, role in pairs(self._CharacterMap or {}) do
        role:Release()
    end
    for _, customer in pairs(self._CustomerList) do
        customer:Release()
    end
    if self._OrderNpc then
        self._OrderNpc:Release()
    end
    if self._SignNpc then
        self._SignNpc:Release()
    end
    

    if self._Perform then
        self._Perform:Release()
    end

    self._CharacterMap = {}
    self._CustomerList = {}
    self._CashierModel = nil
    self._CharacterRoot = nil
    self._SceneSetting = nil
    self._OrderNpc = nil
    self._SignNpc = nil
    self._Perform = nil
    self._PhotoCheckFunc = nil
    self._WorkBenchModel = {}
    self._DragBeginListener = {}
    self._DragEndListener = {}

    self._NextLoadCustomer = 0
    --场景销毁
    XUiHelper.SetSceneType(CS.XSceneType.Ui)
end

function XRestaurantRoom:StopBusiness()
    for _, char in pairs(self._CharacterMap) do
        char:Hide()
    end

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
    self._IsInBussScene = false
end

function XRestaurantRoom:StartBusiness()
    self._RestaurantCamera:OnEnterBusiness()
    self:PlayPerformance()
    self._IsInBussScene = true
end

function XRestaurantRoom:IsInBusinessScene()
    return self._IsInBussScene
end

function XRestaurantRoom:PlayPerformance()
    if not self._Perform then
        return
    end
    
    local perform = self._OwnControl:GetRunningPerform()
    if not perform or perform:IsFinish() then
        return
    end

    self._Perform:StartPerformance(perform:GetPerformId())
end

function XRestaurantRoom:StopPerformance()
    if not self._Perform then
        return
    end
    self._Perform:StopPerformance()
end

--- 加载角色模型
---@param characterId number 角色Id
---@param onLoadCb function 加载成功回调
---@return void
--------------------------
function XRestaurantRoom:LoadCharacter(characterId, onLoadCb)
    local role = self._CharacterMap[characterId]
    if not role then
        role = self._OwnControl:AddEntity(XRestaurantRole, self._CharacterRoot, characterId)
        self._CharacterMap[characterId] = role
    end
    role:Born(onLoadCb)
end

--- 释放角色资源
---@param characterId number 角色Id
---@return void
--------------------------
function XRestaurantRoom:ReleaseCharacter(characterId)
    local role = self._CharacterMap[characterId]
    if not role then
        return
    end
    self._CharacterMap[characterId] = nil
    role:DisposeImmediately()
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
        if onLoadCb then
            onLoadCb()
        end
        local target = self:GetWorkBenchModel(areaType, index)
        local role = self:GetCharacterModel(characterId)
        local benchData = self._Model:GetWorkbenchPosInfo(areaType, index)
        local pos = benchData.WorkPosition
        if self._OwnControl:IsSaleArea(areaType) then
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
        self._SignNpc = self._OwnControl:AddEntity(XRestaurantSignNpc, self._CharacterRoot,
                signDay)
    elseif signDay ~= self._SignNpc:GetId() then
        self._SignNpc:DisposeImmediately()
        self._SignNpc = self._OwnControl:AddEntity(XRestaurantSignNpc, self._CharacterRoot,
                signDay)
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

function XRestaurantRoom:ReleaseSignNpc()
    if self._SignNpc then
        self._SignNpc:Release()
    end
    self._SignNpc = nil
end

--- 加载订单Npc
---@param id number 角色id
---@param loadCb function 加载回调
--------------------------
function XRestaurantRoom:LoadOrderNpc(id, loadCb)
    if not self._OrderNpc then
        self._OrderNpc = self._OwnControl:AddEntity(XRestaurantOrderNpc, self._CharacterRoot, id)
    elseif self._OrderNpc:GetId() ~= id then
        self._OrderNpc:DisposeImmediately()
        self._OrderNpc = self._OwnControl:AddEntity(XRestaurantOrderNpc, self._CharacterRoot, id)
    end

    self._OrderNpc:Born(loadCb)
end

--- 改变订单NPC状态
---@param state number
--------------------------
function XRestaurantRoom:ChangeIndentNpcState(state)
    if not self._OrderNpc then
        return
    end

    self._OrderNpc:ChangeState(state)
end

function XRestaurantRoom:ReleaseOrderNpc()
    if self._OrderNpc then
        self._OrderNpc:Release()
    end
    self._OrderNpc = nil
    
    self:TryLoadIndent()
end

function XRestaurantRoom:OrderNpcExist()
    return self._OrderNpc and self._OrderNpc:Exist()
end

function XRestaurantRoom:GetOrderNpcModel()
    return self._OrderNpc and self._OrderNpc:GetTransform() or nil
end

function XRestaurantRoom:LoadPerformer(performerId)
    return self._OwnControl:AddEntity(XRestaurantPerformer, self._CharacterRoot, performerId)
end

function XRestaurantRoom:LoadPerformProps(prefab)
    if not prefab then
        return
    end
    return XUiHelper.Instantiate(prefab, self:GetPerformStageModel())
end

function XRestaurantRoom:GetPerformStageModel()
    if not self._Perform then
        return
    end
    return self._Perform:GetTransform()
end

function XRestaurantRoom:GetPerform()
    return self._Perform
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XRestaurantRoom:OnBeginDrag(eventData)
    if self._ForbidDrag then
        return
    end
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
    if self._ForbidDrag then
        return
    end
    local deltaX = eventData.delta.x
    local radioX = deltaX / CameraXRatio
    if deltaX == 0 then
        return
    end

    self._RestaurantCamera:MoveCamera(-radioX)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XRestaurantRoom:OnEndDrag(eventData)
    if self._ForbidDrag then
        return
    end
    if XTool.UObjIsNil(self._GameObject) then
        return
    end
    self._RestaurantCamera:OnEndDrag()
    for _, cb in ipairs(self._DragEndListener or {}) do
        cb(eventData)
    end
end

function XRestaurantRoom:SetForbidDrag(value)
    self._ForbidDrag = value
end

function XRestaurantRoom:AddBeginDragCb(cb)
    table.insert(self._DragBeginListener, cb)
end

function XRestaurantRoom:AddEndDragCb(cb)
    table.insert(self._DragEndListener, cb)
end

function XRestaurantRoom:DelBeginDragCb(cb)
    if not cb then
        return
    end
    local index
    for i, listener in ipairs(self._DragBeginListener) do
        if listener == cb then
            index = i
            break
        end
    end

    if index then
        table.remove(self._DragBeginListener, index)
    end
end

function XRestaurantRoom:DelEndDragCb(cb)
    if not cb then
        return
    end
    local index
    for i, listener in ipairs(self._DragEndListener) do
        if listener == cb then
            index = i
            break
        end
    end

    if index then
        table.remove(self._DragEndListener, index)
    end
end

--每秒会执行一次
function XRestaurantRoom:Simulation(timeOfNow)
    self:SimulationCustomer(timeOfNow)
end

function XRestaurantRoom:SimulationCustomer(timeOfNow)
    if #self._CustomerList >= self._MaxCustomerCount then
        return
    end
    if XTool.UObjIsNil(self._CharacterRoot) then
        return
    end
    if timeOfNow > self._NextLoadCustomer then
        self:LoadCustomer(timeOfNow)
    end
end

function XRestaurantRoom:LoadCustomer(timeOfNow)
    local customerId = self:GetRandomCustomerNpcId()
    if not XTool.IsNumberValid(customerId) then
        return
    end
    local customer = self._OwnControl:AddEntity(XRestaurantCustomer, self._CharacterRoot,
            customerId)
    customer:SetBornPoint(self._StartPoint, self._RedPoint, self._GreenPoint)
    table.insert(self._CustomerList, customer)
    customer:Load()
    --未达到最大值时，刷新时间在加载后刷新
    local nextLoad = math.random(self._RandomMin, self._RandomMax)
    self._NextLoadCustomer = timeOfNow + nextLoad
end

function XRestaurantRoom:ClearAllCustomer()
    --不在营业期，不加载
    if not self._Model:IsInBusiness() then
        self._MaxCustomerCount = 0
    end

    for _, customer in ipairs(self._CustomerList) do
        customer:DisposeImmediately()
    end
    self._CustomerList = {}
end

function XRestaurantRoom:GetRandomCustomerNpcId()
    local index = math.random(1, self._CustomerTotal)
    local customerId = self._CustomerIds[index]
    local npcId = self._Model:GetCustomerNpcId(customerId)
    local standingNpcId = self._OwnControl:GetRunningIndentNpcId()
    --随机到站岗的Npc时
    if npcId == standingNpcId and standingNpcId ~= 0 then
        --更新池子
        self:UpdateCustomerRandomPool(index, customerId)
        --重新随机
        return self:GetRandomCustomerNpcId()
    end
    local dict = self._Perform and self._Perform:GetRunningNpcDict() or {}
    for _, performer in pairs(dict) do
        local id = performer:GetNpcId()
        if npcId == id and id ~= 0 then
            --更新池子
            self:UpdateCustomerRandomPool(index, customerId)
            --重新随机
            return self:GetRandomCustomerNpcId()
        end
    end
    local isRepeat = false
    for _, customer in pairs(self._CustomerList) do
        if customer:GetId() == customerId then
            isRepeat = true
            break
        end
    end

    --随机到重复角色
    if isRepeat then
        --更新池子
        self:UpdateCustomerRandomPool(index, customerId)
        --重新随机
        return self:GetRandomCustomerNpcId()
    end

    self:UpdateCustomerRandomPool(index, customerId)
    return customerId
end

function XRestaurantRoom:UpdateCustomerRandomPool(index, customerId)
    self._CustomerIds[index] = self._CustomerIds[self._CustomerTotal]
    self._CustomerIds[self._CustomerTotal] = customerId
    self._CustomerTotal = self._CustomerTotal - 1
    if self._CustomerTotal <= 0 then
        self._CustomerTotal = #self._CustomerIds
    end
end

function XRestaurantRoom:RemoveCustomer(npcId)
    local index
    for idx, customer in ipairs(self._CustomerList) do
        if customer:GetNpcId() == npcId then
            index = idx
            break
        end
    end
    self:RemoveCustomerByIndex(index)
end

function XRestaurantRoom:TryRemoveCustomer(npcId)
    local index
    for idx, customer in ipairs(self._CustomerList) do
        if customer:GetNpcId() == npcId then
            index = idx
            break
        end
    end

    if not index then
        return
    end

    self:RemoveCustomerByIndex(index)
end

function XRestaurantRoom:RemoveCustomerByIndex(index)
    --达到最大值时，刷新时间在销毁后刷新
    if #self._CustomerList >= self._MaxCustomerCount then
        local nextLoad = math.random(self._RandomMin, self._RandomMax)
        self._NextLoadCustomer = XTime.GetServerNowTimestamp() + nextLoad
    end

    if index then
        local customer = self._CustomerList[index]
        table.remove(self._CustomerList, index)
        customer:DisposeImmediately()
    end
end

function XRestaurantRoom:GetCustomerRandomPoint()
    local vec3 = CsVector3.zero
    vec3.x = vec3.x + CsRandom.Range(self._PointMin.x, self._PointMax.x)
    vec3.z = vec3.z + CsRandom.Range(self._PointMin.z, self._PointMax.z)
    return vec3
end


--检测单个拍照任务是否完成
function XRestaurantRoom:CheckPhotoElementFinish(id, count)
    local perform = self._OwnControl:GetRunningPerform()
    if not perform then
        return false
    end
    local eleType = perform:GetPhotoElementType(id)
    local isContain = count ~= 0
    local func = self._PhotoCheckFunc[eleType]
    if not func then
        XLog.Error("不存在拍照类型" .. eleType .. ", Id = " .. id)
        return false
    end
    return func(self, id, isContain, perform)
end

function XRestaurantRoom:CheckPhotoWorkingStaff(eleId, isContain, perform)
    local containOne = false
    for _, staff in pairs(self._CharacterMap) do
        local value = self._RestaurantCamera:CheckObjInView(staff:GetTransform())
        --包含， 并且当前目标在相机内
        if isContain and value then
            return true
        end
        containOne = containOne or value
    end
    if not isContain and not containOne then
        return true
    end
    return false
end

function XRestaurantRoom:CheckPhotoAreaType(eleId, isContain, perform)
    local params = perform:GetPhotoElementParams(eleId)
    local areaType = params[1]
    local isSame = self._RestaurantCamera:CheckInArea(areaType)
    return isSame == isContain
end

function XRestaurantRoom:CheckPhotoWorkbench(eleId, isContain, perform)
    local params = perform:GetPhotoElementParams(eleId)
    local areaType = params[1]
    local map = self._WorkBenchModel[areaType]
    if not map then
        return false
    end
    local containOne = false
    for _, workBench in pairs(map) do
        local value = self._RestaurantCamera:CheckObjInView(workBench.transform)
        --包含， 并且当前目标在相机内
        if isContain and value then
            return true
        end
        containOne = containOne or value
    end
    if not isContain and not containOne then
        return true
    end
    return false
end

function XRestaurantRoom:CheckPhotoSpecifyElements(eleId, isContain, perform)
    local obj = self._RestaurantCamera:GetPhotoEleCache(eleId)
    if not obj then
        local path = perform:GetPhotoElementRelativePath(eleId)
        obj = self._Transform:FindTransformWithSplitEx(path)
        self._RestaurantCamera:SetPhotoEleCache(eleId, obj)
    end
    if XTool.UObjIsNil(obj) then
        self._RestaurantCamera:SetPhotoEleCache(eleId, nil)
        return not isContain
    end
    local value = self._RestaurantCamera:CheckObjInView(obj.transform)
    return value == isContain
end

function XRestaurantRoom:CheckPhotoAnyNpc(eleId, isContain, perform)
    if XMain.IsEditorDebug and not isContain then
        XLog.Error("当前类型不支持[不包含]拍照条件" .. eleId)
        return false
    end
    local params = perform:GetPhotoElementParams(eleId)
    local count, op = params[1], params[2]
    local childCount = self._CharacterRoot.transform.childCount
    local sum = 0
    for i = 0, childCount - 1 do
        local child = self._CharacterRoot.transform:GetChild(i)
        local value = self._RestaurantCamera:CheckObjInView(child.transform)
        if value then
            sum = sum + 1
        end 
    end

    return CheckOp(op, sum, count)
end

function XRestaurantRoom:CheckPhotoAnyElements(eleId, isContain, perform)
    if XMain.IsEditorDebug and not isContain then
        XLog.Error("当前类型不支持[不包含]拍照条件" .. eleId)
        return false
    end
    local params = perform:GetPhotoElementParams(eleId)
    local count, op = params[1], params[2]
    local objs = self._RestaurantCamera:GetPhotoEleCache(eleId)
    if not objs then
        local relativePath = perform:GetPhotoElementRelativePath(eleId)
        local paths = string.Split(relativePath, "|")
        local objs = {}
        for _, path in ipairs(paths) do
            local obj = self._Transform:FindTransformWithSplitEx(path)
            table.insert(objs, {
                Path = path,
                Obj = obj
            })
        end
        self._RestaurantCamera:SetPhotoEleCache(eleId, objs)
    end

    if XTool.IsTableEmpty(objs) then
        return false
    end
    local sum = 0
    for _, data in pairs(objs) do
        local obj = data.Obj
        if XTool.UObjIsNil(obj) then
            obj = self._Transform:FindTransformWithSplitEx(data.Path)
            data.Obj = obj
        end
        if XTool.UObjIsNil(obj) then
            goto continue
        end
        local value = self._RestaurantCamera:CheckObjInView(obj.transform)
        if value then
            sum = sum + 1
        end
        
        ::continue::
    end
    return CheckOp(op, sum, count)
end

function XRestaurantRoom:CheckPhotoTaskFinish(photoTaskId)
    local perform = self._OwnControl:GetRunningPerform()
    if not perform then
        return false
    end
    local finish = true
    local conditions = perform:GetConditions(photoTaskId)
    for _, conditionId in ipairs(conditions) do
        local params = perform:GetConditionParams(conditionId)
        if not self:CheckPhotoElementFinish(params[1], params[2]) then
            finish = false
            break
        end
    end

    return finish
end

return XRestaurantRoom