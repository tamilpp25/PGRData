---@class XTheatre3ReqCDData
---@field RecordTime number
---@field RecordData number[]

---@class XTheatre3Control : XControl
---@field _Model XTheatre3Model
local XTheatre3Control = XClass(XControl, "XTheatre3Control")

local RequestProto = {
    Theatre3ActivationStrengthenTreeRequest = "Theatre3ActivationStrengthenTreeRequest", -- 激活天赋树
    Theatre3GetBattlePassRewardRequest = "Theatre3GetBattlePassRewardRequest",  -- 领取奖励
    --Adventure
    Theatre3SettleAdventureRequest = "Theatre3SettleAdventureRequest",          -- 放弃冒险
    Theatre3SelectDifficultyRequest = "Theatre3SelectDifficultyRequest",        -- 进入冒险选择难度
    Theatre3EndRecruitRequest = "Theatre3EndRecruitRequest",                    -- 结束开局编队
    Theatre3SelectNodeRequest = "Theatre3SelectNodeRequest",                    -- 选择节点
    Theatre3SelectItemRewardRequest = "Theatre3SelectItemRewardRequest",        -- 选择开道具箱奖励，3选1
    Theatre3NodeShopBuyItemRequest = "Theatre3NodeShopBuyItemRequest",          -- 局内商店购买
    Theatre3EndNodeRequest = "Theatre3EndNodeRequest",                          -- 结束节点，商店节点
    Theatre3EventNodeNextStepRequest = "Theatre3EventNodeNextStepRequest",      -- 事件，下一步，选择选项
    Theatre3RecvFightRewardRequest = "Theatre3RecvFightRewardRequest",          -- 战斗结束—打开战斗奖励选择界面—领取战斗奖励
    Theatre3EndRecvFightRewardRequest = "Theatre3EndRecvFightRewardRequest",    -- 战斗结束—打开战斗奖励选择界面—领取战斗奖励-结束领取
    Theatre3SelectEquipRequest = "Theatre3SelectEquipRequest",                  -- 选择装备
    Theatre3ChangeEquipPosRequest = "Theatre3ChangeEquipPosRequest",            -- 装备换位置
    Theatre3RecastEquipRequest = "Theatre3RecastEquipRequest",                  -- 重铸装备
    Theatre3SetTeamRequest = "Theatre3SetTeamRequest",                          -- 设置队伍
    Theatre3EndWorkShopRequest = "Theatre3EndWorkShopRequest",                  -- 事件—工坊—结束工坊—事件下一步
    Theatre3EndEquipBoxRequest = "Theatre3EndEquipBoxRequest",                  -- 结束装备箱事件
    Theatre3LookEquipAttributeRequest = "Theatre3LookEquipAttributeRequest",    -- 内循环查看装备数据
}

function XTheatre3Control:OnInit()
    --初始化内部变量
    ---@type XTheatre3ReqCDData[]
    self._ReqCdDir = {}
end

function XTheatre3Control:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
    
end

function XTheatre3Control:RemoveAgencyEvent()

end

function XTheatre3Control:OnRelease()
    -- 这里执行Control的释放
    self._ReqCdDir = {}
end

--region 活动相关

function XTheatre3Control:GetActivityName()
    local config = self._Model:GetActivityConfig()
    if not config then
        return ""
    end
    return config.Name or ""
end

--endregion

--region BP奖励相关

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

--region Config表相关

function XTheatre3Control:GetShareConfig(key)
    return self._Model:GetShareConfig(key)
end

function XTheatre3Control:GetClientConfig(key, index)
    if not index then
        index = 1
    end
    return self._Model:GetClientConfig(key, index)
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
        return XGoodsCommonManager.GetGoodsIcon(itemId)
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
    for _, v in pairs(self._Model.ActivityData.Equips) do
        if v.EquipIdsMap[equipId] then
            return v.SlotId
        end
    end
    return -1
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

function XTheatre3Control:GetWorkshopCount()
    local step = self:GetAdventureCurChapterDb():GetLastStep()
    return step.WorkShopCurCount, step.WorkShopTotalCount
end

function XTheatre3Control:IsWorkshopHasTimes()
    local step = self:GetAdventureCurChapterDb():GetLastStep()
    return step.WorkShopCurCount < step.WorkShopTotalCount
end

function XTheatre3Control:WorkShopReduceTimes()
    local step = self:GetAdventureCurChapterDb():GetLastStep()
    step:UpdateWorkShopTimes(step.WorkShopCurCount + 1)
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
    XLuaUiManager.Open("UiTheatre3BubbleEquipment", param)
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
    if isAdventure then
        local cfg = self:GetEquipById(equipId)
        self:RequestLookEquipAttribute(equipId, cfg.SuitId, function()
            XLuaUiManager.Open("UiTheatre3BubbleEquipment", param, true)
        end)
    else
        XLuaUiManager.Open("UiTheatre3BubbleEquipment", param)
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

---打开装备选择界面
---@param equipIds number[] 装备Id
---@param Inherit boolean 是否装备继承
function XTheatre3Control:OpenChooseEquipPanel(equipIds, Inherit)
    XLuaUiManager.Open("UiTheatre3EquipmentChoose", equipIds, Inherit)
end

---打开交换套装界面
function XTheatre3Control:OpenExchangeSuitPanel()
    XLuaUiManager.Open("UiTheatre3SetBag", { isChooseSuit = true })
end

---打开装备重铸界面
function XTheatre3Control:OpenRebuildEquipPanel()
    XLuaUiManager.Open("UiTheatre3SetBag", { isChooseEquip = true })
end

---打开展示套装界面
function XTheatre3Control:OpenShowEquipPanel(suitId)
    XLuaUiManager.Open("UiTheatre3SetBag", { isShowEquip = true, autoSelectSuitId = suitId })
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
function XTheatre3Control:GetStrengthenTreeIdList()
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
    local strengthenTreeIdList = self:GetStrengthenTreeIdList()
    for _, id in pairs(strengthenTreeIdList) do
        if self:CheckStrengthenTreeRedPoint(id) then
            return true
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

--region Buff - Desc
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
        return { #self:GetAdventureCurItemList() }
    elseif type == XEnumConst.THEATRE3.EffectGroupDescType.CollectSuit then
        local count = 0
        for i = 1, 3 do
            for _, suit in ipairs(self._Model.ActivityData:GetAdventureSuitList(i)) do
                if self:IsSuitComplete(suit) then
                    count = count + 1
                end
            end
        end
        table.insert(result, count)
        return result
    elseif type == XEnumConst.THEATRE3.EffectGroupDescType.FightAndBoss then
        local adventureEffectDesc = self._Model.ActivityData:GetAdventureEffectDescData()
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

--region 音效相关

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
    local cueId = self:GetClientConfig("Theatre3GetRewardSound", targetIndex)
    cueId = tonumber(cueId) or 0
    if XTool.IsNumberValid(cueId) then
        XSoundManager.PlaySoundByType(cueId, XSoundManager.SoundType.Sound)
    end
end

--endregion

--region 本地数据相关
    
function XTheatre3Control:GetStrengthenTreeSelectIndexKey()
    return string.format("Theatre3StrengthenTreeSelectIndex_%s_%s", XPlayer.Id, self._Model.ActivityData:GetCurActivityId())
end

function XTheatre3Control:GetStrengthenTreeSelectIndex()
    local key = self:GetStrengthenTreeSelectIndexKey()
    return XSaveTool.GetData(key) or 0
end

function XTheatre3Control:SaveStrengthenTreeSelectIndex(value)
    local key = self:GetStrengthenTreeSelectIndexKey()
    local data = XSaveTool.GetData(key) or 0
    if data == value then
        return
    end
    XSaveTool.SaveData(key, value)
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
    local strengthenTreeIdList = self:GetStrengthenTreeIdList()
    for _, id in pairs(strengthenTreeIdList) do
        if self:CheckStrengthenTreeRedPoint(id) then
            self:SaveGeniusRedPoint(id)
        end
    end
end
--endregion

--region 网络请求相关
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

function XTheatre3Control:RequestSelectEquip(equipId, pos, cb)
    local lastStep = self:GetAdventureLastStep()
    XNetwork.Call(RequestProto.Theatre3SelectEquipRequest, { EquipId = equipId, Pos = pos }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local suitId = self:GetEquipById(equipId).SuitId
        lastStep:SetIsOver()
        self._Model.ActivityData:AddSlotEquip(pos, equipId, suitId)
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
        self._Model.ActivityData:ExchangeSlotSuit(srcSuitId, srcPos, srcEquips, dstSuitId, dstPos, dstEquips)
        self:WorkShopReduceTimes()
    end)
end

function XTheatre3Control:RequestRebuildEquip(srcEquipId, dstSuitId, dstPos, cb)
    XNetwork.Call(RequestProto.Theatre3RecastEquipRequest, { SrcEquipId = srcEquipId, DstSuitId = dstSuitId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local srcSuitId = self:GetEquipById(srcEquipId).SuitId
        local srcEquips = self:GetAllSuitWearEquipId(srcSuitId)
        local srcPos = self:GetEquipBelong(srcEquipId)
        local isSuitLost = #srcEquips <= 1 -- 如果套装里只有这一件装备 则套装也会一起失去
        self._Model.ActivityData:RebuildSlotEquip(isSuitLost and srcSuitId or nil, srcPos, srcEquipId, dstSuitId, dstPos, res.DstEquipId)
        self:WorkShopReduceTimes()
        if cb then
            cb(res)
        end
    end)
end

---设置编队
function XTheatre3Control:RequestSetTeam(callBack)
    local teamData = {}
    teamData.CardIds = self._Model.ActivityData:GetTeamsCharIds()
    teamData.RobotIds = self._Model.ActivityData:GetTeamRobotIds()
    teamData.CaptainPos = self._Model.ActivityData:GetCaptainPos()
    teamData.FirstFightPos = self._Model.ActivityData:GetFirstFightPos()

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
    local lastStep = self:GetAdventureLastStep()
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
        if cb then
            cb()
        end
    end)
end

function XTheatre3Control:RequestAdventureSelectItemReward(itemId, cb)
    local reqBody = {
        InnerItemId = itemId,
    }
    local lastStep = self:GetAdventureLastStep()
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3SelectItemRewardRequest, reqBody, function(res)
        -- N选1,单独处理步骤结束
        lastStep:SetIsOver()
        self:SetAdventureStepSelectItem(res.InnerItemId)
        XLuaUiManager.Open("UiTheatre3TipReward", nil, {res.InnerItemId}, cb)
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
        if XTool.IsNumberValid(res.InnerItemId) then
            XLuaUiManager.Open("UiTheatre3TipReward", nil, {res.InnerItemId})
        end
        if not XTool.IsTableEmpty(res.RewardGoodsList) then
            XLuaUiManager.Open("UiTheatre3TipReward", res.RewardGoodsList)
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
            XLuaUiManager.Open("UiTheatre3TipReward", nil, res.InnerItemIds, function()
                if cb then
                    cb(XTool.IsNumberValid(res.NextEventStepId))
                end
            end)
        end
        if not XTool.IsTableEmpty(res.RewardGoodsList) then
            XLuaUiManager.Open("UiTheatre3TipReward", res.RewardGoodsList, nil, function()
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
    local reqBody = {
        Uid = rewardUid,
    }
    local rewards = self:GetAdventureStepSelectRewardList()
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.Theatre3RecvFightRewardRequest, reqBody, function(res)
        if not XTool.IsTableEmpty(res.RewardGoodsList) then
            XLuaUiManager.Open("UiTheatre3TipReward", res.RewardGoodsList)
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
        if cb then
            cb(isEnd)
        end
    end)
end

---结束领取战斗奖励
function XTheatre3Control:RequestAdventureEndRecvFightReward(cb)
    local reqBody = {}
    local lastStep = self:GetAdventureLastStep()
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
    local lastStep = self:GetAdventureLastStep()
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
--endregion

--region RedPoint
function XTheatre3Control:GetAddEnergyLimitRedPoint()
    return self._Model:GetAddEnergyLimitRedPoint()
end

function XTheatre3Control:SetAddEnergyLimitRedPoint(value)
    self._Model:SetAddEnergyLimitRedPoint(value)
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
    for _, cfg in ipairs(self._Model:GetEventConfigs()) do
        if cfg.EventId == eventId and cfg.StepId == stepId then
            return cfg
        end
    end
    return
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

--region System - Adventure Logic
---@return boolean
function XTheatre3Control:CheckAndOpenAdventureNextStep(isPopOpen, isNotCheckNodeSlot)
    local isOpen = true
    ---@type XTheatre3Agency
    local theatre3Agency = XMVCA:GetAgency(ModuleId.XTheatre3)
    if theatre3Agency:CheckAndOpenSettle() then
        return false
    end
    local lostNodeSlot, lostNodeSlotStep = self:GetAdventureLastNodeSlot()
    local step = self:GetAdventureLastStep()
    if not isNotCheckNodeSlot and lostNodeSlotStep == step and self:CheckAndOpenAdventureNodeSlot(lostNodeSlot, isPopOpen) then
        return isOpen
    end
    if not step then
        XLog.Error("Error! CurStep is null!")
        return false
    end
    self:AdventurePlayCurChapterBgm()
    if step:CheckStepType(XEnumConst.THEATRE3.StepType.RecruitCharacter) then
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3RoleRoom", true, true)
    elseif step:CheckStepType(XEnumConst.THEATRE3.StepType.Node) then
        --新章节需要进入loading
        if self:IsNewAdventureChapter() then
            self._Model.ActivityData:GetCurChapterDb():SetOldChapter()
            self:_OpenAdventureUi(isPopOpen, "UiTheatre3Loading", self:GetAdventureCurChapterDb():GetCurChapterId())
        else
            self:_OpenAdventureUi(isPopOpen, "UiTheatre3PlayMain")
        end
    elseif step:CheckStepType(XEnumConst.THEATRE3.StepType.FightReward) then
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3RewardChoose", false)
    elseif step:CheckStepType(XEnumConst.THEATRE3.StepType.ItemReward) then
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3RewardChoose", true)
    elseif step:CheckStepType(XEnumConst.THEATRE3.StepType.WorkShop) then
        if step:CheckWorkShopType(XEnumConst.THEATRE3.WorkShopType.Recast) then
            self:_OpenAdventureUi(isPopOpen, "UiTheatre3SetBag", { isChooseEquip = true })
        elseif step:CheckWorkShopType(XEnumConst.THEATRE3.WorkShopType.Change) then
            self:_OpenAdventureUi(isPopOpen, "UiTheatre3SetBag", { isChooseSuit = true })
        end
    elseif step:CheckStepType(XEnumConst.THEATRE3.StepType.EquipReward) then
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3EquipmentChoose", step:GetEquipIds())
    elseif step:CheckStepType(XEnumConst.THEATRE3.StepType.EquipInherit) then
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3EquipmentChoose", step:GetEquipIds(), true)
    else
        isOpen = false
    end
    return isOpen
end

---@param nodeSlot XTheatre3NodeSlot
---@return boolean
function XTheatre3Control:CheckAndOpenAdventureNodeSlot(nodeSlot, isPopOpen)
    local isOpen = true
    local isFightPass = nodeSlot and nodeSlot:CheckIsFight() and nodeSlot:CheckStageIsPass(self:GetFightStageTemplateStageId(nodeSlot:GetFightTemplateId()))
    if not nodeSlot or isFightPass then
        isOpen = false
    elseif nodeSlot:CheckType(XEnumConst.THEATRE3.NodeSlotType.Fight) then
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3RoleRoom", true, false)
    elseif nodeSlot:CheckType(XEnumConst.THEATRE3.NodeSlotType.Event) then
        if XTool.IsNumberValid(nodeSlot:GetFightTemplateId()) then
            self:_OpenAdventureUi(isPopOpen, "UiTheatre3RoleRoom", true, false)
        else
            self:_OpenAdventureUi(isPopOpen, "UiTheatre3Outpost", nodeSlot)
        end
    elseif nodeSlot:CheckType(XEnumConst.THEATRE3.NodeSlotType.Shop) then
        self:_OpenAdventureUi(isPopOpen, "UiTheatre3Outpost", nodeSlot)
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
    end
end

function XTheatre3Control:AdventurePlayBgm(bgmCueId)
    if not XTool.IsNumberValid(bgmCueId) then
        return
    end
    if XSoundManager.GetCurrentBgmCueId() == bgmCueId then
        return
    end
    XSoundManager.PlaySoundByType(bgmCueId, XSoundManager.SoundType.BGM)
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

--region System - Adventure Data
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
function XTheatre3Control:GetAdventureLastStep()
    local chapterDb = self:GetAdventureCurChapterDb()
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
    local chapterDb = self:GetAdventureCurChapterDb()
    return chapterDb and chapterDb:GetCurChapterId()
end

function XTheatre3Control:GetAdventureCurItemList()
    return self._Model.ActivityData:GetAdventureItemList()
end

function XTheatre3Control:GetAdventureCurEquipSuitCount()
    local result = 0
    for _, equip in pairs(self._Model.ActivityData.Equips) do
        result = result + #equip.SuitIds
    end
    return result
end

function XTheatre3Control:GetAdventureStepSelectItemList()
    local lastStep = self._Model.ActivityData:GetCurChapterDb():GetLastStep()
    return lastStep and lastStep:GetItemIds() or {}
end

function XTheatre3Control:GetAdventureStepSelectEquipsList()
    local lastStep = self._Model.ActivityData:GetCurChapterDb():GetLastStep()
    return lastStep and lastStep:GetEquipIds() or {}
end

---@return XTheatre3NodeReward[]
function XTheatre3Control:GetAdventureStepSelectRewardList()
    local lastStep = self._Model.ActivityData:GetCurChapterDb():GetLastStep()
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
    return self._Model.ActivityData:GetAdventureItemCount(itemId)
end

function XTheatre3Control:SetAdventureStepSelectItem(id)
    local lastStep = self._Model.ActivityData:GetCurChapterDb():GetLastStep()
    if lastStep then
        lastStep:UpdateItemSelectId(id)
    end
end

function XTheatre3Control:SetAdventureStepSelectEquip(id)
    local lastStep = self._Model.ActivityData:GetCurChapterDb():GetLastStep()
    if lastStep then
        lastStep:UpdateEquipSelectId(id)
    end
end
--endregion

--region System - Adventure Checker
function XTheatre3Control:IsHavePassAdventure()
    return self._Model.ActivityData:CheckHasFirstPassFlag()
end

function XTheatre3Control:IsHaveAdventure()
    if XTool.IsNumberValid(self._Model.ActivityData:GetDifficultyId()) then
        return true
    end
    if XTool.IsNumberValid(self._Model.ActivityData:GetCurChapterId()) then
        return true
    end
    return false
end

function XTheatre3Control:IsNewAdventureChapter()
    return self._Model.ActivityData:GetCurChapterDb():CheckIsNewChapterId()
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
--endregion

--region System - Adventure Ui Control
function XTheatre3Control:OpenAdventureProp()
    self:RequestLookEquipAttribute(nil, nil, function()
        XLuaUiManager.Open("UiTheatre3Prop")
    end)
end

function XTheatre3Control:OpenAdventureRoleRoom()
    XLuaUiManager.Open("UiTheatre3RoleRoom", false)
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

--region System - UiTip
function XTheatre3Control:OpenTextTip(sureCb, title, content, closeCb, key, exData)
    XLuaUiManager.Open("UiTheatre3EndTips", sureCb, title, content, closeCb, key, exData)
end

--endregion

return XTheatre3Control