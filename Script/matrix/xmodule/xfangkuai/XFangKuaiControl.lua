---@class XFangKuaiControl : XControl
---@field private _Model XFangKuaiModel
---@field private _BlockMove XFangKuaiMove 移动模块
---@field private _Game XFangKuaiGame 大方块主逻辑
---@field private _Item XFangKuaiItem 道具模块
---@field private _Enviroment XFangKuaiEnviroment 关卡环境模块
---@field private _Score XFangKuaiScore 计分模块
---@field private _Create XFangKuaiCreate 方块生成模块
local XFangKuaiControl = XClass(XControl, "XFangKuaiModelControl")

function XFangKuaiControl:OnInit()
    self._BlockMove = self:AddSubControl(require("XModule/XFangKuai/XSubControl/XFangKuaiMove"))
    self._Item = self:AddSubControl(require("XModule/XFangKuai/XSubControl/XFangKuaiItem"))
    self._Enviroment = self:AddSubControl(require("XModule/XFangKuai/XSubControl/XFangKuaiEnviroment"))
    self._Score = self:AddSubControl(require("XModule/XFangKuai/XSubControl/XFangKuaiScore"))
    self._Game = self:AddSubControl(require("XModule/XFangKuai/XSubControl/XFangKuaiGame"))
    self._Create = self:AddSubControl(require("XModule/XFangKuai/XSubControl/XFangKuaiCreate"))
end

function XFangKuaiControl:AddAgencyEvent()
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_RESETDATA, self.CheckStageDataError, self)
end

function XFangKuaiControl:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_RESETDATA, self.CheckStageDataError, self)
end

function XFangKuaiControl:OnRelease()

end

--region 主逻辑

function XFangKuaiControl:EnterGame(stageId, isNewGame)
    -- 两个模式有两个关卡记录
    local chapterId = self:GetChapterIdByStage(stageId)
    if self._Game:GetCurFightChapterId() ~= chapterId then
        -- 新开始游戏时不会走这 走FangKuaiStageStartRequest
        self._Enviroment:InitEnviroment(stageId)
        self:SetGameStage(stageId)
    end
    XLuaUiManager.Open("UiFangKuaiFight", self._Game, isNewGame)
end

function XFangKuaiControl:SetGameStage(stageId)
    self._Game:SaveStageBlockData()
    self._Game:InitData()
    self._Game:SetStage(stageId)
end

function XFangKuaiControl:RestartGame(stageId, cb)
    self:RecordStage(XEnumConst.FangKuai.RecordUiType.Fight, XEnumConst.FangKuai.RecordButtonType.Reset, stageId)
    if self._Game:IsGameOver() then
        self:ClearFightData(stageId)
        self:FangKuaiStageStartRequest(stageId, cb)
        return
    end
    self:FangKuaiStageSettleRequest(stageId, XEnumConst.FangKuai.Settle.Reset, function()
        self:FangKuaiStageStartRequest(stageId, cb)
    end)
end

function XFangKuaiControl:GetBlockMap()
    return self._Game:GetBlockMap()
end

function XFangKuaiControl:AddOperate(operate, args)
    self._Game:AddOperate(operate, args)
end

---@return table<XFangKuaiBlock,boolean>
function XFangKuaiControl:GetLayerBlocks(gridY)
    return self._Game:GetLayerBlocks(gridY)
end

---@param stageData XFangKuaiStageData
function XFangKuaiControl:CreateBlock(stageData, length, x, y)
    return self._Create:CreateBlock(stageData, length, x, y)
end

---@param data XFangKuaiBlock
---@return XFangKuaiBlock
function XFangKuaiControl:CreateCopyBlockData(len, pos, data, itemId, chapterId)
    return self._Create:CreateCopyBlockData(len, pos, data, itemId, chapterId)
end

---@param data XFangKuaiBlock
function XFangKuaiControl:CreateFissionBlockData(len, pos, data, itemId, stageId)
    local chapterId = self:GetChapterIdByStage(stageId)
    local block = self:CreateCopyBlockData(len, pos, data, itemId, chapterId)
    local direction = self._Model:GetBlockConfig(data:GetBlockId()).Direction
    local blockConfig = self._Model:GetBlockConfigByData(stageId, len, direction, 1) -- 分裂出来的小方块都设color为1
    block:SetBlockType(XEnumConst.FangKuai.BlockType.Normal)
    block:SetBlockId(blockConfig.Id)
    block:SetColor(1)
    block:SetScore()
    return block
end

function XFangKuaiControl:IsDebug()
    if XMain.IsWindowsEditor then
        return XSaveTool.GetData("FangKuai_Debug")
    end
    return false
end

function XFangKuaiControl:CreateNewLines(addLine)
    self._Create:CreateNewLines(self._Game:GetCurFightChapterId(), addLine)
end

function XFangKuaiControl:GetNewBlockLastY()
    return self._Game:GetNewBlockLastY()
end

--endregion

--region 活动

function XFangKuaiControl:GetActivityId()
    return self._Model.ActivityData:GetActivityId()
end

function XFangKuaiControl:GetActivityGameEndTime()
    local timeId = self:GetActivityConfig().TimeId
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XFangKuaiControl:GetActivityConfig()
    local activityId = self:GetActivityId()
    return self._Model:GetActivityConfig(activityId)
end

function XFangKuaiControl:GetHelpId()
    return self:GetActivityConfig().HelpId
end

function XFangKuaiControl:GetActivityRemainder()
    local timeId = self:GetActivityConfig().TimeId
    if XTool.IsNumberValid(timeId) then
        return XFunctionManager.GetEndTimeByTimeId(timeId) - XTime.GetServerNowTimestamp()
    end
    return 0
end

function XFangKuaiControl:GetBubbleReward()
    local rewards = {}
    local params = self._Model:GetClientConfigs("Rewards")
    for _, param in pairs(params) do
        local datas = string.Split(param, "_")
        table.insert(rewards, { TemplateId = tonumber(datas[1]), Count = tonumber(datas[2]) })
    end
    return rewards
end

function XFangKuaiControl:GetBubbleKeepTime()
    return tonumber(self._Model:GetClientConfig("RewardTipsTime", 1))
end

function XFangKuaiControl:GetFavorLevelIcon(lv)
    return self._Model:GetClientConfig("FavorLevelIcon", lv)
end

function XFangKuaiControl:GetFavorLevelColor(characterId, lv)
    local favorData = XMVCA.XFavorability:GetFavorabilityTableData(characterId)
    local color = self._Model:GetClientConfig("FavorLevelColor", lv)
    return string.format("<color=%s>%s</color>", color, favorData.Name)
end

function XFangKuaiControl:GetMaxItemCount()
    return self:GetActivityConfig().MaxItemCount
end

function XFangKuaiControl:GetClientConfig(key, index)
    return self._Model:GetClientConfig(key, index)
end

function XFangKuaiControl:GetActivityData()
    return self._Model.ActivityData
end

---获取该章节里正在挑战的关卡Id（多个章节有多个正在挑战的关卡）
function XFangKuaiControl:GetCurStageId(chapterId)
    return self._Model:GetCurStageId(chapterId)
end

function XFangKuaiControl:GetCurCreateBlocks(chapterId)
    local stageData = self._Model.ActivityData:GetStageData(chapterId)
    return stageData and stageData:GetBlocks() or nil
end

function XFangKuaiControl:ClearCurCreateBlocks(chapterId)
    self._Model.ActivityData:ClearAllBlock(chapterId)
end

function XFangKuaiControl:HandleActivityEnd()
    self:ClearFightData()
    XLuaUiManager.RunMain()
    XUiManager.TipText("ActivityAlreadyOver")
end

function XFangKuaiControl:OpenTip(title, desc, sureCallBack)
    XLuaUiManager.Open("UiFangKuaiTc", title, desc, sureCallBack)
end

function XFangKuaiControl:GetChapterIdByStage(stageId)
    return self._Model:GetStageIdChapterId(stageId)
end

--endregion

--region 关卡

---评级Icon
function XFangKuaiControl:GetStageRankIcon(stageId, score)
    local grade = self._Model:GetScoreGrade(stageId, score)
    return self:GetStageRankIconByGrade(grade)
end

function XFangKuaiControl:GetStageRankIconByGrade(grade)
    return self._Model:GetClientConfig("GradeRankIcon", grade)
end

---@return XTableFangKuaiScoreRate[]
function XFangKuaiControl:GetScoreGradeConfig(stageId)
    return self._Model:GetScoreGradeConfig(stageId)
end

function XFangKuaiControl:IsStageUnlock(stageId)
    return self._Model:IsStageUnlock(stageId)
end

---@return boolean,string
function XFangKuaiControl:IsStageTimeUnlock(stageId)
    return self._Model:IsStageTimeUnlock(stageId)
end

---@return boolean,string
function XFangKuaiControl:IsStageGroupTimeUnlock(stageGroupId)
    local isUnlock, timeStr = self._Model:IsStageGroupTimeUnlock(stageGroupId)
    if not isUnlock then
        return isUnlock, XUiHelper.GetText("FangKuaiStageCondition", timeStr)
    end
    return isUnlock, timeStr
end

---@return boolean,string
function XFangKuaiControl:IsChapterTimeUnlock(chapterId)
    local isUnlock, timeStr = self._Model:IsChapterTimeUnlock(chapterId)
    if not isUnlock then
        return isUnlock, XUiHelper.GetText("FangKuaiStageCondition", timeStr)
    end
    return isUnlock, timeStr
end

---@return boolean,string
function XFangKuaiControl:IsPreStagePass(stageId)
    local preStageId = self._Model:GetStageConfig(stageId).PreStageId
    local condStr = XTool.IsNumberValid(preStageId) and
            XUiHelper.GetText("FangKuaiPreStageLock", self._Model:GetStageConfig(preStageId).Name) or ""
    return self._Model:IsPreStagePass(stageId), condStr
end

function XFangKuaiControl:IsStagePass(stageId)
    return self._Model.ActivityData:IsStagePass(stageId)
end

function XFangKuaiControl:IsOpenHardChapter()
    local conditionStr
    local stages = self:GetHardStages()
    for _, stage in ipairs(stages) do
        local isTimeUnlock, timeStr = self:IsStageTimeUnlock(stage.Id)
        local isPreStageUnlock, preStageStr = self:IsPreStagePass(stage.Id)
        if isTimeUnlock and isPreStageUnlock then
            return true
        end
        if not conditionStr then
            conditionStr = isTimeUnlock and preStageStr or timeStr
        end
    end
    return false, conditionStr
end

function XFangKuaiControl:IsStagePlaying(stageId)
    return self._Model:IsStagePlaying(stageId)
end

function XFangKuaiControl:IsOtherPlaying(stageId, chapterId)
    local curStageId = self:GetCurStageId(chapterId)
    return XTool.IsNumberValid(curStageId) and curStageId ~= stageId
end

function XFangKuaiControl:IsChapterPlaying(curChapterId)
    local stageIdChapterIdMap = self._Model:GetStageIdChapterIdMap()
    for stageId, chapterId in pairs(stageIdChapterIdMap) do
        if curChapterId == chapterId then
            if self:IsStagePlaying(stageId) then
                return true
            end
        end
    end
    return false
end

---@return XTableFangKuaiStage
function XFangKuaiControl:GetStageConfig(stageId)
    return self._Model:GetStageConfig(stageId)
end

---@return XTableFangKuaiStage[]
function XFangKuaiControl:GetNormalStages()
    return self._Model:GetStagesConfig(XEnumConst.FangKuai.Difficulty.Normal)
end

---@return XTableFangKuaiStage[]
function XFangKuaiControl:GetHardStages()
    return self._Model:GetStagesConfig(XEnumConst.FangKuai.Difficulty.Hard)
end

---@return XTableFangKuaiItem[]
function XFangKuaiControl:GetStageShowItems(stageId)
    local items = {}
    local stageConfig = self:GetStageConfig(stageId)
    for _, itemId in pairs(stageConfig.ShowItem) do
        table.insert(items, self:GetItemConfig(itemId))
    end
    return items
end

---是否普通关卡
function XFangKuaiControl:IsStageNormal(stageId)
    return not self._Model:IsStageDifficulty(stageId)
end

---@return XTableFangKuaiItem
function XFangKuaiControl:GetItemConfig(itemId)
    return self._Model:GetItemConfig(itemId)
end

function XFangKuaiControl:GetCurStageData()
    return self._Model.ActivityData:GetStageData(self._Game:GetCurFightChapterId())
end

function XFangKuaiControl:AddRound()
    self:GetCurStageData():AddRound()
end

function XFangKuaiControl:GetCurRound(chapterId)
    chapterId = chapterId or self._Game:GetCurFightChapterId()
    local stageData = self._Model.ActivityData:GetStageData(chapterId)
    return stageData and stageData:GetRound() or 0
end

function XFangKuaiControl:GetExtraRound()
    local stageData = self:GetCurStageData()
    return stageData and stageData:GetExtraRound() or 0
end

---@return XTableFangKuaiStageEnvironment
function XFangKuaiControl:GetEnvironmentConfig(id)
    return self._Model:GetEnvironmentConfig(id)
end

function XFangKuaiControl:ClearFightData(stageId)
    local chapterId = self:GetChapterIdByStage(stageId)
    if self._Game:GetCurFightChapterId() == chapterId then
        self._Game:InitData()
    end

    if XTool.IsNumberValid(stageId) then
        self._Model.ActivityData:ClearStageData(chapterId)
    else
        self._Model.ActivityData:ClearStageData()
    end
end

function XFangKuaiControl:GetCurFightChapterId()
    return self._Game:GetCurFightChapterId()
end

function XFangKuaiControl:GetChapterConfigs()
    return self._Model:GetChapterConfigs()
end

function XFangKuaiControl:GetChapterConfig(chapterId)
    return self._Model:GetChapterConfig(chapterId)
end

function XFangKuaiControl:GetStageGroupConfig(id)
    return self._Model:GetStageGroupConfig(id)
end

function XFangKuaiControl:RecordStageGroupTabIdx(id, index)
    self._Model:RecordStageGroupTabIdx(id, index)
end

function XFangKuaiControl:GetStageGroupTabIdx(id)
    return self._Model:GetStageGroupTabIdx(id)
end

function XFangKuaiControl:GetStageGroupByStage(stageId)
    local stageGroups = self._Model:GetStageGroupConfigs()
    for _, v in pairs(stageGroups) do
        if v.SimpleStageId == stageId or v.DiffcultStageId == stageId then
            return v
        end
    end
    return nil
end

function XFangKuaiControl:GetMaxRound(stageId)
    return self._Model.ActivityData:GetMaxRound(stageId)
end

--endregion

--region 角色

function XFangKuaiControl:GetNpcActionConfig(npcId)
    return self._Model:GetNpcActionConfig(npcId)
end

function XFangKuaiControl:GetAllPlayerNpc()
    local npcs = {}
    for _, npcConfig in pairs(self._Model:GetAllPlayerNpc()) do
        local characterId, favorLv = self:GetMaxFavorCharacter(npcConfig.CharacterId)
        local npc = {}
        npc.Config = npcConfig
        npc.CharacterId = characterId
        npc.FavorLv = favorLv
        table.insert(npcs, npc)
    end
    table.sort(npcs, function(a, b)
        if a.FavorLv ~= b.FavorLv then
            return a.FavorLv > b.FavorLv
        end
        return a.Config.Id < b.Config.Id
    end)
    return npcs
end

function XFangKuaiControl:GetMaxFavorCharacter(characterIds)
    local curCharacterId, curFavorLv
    for _, characterId in pairs(characterIds) do
        local favorLv = XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(characterId)
        if not curFavorLv or curFavorLv < favorLv then
            curFavorLv = favorLv
            curCharacterId = characterId
        end
    end
    return curCharacterId, curFavorLv
end

function XFangKuaiControl:GetCurShowNpcId()
    local key = string.format("FangKuaiNpcId_%s_%s", XPlayer.Id, self:GetActivityId())
    local npcId = XSaveTool.GetData(key) or tonumber(self._Model:GetClientConfig("DefaultNpcId", 1))
    return npcId
end

function XFangKuaiControl:GetCharacterIdByNpcId(npcId)
    local character = self._Model:GetCharacterByNpcId(npcId)
    return self:GetMaxFavorCharacter(character.CharacterId)
end

--endregion

--region 任务

function XFangKuaiControl:IsAllTaskFinish()
    local taskTimeLimitIds = self:GetActivityConfig().TaskTimeLimitIds
    for _, taskId in pairs(taskTimeLimitIds) do
        local taskDatas = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskId, false)
        for _, taskData in pairs(taskDatas) do
            if taskData.State ~= XDataCenter.TaskManager.TaskState.Finish then
                return false
            end
        end
    end
    return true
end

function XFangKuaiControl:GetTaskId(index)
    return self:GetActivityConfig().TaskTimeLimitIds[index]
end

function XFangKuaiControl:GetTaskTimeLimitId(index)
    local taskId = self:GetTaskId(index)
    return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskId, true)
end

function XFangKuaiControl:HasTaskRewardGain(index)
    local taskId = self:GetTaskId(index)
    return XDataCenter.TaskManager.CheckLimitTaskList(taskId)
end

--endregion

--region 道具

function XFangKuaiControl:AddItemId(itemId)
    return self._Item:AddItemId(itemId)
end

function XFangKuaiControl:RemoveItemId(index, isGiveUp)
    self._Item:RemoveItemId(index, isGiveUp)
end

function XFangKuaiControl:IsItemFull()
    return self:GetCurStageData():GetItemCount() >= self:GetMaxItemCount()
end

function XFangKuaiControl:GetItemFlyTime()
    return tonumber(self._Model:GetClientConfig("ItemFlyTime"))
end

function XFangKuaiControl:IsItemNeedChooseColor(itemId)
    return itemId == XEnumConst.FangKuai.ItemType.LengthReduce or itemId == XEnumConst.FangKuai.ItemType.BecomeOneGrid or
            itemId == XEnumConst.FangKuai.ItemType.Born or itemId == XEnumConst.FangKuai.ItemType.Grow
end

function XFangKuaiControl:IsItemNeedUseBtn(itemId)
    return itemId == XEnumConst.FangKuai.ItemType.AddRound or itemId == XEnumConst.FangKuai.ItemType.Frozen or
            itemId == XEnumConst.FangKuai.ItemType.RandomBlock or itemId == XEnumConst.FangKuai.ItemType.RandomLine or
            itemId == XEnumConst.FangKuai.ItemType.Convertion
end

-- 对应符合颜色的方块，长度缩减一个单位（原为1单位长度的方块则直接消除）
function XFangKuaiControl:ExecuteLengthReduce(itemIdx, color)
    self._Item:ExecuteLengthReduce(itemIdx, color)
end

-- 对应符合颜色的方块，以当前长度单位，均替换为当前同颜色类型的1单位长度方块填充
function XFangKuaiControl:ExecuteBecomeOneGrid(itemId, color, chapterId)
    self._Item:ExecuteBecomeOneGrid(itemId, color, chapterId)
end

-- 消除当行的已有方块
---@param chooseBlockData XFangKuaiBlock
function XFangKuaiControl:ExecuteSingleLineRemove(itemIdx, chooseBlockData)
    self._Item:ExecuteSingleLineRemove(itemIdx, chooseBlockData)
end

-- 选择两行并对其进行位置交换
---@param blockData1 XFangKuaiBlock
---@param blockData2 XFangKuaiBlock
function XFangKuaiControl:ExecuteTwoLineExChange(itemIdx, blockData1, blockData2)
    self._Item:ExecuteTwoLineExChange(itemIdx, blockData1, blockData2)
end

-- 点击选中某个方块，与其相邻交换位置
---@param blockData1 XFangKuaiBlock
---@param blockData2 XFangKuaiBlock
function XFangKuaiControl:ExecuteAdjacentExchange(itemIdx, blockData1, blockData2)
    self._Item:ExecuteAdjacentExchange(itemIdx, blockData1, blockData2)
end

-- 增加回合数
function XFangKuaiControl:ExecuteAddRound(itemIdx, params)
    self._Item:ExecuteAddRound(itemIdx, params)
end

-- 下回合方块不会上升
function XFangKuaiControl:ExecuteFrozen(itemIdx, chapterId)
    self._Item:ExecuteFrozen(itemIdx, chapterId)
end

-- 某行方块向左/右对齐
function XFangKuaiControl:ExecuteAlignment(itemIdx, gridY, direction, maxCount)
    self._Item:ExecuteAlignment(itemIdx, gridY, direction, maxCount)
end

-- BOSS方块转化为普通方块
function XFangKuaiControl:ExecuteConvertion(itemIdx, stageId)
    return self._Item:ExecuteConvertion(itemIdx, stageId)
end

-- 选择某个颜色 该颜色的非BOSS方块两侧会长出1长度的方块直到遇到障碍
function XFangKuaiControl:ExecuteBorn(itemIdx, color, maxX, maxY, chapterId)
    self._Item:ExecuteBorn(itemIdx, color, maxX, maxY, chapterId)
end

-- 选择某个颜色 该颜色的非BOSS方块会一直变长直到遇到障碍
function XFangKuaiControl:ExecuteGrow(itemIdx, color, params, maxX, maxY)
    self._Item:ExecuteGrow(itemIdx, color, params, maxX, maxY)
end

function XFangKuaiControl:GetItemCount(chapterId)
    local stageData = self._Model.ActivityData:GetStageData(chapterId)
    return stageData and stageData:GetItemCount() or 0
end

function XFangKuaiControl:GetCannotUseAlpha()
    return tonumber(self._Model:GetClientConfig("CannotUseAlpha"))
end

function XFangKuaiControl:GetFrozenEffectTime()
    return tonumber(self._Model:GetClientConfig("FrozenEffectTime"))
end

function XFangKuaiControl:GetStageColorIds(stageId)
    return self._Model:GetStageColorIds(stageId)
end

function XFangKuaiControl:GetRandomPropToBlock()
    return self._Model:GetClientConfigs("RandomPropToBlock")
end

function XFangKuaiControl:GetRandomPropToLine()
    return self._Model:GetClientConfigs("RandomPropToLine")
end

function XFangKuaiControl:AddFrozenRound(chapterId)
    if self:CanAddFrozenRound(chapterId) then
        local stageData = self._Model.ActivityData:GetStageData(chapterId)
        stageData:AddFrozenRound()
    end
end

function XFangKuaiControl:ReduceFrozenRound(chapterId)
    local stageData = self._Model.ActivityData:GetStageData(chapterId)
    stageData:ReduceFrozenRound()
end

function XFangKuaiControl:IsRoundFrozen(chapterId)
    local stageData = self._Model.ActivityData:GetStageData(chapterId)
    return stageData:IsRoundFrozen()
end

function XFangKuaiControl:CanAddFrozenRound(chapterId)
    local stageConfig = self:GetStageConfig(self:GetCurStageId(chapterId))
    local stageData = self._Model.ActivityData:GetStageData(chapterId)
    return stageData:GetFrozenRound() < stageConfig.MaxUseCount
end

--endregion

--region 方块属性

function XFangKuaiControl:GetBlockConfig(blockId)
    return self._Model:GetBlockConfig(blockId)
end

function XFangKuaiControl:GetAllItems()
    local stageData = self:GetCurStageData()
    return stageData and stageData:GetItems() or nil
end

function XFangKuaiControl:CheckExistItem(index)
    local itemIds = self:GetAllItems()
    return itemIds and itemIds[index]
end

---@return XTableFangKuaiBlockTexture
function XFangKuaiControl:GetBlockTextureConfig(colorId)
    return self._Model:GetBlockTextureConfig(colorId)
end

---@return XTableFangKuaiBlockTexture[]
function XFangKuaiControl:GetAllColorTextureConfigs()
    return self._Model:GetAllColorTextureConfigs()
end

--endregion

--region 方块移动

---@param block XUiGridFangKuaiBlock
function XFangKuaiControl:GetMouseClickGrid(block)
    return self._BlockMove:GetMouseClickGrid(block)
end

---@param block XUiGridFangKuaiBlock
function XFangKuaiControl:MoveX(block, gridX, updateCb, completeCb, moveTime)
    return self._BlockMove:MoveX(block, gridX, updateCb, completeCb, moveTime)
end

---@param block XUiGridFangKuaiBlock
function XFangKuaiControl:MoveY(block, gridY)
    self._BlockMove:MoveY(block, gridY)
end

---@param blockData XFangKuaiBlock
function XFangKuaiControl:GetMoveXTime(blockData, dimGridX)
    return self._BlockMove:GetMoveXTime(blockData, dimGridX)
end

function XFangKuaiControl:GetMoveYTime()
    return self._BlockMove:GetMoveYTime()
end

---@param blockData XFangKuaiBlock
function XFangKuaiControl:GetPosByBlock(blockData)
    return self._BlockMove:GetPosByBlock(blockData)
end

---@param blockData XFangKuaiBlock
function XFangKuaiControl:SignGridOccupyAuto(blockData)
    self._Game:SignGridOccupyAuto(blockData)
end

function XFangKuaiControl:GetPosByGridX(len)
    return self._BlockMove:GetPosByGridX(len)
end

function XFangKuaiControl:GetPosByGridY(len)
    return self._BlockMove:GetPosByGridY(len)
end

function XFangKuaiControl:GetBlockWarnDistance()
    return tonumber(self._Model:GetClientConfig("ShowWarnDistance"))
end

function XFangKuaiControl:GetMinShowCombo()
    return tonumber(self._Model:GetClientConfig("MinComboShow"))
end

--endregion

--region 方块表情

function XFangKuaiControl:GetBlockExpression(expression, isBoss, colorId)
    if expression == XEnumConst.FangKuai.Expression.Standby then
        local config = self._Model:GetBlockTextureConfig(colorId)
        local faceId = math.random(1, isBoss and #config.BossStandby or #config.Standby)
        return isBoss and config.BossStandby[faceId] or config.Standby[faceId]
    else
        local id = self:_GetBlockExpressionKind(expression, isBoss)
        local config = self._Model:GetBrickFaceConfig(id)
        local faceId = math.random(1, #config.FacePic)
        return config.FacePic[faceId]
    end
end

function XFangKuaiControl:_GetBlockExpressionKind(expression, isBoss)
    if expression == XEnumConst.FangKuai.Expression.Click then
        return 1
    elseif expression == XEnumConst.FangKuai.Expression.ClearUp and not isBoss then
        return 2
    elseif expression == XEnumConst.FangKuai.Expression.ClearUp and isBoss then
        return 3
    end
    XLog.Error("没找到对应的表情配置：" .. expression)
    return 1
end

--endregion

--region 关卡环境

function XFangKuaiControl:GetNewLineCount()
    return self._Enviroment:GetNewLineCount()
end

function XFangKuaiControl:ResetEnviromentParam()
    self._Enviroment:ResetParam()
end

function XFangKuaiControl:CreateDropBlockData(stageId)
    self._Enviroment:CreateDropBlockData(stageId)
end

function XFangKuaiControl:StartNextTimesBlockDrop(stageId)
    local stageData = self:GetCurStageData()
    stageData:AddDropBlockTimes()
    local config = self._Model:GetBlockDropConfig(stageId, stageData:GetDropBlockTimes() + 1)
    stageData:SetDropBlockCd(config.ActionCd)
end

--endregion

--region 分数

function XFangKuaiControl:GetComboConfigRadio(combo)
    combo = math.min(combo, self._Model:GetMaxCombo())
    return self._Model:GetComboConfig(combo).Radio
end

function XFangKuaiControl:GetScore(chapterId)
    chapterId = chapterId or self:GetCurFightChapterId()
    local stageData = self._Model.ActivityData:GetStageData(chapterId)
    return stageData and stageData:GetPoint() or 0
end

-- 历史分数
function XFangKuaiControl:GetMaxScore(stageId)
    return self._Model.ActivityData:GetMaxScore(stageId)
end

function XFangKuaiControl:IsNewRecord(score, stageId)
    return score > self:GetMaxScore(stageId)
end

function XFangKuaiControl:AddScore(blockData, waneLen)
    self._Score:AddScore(blockData, waneLen)
end

function XFangKuaiControl:AddCombo(num)
    self:GetCurStageData():AddCombo(num)
end

function XFangKuaiControl:GetComboNum()
    local stageData = self:GetCurStageData()
    return stageData and stageData:GetCombo() or 1
end

function XFangKuaiControl:ResetCombo()
    if self:GetCurStageData() then
        self:GetCurStageData():ClearCombo()
    end
end

function XFangKuaiControl:GetBlockPoint(blockType, blockLen)
    return self._Model:GetBlockPoint(blockType, blockLen)
end

--endregion

--region 结算

function XFangKuaiControl:GetCurStageSettleData()
    return self._Model.ActivityData:GetSettleData()
end

function XFangKuaiControl:GetOpenSettleDelay()
    return tonumber(self._Model:GetClientConfig("OpenSettleDelay"))
end

--endregion

--region 红点

function XFangKuaiControl:CheckTaskRedPoint()
    return self._Model:CheckTaskRedPoint()
end

function XFangKuaiControl:CheckStageRedPoint(stageId)
    return self._Model:CheckStageRedPoint(stageId)
end

function XFangKuaiControl:CheckStageGroupRedPoint(StageGroupId)
    return self._Model:CheckStageGroupRedPoint(StageGroupId)
end

function XFangKuaiControl:CheckChapterRedPoint(chapterId)
    return self._Model:CheckChapterRedPoint(chapterId)
end

function XFangKuaiControl:SaveEnterStageRecord(stageId)
    local key = string.format("FangKuaiStageRecord_%s_%s_%s", self:GetActivityId(), stageId, XPlayer.Id)
    XSaveTool.SaveData(key, true)
    self._Model:SetCurStageIdGuide(stageId)
end

function XFangKuaiControl:SaveEnterStageGroupRecord(stageGroupId)
    local key = string.format("FangKuaiStageGroupRecord_%s_%s_%s", self:GetActivityId(), stageGroupId, XPlayer.Id)
    XSaveTool.SaveData(key, true)
end

--endregion

--region 协议

---请求关卡开始
function XFangKuaiControl:FangKuaiStageStartRequest(stageId, cb)
    local npcId = self:GetCurShowNpcId()
    local characterId = self:GetCharacterIdByNpcId(npcId)
    XNetwork.CallWithAutoHandleErrorCode("FangKuaiStageStartRequest", { StageId = stageId, CharacterId = characterId }, function(res)
        self._Enviroment:InitEnviroment(stageId)
        self._Create:ReqStageStart(stageId, characterId)
        self._Enviroment:InitDropBlockEnviroment(stageId)
        self._Model.ActivityData:UpdateSettleData(nil)
        self:SetGameStage(stageId)
        if cb then
            cb()
        end
    end)
end

---同步数据给服务端校验和保存
function XFangKuaiControl:FangKuaiStageSyncOperatorRequest(stageId)
    local stageData = self:GetCurStageData()
    local operatorData = {}
    operatorData.Round = self:GetCurRound()
    operatorData.Point = self:GetScore()
    operatorData.Combo = stageData:GetHistoryMaxCombo()
    operatorData.FrozenRoundCount = stageData:GetFrozenRound()
    operatorData.FallingBlockCount = stageData:GetDropBlockTimes()
    operatorData.FallingBlockCd = stageData:GetDropBlockCd()
    operatorData.ItemOperatorList = stageData:GetCurRoundItems()
    operatorData.ComboScoreList = stageData:GetComboScoreList()
    operatorData.PreviewBlocks = self._Game:GetServerPreviewBlockMap()
    operatorData.Blocks = self._Game:GetServerBlockMap()
    stageData:ClearRoundItemData()
    stageData:ClearComboScoreList()
    XNetwork.CallWithAutoHandleErrorCode("FangKuaiStageSyncOperatorRequest", { StageId = stageId, OperatorData = operatorData })
end

---请求关卡结算
function XFangKuaiControl:FangKuaiStageSettleRequest(stageId, settleType, cb, isCloseTc)
    if isCloseTc then
        XLuaUiManager.Close("UiFangKuaiTc")
    end
    XNetwork.CallWithAutoHandleErrorCode("FangKuaiStageSettleRequest", { StageId = stageId, SettleType = settleType }, function(res)
        self._Model.ActivityData:UpdateSettleData(res.SettleData, stageId)
        self:ClearFightData(stageId)
        if cb then
            cb()
        end
    end)
end

--endregion

--region 埋点

function XFangKuaiControl:RecordStage(uiType, buttonType, stageId)
    local chapterId = self:GetChapterIdByStage(stageId)
    local dir = {}
    dir["ui_type"] = uiType
    dir["button_type"] = buttonType
    dir["chapter_id"] = stageId
    dir["use_round"] = self:GetCurRound(chapterId)
    dir["get_score"] = self:GetScore(chapterId)
    CS.XRecord.Record(dir, "900003", "FangKuaiClientRecord")
end

--endregion

--region 音效

function XFangKuaiControl:PlayComboSound(combo)
    local cueIds = self._Model:GetClientConfigs("ComboCueId")
    local index = math.min(#cueIds, combo)
    local cueId = tonumber(cueIds[index])
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
end

function XFangKuaiControl:PlayClickSound()
    local cueId = tonumber(self._Model:GetClientConfig("ClickCueId"))
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
end

function XFangKuaiControl:PlayDropSound()
    local cueId = tonumber(self._Model:GetClientConfig("DropCueId"))
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
end

function XFangKuaiControl:PlayUseItemSound()
    local cueId = tonumber(self._Model:GetClientConfig("UseItemCueId"))
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
end

function XFangKuaiControl:PlaySettleSound(stageId, score)
    local grade = self._Model:GetScoreGrade(stageId, score)
    local cueId = tonumber(self._Model:GetClientConfig("SettleCueId", grade == 6 and 1 or 2))
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
end

--endregion

--region 校验

function XFangKuaiControl:CheckStageDataError(data)
    local chapterId = self:GetChapterIdByStage(data.StageId)
    self._Model.ActivityData:UpdateRecordStageData(chapterId, data)
    if self._Game then
        self._Game:ResetFromService()
        XLog.Error(string.format("重置错误关卡%s数据", data.StageId))
    end
end

--endregion

--region

function XFangKuaiControl:GetSingleLineRemoveEffect(isBigMap)
    return self._Model:GetClientConfig("SingleLineRemoveEffect", isBigMap and 2 or 1)
end

function XFangKuaiControl:GetFrozenCreateEffect(isBigMap)
    return self._Model:GetClientConfig("FrozenCreateEffect", isBigMap and 2 or 1)
end

function XFangKuaiControl:GetFrozenKeepEffect(isBigMap)
    return self._Model:GetClientConfig("FrozenKeepEffect", isBigMap and 2 or 1)
end

function XFangKuaiControl:GetFrozenRemoveEffect(isBigMap)
    return self._Model:GetClientConfig("FrozenRemoveEffect", isBigMap and 2 or 1)
end

--endregion

return XFangKuaiControl