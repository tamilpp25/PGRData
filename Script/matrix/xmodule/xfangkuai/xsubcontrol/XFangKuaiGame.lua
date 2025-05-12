---@class XFangKuaiGame : XControl 大方块规则
---@field _HasCreated boolean 新行是否已生成
---@field _HasApplyItem boolean 是否道具已使用
---@field _StageConfig XTableFangKuaiStage
---@field _GridStateMap table<number,table<number,number>> 用于检查格子是否为空
---@field _BlockToGridMap table<XFangKuaiBlock,table> 用于获取所有方块及方块占用的格子
---@field _LayerBlocks table<number,table<XFangKuaiBlock,boolean>> 用于获取某一行所有方块
---@field _MainControl XFangKuaiControl
---@field _Model XFangKuaiModel
---@field _NewBlockPool table<number,XFangKuaiBlock[]>
---@field _InitBlocks table 第一次进战斗/重新登录时显示的初始方块
---@field _CurAddLineCount number 当前回合新生成的行数
---@field _IsGameOver boolean 是否游戏已结束
local XFangKuaiGame = XClass(XControl, "XFangKuaiGame")

local OperateMode = XEnumConst.FangKuai.OperateMode

function XFangKuaiGame:OnInit()
    self:InitData()
end

function XFangKuaiGame:AddAgencyEvent()

end

function XFangKuaiGame:RemoveAgencyEvent()

end

function XFangKuaiGame:OnRelease()
    self:SaveStageBlockData()
end

function XFangKuaiGame:SetStage(stageId)
    self._StageId = stageId
    self._ChapterId = self._MainControl:GetChapterIdByStage(stageId)
    self._StageConfig = self._MainControl:GetStageConfig(stageId)
    self._StageData = self._Model.ActivityData:GetStageData(self._ChapterId)
    self._MaxX = self._StageConfig.SizeX
    self._MaxY = self._StageConfig.SizeY
    self._IsGameOver = false
    self._IsGameOverByDrop = false
    self:UpdateBlockData()
    self._Model:RecordFightChapterId(self._ChapterId)
end

function XFangKuaiGame:InitData()
    self._StageConfig = nil
    self:ClearData()
end

function XFangKuaiGame:ClearData()
    self._HasCreated = false
    self._OperateMap = {}
    self._LayerBlocks = {}
    self._GridStateMap = {}
    self._BlockToGridMap = {}
    self._NewBlockPool = {}
    self._InitBlocks = {}
    self._CurAddLineCount = 1
end

-- 新关卡 需要生成初始方块
function XFangKuaiGame:StartCreateInitBlock()
    self._HasCreated = false
    self._MainControl:ResetCombo()
    self:CheckInitCreateDropBlockData()
    self:AsynInitBlockOperate()
end

function XFangKuaiGame:StartRound(curBlockGridY)
    self._HasCreated = false
    self._MainControl:ResetCombo()
    -- 因为进游戏后可能没有任何操作就退出了，所以cd-1不能放在AsynInitBlockOperate里
    if self._MainControl:GetCurRound(self._ChapterId) == 0 then
        self._StageData:ReduceDropBlockCd()
    end
    self:AsynStartOperate(curBlockGridY)
end

function XFangKuaiGame:StartUseColorItem(index, kind, color, params)
    if kind == XEnumConst.FangKuai.ItemType.LengthReduce then
        self._MainControl:ExecuteLengthReduce(index, color)
    elseif kind == XEnumConst.FangKuai.ItemType.BecomeOneGrid then
        self._MainControl:ExecuteBecomeOneGrid(index, color, self._ChapterId)
    elseif kind == XEnumConst.FangKuai.ItemType.Born then
        self._MainControl:ExecuteBorn(index, color, self._StageConfig.SizeX, self._StageConfig.SizeY, self._ChapterId)
    elseif kind == XEnumConst.FangKuai.ItemType.Grow then
        self._MainControl:ExecuteGrow(index, color, params, self._StageConfig.SizeX, self._StageConfig.SizeY)
    end
    self:StartUseItem()
end

function XFangKuaiGame:StartUseRemoveItem(index, blockData)
    self._MainControl:ExecuteSingleLineRemove(index, blockData)
    self:StartUseItem()
end

function XFangKuaiGame:StartUseExchangeItem(index, kind, blockData1, blockData2)
    if kind == XEnumConst.FangKuai.ItemType.TwoLineExChange then
        self._MainControl:ExecuteTwoLineExChange(index, blockData1, blockData2)
    elseif kind == XEnumConst.FangKuai.ItemType.AdjacentExchange then
        self._MainControl:ExecuteAdjacentExchange(index, blockData1, blockData2)
    end
    self:StartUseItem()
end

function XFangKuaiGame:StartAddRoundItem(index, params)
    self._MainControl:ExecuteAddRound(index, params)
    self._MainControl:FangKuaiStageSyncOperatorRequest(self._StageId)
end

function XFangKuaiGame:StartUseFrozenRoundItem(index)
    self._MainControl:ExecuteFrozen(index, self._ChapterId)
    self._MainControl:FangKuaiStageSyncOperatorRequest(self._StageId)
end

function XFangKuaiGame:StartUseAlignmentItem(index, gridY, direction)
    self._MainControl:ExecuteAlignment(index, gridY, direction, self._StageConfig.SizeX)
    self:StartUseItem()
end

function XFangKuaiGame:StartUseConvertionItem(index)
    local blockData = self._MainControl:ExecuteConvertion(index, self._StageId)
    self._MainControl:FangKuaiStageSyncOperatorRequest(self._StageId)
    return blockData
end

function XFangKuaiGame:StartUseItem()
    self._HasApplyItem = false
    self:AsynUseItemOperate()
end

-- 临时添加 用来显示Lua协程报错
function XFangKuaiGame:XPCall(func)
    if XMain.IsWindowsEditor then
        xpcall(func, function(error)
            XLog.Error(error)
        end)
    else
        func()
    end
end

-- 因为Lua协程没法中断删除 所以在游戏因为断线重连返回主界面后 得手动return掉协程 否则_MainControl为空会报错
function XFangKuaiGame:IsProceedAsyn()
    return self._MainControl and not self._MainControl:GetIsRelease()
end

function XFangKuaiGame:AsynRunOperate(operateMode)
    local time = self:RunOperate(operateMode)
    asynWaitSecond(time)
    return self:IsProceedAsyn()
end

-- 由于分裂BOSS会生成小方块 所以这里先执行clear 把全部小方块生成出来先 否则表现上有点奇怪
function XFangKuaiGame:AsynRunAllOperate()
    local time = self:RunOperate(OperateMode.Clear)
    asynWaitSecond(time)
    if not self:IsProceedAsyn() then
        return false
    end
    time = self:RunAllOperate()
    asynWaitSecond(time)
    return self:IsProceedAsyn()
end

-- 移动方块 -> 检查掉落 -> 检查消除 -> 再次检查掉落 -> 没有方块可掉落 -> 生成新方块 -> 再次检查掉落 -> 没有方块可掉落 -> 检查额外掉落 -> 结束
function XFangKuaiGame:AsynStartOperate(curBlockGridY)
    RunAsyn(function()
        self:XPCall(function()
            -- 方块掉落
            self:CheckAllLayerBlockDrop(curBlockGridY)
            if not self:AsynRunOperate(OperateMode.MoveY) then
                return
            end
            -- 整行消除
            self:CheckAllClearUp()
            local hasClearUpOperate = self:IsExitOperate(OperateMode.Clear)
            -- 如果存在消除整行的操作，则必定有方块会掉落，递归执行
            if hasClearUpOperate then
                if not self:AsynRunOperate(OperateMode.Clear) then
                    return
                end
                if not self:AsynRunOperate(OperateMode.Create) then -- 分裂BOSS消除后会生成小方块
                    return
                end
                if not self:IsBlockEmpty() then
                    self:AsynStartOperate()
                    return
                end
            end
            -- 已经生成新方块且总行数>=2行，流程结束
            local extraAddLine
            if self._HasCreated then
                local residue = self:GetExistBlockLayerNum()
                if residue <= 1 then
                    extraAddLine = self:GetCreateExtraLayerCount()
                else
                    -- 检查是否有顶部方块掉落的关卡环境
                    if self:CheckTopBlockDrop() then
                        self:AsynStartOperate()
                        return
                    end
                    self:OnRoundEnd()
                    return
                end
            end
            -- 道具效果 新行不生成 补充行能正常生成
            if not self._MainControl:IsRoundFrozen(self._ChapterId) or extraAddLine then
                -- 设置新方块坐标 如果行数不足 创建新方块补足
                if not self:AddNewBlocks(extraAddLine) then
                    return
                end
                if not self:AsynRunOperate(OperateMode.Create) then
                    return
                end
                -- 全部方块上移
                self:AllMoveUp()
                if not self:AsynRunOperate(OperateMode.MoveY) then
                    return
                end
            end
            self._HasCreated = true
            -- 再次检查是否有方块会掉落及消除
            self:AsynStartOperate()
        end)
    end)
end

function XFangKuaiGame:AsynInitBlockOperate()
    RunAsyn(function()
        self:XPCall(function()
            -- 创建初始方块/方块清空后生成新方块
            if self:IsNeedCreateExtraBlock() then
                if self._HasCreated then
                    if not self:AddNewBlocks(self:GetCreateExtraLayerCount()) then
                        return
                    end
                    if not self:AsynRunOperate(OperateMode.Create) then
                        return
                    end
                    -- 全部方块上移
                    self:AllMoveUp()
                    if not self:AsynRunOperate(OperateMode.MoveY) then
                        return
                    end
                else
                    self:AddInitBlock()
                    if not self:AsynRunOperate(OperateMode.Create) then
                        return
                    end
                    self._HasCreated = true
                end
            end
            -- 方块掉落
            self:CheckAllLayerBlockDrop()
            if not self:AsynRunOperate(OperateMode.MoveY) then
                return
            end
            -- 方块消除
            self:CheckAllClearUp()
            local hasClearUpOperate = self:IsExitOperate(OperateMode.Clear)
            if not self:AsynRunOperate(OperateMode.Clear) then
                return
            end
            if not self:AsynRunOperate(OperateMode.Create) then
                return
            end
            if hasClearUpOperate or self:IsNeedCreateExtraBlock() then
                self:AsynInitBlockOperate()
                return
            end
            -- 创建关卡环境顶部方块预览
            if self._MainControl:GetCurRound() == 0 then
                if self:CheckTopBlockDrop() then
                    self:AsynInitBlockOperate()
                    return
                end
            end
            -- 同步初始数据给服务端
            if self._StageData:IsNeedSendInitBlockData() then
                self._MainControl:FangKuaiStageSyncOperatorRequest(self._StageId)
            end
            XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_SRARTROUND)
        end)
    end)
end

function XFangKuaiGame:AsynUseItemOperate()
    RunAsyn(function()
        self:XPCall(function()
            -- 执行道具操作
            if not self._HasApplyItem then
                local isBlockRemove = self:IsBlockRemoveInCurOperate()
                self:AsynRunAllOperate()
                -- 有方块消除则Combo+1
                if isBlockRemove then
                    self._MainControl:AddCombo()
                end
            end
            self._HasApplyItem = true
            -- 方块掉落
            self:CheckAllLayerBlockDrop()
            if not self:AsynRunOperate(OperateMode.MoveY) then
                return
            end
            -- 整行消除
            self:CheckAllClearUp()
            local hasClearUpOperate = self:IsExitOperate(OperateMode.Clear)
            if not self:AsynRunOperate(OperateMode.Clear) then
                return
            end
            if not self:AsynRunOperate(OperateMode.Create) then
                return
            end
            if hasClearUpOperate then
                self:AsynUseItemOperate()
                return
            end
            -- 检查剩余层数
            if self:IsNeedCreateExtraBlock() then
                if not self:AddNewBlocks(self:GetCreateExtraLayerCount()) then
                    return
                end
                if not self:AsynRunOperate(OperateMode.Create) then
                    return
                end
                -- 全部方块上移
                self:AllMoveUp()
                if not self:AsynRunOperate(OperateMode.MoveY) then
                    return
                end
                self:AsynUseItemOperate()
                return
            end
            -- 重置combo
            self._MainControl:ResetCombo()
            self._MainControl:FangKuaiStageSyncOperatorRequest(self._StageId)
            XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_USEITEMEND)
        end)
    end)
end

function XFangKuaiGame:OnGameOver(isAdvanceEnd)
    if self._IsGameOver then
        return
    end
    self._IsGameOver = true
    local settleType = isAdvanceEnd and XEnumConst.FangKuai.Settle.Advance or XEnumConst.FangKuai.Settle.Normal
    self._MainControl:FangKuaiStageSettleRequest(self._StageId, settleType, function()
        XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_GAMEOVER, isAdvanceEnd)
    end, not isAdvanceEnd)
end

function XFangKuaiGame:OnRoundEnd()
    self._MainControl:AddRound()

    local isNextRoundGameOver = self:IsNextRoundGameOver()
    if not isNextRoundGameOver then
        if self._Model:HasBlockDropEnviroment(self._StageId) then
            if self._StageData:IsBlockDrop() then
                self._MainControl:StartNextTimesBlockDrop(self._StageId)
            else
                self._StageData:ReduceDropBlockCd()
            end
        end
    end

    self._MainControl:ReduceFrozenRound(self._ChapterId)

    if isNextRoundGameOver then
        self._MainControl:FangKuaiStageSyncOperatorRequest(self._StageId)
        self:OnGameOver()
    else
        if not self._MainControl:IsRoundFrozen(self._ChapterId) then
            -- 生成新方块
            self._MainControl:CreateNewLines()
            self:UpdateBlockData()
        end
        self._MainControl:FangKuaiStageSyncOperatorRequest(self._StageId)
        self._MainControl:ResetCombo()
    end

    self:PrintDebugBlockPosition()

    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_SRARTROUND)
end

-- 前后端数据不匹配 重置客户端数据
function XFangKuaiGame:ResetFromService()
    self._Round = self._MainControl:GetCurRound(self._ChapterId)
    self:ClearData()
    self:UpdateBlockData()
    self._OperateMap = {}
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_RESET)
end

function XFangKuaiGame:AddOperate(operate, args)
    if not self._OperateMap[operate] then
        self._OperateMap[operate] = {}
    end
    table.insert(self._OperateMap[operate], args)
end

function XFangKuaiGame:RunOperate(operate)
    local maxOperateTime = 0
    local args = self._OperateMap[operate]
    if args then
        for i, arg in ipairs(args) do
            local operateTime = 0
            if operate == OperateMode.MoveY then
                operateTime = self:DoMoveY(arg[1], arg[2])
            elseif operate == OperateMode.MoveX then
                operateTime = self:DoMoveX(arg[1], arg[2], arg[3])
            elseif operate == OperateMode.Clear then
                operateTime = self:DoClear(arg[1], i, #args)
            elseif operate == OperateMode.Create then
                operateTime = self:DoCreate(arg[1])
            elseif operate == OperateMode.Wane then
                operateTime = self:DoWane(arg[1], arg[2])
            elseif operate == OperateMode.Remove then
                operateTime = self:DoRemove(arg[1], arg[2])
            elseif operate == OperateMode.Grow then
                operateTime = self:DoGrow(arg[1], arg[2])
            end
            maxOperateTime = math.max(maxOperateTime, operateTime)
        end
        if operate == OperateMode.Clear then
            -- 只是为了播特效
            XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_CLEAR, args)
        end
        self:GetDebugOperateLog(operate, args, maxOperateTime)
        self._OperateMap[operate] = {}
    end
    return maxOperateTime
end

function XFangKuaiGame:RunAllOperate()
    local maxTime = 0
    for operate, _ in pairs(self._OperateMap) do
        local time = self:RunOperate(operate)
        maxTime = math.max(maxTime, time)
    end
    return maxTime
end

function XFangKuaiGame:AddNewBlocks(line)
    self._CurAddLineCount = line or self._MainControl:GetNewLineCount()

    local addLine = self._CurAddLineCount - self:GetNewBlockLastY() + 1
    if addLine > 0 then
        self._MainControl:CreateNewLines(addLine)
        self:UpdateBlockData()
    end

    for i = 1, self._CurAddLineCount do
        local blockDatas = self:GetNewBlockDatas(1, true)
        if XTool.IsTableEmpty(blockDatas) then
            XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_ERROR_RESET)
            XLog.Error("新方块池为空 前后端数据出现错误 重新开始游戏")
            return false
        end
        for _, data in pairs(blockDatas) do
            local grid = data:GetHeadGrid()
            data:UpdatePos(grid.x, 1 - i)
            self:AddOperate(OperateMode.Create, { data })
        end
    end
    if line then
        -- 更新方块预览时 因移动方块造成的生成 要等Round+1后再调 因为显示预览需要下回合的Round
        XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_ADDLINE)
    end
    return true
end

function XFangKuaiGame:AddInitBlock()
    for _, blockData in pairs(self._InitBlocks) do
        self:AddOperate(OperateMode.Create, { blockData })
    end
    self._InitBlocks = {}
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_ADDLINE)
end

---衰弱型BOSS方块会先变短，最后再消失
---@param blockData XFangKuaiBlock
---@param isClear boolean 长度缩短是否因为整行消除（要等整行消除特效播完再播缩短特效）
function XFangKuaiGame:WaneBlock(blockData, count, isClear)
    local len = blockData:GetLen()
    if len <= count then
        self:DoRemove(blockData)
    else
        blockData:UpdateLen(len - count)
        self:SignGridOccupyAuto(blockData)
        XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_WANE, blockData, isClear)
    end
end

---@param blockData XFangKuaiBlock
function XFangKuaiGame:GrowBlock(blockData, count)
    blockData:UpdateLen(blockData:GetLen() + count, true)
    self:SignGridOccupyAuto(blockData)
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_GROW, blockData)
end

---指定次数型BOSS在达到最大受击次数前不会变短 达到后会直接移除
---@param blockData XFangKuaiBlock
function XFangKuaiGame:HitBlock(blockData)
    local hitTimes = blockData:GetHitTimes()
    blockData:SetHitTimes(hitTimes + 1)
    if blockData:IsMaxHitTimes() then
        self:DoRemove(blockData)
    else
        XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_HIT, blockData)
    end
end

---裂变型BOSS每次都会分裂一个1单位正常方块和长度-1的新BOSS方块出来
---@param blockData XFangKuaiBlock
function XFangKuaiGame:FissionBlock(blockData)
    local len = blockData:GetLen()
    if len > 2 then
        local pos = blockData:IsFacingLeft() and blockData:GetHeadGrid() or blockData:GetTailGrid()
        local block = self._MainControl:CreateFissionBlockData(1, pos, blockData, 0, self._StageId)
        self:AddOperate(OperateMode.Create, { block })

        blockData:UpdateLenAndOffset(len - 1, 1)
        self:SignGridOccupyAuto(blockData)
        XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_WANE, blockData, true)
    elseif len == 2 then
        local block1 = self._MainControl:CreateFissionBlockData(1, blockData:GetHeadGrid(), blockData, 0, self._StageId)
        local block2 = self._MainControl:CreateFissionBlockData(1, blockData:GetTailGrid(), blockData, 0, self._StageId)
        self:AddOperate(OperateMode.Create, { block1 })
        self:AddOperate(OperateMode.Create, { block2 })
        self:DoRemove(blockData)
    end
end

---标记方块占用
---@param blockData XFangKuaiBlock
function XFangKuaiGame:SignGridOccupy(blockData, gridX, gridY, isClear)
    local datas = self._BlockToGridMap[blockData]
    if not XTool.IsTableEmpty(datas) then
        for _, gridPos in pairs(datas) do
            -- 如果该位置已经被其他方块占用了 就不能清除 否则会把其他方块的占用信息清空
            if self._GridStateMap[gridPos.y][gridPos.x] == blockData:GetId() then
                self._GridStateMap[gridPos.y][gridPos.x] = nil
            end
        end
        self._LayerBlocks[datas[1].y][blockData] = nil
    end

    if isClear then
        self._BlockToGridMap[blockData] = nil
    else
        local datas = {}
        local tailPos = blockData:CalculateTailPos(gridX)
        for x = gridX, tailPos do
            table.insert(datas, { x = x, y = gridY })
            if not self._GridStateMap[gridY] then
                self._GridStateMap[gridY] = {}
            end
            self._GridStateMap[gridY][x] = blockData:GetId()
        end
        self._BlockToGridMap[blockData] = datas
        if not self._LayerBlocks[gridY] then
            self._LayerBlocks[gridY] = {}
        end
        self._LayerBlocks[gridY][blockData] = true
    end
end

---@param blockData XFangKuaiBlock
function XFangKuaiGame:SignGridOccupyAuto(blockData, isClear)
    local grid = blockData:GetHeadGrid()
    self:SignGridOccupy(blockData, grid.x, grid.y, isClear)
end

function XFangKuaiGame:CheckGridEmpty(gridX, gridY)
    return not self._GridStateMap[gridY] or not self._GridStateMap[gridY][gridX]
end

---方块上升一层（从上到下）
function XFangKuaiGame:AllMoveUp()
    for y = self._MaxY, -self._CurAddLineCount, -1 do
        local blockDatas = self._LayerBlocks[y]
        if blockDatas then
            for blockData, _ in pairs(blockDatas) do
                local gridY = blockData:GetNextUpGrid(self._CurAddLineCount)
                self:AddOperate(OperateMode.MoveY, { blockData, gridY })
            end
        end
    end
end

function XFangKuaiGame:IsNextRoundGameOver()
    local round = self:GetLeaveRound()
    if round and round <= 0 then
        return true
    end
    return self:IsBlockOverflow()
end

function XFangKuaiGame:IsBlockOverflow()
    -- 方块超出了最大行数
    local top = self:GetLayerBlocks(self._MaxY + 1)
    if not XTool.IsTableEmpty(top) then
        return true
    end
    -- 最顶行被占用了 顶部方块掉落后会超出最大行数 所以游戏结束
    if self._IsGameOverByDrop then
        return true
    end
    return false
end

---检查单个方块掉落
---@param blockData XFangKuaiBlock
function XFangKuaiGame:CheckBlockDrop(blockData)
    local dropGridY
    local drops = blockData:GetAllGridDown()
    for i, grids in ipairs(drops) do
        local canDrop = true
        for _, grid in pairs(grids) do
            if not self:CheckGridEmpty(grid.x, grid.y) then
                canDrop = false
                break
            end
        end
        if not canDrop then
            break
        end
        dropGridY = i
    end
    if dropGridY then
        local gridY = blockData:GetDropFinalGridY(dropGridY)
        local gridX = blockData:GetHeadGrid().x
        self:SignGridOccupy(blockData, gridX, gridY) -- 这里得提前刷新阻挡点，否则下一个掉落的方块的落脚点会有问题
        self:AddOperate(OperateMode.MoveY, { blockData, gridY })
        return true
    end
    return false
end

---检查某行之上所有方块掉落（从下到上）
function XFangKuaiGame:CheckAllLayerBlockDrop(gridY)
    gridY = gridY or 1
    local isDrop = false
    for y = 1, self._MaxY + self._CurAddLineCount do
        if y >= gridY then
            local blockDatas = self:GetLayerBlocks(y)
            for blockData, _ in pairs(blockDatas) do
                if self:CheckBlockDrop(blockData) then
                    isDrop = true
                end
            end
        end
    end
    if isDrop then
        XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_DROP)
    end
end

---检查同行消除
function XFangKuaiGame:CheckAllClearUp()
    for y = 1, self._MaxY do
        local canClearUp = true
        for x = 1, self._MaxX do
            if self:CheckGridEmpty(x, y) then
                canClearUp = false
            end
        end
        if canClearUp then
            self:AddOperate(OperateMode.Clear, { y })
        end
    end
end

function XFangKuaiGame:IsExitOperate(operate)
    return not XTool.IsTableEmpty(self._OperateMap[operate])
end

---@param blockData XFangKuaiBlock
function XFangKuaiGame:DoMoveY(blockData, gridY)
    local time = self._MainControl:GetMoveYTime()
    blockData:UpdatePos(nil, gridY)
    self:SignGridOccupyAuto(blockData)
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_MOVEY, blockData, gridY)
    return time
end

---@param blockData XFangKuaiBlock
function XFangKuaiGame:DoMoveX(blockData, gridX)
    local time = self._MainControl:GetMoveXTime(blockData, gridX)
    blockData:UpdatePos(gridX, nil)
    self:SignGridOccupyAuto(blockData)
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_MOVEX, blockData, gridX)
    return time
end

function XFangKuaiGame:DoClear(gridY, index, len)
    if len > 1 and index == 1 then
        self._MainControl:AddCombo(len - 1)
    end

    local blockDatas = self._LayerBlocks[gridY]
    if not blockDatas then
        return 0
    end
    ---@type XFangKuaiBlock[]
    local sortData = {}
    for blockData, _ in pairs(blockDatas) do
        table.insert(sortData, blockData)
    end
    -- 如果一行有多个道具 而道具容量即将满了 则只有排序最靠前的会拿到
    table.sort(sortData, function(a, b)
        local aGridX, bGridX = a:GetHeadGrid().x, b:GetHeadGrid().x
        if aGridX ~= bGridX then
            return aGridX < bGridX
        end
        return a:GetId() < b:GetId()
    end)
    local tempDebugScore = self._MainControl:GetScore()
    for _, blockData in ipairs(sortData) do
        if blockData:GetHeadGrid().y == gridY then
            if blockData:IsBoss() then
                self._MainControl:AddScore(blockData, 1)
                local bossType = blockData:GetBlockType()
                if bossType == XEnumConst.FangKuai.BlockType.BossWane then
                    self:WaneBlock(blockData, 1, true)
                elseif bossType == XEnumConst.FangKuai.BlockType.BossHit then
                    self:HitBlock(blockData)
                elseif bossType == XEnumConst.FangKuai.BlockType.BossFission then
                    self:FissionBlock(blockData)
                end
            else
                self._MainControl:AddScore(blockData)
                self:DoRemove(blockData)
            end
        end
    end
    self:ShowDebugScore(sortData, gridY, tempDebugScore)
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_UPDATESCORE)
    if index == len then
        -- 一次消除2行 分数=2行方块总分×combo2，而不是 第1行方块总分×combo1+第2行方块总分×combo2
        self._MainControl:AddCombo()
    end
    return 0.8
end

---@param newBlockData XFangKuaiBlock
function XFangKuaiGame:DoCreate(newBlockData)
    self:SignGridOccupyAuto(newBlockData)
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_ADD, newBlockData)
    return 0
end

---@param blockData XFangKuaiBlock
function XFangKuaiGame:DoWane(blockData, count)
    self._MainControl:AddScore(blockData, count)
    self:WaneBlock(blockData, count, false)
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_UPDATESCORE)
    return 0.8
end

---@param blockData XFangKuaiBlock
function XFangKuaiGame:DoRemove(blockData, isImmediately)
    self:SignGridOccupyAuto(blockData, true)
    local itemId = blockData:GetItemId()
    -- 添加道具 使用以大化小造成的消除不需要飘道具（道具转移到第一个小方块上了）
    if XTool.IsNumberValid(itemId) and not isImmediately then
        local itemIdx
        local isFull = true
        if not self._MainControl:IsItemFull() then
            isFull = false
            itemIdx = self._MainControl:AddItemId(itemId)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_ADDITEM, itemIdx, blockData, isFull)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_REMOVE, blockData, isImmediately)
    return 0
end

---@param blockData XFangKuaiBlock
function XFangKuaiGame:DoGrow(blockData, growCount)
    self:GrowBlock(blockData, growCount)
    return 0.8
end

function XFangKuaiGame:UpdateBlockData()
    self._InitBlocks = {}
    local newBlocks = self._MainControl:GetCurCreateBlocks(self._ChapterId)
    if not newBlocks then
        return
    end
    ---@type table<number,XFangKuaiBlock[]>
    local previewBlocks = {}
    for _, blockData in pairs(newBlocks) do
        local blockY = blockData:GetHeadGrid().y
        if blockY < 0 then
            -- 地下第一行是-1 把key值变成1,2,3,4
            local key = math.abs(blockY)
            if not previewBlocks[key] then
                previewBlocks[key] = {}
            end
            table.insert(previewBlocks[key], blockData)
        else
            if self:IsBlockEmpty() then
                -- 新关卡/重新登录
                table.insert(self._InitBlocks, blockData)
            end
        end
    end
    -- 把新的预览方块添加到最后面
    table.sort(previewBlocks, function(a, b)
        return a[1]:GetHeadGrid().y > b[1]:GetHeadGrid().y
    end)
    for _, blocks in pairs(previewBlocks) do
        table.insert(self._NewBlockPool, blocks)
    end
    self._MainControl:ClearCurCreateBlocks(self._ChapterId)
end

function XFangKuaiGame:GetNewBlockNotice()
    local noticeBlocks = {}
    local num = self._MainControl:GetNewLineCount()
    for i = 1, num do
        noticeBlocks[i] = self:GetNewBlockDatas(i, false)
    end
    return noticeBlocks
end

---获取方块水平方向可活动的区域
---@param blockData XFangKuaiBlock
function XFangKuaiGame:GetBlockMoveArea(blockData)
    local headGrid = blockData:GetHeadGrid()
    local minX, maxX = headGrid.x, headGrid.x
    for x = blockData:GetHeadGrid().x - 1, 1, -1 do
        if not self:CheckGridEmpty(x, headGrid.y) then
            break
        end
        minX = x
    end
    for x = blockData:GetTailGrid().x + 1, self._MaxX, 1 do
        if not self:CheckGridEmpty(x, headGrid.y) then
            break
        end
        maxX = x - blockData:GetLen() + 1
    end
    return minX, maxX
end

function XFangKuaiGame:GetBlockMap()
    return self._BlockToGridMap
end

function XFangKuaiGame:GetServerBlockMap()
    local datas = {}
    for blockData, _ in pairs(self._BlockToGridMap) do
        if blockData:GetHeadGrid().y <= self._StageConfig.SizeY then
            table.insert(datas, blockData:GetServerData())
        end
    end
    return datas
end

function XFangKuaiGame:GetServerPreviewBlockMap()
    local datas = {}
    for i, blockDatas in ipairs(self._NewBlockPool) do
        for _, blockData in pairs(blockDatas) do
            table.insert(datas, blockData:GetServerData(-i))
        end
    end
    local previewBlock = self._StageData:GetTopPreviewBlock()
    if previewBlock then
        table.insert(datas, previewBlock:GetServerData())
    end
    return datas
end

function XFangKuaiGame:IsBlockEmpty()
    return XTool.IsTableEmpty(self._BlockToGridMap)
end

function XFangKuaiGame:GetExistBlockLayerNum()
    local num = 0
    for _, v in pairs(self._LayerBlocks) do
        if not XTool.IsTableEmpty(v) then
            num = num + 1
        end
    end
    return num
end

function XFangKuaiGame:IsNeedCreateExtraBlock()
    return self:GetExistBlockLayerNum() <= 1
end

function XFangKuaiGame:GetCreateExtraLayerCount()
    return self:GetExistBlockLayerNum() == 0 and 2 or 1
end

function XFangKuaiGame:GetLayerBlocks(gridY)
    return self._LayerBlocks[gridY] or {}
end

---@return XFangKuaiBlock[]
function XFangKuaiGame:GetNewBlockDatas(order, isRemove)
    local blockDatas = {}
    for key, datas in ipairs(self._NewBlockPool) do
        if key == order then
            blockDatas = datas
            if isRemove then
                table.remove(self._NewBlockPool, key)
            end
            break
        end
    end
    return blockDatas
end

function XFangKuaiGame:GetNewBlockLastY()
    return #self._NewBlockPool
end

function XFangKuaiGame:GetLeaveRound()
    if not self._StageConfig then
        return nil
    end
    return self._StageConfig.MaxRound + self._MainControl:GetExtraRound() - self._MainControl:GetCurRound()
end

-- 道具造成方块消失但是没有整行消除 combo也是加1
function XFangKuaiGame:IsBlockRemoveInCurOperate()
    if self:IsExitOperate(OperateMode.Clear) then
        return false
    end
    local wane = self._OperateMap[OperateMode.Wane]
    return not XTool.IsTableEmpty(wane)
end

function XFangKuaiGame:GetCurFightChapterId()
    return self._ChapterId
end

function XFangKuaiGame:GetCurFightStageId()
    return self._StageId
end

function XFangKuaiGame:IsGameOver()
    return self._IsGameOver
end

-- 在退出玩法和切换到其他章节时保存进度
function XFangKuaiGame:SaveStageBlockData()
    -- self._ChapterId没有赋值 说明还没进入战斗过并且Game是空的 这时不能把StageData覆盖掉（登录时服务端会下方记录数据）
    if not self._IsGameOver and XTool.IsNumberValid(self._ChapterId) then
        self._StageData:SaveStageBlockData(self._BlockToGridMap, self._NewBlockPool)
    end
end

--region Debug

---@param sortData XFangKuaiBlock[]
function XFangKuaiGame:ShowDebugScore(sortData, gridY, tempDebugScore)
    if not self._MainControl:IsDebug() then
        return
    end
    local realScore = self._MainControl:GetScore() - tempDebugScore
    if realScore == 0 then
        return
    end
    local score = 0
    for _, blockData in ipairs(sortData) do
        if blockData:GetHeadGrid().y == gridY then
            if blockData:IsBoss() then
                local len = blockData:GetLen()
                if len == 1 then
                    score = score + blockData:GetScore()
                end
            else
                score = score + blockData:GetScore()
            end
        end
    end
    local combo = self._MainControl:GetComboNum()
    XLog.Debug(string.format("<color=#45D4E0>第%s行 原始分：%s combo：%s 加成得分：%s 总分：%s</color>", gridY - 1, score, combo, realScore, self._MainControl:GetScore()))
end

function XFangKuaiGame:GetDebugOperateLog(operate, args, operateTime)
    if not self._MainControl:IsDebug() then
        return
    end
    if XTool.IsTableEmpty(args) then
        return
    end
    local log = self:GetDebugOperateName(operate)
    for _, arg in ipairs(args) do
        if operate == OperateMode.MoveY then
            local id = arg[1]:GetId()
            log = log .. string.format("Id:%s Y:%s\n", id, arg[2])
        elseif operate == OperateMode.MoveX then
            local id = arg[1]:GetId()
            log = log .. string.format("Id:%s X:%s\n", id, arg[2])
        elseif operate == OperateMode.Clear then
            log = log .. string.format("line:%s\n", arg[1])
        elseif operate == OperateMode.Create then
            local id = arg[1]:GetId()
            local grid = arg[1]:GetHeadGrid()
            local len = arg[1]:GetLen()
            local itemId = arg[1]:GetItemId() or 0
            local isBoss = arg[1]:IsBoss() and "True" or "False"
            log = log .. string.format("Id:%s X:%s Y:%s Len:%s ItemId:%s IsBoss:%s\n", id, grid.x, grid.y, len, itemId, isBoss)
        elseif operate == OperateMode.Wane then
            local id = arg[1]:GetId()
            log = log .. string.format("Id:%s Count:%s\n", id, arg[2])
        elseif operate == OperateMode.Remove then
            local id = arg[1]:GetId()
            local isImmediately = arg[2] and "True" or "False"
            log = log .. string.format("Id:%s IsImmediately:%s\n", id, isImmediately)
        end
    end
    XLog.Debug(string.format("%s%s秒后执行", log, operateTime))
end

function XFangKuaiGame:PrintDebugBlockPosition()
    if not self._MainControl:IsDebug() then
        return
    end
    local log = ""
    local emptyGrid = "--- "
    for y = 11, 1, -1 do
        log = log .. string.format("%s:", y)
        for x = 1, 9 do
            if self:CheckGridEmpty(x, y) then
                log = log .. emptyGrid
            else
                local id = self._GridStateMap[y][x]
                log = log .. string.format("%s ", id)
            end
        end
        log = log .. "\n"
    end
    for y = 1, 2 do
        log = log .. string.format("%s:", 1 - y)
        local blocks = self._NewBlockPool[y]
        for x = 1, 9 do
            local id
            if blocks then
                for _, block in pairs(blocks) do
                    if x >= block:GetHeadGrid().x and x <= block:GetTailGrid().x then
                        id = block:GetId()
                        break
                    end
                end
            end
            if id then
                log = log .. string.format("%s ", id)
            else
                log = log .. emptyGrid
            end
        end
        log = log .. "\n"
    end
    XLog.Debug(string.format("<color=#FFFF00>Round:%s</color>\n%s", self._MainControl:GetCurRound(), log))
end

function XFangKuaiGame:GetDebugOperateName(operate)
    if operate == OperateMode.MoveY then
        return "<color=#FF0000>当前操作：上下移动</color>\n"
    elseif operate == OperateMode.MoveX then
        return "<color=#FF0000>当前操作：左右移动</color>\n"
    elseif operate == OperateMode.Clear then
        return "<color=#FF0000>当前操作：消除行</color>\n"
    elseif operate == OperateMode.Create then
        return "<color=#FF0000>当前操作：创建新方块</color>\n"
    elseif operate == OperateMode.Wane then
        return "<color=#FF0000>当前操作：方块缩短</color>\n"
    elseif operate == OperateMode.Remove then
        return "<color=#FF0000>当前操作：方块移除</color>\n"
    end
end

--endregion

--region 引导

function XFangKuaiGame:FindGuideBlock()
    if not self:CheckGridEmpty(4, 4) then
        XLog.Error("引导播放失败：(4,4)位置上已有其他方块")
        return
    end
    local dimBlockData
    for blockData, _ in pairs(self._BlockToGridMap) do
        local grid = blockData:GetHeadGrid()
        if grid.x == 3 and grid.y == 4 then
            dimBlockData = blockData
            break
        end
    end
    if not dimBlockData then
        XLog.Error("引导播放失败：(3,4)位置上没有方块")
        return
    end
    return dimBlockData
end

--endregion

--region 顶部方块掉落

function XFangKuaiGame:CheckTopBlockDrop()
    if not self._Model:HasBlockDropEnviroment(self._StageId) then
        return false
    end
    if self._StageData:IsBlockDrop() then
        local blockData = self._StageData:GetTopPreviewBlock()
        if not blockData then
            return false
        end
        -- 检查最顶行所在位置是否被占用了
        for x = blockData:GetHeadGrid().x, blockData:GetTailGrid().x do
            if not self:CheckGridEmpty(x, blockData:GetHeadGrid().y) then
                -- 被占用了 说明游戏即将结束 方块不需要下落了
                self._IsGameOverByDrop = true
                return false
            end
        end
        self._MainControl:ResetCombo()
        self:SignGridOccupyAuto(blockData)
        self._StageData:SetTopPreviewBlock(nil)
        XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_TOPDROP, blockData)
        return true
    else
        self:CheckCreateDropBlockData()
    end
    return false
end

-- 新回合开始→创建方块→检查顶部方块创建→cd减1
function XFangKuaiGame:CheckCreateDropBlockData()
    if self._Model:HasBlockDropEnviroment(self._StageId) then
        if self._StageData:IsCreatePreviewTopBlock() then
            self._MainControl:CreateDropBlockData(self._StageId)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_TOPPREVIEW)
    end
end

-- 当ActionRange配1且cd配0时 在第一回合就掉落方块 需要一开始就创建预览
function XFangKuaiGame:CheckInitCreateDropBlockData()
    if self._StageData:IsBlockDrop() then
        self:CheckCreateDropBlockData()
    end
end

--endregion

return XFangKuaiGame