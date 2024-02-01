local XGoldenMinerHideTaskInfo = require("XModule/XGoldenMiner/Data/Settle/XGoldenMinerHideTaskInfo")

---@class XGoldenMinerSystemHideTask:XEntityControl
---@field _MainControl XGoldenMinerGameControl
local XGoldenMinerSystemHideTask = XClass(XEntityControl, "XGoldenMinerSystemHideTask")

--region Override
function XGoldenMinerSystemHideTask:EnterGame()
    ---@type XGoldenMinerHideTaskInfo[]
    self._HideTaskInfoList = {}
    local mapId = self._MainControl:GetGameData():GetMapId()
    -- 隐藏任务
    local hideTaskIdList = self._MainControl:GetCfgMapHideTask(mapId)
    if XTool.IsTableEmpty(hideTaskIdList) then
        return
    end
    for _, hideTaskId in ipairs(hideTaskIdList) do
        self._HideTaskInfoList[#self._HideTaskInfoList + 1] = XGoldenMinerHideTaskInfo.New(hideTaskId)
    end
    self:SetDisable(XTool.IsTableEmpty(self._HideTaskInfoList))
end

function XGoldenMinerSystemHideTask:OnRelease()
    self._HideTaskInfoList = nil
end
--endregion

--region Data
function XGoldenMinerSystemHideTask:GetHideTaskInfoList()
    return self._HideTaskInfoList
end

---隐藏任务缓存值清除
function XGoldenMinerSystemHideTask:ClearHideTaskCatch()
    if self:CheckIsDisable() then
        return
    end
    for _, hideTaskInfo in ipairs(self._HideTaskInfoList) do
        if not hideTaskInfo:IsFinish() then
            hideTaskInfo:SetCatchValue(0)
        end
    end
end
--endregion

--region Check
---隐藏任务
---@param hookEntity XGoldenMinerEntityHook
function XGoldenMinerSystemHideTask:CheckHideTask(hookEntity)
    if self:CheckIsDisable() then
        return
    end
    if XTool.IsTableEmpty(hookEntity:GetGrabbingStoneUidList()) then
        return
    end
    for _, hideTaskInfo in ipairs(self._HideTaskInfoList) do
        if not hideTaskInfo:IsFinish() then
            self:_CheckGrabStone(hideTaskInfo, hookEntity)
            self:_CheckGrabStoneByOnce(hideTaskInfo, hookEntity)
            self:_CheckGrabStoneInBuff(hideTaskInfo, hookEntity)
            self:_CheckGrabStoneByReflection(hideTaskInfo, hookEntity)
            self:_CheckGrabDrawMap(hideTaskInfo, hookEntity)
            --if hideTaskInfo:IsFinish() then
            --    XMVCA.XGoldenMiner:DebugLog("隐藏任务完成:HideTaskId="..hideTaskInfo:GetId())
            --end
        end
    end
end

---@param hideTaskInfo XGoldenMinerHideTaskInfo
---@param hookEntity XGoldenMinerEntityHook
function XGoldenMinerSystemHideTask:_CheckGrabStone(hideTaskInfo, hookEntity)
    if hideTaskInfo:GetCfgType() ~= XEnumConst.GOLDEN_MINER.HIDE_TASK_TYPE.GRAB_STONE then
        return
    end
    for _, uid in ipairs(hookEntity:GetGrabbingStoneUidList()) do
        if self._MainControl:GetStoneEntityByUid(uid).Data:GetId() == hideTaskInfo:GetCfgParams()[1] then
            hideTaskInfo:AddCurProgress()
        end
    end
end

---@param hideTaskInfo XGoldenMinerHideTaskInfo
---@param hookEntity XGoldenMinerEntityHook
function XGoldenMinerSystemHideTask:_CheckGrabStoneByOnce(hideTaskInfo, hookEntity)
    if hideTaskInfo:GetCfgType() ~= XEnumConst.GOLDEN_MINER.HIDE_TASK_TYPE.GRAB_STONE_BY_ONCE then
        return
    end
    local isFinish = false
    for _, uid in ipairs(hookEntity:GetGrabbingStoneUidList()) do
        if self._MainControl:GetStoneEntityByUid(uid).Data:GetId() == hideTaskInfo:GetCfgParams()[1] then
            hideTaskInfo:SetCatchValue(hideTaskInfo:GetCatchValue() + 1)
            isFinish = hideTaskInfo:GetCatchValue() >= hideTaskInfo:GetCfgParams()[2]
        end
    end
    if isFinish then
        hideTaskInfo:AddCurProgress()
    end
end

---@param hideTaskInfo XGoldenMinerHideTaskInfo
---@param hookEntity XGoldenMinerEntityHook
function XGoldenMinerSystemHideTask:_CheckGrabStoneInBuff(hideTaskInfo, hookEntity)
    if hideTaskInfo:GetCfgType() ~= XEnumConst.GOLDEN_MINER.HIDE_TASK_TYPE.GRAB_STONE_IN_BUFF then
        return
    end
    -- 在某Buff加持下抓取物品
    local buffId = hideTaskInfo:GetCfgParams()[2]
    if self._MainControl.SystemBuff:CheckBuffAliveById(buffId) then
        for _, uid in ipairs(hookEntity:GetGrabbingStoneUidList()) do
            if self._MainControl:GetStoneEntityByUid(uid).Data:GetId() == hideTaskInfo:GetCfgParams()[1] then
                hideTaskInfo:AddCurProgress()
            end
        end
    end
end

---@param hideTaskInfo XGoldenMinerHideTaskInfo
---@param hookEntity XGoldenMinerEntityHook
function XGoldenMinerSystemHideTask:_CheckGrabStoneByReflection(hideTaskInfo, hookEntity)
    if hideTaskInfo:GetCfgType() ~= XEnumConst.GOLDEN_MINER.HIDE_TASK_TYPE.GRAB_STONE_BY_REFLECTION then
        return
    end
    local isGrab = false
    local isHitCount = 0
    for _, uid in ipairs(hookEntity:GetGrabbingStoneUidList()) do
        if self._MainControl:GetStoneEntityByUid(uid).Data:GetId() == hideTaskInfo:GetCfgParams()[1] then
            isGrab = true
        end
    end

    if not XTool.IsTableEmpty(hookEntity:GetHitStoneUidList()) then
        for i = 2, #hideTaskInfo:GetCfgParams() do
            for _, uid in ipairs(hookEntity:GetHitStoneUidList()) do
                if self._MainControl:GetStoneEntityByUid(uid).Data:GetId() == hideTaskInfo:GetCfgParams()[i] then
                    isHitCount = isHitCount + 1
                end
            end
        end
    end
    if isGrab and isHitCount >= #hideTaskInfo:GetCfgParams() - 1 then
        hideTaskInfo:AddCurProgress()
    end
end

---@param hideTaskInfo XGoldenMinerHideTaskInfo
---@param hookEntity XGoldenMinerEntityHook
function XGoldenMinerSystemHideTask:_CheckGrabDrawMap(hideTaskInfo, hookEntity)
    if hideTaskInfo:GetCfgType() ~= XEnumConst.GOLDEN_MINER.HIDE_TASK_TYPE.GRAB_DRAW_MAP then
        return
    end
    local mapDrawGroup = self._MainControl:GetControl():GetCfgHideTaskMapDrawGroup(hideTaskInfo:GetCfgParams()[1])
    local isFinish = true
    for _, drawId in ipairs(mapDrawGroup) do
        local index = self._MainControl:GetControl():GetCfgHideTaskMapDrawGroupStoneIdIndex(drawId)
        local isStay = self._MainControl:GetControl():GetCfgHideTaskMapDrawGroupIsStay(drawId)
        local stoneEntity = self._MainControl:GetStoneEntityUidDirByType()[index]
        if isStay then
            if not stoneEntity:IsAlive() then
                isFinish = false
            end
        else
            if not stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBED)
                    and not stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.BE_DESTROY)
                    and not stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.DESTROY)
            then
                isFinish = false
            end
        end
    end
    if isFinish then
        hideTaskInfo:AddCurProgress()
    end
end
--endregion

return XGoldenMinerSystemHideTask