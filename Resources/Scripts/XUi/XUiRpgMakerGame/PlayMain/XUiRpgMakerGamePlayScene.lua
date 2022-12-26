local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local Vector3 = CS.UnityEngine.Vector3
local CSXResourceManagerLoad = CS.XResourceManager.Load
local CSXResourceManagerLoadAsync = CS.XResourceManager.LoadAsync

local XRpgMakerGameBlock = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameBlock")
local XRpgMakerGameGap = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameGap")
local XRpgMakerGameCube = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameCube")

local XUiRpgMakerGamePlayScene = XClass(nil, "XUiRpgMakerGamePlayScene")

function XUiRpgMakerGamePlayScene:LoadScene(mapId, sceneLoadCompleteCb, uiName)
    self.MapId = mapId
    self.UiName = uiName

    local sceneAssetUrl = XRpgMakerGameConfigs.GetRpgMakerGamePrefab(mapId)
    self.Resource = CSXResourceManagerLoadAsync(sceneAssetUrl)
    CS.XTool.WaitCoroutine(self.Resource, function()
        if not self.Resource or not self.Resource.Asset then
            XLog.Error("XUiRpgMakerGamePlayScene LoadScene error, instantiate error, name: " .. sceneAssetUrl)
            return
        end

        self.GameObject = CSUnityEngineObjectInstantiate(self.Resource.Asset)
        self.SceneObjRoot = XUiHelper.TryGetComponent(self.GameObject.transform, "GroupBase")
        self.BlockObjs = {}
        self.GapObjs = {}
        self.CubeObjs = {}
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
    self:InitPlayer(mapId)
    self:InitMonster(mapId)
    self:InitGap(mapId)
    self:InitEndPoint(mapId)
    self:InitTriggerPoint(mapId)
end

function XUiRpgMakerGamePlayScene:InitCamera()
    self.Camera = self.GameObject.transform:Find("Camera"):GetComponent("Camera")
end

function XUiRpgMakerGamePlayScene:InitTriggerPoint(mapId)
    local triggerIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToTriggerIdList(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local triggerObj
    local modelPath
    local triggerType

    for _, triggerId in ipairs(triggerIdList) do
        triggerObj = XDataCenter.RpgMakerGameManager.GetTriggerObj(triggerId)
        triggerType = XRpgMakerGameConfigs.GetRpgMakerGameTriggerType(triggerId)
        modelPath = XRpgMakerGameConfigs.GetRpgMakerGameTriggerPath(triggerType)
        triggerObj:LoadModel(modelPath, sceneObjRoot)
    end

    self:InitTriggerPointPosition(mapId)
end

function XUiRpgMakerGamePlayScene:InitTriggerPointPosition(mapId)
    local triggerIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToTriggerIdList(mapId)
    local triggerObj
    local x, y
    local cube
    local cubePosition
    for _, triggerId in ipairs(triggerIdList) do
        triggerObj = XDataCenter.RpgMakerGameManager.GetTriggerObj(triggerId)
        x = XRpgMakerGameConfigs.GetRpgMakerGameTriggerX(triggerId)
        y = XRpgMakerGameConfigs.GetRpgMakerGameTriggerY(triggerId)
        cube = self:GetCubeObj(y, x)
        cubePosition = cube:GetGameObjUpCenterPosition()
        triggerObj:UpdatePosition({PositionX = x, PositionY = y})
        triggerObj:SetGameObjectPosition(cubePosition)
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
    local cubePosition
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath("Gap")

    for _, gapId in ipairs(gapIdList) do
        gameObj = XRpgMakerGameGap.New(gapId)
        gameObj:LoadModel(modelPath, sceneGameRoot)

        x = XRpgMakerGameConfigs.GetRpgMakerGameGapX(gapId)
        y = XRpgMakerGameConfigs.GetRpgMakerGameGapY(gapId)
        direction = XRpgMakerGameConfigs.GetRpgMakerGameGapDirection(gapId)
        cube = self:GetCubeObj(y, x)
        cubePosition = cube:GetGameObjUpCenterPosition()
        gameObj:UpdatePosition({PositionX = x, PositionY = y})
        gameObj:SetGameObjectPosition(cubePosition)
        gameObj:ChangeDirectionAction({Direction = direction})

        self.GapObjs[gapId] = gameObj
    end
end

--初始化终点
function XUiRpgMakerGamePlayScene:InitEndPoint(mapId)
    local endPointObj = XDataCenter.RpgMakerGameManager.GetEndPointObj()
    local sceneObjRoot = self:GetSceneObjRoot()
    local modelPath = endPointObj:IsOpen() and XRpgMakerGameConfigs.GetRpgMakerGameModelPath("GoldOpen") or XRpgMakerGameConfigs.GetRpgMakerGameModelPath("GoldClose")
    endPointObj:LoadModel(modelPath, sceneObjRoot)

    self:InitEndPointPosition(mapId)
end

function XUiRpgMakerGamePlayScene:InitEndPointPosition(mapId)
    local endPointObj = XDataCenter.RpgMakerGameManager.GetEndPointObj()
    local endPointId = endPointObj:GetId()
    local x = XRpgMakerGameConfigs.GetRpgMakerGameEndPointX(endPointId)
    local y = XRpgMakerGameConfigs.GetRpgMakerGameEndPointY(endPointId)
    local cube = self:GetCubeObj(y, x)
    local cubePosition = cube:GetGameObjUpCenterPosition()
    endPointObj:UpdatePosition({PositionX = x, PositionY = y})
    endPointObj:SetGameObjectPosition(cubePosition)
end

function XUiRpgMakerGamePlayScene:InitMonster(mapId)
    local monsterIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToMonsterIdList(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local monsterObj
    local modelPath
    local modelName
    local uiName = self:GetUiName()

    for _, monsterId in ipairs(monsterIdList) do
        monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(monsterId)
        modelName = XRpgMakerGameConfigs.GetRpgMakerGameMonsterPrefab(monsterId)
        modelPath = XModelManager.GetModelPath(modelName)
        monsterObj:LoadModel(modelPath, sceneObjRoot, modelName)
        monsterObj:SetAnimator(modelName, uiName)
        monsterObj:CheckLoadTriggerEndEffect()
    end

    self:InitMonsterPosition(mapId)
    self:InitMonsterViewArea(mapId)
end

--设置怪物模型初始视野范围
function XUiRpgMakerGamePlayScene:InitMonsterViewArea(mapId)
    local monsterIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToMonsterIdList(mapId)
    local monsterObj
    for _, monsterId in ipairs(monsterIdList) do
        monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(monsterId)
        monsterObj:SetGameObjectViewArea()
    end
end

--设置怪物模型初始位置
function XUiRpgMakerGamePlayScene:InitMonsterPosition(mapId, isUseSelfObjPosY)
    local monsterIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToMonsterIdList(mapId)
    local monsterObj
    local x, y
    local direction
    local cube
    local cubePosition
    local position
    local transform
    local modelName

    for _, monsterId in ipairs(monsterIdList) do
        monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(monsterId)
        x = XRpgMakerGameConfigs.GetRpgMakerGameMonsterX(monsterId)
        y = XRpgMakerGameConfigs.GetRpgMakerGameMonsterY(monsterId)
        direction = XRpgMakerGameConfigs.GetRpgMakerGameMonsterDirection(monsterId)
        cube = self:GetCubeObj(y, x)
        cubePosition = cube:GetGameObjUpCenterPosition()
        transform = monsterObj:GetTransform()
        modelName = XRpgMakerGameConfigs.GetRpgMakerGameMonsterPrefab(monsterId)
        monsterObj:SetGameObjectPosition(cubePosition)
        monsterObj:ChangeDirectionAction({Direction = direction})
    end
end

function XUiRpgMakerGamePlayScene:InitPlayer(mapId)
    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()

    --加载玩家角色模型
    local roleId = playerObj:GetId()
    local uiName = self:GetUiName()
    local modelName = XRpgMakerGameConfigs.GetRpgMakerGameRoleModelAssetPath(roleId)
    local modelPath = XModelManager.GetModelPath(modelName)
    local sceneObjRoot = self:GetSceneObjRoot()
    playerObj:LoadModel(modelPath, sceneObjRoot, modelName)
    playerObj:SetAnimator(modelName, uiName)

    self:InitPlayerPosition(mapId)
    playerObj:LoadMoveDirectionEffect()
    playerObj:SetMoveDirectionEffectActive(false)
end

--设置玩家角色模型初始位置
function XUiRpgMakerGamePlayScene:InitPlayerPosition(mapId, isUseSelfObjPosY)
    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    local roleId = playerObj:GetId()
    local startPointId = XRpgMakerGameConfigs.GetRpgMakerGameStartPointId(mapId)
    local x = XRpgMakerGameConfigs.GetRpgMakerGameStartPointX(startPointId)
    local y = XRpgMakerGameConfigs.GetRpgMakerGameStartPointY(startPointId)
    local direction = XRpgMakerGameConfigs.GetRpgMakerGameStartPointDirection(startPointId)
    local cube = self:GetCubeObj(y, x)
    local objSize = cube:GetGameObjSize()
    local cubePosition = cube:GetGameObjUpCenterPosition()

    playerObj:SetGameObjectPosition(cubePosition)
    playerObj:ChangeDirectionAction({Direction = direction})
end

--初始化地面
function XUiRpgMakerGamePlayScene:InitCube(mapId)
    local transform = self.GameObject.transform
    local sceneObjRoot = self:GetSceneObjRoot()
    local cube = XUiHelper.TryGetComponent(sceneObjRoot.transform, "ScenePuzzle01_03Hezi01")
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
    local cubeModelPath1 = XRpgMakerGameConfigs.GetRpgMakerGameModelPath("Cube1")
    local cubeModelPath2 = XRpgMakerGameConfigs.GetRpgMakerGameModelPath("Cube2")

    for i = 1, row do
        self.CubeObjs[i] = {}
        firstModelPath = i % 2 ~= 0 and cubeModelPath1 or cubeModelPath2
        secondModelPath = i % 2 == 0 and cubeModelPath1 or cubeModelPath2
        for j = 1, col do
            modelPath = j % 2 ~= 0 and firstModelPath or secondModelPath
            gameObjPositionX = cube.position.x + cubeSize.x * (j - 1)
            gameObjPositionY = cube.position.z + cubeSize.z * (i - 1)
            gameObj = XRpgMakerGameCube.New()
            gameObj:LoadModel(modelPath, sceneObjRoot)
            gameObj:SetGameObjectPosition(Vector3(gameObjPositionX, cube.position.y, gameObjPositionY))
            self.CubeObjs[i][j] = gameObj
        end
    end
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
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath("Block")
    
    for _, blockId in ipairs(blockIdList) do
        blockRow = XRpgMakerGameConfigs.GetRpgMakerGameBlockRow(blockId)
        colList = XRpgMakerGameConfigs.GetRpgMakerGameBlockColList(blockId)

        for colNum, blockStatus in ipairs(colList) do
            if blockStatus == XRpgMakerGameConfigs.XRpgMakerGameBlockStatus.Block then
                cube = self:GetCubeObj(blockRow, colNum)
                cubePosition = cube:GetGameObjUpCenterPosition()
                blockObjTemp = XRpgMakerGameBlock.New()
                blockObjTemp:LoadModel(modelPath, sceneObjRoot)
                blockObjTemp:UpdatePosition({PositionX = blockRow, PositionY = colNum})
                blockObjTemp:SetGameObjectPosition(cubePosition)

                if not self.BlockObjs[blockRow] then
                    self.BlockObjs[blockRow] = {}
                end
                self.BlockObjs[blockRow][colNum] = blockObjTemp
            end
        end
    end
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
end

--后退
function XUiRpgMakerGamePlayScene:BackUp()
    local mapId = self:GetMapId()
    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    playerObj:UpdateObjPosAndDirection()
    playerObj:CheckIsDeath()

    local monsterIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToMonsterIdList(mapId)
    local monsterObj
    for _, monsterId in ipairs(monsterIdList) do
        monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(monsterId)
        if monsterObj then
            monsterObj:UpdateObjPosAndDirection()
            monsterObj:CheckIsDeath()
            monsterObj:RemovePatrolLineObjs()
            monsterObj:SetGameObjectViewArea()
        end
    end

    self:UpdateEndPointObjStatus()
    self:UpdateTriggeObjStatus(mapId)
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

function XUiRpgMakerGamePlayScene:GetUiName()
    return self.UiName
end

function XUiRpgMakerGamePlayScene:GetBlockObj(pointY, pointX)
    return self.BlockObjs and self.BlockObjs[pointY] and self.BlockObjs[pointY][pointX]
end

function XUiRpgMakerGamePlayScene:GetGapObj(gapId)
    return self.GapObjs and self.GapObjs[gapId]
end

function XUiRpgMakerGamePlayScene:GetSceneCamera()
    return self.Camera
end

return XUiRpgMakerGamePlayScene