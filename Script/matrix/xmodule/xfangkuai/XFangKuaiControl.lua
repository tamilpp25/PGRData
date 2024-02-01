---@class XFangKuaiControl : XControl
---@field private _Model XFangKuaiModel
---@field private _BlockMove XFangKuaiMove 移动模块
---@field private _Game XFangKuaiGame 大方块主逻辑
---@field private _Item XFangKuaiItem 道具模块
---@field private _Enviroment XFangKuaiEnviroment 关卡环境模块
---@field private _Score XFangKuaiScore 计分模块
local XFangKuaiControl = XClass(XControl, "XFangKuaiModelControl")

function XFangKuaiControl:OnInit()
    self._BlockMove = self:AddSubControl(require("XModule/XFangKuai/XSubControl/XFangKuaiMove"))
    self._Item = self:AddSubControl(require("XModule/XFangKuai/XSubControl/XFangKuaiItem"))
    self._Enviroment = self:AddSubControl(require("XModule/XFangKuai/XSubControl/XFangKuaiEnviroment"))
    self._Score = self:AddSubControl(require("XModule/XFangKuai/XSubControl/XFangKuaiScore"))
    self._Game = self:AddSubControl(require("XModule/XFangKuai/XSubControl/XFangKuaiGame"))
end

function XFangKuaiControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XFangKuaiControl:RemoveAgencyEvent()

end

function XFangKuaiControl:OnRelease()

end

--region 主逻辑

function XFangKuaiControl:EnterGame(stageId, isNewGame)
    -- 两个模式有两个关卡记录
    local chapterId = self:GetChapterIdByStage(stageId)
    if self._Game:GetCurFightChapterId() ~= chapterId then
        self:SetGameStage(stageId, chapterId)
    end
    XLuaUiManager.Open("UiFangKuaiFight", self._Game, isNewGame)
end

function XFangKuaiControl:SetGameStage(stageId, chapterId)
    self._Score:InitData()
    self._Game:InitData()
    self:ResetScore(chapterId)
    self._Game:SetStage(stageId)
end

function XFangKuaiControl:RestartGame(stageId, cb)
    self:RecordStage(XEnumConst.FangKuai.RecordUiType.Fight, XEnumConst.FangKuai.RecordButtonType.Reset, stageId)
    if self:IsStageFinished() then
        self:ClearFightData(stageId)
        self:FangKuaiStageStartRequest(stageId, cb)
        return
    end
    self:FangKuaiStageSettleRequest(stageId, function()
        self:FangKuaiStageStartRequest(stageId, cb)
    end)
end

function XFangKuaiControl:GetBlockMap()
    return self._Game:GetBlockMap()
end

function XFangKuaiControl:AddOperate(operate, args)
    self._Game:AddOperate(operate, args)
end

function XFangKuaiControl:GetLayerBlocks(gridY)
    return self._Game:GetLayerBlocks(gridY)
end

---@param data XFangKuaiBlock
---@return XFangKuaiBlock
function XFangKuaiControl:CreateCopyBlockData(index, len, pos, data, itemId, chapterId)
    ---@type XFangKuaiBlock
    local blockData = require("XUi/XUiFangKuai/XEntity/XFangKuaiBlock").New(self)
    local lastId = self._Model.ActivityData:GetLastBlockId(chapterId)
    blockData:CopyBlockData(lastId + index, len, pos, data, itemId)
    return blockData
end

function XFangKuaiControl:CreateBlockDataByService(stageId, serviceData)
    ---@type XFangKuaiBlock
    local blockData = require("XUi/XUiFangKuai/XEntity/XFangKuaiBlock").New(self)
    blockData:InitData(stageId, serviceData)
    return blockData
end

function XFangKuaiControl:IsDebug()
    if XMain.IsWindowsEditor then
        return XSaveTool.GetData("FangKuai_Debug")
    end
    return false
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
    return self._Model.ActivityData:GetCurStageId(chapterId)
end

function XFangKuaiControl:GetAllBlocks(chapterId)
    return self._Model.ActivityData:GetAllBlocks(chapterId)
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
    local isNormal = self:IsStageNormal(stageId)
    local activity = self:GetActivityConfig()
    return isNormal and activity.ChapterIds[1] or activity.ChapterIds[2]
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
function XFangKuaiControl:IsPreStagePass(stageId)
    local preStageId = self._Model:GetStageConfig(stageId).PreStageId
    local condStr = XTool.IsNumberValid(preStageId) and
            XUiHelper.GetText("FangKuaiPreStageLock", self._Model:GetStageConfig(preStageId).Name) or ""
    return self._Model:IsPreStagePass(stageId), condStr
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
    local chapterId = self:GetChapterIdByStage(stageId)
    return self:GetCurStageId(chapterId) == stageId
end

function XFangKuaiControl:IsOtherPlaying(stageId)
    local chapterId = self:GetChapterIdByStage(stageId)
    local curStageId = self:GetCurStageId(chapterId)
    return XTool.IsNumberValid(curStageId) and curStageId ~= stageId
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
    return self._Model:CheckStageDifficulty(self:GetActivityId(), stageId) == 1
end

---@return XTableFangKuaiItem
function XFangKuaiControl:GetItemConfig(itemId)
    return self._Model:GetItemConfig(itemId)
end

---获取服务端回合数
function XFangKuaiControl:GetCurRound(chapterId)
    return self._Model.ActivityData:GetCurRound(chapterId)
end

---获取客户端回合数（做完表现回合数才会+1）
function XFangKuaiControl:GetClientRound()
    return self._Game:GetRound()
end

function XFangKuaiControl:GetExtraRound(chapterId)
    return self._Model.ActivityData:GetExtraRound(chapterId)
end

---@return XTableFangKuaiStageEnvironment
function XFangKuaiControl:GetEnvironmentConfig(id)
    return self._Model:GetEnvironmentConfig(id)
end

function XFangKuaiControl:ClearFightData(stageId)
    local chapterId = self:GetChapterIdByStage(stageId)
    if self._Game:GetCurFightChapterId() == chapterId then
        self._Game:InitData()
        self._Score:InitData()
    end

    if XTool.IsNumberValid(stageId) then
        self._Model.ActivityData:ClearStageData(chapterId)
    else
        self._Model.ActivityData:ClearStageData()
    end
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

function XFangKuaiControl:GetItemFlyTime()
    return tonumber(self._Model:GetClientConfig("ItemFlyTime"))
end

function XFangKuaiControl:IsItemNeedChooseColor(itemId)
    return itemId == XEnumConst.FangKuai.ItemType.LengthReduce or itemId == XEnumConst.FangKuai.ItemType.BecomeOneGrid
end

function XFangKuaiControl:IsItemAddRound(itemId)
    return itemId == XEnumConst.FangKuai.ItemType.AddRound
end

-- 对应符合颜色的方块，长度缩减一个单位（原为1单位长度的方块则直接消除）
function XFangKuaiControl:ExecuteLengthReduce(itemIdx, color, chapterId)
    self._Item:ExecuteLengthReduce(itemIdx, color, chapterId)
end

-- 对应符合颜色的方块，以当前长度单位，均替换为当前同颜色类型的1单位长度方块填充
function XFangKuaiControl:ExecuteBecomeOneGrid(itemId, color, chapterId)
    self._Item:ExecuteBecomeOneGrid(itemId, color, chapterId)
end

-- 消除当行的已有方块
---@param chooseBlockData XFangKuaiBlock
function XFangKuaiControl:ExecuteSingleLineRemove(itemIdx, chooseBlockData, chapterId)
    self._Item:ExecuteSingleLineRemove(itemIdx, chooseBlockData, chapterId)
end

-- 选择两行并对其进行位置交换
---@param blockData1 XFangKuaiBlock
---@param blockData2 XFangKuaiBlock
function XFangKuaiControl:ExecuteTwoLineExChange(itemIdx, blockData1, blockData2, chapterId)
    self._Item:ExecuteTwoLineExChange(itemIdx, blockData1, blockData2, chapterId)
end

-- 点击选中某个方块，与其相邻交换位置
---@param blockData1 XFangKuaiBlock
---@param blockData2 XFangKuaiBlock
function XFangKuaiControl:ExecuteAdjacentExchange(itemIdx, blockData1, blockData2, chapterId)
    self._Item:ExecuteAdjacentExchange(itemIdx, blockData1, blockData2, chapterId)
end

-- 增加回合数
function XFangKuaiControl:ExecuteAddRound(itemIdx, chapterId)
    self._Item:ExecuteAddRound(itemIdx, chapterId)
end

function XFangKuaiControl:GetItemCount(chapterId)
    local items = self._Model.ActivityData:GetItemIds(chapterId)
    return items and #items or 0
end

function XFangKuaiControl:GetCannotUseAlpha()
    return tonumber(self._Model:GetClientConfig("CannotUseAlpha"))
end

function XFangKuaiControl:GetStageColorIds(stageId)
    return self._Model:GetStageColorIds(stageId)
end

--endregion

--region 方块属性

function XFangKuaiControl:GetBlockConfig(blockId)
    return self._Model:GetBlockConfig(blockId)
end

---@return XTableFangKuaiItem[]
function XFangKuaiControl:GetAllItems(chapterId)
    local datas = {}
    local items = self._Model.ActivityData:GetItemIds(chapterId)
    if items then
        for _, itemId in pairs(items) do
            table.insert(datas, self:GetItemConfig(itemId))
        end
    end
    return datas
end

function XFangKuaiControl:CheckExistItem(index, chapterId)
    local itemIds = self._Model.ActivityData:GetItemIds(chapterId)
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

function XFangKuaiControl:InitEnviroment(enviromentId)
    self._Enviroment:InitEnviroment(enviromentId)
end

function XFangKuaiControl:GetNewLineCount()
    return self._Enviroment:GetNewLineCount()
end

function XFangKuaiControl:ResetEnviromentParam()
    self._Enviroment:ResetParam()
end

--endregion

--region 分数

function XFangKuaiControl:GetComboConfigRadio(combo)
    combo = math.min(combo, self._Model:GetMaxCombo())
    return self._Model:GetComboConfig(combo).Radio
end

-- 游戏进行时的分数（客户端自己计算）
function XFangKuaiControl:GetScore()
    return self._Score:GetScore()
end

-- 当前回合分数（服务端下发）
function XFangKuaiControl:GetCurRoundScore(chapterId)
    return self._Model.ActivityData:GetCurStageScore(chapterId)
end

-- 历史分数
function XFangKuaiControl:GetStageRecordScore(stageId)
    return self._Model.ActivityData:GetStageRecordScore(stageId)
end

function XFangKuaiControl:IsNewRecord(score, stageId)
    return score > self:GetStageRecordScore(stageId)
end

function XFangKuaiControl:AddScore(blockData, waneLen)
    self._Score:AddScore(blockData, waneLen)
end

function XFangKuaiControl:AddCombo(num)
    self._Score:AddCombo(num)
end

function XFangKuaiControl:GetComboNum()
    return self._Score:GetComboNum()
end

function XFangKuaiControl:ResetCombo()
    self._Score:ResetCombo()
end

function XFangKuaiControl:ResetScore(chapterId)
    self._Score:ResetScore(chapterId)
end

function XFangKuaiControl:GetBlockPoint(blockType, blockLen)
    return self._Model:GetBlockPoint(blockType, blockLen)
end

--endregion

--region 结算

function XFangKuaiControl:GetCurStageSettleData()
    return self._Model.ActivityData:GetSettleData()
end

function XFangKuaiControl:IsStageFinished()
    return self._Model.ActivityData:IsStageFinished()
end

function XFangKuaiControl:GetOpenSettleDelay()
    return tonumber(self._Model:GetClientConfig("OpenSettleDelay"))
end

--endregion

--region 红点

function XFangKuaiControl:CheckTaskRedPoint()
    return self._Model:CheckTaskRedPoint()
end

function XFangKuaiControl:CheckAllChapterRedPoint()
    return self._Model:CheckAllChapterRedPoint()
end

function XFangKuaiControl:CheckChapterRedPoint(difficulty)
    return self._Model:CheckChapterRedPoint(difficulty)
end

function XFangKuaiControl:CheckStageRedPoint(stageId)
    return self._Model:CheckStageRedPoint(stageId)
end

function XFangKuaiControl:SaveEnterStageRecord(stageId)
    local key = string.format("FangKuaiStageRecord_%s_%s", self:GetActivityId(), stageId)
    XSaveTool.SaveData(key, true)
end

--endregion

--region 协议

---请求关卡开始
function XFangKuaiControl:FangKuaiStageStartRequest(stageId, cb)
    local npcId = self:GetCurShowNpcId()
    local characterId = self:GetCharacterIdByNpcId(npcId)
    XNetwork.CallWithAutoHandleErrorCode("FangKuaiStageStartRequest", { StageId = stageId, CharacterId = characterId }, function(res)
        self._Model.ActivityData:UpdateSettleData(nil)
        self._Model.ActivityData:UpdateStageData(res.ChapterId, res.StageData)
        self:SetGameStage(stageId, res.ChapterId)
        if cb then
            cb(res.StageData)
        end
    end)
end

---请求关卡结算（主动放弃）
function XFangKuaiControl:FangKuaiStageSettleRequest(stageId, cb)
    local chapterId = self:GetChapterIdByStage(stageId)
    XNetwork.CallWithAutoHandleErrorCode("FangKuaiStageSettleRequest", { ChapterId = chapterId }, function(res)
        self._Model.ActivityData:UpdateSettleData(res.SettleData, stageId)
        self:ClearFightData(stageId)
        if cb then
            cb()
        end
    end)
end

---请求方块移动
function XFangKuaiControl:FangKuaiBlockMoveRequest(chapterId, id, targetX)
    XNetwork.CallWithAutoHandleErrorCode("FangKuaiBlockMoveRequest", { ChapterId = chapterId, Id = id, TargetX = targetX }, function(res)
        self._Model.ActivityData:UpdateSettleData(res.SettleData)
        self._Model.ActivityData:UpdateStageData(chapterId, res.StageData)
        if self._Model.ActivityData:IsStageFinished() then
            XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_GAMEOVER)
        elseif self:GetClientRound() == self:GetCurRound(chapterId) then
            self._Game:UpdateBlockData()
        end
    end)
end

---请求道具使用
function XFangKuaiControl:FangKuaiItemUseRequest(chapterId, itemId, params)
    XNetwork.CallWithAutoHandleErrorCode("FangKuaiItemUseRequest", { ChapterId = chapterId, ItemIdx = itemId, Params = params }, function(res)
        self._Model.ActivityData:UpdateSettleData(res.SettleData)
        self._Model.ActivityData:UpdateStageData(chapterId, res.StageData)
        if self._Model.ActivityData:IsStageFinished() then
            XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_GAMEOVER)
        end
        self:PlayUseItemSound()
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
    dir["get_score"] = self:GetCurRoundScore(chapterId)
    CS.XRecord.Record(dir, "900003", "FangKuaiClientRecord")
end

--endregion

--region 音效

function XFangKuaiControl:PlayComboSound(combo)
    local cueIds = self._Model:GetClientConfigs("ComboCueId")
    local index = math.min(#cueIds, combo)
    local cueId = tonumber(cueIds[index])
    XSoundManager.PlaySoundByType(cueId, XSoundManager.SoundType.Sound)
end

function XFangKuaiControl:PlayClickSound()
    local cueId = tonumber(self._Model:GetClientConfig("ClickCueId"))
    XSoundManager.PlaySoundByType(cueId, XSoundManager.SoundType.Sound)
end

function XFangKuaiControl:PlayDropSound()
    local cueId = tonumber(self._Model:GetClientConfig("DropCueId"))
    XSoundManager.PlaySoundByType(cueId, XSoundManager.SoundType.Sound)
end

function XFangKuaiControl:PlayUseItemSound()
    local cueId = tonumber(self._Model:GetClientConfig("UseItemCueId"))
    XSoundManager.PlaySoundByType(cueId, XSoundManager.SoundType.Sound)
end

--endregion

return XFangKuaiControl