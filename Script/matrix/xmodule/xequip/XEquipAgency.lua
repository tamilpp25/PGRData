---@class XEquipAgency : XAgency
---@field _Model XEquipModel
local XEquipAgency = XClass(XAgency, "XEquipAgency")
local XUiPanelEquipV2P6 = require("XUi/XUiCharacterV2P6/Grid/XUiPanelEquipV2P6")
local XUiPanelCharInfoWithEquip = require("XUi/XUiCharacterV2P6/Grid/XUiPanelCharInfoWithEquip")
local XUiPanelCharInfoWithEquipOther = require("XUi/XUiCharacterV2P6/Grid/XUiPanelCharInfoWithEquipOther")

function XEquipAgency:OnInit()
    --初始化一些变量
end

function XEquipAgency:InitRpc()
    -- 注册服务器事件
    XRpc.NotifyEquipDataList = Handler(self, self.NotifyEquipDataList)
    XRpc.NotifyEquipChipGroupList = Handler(self, self.NotifyEquipChipGroupList)
    XRpc.NotifyEquipChipAutoRecycleSite = Handler(self, self.NotifyEquipChipAutoRecycleSite)
    XRpc.NotifyEquipAutoRecycleChipList = Handler(self, self.NotifyEquipAutoRecycleChipList)
end

function XEquipAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

-------rpc start--------
-- 登陆初始化装备数据
function XEquipAgency:InitEquipData(equipList)
    self._Model:InitEquipData(equipList)
    local equipDic = self._Model:GetEquipDic()
    XDataCenter.EquipManager.InitEquipData(equipDic)
    XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_DATA_INIT_NOTIFY)
end

function XEquipAgency:NotifyEquipDataList(data)
    if data.EquipDataList then
        self._Model:UpdateEquipData(data.EquipDataList)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_DATA_LIST_UPDATE_NOTYFY)
    end
end

function XEquipAgency:NotifyEquipChipGroupList(data)
    XDataCenter.EquipManager.NotifyEquipChipGroupList(data)
end

function XEquipAgency:NotifyEquipChipAutoRecycleSite(data)
    XDataCenter.EquipManager.NotifyEquipChipAutoRecycleSite(data)
end

function XEquipAgency:NotifyEquipAutoRecycleChipList(data)
    XDataCenter.EquipManager.NotifyEquipAutoRecycleChipList(data)
end

-- 穿戴装备
function XEquipAgency:PutOn(characterId, equipId, cb)
    if not XMVCA.XCharacter:IsOwnCharacter(characterId) then
        XUiManager.TipText("EquipPutOnNotChar")
        return
    end

    local equipSpecialCharacterId = XDataCenter.EquipManager.GetEquipSpecialCharacterId(equipId)
    if equipSpecialCharacterId and equipSpecialCharacterId ~= characterId then
        local char = XMVCA.XCharacter:GetCharacter(equipSpecialCharacterId)
        if char then
            local characterName = XMVCA.XCharacter:GetCharacterName(equipSpecialCharacterId)
            local gradeName = XMVCA.XCharacter:GetCharGradeName(equipSpecialCharacterId, char.Grade)
            XUiManager.TipMsg(XUiHelper.GetText("EquipPutOnSpecialCharacterIdNotEqual", characterName, gradeName))
        end
        return
    end

    local characterEquipType = XMVCA.XCharacter:GetCharacterEquipType(characterId)
    if not XDataCenter.EquipManager.IsTypeEqual(equipId, characterEquipType) then
        XUiManager.TipText("EquipPutOnEquipTypeError")
        return
    end
    local site = XDataCenter.EquipManager.GetEquipSite(equipId)
    local req = { CharacterId = characterId, Site = site, EquipId = equipId }

    local curEquip = XDataCenter.EquipManager.GetWearingEquipBySite(characterId, site)
    XNetwork.Call("EquipPutOnRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local equip = self:GetEquip(equipId)

        local charIdDic = {}
        local oldEquipId = XDataCenter.EquipManager.GetWearingEquipIdBySite(characterId, site)
        --请求的装备从原来的角色替换到当前角色
        if oldEquipId and oldEquipId ~= 0 then
            local oldEquip = self:GetEquip(oldEquipId)
            local switchCharacterId = XDataCenter.EquipManager.GetEquipWearingCharacterId(equipId)
            if XDataCenter.EquipManager.IsWeapon(oldEquipId) then
                oldEquip:PutOn(switchCharacterId)
            else
                oldEquip:TakeOff()
            end
            XDataCenter.EquipGuideManager.HandleEquipGuidePutOnOrTakeOff({ equipId }, switchCharacterId, false)
        elseif curEquip then --目标角色更换了非目标装备
            XDataCenter.EquipGuideManager.HandleEquipGuidePutOnOrTakeOff({ curEquip.Id }, characterId, false)
        end

        if equip:IsWearing() then
            charIdDic[equip.CharacterId] = true
        end
        charIdDic[characterId] = true
        equip:PutOn(characterId)

        self:TipEquipOperation(nil, XUiHelper.GetText("EquipPutOnSuc"))

        XDataCenter.EquipGuideManager.HandleEquipGuidePutOnOrTakeOff({ equipId }, characterId, true)

        -- 更新角色数据
        XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_PUTON_NOTYFY, equipId)
        XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_PUTON_NOTYFY, equipId)

        if equip:IsWeapon() then
            XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_PUTON_WEAPON_NOTYFY, characterId, equipId)
        end
        
        if cb then cb() end
    end)
end

-- 卸下装备
function XEquipAgency:TakeOff(equipIds)
    if not equipIds or not next(equipIds) then
        XLog.Error("XEquipAgency:TakeOff错误, 参数equipIds不能为为空")
        return
    end

    for _, equipId in pairs(equipIds) do
        if not XDataCenter.EquipManager.IsWearing(equipId) then
            XUiManager.TipText("EquipTakeOffNotChar")
            return
        end
    end

    local req = {EquipIds = equipIds}
    XNetwork.Call("EquipTakeOffRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self:TipEquipOperation(nil, XUiHelper.GetText("EquipTakeOffSuc"))

        local charIdDic = {}
        for _, equipId in pairs(equipIds) do
            local equip = self:GetEquip(equipId)
            local characterId = equip.CharacterId
            charIdDic[characterId] = true
            equip:TakeOff()
            XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_TAKEOFF_NOTYFY, equipId)
            XDataCenter.EquipGuideManager.HandleEquipGuidePutOnOrTakeOff({ equipId }, characterId, false)
        end

        -- 更新角色数据
        XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        XEventManager.DispatchEvent(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, equipIds)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, equipIds)
    end)
end

-- 替换装备意识套装
function XEquipAgency:EquipSuitPrefabEquip(prefabIndex, characterId, afterCheckCb)
    if not characterId then
        return
    end
    local suitPrefabInfo = XDataCenter.EquipManager.GetSuitPrefabInfo(prefabIndex)
    if not suitPrefabInfo then
        return
    end

    local oldEquipSiteToIdDic = {}
    local oldEquipIds = XDataCenter.EquipManager.GetCharacterWearingAwarenessIds(characterId)
    for _, equipId in pairs(oldEquipIds) do
        local equipSite = XDataCenter.EquipManager.GetEquipSite(equipId)
        oldEquipSiteToIdDic[equipSite] = equipId
    end

    local isDifferent = false
    local newEquipSiteToIdDic = {}
    local newEquipIds = suitPrefabInfo:GetEquipIds()
    local newEquipIdDic = {}
    for _, equipId in pairs(newEquipIds) do
        local equipSpecialCharacterId = XDataCenter.EquipManager.GetEquipSpecialCharacterId(equipId)
        if equipSpecialCharacterId and equipSpecialCharacterId ~= characterId then
            local char = XMVCA.XCharacter:GetCharacter(equipSpecialCharacterId)
            local characterName = XMVCA.XCharacter:GetCharacterName(equipSpecialCharacterId)
            local gradeName = XMVCA.XCharacter:GetCharGradeName(equipSpecialCharacterId, char.Grade)
            XUiManager.TipMsg(XUiHelper.GetText("EquipPutOnSpecialCharacterIdNotEqual", characterName, gradeName))
            return
        end

        local equipSite = XDataCenter.EquipManager.GetEquipSite(equipId)
        newEquipSiteToIdDic[equipSite] = equipId
        newEquipIdDic[equipId] = true
        if oldEquipSiteToIdDic[equipSite] ~= equipId then
            isDifferent = true
        end
    end

    for _, oldequipId in pairs(oldEquipIds) do
        if not newEquipIdDic[oldequipId] then
            isDifferent = true
        end
    end

    if not isDifferent then
        XUiManager.TipText("EquipSuitPrefabEquipSame")
        return
    end

    local req = {CharacterId = characterId, GroupId = suitPrefabInfo:GetGroupId()}
    XNetwork.Call("EquipPutOnChipGroupRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local charIdDic = {}
        XDataCenter.EquipGuideManager.HandleEquipGuidePutOnOrTakeOff(oldEquipIds, characterId, false)
        for _, equipId in pairs(oldEquipIds) do
            local equip = self:GetEquip(equipId)
            equip:TakeOff()
        end
        
        for _, equipId in pairs(newEquipIds) do
            local equip = self:GetEquip(equipId)
            -- 记录卸下装备的角色
            if equip:IsWearing() then
                charIdDic[equip.CharacterId] = true
            end
            equip:PutOn(characterId)
        end
        charIdDic[characterId] = true
        XDataCenter.EquipGuideManager.HandleEquipGuidePutOnOrTakeOff(newEquipIds, characterId, true)

        local equipIds = {}
        for _, equipSite in pairs(XEnumConst.EQUIP.EQUIP_SITE.AWARENESS) do
            local equipId = oldEquipSiteToIdDic[equipSite] or newEquipSiteToIdDic[equipSite]
            if equipId then
                table.insert(equipIds, equipId)
            end
        end

        XUiManager.TipText("EquipSuitPrefabEquipSuc")
        if afterCheckCb then
            afterCheckCb()
        end

        -- 更新角色数据
        XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, equipIds)
        XEventManager.DispatchEvent(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, equipIds)
    end)
end

-- 请求升级
function XEquipAgency:LevelUp(equipId, equipIdCheckList, useItemDic, callBackBeforeEvent)
    if not equipId then
        XLog.Error("XEquipAgency.LevelUp错误: 参数equipId不能为空")
        return
    end

    if XDataCenter.EquipManager.IsMaxLevel(equipId) then
        XUiManager.TipText("EquipLevelUpMaxLevel")
        return
    end

    local costEmpty = true
    local costMoney = 0
    if equipIdCheckList and next(equipIdCheckList) then
        costEmpty = nil
        costMoney = costMoney + XDataCenter.EquipManager.GetEatEquipsCostMoney(equipIdCheckList)
    end

    if useItemDic and next(useItemDic) then
        costEmpty = nil
        costMoney = costMoney + XDataCenter.EquipManager.GetEatItemsCostMoney(useItemDic)
        XMessagePack.MarkAsTable(useItemDic)
    end

    if costEmpty then
        XUiManager.TipText("EquipLevelUpItemEmpty")
        return
    end

    if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(
        XDataCenter.ItemManager.ItemId.Coin,
        costMoney,
        1,
        function()
            self:LevelUp(equipId, equipIdCheckList, useItemDic, callBackBeforeEvent)
        end,
        "EquipBreakCoinNotEnough")
    then
        return
    end

    local useEquipIdList = {}
    local containPrecious = false
    for tmpEquipId in pairs(equipIdCheckList) do
        containPrecious = containPrecious or self:GetEquipStar(self:GetEquipTemplateId(tmpEquipId)) >= XEnumConst.EQUIP.CAN_NOT_AUTO_EAT_STAR
        table.insert(useEquipIdList, tmpEquipId)
    end

    local req = {EquipId = equipId, UseEquipIdList = useEquipIdList, UseItems = useItemDic}
    local callFunc = function()
        XNetwork.Call("EquipLevelUpRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local charIdDic = {}
            for _, tmpEquipId in pairs(useEquipIdList) do
                local tmpEquip = self:GetEquip(tmpEquipId)
                if tmpEquip:IsWearing() then
                    charIdDic[tmpEquip.CharacterId] = true
                end
                self:DeleteEquip(tmpEquipId)
            end

            local equip = self:GetEquip(equipId)
            equip:SetLevel(res.Level)
            equip:SetExp(res.Exp)
            if equip:IsWearing() then
                charIdDic[equip.CharacterId] = true
            end

            local closeCb
            if XDataCenter.EquipManager.CanBreakThrough(equipId) then
                closeCb = function()
                    self:TipEquipOperation(equipId, nil, nil, true)
                end
            end
            self:TipEquipOperation(nil, XUiHelper.GetText("EquipStrengthenSuc"), closeCb, true)

            if callBackBeforeEvent then
                callBackBeforeEvent()
            end

            -- 更新角色数据
            XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY, equipId)
            XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY, equipId)
        end)
    end

    if containPrecious then
        local title = XUiHelper.GetText("EquipStrengthenPreciousTipTitle")
        local content = XUiHelper.GetText("EquipStrengthenPreciousTipContent")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
    else
        callFunc()
    end
end

-- 请求突破
function XEquipAgency:Breakthrough(equipId)
    if not equipId then
        XLog.Error("XEquipAgency.Breakthrough错误: 参数equipId不能为空")
        return
    end

    if XDataCenter.EquipManager.IsMaxBreakthrough(equipId) then
        XUiManager.TipText("EquipBreakMax")
        return
    end

    if not XDataCenter.EquipManager.IsReachBreakthroughLevel(equipId) then
        XUiManager.TipText("EquipBreakMinLevel")
        return
    end

    local consumeItems = XDataCenter.EquipManager.GetBreakthroughConsumeItems(equipId)
    if not XDataCenter.ItemManager.CheckItemsCount(consumeItems) then
        XUiManager.TipText("EquipBreakItemNotEnough")
        return
    end

    if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(
        XDataCenter.EquipManager.GetBreakthroughUseItemId(equipId),
        XDataCenter.EquipManager.GetBreakthroughUseMoney(equipId),
        1,
        function()
            self:Breakthrough(equipId)
        end,
        "EquipBreakCoinNotEnough")
    then
        return
    end

    local title = XUiHelper.GetText("EquipBreakthroughConfirmTiltle")
    local content = XUiHelper.GetText("EquipBreakthroughConfirmContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        XNetwork.Call("EquipBreakthroughRequest", {EquipId = equipId}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local equip = self:GetEquip(equipId)
            equip:BreakthroughOneTime()

            if equip:IsWearing() then
                local charIdDic = {}
                charIdDic[equip.CharacterId] = true
                XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
            end
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY, equipId)
            XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY, equipId)
        end)
    end)
end

-- 请求一键升级
function XEquipAgency:EquipOneKeyFeedRequest(equipId, targetBreakthrough, targetLevel, operations, cb)
    if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.EquipQuick) then
        return
    end

    local req = { EquipId = equipId, TargetBreakthrough = targetBreakthrough, TargetLevel = targetLevel, OperationInfos = {}}

    --服务端要求数据结构
    for _, operation in ipairs(operations) do
        local data = {
            OperationType = operation.OperationType,
            UseItemIdList = {},
            UseItemCountList = {},
            UseEquipIdList = {}
        }
        if not XTool.IsTableEmpty(operation.UseItems) then
            for itemId, itemCount in pairs(operation.UseItems) do
                if itemCount > 0 then
                    table.insert(data.UseItemIdList, itemId)
                    table.insert(data.UseItemCountList, itemCount)
                end
            end
        end
        --构造装备列表
        if not XTool.IsTableEmpty(operation.UseEquipIdDic) then
            for equipId in pairs(operation.UseEquipIdDic) do
                table.insert(data.UseEquipIdList, equipId)
            end
        end
        table.insert(req.OperationInfos, data)
    end
    -- 拦截空操作
    if XTool.IsTableEmpty(req.OperationInfos) then
        return
    end

    XDataCenter.TaskManager.CloseSyncTasksEvent()
    XNetwork.Call("EquipOneKeyFeedRequest", req, function(res)
        XDataCenter.TaskManager.OpenSyncTasksEvent()
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        --删除被吃掉的装备
        local charIdDic = {}
        for _, operation in pairs(req.OperationInfos) do
            for _, tmpEquipId in pairs(operation.UseEquipIdList) do
                local tmpEquip = self:GetEquip(tmpEquipId)
                if tmpEquip:IsWearing() then
                    charIdDic[tmpEquip.CharacterId] = true
                end
                self:DeleteEquip(tmpEquipId)
            end
        end

        --更新装备数据
        local equip = self:GetEquip(equipId)
        equip:SetBreakthrough(res.Breakthrough)
        equip:SetLevel(res.Level)
        equip:SetExp(res.Exp)
        if equip:IsWearing() then
            charIdDic[equip.CharacterId] = true
        end

        self:TipEquipOperation(nil, XUiHelper.GetText("EquipMultiStrengthenSuc"))

        if cb then
            cb()
        end

        -- 更新角色数据
        XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_QUICK_STRENGTHEN_NOTYFY, equipId)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY, equipId)
        XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY, equipId)
    end)
end

-- 请求武器/意识共鸣
function XEquipAgency:RequestEquipResonance(equipId, slots, characterId, useEquipId, useItemId, selectSkillIds, equipResonanceType)
    if useEquipId and self:GetEquip(useEquipId).IsLock then
        XUiManager.TipText("EquipIsLock")
        return
    end

    if characterId and not XMVCA.XCharacter:IsOwnCharacter(characterId) then
        XUiManager.TipText("EquipResonanceNotOwnCharacter")
        return
    end

    local callFunc = function()
        local req = { EquipId = equipId, Slots = slots, CharacterId = characterId, UseEquipId = useEquipId, UseItemId = useItemId, 
            SelectSkillIds = selectSkillIds, SelectType = equipResonanceType }

        XNetwork.Call("EquipResonanceRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local charIdDic = {}
            if useEquipId then
                local useEquip = self:GetEquip(useEquipId)
                if useEquip:IsWearing() then
                    charIdDic[useEquip.CharacterId] = true
                end
                self:DeleteEquip(useEquipId)
            end

            local equip = self:GetEquip(equipId)
            for i, resonanceData in ipairs(res.ResonanceDatas) do
                if equip:IsWeapon() then
                    equip:Resonance(resonanceData, true)
                else
                    equip:Resonance(resonanceData)
                end
            end
            if equip:IsWearing() then
                charIdDic[equip.CharacterId] = true
            end

            --5星及以上的装备（包括武器、意识）共鸣操作成功之后，将该装备自动上锁
            if XDataCenter.EquipManager.CanResonance(equipId) then
                equip:SetLock(true)
            end

            -- 更新角色数据
            XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_RESONANCE_NOTYFY, equipId, slots)
            XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_RESONANCE_NOTYFY, equipId, slots)
        end)
    end

    local containPrecious = useEquipId and self:GetEquipStar(self:GetEquipTemplateId(useEquipId)) >= XEnumConst.EQUIP.CAN_NOT_AUTO_EAT_STAR
    if containPrecious then
        local title = XUiHelper.GetText("EquipResonancePreciousTipTitle")
        local content = XUiHelper.GetText("EquipResonancePreciousTipContent")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
    else
        callFunc()
    end
end

-- 共鸣技能确认
function XEquipAgency:ResonanceConfirm(equipId, slot, isUse)
    local req = {EquipId = equipId, Slot = slot, IsUse = isUse}
    XNetwork.Call("EquipResonanceConfirmRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local equip = self:GetEquip(equipId)
        equip:ResonanceConfirm(slot, isUse)

        -- 更新角色数据
        if equip:IsWearing() then
            local charIdDic = {}
            charIdDic[equip.CharacterId] = true
            XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_RESONANCE_ACK_NOTYFY, equipId, slot)
        XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_RESONANCE_ACK_NOTYFY, equipId)
    end)
end

-- 请求超频
function XEquipAgency:Awake(equipId, slot, costType)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EquipAwake) then
        return
    end

    XNetwork.Call("EquipAwakeRequest", {EquipId = equipId, Slot = slot, CostType = costType}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local equip = self:GetEquip(equipId)
        equip:SetAwake(slot)

        -- 更新角色数据
        if equip:IsWearing() then
            local charIdDic = {}
            charIdDic[equip.CharacterId] = true
            XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_AWAKE_NOTYFY, equipId, slot)
        XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_AWAKE_NOTYFY, equipId)
    end)
end

-- 请求超限升级
function XEquipAgency:EquipWeaponOverrunLevelUpRequest(equipId, callback)
    local request = { EquipId = equipId }
    XNetwork.Call("EquipWeaponOverrunLevelUpRequest", request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        -- 刷新数据
        local equip = self:GetEquip(equipId)
        equip:SetOverrunData(res.WeaponOverrunData)
        if equip:IsWearing() then
            local charIdDic = {}
            charIdDic[equip.CharacterId] = true
            XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        end

        -- 升级1级时，自动上锁
        if res.WeaponOverrunData.Level == 1 and not equip.IsLock then
            XDataCenter.EquipManager.SetLock(equipId, true)
        end

        -- 超限发生变化，发送事件
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_OVERRUN_CHANGE_NOTYFY, equipId)
        
        if callback then
            callback()
        end
    end)
end

-- 请求超限额外意识解锁
function XEquipAgency:EquipWeaponActiveOverrunSuitRequest(equipId, suitId, callback)
    local request = { EquipId = equipId, SuitId = suitId }
    XNetwork.Call("EquipWeaponActiveOverrunSuitRequest", request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        -- 刷新数据
        local equip = self:GetEquip(equipId)
        equip:SetOverrunData(res.WeaponOverrunData)
        if equip:IsWearing() then
            local charIdDic = {}
            charIdDic[equip.CharacterId] = true
            XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        end

        if callback then
            callback()
        end
    end)
end

-- 请求超限切换意识选中
function XEquipAgency:EquipWeaponChoseOverrunSuitRequest(equipId, suitId, callback)
    local request = { EquipId = equipId, SuitId = suitId }
    XNetwork.Call("EquipWeaponChoseOverrunSuitRequest", request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        -- 刷新数据
        local equip = self:GetEquip(equipId)
        equip:SetOverrunData(res.WeaponOverrunData)
        if equip:IsWearing() then
            local charIdDic = {}
            charIdDic[equip.CharacterId] = true
            XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        end

        -- 超限发生变化，发送事件
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_OVERRUN_CHANGE_NOTYFY, equipId)

        if callback then
            callback()
        end
    end)
end

-- 请求分解装备
function XEquipAgency:EquipDecompose(equipIds, cb)
    local req = {EquipIds = equipIds}
    XDataCenter.TaskManager.CloseSyncTasksEvent()
    XNetwork.Call("EquipDecomposeRequest", req, function(res)
        XDataCenter.TaskManager.OpenSyncTasksEvent()
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local rewardGoodsList = res.RewardGoodsList
        for _, id in pairs(equipIds) do
            self:DeleteEquip(id)
        end

        if cb then
            cb(rewardGoodsList)
        end
    end)
end
-------rpc end--------

--------------------------------------------------------------------协议数据 start---------------------------------------
-- 获取装备的XEquip对象实例
function XEquipAgency:GetEquip(equipId)
    return self._Model:GetEquip(equipId)
end

-- 获取所有装备的XEquip对象实例
function XEquipAgency:GetEquipDic()
    return self._Model:GetEquipDic()
end

-- 删除装备
function XEquipAgency:DeleteEquip(equipId)
    self._Model:DeleteEquip(equipId)
end

-- 获取装备的配置表Id
function XEquipAgency:GetEquipTemplateId(equipId)
    local equip = self:GetEquip(equipId)
    return equip.TemplateId
end

-- 获取装备的属性哈希表
function XEquipAgency:GetEquipAttrMap(equipId, preBreakthrough, preLevel)
    local attrMap = {}
    if not equipId then
        return attrMap
    end

    local equip = self:GetEquip(equipId)
    local attrs = XFightEquipManager.GetEquipAttribs(equip, preBreakthrough, preLevel)
    attrMap = self:ConstructEquipAttrMap(attrs)
    return attrMap
end

function XEquipAgency:ConstructEquipAttrMap(attrs, isIncludeZero, remainDigitTwo)
    local equipAttrMap = {}
    for _, attrIndex in ipairs(XEquipConfig.AttrSortType) do
        local value = attrs and attrs[attrIndex]

        --默认保留两位小数
        if not remainDigitTwo then
            value = value and FixToInt(value)
        else
            value = value and tonumber(string.format("%0.2f", FixToDouble(value)))
        end

        if isIncludeZero or value and value > 0 then
            local name = XAttribManager.GetAttribNameByIndex(attrIndex)
            table.insert(equipAttrMap, {AttrIndex = attrIndex, Name = name, Value = value or 0})
        end
    end

    return equipAttrMap
end

-- 获取角色穿戴的装备列表
function XEquipAgency:GetWearingEquipList(characterId)
    local equipList = {}
    local equipDic = self._Model:GetEquipDic()
    for _, equip in pairs(equipDic) do
        if equip.CharacterId == characterId then
            table.insert(equipList, equip)
        end
    end
    return equipList
end

-- 获取角色穿戴的意识列表
function XEquipAgency:GetWearingAwarenessList(characterId)
    local equipList = {}
    local equipDic = self._Model:GetEquipDic()
    for _, equip in pairs(equipDic) do
        if equip.CharacterId == characterId and equip:IsAwareness() then
            table.insert(equipList, equip)
        end
    end
    return equipList
end

-- 获取套装列表信息
---@param equipList table 意识实体列表
---@param weaponEquip table 武器实体
function XEquipAgency:GetWearingSuitInfoListByEquipListAndWeapon(equipList, weaponEquip)
    local suitInfoDic = {}
    local suitInfoList = {}
    local getSuitInfoFunc = function(suitId)
        local suitInfo = suitInfoDic[suitId]
        if not suitInfo then
            local suitName = self:GetEquipSuitName(suitId)
            suitInfo = { SuitId = suitId, Name = suitName, Count = 0, IsOverrun = false }
            suitInfoDic[suitId] = suitInfo
            table.insert(suitInfoList, suitInfo)
        end
        return suitInfo
    end

    for _, equip in pairs(equipList) do
        local suitId = self:GetEquipSuitId(equip.TemplateId)
        local suitInfo = getSuitInfoFunc(suitId)
        suitInfo.Count = suitInfo.Count + 1
    end

    -- 武器超限
    if weaponEquip then
        local equip = weaponEquip
        if equip:CanOverrun() and equip:IsOverrunBlindMatch() then
            local overrunSuitId = equip:GetOverrunChoseSuit()
            if overrunSuitId ~= 0 then
                local suitInfo = getSuitInfoFunc(overrunSuitId)
                local skillDescs = self:GetEquipSuitSkillDescription(overrunSuitId)
                local curCnt = suitInfo.Count
                for addCnt = 1, XEnumConst.EQUIP.OVERRUN_ADD_SUIT_CNT do
                    if skillDescs[curCnt + addCnt]then
                        suitInfo.Count = curCnt + addCnt
                        suitInfo.IsOverrun = true
                    end
                end
            end
        end
    end

    table.sort(suitInfoList, function(a, b)
        -- 套装数量多的优先
        if a.Count ~= b.Count then
            return a.Count > b.Count
        end

        -- 非超限的优先
        if a.IsOverrun ~= b.IsOverrun then
            return not a.IsOverrun
        end

        -- 套装id大的优先
        return a.SuitId > b.SuitId
    end)

    return suitInfoList
end

-- 获取角色穿戴的套装列表信息
function XEquipAgency:GetWearingSuitInfoList(characterId)
    local suitInfoList = {}
    local equipList = self:GetWearingAwarenessList(characterId)

    -- 武器
    local equipWeapon = nil
    local usingWeaponId = XDataCenter.EquipManager.GetCharacterWearingWeaponId(characterId)
    if  XTool.IsNumberValid(usingWeaponId) then
        local equip = self:GetEquip(usingWeaponId)
        equipWeapon = equip
    end

    suitInfoList = self:GetWearingSuitInfoListByEquipListAndWeapon(equipList, equipWeapon)
    return suitInfoList
end

-- 是否是角色穿戴武器，激活超限所绑定的意识
function XEquipAgency:IsCharacterOverrunSuit(characterId, suitId)
    local usingWeaponId = XDataCenter.EquipManager.GetCharacterWearingWeaponId(characterId)
    if usingWeaponId ~= 0 then
        local usingEquip = self:GetEquip(usingWeaponId)
        local choseSuit = usingEquip:GetOverrunChoseSuit()
        return choseSuit == suitId
    end

    return false
end

-- 获取意识激活详情列表
function XEquipAgency:GetSuitActiveSkillDesList(suitId, count, isOverrun, isAddOverrunTips)
    count = count or 0

    local skillInfoList = {}
    local skillDesList = self:GetEquipSuitSkillDescription(suitId)
    local maxDescCnt = XEnumConst.EQUIP.WEAR_AWARENESS_COUNT

    for i = 1, maxDescCnt do
        local skillDesc = skillDesList[i]
        if skillDesc then
            local isActive = count >= i -- 意识装备数量激活
            local isActiveWithOverrun = isOverrun and (count + XEnumConst.EQUIP.OVERRUN_ADD_SUIT_CNT) >= i -- 算上超限能否激活

            local skillInfo = {}
            skillInfo.Pos = i
            skillInfo.PosDes = XUiHelper.GetText("EquipSuitSkillPrefix" .. i)
            skillInfo.IsActive = isActive or isActiveWithOverrun
            skillInfo.IsActiveByOverrun = not isActive and isActiveWithOverrun
            skillInfo.SkillDes = skillDesc or ""
            if skillInfo.IsActiveByOverrun then
                skillInfo.OverrunTips = XUiHelper.GetText("EquipOverrunActive" .. i)
                if isAddOverrunTips then
                    skillInfo.SkillDes = skillInfo.SkillDes .. XUiHelper.GetText("EquipOverrunActiveTips")
                end
            end
            table.insert(skillInfoList, skillInfo)
        end
    end
    return skillInfoList
end

function XEquipAgency:GetEquipStarByEquipId(equipId)
    local templateId = XDataCenter.EquipManager.GetEquipTemplateId(equipId)
    local quality = XDataCenter.EquipManager.GetEquipQuality(templateId)
    return quality
end

function XEquipAgency:GetCharDetailEquipTemplate(templateId)
    local config = self._Model:GetEquipRecommend(templateId)
    return config
end

function XEquipAgency:GetEquipRecommendListByIds(ids)
    local list = {}
    for _, id in ipairs(ids) do
        local config = self:GetCharDetailEquipTemplate(id)
        if config then
            table.insert(list, config)
        end
    end
    local voteNumSort = XDataCenter.VoteManager.GetVoteNumSortFun()
    table.sort(list, voteNumSort)

    return list
end
--------------------------------------------------------------------协议数据 end---------------------------------------

--------------------------------------------------------------------config start---------------------------------------
--------------------region Equip --------------------
function XEquipAgency:GetConfigEquip(id)
    return self._Model:GetConfigEquip(id)
end

function XEquipAgency:GetEquipName(id)
    return self._Model:GetConfigEquip(id).Name
end

function XEquipAgency:GetEquipSite(id)
    return self._Model:GetConfigEquip(id).Site
end

function XEquipAgency:GetEquipType(id)
    return self._Model:GetConfigEquip(id).Type
end

function XEquipAgency:GetEquipQuality(id)
    return self._Model:GetConfigEquip(id).Quality
end

function XEquipAgency:GetEquipStar(id)
    return self._Model:GetConfigEquip(id).Star
end

function XEquipAgency:GetEquipWeaponSkillId(id)
    return self._Model:GetConfigEquip(id).WeaponSkillId
end

function XEquipAgency:GetEquipPriority(id)
    return self._Model:GetConfigEquip(id).Priority
end

function XEquipAgency:GetEquipDefaultLock(id)
    return self._Model:GetConfigEquip(id).DefaultLock
end

function XEquipAgency:GetEquipCharacterId(id)
    return self._Model:GetConfigEquip(id).CharacterId
end

function XEquipAgency:GetEquipSuitId(id)
    return self._Model:GetConfigEquip(id).SuitId
end

function XEquipAgency:GetEquipCharacterType(id)
    return self._Model:GetConfigEquip(id).CharacterType
end

function XEquipAgency:GetEquipLogName(id)
    return self._Model:GetConfigEquip(id).LogName
end

function XEquipAgency:GetEquipDescription(id)
    return self._Model:GetConfigEquip(id).Description
end

function XEquipAgency:GetEquipNeedFirstShow(id)
    return self._Model:GetConfigEquip(id).NeedFirstShow
end

function XEquipAgency:GetEquipRecommendCharacterId(id)
    return self._Model:GetConfigEquip(id).RecommendCharacterId
end
--------------------endregion Equip --------------------

---------------------region EquipSuit---------------------------
function XEquipAgency:GetEquipSuitIconPath(id)
    return self._Model:GetConfigEquipSuit(id).IconPath
end

function XEquipAgency:GetEquipSuitBigIconPath(id)
    return self._Model:GetConfigEquipSuit(id).BigIconPath
end

function XEquipAgency:GetEquipSuitName(id)
    return self._Model:GetConfigEquipSuit(id).Name
end

function XEquipAgency:GetEquipSuitDescription(id)
    return self._Model:GetConfigEquipSuit(id).Description
end

function XEquipAgency:GetEquipSuitSkillEffect(id)
    return self._Model:GetConfigEquipSuit(id).SkillEffect
end

function XEquipAgency:GetEquipSuitSkillDescription(id)
    return self._Model:GetConfigEquipSuit(id).SkillDescription
end

function XEquipAgency:GetEquipSuitSuitType(id)
    return self._Model:GetConfigEquipSuit(id).SuitType
end
--------------------endregion EquipSuit --------------------

--------------------------------------------------------------------config end---------------------------------------

-------open ui start--------
-- 初始化成员界面的装备面板
---@return XUiPanelEquipV2P6
function XEquipAgency:InitPanelEquipV2P6(parentTransform, parentUiProxy, ...)
    local path = CS.XGame.ClientConfig:GetString("PanelEquipV2P6")
    local equipUi = parentTransform:LoadPrefab(path)
    -- local cacheComp = parentTransform:GetComponent(typeof(CS.XUiCachePrefab))
    -- local equipUi = CS.UnityEngine.Object.Instantiate(cacheComp.go, parentTransform)
    local xPanelEquipV2P6 = XUiPanelEquipV2P6.New(equipUi, parentUiProxy, ...)
    return xPanelEquipV2P6
end

---@return XUiPanelCharInfoWithEquip
function XEquipAgency:InitPanelCharInfoWithEquip(parentTransform, parentUiProxy, ...)
    local path = CS.XGame.ClientConfig:GetString("PanelCharInfoWithEquip")
    local equipUi = parentTransform:LoadPrefab(path, true, false)
    local xPanel = XUiPanelCharInfoWithEquip.New(equipUi, parentUiProxy, ...)
    return xPanel
end

---@return XUiPanelCharInfoWithEquipOther
function XEquipAgency:InitPanelCharInfoWithEquipOther(parentTransform, parentUiProxy, ...)
    local path = CS.XGame.ClientConfig:GetString("PanelCharInfoWithEquip")
    local equipUi = parentTransform:LoadPrefab(path, true, false)
    local xPanel = XUiPanelCharInfoWithEquipOther.New(equipUi, parentUiProxy, ...)
    return xPanel
end

-- 打开详情界面
function XEquipAgency:OpenUiEquipDetail(equipId, isPreview, characterId, forceShowBindCharacter, childUiIndex, openUiType, isShowExtendPanel)
    if XEnumConst.EQUIP.IS_TEST_V2P6 then
        XLuaUiManager.Open("UiEquipDetailChildV2P6", equipId, isPreview, characterId, forceShowBindCharacter, childUiIndex, openUiType, isShowExtendPanel)
    else
        XLuaUiManager.Open("UiEquipDetail", equipId, isPreview, characterId, forceShowBindCharacter, childUiIndex, openUiType)
    end
end

-- 打开武器替换界面
function XEquipAgency:OpenUiEquipReplace(characterId, closecallback, notShowStrengthenBtn)
    if XEnumConst.EQUIP.IS_TEST_V2P6 then
        XLuaUiManager.Open("UiEquipReplaceV2P6", characterId, closecallback, notShowStrengthenBtn)
    else
        XLuaUiManager.Open("UiEquipReplaceNew", characterId, closecallback, notShowStrengthenBtn)
    end
end

-- 打开意识替换界面
function XEquipAgency:OpenUiEquipAwarenessReplace(characterId, equipSite, notShowStrengthenBtn)
    if XEnumConst.EQUIP.IS_TEST_V2P6 then
        XLuaUiManager.Open("UiEquipAwarenessReplaceV2P6", characterId, equipSite, notShowStrengthenBtn)
    else
        XLuaUiManager.Open("UiEquipAwarenessReplace", characterId, equipSite, notShowStrengthenBtn)
    end
end

-- 打开预览界面
function XEquipAgency:OpenUiEquipPreview(equipTemplateId)
    if XEnumConst.EQUIP.IS_TEST_V2P6 then
        XLuaUiManager.Open("UiEquipPreviewV2P6", equipTemplateId)
    else
        XLuaUiManager.Open("UiEquipDetail", equipTemplateId, true)
    end
end

-- 打开装备意识界面
function XEquipAgency:OpenUiEquipAwareness(characterId)
    XLuaUiManager.Open("UiEquipAwarenessV2P6", characterId)
end

-- 打开操作成功提示界面
function XEquipAgency:TipEquipOperation(equipId, changeTxt, closeCb, setMask)
    local uiName = "UiEquipCanBreakthroughTip"
    if XLuaUiManager.IsUiShow(uiName) then
        XLuaUiManager.Remove(uiName)
    end
    XLuaUiManager.Open(uiName, equipId, changeTxt, closeCb, setMask)
end
----------open ui end----------

return XEquipAgency