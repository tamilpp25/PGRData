--查看玩家信息管理器
XPlayerInfoManagerCreator = function()
    ---@class XPlayerInfoManager
    local XPlayerInfoManager = {}

    local GET_PLAYER_INFO_INTERVAL = 120

    --缓存信息
    --结构为 key:playerId  value:dataType
    --如果dataType为CharacterInfo，则CharacterInfo继续细分  key:characterId  value:具体角色信息
    local cache = {}
    local cacheTime = {}

    local dataType = {
        PlayerInfo = 1,             --玩家信息
        PlayerCharacter = 2,        --展示的成员列表
        PlayerFashion = 3,          --成员涂装
        PlayerWeaponFashion = 4,    --武器涂装
        PlayerTitle = 5,            --收藏品列表
        CharacterInfo = 6           --成员的详情信息(等级、技能、装备等)
    }

    local PlayerInfoRequest = {
        RequestPlayerInfo = "QueryPlayerDetailRequest",                 --获取玩家信息
        RequestPlayerCharacterList = "QueryPlayerCharacterListRequest", --查看玩家成员展示信息
        RequestPlayerFashion = "QueryPlayerFashionRequest",             --查看玩家涂装展示信息
        RequestPlayerWeaponFashion = "QueryPlayerWeaponFashionRequest", --查看玩家武器涂装展示信息
        RequestPlayerTitle = "QueryPlayerTitleRequest",                 --查看玩家收藏品展示信息
        RequestCharacterInfo = "QueryCharacterInfoRequest"              --查看成员详情
    }

    --保存展示信息
    function XPlayerInfoManager.SaveData(charactersAppearanceType, characterIds, appearanceSettingInfo, cb)
        XPlayer.SetAppearance(charactersAppearanceType, characterIds, appearanceSettingInfo, cb)
    end

    local function CanRequest(playerId, type, characterId)
        if cache[playerId] == nil then
            --没有请求过该玩家的信息
            cache[playerId] = {}
            cacheTime[playerId] = {}
            return true
        else
            if cache[playerId][type] then
                --缓存着玩家的这个种类的信息

                if dataType.CharacterInfo == type then
                    --若是角色详情，判断是否请求过该角色的信息
                    if cache[playerId][type][characterId] then
                        return XTime.GetServerNowTimestamp() - cacheTime[playerId][type][characterId] > GET_PLAYER_INFO_INTERVAL
                    else
                        return true
                    end
                end

                return XTime.GetServerNowTimestamp() - cacheTime[playerId][type] > GET_PLAYER_INFO_INTERVAL
            else
                --该玩家的这个种类的信息没有请求过
                cache[playerId][type] = {}
                cacheTime[playerId][type] = {}
                return true
            end
        end
    end

    --请求玩家信息
    function XPlayerInfoManager.RequestPlayerInfoData(playerId, cb)
        --检查缓存
        if CanRequest(playerId, dataType.PlayerInfo) then
            XNetwork.Call(PlayerInfoRequest.RequestPlayerInfo, { PlayerId = playerId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                cache[playerId][dataType.PlayerInfo] = res.Detail
                cacheTime[playerId][dataType.PlayerInfo] = XTime.GetServerNowTimestamp()

                if cb then
                    cb(cache[playerId][dataType.PlayerInfo])
                end
            end)
        else
            if cb then
                cb(cache[playerId][dataType.PlayerInfo])
            end
        end
    end

    -- 请求玩家收藏品展示信息
    function XPlayerInfoManager.RequestPlayerTitleData(playerId, cb)
        --检查缓存
        if CanRequest(playerId, dataType.PlayerTitle) then
            XNetwork.Call(PlayerInfoRequest.RequestPlayerTitle, { PlayerId = playerId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                cache[playerId][dataType.PlayerTitle].Titles = res.Titles
                cache[playerId][dataType.PlayerTitle].Walls = res.Walls
                cacheTime[playerId][dataType.PlayerTitle] = XTime.GetServerNowTimestamp()

                if cb then
                    cb(cache[playerId][dataType.PlayerTitle])
                end
            end)
        else
            if cb then
                cb(cache[playerId][dataType.PlayerTitle])
            end
        end
    end

    -- 请求玩家成员展示信息
    function XPlayerInfoManager.RequestPlayerCharacterListData(playerId, cb)
        --检查缓存
        if CanRequest(playerId, dataType.PlayerCharacter) then
            XNetwork.Call(PlayerInfoRequest.RequestPlayerCharacterList, { PlayerId = playerId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                cache[playerId][dataType.PlayerCharacter] = res.CharacterShows
                cacheTime[playerId][dataType.PlayerCharacter] = XTime.GetServerNowTimestamp()

                if cb then
                    cb(cache[playerId][dataType.PlayerCharacter])
                end
            end)
        else
            if cb then
                cb(cache[playerId][dataType.PlayerCharacter])
            end
        end

    end

    -- 请求玩家涂装展示信息
    function XPlayerInfoManager.RequestPlayerFashionData(playerId, cb)
        --检查缓存
        if CanRequest(playerId, dataType.PlayerFashion) then
            XNetwork.Call(PlayerInfoRequest.RequestPlayerFashion, { PlayerId = playerId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                cache[playerId][dataType.PlayerFashion] = res.Fashions
                cacheTime[playerId][dataType.PlayerFashion] = XTime.GetServerNowTimestamp()

                if cb then
                    cb(cache[playerId][dataType.PlayerFashion])
                end
            end)
        else
            if cb then
                cb(cache[playerId][dataType.PlayerFashion])
            end
        end
    end

    -- 请求玩家武器涂装展示信息
    function XPlayerInfoManager.RequestPlayerWeaponFashionData(playerId, cb)
        --检查缓存
        if CanRequest(playerId, dataType.PlayerWeaponFashion) then
            XNetwork.Call(PlayerInfoRequest.RequestPlayerWeaponFashion, { PlayerId = playerId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                cache[playerId][dataType.PlayerWeaponFashion] = res.WeaponFashions
                cacheTime[playerId][dataType.PlayerWeaponFashion] = XTime.GetServerNowTimestamp()

                if cb then
                    cb(cache[playerId][dataType.PlayerWeaponFashion])
                end
            end)
        else
            if cb then
                cb(cache[playerId][dataType.PlayerWeaponFashion])
            end
        end
    end

    -- 请求角色详情
    function XPlayerInfoManager.RequestCharacterInfoData(playerId, characterId, cb)
        --检查缓存
        if CanRequest(playerId, dataType.CharacterInfo, characterId) then
            XNetwork.Call(PlayerInfoRequest.RequestCharacterInfo, { PlayerId = playerId, CharacterId = characterId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                local characterInofo = { CharacterData = res.CharacterData
                    , EquipData = res.EquipData
                    , PartnerData = res.PartnerData
                    , WeaponFashionId = res.WeaponFashionId
                    , AssignChapterRecords = res.AssignChapterRecords
                    , AwarenessSetPositions = res.AwarenessSetPositions
                    , IsSelfData = playerId == XPlayer.Id } -- 设置是否为属于玩家和非玩家（好友）标志
                cache[playerId][dataType.CharacterInfo][characterId] = characterInofo
                cacheTime[playerId][dataType.CharacterInfo][characterId] = XTime.GetServerNowTimestamp()

                if cb then
                    cb(cache[playerId][dataType.CharacterInfo][characterId])
                end
            end)
        else
            if cb then
                cb(cache[playerId][dataType.CharacterInfo][characterId])
            end
        end
    end

    return XPlayerInfoManager
end