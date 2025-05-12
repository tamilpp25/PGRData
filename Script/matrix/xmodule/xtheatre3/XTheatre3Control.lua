---@class XTheatre3ReqCDData
---@field RecordTime number
---@field RecordData number[]

---@class XTheatre3Control : XControl
---@field _Model XTheatre3Model
local XTheatre3Control = XClass(XControl, "XTheatre3Control")

local RequestProto = {
    Theatre3ActivationStrengthenTreeRequest = "Theatre3ActivationStrengthenTreeRequest", -- 激活天赋树
    Theatre3GetBattlePassRewardRequest = "Theatre3GetBattlePassRewardRequest",      -- 领取奖励
    Theatre3GetAchievementRewardRequest = "Theatre3GetAchievementRewardRequest",    -- 领取成就奖励
    --Adventure
    Theatre3SettleAdventureRequest = "Theatre3SettleAdventureRequest",              -- 放弃冒险
    Theatre3SelectDifficultyRequest = "Theatre3SelectDifficultyRequest",            -- 进入冒险选择难度
    Theatre3EndRecruitRequest = "Theatre3EndRecruitRequest",                        -- 结束开局编队
    Theatre3SelectNodeRequest = "Theatre3SelectNodeRequest",                        -- 选择节点
    Theatre3SelectItemRewardRequest = "Theatre3SelectItemRewardRequest",            -- 选择开道具箱奖励，3选1
    Theatre3NodeShopBuyItemRequest = "Theatre3NodeShopBuyItemRequest",              -- 局内商店购买
    Theatre3EndNodeRequest = "Theatre3EndNodeRequest",                              -- 结束节点，商店节点
    Theatre3EventNodeNextStepRequest = "Theatre3EventNodeNextStepRequest",          -- 事件，下一步，选择选项
    Theatre3RecvFightRewardRequest = "Theatre3RecvFightRewardRequest",              -- 战斗结束—打开战斗奖励选择界面—领取战斗奖励
    Theatre3EndRecvFightRewardRequest = "Theatre3EndRecvFightRewardRequest",        -- 战斗结束—打开战斗奖励选择界面—领取战斗奖励-结束领取
    Theatre3SelectEquipRequest = "Theatre3SelectEquipRequest",                      -- 选择装备
    Theatre3ChangeEquipPosRequest = "Theatre3ChangeEquipPosRequest",                -- 装备换位置
    Theatre3RecastEquipRequest = "Theatre3RecastEquipRequest",                      -- 重铸装备
    Theatre3SetTeamRequest = "Theatre3SetTeamRequest",                              -- 设置队伍
    Theatre3EndWorkShopRequest = "Theatre3EndWorkShopRequest",                      -- 事件—工坊—结束工坊—事件下一步
    Theatre3EndEquipBoxRequest = "Theatre3EndEquipBoxRequest",                      -- 结束装备箱事件
    Theatre3LookEquipAttributeRequest = "Theatre3LookEquipAttributeRequest",        -- 内循环查看装备数据
    Theatre3DestinySelectRequest = "Theatre3DestinySelectRequest",                  -- 选择天选角色
    Theatre3SwitchParallelChapterRequest = "Theatre3SwitchParallelChapterRequest",  -- 切换线路
    Theatre3QubitEquipRequest = "Theatre3QubitEquipRequest",                        -- 选择量子装备
    Theatre3RefreshEquipBoxRequest = "Theatre3RefreshEquipBoxRequest",              -- 刷新装备箱奖励
    Theatre3SelectInitialItemRequest = "Theatre3SelectInitialItemRequest",          -- 选择初始道具
}

function XTheatre3Control:OnInit()
    --初始化内部变量
    ---@type XTheatre3ReqCDData[]
    self._ReqCdDir = {}
    self:_InitCfgCacheValue()
    self:_InitCacheData()
    ---@type XTheatre3BgmControl
    --self._BgmControl = self:AddSubControl(require("XModule/XTheatre3/XSubControl/XTheatre3BgmControl"))
    --self:SetDelayReleaseTime(2)
end

function XTheatre3Control:OnRelease()
    -- 这里执行Control的释放
    self._ReqCdDir = {}
    self._IsWaitSelectEquipReq = false
    self:_ReleaseCfgCacheValue()
    self:_ReleaseCacheData()
end

function XTheatre3Control:AddAgencyEvent()
    self:GetAgency():AddEventListener(XEventId.EVENT_THEATRE3_QUANTUM_VALUE_UPDATE, self.SetCacheQuantumValueData, self)
end

function XTheatre3Control:RemoveAgencyEvent()
    self:GetAgency():RemoveEventListener(XEventId.EVENT_THEATRE3_QUANTUM_VALUE_UPDATE, self.SetCacheQuantumValueData, self)
end

--region BP奖励
function XTheatre3Control:GetBattlePassRewardId(id)
    local config = self._Model:GetBattlePassConfig(id)
    return config.RewardId or 0
end

function XTheatre3Control:GetBattlePassDisplay(id)
    local config = self._Model:GetBattlePassConfig(id)
    return config.Display or 0
end

-- 获取当前BP的等级
function XTheatre3Control:GetCurBattlePassLevel()
    local totalExp = self._Model:GetBattlePassTotalExp()
    return self:GetBattlePassLevelByExp(totalExp)
end

function XTheatre3Control:GetBattlePassLevelByExp(exp)
    return self._Model:GetBattlePassLevelByExp(exp)
end

-- 获取下一个稀有奖励的等级
function XTheatre3Control:GetNextDisplayLevel(level)
    local maxBattlePassLevel = self._Model:GetMaxBattlePassLevel()
    if maxBattlePassLevel <= level then
        return maxBattlePassLevel
    end
    --local configs = self._Model:GetBattlePassConfigs()
    for i = level + 1, maxBattlePassLevel do
        if self:CheckBattlePassDisplay(i) then
            return i
        end
    end
    return maxBattlePassLevel
end

-- 获取当前等级的经验
function XTheatre3Control:GetCurLevelExp(level)
    local curTotalLevelExp = 0
    for i = 1, level do
        local needExp = self._Model:GetBattlePassNeedExp(i)
        curTotalLevelExp = curTotalLevelExp + needExp
    end
    local totalExp = self._Model:GetBattlePassTotalExp()
    local exp = totalExp - curTotalLevelExp
    return math.max(0, exp)
end

-- 获取下一等级的经验
function XTheatre3Control:GetNextLevelExp(level)
    local maxBattlePassLevel = self._Model:GetMaxBattlePassLevel()
    if maxBattlePassLevel < level then
        return 0
    end
    return self._Model:GetBattlePassNeedExp(level)
end

function XTheatre3Control:GetBattlePassIdList()
    return self._Model:GetBattlePassIdList()
end

-- 检查当前是否是最大等级
function XTheatre3Control:CheckBattlePassMaxLevel(level)
    local maxLevel = self._Model:GetMaxBattlePassLevel()
    if level >= maxLevel then
        return true
    end
    return false
end

-- 检查BP奖励是否已经领取
function XTheatre3Control:CheckRewardReceived(battlePassId)
    return self._Model.ActivityData:CheckGetRewardId(battlePassId)
end

-- 奖励是否可以领取
function XTheatre3Control:CheckBattlePassAbleToReceive(battlePassId, curLevel)
    local isReceive = self:CheckRewardReceived(battlePassId)
    return curLevel >= battlePassId and not isReceive
end

function XTheatre3Control:GetCanReceiveBattlePassIds(curLevel)
    local configs = self._Model:GetBattlePassConfigs()
    local list = {}
    for id, _ in pairs(configs) do
        if self:CheckBattlePassAbleToReceive(id, curLevel) then
            table.insert(list, id)
        end
    end
    table.sort(list, function(a, b)
        return a < b
    end)
    return list
end

-- 检查是否是稀有道具
function XTheatre3Control:CheckBattlePassDisplay(id)
    local display = self:GetBattlePassDisplay(id)
    return display == XEnumConst.THEATRE3.RewardDisplayType.Rare
end

-- 是否有可以领取的奖励
function XTheatre3Control:CheckIsHaveReward(curLevel)
    local configs = self._Model:GetBattlePassConfigs()
    for id, _ in pairs(configs) do
        if not self:CheckRewardReceived(id) and id <= curLevel then
            return true
        end
    end
    return false
end
--endregion

--region 任务相关

function XTheatre3Control:GetTaskConfigIds()
    return self._Model:GetTaskConfigIdList()
end

function XTheatre3Control:GetTaskDatas(taskConfigId, isSort)
    if isSort == nil then
        isSort = true
    end
    local taskIdList = self._Model:GetTaskIdsById(taskConfigId)
    local result = {}
    for _, id in ipairs(taskIdList) do
        table.insert(result, XDataCenter.TaskManager.GetTaskDataById(id))
    end
    if isSort then
        XDataCenter.TaskManager.SortTaskList(result)
    end
    return result
end

-- 获得主界面显示的任务Id
function XTheatre3Control:GetMainShowTaskId()
    local showIdList = self._Model:GetTaskMainShowIdList()
    local mainShowTaskId = 0
    for _, id in pairs(showIdList) do
        local taskIds = self._Model:GetTaskIdsById(id)
        for _, taskId in pairs(taskIds) do
            if not XDataCenter.TaskManager.IsTaskFinished(taskId) then
                return taskId
            end
            mainShowTaskId = taskId
        end
    end
    return mainShowTaskId
end

function XTheatre3Control:GetTaskNameById(id)
    local config = self._Model:GetTaskConfig(id)
    return config.Name or ""
end

function XTheatre3Control:CheckTaskCanRewardByTaskId(taskConfigId)
    local taskIdList = self._Model:GetTaskIdsById(taskConfigId)
    for _, taskId in ipairs(taskIdList) do
        if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
            return true
        end
    end
    return false
end

--endregion

--region 事件物品类型相关
function XTheatre3Control:GetEventStepItemName(itemId, itemType)
    if itemType == XEnumConst.THEATRE3.EventStepItemType.OutSideItem then
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId)
        return goodsShowParams.RewardType == XArrangeConfigs.Types.Character and goodsShowParams.TradeName or goodsShowParams.Name
    elseif itemType == XEnumConst.THEATRE3.EventStepItemType.InnerItem then
        return self:GetItemConfigById(itemId).Name
    elseif itemType == XEnumConst.THEATRE3.EventStepItemType.ItemBox then
        return self._Model:GetItemBoxById(itemId).Name
    elseif itemType == XEnumConst.THEATRE3.EventStepItemType.EquipBox then
        return self._Model:GetEquipBoxById(itemId).Name
    end
    return ""
end

function XTheatre3Control:GetEventStepItemIcon(itemId, itemType)
    if itemType == XEnumConst.THEATRE3.EventStepItemType.OutSideItem then
        local goodsShowParams =  XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId)
        return goodsShowParams.Icon
    elseif itemType == XEnumConst.THEATRE3.EventStepItemType.InnerItem then
        return self:GetItemConfigById(itemId).Icon
    elseif itemType == XEnumConst.THEATRE3.EventStepItemType.ItemBox then
        return self._Model:GetItemBoxById(itemId).Icon
    elseif itemType == XEnumConst.THEATRE3.EventStepItemType.EquipBox then
        return self._Model:GetEquipBoxById(itemId).Icon
    end
    return nil
end

function XTheatre3Control:GetEventStepItemWorldDesc(itemId, itemType)
    if itemType == XEnumConst.THEATRE3.EventStepItemType.OutSideItem then
        return XGoodsCommonManager.GetGoodsWorldDesc(itemId)
    elseif itemType == XEnumConst.THEATRE3.EventStepItemType.InnerItem then
        return self:GetItemConfigById(itemId).WorldDesc
    end
    return ""
end

function XTheatre3Control:GetEventStepItemDesc(itemId, itemType)
    if itemType == XEnumConst.THEATRE3.EventStepItemType.OutSideItem then
        return XGoodsCommonManager.GetGoodsDescription(itemId)
    elseif itemType == XEnumConst.THEATRE3.EventStepItemType.InnerItem then
        return self:GetItemConfigById(itemId).Description
    elseif itemType == XEnumConst.THEATRE3.EventStepItemType.ItemBox then
        return self._Model:GetItemBoxById(itemId).Desc
    elseif itemType == XEnumConst.THEATRE3.EventStepItemType.EquipBox then
        return self._Model:GetEquipBoxById(itemId).Desc
    end
    return ""
end

function XTheatre3Control:GetEventStepItemQualityIcon(itemId, itemType)
    if itemType == XEnumConst.THEATRE3.EventStepItemType.OutSideItem then
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId)
        return goodsShowParams.QualityIcon
    else
        local quality = self:GetEventStepItemQuality(itemId, itemType)
        return quality and XArrangeConfigs.GeQualityPath(quality)
    end
end

function XTheatre3Control:GetEventStepItemQuality(itemId, itemType)
    if itemType == XEnumConst.THEATRE3.EventStepItemType.InnerItem then
        return self:GetItemConfigById(itemId).Quality
    elseif itemType == XEnumConst.THEATRE3.EventStepItemType.EquipBox then
        return self._Model:GetEquipBoxById(itemId).Quality
    end
    return nil
end
--endregion

--region 装备相关
---@return XTableTheatre3Equip
function XTheatre3Control:GetEquipById(id)
    return self._Model:GetEquipById(id)
end

function XTheatre3Control:GetEquipSuitIdById(id)
    local cfg = self:GetEquipById(id)
    return cfg and cfg.SuitId
end

---@return XTableTheatre3EquipSuit
function XTheatre3Control:GetSuitById(id)
    return self._Model:GetSuitById(id)
end

---获得该装备所属套装下的所有装备
---@return XTableTheatre3Equip[]
function XTheatre3Control:GetSameSuitEquip(equipId)
    local config = self:GetEquipById(equipId)
    return self:GetAllSuitEquip(config.SuitId)
end

---@return XTableTheatre3Equip[]
function XTheatre3Control:GetAllSuitEquip(suitId)
    return self._Model:GetSameSuitEquip(suitId)
end

function XTheatre3Control:GetAllSuitWearEquipId(suitId)
    local equipIds = {}
    local equips = self:GetAllSuitEquip(suitId)
    for _, v in pairs(equips) do
        if self:IsWearEquip(v.Id) then
            table.insert(equipIds, v.Id)
        end
    end
    return equipIds
end

---是否穿戴装备
function XTheatre3Control:IsWearEquip(equipId)
    return self:GetEquipBelong(equipId) ~= -1
end

---是否穿戴套装
function XTheatre3Control:IsWearSuit(suitId)
    local equips = self:GetAllSuitEquip(suitId)
    for _, equip in pairs(equips) do
        if self:IsWearEquip(equip.Id) then
            return true
        end
    end
    return false
end

---该套装是否全部收集完毕
function XTheatre3Control:IsSuitComplete(suitId)
    local equips = self:GetAllSuitEquip(suitId)
    for _, equip in pairs(equips) do
        if not self:IsWearEquip(equip.Id) then
            return false
        end
    end
    return true
end

---穿戴该装备后套装是否能激活
function XTheatre3Control:CanSuitComplete(equipId)
    local config = self:GetEquipById(equipId)
    local equips = self:GetAllSuitEquip(config.SuitId)
    for _, equip in pairs(equips) do
        if equip.Id ~= equipId and not self:IsWearEquip(equip.Id) then
            return false
        end
    end
    return true
end

---槽位已用装备容量
function XTheatre3Control:GetSlotCapcity(slotId)
    local list = self:GetSlotSuits(slotId)
    return #list
end

---获得槽位上装备的套装
function XTheatre3Control:GetSlotSuits(slotId)
    return self._Model.ActivityData:GetSuitListBySlot(slotId)
end

function XTheatre3Control:GetSlotMaxCapcity(slotId)
    return self._Model.ActivityData:GetMaxCapacity(slotId)
end

function XTheatre3Control:IsSlotFull(slotId)
    return self:GetSlotCapcity(slotId) >= self:GetSlotMaxCapcity(slotId)
end

function XTheatre3Control:GetToggleValue(key)
    local value = XSaveTool.GetData(key) or 0
    return value == 1
end

function XTheatre3Control:SaveToggleValue(key, value)
    XSaveTool.SaveData(key, value and 1 or 0)
end

---检查某槽位是否能穿戴此装备
function XTheatre3Control:CheckCharacterEquip(slotId, equipId)
    local belongId = -1
    local equips = self:GetSameSuitEquip(equipId) -- 同个套装里的装备可以放在同个槽位上
    for _, v in pairs(equips) do
        belongId = self:GetEquipBelong(v.Id)
        if belongId ~= -1 then
            break
        end
    end
    local hasSite = self:GetSlotCapcity(slotId) < self:GetSlotMaxCapcity(slotId)
    return belongId == slotId or (belongId == -1 and hasSite)
end

---返回-1表示该装备还没被穿戴
function XTheatre3Control:GetEquipBelong(equipId)
    return self._Model.ActivityData:GetEquipBelongPosId(equipId)
end

function XTheatre3Control:GetSuitBelong(suitId)
    local equips = self:GetAllSuitEquip(suitId)
    for _, equip in pairs(equips) do
        local slotId = self:GetEquipBelong(equip.Id)
        if slotId ~= -1 then
            return slotId
        end
    end
    return -1
end

---获取槽位上绑定的角色
function XTheatre3Control:GetSlotCharacter(slotId)
    -- 3个位置,位置上没角色则为0,有角色则为角色Id
    local slotInfo = self:GetSlotInfo(slotId)
    if slotInfo then
        return slotInfo:GetCharacterId()
    end
    return 0
end

--- 返回true表示今天不需要显示
function XTheatre3Control:GetTodayDontShowValue(key)
    local recordDay = XSaveTool.GetData(key) or -1
    local curDay = XTime.GetSeverNextRefreshTime()
    return recordDay >= curDay
end

function XTheatre3Control:SaveTodayDontShowValue(key, isClear)
    local day = isClear and 0 or XTime.GetSeverNextRefreshTime()
    XSaveTool.SaveData(key, day)
end

---显示装备Tip
---@param equipId number 装备Id
---@param btnTxt string 按钮文本，可为nil
---@param btnCallBack function 按钮回调，为nil则不显示按钮
---@param tipWorldPos UnityEngine.Vector3 tip位置，可为nil
---@param closeCallBack function 关闭回调，可为nil
function XTheatre3Control:OpenEquipmentTip(equipId, btnTxt, btnCallBack, tipWorldPos, closeCallBack)
    local param = {
        equipId = equipId,
        btnTxt = btnTxt,
        btnCallBack = btnCallBack,
        tipWorldPos = tipWorldPos,
        closeCallBack = closeCallBack,
    }
    local suitId = self:GetEquipSuitIdById(equipId)
    XLuaUiManager.Open("UiTheatre3BubbleEquipment", param, nil, self:CheckAdventureSuitIsQuantum(suitId))
end

---显示装备Tip（可以设置居目标对象的左边还是右边）
function XTheatre3Control:OpenEquipmentTipByAlign(equipId, btnTxt, btnCallBack, closeCallBack, dimObj, align, isAdventure)
    local param = {
        equipId = equipId,
        btnTxt = btnTxt,
        btnCallBack = btnCallBack,
        closeCallBack = closeCallBack,
        DimObj = dimObj,
        Align = align or XEnumConst.THEATRE3.TipAlign.Right,
    }
    local suitId = self:GetEquipSuitIdById(equipId)
    if isAdventure then
        local cfg = self:GetEquipById(equipId)
        self:RequestLookEquipAttribute(equipId, cfg.SuitId, function()
            XLuaUiManager.Open("UiTheatre3BubbleEquipment", param, true, self:CheckAdventureSuitIsQuantum(suitId))
        end)
    else
        XLuaUiManager.Open("UiTheatre3BubbleEquipment", param, nil, self:CheckAdventureSuitIsQuantum(suitId))
    end
end

---显示套装Tip
---@param suitId number 套装Id
---@param btnTxt string 按钮文本，可为nil
---@param btnCallBack function 按钮回调，为nil则不显示按钮
---@param closeCallBack function 关闭回调，可为nil
---@param dimObj UnityEngine.Transform
function XTheatre3Control:OpenSuitTip(suitId, btnTxt, btnCallBack, closeCallBack, dimObj, align)
    local param = {
        suitId = suitId,
        btnTxt = btnTxt,
        btnCallBack = btnCallBack,
        closeCallBack = closeCallBack,
        DimObj = dimObj,
        Align = align or XEnumConst.THEATRE3.TipAlign.Right,
    }

    self:RequestLookEquipAttribute(nil, suitId, function()
        XLuaUiManager.Open("UiTheatre3SuitTip", param)
    end)
end

---打开展示套装界面
function XTheatre3Control:OpenShowEquipPanel(suitId)
    if self:IsAdventureALine() then
        XLuaUiManager.Open("UiTheatre3SetBag", self:_CreateSetBagParam(suitId, true))
    else
        XLuaUiManager.Open("UiTheatre3Quantization", self:_CreateSetBagParam(suitId, true))
    end
end

---@return XTheatre3SetBagParam
function XTheatre3Control:_CreateSetBagParam(autoSelectSuitId, isShowEquip, isExchangeSuit, isRebuildEquip, isQuantumEquip)
    ---@type XTheatre3SetBagParam
    local param = {}
    param.isExchangeSuit = isExchangeSuit
    param.isQuantumEquip = isQuantumEquip
    param.isRebuildEquip = isRebuildEquip
    param.isShowEquip = isShowEquip
    param.autoSelectSuitId = autoSelectSuitId
    return param
end
--endregion

--region 结算相关

---@return XTableTheatre3Ending
function XTheatre3Control:GetEndingById(id)
    return self._Model:GetEndingById(id)
end

---@return XTheatre3Settle
function XTheatre3Control:GetSettleData()
    return self._Model.ActivityData:GetSettleData()
end

function XTheatre3Control:SignSettleTip()
    self._Model.ActivityData:SignSettleTip()
end

function XTheatre3Control:ResetTeamDate()
    self._Model.ActivityData:ResetTeam()
end

function XTheatre3Control:GetRewardBoxConfig(rewardType, id)
    if rewardType == XEnumConst.THEATRE3.NodeRewardType.ItemBox then
        return self._Model:GetItemBoxById(id)
    elseif rewardType == XEnumConst.THEATRE3.NodeRewardType.EquipBox then
        return self._Model:GetEquipBoxById(id)
    elseif rewardType == XEnumConst.THEATRE3.NodeRewardType.Gold then
        return self._Model:GetGoldBoxById(id)
    end
    return nil
end

---获取结算后返回主界面时需要显示的弹框
function XTheatre3Control:GetSettleTips()
    local datas = {}
    local settle = self:GetSettleData()
    if not settle then
        return datas
    end

    local oldBpExp = self._Model.ActivityData:GetOldBpExp()
    -- 等级升级Tip
    if oldBpExp then
        local old = self:GetBattlePassLevelByExp(oldBpExp)
        local now = self:GetCurBattlePassLevel()
        if old < now then
            local param = { old = old, now = now }
            table.insert(datas, { uiName = "UiTheatre3LvTips", uiParam = param })
        end
    end
    -- 解锁藏品Tip
    local unlockItems = settle.CurUnlockItemId
    if not XTool.IsTableEmpty(unlockItems) then
        local param = { datas = unlockItems, isUnlockSettle = true }
        table.insert(datas, { uiName = "UiTheatre3UnlockTips", uiParam = param })
    end
    -- 解锁装备Tip
    local unlockEquips = settle.CurUnlockEquipId
    if not XTool.IsTableEmpty(unlockEquips) then
        local param = { datas = unlockEquips, isUnlockEquip = true }
        table.insert(datas, { uiName = "UiTheatre3UnlockTips", uiParam = param })
    end

    return datas
end

--endregion

--region 成员相关
function XTheatre3Control:GetSettleFactorInfo()
    local result = {}
    local settle = self:GetSettleData()
    local configs = self._Model:GetSettleFactor()
    for i, v in ipairs(configs) do
        local data = {}
        data.name = v.Name
        if i == 1 then
            data.count = settle.NodeCount
            data.score = settle.NodeCountScore
        elseif i == 2 then
            data.count = settle.FightNodeCount
            data.score = settle.FightNodeCountScore
        elseif i == 3 then
            data.count = settle.ChapterCount
            data.score = settle.ChapterCountScore
        elseif i == 4 then
            data.count = settle.TotalSuitCount
            data.score = settle.TotalSuitCountScore
        elseif i == 5 then
            data.count = settle.TotalEquipCount
            data.score = settle.TotalEquipCountScore
        elseif i == 6 then
            data.count = settle.TotalItemCount
            data.score = settle.TotalItemCountScore
        else
            XLog.Error("undefind settle factor type:" .. v)
            data.count = 0
            data.score = 0
        end
        table.insert(result, data)
    end
    return result
end
--endregion

--region 精通-天赋
---@return number[]
function XTheatre3Control:GetStrengthenTreeIdList(isSecond)
    return self._Model:GetStrengthenTreeIdList(isSecond and 2 or 1)
end

function XTheatre3Control:GetAllStrengthenTreeIdListDir()
    return self._Model:GetStrengthenTreeIdList()
end

---@return XTableTheatre3StrengthenTree
function XTheatre3Control:GetStrengthenTreeById(id)
    return self._Model:GetStrengthenTreeConfigById(id)
end

function XTheatre3Control:GetStrengthenTreeNameById(id)
    local config = self:GetStrengthenTreeById(id)
    return config and config.Name or ""
end

function XTheatre3Control:GetStrengthenTreeIconById(id)
    local config = self:GetStrengthenTreeById(id)
    return config and config.Icon
end

function XTheatre3Control:GetStrengthenTreePointTypeById(id)
    local config = self:GetStrengthenTreeById(id)
    return config and config.PointType
end

function XTheatre3Control:GetStrengthenTreeDescById(id)
    local config = self:GetStrengthenTreeById(id)
    return config and config.Desc or ""
end

function XTheatre3Control:GetStrengthenTreeNeedPointById(id)
    local config = self:GetStrengthenTreeById(id)
    return config and config.NeedStrengthenPoint or 0
end

function XTheatre3Control:GetStrengthenTreePreIdById(id)
    local config = self:GetStrengthenTreeById(id)
    return config and config.PreId or {}
end

function XTheatre3Control:GetStrengthenTreeConditionById(id)
    local config = self:GetStrengthenTreeById(id)
    return config and config.Condition or 0
end

-- 检查天赋是否解锁
function XTheatre3Control:CheckStrengthTreeUnlock(id)
    return self._Model.ActivityData:CheckUnlockStrengthTree(id)
end

-- 检查前置天赋是否有任意一个解锁
function XTheatre3Control:CheckAnyPreStrengthenTreeUnlock(id)
    local preIds = self:GetStrengthenTreePreIdById(id)
    if XTool.IsTableEmpty(preIds) then
        return true
    end
    for _, preId in pairs(preIds) do
        if self:CheckStrengthTreeUnlock(preId) then
            return true
        end
    end
    return false
end

-- 检查前置天赋是否全部解锁
function XTheatre3Control:CheckPreStrengthenTreeAllUnlock(id, isRedPoint)
    local preIds = self:GetStrengthenTreePreIdById(id)
    if XTool.IsTableEmpty(preIds) then
        if isRedPoint then
            return not self:_CheckGeniusRedPoint(id)
        else
            return true
        end
    end
    for _, preId in pairs(preIds) do
        if not self:CheckStrengthTreeUnlock(preId) then
            return false
        end
    end
    if isRedPoint then
        return not self:_CheckGeniusRedPoint(id)
    else
        return true
    end
end

-- 检查天赋条件是否成立
function XTheatre3Control:CheckStrengthenTreeCondition(id)
    local condition = self:GetStrengthenTreeConditionById(id)
    if XTool.IsNumberValid(condition) then
        return XConditionManager.CheckCondition(condition)
    end
    return true, ""
end

-- 检查天赋点货币是否充足
function XTheatre3Control:CheckStrengthenTreeNeedPointEnough(id)
    local itemCount = XDataCenter.ItemManager.GetCount(XEnumConst.THEATRE3.Theatre3TalentPoint)
    local needCount = self:GetStrengthenTreeNeedPointById(id)
    return itemCount >= needCount
end

-- 检查天赋树红点
-- 满足前置条件且未激活且天赋点数量充足的天赋
function XTheatre3Control:CheckStrengthenTreeRedPoint(id)
    local isOpen = self:CheckStrengthenTreeCondition(id)
    if not isOpen then
        return false
    end
    local isUnlock = self:CheckStrengthTreeUnlock(id)
    if isUnlock then
        return false
    end
    local isEnough = self:CheckStrengthenTreeNeedPointEnough(id)
    if not isEnough then
        return false
    end
    return self:CheckPreStrengthenTreeAllUnlock(id, true)
end

-- 检查所有天赋树红点
function XTheatre3Control:CheckAllStrengthenTreeRedPoint()
    local strengthenTreeIdListDir = self:GetAllStrengthenTreeIdListDir()
    for _, list in pairs(strengthenTreeIdListDir) do
        for _, id in pairs(list) do
            if self:CheckStrengthenTreeRedPoint(id) then
                return true
            end
        end
    end
    return false
end
--endregion

--region 精通-成员
function XTheatre3Control:GetCharacterGroupIdList()
    local characterGroupIdList = self._Model:GetCharacterGroupIdList()
    table.sort(characterGroupIdList, function(a, b)
        local orderIdA = self:GetCharacterGroupOrderIdById(a)
        local orderIdB = self:GetCharacterGroupOrderIdById(b)
        if orderIdA ~= orderIdB then
            return orderIdA < orderIdB
        end
        return a < b
    end)
    return characterGroupIdList
end

function XTheatre3Control:GetCharacterIdListByGroupId(groupId)
    local characterIdList = self._Model:GetCharacterIdListByGroupId(groupId)
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    -- 排序 角色精通等级 ＞ 当前精通等级经验 ＞ 成员战力
    table.sort(characterIdList, function(a, b)
        -- 角色精通等级
        local levelA = self:GetCharacterLv(a)
        local levelB = self:GetCharacterLv(b)
        if levelA ~= levelB then
            return levelA > levelB
        end
        -- 当前精通等级经验
        local expA = self:GetCharacterExp(a)
        local expB = self:GetCharacterExp(b)
        if expA ~= expB then
            return expA > expB
        end
        -- 成员战力
        local abilityA = characterAgency:GetCharacterAbilityById(a)
        local abilityB = characterAgency:GetCharacterAbilityById(b)
        if abilityA ~= abilityB then
            return abilityA > abilityB
        end
        return a < b
    end)
    return characterIdList
end

function XTheatre3Control:GetCharacterLevelIdListByCharacterId(characterId)
    return self._Model:GetCharacterLevelIdListByCharacterId(characterId)
end

function XTheatre3Control:GetCharacterEndingIdList(characterId)
    return self._Model:GetCharacterEndingIdList(characterId)
end

---@return XTableTheatre3CharacterGroup
function XTheatre3Control:GetCharacterGroupById(id)
    return self._Model:GetCharacterGroupById(id)
end

function XTheatre3Control:GetCharacterGroupOrderIdById(id)
    local config = self:GetCharacterGroupById(id)
    return config and config.OrderId or 0
end

---@return XTableTheatre3CharacterRecruit
function XTheatre3Control:GetCharacterRecruitById(recruitId)
    return self._Model:GetCharacterRecruitConfigById(recruitId)
end

function XTheatre3Control:GetCharacterIdByRecruitId(recruitId)
    local config = self:GetCharacterRecruitById(recruitId)
    return config and config.CharacterId or 0
end

function XTheatre3Control:GetCharacterLevelByLevelId(levelId)
    local config = self._Model:GetCharacterLevelConfigById(levelId)
    return config and config.Level or 0
end

function XTheatre3Control:GetCharacterLevelStrengthenPoint(levelId)
    local config = self._Model:GetCharacterLevelConfigById(levelId)
    return config and config.StrengthenPoint or 0
end

function XTheatre3Control:GetCharacterLevelNeedExp(levelId)
    local config = self._Model:GetCharacterLevelConfigById(levelId)
    return config and config.NeedExp or 0
end

function XTheatre3Control:GetCharacterLevelDesc(levelId)
    local config = self._Model:GetCharacterLevelConfigById(levelId)
    return config and config.Desc or 0
end

function XTheatre3Control:GetCharacterEndingCondition(id)
    local config = self._Model:GetCharacterEndingConfigById(id)
    return config and config.ConditionId or 0
end

function XTheatre3Control:GetCharacterEndingCharacterId(id)
    local config = self._Model:GetCharacterEndingConfigById(id)
    return config and config.CharacterId or 0
end

function XTheatre3Control:GetCharacterEndingIcon(id)
    local config = self._Model:GetCharacterEndingConfigById(id)
    return config and config.Icon
end

function XTheatre3Control:GetCharacterEndingTitle(id)
    local config = self._Model:GetCharacterEndingConfigById(id)
    return config and config.Title or ""
end

function XTheatre3Control:GetCharacterEndingDesc(id)
    local config = self._Model:GetCharacterEndingConfigById(id)
    return config and config.Desc or ""
end

-- 获取角色升级需要的经验
function XTheatre3Control:GetCharacterLevelUpNeedExp(characterId, level)
    local maxLevel = self._Model:GetCharacterMaxLevel(characterId)
    if level > maxLevel then
        return 0
    end
    local characterLevelId = self._Model:GetCharacterLevelId(characterId, level)
    if not XTool.IsNumberValid(characterLevelId) then
        return 0
    end
    return self:GetCharacterLevelNeedExp(characterLevelId)
end

function XTheatre3Control:CalculateCharacterLevel(characterId, curLevel, curExp, addExp)
    local curNeedExp = self:GetCharacterLevelUpNeedExp(characterId, curLevel + 1)
    local totalExp = curExp + addExp
    if curNeedExp ~= 0 then
        local bo = totalExp >= curNeedExp
        while bo do
            totalExp = totalExp - curNeedExp
            curLevel = curLevel + 1
            curNeedExp = self:GetCharacterLevelUpNeedExp(characterId, curLevel + 1)
            if curNeedExp <= 0 then
                bo = false
            else
                bo = totalExp >= curNeedExp
            end
        end
    end
    return curLevel, totalExp, curNeedExp
end

-- 检查当前等级是否是最大等级
function XTheatre3Control:CheckCharacterMaxLevel(characterId, level)
    local maxLevel = self._Model:GetCharacterMaxLevel(characterId)
    if level >= maxLevel then
        return true
    end
    return false
end

function XTheatre3Control:CheckCharacterEnding(id)
    local characterId = self:GetCharacterEndingCharacterId(id)
    return self._Model.ActivityData:GetCharacterInfo(characterId):CheckEnding(id)
end

-- 服务端有同步角色结局通过数据改用上方法
function XTheatre3Control:CheckCharacterEndingCondition(id)
    local condition = self:GetCharacterEndingCondition(id)
    if XTool.IsNumberValid(condition) then
        return XConditionManager.CheckCondition(condition)
    end
    return true, ""
end

--endregion

--region 编队相关
function XTheatre3Control:GetCharacterCost(id)
    id = XEntityHelper.GetCharacterIdByEntityId(id)
    if self:CheckIsLuckCharacter(id) then
        return 0
    end
    return self._Model:GetCharacterCost(id)
end

function XTheatre3Control:GetCurEnergy()
    local cost = 0
    for slotId = 1, 3 do
        local id = self:GetSlotCharacter(slotId)
        if id ~= 0 then
            cost = cost + self:GetCharacterCost(id)
        end
    end
    return cost, self._Model.ActivityData:GetMaxEnergy()
end

---@return XTheatre3EquipPos
function XTheatre3Control:GetSlotInfo(posId)
    return self._Model.ActivityData:GetSlotInfo(posId)
end

function XTheatre3Control:GetSlotOrder(posId)
    return self._Model.ActivityData:GetSlotIndexByPos(posId)
end

function XTheatre3Control:GetSlotIdByColor(colorId)
    return self._Model.ActivityData:GetSlotPosIdByColorId(colorId)
end

function XTheatre3Control:UpdateEquipPosRoleId(roleId, slotId, isJoin)
    self._Model.ActivityData:UpdateEquipPosRoleId(roleId, slotId, isJoin)
end

function XTheatre3Control:GetCharacterList(isOnlyRobot)
    local configs = self._Model:GetCharacterRecruitConfig()
    local characterList = {}
    for _, config in pairs(configs) do
        table.insert(characterList, config.RobotId)
        if not isOnlyRobot then
            if XMVCA.XCharacter:IsCharacterCanShow(config.CharacterId) then
                table.insert(characterList, config.CharacterId)
            end
        end
    end
    return characterList
end

function XTheatre3Control:GetCharacterLv(id)
    local info = self._Model.ActivityData:GetCharacterInfo(id)
    return info and info.Level or 0
end

function XTheatre3Control:GetCharacterExp(characterId)
    local info = self._Model.ActivityData:GetCharacterInfo(characterId)
    return info and info.Exp or 0
end

function XTheatre3Control:IsCharacterRepeat(id)
    if self:GetEntityIdIsInTeam(id) then
        return false
    end
    local characterId = XEntityHelper.GetCharacterIdByEntityId(id)
    local entityIds = self:GetTeamsEntityIds()
    for _, entityId in pairs(entityIds) do
        if characterId == XEntityHelper.GetCharacterIdByEntityId(entityId) then
            return true
        end
    end
    return false
end

function XTheatre3Control:GetFilterSortOverrideFunTable(slotId)
    local cost, total = self:GetCurEnergy()
    local cur = total - cost
    if slotId then
        local id = self:GetSlotCharacter(slotId)
        if id ~= 0 then
            cur = cur + self:GetCharacterCost(id)
        end
    end

    return {
        CheckFunList = {
            [CharacterSortFunType.Custom1] = function(idA, idB)
                local costA = self:GetCharacterCost(idA)
                local costB = self:GetCharacterCost(idB)
                if costA ~= costB then
                    return true
                end
            end,
            [CharacterSortFunType.Custom2] = function(idA, idB)
                if idA ~= idB then
                    return true
                end
            end
        },
        SortFunList = {
            -- 消耗能量
            [CharacterSortFunType.Custom1] = function(idA, idB)
                local costA = self:GetCharacterCost(idA)
                local costB = self:GetCharacterCost(idB)
                -- 天选角色优先
                if costA == 0 or costB == 0 then
                    return costA == 0
                end
                local isACanjoin = cur >= costA
                local isBCanjoin = cur >= costB
                if isACanjoin ~= isBCanjoin then
                    return isACanjoin == true
                end
                if costA ~= costB then
                    return costA > costB
                end
            end,
            -- Id
            [CharacterSortFunType.Custom2] = function(idA, idB)
                return idA > idB
            end
        }
    }
end

---槽位上是否有上阵角色
function XTheatre3Control:CheckIsHaveCharacter(slotId)
    local slotInfo = self:GetSlotInfo(slotId)
    return slotInfo:CheckIsHaveCharacter()
end

function XTheatre3Control:CheckCaptainHasEntityId()
    return self._Model.ActivityData:CheckCaptainHasEntityId()
end

function XTheatre3Control:CheckFirstFightHasEntityId()
    return self._Model.ActivityData:CheckFirstFightHasEntityId()
end

function XTheatre3Control:CheckIsCaptainPos(pos)
    local captainPos = self._Model.ActivityData:GetCaptainPos()
    return captainPos == pos
end

function XTheatre3Control:CheckIsFirstFightPos(pos)
    local firstFightPos = self._Model.ActivityData:GetFirstFightPos()
    return firstFightPos == pos
end

function XTheatre3Control:GetEquipCaptainPos()
    local captainPos = self._Model.ActivityData:GetCaptainPos()
    return self._Model.ActivityData:GetSlotPosIdByColorId(captainPos)
end

function XTheatre3Control:GetEquipFirstFightPos()
    local firstFightPos = self._Model.ActivityData:GetFirstFightPos()
    return self._Model.ActivityData:GetSlotPosIdByColorId(firstFightPos)
end

function XTheatre3Control:GetTeamsEntityIds()
    return self._Model.ActivityData:GetTeamsEntityIds()
end

function XTheatre3Control:GetEntityIdIsInTeam(entityId)
    return self._Model.ActivityData:GetEntityIdIsInTeam(entityId)
end

function XTheatre3Control:GetEntityIdBySlotColor(colorId)
    return self._Model.ActivityData:GetEntityIdBySlotColor(colorId)
end

function XTheatre3Control:UpdateEntityTeamPos(entityId, teamPos, isJoin)
    self._Model.ActivityData:UpdateEntityTeamPos(entityId, teamPos, isJoin)
end

function XTheatre3Control:UpdateTeamEntityIdList(entityIdList)
    self._Model.ActivityData:UpdateTeamEntityIdList(entityIdList)
end

--- 交换队伍位置
function XTheatre3Control:SwapEntityTeamPos(teamPosA, teamPosB)
    self._Model.ActivityData:SwapEntityTeamPos(teamPosA, teamPosB)
end

function XTheatre3Control:UpdateCaptainPosAndFirstFightPos(cPos, fPos)
    self._Model.ActivityData:UpdateCaptainPosAndFirstFightPos(cPos, fPos)
end

function XTheatre3Control:GetEnergyUnusedDesc(count)
    local desc = nil
    local temp = nil
    local configs = self._Model:GetEnergyUnusedConfig(count)
    for _, v in pairs(configs) do
        if v.UnusedCount <= count and (not temp or v.UnusedCount > temp) then
            temp = v.UnusedCount
            desc = v.Desc
        end
    end
    return desc
end

function XTheatre3Control:GetTeamData()
    return self._Model:GetTeamData()
end

function XTheatre3Control:SetTeamGeneralSkillId(generalSkillId)
    self._Model:SetTeamGeneralSkillId(generalSkillId)
end
--endregion

--region 图鉴-道具相关
function XTheatre3Control:GetItemTypeIdList()
    return self._Model:GetItemTypeIdList()
end

function XTheatre3Control:GetItemIdListByTypeId(typeId)
    return self._Model:GetItemIdListByTypeId(typeId)
end

---@return XTableTheatre3Item
function XTheatre3Control:GetItemConfigById(id)
    return self._Model:GetItemConfigById(id)
end

function XTheatre3Control:GetItemNameById(id)
    local cfg = self._Model:GetItemConfigById(id)
    return cfg and cfg.Name
end

function XTheatre3Control:GetItemBgTypeById(id)
    return self:GetItemConfigById(id).BgType
end

function XTheatre3Control:GetItemBgUrlById(id)
    local bgType = self:GetItemBgTypeById(id)
    return self:GetClientConfig("BgImgMap", bgType)
end

function XTheatre3Control:GetItemBgUrlByBgType(bgType)
    return self:GetClientConfig("BgImgMap", bgType)
end

function XTheatre3Control:GetItemTypeName(typeId)
    local config = self._Model:GetItemTypeConfigByTypeId(typeId)
    return config and config.Name or ""
end

function XTheatre3Control:GetItemUnlockConditionId(itemId)
    local config = self:GetItemConfigById(itemId)
    return config and config.UnlockConditionId or 0
end

-- 获取物品解锁进度
function XTheatre3Control:GetItemUnlockProgress()
    local itemTypeIdList = self:GetItemTypeIdList()
    local curCount = 0
    local totalCount = 0
    for _, typeId in pairs(itemTypeIdList) do
        local itemIds = self:GetItemIdListByTypeId(typeId)
        for _, itemId in pairs(itemIds) do
            if self:CheckUnlockItemId(itemId) then
                curCount = curCount + 1
            end
        end
        totalCount = totalCount + #itemIds
    end
    return curCount, totalCount
end

-- 检查物品id是否解锁 用于图鉴
function XTheatre3Control:CheckUnlockItemId(itemId)
    -- 如果没配置condition默认解锁
    local unlockConditionId = self:GetItemUnlockConditionId(itemId)
    if not XTool.IsNumberValid(unlockConditionId) then
        return true
    end
    return self._Model.ActivityData:CheckUnlockItemId(itemId)
end

-- 检查物品是否有红点  首次获得时显示红点
function XTheatre3Control:CheckItemRedPoint(itemId)
    -- 默认解锁无需红点
    local unlockConditionId = self:GetItemUnlockConditionId(itemId)
    if not XTool.IsNumberValid(unlockConditionId) then
        return false
    end
    if not self:GetItemClickRedPoint(itemId) and self:CheckUnlockItemId(itemId) then
        return true
    end
    return false
end

-- 检查所有的物品是否有红点
function XTheatre3Control:CheckAllItemRedPoint()
    local itemTypeIdList = self:GetItemTypeIdList()
    for _, typeId in pairs(itemTypeIdList) do
        local itemIds = self:GetItemIdListByTypeId(typeId)
        for _, itemId in pairs(itemIds) do
            if self:CheckItemRedPoint(itemId) then
                return true
            end
        end
    end
    return false
end
--endregion

--region 图鉴-套装相关
function XTheatre3Control:GetEquipSuitTypeIdList()
    return self._Model:GetEquipSuitTypeIdList()
end

function XTheatre3Control:GetEquipSuitIdListByTypeId(typeId)
    return self._Model:GetEquipSuitIdListByTypeId(typeId)
end

function XTheatre3Control:GetEquipSuitTypeName(typeId)
    local config = self._Model:GetEquipSuitTypeConfigByTypeId(typeId)
    return config and config.Name or ""
end

-- 获取套装解锁进度
function XTheatre3Control:GetEquipSuitUnlockProgress()
    local equipSuitTypeIdList = self:GetEquipSuitTypeIdList()
    local curCount = 0
    local totalCount = 0
    for _, typeId in pairs(equipSuitTypeIdList) do
        local equipSuitIdList = self:GetEquipSuitIdListByTypeId(typeId)
        for _, suitId in pairs(equipSuitIdList) do
            if self:CheckAnyEquipIdUnlock(suitId) then
                curCount = curCount + 1
            end
        end
        totalCount = totalCount + #equipSuitIdList
    end
    return curCount, totalCount
end

-- 检查装备是否解锁 用于图鉴
function XTheatre3Control:CheckEquipIdUnlock(equipId)
    return self._Model.ActivityData:CheckUnlockEquipId(equipId)
end

-- 检查套装下是否有任意一件装备解锁
function XTheatre3Control:CheckAnyEquipIdUnlock(suitId)
    local equipConfigs = self._Model:GetSameSuitEquip(suitId)
    if XTool.IsTableEmpty(equipConfigs) then
        return true
    end
    for _, config in pairs(equipConfigs) do
        if self:CheckEquipIdUnlock(config.Id) then
            return true
        end
    end
    return false
end

-- 检查装备是否有红点  首次获得时显示红点
function XTheatre3Control:CheckEquipRedPoint(equipId)
    if not self:GetEquipClickRedPoint(equipId) and self:CheckEquipIdUnlock(equipId) then
        return true
    end
    return false
end

-- 检查套装是否有红点
function XTheatre3Control:CheckEquipSuitRedPoint(suitId)
    local equipConfigs = self._Model:GetSameSuitEquip(suitId)
    if XTool.IsTableEmpty(equipConfigs) then
        return false
    end
    for _, config in pairs(equipConfigs) do
        if self:CheckEquipRedPoint(config.Id) then
            return true
        end
    end
    return false
end

-- 检查所有的套装是否有红点
function XTheatre3Control:CheckAllEquipSuitRedPoint()
    local equipSuitTypeIdList = self:GetEquipSuitTypeIdList()
    for _, typeId in pairs(equipSuitTypeIdList) do
        local equipSuitIdList = self:GetEquipSuitIdListByTypeId(typeId)
        for _, suitId in pairs(equipSuitIdList) do
            if self:CheckEquipSuitRedPoint(suitId) then
                return true
            end
        end
    end
    return false
end
--endregion

--region System - Sound
-- 播放奖励音效(1.道具箱 | 2.金币 | 3.装备箱)
function XTheatre3Control:PlayGetRewardSound(nodeRewardType)
    local targetIndex
    if nodeRewardType == XEnumConst.THEATRE3.NodeRewardType.ItemBox then
        targetIndex = 1
    elseif nodeRewardType == XEnumConst.THEATRE3.NodeRewardType.Gold then
        targetIndex = 2
    elseif nodeRewardType == XEnumConst.THEATRE3.NodeRewardType.EquipBox then
        targetIndex = 3
    end
    local cueId = self:GetClientConfigNumber("Theatre3GetRewardSound", targetIndex) or 0
    if XTool.IsNumberValid(cueId) then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
    end
end

function XTheatre3Control:PlayQuantumBGM(isALine)
    if isALine then
        XLuaAudioManager.SetWholeSelector("MusicSwitch","A")
    else
        XLuaAudioManager.SetWholeSelector("MusicSwitch","B")
    end
end
--endregion

--region Server - Request
-- 领取BP奖励
function XTheatre3Control:GetBattlePassRewardRequest(rewardType, id, cb)
    local req = { GetRewardType = rewardType, Id = id }
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3GetBattlePassRewardRequest, req, function(res)
        XLuaUiManager.Open("UiTheatre3TipReward", res.RewardGoodsList)
        self._Model:UpdateGetRewardId(rewardType, res.GetRewardIds, id)
        if cb then
            cb()
        end
    end)
end

-- 激活天赋树
function XTheatre3Control:ActivationStrengthenTreeRequest(id, cb)
    local req = { Id = id }
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3ActivationStrengthenTreeRequest, req, function(res)
        -- 更新解锁天赋Id
        self._Model.ActivityData:AddUnlockStrengthTreeId(id)
        if cb then
            cb()
        end
    end)
end

function XTheatre3Control:RequestSelectEquip(equipId, pos, isQuantum)
    -- 服务端说只能请求一次RequestSelectEquip
    if self._IsWaitSelectEquipReq then
        return
    end
    self._IsWaitSelectEquipReq = true

    local lastStep = self:_GetLastAdventureSelectEquip()
    XNetwork.Call(RequestProto.Theatre3SelectEquipRequest, { SelectId = equipId, Pos = pos }, function(res)
        self._IsWaitSelectEquipReq = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local suitId = isQuantum and equipId or self:GetEquipById(equipId).SuitId
        
        local FuncNextStep = function()
            self:CheckAndOpenAdventureNextStep(true)
        end
        lastStep:SetIsOver()
        if isQuantum then
            XLuaUiManager.Open("UiTheatre3QuantumSettlement", suitId, FuncNextStep)
            return
        end
        local data = {
            Pos = pos,
            EquipId = equipId,
            SuitId = suitId,
            QubitActive = isQuantum,
        }
        self._Model.ActivityData:AddContainerEquip(pos, data)
        -- 套装激活弹框
        if self:IsSuitComplete(suitId) then
            XLuaUiManager.Open("UiTheatre3SuitActiveTip", suitId, FuncNextStep)
        else
            FuncNextStep()
        end
    end)
end

function XTheatre3Control:SelectInitialItemRequest(itemId)
    XNetwork.Call(RequestProto.Theatre3SelectInitialItemRequest, { ItemId = itemId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:CheckAndOpenAdventureNextStep(true)
    end)
end

--- 刷新装备箱奖励
function XTheatre3Control:RefreshEquipBoxRequest(cb)
    XNetwork.Call(RequestProto.Theatre3RefreshEquipBoxRequest, nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local step = self:GetAdventureLastStep(XEnumConst.THEATRE3.StepType.EquipReward)
        if step then
            step:UpdateEquipIds(res.Step.EquipIds)
            step:UpdateRefreshTimes(res.Step.RefreshTimes)
        else
            XLog.Error("当前步骤不是选择装备.")
        end
        if cb then
            cb()
        end
    end)
end

function XTheatre3Control:RequestChangeSuitPos(srcSuitId, srcPos, dstSuitId, dstPos)
    XNetwork.Call(RequestProto.Theatre3ChangeEquipPosRequest, { SrcSuitId = srcSuitId, SrcPos = srcPos, DstSuitId = dstSuitId, DstPos = dstPos }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local srcEquips = self:GetAllSuitWearEquipId(srcSuitId)
        local dstEquips = self:GetAllSuitWearEquipId(dstSuitId)
        self._Model.ActivityData:ExchangeContainerSuit(srcSuitId, srcPos, srcEquips, dstSuitId, dstPos, dstEquips)
        self:WorkShopReduceTimes()
    end)
end

function XTheatre3Control:RequestRebuildEquip(srcEquipId, dstSuitId, dstPos)
    XNetwork.Call(RequestProto.Theatre3RecastEquipRequest, { SrcEquipId = srcEquipId, DstSuitId = dstSuitId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local srcSuitId = self:GetEquipById(srcEquipId).SuitId
        local srcEquips = self:GetAllSuitWearEquipId(srcSuitId)
        local srcPos = self:GetEquipBelong(srcEquipId)
        local isSuitLost = #srcEquips <= 1 -- 如果套装里只有这一件装备 则套装也会一起失去
        self._Model.ActivityData:RebuildContainerEquip(isSuitLost and srcSuitId or nil, srcPos, srcEquipId, dstSuitId, dstPos, res.DstEquipId)
        self:WorkShopReduceTimes()
        XLuaUiManager.Open("UiTheatre3RecastSettlement", srcEquipId, res.DstEquipId)
    end)
end

---设置编队
function XTheatre3Control:RequestSetTeam(callBack)
    local teamData = {}
    teamData.CardIds = self._Model.ActivityData:GetTeamsCharIds()
    teamData.RobotIds = self._Model.ActivityData:GetTeamRobotIds()
    teamData.CaptainPos = self._Model.ActivityData:GetCaptainPos()
    teamData.FirstFightPos = self._Model.ActivityData:GetFirstFightPos()
    teamData.EnterCgIndex = self._Model.ActivityData:GetEnterCgIndex()
    teamData.SettleCgIndex = self._Model.ActivityData:GetSettleCgIndex()

    local entityIds = self:GetTeamsEntityIds()
    local equipPosInfos = {}
    for i = 1, 3 do
        local slotInfo = self:GetSlotInfo(i)
        local posId = slotInfo:GetPos()
        local colorId = slotInfo:GetColorId()
        local cardId = slotInfo:GetCardId()
        local robotId = slotInfo:GetRobotId()
        local roleId = slotInfo:GetRoleId()
        if roleId ~= entityIds[colorId] then
            XLog.Error("槽位角色id和编队角色Id不一致", roleId, entityIds, posId, colorId)
        end
        table.insert(equipPosInfos, { Pos = posId, CardId = cardId, RobotId = robotId, ColorId = colorId })
    end

    XNetwork.Call(RequestProto.Theatre3SetTeamRequest, { EquipPosInfos = equipPosInfos, TeamData = teamData }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        
        -- 保存效应选择
        self._Model:SaveTeamGeneralSkillId()
        
        if callBack then
            callBack()
        end
    end)
end

---结束冒险
function XTheatre3Control:RequestSettleAdventure(cb)
    XNetwork.Call(RequestProto.Theatre3SettleAdventureRequest, nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if res.SettleData.EndId then
            if self._Model:CheckEndingIsSuccess(res.SettleData.EndId) then
                self._Model.ActivityData:AddTotalAllPassCount()
            end
        end
        self._Model.ActivityData:UpdateSettle(res.SettleData)
        if cb then
            cb()
        end
    end)
end

-- 进入冒险选择难度
function XTheatre3Control:RequestAdventureSelectDifficulty(difficultyId, cb)
    -- 初始化冒险数据
    self:InitAdventureData()
    self:InitAdventureSettleData()
    self:ClearAdventureEventNodeStoryDir()
    self:ResetTeamDate()
    local req = { Difficulty = difficultyId }
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3SelectDifficultyRequest, req, function(res)
        self._Model.ActivityData:UpdateDifficulty(res.DifficultyId)
        self._Model.ActivityData:UpdateMaxEnergy(res.MaxEnergy)
        self._Model.ActivityData:UpdateEquipPosData(res.EquipPos)
        if cb then
            cb()
        end
    end)
end

-- 结束开局编队
function XTheatre3Control:RequestAdventureEndRecruit(cb)
    local lastStep = self:GetAdventureLastStep(XEnumConst.THEATRE3.StepType.RecruitCharacter)
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3EndRecruitRequest, nil, function(res)
        lastStep:SetIsOver()
        if cb then
            cb()
        end
    end)
end

-- 选择节点
---@param nodeData XTheatre3Node
---@param nodeSlot XTheatre3NodeSlot
function XTheatre3Control:RequestAdventureSelectNode(nodeData, nodeSlot, cb)
    local reqBody = {
        NodeId = nodeData:GetNodeId(),
        SlotId = nodeSlot:GetSlotId(),
    }
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3SelectNodeRequest, reqBody, function(res)
        nodeData:SetSelect(nodeSlot)
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_ADVENTURE_MAIN_SELECT_NODE, self._NodeSlot)
        self:CheckAndOpenAdventureNodeSlot(nodeSlot, not nodeSlot:CheckIsFight())
    end)
end

function XTheatre3Control:RequestAdventureSelectItemReward(itemId, cb)
    local reqBody = {
        InnerItemId = itemId,
    }
    local lastStep = self:GetAdventureLastStep(XEnumConst.THEATRE3.StepType.ItemReward)
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3SelectItemRewardRequest, reqBody, function(res)
        -- N选1,单独处理步骤结束
        lastStep:SetIsOver()
        self:SetAdventureStepSelectItem(res.InnerItemId)
        self:OpenAdventureTipReward(nil, {res.InnerItemId}, cb)
    end)
end

function XTheatre3Control:RequestAdventureShopBuyItem(shopItemUid, cb)
    local reqBody = {
        ShopItemUid = shopItemUid
    }
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3NodeShopBuyItemRequest, reqBody, function(res)
        if cb then
            cb()
        end
        local checkNewStep = function()
            local lastStep = self:GetAdventureLastStep()
            if not lastStep:CheckStepType(XEnumConst.THEATRE3.StepType.Node) then
                self:CheckAndOpenAdventureNextStep(true)
            end
        end
        local checkQuantumCb = function()
            if self._CacheQuantumData then
                self:CheckAdventureQuantumValueChange(checkNewStep)
            else
                checkNewStep()
            end
        end
        local closeCb = function()
            if not XTool.IsTableEmpty(res.LotteryRewards) then
                local keyIndex, value = next(res.LotteryRewards)
                local content = self:GetClientConfig("ShopBuyExGet", keyIndex)
                if keyIndex == 1 then
                    content = string.format(content, self:GetItemNameById(value))
                else
                    content = string.format(content, value)
                end
                self:OpenTextTip(nil, nil, content, checkQuantumCb)
            else
                checkQuantumCb()
            end
        end
        if XTool.IsNumberValid(res.InnerItemId) then
            self:OpenAdventureTipReward(nil, {res.InnerItemId}, closeCb)
        end
        if not XTool.IsTableEmpty(res.RewardGoodsList) then
            self:OpenAdventureTipReward({res.RewardGoodsList}, nil, closeCb)
        end
        
    end)
end

function XTheatre3Control:RequestAdventureEndNode(cb)
    local lastStep = self:GetAdventureLastStep()
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3EndNodeRequest, nil, function(res)
        if lastStep then
            lastStep:SetIsOver()
            self:GetAdventureCurChapterDb():AddPassNode(lastStep:GetSelectNodeId())
        end
        if cb then
            cb()
        end
    end)
end

function XTheatre3Control:RequestAdventureEventNodeNextStep(curEventStepId, optionId, cb)
    local reqBody = {
        CurEventStepId = curEventStepId,
        OptionId = optionId,
    }
    local lastStep = self:GetAdventureLastStep()
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3EventNodeNextStepRequest, reqBody, function(res)
        local lastNodeSlot = self:GetAdventureLastNodeSlot()
        if lastNodeSlot then
            lastNodeSlot:AddPassedStepId(lastNodeSlot:GetCurStepId())
            lastNodeSlot:SetCurStepId(res.NextEventStepId)
            lastNodeSlot:SetFightTemplateId(res.FightTemplateId)
        end
        if lastStep and not XTool.IsNumberValid(res.NextEventStepId) then
            lastStep:SetIsOver()
            self:GetAdventureCurChapterDb():AddPassNode(lastStep:GetSelectNodeId())
        end
        
        if not XTool.IsTableEmpty(res.InnerItemIds) then
            self:OpenAdventureTipReward(nil, res.InnerItemIds, function()
                if cb then
                    cb(XTool.IsNumberValid(res.NextEventStepId))
                end
            end)
        end
        if not XTool.IsTableEmpty(res.RewardGoodsList) then
            self:OpenAdventureTipReward(res.RewardGoodsList, nil, function()
                if cb then
                    cb(XTool.IsNumberValid(res.NextEventStepId))
                end
            end)
        end
        if XTool.IsTableEmpty(res.InnerItemIds) and XTool.IsTableEmpty(res.RewardGoodsList) then
            if cb then
                cb(XTool.IsNumberValid(res.NextEventStepId))
            end
        end
    end)
end

---领取战斗奖励
function XTheatre3Control:RequestAdventureRecvFightReward(rewardUid, cb)
    local request = RequestProto.Theatre3RecvFightRewardRequest
    -- 此处记录
    local CsTime = CS.UnityEngine.Time
    if self._ReqCdDir[request]  then
        if CsTime.realtimeSinceStartup - self._ReqCdDir[request].RecordTime < 0.5 then
            return
        end
    end
    local reqBody = {
        Uid = rewardUid,
    }
    local rewards = self:GetAdventureStepSelectRewardList()
    if not self._ReqCdDir[request] then
        self._ReqCdDir[request] = {}
    end
    self._ReqCdDir[request].RecordTime = CsTime.realtimeSinceStartup
    XNetwork.CallWithAutoHandleErrorCode(request, reqBody, function(res)
        if not XTool.IsTableEmpty(res.RewardGoodsList) then
            self:OpenAdventureTipReward(res.RewardGoodsList)
        end
        local isEnd = true -- 是否已经领取全部奖励
        for _, v in pairs(rewards) do
            if v.Uid == rewardUid then
                v.Received = true
            end
            if not v.Received then
                isEnd = false
            end
        end
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_ADVENTURE_RECV_FIGHT_REWARD)
        if cb then
            cb(isEnd)
        end
    end)
end

---结束领取战斗奖励
function XTheatre3Control:RequestAdventureEndRecvFightReward(cb)
    local reqBody = {}
    local lastStep = self:GetAdventureLastStep(XEnumConst.THEATRE3.StepType.FightReward)
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3EndRecvFightRewardRequest, reqBody, function(res)
        if lastStep then
            lastStep:SetIsOver()
            self:GetAdventureCurChapterDb():AddPassNode(lastStep:GetSelectNodeId())
        end
        if cb then
            cb()
        end
    end)
end

---事件—工坊—结束工坊—事件下一步
function XTheatre3Control:RequestAdventure3EndWorkShop(cb)
    local reqBody = {}
    local lastStep = self:GetAdventureLastStep(XEnumConst.THEATRE3.StepType.WorkShop)
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3EndWorkShopRequest, reqBody, function(res)
        if lastStep then
            lastStep:SetIsOver()
            self:GetAdventureCurChapterDb():AddPassNode(lastStep:GetSelectNodeId())
        end
        if cb then
            cb()
        end
    end)
end

function XTheatre3Control:RequestEndEquipBox(cb)
    local lastStep = self:GetAdventureLastStep()
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3EndEquipBoxRequest, nil, function(res)
        lastStep:SetIsOver()
        if cb then
            cb()
        end
    end)
end

function XTheatre3Control:RequestLookEquipAttribute(equipId, suitId, cb)
    local request = RequestProto.Theatre3LookEquipAttributeRequest
    local effectDescData = self._Model.ActivityData:GetAdventureEffectDescData()
    local CsTime = CS.UnityEngine.Time
    if self._ReqCdDir[request] and effectDescData then
        if CsTime.realtimeSinceStartup - self._ReqCdDir[request].RecordTime < 1.1 then
            return
        else
            if (effectDescData:CheckHasEquipData(equipId) or effectDescData:CheckHasSuitData(suitId))
                    and XTime.GetServerNowTimestamp() - self._ReqCdDir[request].RecordTime < 3
                    and self._ReqCdDir[request].RecordData[1] == equipId
                    and self._ReqCdDir[request].RecordData[2] == suitId
            then
                if cb then cb() end
                return
            end
        end
    end
    local reqBody = {
        EquipId = equipId or 0,
        SuitId = suitId or 0,
    }
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3LookEquipAttributeRequest, reqBody, function(res)
        self._Model.ActivityData:UpdateEffectDescData(res)
        self._ReqCdDir[request] = {}
        self._ReqCdDir[request].RecordData = {equipId, suitId}
        self._ReqCdDir[request].RecordTime = CsTime.realtimeSinceStartup
        if cb then
            cb()
        end
    end)
end

function XTheatre3Control:RequestAchievementReward(achievementLevel)
    local reqBody = {
        NeedCountId = achievementLevel,
    }
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3GetAchievementRewardRequest, reqBody, function(res)
        if table.nums(res.RewardGoodsList) > 0 then
            XLuaUiManager.Open("UiTheatre3TipReward", res.RewardGoodsList, nil, function()
                XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_ACHIEVEMENT_RECV_REWARD)
            end)
            self._Model.ActivityData:AddAchievementRecord(achievementLevel)
        end
    end)
end

function XTheatre3Control:RequestSelectLuckCharacter(characterId, cb)
    local reqBody = {
        CharacterId = characterId,
    }
    local lastStep = self:GetAdventureLastStep(XEnumConst.THEATRE3.StepType.LuckyCharSelect)
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3DestinySelectRequest, reqBody, function(res)
        lastStep:SetIsOver()
        self._Model.ActivityData:UpdateLuckCharacterId(characterId)
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_SELECT_LUCK_CHARACTER)
    end)
end

---事件-工坊-量子化
function XTheatre3Control:RequestEquipQuantum(suitId)
    local reqBody = {
        EquipId = suitId,
    }
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3QubitEquipRequest, reqBody, function(res)
        self:WorkShopReduceTimes()
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_QUANTUM_SUCCESS)
        XLuaUiManager.Open("UiTheatre3QuantumSettlement", suitId)
    end)
end

---切换线路
function XTheatre3Control:RequestSwitchParallelChapter(chapterId)
    if not self._Model.ActivityData:IsCanSwitchChapter() or not XTool.IsNumberValid(chapterId) then
        XUiManager.TipErrorWithKey("Theatre3CantSwitchChapter")
        return
    end
    local reqBody = {
        ChapterId = chapterId,
    }
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3SwitchParallelChapterRequest, reqBody, function(res)
        self._Model.ActivityData:UpdateCurChapterId(chapterId)
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_CHAPTER_CHANGE, self:IsAdventureALine())
    end)
end
--endregion

--region RedPoint
function XTheatre3Control:GetAddEnergyLimitRedPoint()
    return self._Model:GetAddEnergyLimitRedPoint()
end

function XTheatre3Control:SetAddEnergyLimitRedPoint(value)
    self._Model:SetAddEnergyLimitRedPoint(value)
end
--endregion

--region Data - CacheData
function XTheatre3Control:_InitCacheData()
    self._AdventureEventNodeStoryIdDir = XSaveTool.GetData("Theatre3StoryIdDir") or {}
end

function XTheatre3Control:_ReleaseCacheData()
    self._AdventureEventNodeStoryIdDir = false
end

function XTheatre3Control:CheckAdventureEventNodeStoryId(storyId)
    return not self._AdventureEventNodeStoryIdDir[storyId]
end

function XTheatre3Control:SaveAdventureEventNodeStoryId(storyId)
    self._AdventureEventNodeStoryIdDir[storyId] = true
    self:_SaveAdventureEventNodeStoryDir()
end

function XTheatre3Control:ClearAdventureEventNodeStoryDir()
    self._AdventureEventNodeStoryIdDir = {}
    self:_SaveAdventureEventNodeStoryDir()
end

function XTheatre3Control:_SaveAdventureEventNodeStoryDir()
    return XSaveTool.SaveData("Theatre3StoryIdDir", self._AdventureEventNodeStoryIdDir)
end

-- 图鉴-道具红点点击缓存
function XTheatre3Control:GetItemClickRedPointKey(itemId)
    return string.format("XTheatre3ItemClickRedPoint_%s_%s_%s", XPlayer.Id, self._Model.ActivityData:GetCurActivityId(), itemId)
end

function XTheatre3Control:GetItemClickRedPoint(itemId)
    local key = self:GetItemClickRedPointKey(itemId)
    return XSaveTool.GetData(key) or false
end

function XTheatre3Control:SaveItemClickRedPoint(itemId)
    local key = self:GetItemClickRedPointKey(itemId)
    local data = XSaveTool.GetData(key) or false
    if data then
        return
    end
    XSaveTool.SaveData(key, true)
end

function XTheatre3Control:ClearItemRedPoint()
    local itemTypeIdList = self:GetItemTypeIdList()
    for _, typeId in pairs(itemTypeIdList) do
        local itemIds = self:GetItemIdListByTypeId(typeId)
        for _, itemId in pairs(itemIds) do
            if self:CheckItemRedPoint(itemId) then
                self:SaveItemClickRedPoint(itemId)
            end
        end
    end
end

-- 图鉴-装备红点点击缓存
function XTheatre3Control:GetEquipClickRedPointKey(equipId)
    return string.format("XTheatre3EquipClickRedPoint_%s_%s_%s", XPlayer.Id, self._Model.ActivityData:GetCurActivityId(), equipId)
end

function XTheatre3Control:GetEquipClickRedPoint(equipId)
    local key = self:GetEquipClickRedPointKey(equipId)
    return XSaveTool.GetData(key) or false
end

function XTheatre3Control:SaveEquipClickRedPoint(equipId)
    local key = self:GetEquipClickRedPointKey(equipId)
    local data = XSaveTool.GetData(key) or false
    if data then
        return
    end
    XSaveTool.SaveData(key, true)
end

function XTheatre3Control:ClearEquipRedPoint()
    local equipSuitTypeIdList = self:GetEquipSuitTypeIdList()
    for _, typeId in pairs(equipSuitTypeIdList) do
        local equipSuitIdList = self:GetEquipSuitIdListByTypeId(typeId)
        for _, suitId in pairs(equipSuitIdList) do
            local equipConfigs = self._Model:GetSameSuitEquip(suitId)
            if not XTool.IsTableEmpty(equipConfigs) then
                for _, config in pairs(equipConfigs) do
                    if self:CheckEquipRedPoint(config.Id) then
                        self:SaveEquipClickRedPoint(config.Id)
                    end
                end
            end
        end
    end
end

-- 精通-天赋红点点击缓存
function XTheatre3Control:_GetGeniusRedPointKey(geniusId)
    return string.format("XTheatre3GeniusRedPoint_%s_%s_%s", XPlayer.Id, self._Model.ActivityData:GetCurActivityId(), geniusId)
end

function XTheatre3Control:_CheckGeniusRedPoint(geniusId)
    local key = self:_GetGeniusRedPointKey(geniusId)
    return XSaveTool.GetData(key) or false
end

function XTheatre3Control:SaveGeniusRedPoint(geniusId)
    local key = self:_GetGeniusRedPointKey(geniusId)
    local data = XSaveTool.GetData(key) or false
    if data then
        return
    end
    XSaveTool.SaveData(key, true)
end

function XTheatre3Control:ClearGeniusRedPoint()
    local strengthenTreeIdListDir = self:GetAllStrengthenTreeIdListDir()
    for _, list in pairs(strengthenTreeIdListDir) do
        for _, id in pairs(list) do
            if self:CheckStrengthenTreeRedPoint(id) then
                self:SaveGeniusRedPoint(id)
            end
        end
    end
end

function XTheatre3Control:CheckIsNotOpenQuantumIsTip()
    return XSaveTool.GetData(string.format("XTheatre3OpenQuantumIsTip_%s", XPlayer.Id))
end

function XTheatre3Control:SetOpenQuantumIsTip()
    XSaveTool.SaveData(string.format("XTheatre3OpenQuantumIsTip_%s", XPlayer.Id), true)
end
--endregion

--region Data - Achievement
---@return XTaskData[]
function XTheatre3Control:GetAchievementTaskDataList(achievementId, isSort)
    if isSort == nil then isSort = true end

    local taskIdList = self:GetCfgAchievementTaskIds(achievementId)
    local result = {}
    for _, id in ipairs(taskIdList) do
        table.insert(result, XDataCenter.TaskManager.GetTaskDataById(id))
    end
    if isSort then
        XDataCenter.TaskManager.SortTaskList(result)
    end
    return result
end

function XTheatre3Control:GetAchievementFinishTaskCount(achievementId, isSort)
    if isSort == nil then isSort = true end

    local taskIdList = self:GetCfgAchievementTaskIds(achievementId)
    local result = {}
    for _, id in ipairs(taskIdList) do
        table.insert(result, XDataCenter.TaskManager.GetTaskDataById(id))
    end
    if isSort then
        XDataCenter.TaskManager.SortTaskList(result)
    end
    return result
end

function XTheatre3Control:CheckAchievementIsGet(achievementLevel)
    return self._Model.ActivityData:CheckAchievementRecord(achievementLevel)
end

function XTheatre3Control:CheckHaveAnyAchievementTaskFinish()
    for _, cfg in ipairs(self._Model:GetAchievementConfigs()) do
        for _, taskData in ipairs(self:GetAchievementTaskDataList(cfg.Id, true)) do
            if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end
    end
    return false
end
--endregion

--region Data - LuckyCharacter
function XTheatre3Control:CheckIsLuckCharacter(id)
    return self._Model.ActivityData:CheckIsLuckCharacter(id)
end

function XTheatre3Control:GetLuckyValuePercent()
    return math.min(self:_GetLuckyValue() / self:_GetLuckyValueLimit(), 1) 
end

function XTheatre3Control:_GetLuckyValue()
    return self._Model.ActivityData:GetLuckyValue()
end

function XTheatre3Control:_GetLuckyValueLimit()
    return tonumber(self:GetShareConfig("DestinyValueMaxLimit"))
end
--endregion

--region Cfg - ConfigCache
function XTheatre3Control:_InitCfgCacheValue()
    self._DamageMagicEquipSuitDir = {}
    self._QuantumUpTxtDir = {}
end

function XTheatre3Control:_ReleaseCfgCacheValue()
    self._DamageMagicEquipSuitDir = false
    self._QuantumUpTxtDir = false
end
--endregion

--region Cfg - Activity
function XTheatre3Control:GetActivityName()
    local config = self._Model:GetActivityConfig()
    if not config then
        return ""
    end
    return config.Name or ""
end
--endregion

--region Cfg - Client&Share
function XTheatre3Control:GetShareConfig(key)
    return self._Model:GetShareConfig(key)
end

function XTheatre3Control:GetClientConfig(key, index)
    if not index then
        index = 1
    end
    return self._Model:GetClientConfig(key, index)
end

function XTheatre3Control:GetClientConfigs(key)
    return self._Model:GetClientConfigs(key)
end

function XTheatre3Control:GetClientConfigTxtByConvertLine(key, index)
    return XUiHelper.ConvertLineBreakSymbol(self:GetClientConfig(key, index))
end

function XTheatre3Control:GetClientConfigNumber(key, index)
    return tonumber(self:GetClientConfig(key, index))
end

---伤害统计显示开关
function XTheatre3Control:GetShowDamageStatisticsIsOpen()
    local value = self:GetClientConfigNumber("IsShowDamageStatistics", 1)
    return XTool.IsNumberValid(value)
end
--endregion

--region Cfg - Difficulty
---@return number[]
function XTheatre3Control:GetDifficultyIdList()
    local result = {}
    local configs = self._Model:GetDifficultyConfigs()
    if XTool.IsTableEmpty(configs) then
        return result
    end
    if self:IsHavePassAdventure() then
        for _, config in ipairs(configs) do
            if not XTool.IsNumberValid(config.FirstPassFlag) then
                result[#result + 1] = config.Id
            end
        end
    else
        local FirstDifficultyCount = 0
        for _, config in ipairs(configs) do
            if XTool.IsNumberValid(config.FirstPassFlag) then
                result[#result + 1] = config.Id
                FirstDifficultyCount = FirstDifficultyCount + 1
            elseif not XTool.IsNumberValid(FirstDifficultyCount) then
                result[#result + 1] = config.Id
            else
                FirstDifficultyCount = FirstDifficultyCount - 1
            end
        end
    end
    XTool.SortIdTable(result)
    return result
end

---@return XTableTheatre3Difficulty
function XTheatre3Control:GetDifficultyById(id)
    return self._Model:GetDifficultyById(id)
end
--endregion

--region Cfg - Chapter
---@return XTableTheatre3Chapter
function XTheatre3Control:GetChapterById(chapterId)
    return self._Model:GetChapterCfgById(chapterId)
end
--endregion

--region Cfg - EventNode
function XTheatre3Control:GetEventCfgByIdAndStep(eventId, stepId)
    return self._Model:GetEventCfgByIdAndStep(eventId, stepId)
end

function XTheatre3Control:GetEventNodeCfgById(eventId)
    return self._Model:GetEventNodeCfgById(eventId)
end

---@return number[]
function XTheatre3Control:GetEventOptionIdListByGroup(optionGroupId)
    local result = {}
    local configs = self._Model:GetEventOptionGroupConfigs()
    for _, config in ipairs(configs) do
        if config.GroupId == optionGroupId then
            result[#result + 1] = config.Id
        end
    end
    XTool.SortIdTable(result)
    return result
end

---@return XTableTheatre3EventOptionGroup
function XTheatre3Control:GetEventOptionCfgById(optionId)
    return self._Model:GetEventOptionCfgById(optionId)
end
--endregion

--region Cfg - FightNode
function XTheatre3Control:GetFightStageTemplateStageId(id)
    local cfg = self._Model:GetFightStageTemplateCfgById(id)
    if cfg then
        return cfg.StageId
    end
end

function XTheatre3Control:GetFightNodeCfgById(fightNodeId)
    return self._Model:GetFightNodeCfgById(fightNodeId)
end
--endregion

--region Cfg - ShopNode
function XTheatre3Control:GetShopNodeCfgById(id)
    return self._Model:GetShopNodeCfgById(id)
end
--endregion

--region Cfg - Achievement
function XTheatre3Control:GetCfgAchievementRewardIdList()
    return self._Model:GetActivityConfig().RewardIds
end

function XTheatre3Control:GetCfgAchievementNeedCountList()
    return self._Model:GetActivityConfig().NeedCounts
end

function XTheatre3Control:GetCfgAchievementIdList()
    local result = {}
    for _, cfg in pairs(self._Model:GetAchievementConfigs()) do
        table.insert(result, cfg.Id)
    end
    return result
end

function XTheatre3Control:GetCfgAchievementTag(id)
    local cfg = self._Model:GetAchievementCfg(id)
    return cfg and cfg.TagName
end

function XTheatre3Control:GetCfgAchievementTaskIds(id)
    local cfg = self._Model:GetAchievementCfg(id)
    return cfg and cfg.TaskIds
end
--endregion

--region Cfg - EquipDamageSource
function XTheatre3Control:GetCfgEquipDamageMagicId2SuitIdDir(suitId)
    self:_InitCfgEquipDamageMagicId2SuitIdDir()
    return self._DamageMagicEquipSuitDir[suitId]
end

function XTheatre3Control:_InitCfgEquipDamageMagicId2SuitIdDir()
    if XTool.IsTableEmpty(self._DamageMagicEquipSuitDir) then
        for _, cfg in pairs(self._Model:GetEquipDamageSourceConfigs()) do
            if XTool.IsTableEmpty(self._DamageMagicEquipSuitDir[cfg.EquipId]) then
                self._DamageMagicEquipSuitDir[cfg.EquipId] = {}
            end
            for _, effectId in ipairs(cfg.MagicId) do
                table.insert(self._DamageMagicEquipSuitDir[cfg.EquipId], effectId)
            end
        end
    end
end
--endregion

--region Cfg - Quantum
function XTheatre3Control:GetCfgQuantumLevelByValue(value)
    return self._Model:GetQuantumLevelCfgByValue(value)
end

function XTheatre3Control:GetCfgQuantumShowPuzzleListByValue(value, quantumType)
    return self._Model:GetQuantumShowPuzzleListCfgByValue(value, quantumType)
end

function XTheatre3Control:GetCfgQuantumLevelValue(id)
    local cfg = self._Model:GetQuantumShowLevelCfgById(id)
    return cfg and cfg.Value
end

function XTheatre3Control:GetCfgQuantumEffectListByValue(aValue, bValue)
    local result = {}
    local isALine = self:IsAdventureALine()
    ---@param cfg XTableTheatre3QubitEffect
    local FuncAddResult = function(cfg)
        local coverIndex = XTool.IsNumberValid(cfg.CoverId) and table.indexof(result, cfg.CoverId)
        if coverIndex then
            table.remove(result, coverIndex)
        end
        table.insert(result, cfg.Id)
    end
    for _, cfg in ipairs(self._Model:GetQuantumEffectConfigs()) do
        local isA = XTool.IsNumberValid(cfg.QubitA) and aValue >= cfg.QubitA
        local isB = XTool.IsNumberValid(cfg.QubitB) and bValue >= cfg.QubitB
        if cfg.ShowType == XEnumConst.THEATRE3.QuantumEffectShowType.All and (isA or isB) then
            FuncAddResult(cfg)
        elseif cfg.ShowType == XEnumConst.THEATRE3.QuantumEffectShowType.QuantumA and (isA or isB) and isALine then
            FuncAddResult(cfg)
        elseif cfg.ShowType == XEnumConst.THEATRE3.QuantumEffectShowType.QuantumB and (isA or isB) and not isALine then
            FuncAddResult(cfg)
        end
    end
    return result
end

function XTheatre3Control:GetCfgQuantumEffectDescById(quantumEffectId)
    local cfg = self._Model:GetQuantumEffectCfg(quantumEffectId)
    return cfg and cfg.Desc
end

function XTheatre3Control:GetCfgQuantumEffectIsShakeById(quantumEffectId)
    local cfg = self._Model:GetQuantumEffectCfg(quantumEffectId)
    return cfg and XTool.IsNumberValid(cfg.IsShake)
end

function XTheatre3Control:GetCfgQuantumUpTxtByValue(isA, value)
    self:_InitCfgQuantumUpTxtDir()
    local idList = self._QuantumUpTxtDir[isA and XEnumConst.THEATRE3.QuantumType.QuantumA or XEnumConst.THEATRE3.QuantumType.QuantumB]
    local resultValue = 0
    if XTool.IsTableEmpty(idList) then
        return
    end
    for idValue, _ in pairs(idList) do
        if idValue <= value and idValue > resultValue then
            resultValue = idValue
        end
    end
    return self._Model:GetRandomQuantumUpTxtById(idList[resultValue]) 
end

function XTheatre3Control:_InitCfgQuantumUpTxtDir()
    if XTool.IsTableEmpty(self._QuantumUpTxtDir) then
        self._QuantumUpTxtDir[XEnumConst.THEATRE3.QuantumType.QuantumA] = {}
        self._QuantumUpTxtDir[XEnumConst.THEATRE3.QuantumType.QuantumB] = {}
        for _, cfg in ipairs(self._Model:GetQuantumUpTxtConfigs()) do
            self._QuantumUpTxtDir[cfg.QubitType][cfg.Value] = cfg.Id
        end
    end
end
--endregion

--region Cfg - ItemGroup

function XTheatre3Control:GetItemsByGroupId(groupId)
    return self._Model:GetItemsByGroupId(groupId)
end

function XTheatre3Control:GetItemGroupConfigById(id)
    return self._Model:GetItemGroupConfigById(id)
end

--endregion

--region Adventure - Logic
---@param isCheckContinue boolean 之前战斗结束后一定返回节点选择界面 2.13新增‘连战’ 战斗后还有后续内容 不能直接返回 为了避免和点击返回按钮的逻辑冲突 这里直接加了个新参数
---@return boolean
function XTheatre3Control:CheckAndOpenAdventureNextStep(isPopOpen, isNotCheckNodeSlot, isCheckContinue)
    if self._CacheQuantumData then
        self:CheckAdventureQuantumValueChange(function() 
            self:CheckAndOpenAdventureNextStep(isPopOpen, isNotCheckNodeSlot)
        end)
        return false
    end
    local isOpen = true
    ---@type XTheatre3Agency
    local theatre3Agency = XMVCA:GetAgency(ModuleId.XTheatre3)
    if theatre3Agency:CheckAndOpenSettle() then
        return false
    end
    local lostNodeSlot, lostNodeSlotStep = self:GetAdventureLastNodeSlot()
    local step = self:GetAdventureLastStepExcludeSpecialType()
    -- 商店买道具箱选择道具后可以开出装备箱，然后还得回到商店
    if not isNotCheckNodeSlot and lostNodeSlotStep == step and self:CheckAndOpenAdventureNodeSlot(lostNodeSlot, isPopOpen) then
        return isOpen
    end
    if not step then
        XLog.Error("Error! CurStep is null!")
        return false
    end
    self:AdventurePlayCurChapterBgm()
    if step:CheckStepType(XEnumConst.THEATRE3.StepType.RecruitCharacter) then
        self:OpenAdventureRoleRoom(isPopOpen, true, true)
    elseif step:CheckStepType(XEnumConst.THEATRE3.StepType.Node) then
        --新章节需要进入loading
        if self:IsNewAdventureChapter() then
            self._Model.ActivityData:SetIsNewChapter(false)
            self:OpenAdventureLoading(isPopOpen, self:GetAdventureCurChapterId())
        else
            if step:CheckIsSelected() and not step:CheckIsOver() and isCheckContinue then
                self:CheckAndOpenAdventureNodeSlot(lostNodeSlot, isPopOpen)
            else
                self:OpenAdventurePlayMain(isPopOpen)
            end
        end
    elseif step:CheckStepType(XEnumConst.THEATRE3.StepType.FightReward) then
        self:OpenAdventureRewardChoose(isPopOpen, false)
    elseif step:CheckStepType(XEnumConst.THEATRE3.StepType.ItemReward) then
        self:OpenAdventureRewardChoose(isPopOpen, true)
    elseif step:CheckStepType(XEnumConst.THEATRE3.StepType.WorkShop) then
        ---@type XTheatre3SetBagParam
        local param
        if step:CheckWorkShopType(XEnumConst.THEATRE3.WorkShopType.ExChange) then
            param = self:_CreateSetBagParam(nil, nil, true )
        elseif step:CheckWorkShopType(XEnumConst.THEATRE3.WorkShopType.Rebuild) then
            param = self:_CreateSetBagParam(nil, nil, nil, true)
        elseif step:CheckWorkShopType(XEnumConst.THEATRE3.WorkShopType.Qubit) then -- 选择装备量子化
            param = self:_CreateSetBagParam(nil, nil, nil, nil, true)
        end
        self:OpenAdventureWorkShop(isPopOpen, param)
    elseif step:CheckStepType(XEnumConst.THEATRE3.StepType.EquipReward) then
        if step:CheckEquipBoxType(XEnumConst.THEATRE3.EquipBoxType.Qubit) then -- 量子箱选择
            self:_OpenAdventureUi(isPopOpen, "UiTheatre3QuantumChoose", step:GetEquipIds())
        else
            self:_OpenAdventureUi(isPopOpen, "UiTheatre3EquipmentChoose", step:GetEquipIds())
        end
    elseif step:CheckStepType(XEnumConst.THEATRE3.StepType.EquipInherit) then
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3EquipmentChoose", step:GetEquipIds(), true)
    elseif step:CheckStepType(XEnumConst.THEATRE3.StepType.LuckyCharSelect) then
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3LuckyCharacter")
    elseif step:CheckStepType(XEnumConst.THEATRE3.StepType.PropSelect) then
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3PropChoose")
    else
        isOpen = false
    end
    return isOpen
end

---@param nodeSlot XTheatre3NodeSlot
---@return boolean
function XTheatre3Control:CheckAndOpenAdventureNodeSlot(nodeSlot, isPopOpen)
    if self._CacheQuantumData then
        self:CheckAdventureQuantumValueChange(function()
            self:CheckAndOpenAdventureNodeSlot(nodeSlot, isPopOpen)
        end)
        return false
    end
    local isOpen = true
    local isFightPass = nodeSlot and nodeSlot:CheckIsFight() and nodeSlot:CheckStageIsPass(self:GetFightStageTemplateStageId(nodeSlot:GetFightTemplateId()))
    if not nodeSlot or isFightPass then
        isOpen = false
    elseif nodeSlot:CheckType(XEnumConst.THEATRE3.NodeSlotType.Fight) then
        self:OpenAdventureRoleRoom(isPopOpen, true, false)
    elseif nodeSlot:CheckType(XEnumConst.THEATRE3.NodeSlotType.Event) then
        if nodeSlot:CheckIsFight() then
            self:OpenAdventureRoleRoom(isPopOpen, true, false)
        else
            self:OpenAdventureOutpost(isPopOpen, nodeSlot)
        end
    elseif nodeSlot:CheckType(XEnumConst.THEATRE3.NodeSlotType.Shop) then
        self:OpenAdventureOutpost(isPopOpen, nodeSlot)
    else
        isOpen = false
    end
    return isOpen
end

function XTheatre3Control:AdventurePlayCurChapterBgm()
    local chapterId = self:GetAdventureCurChapterId()
    if not XTool.IsNumberValid(chapterId) then
        return
    end
    local chapter = self:GetChapterById(chapterId)
    if chapter then
        self:AdventurePlayBgm(chapter.BgmCueId)
        self:PlayQuantumBGM(self:IsAdventureALine())
    end
end

function XTheatre3Control:AdventurePlayBgm(bgmCueId)
    if not XTool.IsNumberValid(bgmCueId) then
        return
    end
    if XLuaAudioManager.GetCurrentMusicId() == bgmCueId then
        return
    end
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, bgmCueId)
end

function XTheatre3Control:AdventureStart()
    self:_OpenAdventureSelectDifficulty()
end

function XTheatre3Control:AdventureContinue()
    if not self:IsHaveAdventure() then
        return
    end
    self:CheckAndOpenAdventureNextStep(false, true)
end

function XTheatre3Control:AdventureGiveUp(cb)
    if not self:IsHaveAdventure() then
        return
    end
    local title = XUiHelper.ReadTextWithNewLine("Theatre3GiveUpTitle")
    local content = XUiHelper.ReadTextWithNewLine("Theatre3GiveUpContent")
    self:OpenTextTip(function() self:RequestSettleAdventure(cb) end, title, content)
end
--endregion

--region Adventure - Data
---结算结束更新角色精通经验
function XTheatre3Control:UpdateSettleRoleExp()
    for _, characterInfo in pairs(self._Model.ActivityData:GetCharacterInfoList()) do
        local nowLevel, nowExp, _ = self:CalculateCharacterLevel(characterInfo.CharacterId, characterInfo.Level, characterInfo.Exp, characterInfo.ExpTemp)
        characterInfo:SetLevel(nowLevel)
        characterInfo:SetExp(nowExp)
        characterInfo:SetExpTemp(0)
    end
end

function XTheatre3Control:InitAdventureData()
    self._Model.ActivityData:InitAdventureData()
end

function XTheatre3Control:InitAdventureSettleData()
    self._Model.ActivityData:InitAdventureSettleData()
end

---@return XTheatre3Step
function XTheatre3Control:GetAdventureLastStep(type)
    local chapterDb = self:GetAdventureCurChapterDb()
    return chapterDb:GetLastStep(type)
end

function XTheatre3Control:_GetLastAdventureSelectEquip()
    local chapterDb = self:GetAdventureCurChapterDb()
    local step = chapterDb:GetLastStep(XEnumConst.THEATRE3.StepType.EquipReward)
    if not step then
        step = chapterDb:GetLastStep(XEnumConst.THEATRE3.StepType.EquipInherit)
    end
    return step
end

---@return XTheatre3Step
function XTheatre3Control:GetAdventureLastStepExcludeSpecialType()
    local step
    local chapterDb = self:GetAdventureCurChapterDb()
    step = chapterDb:GetLastStep(XEnumConst.THEATRE3.StepType.EquipReward)
    if not step then
        step = chapterDb:GetLastStep(XEnumConst.THEATRE3.StepType.EquipInherit)
    end
    if step then
        return step
    end
    return chapterDb:GetLastStep()
end

---@return XTheatre3NodeSlot, XTheatre3Step
function XTheatre3Control:GetAdventureLastNodeSlot()
    local chapterDb = self:GetAdventureCurChapterDb()
    return chapterDb:GetLastNodeSlot()
end

function XTheatre3Control:GetAdventureCurChapterDb()
    return self._Model.ActivityData:GetCurChapterDb()
end

function XTheatre3Control:GetAdventureCurDifficultyId()
    return self._Model.ActivityData:GetDifficultyId()
end

function XTheatre3Control:GetAdventureCurChapterId()
    return self._Model.ActivityData:GetCurChapterId()
end

---@return XTheatre3Item[]
function XTheatre3Control:GetAdventureCurItemList()
    return self._Model.ActivityData:GetAdventureItemList()
end

function XTheatre3Control:GetAdventureCurItemCount()
    local result = 0
    for _, itemData in ipairs(self:GetAdventureCurItemList()) do
        if self:IsAdventureItemLive(itemData) then
            result = result + 1
        end
    end
    return result
end

function XTheatre3Control:GetAdventureCurEquipSuitCount()
    return self._Model.ActivityData:GetAllEquipSuitCount()
end

function XTheatre3Control:GetAdventureStepSelectItemList()
    local lastStep = self:GetAdventureLastStep()
    return lastStep and lastStep:GetItemIds() or {}
end

function XTheatre3Control:GetAdventureStepSelectEquipsList()
    local lastStep = self:GetAdventureLastStep()
    return lastStep and lastStep:GetEquipIds() or {}
end

---@return XTheatre3NodeReward[]
function XTheatre3Control:GetAdventureStepSelectRewardList()
    local lastStep = self:GetAdventureLastStep()
    if XTool.IsTableEmpty(lastStep) then
        return {}
    end
    -- 以下所有均只是为了一个困难标签
    local result = lastStep:GetFightRewards()
    local stepRootUid = lastStep:GetRootUid()
    local rootStep = self._Model.ActivityData:GetCurChapterDb():GetStepByUid(stepRootUid)
    if rootStep then
        local nodeSlot = rootStep:GetLastNodeSlot()
        local fightId = nodeSlot and nodeSlot:GetFightId()
        local fightNodeCfg = XTool.IsNumberValid(fightId) and self._Model:GetFightNodeCfgById(fightId)
        if fightNodeCfg and fightNodeCfg.Difficulty == 2 then
            for _, reward in ipairs(result) do
                if self:_CheckNodeRewardIsDifficulty(reward, fightNodeCfg) then
                    reward:SetTag(XEnumConst.THEATRE3.NodeRewardTag.Difficulty)
                end
            end
        end
    end
    return result or {}
end

---@param reward XTheatre3NodeReward
---@param fightNodeCfg XTableTheatre3FightNode
function XTheatre3Control:_CheckNodeRewardIsDifficulty(reward, fightNodeCfg)
    if reward:CheckType(XEnumConst.THEATRE3.NodeRewardType.Gold) then
        for _, id in pairs(fightNodeCfg.GoldIds) do
            if reward:GetConfigId() == id then
                return true
            end
        end
    end
    if reward:CheckType(XEnumConst.THEATRE3.NodeRewardType.ItemBox) then
        for _, id in pairs(fightNodeCfg.ItemBoxIds) do
            if reward:GetConfigId() == id then
                return true
            end
        end
    end
    if reward:CheckType(XEnumConst.THEATRE3.NodeRewardType.EquipBox) then
        for _, id in pairs(fightNodeCfg.EquipBoxIds) do
            if reward:GetConfigId() == id then
                return true
            end
        end
    end
    return false
end

function XTheatre3Control:GetAdventureSlotDataList()
    return self._Model.ActivityData:GetSlotInfoList()
end

function XTheatre3Control:GetAdventureItemCount(itemId)
    local result = 0
    local itemDataList = self:GetAdventureCurItemList()
    for i, itemData in ipairs(itemDataList) do
        if self:IsAdventureItemLive(itemData) and (not XTool.IsNumberValid(itemId) or itemData.ItemId == itemId) then
            result = result + 1
        end
    end
    return result
end

function XTheatre3Control:SetAdventureStepSelectItem(id)
    local lastStep = self:GetAdventureLastStep()
    if lastStep then
        lastStep:UpdateItemSelectId(id)
    end
end

function XTheatre3Control:SetAdventureStepSelectEquip(id)
    local lastStep = self:GetAdventureLastStep()
    if lastStep then
        lastStep:UpdateEquipSelectId(id)
    end
end
--endregion

--region Adventure - Checker
function XTheatre3Control:IsHavePassAdventure()
    return self._Model.ActivityData:CheckHasFirstPassFlag()
end

function XTheatre3Control:IsHaveAdventure()
    return self._Model:IsHaveAdventure()
end

function XTheatre3Control:IsNewAdventureChapter()
    return self._Model.ActivityData:IsNewChapterId()
end

function XTheatre3Control:IsAdventureHaveFightReward()
    for _, reward in pairs(self:GetAdventureStepSelectRewardList()) do
        if not reward:CheckIsReceived() then
            return true
        end
    end
    return false
end

function XTheatre3Control:IsDifficultyUnlock(difficultyId)
    if not self._Model.ActivityData then
        return false
    end
    return self._Model.ActivityData:CheckDifficultyIdUnlock(difficultyId)
end

---@param itemData XTheatre3Item
function XTheatre3Control:IsAdventureItemLive(itemData)
    local cfg = self._Model:GetItemConfigById(itemData.ItemId)
    if XTool.IsNumberValid(cfg.ExpireTime) then
        return itemData.Live < cfg.ExpireTime
    end
    return true
end
--endregion

--region Adventure - Ui Control
function XTheatre3Control:RegisterClickEvent(table, component, handle, clear)
    XUiHelper.RegisterClickEvent(table, component, handle, clear, true)
end

function XTheatre3Control:CheckAndOpenQuantumOpen(cb)
    local conditionId = self:GetClientConfigNumber("QuantumOpenTipCondition")
    if not XTool.IsNumberValid(conditionId) then
        return
    end
    local isTrue, _ = XConditionManager.CheckCondition(conditionId)
    if isTrue and not self:CheckIsNotOpenQuantumIsTip() then
        XLuaUiManager.Open("UiTheatre3NewFunction", cb)
        return true
    end
end

function XTheatre3Control:OpenAdventureProp()
    self:RequestLookEquipAttribute(nil, nil, function()
        if self:IsAdventureALine() then
            XLuaUiManager.Open("UiTheatre3Prop")
        else
            XLuaUiManager.Open("UiTheatre3QuantumProp")
        end
    end)
end

function XTheatre3Control:OpenAdventureFightResult()
    if self:IsAdventureALine() then
        XLuaUiManager.Open("UiTheatre3FightResult")
    else
        XLuaUiManager.Open("UiTheatre3QuantumFightResult")
    end
end

function XTheatre3Control:OpenAdventureRoleRoom(isPopOpen, isBattle,isStartAdventure)
    if self:IsAdventureALine() then
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3RoleRoom", isBattle,isStartAdventure)
    else
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3QuantumRoleRoom", isBattle,isStartAdventure)
    end
end

function XTheatre3Control:OpenAdventureTeamInstall()
    if self:IsAdventureALine() then
        XLuaUiManager.Open("UiTheatre3TeamInstall")
    else
        XLuaUiManager.Open("UiTheatre3QuantumTeamInstall")
    end
end

function XTheatre3Control:OpenTextTip(sureCb, title, content, closeCb, key, exData)
    if self:IsAdventureALine() then
        XLuaUiManager.Open("UiTheatre3EndTips", sureCb, title, content, closeCb, key, exData)
    else
        XLuaUiManager.Open("UiTheatre3EndTips2", sureCb, title, content, closeCb, key, exData)
    end
end

function XTheatre3Control:OpenQuantumTextTip(sureCb, title, content, closeCb, key, exData)
    XLuaUiManager.Open("UiTheatre3EndTips2", sureCb, title, content, closeCb, key, exData)
end

---@param nodeSlot XTheatre3NodeSlot
function XTheatre3Control:OpenAdventureOutpost(isPopOpen, nodeSlot)
    self:AdventurePlayCurChapterBgm()
    if nodeSlot.SlotType == XEnumConst.THEATRE3.NodeSlotType.Shop and XTool.IsNumberValid(nodeSlot:GetShopId()) then
        local shopCfg = self:GetShopNodeCfgById(nodeSlot:GetShopId())
        if shopCfg.ShopType == XEnumConst.THEATRE3.ShopType.GiveMoney then
            -- 给钱商店都用LineB那种样式
            self:_OpenAdventureUi(isPopOpen, "UiTheatre3QuantumOutpost", nodeSlot)
            return
        end
    end
    if self:IsAdventureALine() then
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3Outpost", nodeSlot)
    else
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3QuantumOutpost", nodeSlot)
    end
end

function XTheatre3Control:OpenAdventureLoading(isPopOpen, chapterId)
    if self:IsAdventureALine() then
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3Loading", chapterId)
    else
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3QuantumLoading", chapterId)
    end
end

function XTheatre3Control:OpenAdventurePlayMain(isPopOpen, isSwitch)
    if self:IsAdventureALine() then
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3PlayMain", isSwitch)
    else
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3QuantumPlayMain", isSwitch)
    end
end

function XTheatre3Control:OpenAdventureRewardChoose(isPopOpen, isProp)
    if self:IsAdventureALine() then
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3RewardChoose", isProp)
    else
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3QuantumRewardChoose", isProp)
    end
end

---@param param XTheatre3SetBagParam
function XTheatre3Control:OpenAdventureWorkShop(isPopOpen, param)
    if param.isQuantumEquip then
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3Quantization", param)
        return
    end
    if self:IsAdventureALine() then
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3SetBag", param)
    else
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3Quantization", param)
    end
end

function XTheatre3Control:OpenAdventureTips(templateId, itemType, customData, closeCb)
    if self:IsAdventureALine() then
        self:_OpenAdventureUi(false, "UiTheatre3Tips", templateId, itemType, customData, closeCb)
    else
        self:_OpenAdventureUi(false, "UiTheatre3QuantumTips", templateId, itemType, customData, closeCb)
    end
end

function XTheatre3Control:OpenAdventureTipReward(rewardGoodsList, innerItemList, closeCb)
    if self:IsAdventureALine() then
        XLuaUiManager.Open("UiTheatre3TipReward", rewardGoodsList, innerItemList, closeCb)
    else
        XLuaUiManager.Open("UiTheatre3QuantumTipReward", rewardGoodsList, innerItemList, closeCb)
    end
end

function XTheatre3Control:OpenAdventureShopTips(isMoneyShop, shopItem, closeCb, sureCb)
    if self:IsAdventureALine() then
        self:_OpenAdventureUi(false, "UiTheatre3ShopTips", isMoneyShop, shopItem, closeCb, sureCb)
    else
        self:_OpenAdventureUi(false, "UiTheatre3QuantumShopTips", isMoneyShop, shopItem, closeCb, sureCb)
    end
end

function XTheatre3Control:OpenAdventureEquipDetail(equipId, isNotShowCurTag, isQuantum)
    XLuaUiManager.Open("UiTheatre3SetDetail", equipId, isNotShowCurTag, isQuantum)
end

function XTheatre3Control:_OpenAdventureSelectDifficulty()
    XLuaUiManager.Open("UiTheatre3Difficulty")
end

function XTheatre3Control:_OpenAdventureUi(isPopOpen, uiName, ...)
    if isPopOpen then
        XLuaUiManager.PopThenOpen(uiName, ...)
    else
        XLuaUiManager.Open(uiName, ...)
    end
end
--endregion

--region Adventure - Equip
function XTheatre3Control:GetAdventureSuitDesc(suitId, isDetail)
    local suitConfig = self:GetSuitById(suitId)
    local desc = isDetail and suitConfig.Desc or suitConfig.SimpleEffectDesc
    desc = XUiHelper.FormatText(desc, self:GetSuitEffectGroupDesc(suitId))
    return XUiHelper.ReplaceUnicodeSpace(XUiHelper.ReplaceTextNewLine(desc))
end

function XTheatre3Control:GetAdventureQuantumSuitDesc(suitId, isDetail)
    local suitConfig = self:GetSuitById(suitId)
    local desc = isDetail and suitConfig.QubitDesc or suitConfig.QubitSampleEffectDesc
    desc = XUiHelper.FormatText(desc, self:GetSuitEffectGroupDesc(suitId))
    return XUiHelper.ReplaceUnicodeSpace(XUiHelper.ReplaceTextNewLine(desc))
end

function XTheatre3Control:GetAdventureQuantumTraitDesc(suitId, index)
    local suitConfig = self:GetSuitById(suitId)
    return XUiHelper.ReplaceUnicodeSpace(XUiHelper.ReplaceTextNewLine(suitConfig.QubitTraitDesc[index]))
end

function XTheatre3Control:GetAdventureTraitDesc(suitId, index)
    local suitConfig = self:GetSuitById(suitId)
    return XUiHelper.ReplaceUnicodeSpace(XUiHelper.ReplaceTextNewLine(suitConfig.TraitDesc[index]))
end

function XTheatre3Control:CheckAdventureEquipIsQuantum(equipId)
    return self._Model.ActivityData and self._Model.ActivityData:CheckIsQuantumByEquipId(equipId)
end

function XTheatre3Control:CheckAdventureSuitIsQuantum(suitId)
    if not XTool.IsNumberValid(suitId) then
        return false
    end
    return self._Model.ActivityData and self._Model.ActivityData:CheckIsQuantumBySuitId(suitId)
end
--endregion

--region Adventure - WorkShop
function XTheatre3Control:GetWorkshopCount()
    local step = self:GetAdventureLastStep()
    if not step then
        return 0, 0
    end
    return step.WorkShopCurCount, step.WorkShopTotalCount
end

function XTheatre3Control:IsWorkshopHasTimes()
    local step = self:GetAdventureLastStep()
    if not step then
        return false
    end
    return step.WorkShopCurCount < step.WorkShopTotalCount
end

function XTheatre3Control:WorkShopReduceTimes()
    local step = self:GetAdventureLastStep()
    if step then
        step:UpdateWorkShopTimes(step.WorkShopCurCount + 1)
    end
end
--endregion

--region Adventure - Quantum
function XTheatre3Control:GetAdventureQuantumValue(isA)
    return self._Model.ActivityData:GetQuantumValue(isA)
end

function XTheatre3Control:SetCacheQuantumValueData(isChangeA, IsChangeB, isLevelUp)
    if XTool.IsTableEmpty(self._CacheQuantumData) then
        ---@type XUiTheatre3PanelQuantumData
        self._CacheQuantumData = {}
    end
    self._CacheQuantumData.AValue = self:GetAdventureQuantumValue(true)
    self._CacheQuantumData.BValue = self:GetAdventureQuantumValue(false)
    self._CacheQuantumData.IsChangeA = self._CacheQuantumData.IsChangeA or isChangeA
    self._CacheQuantumData.IsChangeB = self._CacheQuantumData.IsChangeB or IsChangeB
    self._CacheQuantumData.IsLevelUp = self._CacheQuantumData.IsLevelUp or isLevelUp
    self._CacheQuantumData.QuantumLevelCfg = self:GetCfgQuantumLevelByValue(self._CacheQuantumData.AValue + self._CacheQuantumData.BValue)
    self._CacheQuantumData.QuantumEffectDescList = self:GetCfgQuantumEffectListByValue(self._CacheQuantumData.AValue, self._CacheQuantumData.BValue)
    self._CacheQuantumData.QuantumAShowPuzzleList = self:GetCfgQuantumShowPuzzleListByValue(self._CacheQuantumData.AValue, XEnumConst.THEATRE3.QuantumType.QuantumA)
    self._CacheQuantumData.QuantumBShowPuzzleList = self:GetCfgQuantumShowPuzzleListByValue(self._CacheQuantumData.BValue, XEnumConst.THEATRE3.QuantumType.QuantumB)
end

function XTheatre3Control:CheckAdventureQuantumValueChange(cb)
    if XTool.IsTableEmpty(self._CacheQuantumData) then
        return
    end
    if not self._CacheQuantumData.IsChangeA and not self._CacheQuantumData.IsChangeB then
        return
    end
    if self._CacheQuantumData.IsLevelUp then
        local resultTxt = self._Model:GetQuantumLevelUpTxtByValue(self._CacheQuantumData.AValue + self._CacheQuantumData.BValue)
        XLuaUiManager.Open("UiTheatre3QuantumLevelUp", self._CacheQuantumData, resultTxt, nil, nil, cb)
        self._CacheQuantumData = nil
        return
    end
    local aResultTxt, bResultTxt
    if self._CacheQuantumData.IsChangeA then
        aResultTxt = self:GetCfgQuantumUpTxtByValue(true, self._CacheQuantumData.AValue)
    end
    if self._CacheQuantumData.IsChangeB then
        bResultTxt = self:GetCfgQuantumUpTxtByValue(false, self._CacheQuantumData.BValue)
    end
    XLuaUiManager.Open("UiTheatre3QuantumLevelUp", self._CacheQuantumData, nil, aResultTxt, bResultTxt, cb)
    self._CacheQuantumData = nil
end

function XTheatre3Control:IsAdventureALine()
    return self._Model:IsAdventureALine()
end
--endregion

--region Adventure - BuffDesc
function XTheatre3Control:GetEquipEffectGroupDesc(equipId)
    local effectGroupId = self._Model:GetEquipById(equipId).EffectGroupId
    local type = self._Model:GetEffectGroupDescCfgType(effectGroupId)
    if not type then
        return ""
    end
    return self:_GetEffectGroupDesc(effectGroupId, self:_GetEffectGroupParamList(type, equipId))
end

function XTheatre3Control:GetSuitEffectGroupDesc(suitId)
    local suitEffectGroupId = self._Model:GetSuitById(suitId).SuitEffectGroupId
    local effectGroupId = self._Model:GetSuitEffectGroupById(suitEffectGroupId).EffectGroupId

    local type = self._Model:GetEffectGroupDescCfgType(effectGroupId)
    if not type then
        return ""
    end
    return self:_GetEffectGroupDesc(effectGroupId, self:_GetEffectGroupParamList(type, nil, suitId))
end

function XTheatre3Control:GetItemEffectGroupDesc(itemId)
    local effectGroupId = self._Model:GetItemConfigById(itemId).EffectGroupId
    local type = self._Model:GetEffectGroupDescCfgType(effectGroupId)
    if not type then
        return ""
    end
    return self:_GetEffectGroupDesc(effectGroupId, self:_GetEffectGroupParamList(type))
end

---@return number[]
function XTheatre3Control:_GetEffectGroupParamList(type, equipId, suitId)
    local result = {}
    if type == XEnumConst.THEATRE3.EffectGroupDescType.PassNode then
        local adventureEffectDesc = self._Model.ActivityData:GetAdventureEffectDescData()
        if adventureEffectDesc then
            if XTool.IsNumberValid(equipId) then
                table.insert(result, adventureEffectDesc:GetEquipPassNodeCount(equipId))
                return result
            end
            if XTool.IsNumberValid(suitId) then
                table.insert(result, adventureEffectDesc:GetSuitPassNodeCount(equipId))
                return result
            end
        end
        return result
    elseif type == XEnumConst.THEATRE3.EffectGroupDescType.BuyCount then
        local adventureEffectDesc = self._Model.ActivityData:GetAdventureEffectDescData()
        if adventureEffectDesc then
            table.insert(result, adventureEffectDesc:GetItemBuyCount())
        end
        return result
    elseif type == XEnumConst.THEATRE3.EffectGroupDescType.ItemCount then
        return { self:GetAdventureCurItemCount() }
    elseif type == XEnumConst.THEATRE3.EffectGroupDescType.CollectSuit then
        local count = 0
        for i = 1, 3 do
            for suit, _ in ipairs(self._Model.ActivityData:GetAdventureSuitList(i)) do
                if self:IsSuitComplete(suit) then
                    count = count + 1
                end
            end
        end
        table.insert(result, count)
        return result
    elseif type == XEnumConst.THEATRE3.EffectGroupDescType.FightAndBoss then
        local adventureEffectDesc = self._Model.ActivityData:GetAdventureEffectDescData()
        if XTool.IsTableEmpty(adventureEffectDesc) then
            return result
        end
        if XTool.IsNumberValid(equipId) then
            table.insert(result, adventureEffectDesc:GetEquipPassFightCount(equipId))
            table.insert(result, adventureEffectDesc:GetEquipPassBossFightCount(equipId))
            return result
        end
        if XTool.IsNumberValid(suitId) then
            table.insert(result, adventureEffectDesc:GetSuitPassFightCount(suitId))
            table.insert(result, adventureEffectDesc:GetSuitPassBossFightCount(suitId))
            return result
        end
        return result
    end
end

---@param paramList number[]
function XTheatre3Control:_GetEffectGroupDesc(effectGroupId, paramList)
    return self._Model:GetEffectGroupDescByIndex(effectGroupId, paramList)
end
--endregion

--region Adventure - FightResult
function XTheatre3Control:GetAdventureFightRecordCharacter(slotId)
    return self:GetSlotCharacter(slotId)
end

function XTheatre3Control:GetAdventureFightRecordSuitList(slotId)
    local fightRecord = self._Model.ActivityData:GetAdventureFightRecord()
    local equipList = { }
    if not fightRecord then
        return equipList
    end
    local characterId = self:GetAdventureFightRecordCharacter(slotId)
    if not fightRecord:CheckIsHaveNowRecord(characterId) then
        return equipList
    end
    
    for _, suitId in ipairs(self:GetSlotSuits(slotId)) do
        local magicIdList = self:GetCfgEquipDamageMagicId2SuitIdDir(suitId)
        local prevValue, nowValue = self:_GetAdventureFightResultByCharacterId(characterId, suitId)
        if fightRecord:CheckNowRecordIsHaveMagic(characterId, magicIdList)
            and (XTool.IsNumberValid(prevValue) or XTool.IsNumberValid(nowValue)) 
        then
            equipList[#equipList + 1] = suitId
        end
    end
    if XTool.IsTableEmpty(equipList) then
        return equipList
    end
    table.sort(equipList, function(a, b)
        local _, nowA = self:_GetAdventureFightResultByCharacterId(characterId, a)
        local _, nowB = self:_GetAdventureFightResultByCharacterId(characterId, b)
        return nowA > nowB
    end)
    return equipList
end

function XTheatre3Control:GetAdventureFightResultBySlotId(slotId)
    local characterId = self:GetAdventureFightRecordCharacter(slotId)
    local suitList = self:GetSlotSuits(slotId)
    local prevValue = 0
    local nowValue = 0
    if XTool.IsNumberValid(characterId) and not XTool.IsTableEmpty(suitList) then
        for _, suitId in ipairs(suitList) do
            local now, prev = self:_GetAdventureFightResultByCharacterId(characterId, suitId)
            nowValue = nowValue + now
            prevValue = prevValue + prev
        end
    end
    return nowValue, prevValue
end

function XTheatre3Control:GetAdventureFightResultByEquipSuitId(slotId, equipSuitId)
    local characterId = self:GetAdventureFightRecordCharacter(slotId)
    return self:_GetAdventureFightResultByCharacterId(characterId, equipSuitId)
end

function XTheatre3Control:_GetAdventureFightResultByCharacterId(characterId, equipSuitId)
    local fightRecord = self._Model.ActivityData:GetAdventureFightRecord()
    local magicIdList = self:GetCfgEquipDamageMagicId2SuitIdDir(equipSuitId)
    local prevValue = 0
    local nowValue = 0
    if not fightRecord or XTool.IsTableEmpty(magicIdList) then
        return nowValue, prevValue
    end
    for _, magicId in ipairs(magicIdList) do
        local n, p = fightRecord:GetCharacterMagicDamageRecordData(characterId, magicId)
        prevValue = prevValue + p
        nowValue = nowValue + n
    end
    return nowValue, prevValue
end
--endregion

--region Adventure - LuckCharacter
function XTheatre3Control:GetAdventureLuckCharacterSelectList()
    return self:GetAdventureLastStep():GetLuckCharacterIdList()
end
--endregion

--region Adventure - ConnectChapter
function XTheatre3Control:GetAdventureOtherChapterId()
    return self:GetAdventureCurChapterDb():GetOtherChapterId(self:GetAdventureCurChapterId())
end

function XTheatre3Control:CheckAdventureSwitchChapterIdIsShow()
    return self._Model.ActivityData:IsCanSwitchChapter() and not self:CheckAdventureSwitchAChapterIdIsLock()
end

function XTheatre3Control:CheckAdventureQuantumIsShow()
    local aValue = self:GetAdventureQuantumValue(true)
    local bValue = self:GetAdventureQuantumValue(false)
    return XTool.IsNumberValid(aValue) or XTool.IsNumberValid(bValue)
end

function XTheatre3Control:CheckAdventureSwitchAChapterIdIsLock()
    if self:IsAdventureALine() then
        return false
    end
    local conditionId = self:GetClientConfigNumber("ToALineCloseCondition")
    if XTool.IsNumberValid(conditionId) then
        local isTrue, _ = XConditionManager.CheckCondition(conditionId)
        return not isTrue
    end
    return false
end
--endregion

--region 装备箱刷新

---@return XTableTheatre3EquipBox
function XTheatre3Control:GetCurEquipBoxConfig()
    local step = self:GetAdventureLastStep(XEnumConst.THEATRE3.StepType.EquipReward)
    if step then
        return self._Model:GetEquipBoxById(step:GetEquipBoxId())
    end
    return nil
end

function XTheatre3Control:GetTotalRefreshTimes()
    local step = self:GetAdventureLastStep(XEnumConst.THEATRE3.StepType.EquipReward)
    if step then
        local times = step:GetFreeRefreshLimit() + self:GetCurEquipBoxConfig().RefreshCostNum
        local refreshTime = step:GetRefreshTimes()
        return times - refreshTime, times
    end
end

function XTheatre3Control:GetFreeRefreshTimes()
    local step = self:GetAdventureLastStep(XEnumConst.THEATRE3.StepType.EquipReward)
    if step then
        local totalFreeTimes = step:GetFreeRefreshLimit()
        local refreshTime = step:GetRefreshTimes()
        if refreshTime <= totalFreeTimes then
            return totalFreeTimes - refreshTime, totalFreeTimes
        else
            return 0, totalFreeTimes
        end
    end
    return 0, 0
end

function XTheatre3Control:GetPayRefreshTimes()
    local step = self:GetAdventureLastStep(XEnumConst.THEATRE3.StepType.EquipReward)
    if step then
        local totalPayTimes = self:GetCurEquipBoxConfig().RefreshCostNum
        local totalFreeTimes = step:GetFreeRefreshLimit()
        local refreshTime = step:GetRefreshTimes()
        if refreshTime <= totalFreeTimes then
            return totalPayTimes, totalPayTimes
        else
            return totalPayTimes - (refreshTime - totalFreeTimes), totalPayTimes
        end
    end
    return 0, 0
end

function XTheatre3Control:GetPayRefreshCost()
    local step = self:GetAdventureLastStep(XEnumConst.THEATRE3.StepType.EquipReward)
    if step then
        local payRefreshTimes = step:GetRefreshTimes() - step:GetFreeRefreshLimit()
        if payRefreshTimes < 0 then
            return true, 0
        end
        local config = self:GetCurEquipBoxConfig()
        local costNum = math.floor(config.RefreshCost[math.min(payRefreshTimes + 1, #config.RefreshCost)] * (1 - step:GetDiscount()))
        return XDataCenter.ItemManager.GetCount(XEnumConst.THEATRE3.RefreshBoxCoin) >= costNum, costNum
    end
    return false, 0
end

function XTheatre3Control:CheckRefreshEquipBox()
    local step = self:GetAdventureLastStep(XEnumConst.THEATRE3.StepType.EquipReward)
    if not step then
        return false
    end
    local freeTimes = self:GetFreeRefreshTimes()
    local payTimes = self:GetPayRefreshTimes()
    local isCanPayRefresh = self:GetPayRefreshCost()
    if freeTimes <= 0 and payTimes <= 0 then
        return false
    end
    if freeTimes <= 0 and not isCanPayRefresh then
        XUiManager.TipText("Theatre3RefreshBoxTip")
        return false
    end
    return true
end

--endregion

--region 压力值

function XTheatre3Control:GetHistoryPressureValue()
    return self._Model.ActivityData:GetFireItemCount()
end

function XTheatre3Control:GetCurPressureValue()
    local value = 0
    local items = self:GetAdventureCurItemList()
    for _, item in pairs(items) do
        local config = self:GetItemConfigById(item.ItemId)
        if XTool.IsNumberValid(config.FireNum) then
            value = value + config.FireNum
        end
    end
    return value
end

function XTheatre3Control:GetPressureIcon(value, isCheckAdventure)
    local isAdventure = true
    if isCheckAdventure then
        isAdventure = self:IsAdventureALine()
    end
    local pressureIconMap = self:GetClientConfigs(isAdventure and "PressureIconMap" or "PressureRedIconMap")
    local pressureIcon = pressureIconMap[#pressureIconMap - 1]
    for i = 1, #pressureIconMap / 2 do
        if value <= tonumber(pressureIconMap[i * 2]) then
            pressureIcon = pressureIconMap[i * 2 - 1]
        end
    end
    return pressureIcon
end

--endregion

return XTheatre3Control