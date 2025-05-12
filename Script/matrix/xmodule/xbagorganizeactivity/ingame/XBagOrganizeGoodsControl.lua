--- 玩法内分管货物相关逻辑的控制器
---@class XBagOrganizeGoodsControl: XControl
---@field private _MainControl XBagOrganizeActivityGameControl
---@field private _Model XBagOrganizeActivityModel
---@field _GoodsEntityPool XPool
local XBagOrganizeGoodsControl = XClass(XControl, 'XBagOrganizeGoodsControl')
local XBagOrganizeGoodsEntity = require('XModule/XBagOrganizeActivity/InGame/Entity/XBagOrganizeGoodsEntity')

function XBagOrganizeGoodsControl:OnInit()
    --- 放置到背包中的货物数据的对象池
    self._GoodsEntityPool = XPool.New(function()
        return XBagOrganizeGoodsEntity.New()
    end, function(goods)
        goods:RemoveAllBuffEffectByHand()
    end, false)

    self._MainControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_RANDOMEVENT_EFFECT_VALID, self.OnNewEventEffectValid, self)
end

function XBagOrganizeGoodsControl:OnRelease()
    
end

function XBagOrganizeGoodsControl:ResetInNewGame()
    -- 在列表中的货物Id列表
    self._GoodsIdsInList = {}
    -- 在背包中的货物Id列表（未打包）
    self._GoodsIdsInBag = {}
    -- 已经打包的货物字典 key: GoodsId
    self._IsPackingGoodsDict = {}
    -- 放置到背包中的货物数据实体字典 key：Uid
    self._PlacedGoodsEntities = {}
    
    self:InitGoodsIdsInListOnGameStart()
end

function XBagOrganizeGoodsControl:ResetCurGameSchedule(isInit)
    -- 回收放置的货物
    if not XTool.IsTableEmpty(self._PlacedGoodsEntities) then
        for i, v in pairs(self._PlacedGoodsEntities) do
            self._MainControl.MapControl:ClearPlacedGoodsTagInBlock(v)
            self._GoodsEntityPool:ReturnItemToPool(v)
        end
    end
    -- 清空已放置货物字典
    self._PlacedGoodsEntities = {}
    -- 清空当前放置的部分
    self._GoodsIdsInBag = {}

    if isInit then
        self._IsPackingGoodsDict = {}
        -- 因为目前只有非限时非随机关卡有重置功能，因此直接初始化货物列表即可
        self._GoodsIdsInList = {}
        self:InitGoodsIdsInListOnGameStart()
    end
end

function XBagOrganizeGoodsControl:GetNewGoodsFromPool(uid, goodsId, cfg)
    local goods = self._GoodsEntityPool:GetItemFromPool()
    goods:SetData(goodsId, uid, cfg.Blocks, cfg.Value)
    -- 有效才参与得分计算，新生成的货物实体都需要参与得分计算
    goods:SetIsValid(true)
    
    return goods
end

--- 根据传入的货物唯一值，将指定货物从列表及背包中移除
function XBagOrganizeGoodsControl:RemoveGoodsByComposeId(composeId)
    if XTool.IsNumberValid(composeId) then
        if not self:CheckGoodsIsPackingById(composeId) then
            local uid = XMath.ToInt(composeId / 10000)
            self:SetGoodsIsUsed(composeId, nil)
            -- 从列表中移除
            local isIn, index = table.contains(self._GoodsIdsInList, composeId)
            if isIn then
                table.remove(self._GoodsIdsInList, index)
            end
            -- 从背包中移除
            ---@type XBagOrganizeGoodsEntity
            local entity = self._PlacedGoodsEntities[uid]

            if entity then
                -- 如果是正在编辑的道具，直接取消
                if entity == self._MainControl._PrePlaceItemEntity then
                    self._MainControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_CLOSE_ITEMOPTION)
                    self._MainControl:CancelPlaceGoods()
                else
                    -- 从背包中移除
                    self._MainControl.MapControl:ClearPlacedGoodsTagInBlock(entity)
                    self:SetGoodsToPlacedDict(uid, nil)
                    local cfg = self._Model:GetBagOrganizeGoodsConfig()[entity.Id]

                    -- 刷新同色加成
                    self._MainControl:DealWithGoodsSameColorCombo(cfg.BlockColor)
                    -- 回收实体
                    self:RecycleGoodsEntity(self._PrePlaceItemEntity)
                end

                -- 广播刷新列表和背包
                self._MainControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_GOODS_LIST)
                self._MainControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_GOODS_SHOW)
            end
        end
    end
end

--region ---------- 货物列表 ---------->>>

--- 新一局开始阶段的列表初始化
function XBagOrganizeGoodsControl:InitGoodsIdsInListOnGameStart()
    if self._MainControl:IsTimelimitEnabled() then
        -- 目前只有限时玩法需要复杂处理
    else
        -- 非限时玩法直接读第一组的货物id列表就行
        local goodsIds = self:GetNoTimelimitStageGoodsIdsById(self._Model:GetCurStageId())
        
        if not self:AddGoodsIdsInList(goodsIds) then
            XLog.Error('关卡'..tostring(self._Model:GetCurStageId())..'未开启限时玩法，且找不到固定货物列表配置')
        end
    end
end

function XBagOrganizeGoodsControl:AddGoodsIdsInList(goodsIds, needUniIdList)
    if not XTool.IsTableEmpty(goodsIds) then
        local uniIdList

        if needUniIdList then
            uniIdList = {}

            -- 对货物Id进行唯一性处理
            for i = 1, #goodsIds do
                -- id = uid * 10000 + goodsId
                uniIdList[i] = self._MainControl:GetNewUid() * 10000 + goodsIds[i]
            end

            for i, id in pairs(uniIdList) do
                table.insert(self._GoodsIdsInList, id)
            end

            return uniIdList
        else
            for i, goodsId in pairs(goodsIds) do
                -- id = uid * 10000 + goodsId
                local id = self._MainControl:GetNewUid() * 10000 + goodsId
                table.insert(self._GoodsIdsInList, id)
            end
            return true
        end
    end
end

--- 获取在列表中的货物Id
function XBagOrganizeGoodsControl:GetGoodsIdsInList()
    return self._GoodsIdsInList
end

--- 获取已打包的货物数量
function XBagOrganizeGoodsControl:GetIsPackingCount()
    return XTool.GetTableCount(self._IsPackingGoodsDict)
end

--- 获取在列表中的货物数量（注意的是不会区分是否已打包，如果打包后不销毁，一样计数）
function XBagOrganizeGoodsControl:GetGoodsInListCount()
    return XTool.GetTableCount(self._GoodsIdsInList)
end

--- 统计列表中所有未打包的货物的总价值（包括事件加成），用于限时玩法刷新规则
function XBagOrganizeGoodsControl:GetGoodsTotalValueInList()
    local totalValue = 0

    if not XTool.IsTableEmpty(self._GoodsIdsInList) then
        for i, uid in pairs(self._GoodsIdsInList) do
            if not self:CheckGoodsIsPackingById(uid) then
                local goodsId = XMath.ToMinInt(math.fmod(uid, 10000))
                local cfg = self._Model:GetBagOrganizeGoodsConfig()[goodsId]

                if cfg then
                    local eventBuffMulty = self._MainControl.TimelimitControl:GetEventBuffTotalMulty(cfg)
                    if XTool.IsNumberValid(eventBuffMulty) then
                        totalValue = totalValue + (cfg.Value + math.ceil(cfg.Value * eventBuffMulty))
                    else
                        totalValue = totalValue + cfg.Value
                    end
                end
            end
        end
    end
    
    return totalValue
end

--- 将存在列表中的指定货物配置Id转移到已打包列表
---@param id @ uid * 10000 + goodsId
function XBagOrganizeGoodsControl:SetGoodsIdToPacking(id)
    self._IsPackingGoodsDict[id] = true
end

--- 根据货物配置Id判断是否已经被打包了
---@param id @ uid * 10000 + goodsId
function XBagOrganizeGoodsControl:CheckGoodsIsPackingById(id)
    return self._IsPackingGoodsDict[id] and true or false
end

--- 判断是否有任意货物已经打包了，用于多背包玩法判断是否可以重置
function XBagOrganizeGoodsControl:CheckAnyGoodsIsPacking()
    return not XTool.IsTableEmpty(self._IsPackingGoodsDict)
end

function XBagOrganizeGoodsControl:GetPackingDic()
    return self._IsPackingGoodsDict
end

---@param id @ uid * 10000 + goodsId
function XBagOrganizeGoodsControl:SetGoodsIsUsed(id, isUse)
    self._GoodsIdsInBag[id] = isUse
end

---@param id @ uid * 10000 + goodsId
function XBagOrganizeGoodsControl:GetIsGoodsUsedById(id)
    return self._GoodsIdsInBag[id] or false
end

--endregion <<<--------------------------

--region ---------- 背包内 ---------->>>

function XBagOrganizeGoodsControl:GetPlacedGoodsEntities()
    return self._PlacedGoodsEntities
end

--- 获取数组形式的已放置货物数据
function XBagOrganizeGoodsControl:GetPlacedGoodsEntityList()
    local entities = self:GetPlacedGoodsEntities()

    local entitiesList = {}


    if not XTool.IsTableEmpty(entities) then
        for i, v in pairs(entities) do
            if v ~= self._MainControl._PrePlaceItemEntity then
                table.insert(entitiesList, v)
            end
        end
    end

    return entitiesList
end

--- 根据Uid获取对应放置货物的配置Id
function XBagOrganizeGoodsControl:GetPlacedGoodsId(uid)
    if self._PlacedGoodsEntities then
        local entity = self._PlacedGoodsEntities[uid]
        if entity then
            return entity.Id
        end
    end
    return 0
end

--- 根据Uid获取对应放置货物的格子数据
function XBagOrganizeGoodsControl:GetPlacedGoodsBlocks(uid)
    if self._PlacedGoodsEntities then
        local entity = self._PlacedGoodsEntities[uid]
        if entity then
            return entity:GetBlocks()
        end
    end
    return nil
end

--- 根据Uid获取对应放置货物的旋转信息
function XBagOrganizeGoodsControl:GetPlacedGoodsRotateTimes(uid)
    if self._PlacedGoodsEntities then
        local entity = self._PlacedGoodsEntities[uid]
        if entity then
            return entity:GetRotateTimes()
        end
    end
    return 0
end

--- 将货物设置到已放置列表中（放置用于参与相关计算，不一定是真放置成功）
---@param goods XBagOrganizeGoodsEntity
function XBagOrganizeGoodsControl:SetGoodsToPlacedDict(uid, goods)
    self._PlacedGoodsEntities[uid] = goods
end

--- 回收货物对象
function XBagOrganizeGoodsControl:RecycleGoodsEntity(goods)
    self._GoodsEntityPool:ReturnItemToPool(goods)
end

--- 获取指定货物的总价值（不考虑破损的损耗）
function XBagOrganizeGoodsControl:GetGoodsTotalValue(uid)
    if not XTool.IsNumberValid(uid) then
        return 0
    end

    if not XTool.IsTableEmpty(self._PlacedGoodsEntities) then
        ---@type XBagOrganizeGoodsEntity
        local entity = self._PlacedGoodsEntities[uid]
        if entity then
            return entity.Value:GetFinalValIntCeil()
        end
    end

    return 0
end

--- 获取指定货物的同色加成价值
function XBagOrganizeGoodsControl:GetGoodsComboValue(uid)
    if not XTool.IsNumberValid(uid) then
        return 0
    end

    if not XTool.IsTableEmpty(self._PlacedGoodsEntities) then
        ---@type XBagOrganizeGoodsEntity
        local entity = self._PlacedGoodsEntities[uid]
        if entity then
            return entity.Value:GetMultyBuffAddsByBuffType(XMVCA.XBagOrganizeActivity.EnumConst.BuffType.SameColorCombo)
        end
    end

    return 0
end

--- 获取指定货物的事件加成价值
function XBagOrganizeGoodsControl:GetEventBuffValue(uid)
    if not XTool.IsNumberValid(uid) then
        return 0
    end

    if not XTool.IsTableEmpty(self._PlacedGoodsEntities) then
        ---@type XBagOrganizeGoodsEntity
        local entity = self._PlacedGoodsEntities[uid]
        if entity then
            return entity.Value:GetMultyBuffAddsByBuffType(XMVCA.XBagOrganizeActivity.EnumConst.BuffType.RandomEvent)
        end
    end

    return 0
end

--- 判断指定Uid的货物实体，是否拥有同色加成buff
function XBagOrganizeGoodsControl:IsGoodsSameColorCombo(uid)
    if not XTool.IsNumberValid(uid) then
        return false
    end
    
    if not XTool.IsTableEmpty(self._PlacedGoodsEntities) then
        ---@type XBagOrganizeGoodsEntity
        local entity = self._PlacedGoodsEntities[uid]
        if entity then
            return entity:CheckHasBuffByBuffType(XMVCA.XBagOrganizeActivity.EnumConst.BuffType.SameColorCombo)
        end
    end

    return false
end

--- 判断指定Uid的货物实体，是否拥有事件加成buff
function XBagOrganizeGoodsControl:IsGoodsEventBuff(uid)
    if not XTool.IsNumberValid(uid) then
        return false
    end

    if not XTool.IsTableEmpty(self._PlacedGoodsEntities) then
        ---@type XBagOrganizeGoodsEntity
        local entity = self._PlacedGoodsEntities[uid]
        if entity then
            return entity:CheckHasBuffByBuffType(XMVCA.XBagOrganizeActivity.EnumConst.BuffType.RandomEvent)
        end
    end

    return false
end

--- 检查是否存在任意已放置的货物是无效的(用于打包前的检查）
function XBagOrganizeGoodsControl:CheckAnyPlacedGoodsIsInvalid()
    if not XTool.IsTableEmpty(self._PlacedGoodsEntities) then
        ---@param v XBagOrganizeGoodsEntity
        for i, v in pairs(self._PlacedGoodsEntities) do
            if not v:GetIsValid() then
                return true
            end
        end 
    end
end

--- 将已放置的所有货物都设置为已打包
function XBagOrganizeGoodsControl:SetAllPlacedGoodsToPacking(isRemove)
    if not XTool.IsTableEmpty(self._PlacedGoodsEntities) then
        ---@param v XBagOrganizeGoodsEntity
        for i, v in pairs(self._PlacedGoodsEntities) do
            self._MainControl.MapControl:ClearPlacedGoodsTagInBlock(v)
            self:SetGoodsIdToPacking(v.ComposeId)
            self._GoodsEntityPool:ReturnItemToPool(v)

            if isRemove then
                local isIn, index = table.contains(self._GoodsIdsInList, v.ComposeId)

                if isIn then
                    table.remove(self._GoodsIdsInList, index)
                    self:SetGoodsIsUsed(v, nil)

                    -- 检查如果是限时货物，也要从限时列表中移除
                    if XTool.IsNumberValid(self._MainControl.TimelimitControl:GetGoodsTotalLifeTimeByUid(v.ComposeId)) then
                        self._MainControl.TimelimitControl:RemoveFromTimelimitMapById(v.ComposeId)
                    end
                end
            end
        end

        self._PlacedGoodsEntities = {}
    end
end

--- 当有新事件buff产生时，背包上的货物需要重新刷新一次buff
function XBagOrganizeGoodsControl:OnNewEventEffectValid()
    if not XTool.IsTableEmpty(self._PlacedGoodsEntities) then
        ---@param v XBagOrganizeGoodsEntity
        for i, v in pairs(self._PlacedGoodsEntities) do
            -- 先取消事件加成
            v:ClearBuffEffectByTypeOrConfigId(XMVCA.XBagOrganizeActivity.EnumConst.BuffType.RandomEvent)
            -- 再重新添加
            self._MainControl.TimelimitControl:TryAddEventBuff(v)
        end
    end
    self._MainControl:RefreshValidTotalScore()
    self._MainControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_TOTALSCORE_UPDATE)
end
--endregion <<<-----------------------

--region ---------- Configs ---------->>>

function XBagOrganizeGoodsControl:GetNoTimelimitStageGoodsIdsById(stageId)
    ---@type XTableBagOrganizeStage
    local stageCfg = self._Model:GetBagOrganizeStageCfgById(self._Model:GetCurStageId())
    
    if stageCfg then
        local goodsRuleId = stageCfg.GoodsRuleIds[1]

        if XTool.IsNumberValid(goodsRuleId) then
            ---@type XTableBagOrganizeGoodsRule
            local goodsRuleCfg = self._Model:GetBagOrganizeGoodsRuleCfgById(goodsRuleId)

            if goodsRuleCfg then
                local constantGroupId = goodsRuleCfg.ConstantGroupId

                if XTool.IsNumberValid(constantGroupId) then
                    ---@type XTableBagOrganizeGoodsGroup
                    local groupCfg = self._Model:GetBagOrganizeGoodsGroupCfgById(constantGroupId)
                    
                    return groupCfg and groupCfg.GoodsList or nil
                end
            end
        end
    end
end

--endregion <<<-------------------------

return XBagOrganizeGoodsControl