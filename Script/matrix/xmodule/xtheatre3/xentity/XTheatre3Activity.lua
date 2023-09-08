local XTheatre3Chapter = require("XModule/XTheatre3/XEntity/XTheatre3Chapter")
local XTheatre3Team = require("XModule/XTheatre3/XEntity/XTheatre3Team")
local XTheatre3Character = require("XModule/XTheatre3/XEntity/XTheatre3Character")
local XTheatre3EquipPos = require("XModule/XTheatre3/XEntity/XTheatre3EquipPos")
local XTheatre3Equip = require("XModule/XTheatre3/XEntity/XTheatre3Equip")
local XTheatre3Settle = require("XModule/XTheatre3/XEntity/XTheatre3Settle")

-- 肉鸽1号位位于最左边，对应颜色为蓝色，所以需要把红蓝两个颜色交换下
local ColorMap = { [1] = 2, [2] = 1, [3] = 3 }

---@class XTheatre3Activity
local XTheatre3Activity = XClass(nil, "XTheatre3Activity")

function XTheatre3Activity:Ctor()
    -- 当前活动ID
    self.CurActivityId = 0
    -- 当前章节ID
    self.CurChapterId = 0
    -- 选择的难度ID
    self.DifficultyId = 0
    -- 能量石上限
    self.MaxEnergy = 0
    -- 当前章节数据
    ---@type XTheatre3Chapter
    self.CurChapterDb = nil
    ---@type XTheatre3AdventureEffectDescData
    self.AdventureEffectDescData = nil
    -- 当前编队数据
    ---@type XTheatre3Team
    self.CurTeamData = nil
    -- 角色系统
    ---@type XTheatre3Character[]
    self.Characters = {}
    -- 装备系统
    ---@type XTheatre3Equip[]
    self.Equips = {}
    -- 装备槽位
    ---@type XTheatre3EquipPos[]
    self.EquipPos = {}
    -- 本局拥有道具 { Uid, ItemId }[]
    self.Items = {}
    -- 已解锁物品ID，用于图鉴
    ---@type number[]
    self.UnlockItemId = {}
    -- 已解锁装备ID，用于图鉴
    ---@type number[]
    self.UnlockEquipId = {}
    -- 领取的BattlePassId
    ---@type number[]
    self.GetRewardIds = {}
    -- 已经解锁的天赋树Id
    ---@type number[]
    self.UnlockStrengthTree = {}
    -- 累计BattlePass 经验
    self.TotalBattlePassExp = 0
    -- 保存结算前的BP经验，用于判断BP等级是否满级
    self.TempTotalBattlePassExp = nil
    -- 槽位容量 key=槽位Id,value=容量
    ---@type table<number,number>
    self.SlotCapacity = {}
    --- 难度通关结局字典
    ---@type table<number,table>
    self.PassDifficultyRecords = {}
    ---解锁的难度
    self.UnlockDifficultyId = {}
    ---首通标记
    self.FirstPassFlag = false
    ---首次通过章节字典
    self.FirstPassChapterDir = {}
    ---@type XTheatre3Settle
    self.Settle = nil
end

function XTheatre3Activity:NotifyTheatre3Activity(data)
    self.CurActivityId = data.CurActivityId
    self.CurChapterId = data.CurChapterId
    self.DifficultyId = data.DifficultyId
    self.MaxEnergy = data.MaxEnergy
    self.FirstPassFlag = XTool.IsNumberValid(data.FirstPassFlag)
    self:UpdateChapterData(data.CurChapterDb)
    self:UpdateTeamData(data.CurTeamData)
    self:UpdateCharacterData(data.Characters)
    self:UpdateEquipData(data.Equips)
    self:UpdateEquipPosData(data.EquipPos, true)
    self:UpdateItemData(data.Items)
    self:UpdateUnlockItemIdData(data.UnlockItemId)
    self:UpdateUnlockEquipIdData(data.UnlockEquipId)
    self:UpdateGetRewardIdData(data.GetRewardIds)
    self:UpdateUnlockStrengthTreeData(data.UnlockStrengthTree)
    self:UpdatePassDifficultyRecords(data.PassDifficultyRecords)
    self:UpdateUnlockDifficultyId(data.UnlockDifficultyId)
    self:UpdateFirstPassChapter(data.PassChapterIds)
    self.TotalBattlePassExp = data.TotalBattlePassExp
end

function XTheatre3Activity:NotifyTheatre3AddStep(data)
    if not self.CurChapterDb then
        self.CurChapterDb = XTheatre3Chapter.New()
    end
    if XTool.IsTableEmpty(data) then
        return
    end
    local chapterId = self.CurChapterDb.ChapterId
    self.CurChapterDb:NotifyAddStep(data)
    if XTool.IsNumberValid(chapterId) and chapterId ~= self.CurChapterDb.ChapterId then
        self:SetAdventureChapterFirstPass(chapterId)
    end
end

function XTheatre3Activity:NotifyTheatre3AddItem(data)
    if XTool.IsTableEmpty(data) then
        return
    end
    for _, item in ipairs(data) do
        self.Items[#self.Items + 1] = item
    end
end

function XTheatre3Activity:NotifyTheatre3NodeNextStep(data)
    if XTool.IsTableEmpty(data) then
        return
    end
    local lastNodeSlot, step = self.CurChapterDb:GetLastNodeSlot()
    if lastNodeSlot and lastNodeSlot:GetEventId() == data.EventId then
        lastNodeSlot:AddPassedStepId(lastNodeSlot:GetCurStepId())
        lastNodeSlot:SetCurStepId(data.NextStepId)
        if not XTool.IsNumberValid(data.NextStepId) then
            step:SetIsOver()
        end
    end
end

function XTheatre3Activity:UpdateChapterData(data)
    if not self.CurChapterDb then
        self.CurChapterDb = XTheatre3Chapter.New()
    end
    if XTool.IsTableEmpty(data) then
        return
    end
    self.CurChapterDb:NotifyTheatre3Chapter(data)
end

function XTheatre3Activity:UpdateTeamData(data)
    if not self.CurTeamData then
        self.CurTeamData = XTheatre3Team.New("XTheatre3Team")
        if not self.CurTeamData:GetIsEmpty() then
            return --登录时使用本地保存的数据
        end
    end
    if XTool.IsTableEmpty(data) then
        self.CurTeamData:Clear()
        return
    end
    self.CurTeamData:UpdateCaptainPosAndFirstFightPos(data.CaptainPos, data.FirstFightPos)
    self.CurTeamData:UpdateCardIdsAndRobotIds(data.CardIds, data.RobotIds)
end

function XTheatre3Activity:UpdateCharacterData(data)
    if not data then
        return
    end
    for _, v in pairs(data) do
        local character = self.Characters[v.CharacterId]
        if not character then
            character = XTheatre3Character.New()
            self.Characters[v.CharacterId] = character
        end
        character:NotifyTheatre3Character(v)
    end
end

function XTheatre3Activity:UpdateEquipData(data)
    if not data then
        return
    end
    local temp = {}
    for _, v in pairs(data) do
        local pos = v.Pos
        if not temp[pos] then
            temp[pos] = {}
        end
        table.insert(temp[pos], v)
    end
    for pos, v in pairs(temp) do
        local slot = self.Equips[pos]
        if not slot then
            slot = XTheatre3Equip.New()
            self.Equips[pos] = slot
        end
        slot:NotifyTheatre3Equip(pos, v)
    end
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_THEATRE3_UPDATE_EQUIP)
end

function XTheatre3Activity:UpdateEquipPosData(data, isTeamRoleId)
    if XTool.IsTableEmpty(data) then
        self:SetDefaultEquipPosData() -- 设置下默认值
        return
    end
    for _, v in ipairs(data) do
        local equip = self.EquipPos[v.PosId]
        if not equip then
            equip = XTheatre3EquipPos.New()
            self.EquipPos[v.PosId] = equip
        end
        self:UpdateEquipPos(equip, v, isTeamRoleId)
        self.SlotCapacity[v.PosId] = v.Capacity
    end
end

---@param equip XTheatre3EquipPos
function XTheatre3Activity:UpdateEquipPos(equip, data, isTeamRoleId)
    -- 初始化的时候ColorId为0需要赋值默认值
    if not XTool.IsNumberValid(data.ColorId) then
        data.ColorId = ColorMap[data.PosId]
    end
    if not equip then
        return
    end
    equip:UpdateEquipPosIdAndColorId(data.PosId, data.ColorId)
    local roleId = 0
    if XTool.IsNumberValid(data.CardId) then
        roleId = data.CardId
    elseif XTool.IsNumberValid(data.RobotId) then
        roleId = data.RobotId
    end
    local entityId = self.CurTeamData:GetEntityIdByTeamPos(data.ColorId)
    if entityId ~= roleId then
        XLog.Debug("槽位角色id和编队角色Id不一致", entityId, roleId)
    end
    equip:UpdateEquipPosRoleId(isTeamRoleId and entityId or roleId)
end

function XTheatre3Activity:SetDefaultEquipPosData()
    if not XTool.IsTableEmpty(self.EquipPos) then
        return
    end
    for i = 1, 3 do
        local equip = self.EquipPos[i]
        if not equip then
            equip = XTheatre3EquipPos.New()
            self.EquipPos[i] = equip
        end
        self:UpdateEquipPos(equip, {PosId = i})
    end
end

function XTheatre3Activity:UpdateEquipPosRoleId(roleId, slotId, isJoin)
    if isJoin then
        local slotInfo = self:GetSlotInfo(slotId)
        slotInfo:UpdateEquipPosRoleId(roleId)
    else
        for _, slotInfo in pairs(self:GetSlotInfoList()) do
            if slotInfo:GetRoleId() == roleId then
                slotInfo:UpdateEquipPosRoleId(0)
                break
            end
        end
    end
end

function XTheatre3Activity:UpdateItemData(data)
    self.Items = {}
    if not XTool.IsTableEmpty(data) then
        self.Items = data
    end
end

function XTheatre3Activity:UpdateUnlockItemIdData(data)
    if not data then
        return
    end
    self.UnlockItemId = {}
    for _, itemId in pairs(data) do
        if XTool.IsNumberValid(itemId) then
            self.UnlockItemId[itemId] = itemId
        end
    end
end

function XTheatre3Activity:UpdateUnlockEquipIdData(data)
    if not data then
        return
    end
    self.UnlockEquipId = {}
    for _, itemId in pairs(data) do
        if XTool.IsNumberValid(itemId) then
            self.UnlockEquipId[itemId] = itemId
        end
    end
end

function XTheatre3Activity:UpdateGetRewardIdData(data)
    if not data then
        return
    end
    self.GetRewardIds = {}
    for _, rewardId in pairs(data) do
        self:AddGetRewardId(rewardId)
    end
end

function XTheatre3Activity:AddGetRewardId(rewardId)
    if XTool.IsNumberValid(rewardId) then
        self.GetRewardIds[rewardId] = rewardId
    end
end

function XTheatre3Activity:UpdateUnlockStrengthTreeData(data)
    if not data then
        return
    end
    for _, treeId in pairs(data) do
        self:AddUnlockStrengthTreeId(treeId)
    end
end

function XTheatre3Activity:AddUnlockStrengthTreeId(treeId)
    if XTool.IsNumberValid(treeId) then
        self.UnlockStrengthTree[treeId] = treeId
    end
end

function XTheatre3Activity:UpdateTotalBattlePassExp(exp)
    self.TempTotalBattlePassExp = self.TotalBattlePassExp
    self.TotalBattlePassExp = exp
end

function XTheatre3Activity:UpdateSettle(data)
    if not self.Settle then
        self.Settle = XTheatre3Settle.New()
    end
    self.Settle:NotifyTheatre3Settle(data)
    if data.Items then
        -- 本局拥有道具
        self:UpdateItemData(data.Items)
    end
    if data.Equips then
        -- 已获得装备
        self:UpdateEquipData(data.Equips)
    end
    if data.EquipPos then
        -- 装备槽位
        self:UpdateEquipPosData(data.EquipPos)
    end
    if data.Characters then
        -- 角色数据
        self:UpdateCharacterData(data.Characters)
    end
    if data.UnlockItemId then
        -- 所有已解锁道具ID
        self:UpdateUnlockItemIdData(data.UnlockItemId)
    end
    if data.UnlockDifficultyId then
        -- 已解锁难度ID
        self:UpdateUnlockDifficultyId(data.UnlockDifficultyId)
    end
    if data.UnlockEquipId then
        -- 已解锁的装备
        self:UpdateUnlockEquipIdData(data.UnlockEquipId)
    end
    if data.PassDifficultyRecords then
        self:UpdatePassDifficultyRecords(data.PassDifficultyRecords)
    end
    if data.PassChapterIds then
        self:UpdateFirstPassChapter(data.PassChapterIds)
        self:SetAdventurePassChapterDir({})
    end
    if XTool.IsNumberValid(data.FirstPassFlag) then
        self.FirstPassFlag = true
    end
end

function XTheatre3Activity:GetCurActivityId()
    return self.CurActivityId
end

function XTheatre3Activity:GetCurChapterId()
    return self.CurChapterId
end

function XTheatre3Activity:GetDifficultyId()
    return self.DifficultyId
end

function XTheatre3Activity:GetMaxEnergy()
    return self.MaxEnergy
end

function XTheatre3Activity:GetTotalBattlePassExp()
    return self.TotalBattlePassExp
end

function XTheatre3Activity:CheckUnlockItemId(itemId)
    return self.UnlockItemId[itemId] and true or false
end

function XTheatre3Activity:CheckUnlockEquipId(equipId)
    return self.UnlockEquipId[equipId] and true or false
end

function XTheatre3Activity:CheckGetRewardId(rewardId)
    return self.GetRewardIds[rewardId] and true or false
end

function XTheatre3Activity:CheckUnlockStrengthTree(treeId)
    return self.UnlockStrengthTree[treeId] and true or false
end

---@return XTheatre3EquipPos[]
function XTheatre3Activity:GetSlotInfoList()
    return self.EquipPos
end

---@return XTheatre3EquipPos
function XTheatre3Activity:GetSlotInfo(slotId)
    return self.EquipPos[slotId]
end

function XTheatre3Activity:GetSlotPosIdByColorId(colorId)
    for _, v in ipairs(self.EquipPos) do
        if v:GetColorId() == colorId then
            return v:GetPos()
        end
    end
    return 1
end

function XTheatre3Activity:GetSlotIndexByPos(pos)
    for _, v in ipairs(self.EquipPos) do
        if v:GetPos() == pos then
            return v:GetColorId()
        end
    end
    return 1
end

---@return XTheatre3Character
function XTheatre3Activity:GetCharacterInfo(charId)
    return self.Characters[charId]
end

---@return XTheatre3Character[]
function XTheatre3Activity:GetCharacterInfoList()
    return self.Characters
end

function XTheatre3Activity:GetMaxCapacity(slotId)
    return self.SlotCapacity[slotId] or 0
end

function XTheatre3Activity:_GetSlot(slotId)
    local slot = self.Equips[slotId]
    if not slot then
        slot = XTheatre3Equip.New()
        slot:NotifyTheatre3Equip(slotId, {}) -- 初始化
        self.Equips[slotId] = slot
    end
    return slot
end

---@return number[]
function XTheatre3Activity:GetSuitListBySlot(slotId)
    local slot = self:_GetSlot(slotId)
    return slot.SuitIds
end

function XTheatre3Activity:AddSlotEquip(slotId, equipId, suitId)
    local slot = self:_GetSlot(slotId)
    slot:AddEquipAndSuit(equipId, suitId)
end

function XTheatre3Activity:ExchangeSlotSuit(srcSuitId, srcPos, srcEquips, dstSuitId, dstPos, dstEquips)
    local src = self:_GetSlot(srcPos)
    local dst = self:_GetSlot(dstPos)
    src:ExchangeSuit(srcSuitId, srcEquips, dstSuitId, dstEquips)
    dst:ExchangeSuit(dstSuitId, dstEquips, srcSuitId, srcEquips)
end

function XTheatre3Activity:RebuildSlotEquip(srcSuitId, srcPos, srcEquip, dstSuitId, dstPos, dstEquip)
    local src = self:_GetSlot(srcPos)
    local dst = self:_GetSlot(dstPos)
    src:LoseEquip(srcEquip, srcSuitId)
    dst:AddEquipAndSuit(dstEquip, dstSuitId)
end

--region Team
function XTheatre3Activity:GetTeamsEntityIds()
    return self.CurTeamData and self.CurTeamData:GetEntityIds() or {}
end

function XTheatre3Activity:GetTeamsCharIds()
    return self.CurTeamData and self.CurTeamData:GetCharacterIdsOrder() or {}
end

function XTheatre3Activity:GetTeamRobotIds()
    return self.CurTeamData and self.CurTeamData:GetRobotIdsOrder() or {}
end

function XTheatre3Activity:GetCaptainPos()
    return self.CurTeamData and self.CurTeamData:GetCaptainPos() or 1
end

function XTheatre3Activity:GetFirstFightPos()
    return self.CurTeamData and self.CurTeamData:GetFirstFightPos() or 1
end

---@return boolean, number isInTeam, EquipPos.ColorId
function XTheatre3Activity:GetEntityIdIsInTeam(entityId)
    return self.CurTeamData:GetEntityIdIsInTeam(entityId)
end

function XTheatre3Activity:GetEntityIdBySlotColor(slotColorId)
    return self.CurTeamData:GetEntityIdByTeamPos(slotColorId)
end

function XTheatre3Activity:UpdateEntityTeamPos(entityId, teamPos, isJoin)
    self.CurTeamData:UpdateEntityTeamPos(entityId, teamPos, isJoin)
end

function XTheatre3Activity:SwapEntityTeamPos(teamPosA, teamPosB)
    self.CurTeamData:SwitchEntityPos(teamPosA, teamPosB)
end

function XTheatre3Activity:UpdateCaptainPosAndFirstFightPos(cPos, fPos)
    self.CurTeamData:UpdateCaptainPosAndFirstFightPos(cPos, fPos)
end

function XTheatre3Activity:CheckCaptainHasEntityId()
    local entityId = self.CurTeamData:GetCaptainPosEntityId()
    return XTool.IsNumberValid(entityId)
end

function XTheatre3Activity:CheckFirstFightHasEntityId()
    local entityId = self.CurTeamData:GetFirstFightPosEntityId()
    return XTool.IsNumberValid(entityId)
end

function XTheatre3Activity:ResetTeam()
    -- 结束冒险后需要重置编队数据
    if self.CurTeamData then
        self.CurTeamData:Clear()
    end
end
--endregion

--region Checker
function XTheatre3Activity:CheckFirstOpenChapterId(chapterId)
    if not XTool.IsNumberValid(chapterId - 1) then
        return true
    end
    return self.FirstPassChapterDir[chapterId - 1]
end

function XTheatre3Activity:CheckHasFirstPassFlag()
    return self.FirstPassFlag
end

function XTheatre3Activity:CheckHasPassEnding(difficultyId, endingId)
    if not self.PassDifficultyRecords[difficultyId] then
        return false
    end
    -- endingId = 0表示任意结局
    if not XTool.IsNumberValid(endingId) then
        return true
    end
    return table.indexof(self.PassDifficultyRecords[difficultyId], endingId)
end

function XTheatre3Activity:CheckEndingIsPass(endingId)
    if XTool.IsTableEmpty(self.PassDifficultyRecords) then
        return false
    end
    if not XTool.IsNumberValid(endingId) then
        return true
    end
    for _, list in pairs(self.PassDifficultyRecords) do
        if table.indexof(list, endingId) then
            return true
        end
    end
    return false
end

function XTheatre3Activity:CheckDifficultyIdUnlock(difficultyId)
    if XTool.IsTableEmpty(self.UnlockDifficultyId) then
        return false
    end
    return table.indexof(self.UnlockDifficultyId, difficultyId)
end

function XTheatre3Activity:CheckAdventureHasPassEventStep(eventStepId)
    -- 不在冒险则为false
    if not XTool.IsNumberValid(self.DifficultyId) then
        return false
    end
    return self.CurChapterDb:CheckIsPassEventStep(eventStepId)
end

function XTheatre3Activity:CheckAdventureHasPassChapter(chapterId)
    -- 不在冒险则为false
    if not XTool.IsNumberValid(self.DifficultyId) then
        return false
    end
    XLog.Error("当前通关章节数据未同步！")
end

function XTheatre3Activity:CheckAdventureHasPassNode(nodeId)
    -- 不在冒险则为false
    if not XTool.IsNumberValid(self.DifficultyId) then
        return false
    end
    return self.CurChapterDb:CheckIsPassNodeId(nodeId)
end
--endregion

--region EndingRecord
function XTheatre3Activity:UpdatePassDifficultyRecords(data)
    self.PassDifficultyRecords = {}
    if XTool.IsTableEmpty(data) then
        return
    end
    self.PassDifficultyRecords = data
end
--endregion

--region Difficulty
function XTheatre3Activity:UpdateUnlockDifficultyId(data)
    self.UnlockDifficultyId = {}
    if XTool.IsTableEmpty(data) then
        return
    end
    self.UnlockDifficultyId = data
end
--endregion

--region EquipDescData
function XTheatre3Activity:UpdateEffectDescData(data)
    if not self.AdventureEffectDescData then
        local XTheatre3AdventureEffectDescData = require("XModule/XTheatre3/XEntity/Adventure/XTheatre3AdventureEffectDescData")
        self.AdventureEffectDescData = XTheatre3AdventureEffectDescData.New()
    end
    self.AdventureEffectDescData:UpdateData(data)
end

function XTheatre3Activity:GetAdventureEffectDescData()
    return self.AdventureEffectDescData
end
--endregion

--region Adventure
function XTheatre3Activity:InitAdventureData()
    self.DifficultyId = 0
    self.MaxEnergy = 0
    self.CurChapterId = 0
    self.CurChapterDb = nil
    self.AdventureEffectDescData = nil
end

function XTheatre3Activity:InitAdventureSettleData()
    self.Settle = nil
    self.Equips = {}
    for i = 1, 3 do
        self.Equips[i] = XTheatre3Equip.New()
        self.Equips[i]:NotifyTheatre3Equip(i, {})
    end
    self.EquipPos = {}
    self.Items = {}
    self.TempTotalBattlePassExp = nil
end

function XTheatre3Activity:UpdateDifficulty(difficultyId)
    self.DifficultyId = difficultyId
end

function XTheatre3Activity:UpdateMaxEnergy(maxEnergy)
    self.MaxEnergy = maxEnergy
end

function XTheatre3Activity:UpdateFirstPassChapter(data)
    self.FirstPassChapterDir = {}

    if not XTool.IsTableEmpty(data) then
        for _, chapterId in ipairs(data) do
            self:SetAdventureChapterFirstPass(chapterId, true)
        end
    end
    local dir = self:GetAdventurePassChapterDir()
    for chapterId, _ in ipairs(dir) do
        self:SetAdventureChapterFirstPass(chapterId, true)
    end
end

function XTheatre3Activity:SetAdventureChapterFirstPass(chapterId, isNotSave)
    if not XTool.IsNumberValid(chapterId) then
        return
    end
    if not self.FirstPassChapterDir[chapterId] then
        self.FirstPassChapterDir[chapterId] = true
    end
    if isNotSave then
        return
    end
    self:SetAdventurePassChapterDir(self.FirstPassChapterDir)
end

function XTheatre3Activity:GetCurChapterDb()
    return self.CurChapterDb
end

function XTheatre3Activity:GetAdventureItemList()
    return self.Items
end

function XTheatre3Activity:GetAdventurePassChapterIdSaveKey()
    return string.format("GetAdventurePassChapterIdSaveKey_%s_%s", XPlayer.Id, self:GetCurActivityId())
end

function XTheatre3Activity:GetAdventurePassChapterDir()
    local key = self:GetAdventurePassChapterIdSaveKey()
    return XSaveTool.GetData(key) or {}
end

function XTheatre3Activity:SetAdventurePassChapterDir(dir)
    local key = self:GetAdventurePassChapterIdSaveKey()
    return XSaveTool.SaveData(key, dir)
end

function XTheatre3Activity:GetAdventureItemCount(itemId)
    local result = 0
    if XTool.IsTableEmpty(self.Items) then
        return result
    end
    for _, itemData in ipairs(self.Items) do
        if itemData.ItemId == itemId then
            result = result + 1
        end
    end
    return result
end

function XTheatre3Activity:GetAdventureSuitList(index)
    return self.Equips[index]:GetSuitIdList()
end
--endregion

--region 结算

function XTheatre3Activity:GetSettleData()
    return self.Settle
end

function XTheatre3Activity:SignSettleTip()
    if self.Settle then
        self.Settle.IsNeedShowTip = false
    end
end

function XTheatre3Activity:GetOldBpExp()
    return self.TempTotalBattlePassExp
end

--endregion

return XTheatre3Activity