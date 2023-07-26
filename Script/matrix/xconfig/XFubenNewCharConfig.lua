XFubenNewCharConfig = XFubenNewCharConfig or {}

local SHARE_NEWCHAR_TEACH = "Share/Fuben/Teaching/TeachingActivity.tab"
local SHARE_NEWCHAR_TREASURE = "Share/Fuben/Teaching/TeachingTreasure.tab"
local CLIENT_CHARMSG = "Client/Fuben/Teaching/CharActiveMsg.tab"
local SHARE_STAGE_DETAIL = "Share/Fuben/Teaching/TeachingRobot.tab"

local NewCharTeachAct = {}
local NewCharTreasure = {}
local NewCharMsg = {}
local NewCharMsgGroup = {}
local NewCharStageDetail = {}

XFubenNewCharConfig.NewCharType = 
{
    YinMianZheGuang = 1,
    KoroChar = 2,
    WeiLa = 3,
    LuoLan = 4,
    Liv = 5,
    Selena = 6,
    Pulao = 7,
    Qishi = 8,
    Hakama = 9,
    SuperKarenina = 10, -- v1.28
    Noan = 11,          -- v1.29
    SuperBianca = 12,   -- v1.30
    Bombinata = 13,     -- v1.31
    Lee = 14,           -- v1.32
    Ayla = 15,          -- v2.0
}

XFubenNewCharConfig.KoroPanelType =
{
    Normal = 1,
    Teaching = 2,
    Challenge = 3,
    Skin = 4,
}

function XFubenNewCharConfig.Init()
    NewCharTeachAct = XTableManager.ReadByIntKey(SHARE_NEWCHAR_TEACH, XTable.XTableTeachingActivity, "Id")
    NewCharTreasure = XTableManager.ReadByIntKey(SHARE_NEWCHAR_TREASURE, XTable.XTableTeachingTreasure, "TreasureId")
    NewCharMsg = XTableManager.ReadByIntKey(CLIENT_CHARMSG, XTable.XTableCharActiveMsg, "Id")
    NewCharStageDetail = XTableManager.ReadByIntKey(SHARE_STAGE_DETAIL, XTable.XTableTeachingRobot, "StageId")
    for _, v in pairs(NewCharMsg) do
        NewCharMsgGroup[v.ActId] = NewCharMsgGroup[v.ActId] or {}
        local grp = NewCharMsgGroup[v.ActId]
        table.insert(grp, v)
    end
    
    for _, v in pairs(NewCharMsgGroup) do
        table.sort(v,  function(a, b)
            if a.Order ~= b.Order then
                return a.Order < b.Order
            end

            return a.Id < b.Id
        end)
    end
end

function XFubenNewCharConfig.GetDataById(id)
    local template = NewCharTeachAct[id]
    if not template then
        XLog.ErrorTableDataNotFound("XFubenNewCharConfig.GetDataById", "TeachingActivity", SHARE_NEWCHAR_TEACH, "Id", tostring(id))
        return
    end
    return template
end

function XFubenNewCharConfig.GetActTemplates()
    return NewCharTeachAct
end

function XFubenNewCharConfig.GetMsgGroupById(id)
    local group = NewCharMsgGroup[id]
    if not group then
        XLog.ErrorTableDataNotFound("XFubenNewCharConfig.GetMsgGroupById", "CharActiveMsg", CLIENT_CHARMSG, "Id", tostring(id))
        return
    end
    return group
end

function XFubenNewCharConfig.GetTreasureCfg(treasureId)
    return NewCharTreasure[treasureId]
end

function XFubenNewCharConfig.GetActivityTime(id)
    local config = XFubenNewCharConfig.GetDataById(id)
    return XFunctionManager.GetTimeByTimeId(config.TimeId)
end

function XFubenNewCharConfig.GetNewCharType(id)
    local config = NewCharTeachAct[id]
    return config.NewCharType
end

--获取详情描述
function XFubenNewCharConfig.GetNewCharDescDetail(id)
    local config = NewCharStageDetail[id]
    return string.gsub(config.DescDetail, "\\n", "\n")
end

function XFubenNewCharConfig.GetNewCharShowFightEventIds(id)
    local config = NewCharStageDetail[id]
    return config.ShowFightEventIds
end

function XFubenNewCharConfig.GetNewCharKoroCfg()
    local cfg = nil

    if NewCharTeachAct then
        for _, v in pairs(NewCharTeachAct) do
            if v.TimeId and v.TimeId ~= 0 and XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
                cfg = v
                break
            end
        end
    end

    return cfg
end

--获取试用角色
function XFubenNewCharConfig:GetTryCharacterIds(id)
    local config = NewCharStageDetail[id]
    return config.RobotId
end

--获取该关卡默认角色类型
function XFubenNewCharConfig:GetTryCharacterCharacterType(id)
    local config = NewCharStageDetail[id]
    return config.CharacterType
end

function XFubenNewCharConfig.GetStageByCharacterId(characterId)
    local templates = XFubenNewCharConfig.GetActTemplates()
    for _, config in pairs(templates) do
        if config.CharacterId == characterId then
            return config.StageId
        end
    end
    return nil
end 