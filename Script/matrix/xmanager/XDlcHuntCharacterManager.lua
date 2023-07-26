local XDlcHuntCharacter = require("XEntity/XDlcHunt/XDlcHuntCharacter")

XDlcHuntCharacterManagerCreator = function()

    ---@class XDlcHuntCharacterManager
    local XDlcHuntCharacterManager = {}

    ---@type XDlcHuntCharacter[]
    local _CharacterDict = {}

    -- 出战角色
    local _FightCharacterId = false

    local RequestProto = {
        SetFightCharacter = "DlcCharacterSetFightRequest",
        SetChipGroup2Character = "DlcCharacterChipFormRequest",
    }

    function XDlcHuntCharacterManager.Init()
        local characterIdList = XDlcHuntCharacterConfigs.GetAllCharacterId()
        for i = 1, #characterIdList do
            ---@type XDlcHuntCharacter
            local character = XDlcHuntCharacter.New()
            local characterId = characterIdList[i]
            character:SetCharacterId(characterId)
            _CharacterDict[characterId] = character
        end
    end

    function XDlcHuntCharacterManager.InitDataFromServer(characterList)
        for i = 1, #characterList do
            local characterData = characterList[i]
            local characterId = characterData.Id
            ---@type XDlcHuntCharacter
            local character = XDlcHuntCharacterManager.GetCharacter(characterId)
            character:SetData(characterData)
        end
    end

    ---@return XDlcHuntCharacter[]
    function XDlcHuntCharacterManager.GetCharacterList()
        local result = {}
        for characterId, character in pairs(_CharacterDict) do
            result[#result + 1] = character
        end
        ---@param a XDlcHuntCharacter
        ---@param b XDlcHuntCharacter
        table.sort(result, function(a, b)
            local priorityA = a:GetPriority()
            local priorityB = b:GetPriority()
            return priorityA < priorityB
        end)
        return result
    end

    ---@return XDlcHuntCharacter
    function XDlcHuntCharacterManager.GetCharacter(characterId)
        return _CharacterDict[characterId]
    end

    ---@return XDlcHuntCharacter
    function XDlcHuntCharacterManager.GetCharacterByNpcId(npcId)
        local characterId = XDlcHuntCharacterConfigs.GetCharacterIdByNpcId(npcId)
        return XDlcHuntCharacterManager.GetCharacter(characterId)
    end

    function XDlcHuntCharacterManager.GetFightCharacterId()
        local characterId = _FightCharacterId
        if not characterId or characterId == 0 then
            local characterIdList = XDlcHuntCharacterConfigs.GetAllCharacterId()
            return characterIdList[1]
        end
        return _FightCharacterId
    end

    function XDlcHuntCharacterManager.SetFightCharacter(characterId)
        _FightCharacterId = characterId
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_SELECT_CHARACTER_UPDATE)
    end

    --region notify
    function XDlcHuntCharacterManager.NotifyDlcFightCharacterId(data)
        XDlcHuntCharacterManager.SetFightCharacter(data.FightCharacterId)
    end
    --endregion notify

    --region request
    ---@param character XDlcHuntCharacter
    ---@param chipGroup XDlcHuntChipGroup
    function XDlcHuntCharacterManager.RequestSetChipGroup2Character(character, chipGroup)
        local characterId = character:GetCharacterId()
        local chipGroupId = chipGroup:GetUid()
        if character:GetChipGroupId() == chipGroupId then
            return
        end
        XNetwork.Call(RequestProto.SetChipGroup2Character, {
            CharacterId = characterId,
            ChipFormId = chipGroupId,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            character:SetChipGroupId(chipGroupId)
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_UPDATE)
        end)
    end
    
    ---@param character XDlcHuntCharacter
    function XDlcHuntCharacterManager.RequestSetFightCharacter(character)
        local characterId = character:GetCharacterId()
        XNetwork.Call(RequestProto.SetFightCharacter, { CharacterId = characterId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XDlcHuntCharacterManager.SetFightCharacter(characterId)
        end)
    end
    --endregion request

    XDlcHuntCharacterManager.Init()
    return XDlcHuntCharacterManager
end

XRpc.NotifyDlcFightCharacterId = function(data)
    XDataCenter.DlcHuntCharacterManager.NotifyDlcFightCharacterId(data)
end