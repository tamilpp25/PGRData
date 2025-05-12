---@class XCharacterControl : XControl
---@field _Model XCharacterModel
local XCharacterControl = XClass(XControl, "XCharacterControl")
function XCharacterControl:OnInit()
    --初始化内部变量
end

-------- 优化拆分到Control的表 begin
function XCharacterControl:GetCharGraphTemplate(graphId)
    local template = self._Model:GetCharacterGraph()[graphId]
    if not template then
        XLog.Error("CharacterGraph.tab not found id ", graphId)
        return
    end
    return template
end

-- 获得当前品质的各个star的进化表演阶段
---@return table
function XCharacterControl:GetCharacterSkillQualityBigEffectBallPerformArea(quality)
    local config = self:GetModelCharacterSkillQualityBigEffectBall()[quality]
    if XTool.IsTableEmpty(config) then
        XLog.Error("CharacterSkillQualityBigEffectBall.tab not found quality ", quality)
        return
    end

    local res = {}
    for k, areaStr in pairs(config.PerformArea) do
        local areaTable = string.Split(areaStr, '|')
        -- 把area做成table 且转换为number
        for j, v in pairs(areaTable) do
            areaTable[j] = tonumber(v)
        end
        res[k] = areaTable
    end

    return res
end

-- 根据角色获得当前其处在哪个表演阶段
function XCharacterControl:GetCharQualityPerformArea(charId, quality)
    local char = self:GetAgency():GetCharacter(charId)
    if not char then
        return
    end

    local allAreas = self:GetCharacterSkillQualityBigEffectBallPerformArea(quality)
    local curQualityState = self:GetAgency():GetQualityState(charId, quality)
    if curQualityState == XEnumConst.CHARACTER.QualityState.ActiveFinish then
        return #allAreas -- 最大阶段
    end

    if curQualityState == XEnumConst.CHARACTER.QualityState.Lock then
        return XEnumConst.CHARACTER.PerformState.One
    end

    local star = char.Star
    for k, area in pairs(allAreas) do
        local areaMin = area[1]
        local areaMax = area[2]
        if star >= areaMin and star <= areaMax then
            return k
        end 
    end
end

-- 获取核心切换技能的描述
function XCharacterControl:GetCharacterSkillExchangeDesBySkillIdAndLevel(skillId, skillLevel)
    local levelString = (skillLevel >= 10) and skillLevel or ("0"..skillLevel)
    local targetId = tonumber((skillId *100)..levelString)
    return self:GetModelCharacterSkillExchangeDes()[targetId]
end

-- 部分拆分的直接get的表
function XCharacterControl:GetModelCharacterSkillQualityBigEffectBall()
    return self._Model:GetCharacterSkillQualityBigEffectBall()
end

function XCharacterControl:GetModelCharacterSkillExchangeDes()
    return self._Model:GetCharacterSkillExchangeDes()
end
--

-------- 优化拆分到Control的表 end

-- 协议 begin
function XCharacterControl:CharacterResetNewFlagRequest(characterIdList, cb)
    XNetwork.Call("CharacterResetNewFlagRequest", { CharacterIds = characterIdList }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if cb then
            cb()
        end
    end)
end

function XCharacterControl:CharacterSetCollectStateRequest(characterId, collectState, cb)
    local char = XMVCA.XCharacter:GetCharacter(characterId)
    if not char then
        return
    end

    if collectState == char.CollectState then
        return
    end

    XNetwork.Call("CharacterSetCollectStateRequest", { CharacterId = characterId, CollectState = collectState }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if cb then
            cb()
        end
    end)
end

function XCharacterControl:CharacterEnhanceSkillNoticeRequest(characterId, cb)
    local char = XMVCA.XCharacter:GetCharacter(characterId)
    if not char then
        return
    end

    XNetwork.Call("CharacterEnhanceSkillNoticeRequest", { CharacterId = characterId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if cb then
            cb()
        end
    end)
end
-- 协议 end

function XCharacterControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XCharacterControl:RemoveAgencyEvent()

end

function XCharacterControl:OnRelease()
end

return XCharacterControl