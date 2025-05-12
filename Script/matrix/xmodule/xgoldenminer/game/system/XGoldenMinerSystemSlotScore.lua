local MAX_PROGRESS = 3

---@class XGoldenMinerSystemSlotScore:XEntityControl
---@field _MainControl XGoldenMinerGameControl
local XGoldenMinerSystemSlotScore = XClass(XEntityControl, "XGoldenMinerSystemSlotScore")

--region Override

function XGoldenMinerSystemSlotScore:EnterGame(objDir)
    self._Progress = 0
    self._StoneTypeList = {}
    for i = 1, MAX_PROGRESS do
        table.insert(self._StoneTypeList, 0)
    end
end

function XGoldenMinerSystemSlotScore:OnRelease()
    self._Progress = 0
    self._StoneTypeList = nil
end
--endregion

function XGoldenMinerSystemSlotScore:HandleGrabbedStoneType(stoneType)
    self._Progress = self._Progress + 1

    if stoneType ~= XEnumConst.GOLDEN_MINER.SLOT_SCORE_ANY_TYPE then
        if self:_CheckIsAnyTypeByBuff(stoneType) or
                self:_CheckIsAnyType(stoneType)
        then
            stoneType = XEnumConst.GOLDEN_MINER.SLOT_SCORE_ANY_TYPE
        end
    end

    self._StoneTypeList[self._Progress] = stoneType

    local stoneTypeList = XTool.Clone(self._StoneTypeList)

    if self._Progress == MAX_PROGRESS then
        -- 判断哪些石头和其他相同
        local sameStoneIdSet = {}
        local sameStoneIndexSet = {}
        for i = 1, MAX_PROGRESS do
            if not sameStoneIndexSet[i] then
                if sameStoneIdSet[stoneTypeList[i]] then
                    sameStoneIndexSet[i] = true
                else
                    if stoneTypeList[i] == XEnumConst.GOLDEN_MINER.SLOT_SCORE_ANY_TYPE then
                        sameStoneIndexSet[i] = true
                    end

                    for j = i + 1, MAX_PROGRESS do
                        if stoneTypeList[i] == stoneTypeList[j] then
                            if stoneTypeList[i] == XEnumConst.GOLDEN_MINER.SLOT_SCORE_ANY_TYPE then
                                -- 比较的两个抓取物都是赖子
                                sameStoneIndexSet[i] = true
                            else
                                sameStoneIdSet[stoneTypeList[i]] = true
                                sameStoneIndexSet[i] = true
                                sameStoneIndexSet[j] = true
                            end
                            break
                        elseif stoneTypeList[i] == XEnumConst.GOLDEN_MINER.SLOT_SCORE_ANY_TYPE then
                            sameStoneIndexSet[i] = true
                            sameStoneIndexSet[j] = true
                            sameStoneIdSet[stoneTypeList[j]] = true
                            stoneTypeList[i] = stoneTypeList[j]
                            break
                        elseif stoneTypeList[j] == XEnumConst.GOLDEN_MINER.SLOT_SCORE_ANY_TYPE then
                            sameStoneIndexSet[i] = true
                            sameStoneIndexSet[j] = true
                            sameStoneIdSet[stoneTypeList[i]] = true
                            stoneTypeList[j] = stoneTypeList[i]
                            break
                        end
                    end
                end
            end
        end

        --算分
        local sameCount = XTool.GetTableCount(sameStoneIndexSet)
        local slotScoreType = XEnumConst.GOLDEN_MINER.SLOT_SCORE_TYPE.Diff
        
        if sameCount == 0 then
            slotScoreType = XEnumConst.GOLDEN_MINER.SLOT_SCORE_TYPE.Diff
        elseif sameCount == 2 then
            slotScoreType = XEnumConst.GOLDEN_MINER.SLOT_SCORE_TYPE.Double
        elseif sameCount == 3 then
            slotScoreType = XEnumConst.GOLDEN_MINER.SLOT_SCORE_TYPE.Triple
        end

        local score = self._MainControl:GetClientSlotScoreScore(slotScoreType)
        self._MainControl:AddMapScore(score)
        self._MainControl:AddSlotScoreHandleCount(slotScoreType)
        
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_SLOT_SCORE_DATA_CHANGED, self._StoneTypeList, true, sameStoneIndexSet)
        self:_ResetProgress()
    else
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_SLOT_SCORE_DATA_CHANGED, self._StoneTypeList)
    end
end

function XGoldenMinerSystemSlotScore:_ResetProgress()
    self._Progress = 0
    for i = 1, MAX_PROGRESS do
        self._StoneTypeList[i] = 0
    end
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_SLOT_SCORE_DATA_CHANGED, self._StoneTypeList)
end

function XGoldenMinerSystemSlotScore:_CheckIsAnyTypeByBuff(stoneType)
    local buffUidList = self._MainControl.SystemBuff:GetBuffUidListByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.SLOT_MACHINE_ANY_STONE)
    if XTool.IsTableEmpty(buffUidList) then
        return false
    end
    for uid, _ in pairs(buffUidList) do
        local buff = self._MainControl:GetBuffEntityByUid(uid)
        if buff and buff:IsAlive() then
            local params = buff:GetBuffParams()
            for _, v in pairs(params) do
                if v == stoneType then
                    return true
                end
            end
        end
    end
end

function XGoldenMinerSystemSlotScore:_CheckIsAnyType(stoneType)
    return self._MainControl:GetCfgStoneTypeIsSlotAnyType(stoneType)
end

return XGoldenMinerSystemSlotScore