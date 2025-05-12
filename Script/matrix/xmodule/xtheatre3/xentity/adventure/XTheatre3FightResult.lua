---@class XTheatre3StageFightResult
---@field StageId number
---@field CharacterMagicIdListRecord number[]
---@field MagicIdDamageRecord number[]

---@class XTheatre3FightResult
local XTheatre3FightResult = XClass(nil, "XTheatre3FightResult")

function XTheatre3FightResult:Ctor()
    self:InitData()
end

function XTheatre3FightResult:InitData()
    ---@type XTheatre3StageFightResult
    self._NowRecord = {}
    ---@type XTheatre3StageFightResult
    self._PrevRecord = {}
end

--region Getter
function XTheatre3FightResult:GetCharacterMagicDamageRecordData(characterId, magicId)
    local nowValue = 0
    local prevValue = 0
    if not XTool.IsTableEmpty(self._NowRecord)
            and not XTool.IsTableEmpty(self._NowRecord.CharacterMagicIdListRecord)
            and self._NowRecord.CharacterMagicIdListRecord[characterId]
            and table.indexof(self._NowRecord.CharacterMagicIdListRecord[characterId], magicId)
    then
        nowValue = self._NowRecord.MagicIdDamageRecord[magicId] or nowValue
    end
    if not XTool.IsTableEmpty(self._PrevRecord)
            and not XTool.IsTableEmpty(self._PrevRecord.CharacterMagicIdListRecord)
            and self._PrevRecord.CharacterMagicIdListRecord[characterId]
            and table.indexof(self._PrevRecord.CharacterMagicIdListRecord[characterId], magicId)
    then
        prevValue = self._PrevRecord.MagicIdDamageRecord[magicId] or prevValue
    end
    return nowValue, prevValue
end
--endregion

--region Setter
function XTheatre3FightResult:UpdateData(data)
    if XTool.IsTableEmpty(data) then
        self:InitData()
        return
    end
    for _, fightData in ipairs(data) do
        self:AddData(fightData.StageId, fightData.DamageSourceDic, fightData.StringToListIntRecord, true)
    end
end

function XTheatre3FightResult:AddData(stageId, fightRecords, idList, isServerData)
    self._PrevRecord = self._NowRecord
    if XTool.IsNumberValid(stageId) then
        self._NowRecord = self:_ParseFightRecords2NowRecord(stageId, fightRecords, idList, isServerData)
    else
        self._NowRecord = {}
    end
end

function XTheatre3FightResult:_ParseFightRecords2NowRecord(stageId, fightRecords, idList, isFromServer)
    ---@type XTheatre3StageFightResult
    local dataRecord = {}
    dataRecord.StageId = stageId
    dataRecord.CharacterMagicIdListRecord = {}
    dataRecord.MagicIdDamageRecord = {}
    if not idList then
        return dataRecord
    end

    if isFromServer then
        for _, list in pairs(idList) do
            local characterId = 0
            for i, id in ipairs(list) do
                if i == 1 then
                    characterId = math.floor(id / 10)
                    dataRecord.CharacterMagicIdListRecord[characterId] = {}
                else
                    local magicIdList = XMVCA.XTheatre3:GetCfgEquipSuitMagicIdList(id)
                    if not magicIdList then
                        break
                    end
                    for _, magicId in ipairs(magicIdList) do
                        table.insert(dataRecord.CharacterMagicIdListRecord[characterId], magicId)
                    end
                end
            end
        end
        for _, dataDir in pairs(fightRecords) do
            if dataDir.DamageSource then
                for i, value in pairs(dataDir.DamageSource) do
                    dataRecord.MagicIdDamageRecord[i] = value
                end
            end
        end
    else
        for _, list in pairs(idList) do
            local characterId = 0
            for i = 0, list.Count - 1 do
                if i == 0 then
                    characterId = math.floor(list[i] / 10)
                    dataRecord.CharacterMagicIdListRecord[characterId] = {}
                else
                    local magicIdList = XMVCA.XTheatre3:GetCfgEquipSuitMagicIdList(list[i])
                    if not magicIdList then
                        break
                    end
                    for _, magicId in ipairs(magicIdList) do
                        table.insert(dataRecord.CharacterMagicIdListRecord[characterId], magicId)
                    end
                end
            end
        end
        for _, dataDir in pairs(fightRecords) do
            for i, value in pairs(dataDir) do
                dataRecord.MagicIdDamageRecord[i] = value
            end
        end
    end
    
    return dataRecord
end
--endregion

--region Check
function XTheatre3FightResult:CheckIsHaveNowRecord(characterId)
    if not self._NowRecord or not self._NowRecord.CharacterMagicIdListRecord then
        return false
    end
    return self._NowRecord.CharacterMagicIdListRecord[characterId]
end

function XTheatre3FightResult:CheckNowRecordIsHaveMagic(characterId, magicIdList)
    if XTool.IsTableEmpty(magicIdList) then
        return false
    end
    if not self._NowRecord or not self._NowRecord.CharacterMagicIdListRecord then
        return false
    end
    for _, magicId in ipairs(magicIdList) do
        if table.indexof(self._NowRecord.CharacterMagicIdListRecord[characterId], magicId) then
            return true
        end
    end
    return false
end
--endregion

return XTheatre3FightResult