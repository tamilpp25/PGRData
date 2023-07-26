local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XPlanetRunningExploreEntity = require("XUi/XUiPlanet/Explore/XPlanetRunningExploreEntity")
local XPlanetRunningComponentAttr = require("XUi/XUiPlanet/Explore/Component/XPlanetRunningComponentAttr")
local XPlanetRunningComponentMove = require("XUi/XUiPlanet/Explore/Component/XPlanetRunningComponentMove")
local XPlanetRunningComponentLeaderMove = require("XUi/XUiPlanet/Explore/Component/XPlanetRunningComponentLeaderMove")
local XPlanetRunningComponentCamp = require("XUi/XUiPlanet/Explore/Component/XPlanetRunningComponentCamp")
local XPlanetRunningComponentData = require("XUi/XUiPlanet/Explore/Component/XPlanetRunningComponentData")
local XPlanetRunningComponentRotation = require("XUi/XUiPlanet/Explore/Component/XPlanetRunningComponentRotation")
local XPlanetRunningSystemMove = require("XUi/XUiPlanet/Explore/System/XPlanetRunningSystemMove")
local XPlanetRunningSystemRotate = require("XUi/XUiPlanet/Explore/System/XPlanetRunningSystemRotate")
local XPlanetRunningSystemLeaderMove = require("XUi/XUiPlanet/Explore/System/XPlanetRunningSystemLeaderMove")
local XPlanetBubbleManager = require("XUi/XUiPlanet/Explore/Bubble/XPlanetBubbleManager")
local XPlanetRunningSystemAnimation = require("XUi/XUiPlanet/Explore/System/XPlanetRunningSystemAnimation")
local XPlanetRunningComponentAnimation = require("XUi/XUiPlanet/Explore/Component/XPlanetRunningComponentAnimation")
local XPlanetMovieManager = require("XUi/XUiPlanet/Explore/Movie/XPlanetMovieManager")
local CAMP = XPlanetExploreConfigs.CAMP

local EXPLORE_STATUS = {
    NONE = 0,
    START = 1,
    WALK = 2,
    END = 3,
    PAUSE = 4,
}

local TIME_SCALE = XPlanetExploreConfigs.TIME_SCALE

---@class XPlanetRunningExplore
local XPlanetRunningExplore = XClass(nil, "XPlanetRunningExplore")

function XPlanetRunningExplore:Ctor()
    ---@type XPlanetMainScene|XPlanetStageScene
    self.Scene = false

    ---@type XPlanetRunningSystemMove
    self.SystemMove = XPlanetRunningSystemMove.New()

    ---@type XPlanetRunningSystemRotate
    self.SystemRotate = XPlanetRunningSystemRotate.New()

    ---@type XPlanetRunningSystemLeaderMove
    self.SystemLeaderMove = XPlanetRunningSystemLeaderMove.New()

    ---@type XPlanetRunningSystemAnimation
    self.SystemAnimation = XPlanetRunningSystemAnimation.New()

    ---@type XPlanetMovieManager
    self.MovieManager = XPlanetMovieManager.New(self)

    ---@type XPlanetRunningExploreEntity[]
    self.Entities = {}

    ---@type XPlanetRunningExploreEntity[]
    self._DictEntities = {}

    self.LeaderId = false

    self._Data = {
        CharacterData = {},
        MonsterData = {}
    }

    self._RootUi = nil

    self._RootCharacter = false

    self._InStart = false   -- 初始化锁

    ---@type XUiPanelRoleModel[]
    self._Model = {}

    self._Status = EXPLORE_STATUS.NONE

    self._IncId = 0
    self._IndexCaptain = 1
    self._Vector3Zero = Vector3()

    self._SkipFight = false

    self._PauseReason = XPlanetExploreConfigs.PAUSE_REASON.NONE

    self._TimeScale = TIME_SCALE.NORMAL

    self._GridInBuildingRange = {}

    ---@type XPlanetRunningDataDelayCreateModel[]
    self._ModelDelay2Create = {}
    self._GapModelDelay = 10
    self._DurationModelDelay = 0
end

function XPlanetRunningExplore:SetRootUi(rootUi)
    self._RootUi = rootUi
end

function XPlanetRunningExplore:SetBubbleManager()
    if not self._RootUi then
        return
    end
    ---@type XPlanetBubbleManager
    self.PlanetBubbleManager = XPlanetBubbleManager.New(self, self._RootUi, self._RootUi.BubbleRoot,
            self.Scene:GetCamera())
end

function XPlanetRunningExplore:IsRunning()
    return self._Status == EXPLORE_STATUS.WALK
            or self._Status == EXPLORE_STATUS.START
end

function XPlanetRunningExplore:_GetUid()
    self._IncId = self._IncId + 1
    return self._IncId
end

function XPlanetRunningExplore:StartSync()
    self._Status = EXPLORE_STATUS.START
    self:Update(0)
end

function XPlanetRunningExplore:Pause(reason, notSyncPosition)
    if reason then
        self._PauseReason = self._PauseReason | reason
    end
    self._Status = EXPLORE_STATUS.PAUSE
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_PAUSE)
    self.SystemAnimation:LetCharacterAction(self, XPlanetExploreConfigs.ACTION.STAND)

    if reason == XPlanetExploreConfigs.PAUSE_REASON.RESULT then
        return
    end
    if notSyncPosition then
        return
    end

    -- 在暂停时, 可能进行建筑或退出操作, 影响角色属性和存档, 需要同步坐标
    self.SystemLeaderMove:SyncPosition(self)
end

function XPlanetRunningExplore:Resume(reason)
    if reason then
        self._PauseReason = self._PauseReason & (~reason)
    end
    if self._PauseReason ~= XPlanetExploreConfigs.PAUSE_REASON.NONE then
        return
    end
    if self._Status == EXPLORE_STATUS.PAUSE then
        self._Status = EXPLORE_STATUS.WALK
        XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_PAUSE)
    end

    self.SystemAnimation:LetCharacterAction(self, XPlanetExploreConfigs.ACTION.WALK)
end

function XPlanetRunningExplore:IsPauseNotByPlayer()
    return self._PauseReason ~= XPlanetExploreConfigs.PAUSE_REASON.PLAYER
end

function XPlanetRunningExplore:IsPause(reason)
    if reason then
        return self._PauseReason & reason ~= XPlanetExploreConfigs.PAUSE_REASON.NONE
    end
    return self._PauseReason ~= XPlanetExploreConfigs.PAUSE_REASON.NONE
end

function XPlanetRunningExplore:SetData(data)
    self._Data = data
end

function XPlanetRunningExplore:UpdateDataBoss(data)
    if not data then
        local stageData = XDataCenter.PlanetManager.GetStageData()
        data = stageData:GetMonsterData()
    end
    self._Data.MonsterData = data
end

function XPlanetRunningExplore:UpdateDataCharacter(data)
    if not data then
        local stageData = XDataCenter.PlanetManager.GetStageData()
        data = stageData:GetCharacterData()
    end
    self._Data.CharacterData = data
end

function XPlanetRunningExplore:SetScene(scene)
    self.Scene = scene
end

function XPlanetRunningExplore:Update(deltaTime)
    deltaTime = deltaTime * self:GetTimeScale()

    self:UpdateModelDelayCreate()

    if self._Status == EXPLORE_STATUS.START then
        self._Status = EXPLORE_STATUS.WALK
        self._InStart = true
        self:CreateLeader()
        self:InitRootModel()
        self:UpdateCharacters()
        self:UpdateBoss()
        self:HideFollowers()
        self.SystemAnimation:Update(self)
        -- 入场剧情播放
        self:CheckAndPlayMovie()
        self._InStart = false
        return
    end

    if self._Status == EXPLORE_STATUS.WALK then
        self.SystemLeaderMove:Update(self, deltaTime)
        self.SystemRotate:Update(self, deltaTime)
        self.SystemAnimation:Update(self)
        return
    end

    if self._Status == EXPLORE_STATUS.PAUSE then
        self.SystemAnimation:Update(self)
        -- 暂停时也要更新动作
        return
    end
end

---@return XPlanetRunningExploreEntity
function XPlanetRunningExplore:GetEntity(entityId)
    return self._DictEntities[entityId]
end

function XPlanetRunningExplore:GetModel(entityId)
    return self._Model[entityId]
end

function XPlanetRunningExplore:UpdateCharacters(characterDataList)
    -- 创建玩家角色
    characterDataList = characterDataList or self._Data.CharacterData

    local dict = {}
    for i = 1, #characterDataList do
        local data = characterDataList[i]
        local characterId = data.Id
        dict[characterId] = data
    end

    for i = #self.Entities, 1, -1 do
        local entity = self.Entities[i]
        if entity.Camp.CampType == CAMP.PLAYER and entity.Data then
            local characterId = entity.Data.IdFromConfig
            if not dict[characterId] then
                self:RemoveEntity(entity, i)
                dict[characterId] = nil
            end
        end
    end

    for characterId, data in pairs(dict) do
        local entity = self:FindCharacter(characterId)
        if data then
            if not entity then
                entity = self:CreateCharacter(data)
            else
                self:UpdateCharacterAttr(entity, data)
            end
            self:UpdateModel(entity)
        end
    end

    -- 设置队长
    for i = 1, #characterDataList do
        local data = characterDataList[i]
        if data.Life > 0 then
            self:SetCaptainByCharacterId(data.Id)
            break
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_CHARACTER_ENTITY)
end

function XPlanetRunningExplore:CreateMovieEntity(characterId)
    ---@type XPlanetRunningExploreEntity
    local entity = XPlanetRunningExploreEntity.New()
    entity.Id = self:_GetUid()
    entity.Data = XPlanetRunningComponentData.New()
    entity.Data.IdFromConfig = characterId

    local modelName = nil
    if XPlanetCharacterConfigs.CheckHasCharacter(characterId) then
        modelName = XPlanetCharacterConfigs.GetCharacterModel(characterId)
    else
        modelName = XPlanetStageConfigs.GetBossModel(characterId)
    end
    entity.Data.ModelName = modelName
    --
    entity.Attr = XPlanetRunningComponentAttr.New()
    entity.Attr.Life = 1
    -- camp
    entity.Camp = XPlanetRunningComponentCamp.New()
    entity.Camp.CampType = CAMP.MOVIE

    --
    entity.Move = entity.Move or XPlanetRunningComponentMove.New()

    entity.Rotation = XPlanetRunningComponentRotation.New()

    entity.Animation = XPlanetRunningComponentAnimation.New()
    entity.Animation.Action = XPlanetExploreConfigs.ACTION.STAND

    self:AddEntity(entity)
    self:UpdateModel(entity)

    return entity
end

function XPlanetRunningExplore:CreateCharacter(characterData)
    ---@type XPlanetRunningExploreEntity
    local entity = XPlanetRunningExploreEntity.New()
    entity.Id = self:_GetUid()
    entity.Data = XPlanetRunningComponentData.New()
    entity.Data.IdFromConfig = characterData.Id

    -- 属性 属性都要动态计算
    entity.Attr = XPlanetRunningComponentAttr.New()
    self:UpdateCharacterAttr(entity, characterData)

    -- 移动
    entity.Move = XPlanetRunningComponentMove.New()
    entity.Move.Status = XPlanetExploreConfigs.MOVE_STATUS.START

    -- 起点
    local stageData = XDataCenter.PlanetManager.GetStageData()
    local gridId = stageData:GetGridId()
    local tileId = self.Scene:CheckIsTalentPlanet() and self.Scene:GetRoadMapStartPoint() or gridId
    self:UpdatePositionCurrent(entity, tileId)

    -- camp
    entity.Camp = XPlanetRunningComponentCamp.New()
    entity.Camp.CampType = CAMP.PLAYER

    -- rotation
    entity.Rotation = XPlanetRunningComponentRotation.New()

    -- animation
    entity.Animation = XPlanetRunningComponentAnimation.New()

    self:AddEntity(entity)
    return entity
end

---@param entity XPlanetRunningExploreEntity
function XPlanetRunningExplore:CreateModel(entity, delay)
    if self:GetModel(entity.Id) then
        return
    end
    -- boss不能重叠多个模型
    if entity.Camp.CampType == CAMP.BOSS then
        if self:IsBossModelOnGrid(entity.Move.TileIdCurrent) then
            return
        end
    end

    local rootCharacter = self._RootCharacter
    local modelName
    if not entity then
        return
    end
    if not entity.Data then
        return
    end

    local idFromConfig = entity.Data.IdFromConfig
    if entity.Camp.CampType == CAMP.PLAYER then
        modelName = XPlanetCharacterConfigs.GetCharacterModel(idFromConfig)
    elseif entity.Camp.CampType == CAMP.BOSS then
        modelName = XPlanetStageConfigs.GetBossModel(idFromConfig)
    elseif entity.Camp.CampType == CAMP.MOVIE then
        modelName = entity.Data.ModelName
    end

    if modelName then
        local nodeCharacter = CS.UnityEngine.GameObject("Role")
        nodeCharacter.transform:SetParent(rootCharacter.transform, false)
        nodeCharacter.gameObject:SetLayerRecursively(CS.UnityEngine.LayerMask.NameToLayer(HomeSceneLayerMask.HomeCharacter))

        ---@type XUiPanelRoleModel
        local panelModel = XUiPanelRoleModel.New(nodeCharacter)
        local entityId = entity.Id
        self._Model[entityId] = panelModel

        if delay then
            ---@class XPlanetRunningDataDelayCreateModel
            local dataDelay2Create = {
                EntityId = entity.Id,
                ModelName = modelName
            }
            self._ModelDelay2Create[#self._ModelDelay2Create + 1] = (dataDelay2Create)
        else
            self:LoadModel(entity, panelModel, modelName)
        end

        local position = entity.Move.PositionCurrent
        if position then
            panelModel:SetLocalPosition(position)
        end

        -- 初始化时, 更新坐标和旋转
        self:UpdateTransform(entity)
    end
end

---@param entity XPlanetRunningExploreEntity
---@param panelModel XUiPanelRoleModel
function XPlanetRunningExplore:LoadModel(entity, panelModel, modelName, updateTransform)
    panelModel:UpdateRoleModel(modelName, nil, nil, function(model)
        self:OnModelCreate(entity, panelModel, updateTransform)
    end, false, true)
end

---@param entity XPlanetRunningExploreEntity
---@param panelModel XUiPanelRoleModel
function XPlanetRunningExplore:OnModelCreate(entity, panelModel, updateTransform)
    if self.PlanetBubbleManager then
        self.PlanetBubbleManager:UpdateFollowTransform(entity)
    end

    -- 先关掉根节点动画
    panelModel:CloseRootMotion(panelModel)
    local scale = 1.5
    panelModel:GetTransform().localScale = CS.UnityEngine.Vector3(scale, scale, scale)

    local componentXInput = XUiHelper.TryGetComponent(panelModel:GetTransform(), "", "XGoInputHandler")
    if componentXInput then
        componentXInput.enabled = false
    end

    if updateTransform then
        self:UpdateTransform(entity)
    end

    --非Boss出生时播放特效
    if entity.Camp.CampType ~= CAMP.BOSS or not XPlanetStageConfigs.IsSpecialBoss(entity.Data.IdFromConfig) then
        self:PlayBornEffect(entity)
    end

    -- Boss出现
    if self._Status ~= EXPLORE_STATUS.START then
        if entity.Camp.CampType == CAMP.BOSS and
                XPlanetStageConfigs.IsSpecialBoss(entity.Data.IdFromConfig) and
                not self._InStart then
            local model = self:GetModel(entity.Id)
            if model and model:GetTransform() then
                model:HideRoleModel()
                XLuaUiManager.SafeClose("UiPlanetDetail02")
                XEventManager.DispatchEvent(XEventId.EVENT_PLANET_HIDE_EXPLORE_UI)
                XDataCenter.PlanetExploreManager.OpenUiPlanetEncounter(function()
                    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_ON_BOSS_MODEL_CREATE, entity.Id)
                end, XPlanetConfigs.TipType.BossBorn)
            end
        end
    end
end

function XPlanetRunningExplore:FindBoss(bossId)
    for _, entity in pairs(self.Entities) do
        if entity.Camp.CampType == CAMP.BOSS
                and entity.Data.IdFromConfig == bossId
        then
            return entity
        end
    end
    return false
end

function XPlanetRunningExplore:FindCharacter(characterId)
    for i = 1, #self.Entities do
        local entity = self.Entities[i]
        if entity.Camp.CampType == CAMP.PLAYER
                and entity.Data.IdFromConfig == characterId
        then
            return entity, i
        end
    end
    return false
end

function XPlanetRunningExplore:FindBossByIdFromServer(idFromServer)
    for _, entity in pairs(self.Entities) do
        if entity.Camp.CampType == CAMP.BOSS
                and entity.Data.IdFromServer == idFromServer
        then
            return entity
        end
    end
    return false
end

function XPlanetRunningExplore:FindEntityByTransform(transform)
    for entityId, model in pairs(self._Model) do
        if model and model:GetTransform() == transform then
            return self:GetEntity(entityId)
        end
    end
    return false
end

-- 创建boss
function XPlanetRunningExplore:UpdateBoss(data)
    local bossList = data or self._Data.MonsterData
    local dict = {}
    for i = 1, #bossList do
        local bossData = bossList[i]
        local idFromServer = bossData.Id
        local count = bossData.Count or 1
        ---@type XPlanetRunningExploreEntity
        local entity = self:FindBossByIdFromServer(idFromServer)
        if not entity then
            entity = XPlanetRunningExploreEntity.New()
            entity.Data = entity.Data or XPlanetRunningComponentData.New()
            entity.Id = self:_GetUid()
            self:AddEntity(entity)
        end
        dict[entity.Id] = true
        entity.Data.IdFromConfig = bossData.CfgId
        entity.Data.IdFromServer = idFromServer

        -- 属性 属性都要动态计算 客户端取不到了
        entity.Attr = entity.Attr or XPlanetRunningComponentAttr.New()
        entity.Attr.Attack = 0
        entity.Attr.MaxLife = bossData.MaxLife or 1
        entity.Attr.Defense = 0
        entity.Attr.Life = bossData.Life or 1
        entity.Attr.CriticalPercent = 0
        entity.Attr.CriticalDamageAdded = 0
        entity.Attr.Speed = 0
        entity.Data.Amount = count

        -- 移动
        entity.Move = entity.Move or XPlanetRunningComponentMove.New()
        entity.Move.Status = XPlanetExploreConfigs.MOVE_STATUS.START

        -- 起点
        local tileId = bossData.NodeId
        self:UpdatePositionCurrent(entity, tileId)

        entity.Camp = entity.Camp or XPlanetRunningComponentCamp.New()
        entity.Camp.CampType = CAMP.BOSS

        entity.Rotation = XPlanetRunningComponentRotation.New()

        -- animation
        entity.Animation = XPlanetRunningComponentAnimation.New()
    end
    for i = #self.Entities, 1, -1 do
        local entity = self.Entities[i]
        if entity.Camp.CampType == CAMP.BOSS then
            if not dict[entity.Id] then
                self:RemoveEntity(entity, i)
            else
                self:UpdateModel(entity, true)
            end
        end
    end
    self:UpdateBossBubbleAmount()
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_BOSS_ENTITY)
    self:SortModelDelay()
end

---@param entity XPlanetRunningExploreEntity
function XPlanetRunningExplore:RemoveEntity(entity, index)
    self:RemoveModel(entity)
    if not index then
        for i = 1, #self.Entities do
            if self.Entities[i] == entity then
                index = i
                break
            end
        end
    end
    if index then
        table.remove(self.Entities, index)
    end
    if entity then
        self._DictEntities[entity.Id] = nil
    end
end

---@param entity XPlanetRunningExploreEntity
function XPlanetRunningExplore:RemoveModel(entity)
    local entityId = entity.Id
    local model = self:GetModel(entityId)
    self:StopBubbleText(entity)
    self:StopBubble(entity)
    if model then
        model:RemoveRoleModelPool()
        self._Model[entityId] = nil
    end
end

function XPlanetRunningExplore:FindBossOnGrid(gridId)
    for i = 1, #self.Entities do
        local entity = self.Entities[i]
        if entity.Camp.CampType == CAMP.BOSS then
            local entityGridId = entity.Move.TileIdCurrent
            if entityGridId == gridId then
                return entity
            end
        end
    end
end

function XPlanetRunningExplore:IsBossOnGrid(gridId)
    local boss = self:FindBossOnGrid(gridId)
    return boss and true or false
end

function XPlanetRunningExplore:IsSkipFight()
    --return self._SkipFight
    return XDataCenter.PlanetManager.GetStageSkipFight()
end

function XPlanetRunningExplore:SetSkipFight(value)
    --self._SkipFight = value
    XDataCenter.PlanetManager.SetStageSkipFight(value)
end

---@return XPlanetRunningExploreEntity[]
function XPlanetRunningExplore:GetBossListByGrid(gridId)
    local result = {}
    for i = 1, #self.Entities do
        local entity = self.Entities[i]
        if entity.Move.TileIdCurrent == gridId
                and entity.Camp.CampType == CAMP.BOSS
        then
            result[#result + 1] = entity
        end
    end
    return result
end

---@return XPlanetRunningExploreEntity[]
function XPlanetRunningExplore:GetCharacterAlive()
    local result = {}
    for i = 1, #self.Entities do
        local entity = self.Entities[i]
        if entity.Camp.CampType == CAMP.PLAYER
                and entity.Attr.Life > 0
        then
            result[#result + 1] = entity
        end
    end
    return result
end

---@return XPlanetRunningExploreEntity[]
function XPlanetRunningExplore:GetCharacter()
    local result = {}
    for i = 1, #self.Entities do
        local entity = self.Entities[i]
        if entity.Camp.CampType == CAMP.PLAYER then
            result[#result + 1] = entity
        end
    end
    return result
end

---@return XPlanetRunningExploreEntity[]
function XPlanetRunningExplore:GetBoss()
    local result = {}
    for i = 1, #self.Entities do
        local entity = self.Entities[i]
        if entity.Camp.CampType == CAMP.BOSS then
            result[#result + 1] = entity
        end
    end
    return result
end

function XPlanetRunningExplore:GetCaptain()
    for i = 1, #self.Entities do
        local entity = self.Entities[i]
        if entity.Camp.CampType == CAMP.PLAYER
                and entity.Attr.Life > 0
        then
            return entity
        end
    end
end

function XPlanetRunningExplore:GetCaptainTransform()
    local entity = self:GetCaptain()
    if not entity then
        return false
    end
    local model = self:GetModel(entity.Id)
    if not model then
        return false
    end
    return model:GetTransform()
end

function XPlanetRunningExplore:UpdateFollowerPosition()
    -- 更新一下坐标
    local leader = self:GetLeader()
    self.SystemLeaderMove:MoveFollower(self, leader, 0)

    -- 更新一下角度
    self.SystemRotate:UpdateEntity(self, leader, math.huge)
end

-- 更换队长
function XPlanetRunningExplore:SetCaptainByCharacterId(characterId)
    local entity, index = self:FindCharacter(characterId)
    if entity and index ~= self._IndexCaptain then
        table.remove(self.Entities, index)
        table.insert(self.Entities, self._IndexCaptain, entity)

        --self:SaveTeamCharacterIndex()

        -- 更换队长后, 更新坐标和旋转
        self:UpdateFollowerPosition()
        if self:IsRunning() and self._Status == EXPLORE_STATUS.WALK then
            self.SystemAnimation:LetCharacterAction(self, XPlanetExploreConfigs.ACTION.WALK)
        else
            self.SystemAnimation:LetCharacterAction(self, XPlanetExploreConfigs.ACTION.STAND)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_CHARACTER_ENTITY)
    end
end

function XPlanetRunningExplore:SetCaptainByEntityId(entityId)
    local entity, index = self:GetEntity(entityId)
    if entity then
        table.remove(self.Entities, index)
        table.insert(self.Entities, 1, entity)
    end
end

function XPlanetRunningExplore:UpdateTeam(characterIdList)
    local characterData = {}
    for i, characterId in pairs(characterIdList) do
        local data = {
            Id = characterId,
            Life = 1,
            MaxLife = 1,
        }
        characterData[#characterData + 1] = data
    end
    self:UpdateCharacters(characterData)
end

function XPlanetRunningExplore:CreateLeader()
    ---@type XPlanetRunningExploreEntity
    local entity = XPlanetRunningExploreEntity.New()
    entity.Id = self:_GetUid()
    self.LeaderId = entity.Id
    entity.LeaderMove = XPlanetRunningComponentLeaderMove.New()

    -- 移动
    entity.Move = XPlanetRunningComponentMove.New()
    entity.Move.Status = XPlanetExploreConfigs.MOVE_STATUS.START

    -- 起点
    local stageData = XDataCenter.PlanetManager.GetStageData()
    local gridId = stageData:GetGridId()
    local tileId = self.Scene:CheckIsTalentPlanet() and self.Scene:GetRoadMapStartPoint() or gridId
    self:UpdatePositionCurrent(entity, tileId)
    entity.LeaderMove.TileIdOnServer = tileId

    entity.Camp = XPlanetRunningComponentCamp.New()
    entity.Camp.CampType = CAMP.LEADER

    entity.Rotation = XPlanetRunningComponentRotation.New()

    self:AddEntity(entity)
end

function XPlanetRunningExplore:IsCaptain(entityId)
    local captain = self:GetCaptain()
    if not captain then
        return false
    end
    return captain.Id == entityId
end

function XPlanetRunningExplore:InitRootModel()
    if not self._RootCharacter then
        local transformPlanet = self.Scene._Planet._Transform
        local rootCharacter = CS.UnityEngine.GameObject("CharacterRoot")
        rootCharacter.transform:SetParent(transformPlanet, false)
        rootCharacter.gameObject:SetLayerRecursively(CS.UnityEngine.LayerMask.NameToLayer(HomeSceneLayerMask.HomeCharacter))
        self._RootCharacter = rootCharacter
    end
end

function XPlanetRunningExplore:Destroy()
    self:OnDestroy()
    for i = 1, #self.Entities do
        local entity = self.Entities[i]
        entity.Id = 0
        entity.Attr = nil
        entity.Move = nil
        entity.LeaderMove = nil
        entity.Camp = nil
        entity.Rotation = nil
        entity.Data = nil
        entity.Animation = nil
    end
    self.Entities = nil
    self._RootUi = nil
    self._RootCharacter = nil
    self._Model = nil
    self.Scene = nil
    self._Data = nil
    self.SystemMove = nil
    self.SystemRotate = nil
    self.SystemLeaderMove = nil
    self.SystemAnimation = nil
    self.MovieManager = nil
    self.LeaderId = nil
    self._Status = nil
    self._IncId = nil
    self._SkipFight = nil
    self._PauseReason = nil
    self._TimeScale = nil
    self._Vector3Zero = nil
    if self.PlanetBubbleManager then
        self.PlanetBubbleManager:OnDestroy()
        self.PlanetBubbleManager = nil
    end
end

function XPlanetRunningExplore:IsDestroy()
    return not self.Scene
end

function XPlanetRunningExplore:UpdateByStageData()
    local stageData = XDataCenter.PlanetManager.GetStageData()
    self:UpdateDataCharacter(stageData:GetCharacterData())
    self:UpdateDataBoss(stageData:GetMonsterData())
    self:UpdateCharacters()
    self:UpdateBoss()
end

function XPlanetRunningExplore:OnStart()
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_PLAY_ANIMATION_ON_RESULT, self.PlayAnimationWhenResult, self)
end

function XPlanetRunningExplore:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_STAGE, self.UpdateByStageData, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_CHARACTER, self.OnCharacterUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_NEW_EFFECT, self.OnEffectAdd, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_RESUME, self.Resume, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_BUILDING, self.UpdateBuildingRange, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_PLAY_BUBBLE, self.PlayBubbleFromEvent, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_PLAY_BUBBLE_ID, self.PlayBubble2Captain, self)
    self:UpdateDataCharacter()
    self:UpdateCharacters()
end

function XPlanetRunningExplore:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_STAGE, self.UpdateByStageData, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_CHARACTER, self.OnCharacterUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_NEW_EFFECT, self.OnEffectAdd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_RESUME, self.Resume, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_BUILDING, self.UpdateBuildingRange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_PLAY_BUBBLE, self.PlayBubbleFromEvent, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_PLAY_BUBBLE_ID, self.PlayBubble2Captain, self)
end

function XPlanetRunningExplore:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_PLAY_ANIMATION_ON_RESULT, self.PlayAnimationWhenResult, self)
end

---@param entity XPlanetRunningExploreEntity
function XPlanetRunningExplore:UpdateCharacterAttr(entity, characterData)
    XDataCenter.PlanetExploreManager.UpdateCharacterAttrByClient(entity)
    local life = entity.Attr.Life
    local lifeCurrent = characterData.Life or 1
    entity.Attr.Life = lifeCurrent

    -- 首次掉血引导
    if life > lifeCurrent and lifeCurrent > 0
            and XDataCenter.PlanetManager.SetGuideFirstHunt(true)
            and XDataCenter.PlanetManager.CheckGuideOpen() then
        self:Pause(XPlanetExploreConfigs.PAUSE_REASON.GUIDE)
    end
end

---@param entity XPlanetRunningExploreEntity
function XPlanetRunningExplore:UpdateModel(entity, delay)
    if entity.Attr.Life <= 0 then
        self:RemoveModel(entity)
    else
        local model = self:GetModel(entity.Id)
        if not model then
            self:CreateModel(entity, delay)
        end
    end
end

function XPlanetRunningExplore:OnCharacterUpdate()
    self:UpdateDataCharacter()
    self:UpdateCharacters()
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_ON_CHARACTER_ENTITY_UPDATE)
end

function XPlanetRunningExplore:OnEffectAdd(effectIdList)
    for i = 1, #effectIdList do
        local effectId = effectIdList[i]
        local entity = self:GetCaptain()
        local effect = XPlanetStageConfigs.GetBuffEffect2Model(effectId)
        if not string.IsNilOrEmpty(effect) then
            self:PlayEffect2Model(entity, effect)
        end
        self:PlayBubble(entity, effectId)
    end
end

function XPlanetRunningExplore:PlayBubbleFromEvent(effectId)
    local entity = self:GetCaptain()
    local effect = XPlanetStageConfigs.GetBuffEffect2Model(effectId)
    if not string.IsNilOrEmpty(effect) then
        self:PlayEffect2Model(entity, effect)
    end
    self:PlayBubble(entity, effectId)
end

function XPlanetRunningExplore:PlayBubble2Captain(bubbleId)
    local captain = self:GetCaptain()
    if self.PlanetBubbleManager then
        self.PlanetBubbleManager:PlayBubble(bubbleId, captain.Id)
    end
end

---@param entity XPlanetRunningExploreEntity
function XPlanetRunningExplore:PlayBubble(entity, effectId)
    local bubbleControllerId = XPlanetStageConfigs.GetBuffBubbleControllerId(effectId)
    if bubbleControllerId and bubbleControllerId ~= 0 then
        if self.PlanetBubbleManager then
            self.PlanetBubbleManager:PlayBubble(bubbleControllerId, entity.Id)
        end
    end
end

function XPlanetRunningExplore:StopBubble(entity)
    if self.PlanetBubbleManager then
        self.PlanetBubbleManager:StopBubble(entity.Id)
    end
end

---@param entity XPlanetRunningExploreEntity
function XPlanetRunningExplore:UpdatePositionCurrent(entity, tileId)
    entity.Move.TileIdCurrent = tileId
    local position = self.Scene:GetTileHeightPosition(tileId)
    entity.Move.PositionCurrent = position
end

function XPlanetRunningExplore:HideFollowers()
    local characterList = self:GetCharacter()
    for i = 2, #characterList do
        local entity = characterList[i]
        self:HideModel(entity)
    end
end

---@param entity XPlanetRunningExploreEntity
function XPlanetRunningExplore:HideModel(entity)
    local model = self:GetModel(entity.Id)
    if model then
        model:SetLocalPosition(self._Vector3Zero)
    end
    entity.Data.IsHideModel = true
end

---@param entity XPlanetRunningExploreEntity
function XPlanetRunningExplore:ShowModel(entity)
    if entity.Data.IsHideModel then
        entity.Data.IsHideModel = false
        self:PlayBornEffect(entity)
    end
end

function XPlanetRunningExplore:GetTimeScale()
    return self._TimeScale
end

function XPlanetRunningExplore:SetTimeScale(value)
    self._TimeScale = value
end

function XPlanetRunningExplore:IsDoubleTimeScale()
    return self._TimeScale == TIME_SCALE.X2
end

function XPlanetRunningExplore:IsNormalTimeScale()
    return self._TimeScale == TIME_SCALE.NORMAL
end

function XPlanetRunningExplore:ReplayModelAnimation()
    self.SystemAnimation:ReplayModelAnimation(self)
end

---@param entity XPlanetRunningExploreEntity
function XPlanetRunningExplore:PlayEffect2Model(entity, effectPath, isOnScene, callback)
    local model = self:GetModel(entity.Id)
    if model then
        if isOnScene then
            local transform = model:GetTransform()
            if transform then
                local up = transform.localRotation * Vector3.up
                local position
                if isOnScene then
                    local height = 1
                    position = up.normalized * height + transform.localPosition
                else
                    position = transform.localPosition
                end

                local rotation = transform.localRotation
                self.Scene:PlayEffect(effectPath, position, rotation, callback)
            end
        else
            model:LoadEffect(effectPath, nil, nil, nil, true)
        end
        return
    end
    if not entity.Move.PositionCurrent then
        return
    end
    if not entity.Rotation.RotationCurrent then
        return
    end
    self.Scene:PlayEffect(effectPath, entity.Move.PositionCurrent, entity.Rotation.RotationCurrent, callback)
end

function XPlanetRunningExplore:UpdateBossBubbleAmount()
    local dictGrid = {}
    for i = 1, #self.Entities do
        local entity = self.Entities[i]
        if entity.Camp.CampType == CAMP.BOSS then
            local gridId = entity.Move.TileIdCurrent
            local dataGrid = dictGrid[gridId]
            if not dataGrid then
                dataGrid = {
                    Amount = 0,
                    Entity = false
                }
                dictGrid[gridId] = dataGrid
            end
            dataGrid.Amount = dataGrid.Amount + entity.Data.Amount

            if not dataGrid.Entity then
                local model = self:GetModel(entity.Id)
                if model then
                    dataGrid.Entity = entity
                end
            end

        end
    end
    for gridId, dataGrid in pairs(dictGrid) do
        local amount = dataGrid.Amount
        if amount > 1 then
            self:PlayBubbleText(dataGrid.Entity, "X" .. amount)
        else
            self:StopBubbleText(dataGrid.Entity)
        end
    end
end

function XPlanetRunningExplore:IsBossModelOnGrid(gridId)
    for entityId, model in pairs(self._Model) do
        local entity = self:GetEntity(entityId)
        if entity.Camp.CampType == CAMP.BOSS then
            if entity.Move.TileIdCurrent == gridId then
                return true
            end
        end
    end
    return false
end

function XPlanetRunningExplore:ResetLeaderPosition()
    local entity = self:GetLeader()
    local tileId = self.Scene:GetRoadMapStartPoint()
    self:UpdatePositionCurrent(entity, tileId)
    entity.Move.TileIdStart = false
    entity.Move.TileIdEnd = false
    entity.Move.Status = XPlanetExploreConfigs.MOVE_STATUS.START
    entity.LeaderMove.Path = {}
    self:HideFollowers()
    self:ReplayModelAnimation()
end

---@param entity XPlanetRunningExploreEntity
function XPlanetRunningExplore:PlayBubbleText(entity, text)
    if self.PlanetBubbleManager then
        self.PlanetBubbleManager:PlayBubbleText(entity.Id, text)
    end
end

---@param entity XPlanetRunningExploreEntity
function XPlanetRunningExplore:StopBubbleText(entity)
    if self.PlanetBubbleManager then
        self.PlanetBubbleManager:StopBubbleText(entity.Id)
    end
end

function XPlanetRunningExplore:PlayMovie(movieId, fininshCb)
    -- 检测缓存。当通关了且没勾重播按钮则不能播放剧情
    local stageId = XDataCenter.PlanetManager.GetStageData():GetStageId()
    local isPlayCache = XDataCenter.PlanetManager.GetBtnStoryCache()
    local checkIsPass = XDataCenter.PlanetManager.GetViewModel():CheckStageIsPass(stageId)
    if checkIsPass then
        local resultFromServer = XDataCenter.PlanetExploreManager.GetResult()
        if resultFromServer and resultFromServer:GetFirstPass() then
            checkIsPass = false
        end
    end

    if not isPlayCache and checkIsPass then
        if fininshCb then
            fininshCb()
        end
        return
    end

    -- 剧情播放、暂停玩法
    self:Pause(XPlanetExploreConfigs.PAUSE_REASON.MOVIE)

    -- 剧情镜头
    self.Scene:UpdateCamInMovie(self:GetCaptainTransform())

    -- 隐藏非剧情Ui
    if self._RootUi then
        self._RootUi:HideUi()
    end

    -- 隐藏正在播放的气泡
    if self.PlanetBubbleManager then
        self.PlanetBubbleManager:StopAllBubble()
        self.PlanetBubbleManager:HideAllBubbleText()
    end

    -- 隐藏其他小人
    for k, entity in pairs(self.Entities) do
        local model = self:GetModel(entity.Id)
        if model and not XTool.UObjIsNil(model.GameObject) then
            model.GameObject:SetActiveEx(false)
        end
    end
    -- 生成剧情专用小人
    local movieInfo = XPlanetExploreConfigs.GetMovieInfoById(movieId)
    local movieEntitys = {}
    local charIds = {}
    for k, v in pairs(movieInfo) do
        if not movieEntitys[v.PlanetCharacterId] and XTool.IsNumberValid(v.PlanetCharacterId) then
            local entity = self:CreateMovieEntity(v.PlanetCharacterId)
            local model = self:GetModel(entity.Id)
            model:GetTransform().name = model:GetTransform().name .. "Story"
            movieEntitys[v.PlanetCharacterId] = entity
        end
    end
    for charId, v in pairs(movieEntitys) do
        table.insert(charIds, charId)
    end

    -- 队长坐标
    local firstEntity = movieEntitys[charIds[1]]
    if firstEntity then
        local modelF = self:GetModel(firstEntity.Id)
        local pos, rotation = self:GetEntityBeforePosAndRot(self:GetLeader())
        modelF:SetLocalPosition(pos)
        modelF:GetTransform().rotation = rotation

        -- local modelCaptain = self:GetModel(self:GetCaptain().Id)
        -- modelF:GetTransform():LookAt(modelCaptain:GetTransform().position, Vector3.back)
    end

    -- boss坐标
    local secondEntity = movieEntitys[charIds[2]]
    if secondEntity then
        local modelS = self:GetModel(secondEntity.Id)
        local pos, rotation = self:GetEntityNextPosAndRot(self:GetLeader())
        modelS:SetLocalPosition(pos)
        modelS:GetTransform().rotation = rotation

        -- 互相看着对方
        local modelF = self:GetModel(firstEntity.Id)
        local v3 = modelS:GetTransform().position - self.Scene:GetPlanetPosition() -- 需要以一个轴旋转人物、该轴是圆心指向角色的向量
        modelS:GetTransform():LookAt(modelF:GetTransform().position, v3)
    end

    if self.MovieManager then
        local doFinCb = function()
            if self._RootUi then
                -- 播放剧情关闭过度黑幕
                self._RootUi:PlayAnimation("DarkDisable")
                -- 恢复非剧情Ui
                self._RootUi:ShowUi()
            end
            if not self.Scene then
                return
            end
            -- 恢复场景镜头
            self.Scene:UpdateCameraInStage()
            if fininshCb then
                fininshCb()
            end
            -- 恢复其他小人
            for k, entity in pairs(self.Entities) do
                local model = self:GetModel(entity.Id)
                if model and not XTool.UObjIsNil(model.GameObject) then
                    model.GameObject:SetActiveEx(true)
                end
            end

            -- 恢复text
            if self.PlanetBubbleManager then
                self.PlanetBubbleManager:ShowAllBubbleText()
            end

            -- 删除剧情专用小人
            for k, entity in pairs(movieEntitys) do
                self:RemoveEntity(entity)
            end

            self:Resume(XPlanetExploreConfigs.PAUSE_REASON.MOVIE)
        end
        self.MovieManager:Play(movieId, movieEntitys, doFinCb)
    end
end

function XPlanetRunningExplore:SkipMovie()
    if self.MovieManager then
        self.MovieManager:Skip()
    end
end

function XPlanetRunningExplore:IsPlayingMovie()
    if self._PauseReason & XPlanetExploreConfigs.PAUSE_REASON.MOVIE > 0 then
        return true
    end
end

function XPlanetRunningExplore:PlayBornEffect(entity)
    -- 初始创造和主界面的不播放音效
    if XLuaUiManager.IsUiShow("UiPlanetLoading") or XLuaUiManager.IsUiShow("UiPlanetMain") then
        return
    end
    local effectPath = XPlanetConfigs.GetEffectChangeRole()
    self:PlayEffect2Model(entity, effectPath, true)
end

function XPlanetRunningExplore:PlayAnimationWhenResult(isWin)
    self:Pause(XPlanetExploreConfigs.PAUSE_REASON.RESULT)

    local bossList = self:GetBoss()
    for i = 1, #bossList do
        local boss = bossList[i]
        local model = self:GetModel(boss.Id)
        if model then
            model:HideRoleModel()
        end
    end

    local characterList = self:GetCharacterAlive()
    for i = 1, #characterList do
        local entity = characterList[i]
        if isWin then
            entity.Animation.ActionOnce = XPlanetExploreConfigs.ACTION.WIN
        else
            entity.Animation.Action = XPlanetExploreConfigs.ACTION.FAIL
        end
    end
end

---@param entity XPlanetRunningExploreEntity
---@return Vector3,Quaternion 下一格表面坐标,下一格子朝向本格方向
function XPlanetRunningExplore:GetEntityNextPosAndRot(entity)
    if not entity then
        XLog.Error("XPlanetRunningExplore:GetEntityBeforePosAndRot Error! entity is Null!")
        return false
    end
    local position = entity.Move.PositionTarget
    local rotation = entity.Rotation.RotationCurrent

    local curTile = entity.Move.TileIdCurrent
    local nextPosition = self.Scene:GetTileHeightPosition(self.Scene:GetNextRoadTileId(curTile))
    rotation = CS.UnityEngine.Quaternion.LookRotation(nextPosition - position, self.Scene:GetTileUp(curTile))
    position = nextPosition
    return position, rotation
end

---@param entity XPlanetRunningExploreEntity
---@return Vector3,Quaternion 上一格表面坐标,上一格子朝向本格方向
function XPlanetRunningExplore:GetEntityBeforePosAndRot(entity)
    if not entity then
        XLog.Error("XPlanetRunningExplore:GetEntityBeforePosAndRot Error! entity is Null!")
        return false
    end
    local position = entity.Move.PositionTarget
    local rotation = entity.Rotation.RotationCurrent

    local curTile = entity.Move.TileIdCurrent
    local beforePosition = self.Scene:GetTileHeightPosition(self.Scene:GetBeforeRoadTileId(curTile))
    rotation = CS.UnityEngine.Quaternion.LookRotation(position - beforePosition, self.Scene:GetTileUp(curTile))
    position = beforePosition
    return position, rotation
end

---@return XPlanetRunningExploreEntity
function XPlanetRunningExplore:GetLeader()
    return self._DictEntities[self.LeaderId]
end

---@param entity XPlanetRunningExploreEntity
function XPlanetRunningExplore:AddEntity(entity)
    self.Entities[#self.Entities + 1] = entity
    self._DictEntities[entity.Id] = entity
end

function XPlanetRunningExplore:UpdateBuildingRange()
    self._GridInBuildingRange = {}
    local buildingList = self.Scene:GetBuildingList()
    for _, building in pairs(buildingList) do
        local range2Cycle = building:GetRangeTileList()
        for cycle, listGrid in pairs(range2Cycle) do
            for i = 1, #listGrid do
                local gridId = listGrid[i]
                self._GridInBuildingRange[gridId] = true
            end
        end
    end
end

function XPlanetRunningExplore:IsGridInBuildingRange(gridId)
    return self._GridInBuildingRange[gridId]
end

function XPlanetRunningExplore:CheckAndPlayMovie()
    if self.Scene:CheckIsTalentPlanet() then
        return
    end
    local stageId = XDataCenter.PlanetManager.GetStageData():GetStageId()
    local movieId = XPlanetExploreConfigs.GetMovieIdByCheckControllerStage(XPlanetExploreConfigs.MOVIE_CONDITION.ENTER_STAGE, stageId)
    if movieId and XDataCenter.PlanetManager.GetIsNotCountinueEnterGame() then
        self:PlayMovie(movieId, function()
            self.Scene:UpdateCameraInStage(true, true)
            XEventManager.DispatchEvent(XEventId.EVENT_PLANET_STAGE_MOVIE_STOP)
        end)
    end
end

function XPlanetRunningExplore:IsOnStartPoint(gridId)
    return self.Scene:GetRoadMapStartPoint() == gridId
end

-- 本来应该写个system， 但是临近上线， 就不提交新文件了
function XPlanetRunningExplore:UpdateModelDelayCreate()
    self._DurationModelDelay = self._DurationModelDelay + 1
    if self._DurationModelDelay > self._GapModelDelay then
        self._DurationModelDelay = 0
        if #self._ModelDelay2Create > 0 then
            ---@type XPlanetRunningDataDelayCreateModel
            local data = self._ModelDelay2Create[1]
            table.remove(self._ModelDelay2Create, 1)
            local entityId = data.EntityId
            local entity = self:GetEntity(entityId)
            if entity and entity.Attr.Life > 0 then
                local model = self:GetModel(entityId)
                if model then
                    local modelName = data.ModelName
                    self:LoadModel(entity, model, modelName, true)
                end
            end
        end
    end
end

function XPlanetRunningExplore:UpdateTransform(entity)
    if entity.Move.Status == XPlanetExploreConfigs.MOVE_STATUS.START then
        self.SystemMove:Update(self, entity, 0, true)
        self.SystemRotate:UpdateEntity(self, entity, math.huge)
        entity.Move.Status = XPlanetExploreConfigs.MOVE_STATUS.START
    end
end

function XPlanetRunningExplore:SortModelDelay()
    local dictGrid = {}
    local startTileId = self:GetLeader().Move.TileIdCurrent
    local nextTileId = startTileId
    for i = 1, 999 do
        nextTileId = self.Scene:GetNextRoadTileId(nextTileId)
        dictGrid[nextTileId] = i
        if nextTileId == startTileId then
            break
        end
    end

    for i = #self._ModelDelay2Create, 1, -1 do
        local data = self._ModelDelay2Create[i]
        local entityId = data.EntityId
        local entity = self:GetEntity(entityId)
        if not entity then
            table.remove(self._ModelDelay2Create, i)
        end
    end

    ---@param a XPlanetRunningDataDelayCreateModel
    ---@param b XPlanetRunningDataDelayCreateModel
    table.sort(self._ModelDelay2Create, function(a, b)
        local entityIdB = b.EntityId
        local entityB = self:GetEntity(entityIdB)
        local tileIdB = entityB.Move.TileIdCurrent

        local entityIdA = a.EntityId
        local entityA = self:GetEntity(entityIdA)
        local tileIdA = entityA.Move.TileIdCurrent

        local priorityB = dictGrid[tileIdB]
        local priorityA = dictGrid[tileIdA]

        return priorityA < priorityB
    end)
end

return XPlanetRunningExplore
