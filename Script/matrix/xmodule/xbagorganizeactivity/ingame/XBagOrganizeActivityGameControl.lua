---@class XBagOrganizeActivityGameControl : XControl
---@field private _Model XBagOrganizeActivityModel
---@field _MainControl XBagOrganizeActivityControl
---@field _PrePlaceItemEntity XBagOrganizePlaceableEntity
---@field _ComboCalStack XStack
local XBagOrganizeActivityGameControl = XClass(XControl, "XBagOrganizeActivityGameControl")

function XBagOrganizeActivityGameControl:OnInit()
    ---@type XBagOrganizeMapControl @玩法内分管背包地块相关逻辑的控制器
    self.MapControl = self:AddSubControl(require('XModule/XBagOrganizeActivity/InGame/XBagOrganizeMapControl'))
    ---@type XBagOrganizeBuffControl @玩法内分管buff系统的控制器
    self.BuffControl = self:AddSubControl(require('XModule/XBagOrganizeActivity/InGame/XBagOrganizeBuffControl'))
    ---@type XBagOrganizeGoodsControl @玩法内分管货物相关逻辑的控制器
    self.GoodsControl = self:AddSubControl(require('XModule/XBagOrganizeActivity/InGame/XBagOrganizeGoodsControl'))
    ---@type XBagOrganizeTimelimitControl @玩法内分管限时玩法的控制器
    self.TimelimitControl = self:AddSubControl(require('XModule/XBagOrganizeActivity/InGame/XBagOrganizeTimelimitControl'))
    
    self._PrePlaceItemEntity = nil
    
    self._UidSets = 0
    
    ---@type XBagOrganizeScoreEntity
    self._TotalScore = require('XModule/XBagOrganizeActivity/InGame/Entity/XBagOrganizeScoreEntity').New()
    
    self._ComboCalStack = XStack.New()
    
    self.GoodsListCountMax = self._MainControl:GetClientConfigNum('GoodsListCountMax')
end

function XBagOrganizeActivityGameControl:OnRelease()
    
end

function XBagOrganizeActivityGameControl:InitGame()
    self._CurStageId = self._MainControl:GetCurStageId()
    self.MapControl:ResetMap()
    self.GoodsControl:ResetInNewGame()
    self:ResetGame(true)
    self.TimelimitControl:ResetInNewGame()
    self:ResetRecordGameContentData()
end

function XBagOrganizeActivityGameControl:GetCurStageId()
    return self._CurStageId or 0
end

--- 获取Scope派生对象，实际游戏会按照派生类型分类，这里的接口用于读取处于任意分类中的scope
function XBagOrganizeActivityGameControl:GetScopeEntityById(id)
    local scope = self.GoodsControl:GetPlacedGoodsEntities()[id]

    -- 因为现在只有货物，所以直接返回，如果后续有派生其他可放置物体，则需要做兼顾处理
    return scope
end

function XBagOrganizeActivityGameControl:GetNewUid()
    self._UidSets = self._UidSets + 1
    return self._UidSets
end

--region ---------------------------- PrePlaceItem ----------------------------->>>

function XBagOrganizeActivityGameControl:GetPreItemId()
    return self._PrePlaceItemEntity and self._PrePlaceItemEntity.Id or 0
end

function XBagOrganizeActivityGameControl:GetPreItemType()
    return self._PrePlaceItemEntity and self._PrePlaceItemEntity:GetType() or XMVCA.XBagOrganizeActivity.EnumConst.EntityType.Placeable
end

function XBagOrganizeActivityGameControl:GetPreItemBlocks()
    return self._PrePlaceItemEntity and self._PrePlaceItemEntity:GetBlocks() or nil
end

function XBagOrganizeActivityGameControl:GetPreItemLeftUp()
    if self._PrePlaceItemEntity then
        return self._PrePlaceItemEntity:GetLeftUpX(), self._PrePlaceItemEntity:GetLeftUpY()
    end
    
    return 0, 0
end

function XBagOrganizeActivityGameControl:GetPreItemUid()
    return self._PrePlaceItemEntity and self._PrePlaceItemEntity.Uid or 0
end

function XBagOrganizeActivityGameControl:RotatePreItem()
    if self._PrePlaceItemEntity then
        self._PrePlaceItemEntity:SetRotateTimes(self._PrePlaceItemEntity:GetRotateTimes() + 1)
    end
end

function XBagOrganizeActivityGameControl:UpdatePreItemLeftUpPos(x, y)
    if self._PrePlaceItemEntity then
        self._PrePlaceItemEntity:SetLeftUp(x, y)
    end
end
---------------------------------------- Goods --------------------------------------------

---@param id @uid * 10000 + goodsId
function XBagOrganizeActivityGameControl:CreateNewGoodsToPrePlace(id)
    -- 如果当前编辑物体可以放下（无冲突）则直接放下，否则移除
    if self._PrePlaceItemEntity and self:CheckPreGoodsPositionIsValid() then
        self:PlaceGoods()
        self:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_GOODS_SHOW)
    else
        self:CancelPlaceGoods()
    end

    local goodsId = XMath.ToMinInt(math.fmod(id, 10000))
    local uid = XMath.ToMinInt(id / 10000)
    
    local cfg = self._MainControl:GetGoodsCfgById(goodsId)
    local goods = self.GoodsControl:GetNewGoodsFromPool(uid, goodsId, cfg)
    self._PrePlaceItemEntity = goods
    -- 新生成的货物先添加到放置列表中，但不施加占位效果
    self.GoodsControl:SetGoodsToPlacedDict(uid, goods)
    self:DealWithGoodsSameColorCombo(cfg.BlockColor)
    self.TimelimitControl:TryAddEventBuff(goods)
end

function XBagOrganizeActivityGameControl:SetGoodsToPrePlace(uid, uiPos)
    local entity = self.GoodsControl:GetPlacedGoodsEntities()[uid]
    
    if entity then
        self:CancelPlaceGoods()
        -- 将货物设置到编辑位
        self._PrePlaceItemEntity = entity
        -- 移除对应地块的占据标记
        self.MapControl:ClearPlacedGoodsTagInBlock(entity)
        -- 编辑中的货物均以有效的状态进行算分
        entity:SetIsValid(true)

        self:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_OPEN_GOODSOPTION, uiPos)
        self:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_GOODS_SHOW)
    end
end

--- 检查预放置的货物是否越界(在总网格尺寸范围以外）
function XBagOrganizeActivityGameControl:CheckPreGoodsPositionIsOutBoard(leftUpX, leftUpY)
    local isOutBoard = false

    if self._PrePlaceItemEntity then
        for i, v in ipairs(self._PrePlaceItemEntity:GetBlocks()) do
            if XTool.IsNumberValid(v) then
                -- 将局部的4x4网格坐标进行转换
                local locXOffset = (i - 1) % 4
                local locYOffset = XMath.ToMinInt((i - 1) / 4)

                local blockX = leftUpX + locXOffset
                local blockY = leftUpY + locYOffset

                if blockX < 1 or blockY < 1 or blockX > self.MapControl.MaxWidth or blockY > self.MapControl.MaxHeight then
                    isOutBoard = true
                    break
                end
            end
        end
    end

    if isOutBoard then
        return true
    end

    return false
end

--- 检查预放置货物的位置是否有效（未越界，且未被其他货物占用），以指导货物的放置
function XBagOrganizeActivityGameControl:CheckPreGoodsPositionIsValid()
    local isCanPlace = true

    for i, v in ipairs(self._PrePlaceItemEntity:GetBlocks()) do
        if XTool.IsNumberValid(v) then

            if not self:CheckPreGoodsBlockIsValidByIndex(i, v) then
                isCanPlace = false
                break
            end
        end
    end

    return isCanPlace
end

--- 根据货物格子的局部索引，判断对应的网格位置是否可用（格子启用且未被占用）
function XBagOrganizeActivityGameControl:CheckPreGoodsBlockIsValidByIndex(index)
    if self._PrePlaceItemEntity then
        local xOffset = self._PrePlaceItemEntity:GetLeftUpX()
        local yOffset = self._PrePlaceItemEntity:GetLeftUpY() - 1
        local locXOffset = (index - 1) % 4
        local locYOffset = XMath.ToMinInt((index - 1) / 4)
        local fixedIndex = xOffset + locXOffset + (yOffset + locYOffset) * self.MapControl.MaxWidth
        
        -- 格子位置在背包有效区域内是前提
        if self.MapControl:GetBlockIsEnabledByIndex(fixedIndex) then
            return not self.MapControl:CheckBlockIsUseByIndex(fixedIndex, XMVCA.XBagOrganizeActivity.EnumConst.EntityType.Goods)
        end
    end
    return false
end

function XBagOrganizeActivityGameControl:PlaceGoods()
    if self._PrePlaceItemEntity then
        -- 确认占用格子是否可用且未被占用
        if self:CheckPreGoodsPositionIsValid() then
            -- 向对应的地块添加占据标签
            self.MapControl:AddPlacedGoodsTagInBlock(self._PrePlaceItemEntity)
            -- 标记该货物已使用
            self.GoodsControl:SetGoodsIsUsed(self._PrePlaceItemEntity.ComposeId, true)
            self._PrePlaceItemEntity:SetIsValid(true)
            -- 加入到列表中
            self.GoodsControl:SetGoodsToPlacedDict(self._PrePlaceItemEntity.Uid, self._PrePlaceItemEntity)
            self._PrePlaceItemEntity = nil
            return true
        end
    end

    return false
end

function XBagOrganizeActivityGameControl:CancelPlaceGoods()
    if self._PrePlaceItemEntity and self._PrePlaceItemEntity:GetType() == XMVCA.XBagOrganizeActivity.EnumConst.EntityType.Goods then
        local cfg = self._MainControl:GetGoodsCfgById(self._PrePlaceItemEntity.Id)
        -- 标记该货物未使用
        self.GoodsControl:SetGoodsIsUsed(self._PrePlaceItemEntity.ComposeId, nil)
        -- 从放置列表中移除
        self.GoodsControl:SetGoodsToPlacedDict(self._PrePlaceItemEntity.Uid, nil)
        
        --先清空Buff，因为回收后会直接清空各种引用
        -- 刷新同色加成
        self:DealWithGoodsSameColorCombo(cfg.BlockColor)
        
        self.GoodsControl:RecycleGoodsEntity(self._PrePlaceItemEntity)
        self._PrePlaceItemEntity = nil
    end
end

-- 处理场上指定颜色的货物的加成，在货物追加和减少时都需要扫描一遍
function XBagOrganizeActivityGameControl:DealWithGoodsSameColorCombo(color)
    if not self:IsSameColorComboEnabled() then
        return
    end
    
    local goodsEntityList = self.GoodsControl:GetPlacedGoodsEntities()
    if not XTool.IsTableEmpty(goodsEntityList) then
        self._ComboCalStack:Clear()
        ---@param v XBagOrganizeGoodsEntity
        for i, v in pairs(goodsEntityList) do
            ---@type XTableBagOrganizeGoods
            local cfg = self._MainControl:GetGoodsCfgById(v.Id)
            if cfg and cfg.BlockColor == color then
                self._ComboCalStack:Push(v)
                -- 清除原有的同色buff，如果有的话
                v:ClearBuffEffectByTypeOrConfigId(XMVCA.XBagOrganizeActivity.EnumConst.BuffType.SameColorCombo, color)
            end
        end
        
        -- 判断数量
        local count = self._ComboCalStack:Count()
        if count > 0 then
            -- 获取加成比例
            local multy = self._MainControl:GetClientConfigNum('GoodsValueUpMulty', count)
            if XTool.IsNumberValid(multy) then
                for i = 1, count do
                    ---@type XBagOrganizeGoodsEntity
                    local goods = self._ComboCalStack:Pop()
                    
                    -- 施加同色加成buff
                    ---@type XBagOrganizeBuff
                    local buff = self.BuffControl:GetMultyModifierBuff(XMVCA.XBagOrganizeActivity.EnumConst.BuffType.SameColorCombo, multy, 'Value')
                    buff.ConfigId = color
                    buff:AddBuff(goods)
                end
                
            end
        end
    end
end

--endregion <<<-------------------------------------------------------------------

--region ---------------------------- Score ----------------------------->>>

function XBagOrganizeActivityGameControl:GetValidTotalScore()
    return self._TotalScore.Value:GetFinalValInt()
end

function XBagOrganizeActivityGameControl:GetCurValidScore()
    return self._TotalScore.Value:GetOriginVal()
end

function XBagOrganizeActivityGameControl:GetPackingTotalScore()
    return self._TotalScore.Value:GetAddsBuffAddsByBuffType(XMVCA.XBagOrganizeActivity.EnumConst.BuffType.TotalScorePart)
end

--- 用于多背包多次打包的玩法机制，将当前背包的分数进行提交
--- 当前背包的分数将在OriginVal字段体现，提交的逻辑表现为将OriginVal值封装到buff中，通过buff机制进行修正，同时OriginVal归0
function XBagOrganizeActivityGameControl:SubmitPartScore()
    local curScore = self._TotalScore.Value:GetOriginVal()
    
    ---@type XBagOrganizeBuff
    local buff = self.BuffControl:GetAddsModifierBuff(XMVCA.XBagOrganizeActivity.EnumConst.BuffType.TotalScorePart, curScore, 'Value')

    --- 因仅是利用buff机制进行管理，没有对buff显示有特别要求，这里只需要确保buff之间唯一即可
    buff.ConfigId = 'SubmitPartScore'..tostring(self:GetNewUid())
    buff:AddBuff(self._TotalScore)

    self._TotalScore.Value:SetOriginVal(0)
end

--- 计算有效的总分
function XBagOrganizeActivityGameControl:RefreshValidTotalScore()
    -- 计算货物的价值
    local value = 0
    local goodsEntityList = self.GoodsControl:GetPlacedGoodsEntities()
    if not XTool.IsTableEmpty(goodsEntityList) then
        ---@param goods XBagOrganizeGoodsEntity
        for i, goods in pairs(goodsEntityList) do
            if goods:GetIsValid() then
                value = value + goods.Value:GetFinalValIntCeil()
            end
        end
    end
    
    -- 扣除背包的价值
    if self:IsMultyBagEnabled() and XTool.IsNumberValid(self.MapControl.CurMapId) then
        local mapCfg = self._Model:GetBagOrganizeBagCfgById(self.MapControl.CurMapId)
        
        if mapCfg then
            if self:IsTimelimitEnabled() then
                local mapDiscount = self.TimelimitControl:GetBagDiscountEventEffect(self.MapControl.CurMapId)
                value = value + math.ceil(mapCfg.Cost * mapDiscount)
            else
                value = value + mapCfg.Cost
            end
        end
    end

    -- 当前打包分值遇上限时玩法需要处理阶段增量
    if self:IsTimelimitEnabled() and XTool.IsNumberValid(self.TimelimitControl:GetCurPeriodScoreRateAdds()) then
        -- 分数大于0才计算倍率
        if value > 0 then
            value = value * (1 + self.TimelimitControl:GetCurPeriodScoreRateAdds())
        end
    end
    
    -- 计算最终收益
    self._TotalScore.Value:SetOriginVal(value)
    
    self:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_TOTALSCORE_UPDATE)
end

--endregion <<<-------------------------------------------------------------

--region -------------------- 埋点相关 -------------------->>>

function XBagOrganizeActivityGameControl:RecordBagDataAfterPacking()
    local data = {}
    
    -- 记录当次打包的背包Id
    data["bag_id"] = self.MapControl.CurMapId
    
    -- 记录当次打包的货物列表
    local goodsList = {}
    
    local goodsEntities = self.GoodsControl:GetPlacedGoodsEntities()

    if not XTool.IsTableEmpty(goodsEntities) then
        ---@param grid XBagOrganizeGoodsEntity
        for uid, grid in pairs(goodsEntities) do

            if grid then
                local cfg = self._MainControl:GetGoodsCfgById(grid.Id)
                
                local totalValue = grid.Value:GetFinalValIntCeil()
                local colorValue = grid.Value:GetMultyBuffAddsByBuffType(XMVCA.XBagOrganizeActivity.EnumConst.BuffType.SameColorCombo)
                local eventValue = grid.Value:GetMultyBuffAddsByBuffType(XMVCA.XBagOrganizeActivity.EnumConst.BuffType.RandomEvent)

                goodsList[tostring(grid.ComposeId)] = tostring(totalValue)..'_'..tostring(cfg.BlockColor)..'_'..tostring(colorValue)..'_'..tostring(eventValue)
            else
                XLog.Error('已打包的货物'..tostring(uid)..' 找不到它的实体数据')    
            end
        end
    end
    
    data["goods_list"] = goodsList
    
    -- 记录当次打包的货物的颜色buff
    data["buff_infos"] = self:_GetRecordBuffInfos()
    
    -- 插入列表中(埋点特殊处理, C#解析只识别字典）
    self._RecordGameContent[tostring(self._RecordGameContentCount)] = data
    self._RecordGameContentCount = self._RecordGameContentCount + 1
end

function XBagOrganizeActivityGameControl:RecordEventAfterEffectValid(eventId, resultId)
    if self._RecordEventEffects == nil then
        self._RecordEventEffects = {}
    end
    
    local record = tostring(eventId)..'_'..tostring(resultId)
    -- 插入列表中(埋点特殊处理, C#解析只识别字典）
    self._RecordEventEffects[tostring(self._RecordEventEffectsCount)] = record
    self._RecordEventEffectsCount = self._RecordEventEffectsCount + 1
end

function XBagOrganizeActivityGameControl:GetRecordContent()
    return self._RecordGameContent
end

function XBagOrganizeActivityGameControl:GetRecordEventEffects()
    -- 只有关卡开启了限时玩法才记录
    if not self:IsTimelimitEnabled() then
        return ''
    end

    return self._RecordEventEffects or ''
end

function XBagOrganizeActivityGameControl:_GetRecordBuffInfos()
    -- 只有当前关卡开启了同色规则才记录
    if not self:IsSameColorComboEnabled() then
        return ''
    end
    
    -- 统计同色
    local buffInfos = {}
    local goodsEntityList = self.GoodsControl:GetPlacedGoodsEntities()
    
    if not XTool.IsTableEmpty(goodsEntityList) then
        ---@param v XBagOrganizeGoodsEntity
        for i, v in pairs(goodsEntityList) do
            ---@type XTableBagOrganizeGoods
            local cfg = self._MainControl:GetGoodsCfgById(v.Id)
            if not XTool.IsNumberValid(buffInfos[cfg.BlockColor]) then
                buffInfos[cfg.BlockColor] = 1
            else
                buffInfos[cfg.BlockColor] = buffInfos[cfg.BlockColor] + 1    
            end
        end
    end
    -- 转换成目标格式的记录
    local content = {}
    if not XTool.IsTableEmpty(buffInfos) then
        local index = 1
        for i, v in pairs(buffInfos) do
            local multy = self._MainControl:GetClientConfigNum('GoodsValueUpMulty', v)
            if XTool.IsNumberValid(multy) then
                content[tostring(index)] = tostring(i)..'_'..tostring(v)..'_'..tostring(multy)
                index = index + 1
            end
        end
    end
    return content
end

function XBagOrganizeActivityGameControl:ResetRecordGameContentData()
    self._RecordGameContent = {}
    self._RecordGameContentCount = 0
    self._RecordEventEffects = nil
    self._RecordEventEffectsCount = 0
end

--endregion <<<------------------------------------------------

-- 重置当前关卡进度
function XBagOrganizeActivityGameControl:ResetGame(isInit)
    self.GoodsControl:ResetCurGameSchedule(isInit)
    -- 回收编辑中的物品
    self:CancelPlaceGoods()

    -- 只有新关卡初始化阶段才重置uid池。重置当前背包阶段不会回收已使用uid的对象，重置uid池会存在uid冲突的风险
    if isInit then
        -- 重置uid池
        self._UidSets = 0
		-- 重置得分与星级
    	self._TotalScore:RemoveAllBuffEffectByHand()
    end
    
    -- 重置当前预览得分
    self._TotalScore.Value:SetOriginVal(0)
end

--- 尝试打包
function XBagOrganizeActivityGameControl:TryPacking(cb)
    local canSubmit = true
    local isPacking = false
    local isRemoveFromGoodsList = self:IsTimelimitEnabled()

    -- 先将当前背包尝试打包
    if not self.GoodsControl:CheckAnyPlacedGoodsIsInvalid() and self._TotalScore.Value:GetOriginVal() > 0 then
        -- 如果放置上去的货物都是有效的，且分数>0, 那么可以打包
        self:SubmitPartScore()
        isPacking = true
    end

    -- 如果打包成功，则将已放置的货物移动到已打包列表
    if isPacking then
        -- 记录打包信息
        self:RecordBagDataAfterPacking()
        
        self.GoodsControl:SetAllPlacedGoodsToPacking(isRemoveFromGoodsList)
        self:RefreshValidTotalScore()
    end
    
    if self:IsMultyBagEnabled() then
        canSubmit = false
        
        -- 判断是否所有货物都打包完
        if XTool.GetTableCount(self.GoodsControl:GetGoodsIdsInList()) == self.GoodsControl:GetIsPackingCount() then
            canSubmit = true
        end
    end
    
    if self:IsTimelimitEnabled() then
        -- 限时玩法的结算由相关定时器控制
        canSubmit = false
    end

    -- 如果前面的规则检查都通过了，才进行最后一步分数有效性校验
    if canSubmit then
        local totalScore = self:GetPackingTotalScore()

        if XTool.IsNumberValid(totalScore) then
            XMVCA.XBagOrganizeActivity:RequestBagOrganizeSettle(self._CurStageId, XMVCA.XBagOrganizeActivity.EnumConst.SettleType.Normal, totalScore, cb)
            return true
        end
    end

    if cb then
        cb()
    end
end

-- 直接将已经打包提交的部分提交
function XBagOrganizeActivityGameControl:SubmitHadPackingResult(cb)
    local totalScore = self:GetPackingTotalScore()

    if totalScore < 0 then
        totalScore = 0
    end

    XMVCA.XBagOrganizeActivity:RequestBagOrganizeSettle(self._CurStageId, XMVCA.XBagOrganizeActivity.EnumConst.SettleType.Normal, totalScore, cb)
end

--region --------------------------- Conditions ---------------------------------->>>
function XBagOrganizeActivityGameControl:IsSameColorComboEnabled()
    return self._Model:GetIsSameColroComboEnabledByStageId(self:GetCurStageId())
end

function XBagOrganizeActivityGameControl:IsMultyBagEnabled()
    return self._Model:GetIsMultyBagEnabledByStageId(self:GetCurStageId())
end

function XBagOrganizeActivityGameControl:IsTimelimitEnabled()
    return self._Model:GetIsTimelimitEnabledByStageId(self:GetCurStageId())
end

-- 判断是否可以重置游戏，如果数据和初始一样就没必要重置，防止高频重置协议请求
function XBagOrganizeActivityGameControl:IsCanResetGame()
    local placeCount = XTool.GetTableCount(self.GoodsControl:GetPlacedGoodsEntities())
    -- 只有放置了物体才能重置
    if placeCount > 0 then
        if not XTool.IsTableEmpty(self._PrePlaceItemEntity) then
            -- 存在编辑状态的物体时，需要放置的物体数量不止1个，才可以重置[表现逻辑编辑中物体属于未放置，但内部逻辑编辑中的物体也存在放置表中用于计算（同时只能有一个物体处于编辑状态）]
            return placeCount > 1
        end
        return true
    end
    
    return false
end
--endregion <<<-------------------------------------------------------------------

return XBagOrganizeActivityGameControl