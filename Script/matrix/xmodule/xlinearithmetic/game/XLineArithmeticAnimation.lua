local XLineArithmeticEnum = require("XModule/XLineArithmetic/Game/XLineArithmeticEnum")

-- 终点格吞噬
local EAT_FINAL_GRID_STATE = {
    START = 1,

    --吞噬格子顺序:
    REMOVE_EVENT = 2, --移除事件格, 事件起作用
    REMOVE_EVENT_WAIT = 3, -- 等待
    REMOVE_EMPTY_GRID = 4, -- 移除数字为0的格子
    REMOVE_EMPTY_GRID_WAIT = 5, -- 等待
    FILL_UP_EMPTY_GRID_START = 6, -- 队列前移, 填补空格
    FILL_UP_EMPTY_GRID = 7, -- 队列前移, 填补空格
    EAT_SINGLE_GRID_START = 8, --吃掉单个格子
    EAT_SINGLE_GRID = 9, --吃掉单个格子
    MOVE_REMAIN_GRIDS_START = 10, -- 移动剩余格子
    MOVE_REMAIN_GRIDS = 11, -- 移动剩余格子
    AWAKE_FINAL_GRID = 12, --戳破气泡动画播放
    AWAKE_FINAL_GRID_WAIT = 13, --戳破气泡动画播放
    END = 14
}

-- 停留格吞噬
local EAT_STAY_GRID_STATE = {
    START = 1,
    EAT_GRID = 2,
    MOVE_GRID_WAIT = 3,
    MOVE_GRID = 4,
    NEW_GRID_BORN_EFFECT = 5,
    NEW_GRID_BORN = 6,
}

---@class XLineArithmeticAnimation
local XLineArithmeticAnimation = XClass(nil, "XLineArithmeticAnimation")

function XLineArithmeticAnimation:Ctor()
    self._Type = XLineArithmeticEnum.ANIMATION.NONE
    self._IsFinish = false

    ---@type XLineArithmeticAnimationDataEatFinalGrid
    self._Data = false

    self._Time = 0

    ---@type XLinArithmeticAnimationMoveData[]
    self._MoveDataList = {}

    -- 下面是混合物, 如果动画太多, 再分成不同class
    self._AnimationState = false
    self._CurrentIndex = 1
    self._DurationWaitEvent = 0.3
    self._DurationMoveGrid = 0.2
    self._DurationWaitVanishEffect = 0.3
    self._DurationWaitAwakeEffect = 1.3
    self._InitPosList = false
    ---@type XLinArithmeticAnimationGridData[]
    self._DataToEat = {}

    self._ArrowIndex = 0
    self._ArrowRemoveData = {}

    self._TailGridIndex4Arrow = 0
end

function XLineArithmeticAnimation:SetType(type)
    self._Type = type
end

function XLineArithmeticAnimation:SetData(data)
    self._Data = data
end

---@param ui XUiLineArithmeticGame
function XLineArithmeticAnimation:Update(ui, deltaTime)
    if self._Type == XLineArithmeticEnum.ANIMATION.NONE then
        self:SetFinish()
        return
    end
    if self._Type == XLineArithmeticEnum.ANIMATION.EAT_FINAL_GRID then
        self:UpdateEatFinalGrid(ui, deltaTime)
        return
    end
    if self._Type == XLineArithmeticEnum.ANIMATION.EAT_STAY_GRID then
        self:UpdateEatStayGrid(ui, deltaTime)
        return
    end
end

function XLineArithmeticAnimation:SetFinish()
    self._IsFinish = true
    -- 移除unity.vector3的引用
    self._InitPosList = nil
    self._MoveDataList = nil
end

function XLineArithmeticAnimation:IsFinish()
    return self._IsFinish
end

---@param ui XUiLineArithmeticGame
function XLineArithmeticAnimation:UpdateEatFinalGrid(ui, deltaTime)

    ---@type XLineArithmeticAnimationDataEatFinalGrid
    local data = self._Data

    if self._AnimationState == false then
        self._AnimationState = EAT_FINAL_GRID_STATE.START
    end

    if self._AnimationState == EAT_FINAL_GRID_STATE.START then
        local grids = data.Grids
        if self:SetInitPosList(ui, grids) then
            return
        end
        --ui:UpdateLine(data.LineGrids)
        self._AnimationState = EAT_FINAL_GRID_STATE.REMOVE_EVENT
    end

    if self._AnimationState == EAT_FINAL_GRID_STATE.REMOVE_EVENT then
        local eventGrids = data.GridsRemove4Event
        if #eventGrids == 0 then
            self._AnimationState = EAT_FINAL_GRID_STATE.FILL_UP_EMPTY_GRID_START
        else
            for i = 1, #eventGrids do
                local uid = eventGrids[i]
                local uiGrid = ui:GetUiGridByUid(uid)
                if not uiGrid then
                    self:SetFinish()
                    XLog.Error("[XLineArithmeticAnimation] 移除事件格找不到对应格子", uid)
                    return
                end
                uiGrid:Close()
            end

            local numberGrids = data.KeepGrids
            for i = 1, #numberGrids do
                local numberGridData = numberGrids[i]
                local uid = numberGridData.Uid
                local uiGrid = ui:GetUiGridByUid(uid)
                if not uiGrid then
                    self:SetFinish()
                    XLog.Error("[XLineArithmeticAnimation] 数字格找不到对应格子", uid)
                    return
                end
                --uiGrid:SetScorePreview(numberGridData.ScorePreview)
                if numberGridData.Score then
                    ---@class XLinArithmeticAnimationNumberScrollData
                    local numberScrollData = {
                        Uid = uid,
                        Score = numberGridData.Score,
                    }
                    ui:AddNumberScrollData(numberScrollData)
                end
            end

            self._AnimationState = EAT_FINAL_GRID_STATE.REMOVE_EVENT_WAIT
            self._Time = 0
        end
        self:SetMapDataAfterEvent(ui, data.MapDataAfterEvent)
        return
    end

    if self._AnimationState == EAT_FINAL_GRID_STATE.REMOVE_EVENT_WAIT then
        self._Time = self._Time + deltaTime
        if self._Time >= self._DurationWaitEvent then
            self._AnimationState = EAT_FINAL_GRID_STATE.REMOVE_EMPTY_GRID
            self._Time = 0
        end
        return
    end

    if self._AnimationState == EAT_FINAL_GRID_STATE.REMOVE_EMPTY_GRID then
        local isPlayingAnimation = false
        local numberGrids = data.KeepGrids
        for i = 1, #numberGrids do
            local numberGridData = numberGrids[i]
            local uid = numberGridData.Uid
            local uiGrid = ui:GetUiGridByUid(uid)
            if not uiGrid then
                self:SetFinish()
                XLog.Error("[XLineArithmeticAnimation] 数字格找不到对应格子", uid)
                return
            end
            if ui:IsPlayingNumberScroll() then
                isPlayingAnimation = true
            else
                if numberGridData.Score == 0 then
                    uiGrid:Close()
                end
            end
        end

        if not isPlayingAnimation then
            self._AnimationState = EAT_FINAL_GRID_STATE.REMOVE_EMPTY_GRID_WAIT
            self._Time = 0
        end
        return
    end

    if self._AnimationState == EAT_FINAL_GRID_STATE.REMOVE_EMPTY_GRID_WAIT then
        self._Time = self._Time + deltaTime
        if self._Time >= self._DurationWaitEvent then
            self._AnimationState = EAT_FINAL_GRID_STATE.FILL_UP_EMPTY_GRID_START
            self._Time = 0
        end
        return
    end

    -- 记录 填满格子 需要的数据
    if self._AnimationState == EAT_FINAL_GRID_STATE.FILL_UP_EMPTY_GRID_START then
        local grids = data.KeepGrids
        local numberGridIndex = 0
        ---@type XLinArithmeticAnimationMoveData
        local lastMoveData
        local lastIndex
        for i = 1, #grids do
            local numberGridData = grids[i]
            if numberGridData.Score ~= 0 then
                numberGridIndex = numberGridIndex + 1

                local beginIndex = numberGridData.PosIndex
                local posList = {}
                for j = beginIndex, 1 + numberGridIndex, -1 do
                    local pos = self._InitPosList[j]
                    posList[#posList + 1] = pos
                end

                ---@class XLinArithmeticAnimationMoveData
                local moveData = {
                    Uid = numberGridData.Uid,
                    PosList = posList,
                    CurrentIndex = 1,
                    Time = 0,
                }
                self:AddMoveData(moveData)

                lastMoveData = moveData
                lastIndex = numberGridData.PosIndex

                --self:AddArrowRemoveData(#moveData.PosList - 1)

                ---@class XLinArithmeticAnimationGridData
                local gridData = {
                    Uid = numberGridData.Uid,
                    PosIndex = numberGridIndex,
                    CanEat = numberGridData.CanEat,
                    Score4FinalGrid = numberGridData.Score4FinalGrid,
                }
                self._DataToEat[#self._DataToEat + 1] = gridData
            end
        end

        -- 只给最后一个格子移除箭头
        if lastMoveData and lastIndex then
            lastMoveData.PosIndex = lastIndex
            if lastIndex and lastIndex > self._TailGridIndex4Arrow then
                self._TailGridIndex4Arrow = lastIndex
            end
        end

        -- 因为最后一个格子可能被事件吃掉，导致为空
        -- 把超过最后一个格子的箭头移除
        if lastIndex then
            self:RemoveOverArrow(ui, lastIndex)
        end

        -- 将未完成的格子改回清醒状态
        self:WakeUpFinalGrid(ui, data.AwakeGrids, data.Grids[1], data.RemoveEmoGrids)

        self._AnimationState = EAT_FINAL_GRID_STATE.FILL_UP_EMPTY_GRID
        return
    end

    -- 移动格子同时移除对应箭头
    if self._AnimationState == EAT_FINAL_GRID_STATE.FILL_UP_EMPTY_GRID then
        if self:IsMoving() then
            self:UpdateMoveData(ui, deltaTime)
            return
        end
        self._AnimationState = EAT_FINAL_GRID_STATE.EAT_SINGLE_GRID_START
        return
    end

    -- 吃掉单个格子
    if self._AnimationState == EAT_FINAL_GRID_STATE.EAT_SINGLE_GRID_START then
        local dataToEat = self._DataToEat[1]
        if not dataToEat then
            self._AnimationState = EAT_FINAL_GRID_STATE.AWAKE_FINAL_GRID
            return
        end
        if not dataToEat.CanEat then
            self._AnimationState = EAT_FINAL_GRID_STATE.AWAKE_FINAL_GRID
            return
        end

        local uiGrid = ui:GetUiGridByUid(dataToEat.Uid)
        local pos = uiGrid.Transform.localPosition

        ---@type XLinArithmeticAnimationMoveData
        local moveData = {
            Uid = dataToEat.Uid,
            PosList = { pos, self:GetTailGridPos() },
            CurrentIndex = 1,
            Time = 0,
        }
        self:AddMoveData(moveData)
        self._AnimationState = EAT_FINAL_GRID_STATE.EAT_SINGLE_GRID
        return
    end

    if self._AnimationState == EAT_FINAL_GRID_STATE.EAT_SINGLE_GRID then
        if self:IsMoving() then
            self:UpdateMoveData(ui, deltaTime)
        else
            local tailGridUid = self:GetTailGridUid()
            local dataToEat = self._DataToEat[1]
            if dataToEat.Score4FinalGrid then
                ---@type XLinArithmeticAnimationNumberScrollData
                local numberScrollData = {
                    Uid = tailGridUid,
                    Score = dataToEat.Score4FinalGrid,
                }
                ui:AddNumberScrollData(numberScrollData)
            end
            table.remove(self._DataToEat, 1)
            self._AnimationState = EAT_FINAL_GRID_STATE.MOVE_REMAIN_GRIDS_START

            -- 万事结算时，每吃一个数字格播放一次，音效ID：4704
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.LineArithmeticEat)
        end
        return
    end

    if self._AnimationState == EAT_FINAL_GRID_STATE.MOVE_REMAIN_GRIDS_START then
        for i = 1, #self._DataToEat do
            local dataToEat = self._DataToEat[i]
            local pos1 = self._InitPosList[dataToEat.PosIndex]
            local pos2 = self._InitPosList[dataToEat.PosIndex + 1]
            if pos1 and pos2 then
                ---@type XLinArithmeticAnimationMoveData
                local moveData = {
                    Uid = dataToEat.Uid,
                    PosList = { pos2, pos1 },
                    CurrentIndex = 1,
                    Time = 0,
                    PosIndex = (i == #self._DataToEat) and (dataToEat.PosIndex + 1) or false,
                }
                self:AddMoveData(moveData)
                --self:AddArrowRemoveData(#moveData.PosList - 1)
            else
                XLog.Error("[XLineArithmeticAnimation] 移动格子逻辑有问题", dataToEat.PosIndex)
                self:SetFinish()
                return
            end

            dataToEat.PosIndex = dataToEat.PosIndex - 1
        end
        self._AnimationState = EAT_FINAL_GRID_STATE.MOVE_REMAIN_GRIDS
        return
    end

    if self._AnimationState == EAT_FINAL_GRID_STATE.MOVE_REMAIN_GRIDS then
        if self:IsMoving() then
            self:UpdateMoveData(ui, deltaTime)
        else
            self._AnimationState = EAT_FINAL_GRID_STATE.EAT_SINGLE_GRID_START
        end
        return
    end

    if self._AnimationState == EAT_FINAL_GRID_STATE.AWAKE_FINAL_GRID then
        if data.IsFinalGridPlayAwake then
            local lastGrid = data.Grids[1]
            local uid = lastGrid
            local uiGrid = ui:GetUiGridByUid(uid)
            uiGrid:SetEffectByData({
                IsAwake = true
            })
            self._Time = 0
            self._AnimationState = EAT_FINAL_GRID_STATE.AWAKE_FINAL_GRID_WAIT

            -- 结算完，万事未完成时，开始播放，知道气泡破裂的特效结束，音效ID：4705
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.LineArithmeticBubbleBreak)
        else
            self._AnimationState = EAT_FINAL_GRID_STATE.END

            -- 结算完，万事完成时，播放一次，音效ID：4706
            XScheduleManager.ScheduleOnce(function()
                XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.LineArithmeticFinishFinalGrid)
            end, 500)
        end
        return
    end

    if self._AnimationState == EAT_FINAL_GRID_STATE.AWAKE_FINAL_GRID_WAIT then
        self._Time = self._Time + deltaTime
        if self._Time >= self._DurationWaitAwakeEffect then
            self._AnimationState = EAT_FINAL_GRID_STATE.END
            self._Time = 0
        end
        return
    end

    if self._AnimationState == EAT_FINAL_GRID_STATE.END then
        self:SetFinish()
        return
    end
end

---@param ui XUiLineArithmeticGame
function XLineArithmeticAnimation:RemoveArrowByIndex(ui, arrowIndex)
    --local isRemoveArrow = self._ArrowRemoveData[arrowIndex]
    --if isRemoveArrow then
    --    self._ArrowRemoveData[arrowIndex] = false
    --end
    self:RemoveArrow(ui, arrowIndex)
end

---@param ui XUiLineArithmeticGame
function XLineArithmeticAnimation:RemoveOverArrow(ui, arrowIndex)
    ui:RemoveOverLineByIndex(arrowIndex)
end

---@param ui XUiLineArithmeticGame
function XLineArithmeticAnimation:UpdateMoveData(ui, deltaTime)
    for i = #self._MoveDataList, 1, -1 do
        local moveData = self._MoveDataList[i]
        if moveData.CurrentIndex >= #moveData.PosList then
            -- 结束
            table.remove(self._MoveDataList, i)
            --local arrowIndex = moveData.CurrentIndex - 1
            --self:RemoveArrowByIndex(ui, arrowIndex)

            --self:CheckRemoveArrow(ui, moveData)
        else
            local index = moveData.CurrentIndex
            moveData.Time = moveData.Time + deltaTime
            local time = moveData.Time
            local duration = self._DurationMoveGrid
            local progress = time / duration
            if time > duration then
                progress = 1
            end
            local posList = moveData.PosList
            local pos1 = posList[index]
            local pos2 = posList[index + 1]
            local center = (pos2 - pos1) * progress + pos1
            local uiGrid = ui:GetUiGridByUid(moveData.Uid)
            if uiGrid then
                uiGrid.Transform.localPosition = center
            else
                XLog.Error("[XLineArithmeticAnimation] 移动格子失败", moveData.Uid)
            end

            if time >= duration then
                moveData.Time = 0
                moveData.CurrentIndex = moveData.CurrentIndex + 1
                self:CheckRemoveArrow(ui, moveData)
            end
        end
    end
end

function XLineArithmeticAnimation:CheckRemoveArrow(ui, moveData)
    if moveData.PosIndex then
        if moveData.PosIndex == self._TailGridIndex4Arrow then
            self:RemoveArrowByIndex(ui, self._TailGridIndex4Arrow)
            self._TailGridIndex4Arrow = self._TailGridIndex4Arrow - 1
            moveData.PosIndex = moveData.PosIndex - 1
        end
    end
end

function XLineArithmeticAnimation:IsMoving()
    return #self._MoveDataList ~= 0
end

function XLineArithmeticAnimation:GetTailGridPos()
    return self._InitPosList[1]
end

---@param moveData XLinArithmeticAnimationMoveData
function XLineArithmeticAnimation:AddMoveData(moveData)
    self._MoveDataList[#self._MoveDataList + 1] = moveData
end

function XLineArithmeticAnimation:GetTailGridUid()
    return self._Data.Grids[1]
end

---@param ui XUiLineArithmeticGame
function XLineArithmeticAnimation:RemoveArrow(ui, arrowIndex)
    if not arrowIndex then
        return
    end
    ui:HideUiLineByIndex(arrowIndex)
end

function XLineArithmeticAnimation:AddArrowRemoveData(arrowIndex)
    if arrowIndex > 0 then
        self._ArrowRemoveData[arrowIndex] = true
    end
end

---@param ui XUiLineArithmeticGame
function XLineArithmeticAnimation:UpdateEatStayGrid(ui, deltaTime)

    ---@type XLineArithmeticAnimationDataEatStayGrid
    local data = self._Data

    if self._AnimationState == false then
        self._AnimationState = EAT_STAY_GRID_STATE.START
    end

    if self._AnimationState == EAT_STAY_GRID_STATE.START then
        self._AnimationState = EAT_STAY_GRID_STATE.EAT_GRID
    end

    if self._AnimationState == EAT_STAY_GRID_STATE.EAT_GRID then
        local grids = data.Grids
        if self:SetInitPosList(ui, grids) then
            return
        end

        local eatGrids = data.EatGrids
        for i = 1, #eatGrids do
            local uid = eatGrids[i]
            local uiGrid = ui:GetUiGridByUid(uid)
            if uiGrid then
                uiGrid:Close()
            else
                XLog.Error("[XLineArithmeticAnimation] 停留事件格找不到格子:", uid)
            end
        end
        self._AnimationState = EAT_STAY_GRID_STATE.MOVE_GRID_WAIT
        return
    end

    if self._AnimationState == EAT_STAY_GRID_STATE.MOVE_GRID_WAIT then
        self._Time = self._Time + deltaTime
        if self._Time >= self._DurationWaitEvent then
            self._AnimationState = EAT_STAY_GRID_STATE.MOVE_GRID
            self._Time = 0

            local grids = data.KeepGrids
            local numberGridIndex = 0
            for i = 1, #grids do
                numberGridIndex = numberGridIndex + 1
                local gridData = grids[i]

                local beginIndex = gridData.PosIndex
                local posList = {}
                for j = beginIndex, 1 + numberGridIndex, -1 do
                    local pos = self._InitPosList[j]
                    posList[#posList + 1] = pos
                end

                ---@type XLinArithmeticAnimationMoveData
                local moveData = {
                    Uid = gridData.Uid,
                    PosList = posList,
                    CurrentIndex = 1,
                    Time = 0,
                    PosIndex = beginIndex,
                }
                self:AddMoveData(moveData)

                if beginIndex > self._TailGridIndex4Arrow then
                    self._TailGridIndex4Arrow = beginIndex
                end
            end

            -- 把超过最后一个格子的箭头移除
            self:RemoveOverArrow(ui, self._TailGridIndex4Arrow)

            -- 将未完成的格子改回清醒状态
            self:WakeUpFinalGrid(ui, data.AwakeGrids, data.Grids[1])

            self._AnimationState = EAT_STAY_GRID_STATE.MOVE_GRID
        end
        return
    end

    if self._AnimationState == EAT_STAY_GRID_STATE.MOVE_GRID then
        if self:IsMoving() then
            self:UpdateMoveData(ui, deltaTime)
            return
        end
        self._AnimationState = EAT_STAY_GRID_STATE.NEW_GRID_BORN_EFFECT
        self._Time = 0

        -- 播放雾气特效
        local tailGridUid = self._Data.Grids[1]
        if tailGridUid then
            local grid = ui:GetUiGridByUid(tailGridUid)
            grid:SetReplaceEffect()
        end
        return
    end

    if self._AnimationState == EAT_STAY_GRID_STATE.NEW_GRID_BORN_EFFECT then
        self._Time = self._Time + deltaTime
        if self._Time >= self._DurationWaitVanishEffect then
            self._AnimationState = EAT_STAY_GRID_STATE.NEW_GRID_BORN
        end
        return
    end

    if self._AnimationState == EAT_STAY_GRID_STATE.NEW_GRID_BORN then
        self._Time = self._Time + deltaTime
        if self._Time >= self._DurationWaitEvent then
            self:SetFinish()
        end
        return
    end
end

---@return boolean is Error
function XLineArithmeticAnimation:SetInitPosList(ui, grids)
    self._InitPosList = {}

    for i = 1, #grids do
        local uid = grids[i]
        local uiGrid = ui:GetUiGridByUid(uid)
        if not uiGrid then
            XLog.Error("[XLineArithmeticAnimation] 初始化格子坐标找不到对应格子", uid)
            self:SetFinish()
            return true
        end
        uiGrid.Transform:SetSiblingIndex(uiGrid.Transform.parent.childCount - i)

        ---@type UnityEngine.RectTransform
        local rectTransform = uiGrid.Transform
        local localPosition = rectTransform.localPosition
        self._InitPosList[i] = localPosition
    end

    return false
end

---@param ui XUiLineArithmeticGame
function XLineArithmeticAnimation:WakeUpFinalGrid(ui, grids, gridFinal, gridsRemoveEmo)
    for i = 1, #grids do
        local data = grids[i]
        local uid = data.Uid
        local uiGrid = ui:GetUiGridByUid(uid)
        if uiGrid then
            uiGrid:SetFinalGridIcon(data.Icon)
            uiGrid:SetEffectByData(data)
            uiGrid:HideEmoIcon()
            if data.ScoreAfterEvent then
                uiGrid:SetTextNumber(data.ScoreAfterEvent)
                uiGrid:SetScorePreview(0)
            end
        else
            XLog.Error("[XLineArithmeticAnimation] 摇醒终点格逻辑有问题:", uid)
        end
    end

    if gridFinal then
        local uid = gridFinal
        local uiGrid = ui:GetUiGridByUid(uid)
        if uiGrid then
            uiGrid:HideEmoIcon()
            uiGrid:SetEffectByData({ IsSleep = true })
        end
    end

    if gridsRemoveEmo then
        for i = 1, #gridsRemoveEmo do
            local data = gridsRemoveEmo[i]
            local uid = data.Uid
            local uiGrid = ui:GetUiGridByUid(uid)
            if uiGrid then
                uiGrid:SetFinalGridIcon(data.Icon)
                uiGrid:SetEffectByData(data)
                uiGrid:HideEmoIcon()
            else
                XLog.Error("[XLineArithmeticAnimation] 移除终点格表情逻辑有问题:", uid)
            end
        end
    end
end

function XLineArithmeticAnimation:SetMapDataAfterEvent(ui, mapDataAfterEvent)
    for i = 1, #mapDataAfterEvent do
        local mapData = mapDataAfterEvent[i]
        local uid = mapData.Uid
        local uiGrid = ui:GetUiGridByUid(uid)
        if not uiGrid then
            XLog.Error("[XLineArithmeticAnimation] 事件结算后, 设置格子分数有问题:", uid)
            self:SetFinish()
            return
        end
        uiGrid:SetTextNumber(mapData.Number)
        uiGrid:SetScorePreview(mapData.NumberOnPreview)
    end
end

return XLineArithmeticAnimation
