---@class XTempleActivityData
local XTempleActivityData = XClass(nil, "XTempleActivityData")

function XTempleActivityData:Ctor()
    self._ActivityId = nil
    if XMain.IsDebug then
        self._ActivityId = 1
    end
    self._StageDict = {}
    ---@type XTempleStageData
    self._Stage2Continue = {}

    self._IsInstantiate = false
    self._ServerData = nil

    self._SelectedCharacter = nil

    self._RolePicData = {}
end

---@param model XTempleModel
function XTempleActivityData:Instantiate(model)
    if not self._ServerData then
        return
    end
    local serverData = self._ServerData
    self._ActivityId = serverData.ActivityId
    for i = 1, #serverData.StageRecords do
        local stage = serverData.StageRecords[i]
        self._StageDict[stage.StageId] = {
            Score = stage.Score
        }
    end

    self._Stage2Continue = {}
    if serverData.TempleFairDataList then
        for i = 1, #serverData.TempleFairDataList do
            local stage = serverData.TempleFairDataList[i]
            local stageId = stage.StageId
            local chapter = model:GetChapterId(stageId)
            self._Stage2Continue[chapter] = stage
        end
    elseif serverData.TempleFairData then
        local stage = serverData.TempleFairData
        local stageId = stage.StageId
        local chapter = model:GetChapterId(stageId)
        self._Stage2Continue[chapter] = stage
    end

    self._IsInstantiate = true
    self._ServerData = nil

    self._RolePicData = serverData.RolePicDataDic
end

function XTempleActivityData:SetServerData(serverData, model)
    self._ServerData = serverData
    if self._IsInstantiate then
        self:Instantiate(model)
    end
end

function XTempleActivityData:IsStageHasRecord(stageId)
    local stage = self._StageDict[stageId]
    if stage then
        return true
    end
    return false
end

function XTempleActivityData:GetStageScore(stageId)
    local stage = self._StageDict[stageId]
    if stage then
        return stage.Score
    end
    return 0
end

function XTempleActivityData:GetActivityId()
    return self._ActivityId
end

function XTempleActivityData:GetStageId2Continue(chapter)
    local stage = self:GetStage2Continue(chapter)
    return stage and stage.StageId
end

function XTempleActivityData:SetStage2Continue(value, chapter)
    self._Stage2Continue[chapter] = value
end

function XTempleActivityData:GetStage2Continue(chapter)
    local stage = self._Stage2Continue[chapter]
    if stage then
        if stage.StageStartTime == 0 then
            return false
        end
    end
    return stage
end

function XTempleActivityData:HasStage2Continue(chapter)
    local data = self:GetStage2Continue(chapter)
    if data and data.StageId ~= 0 then
        return true
    end
    return false
end

---@param model XTempleModel
function XTempleActivityData:GetSelectedCharacterId(model)
    if not self._SelectedCharacter then
        local target
        --默认角色规则
        --玩家选中某一情人节关卡，进入关卡准备界面，系统会默认选中好感度最高的角色作为当前角色0若玩家未完成所有情人节关卡，
        --准备界面里的角色立绘显示好感度最高且未解锁相册的角色立绘
        --若玩家完成所有情人节关卡，准备界面里的角色立绘随机显示LoverDialogue里的角色立绘
        if self:HasAllPhotoData(model) then
            local configs = model:GetAllNpcCouple()
            local array = {}
            for i, config in pairs(configs) do
                array[#array + 1] = i
                -- 随便选一个作为默认
                target = config.NpcId
            end
            local max = #array
            if max > 1 then
                local index = math.random(1, max)
                local key = array[index]
                local config = configs[key]
                target = config.NpcId
            end
        else
            local configs = model:GetAllNpcCouple()
            local lv = -1
            local id = 0
            for i, config in pairs(configs) do
                local characterId = config.NpcId
                if not self:HasPhotoData(characterId) then
                    local trustLv = XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(characterId)
                    if trustLv ~= lv then
                        if trustLv > lv then
                            target = characterId
                            lv = trustLv
                            id = config.Id
                        end
                    else
                        if config.Id < id then
                            target = characterId
                            id = config.Id
                        end
                    end
                end
            end
            if not target then
                for i, config in pairs(configs) do
                    target = config.NpcId
                end
            end
        end

        self:SetSelectedCharacterId(target)
    end
    return self._SelectedCharacter
end

function XTempleActivityData:SetSelectedCharacterId(characterId)
    self._SelectedCharacter = characterId
end

function XTempleActivityData:GetSelectedCharacterKey()
    return "XTempleSelectedCharacter" .. XPlayer.Id
end

function XTempleActivityData:GetAllPhotoData()
    return self._RolePicData
end

function XTempleActivityData:GetPhotoData(characterId)
    if self._RolePicData then
        local data = self._RolePicData[characterId]
        if data then
            return data
        end
    end
    return false
end

function XTempleActivityData:HasPhotoData(characterId)
    if self._RolePicData then
        local data = self._RolePicData[characterId]
        if data then
            return true
        end
    end
    return false
end

function XTempleActivityData:HasAllPhotoData(model)
    local configs = model:GetAllNpcCouple()
    for i, config in pairs(configs) do
        local characterId = config.NpcId
        if not self:HasPhotoData(characterId) then
            return false
        end
    end
    return true
end

return XTempleActivityData
