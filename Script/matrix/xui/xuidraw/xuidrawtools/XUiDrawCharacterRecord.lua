local list

local Record = function()
    local charList = XMVCA.XCharacter:GetOwnCharacterList()
    list = {}
    for i = 1, #charList do
        table.insert(list, charList[i].Id)
    end
end

local IsOwnCharacter = function(id)
    if not list then
        XLog.Warning("Haven't record character list yet.")
        return
    end

    if XArrangeConfigs.GetType(id) ~= XArrangeConfigs.Types.Character then
        return false
    end

    for i = 1, #list do
        if list[i] == id then
            return true
        end
    end

    table.insert(list, id)

    return false
end

local GetDecomposeData = function(goods)
    local characterId = goods.TemplateId
    local template = XMVCA.XCharacter:GetCharacterTemplate(characterId)
    local characterType = XMVCA.XCharacter:GetCharacterType(characterId)
    local decomposeCount = XMVCA.XCharacter:GetDecomposeCount(characterType, goods.Quality)
    return { TemplateId = template.ItemId, Count = decomposeCount }
end

---@class XUiDrawCharacterRecord
local CharacterRecord = {}

---@type function
CharacterRecord.Record = Record
---@type function(characterId)
CharacterRecord.IsOwnCharacter = IsOwnCharacter
---@type function(goods)
CharacterRecord.GetDecomposeData = GetDecomposeData

return CharacterRecord