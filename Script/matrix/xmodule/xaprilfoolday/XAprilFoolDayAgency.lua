---@class XAprilFoolDayAgency : XAgency
---@field private _Model XAprilFoolDayModel
local XAprilFoolDayAgency = XClass(XAgency, "XAprilFoolDayAgency")
function XAprilFoolDayAgency:OnInit()
    --初始化一些变量
end

function XAprilFoolDayAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XAprilFoolDayAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------

-- 活动时间
function XAprilFoolDayAgency:IsInTime()
    local TITLE_START_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayStartTime"))
    local TITLE_END_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayEndTime"))

    local curTime = os.time()
    return curTime >= TITLE_START_TIME and curTime < TITLE_END_TIME
end

-- 标题时间
function XAprilFoolDayAgency:IsInTitleTime()
    local TITLE_START_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayTitleStartTime"))
    local TITLE_END_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayTitleEndTime"))

    local curTime = os.time()
    return curTime >= TITLE_START_TIME and curTime < TITLE_END_TIME
end

-- Q版模型时间
function XAprilFoolDayAgency:IsInCuteModelTime()
    local CUTE_START_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayCuteModeltartTime"))
    local CUTE_END_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayCuteModelEndTime"))

    local curTime = os.time()
    return curTime >= CUTE_START_TIME and curTime < CUTE_END_TIME
end

-- Q版头像时间
function XAprilFoolDayAgency:IsInCuteHeadIconTime()
    local CUTE_START_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayCuteHeadStartTime2025"))
    local CUTE_END_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayCuteHeadEndTime2025"))

    local curTime = os.time()
    return curTime >= CUTE_START_TIME and curTime < CUTE_END_TIME
end

-- 随机爪痕时间
function XAprilFoolDayAgency:IsInRandomClawTime()
    local CUTE_START_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayClawStartTime2025"))
    local CUTE_END_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayClawEndTime2025"))

    local curTime = os.time()
    return curTime >= CUTE_START_TIME and curTime < CUTE_END_TIME
end

-- Ui界面随机角色模型时间
function XAprilFoolDayAgency:IsInRandomCharacterUiModelTime()
    return false
end

function XAprilFoolDayAgency:IsMainCharacter(characterId)
    local mainCharacterId = tonumber(CS.XGame.ClientConfig:GetInt("AprilFoolsDayMainCharacter"))
    return characterId == mainCharacterId
end

function XAprilFoolDayAgency:IsSubCharacter(characterId)
    local subCharalist = CS.XGame.ClientConfig:GetString("AprilFoolsDaySubCharacter")
    subCharalist = string.ToIntArray(subCharalist, '|')
    local isCharIn = table.contains(subCharalist, characterId)

    return isCharIn
end

--- 返回false表示不显示猫或狼
function XAprilFoolDayAgency:IsShowCatOrWolf()
    if not self:IsInRandomClawTime() then
        return false
    end

    local randomNum = math.random()
    local showProbability = tonumber(CS.XGame.ClientConfig:GetInt("AprilFoolsDayClawProShow2025")) * 0.001
    if randomNum < showProbability then
        return false
    end

    randomNum = math.random()
    if randomNum < 0.5 then
        return XEnumConst.AprilFool.Random2025Type.Cat
    else
        return XEnumConst.AprilFool.Random2025Type.Wolf
    end
end

-- 隐藏角色模型
function XAprilFoolDayAgency:IsMainCharacterHide(characterId)
    if not self:IsInRandomCharacterUiModelTime() then
        return false
    end

    if not self:IsMainCharacter(characterId) then
        return false
    end

    local hideProbability = tonumber(CS.XGame.ClientConfig:GetInt("AprilFoolsDayMainCharacterMiss")) * 0.01
    local randomNum = math.random()
    local isLastHide = randomNum <= hideProbability
    if isLastHide then
        self._Model.TempWholeDic.IsLastHideChar = characterId
    else
        self._Model.TempWholeDic.IsLastHideChar = nil
    end

    return isLastHide
end

-- 显示愚人节专用第二角色模型
function XAprilFoolDayAgency:GetCharIsSubCharacterShow(characterId)
    if not self:IsInRandomCharacterUiModelTime() then
        return false
    end

    if not self:IsSubCharacter(characterId) then
        return false
    end

    return self._Model.TempWholeDic.IsLastHideChar
end

----------public end----------


return XAprilFoolDayAgency