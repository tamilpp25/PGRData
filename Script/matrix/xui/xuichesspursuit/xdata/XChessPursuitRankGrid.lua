local type = type
local tableInsert = table.insert
local tableSort = table.sort

local Default = {
    Grid = 0, --布阵格id
    Hurt = 0,
    CharacterIds = {},
    CharacterHeadInfoList = {},
    RobotIds = {},
    UsedCardIds = {},
}

local XChessPursuitRankGrid = XClass(nil, "XChessPursuitRankGrid")

function XChessPursuitRankGrid:Ctor(data)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self:UpdateData(data)
end

function XChessPursuitRankGrid:UpdateData(data)
    if not data then
        return
    end
    self.Hurt = data.Hurt
    self.Grid = data.Grid
    self.CharacterIds = data.CharacterIds
    self.CharacterHeadInfoList = data.CharacterHeadInfoList
    self.RobotIds = data.RobotIds
    self.UsedCardIds = data.UsedCardIds

    self:UpdateCharacterIdToLiberateLvDic()
end

function XChessPursuitRankGrid:UpdateCharacterIdToLiberateLvDic()
    self.CharacterHeadInfoDic = {}
    for index, characterId in ipairs(self.CharacterIds) do
        if self.CharacterHeadInfoList[index] then
            self.CharacterHeadInfoDic[characterId] = self.CharacterHeadInfoList[index]
        end
    end
end

function XChessPursuitRankGrid:GetCharacterIdList(gridTeamIndex, playerId)
    local characterIdList = {}
    local isHaveCaptain = false
    for _, characterId in ipairs(self.CharacterIds) do
        if characterId > 0 then
            if not isHaveCaptain and XDataCenter.ChessPursuitManager.IsRankCaptain(characterId) then
                isHaveCaptain = true
                tableInsert(characterIdList, characterId, 1)
            else
                tableInsert(characterIdList, characterId)
            end
        end
    end
    for _, robotId in ipairs(self.RobotIds) do
        if robotId > 0 then
            if not isHaveCaptain and XDataCenter.ChessPursuitManager.IsRankCaptain(characterId) then
                isHaveCaptain = true
                tableInsert(characterIdList, robotId, 1)
            else
                tableInsert(characterIdList, robotId)
            end
        end
    end
    return characterIdList
end

function XChessPursuitRankGrid:GetHurt()
    return self.Hurt
end

function XChessPursuitRankGrid:GetUsedCardIds()
    return self.UsedCardIds
end

function XChessPursuitRankGrid:GetGrid()
    return self.Grid
end

function XChessPursuitRankGrid:GetCharacterHeadInfo(characterId)
    return characterId and self.CharacterHeadInfoDic[characterId] or {}
end

return XChessPursuitRankGrid