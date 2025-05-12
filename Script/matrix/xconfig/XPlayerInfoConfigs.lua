XPlayerInfoConfigs = XPlayerInfoConfigs or {}

local TABLE_FETTERS_PATH = "Share/Social/FettersLevel.tab"
local TABLE_CHARACTER_SHOW_SCORE_PATH = "Share/Character/CharacterShowScore.tab"
local TABLE_PLAYER_GENDER = "Share/Player/PlayerGender.tab"

local FettersCfg = {}
local CharacterShowScoreCfg = {}
local PlayerGenderCfg = {}

-- 成员展示选项
XPlayerInfoConfigs.CharactersAppearanceType = {
    All = 0,    --展示全部成员
    Select = 1  --选择展示成员
}

XPlayerInfoConfigs.FashionType = {
    Character = 0,    --成员涂装
    Weapon = 1  --武器涂装
}

function XPlayerInfoConfigs.Init()
    FettersCfg = XTableManager.ReadByIntKey(TABLE_FETTERS_PATH, XTable.XTableFetter, "Level")
    CharacterShowScoreCfg = XTableManager.ReadByIntKey(TABLE_CHARACTER_SHOW_SCORE_PATH, XTable.XTableCharacterShowScore, "CharacterId")
    PlayerGenderCfg = XTableManager.ReadByIntKey(TABLE_PLAYER_GENDER, XTable.XTablePlayerGender, "Id")
end

function XPlayerInfoConfigs.GetLevelByExp(exp)
    local Level = 1
    for k, v in pairs(FettersCfg) do
        Level = k
        if exp == 0 then
            Level = 1
            break
        elseif v.Exp > exp then
            break
        elseif v.Exp == exp then
            if Level >= FettersCfg[#FettersCfg].Level then
                break
            end
            Level = Level + 1
            break
        end
    end
    return Level
end

function XPlayerInfoConfigs.GetLevelDataByExp(exp)
    --默认1级
    local result = FettersCfg[1]
    if exp >= FettersCfg[#FettersCfg].Exp then
        return FettersCfg[#FettersCfg]
    else
        for i = #FettersCfg, 1, -1 do
            if exp >= FettersCfg[i].Exp then
                result = FettersCfg[i + 1]
                break
            end
        end
    end
    return result
end

function XPlayerInfoConfigs.GetCurLevelExp(level)
    if level == 0 then
        return 0
    end
    for i = #FettersCfg, 1, -1 do
        if level == FettersCfg[i].Level then
            return FettersCfg[i].Exp
        end
    end
    --满级
    return FettersCfg[#FettersCfg]
end

function XPlayerInfoConfigs.GetFettersCfg()
    return FettersCfg
end

-- 品质做表头，存放的是对应品质的评分
function XPlayerInfoConfigs.GetCharacterShowScore(characterId)
    if not CharacterShowScoreCfg[characterId] then
        XLog.Error(string.format("XPlayerInfoConfigs.GetCharacterShowScore函数错误，没有角色Id:%s的评分数据，路径为%s"
        , characterId, TABLE_CHARACTER_SHOW_SCORE_PATH))
        return {}
    end
    return CharacterShowScoreCfg[characterId].Quality
end

function XPlayerInfoConfigs.GetPlayerGenderCfgs()
    return PlayerGenderCfg
end 

function XPlayerInfoConfigs.GetPlayerGenderDescById(id)
    local cfg = PlayerGenderCfg[id]
    if cfg then
        return cfg.Desc
    else
        XLog.ErrorTableDataNotFound('GetPlayerGenderDescById', TABLE_PLAYER_GENDER, 'id', id)
    end
end

function XPlayerInfoConfigs.GetPlayerGenderEnDescById(id)
    local cfg = PlayerGenderCfg[id]
    if cfg then
        return cfg.EnDesc
    else
        XLog.ErrorTableDataNotFound('GetPlayerGenderDescById', TABLE_PLAYER_GENDER, 'id', id)
    end
end

function XPlayerInfoConfigs.GetPlayerGenderIconAddressById(id)
    local cfg = PlayerGenderCfg[id]
    if cfg then
        return cfg.IconAddress
    else
        XLog.ErrorTableDataNotFound('GetPlayerGenderDescById', TABLE_PLAYER_GENDER, 'id', id)
    end
end 