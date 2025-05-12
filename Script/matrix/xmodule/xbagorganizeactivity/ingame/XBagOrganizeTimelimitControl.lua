--- 玩法内分管限时玩法的控制器
---@class XBagOrganizeTimelimitControl: XControl
---@field private _MainControl XBagOrganizeActivityGameControl
---@field private _Model XBagOrganizeActivityModel
local XBagOrganizeTimelimitControl = XClass(XControl, 'XBagOrganizeTimelimitControl')

local __IsDebug = false

function XBagOrganizeTimelimitControl:OnInit()
    self._DebugOpenCache = XSaveTool.GetData('BagOrganizeTimelimitDebug')
end

function XBagOrganizeTimelimitControl:OnRelease()
    self:StopTimelimit()
end

function XBagOrganizeTimelimitControl:ResetInNewGame()
    self:StopTimelimit()

    if self._MainControl:IsTimelimitEnabled() then
        self._TimelimitGoodsUidMap = {} -- 记录对应uid货物的当前剩余时间
        self._TimelimitTotalTimeGoodsUidMap = {} -- 记录对应uid货物的总的生存时间
        self._TimelimitGoodsUidRemoveList = {}
        self:InitTimeData()
        self:StartTimelimit()
        
        self._ValidEventEffectList = {}
        
    end
end

--- 初始化当前关卡的时间参数
function XBagOrganizeTimelimitControl:InitTimeData()
    self._StageId = self._MainControl:GetCurStageId()
    
    ---@type XTableBagOrganizeStage
    self._StageCfg = self._Model:GetBagOrganizeStageCfgById(self._StageId)

    self._TotalDuration = 0
    self._CurRuleIndex = 1
    
    if self._StageCfg then
        if not XTool.IsTableEmpty(self._StageCfg.GoodsRuleIds) then
            for i, ruleId in pairs(self._StageCfg.GoodsRuleIds) do
                ---@type XTableBagOrganizeGoodsRule
                local ruleCfg = self._Model:GetBagOrganizeGoodsRuleCfgById(ruleId)

                if ruleCfg then
                    self._TotalDuration = self._TotalDuration + ruleCfg.Duration
                end
            end

            ---@type XTableBagOrganizeGoodsRule
            self._CurRuleCfg = self._Model:GetBagOrganizeGoodsRuleCfgById(self._StageCfg.GoodsRuleIds[self._CurRuleIndex])
        else
            XLog.Error('当前关卡'..tostring(self._StageId)..' 没有配置货物规则Id')
        end
    end
    
    self._PassedTime = 0 -- 实际经过的时间缓存（暂停时截取至暂停前的时间累计到该字段）
    self._PeriodBeginTime = 0 -- 当前阶段的开始时长（配置表Duration累计）
    self._LastCreateGoodsTime = 0 -- 上次生成新货物的时间

    self:_InitCurPeriodRandomGoodsList()
end


function XBagOrganizeTimelimitControl:StartTimelimit()
    self:StopTimelimit()

    self._StartTime = CS.UnityEngine.Time.time

    if not self._CurRuleCfg then
        XLog.Error('当前不存在有效的规则配置')
        return
    end

    -- 新开始时立即检查一次随机事件(不是从暂停状态恢复）
    if not self._IsResume then
        self:ClearEventForOuttime()
        if self:CheckHasEventRuleByPeriodIndex(self._CurRuleIndex) then
            self:CreateRandomEventByPeriodIndex(self._CurRuleIndex)
        end
    end
    
    -- 每次开始检查一次当前阶段是否限时
    self:CheckCurPeriodAnyTimelimitGoods()
    
    self._LastTickTime = CS.UnityEngine.Time.time
    self:TimelimitTick(nil, true)
    self._TimelimitRuleTimer = XScheduleManager.ScheduleForever(handler(self, self.TimelimitTick), XScheduleManager.SECOND * 0.05)
end

function XBagOrganizeTimelimitControl:PauseTimelimit()
    self._IsPause = true
    self._PassedTime = self._PassedTime + (CS.UnityEngine.Time.time - self._StartTime)
    self:StopTimelimit()
end

function XBagOrganizeTimelimitControl:ResumeTimelimit()
    self._IsPause = false
    self._IsResume = true
    self:StartTimelimit()
    self._IsResume = false
end

function XBagOrganizeTimelimitControl:StopTimelimit()
    if self._TimelimitRuleTimer then
        XScheduleManager.UnSchedule(self._TimelimitRuleTimer)
        self._TimelimitRuleTimer = nil
    end
end

function XBagOrganizeTimelimitControl:IsPause()
    return self._IsPause
end

---@param timeId number @定时器默认参数
function XBagOrganizeTimelimitControl:TimelimitTick(timeId, isBegin)
    local totalPassTime = self._PassedTime + (CS.UnityEngine.Time.time - self._StartTime)
    local leftTime = self._TotalDuration - totalPassTime

    local deltaTime = CS.UnityEngine.Time.time - self._LastTickTime
    
    if leftTime < 0 then
        leftTime = 0
    end
    
    -- 如果存在限时道具，需要消减时间
    if not XTool.IsTableEmpty(self._TimelimitGoodsUidMap) then
        for i, v in pairs(self._TimelimitGoodsUidMap) do
            self._TimelimitGoodsUidMap[i] = self._TimelimitGoodsUidMap[i] - deltaTime

            if self._TimelimitGoodsUidMap[i] <= 0 then
                table.insert(self._TimelimitGoodsUidRemoveList, i)
            end
        end
    end

    if not XTool.IsTableEmpty(self._TimelimitGoodsUidRemoveList) then
        for i = #self._TimelimitGoodsUidRemoveList, 1, -1 do
            local uid = self._TimelimitGoodsUidRemoveList[i]
            -- 从轮询列表中移除
            self._TimelimitGoodsUidMap[uid] = nil
            self._TimelimitTotalTimeGoodsUidMap[uid] = nil
            -- 移除该Id关联的列表数据和背包数据
            self._MainControl.GoodsControl:RemoveGoodsByComposeId(uid)
            
            table.remove(self._TimelimitGoodsUidRemoveList, i)
        end
        
        -- 如果执行了移除操作，且此时还有编辑中的物体（编辑中的物体未移除），则需要重新检查编辑中的物体所在区域的有效情况（可能原本重叠的部分不再重叠）
        if XTool.IsNumberValid(self._MainControl:GetPreItemId()) then
            self._MainControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_OPTION_SHOW)
        end
        
        -- 刷新货物列表
        self._MainControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_GOODS_LIST)
        
        -- 移除后需要重新刷新分数
        self._MainControl:RefreshValidTotalScore()
    end
    
    -- 发送事件让前端更新显示
    self._MainControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_TIMELIMIT_RULE_UPDATE, leftTime, isBegin)
    
    -- 倒计时完成后停止并提交结果
    if leftTime <= 0 then
        self:StopTimelimit()
        return
    end

    -- 判断是否切换阶段
    local curPeriodPassedTime = totalPassTime - self._PeriodBeginTime
    
    if curPeriodPassedTime >= self._CurRuleCfg.Duration then
        self:_SwitchPeriod()
    else
        local curGoodsCountInList = self._MainControl.GoodsControl:GetGoodsInListCount()
        
        local totalGoodsValueNoPacking = self._MainControl.GoodsControl:GetGoodsTotalValueInList()
        local minCostInBags = math.abs(self._MainControl.MapControl:GetMinCostInBagList())
        
        -- 未切换阶段, 或者物品栏已经空了, 或者当前货物总价值小于等于最便宜的背包价格
        if curPeriodPassedTime >= self._LastCreateGoodsTime + self._CurRuleCfg.RandInterval or curGoodsCountInList <= 0 or totalGoodsValueNoPacking <= minCostInBags then

            ---@type XTableBagOrganizeGoodsGroup
            local goodsGroupCfg
            local goodsList
            
            local ignoreCommonApply = false
            
            -- 配置规则是固定生成，或拥有固定生成的事件效果
            if self._CurRuleCfg.Type == XMVCA.XBagOrganizeActivity.EnumConst.GoodsRuleType.Constant then
                goodsGroupCfg = self._Model:GetBagOrganizeGoodsGroupCfgById(self._CurRuleCfg.ConstantGroupId)

                if goodsGroupCfg then
                    goodsList = goodsGroupCfg.GoodsList

                    if self:CheckDebugEnable() then
                        XLog.Debug('---[背包整理]限时玩法生成打印：配置 '..tostring(self._CurRuleCfg.Id)..' 固定生成：', goodsList)
                    end

                    self:_TryApplyGoodsFromCreate(goodsList, goodsGroupCfg, curGoodsCountInList, curPeriodPassedTime)
                end
            elseif self:CheckHasConstantGoodsCreateEventEffect() then
                local groupIds = self:GetGoodsCreateEventEffectConstantId()

                if not XTool.IsTableEmpty(groupIds) then
                    local count = XTool.GetTableCount(groupIds)

                    -- 每次最多生成配置长度
                    for i = 1, count do
                        local groupId = groupIds[self._EffectConstantGoodsGroupIdIndex]

                        if XTool.IsNumberValid(groupId) then
                            goodsGroupCfg = self._Model:GetBagOrganizeGoodsGroupCfgById(groupId)
                        end

                        if goodsGroupCfg then
                            goodsList = goodsGroupCfg.GoodsList

                            if self:CheckDebugEnable() then
                                XLog.Debug('---[背包整理]限时玩法生成打印：事件固定生成,(groupId：'..tostring(groupId)..')', goodsList)
                            end
                            
                            local goodsCountInList = self._MainControl.GoodsControl:GetGoodsInListCount()

                            if self:_TryApplyGoodsFromCreate(goodsList, goodsGroupCfg, goodsCountInList, curPeriodPassedTime) then
                                self._EffectConstantGoodsGroupIdIndex = self._EffectConstantGoodsGroupIdIndex + 1

                                if self._EffectConstantGoodsGroupIdIndex > count then
                                    self._EffectConstantGoodsGroupIdIndex = 1
                                end
                            else
                                break
                            end
                        end
                    end
                end
                
            elseif self._CurRuleCfg.Type == XMVCA.XBagOrganizeActivity.EnumConst.GoodsRuleType.Random then
                local groupId = self._RandomGoodsGroupIds[self._RandomGoodsGroupIndex]

                if XTool.IsNumberValid(groupId) then
                    goodsGroupCfg = self._Model:GetBagOrganizeGoodsGroupCfgById(groupId)

                    if goodsGroupCfg then
                        goodsList = goodsGroupCfg.GoodsList

                        if self:CheckDebugEnable() then
                            XLog.Debug('---[背包整理]限时玩法生成打印：配置 '..tostring(self._CurRuleCfg.Id)..' 随机生成：', goodsList)
                        end

                        if self:_TryApplyGoodsFromCreate(goodsList, goodsGroupCfg, curGoodsCountInList, curPeriodPassedTime) then
                            self._RandomGoodsGroupIndex = self._RandomGoodsGroupIndex + 1

                            if self._RandomGoodsGroupIndex > self._RandomGoodsGroupIdCount then
                                self._RandomGoodsGroupIndex = 1
                            end
                        end
                    end
                else
                    XLog.Error('随机货物组Id无效，规则Id:'..tostring(self._CurRuleCfg.Id)..' 索引: '..tostring(self._RandomGoodsGroupIndex)..' 组Id: '..tostring(groupId))
                end
            else
                XLog.Error('错误的规则类型，规则Id:'..tostring(self._CurRuleCfg.Id)..' 类型值：'..tostring(self._CurRuleCfg.Type))
                return
            end
        end
    end

    self._LastTickTime = CS.UnityEngine.Time.time
end

--- 执行时间段切换相关初始化
function XBagOrganizeTimelimitControl:_SwitchPeriod()
    -- 记录上个阶段的倍率
    local lastPeriodScoreAdds = self._CurRuleCfg.ScoreRateAdds

    -- 切换阶段前记录上个阶段是否是限时时间段
    local lastPeriodIsTimelimitGoods = self:CheckCurPeriodAnyTimelimitGoods()
    -- 切换阶段时，累计时间，切换配置引用
    self._PeriodBeginTime = self._PeriodBeginTime + self._CurRuleCfg.Duration
    self._CurRuleIndex = self._CurRuleIndex + 1

    if self._CurRuleIndex <= #self._StageCfg.GoodsRuleIds then
        self._CurRuleCfg = self._Model:GetBagOrganizeGoodsRuleCfgById(self._StageCfg.GoodsRuleIds[self._CurRuleIndex])
        self._LastCreateGoodsTime = 0
        if not self._CurRuleCfg then
            self:StopTimelimit()
            return
        end
    end

    if not self:CheckCurPeriodAnyTimelimitGoods() then
        -- 如果新阶段是不限时的，当前限时的部分在此期间暂停计时
        if not XTool.IsTableEmpty(self._TimelimitGoodsUidMap) then
            self._TimelimitGoodsUidMap = {}
            self._TimelimitTotalTimeGoodsUidMap = {}
        end
    elseif not lastPeriodIsTimelimitGoods then
        -- 否则如果上个阶段是不限时，且当前有不限时货物，按照配置设置成限时货物
        local goodsUids = self._MainControl.GoodsControl:GetGoodsIdsInList()

        if not XTool.IsTableEmpty(goodsUids) then
            if XTool.IsNumberValid(self._CurRuleCfg.GoodsDefaultLifeTime) then
                for i, uid in pairs(goodsUids) do
                    self._TimelimitGoodsUidMap[uid] = self._CurRuleCfg.GoodsDefaultLifeTime
                    self._TimelimitTotalTimeGoodsUidMap[uid] = self._CurRuleCfg.GoodsDefaultLifeTime
                end
            else
                XLog.Error('存在不限时货物遗留至限时时间段，且该时间段未配置默认限时时长，遗留货物将不会变成限时货物，请检查GoodsRule配置 Id：'..tostring(self._CurRuleCfg.Id))
            end
        end
    end

    -- 切换阶段时立即检查随机事件
    self:ClearEventForOuttime()
    if self:CheckHasEventRuleByPeriodIndex(self._CurRuleIndex) then
        self:CreateRandomEventByPeriodIndex(self._CurRuleIndex)
    end

    -- 切换阶段时，因为阶段倍率的变化，需要刷新一遍
    if lastPeriodScoreAdds ~= self._CurRuleCfg.ScoreRateAdds then
        self._MainControl:RefreshValidTotalScore()
    end
    
    -- 切换阶段后，若新阶段是生成组，则需要进行打乱一次
    self:_InitCurPeriodRandomGoodsList()
end

function XBagOrganizeTimelimitControl:_InitCurPeriodRandomGoodsList()
    if self._CurRuleCfg.Type == XMVCA.XBagOrganizeActivity.EnumConst.GoodsRuleType.Random then
        self._RandomGoodsGroupIds = XTool.CloneEx(self._CurRuleCfg.RandGroupIds, true)
        self._RandomGoodsGroupIds = XTool.RandomArray(self._RandomGoodsGroupIds, os.time(), true)
        self._RandomGoodsGroupIndex = 1
        self._RandomGoodsGroupIdCount = #self._RandomGoodsGroupIds
    end
end

function XBagOrganizeTimelimitControl:_TryApplyGoodsFromCreate(goodsList, goodsGroupCfg, curGoodsCountInList, curPeriodPassedTime)
    if goodsList and #goodsList <= ( self._MainControl.GoodsListCountMax - curGoodsCountInList) then
        self._LastCreateGoodsTime = curPeriodPassedTime

        self:_ApplyGoodsFromCreate(goodsList, goodsGroupCfg)

        if self:CheckDebugEnable() then
            XLog.Debug('---[背包整理]限时玩法生成打印：满足生成条件，生成结果生效！！！')
        end
        
        return true
    else
        if self:CheckDebugEnable() then
            XLog.Debug('---[背包整理]限时玩法生成打印：不满足生成条件，生成结果丢弃~~~')
        end
        
        return false
    end
end

function XBagOrganizeTimelimitControl:_ApplyGoodsFromCreate(goodsList, goodsGroupCfg)
    local lifeTimeSeconds = XTool.IsNumberValid(goodsGroupCfg.LifeTimeSeconds) and goodsGroupCfg.LifeTimeSeconds or self._CurRuleCfg.GoodsDefaultLifeTime
    -- 针对限时道具进行额外缓存
    if XTool.IsNumberValid(lifeTimeSeconds) then
        local uidList = self._MainControl.GoodsControl:AddGoodsIdsInList(goodsList, true)

        for i, v in pairs(uidList) do
            self._TimelimitGoodsUidMap[v] = lifeTimeSeconds
            self._TimelimitTotalTimeGoodsUidMap[v] = lifeTimeSeconds
        end
    else
        self._MainControl.GoodsControl:AddGoodsIdsInList(goodsList)
    end

    self._MainControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_GOODS_LIST)
end

--- 检查当前阶段对应组是否存在限时
function XBagOrganizeTimelimitControl:CheckCurPeriodAnyTimelimitGoods()
    if self._CurRuleCfg then
        if XTool.IsNumberValid(self._CurRuleCfg.GoodsDefaultLifeTime) then
            return true
        end
        
        if self._CurRuleCfg.Type == XMVCA.XBagOrganizeActivity.EnumConst.GoodsRuleType.Constant then
            ---@type XTableBagOrganizeGoodsGroup
            local cfg  = self._Model:GetBagOrganizeGoodsGroupCfgById(self._CurRuleCfg.ConstantGroupId)

            if cfg then
                return XTool.IsNumberValid(cfg.LifeTimeSeconds)
            end
        else
            if not XTool.IsTableEmpty(self._CurRuleCfg.RandGroupIds) then
                for i, groupId in pairs(self._CurRuleCfg.RandGroupIds) do
                    ---@type XTableBagOrganizeGoodsGroup
                    local cfg  = self._Model:GetBagOrganizeGoodsGroupCfgById(groupId)

                    if cfg and XTool.IsNumberValid(cfg.LifeTimeSeconds) then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

--region 随机事件

--- 判断当前关卡对应时间段是否有随机事件规则配置
function XBagOrganizeTimelimitControl:CheckHasEventRuleByPeriodIndex(index)
    local stageId = self._MainControl:GetCurStageId()
    local eventRuleId = stageId * 1000 + index
    
    local cfg = self._Model:GetBagOrganizeEventRuleCfgById(eventRuleId, true)
    
    return cfg and true or false
end

--- 随机生成当前事件
function XBagOrganizeTimelimitControl:CreateRandomEventByPeriodIndex(index)
    local stageId = self._MainControl:GetCurStageId()
    local eventRuleId = stageId * 1000 + index

    ---@type XTableBagOrganizeEventRule
    local cfg = self._Model:GetBagOrganizeEventRuleCfgById(eventRuleId, true)

    if cfg then
        local eventIndex = XTool.RandomSelectByWeightArray(cfg.EventWeights)
        local eventId = cfg.EventIds[eventIndex]

        if XTool.IsNumberValid(eventId) then
            self._CurEventCfg = self._Model:GetBagOrganizeEventCfgById(eventId)
            
            self._MainControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_NEW_RANDOMEVENT_APPEAR)
        else
            XLog.Error('随机事件Id无效，规则Id:'..tostring(eventRuleId)..' 索引: '..tostring(eventIndex)..' 事件Id: '..tostring(eventId))
        end
    end
end

--- 清除当前事件（未触发）
function XBagOrganizeTimelimitControl:ClearEventForOuttime()
    if self._CurEventCfg then
        self._CurEventCfg = nil
        self._MainControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_RANDOMEVENT_OUTTIME)
    end
end

--- 清除当前事件（已触发）
function XBagOrganizeTimelimitControl:ClearEventForUsed()
    if self._CurEventCfg then
        self._CurEventCfg = nil
    end
end

--- 添加生效的事件：前端玩家打开事件详情并选择选项触发指定事件后，该事件结果通过此接口缓存记录下来
---@param resultCfg XTableBagOrganizeEventResult
function XBagOrganizeTimelimitControl:AddValidEventEffect(resultCfg, fromCompose)
    local numberValue1 = (not string.IsNilOrEmpty(resultCfg.Params[1]) and string.IsFloatNumber(resultCfg.Params[1])) and tonumber(resultCfg.Params[1]) or 0
    local numberValue2 = (not string.IsNilOrEmpty(resultCfg.Params[2]) and string.IsFloatNumber(resultCfg.Params[2])) and tonumber(resultCfg.Params[2]) or 0

    if self:CheckDebugEnable() and not fromCompose then
        XLog.Debug('---[背包整理]限时玩法事件生效打印，生效事件Id：'..tostring(resultCfg.Id))
    end

    --- 目前事件较少，直接使用判断划分每个事件，后续若增多一倍则考虑单独一个类分管事件
    if resultCfg.Type == XMVCA.XBagOrganizeActivity.EnumConst.EventResultType.Compose then
        -- 表示事件的组合，需要拆开递归检查
        if not XTool.IsTableEmpty(resultCfg.Params) then
            for i, v in pairs(resultCfg.Params) do
                if string.IsNumeric(v) then
                    local resultId = tonumber(v)
                    local subResultCfg = self._Model:GetBagOrganizeEventResultCfgById(resultId)

                    if subResultCfg then
                        self:AddValidEventEffect(subResultCfg, true)
                    else
                        XLog.Error('组合事件Id:'..tostring(resultCfg.Id)..' 的第'..tostring(i)..'个参数，找不到对应Id的子事件配置，参数为：'..tostring(v))
                    end
                else
                    XLog.Error('组合事件Id:'..tostring(resultCfg.Id)..' 的第'..tostring(i)..'个参数，不是整型数值的形式，参数为：'..tostring(v))
                end
            end
        else
            XLog.Error('组合事件参数为空, Id:'..tostring(resultCfg.Id))
        end
    elseif resultCfg.Type == XMVCA.XBagOrganizeActivity.EnumConst.EventResultType.GoodsBuffWithColor then
        local effectMap = self._ValidEventEffectList[resultCfg.Type] or {}
        local value = effectMap[resultCfg.Params[1]]
        
        -- 指定颜色道具加成
        if XTool.IsNumberValid(value) then
            value = value + numberValue2
        else
            value = numberValue2
        end

        effectMap[resultCfg.Params[1]] = value
        self._ValidEventEffectList[resultCfg.Type] = effectMap
        
    elseif resultCfg.Type == XMVCA.XBagOrganizeActivity.EnumConst.EventResultType.GoodsBuffWithId then
        local effectMap = self._ValidEventEffectList[resultCfg.Type] or {}
        local value = effectMap[numberValue1]
        
        -- 指定Id道具加成
        if XTool.IsNumberValid(value) then
            value = value + numberValue2
        else
            value = numberValue2
        end

        effectMap[numberValue1] = value
        self._ValidEventEffectList[resultCfg.Type] = effectMap
        
    elseif resultCfg.Type == XMVCA.XBagOrganizeActivity.EnumConst.EventResultType.BagFreeWithId then
        local effectMap = self._ValidEventEffectList[resultCfg.Type] or {}
        effectMap[numberValue1] = numberValue2
        self._ValidEventEffectList[resultCfg.Type] = effectMap
        
    elseif resultCfg.Type == XMVCA.XBagOrganizeActivity.EnumConst.EventResultType.GoodsCreateByConstant then
        -- 后续道具刷新固定组

        if not XTool.IsTableEmpty(resultCfg.Params) then
            local groupIdList = {}

            for i, v in ipairs(resultCfg.Params) do
                local id = string.IsNumeric(v) and tonumber(v) or 0

                if XTool.IsNumberValid(id) then
                    table.insert(groupIdList, id)
                end
            end

            self._ValidEventEffectList[resultCfg.Type] = groupIdList
            
            -- 固定道具刷新效果生效时，重置组索引
            self._EffectConstantGoodsGroupIdIndex = 1
        end
    end
    
    self._MainControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_RANDOMEVENT_EFFECT_VALID)
end

--- 针对新放到背包中的道具，根据现有的事件效果，尝试添加buff
---@param goods XBagOrganizeGoodsEntity
function XBagOrganizeTimelimitControl:TryAddEventBuff(goods)
    if not self._MainControl:IsTimelimitEnabled() then
        return
    end
    
    -- 事件buff类型较少，直接简单查找
    local value = nil
    local effectMap = nil
    local goodsId = XMath.ToInt(math.fmod(goods.Id, 10000))
    
    -- 指定Id型
    effectMap = self._ValidEventEffectList[XMVCA.XBagOrganizeActivity.EnumConst.EventResultType.GoodsBuffWithId]
    value = effectMap and effectMap[goodsId] or 0
    
    if XTool.IsNumberValid(value) then
        ---@type XBagOrganizeBuff
        local buff = self._MainControl.BuffControl:GetMultyModifierBuff(XMVCA.XBagOrganizeActivity.EnumConst.BuffType.RandomEvent, value, 'Value')
        buff.ConfigId = 'GoodsBuffWithId'
        buff:AddBuff(goods)
    end
    
    -- 指定颜色型
    effectMap = self._ValidEventEffectList[XMVCA.XBagOrganizeActivity.EnumConst.EventResultType.GoodsBuffWithColor]
    
    if effectMap then
        ---@type XTableBagOrganizeGoods
        local goodsCfg = self._Model:GetBagOrganizeGoodsConfig()[goodsId]

        if goodsCfg then
            value = effectMap[goodsCfg.BlockColor]
        else
            value = 0
        end
        
        if XTool.IsNumberValid(value) then
            ---@type XBagOrganizeBuff
            local buff = self._MainControl.BuffControl:GetMultyModifierBuff(XMVCA.XBagOrganizeActivity.EnumConst.BuffType.RandomEvent, value, 'Value')
            buff.ConfigId = 'GoodsBuffWithColor'
            buff:AddBuff(goods)
        end
    end
end

--endregion

--region Get

--- 获取当前时间段的倍率增量
function XBagOrganizeTimelimitControl:GetCurPeriodScoreRateAdds()
    if self._CurRuleCfg then
        return self._CurRuleCfg.ScoreRateAdds or 0
    end
    
    return 0
end

--- 获取当前时间段的描述
function XBagOrganizeTimelimitControl:GetCurPeriodDesc()
    if self._CurRuleCfg then
        return self._CurRuleCfg.PeriodDesc
    end

    return ''
end

--- 获取当前时间段标题
function XBagOrganizeTimelimitControl:GetCurPeriodTitle()
    if self._CurRuleCfg then
        return self._CurRuleCfg.PeriodTitle
    end
    
    return ''
end

--- 获取当前出现的随机事件配置
function XBagOrganizeTimelimitControl:GetCurPeriodRandomEventCfg()
    return self._CurEventCfg
end

--- 判断当前是否有待触发的事件
function XBagOrganizeTimelimitControl:CheckHasRandomEvent()
    return self._CurEventCfg and true or false
end

--- 判断是否有背包折扣的事件效果
--- 传参判断指定背包是否免费，无参表示是否存在相关效果
function XBagOrganizeTimelimitControl:CheckHasBagDiscountEventEffect(bagId)
    if not self._MainControl:IsTimelimitEnabled() then
        return false
    end

    local effectMap = self._ValidEventEffectList[XMVCA.XBagOrganizeActivity.EnumConst.EventResultType.BagFreeWithId]

    if not XTool.IsTableEmpty(effectMap) then
        if XTool.IsNumberValid(bagId) then
            return effectMap[bagId] and true or false
        else
            return true
        end
        
    end

    return false
end

--- 获取指定背包的折扣
function XBagOrganizeTimelimitControl:GetBagDiscountEventEffect(bagId)
    if not self._MainControl:IsTimelimitEnabled() then
        return 1
    end

    local effectMap = self._ValidEventEffectList[XMVCA.XBagOrganizeActivity.EnumConst.EventResultType.BagFreeWithId]

    if not XTool.IsTableEmpty(effectMap) then
        if XTool.IsNumberValid(bagId) then
            return effectMap[bagId] or 1
        end

    end

    return 1
end

--- 指定道具配置，根据现有的事件效果，获取它受到事件加成的总和
---@param goodsCfg XTableBagOrganizeGoods
function XBagOrganizeTimelimitControl:GetEventBuffTotalMulty(goodsCfg)
    if not self._MainControl:IsTimelimitEnabled() or self._ValidEventEffectList == nil then
        return 0
    end
    local totalValue = 0
    -- 事件buff类型较少，直接简单查找
    local value = nil
    local effectMap = nil

    -- 指定Id型
    effectMap = self._ValidEventEffectList[XMVCA.XBagOrganizeActivity.EnumConst.EventResultType.GoodsBuffWithId]
    value = effectMap and effectMap[goodsCfg.Id] or 0

    if XTool.IsNumberValid(value) then
        totalValue = totalValue + value
    end

    -- 指定颜色型
    effectMap = self._ValidEventEffectList[XMVCA.XBagOrganizeActivity.EnumConst.EventResultType.GoodsBuffWithColor]

    if effectMap then
        if goodsCfg then
            value = effectMap[goodsCfg.BlockColor]
        else
            value = 0
        end

        if XTool.IsNumberValid(value) then
            totalValue = totalValue + value
        end
    end
    
    return totalValue
end

--- 判断是否有道具刷新固定组的事件效果
function XBagOrganizeTimelimitControl:CheckHasConstantGoodsCreateEventEffect()
    if not self._MainControl:IsTimelimitEnabled() then
        return false
    end
    local goodsGroupIds = self._ValidEventEffectList and self._ValidEventEffectList[XMVCA.XBagOrganizeActivity.EnumConst.EventResultType.GoodsCreateByConstant] or nil
    return not XTool.IsTableEmpty(goodsGroupIds) and true or false
end

--- 获取道具刷新固定组的事件效果
function XBagOrganizeTimelimitControl:GetGoodsCreateEventEffectConstantId()
    if not self._MainControl:IsTimelimitEnabled() then
        return false
    end

    local goodsGroupId = self._ValidEventEffectList[XMVCA.XBagOrganizeActivity.EnumConst.EventResultType.GoodsCreateByConstant]
    return XTool.IsNumberValid(goodsGroupId) and goodsGroupId or false
end

--- 获取道具的生存时间
function XBagOrganizeTimelimitControl:GetGoodsTotalLifeTimeByUid(uid)
    return self._TimelimitTotalTimeGoodsUidMap and self._TimelimitTotalTimeGoodsUidMap[uid] or 0
end

--- 获取道具的剩余时间
function XBagOrganizeTimelimitControl:GetGoodsLeftTimeByUid(uid)
    return self._TimelimitGoodsUidMap and self._TimelimitGoodsUidMap[uid] or 0
end

--endregion

--region Set

--- 移除限时字典中指定的货物Id（当限时货物完成打包后移除）
function XBagOrganizeTimelimitControl:RemoveFromTimelimitMapById(id)
    self._TimelimitGoodsUidMap[id] = nil
    self._TimelimitTotalTimeGoodsUidMap[id] = nil
end

--endregion

function XBagOrganizeTimelimitControl:CheckDebugEnable()
    -- debug环境下，代码手动开启，或者通过控制台开启
    return XMain.IsEditorDebug and (__IsDebug or self._DebugOpenCache)
end

return XBagOrganizeTimelimitControl