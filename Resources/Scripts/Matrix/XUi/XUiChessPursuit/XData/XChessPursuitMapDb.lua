--- 管理ChessPursuitMapDb的服务端数据，只能通过Get方法获取内部数据

local XChessPursuitMapDb = XClass(nil, "XChessPursuitMapDb")
local CSXChessPursuitDirection = CS.XChessPursuitDirection

-- 服务端没发mapDb的情况发，可传mapId会创建一个虚拟对象
function XChessPursuitMapDb:Ctor(mapDbOrMapId)
    local mapDb
    if (type(mapDbOrMapId) == "number") then
        self.Virtual = true
        local chessPursuitMapTemplate = XChessPursuitConfig.GetChessPursuitMapTemplate(mapDbOrMapId)
        local chessPursuitMapBoss = XDataCenter.ChessPursuitManager.GetChessPursuitMapBoss(chessPursuitMapTemplate.BossId)
        mapDb = {
            Id = mapDbOrMapId,
            WinForBattleCount = 0,
            BossBattleCount = 0,
            IsTakeReward = false,
            BossHp = chessPursuitMapBoss and chessPursuitMapBoss:GetInitHp() or 0,
            Coin = 0,
            BuyedCardId = {},
        }
    else
        self.Virtual = false
        mapDb = mapDbOrMapId
    end
    
    self.ChessPursuitMapDb = mapDb
    self.ChessPursuitMapTemplate = XChessPursuitConfig.GetChessPursuitMapTemplate(self.ChessPursuitMapDb.Id)

    self:InitBuyedCardIdDic()
end

function XChessPursuitMapDb:InitBuyedCardIdDic()
    self.BuyedCardIdDic = {}
    for _, buyedCardId in ipairs(self.ChessPursuitMapDb.BuyedCardId) do
        self.BuyedCardIdDic[buyedCardId] = true
    end
end

function XChessPursuitMapDb:GetMapId()
    return self.ChessPursuitMapDb.Id
end

function XChessPursuitMapDb:GetVirtual()
    return self.Virtual
end

-- BOSS当前的位置
function XChessPursuitMapDb:GetBossPos()
    return self.ChessPursuitMapDb.BossPos
end

function XChessPursuitMapDb:GetBossMoveDirection()
    if self.ChessPursuitMapDb.BossMoveDirection == 1 then
        return CSXChessPursuitDirection.Forward
    elseif self.ChessPursuitMapDb.BossMoveDirection == -1 then
        return CSXChessPursuitDirection.Back
    end
end

function XChessPursuitMapDb:GetChessPursuitMapTemplate()
    return self.ChessPursuitMapTemplate
end

--需要先布阵
function XChessPursuitMapDb:NeedBuZhen()
    if XTool.IsTableEmpty(self.ChessPursuitMapDb.GridTeamDb) then
        return true
    end

    if #self.ChessPursuitMapDb.GridTeamDb < 1 then
        return true
    else
        return false
    end
end

--排行榜奖励可领取
function XChessPursuitMapDb:IsTakeReward()
    return self.ChessPursuitMapDb.IsTakeReward
end

--击杀BOSS历史最少的战斗次数
function XChessPursuitMapDb:GetWinForBattleCount()
    return self.ChessPursuitMapDb.WinForBattleCount
end

--当前与BOSS战斗的次数
function XChessPursuitMapDb:GetBossBattleCount()
    return self.ChessPursuitMapDb.BossBattleCount
end

--货币
function XChessPursuitMapDb:GetCoin()
    return self.ChessPursuitMapDb.Coin
end

--BOSS当前状态是否被击杀
function XChessPursuitMapDb:IsClear()
    return self.ChessPursuitMapDb.BossHp <= 0
end

--BOSS曾经被击杀过，不管当前状态
function XChessPursuitMapDb:IsKill()
    return self.ChessPursuitMapDb.WinForBattleCount > 0
end

function XChessPursuitMapDb:GetGridTeamDb()
    return self.ChessPursuitMapDb.GridTeamDb
end

function XChessPursuitMapDb:SetGridTeamDb(gridTeamDb)
    self.ChessPursuitMapDb.GridTeamDb = gridTeamDb
end

function XChessPursuitMapDb:GetBossHp()
    return self.ChessPursuitMapDb.BossHp
end

function XChessPursuitMapDb:ChangeGridTeamDb(data)
    for i, gridTeamDb in ipairs(self.ChessPursuitMapDb.GridTeamDb) do
        if gridTeamDb.Id == data.GridId then
            gridTeamDb.FirstFightPos = data.FirstFightPos
            gridTeamDb.CaptainPos = data.CaptainPos
            gridTeamDb.CardIds = data.CardIds
            gridTeamDb.RobotIds = data.RobotIds
            return
        end
    end
end

function XChessPursuitMapDb:GetGridTeamDbByGridId(teamGridIndex)
    local gridId = self.ChessPursuitMapTemplate.TeamGrid[teamGridIndex]

    for i,gridTeamDb in ipairs(self.ChessPursuitMapDb.GridTeamDb) do
        if gridTeamDb.Id == gridId then
            return gridTeamDb
        end
    end
end

--对boss造成最高伤害记录
function XChessPursuitMapDb:GetHurtBossByGridId(teamGridIndex)
    local gridTeamDb = self:GetGridTeamDbByGridId(teamGridIndex)

    if gridTeamDb then
        return gridTeamDb.HurtBoss or 0
    else
        return 0
    end
end

function XChessPursuitMapDb:GetGridTeamCaptainCharacterIdIdByGridId(teamGridIndex)
    local teamCharacterIds = self:GetTeamCharacterIds(teamGridIndex)
    
    if next(teamCharacterIds) then
        local gridTeamDb = self:GetGridTeamDbByGridId(teamGridIndex)
        return teamCharacterIds[gridTeamDb.CaptainPos]
    end
end

function XChessPursuitMapDb:GetTeamCharacterIds(teamGridIndex, isNotConverRobotId)
    local gridTeamDb = self:GetGridTeamDbByGridId(teamGridIndex)
    local tl = {}
    if not gridTeamDb then
        return tl
    end

    for i, characterId in ipairs(gridTeamDb.CardIds) do
        -- 0即可能没有上阵或在RobotIds
        if characterId ~= 0 then
            tl[i] = characterId
        else
            local robotId = gridTeamDb.RobotIds[i]
            tl[i] = isNotConverRobotId and robotId or XRobotManager.GetCharacterId(robotId)
        end
    end

    return tl
end

function XChessPursuitMapDb:GetRewardState()
    local taskId = self.ChessPursuitMapTemplate.TaskId
    local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
    if taskData then
        if taskData.State then
            if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then --未领奖励
                return XDataCenter.TaskManager.TaskState.Achieved
            elseif taskData.State == XDataCenter.TaskManager.TaskState.Finish then --已领取奖励
                return XDataCenter.TaskManager.TaskState.Finish
            else
                return XDataCenter.TaskManager.TaskState.InActive --不显示按钮
            end
        else
            return XDataCenter.TaskManager.TaskState.InActive --不显示按钮
        end
    end
end

--手上有的卡
function XChessPursuitMapDb:GetBuyedCards()
    -- int Id;
    -- int CardCfgId;
    -- int KeepCount;
    return self.ChessPursuitMapDb.BuyedCards
end

function XChessPursuitMapDb:GetGridCardDb()
    return self.ChessPursuitMapDb.GridCardDb
end

function XChessPursuitMapDb:GetBossCardDb()
    return self.ChessPursuitMapDb.BossCardDb
end


function XChessPursuitMapDb:GetHaveCardsCount()
    local buyedCards = self:GetBuyedCards()
    return buyedCards and #buyedCards or 0
end

--卡牌是否已购买过
function XChessPursuitMapDb:IsBuyedCard(id)
    if id and self.BuyedCardIdDic[id] then
        return true
    end
    return false
end

--是否可以领取奖励
function XChessPursuitMapDb:IsCanTakeReward()
    local taskState = self:GetRewardState()

    if self:IsKill() then
        if taskState == XDataCenter.TaskManager.TaskState.Achieved then
            return true
        else
            return false
        end
    else
        return false
    end
end

--@region ！！！以下函数只可以由XChessPursuitManager里的函数调用
function XChessPursuitMapDb:SetGridTeamDbHurtBoss(teamGridIndex, value)
    local gridTeamDb = self:GetGridTeamDbByGridId(teamGridIndex)
    if gridTeamDb then
        gridTeamDb.HurtBoss = value
    end
end

function XChessPursuitMapDb:SetBossPos(value)
    self.ChessPursuitMapDb.BossPos = value
end

function XChessPursuitMapDb:SubBossHp(value)
    self:SetBossHp(self.ChessPursuitMapDb.BossHp - value)
end

function XChessPursuitMapDb:SetBossHp(value)
    self.ChessPursuitMapDb.BossHp = value
    if self:GetBossHp() <= 0 then
        if self.ChessPursuitMapDb.WinForBattleCount == 0 or self.ChessPursuitMapDb.WinForBattleCount > self.ChessPursuitMapDb.BossBattleCount then
            self.ChessPursuitMapDb.WinForBattleCount = self.ChessPursuitMapDb.BossBattleCount
        end
    end
end

function XChessPursuitMapDb:AddBuyedCards(values)
    for i,v in ipairs(values) do
        table.insert(self.ChessPursuitMapDb.BuyedCards, v)
    end
end

function XChessPursuitMapDb:SetCoin(value)
    self.ChessPursuitMapDb.Coin = value
end

--减掉消耗了的货币
function XChessPursuitMapDb:SubCoin(subCoin)
    self.ChessPursuitMapDb.Coin = self.ChessPursuitMapDb.Coin - subCoin
end

function XChessPursuitMapDb:RemoveCardsByUsedToGrid(usedToGrid)
    for gridId, xChessPursuitCardDbList in pairs(usedToGrid) do
        for _,xChessPursuitCardDb in ipairs(xChessPursuitCardDbList) do
            for i=#self.ChessPursuitMapDb.BuyedCards, 1, -1 do
                if xChessPursuitCardDb.Id == self.ChessPursuitMapDb.BuyedCards[i].Id then
                    table.remove(self.ChessPursuitMapDb.BuyedCards, i)
                    break
                end
            end
        end
    end
end

function XChessPursuitMapDb:RemoveCardsByUesdToBoss(uesdToBoss)
    for gridId, xChessPursuitCardDb in pairs(uesdToBoss) do
        for i=#self.ChessPursuitMapDb.BuyedCards, 1, -1 do
            if xChessPursuitCardDb.Id == self.ChessPursuitMapDb.BuyedCards[i].Id then
                table.remove(self.ChessPursuitMapDb.BuyedCards, i)
                break
            end
        end
    end
end

function XChessPursuitMapDb:AddGridCardDb(usedToGrid)
    for gridId, xChessPursuitCardDbList in pairs(usedToGrid) do
        for _,xChessPursuitCardDb in ipairs(xChessPursuitCardDbList) do
            local isInsert = false
            for i,v in ipairs(self.ChessPursuitMapDb.GridCardDb) do
                if v.Id == gridId then
                    table.insert(v.Cards, xChessPursuitCardDb)
                    isInsert = true
                    break
                end
            end
            if not isInsert then
                table.insert(self.ChessPursuitMapDb.GridCardDb, {
                    Id = gridId,
                    Cards = {xChessPursuitCardDb}
                })
            end
        end
    end
end

function XChessPursuitMapDb:AddBossCardDb(uesdToBoss)
    for i,v in ipairs(uesdToBoss) do
        table.insert(self.ChessPursuitMapDb.BossCardDb, v)
    end
end

function XChessPursuitMapDb:RefreshKeepCount(cardId, keepCount)
    for i,v in ipairs(self.ChessPursuitMapDb.GridCardDb) do
        for i,xChessPursuitCardDb in ipairs(v.Cards) do
            if xChessPursuitCardDb.Id == cardId then
                if keepCount == 0 then
                    local cfg = XChessPursuitConfig.GetChessPursuitCardTemplate(xChessPursuitCardDb.CardCfgId)
                    local cfgEffect = XChessPursuitConfig.GetChessPursuitCardEffectTemplate(cfg.EffectId)
                    --keepType 0 是永久效果
                    if cfgEffect.KeepType ~= 0 then
                        table.remove(v.Cards, i)
                    end
                else
                    xChessPursuitCardDb.KeepCount = keepCount
                end
                break
            end
        end
    end

    for i,xChessPursuitCardDb in ipairs(self.ChessPursuitMapDb.BossCardDb) do
        if xChessPursuitCardDb.Id == cardId then
            if keepCount == 0 then
                local cfg = XChessPursuitConfig.GetChessPursuitCardTemplate(xChessPursuitCardDb.CardCfgId)
                local cfgEffect = XChessPursuitConfig.GetChessPursuitCardEffectTemplate(cfg.EffectId)
                --keepType 0 是永久效果
                if cfgEffect.KeepType ~= 0 then
                    table.remove(self.ChessPursuitMapDb.BossCardDb, i)
                end
            else
                xChessPursuitCardDb.KeepCount = keepCount
            end
            break
        end
    end
end

function XChessPursuitMapDb:SetBossMoveDirection(value)
    if value and value ~= 0 then
        self.ChessPursuitMapDb.BossMoveDirection = value
    end
end

function XChessPursuitMapDb:AddBossBattleCount(value)
    self.ChessPursuitMapDb.BossBattleCount = self.ChessPursuitMapDb.BossBattleCount + value
end

--保存已购买的卡牌id
function XChessPursuitMapDb:AddBuyedCardId(cardIds)
    for _, v in ipairs(cardIds) do
        self.BuyedCardIdDic[v.CardCfgId] = true
    end
end

--保存已购买的卡牌id
function XChessPursuitMapDb:AddBuyedCardId(cardIds)
    for _, v in ipairs(cardIds) do
        self.BuyedCardIdDic[v.CardCfgId] = true
    end
end
--@endregion

return XChessPursuitMapDb