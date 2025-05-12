local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local Vector3 = CS.UnityEngine.Vector3
local CSXResourceManagerLoadAsync

local XRpgMakerGameBlock = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameBlock")
local XRpgMakerGameGap = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameGap")
local XRpgMakerGameCube = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameCube")
local XRpgMakerGameTrap = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameTrap")
local XRpgMakerGameGrassData = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameGrassData")

---推箱子4.0 合表游戏场景管理器
---@class XUiRpgPlayMixBlockScene
local XUiRpgPlayMixBlockScene = XClass(nil, "XUiRpgPlayMixBlockScene")

function XUiRpgPlayMixBlockScene:LoadScene(mapId, sceneLoadCompleteCb)
    self.MapId = mapId

    local sceneAssetUrl = XRpgMakerGameConfigs.GetRpgMakerGamePrefab(mapId)
    XLog.Error("[XResourceManager优化] 已经无法运行, 从XResourceManager改为loadPrefab")
    self.Resource = CSXResourceManagerLoadAsync(sceneAssetUrl)
    CS.XTool.WaitCoroutine(self.Resource, function()
        if not self.Resource or not self.Resource.Asset then
            XLog.Error("XUiRpgPlayMixBlockScene LoadScene error, instantiate error, name: " .. sceneAssetUrl)
            return
        end

        self.GameObject = CSUnityEngineObjectInstantiate(self.Resource.Asset)
        self.SceneObjRoot = XUiHelper.TryGetComponent(self.GameObject.transform, "GroupBase/Objects")
        self.BlockObjs = {}
        self.GapObjs = {}
        self.CubeObjs = {}
        self.TrapObjs = {}
        self.NewGrowObjs = {}   --非配置生成的草圃对象字典
        self.NewGrowRoundObjs = {}  --非配置生成的草圃对象对应的回合数是否显示
        self:Init()
        if sceneLoadCompleteCb then
            sceneLoadCompleteCb()
        end
    end)
end

function XUiRpgPlayMixBlockScene:RemoveScene()
    if self.GameObject then
        CS.UnityEngine.GameObject.Destroy(self.GameObject)
        self.GameObject = nil
    end

    if self.Resource then
        self.Resource:Release()
        self.Resource = nil
    end
end

function XUiRpgPlayMixBlockScene:DisposeMonsterPatrolLineObjs()
    for _, obj in pairs(self.MonsterPatrolLineObjs) do
        obj:Dispose()
    end
    self.MonsterPatrolLineObjs = {}
end

function XUiRpgPlayMixBlockScene:Init()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    self:InitCamera()

    local mapId = self:GetMapId()
    self:InitCube(mapId)
    self:InitBlock(mapId)
    self:InitEntity(mapId)
    self:InitGap(mapId)
    self:InitEndPoint(mapId)
    self:InitTriggerPoint(mapId)
    self:InitElectricFence(mapId)
    self:InitTrap(mapId)
    self:InitPlayer(mapId)
    self:InitMonster(mapId)
    self:InitShadow(mapId)
    self:InitTransferPoint(mapId)
    self:InitBubble(mapId)
    self:InitDrop(mapId)
    self:InitMagic(mapId)
end

function XUiRpgPlayMixBlockScene:InitCamera()
    --镜头角度与地图适配
    local row = XRpgMakerGameConfigs.GetRpgMakerGameRow(self:GetMapId())
    local cameras = {}
    for i = 8, 10, 1 do
        local cameraName = "Camera" .. i
        local camera = self.GameObject.transform:Find(cameraName)
        if not XTool.UObjIsNil(camera) then
            table.insert(cameras, camera)
            if i == row then
                self.Camera = camera:GetComponent("Camera")
            end
            camera.gameObject:SetActiveEx(false)
        end
    end
    if XTool.UObjIsNil(self.Camera) then
        self.Camera = self.GameObject.transform:Find("Camera"):GetComponent("Camera")
    end
    self.Camera.gameObject:SetActiveEx(true)
    self.PhysicsRaycaster = self.Camera.gameObject:AddComponent(typeof(CS.UnityEngine.EventSystems.PhysicsRaycaster))
end

---设置场景对象的位置，和二维坐标
---@param cubeX number 二维X坐标
---@param cubeY number 二维Y坐标
---@param obj any
function XUiRpgPlayMixBlockScene:SetObjPosition(cubeX, cubeY, obj)
    local cube = self:GetCubeObj(cubeY, cubeX)
    if not cube then
        XLog.Error("设置场景对象的位置错误：", cubeY, cubeX, obj)
        return
    end
    local cubePosition = cube:GetGameObjUpCenterPosition()
    obj:UpdatePosition({PositionX = cubeX, PositionY = cubeY})
    obj:SetGameObjectPosition(cubePosition)
end

---初始化实体
function XUiRpgPlayMixBlockScene:InitEntity(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local obj
    local modelPath
    local entityType
    local modelKey
    local x, y
    local entityData

    local trapModelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(XRpgMakerGameConfigs.ModelKeyMaps.Trap)
    local mapEntityDataList = XRpgMakerGameConfigs.GetMixBlockEntityList(mapId)

    for index, data in ipairs(mapEntityDataList) do
        --加载模型
        obj = XDataCenter.RpgMakerGameManager.GetEntityObj(index)
        entityData = obj:GetMapObjData()
        entityType = entityData:GetType()
        modelKey = XRpgMakerGameConfigs.GetMixBlockModelEntityKey(entityType)
        modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
        obj:LoadModel(modelPath, sceneObjRoot, nil, modelKey)

        --设置位置
        x = entityData:GetX()
        y = entityData:GetY()
        self:SetObjPosition(x, y, obj)

        --额外加载陷阱
        if entityData:GetParams()[2] == XRpgMakerGameConfigs.XRpgMakerGameSteelBrokenType.Trap then
            local trapObj = XRpgMakerGameTrap.New()
            trapObj:LoadModel(trapModelPath, sceneObjRoot, nil, XRpgMakerGameConfigs.ModelKeyMaps.Trap)
            self:SetObjPosition(x, y, trapObj)
        end
    end
end

------------------草圃相关 begin-------------------------
--非配置的草圃生长
function XUiRpgPlayMixBlockScene:GrowGrass(x, y)
    local curRoundCount = XDataCenter.RpgMakerGameManager.GetCurrentCount()
    local obj = self.NewGrowObjs[x] and self.NewGrowObjs[x][y]
    if obj then
        obj:SetRoundState(curRoundCount, true)
        obj:SetActive(true)
        return
    end

    if not self.NewGrowObjs[x] then
        self.NewGrowObjs[x] = {}
    end

    local modelKey = XRpgMakerGameConfigs.GetModelEntityKey(XRpgMakerGameConfigs.XRpgMakerGameEntityType.Grass)
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
    obj = XRpgMakerGameGrassData.New()
    obj:LoadModel(modelPath, self:GetSceneObjRoot(), nil, modelKey)
    obj:SetRoundState(curRoundCount, true)
    obj:PlayGrowSound()
    self:SetObjPosition(x, y, obj)
    self.NewGrowObjs[x][y] = obj
end

--非配置的草圃燃烧
function XUiRpgPlayMixBlockScene:BurnGrass(x, y)
    local curRoundCount = XDataCenter.RpgMakerGameManager.GetCurrentCount()
    local obj = self.NewGrowObjs[x] and self.NewGrowObjs[x][y]
    if not obj then
        return
    end
    obj:SetRoundState(curRoundCount, false)
    obj:Burn()
end

--根据回合数检查非配置的草圃是否显示，并删除指定回合数以上的数据
function XUiRpgPlayMixBlockScene:CheckGrowActive(currRound)
    for _, growObjs in pairs(self.NewGrowObjs) do
        for _, growObj in pairs(growObjs) do
            growObj:CheckRoundState(currRound)
        end
    end
end

--重置所有非配置的草圃
function XUiRpgPlayMixBlockScene:ResetGrow()
    for _, growObjs in pairs(self.NewGrowObjs) do
        for _, growObj in pairs(growObjs) do
            XUiHelper.Destroy(growObj:GetGameObject())
        end
    end
    self.NewGrowObjs = {}
end

--获得非配置的草圃
function XUiRpgPlayMixBlockScene:GetGrass(x, y)
    return self.NewGrowObjs[x] and self.NewGrowObjs[x][y]
end
------------------草圃相关 end---------------------------



--#region 地图初始化

--初始化传送
function XUiRpgPlayMixBlockScene:InitTransferPoint(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local obj
    local modelPath
    local modelKey
    local color
    local x, y
    
    local mapTransferPointDataList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.TransferPoint)
    for index, data in ipairs(mapTransferPointDataList) do
        --加载模型
        obj = XDataCenter.RpgMakerGameManager.GetTransferPointObj(index)
        color = data:GetParams()[1]
        modelKey = XRpgMakerGameConfigs.GetTransferPointLoopColorKey(color)
        modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
        obj:LoadModel(modelPath, sceneObjRoot, nil, modelKey)
        --设置位置
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, obj)
    end
end

--初始化机关
function XUiRpgPlayMixBlockScene:InitTriggerPoint(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local triggerObj
    local modelPath
    local triggerType
    local modelKey
    local isElectricOpen
    local x, y

    local mapTriggerDataList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Trigger)
    for _, data in ipairs(mapTriggerDataList) do
        local triggerId = data:GetParams()[1]
        --加载模型
        triggerObj = XDataCenter.RpgMakerGameManager.GetTriggerObj(triggerId)
        isElectricOpen = triggerObj:IsElectricOpen()
        triggerType = XRpgMakerGameConfigs.GetRpgMakerGameTriggerType(triggerId)
        modelKey = XRpgMakerGameConfigs.GetRpgMakerGameTriggerKey(triggerType, isElectricOpen)
        modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
        triggerObj:LoadModel(modelPath, sceneObjRoot, nil, modelKey)
        --设置位置
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, triggerObj)

        triggerObj:UpdateObjTriggerStatus(true)
    end
end

--初始化缝隙
function XUiRpgPlayMixBlockScene:InitGap(mapId)
    local sceneGameRoot = self:GetSceneObjRoot()
    local x, y
    local direction
    local gameObj
    local modelKey = XRpgMakerGameConfigs.ModelKeyMaps.Gap
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)

    local mapGapDataList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Gap)
    for index, gapData in ipairs(mapGapDataList) do
        --加载模型
        gameObj = XRpgMakerGameGap.New(index)
        gameObj:InitDataByMapObjData(gapData)
        gameObj:LoadModel(modelPath, sceneGameRoot, nil, modelKey)
        --设置位置和方向
        x = gapData:GetX()
        y = gapData:GetY()
        self:SetObjPosition(x, y, gameObj)
        direction = gapData:GetParams()[1]
        gameObj:ChangeDirectionAction({Direction = direction})

        self.GapObjs[index] = gameObj
    end
end

--初始化电网
function XUiRpgPlayMixBlockScene:InitElectricFence(mapId)
    local sceneGameRoot = self:GetSceneObjRoot()
    local x, y
    local direction
    local gameObj
    local modelKey = XRpgMakerGameConfigs.ModelKeyMaps.ElectricFence
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)

    local mapElectricFenceDataList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.ElectricFence)
    for index, data in ipairs(mapElectricFenceDataList) do
        --加载模型
        gameObj = XDataCenter.RpgMakerGameManager.GetElectricFenceObj(index)
        gameObj:LoadModel(modelPath, sceneGameRoot, nil, modelKey)
        --设置位置和方向
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, gameObj)
        direction = data:GetParams()[1]
        gameObj:ChangeDirectionAction({Direction = direction})
    end
end

--初始化影子
function XUiRpgPlayMixBlockScene:InitShadow(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local shadowObj
    local x, y
    local direction
    -- 影子特效key 根据roleId读取
    local stageId = XDataCenter.RpgMakerGameManager.GetRpgMakerGameEnterStageDb():GetStageId()
    local roleId = XRpgMakerGameConfigs.GetStageShadowId(stageId)
    if not XTool.IsNumberValid(roleId) then return end
    local modelName = XRpgMakerGameConfigs.GetRpgMakerGameRoleModelAssetPath(roleId)
    local modelKey = XRpgMakerGameConfigs.GetModelSkillShadowEffctKey(XRpgMakerGameConfigs.GetRoleSkillType(roleId))

    local mapShadowDataList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Shadow)
    for _, data in ipairs(mapShadowDataList) do
        local shadowId = data:GetParams()[1]
        --加载模型
        shadowObj = XDataCenter.RpgMakerGameManager.GetShadowObj(shadowId)
        shadowObj:LoadModel(nil, sceneObjRoot, modelName, modelKey)
        --设置位置和方向
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, shadowObj)
        direction = data:GetParams()[2]
        shadowObj:ChangeDirectionAction({Direction = direction})
    end
end

--初始化陷阱
function XUiRpgPlayMixBlockScene:InitTrap(mapId)
    local x, y
    local obj
    local sceneObjRoot = self:GetSceneObjRoot()
    local modelKey = XRpgMakerGameConfigs.ModelKeyMaps.Trap
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
    
    local mapTrapDataList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Trap)
    for index, data in ipairs(mapTrapDataList) do
        --加载模型
        obj = XRpgMakerGameTrap.New(index)
        obj:LoadModel(modelPath, sceneObjRoot, nil, modelKey)
        self.TrapObjs[index] = obj
        --设置位置
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, obj)
    end
end

--初始化终点
function XUiRpgPlayMixBlockScene:InitEndPoint(mapId)
    --加载模型
    local endPointObj = XDataCenter.RpgMakerGameManager.GetEndPointObj()
    local sceneObjRoot = self:GetSceneObjRoot()
    local modelKey = endPointObj:IsOpen() and XRpgMakerGameConfigs.ModelKeyMaps.GoldOpen or XRpgMakerGameConfigs.ModelKeyMaps.GoldClose
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
    endPointObj:LoadModel(modelPath, sceneObjRoot, nil, modelKey)
    --设置位置
    local endPointData = endPointObj:GetMapObjData()
    if XTool.IsTableEmpty(endPointData) then
        return
    end
    local x = endPointData:GetX()
    local y = endPointData:GetY()
    self:SetObjPosition(x, y, endPointObj)
end

function XUiRpgPlayMixBlockScene:InitMonster(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local monsterObj
    local modelName
    local x, y
    local direction
    local skillType

    local mapMonsterDataList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Moster)
    for _, data in ipairs(mapMonsterDataList) do
        local monsterId = data:GetParams()[1]
        --加载模型
        monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(monsterId)
        modelName = XRpgMakerGameConfigs.GetRpgMakerGameMonsterPrefab(monsterId)
        monsterObj:LoadModel(nil, sceneObjRoot, modelName)
        monsterObj:CheckLoadTriggerEndEffect()
        --设置位置和方向
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, monsterObj)
        direction = XRpgMakerGameConfigs.GetRpgMakerGameMonsterDirection(monsterId)
        monsterObj:ChangeDirectionAction({Direction = direction})
        --设置怪物模型初始视野范围
        monsterObj:SetViewAreaAndLine()
        --设置技能特效
        skillType = XRpgMakerGameConfigs.GetMonsterSkillType(monsterId)
        monsterObj:LoadSkillEffect(skillType)
    end
end

function XUiRpgPlayMixBlockScene:InitPlayer(mapId)
    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    local startPointData = playerObj:GetMapObjData()
    if XTool.IsTableEmpty(startPointData) then
        return
    end
    local x = startPointData:GetX()
    local y = startPointData:GetY()

    --加载玩家角色模型
    local roleId = playerObj:GetId()
    local modelName = XRpgMakerGameConfigs.GetRpgMakerGameRoleModelAssetPath(roleId)
    local sceneObjRoot = self:GetSceneObjRoot()
    playerObj:LoadModel(nil, sceneObjRoot, modelName)
    --设置位置
    self:SetObjPosition(x, y, playerObj)
    --设置方向
    local direction = startPointData:GetParams()[1]
    playerObj:ChangeDirectionAction({Direction = direction})
    --初始化箭头特效
    playerObj:LoadMoveDirectionEffect()
    playerObj:SetMoveDirectionEffectActive(false)
end

--初始化地面
function XUiRpgPlayMixBlockScene:InitCube(mapId)
    local transform = self.GameObject.transform
    local sceneObjRoot = self:GetSceneObjRoot()
    local cube = XUiHelper.TryGetComponent(sceneObjRoot.transform, "ScenePuzzle01_03Hezi01") or 
        XUiHelper.TryGetComponent(sceneObjRoot.transform, "ScenePuzzle02_02Box") or
        XUiHelper.TryGetComponent(sceneObjRoot.transform, "ScenePuzzle03_01Box") or
        XUiHelper.TryGetComponent(sceneObjRoot.transform, "ScenePuzzle04_02Box")
    if not cube then
        XLog.Error(string.format("XUiRpgPlayMixBlockScene:InitCube没找到ScenePuzzle01_03Hezi01对象 mapId：%s，sceneObjRoot：%s", mapId, sceneObjRoot))
        return
    end

    local cubeMeshFilter = cube:GetComponent("MeshFilter")
    local cubeSize = cubeMeshFilter.mesh.bounds.size

    local row = XRpgMakerGameConfigs.GetRpgMakerGameRow(mapId)
    local col = XRpgMakerGameConfigs.GetRpgMakerGameCol(mapId)
    local modelPath
    local gameObjPositionX
    local gameObjPositionY
    local gameObj
    local firstModelPath
    local secondModelPath
    local curChapterGroupId = XDataCenter.RpgMakerGameManager.GetCurChapterGroupId()
    local prefabs = XRpgMakerGameConfigs.GetChapterGroupGroundPrefab(curChapterGroupId)
    local cubeModelPath1 = prefabs[1]
    local cubeModelPath2 = prefabs[2]
    local poolModelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(XRpgMakerGameConfigs.ModelKeyMaps.Pool)
    local modelKey

    for i = 1, row do
        self.CubeObjs[i] = {}
        firstModelPath = i % 2 ~= 0 and cubeModelPath1 or cubeModelPath2
        secondModelPath = i % 2 == 0 and cubeModelPath1 or cubeModelPath2
        for j = 1, col do
            modelKey = nil
            if XRpgMakerGameConfigs.IsSameMixBlock(mapId, j, i, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Water) or
                XRpgMakerGameConfigs.IsSameMixBlock(mapId, j, i, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Ice) then
                    modelPath = poolModelPath
                    modelKey = XRpgMakerGameConfigs.ModelKeyMaps.Pool
            else
                modelPath = j % 2 ~= 0 and firstModelPath or secondModelPath
            end
            gameObjPositionX = cube.position.x + cubeSize.x * (j - 1)
            gameObjPositionY = cube.position.z + cubeSize.z * (i - 1)
            gameObj = XRpgMakerGameCube.New()
            gameObj:LoadModel(modelPath, sceneObjRoot, nil, modelKey)
            gameObj:SetGameObjectPosition(Vector3(gameObjPositionX, cube.position.y, gameObjPositionY))
            self.CubeObjs[i][j] = gameObj
        end
    end

    cube.gameObject:SetActiveEx(false)
end

--初始化阻挡物
function XUiRpgPlayMixBlockScene:InitBlock(mapId)
    local blockRow
    local colNum
    local blockObjTemp
    local sceneObjRoot = self:GetSceneObjRoot()
    local modelPath = XRpgMakerGameConfigs.GetChapterGroupBlockPrefab(XDataCenter.RpgMakerGameManager.GetCurChapterGroupId())
    local mapBlockDataList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.BlockType)

    for _, data in ipairs(mapBlockDataList) do
        colNum = data:GetX()
        blockRow = data:GetY()
        blockObjTemp = XRpgMakerGameBlock.New()
        blockObjTemp:LoadModel(modelPath, sceneObjRoot)
        self:SetObjPosition(colNum, blockRow, blockObjTemp)

        if not self.BlockObjs[blockRow] then
            self.BlockObjs[blockRow] = {}
        end
        self.BlockObjs[blockRow][colNum] = blockObjTemp
    end
end

---初始化泡泡
---@param mapId integer
function XUiRpgPlayMixBlockScene:InitBubble(mapId)
    local sceneGameRoot = self:GetSceneObjRoot()
    local x, y
    local gameObj
    local bubbleId
    local modelKey = XRpgMakerGameConfigs.ModelKeyMaps.Bubble
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)

    local mapBubbleDataList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Bubble)
    for index, data in ipairs(mapBubbleDataList) do
        bubbleId = data:GetParams()[1]
        --加载模型
        gameObj = XDataCenter.RpgMakerGameManager.GetBubbleObj(bubbleId)
        gameObj:LoadModel(modelPath, sceneGameRoot, nil, modelKey)
        --设置位置和方向
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, gameObj)
    end
end

---初始化掉落物
---@param mapId integer
function XUiRpgPlayMixBlockScene:InitDrop(mapId)
    local sceneGameRoot = self:GetSceneObjRoot()
    local x, y
    local gameObj
    local dropId, dropType, modelKey, modelPath

    local mapBubbleDataList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Drop)
    for _, data in ipairs(mapBubbleDataList) do
        dropId = data:GetParams()[1]
        dropType = data:GetParams()[2]
        modelKey = XRpgMakerGameConfigs.GetMixBlockModelDropKey(dropType)
        modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
        --加载模型
        gameObj = XDataCenter.RpgMakerGameManager.GetDropObj(dropId)
        gameObj:LoadModel(modelPath, sceneGameRoot, nil, modelKey)
        --设置位置和方向
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, gameObj)
    end
end

---初始化魔法阵
---@param mapId integer
function XUiRpgPlayMixBlockScene:InitMagic(mapId)
    local sceneGameRoot = self:GetSceneObjRoot()
    local x, y
    local gameObj
    local modelKey = XRpgMakerGameConfigs.ModelKeyMaps.Magic
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)

    local mapMagicDataList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Magic)
    for index, data in ipairs(mapMagicDataList) do
        --加载模型
        gameObj = XDataCenter.RpgMakerGameManager.GetMagicObj(index)
        gameObj:LoadModel(modelPath, sceneGameRoot, nil, modelKey)
        --设置位置和方向
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, gameObj)
    end
end

--#endregion



function XUiRpgPlayMixBlockScene:GetGapObjs()
    return self.GapObjs
end

function XUiRpgPlayMixBlockScene:GetBlockObj(row, col)
    return self.BlockObjs[row] and self.BlockObjs[row][col]
end

function XUiRpgPlayMixBlockScene:GetMapId()
    return self.MapId
end

function XUiRpgPlayMixBlockScene:GetCubeObj(row, col)
    return self.CubeObjs[row] and self.CubeObjs[row][col]
end

function XUiRpgPlayMixBlockScene:GetCubeObjs()
    return self.CubeObjs
end

function XUiRpgPlayMixBlockScene:GetSceneObjRoot()
    return self.SceneObjRoot
end

function XUiRpgPlayMixBlockScene:IsSceneNil()
    return XTool.UObjIsNil(self.GameObject)
end

function XUiRpgPlayMixBlockScene:SetSceneActive(isActive)
    if not self:IsSceneNil() then
        self.GameObject.gameObject:SetActiveEx(isActive)
    end
end

--重置
function XUiRpgPlayMixBlockScene:Reset()
    self:BackUp()
    self:ResetGrow()
end

--后退
function XUiRpgPlayMixBlockScene:BackUp()
    local mapId = self:GetMapId()
    self:UpdatePlayerObj()
    self:UpdateEntity(mapId)
    self:UpdateMonsterObjs(mapId)
    self:UpdateEndPointObjStatus()
    self:UpdateTriggeObjStatus(mapId)
    self:UpdateShadowObjs(mapId)
    self:UpdateElectricFenceObjStatus(mapId)
    self:UpdateBubbleObjs(mapId)
    self:UpdateDropObjs(mapId)
end

function XUiRpgPlayMixBlockScene:UpdateEntity(mapId)
    local entityList = XRpgMakerGameConfigs.GetMixBlockEntityList(mapId)
    local obj
    for index, _ in ipairs(entityList) do
        obj = XDataCenter.RpgMakerGameManager.GetEntityObj(index)
        if obj and obj.CheckPlayFlat then
            obj:CheckPlayFlat()
        end
    end
end

function XUiRpgPlayMixBlockScene:UpdateElectricFenceObjStatus(mapId)
    local electricFenceIdList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.ElectricFence)
    local obj
    for index, _ in ipairs(electricFenceIdList) do
        obj = XDataCenter.RpgMakerGameManager.GetElectricFenceObj(index)
        if obj then
            obj:PlayElectricFenceStatusChangeAction()
        end
    end
end

function XUiRpgPlayMixBlockScene:UpdateShadowObjs(mapId)
    local shadowIdList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Shadow)
    local shadowObj
    local shadowId
    for _, data in ipairs(shadowIdList) do
        shadowId = data:GetParams()[1]
        shadowObj = XDataCenter.RpgMakerGameManager.GetShadowObj(shadowId)
        if shadowObj then
            shadowObj:UpdateObjPosAndDirection()
            shadowObj:CheckIsDeath()
        end
    end
end

function XUiRpgPlayMixBlockScene:UpdatePlayerObj()
    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    playerObj:UpdateObjPosAndDirection()
    playerObj:CheckIsDeath()
end

function XUiRpgPlayMixBlockScene:UpdateMonsterObjs(mapId)
    local monsterIdList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Moster)
    local monsterObj
    local monsterId
    for _, data in ipairs(monsterIdList) do
        monsterId = data:GetParams()[1]
        monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(monsterId)
        if monsterObj then
            monsterObj:UpdateObjPosAndDirection()
            monsterObj:CheckIsDeath()
            monsterObj:RemovePatrolLineObjs()
            monsterObj:SetViewAreaAndLine()
            monsterObj:LoadSentrySign()
        end
    end
end

function XUiRpgPlayMixBlockScene:UpdateEndPointObjStatus()
    local endPointObj = XDataCenter.RpgMakerGameManager.GetEndPointObj()
    endPointObj:UpdateObjStatus()
end

function XUiRpgPlayMixBlockScene:UpdateTriggeObjStatus(mapId)
    local triggerIdList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Trigger)
    local triggerObj
    local triggerId
    for _, data in ipairs(triggerIdList) do
        triggerId = data:GetParams()[1]
        triggerObj = XDataCenter.RpgMakerGameManager.GetTriggerObj(triggerId)
        triggerObj:UpdateObjTriggerStatus()
    end
end

function XUiRpgPlayMixBlockScene:UpdateBubbleObjs(mapId)
    local objDataList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Bubble)
    local obj
    local bubbleId
    for _, data in ipairs(objDataList) do
        bubbleId = data:GetParams()[1]
        obj = XDataCenter.RpgMakerGameManager.GetBubbleObj(bubbleId)
        if obj then
            obj:UpdateObjPosAndDirection()
        end
    end
end

function XUiRpgPlayMixBlockScene:UpdateDropObjs(mapId)
    local objDataList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Drop)
    local obj
    local bubbleId
    for _, data in ipairs(objDataList) do
        bubbleId = data:GetParams()[1]
        obj = XDataCenter.RpgMakerGameManager.GetDropObj(bubbleId)
        if obj then
            obj:UpdateObjPosAndDirection()
        end
    end
end

function XUiRpgPlayMixBlockScene:PlayAnimation()
    self.PlayableDirector = XUiHelper.TryGetComponent(self.GameObject.transform, "Animation/AnimEnable", "PlayableDirector")
    if self.PlayableDirector then
        self.PlayableDirector.gameObject:SetActiveEx(true)
        self.PlayableDirector:Play()
    end
end

function XUiRpgPlayMixBlockScene:GetSceneCamera()
    return self.Camera
end

return XUiRpgPlayMixBlockScene