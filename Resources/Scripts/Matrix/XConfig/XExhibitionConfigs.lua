XExhibitionConfigs = XExhibitionConfigs or {}

local TABLE_CHARACTER_EXHIBITION = "Client/Exhibition/Exhibition.tab"
local TABLE_CHARACTER_EXHIBITION_LEVEL = "Client/Exhibition/ExhibitionLevel.tab"
local TABLE_CHARACTER_GROW_TASK_INFO = "Share/Exhibition/ExhibitionReward.tab"

local DefaultPortraitImagePath = CS.XGame.ClientConfig:GetString("DefaultPortraitImagePath")
local ExhibitionLevelPoint = {}
local ExhibitionConfig = {}
local ExhibitionGroupNameConfig = {}
local ExhibitionGroupLogoConfig = {}
local ExhibitionGroupDescConfig = {}
local CharacterExhibitionLevelConfig = {}
local GrowUpTasksConfig = {}
local CharacterGrowUpTasksConfig = {}
local CharacterGrowUpTasksConfigByType = {}
local CharacterHeadPortrait = {}
local CharacterGraduationPortrait = {}
local ExhibitionConfigByTypeAndPort = {}
local ExhibitionConfigByTypeAndGroup = {}
local CharacterToExhibitionTypeTable = {}
local InVisibleGroupTable = {}
function XExhibitionConfigs.Init()
    CharacterExhibitionLevelConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_EXHIBITION_LEVEL, XTable.XTableExhibitionLevel, "LevelId")
    ExhibitionConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_EXHIBITION, XTable.XTableCharacterExhibition, "Id")
    for _, v in pairs(ExhibitionConfig) do
        if v.Port ~= nil then
            CharacterHeadPortrait[v.CharacterId] = v.HeadPortrait
            CharacterGraduationPortrait[v.CharacterId] = v.GraduationPortrait
            ExhibitionGroupNameConfig[v.GroupId] = v.GroupName
            ExhibitionGroupLogoConfig[v.GroupId] = v.GroupLogo
            ExhibitionGroupDescConfig[v.GroupId] = v.GroupDescription
            if v.Type and not ExhibitionConfigByTypeAndPort[v.Type] then
                ExhibitionConfigByTypeAndPort[v.Type] = {}
                ExhibitionConfigByTypeAndGroup[v.Type] = {}
            end
            ExhibitionConfigByTypeAndPort[v.Type][v.Port] = v
            ExhibitionConfigByTypeAndGroup[v.Type][v.GroupId] = v
            if v.Type then
                if not InVisibleGroupTable[v.Type] then InVisibleGroupTable[v.Type] = {} end
                if InVisibleGroupTable[v.Type][v.GroupId] == nil then InVisibleGroupTable[v.Type][v.GroupId] = true end
                if v.InVisible == 1 then InVisibleGroupTable[v.Type][v.GroupId] = false end
            end
        end
        if v.CharacterId and v.CharacterId ~= 0 and not CharacterToExhibitionTypeTable[v.CharacterId] then
            CharacterToExhibitionTypeTable[v.CharacterId] = v.Type
        end
    end
    GrowUpTasksConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_GROW_TASK_INFO, XTable.XTableExhibitionReward, "Id")
    for task, v in pairs(GrowUpTasksConfig) do
        if CharacterGrowUpTasksConfig[v.CharacterId] == nil then
            CharacterGrowUpTasksConfig[v.CharacterId] = {}
        end
        CharacterGrowUpTasksConfig[v.CharacterId][task] = v
        local type = CharacterToExhibitionTypeTable[v.CharacterId] or 1
        if not CharacterGrowUpTasksConfigByType[type] then CharacterGrowUpTasksConfigByType[type] = {} end
        if not CharacterGrowUpTasksConfigByType[type][v.Id] then
            CharacterGrowUpTasksConfigByType[type][v.Id] = v
        end
    end
    ExhibitionLevelPoint[1] = CS.XGame.ClientConfig:GetInt("ExhibitionLevelPoint_01")
    ExhibitionLevelPoint[2] = CS.XGame.ClientConfig:GetInt("ExhibitionLevelPoint_02")
    ExhibitionLevelPoint[3] = CS.XGame.ClientConfig:GetInt("ExhibitionLevelPoint_03")
    ExhibitionLevelPoint[4] = CS.XGame.ClientConfig:GetInt("ExhibitionLevelPoint_04")
end

function XExhibitionConfigs.GetDefaultPortraitImagePath()
    return DefaultPortraitImagePath
end

function XExhibitionConfigs.GetExhibitionLevelPoints()
    return ExhibitionLevelPoint
end

function XExhibitionConfigs.GetGrowUpLevelMax()
    local maxPoint = 0
    for i = 1, 4 do
        maxPoint = maxPoint + ExhibitionLevelPoint[i]
    end
    return maxPoint
end

function XExhibitionConfigs.GetExhibitionConfig()
    return ExhibitionConfig
end

function XExhibitionConfigs.GetExhibitionPortConfigByType(showType)
    if not showType then return ExhibitionConfig end
    return ExhibitionConfigByTypeAndPort[showType] or {}
end

function XExhibitionConfigs.GetExhibitionGroupNameConfig()
    return ExhibitionGroupNameConfig
end

function XExhibitionConfigs.GetExhibitionGroupConfigByType(showType)
    if not showType then return ExhibitionConfig end
    return ExhibitionConfigByTypeAndGroup[showType] or {}
end

function XExhibitionConfigs.GetExhibitionConfigByTypeAndGroup(showType, groupId)
    return ExhibitionConfigByTypeAndGroup[showType][groupId]
end

function XExhibitionConfigs.GetExhibitionTypeByCharacterId(characterId)
    return CharacterToExhibitionTypeTable[characterId]
end

function XExhibitionConfigs.GetExhibitionGroupLogoConfig()
    return ExhibitionGroupLogoConfig
end

function XExhibitionConfigs.GetExhibitionGroupDescConfig()
    return ExhibitionGroupDescConfig
end

function XExhibitionConfigs.GetExhibitionInVisbleGroupTable(exhibitionType)
    return InVisibleGroupTable[exhibitionType] or {}
end

function XExhibitionConfigs.GetIsExhibitionInVisbleGroup(exhibitionType, groupId)
    return InVisibleGroupTable[exhibitionType] and InVisibleGroupTable[exhibitionType][groupId] or false
end

function XExhibitionConfigs.GetExhibitionLevelConfig()
    return CharacterExhibitionLevelConfig
end

function XExhibitionConfigs.GetCharacterGrowUpTasks(characterId)
    local config = CharacterGrowUpTasksConfig[characterId]
    if not config then
        XLog.Error("XExhibitionConfigs.GetCharacterGrowUpTasks error: 角色解放配置错误：characterId: " .. characterId .. " ,path: " .. TABLE_CHARACTER_GROW_TASK_INFO)
        return
    end
    return config
end

function XExhibitionConfigs.GetCharacterGrowUpTask(characterId, level)
    local levelTasks = XExhibitionConfigs.GetCharacterGrowUpTasks(characterId)
    for _, config in pairs(levelTasks) do
        if config.LevelId == level then
            return config
        end
    end
end

function XExhibitionConfigs.GetCharacterGrowUpTasksConfig()
    return CharacterGrowUpTasksConfig
end

function XExhibitionConfigs.GetExhibitionGrowUpLevelConfig(level)
    return CharacterExhibitionLevelConfig[level]
end

function XExhibitionConfigs.GetExhibitionLevelNameByLevel(level)
    return CharacterExhibitionLevelConfig[level].Name or ""
end

function XExhibitionConfigs.GetExhibitionLevelDescByLevel(level)
    return CharacterExhibitionLevelConfig[level].Desc or ""
end

function XExhibitionConfigs.GetExhibitionLevelIconByLevel(level)
    return CharacterExhibitionLevelConfig[level].LevelIcon or ""
end

function XExhibitionConfigs.GetCharacterHeadPortrait(characterId)
    return CharacterHeadPortrait[characterId]
end

function XExhibitionConfigs.GetCharacterGraduationPortrait(characterId)
    return CharacterGraduationPortrait[characterId]
end

function XExhibitionConfigs.GetGrowUpTasksConfig()
    return GrowUpTasksConfig
end

function XExhibitionConfigs.GetGrowUpTasksConfigByType(exhibitionType)
    if not exhibitionType then return GrowUpTasksConfig end
    return CharacterGrowUpTasksConfigByType[exhibitionType] or {}
end