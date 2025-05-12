--- 2048 记录和回放棋盘状态的debug控制器
---@class XGame2048DebugRecordControl: XControl
---@field private _Model XGame2048Model
---@field private _MainControl XGame2048GameControl
local XGame2048DebugRecordControl = XClass(XControl, 'XGame2048DebugRecordControl')

function XGame2048DebugRecordControl:OnInit()
    self._RecordOpenCache = XSaveTool.GetData('Game2048RecordEnable')
    
    XMVCA.XGame2048:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_START_RECORD, self.StartRecord, self)
    XMVCA.XGame2048:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_END_RECORD, self.EndRecord, self)
    XMVCA.XGame2048:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_LOAD_RECORD_DATA, self.StartPlayBack, self)
end

function XGame2048DebugRecordControl:OnRelease()
    XMVCA.XGame2048:RemoveEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_START_RECORD, self.StartRecord, self)
    XMVCA.XGame2048:RemoveEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_END_RECORD, self.EndRecord, self)
    XMVCA.XGame2048:RemoveEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_LOAD_RECORD_DATA, self.StartPlayBack, self)
end

--- 判断是否启用了录制，启用录制时，每局默认录制
function XGame2048DebugRecordControl:CheckIsRecordEnable()
    return self._RecordOpenCache or false
end

--region 录制模式

--- 判断是否正在录制
function XGame2048DebugRecordControl:CheckIsRecording()
    return self._IsRecording or false
end

function XGame2048DebugRecordControl:StartRecord()
    -- 回放过程中不能录制
    if self:CheckIsPlayBack() then
        return
    end
    
    if self:CheckIsRecording() then
        self:EndRecord()
    end
    
    XLog.Error('<b>[2048Recorder]开始局内录制...</b>')
    
    -- 棋盘每回合的信息
    self._StepsQueue = {}
    -- 棋盘初始生成信息
    self._InitDatas = XTool.Clone(self._MainControl.TurnControl:GetStageContextFromClient())
    -- 步数计数器
    self._StepsCounter = 1

    self._IsRecording = true
end

--- 记录随机数种子
function XGame2048DebugRecordControl:RecordRandomSeed(seed)
    self._RandomSeed = seed
end

--- 记录该回合的移动方向
function XGame2048DebugRecordControl:RecordCurStepMoveDire(x, y)
    if self._StepsQueue[self._StepsCounter] == nil then
        self._StepsQueue[self._StepsCounter] = {}
    end

    local enumDire = 0
    
    if y > 0 then
        enumDire = XMVCA.XGame2048.EnumConst.DragDirectionByGuide.Up
    elseif y < 0 then
        enumDire = XMVCA.XGame2048.EnumConst.DragDirectionByGuide.Down
    elseif x < 0 then
        enumDire = XMVCA.XGame2048.EnumConst.DragDirectionByGuide.Left
    elseif x > 0 then
        enumDire = XMVCA.XGame2048.EnumConst.DragDirectionByGuide.Right
    end

    self._StepsQueue[self._StepsCounter].MoveDire = enumDire
    -- 额外的次序索引标记，用于检查是否在序列化/反序列化的过程中乱序
    self._StepsQueue[self._StepsCounter].Index = self._StepsCounter
end

--- 记录该回合开始，新生成的方块
function XGame2048DebugRecordControl:RecordCurStepNewGrid(GeneratedResults)
    if self._StepsQueue[self._StepsCounter] == nil then
        self._StepsQueue[self._StepsCounter] = {}
    end
    
    local stepData = self._StepsQueue[self._StepsCounter]

    if stepData.NewGrids == nil then
        stepData.NewGrids = {}
    end
    
    local newGridsInBegin = stepData.NewGrids

    if not XTool.IsTableEmpty(GeneratedResults) then
        for i, v in pairs(GeneratedResults) do
            if not XTool.IsTableEmpty(v.TargetBlock) then
                table.insert(newGridsInBegin, XTool.Clone(v.TargetBlock))
            end
        end
    end
end

--- 录制下一回合
function XGame2048DebugRecordControl:RecordNextSteps()
    self._StepsCounter = self._StepsCounter + 1
end

function XGame2048DebugRecordControl:EndRecord()
    if not self:CheckIsRecording() then
        return
    end

    XLog.Error('<b>[2048Recorder]局内录制结束...</b>')

    xpcall(function() 
        local data = {
            StepsQueue = self._StepsQueue,
            InitDatas = self._InitDatas,
            StepsCounter = self._StepsCounter,
            RandomSeed = self._RandomSeed,
        }
        self:ExportToFile(data, CS.XLaunchManager.ProductPath..'/ReplayFight/Game2048RecordData/', tostring(os.time())..'StageId['..tostring(self._MainControl._StageId)..']'..'.lua')
    end, function(msg)
        XLog.Error(msg)
    end)
    
    self._IsRecording = false
end

-- 将数据转换为 Lua 代码字符串（支持 table/string/number/boolean/nil）
function XGame2048DebugRecordControl:SerializeRecord(val, indent, visited)
    indent = indent or ""
    visited = visited or {}
    local ty = type(val)

    if ty == "table" then
        -- 循环引用检测（简化版）
        if visited[val] then return "{} --[[循环引用跳过]]" end
        visited[val] = true

        local parts = {"{\n"}
        local new_indent = indent .. "  "

        -- 处理数组部分（连续数字索引）
        for i, v in ipairs(val) do
            table.insert(parts, new_indent .. self:SerializeRecord(v, new_indent, visited) .. ",\n")
        end

        -- 处理键值对部分（非数组元素）
        for k, v in pairs(val) do
            if not (type(k) == "number" and k >= 1 and k <= #val) then
                local key_str
                if type(k) == "string" and string.match(k, "^[a-zA-Z_][a-zA-Z0-9_]*$") then
                    key_str = k -- 合法标识符直接写
                else
                    key_str = "[" .. self:SerializeRecord(k, new_indent, visited) .. "]" -- 复杂键用方括号
                end
                table.insert(parts, new_indent .. key_str .. " = " .. self:SerializeRecord(v, new_indent, visited) .. ",\n")
            end
        end

        table.insert(parts, indent .. "}")
        return table.concat(parts)
    elseif ty == "string" then
        return string.format("%q", val) -- 转义双引号
    elseif ty == "number" or ty == "boolean" or ty == "nil" then
        return tostring(val) -- 直接转换
    else
        error("不支持的类型: " .. ty)
    end
end

-- 将数据保存为可 require 的 Lua 文件
function XGame2048DebugRecordControl:ExportToFile(data, directory, filename)
    if CS.System.IO.Directory.Exists(directory) == false then
        CS.System.IO.Directory.CreateDirectory(directory)
    end
    
    local filepath = directory..filename
    
    local file = io.open(filepath, "w")
    if not file then error("无法创建文件: " .. filepath) end
    
    local content = "return " .. self:SerializeRecord(data)
    file:write(content)
    file:close()

    XLog.Error('[2048Recorder]录制保存成功：'..tostring(filepath))
end
--endregion

--region 回放模式
--- 判断是否在回放
function XGame2048DebugRecordControl:CheckIsPlayBack()
    return self._IsPlayBack or false
end

function XGame2048DebugRecordControl:StartPlayBack(path)
    -- 先结束录制
    self:EndRecord()
    
    local success, data = pcall(function() 
        path = string.gsub(path, '\\', '/')
        local content = CS.System.IO.File.ReadAllText(path)
        
        return load(content)
    end)
    if not success then
        print("加载失败:", data)
        return
    end

    if type(data) == 'function' then
        data = data()
    end
    
    if data then
        self._StepsQueue = data.StepsQueue
        self._InitDatas = data.InitDatas
        self._StepsCounter = data.StepsCounter
        self._RandomSeed = data.RandomSeed
        
        self._IsPlayBack = true
        
        self._CurIndex = 1
        
        XMVCA.XGame2048:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_ON_RECORD_LOADED, self._InitDatas)
        self._MainControl:InitRandom(self._RandomSeed)
        
        XLog.Error('<b>[2048Recorder]开始回放...</b>')
    else
        XLog.Error('[2048Recorder]加载2048玩法回放文件失败')
    end
end

function XGame2048DebugRecordControl:DoNextStep(cb)
    if not self._IsPlayBack then
        return
    end
    
    self._CurIndex = self._CurIndex + 1

    if self._CurIndex > self._StepsCounter then
        XLog.Error('<b>[2048Recorder]已完成所有记录回合的回放</b>')
        self._IsPlayBack = false
    else
        -- 清空记录
        self._MainControl.TurnControl:ClearLastTurnData()

        -- 将上一回合产生的消除回收
        if not XTool.IsTableEmpty(self._MainControl._WasteGridEntities) then
            for k, v in pairs(self._MainControl._WasteGridEntities) do
                self._MainControl._GridBlockEntityPool:ReturnItemToPool(k)
            end
            self._MainControl._WasteGridEntities = {}
        end

        -- 更新数据
        if not XTool.IsTableEmpty(self._MainControl._GridEntities) then
            for i, v in pairs(self._MainControl._GridEntities) do
                v:SyncToServerData()
            end
        end

        local resultData = {
            CurrentSteps = self._MainControl.TurnControl:GetCurStepsCount() + 1
        }
        
        self._MainControl.TurnControl:UpdateNewTurnStageData(resultData)
        
        self._MainControl.TurnControl:CountDownFeverLeftRound()
        self._MainControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_REFRESH_DATA)

        -- 广播新格子生成事件
        local stepData = self._StepsQueue[self._CurIndex]

        if stepData and stepData.NewGrids then
            if not XTool.IsTableEmpty(stepData.NewGrids) then
                for i, v in pairs(stepData.NewGrids) do
                    self._MainControl.TurnControl._StageDataFromServer:UpdateNewGrids(v)

                    ---@type XGame2048Grid
                    local gridEntity = self._MainControl:GetGridEntityByServerBlockData(v)
                    self._MainControl.ActionsControl:AddNewBornAction(gridEntity.Uid)
                    self._MainControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_REFRESH_NEW_GRID, gridEntity)
                end
            end
        end

        -- 执行机制逻辑
        self._MainControl:DoBuff()
        -- 尝试一次动画播放
        self._MainControl.ActionsControl:StartActionList(cb)

        self._MainControl._IsWaitForNextStep = false

        if self._MainControl:CheckDebugEnable() then
            self._MainControl:PrintGridsInBoardLogForDebug()
        end

        if self._CurIndex >= self._StepsCounter then
            XLog.Error('<b>[2048Recorder]已完成所有记录回合的回放</b>')
            self._IsPlayBack = false
        end
    end
end

function XGame2048DebugRecordControl:GetCurStepMove()
    local stepData = self._StepsQueue[self._CurIndex]

    if stepData then
        local enumMoveDire = stepData.MoveDire

        if XTool.IsNumberValid(enumMoveDire) and enumMoveDire <= 4 then
            if enumMoveDire == XMVCA.XGame2048.EnumConst.DragDirectionByGuide.Up then
                return 0, 1
            elseif enumMoveDire == XMVCA.XGame2048.EnumConst.DragDirectionByGuide.Down then
                return 0, -1
            elseif enumMoveDire == XMVCA.XGame2048.EnumConst.DragDirectionByGuide.Left then
               return -1, 0
            elseif enumMoveDire == XMVCA.XGame2048.EnumConst.DragDirectionByGuide.Right then
                return 1, 0
            end
        else
            XLog.Error('回合移动信息错误：', stepData)    
        end
    else
        XLog.Error('回合信息错误:', stepData)
    end
    
    return 0, 0
end

--endregion

return XGame2048DebugRecordControl