local XTheatre4MapSubControl = require("XModule/XTheatre4/SubControl/XTheatre4MapSubControl")
local XTheatre4EffectSubControl = require("XModule/XTheatre4/SubControl/XTheatre4EffectSubControl")
local XTheatre4AssetSubControl = require("XModule/XTheatre4/SubControl/XTheatre4AssetSubControl")
local XTheatre4SetControl = require("XModule/XTheatre4/SubControl/XTheatre4SetControl")
local XTheatre4SystemSubControl = require("XModule/XTheatre4/SubControl/XTheatre4SystemSubControl")

---@class XTheatre4Control : XControl
---@field private _Model XTheatre4Model
---@field MapSubControl XTheatre4MapSubControl
---@field EffectSubControl XTheatre4EffectSubControl
---@field AssetSubControl XTheatre4AssetSubControl
---@field SetControl XTheatre4SetControl
---@field SystemControl XTheatre4SystemSubControl
local XTheatre4Control = XClass(XControl, "XTheatre4Control")
function XTheatre4Control:OnInit()
    --初始化内部变量
    self.MapSubControl = self:AddSubControl(XTheatre4MapSubControl)
    self.EffectSubControl = self:AddSubControl(XTheatre4EffectSubControl)
    self.AssetSubControl = self:AddSubControl(XTheatre4AssetSubControl)
    self.SetControl = self:AddSubControl(XTheatre4SetControl)
    self.SystemControl = self:AddSubControl(XTheatre4SystemSubControl)

    -- 请求名称
    self.RequestName = {
        Theatre4EnterRequest = "Theatre4EnterRequest", -- 进入玩法
        Theatre4SelectDifficultRequest = "Theatre4SelectDifficultRequest", -- 选择难度
        Theatre4SelectInheritRequest = "Theatre4SelectInheritRequest", -- 选择继承藏品
        Theatre4SelectAffixRequest = "Theatre4SelectAffixRequest", -- 选择词缀
        Theatre4ExploreGridRequest = "Theatre4ExploreGridRequest", -- 探索格子
        Theatre4BattlePassGetRewardRequest = "Theatre4BattlePassGetRewardRequest", -- 奖励领奖
        Theatre4TechUnlockRequest = "Theatre4TechUnlockRequest", -- 激活科技
        Theatre4RefreshRecruitRequest = "Theatre4RefreshRecruitRequest", -- 刷新招募
        Theatre4ConfirmRecruitRequest = "Theatre4ConfirmRecruitRequest", -- 确认招募
        Theatre4SettleAdventureRequest = "Theatre4SettleAdventureRequest", -- 结算冒险
        Theatre4DailySettleRequest = "Theatre4DailySettleRequest", -- 每日结算
        Theatre4ShopBuyRequest = "Theatre4ShopBuyRequest", -- 商店购买
        Theatre4RefreshGoodsRequest = "Theatre4RefreshGoodsRequest", -- 商店刷新
        Theatre4ConfirmDropRequest = "Theatre4ConfirmDropRequest", -- 请求领取事务奖励
        Theatre4ConfirmFightRewardRequest = "Theatre4ConfirmFightRewardRequest", -- 请求领取战斗奖励
        Theatre4QuitFightRewardRequest = "Theatre4QuitFightRewardRequest", -- 请求放弃战斗奖励
        Theatre4ConfirmItemRequest = "Theatre4ConfirmItemRequest", -- 藏品箱领奖确认
        Theatre4DoGridEventRequest = "Theatre4DoGridEventRequest", -- 处理格子上的事件
        Theatre4SetTeamDataRequest = "Theatre4SetTeamDataRequest", -- 设置队伍数据
        Theatre4DoFateEventRequest = "Theatre4DoFateEventRequest", -- 处理时间轴事件
        Theatre4SelectTalentRequest = "Theatre4SelectTalentRequest", -- 选择天赋
        Theatre4RefreshTalentRequest = "Theatre4RefreshTalentRequest", -- 刷新天赋
        Theatre4ReplaceItemRequest = "Theatre4ReplaceItemRequest", -- 替换藏品
        Theatre4UseSkillEffectRequest = "Theatre4UseSkillEffectRequest", -- 使用主动技能效果
        Theatre4SweepMosnterRequest = "Theatre4SweepMosnterRequest", -- 扫荡怪物
        Theatre4ItemRecyclingRequest = "Theatre4ItemRecyclingRequest", -- 回收藏品
        Theatre4WaitItemRecyclingRequest = "Theatre4WaitItemRecyclingRequest", -- 回收溢出藏品
    }

    self._IsLock = false
    self._LockRef = function()
        self._IsLock = true
        self:LockRef()
    end
    self._UnlockRef = function()
        if self._IsLock then
            self:UnLockRef()
            self._IsLock = false
        end
    end
    self._IsSendError = false
    self._ErrorUnlockRef = function()
        self:UnLockRef()
        if self._IsSendError == false then
            CS.XCustomReport.Report(ModuleId.XTheatre4, "[XTheatre4Control] 肉鸽，control有泄漏，麻烦联系下肉鸽程序，谢谢")
            self._IsSendError = true
        end
    end
end

function XTheatre4Control:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
    CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_BEFORE_RELEASE_ALL, self._LockRef)
    -- 3.4解决方案: 由于ui新框架修好了一个问题, 但是造成了revertAll不成对, 所以监听事件从revertAll改为副本胜利
    -- 希望有一天这个问题可以被解决
    --CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_AFTER_REVERT_ALL, self._UnlockRef)
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_EXIT_FINAL, self._UnlockRef, self)
    CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_BEFORE_CLEAR_ALL, self._UnlockRef)
    XEventManager.AddEventListener(XEventId.EVENT_MAINUI_ENABLE, self._ErrorUnlockRef, self)
end

function XTheatre4Control:RemoveAgencyEvent()
    CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_BEFORE_RELEASE_ALL, self._LockRef)
    --CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_AFTER_REVERT_ALL, self._UnlockRef)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_EXIT_FINAL, self._UnlockRef, self)
    CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_BEFORE_CLEAR_ALL, self._UnlockRef)
    XEventManager.RemoveEventListener(XEventId.EVENT_MAINUI_ENABLE, self._ErrorUnlockRef, self)
end

function XTheatre4Control:OnRelease()
    --XLog.Error("这里执行Control的释放")
    self.MapSubControl = nil
    self.EffectSubControl = nil
    self.AssetSubControl = nil
    self.SetControl = nil
    self.SystemControl = nil
end

--region 请求服务端

-- 进入玩法
function XTheatre4Control:EnterRequest(cb)
    XNetwork.Call(self.RequestName.Theatre4EnterRequest, nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then
            cb()
        end
    end)
end

-- 选择难度
function XTheatre4Control:SelectDifficultRequest(difficult, cb)
    local request = { Difficult = difficult }
    XNetwork.Call(self.RequestName.Theatre4SelectDifficultRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model.ActivityData:UpdateAdventureData(res.AdventureData)
        if cb then
            cb()
        end
    end)
end

-- 选择继承藏品
function XTheatre4Control:SelectInheritRequest(itemId, callback)
    local request = { ItemId = itemId }
    XNetwork.Call(self.RequestName.Theatre4SelectInheritRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model.ActivityData:UpdateAdventureData(res.AdventureData)
        if callback then
            callback()
        end
    end)
end

-- 选择词缀
function XTheatre4Control:SelectAffixRequest(affixId, cb)
    local request = { Affix = affixId }
    XNetwork.Call(self.RequestName.Theatre4SelectAffixRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model.ActivityData:UpdateAdventureData(res.AdventureData)
        local lastChapterData = self._Model:GetLastChapterData()
        if lastChapterData then
            -- 入队弹框
            self._Model:EnqueuePopupData(XEnumConst.Theatre4.PopupType.ArriveNewArea, lastChapterData:GetMapGroup(), lastChapterData:GetMapId())
            self._Model.IsNewAdventure = true
        end
        if cb then
            cb()
        end
    end)
end

-- 探索格子
function XTheatre4Control:ExploreGridRequest(mapId, posX, posY, cb)
    local request = { MapId = mapId, PosX = posX, PosY = posY }
    XNetwork.Call(self.RequestName.Theatre4ExploreGridRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local chapterData = self._Model:GetChapterData(mapId)
        if chapterData then
            chapterData:UpdateGrid(res.Grid)
            chapterData:UpdateGrids(res.OtherGrids)
            XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_UPDATE_MAP_GRID_DATA, mapId)
        end
        if cb then
            cb()
        end
    end)
end

-- 奖励领奖
function XTheatre4Control:BattlePassGetRewardRequest(rewardType, rewardId, callback)
    local request = { GetRewardType = rewardType, Id = rewardId }
    XNetwork.Call(self.RequestName.Theatre4BattlePassGetRewardRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if rewardType == XEnumConst.Theatre4.BattlePassGetRewardType.GetAll then
            self._Model:SetBattlePassGotRewardIds(res.GotRewardIds)
            self._Model:ClearBattlePassCacheMap()
        else
            self._Model:AddBattlePassGotRewardId(rewardId)
            self._Model:AddBattlePassRewardIdMap(rewardId)
        end
        if callback then
            callback(res.RewardGoodsList)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_BP_REFRESH, rewardType)
    end)
end

-- 激活科技
function XTheatre4Control:TechUnlockRequest(techId)
    local request = { TechId = techId }
    XNetwork.Call(self.RequestName.Theatre4TechUnlockRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:AddUnlockTechId(techId)
        self._Model:AddActivedTechIdMap(techId)
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_TECHS_REFRESH)
    end)
end

-- 刷新招募
function XTheatre4Control:RefreshCharacterRequest(transactionId, cb)
    local request = { TransactionId = transactionId }
    XNetwork.Call(self.RequestName.Theatre4RefreshRecruitRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local adventureData = self._Model:GetAdventureData()
        if adventureData then
            adventureData:UpdateTransaction(res.Transaction)
            XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_UPDATE_HIRE)
        end
        if cb then
            cb()
        end
    end)
end

-- 招募
function XTheatre4Control:ConfirmRecruitRequest(transactionId, memberIndex, cb)
    local request = { TransactionId = transactionId, Index = memberIndex }
    XNetwork.Call(self.RequestName.Theatre4ConfirmRecruitRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local adventureData = self._Model:GetAdventureData()
        if adventureData then
            adventureData:UpdateTransaction(res.Transaction)
        end
        if cb then
            cb()
        end
    end)
end

-- 结算冒险
function XTheatre4Control:SettleAdventureRequest(cb)
    XNetwork.Call(self.RequestName.Theatre4SettleAdventureRequest, nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then
            cb()
        end
    end)
end

-- 每日结算
function XTheatre4Control:DailySettleRequest(cb)
    self._Model.IsDailySettling = true
    self._Model:RecordPreDailySettleData()
    XNetwork.Call(self.RequestName.Theatre4DailySettleRequest, nil, function(res)
        self._Model.IsDailySettling = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:RecordDailySettleResult(res.SettleResult)
        if cb then
            cb()
        end
    end)
end

-- 商店购买
function XTheatre4Control:ShopBuyRequest(mapId, posX, posY, goodsIndex, cb)
    local request = { MapId = mapId, PosX = posX, PosY = posY, GoodsIndex = goodsIndex }
    XNetwork.Call(self.RequestName.Theatre4ShopBuyRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then
            cb(res.Shop)
        end
    end)
end

-- 刷新商店
function XTheatre4Control:RefreshGoodsRequest(mapId, posX, posY, cb)
    local request = { MapId = mapId, PosX = posX, PosY = posY }
    XNetwork.Call(self.RequestName.Theatre4RefreshGoodsRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then
            cb(res.Shop)
        end
    end)
end

-- 请求领取事务奖励
function XTheatre4Control:ConfirmDropRequest(transactionId, index, cb)
    local request = { TransactionId = transactionId, Index = index }
    XNetwork.Call(self.RequestName.Theatre4ConfirmDropRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then
            cb()
        end
    end)
end

-- 请求领取战斗奖励
function XTheatre4Control:ConfirmFightRewardRequest(transactionId, index, cb)
    local request = { TransactionId = transactionId, Index = index }
    XNetwork.Call(self.RequestName.Theatre4ConfirmFightRewardRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 更新已选择的下标
        local transaction = self._Model:GetTransactionData(transactionId)
        if transaction then
            transaction:AddSelectId(index)
        end
        if cb then
            cb()
        end
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_RESTRICT_FOCUS)
    end)
end

-- 请求放弃战斗奖励
function XTheatre4Control:QuitFightRewardRequest(transactionId, cb)
    local request = { TransactionId = transactionId }
    XNetwork.Call(self.RequestName.Theatre4QuitFightRewardRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then
            cb()
        end
    end)
end

-- 藏品箱领奖确认
---@param transactionId number 事务Id
---@param operateType number 操作类型 1:获得 2:回收
---@param index number 选择奖励的下标
---@param replaceItemUid number 替换藏品的唯一id
function XTheatre4Control:ConfirmItemRequest(transactionId, operateType, index, replaceItemUid, cb)
    local request = { TransactionId = transactionId, OperateType = operateType, Index = index, ReplaceItemUid = replaceItemUid }
    XNetwork.Call(self.RequestName.Theatre4ConfirmItemRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then
            cb()
        end
    end)
end

-- 处理格子上的事件
function XTheatre4Control:DoGridEventRequest(mapId, posX, posY, option, cb)
    -- option 选项（没有就传0）
    local request = { MapId = mapId, PosX = posX, PosY = posY, Option = option }
    XNetwork.Call(self.RequestName.Theatre4DoGridEventRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local chapterData = self._Model:GetChapterData(mapId)
        if chapterData then
            chapterData:UpdateGrids(res.Grids)
            XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_UPDATE_MAP_GRID_DATA, mapId)
        end
        if cb then
            cb()
        end
    end)
end

-- 设置队伍数据
---@param teamData XTheatre4TeamData
function XTheatre4Control:SetTeamDataRequest(teamData)
    local request = { TeamData = teamData }
    XNetwork.Call(self.RequestName.Theatre4SetTeamDataRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 更新队伍数据
        local adventureData = self._Model:GetAdventureData()
        if adventureData then
            adventureData:UpdateTeamData(teamData)
        end
    end)
end

-- 处理时间轴事件
function XTheatre4Control:DoFateEventRequest(option, eventId, cb)
    local request = { Option = option, FateEventUniqueId = eventId }
    XNetwork.Call(self.RequestName.Theatre4DoFateEventRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then
            cb()
        end
    end)
end

-- 选择天赋
function XTheatre4Control:SelectTalentRequest(colorId, talentId, cb)
    local request = { Color = colorId, TalentId = talentId }
    XNetwork.Call(self.RequestName.Theatre4SelectTalentRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local adventureData = self._Model:GetAdventureData()
        if adventureData then
            adventureData:AddColor(res.ColorTalent)
            -- 选择的天赋Id入队弹框
            self._Model:EnqueuePopupData(XEnumConst.Theatre4.PopupType.TalentLevelUp, false, { talentId })
        end
        if cb then
            cb()
        end
    end)
end

-- 刷新天赋
function XTheatre4Control:RefreshTalentRequest(colorId, cb)
    local request = { Color = colorId }
    XNetwork.Call(self.RequestName.Theatre4RefreshTalentRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local adventureData = self._Model:GetAdventureData()
        if adventureData then
            adventureData:AddColor(res.ColorTalent)
        end
        if cb then
            cb()
        end
    end)
end

-- 替换藏品
function XTheatre4Control:ReplaceItemRequest(waitItemId, itemUId, cb)
    -- 被替换的藏品唯一id
    local request = { WaitItemId = waitItemId, TargetItemUid = itemUId }
    XNetwork.Call(self.RequestName.Theatre4ReplaceItemRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 主动移除待处理藏品
        local adventureData = self._Model:GetAdventureData()
        if adventureData then
            adventureData:RemoveWaitItem(waitItemId)
        end
        if cb then
            cb()
        end
    end)
end

-- 使用主动技能效果
function XTheatre4Control:UseSkillEffectRequest(effectId, params, cb)
    local request = { EffectId = effectId, Params = params }
    XNetwork.Call(self.RequestName.Theatre4UseSkillEffectRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then
            cb()
        end
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_REFRESH_TIME_LINE)
    end)
end

-- 扫荡怪物
function XTheatre4Control:SweepMonsterRequest(mapId, posX, posY, cb, sweepType)
    local request = { MapId = mapId, PosX = posX, PosY = posY, SweepType = sweepType or XEnumConst.Theatre4.SweepType.Yellow }
    XNetwork.Call(self.RequestName.Theatre4SweepMosnterRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then
            cb()
        end
    end)
end

-- 回收藏品
function XTheatre4Control:ItemRecyclingRequest(uid, cb)
    local request = { Uid = uid }
    XNetwork.Call(self.RequestName.Theatre4ItemRecyclingRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then
            cb()
        end
    end)
end

-- 回收溢出藏品
function XTheatre4Control:WaitItemRecyclingRequest(itemId, cb)
    local request = { ItemId = itemId }
    XNetwork.Call(self.RequestName.Theatre4WaitItemRecyclingRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 主动移除待处理藏品
        local adventureData = self._Model:GetAdventureData()
        local popupType = XEnumConst.Theatre4.PopupType.AssetReward
        local rewardType = XEnumConst.Theatre4.AssetType.Item

        self._Model:RemoveAssetRewardPopupData(popupType, itemId, rewardType)
        if adventureData then
            adventureData:RemoveWaitItem(itemId)
        end
        if cb then
            cb()
        end
    end)
end

--endregion

--region 冒险数据

-- 获取当前天数
function XTheatre4Control:GetDays()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return 0
    end
    return adventureData:GetDays()
end

---@return XTheatre4Fate[]
function XTheatre4Control:GetFateList()
    local fateList = self._Model:GetFateList()
    return fateList
end

---@return boolean, XTheatre4Fate
function XTheatre4Control:IsFateExist(fateUid)
    local fate = self:GetFateByFateUid(fateUid)
    return fate ~= nil, fate
end

function XTheatre4Control:GetFateByFateUid(fateUid)
    local fateList = self._Model:GetFateList()
    for i = 1, #fateList do
        local fate = fateList[i]
        if fateUid == fate:GetFateEventId() then
            return fate
        end
    end
    return nil
end

-- 获取时间轴触发事件的关卡Id
function XTheatre4Control:GetFateTriggerStageId(fateUid)
    local fateData = self:GetFateByFateUid(fateUid)
    if not fateData then
        return 0
    end
    return fateData:GetStageId()
end

-- 获取时间轴触发事件的关卡分数
function XTheatre4Control:GetFateTriggerStageScore(fateUid)
    local fateData = self:GetFateByFateUid(fateUid)
    if not fateData then
        return 0
    end
    return fateData:GetStageScore()
end

function XTheatre4Control:GetFateByDay(day)
    local fateList = self._Model:GetFateList()
    for i = 1, #fateList do
        local fate = fateList[i]
        if day == self:GetFateTriggerDay(fate) then
            return fate
        end
    end
    return false
end

-- 获取时间轴触发后生效的天数
---@param fateData XTheatre4Fate
function XTheatre4Control:GetFateTriggerDay(fateData)
    if not fateData then
        return 0
    end
    -- 有fateEventId才是时间轴事件
    local fateEventId = fateData:GetFateEventId()
    if fateEventId <= 0 then
        return 0
    end
    local timeLeft = fateData:GetEventTimeLeft()
    local curDay = self:GetDays()
    return curDay + timeLeft
end

-- 检查是否是时间轴事件触发天数
function XTheatre4Control:CheckIsFateTriggerDay(day)
    -- 从配置表获取
    local fateId = self._Model:GetAdventureData():GetFateId()
    if fateId and fateId > 0 then
        local config = self._Model:GetFateConfigById(fateId)
        if config then
            local triggerDays = config.TriggerDay
            for _, v in pairs(triggerDays) do
                if day == v then
                    local eventGroups = config.EventGroup
                    if #eventGroups > 0 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- 获取当前难度
function XTheatre4Control:GetDifficulty()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return 0
    end
    return adventureData:GetDifficulty()
end

-- 获取词缀Id
function XTheatre4Control:GetAffix()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return 0
    end
    return adventureData:GetAffix()
end

-- 获取线路Id
function XTheatre4Control:GetMapBlueprintId()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return nil
    end
    return adventureData:GetMapBlueprintId()
end

-- 获取已购物次数
function XTheatre4Control:GetEffectShopBuyTimes()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return 0
    end
    return adventureData:GetEffectShopBuyTimes()
end

-- 获取已扫荡(诏安)次数
function XTheatre4Control:GetEffectSweepTimes()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return 0
    end
    return adventureData:GetEffectSweepTimes()
end

-- 获取角色最高的星级
function XTheatre4Control:GetCharacterMaxStar()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return 0
    end
    return adventureData:GetCharacterMaxStar()
end

-- 检查冒险数据是否为空
function XTheatre4Control:CheckAdventureDataEmpty()
    local adventureData = self._Model:GetAdventureData()
    return not adventureData
end

-- 检查是否是新开的冒险
function XTheatre4Control:CheckIsNewAdventure()
    return self._Model.IsNewAdventure
end

-- 清除新开冒险标记
function XTheatre4Control:ClearNewAdventureFlag()
    self._Model.IsNewAdventure = false
end

-- 获取上一次冒险结算时间
function XTheatre4Control:GetLastAdventureSettleTime()
    local preAdventureSettleData = self._Model:GetPreAdventureSettleData()
    if not preAdventureSettleData then
        return 0
    end
    return preAdventureSettleData:GetSettleTime()
end

-- 获取当前冒险开始时间
function XTheatre4Control:GetCurAdventureStartTime()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return 0
    end
    return adventureData:GetStartTime()
end

-- 冒险数据修正
function XTheatre4Control:CheckAndFixAdventureData()
    -- 上一次冒险结算时间
    local lastSettleTime = self:GetLastAdventureSettleTime()
    -- 当前冒险开始时间
    local curStartTime = self:GetCurAdventureStartTime()
    -- 检查冒险数据是否正常
    if lastSettleTime > 0 and curStartTime > 0 and lastSettleTime >= curStartTime then
        -- 清空冒险数据
        if self._Model.ActivityData then
            self._Model.ActivityData:UpdateAdventureData(nil)
        end
        -- 清理弹框数据
        self:ClearAllPopupData()
        -- 清理查看地图数据
        self:ClearViewMapData()
        -- 清理冒险结算数据
        self:ClearAdventureSettleData()
        -- 清理相机跟随数据
        self:ClearCameraFollowLastPos()
    end
end

--region 藏品数据

-- 获取藏品剩余持续天数
function XTheatre4Control:GetItemLeftDays(uid)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return -1
    end
    local item = adventureData:GetItemByUid(uid) or adventureData:GetPropByUid(uid)
    if not item then
        return -1
    end
    return item:GetLeftDays()
end

-- 获取拥有的道具信息列表
---@return { UId:number, ItemId:number }[]
function XTheatre4Control:GetOwnPropDataList()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return {}
    end
    local ownPropData = {}
    ---@type table<number, XTheatre4Item>
    local items = adventureData:GetProps()
    if not XTool.IsTableEmpty(items) then
        for _, item in pairs(items) do
            table.insert(ownPropData, { UId = item:GetUid(), ItemId = item:GetItemId() })
        end
    end
    return ownPropData
end

-- 获取计数上限的藏品信息列表 Item里的藏品
---@return { UId:number, ItemId:number }[]
function XTheatre4Control:GetCountLimitItemDataList()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return {}
    end
    local countLimitItemData = {}
    ---@type table<number, XTheatre4Item>
    local items = adventureData:GetItems()
    if not XTool.IsTableEmpty(items) then
        for _, item in pairs(items) do
            table.insert(countLimitItemData, { UId = item:GetUid(), ItemId = item:GetItemId() })
        end
    end
    return countLimitItemData
end

-- 获取背包侧边栏显示的藏品数据
function XTheatre4Control:GetBagSideItemDataList()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return nil
    end
    local itemDataList = {}
    ---@type table<number, XTheatre4Item>[]
    local allItems = { adventureData:GetItems(), adventureData:GetProps() }
    for _, items in pairs(allItems) do
        if not XTool.IsTableEmpty(items) then
            for _, item in pairs(items) do
                local itemId = item:GetItemId()
                if self:CheckShowItem(itemId) then
                    table.insert(itemDataList, { UId = item:GetUid(), ItemId = itemId })
                end
            end
        end
    end
    return itemDataList
end

-- 获取藏品数量和上限
---@return number, number 当前数量, 上限
function XTheatre4Control:GetItemCountAndLimit()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return 0, 0
    end
    local items = adventureData:GetItems()
    local maxLimit = self.AssetSubControl:GetItemLimit()
    return table.nums(items), maxLimit
end

-- 检查藏品数量是否已到上限
function XTheatre4Control:CheckItemMaxLimit()
    local itemCount, maxLimit = self:GetItemCountAndLimit()
    return itemCount >= maxLimit
end

--endregion

--region 事务数据

-- 获取事务奖励数据列表
---@return { Reward:XTheatre4Asset, Index:number }[]
function XTheatre4Control:GetTransactionRewardDataList(transactionId)
    local rewards = self:GetTransactionRewardList(transactionId)
    if not rewards then
        return nil
    end
    local selectIds = self:GetTransactionSelectIds(transactionId)
    local rewardDataList = {}
    for index, reward in pairs(rewards) do
        if not table.contains(selectIds, index) then
            table.insert(rewardDataList, { Reward = reward, Index = index })
        end
    end
    return rewardDataList
end

-- 获取事务里的奖励列表
function XTheatre4Control:GetTransactionRewardList(transactionId)
    local transaction = self._Model:GetTransactionData(transactionId)
    if not transaction then
        return nil
    end
    return transaction:GetRewards()
end

-- 获取事务里已选的奖励下标
function XTheatre4Control:GetTransactionSelectIds(transactionId)
    local transaction = self._Model:GetTransactionData(transactionId)
    if not transaction then
        return {}
    end
    return transaction:GetSelectIds()
end

-- 获取事务里剩余可选次数
function XTheatre4Control:GetTransactionSelectTimes(transactionId)
    local transaction = self._Model:GetTransactionData(transactionId)
    if not transaction then
        return 0
    end
    return transaction:GetSelectTimes()
end

-- 获取事务里最大可选次数
function XTheatre4Control:GetTransactionSelectLimit(transactionId)
    local transaction = self._Model:GetTransactionData(transactionId)
    if not transaction then
        return 0
    end
    return transaction:GetSelectLimit()
end

-- 检查是否还有未领取的奖励
function XTheatre4Control:CheckTransactionRewardEmpty(transactionId)
    local rewardDataList = self:GetTransactionRewardDataList(transactionId)
    return XTool.IsTableEmpty(rewardDataList)
end

--endregion

--region 颜色天赋数据

-- 获取颜色Id列表
function XTheatre4Control:GetColorIds()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return {}
    end
    return adventureData:GetColorIds()
end

-- 获取颜色天赋刷新消耗
function XTheatre4Control:GetColorTalentRefreshCost(colorId)
    local freeRefreshTimes = self:GetColorTalentFreeRefreshTimes(colorId)
    if freeRefreshTimes > 0 then
        return 0
    end
    local config = self._Model:GetActivityConfig()
    -- 配置消耗
    local refreshCosts = config and config.TalentRefreshCost or {}
    local refreshLimit = self:GetColorTalentRefreshLimit(colorId)
    local refreshTimes = self:GetColorTalentRefreshTimes(colorId)
    local curRefreshTimes = refreshLimit - refreshTimes + 1
    local cost = refreshCosts[math.min(curRefreshTimes, #refreshCosts)] or 0
    -- 额外消耗
    if cost > 0 then
        local extraCost = self.EffectSubControl:GetEffectRefreshTalentExtraCost()
        cost = cost + extraCost
        if cost < 0 then
            cost = 0
        end
    end
    return cost
end

-- 获取颜色天赋免费刷新次数
function XTheatre4Control:GetColorTalentFreeRefreshTimes(colorId)
    local colorTalentData = self._Model:GetColorTalentData(colorId)
    if not colorTalentData then
        return 0
    end
    return colorTalentData:GetRefreshFreeTimes()
end

-- 获取颜色天赋刷新上限
function XTheatre4Control:GetColorTalentRefreshLimit(colorId)
    local colorTalentData = self._Model:GetColorTalentData(colorId)
    if not colorTalentData then
        return 0
    end
    return colorTalentData:GetRefreshLimit()
end

-- 获取颜色天赋剩余刷新次数
function XTheatre4Control:GetColorTalentRefreshTimes(colorId)
    local colorTalentData = self._Model:GetColorTalentData(colorId)
    if not colorTalentData then
        return 0
    end
    return colorTalentData:GetRefreshTimes()
end

-- 获取待处理档位的天赋Ids
function XTheatre4Control:GetWaitSlotTalentIds(colorId)
    local colorTalentData = self._Model:GetColorTalentData(colorId)
    if not colorTalentData then
        return {}
    end
    return colorTalentData:GetWaitSlotTalentIds()
end

--endregion

--endregion

--region 配置表数据

-- 获取客户端配置
function XTheatre4Control:GetClientConfig(key, index, isNumber)
    index = XTool.IsNumberValid(index) and index or 1
    local value = self._Model:GetClientConfig(key, index)
    return isNumber and tonumber(value) or value
end

function XTheatre4Control:GetClientConfigParams(key)
    return self._Model:GetClientConfigParams(key)
end

-- 获取配置
---@param key string 配置key
---@param index number 索引
---@param isString boolean 是否返回字符串 默认返回数字
function XTheatre4Control:GetConfig(key, index, isString)
    index = XTool.IsNumberValid(index) and index or 1
    local values = self._Model:GetConfigValuesByKey(key) or {}
    local value = values[index] or 0
    return isString and value or tonumber(value)
end

--region 事件

-- 获取事件类型
function XTheatre4Control:GetEventType(eventId)
    return self._Model:GetEventTypeById(eventId)
end

-- 获取事件描述
function XTheatre4Control:GetEventDesc(eventId)
    return self._Model:GetEventDescById(eventId)
end

-- 获取未翻开事件描述
function XTheatre4Control:GetEventUnOpenDesc(eventId)
    return self._Model:GetEventUnOpenDescById(eventId) or ""
end

-- 获取事件名称
function XTheatre4Control:GetEventName(eventId)
    return self._Model:GetEventNameById(eventId)
end

-- 获取事件图标
function XTheatre4Control:GetEventIcon(eventId)
    return self._Model:GetEventIconById(eventId)
end

-- 获取事件块图标
function XTheatre4Control:GetEventBlockIcon(eventId)
    return self._Model:GetEventBlockIconById(eventId)
end

-- 获取事件标题
function XTheatre4Control:GetEventTitle(eventId)
    return self._Model:GetEventTitleById(eventId)
end

-- 获取事件标题内容
function XTheatre4Control:GetEventTitleContent(eventId)
    return self._Model:GetEventTitleContentById(eventId)
end

-- 获取事件角色立绘
function XTheatre4Control:GetEventRoleIcon(eventId)
    return self._Model:GetEventRoleIconById(eventId)
end

-- 获取事件角色名称
function XTheatre4Control:GetEventRoleName(eventId)
    return self._Model:GetEventRoleNameById(eventId)
end

-- 获取事件角色描述
function XTheatre4Control:GetEventRoleContent(eventId)
    return self._Model:GetEventRoleContentById(eventId)
end

-- 获取事件角色特效
function XTheatre4Control:GetEventRoleEffect(eventId)
    return self._Model:GetEventRoleEffectById(eventId)
end

-- 获取事件按钮文本
function XTheatre4Control:GetEventConfirmContent(eventId)
    return self._Model:GetEventConfirmContentById(eventId)
end

-- 获取事件背景资产
function XTheatre4Control:GetEventBgAsset(eventId)
    return self._Model:GetEventBgAssetById(eventId)
end

-- 获取事件故事Id
function XTheatre4Control:GetEventStoryId(eventId)
    return self._Model:GetEventStoryIdById(eventId)
end

-- 获取事件奖励Ids
function XTheatre4Control:GetEventRewardIds(eventId)
    return self._Model:GetEventRewardIdsById(eventId)
end

-- 检查事件是否结束 配置为1时结束
function XTheatre4Control:CheckEventEnd(eventId)
    local isEnd = self._Model:GetEventIsEndById(eventId)
    return isEnd == 1
end

-- 检查事件是否强制播放 配置为1时强制播放
function XTheatre4Control:CheckEventForcePlay(eventId)
    local forcePlay = self._Model:GetEventIsForcePlayById(eventId)
    return forcePlay == 1
end

--endregion

--region 事件选项

-- 检查是否满足事件选项条件 默认满足
function XTheatre4Control:CheckEventOptionCondition(conditionId)
    if XTool.IsNumberValid(conditionId) then
        return XConditionManager.CheckCondition(conditionId)
    end
    return true, ""
end

-- 通过事件Id获取事件选项Ids TODO 后续可以优化
function XTheatre4Control:GetEventOptionIds(eventId)
    local optionGroupId = self._Model:GetEventOptionGroupIdById(eventId)
    if not XTool.IsNumberValid(optionGroupId) then
        return nil
    end
    local optionConfigs = self._Model:GetEventOptionConfigs()
    if not optionConfigs then
        return nil
    end
    local optionIds = {}
    for _, config in pairs(optionConfigs) do
        if config.GroupId == optionGroupId then
            -- 判断是否满足显示条件
            if self:CheckEventOptionCondition(config.OptionShowCondition) then
                table.insert(optionIds, config.Id)
            end
        end
    end
    --排序
    table.sort(optionIds, function(a, b)
        return a < b
    end)
    return optionIds
end

-- 获取事件选项描述
function XTheatre4Control:GetEventOptionDesc(optionId)
    return self._Model:GetEventOptionOptionDescById(optionId)
end

-- 获取事件选项副描述
function XTheatre4Control:GetEventOptionSubDesc(optionId)
    return self._Model:GetEventOptionOptionDownDescById(optionId)
end

-- 获取事件选项类型
function XTheatre4Control:GetEventOptionType(optionId)
    return self._Model:GetEventOptionOptionTypeById(optionId)
end

-- 获取事件选项道具类型
function XTheatre4Control:GetEventOptionItemType(optionId)
    return self._Model:GetEventOptionOptionItemTypeById(optionId)
end

-- 获取事件选项道具Id
function XTheatre4Control:GetEventOptionItemId(optionId)
    return self._Model:GetEventOptionOptionItemIdById(optionId)
end

-- 获取事件选项道具数量
function XTheatre4Control:GetEventOptionItemCount(optionId)
    return self._Model:GetEventOptionOptionItemCountById(optionId)
end

-- 获取事件选项关卡分数最低
function XTheatre4Control:GetEventOptionStageScoreMin(optionId)
    return self._Model:GetEventOptionOptionStageScoreMinById(optionId)
end

-- 获取事件选项关卡分数最高
function XTheatre4Control:GetEventOptionStageScoreMax(optionId)
    return self._Model:GetEventOptionOptionStageScoreMaxById(optionId)
end

-- 获取事件选项可选的条件
function XTheatre4Control:GetEventOptionCondition(optionId)
    return self._Model:GetEventOptionOptionConditionById(optionId)
end

-- 获取事件选项显示的条件
function XTheatre4Control:GetEventOptionShowCondition(optionId)
    return self._Model:GetEventOptionOptionShowConditionById(optionId)
end

-- 获取事件选项图标
function XTheatre4Control:GetEventOptionIcon(optionId)
    return self._Model:GetEventOptionOptionIconById(optionId)
end

--endregion

--region 宝箱

-- 获取宝箱名称
function XTheatre4Control:GetBoxGroupName(id)
    return self._Model:GetBoxGroupNameById(id)
end

-- 获取宝箱图片
function XTheatre4Control:GetBoxGroupIcon(id)
    return self._Model:GetBoxGroupIconById(id)
end

-- 获取宝箱块图标
function XTheatre4Control:GetBoxGroupBlockIcon(id)
    return self._Model:GetBoxGroupBlockIconById(id)
end

-- 获取宝箱标题
function XTheatre4Control:GetBoxGroupTitle(id)
    return self._Model:GetBoxGroupTitleById(id)
end

-- 获取宝箱标题内容
function XTheatre4Control:GetBoxGroupTitleContent(id)
    return self._Model:GetBoxGroupTitleContentById(id)
end

-- 获取宝箱描述
function XTheatre4Control:GetBoxGroupDesc(id)
    return self._Model:GetBoxGroupDescById(id)
end

--endregion

--region 商店

-- 获取商店名称
function XTheatre4Control:GetShopName(id)
    return self._Model:GetShopNameById(id)
end

-- 获取商店图片
function XTheatre4Control:GetShopIcon(id)
    return self._Model:GetShopIconById(id)
end

-- 获取商店块图标
function XTheatre4Control:GetShopBlockIcon(id)
    return self._Model:GetShopBlockIconById(id)
end

-- 获取商店标题
function XTheatre4Control:GetShopTitle(id)
    return self._Model:GetShopTitleById(id)
end

-- 获取商店标题内容
function XTheatre4Control:GetShopTitleContent(id)
    return self._Model:GetShopTitleContentById(id)
end

-- 获取商店描述
function XTheatre4Control:GetShopDesc(id)
    return self._Model:GetShopDescById(id)
end

-- 获取商店未翻开描述
function XTheatre4Control:GetShopUnOpenDesc(id)
    return self._Model:GetShopUnOpenDescById(id) or ""
end

-- 获取商店角色立绘
function XTheatre4Control:GetShopRoleIcon(id)
    return self._Model:GetShopRoleIconById(id)
end

-- 获取商店角色名称
function XTheatre4Control:GetShopRoleName(id)
    return self._Model:GetShopRoleNameById(id)
end

-- 获取商店角色描述
function XTheatre4Control:GetShopRoleContent(id)
    return self._Model:GetShopRoleContentById(id)
end

-- 获取商店背景资产
function XTheatre4Control:GetShopBgAsset(id)
    return self._Model:GetShopBgAssetById(id)
end

-- 获取商店刷新上限
function XTheatre4Control:GetShopRefreshLimit(id)
    return self._Model:GetShopRefreshLimitById(id)
end

-- 获取商店刷新免费次数
function XTheatre4Control:GetShopRefreshFreeTimes(id)
    return self._Model:GetShopRefreshFreeTimesById(id)
end

-- 获取商店刷新消耗
function XTheatre4Control:GetShopRefreshCost(id)
    return self._Model:GetShopRefreshCostById(id)
end

--endregion

--region 商店商品

-- 获取商店商品类型
function XTheatre4Control:GetGoodsType(id)
    return self._Model:GetShopGoodsTypeById(id)
end

-- 获取商店商品Id
function XTheatre4Control:GetGoodsId(id)
    return self._Model:GetShopGoodsIdById(id)
end

-- 获取商店商品数量
function XTheatre4Control:GetGoodsNum(id)
    return self._Model:GetShopGoodsNumById(id)
end

-- 获取商店商品价格
function XTheatre4Control:GetGoodsPrice(id)
    return self._Model:GetShopGoodsPriceById(id)
end

--endregion

--region 战斗

-- 获取战斗名称
function XTheatre4Control:GetFightName(id)
    return self._Model:GetFightNameById(id)
end

-- 获取战斗名称
function XTheatre4Control:GetFightPanelName(id)
    return self._Model:GetFightPanelNameById(id) or ""
end

-- 获取战斗类型
function XTheatre4Control:GetFightTypeById(id)
    return self._Model:GetFightTypeById(id) or 0
end

-- 获取战斗图标
function XTheatre4Control:GetFightIcon(id)
    return self._Model:GetFightIconById(id)
end

-- 获取战斗块图标
function XTheatre4Control:GetFightBlockIcon(id)
    return self._Model:GetFightBlockIconById(id)
end

-- 获取战斗头像图标
function XTheatre4Control:GetFightHeadIcon(id)
    return self._Model:GetFightHeadIconById(id)
end

-- 获取战斗描述
function XTheatre4Control:GetFightDesc(id)
    return self._Model:GetFightDescById(id)
end

-- 获取下一个Boss战斗Id
function XTheatre4Control:GetNextFightId(id)
    local nextFightIds = self._Model:GetFightNextFightIdById(id)
    local nextFightConditions = self._Model:GetFightNextFightConditionById(id)

    if XTool.IsTableEmpty(nextFightIds) then
        return 0
    end

    for i, fightId in pairs(nextFightIds) do
        local conditionId = nextFightConditions[i]

        if XTool.IsNumberValid(conditionId) then
            if XConditionManager.CheckCondition(conditionId) then
                return fightId
            end
        else
            return fightId
        end
    end

    return 0
end

function XTheatre4Control:CheckCurrentHasNextBoss()
    local bossGridData = self.MapSubControl:GetCurrentBossGridData(nil, true)
    if not bossGridData then
        return false
    end
    local fightId = bossGridData:GetGridContentId()
    if not XTool.IsNumberValid(fightId) then
        return false
    end
    local nextFightId = self:GetNextFightId(fightId)
    return XTool.IsNumberValid(nextFightId)
end

--endregion

--region 战斗组

-- 获取繁荣度限制
function XTheatre4Control:GetFightGroupProsperityLimit(id)
    local difficultyList = self._Model:GetFightGroupDifficultyById(id)
    local prosperityLimitList = self._Model:GetFightGroupProsperityLimitById(id)
    if not difficultyList or not prosperityLimitList then
        return 0
    end
    local curDifficulty = self:GetDifficulty()
    for index, v in pairs(difficultyList) do
        if v == curDifficulty then
            return prosperityLimitList[index] or 0
        end
    end
    return 0
end

-- 获取招安消耗
function XTheatre4Control:GetFightGroupClearCost(id)
    local difficultyList = self._Model:GetFightGroupDifficultyById(id)
    local clearCostList = self._Model:GetFightGroupClearCostById(id)
    if not difficultyList or not clearCostList then
        return 0
    end
    local curDifficulty = self:GetDifficulty()
    for index, v in pairs(difficultyList) do
        if v == curDifficulty then
            return clearCostList[index] or 0
        end
    end
    return 0
end

-- 获取红色买死消耗
function XTheatre4Control:GetFightGroupRedClearCost(id)
    local difficultyList = self._Model:GetFightGroupDifficultyById(id)
    local clearCostList = self._Model:GetFightGroupRedClearCostById(id)
    if not difficultyList or not clearCostList then
        return 0
    end
    local curDifficulty = self:GetDifficulty()
    for index, v in pairs(difficultyList) do
        if v == curDifficulty then
            return clearCostList[index] or 0
        end
    end
    return 0
end

-- 根据FightId获取FightGroupId
function XTheatre4Control:GetFightGroupIdByFightId(fightId)
    local fightGroupConfigs = self._Model:GetFightGroupConfigs()

    for id, config in pairs(fightGroupConfigs) do
        if config.FightId == fightId then
            return id
        end
    end

    return 0
end

--endregion

--region 建筑

-- 获取建筑参数
function XTheatre4Control:GetBuildingParams(id)
    return self._Model:GetBuildingParamsById(id)
end

-- 获取建筑名称
function XTheatre4Control:GetBuildingName(id)
    return self._Model:GetBuildingNameById(id)
end

-- 获取建筑图标
function XTheatre4Control:GetBuildingIcon(id)
    return self._Model:GetBuildingIconById(id)
end

-- 获取建筑标题
function XTheatre4Control:GetBuildingTitle(id)
    return self._Model:GetBuildingTitleById(id)
end

-- 获取建筑标题内容
function XTheatre4Control:GetBuildingTitleContent(id)
    return self._Model:GetBuildingTitleContentById(id)
end

-- 获取建筑描述
function XTheatre4Control:GetBuildingDesc(id)
    return self._Model:GetBuildingDescById(id)
end

-- 获取建筑在章节中最大数量
function XTheatre4Control:GetBuildingMaxCountInChapter(id)
    return self._Model:GetBuildingMaxCountInChapterById(id)
end

-- 获取建筑技能图片
function XTheatre4Control:GetBuildingSkillPicture(id)
    return self._Model:GetBuildingSkillPictureById(id)
end

--endregion

--region 词缀

-- 获取词缀名称
function XTheatre4Control:GetAffixName(id)
    return self._Model:GetAffixNameById(id)
end

-- 获取词缀图标
function XTheatre4Control:GetAffixIcon(id)
    return self._Model:GetAffixIconById(id)
end

-- 获取词缀描述
function XTheatre4Control:GetAffixDesc(id)
    return self._Model:GetAffixDescById(id)
end

--endregion

--region 颜色天赋

-- 获取颜色天赋名称
function XTheatre4Control:GetColorTalentName(id)
    return self._Model:GetColorTalentNameById(id)
end

-- 获取颜色天赋图标
function XTheatre4Control:GetColorTalentIcon(id)
    return self._Model:GetColorTalentIconById(id)
end

-- 获取颜色天赋描述
function XTheatre4Control:GetColorTalentDesc(id)
    return self._Model:GetColorTalentDescById(id)
end

-- 获取颜色天赋类型
function XTheatre4Control:GetColorTalentType(id)
    return self._Model:GetColorTalentTypeById(id)
end

-- 获取颜色天赋条件
function XTheatre4Control:GetColorTalentCondition(id)
    return self._Model:GetColorTalentConditionById(id)
end

-- 获取颜色天赋树条件Id
function XTheatre4Control:GetColorTalentTreeConditionId(color)
    return self._Model:GetColorTreeConditionId(color)
end

-- 获取颜色天赋条件描述
function XTheatre4Control:GetColorTalentConditionDesc(id)
    local conditionId = self:GetColorTalentCondition(id)
    if XTool.IsNumberValid(conditionId) then
        return XConditionManager.GetConditionDescById(conditionId)
    end
    return ""
end

-- 获取颜色天赋标签列表
function XTheatre4Control:GetColorTalentTags(id)
    return self._Model:GetColorTalentTagsById(id)
end

-- 获取颜色天赋标签背景颜色列表
function XTheatre4Control:GetColorTalentTagBgColors(id)
    return self._Model:GetColorTalentTagBgColorsById(id)
end

-- 获取天赋数名称
function XTheatre4Control:GetColorTreeName(color)
    return self._Model:GetColorTreeName(color)
end

-- 获取关联的颜色天赋Ids
function XTheatre4Control:GetRelatedTalentIdsById(talentId)
    return self._Model:GetRelatedTalentIds(talentId)
end

-- 获取颜色天赋等级
function XTheatre4Control:GetColorTalentLevel(colorId, point)
    return self._Model:GetColorTalentLevel(colorId, point)
end

-- 获取颜色天赋当前点数和下一等级点数
---@return number, number 当前点数, 下一等级点数
function XTheatre4Control:GetColorTalentCurAndNextLevelPoint(colorId, curLevel)
    local curUnlockPoint = self._Model:GetColorTalentUnlockPoint(colorId, curLevel)
    local nextUnlockPoint = self._Model:GetColorTalentUnlockPoint(colorId, curLevel + 1)
    local point = self.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.ColoPoint, colorId)
    local curLevelPoint = point - curUnlockPoint
    local nextLevelPoint = nextUnlockPoint - curUnlockPoint
    curLevelPoint = curLevelPoint > 0 and curLevelPoint or 0
    nextLevelPoint = nextLevelPoint > 0 and nextLevelPoint or 1
    return curLevelPoint, nextLevelPoint
end

-- 检查颜色天赋是否已满级
function XTheatre4Control:CheckColorTalentIsMaxLevel(colorId, curLevel)
    return self._Model:CheckColorTalentIsMaxLevel(colorId, curLevel)
end

-- 检查颜色天赋是否参与冒险结算 配置为1时参与
function XTheatre4Control:CheckColorTalentJoinAdventureSettle(talentId)
    local joinAdventureSettle = self._Model:GetColorTalentJoinAdventureSettleById(talentId)
    return joinAdventureSettle == 1
end

--endregion

--region 奖励

-- 获取奖励资源类型
function XTheatre4Control:GetRewardElementType(id)
    return self._Model:GetRewardElementTypeById(id)
end

-- 获取奖励资源Id
function XTheatre4Control:GetRewardElementId(id)
    return self._Model:GetRewardElementIdById(id)
end

-- 获取奖励资源数量
function XTheatre4Control:GetRewardElementCount(id)
    return self._Model:GetRewardElementCountById(id)
end

-- 检查奖励是否显示 配置为1时显示
function XTheatre4Control:CheckShowReward(id)
    if not XTool.IsNumberValid(id) then
        return false
    end
    local isShow = self._Model:GetRewardIsSHowById(id)
    return isShow == 1
end

--endregion

--region 难度

-- 获取难度率
function XTheatre4Control:GetDifficultyRate(id)
    return self._Model:GetDifficultyDifficultRateById(id)
end

function XTheatre4Control:GetDifficultyBPExpRateById(id)
    return self._Model:GetDifficultyBPExpRateById(id)
end

-- 获取回复能量
function XTheatre4Control:GetDifficultyReEnergy(id)
    return self._Model:GetDifficultyReEnergyById(id)
end

-- 获取难度雪的特效
function XTheatre4Control:GetDifficultySnowEffect(id)
    return self._Model:GetDifficultySnowEffectById(id)
end

--endregion

--region 藏品

-- 获取藏品描述图标
function XTheatre4Control:GetItemDescIcon(id)
    return self._Model:GetItemDescIconById(id)
end

-- 获取藏品条件
function XTheatre4Control:GetItemCondition(id)
    return self._Model:GetItemConditionById(id)
end

function XTheatre4Control:GetItemBackPrice(id)
    return self._Model:GetItemBackPriceById(id)
end

function XTheatre4Control:GetItemCountLimit(id)
    return self._Model:GetItemCountLimitById(id)
end

function XTheatre4Control:GetItemType(id)
    return self._Model:GetItemTypeById(id)
end

-- 获取藏品条件描述
function XTheatre4Control:GetItemConditionDesc(id)
    local conditionId = self:GetItemCondition(id)
    if XTool.IsNumberValid(conditionId) then
        return XConditionManager.GetConditionDescById(conditionId)
    end
    return ""
end

-- 获取藏品里道具的数量
function XTheatre4Control:GetItemIsPropCount()
    local itemConfigs = self._Model:GetItemConfigs()
    local count = 0
    for _, config in pairs(itemConfigs) do
        if config.IsProp == 1 then
            count = count + 1
        end
    end
    return count
end

-- 检查藏品是否显示 配置为1时显示
function XTheatre4Control:CheckShowItem(id)
    if not XTool.IsNumberValid(id) then
        return false
    end
    local isShow = self._Model:GetItemIsShowById(id)
    return isShow == 1
end

--endregion

--region 块图标

-- 获取块默认图标
function XTheatre4Control:GetBlockIconDefaultIcon(id)
    return self._Model:GetBlockIconDefaultIconById(id)
end

-- 获取块颜色图标
function XTheatre4Control:GetBlockIconColorIcon(id)
    return self._Model:GetBlockIconColorIconById(id)
end

--endregion

--endregion

--region 本地缓存数据

-- 获取本地缓存的Key值
function XTheatre4Control:GetLocalCacheKey(key)
    local activityId = self._Model.ActivityData:GetActivityId()
    return string.format("XTheatre4_%s_%s_%s", key, XPlayer.Id, activityId)
end

-- 检查今日不再显示的值
function XTheatre4Control:CheckTodayDontShowValue(key)
    local localKey = self:GetLocalCacheKey(key)
    local recordDay = XSaveTool.GetData(localKey) or 0
    local curDay = XTime.GetSeverNextRefreshTime()
    return recordDay >= curDay
end

-- 保存今日不再显示的值
function XTheatre4Control:SaveTodayDontShowValue(key, isCheck)
    local localKey = self:GetLocalCacheKey(key)
    local curDay = isCheck and XTime.GetSeverNextRefreshTime() or 0
    XSaveTool.SaveData(localKey, curDay)
end

-- 检测是否回合结算跳过动画
function XTheatre4Control:CheckRoundSettleSkipAnim()
    local key = self:GetLocalCacheKey("RoundSettleSkipAnim")
    return XSaveTool.GetData(key) or false
end

-- 保存回合结算跳过动画
function XTheatre4Control:SaveRoundSettleSkipAnim(isSkip)
    local key = self:GetLocalCacheKey("RoundSettleSkipAnim")
    XSaveTool.SaveData(key, isSkip)
end

-- 获取相机跟随点最后位置和距离
---@return { PosX:number, PosY:number, Distance:number }
function XTheatre4Control:GetCameraFollowLastPos()
    local key = self:GetLocalCacheKey("CameraFollowLastPositionAndDistance")
    return XSaveTool.GetData(key) or nil
end

-- 记录相机跟随点最后位置和距离
---@param posX number 位置X
---@param posY number 位置Y
---@param distance number 距离
function XTheatre4Control:SaveCameraFollowLastPos(posX, posY, distance)
    local key = self:GetLocalCacheKey("CameraFollowLastPositionAndDistance")
    XSaveTool.SaveData(key, { PosX = posX, PosY = posY, Distance = distance })
end

-- 清理相机跟随点最后位置和距离
function XTheatre4Control:ClearCameraFollowLastPos()
    local key = self:GetLocalCacheKey("CameraFollowLastPositionAndDistance")
    XSaveTool.SaveData(key, nil)
end

-- 每局游戏的保存key
function XTheatre4Control:GetSaveKey()
    local time = 0
    local adventureData = self._Model:GetAdventureData()
    if adventureData then
        time = adventureData:GetStartTime()
    else
        XLog.Warning("[XTheatre4Control] adventureData不存在")
    end
    return "Theatre4" .. XPlayer.Id .. time .. "|"
end

-- 获取是否不显示进攻预警弹框
function XTheatre4Control:GetNotShowAttackWarningPopup()
    return self._Model.IsNotShowAttackWarning
end

-- 设置是否不显示进攻预警弹框
function XTheatre4Control:SetNotShowAttackWarningPopup(isNotShow)
    self._Model.IsNotShowAttackWarning = isNotShow
end

-- 检查是否开启镜头聚焦后恢复 1 开启 0 关闭
function XTheatre4Control:CheckOpenCameraFocusRecover()
    local isRecover = self:GetClientConfig("IsOpenGridFocusRecover", 1, true)
    return isRecover == 1
end

-- 获取聚焦到格子前相机的位置
---@return { PosX:number, PosY:number }
function XTheatre4Control:GetFocusGridBeforeCameraPos()
    return self._Model.FocusGridBeforeCameraPos
end

-- 保存聚焦到格子前相机的位置
---@param posX number 位置X
---@param posY number 位置Y
function XTheatre4Control:SaveFocusGridBeforeCameraPos(posX, posY)
    self._Model.FocusGridBeforeCameraPos = { PosX = posX, PosY = posY }
end

--endregion

--region 通用弹框

-- 显示通用弹框
function XTheatre4Control:ShowCommonPopup(title, content, sureCallback, closeCallback, data)
    if not title and not content then
        XLog.Error("ShowCommonPopUp error: title or content is nil")
        return
    end
    XLuaUiManager.Open("UiTheatre4PopupCommon", title, content, sureCallback, closeCallback, data)
end

-- 打开角色界面（单纯的角色展示界面）
function XTheatre4Control:OpenCharacterPanel()
    XLuaUiManager.Open("UiBattleRoomRoleDetail", nil, nil, nil, require("XUi/XUiTheatre4/BattleRoom/XUiTheatre4BattleRoomRoleDetail"))
end

-- 显示查看地图面板
---@param enterType number 进入类型
function XTheatre4Control:ShowViewMapPanel(enterType)
    if not XTool.IsNumberValid(enterType) then
        XLog.Error("ShowViewMapPanel error: enterType is nil")
        return
    end
    ---@type XUiTheatre4Game
    local luaUi = XLuaUiManager.GetTopLuaUi("UiTheatre4Game")
    if luaUi then
        luaUi:ShowViewMapPanel(enterType)
    end
end

-- 检查是否正在查看地图
---@param isNotTip boolean 是否不提示
function XTheatre4Control:CheckIsViewMap(isNotTip)
    local viewMapData = self:GetViewMapData()
    if viewMapData:GetIsViewing() then
        if not isNotTip then
            local enterType = viewMapData:GetEnterType()
            local enterName = self:GetClientConfig("EntryViewMapPopupName", enterType) or ""
            local content = self:GetClientConfig("ViewMapBtnClickTipContent") or ""
            self:ShowRightTipPopup(XUiHelper.FormatText(content, enterName))
        end
        return true
    end
    return false
end

-- 显示右上角提示弹框
function XTheatre4Control:ShowRightTipPopup(content)
    if not content then
        XLog.Error("ShowTopTipPopup error: content is nil")
        return
    end
    XLuaUiManager.OpenWithCallback("UiTheatre4TipsCommon", function(ui)
        ui.UiProxy.UiLuaTable:Refresh(content)
    end)
end

--endregion

--region 按钮注册相关

-- 获取按钮点击冷却时长 单位秒
function XTheatre4Control:GetButtonCoolTime()
    return self:GetClientConfig("BtnClickCoolingTime", 1, true) / 1000
end

-- 注册按钮点击事件
function XTheatre4Control:RegisterClickEvent(table, component, handle)
    local cdTime = self:GetButtonCoolTime() or 0
    local isOpenCd = cdTime > 0
    XUiHelper.RegisterClickEvent(table, component, handle, true, isOpenCd, cdTime)
end

--endregion

--region 音频相关

function XTheatre4Control:AdventurePlayBgm(bgmCueId)
    if not XTool.IsNumberValid(bgmCueId) then
        return
    end
    if XLuaAudioManager.GetCurrentMusicId() == bgmCueId then
        return
    end
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, bgmCueId)
end

--endregion

--region 结算数据

-- 获取结局配置
---@return XTableTheatre4Ending
function XTheatre4Control:GetEndingConfig(id)
    return self._Model:GetEndingConfigById(id)
end

-- 获取结局倍率
function XTheatre4Control:GetEndingFactor(id)
    return self._Model:GetEndingFactorById(id)
end

-- 获取结局最大繁荣度
function XTheatre4Control:GetEndingMaxProsperity(id)
    return self._Model:GetEndingMaxProsperityById(id)
end

-- 获取日结算信息
function XTheatre4Control:GetDailySettleData()
    return self._Model:GetDailySettleResult()
end

-- 清空日结算信息
function XTheatre4Control:ClearDailySettleData()
    self._Model:ClearDailySettleResult()
end

-- 获取历史最高分数
function XTheatre4Control:GetHistoryMaxScore()
    return self._Model.ActivityData:GetMaxScore()
end

-- 获取结算星级BP奖励
function XTheatre4Control:GetSettleStarBpExp()
    local preAdventureSettleData = self._Model:GetPreAdventureSettleData()
    if not preAdventureSettleData then
        return 0
    end
    return preAdventureSettleData:GetStarBpExp()
end

-- 获取结算奖励列表
function XTheatre4Control:GetSettleRewardGoods()
    local preAdventureSettleData = self._Model:GetPreAdventureSettleData()
    if not preAdventureSettleData then
        return {}
    end
    return preAdventureSettleData:GetRewardGoods()
end

-- 检查结局是否是新结局 次数为1时为新结局
function XTheatre4Control:CheckEndingIsNew(endingId)
    local passCount = self._Model.ActivityData:GetEndingPassCount(endingId)
    return passCount == 1
end

-- 获取冒险结算信息
function XTheatre4Control:GetAdventureSettleData()
    return self._Model:GetAdventureSettleResult()
end

-- 检查冒险结算信息是否未空
function XTheatre4Control:CheckAdventureSettleDataEmpty()
    return self._Model:CheckAdventureSettleResultEmpty()
end

-- 清空冒险结算信息
function XTheatre4Control:ClearAdventureSettleData()
    self._Model:ClearAdventureSettleResult()
end

--endregion

--region 编队数据

-- 获取编队
---@return XTheatre4Team
function XTheatre4Control:GetTeam()
    local team = self._Model:GetTeam()
    team:UpdateAutoSave(false)
    team:UpdateTeamData(self._Model:GetTeamData())
    team:UpdateSaveCallback(function(inTeam)
        -- 同步队伍数据
        self:SetTeamDataRequest(inTeam:GetTeamData())
    end)
    return team
end

-- 打开战斗界面之前
---@param uiName string 界面名
function XTheatre4Control:BeforeOpenBattlePanel(uiName, stageId, mapId, posX, posY)
    if string.IsNilOrEmpty(uiName) then
        XLog.Error("BeforeOpenBattlePanel error: uiName is nil")
        return
    end
    XLuaUiManager.CloseWithCallback(uiName, function()
        self:OpenBattlePanel(stageId, mapId, posX, posY)
    end)
end

-- 打开战斗界面
---@param stageId number 关卡Id
---@param mapId number 地图Id
---@param posX number 地图X坐标
---@param posY number 地图Y坐标
function XTheatre4Control:OpenBattlePanel(stageId, mapId, posX, posY)
    -- 打印关卡Id
    if XEnumConst.Theatre4.IsDebug then
        XLog.Warning("<color=#F1D116>Theatre4:</color> OpenBattlePanel stageId: " .. stageId)
    end
    local extraData
    if XTool.IsNumberValid(mapId) then
        extraData = { MapId = mapId, PosX = posX, PosY = posY }
    end
    local team = self:GetTeam()
    team:UpdateAutoSave(true)
    team:UpdateExtraData(extraData)
    XLuaUiManager.Open(
            "UiBattleRoleRoom",
            stageId,
            team,
            require("XUi/XUiTheatre4/BattleRoom/XUiTheatre4BattleRoleRoom"))
end

--endregion

--region 弹框相关

-- 获取具有弹框数据的弹框类型列表
---@return number[] 弹框类型列表
function XTheatre4Control:GetHasDataPopupTypeList()
    local types = {}
    for _, type in pairs(XEnumConst.Theatre4.PopupType) do
        if type ~= XEnumConst.Theatre4.PopupType.None and not self:CheckPopupDataEmptyByType(type) then
            table.insert(types, type)
        end
    end
    if #types > 1 then
        -- 优先级排序 从小到大
        table.sort(types, function(a, b)
            return a < b
        end)
    end
    return types
end

-- 获取下一个需要弹的弹框类型 高优先级的弹出
---@return number 弹框类型
function XTheatre4Control:GetNextPopupType()
    local types = self:GetHasDataPopupTypeList()
    if XTool.IsTableEmpty(types) then
        return XEnumConst.Theatre4.PopupType.None
    end
    local lastPopupType = self._Model:GetCurrentPopupType()
    for _, type in ipairs(types) do
        if not self._Model:HasCurrentPopupType(type) and (lastPopupType == XEnumConst.Theatre4.PopupType.None or type < lastPopupType) then
            return type
        end
    end
    return XEnumConst.Theatre4.PopupType.None
end

-- 检查是否需要打开下一个弹框
---@param uiName string 界面名
---@param isNeedClose boolean 是否需要关闭当前弹框
function XTheatre4Control:CheckNeedOpenNextPopup(uiName, isNeedClose, ...)
    -- 移除上一个弹框类型
    if isNeedClose then
        self._Model:RemoveCurrentPopupTypeByUiName(uiName)
    end
    -- 获取下一个弹框类型
    local nextPopupType = self:GetNextPopupType()
    if nextPopupType == XEnumConst.Theatre4.PopupType.None then
        -- 直接关闭上一个弹框
        if isNeedClose then
            XLuaUiManager.Close(uiName)
        end
        return
    end
    if isNeedClose then
        -- 关闭上一个后打开下一个
        local arg = { ... }
        XLuaUiManager.CloseWithCallback(uiName, function()
            self:OpenPopup(nextPopupType, table.unpack(arg))
        end)
    else
        -- 直接打开下一个
        self:OpenPopup(nextPopupType, ...)
    end
end

-- 检查是否有弹框正在打开中
function XTheatre4Control:CheckPopupOpening()
    return self._Model:HasPopupOpening()
end

-- 打开弹框
function XTheatre4Control:OpenPopup(type, ...)
    -- 检查是否有同类型弹框正在打开中
    if self._Model:HasCurrentPopupType(type) then
        return
    end
    local popupData = self._Model:DequeuePopupData(type)
    local uiName = self._Model:GetPopupUiName(type)
    local methodName = self._Model:GetPopupMethodName(type)
    if methodName and self[methodName] then
        self._Model:AddCurrentPopupType(type)
        self[methodName](self, uiName, popupData, ...)
    else
        XLog.Error("OpenPopup error: methodName is nil.PopupType" .. type)
    end
end

-- 打开招募成员弹框
---@param transactionData XTheatre4Transaction
function XTheatre4Control:OpenRecruitMemberPopup(uiName, transactionData)
    if not transactionData then
        return
    end
    XLuaUiManager.Open(uiName)
end

-- 打开物品替换弹框
---@param itemId number 物品Id
function XTheatre4Control:OpenItemReplacePopup(uiName, itemId)
    if not XTool.IsNumberValid(itemId) then
        return
    end
    XLuaUiManager.Open(uiName, itemId)
end

-- 打开物品选择弹框
---@param transactionData XTheatre4Transaction
function XTheatre4Control:OpenItemSelectPopup(uiName, transactionData)
    if not transactionData then
        return
    end
    XLuaUiManager.Open(uiName, transactionData:GetId())
end

-- 打开奖励选择弹框
---@param transactionData XTheatre4Transaction
function XTheatre4Control:OpenRewardSelectPopup(uiName, transactionData)
    if not transactionData then
        return
    end
    XLuaUiManager.Open(uiName, transactionData:GetId())
end

-- 打开战斗奖励弹框
---@param transactionData XTheatre4Transaction
function XTheatre4Control:OpenFightRewardPopup(uiName, transactionData)
    if not transactionData then
        return
    end
    XLuaUiManager.Open(uiName, transactionData:GetId())
end

-- 打开资产奖励弹框
---@param rewardList table 资产奖励列表
function XTheatre4Control:OpenAssetRewardPopup(uiName, rewardList)
    if not rewardList then
        return
    end
    XLuaUiManager.Open(uiName, nil, rewardList)
end

-- 打开天赋选择弹框
---@param talentData { Color: number, TalentIds: number[] }
function XTheatre4Control:OpenTalentSelectPopup(uiName, talentData)
    if not talentData then
        return
    end
    XLuaUiManager.Open(uiName, talentData.Color, talentData.TalentIds)
end

-- 打开天赋升级弹框
---@param colorLevelUpData { Color: number, TalentIds: number[] }
function XTheatre4Control:OpenTalentLevelUpPopup(uiName, colorLevelUpData)
    if not colorLevelUpData then
        return
    end
    XLuaUiManager.Open(uiName, colorLevelUpData.Color, colorLevelUpData.TalentIds)
end

-- 打开到达新区域弹框
---@param mapData { MapGroup: number, MapId: number }
function XTheatre4Control:OpenArriveNewAreaPopup(uiName, mapData)
    if not mapData then
        return
    end
    ---@type XUiTheatre4Game
    local luaUi = XLuaUiManager.GetTopLuaUi("UiTheatre4Game")
    if luaUi then
        luaUi:PlayNewChapterOpen(uiName, mapData.MapGroup, mapData.MapId)
    end
end

-- 播放扣血特效
---@param effectData { IsBoss: boolean, MapId: number, PunishCountdown:number, IsHp:boolean }
function XTheatre4Control:PlayBloodEffect(_, effectData)
    if not effectData then
        return
    end
    ---@type XUiTheatre4Game
    local luaUi = XLuaUiManager.GetTopLuaUi("UiTheatre4Game")
    if not luaUi then
        return
    end
    if effectData.IsBoss then
        if effectData.PunishCountdown == 1 and not self:GetNotShowAttackWarningPopup() and not effectData.IsHp then
            XLuaUiManager.Open("UiTheatre4PopupAttackTips", effectData.MapId, function()
                luaUi:PlayBossGridEffect(effectData.MapId)
            end)
        else
            luaUi:PlayBossGridEffect(effectData.MapId)
        end
    end
    if effectData.IsHp then
        XUiManager.TipMsg(self:GetClientConfig("BossAttackDrainLifeTip", 1))
        luaUi:PlayScreenEffectHpDecrease()
    end
end

-- 检查弹框数据是否为空通过弹框类型
function XTheatre4Control:CheckPopupDataEmptyByType(type)
    return self._Model:CheckPopupDataEmpty(type)
end

-- 清空弹框数据通过弹框类型
function XTheatre4Control:ClearPopupDataByType(type)
    self._Model:ClearPopupDataByType(type)
end

-- 清空所有弹框数据
function XTheatre4Control:ClearAllPopupData()
    self._Model:ClearAllPopupData()
end

-- 检查弹框是否存在到达新区域弹框
function XTheatre4Control:CheckHasArriveNewAreaPopup()
    return not self:CheckPopupDataEmptyByType(XEnumConst.Theatre4.PopupType.ArriveNewArea)
end

-- 打开事件界面
---@param eventId number 事件Id
---@param mapId number 地图Id
---@param gridData XTheatre4Grid 格子数据
---@param callback function 回调
---@param cancelCallback function 取消回调
function XTheatre4Control:OpenEventUi(eventId, mapId, gridData, fateUid, callback, cancelCallback)
    if not XTool.IsNumberValid(eventId) then
        if cancelCallback then
            cancelCallback()
        end
        if callback then
            callback()
        end
        return
    end
    local storyId = self:GetEventStoryId(eventId)
    if not XTool.IsNumberValid(storyId) then
        XLuaUiManager.Open("UiTheatre4Event", eventId, mapId, gridData, fateUid, callback, cancelCallback)
    else
        -- 打开剧情
        XDataCenter.MovieManager.PlayMovie(storyId, function()
            XLuaUiManager.Open("UiTheatre4Event", eventId, mapId, gridData, fateUid, callback, cancelCallback)
        end, nil, nil, false)
    end
end

--endregion

--region 查看地图相关

-- 获取查看地图数据
---@return XTheatre4ViewMapData
function XTheatre4Control:GetViewMapData()
    if not self._Model.ViewMapData then
        self._Model.ViewMapData = require("XModule/XTheatre4/XEntity/ViewMap/XTheatre4ViewMapData").New()
    end
    return self._Model.ViewMapData
end

-- 清理查看地图数据
function XTheatre4Control:ClearViewMapData()
    self._Model.ViewMapData = nil
end

-- 开始查看地图
function XTheatre4Control:StartViewMap(enterType)
    local viewMapData = self:GetViewMapData()
    local curUiNames = self._Model:GetAllCurrentPopupUiName(true)
    for _, uiName in ipairs(curUiNames) do
        local luaUi = XLuaUiManager.GetTopLuaUi(uiName)
        if luaUi then
            if luaUi.GetPopupArgs then
                local args = luaUi:GetPopupArgs()
                if args then
                    if XEnumConst.Theatre4.IsDebug then
                        XLog.Debug(string.format("<color=#F1D116>Theatre4:</color> StartViewMap: uiName=%s, args=%s", uiName, table.concat(args, ",")))
                    end
                    viewMapData:AddPopupArgs(uiName, args)
                else
                    XLog.Error("PopupArgs is nil uiName: " .. uiName)
                end
            else
                XLog.Error("GetPopupArgs is nil uiName: " .. uiName)
            end
            luaUi:Remove()
        end
    end
    -- 关闭Game上层所有界面（避免有其它ui）
    XLuaUiManager.CloseAllUpperUi("UiTheatre4Game")
    viewMapData:SetIsViewing(true)
    viewMapData:SetEnterType(enterType)
    if XEnumConst.Theatre4.IsDebug then
        XLog.Debug(string.format("<color=#F1D116>Theatre4:</color> StartViewMap enterType: %s, curUiNames: %s", enterType, table.concat(curUiNames, ",")))
    end
end

-- 结束查看地图
function XTheatre4Control:EndViewMap()
    local viewMapData = self:GetViewMapData()
    local curUiNames = self._Model:GetAllCurrentPopupUiName()
    for _, uiName in ipairs(curUiNames) do
        local args = viewMapData:GetPopupArgs(uiName)
        if args then
            if XEnumConst.Theatre4.IsDebug then
                XLog.Debug(string.format("<color=#F1D116>Theatre4:</color> EndViewMap uiName: %s, args: %s", uiName, table.concat(args, ",")))
            end
            XLuaUiManager.Open(uiName, table.unpack(args))
        else
            XLuaUiManager.Open(uiName)
        end
    end
    viewMapData:SetIsViewing(false)
    viewMapData:ClearPopupArgs()
    if XEnumConst.Theatre4.IsDebug then
        XLog.Debug(string.format("<color=#F1D116>Theatre4:</color> EndViewMap curUiNames: %s", table.concat(curUiNames, ",")))
    end
end

--endregion

--region 难度星级相关

-- 获取难度星级奖励BP经验
function XTheatre4Control:GetDifficultyStarRewardBpExp(starId)
    return self._Model:GetDifficultyStarRewardBpExpById(starId) or 0
end

-- 获取难度星级Ids
---@param mapId number 地图Id
function XTheatre4Control:GetDifficultyStarIds(mapId)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return {}
    end

    local chapterCount = XTool.IsNumberValid(mapId) and select(2, adventureData:GetChapterData(mapId)) or adventureData:GetChapterCount()
    if chapterCount <= 0 then
        return {}
    end

    local curDifficulty = adventureData:GetDifficulty()
    local starGroupIds = self._Model:GetDifficultyStarGroupIdsById(curDifficulty)
    local starGroupId = starGroupIds and starGroupIds[chapterCount] or 0
    if starGroupId <= 0 then
        return {}
    end
    return self._Model:GetDifficultyStarIds(starGroupId)
end

-- 获取难度星级标题
---@param starIds number[] 星级Ids
function XTheatre4Control:GetDifficultyStarTitle(starIds)
    if XTool.IsTableEmpty(starIds) then
        return ""
    end
    for _, id in ipairs(starIds) do
        local title = self._Model:GetDifficultyStarTitleById(id)
        if not string.IsNilOrEmpty(title) then
            return title
        end
    end
    return ""
end

-- 获取难度星级描述
---@param starIds number[] 星级Ids
function XTheatre4Control:GetDifficultyStarDesc(starIds)
    if XTool.IsTableEmpty(starIds) then
        return ""
    end

    -- 取第一个星级的类型
    local starType = self._Model:GetDifficultyStarTypeById(starIds[1])
    if starType == XEnumConst.Theatre4.StarType.BossCountDown then
        return self:GetStarBossCountDownDesc(starIds)
    elseif starType == XEnumConst.Theatre4.StarType.Condition then
        return self:GetStarConditionDesc(starIds)
    end
    return ""
end

-- 获取难度星级倒计时描述
---@param starIds number[] 星级Ids
function XTheatre4Control:GetStarBossCountDownDesc(starIds)
    local punishCountdown = self:GetRemainBossCountDown()
    for _, id in ipairs(starIds) do
        local starParams = self._Model:GetDifficultyStarParamsById(id)
        if punishCountdown >= (starParams[1] or 0) then
            return XUiHelper.FormatText(self:GetClientConfig("CountDownDesc", 1), punishCountdown)
        end
    end
    return ""
end

-- 获取难度星级条件描述
---@param starIds number[] 星级Ids
function XTheatre4Control:GetStarConditionDesc(starIds)
    local desc = ""
    for _, id in ipairs(starIds) do
        local starParams = self._Model:GetDifficultyStarParamsById(id)
        local conditionId = starParams[1] or 0
        local isMeet, conditionDesc = self:CheckStarConditionIsMeet(conditionId)
        if isMeet then
            desc = conditionDesc
        end
    end
    return desc
end

-- 获取难度星级条件数量
---@param starId number 星级Id
function XTheatre4Control:GetDifficultyStarConditionCount(starId)
    local starType = self._Model:GetDifficultyStarTypeById(starId)
    local starParams = self._Model:GetDifficultyStarParamsById(starId)
    if starType == XEnumConst.Theatre4.StarType.BossCountDown then
        return starParams[1] or 0
    elseif starType == XEnumConst.Theatre4.StarType.Condition then
        local conditionId = starParams[1] or 0
        local conditionIndex = starParams[2] or 0
        local conditionTemplate = XConditionManager.GetConditionTemplate(conditionId)
        if conditionTemplate and conditionTemplate.Params then
            return conditionTemplate.Params[conditionIndex] or 0
        end
    end
    return 0
end

-- 获得剩余Boss倒计时
---@param mapId number 地图Id
function XTheatre4Control:GetRemainBossCountDown(mapId)
    local bossGridData = self.MapSubControl:GetCurrentBossGridData(mapId, true)
    if not bossGridData then
        return -1
    end
    return bossGridData:GetGridPunishCountdown()
end

-- 检查星级条件是否满足
---@param conditionId number 条件Id
function XTheatre4Control:CheckStarConditionIsMeet(conditionId)
    if not XTool.IsNumberValid(conditionId) then
        return true, ""
    end
    return XConditionManager.CheckCondition(conditionId)
end

-- 检查当前难度星级是否满足
---@param starId number 星级Id
---@param mapId number 地图Id
function XTheatre4Control:CheckCurDifficultyStarIsMeet(starId, mapId)
    if not XTool.IsNumberValid(starId) then
        return false
    end
    local starType = self._Model:GetDifficultyStarTypeById(starId)
    local starParams = self._Model:GetDifficultyStarParamsById(starId)
    local isMeet = false
    if starType == XEnumConst.Theatre4.StarType.BossCountDown then
        local countDown = self:GetRemainBossCountDown(mapId)
        isMeet = countDown >= (starParams[1] or 0)
    elseif starType == XEnumConst.Theatre4.StarType.Condition then
        local conditionId = starParams[1] or 0
        isMeet = self:CheckStarConditionIsMeet(conditionId)
    end
    return isMeet
end

-- 检查是否显示星级下降提示 只处理按boss倒计时的星级
function XTheatre4Control:CheckShowStarDownTip()
    local starIds = self:GetDifficultyStarIds()
    if XTool.IsTableEmpty(starIds) then
        return false
    end
    for _, starId in pairs(starIds) do
        local starType = self._Model:GetDifficultyStarTypeById(starId)
        local starParams = self._Model:GetDifficultyStarParamsById(starId)
        if starType == XEnumConst.Theatre4.StarType.BossCountDown then
            local countDown = self:GetRemainBossCountDown()
            if countDown == (starParams[1] or 0) then
                return true
            end
        end
    end
    return false
end

--endregion

--region time back
-- 时间回溯
function XTheatre4Control:TimeBackRequest()
    local effects = self.EffectSubControl:GetEffectsByType(XEnumConst.Theatre4.EffectType.Type423)
    if #effects == 0 then
        XLog.Warning("[XTheatre4Control] 时间回溯effect数量为0")
        return
    end
    XLuaUiManager.Close("UiTheatre4BubbleBacktrack")
    local effectId = effects[1]:GetEffectId()
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_TIME_BACK, function()
        self:UseSkillEffectRequest(effectId, {})
    end)
end
--endregion

--region replace map image and play effect
function XTheatre4Control:GetMapReplaceAndEffectConfig()
    local chapterData = self._Model:GetLastChapterData()
    if not chapterData then
        XLog.Warning("[XTheatre4Control] GetMapReplaceAndEffectConfig chapterData is nil")
        return
    end
    local mapId = chapterData:GetMapId()
    local mapGroupId = chapterData:GetMapGroup()
    local mapGroupConfig = self._Model:GetMapGroupConfigByMapGroupAndMapId(mapGroupId, mapId)
    if not mapGroupConfig then
        XLog.Warning("[XTheatre4Control] GetMapReplaceAndEffectConfig mapGroupConfig is nil")
        return
    end
    local spEffectGroup = mapGroupConfig.SpEffectGroup
    if spEffectGroup <= 0 then
        return
    end
    local scientificSpEffectConfigs = self._Model:GetScientificSpEffectConfigs()
    local configFound = nil
    local difficulty = self:GetDifficulty()
    local awakenPoint = self.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.AwakeningPoint)
    local colorPoint = -1
    for i = 1, 99 do
        local possibleId = spEffectGroup * 100 + i
        local config = scientificSpEffectConfigs[possibleId]
        if not config then
            break
        end
        if config.Difficulty == difficulty then
            if awakenPoint >= config.ColorPoint then
                if config.ColorPoint > colorPoint then
                    configFound = config
                    colorPoint = config.ColorPoint
                end
            end
            break
        end
    end

    if not configFound then
        XLog.Warning("[XTheatre4Control] GetMapReplaceAndEffectConfig configs is empty, 请把Theatre4ScientificSpEffect的id, 配置为groupId + 01的格式, 有利于查找")
        return
    end
    
    return configFound
end

function XTheatre4Control:GetTraceBackConfigByIdAndDifficulty(traceBackGroupId, difficulty)
    return self._Model:GetTraceBackConfigByIdAndDifficulty(traceBackGroupId, difficulty)
end

return XTheatre4Control
