local XTheatre3Chapter = require("XModule/XTheatre3/XEntity/XTheatre3Chapter")
local XTheatre3Team = require("XModule/XTheatre3/XEntity/XTheatre3Team")
local XTheatre3Character = require("XModule/XTheatre3/XEntity/XTheatre3Character")
local XTheatre3EquipPos = require("XModule/XTheatre3/XEntity/XTheatre3EquipPos")
local XTheatre3EquipContainer = require("XModule/XTheatre3/XEntity/XTheatre3EquipContainer")
local XTheatre3Settle = require("XModule/XTheatre3/XEntity/XTheatre3Settle")

-- 肉鸽1号位位于最左边，对应颜色为蓝色，所以需要把红蓝两个颜色交换下
local ColorMap = { [1] = 2, [2] = 1, [3] = 3 }

---@class XTheatre3Activity
local XTheatre3Activity = XClass(nil, "XTheatre3Activity")

function XTheatre3Activity:Ctor()
    -- Data
    self:_InitActivityParams()
    self:_InitBpExpParams()
    self:_InitCharacterParams()
    
    -- Record
    self:_InitFirstPassAdventureParams()
    self:_InitFirstPassChapterParams()
    self:_InitTotalAllPassCountParams()
    self:_InitPassEndingParams()
    self:_InitUnlockItemParams()
    self:_InitUnlockEquipParams()
    self:_InitUnlockStrengthParams()
    self:_InitUnlockDifficultyParams()
    self:_InitBPRewardParams()
    self:_InitAchievementParams()
    
    -- Adventure
    self:_InitAdventureChapterParams()
    self:_InitAdventureTeamParams()
    self:_InitAdventureEquipContainerParams()
    self:_InitAdventureEquipPosParams()
    self:_InitAdventureItemParams()
    self:_InitAdventureSettleParams()
    self:_InitAdventureFightRecordParams()
    self:_InitAdventureLuckCharacterParams()
    self:_InitAdventureEffectDescDataParams()
    self:_InitAdventureQuantumParams()
end

--region Server - Notify
function XTheatre3Activity:NotifyTheatre3Activity(data)
    -- Data
    self:_UpdateCurActivityId(data.CurActivityId)
    self:_UpdateCharacterData(data.Characters)
    self:UpdateTotalBattlePassExp(data.TotalBattlePassExp, false)
    
    -- Record
    self:_UpdateFirstPass(XTool.IsNumberValid(data.FirstPassFlag))
    self:_UpdateFirstPassChapter(data.PassChapterIds)
    self:_UpdateTotalAllPassCount(data.TotalAllPassCount)
    self:_UpdatePassDifficultyRecords(data.PassDifficultyRecords)
    self:_UpdateUnlockItemIdData(data.UnlockItemId)
    self:_UpdateUnlockEquipIdData(data.UnlockEquipId)
    self:_UpdateUnlockDifficultyId(data.UnlockDifficultyId)
    self:_UpdateUnlockStrengthTreeData(data.UnlockStrengthTree)
    self:_UpdateAchievementRecord(data.AchievementRewards)
    self:UpdateGetRewardIdData(data.GetRewardIds)

    -- Adventure
    self:_UpdateTeamData(data.CurTeamData)
    self:UpdateDifficulty(data.DifficultyId)
    self:UpdateMaxEnergy(data.MaxEnergy)
    self:UpdateEquipPosData(data.EquipPos, true)
    self:UpdateItemData(data.Items)
    self:UpdateChapterSwitch(data.ChapterSwitch)
    self:_UpdateChapterData(data.CurChapterDb)
    self:UpdateCurChapterId(data.CurChapterId)
    self:_UpdateEquipData(data.Equips)
    self:_UpdateAdventureFightRecord(data.FightRecords)
    self:UpdateLuckyValue(data.DestinyValue)
    self:UpdateLuckCharacterId(data.DestinyCharacterId)
    self:UpdateQuantumValue(data.QubitValueA, true)
    self:UpdateQuantumValue(data.QubitValueB, false)
end

function XTheatre3Activity:NotifyTheatre3AddChapter(data)
    self:_CheckAndCreateChapter()
    if XTool.IsTableEmpty(data) then
        return
    end
    self.CurChapterDb:UpdateChapterId(data.Chapter.ChapterId)
    self.CurChapterDb:UpdateConnectChapterId(data.Chapter.ConnectChapterId)
    self:SetIsNewChapter(true)
end

function XTheatre3Activity:NotifyTheatre3AddStep(data)
    self:_CheckAndCreateChapter()
    if XTool.IsTableEmpty(data) then
        return
    end
    local curChapterId = self.CurChapterId
    self:UpdateCurChapterId(data.ChapterId)
    self.CurChapterDb:NotifyAddStep(data, curChapterId)
    if XTool.IsNumberValid(curChapterId) and curChapterId ~= self.CurChapterId then
        self:SetIsNewChapter(true)
        self:SetAdventureChapterFirstPass(curChapterId)
    end
end

function XTheatre3Activity:NotifyTheatre3AddItem(data)
    if XTool.IsTableEmpty(data) then
        return
    end
    for _, item in ipairs(data) do
        self._Items[#self._Items + 1] = item
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
--endregion

--region Data - Activity
function XTheatre3Activity:_InitActivityParams()
    -- 当前活动ID
    self.CurActivityId = 0
end

function XTheatre3Activity:_UpdateCurActivityId(value)
    self.CurActivityId = value
end

function XTheatre3Activity:GetCurActivityId()
    return self.CurActivityId
end
--endregion

--region Data - Character
function XTheatre3Activity:_InitCharacterParams()
    -- 角色系统
    ---@type XTheatre3Character[]
    self.Characters = {}
end

function XTheatre3Activity:_UpdateCharacterData(data)
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

---@return XTheatre3Character
function XTheatre3Activity:GetCharacterInfo(charId)
    return self.Characters[charId]
end

---@return XTheatre3Character[]
function XTheatre3Activity:GetCharacterInfoList()
    return self.Characters
end
--endregion

--region Data - BPExp
function XTheatre3Activity:_InitBpExpParams()
    -- 累计BattlePass 经验
    self.TotalBattlePassExp = 0
    -- 保存结算前的BP经验，用于判断BP等级是否满级
    self.TempTotalBattlePassExp = nil
end

function XTheatre3Activity:UpdateTotalBattlePassExp(exp, isNeedTemp)
    if isNeedTemp then
        self.TempTotalBattlePassExp = self.TotalBattlePassExp
    end
    self.TotalBattlePassExp = exp
end

function XTheatre3Activity:GetTotalBattlePassExp()
    return self.TotalBattlePassExp
end
--endregion

--region Record - FirstPassAdventure
function XTheatre3Activity:_InitFirstPassAdventureParams()
    ---首通标记
    self.FirstPassFlag = false
end

function XTheatre3Activity:_UpdateFirstPass(value)
    self.FirstPassFlag = value
end

function XTheatre3Activity:CheckHasFirstPassFlag()
    return self.FirstPassFlag
end
--endregion

--region Record - FirstPassChapter
function XTheatre3Activity:_InitFirstPassChapterParams()
    ---首次通过章节字典
    self.FirstPassChapterDir = {}
end

function XTheatre3Activity:_UpdateFirstPassChapter(data)
    self:_InitFirstPassChapterParams()

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

function XTheatre3Activity:CheckFirstOpenChapterId(chapterId)
    if not XTool.IsNumberValid(chapterId - 1) then
        return true
    end
    return self.FirstPassChapterDir[chapterId - 1]
end
--endregion

--region Record - PassEnding
function XTheatre3Activity:_InitPassEndingParams()
    --- 难度通关结局字典
    ---@type table<number,table>
    self.PassDifficultyRecords = {}
end

function XTheatre3Activity:_UpdatePassDifficultyRecords(data)
    self:_InitPassEndingParams()
    if XTool.IsTableEmpty(data) then
        return
    end
    self.PassDifficultyRecords = data
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
--endregion

--region Record - TotalAllPassCount
function XTheatre3Activity:_InitTotalAllPassCountParams()
    self._TotalAllPassCount = 0
end

function XTheatre3Activity:_UpdateTotalAllPassCount(value)
    if XTool.IsNumberValid(value) then
        self._TotalAllPassCount = value
    else
        self._TotalAllPassCount = 0
    end
end

function XTheatre3Activity:AddTotalAllPassCount()
    self._TotalAllPassCount = self._TotalAllPassCount + 1
end

function XTheatre3Activity:CheckTotalAllPassCount(count)
    return self._TotalAllPassCount >= count
end
--endregion

--region Record - UnlockDifficulty
function XTheatre3Activity:_InitUnlockDifficultyParams()
    ---解锁的难度
    self.UnlockDifficultyId = {}
end

function XTheatre3Activity:_UpdateUnlockDifficultyId(data)
    self:_InitUnlockDifficultyParams()
    if XTool.IsTableEmpty(data) then
        return
    end
    self.UnlockDifficultyId = data
end

function XTheatre3Activity:CheckDifficultyIdUnlock(difficultyId)
    if XTool.IsTableEmpty(self.UnlockDifficultyId) then
        return false
    end
    return table.indexof(self.UnlockDifficultyId, difficultyId)
end
--endregion

--region Record - UnlockStrength
function XTheatre3Activity:_InitUnlockStrengthParams()
    -- 已经解锁的天赋树Id
    ---@type number[]
    self.UnlockStrengthTree = {}
end

function XTheatre3Activity:_UpdateUnlockStrengthTreeData(data)
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

function XTheatre3Activity:CheckUnlockStrengthTree(treeId)
    return self.UnlockStrengthTree[treeId] and true or false
end
--endregion

--region Record - UnlockItem
function XTheatre3Activity:_InitUnlockItemParams()
    -- 已解锁物品ID，用于图鉴
    ---@type number[]
    self.UnlockItemId = {}
end

function XTheatre3Activity:_UpdateUnlockItemIdData(data)
    if not data then
        return
    end
    self:_InitUnlockItemParams()
    for _, itemId in pairs(data) do
        if XTool.IsNumberValid(itemId) then
            self.UnlockItemId[itemId] = itemId
        end
    end
end

function XTheatre3Activity:CheckUnlockItemId(itemId)
    return self.UnlockItemId[itemId] and true or false
end
--endregion

--region Record - UnlockEquip
function XTheatre3Activity:_InitUnlockEquipParams()
    -- 已解锁装备ID，用于图鉴
    ---@type number[]
    self.UnlockEquipId = {}
end

function XTheatre3Activity:_UpdateUnlockEquipIdData(data)
    if not data then
        return
    end
    self:_InitUnlockEquipParams()
    for _, itemId in pairs(data) do
        if XTool.IsNumberValid(itemId) then
            self.UnlockEquipId[itemId] = itemId
        end
    end
end

function XTheatre3Activity:CheckUnlockEquipId(equipId)
    return self.UnlockEquipId[equipId] and true or false
end
--endregion

--region Record - BPReward
function XTheatre3Activity:_InitBPRewardParams()
    -- 领取的BattlePassId
    ---@type number[]
    self.GetRewardIds = {}
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

function XTheatre3Activity:CheckGetRewardId(rewardId)
    return self.GetRewardIds[rewardId] and true or false
end
--endregion

--region Record - Achievement
function XTheatre3Activity:_InitAchievementParams()
    ---@type boolean[]
    self._AchievementReward = {}
end

function XTheatre3Activity:_UpdateAchievementRecord(data)
    self._AchievementReward = {}
    if XTool.IsTableEmpty(data) then
        return
    end
    for _, level in ipairs(data) do
        self:AddAchievementRecord(level)
    end
end

function XTheatre3Activity:CheckAchievementRecord(level)
    return self._AchievementReward[level]
end

function XTheatre3Activity:AddAchievementRecord(level)
    self._AchievementReward[level] = true
end
--endregion

--region Adventure - Chapter
function XTheatre3Activity:_InitAdventureChapterParams()
    -- 当前章节ID
    self.CurChapterId = 0
    -- 是否是新章节
    self._IsNewChapterId = false
    -- 选择的难度ID
    self.DifficultyId = 0
    -- 是否可切换章节
    self._ChapterSwitch = true
    -- 当前章节数据
    ---@type XTheatre3Chapter
    self.CurChapterDb = false
end

function XTheatre3Activity:UpdateChapterSwitch(data)
    self._ChapterSwitch = data
end

function XTheatre3Activity:_UpdateChapterData(data)
    self:_CheckAndCreateChapter()
    if XTool.IsTableEmpty(data) then
        return
    end
    self.CurChapterDb:NotifyTheatre3Chapter(data)
end

function XTheatre3Activity:UpdateDifficulty(difficultyId)
    self.DifficultyId = difficultyId
end

function XTheatre3Activity:UpdateCurChapterId(value)
    self.CurChapterId = value
end

function XTheatre3Activity:SetIsNewChapter(value)
    self._IsNewChapterId = value
end

function XTheatre3Activity:GetDifficultyId()
    return self.DifficultyId
end

function XTheatre3Activity:GetCurChapterId()
    return self.CurChapterId
end

function XTheatre3Activity:GetCurChapterDb()
    return self.CurChapterDb
end

function XTheatre3Activity:GetAdventurePassChapterDir()
    local key = self:_GetAdventurePassChapterIdSaveKey()
    return XSaveTool.GetData(key) or {}
end

function XTheatre3Activity:IsCanSwitchChapter()
    if not self._ChapterSwitch then
        return false
    end
    return self.CurChapterDb and self.CurChapterDb:CheckIsCanSwitchChapter(self.CurChapterId)
end

function XTheatre3Activity:IsNewChapterId()
    return self._IsNewChapterId
end

function XTheatre3Activity:SetAdventurePassChapterDir(dir)
    local key = self:_GetAdventurePassChapterIdSaveKey()
    return XSaveTool.SaveData(key, dir)
end

function XTheatre3Activity:_GetAdventurePassChapterIdSaveKey()
    return string.format("GetAdventurePassChapterIdSaveKey_%s_%s", XPlayer.Id, self:GetCurActivityId())
end

function XTheatre3Activity:_CheckAndCreateChapter()
    if not self.CurChapterDb then
        self.CurChapterDb = XTheatre3Chapter.New()
    end
end
--endregion

--region Adventure - EquipContainer
function XTheatre3Activity:_InitAdventureEquipContainerParams()
    -- 装备系统
    ---@type XTheatre3EquipContainer[]
    self.EquipContainerDir = {}
    -- 槽位容量 key=槽位Id,value=容量
    ---@type table<number,number>
    self.SlotCapacity = {}
end

function XTheatre3Activity:_UpdateEquipData(data)
    if not data then
        return
    end
    for _, equipData in pairs(data) do
        local pos = equipData.Pos
        self:_GetEquipContainerByPos(pos):AddEquipByData(equipData)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_UPDATE_EQUIP)
end

function XTheatre3Activity:GetAdventureSuitList(pos)
    return self.EquipContainerDir[pos]:GetSuitDir()
end

function XTheatre3Activity:_GetEquipContainerByPos(pos)
    if not self.EquipContainerDir[pos] then
        self.EquipContainerDir[pos] = XTheatre3EquipContainer.New(pos)
    end
    return self.EquipContainerDir[pos]
end

function XTheatre3Activity:GetAllEquipSuitCount()
    local result = 0
    for _, containDir in pairs(self.EquipContainerDir) do
        result = result + containDir:GetSuitCount()
    end
    return result
end

---@return number[]
function XTheatre3Activity:GetSuitListBySlot(slotId)
    local slot = self:_GetEquipContainerByPos(slotId)
    return slot:GetSuitList()
end

function XTheatre3Activity:GetEquipBelongPosId(equipId)
    for _, containDir in pairs(self.EquipContainerDir) do
        local belongPosId = containDir:GetEquipBelongPosId(equipId)
        if belongPosId then
            return belongPosId
        end
    end
    return -1
end

function XTheatre3Activity:GetSuitUnQuantumCount()
    local result = 0
    for _, containDir in pairs(self.EquipContainerDir) do
        result = result + containDir:GetSuitUnQuantumCount()
    end
    return result
end

function XTheatre3Activity:CheckIsQuantumBySuitId(suitId)
    for _, container in ipairs(self.EquipContainerDir) do
        if container:CheckIsQuantumBySuitId(suitId) then
            return true
        end
    end
    return false
end

function XTheatre3Activity:CheckIsQuantumByEquipId(equipId)
    for _, container in ipairs(self.EquipContainerDir) do
        if container:CheckIsQuantumByEquipId(equipId) then
            return true
        end
    end
    return false
end

function XTheatre3Activity:AddContainerEquip(pos, data)
    local slot = self:_GetEquipContainerByPos(pos)
    slot:AddEquipByData(data)
end

function XTheatre3Activity:ExchangeContainerSuit(srcSuitId, srcPos, srcEquips, dstSuitId, dstPos, dstEquips)
    local src = self:_GetEquipContainerByPos(srcPos)
    local dst = self:_GetEquipContainerByPos(dstPos)
    local srcEquipDir = src:GetEquipDirBySuitId(srcSuitId)
    local dstEquipDir = dst:GetEquipDirBySuitId(dstSuitId)
    src:SwitchEquip(srcSuitId, srcEquips, dstSuitId, dstEquipDir)
    dst:SwitchEquip(dstSuitId, dstEquips, srcSuitId, srcEquipDir)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_UPDATE_EQUIP)
end

function XTheatre3Activity:RebuildContainerEquip(srcSuitId, srcPos, srcEquip, dstSuitId, dstPos, dstEquip)
    local src = self:_GetEquipContainerByPos(srcPos)
    local dst = self:_GetEquipContainerByPos(dstPos)
    src:RemoveEquip(srcSuitId, srcEquip)
    dst:AddEquipById(dstSuitId, dstEquip)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_UPDATE_EQUIP)
end
--endregion

--region Adventure - EquipPos
function XTheatre3Activity:_InitAdventureEquipPosParams()
    -- 装备槽位
    ---@type XTheatre3EquipPos[]    
    self.EquipPos = {}
end

function XTheatre3Activity:UpdateEquipPosData(data, isTeamRoleId)
    if XTool.IsTableEmpty(data) then
        self:_SetDefaultEquipPosData() -- 设置下默认值
        return
    end
    for _, v in ipairs(data) do
        local equip = self.EquipPos[v.PosId]
        if not equip then
            equip = XTheatre3EquipPos.New()
            self.EquipPos[v.PosId] = equip
        end
        self:_UpdateEquipPos(equip, v, isTeamRoleId)
        self.SlotCapacity[v.PosId] = v.Capacity
    end
end

---@param equip XTheatre3EquipPos
function XTheatre3Activity:_UpdateEquipPos(equip, data, isTeamRoleId)
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

function XTheatre3Activity:_SetDefaultEquipPosData()
    if not XTool.IsTableEmpty(self.EquipPos) then
        return
    end
    for i = 1, 3 do
        local equip = self.EquipPos[i]
        if not equip then
            equip = XTheatre3EquipPos.New()
            self.EquipPos[i] = equip
        end
        self:_UpdateEquipPos(equip, { PosId = i})
    end
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

function XTheatre3Activity:GetMaxCapacity(slotId)
    return self.SlotCapacity[slotId] or 0
end
--endregion

--region Adventure - Team
function XTheatre3Activity:_InitAdventureTeamParams()
    -- 能量石上限
    self.MaxEnergy = 0
    -- 当前编队数据
    ---@type XTheatre3Team
    self.CurTeamData = nil
end

function XTheatre3Activity:UpdateMaxEnergy(value)
    self.MaxEnergy = value
end

function XTheatre3Activity:GetMaxEnergy()
    return self.MaxEnergy
end

function XTheatre3Activity:_UpdateTeamData(data)
    if not self.CurTeamData then
        self.CurTeamData = XTheatre3Team.New("XTheatre3Team")
    end
    if XTool.IsTableEmpty(data) then
        self.CurTeamData:Clear()
        return
    end
    self.CurTeamData:UpdateCaptainPosAndFirstFightPos(data.CaptainPos, data.FirstFightPos)
    self.CurTeamData:UpdateCardIdsAndRobotIds(data.CardIds, data.RobotIds)
end

function XTheatre3Activity:UpdateEntityTeamPos(entityId, teamPos, isJoin)
    self.CurTeamData:UpdateEntityTeamPos(entityId, teamPos, isJoin)
end

function XTheatre3Activity:UpdateTeamEntityIdList(entityIdList)
    self.CurTeamData:UpdateEntityIds(entityIdList)
end

function XTheatre3Activity:UpdateCaptainPosAndFirstFightPos(cPos, fPos)
    self.CurTeamData:UpdateCaptainPosAndFirstFightPos(cPos, fPos)
end

function XTheatre3Activity:SwapEntityTeamPos(teamPosA, teamPosB)
    self.CurTeamData:SwitchEntityPos(teamPosA, teamPosB)
end

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

--region Adventure - LuckyCharacter
function XTheatre3Activity:_InitAdventureLuckCharacterParams()
    self._LuckyValue = 0
    self._LuckCharacterId = 0
end

function XTheatre3Activity:UpdateLuckyValue(value)
    self._LuckyValue = value or 0
end

function XTheatre3Activity:AddLuckyValue(value)
    self._LuckyValue = self._LuckyValue + value
end

function XTheatre3Activity:UpdateLuckCharacterId(id)
    self._LuckCharacterId = id
end

function XTheatre3Activity:GetLuckyValue()
    return self._LuckyValue
end

function XTheatre3Activity:CheckIsLuckCharacter(id)
    if not XTool.IsNumberValid(id) then
        return false
    end
    return self._LuckCharacterId == id
end
--endregion

--region Adventure - Item
---@class XTheatre3Item
---@field Uid number
---@field ItemId number
---@field Live number

function XTheatre3Activity:_InitAdventureItemParams()
    -- 本局拥有道具
    ---@type XTheatre3Item[]
    self._Items = {}
end

function XTheatre3Activity:UpdateItemData(data)
    self._Items = {}
    if not XTool.IsTableEmpty(data) then
        self._Items = data
    end
end

---@return XTheatre3Item[]
function XTheatre3Activity:GetAdventureItemList()
    return self._Items
end

function XTheatre3Activity:CheckAdventureItemOwn(itemId, isOwn, isHaveLive)
    local itemCount = 0
    for _, item in ipairs(self._Items) do
        if item.ItemId == itemId and (not isHaveLive or (isHaveLive and item.Live > 0)) then
            itemCount = itemCount + 1
        end
    end
    if isOwn then
        return itemCount > 0
    else
        return itemCount < 1
    end
end
--endregion

--region Adventure - EquipDescData
function XTheatre3Activity:_InitAdventureEffectDescDataParams()
    ---@type XTheatre3AdventureEffectDescData
    self._AdventureEffectDescData = nil
end

function XTheatre3Activity:UpdateEffectDescData(data)
    if not self._AdventureEffectDescData then
        local XTheatre3AdventureEffectDescData = require("XModule/XTheatre3/XEntity/Adventure/XTheatre3AdventureEffectDescData")
        self._AdventureEffectDescData = XTheatre3AdventureEffectDescData.New()
    end
    self._AdventureEffectDescData:UpdateData(data)
end

function XTheatre3Activity:GetAdventureEffectDescData()
    return self._AdventureEffectDescData
end
--endregion

--region Adventure - Settle
function XTheatre3Activity:_InitAdventureSettleParams()
    ---@type XTheatre3Settle
    self.Settle = nil
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
        self:_UpdateEquipData(data.Equips)
    end
    if data.EquipPos then
        -- 装备槽位
        self:UpdateEquipPosData(data.EquipPos)
    end
    if data.Characters then
        -- 角色数据
        self:_UpdateCharacterData(data.Characters)
    end
    if data.UnlockItemId then
        -- 所有已解锁道具ID
        self:_UpdateUnlockItemIdData(data.UnlockItemId)
    end
    if data.UnlockDifficultyId then
        -- 已解锁难度ID
        self:_UpdateUnlockDifficultyId(data.UnlockDifficultyId)
    end
    if data.UnlockEquipId then
        -- 已解锁的装备
        self:_UpdateUnlockEquipIdData(data.UnlockEquipId)
    end
    if data.PassDifficultyRecords then
        self:_UpdatePassDifficultyRecords(data.PassDifficultyRecords)
    end
    if data.PassChapterIds then
        self:_UpdateFirstPassChapter(data.PassChapterIds)
        self:SetAdventurePassChapterDir({})
    end
    if data.DestinyValue then
        self:AddLuckyValue(data.DestinyValue)
    end
    self:UpdateQuantumValue(0, true)
    self:UpdateQuantumValue(0, false)
    if XTool.IsNumberValid(data.FirstPassFlag) then
        self:_UpdateFirstPass(true)
    end
    self:UpdateChapterSwitch(false)
end

function XTheatre3Activity:InitAdventureData()
    self.CurChapterDb = nil
    self:UpdateMaxEnergy(0)
    self:UpdateDifficulty(0)
    self:UpdateCurChapterId(0)
    self:UpdateLuckCharacterId(0)
    self:_InitAdventureEffectDescDataParams()
    self:_InitAdventureFightRecordParams()
end

function XTheatre3Activity:InitAdventureSettleData()
    self:_InitAdventureSettleParams()
    self.EquipPos = {}
    for i = 1, 3 do
        self:_GetEquipContainerByPos(i):ClearEquip()
    end
    self:_InitAdventureItemParams()
    self.TempTotalBattlePassExp = nil
end

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

--region Adventure - FightRecord
function XTheatre3Activity:_InitAdventureFightRecordParams()
    ---@type XTheatre3FightResult
    self._AdventureFightResult = false
end

function XTheatre3Activity:_UpdateAdventureFightRecord(data)
    self:GetAdventureFightRecord():UpdateData(data)
end

function XTheatre3Activity:AddAdventureFightRecord(stageId, fightRecord, idList)
    self:GetAdventureFightRecord():AddData(stageId, fightRecord, idList)
end

---@return XTheatre3FightResult
function XTheatre3Activity:GetAdventureFightRecord()
    if not self._AdventureFightResult then
        local XTheatre3FightResult = require("XModule/XTheatre3/XEntity/Adventure/XTheatre3FightResult")
        self._AdventureFightResult = XTheatre3FightResult.New()
    end
    return self._AdventureFightResult
end
--endregion

--region Adventure - Quantum
function XTheatre3Activity:_InitAdventureQuantumParams()
    self._QuantumValueA = 0
    self._QuantumValueB = 0
end

---@return boolean isChange
function XTheatre3Activity:UpdateQuantumValue(value, isA)
    local isChange
    if isA then
        isChange = self._QuantumValueA ~= value
        self._QuantumValueA = value
    else
        isChange = self._QuantumValueB ~= value
        self._QuantumValueB = value
    end
    return isChange
end

function XTheatre3Activity:GetQuantumValue(isA)
    if isA then
        return self._QuantumValueA
    else
        return self._QuantumValueB
    end
end

function XTheatre3Activity:GetQuantumAllValue()
    return self._QuantumValueA + self._QuantumValueB
end

function XTheatre3Activity:CheckQuantumValue(type, value)
    if type == XEnumConst.THEATRE3.QuantumType.QuantumA then
        if value == 0 then
            return self._QuantumValueA == value
        else
            return self._QuantumValueA >= value
        end
    else
        if value == 0 then
            return self._QuantumValueB == value
        else
            return self._QuantumValueB >= value
        end
    end
end
--endregion

--region Checker
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

return XTheatre3Activity