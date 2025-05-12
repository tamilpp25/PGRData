--[[
    说明：等级现在分普通等级和荣耀等级(当普通等级达到120会转为荣耀等级)，使用下面的方法注意区分等级类型，在此对参数作统一说明
    --@level:等级可以是默认的普通等级或荣耀等级，等级是荣耀等级@isHonor必须传true
	--@isHonor: 是否使用荣耀勋阶的表，true(使用荣耀表)，否则使用默认的等级表
]]

XPlayerManager = XPlayerManager or {}

local TABLE_PLAYER = "Share/Player/Player.tab"
local TABLE_HONORLEVEL = "Share/Player/HonorLevel.tab"
local PlayerTable
local HonorLevelTable

XPlayerManager.PlayerChangeNameInterval = CS.XGame.Config:GetInt("PlayerChangeNameInterval")
XPlayerManager.PlayerMaxLevel = CS.XGame.Config:GetInt("PlayerMaxLevel")

function XPlayerManager.Init()
    PlayerTable = XTableManager.ReadByIntKey(TABLE_PLAYER, XTable.XTablePlayer, "Level")
    HonorLevelTable = XTableManager.ReadByIntKey(TABLE_HONORLEVEL, XTable.XTableHonorLevel, "HonorLevel")

    if not PlayerTable then
        XLog.Error("读取Player Table发生错误 表的路径是: " .. TABLE_PLAYER)
    end
    if not HonorLevelTable then
        XLog.Error("读取HonorLevel Table发生错误 表的路径是: " .. TABLE_HONORLEVEL)
    end
end

local function GetTableByLevel(level, isHonor, functionName)
    local table

    if isHonor then
        table = HonorLevelTable
    else
        table = PlayerTable
    end

    if not table[level] then
        --注意阅读上面的参数说明
        if isHonor then
            XLog.ErrorTableDataNotFound("XPlayerManager." .. functionName, "HonorLevelTable", TABLE_HONORLEVEL, "HonorLevel", tostring(level))
        else
            XLog.ErrorTableDataNotFound("XPlayerManager." .. functionName, "PlayerTable", TABLE_PLAYER, "level", tostring(level))
        end
    else
        return table[level]
    end
end

function XPlayerManager.GetMaxExp(level, isHonor)
    local maxExp = 0
    local table = GetTableByLevel(level, isHonor, "GetMaxExp")
    if table then
        maxExp = table.MaxExp
    end
    return maxExp
end

function XPlayerManager.GetMaxActionPoint(level, isHonor)
    local maxActp = 0
    local table = GetTableByLevel(level, isHonor, "GetMaxActionPoint")
    if table then
        maxActp = table.MaxActionPoint
    end
    return maxActp
end

function XPlayerManager.GetMaxFriendCount(level, isHonor)
    local maxCount = 0
    local table = GetTableByLevel(level, isHonor, "GetMaxFriendCount")
    if table then
        maxCount = table.MaxFriendCount
    end
    return maxCount
end

--注意：荣誉等级没有FreeActionPoint字段
function XPlayerManager.GetFreeActionPoint(level)
    local freeActp = 0
    local table = GetTableByLevel(level, false, "GetFreeActionPoint")
    if table then
        freeActp = table.FreeActionPoint
    end
    return freeActp
end

function XPlayerManager.GetRewardId(level)
    local RewardId = 0
    local table = GetTableByLevel(level, true, "RewardId")
    if table then
        RewardId = table.RewardId
    end
    return RewardId
end

---@return XTableHeadPortrait
function XPlayerManager.GetHeadPortraitInfoById(id)
    return XDataCenter.HeadPortraitManager.GetHeadPortraitInfoById(id)
end

--==============================--
--desc: 获取玩家信息
--@id: 玩家id
--@cb: 结果回调
--==============================--
function XPlayerManager.GetPlayerInfos(id, cb)
    local req = { id = id }
    XNetwork.Call("GetPlayerInfoRequest", req,
    function(result)
        if result.Code and result.Code ~= XCode.Success then
            XUiManager.TipCode(result.Code)
            return
        end
        if cb then
            cb(result.Code, result.PlayerData)
        end
    end
    )
end

function XPlayerManager.IsGetGenderReward()
    return XPlayer.IsGetGenderReward
end

function XPlayerManager.GetPlayerGenderChangeTime()
    return XPlayer.ChangeGenderTime
end

function XPlayerManager:CheckGenderCd()
    -- 上次修改时间<=全局重置时间时无视个人cd，可修改
    local lastChangedTime = XPlayerManager.GetPlayerGenderChangeTime()
    local changeGenderInterval = CS.XGame.Config:GetInt('PlayerChangeGenderInterval')

    if XTool.IsNumberValid(lastChangedTime) then
        -- 检测Cd
        local leftTime = lastChangedTime + changeGenderInterval - XTime.GetServerNowTimestamp()
        local isInCd = leftTime > 0

        return isInCd, leftTime
    else
        return false
    end
end

function XPlayerManager.RequestChangePlayerGender(gender, cb)
    XNetwork.Call('ChangePlayerGenderRequest', {Gender = gender}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        XPlayer.UpdatePlayerGenderData(res)

        if not XTool.IsTableEmpty(res.RewardGoodsList) then
            XUiManager.OpenUiObtain(res.RewardGoodsList, nil, cb, cb)
            return
        end

        if cb then
            cb()
        end
    end)
end