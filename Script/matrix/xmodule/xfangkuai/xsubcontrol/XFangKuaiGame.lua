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
---@field _IsWaiting boolean 等待服务端返回协议中
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

end

function XFangKuaiGame:SetStage(stageId)
    self._StageId = stageId
    self._ChapterId = self._MainControl:GetChapterIdByStage(stageId)
    self._StageConfig = self._MainControl:GetStageConfig(stageId)
    self._MaxX = self._StageConfig.SizeX
    self._MaxY = self._StageConfig.SizeY
    self._MainControl:InitEnviroment(self._StageConfig.EnvironmentId)
    self._Round = self._MainControl:GetCurRound(self._ChapterId)
    self._IsGameOver = false
    self._IsWaiting = false
    self:UpdateBlockData()
end

function XFangKuaiGame:InitData()
    self._StageConfig = nil
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
    self:AsynInitBlockOperate()
end

function XFangKuaiGame:StartRound(curBlockGridY)
    self._HasCreated = false
    self._MainControl:ResetCombo()
    self:AsynStartOperate(curBlockGridY)
end

function XFangKuaiGame:StartUseColorItem(index, kind, color)
    if kind == XEnumConst.FangKuai.ItemType.LengthReduce then
        self._MainControl:ExecuteLengthReduce(index, color, self._ChapterId)
    elseif kind == XEnumConst.FangKuai.ItemType.BecomeOneGrid then
        self._MainControl:ExecuteBecomeOneGrid(index, color, self._ChapterId)
    end
    self:StartUseItem()
end

function XFangKuaiGame:StartUseRemoveItem(index, blockData)
    self._MainControl:ExecuteSingleLineRemove(index, blockData, self._ChapterId)
    self:StartUseItem()
end

function XFangKuaiGame:StartUseExchangeItem(index, kind, blockData1, blockData2)
    if kind == XEnumConst.FangKuai.ItemType.TwoLineExChange then
        self._MainControl:ExecuteTwoLineExChange(index, blockData1, blockData2, self._ChapterId)
    elseif kind == XEnumConst.FangKuai.ItemType.AdjacentExchange then
        self._MainControl:ExecuteAdjacentExchange(index, blockData1, blockData2, self._ChapterId)
    end
    self:StartUseItem()
end

function XFangKuaiGame:StartAddRoundItem(index)
    self._MainControl:ExecuteAddRound(index, self._ChapterId)
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

function XFangKuaiGame:AsynRunOperate(operateMode)
    local time = self:RunOperate(operateMode)
    asynWaitSecond(time)
end

function XFangKuaiGame:AsynRunAllOperate()
    local time = self:RunAllOperate()
    asynWaitSecond(time)
end

-- 移动方块 -> 检查掉落 -> 检查消除 -> 再次检查掉落 -> 没有方块可掉落 -> 生成新方块 -> 再次检查掉落 -> 没有方块可掉落 -> 检查额外掉落 -> 结束
function XFangKuaiGame:AsynStartOperate(curBlockGridY)
    RunAsyn(function()
        self:XPCall(function()
            -- 方块掉落
            self:CheckAllLayerBlockDrop(curBlockGridY)
            self:AsynRunOperate(OperateMode.MoveY)
            -- 整行消除
            self:CheckAllClearUp()
            local hasClearUpOperate = self:IsExitOperate(OperateMode.Clear)
            -- 如果存在消除整行的操作，则必定有方块会掉落，递归执行
            if hasClearUpOperate then
                self:AsynRunOperate(OperateMode.Clear)
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
                    self:OnRoundEnd()
                    return
                end
            end
            -- 生成新方块
            if not self:AddNewBlocks(extraAddLine) then
                return
            end
            self._HasCreated = true
            self:AsynRunOperate(OperateMode.Create)
            -- 全部方块上移
            self:AllMoveUp()
            self:AsynRunOperate(OperateMode.MoveY)
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
                    self:AsynRunOperate(OperateMode.Create)
                    -- 全部方块上移
                    self:AllMoveUp()
                    self:AsynRunOperate(OperateMode.MoveY)
                else
                    self:AddInitBlock()
                    self:AsynRunOperate(OperateMode.Create)
                    self._HasCreated = true
                end
            end
            -- 方块掉落
            self:CheckAllLayerBlockDrop()
            self:AsynRunOperate(OperateMode.MoveY)
            -- 方块消除
            self:CheckAllClearUp()
            local hasClearUpOperate = self:IsExitOperate(OperateMode.Clear)
            self:AsynRunOperate(OperateMode.Clear)
            if hasClearUpOperate or self:IsNeedCreateExtraBlock() then
                self:AsynInitBlockOperate()
                return
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
            self:AsynRunOperate(OperateMode.MoveY)
            -- 整行消除
            self:CheckAllClearUp()
            local hasClearUpOperate = self:IsExitOperate(OperateMode.Clear)
            self:AsynRunOperate(OperateMode.Clear)
            if hasClearUpOperate then
                self:AsynUseItemOperate()
                return
            end
            -- 检查剩余层数
            if self:IsNeedCreateExtraBlock() then
                if not self:AddNewBlocks(self:GetCreateExtraLayerCount()) then
                    return
                end
                self:AsynRunOperate(OperateMode.Create)
                -- 全部方块上移
                self:AllMoveUp()
                self:AsynRunOperate(OperateMode.MoveY)
                self:AsynUseItemOperate()
                return
            end
            -- 重置combo
            self._MainControl:ResetCombo()
            XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_USEITEMEND)
        end)
    end)
end

function XFangKuaiGame:OnGameOver()
    self._IsGameOver = true
    if self._MainControl:IsStageFinished() then
        XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_GAMEOVER)
    end
end

function XFangKuaiGame:OnRoundEnd()
    self._Round = self._Round + 1

    if self:IsNextRoundGameOver() then
        self:OnGameOver()
    else
        if self._Round == self._MainControl:GetCurRound(self._ChapterId) then
            -- 等待服务端返回最新数据后再刷新
            self:UpdateBlockData()
            self:CheckService()
        end
        self._MainControl:ResetCombo()
    end

    self:PrintDebugBlockPosition()

    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_SRARTROUND)
end

function XFangKuaiGame:CheckService()
    local isError = false
    local serviceRound = self._MainControl:GetCurRound(self._ChapterId)
    -- 如果弱网环境，在新方块池里方块用完之前无需校验；用完之后重置为服务端最后一次发过来的数据
    if serviceRound == self._Round then
        isError = self:CheckData()
    elseif serviceRound < self._Round then
        -- 等待服务端返回协议 转菊花
        if XTool.IsTableEmpty(self._NewBlockPool) then
            self._IsWaiting = true
            --XLuaUiManager.SetAnimationMask("FangKuaiWaiting", true, 0)
            XLog.Warning("等待服务端返回关卡数据")
            return
        end
    else
        isError = true
        XLog.Error(string.format("回合数不一致.客户端回合数=%s 服务端回合数=%s", self._Round, serviceRound))
    end
    -- 重置数据
    if isError then
        self:ResetFromService()
    end
end

-- 前后端数据不匹配 重置客户端数据
function XFangKuaiGame:ResetFromService()
    self._MainControl:ResetScore(self._ChapterId)
    self._MainControl:ResetEnviromentParam()
    self._Round = self._MainControl:GetCurRound(self._ChapterId)
    self:UpdateBlockData(true)
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
                operateTime = self:DoMoveX(arg[1], arg[2])
            elseif operate == OperateMode.Clear then
                operateTime = self:DoClear(arg[1], i, #args)
            elseif operate == OperateMode.Create then
                operateTime = self:DoCreate(arg[1])
            elseif operate == OperateMode.Wane then
                operateTime = self:DoWane(arg[1], arg[2])
            elseif operate == OperateMode.Remove then
                operateTime = self:DoRemove(arg[1], arg[2])
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

function XFangKuaiGame:AddNewBlocks(addLine)
    self._CurAddLineCount = addLine or self._MainControl:GetNewLineCount()
    for i = 1, self._CurAddLineCount do
        local blockDatas = self:GetNewBlockDatas(1, true)
        if XTool.IsTableEmpty(blockDatas) then
            XLog.Error("新方块池为空")
            return false
        end
        for _, data in pairs(blockDatas) do
            local grid = data:GetHeadGrid()
            data:UpdatePos(grid.x, 1 - i)
            self:AddOperate(OperateMode.Create, { data })
        end
    end
    if addLine then
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

---方块会先变短，最后再消失
---@param blockData XFangKuaiBlock
---@param isClear boolean 长度缩短是否因为整行消除（要等整行消除特效播完再播缩短特效）
function XFangKuaiGame:WaneBlock(blockData, count, isClear)
    local len = blockData:GetLen()
    if len == 1 then
        self:DoRemove(blockData)
    else
        blockData:UpdateLen(len - count)
        self:SignGridOccupyAuto(blockData)
        XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_WANE, blockData, isClear)
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
    local top = self:GetLayerBlocks(self._MaxY + 1)
    return not XTool.IsTableEmpty(top)
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
                self:WaneBlock(blockData, 1, true)
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
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_REMOVE, blockData, isImmediately)
    return 0
end

function XFangKuaiGame:UpdateBlockData(isUpdateBlocks)
    self._NewBlockPool = {}
    self._InitBlocks = {}
    if isUpdateBlocks then
        self._GridStateMap = {}
        self._BlockToGridMap = {}
        self._LayerBlocks = {}
    end

    local allBlocks = self._MainControl:GetAllBlocks(self._ChapterId)
    if not allBlocks then
        return
    end
    for _, serviceData in pairs(allBlocks) do
        if serviceData.Y < 0 then
            -- 服务端地下第一行是-1 把key值变成1,2,3,4
            local key = math.abs(serviceData.Y)
            local blockData = self._MainControl:CreateBlockDataByService(self._StageId, serviceData)
            if not self._NewBlockPool[key] then
                self._NewBlockPool[key] = {}
            end
            table.insert(self._NewBlockPool[key], blockData)
        else
            if self:IsBlockEmpty() then
                -- 新关卡/重新登录
                local blockData = self._MainControl:CreateBlockDataByService(self._StageId, serviceData)
                table.insert(self._InitBlocks, blockData)
            end
            if isUpdateBlocks then
                -- 重置场上所有正在显示的方块
                local blockData = self._MainControl:CreateBlockDataByService(self._StageId, serviceData)
                self:SignGridOccupyAuto(blockData)
            end
        end
    end

    if self._IsWaiting then
        self._IsWaiting = false
        --XLuaUiManager.ClearAnimationMask()
        self:CheckService()
    end
end

---校验数据 因为部分逻辑是客户端和服务端分开运算的
function XFangKuaiGame:CheckData()
    local isDataError = false
    local clientScore = self._MainControl:GetScore()
    local serviceScore = self._MainControl:GetCurRoundScore(self._ChapterId)
    if clientScore ~= serviceScore then
        isDataError = true
        XLog.Error(string.format("分数不一致.客户端=%s,服务端=%s", clientScore, serviceScore))
    end

    local errorMsgs = {}
    local allBlocks = self._MainControl:GetAllBlocks(self._ChapterId)
    if not allBlocks then
        return
    end
    local serviceDatas = XTool.Clone(allBlocks)

    ---@param block XFangKuaiBlock
    local check = function(block)
        local id = block:GetId()
        local serviceData = serviceDatas[id]
        if serviceData then
            local errorMsg = block:CheckData(serviceData)
            if errorMsg then
                table.insert(errorMsgs, errorMsg)
            end
            serviceDatas[id] = nil
        else
            local grid = block:GetHeadGrid()
            XLog.Error(string.format("后端没有该数据：Id=%s,X=%s,Y=%s", id, grid.x, grid.y))
        end
    end

    for block, _ in pairs(self._BlockToGridMap) do
        check(block)
    end
    for _, blocks in pairs(self._NewBlockPool) do
        for _, block in pairs(blocks) do
            check(block)
        end
    end

    if not XTool.IsTableEmpty(serviceDatas) then
        isDataError = true
        XLog.Error("前端没有该数据", serviceDatas)
    end
    if #errorMsgs > 0 then
        isDataError = true
        XLog.Error("前后端数据不一致", errorMsgs)
    end
    return isDataError
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

function XFangKuaiGame:GetNewBlockDatas(order, isRemove)
    local blockDatas = {}
    local index = 1
    for key, datas in ipairs(self._NewBlockPool) do
        if not XTool.IsTableEmpty(datas) then
            if index == order then
                blockDatas = datas
                if isRemove then
                    self._NewBlockPool[key] = {}
                end
                break
            end
            index = index + 1
        end
    end
    return blockDatas
end

function XFangKuaiGame:GetLeaveRound()
    if not self._StageConfig then
        return nil
    end
    return self._StageConfig.MaxRound + self._MainControl:GetExtraRound(self._ChapterId) - self._Round
end

function XFangKuaiGame:GetRound()
    return self._Round
end

function XFangKuaiGame:IsGameOver()
    return self._IsGameOver
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
    --if not self._MainControl:IsDebug() then
    --    return
    --end
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
            local itemId = arg[1]:GetItemId()
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
    --if not self._MainControl:IsDebug() then
    --    return
    --end
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
    XLog.Debug(string.format("<color=#FFFF00>Round:%s</color>\n%s", self._Round, log))
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
    if not self:CheckGridEmpty(3, 3) then
        XLog.Error("引导播放失败：(3,3)位置上已有其他方块")
        return
    end
    local dimBlockData
    for blockData, _ in pairs(self._BlockToGridMap) do
        local grid = blockData:GetHeadGrid()
        if grid.x == 4 and grid.y == 3 then
            dimBlockData = blockData
            break
        end
    end
    if not dimBlockData then
        XLog.Error("引导播放失败：(4,3)位置上没有方块")
        return
    end
    return dimBlockData
end

--endregion

return XFangKuaiGame