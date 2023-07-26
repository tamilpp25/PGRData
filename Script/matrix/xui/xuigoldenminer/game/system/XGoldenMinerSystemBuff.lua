local XGoldenMinerComponentBuff = require("XUi/XUiGoldenMiner/Game/Component/XGoldenMinerComponentBuff")

---@class XGoldenMinerSystemBuff
local XGoldenMinerSystemBuff = XClass(nil, "XGoldenMinerSystemBuff")

---@param game XGoldenMinerGame
function XGoldenMinerSystemBuff:Init(game)
    self:InitBuffContainer(game)
end

---@param game XGoldenMinerGame
function XGoldenMinerSystemBuff:Update(game, time)
    self:CheckBuffTrigger(game)
    self:UpdateBuffContainer(game, game.BuffContainer, time)
end

--region Buff - Trigger
---@param buff XGoldenMinerComponentBuff
---@return boolean
function XGoldenMinerSystemBuff:TriggerCountBuff(buff)
    if not self:CheckBuffTimeType(buff, XGoldenMinerConfigs.BuffTimeType.Count) then
        return false
    end
    if not self:CheckBuffIsAlive(buff) then
        return false
    end
    buff.CurTimeTypeParam = buff.CurTimeTypeParam - 1
    --XGoldenMinerConfigs.DebugLog("Buff生效1次,Id="..buff.Id..",剩余次数="..buff.CurTimeTypeParam)
    if buff.CurTimeTypeParam <= 0 then
        buff.Status = XGoldenMinerConfigs.GAME_BUFF_STATUS.BE_DIE
    end
    return true
end

---@param game XGoldenMinerGame
---@param buff XGoldenMinerComponentBuff
---@return boolean
function XGoldenMinerSystemBuff:TriggerGlobalRoleSkillBuff(game, buff)
    if not self:CheckBuffTimeType(buff, XGoldenMinerConfigs.BuffTimeType.Global) then
        return false
    end
    if not self:CheckBuffIsAlive(buff) then
        return false
    end

    if buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerBoomGetScore then
        local score = math.random(buff.BuffParams[1], buff.BuffParams[2])
        game:AddMapScore(score)
        
        --XGoldenMinerConfigs.DebugLog("炸弹加分,Score="..score)
    end

    if buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerMouseGetItem then
        local redId = XGoldenMinerConfigs.GetRedEnvelopeRandId(buff.BuffParams[1])
        local itemId = XGoldenMinerConfigs.GetRedEnvelopeItemId(redId)
        game:AddItem(itemId)
        --XGoldenMinerConfigs.DebugLog("定春加道具,ItemId="..itemId)
    end

    if buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerQTEGetScore then
        local percent = math.random(buff.BuffParams[1], buff.BuffParams[2]) / XGoldenMinerConfigs.Percent
        for _, hookEntity in ipairs(game.HookEntityList) do
            for _, stoneEntity in pairs(hookEntity.HookGrabbingStoneList) do
                if stoneEntity.QTE and stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBED then
                    local score = stoneEntity.QTE.AddScore * percent
                    stoneEntity.QTE.AddScore = math.ceil(stoneEntity.QTE.AddScore + score)
                    --XGoldenMinerConfigs.DebugLog("QTE额外加分,Score="..score)
                end
            end
        end
    end
    
    return true
end

---@param game XGoldenMinerGame
function XGoldenMinerSystemBuff:CheckBuffTrigger(game)
    local buffTypeDir = game.BuffContainer.BuffTypeDir
    if XTool.IsTableEmpty(buffTypeDir) then
        return
    end
    local isTrigger = false
    for _, buffList in pairs(buffTypeDir) do
        for _, buff in ipairs(buffList) do
            if buff.Status == XGoldenMinerConfigs.GAME_BUFF_STATUS.NONE then
                --XGoldenMinerConfigs.DebugLog("触发Buff,id="..buff.Id)
                buff.Status = XGoldenMinerConfigs.GAME_BUFF_STATUS.ALIVE
                self:BuffTriggerFullScreenEffect(game.BuffContainer, buff)
                isTrigger = true
            end
        end
    end
    if isTrigger then
        --XGoldenMinerConfigs.DebugLogData("当前生效Buff:", self:GetAliveBuffList(game.BuffContainer))
        self:UpdateGameStatus(game)
        self:UpdateGameTime(game)
        self:UpdateItemToEntity(game)
        self:UpdateHookShootSpeed(game)
        self:UpdateHookRevokePercent(game)
        self:UpdateStoneScore(game)
        self:UpdateStoneWeight(game)
    end
end

---@param game XGoldenMinerGame
function XGoldenMinerSystemBuff:UpdateGameStatus(game)
    if self:CheckHasBuff(game.BuffContainer, XGoldenMinerConfigs.BuffType.GoldenMinerUseItemStopTime) then
        game:TimeStop()
        return
    end
    if self:CheckHasBuff(game.BuffContainer, XGoldenMinerConfigs.BuffType.GoldenMinerItemStopTime) then
        game:TimeStop()
        return
    end
    game:TimeResume()
end

---@param game XGoldenMinerGame
function XGoldenMinerSystemBuff:UpdateGameTime(game)
    ---@type XGoldenMinerComponentBuff
    local buff
    -- 初始加时
    buff = self:GetAliveBuffByType(game.BuffContainer, XGoldenMinerConfigs.BuffType.GoldenMinerInitAddTime)
    if buff then
        if XTool.IsNumberValid(buff.BuffParams[2]) and buff.BuffParams[2] > game:GetData():GetFinishStageCount()
            or not XTool.IsNumberValid(buff.BuffParams[2])
        then
            game:AddTime(buff.BuffParams[1])
        end
        self:TriggerCountBuff(buff)
    end
    
    -- 道具加时
    buff = self:GetAliveBuffByType(game.BuffContainer, XGoldenMinerConfigs.BuffType.GoldenMinerUseItemAddTime)
    if buff then
        game:AddTime(buff.BuffParams[1])
        self:TriggerCountBuff(buff)
    end
end

---@param game XGoldenMinerGame
function XGoldenMinerSystemBuff:UpdateHookShootSpeed(game)
    if XTool.IsTableEmpty(game.HookEntityList) then
        return
    end
    for _, hookEntity in ipairs(game.HookEntityList) do
        hookEntity.Hook.CurShootSpeed = self:_ComputeHookShootSpeed(game, hookEntity.Hook)
        --XGoldenMinerConfigs.DebugLog("已触发Buff下钩爪发射速度:"..hookEntity.Hook.CurShootSpeed)
    end
end

---@param game XGoldenMinerGame
function XGoldenMinerSystemBuff:UpdateHookRevokePercent(game)
    if XTool.IsTableEmpty(game.HookEntityList) then
        return
    end
    for _, hookEntity in ipairs(game.HookEntityList) do
        hookEntity.Hook.CurRevokeSpeedPercent = self:_ComputeHookRevokePercent(game)
        --XGoldenMinerConfigs.DebugLog("已触发Buff下钩爪回收速度倍率:"..hookEntity.Hook.CurRevokeSpeedPercent)
    end
end

---更新道具对抓取物的效果
---@param game XGoldenMinerGame
function XGoldenMinerSystemBuff:UpdateItemToEntity(game)
    ---@type XGoldenMinerComponentBuff
    local buff
    -- 添加瞄准镜
    buff = self:GetAliveBuffByType(game.BuffContainer, XGoldenMinerConfigs.BuffType.GoldenMinerAim)
    if buff then
        for _, hookEntity in ipairs(game.HookEntityList) do
            hookEntity.Hook.IsAim = true
            for _, aim in pairs(hookEntity.Hook.AimTranList) do
                aim.gameObject:SetActiveEx(true)
            end
        end
        self:TriggerCountBuff(buff)
    end
    
    -- 使用炸弹
    buff = self:GetAliveBuffByType(game.BuffContainer, XGoldenMinerConfigs.BuffType.GoldenMinerBoom)
    if buff then
        for _, hookEntity in ipairs(game.HookEntityList) do
            if not XTool.IsTableEmpty(hookEntity.HookGrabbingStoneList) then
                for _, stoneEntity in ipairs(hookEntity.HookGrabbingStoneList) do
                    game:SetStoneEntityStatus(stoneEntity, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.BE_DESTROY)
                end
                XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
                        XGoldenMinerConfigs.GAME_EFFECT_TYPE.GRAB_BOOM,
                        hookEntity.Hook.GrabPoint,
                        XGoldenMinerConfigs.GetUseBoomEffect())
            end
        end
        self:TriggerCountBuff(buff)
    end

    -- 点石成金
    buff = self:GetAliveBuffByType(game.BuffContainer, XGoldenMinerConfigs.BuffType.GoldenMinerStoneChangeGold)
    if buff then
        for _, hookEntity in ipairs(game.HookEntityList) do
            if not XTool.IsTableEmpty(hookEntity.HookGrabbingStoneList) then
                for _, stoneEntity in ipairs(hookEntity.HookGrabbingStoneList) do
                    if stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBING then
                        game:ChangeToGold(stoneEntity)
                        game:SetStoneEntityStatus(stoneEntity, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBING)
                    end
                end
                self:UpdateStoneScore(game)
                XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
                        XGoldenMinerConfigs.GAME_EFFECT_TYPE.GRAB_BOOM,
                        hookEntity.Hook.GrabPoint,
                        XGoldenMinerConfigs.GetUseBoomEffect())
            end
        end
        self:TriggerCountBuff(buff)
    end

    -- 类型炸弹
    buff = self:GetAliveBuffByType(game.BuffContainer, XGoldenMinerConfigs.BuffType.GoldenMinerTypeBoom)
    if buff then
        if not XTool.IsTableEmpty(game.StoneEntityList) then
            for _, stoneEntity in ipairs(game.StoneEntityList) do
                if (stoneEntity.Data:GetType() == buff.BuffParams[1] or buff.BuffParams[1] == 0)
                    and stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.ALIVE
                then
                    game:SetStoneEntityStatus(stoneEntity, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.BE_DESTROY)
                    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
                            XGoldenMinerConfigs.GAME_EFFECT_TYPE.TYPE_BOOM,
                            stoneEntity.Stone.Transform,
                            XGoldenMinerConfigs.GetUseBoomEffect())
                end
            end
        end
        self:TriggerCountBuff(buff)
    end
end

---@param game XGoldenMinerGame
function XGoldenMinerSystemBuff:UpdateStoneScore(game)
    if XTool.IsTableEmpty(game.StoneEntityList) then
        return
    end
    for _, stoneEntity in ipairs(game.StoneEntityList) do
        if stoneEntity.Status ~= XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBED and not stoneEntity.QTE then
            self:_ComputeStoneScore(game, stoneEntity)
        end
    end
end

---@param game XGoldenMinerGame
function XGoldenMinerSystemBuff:UpdateStoneWeight(game)
    if XTool.IsTableEmpty(game.StoneEntityList) then
        return
    end
    for _, stoneEntity in ipairs(game.StoneEntityList) do
        if stoneEntity.Status ~= XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBED then
            stoneEntity.Stone.CurWeight = self:_ComputeStoneWeight(game, stoneEntity)
            --XGoldenMinerConfigs.DebugLog("已触发Buff下抓取物重量:"..stoneEntity.Stone.CurWeight..",StoneId="..stoneEntity.Data:GetId())
        end
    end
end

---@param game XGoldenMinerGame
---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemBuff:_ComputeHookShootSpeed(game, hook)
    local buffTypeDir = game.BuffContainer.BuffTypeDir
    if XTool.IsTableEmpty(buffTypeDir) then
        return hook.ShootSpeed
    end
    local buffList = buffTypeDir[XGoldenMinerConfigs.BuffType.GoldenMinerStretchSpeed]
    local percentChange = 0
    if not XTool.IsTableEmpty(buffList) then
        for _, buff in ipairs(buffList) do
            if self:CheckBuffIsAlive(buff) then
                percentChange = percentChange + buff.BuffParams[1]
            end
        end
    end
    return hook.ShootSpeed * (1 + percentChange / XGoldenMinerConfigs.Percent)
end

---@param game XGoldenMinerGame
function XGoldenMinerSystemBuff:_ComputeHookRevokePercent(game)
    local buffTypeDir = game.BuffContainer.BuffTypeDir
    if XTool.IsTableEmpty(buffTypeDir) then
        return 1
    end
    local percentChange = 0
    local buffList = buffTypeDir[XGoldenMinerConfigs.BuffType.GoldenMinerShortenSpeed]
    if not XTool.IsTableEmpty(buffList) then
        for _, buff in ipairs(buffList) do
            if self:CheckBuffIsAlive(buff) then
                percentChange = percentChange + buff.BuffParams[1]
            end
        end
    end
    return 1 + percentChange / XGoldenMinerConfigs.Percent
end

---@param game XGoldenMinerGame
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemBuff:_ComputeStoneScore(game, stoneEntity)
    local buffTypeDir = game.BuffContainer.BuffTypeDir
    if XTool.IsTableEmpty(buffTypeDir) then
        stoneEntity.Stone.CurScore = stoneEntity.Stone.Score
        if stoneEntity.CarryStone then
            stoneEntity.CarryStone.Stone.CurScore = stoneEntity.CarryStone.Stone.Score
        end
        return
    end
    local percentChange = 0
    local buffList
    -- 指定Type抓取物获得的分数增加 X%
    buffList = buffTypeDir[XGoldenMinerConfigs.BuffType.GoldenMinerStoneScore]
    if not XTool.IsTableEmpty(buffList) then
        for _, buff in ipairs(buffList) do
            if self:CheckBuffIsAlive(buff)
                    and stoneEntity.Data:GetType() == buff.BuffParams[1]
            then
                percentChange = percentChange + buff.BuffParams[2]
            end
        end
    end
    -- 每次夹取物品价值变化
    buffList = buffTypeDir[XGoldenMinerConfigs.BuffType.GoldenMinerValueFloat]
    if not XTool.IsTableEmpty(buffList) then
        for _, buff in ipairs(buffList) do
            if self:CheckBuffIsAlive(buff) then
                percentChange = percentChange + math.random(buff.BuffParams[1], buff.BuffParams[2])
            end
        end
    end

    stoneEntity.Stone.CurScore = math.ceil(stoneEntity.Stone.Score * (1 + percentChange / XGoldenMinerConfigs.Percent))
    --XGoldenMinerConfigs.DebugLog("已触发Buff下抓取物分数:"..stoneEntity.Stone.CurScore..",StoneId="..stoneEntity.Data:GetId())
    if stoneEntity.CarryStone then
        stoneEntity.CarryStone.Stone.CurScore = math.ceil(stoneEntity.CarryStone.Stone.Score * (1 + percentChange / XGoldenMinerConfigs.Percent))
        --XGoldenMinerConfigs.DebugLog("已触发Buff下抓取物携带物分数:"..stoneEntity.CarryStone.Stone.CurScore..",StoneId="..stoneEntity.CarryStone.Data:GetId())
    end
end

---@param game XGoldenMinerGame
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemBuff:_ComputeStoneWeight(game, stoneEntity)
    local buffTypeDir = game.BuffContainer.BuffTypeDir
    if XTool.IsTableEmpty(buffTypeDir) then
        return stone.Weight
    end
    local percentChange = 0
    local buffList
    -- 变化重量
    buffList = buffTypeDir[XGoldenMinerConfigs.BuffType.GoldenMinerWeightFloat]
    if not XTool.IsTableEmpty(buffList) then
        for _, buff in ipairs(buffList) do
            if self:CheckBuffIsAlive(buff)
                    and (stoneEntity.Data:GetType() == buff.BuffParams[1] or buff.BuffParams[1] == 0)
            then
                percentChange = percentChange + buff.BuffParams[2]
            end
        end
    end
    
    return stoneEntity.Stone.Weight * (1 + percentChange / XGoldenMinerConfigs.Percent)
end
--endregion

--region Buff - Update
---@param game XGoldenMinerGame
---@param buff XGoldenMinerComponentBuff
function XGoldenMinerSystemBuff:UpdateBuff(game, buff, time)
    if self:CheckBuffTimeType(buff, XGoldenMinerConfigs.BuffTimeType.Time) and self:CheckBuffIsAlive(buff) then
        --XGoldenMinerConfigs.DebugLog("Buff持续生效,Id="..buff.Id..",倒计时="..buff.CurTimeTypeParam)
        -- 使用道具时停的效果比道具时停效果先触发
        if buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerItemStopTime
                and self:CheckHasBuff(game.BuffContainer, XGoldenMinerConfigs.BuffType.GoldenMinerUseItemStopTime) then
            return
        end
        buff.CurTimeTypeParam = buff.CurTimeTypeParam - time
        buff.CurTimeTypeParam = math.max(buff.CurTimeTypeParam, 0)
        if buff.CurTimeTypeParam <= 0 then
            buff.Status = XGoldenMinerConfigs.GAME_BUFF_STATUS.BE_DIE
        end
    elseif buff.Status == XGoldenMinerConfigs.GAME_BUFF_STATUS.BE_DIE then
        self:OnBuffDie(game, buff)
        self:BuffDieFullScreenEffect(game.BuffContainer, buff)
    end
end

---@param buffContainer XGoldenMinerEntityBuffContainer
---@return XGoldenMinerComponentBuff
function XGoldenMinerSystemBuff:GetAliveBuffByType(buffContainer, buffType)
    if not buffContainer or XTool.IsTableEmpty(buffContainer.BuffTypeDir) then
        return false
    end
    local buffList = buffContainer.BuffTypeDir[buffType]
    if XTool.IsTableEmpty(buffList) then
        return false
    end
    for _, buff in ipairs(buffList) do
        if self:CheckBuffIsAlive(buff) then
            return buff
        end
    end
    return false
end

---@param buff XGoldenMinerComponentBuff
---@param timeType number XGoldenMinerConfigs.BuffTimeType
function XGoldenMinerSystemBuff:CheckBuffTimeType(buff, timeType)
    return buff.TimeType == timeType
end

---@param buff XGoldenMinerComponentBuff
function XGoldenMinerSystemBuff:CheckBuffIsAlive(buff)
    return buff.Status == XGoldenMinerConfigs.GAME_BUFF_STATUS.ALIVE
end

---@param buffContainer XGoldenMinerEntityBuffContainer
---@return boolean
function XGoldenMinerSystemBuff:CheckHasBuff(buffContainer, buffType)
    if not buffContainer or XTool.IsTableEmpty(buffContainer.BuffTypeDir) then
        return false
    end
    local buffList = buffContainer.BuffTypeDir[buffType]
    if XTool.IsTableEmpty(buffList) then
        return false
    end
    for _, buff in ipairs(buffList) do
        if self:CheckBuffIsAlive(buff) then
            return true
        end
    end
    return false
end

---@param buffContainer XGoldenMinerEntityBuffContainer
---@return boolean
function XGoldenMinerSystemBuff:CheckHasBuffByBuffId(buffContainer, buffType, buffId)
    if not buffContainer or XTool.IsTableEmpty(buffContainer.BuffTypeDir) then
        return false
    end
    local buffList = buffContainer.BuffTypeDir[buffType]
    if XTool.IsTableEmpty(buffList) then
        return false
    end
    for _, buff in ipairs(buffList) do
        if self:CheckBuffIsAlive(buff) and buff.Id == buffId then
            return true
        end
    end
    return false
end

---@param buffContainer XGoldenMinerEntityBuffContainer
---@return XGoldenMinerComponentBuff
function XGoldenMinerSystemBuff:CheckHasBuffById(buffContainer, buffId)
    if not buffContainer or XTool.IsTableEmpty(buffContainer.BuffDir) then
        return false
    end
    local buffList = buffContainer.BuffTypeDir[XGoldenMinerConfigs.GetBuffType(buffId)]
    if XTool.IsTableEmpty(buffList) then
        return false
    end
    for _, buff in ipairs(buffList) do
        if buff.Id == buffId then
            return buff
        end
    end
    return false
end

---@return XGoldenMinerComponentBuff
function XGoldenMinerSystemBuff:CreateBuff(id)
    if not XTool.IsNumberValid(id) then
        return
    end
    ---@type XGoldenMinerComponentBuff
    local buff = XGoldenMinerComponentBuff.New()
    buff.Status = XGoldenMinerConfigs.GAME_BUFF_STATUS.NONE
    buff.Id = id
    buff.BuffType = XGoldenMinerConfigs.GetBuffType(id)
    buff.BuffParams = XGoldenMinerConfigs.GetBuffParams(id)
    buff.TimeType = XGoldenMinerConfigs.GetBuffTimeType(id)
    buff.TimeTypeParam = XGoldenMinerConfigs.GetBuffTimeTypeParam(id)
    buff.CurTimeTypeParam = 0
    return buff
end

---@param game XGoldenMinerGame
---@param buff XGoldenMinerComponentBuff
function XGoldenMinerSystemBuff:OnBuffDie(game, buff)
    --XGoldenMinerConfigs.DebugLog("Buff效果结束,Id="..buff.Id)
    --XGoldenMinerConfigs.DebugLogData("当前生效Buff:", self:GetAliveBuffList(game.BuffContainer))
    if buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerItemStopTime
            or buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerUseItemStopTime
    then
        self:UpdateGameStatus(game)
    elseif buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerStretchSpeed then
        self:UpdateHookShootSpeed(game)
    elseif buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerShortenSpeed then
        self:UpdateHookRevokePercent(game)
    elseif buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerStoneScore
            or buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerValueFloat
    then
        self:UpdateStoneScore(game)
    elseif buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerWeightFloat then
        self:UpdateStoneWeight(game)
    end
    buff.Status = XGoldenMinerConfigs.GAME_BUFF_STATUS.DIE
end
--endregion

--region Buff - Effect
---@param buffContainer XGoldenMinerEntityBuffContainer
---@param buff XGoldenMinerComponentBuff
function XGoldenMinerSystemBuff:BuffTriggerFullScreenEffect(buffContainer, buff)
    if buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerWeightFloat then
        self:_PlayFullScreenEffect(XGoldenMinerConfigs.GAME_EFFECT_TYPE.WEIGHT_FLOAT, XGoldenMinerConfigs.GetWeightFloatEffect())
    elseif buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerItemStopTime then
        if self:CheckHasBuff(buffContainer, buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerUseItemStopTime) then
            return
        end
        self:_PlayFullScreenEffect(XGoldenMinerConfigs.GAME_EFFECT_TYPE.TIME_STOP, XGoldenMinerConfigs.GetStopTimeStartEffect())
    elseif buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerUseItemStopTime then
        self:_PlayFullScreenEffect(XGoldenMinerConfigs.GAME_EFFECT_TYPE.TIME_STOP, XGoldenMinerConfigs.GetStopTimeStartEffect())
    end
end

---@param buffContainer XGoldenMinerEntityBuffContainer
---@param buff XGoldenMinerComponentBuff
function XGoldenMinerSystemBuff:BuffDieFullScreenEffect(buffContainer, buff)
    if buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerWeightFloat then
        self:_PlayFullScreenEffect(XGoldenMinerConfigs.GAME_EFFECT_TYPE.WEIGHT_RESUME, XGoldenMinerConfigs.GetWeightFloatEffect())
    elseif buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerItemStopTime then
        self:_PlayFullScreenEffect(XGoldenMinerConfigs.GAME_EFFECT_TYPE.TIME_RESUME, XGoldenMinerConfigs.GetStopTimeStopEffect())
    elseif buff.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerUseItemStopTime then
        if self:CheckHasBuff(buffContainer, XGoldenMinerConfigs.BuffType.GoldenMinerItemStopTime) then
            return
        end
        self:_PlayFullScreenEffect(XGoldenMinerConfigs.GAME_EFFECT_TYPE.TIME_RESUME, XGoldenMinerConfigs.GetStopTimeStopEffect())
    end
end

function XGoldenMinerSystemBuff:_PlayFullScreenEffect(effectType, path)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT, effectType, nil, path)
end
--endregion

--region BuffContainer
---@param game XGoldenMinerGame
function XGoldenMinerSystemBuff:InitBuffContainer(game)
    local buffIdList = game.BuffIdList
    for _, buffId in ipairs(buffIdList) do
        self:AddBuffById(game.BuffContainer, buffId)
    end
end

---@param buffContainer XGoldenMinerEntityBuffContainer
function XGoldenMinerSystemBuff:AddBuffById(buffContainer, buffId)
    if self:CheckIsIgnoreBuff(buffId) then
        return
    end
    local buff = self:CheckHasBuffById(buffContainer, buffId)
    if not buff then
        buff = self:CreateBuff(buffId)
        self:AddBuffInContainer(buffContainer, buff)
    end
    buff.CurTimeTypeParam = buff.TimeTypeParam
    buff.Status = XGoldenMinerConfigs.GAME_BUFF_STATUS.NONE
end

function XGoldenMinerSystemBuff:CheckIsIgnoreBuff(buffId)
    local type = XGoldenMinerConfigs.GetBuffType(buffId)
    if type == XGoldenMinerConfigs.BuffType.GoldenMinerInitItem
            or type == XGoldenMinerConfigs.BuffType.GoldenMinerInitScores
            or type == XGoldenMinerConfigs.BuffType.GoldenMinerSkipDiscount
            or type == XGoldenMinerConfigs.BuffType.GoldenMinerShopDrop
            or type == XGoldenMinerConfigs.BuffType.GoldenMinerShopDiscount
            or type == XGoldenMinerConfigs.BuffType.GoldenMinerCordMode
            or type == XGoldenMinerConfigs.BuffType.GoldenMinerRandItem
    then
        return true
    end
    return false
end

---@param buffContainer XGoldenMinerEntityBuffContainer
function XGoldenMinerSystemBuff:GetAliveBuffList(buffContainer)
    local buffTypeDir = buffContainer.BuffTypeDir
    local aliveBuffList = {}
    if XTool.IsTableEmpty(buffTypeDir) then
        return aliveBuffList
    end
    for _, buffList in pairs(buffTypeDir) do
        for _, buff in ipairs(buffList) do
            if buff.Status == XGoldenMinerConfigs.GAME_BUFF_STATUS.ALIVE then
                aliveBuffList[#aliveBuffList + 1] = buff
            end
        end
    end
    return aliveBuffList
end

---@param buffContainer XGoldenMinerEntityBuffContainer
---@param buff XGoldenMinerComponentBuff
function XGoldenMinerSystemBuff:AddBuffInContainer(buffContainer, buff)
    if not buffContainer then
        return false
    end
    if not buffContainer.BuffTypeDir[buff.BuffType] then
        buffContainer.BuffTypeDir[buff.BuffType] = {}
    end
    local buffList = buffContainer.BuffTypeDir[buff.BuffType]
    local index
    if XTool.IsTableEmpty(buffList) then
        buffList[#buffList + 1] = buff
        return
    end
    for i, Buff in ipairs(buffList) do
        if Buff.Id == buff.Id then
            index = i
        end
    end
    if index then
        buffList[index] = buff
    else
        buffList[#buffList + 1] = buff
    end
end

---@param game XGoldenMinerGame
---@param buffContainer XGoldenMinerEntityBuffContainer
---@return boolean
function XGoldenMinerSystemBuff:UpdateBuffContainer(game, buffContainer, time)
    if not buffContainer or XTool.IsTableEmpty(buffContainer.BuffTypeDir) then
        return
    end
    for _, buffList in pairs(buffContainer.BuffTypeDir) do
        for _, buff in ipairs(buffList) do
            self:UpdateBuff(game, buff, time)
        end
    end
end
--endregion

return XGoldenMinerSystemBuff