local XTempleGameControl = require("XModule/XTemple/XTempleGameControl")
local XTempleAction = require("XEntity/XTemple/Action/XTempleAction")
local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")
local XTempleOption = require("XEntity/XTemple/Action/XTempleOption")
local ACTION = XTempleEnumConst.ACTION
local GRID = XTempleEnumConst.GRID
local RULE = XTempleEnumConst.RULE
local EDIT_TYPE = XTempleEnumConst.EDIT_TYPE
local TIME_OF_DAY = XTempleEnumConst.TIME_OF_DAY
local GRID_TYPE_EDITOR = XTempleEnumConst.GRID_TYPE_EDITOR
local RULE_BLOCK_EDITOR = XTempleEnumConst.RULE_BLOCK_EDITOR

local STATE = {
    SELECT_STAGE = 1,
    EDIT_TIME = 2,
    EDIT_MAP = 3,
    EDIT_BLOCK = 4,
    EDIT_RULE = 5,
    EDIT_ROUND = 6,
    EDIT_RULE_TIPS = 7,
}

---@class XTempleGameEditorControl:XTempleGameControl
---@field private _Model XTempleModel
local XTempleGameEditorControl = XClass(XTempleGameControl, "XTempleGameEditorControl")

function XTempleGameEditorControl:Ctor()
    self._EditingStageId = 0

    self._EditingRuleId = 0
    --
    -----@type XTempleAction[]
    --self._ActionRecord = nil
    --
    --self._IsLockUpdate = false
    --
    --self._IsEditingMap = true
    --
    --self._CurrentRound = 0

    self._State = STATE.SELECT_STAGE
    self._Data = {
        IsSelectStage = true,
        IsEditMap = false,
        IsEditBlock = false,
        IsEditTime = false,
        IsEditRule = false,
        IsEditRound = false,
        IsEditRuleTips = false,
    }

    self._DataOfAllBlock = {}

    self._EditingBlockId = 0

    self._EditingRound = 1

    self._EditingRoundOptionIndex = 0

    self._SearchBlockName = ""

    self._TipsEditingRule = false
end

function XTempleGameEditorControl:OnInit()
    XTempleGameControl.OnInit(self)
    --XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_ON_ACTION, self.UpdateActionRecordFromGame, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_ON_CLICK_GRID, self.OnClickGrid, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_ON_ACTION_CONFIRM, self.OnActionConfirm, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_ON_CLICK_RULE, self.OnClickRule, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_EDIT_RULE, self.EditRule, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_SAVE_EDIT_BLOCK, self.SaveGameConfig, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_EDIT_TIME, self.EditTime, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_EDIT_ROUND, self.EditRound, self)
end

function XTempleGameEditorControl:OnRelease()
    XTempleGameControl.OnRelease(self)
    --XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_ON_ACTION, self.UpdateActionRecordFromGame, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_ON_CLICK_GRID, self.OnClickGrid, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_ON_ACTION_CONFIRM, self.OnActionConfirm, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_ON_CLICK_RULE, self.OnClickRule, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_EDIT_RULE, self.EditRule, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_SAVE_EDIT_BLOCK, self.SaveGameConfig, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_EDIT_TIME, self.EditTime, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_EDIT_ROUND, self.EditRound, self)
end

function XTempleGameEditorControl:OnSelectState(state)
    if self._State == STATE.EDIT_ROUND then
        -- 清空游戏记录
        self:SetSelectedStage(self._EditingStageId)
    end

    self._State = state
    self._Data.IsSelectStage = self._State == STATE.SELECT_STAGE
    self._Data.IsEditTime = self._State == STATE.EDIT_TIME
    self._Data.IsEditMap = self._State == STATE.EDIT_MAP
    self._Data.IsEditBlock = self._State == STATE.EDIT_BLOCK
    self._Data.IsEditRule = self._State == STATE.EDIT_RULE
    self._Data.IsEditRound = self._State == STATE.EDIT_ROUND
    self._Data.IsEditRuleTips = self._State == STATE.EDIT_RULE_TIPS

    if self._Data.IsEditRound then
        self:LoadActionRecord()
        self._Game:SimulateActionRecord()
    end
end

function XTempleGameEditorControl:GetUiStateData()
    return self._Data
end

function XTempleGameEditorControl:GetStateButtonGroupIndex()
    return self._State
end

local function SortStage(a, b)
    return a.StageId < b.StageId
end

function XTempleGameEditorControl:GetStageList()
    local stageConfigList = self._Model:GetStageConfigList()
    if self._EditingStageId == 0 then
        self._EditingStageId = 1001
    end

    local data = {}
    for _, config in pairs(stageConfigList) do
        local stageId = config.Id
        ---@class XTempleEditorUiDataGrid
        local stage = {
            Name = config.StageName,
            StageId = stageId,
            IsSelected = stageId == self._EditingStageId,
        }
        data[#data + 1] = stage
    end
    table.sort(data, SortStage)
    return data
end

function XTempleGameEditorControl:SetSelectedStage(stageId)
    self._EditingStageId = stageId
    self._StageId = stageId
    self:StartGame(stageId)
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
end

function XTempleGameEditorControl:InitGame()
    XTempleGameControl.InitGame(self)
    self._Game:SetEditor()
end

function XTempleGameEditorControl:InitBlocks4InitMap()
    local grids = self._Model:GetGrids()
    for i, config in pairs(grids) do
        local id = config.Id
        if id ~= GRID.EMPTY then
            local blockId = GRID_TYPE_EDITOR | id
            if not self._Game:GetMap():GetBlockById(blockId) then
                ---@type XTempleBlock
                local block = self._Game:AddBlock()
                block:SetId(blockId)
                block:SetName(config.Name)

                -- 用单个grid生成block
                ---@type XTempleGrid
                local grid = self._Game:AddGrid()
                local x, y = 1, 1
                grid:SetPosition(x, y)
                grid:SetId(id)

                block:SetGrids({ [x] = { [y] = grid } })
                self._Game:GetMap():Add2Block(block)
            end
        end
    end
end

function XTempleGameEditorControl:GetOption2InitMap()
    self:InitBlocks4InitMap()
    local result = {}
    local allGrids = self._Model:GetGrids()
    for _, gridConfig in pairs(allGrids) do
        local id = gridConfig.Id
        local blockId = GRID_TYPE_EDITOR | id
        local block = self._Game:GetMap():GetBlockById(blockId)
        if block then
            local data = self:GetBlock4UiOption(block)
            result[#result + 1] = data
        end
    end
    return result
end

function XTempleGameEditorControl:OnClickBlockOptionEditor(blockId)
    local block = self._Game:GetMap():GetBlockById(blockId)
    self:SelectBlockOption(block)
end

function XTempleGameEditorControl:OnClickRule(id)
    self._EditingRuleId = id
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_EDIT)
end

function XTempleGameEditorControl:GetEditRule()
    if self._EditingRuleId == 0 then
        local rules = self._Game:GetPublicRules()
        if rules[1] then
            self._EditingRuleId = rules[1]:GetId()
        end
    end
    ---@type XTempleRule
    local rule = self._Game:GetRuleById(self._EditingRuleId)
    if not rule then
        return
    end
    local ruleType = rule:GetType()
    local ruleTextArray = {}
    local ruleDropdown = {}
    local allRule = self._Model:GetAllRule()
    local ruleSorted = {}
    for i, config in pairs(allRule) do
        ruleSorted[#ruleSorted + 1] = config.Id
    end
    table.sort(ruleSorted, function(a, b)
        return a < b
    end)

    for i = 1, #ruleSorted do
        local type = ruleSorted[i]
        ruleTextArray[#ruleTextArray + 1] = type .. ":" .. self._Model:GetRuleText(type)
        ruleDropdown[#ruleDropdown + 1] = type
    end
    local ruleDropdownArray = self:GetDropdownValueArray(ruleDropdown)
    local optionRule = {
        DropDown = ruleTextArray,
        Value = ruleDropdownArray,
        Selected = self:GetDropdownValue(ruleType, ruleDropdownArray),
        RuleId = rule:GetId(),
        ParamIndex = nil,
        EditType = EDIT_TYPE.RULE_TYPE,
    }

    local options = rule:GetEditOptions()
    for i = 1, #options do
        local option = options[i]
        option.ParamIndex = i
        option.RuleId = rule:GetId()
        option.EditType = EDIT_TYPE.PARAMS
    end

    local score = rule:GetRewardScore()
    local dropdownScore = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, -1, -2, -3, -4, -5, -6, -7, -8, -9, -10 }
    local dropdownArray = self:GetDropdownValueArray(dropdownScore)
    ---@class XTempleGameEditorRuleOption
    local optionScore = {
        DropDown = dropdownScore,
        Value = dropdownArray,
        Selected = self:GetDropdownValue(score, dropdownArray),
        RuleId = rule:GetId(),
        ParamIndex = #options + 1,
        EditType = EDIT_TYPE.SCORE,
    }
    table.insert(options, 1, optionScore)
    table.insert(options, 1, optionRule)

    local time = rule:GetActiveTime()
    local timeToggle = {}
    for i = 1, 4 do
        local type = 1 << (i - 1)
        if time & type ~= 0 then
            timeToggle[i] = {
                Selected = true,
                ParamIndex = type,
                EditType = EDIT_TYPE.TIME,
                RuleId = rule:GetId()
            }
        else
            timeToggle[i] = {
                Selected = false,
                ParamIndex = type,
                EditType = EDIT_TYPE.TIME,
                RuleId = rule:GetId()
            }
        end
    end

    local operation
    if rule:GetType() == RULE.SHAPE then
        local blockId = rule:GetShapeBlockId()
        if not self._Game:GetMap():GetBlockById(blockId) then
            ---@type XTempleBlock
            local block = self._Game:AddBlock()
            blockId = RULE_BLOCK_EDITOR | rule:GetId()
            block:SetId(blockId)
            rule:SetShapeBlockId(blockId)
            self._Game:GetMap():Add2Block(block)
        end
        local block = self._Game:GetMap():GetBlockById(blockId)
        operation = {
            Block = block,
        }
    end

    local data = {
        Text = rule:GetText(),
        Option = options,
        TimeToggle = timeToggle,
        Operation = operation,
        RuleName = rule:GetName(),
        RuleIsHide = rule:GetIsHide()
    }
    return data
end

---@param data XTempleUiDataGrid
function XTempleGameEditorControl:OnClickGrid(data)
    if self._State == STATE.EDIT_ROUND then
        if self._Data.IsEditBlock then
            return
        end
        local x = data.X
        local y = data.Y
        local grid = self._Game:GetMap():GetGrid(x, y)
        local round = grid:GetEditingRound()
        self:EditRound(round)
        return
    end

    if self._State ~= STATE.EDIT_MAP then
        return
    end

    local x = data.X
    local y = data.Y
    local grid = self._Game:GetMap():GetGrid(x, y)
    if grid then
        if grid:IsEmpty() then
            return
        end
        self:InsertDragAction(grid, x, y)
        grid:SetId(GRID.EMPTY)
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
    end
end

function XTempleGameEditorControl:InsertDragAction(grid, x, y)
    ---@type XTempleAction
    local actionPutDown = XTempleAction.New()
    actionPutDown:SetData({
        Type = ACTION.PUT_DOWN,
        BlockId = GRID_TYPE_EDITOR | grid:GetType(),
    })
    self._Game:EnqueueAction(actionPutDown)

    ---@type XTempleAction
    local actionDrag = XTempleAction.New()
    actionDrag:SetData({
        Type = ACTION.DRAG,
        Position = XLuaVector2.New(x, y)
    })
    self._Game:EnqueueAction(actionDrag)
end

function XTempleGameEditorControl:OnActionConfirm()
    if self._State == STATE.EDIT_MAP then
        self:SaveGameConfig()
    end
    if self._State == STATE.EDIT_ROUND then
        if not self._Game:IsSimulating() then
            self:SaveActionRecord()
            self._EditingRound = self._Game:GetOptionRound()
        end
    end
end

function XTempleGameEditorControl:SaveBlocks()
    local headTable = {
        "Id", "Name", "Grid1", "Grid2", "Grid3", "Grid4", "Grid5", "Grid6"
    }
    local isTable = {
        Grid1 = true,
        Grid2 = true,
        Grid3 = true,
        Grid4 = true,
        Grid5 = true,
        Grid6 = true,
    }
    local toSave = {}

    -- block
    ---@type XTempleBlock[]
    local blocks = self._Game:GetMap():EditorGetBlocks()
    for blockId, block in pairs(blocks) do
        if blockId & GRID_TYPE_EDITOR == 0 then
            toSave[blockId] = toSave[blockId] or {}
            local config = toSave[blockId]
            config.Id = blockId
            config.Name = block:GetName()
            for y = block:GetRowAmount(), 1, -1 do
                for x = 1, block:GetColumnAmount() do
                    local grid = block:GetGrid(x, y)
                    local gridType = grid and grid:GetEncodeInfo() or 0
                    local key = "Grid" .. y
                    config[key] = config[key] or {}
                    config[key][x] = gridType
                end
            end
        end
    end

    local content = self:GetConfigContent(toSave, headTable, isTable)

    local path = self._Model:EditorGetBlockPath()
    CS.System.IO.File.WriteAllText(path, content, CS.System.Text.Encoding.GetEncoding("GBK"));

    self:SaveToBackUpFile("Block", content)
end

function XTempleGameEditorControl:SaveGameConfig()
    if self:IsLockUpdateUi() then
        return
    end
    local toSave = {}

    -- 不保存其他配置
    if self._Data.IsEditRound then
        local gameConfig = self._Model:GetStageGameConfig(self._StageId)

        --复制一下
        toSave = self:CloneWithoutReadonly(gameConfig)

        for i = 1, #toSave do
            local config = toSave[i]
            config.OptionRound = nil
            config.Option = nil
            config.OptionReward = nil
            config.OptionSpend = nil
        end
    else
        -- map 
        local map = self._Game:GetMap()
        local column = map:GetColumnAmount()
        local row = map:GetRowAmount()
        for y = 1, row do
            for x = 1, column do
                local grid = map:GetGrid(x, y)
                local type = grid:GetEncodeInfo()
                local i = x
                local j = row - y + 1
                toSave[j] = toSave[j] or {}
                toSave[j].Map = toSave[j].Map or {}
                toSave[j].Map[i] = type
            end
        end

        -- rule
        local rules = self._Game:GetPublicRules()
        for i = 1, #rules do
            local rule = rules[i]
            toSave[i] = toSave[i] or {}
            local config = toSave[i]
            config.RuleId = rule:GetId()
            config.RuleType = rule:GetType()
            config.RuleParams = rule:GetParams()
            config.RuleTime = rule:GetTime4Edit()
            config.RuleScore = rule:GetRewardScore()
            config.RuleInTips = 0
            config.RuleName = rule:GetName()
            config.RuleIsHide = rule:GetIsHide() and 1 or 0
        end

        -- time
        local timeArray = self._Game:GetTimeArray()
        for i = 1, #timeArray do
            local time = timeArray[i]
            toSave[i] = toSave[i] or {}
            local config = toSave[i]
            config.Time = time:GetType()
            config.TimeDuration = time:GetDuration()
        end
    end

    -- option
    local optionList = self._Game:GetAllOptions()
    local optionIndex = 0
    for i = 1, #optionList do
        local options = optionList[i]
        for j = 1, #options do
            optionIndex = optionIndex + 1
            toSave[optionIndex] = toSave[optionIndex] or {}
            local config = toSave[optionIndex]
            local option = options[j]
            local blockId = option:GetBlockId()
            if blockId ~= 0 then
                config.OptionRound = i
                config.OptionId = option:GetId()
                config.OptionBlock = blockId
                config.OptionReward = option:GetIsExtraScoreValue()
                config.OptionSpend = option:GetSpend()
            end
        end
    end

    -- id
    for i = 1, #toSave do
        local config = toSave[i]
        config.Id = i
    end

    local path = self._Model:GetStageGamePath(self._StageId, true)

    local headTable = {
        "Id", "OptionRound", "OptionId", "OptionBlock", "OptionReward", "OptionSpend", "RuleId", "RuleName", "RuleType", "RuleParams", "RuleTime", "RuleScore", "RuleIsHide", "Rule4Grid", "Map", "Time", "TimeDuration"
    }
    local isTable = {
        RuleParams = true,
        RuleTime = true,
        Map = true,
    }

    local content = self:GetConfigContent(toSave, headTable, isTable)

    self:SaveToBackUpFile("Stage", content, self._StageId)
    CS.System.IO.File.WriteAllText(path, content, CS.System.Text.Encoding.GetEncoding("GBK"));

    self._Model:SetConfigDirty(true)
    self:SaveBlocks()
end

function XTempleGameEditorControl:GetConfigContent(toSave, headTable, isTable)
    local defaultTable = { 0 }

    -- 收集数组
    local headTableAmount = {}
    for i, config in pairs(toSave) do
        for j = 1, #headTable do
            local key = headTable[j]
            local value = config[key]
            if isTable[key] then
                value = value or defaultTable
                local amount = #value
                amount = math.max(amount, 1)
                if (not headTableAmount[key]) or (headTableAmount[key] < amount) then
                    headTableAmount[key] = amount
                end
            else
                headTableAmount[key] = 0
            end
        end
    end

    local contentTable = {}
    for i = 1, #headTable do
        local key = headTable[i]
        local amount = headTableAmount[key] or 0
        if amount == 0 then
            contentTable[#contentTable + 1] = key
            contentTable[#contentTable + 1] = '\t'
        else
            for j = 1, amount do
                contentTable[#contentTable + 1] = key
                contentTable[#contentTable + 1] = '['
                contentTable[#contentTable + 1] = j
                contentTable[#contentTable + 1] = ']'
                contentTable[#contentTable + 1] = '\t'
            end
        end
    end
    contentTable[#contentTable] = nil
    contentTable[#contentTable + 1] = "\r\n"

    for i, config in pairs(toSave) do
        for j = 1, #headTable do
            local key = headTable[j]
            local value = config[key]
            if isTable[key] then
                value = value or defaultTable
                local size = headTableAmount[key]
                for k = 1, size do
                    local element = value[k]
                    if element then
                        contentTable[#contentTable + 1] = element
                    end
                    contentTable[#contentTable + 1] = '\t'
                end
            else
                contentTable[#contentTable + 1] = value
                contentTable[#contentTable + 1] = '\t'
            end
        end
        contentTable[#contentTable] = nil
        contentTable[#contentTable + 1] = "\r\n"
    end
    local content = table.concat(contentTable)
    return content
end

-- 丢掉metatable
function XTempleGameEditorControl:CloneWithoutReadonly(data)
    if not data then
        return data
    end
    if type(data) ~= "table" then
        return data
    end
    local visitedMap = {}
    ---@type XQueue
    local queue = XQueue.New()
    queue:Enqueue(data)

    while (not queue:IsEmpty()) do
        -- curData是原始对象，obj是复制对象
        local curData = queue:Dequeue()
        local obj
        if visitedMap[curData] then
            obj = visitedMap[curData]
        else
            obj = {}
            visitedMap[curData] = obj
        end
        for k, v in pairs(curData) do
            local key
            if type(k) == "table" then
                if visitedMap[k] then
                    key = visitedMap[k]
                else
                    key = {}
                    visitedMap[k] = key
                    queue:Enqueue(k)
                end
            else
                key = k
            end
            local value
            if type(v) == "table" then
                if visitedMap[v] then
                    value = visitedMap[v]
                else
                    value = {}
                    visitedMap[v] = value
                    queue:Enqueue(v)
                end
            else
                value = v
            end
            obj[key] = value
        end
    end
    return visitedMap[data]
end

---@param option XTempleGameEditorRuleOption
function XTempleGameEditorControl:EditRule(option, selectIndex)
    local ruleId = option.RuleId
    ---@type XTempleRule
    local rule = self._Game:GetRuleById(ruleId)
    if rule then
        if option.EditType == EDIT_TYPE.RULE_TYPE then
            local value = option.Value[selectIndex]
            local data = rule:GetData4Edit()
            data.Type = value
            data.Params = {}
            rule:SetData(data)

        elseif option.EditType == EDIT_TYPE.SCORE then
            local value = option.Value[selectIndex]
            local data = rule:GetData4Edit()
            data.Score = value
            --data.Params[option.ParamIndex] = value
            rule:SetData(data)

        elseif option.EditType == EDIT_TYPE.PARAMS then
            local value = option.Value[selectIndex]
            local data = rule:GetData4Edit()
            data.Params[option.ParamIndex] = value
            rule:SetData(data)

        elseif option.EditType == EDIT_TYPE.TIME then
            local data = rule:GetData4Edit()
            if selectIndex then
                data.TimeOfDay = data.TimeOfDay | option.ParamIndex
            else
                data.TimeOfDay = data.TimeOfDay & (~option.ParamIndex)
            end
            rule:SetData(data)
        end
        self:SaveGameConfig()
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_EDIT)
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
    end
end

function XTempleGameEditorControl:RemoveEditingRule()
    local rule2Remove = self._Game:GetRuleById(self._EditingRuleId)
    if rule2Remove then
        self._Game:RemoveRule(rule2Remove)
        local rules = self._Game:GetPublicRules()
        for i = 1, #rules do
            local rule = rules[i]
            rule:SetId(i)
        end
        if not self._Game:GetRuleById(self._EditingRuleId) then
            self._EditingRuleId = #rules
        end
    end
    self:SaveGameConfig()
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_EDIT)
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
end

function XTempleGameEditorControl:AddNewRule()
    local game = self._Game
    ---@type XTempleRule
    local rule = game:AddRule()
    rule:SetType(RULE.DEFAULT)
    self._EditingRuleId = rule:GetId()
    self:SaveGameConfig()
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_EDIT)
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
end

function XTempleGameEditorControl:GetData4EditTime()
    local dropDown = {}
    for i = 0, 35 do
        dropDown[#dropDown + 1] = i
    end

    local timeData = {}
    local timeArray = self._Game:GetTimeArray()
    for type = TIME_OF_DAY.BEGIN + 1, TIME_OF_DAY.END - 1 do
        local isOn = false
        local duration = 0
        for i = 1, #timeArray do
            local time = timeArray[i]
            if time:GetType() == type then
                isOn = true
                duration = time:GetDuration()
            end
        end
        ---@class XTempleGameEditorTimeData
        local data = {
            IsOn = isOn,
            Selected = duration,
            DropDown = dropDown,
            Time = type
        }
        timeData[#timeData + 1] = data
    end
    return timeData
end

---@param data XTempleGameEditorTimeData
function XTempleGameEditorControl:EditTime(data)
    local type = data.Time
    local isOn = data.IsOn
    local timeArray = self._Game:GetTimeArray()
    if isOn then
        local isFind = false
        for i = 1, #timeArray do
            local time = timeArray[i]
            if time:GetType() == type then
                time:SetDuration(data.Selected)
                isFind = true
                break
            end
        end
        if not isFind then
            ---@type XTempleTimeOfDay
            local time2Insert = self._Game:AddTimeOfDay()
            time2Insert:SetType(type)
            for i = 1, #timeArray do
                local time = timeArray[i]
                if time2Insert:GetType() < time:GetType() then
                    table.insert(timeArray, i, time2Insert)
                    time2Insert = nil
                    break
                end
            end
            if time2Insert then
                table.insert(timeArray, time2Insert)
            end
        end
    else
        for i = 1, #timeArray do
            local time = timeArray[i]
            if time:GetType() == type then
                table.remove(timeArray, i)
                break
            end
        end
    end
    self:SaveGameConfig()
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
end

function XTempleGameEditorControl:GetDataOfAllBlocks()
    local data = {}

    ---@type XTempleBlock[]
    local blocks = self._Game:GetMap():EditorGetBlocks()
    for blockId, block in pairs(blocks) do
        if blockId & RULE_BLOCK_EDITOR == 0
                and blockId & GRID_TYPE_EDITOR == 0
                and blockId & XTempleEnumConst.RULE_TIPS_BLOCK == 0
        then
            local isInsert = true
            if self._SearchBlockName ~= "" then
                isInsert = string.find(block:GetName(), self._SearchBlockName)
            end
            if isInsert then
                ---@type XTempleUiDataBlockOption
                local dataBlockOption = self:GetBlock4UiOption(block)
                data[#data + 1] = dataBlockOption
                data.IsSelected = self._EditingBlockId == dataBlockOption.BlockId
            end
        end
    end
    table.sort(data, function(a, b)
        return a.BlockId < b.BlockId
    end)

    self._DataOfAllBlock = data
    return data
end

---@param blockData XTempleUiDataBlockOption
function XTempleGameEditorControl:SetSelectedEditingBlock(blockData)
    local blockId = blockData.BlockId
    self._EditingBlockId = blockId
end

function XTempleGameEditorControl:GetEditingBlockId()
    return self._EditingBlockId
end

function XTempleGameEditorControl:GetEditingBlock()
    local block = self._Game:GetMap():GetBlockById(self._EditingBlockId)
    return block
end

function XTempleGameEditorControl:AddNewBlock()
    local map = self._Game:GetMap()
    ---@type XTempleBlock
    local block = self._Game:AddBlock()
    local blockId = map:EditorGetNextBlockId()
    block:SetId(blockId)
    block:SetName(self._SearchBlockName or "")
    map:Add2Block(block)
    self:SaveGameConfig()
    self._EditingBlockId = blockId
end

function XTempleGameEditorControl:RemoveEditingBlock()
    if self._EditingBlockId then
        local map = self._Game:GetMap()
        map:RemoveBlock(self._EditingBlockId)
        self:SaveGameConfig()
    end
    local selectIndex = 1
    if self._DataOfAllBlock then
        for i = 1, #self._DataOfAllBlock do
            local data = self._DataOfAllBlock[i]
            if data.BlockId == self._EditingBlockId then
                selectIndex = i
                break
            end
        end
    end
    return selectIndex
end

function XTempleGameEditorControl:IsShowSkip()
    local options = self._Game:GetOptionsByRound(self._EditingRound)
    if not options then
        return false
    end
    local option = options[1]
    if not option then
        return false
    end
    if option:IsSkip() then
        return true
    end
    return false
end

function XTempleGameEditorControl:SetSkipOption(value)
    if self:IsShowSkip() == value then
        return
    end
    if value then
        ---@type XTempleOption
        local option = self._Game:CreateOption()
        option:SetBlockId(XTempleEnumConst.BLOCK.SKIP)
        option:SetRound(self._EditingRound)
        option:SetSpend(1)
        option:SetIsExtraScore(0)
        option:SetId(self._Game:GetNextOptionId())
        self._Game:AddOption(option, 1)
    else
        local options = self._Game:GetOptionsByRound(self._EditingRound)
        local option = options[1]
        if option and option:IsSkip() then
            self._Game:RemoveOption(option)
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
end

function XTempleGameEditorControl:GetDataRoundList()
    local data = {}
    local optionList = self._Game:GetAllOptions()
    for i = 1, #optionList do
        local round = {
            Round = i,
            Name = "Round:" .. i
        }
        data[#data + 1] = round
    end
    return data
end

function XTempleGameEditorControl:EditRound(round)
    self._EditingRound = round

    self:LoadActionRecord()
    self._Game:SetEndlessTime4Edit()
    self._Game:SetOptionRound(1)
    self._Game:SimulateActionRecord(1, round - 1)
    self._Game:SetOptionRound(round + 1)
    self._Game:SimulateActionRecord(round + 1, nil, nil, true)
    self._Game:SetOptionRound(round)
    self._Game:SimulateActionRecord(round, round, false, true)
    self._Game:SetOptionRound(round)

    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
end

function XTempleGameEditorControl:AddNewRound()
    local round = self._Game:GetNewRoundIndex()

    ---@type XTempleOption
    local optionSkip = self._Game:CreateOption()
    optionSkip:SetBlockId(XTempleEnumConst.BLOCK.SKIP)
    optionSkip:SetRound(round)
    optionSkip:SetId(self._Game:GetNextOptionId())
    self._Game:AddOption(optionSkip)

    self._EditingRound = round
    self._Game:SetOptionRound(round)
    self:SaveGameConfig()

    self:EditRound(round)
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
end

function XTempleGameEditorControl:RemoveRound()
    if self._Game:RemoveRound(self._EditingRound) then
        self:SaveGameConfig()
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
    end
end

function XTempleGameEditorControl:AddNewOption()
    local options = self._Game:GetOptionsByRound(self._EditingRound)
    if options then
        if #options >= XTempleEnumConst.OPTIONS_AMOUNT then
            return
        end
        ---@type XTempleOption
        local option = self._Game:CreateOption()
        option:SetBlockId(0)
        option:SetRound(self._EditingRound)
        option:SetSpend(1)
        option:SetId(self._Game:GetNextOptionId())
        self._Game:AddOption(option)

        self:SaveGameConfig()
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
    end
end

function XTempleGameEditorControl:GetEditingRound()
    return self._EditingRound
end

function XTempleGameEditorControl:RemoveOption(index)
    local options = self._Game:GetOptionsByRound(self._EditingRound)
    local toSelect = 0
    for i = 1, #options do
        local option = options[i]
        if option:GetBlockId() >= 0 then
            toSelect = toSelect + 1
        end
        if toSelect == index then
            table.remove(options, i)
            self:SaveGameConfig()
            XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
            break
        end
    end
end

function XTempleGameEditorControl:SetEditingBlockFromOption(index)
    local options = self._Game:GetOptionsByRound(self._EditingRound)
    local optionToSelect
    local toSelect = 0
    for i = 1, #options do
        local option = options[i]
        if option:GetBlockId() >= 0 then
            toSelect = toSelect + 1
        end
        if toSelect == index then
            optionToSelect = option
            self._EditingRoundOptionIndex = i
        end
    end

    if optionToSelect then
        local blockId = optionToSelect:GetBlockId()
        self._EditingBlockId = blockId
        self._Data.IsEditBlock = true
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_EDIT_BLOCK_FROM_OPTION)
    end
end

function XTempleGameEditorControl:SetBlock2RoundOption()
    self._Data.IsEditBlock = false
    local blockId = self._EditingBlockId
    local options = self._Game:GetOptionsByRound(self._EditingRound, true)
    local option = options[self._EditingRoundOptionIndex]
    self._EditingRoundOptionIndex = 0
    if option then
        local block = self._Game:GetMap():GetBlockById(blockId)
        if block then
            option:SetBlockId(blockId)
        end
    end
    self:SaveGameConfig()
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_EDIT_BLOCK_FROM_OPTION)
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
end

function XTempleGameEditorControl:SaveActionRecord()
    --local Json = require("XCommon/Json")
    --self._Game:HandleActionRecord4Save()
    --local actionRecords = self._Game:GetActionRecords()
    --local content = Json.encode(actionRecords)
    --local path = self._Model:GetEditorActionPath(self._EditingStageId)
    --local file2Write = io.open(path, "w")
    --assert(file2Write)
    --file2Write:write(content)
    --file2Write:close()
    --self:SaveToBackUpFile("ActionRecord", content, self._StageId)

    local actionRecords = self._Game:GetActionRecords()

    local toSave = {}
    for i = 1, #actionRecords do
        local record = actionRecords[i]
        local config
        if record then
            config = {
                Id = i,
                BlockId = record.BlockId,
                X = record.X,
                Y = record.Y,
                Round = record.Round,
                OptionId = record.OptionId,
                Rotation = record.Rotation,
            }
        else
            config = {
                Id = i,
                BlockId = 0,
                Round = i,
                OptionId = 0,
                Rotation = 0
            }
        end
        toSave[i] = config
    end

    local headTable = {
        "Id", "BlockId", "X", "Y", "Round", "OptionId", "Rotation"
    }
    local isTable = {}
    local content = self:GetConfigContent(toSave, headTable, isTable)
    local path = self._Model:GetActionRecordPath(self._EditingStageId, true)
    CS.System.IO.File.WriteAllText(path, content, CS.System.Text.Encoding.GetEncoding("GBK"));
    self:SaveToBackUpFile("Record", content, self._EditingStageId)
end

function XTempleGameEditorControl:LoadActionRecord()
    --local path = self._Model:GetActionRecordPath(self._EditingStageId, true)
    --local file2Read = io.open(path, "r")
    --if not file2Read then
    --    self._Game:ClearActionRecord()
    --    return
    --end
    --assert(file2Read)
    --local content = file2Read:read("*a")
    --file2Read:close()
    --local Json = require("XCommon/Json")
    --local actionRecords = Json.decode(content)
    local actionRecords = self._Model:GetActionRecord(self._EditingStageId)
    self:SetSelectedStage(self._EditingStageId)
    self._Game:SetActionRecords(actionRecords)

    -- editor 将旧的锚点逻辑改成新的
    --self:RefreshRotateAnchorPoint()
end

function XTempleGameEditorControl:OnClickRestartGame()
    XTempleGameControl.OnClickRestartGame(self)
    self:SaveActionRecord()
end

function XTempleGameEditorControl:StartGame(stageId)
    XTempleGameControl.StartGame(self, stageId)
    local blockConfig = self._Model:GetAllBlocks()
    self._Game:EditorInitFromBlockConfig(blockConfig)
end

function XTempleGameEditorControl:GetEditingOption()
    local round = self._EditingRound
    local optionIndex = self._EditingRoundOptionIndex
    local options = self._Game:GetOptionsByRound(round)
    if options then
        return options[optionIndex]
    end
end

function XTempleGameEditorControl:SetEditingOptionSpend(spend)
    local option = self:GetEditingOption()
    if option then
        option:SetSpend(spend)
    end
end

function XTempleGameEditorControl:SetEditingOptionScore(score)
    local option = self:GetEditingOption()
    if option then
        option:SetIsExtraScore(score)
    end
end

function XTempleGameEditorControl:SetEditingRuleName(name)
    local ruleId = self._EditingRuleId
    ---@type XTempleRule
    local rule = self._Game:GetRuleById(ruleId)
    if rule then
        if rule:GetName() ~= name then
            rule:SetName(name)
            self:SaveGameConfig()
            XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
        end
    end
end

function XTempleGameEditorControl:GetTotalRound()
    local times = self._Game:GetTimeArray()
    local duration = 0
    for i = 1, #times do
        local time = times[i]
        duration = duration + time:GetDuration()
    end
    return duration
end

function XTempleGameEditorControl:SetEditingRuleHide(value)
    local ruleId = self._EditingRuleId
    ---@type XTempleRule
    local rule = self._Game:GetRuleById(ruleId)
    if rule then
        if rule:GetIsHide() ~= value then
            rule:SetIsHide(value)
            self:SaveGameConfig()
            XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
        end
    end
end

function XTempleGameEditorControl:GetDropdownValueArray(dropdown)
    local valueArray = {}
    for i = 1, #dropdown do
        local index = i - 1
        valueArray[index] = dropdown[i]
    end
    return valueArray
end

function XTempleGameEditorControl:GetDropdownValue(value, array)
    for i, v in pairs(array) do
        if v == value then
            return i
        end
    end
end

function XTempleGameEditorControl:SetEditingBlockName(name)
    ---@type XTempleBlock
    local block = self:GetEditingBlock()
    block:SetName(name)
    self:SaveGameConfig()
end

function XTempleGameEditorControl:SaveToBackUpFile(key, content, stageId)
    local time = os.date("%Y%m%d_%H%M%S_")
    local directory = CS.UnityEngine.Application.dataPath .. "../../../../Product/Table/Client/MiniActivity/TempleFair/TempleBackup/" .. key .. "/"
    stageId = stageId or ""
    local path = directory .. time .. key .. stageId .. ".tabconfig"
    CS.System.IO.Directory.CreateDirectory(directory)
    CS.System.IO.File.WriteAllText(path, content, CS.System.Text.Encoding.GetEncoding("GBK"))
    local files = CS.System.IO.Directory.GetFiles(directory)
    if files.Length > 100 then
        local file2Delete
        local file2DeleteTime = math.huge
        for i = 0, files.Length - 1 do
            local fileName = files[i]
            local time1, time2, name3 = string.match(fileName, "(%d+)_(%d+)_(%w+).tabconfig")
            if time1 then
                local saveTime = time1 * 1000000 + time2
                if saveTime < file2DeleteTime then
                    file2Delete = fileName
                    file2DeleteTime = saveTime
                end
            end
        end
        if file2Delete then
            CS.System.IO.File.Delete(file2Delete)
        end
    end
end

function XTempleGameEditorControl:SetSearchBlockName(name)
    if self._SearchBlockName == name then
        return
    end
    self._SearchBlockName = name
end

function XTempleGameEditorControl:GetSearchBlockName()
    return self._SearchBlockName
end

function XTempleGameEditorControl:GetSearchItems()
    local data = {}
    local grids = self._Model:GetGrids()
    for i, grid in pairs(grids) do
        data[#data + 1] = grid.Name
    end
    return data
end

function XTempleGameEditorControl:GetRules()
    local data = {}
    local configs = self._Model:GetRules()
    for i, config in pairs(configs) do
        data[#data + 1] = {
            Text = config.Id .. ":" .. config.Text,
            Id = config.Id
        }
    end
    table.sort(data, function(a, b)
        return a.Id < b.Id
    end)
    return data
end

function XTempleGameEditorControl:SetTipsEditingRule(data)
    if data then
        self._TipsEditingRule = data.Id
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_EDITING_RULE_TIPS)
    end
end

function XTempleGameEditorControl:IsTipsEditingRule(data)
    if data then
        return self._TipsEditingRule == data.Id
    end
    return false
end

function XTempleGameEditorControl:IsSetTipsEditingRule()
    return self._TipsEditingRule and true or false
end

function XTempleGameEditorControl:GetDataRuleTips()
    local ruleId = self._TipsEditingRule
    local data = {
        TextRule = self._Model:GetRuleText(ruleId),
    }
    return data
end

function XTempleGameEditorControl:GetRuleTipsBlock()
    local ruleId = self._TipsEditingRule
    local blockId = self._Model:GetRuleBlockId(ruleId)
    ---@type XTempleBlock
    local block = self._Game:GetMap():GetBlockById(blockId)
    if block then
        return block
    end
    block = self._Game:AddBlock()
    block:SetId(blockId)
    block:SetName(ruleId)
    self._Game:GetMap():Add2Block(block)
    return block
end

function XTempleGameEditorControl:RefreshRotateAnchorPoint()
    local actionRecord = self._Game:GetActionRecords()
    actionRecord = XTool.CloneEx(actionRecord, true)
    self._Game:SetActionRecords(actionRecord)
    for i = 1, #actionRecord do
        local record = actionRecord[i]
        if record.Rotation ~= 0 then
            ---@type XTempleBlock
            local block = self._Game:GetMap():GetBlockById(record.BlockId)
            local block1 = block:Clone()
            local block2 = block:Clone()
            local rotateAmount = record.Rotation / 90
            self._IsNewRotation = false
            for j = 1, rotateAmount do
                block1:Rotate90()
            end
            self._IsNewRotation = true
            for j = 1, rotateAmount do
                block2:Rotate90()
            end
            local anchorPoint1 = block1:GetAnchorPosition()
            local anchorPoint2 = block2:GetAnchorPosition()
            local diffX = anchorPoint2.x - anchorPoint1.x
            local diffY = anchorPoint2.y - anchorPoint1.y
            record.X = record.X + diffX
            record.Y = record.Y + diffY
        end
    end
    self:SaveActionRecord()
end

return XTempleGameEditorControl
