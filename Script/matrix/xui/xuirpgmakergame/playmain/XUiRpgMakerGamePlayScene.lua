local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local Vector3 = CS.UnityEngine.Vector3
local CSXResourceManagerLoad = CS.XResourceManager.Load
local CSXResourceManagerLoadAsync = CS.XResourceManager.LoadAsync

local XRpgMakerGameBlock = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameBlock")
local XRpgMakerGameGap = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameGap")
local XRpgMakerGameCube = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameCube")
local XRpgMakerGameTrap = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameTrap")
local XRpgMakerGameGrassData = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameGrassData")

local XUiRpgMakerGamePlayScene = XClass(nil, "XUiRpgMakerGamePlayScene")

function XUiRpgMakerGamePlayScene:LoadScene(mapId, sceneLoadCompleteCb)
    self.MapId = mapId

    local sceneAssetUrl = XRpgMakerGameConfigs.GetRpgMakerGamePrefab(mapId)
    self.Resource = CSXResourceManagerLoadAsync(sceneAssetUrl)
    CS.XTool.WaitCoroutine(self.Resource, function()
        if not self.Resource or not self.Resource.Asset then
            XLog.Error("XUiRpgMakerGamePlayScene LoadScene error, instantiate error, name: " .. sceneAssetUrl)
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

function XUiRpgMakerGamePlayScene:RemoveScene()
    if self.GameObject then
        CS.UnityEngine.GameObject.Destroy(self.GameObject)
        self.GameObject = nil
    end

    if self.Resource then
        self.Resource:Release()
        self.Resource = nil
    end
end

function XUiRpgMakerGamePlayScene:DisposeMonsterPatrolLineObjs()
    for _, obj in pairs(self.MonsterPatrolLineObjs) do
        obj:Dispose()
    end
    self.MonsterPatrolLineObjs = {}
end

function XUiRpgMakerGamePlayScene:Init()
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
end

function XUiRpgMakerGamePlayScene:InitCamera()
    self.Camera = self.GameObject.transform:Find("Camera"):GetComponent("Camera")
    self.PhysicsRaycaster = self.Camera.gameObject:AddComponent(typeof(CS.UnityEngine.EventSystems.PhysicsRaycaster))
end

--设置场景对象的位置，和二维坐标
--cubeX, cubeY：二维坐标
function XUiRpgMakerGamePlayScene:SetObjPosition(cubeX, cubeY, obj)
    local cube = self:GetCubeObj(cubeY, cubeX)
    if not cube then
        XLog.Error("设置场景对象的位置错误：", cubeY, cubeX, obj)
        return
    end
    local cubePosition = cube:GetGameObjUpCenterPosition()
    obj:UpdatePosition({PositionX = cubeX, PositionY = cubeY})
    obj:SetGameObjectPosition(cubePosition)
end

--初始化实体
function XUiRpgMakerGamePlayScene:InitEntity(mapId)
    local entityIdList = XRpgMakerGameConfigs.GetMapIdToEntityIdList(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local obj
    local modelPath
    local entityType
    local modelKey
    local x, y

    local trapModelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(XRpgMakerGameConfigs.ModelKeyMaps.Trap)

    for _, id in ipairs(entityIdList) do
        --加载模型
        obj = XDataCenter.RpgMakerGameManager.GetEntityObj(id)
        entityType = XRpgMakerGameConfigs.GetEntityType(id)
        modelKey = XRpgMakerGameConfigs.GetModelEntityKey(entityType)
        modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
        obj:LoadModel(modelPath, sceneObjRoot, nil, modelKey)

        --设置位置
        x = XRpgMakerGameConfigs.GetEntityX(id)
        y = XRpgMakerGameConfigs.GetEntityY(id)
        self:SetObjPosition(x, y, obj)

        --额外加载陷阱
        if XRpgMakerGameConfigs.GetEntityBrokenType(id) == XRpgMakerGameConfigs.XRpgMakerGameSteelBrokenType.Trap then
            local trapObj = XRpgMakerGameTrap.New()
            trapObj:LoadModel(trapModelPath, sceneObjRoot, nil, XRpgMakerGameConfigs.ModelKeyMaps.Trap)
            self:SetObjPosition(x, y, trapObj)
        end
    end
end

------------------草圃相关 begin-------------------------
--非配置的草圃生长
function XUiRpgMakerGamePlayScene:GrowGrass(x, y)
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
function XUiRpgMakerGamePlayScene:BurnGrass(x, y)
    local curRoundCount = XDataCenter.RpgMakerGameManager.GetCurrentCount()
    local obj = self.NewGrowObjs[x] and self.NewGrowObjs[x][y]
    if not obj then
        return
    end
    obj:SetRoundState(curRoundCount, false)
    obj:Burn()
end

--根据回合数检查非配置的草圃是否显示，并删除指定回合数以上的数据
function XUiRpgMakerGamePlayScene:CheckGrowActive(currRound)
    for _, growObjs in pairs(self.NewGrowObjs) do
        for _, growObj in pairs(growObjs) do
            growObj:CheckRoundState(currRound)
        end
    end
end

--重置所有非配置的草圃
function XUiRpgMakerGamePlayScene:ResetGrow()
    for _, growObjs in pairs(self.NewGrowObjs) do
        for _, growObj in pairs(growObjs) do
            XUiHelper.Destroy(growObj:GetGameObject())
        end
    end
    self.NewGrowObjs = {}
end

--获得非配置的草圃
function XUiRpgMakerGamePlayScene:GetGrass(x, y)
    return self.NewGrowObjs[x] and self.NewGrowObjs[x][y]
end
------------------草圃相关 end---------------------------

--初始化传送
function XUiRpgMakerGamePlayScene:InitTransferPoint(mapId)
    local transferPointIdList = XRpgMakerGameConfigs.GetMapIdToTransferPointIdList(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local obj
    local modelPath
    local triggerType
    local modelKey
    local color
    local x, y

    for _, id in ipairs(transferPointIdList) do
        --加载模型
        obj = XDataCenter.RpgMakerGameManager.GetTransferPointObj(id)
        color = XRpgMakerGameConfigs.GetTransferPointColor(id)
        modelKey = XRpgMakerGameConfigs.GetTransferPointLoopColorKey(color)
        modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
        obj:LoadModel(modelPath, sceneObjRoot, nil, modelKey)
        --设置位置
        x = XRpgMakerGameConfigs.GetTransferPointX(id)
        y = XRpgMakerGameConfigs.GetTransferPointY(id)
        self:SetObjPosition(x, y, obj)
    end
end

--初始化机关
function XUiRpgMakerGamePlayScene:InitTriggerPoint(mapId)
    local triggerIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToTriggerIdList(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local triggerObj
    local modelPath
    local triggerType
    local modelKey
    local isElectricOpen
    local x, y

    for _, triggerId in ipairs(triggerIdList) do
        --加载模型
        triggerObj = XDataCenter.RpgMakerGameManager.GetTriggerObj(triggerId)
        isElectricOpen = triggerObj:IsElectricOpen()
        triggerType = XRpgMakerGameConfigs.GetRpgMakerGameTriggerType(triggerId)
        modelKey = XRpgMakerGameConfigs.GetRpgMakerGameTriggerKey(triggerType, isElectricOpen)
        modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
        triggerObj:LoadModel(modelPath, sceneObjRoot, nil, modelKey)
        --设置位置
        x = XRpgMakerGameConfigs.GetRpgMakerGameTriggerX(triggerId)
        y = XRpgMakerGameConfigs.GetRpgMakerGameTriggerY(triggerId)
        self:SetObjPosition(x, y, triggerObj)

        triggerObj:UpdateObjTriggerStatus(true)
    end
end

--初始化缝隙
function XUiRpgMakerGamePlayScene:InitGap(mapId)
    local sceneGameRoot = self:GetSceneObjRoot()
    local gapIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToGapIdList(mapId)
    local x, y
    local direction
    local gameObj
    local cube
    local modelKey = XRpgMakerGameConfigs.ModelKeyMaps.Gap
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)

    for _, gapId in ipairs(gapIdList) do
        --加载模型
        gameObj = XRpgMakerGameGap.New(gapId)
        gameObj:LoadModel(modelPath, sceneGameRoot, nil, modelKey)
        --设置位置和方向
        x = XRpgMakerGameConfigs.GetRpgMakerGameGapX(gapId)
        y = XRpgMakerGameConfigs.GetRpgMakerGameGapY(gapId)
        self:SetObjPosition(x, y, gameObj)
        direction = XRpgMakerGameConfigs.GetRpgMakerGameGapDirection(gapId)        
        gameObj:ChangeDirectionAction({Direction = direction})

        self.GapObjs[gapId] = gameObj
    end
end

--初始化电网
function XUiRpgMakerGamePlayScene:InitElectricFence(mapId)
    local sceneGameRoot = self:GetSceneObjRoot()
    local electricFenceIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToElectricFenceIdList(mapId)
    local x, y
    local direction
    local gameObj
    local modelKey = XRpgMakerGameConfigs.ModelKeyMaps.ElectricFence
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)

    for _, electricFenceId in ipairs(electricFenceIdList) do
        --加载模型
        gameObj = XDataCenter.RpgMakerGameManager.GetElectricFenceObj(electricFenceId)
        gameObj:LoadModel(modelPath, sceneGameRoot, nil, modelKey)
        --设置位置和方向
        x = XRpgMakerGameConfigs.GetRpgMakerGameElectricFenceX(electricFenceId)
        y = XRpgMakerGameConfigs.GetRpgMakerGameElectricFenceY(electricFenceId)
        self:SetObjPosition(x, y, gameObj)
        direction = XRpgMakerGameConfigs.GetRpgMakerGameElectricDirection(electricFenceId)
        gameObj:ChangeDirectionAction({Direction = direction})
    end
end

--初始化影子
function XUiRpgMakerGamePlayScene:InitShadow(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local shadowIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToShadowIdList(mapId)
    local shadowObj
    local x, y
    local direction
    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    local roleId = playerObj:GetId()
    local modelName = XRpgMakerGameConfigs.GetRpgMakerGameRoleModelAssetPath(roleId)
    local modelKey = XRpgMakerGameConfigs.ModelKeyMaps.ShadowEffect

    for _, shadowId in ipairs(shadowIdList) do
        --加载模型
        shadowObj = XDataCenter.RpgMakerGameManager.GetShadowObj(shadowId)
        shadowObj:LoadModel(nil, sceneObjRoot, modelName, modelKey)
        --设置位置和方向
        x = XRpgMakerGameConfigs.GetRpgMakerGameShadowX(shadowId)
        y = XRpgMakerGameConfigs.GetRpgMakerGameShadowY(shadowId)
        self:SetObjPosition(x, y, shadowObj)
        direction = XRpgMakerGameConfigs.GetRpgMakerGameShadowDirection(shadowId)
        shadowObj:ChangeDirectionAction({Direction = direction})
    end
end

--初始化陷阱
function XUiRpgMakerGamePlayScene:InitTrap(mapId)
    local trapIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToTrapIdList(mapId)
    local x, y
    local obj
    local sceneObjRoot = self:GetSceneObjRoot()
    local modelKey = XRpgMakerGameConfigs.ModelKeyMaps.Trap
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
    
    for _, trapId in ipairs(trapIdList) do
        --加载模型
        obj = XRpgMakerGameTrap.New(trapId)
        obj:LoadModel(modelPath, sceneObjRoot, nil, modelKey)
        self.TrapObjs[trapId] = obj
        --设置位置
        x = XRpgMakerGameConfigs.GetRpgMakerGameTrapX(trapId)
        y = XRpgMakerGameConfigs.GetRpgMakerGameTrapY(trapId)
        self:SetObjPosition(x, y, obj)
    end
end

--初始化终点
function XUiRpgMakerGamePlayScene:InitEndPoint(mapId)
    --加载模型
    local endPointObj = XDataCenter.RpgMakerGameManager.GetEndPointObj()
    local sceneObjRoot = self:GetSceneObjRoot()
    local modelKey = endPointObj:IsOpen() and XRpgMakerGameConfigs.ModelKeyMaps.GoldOpen or XRpgMakerGameConfigs.ModelKeyMaps.GoldClose
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
    endPointObj:LoadModel(modelPath, sceneObjRoot, nil, modelKey)
    --设置位置
    local endPointId = endPointObj:GetId()
    local x = XRpgMakerGameConfigs.GetRpgMakerGameEndPointX(endPointId)
    local y = XRpgMakerGameConfigs.GetRpgMakerGameEndPointY(endPointId)
    self:SetObjPosition(x, y, endPointObj)
end

function XUiRpgMakerGamePlayScene:InitMonster(mapId)
    local monsterIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToMonsterIdList(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local monsterObj
    local modelName
    local x, y
    local direction
    local skillType

    for _, monsterId in ipairs(monsterIdList) do
        --加载模型
        monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(monsterId)
        modelName = XRpgMakerGameConfigs.GetRpgMakerGameMonsterPrefab(monsterId)
        monsterObj:LoadModel(nil, sceneObjRoot, modelName)
        monsterObj:CheckLoadTriggerEndEffect()
        --设置位置和方向
        x = XRpgMakerGameConfigs.GetRpgMakerGameMonsterX(monsterId)
        y = XRpgMakerGameConfigs.GetRpgMakerGameMonsterY(monsterId)
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

function XUiRpgMakerGamePlayScene:InitPlayer(mapId)
    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    local startPointId = XRpgMakerGameConfigs.GetRpgMakerGameStartPointId(mapId)
    local x = XRpgMakerGameConfigs.GetRpgMakerGameStartPointX(startPointId)
    local y = XRpgMakerGameConfigs.GetRpgMakerGameStartPointY(startPointId)

    --加载玩家角色模型
    local roleId = playerObj:GetId()
    local modelName = XRpgMakerGameConfigs.GetRpgMakerGameRoleModelAssetPath(roleId)
    local sceneObjRoot = self:GetSceneObjRoot()
    playerObj:LoadModel(nil, sceneObjRoot, modelName)
    --设置位置
    self:SetObjPosition(x, y, playerObj)
    --设置方向
    local direction = XRpgMakerGameConfigs.GetRpgMakerGameStartPointDirection(startPointId)
    playerObj:ChangeDirectionAction({Direction = direction})
    --初始化箭头特效
    playerObj:LoadMoveDirectionEffect()
    playerObj:SetMoveDirectionEffectActive(false)
    --设置技能特效
    local skillType = XRpgMakerGameConfigs.GetRoleSkillType(roleId)
    playerObj:LoadSkillEffect(skillType)
end

--初始化地面
function XUiRpgMakerGamePlayScene:InitCube(mapId)
    local transform = self.GameObject.transform
    local sceneObjRoot = self:GetSceneObjRoot()
    local cube = XUiHelper.TryGetComponent(sceneObjRoot.transform, "ScenePuzzle01_03Hezi01") or 
        XUiHelper.TryGetComponent(sceneObjRoot.transform, "ScenePuzzle02_02Box") or
        XUiHelper.TryGetComponent(sceneObjRoot.transform, "ScenePuzzle03_01Box")
    if not cube then
        XLog.Error(string.format("XUiRpgMakerGamePlayScene:InitCube没找到ScenePuzzle01_03Hezi01对象 mapId：%s，sceneObjRoot：%s", mapId, sceneObjRoot))
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

            if XRpgMakerGameConfigs.IsSameEntity(mapId, j, i, XRpgMakerGameConfigs.XRpgMakerGameEntityType.Water) or
                XRpgMakerGameConfigs.IsSameEntity(mapId, j, i, XRpgMakerGameConfigs.XRpgMakerGameEntityType.Ice) then
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
function XUiRpgMakerGamePlayScene:InitBlock(mapId)
    local blockIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToBlockIdList(mapId)
    local blockRow
    local colList
    local blockObjTemp
    local sceneObjRoot = self:GetSceneObjRoot()
    local cube
    local cubePosition
    local modelPath = XRpgMakerGameConfigs.GetChapterGroupBlockPrefab(XDataCenter.RpgMakerGameManager.GetCurChapterGroupId())
    
    for _, blockId in ipairs(blockIdList) do
        blockRow = XRpgMakerGameConfigs.GetRpgMakerGameBlockRow(blockId)
        colList = XRpgMakerGameConfigs.GetRpgMakerGameBlockColList(blockId)

        for colNum, blockStatus in ipairs(colList) do
            if blockStatus == XRpgMakerGameConfigs.XRpgMakerGameBlockStatus.Block then
                blockObjTemp = XRpgMakerGameBlock.New()
                blockObjTemp:LoadModel(modelPath, sceneObjRoot)
                self:SetObjPosition(colNum, blockRow, blockObjTemp)

                if not self.BlockObjs[blockRow] then
                    self.BlockObjs[blockRow] = {}
                end
                self.BlockObjs[blockRow][colNum] = blockObjTemp
            end
        end
    end
end

function XUiRpgMakerGamePlayScene:GetGapObjs()
    return self.GapObjs
end

function XUiRpgMakerGamePlayScene:GetBlockObj(row, col)
    return self.BlockObjs[row] and self.BlockObjs[row][col]
end

function XUiRpgMakerGamePlayScene:GetMapId()
    return self.MapId
end

function XUiRpgMakerGamePlayScene:GetCubeObj(row, col)
    return self.CubeObjs[row] and self.CubeObjs[row][col]
end

function XUiRpgMakerGamePlayScene:GetCubeObjs()
    return self.CubeObjs
end

function XUiRpgMakerGamePlayScene:GetSceneObjRoot()
    return self.SceneObjRoot
end

function XUiRpgMakerGamePlayScene:IsSceneNil()
    return XTool.UObjIsNil(self.GameObject)
end

function XUiRpgMakerGamePlayScene:SetSceneActive(isActive)
    if not self:IsSceneNil() then
        self.GameObject.gameObject:SetActiveEx(isActive)
    end
end

--重置
function XUiRpgMakerGamePlayScene:Reset()
    self:BackUp()
    self:ResetGrow()
end

--后退
function XUiRpgMakerGamePlayScene:BackUp()
    local mapId = self:GetMapId()
    self:UpdatePlayerObj()
    self:UpdateEntity(mapId)
    self:UpdateMonsterObjs(mapId)
    self:UpdateEndPointObjStatus()
    self:UpdateTriggeObjStatus(mapId)
    self:UpdateShadowObjs(mapId)
    self:UpdateElectricFenceObjStatus(mapId)
end

function XUiRpgMakerGamePlayScene:UpdateEntity(mapId)
    local entityList = XRpgMakerGameConfigs.GetMapIdToEntityIdList(mapId)
    local obj
    for _, entityId in ipairs(entityList) do
        obj = XDataCenter.RpgMakerGameManager.GetEntityObj(entityId)
        if obj and obj.CheckPlayFlat then
            obj:CheckPlayFlat()
        end
    end
end

function XUiRpgMakerGamePlayScene:UpdateElectricFenceObjStatus(mapId)
    local electricFenceIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToElectricFenceIdList(mapId)
    local obj
    for _, electricFenceId in ipairs(electricFenceIdList) do
        obj = XDataCenter.RpgMakerGameManager.GetElectricFenceObj(electricFenceId)
        if obj then
            obj:PlayElectricFenceStatusChangeAction()
        end
    end
end

function XUiRpgMakerGamePlayScene:UpdateShadowObjs(mapId)
    local shadowIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToShadowIdList(mapId)
    local shadowObj
    for _, shadowId in ipairs(shadowIdList) do
        shadowObj = XDataCenter.RpgMakerGameManager.GetShadowObj(shadowId)
        if shadowObj then
            shadowObj:UpdateObjPosAndDirection()
            shadowObj:CheckIsDeath()
        end
    end
end

function XUiRpgMakerGamePlayScene:UpdatePlayerObj()
    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    playerObj:UpdateObjPosAndDirection()
    playerObj:CheckIsDeath()
end

function XUiRpgMakerGamePlayScene:UpdateMonsterObjs(mapId)
    local monsterIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToMonsterIdList(mapId)
    local monsterObj
    for _, monsterId in ipairs(monsterIdList) do
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

function XUiRpgMakerGamePlayScene:UpdateEndPointObjStatus()
    local endPointObj = XDataCenter.RpgMakerGameManager.GetEndPointObj()
    endPointObj:UpdateObjStatus()
end

function XUiRpgMakerGamePlayScene:UpdateTriggeObjStatus(mapId)
    local triggerIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToTriggerIdList(mapId)
    local triggerObj
    for _, triggerId in ipairs(triggerIdList) do
        triggerObj = XDataCenter.RpgMakerGameManager.GetTriggerObj(triggerId)
        triggerObj:UpdateObjTriggerStatus()
    end
end

function XUiRpgMakerGamePlayScene:PlayAnimation()
    self.PlayableDirector = XUiHelper.TryGetComponent(self.GameObject.transform, "Animation/AnimEnable", "PlayableDirector")
    if self.PlayableDirector then
        self.PlayableDirector.gameObject:SetActiveEx(true)
        self.PlayableDirector:Play()
    end
end

function XUiRpgMakerGamePlayScene:GetSceneCamera()
    return self.Camera
end

return XUiRpgMakerGamePlayScene