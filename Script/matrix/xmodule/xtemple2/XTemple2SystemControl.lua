local XTemple2Enum = require("XModule/XTemple2/XTemple2Enum")

---@class XTemple2SystemControl : XControl
---@field private _Model XTemple2Model
---@field private _MainControl XTemple2Control
local XTemple2SystemControl = XClass(XControl, "XTemple2SystemControl")

function XTemple2SystemControl:OnInit()
    self._UiData = {
        ---@type XUiTemple2MainGridData[]
        Chapter = {},
        ---@type XUiTemple2ChapterGridData[]
        Stage = {},
        ---@type XTemple2SystemControlStageDetail
        StageDetail = {},
        Story = {
            ---@type XUiTemple2StoryGridData[]
            List = false,
            Progress = false,
        },
    }

    ---@type XUiTemple2MainGridData
    self._CurrentChapterData = false
    ---@type XUiTemple2ChapterGridData
    self._CurrentStageData = false
    self._IsChapterDirty = false
    self._IsStageDirty = false

    ---@type XUiTemple2PopupChapterDetailGridData
    self._SelectedCharacter = false
    ---@type XUiTemple2StoryGridData
    self._SelectedStory = false
end

function XTemple2SystemControl:OnRelease()
    --do nothing
end

function XTemple2SystemControl:GetDataChapter()
    return self._UiData.Chapter
end

function XTemple2SystemControl:UpdateChapter()
    local allChapterConfig = self._Model:GetAllChapter()

    -- const
    if #self._UiData.Chapter == 0 then
        ---@type XTable.XTableTemple2Chapter[]
        for i = 1, #allChapterConfig do
            local chapterConfig = allChapterConfig[i]
            ---@class XUiTemple2MainGridData
            local data = self._UiData.Chapter[i]
            if not data then
                data = {}
                self._UiData.Chapter[i] = data
            end
            data.Id = chapterConfig.Id
            data.Name = chapterConfig.Name
            data.IsUnlock = false
            data.StageList = chapterConfig.StageIds
            data.Index = i
            data.LockReason = false
        end
    end

    for i = 1, #self._UiData.Chapter do
        local chapterConfig = allChapterConfig[i]
        local timerId = chapterConfig.TimeId
        local isUnlock = XFunctionManager.CheckInTimeByTimeId(timerId)
        local data = self._UiData.Chapter[i]
        data.IsUnlock = isUnlock
        if not isUnlock then
            local currentTime = XTime.GetServerNowTimestamp()
            local endTime = XFunctionManager.GetEndTimeByTimeId(timerId)
            if currentTime > endTime then
                data.LockReason = XUiHelper.GetText("ActivityShortStoryChapterEnd")
            else
                local startTime = XFunctionManager.GetStartTimeByTimeId(timerId)
                local remainTime = startTime - currentTime
                remainTime = math.max(remainTime, 0)
                data.LockReason = XUiHelper.GetText("Temple2ChapterStart", XUiHelper.GetTime(remainTime))
            end
        end
    end
end

---@param data XUiTemple2MainGridData
function XTemple2SystemControl:SetCurrentChapter(data)
    if not self._CurrentChapterData or data.Id ~= self._CurrentChapterData.Id then
        self._IsChapterDirty = true
    end
    self._CurrentChapterData = data
end

function XTemple2SystemControl:GetCurrentChapterIndex()
    if self._CurrentChapterData then
        return self._CurrentChapterData.Index
    end
    return 1
end

function XTemple2SystemControl:GetRemainTime()
    local remainTime = self._Model:GetRemainTime()
    local text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
    return text
end

function XTemple2SystemControl:UpdateStage()
    local chapterData = self._CurrentChapterData
    if not chapterData then
        XLog.Error("[XTemple2SystemControl] 没有选章节，怎么进入关卡选择的？")
        return
    end
    local stageDataList = self._UiData.Stage
    if self._IsChapterDirty then
        self._IsChapterDirty = false
        local stageList = chapterData.StageList
        for i = 1, #stageList do
            local stageId = stageList[i]
            ---@type XTable.XTableTemple2Stage
            local stageConfig = self._Model:GetStageConfig(stageId)
            ---@class XUiTemple2ChapterGridData
            local data = stageDataList[i]
            if not data then
                data = {}
                stageDataList[i] = data
            end
            data.Name = stageConfig.Name
            data.Id = stageId
            data.IsOngoing = false
            data.IsUnlock = false
        end
        for i = #stageList + 1, #stageDataList do
            stageDataList[i] = nil
        end
    end

    local stageOngoing = self._Model:GetStageOngoing()
    --local isFind = false
    for i = 1, #stageDataList do
        local stageData = stageDataList[i]
        if stageOngoing == stageData.Id then
            stageData.IsOngoing = true
            --isFind = true
        else
            stageData.IsOngoing = false
        end
        stageData.IsUnlock = self._Model:IsStageUnlock(stageData.Id)
    end
    --if stageOngoing and not isFind then
    --    XLog.Debug("[XTemple2SystemControl] 你有一个进行中的关卡记录, 但是这一关在这一章找不到:" .. stageOngoing)
    --end
end

function XTemple2SystemControl:GetDataStage()
    return self._UiData.Stage
end

---@param data XUiTemple2ChapterGridData
function XTemple2SystemControl:GiveUpOngoingStage(data)
    XMVCA.XTemple2:Temple2ResetRequest(data.Id, true)
end

---@param data XUiTemple2ChapterGridData
function XTemple2SystemControl:OpenStageDetail(data)
    if not data.IsUnlock then
        --XUiManager.TipText("Temple2PreStage")
        local _, reason = self._Model:IsStageUnlock(data.Id, true)
        if reason then
            XUiManager.TipMsg(reason)
        end
        return
    end
    local stageRecord = self._Model:GetStageRecordOngoing()
    if stageRecord and stageRecord.StageId ~= 0 then
        if stageRecord.StageId ~= data.Id then
            XUiManager.TipText("Temple2StageOngoing")
            return
        end
        self._MainControl:OpenGame(stageRecord.StageId, stageRecord.CharacterId)
        return
    end
    self:SetCurrentStage(data)
    XLuaUiManager.Open("UiTemple2PopupChapterDetail")
end

---@param data XUiTemple2ChapterGridData
function XTemple2SystemControl:SetCurrentStage(data)
    if not self._CurrentStageData or data.Id ~= self._CurrentStageData.Id then
        self._IsStageDirty = true
    end
    self._CurrentStageData = data
end

function XTemple2SystemControl:UpdateStageDetail()
    local stageData = self._CurrentStageData
    if not stageData then
        XLog.Error("[XTemple2SystemControl] 没有选章节，怎么进入关卡选择的？")
        return
    end
    ---@class XTemple2SystemControlStageDetail
    local stageDetail = self._UiData.StageDetail
    local stageId = stageData.Id
    if self._IsStageDirty then
        self._IsStageDirty = false
        local stageConfig = self._Model:GetStageConfig(stageId)
        stageDetail.Name = stageConfig.Name
        stageDetail.Desc = stageConfig.Desc
    end

    ---@type XUiTemple2PopupChapterDetailGridData[]
    local characterDataList = {}
    ---@type XUiTemple2PopupChapterDetailGridData[]
    stageDetail.CharacterList = characterDataList
    local allCharacter = self._Model:GetAllCharacter()

    local characterList = self._Model:GetCharacterToday()
    local dictCharacter = {}
    if characterList then
        for i = 1, #characterList do
            local characterId = characterList[i]
            dictCharacter[characterId] = true
        end
    end

    if allCharacter then
        for id, config in pairs(allCharacter) do
            ---@class XUiTemple2PopupChapterDetailGridData
            local data = {
                Name = config.Name,
                Desc = config.Text,
                Head = config.Head,
                Icon = config.Icon,
                Id = config.Id,
                IsSelected = false,
                IsUnlock = dictCharacter[id]
            }
            characterDataList[#characterDataList + 1] = data
        end
        table.sort(characterDataList, function(a, b)
            return a.Id < b.Id
        end)
    else
        XLog.Error("[XTemple2SystemControl] 服务端给的角色列表为空")
    end

    if not self._SelectedCharacter then
        local lastSelected = XSaveTool.GetData("XTemple2SelectedCharacter")
        if lastSelected then
            for i = 1, #characterDataList do
                local data = characterDataList[i]
                if data.Id == lastSelected then
                    if data.IsUnlock then
                        self._SelectedCharacter = data
                    end
                    break
                end
            end
        end

        if not self._SelectedCharacter then
            for i = 1, #characterDataList do
                local data = characterDataList[i]
                if data.IsUnlock then
                    self._SelectedCharacter = data
                    break
                end
            end
        end
    end

    ---@type XUiTemple2PopupChapterDetailGridData
    local selectedCharacter
    for i = 1, #characterDataList do
        local character = characterDataList[i]
        local isSelected = false
        if self._SelectedCharacter then
            if self._SelectedCharacter.Id == character.Id then
                isSelected = true
            end
        end
        character.IsSelected = isSelected
        if character.IsSelected then
            selectedCharacter = character
        end
    end
    stageDetail.SelectedCharacter = selectedCharacter
    stageDetail.HistoryScore = self._Model:GetHistoryScore(stageId)
end

function XTemple2SystemControl:GetDataStageDetail()
    return self._UiData.StageDetail
end

function XTemple2SystemControl:StartGame()
    local stage = self._CurrentStageData
    if not stage then
        XLog.Error("[XTemple2SystemControl] 未设置当前关卡")
        return
    end
    local character = self._SelectedCharacter
    if not character then
        XLog.Error("[XTemple2SystemControl] 未设置当前角色")
        return
    end
    local startType = XTemple2Enum.START_TYPE.NORMAL
    XMVCA.XTemple2:Temple2StartRequest(stage.Id, character.Id, startType, function()
        XLuaUiManager.Close("UiTemple2PopupChapterDetail")
        self._MainControl:GetGameControl():SetModeScore(false)
        self._MainControl:OpenGame(stage.Id, character.Id)
        -- 关闭详情界面，防止重新调用start，和设置角色
    end)
end

---@param data XUiTemple2PopupChapterDetailGridData
function XTemple2SystemControl:SetSelectedCharacter(data)
    if data.IsUnlock then
        self._SelectedCharacter = data
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_UPDATE_NPC_LIST)
        XSaveTool.SaveData("XTemple2SelectedCharacter", data.Id)
    end
end

function XTemple2SystemControl:GetDataStory()
    local storyData = self._UiData.Story.List
    if not storyData then
        storyData = {}
        self._UiData.Story.List = storyData
        local allStory = self._Model:GetAllStory()
        for i = 1, #allStory do
            ---@type XTable.XTableTemple2Bubble
            local config = allStory[i]
            ---@class XUiTemple2StoryGridData
            local data = {
                Desc = config.Desc,
                Icon = config.CharacterIcon,
                Id = config.StoryId,
                BubbleId = config.Id,
                StoryDescSimple = config.StoryDescSimple,
                StoryDesc = config.StoryDesc,
                StoryTitle = config.StoryTitle,
                IsSelected = false,
                IsUnlock = false,
            }
            storyData[#storyData + 1] = data
        end
        table.sort(storyData, function(a, b)
            return a.Id < b.Id
        end)
    end
    for i = 1, #self._UiData.Story.List do
        local data = storyData[i]
        local isSelected = false
        if self._SelectedStory then
            isSelected = data.Id == self._SelectedStory.Id
        end
        data.IsSelected = isSelected
    end
    local amount = 0
    local totalAmount = #self._UiData.Story.List
    for i = 1, totalAmount do
        local data = storyData[i]
        if self._Model:IsStoryUnlock(data.BubbleId) then
            amount = amount + 1
            data.IsUnlock = true
        else
            data.IsUnlock = false
        end
    end
    self._UiData.Story.Progress = amount .. "/" .. totalAmount
    return self._UiData.Story.List
end

function XTemple2SystemControl:SetSelectedStory(data)
    self._SelectedStory = data
end

function XTemple2SystemControl:PlayHistory()
    local stage = self._CurrentStageData
    if not stage then
        XLog.Error("[XTemple2SystemControl] 未设置当前关卡")
        return
    end
    local stageId = stage.Id
    local history = self._Model:GetHistory(stageId)
    if not history then
        XUiManager.TipText("Temple2NoRecord")
        return
    end
    local startType = XTemple2Enum.START_TYPE.HISTORY
    XMVCA.XTemple2:Temple2StartRequest(stage.Id, history.CharacterId, startType, function()
        XLuaUiManager.Close("UiTemple2PopupChapterDetail")
        self._MainControl:OpenGame(stage.Id, history.CharacterId)
        -- 关闭详情界面，防止重新调用start，和设置角色
    end)

    --local stage = self._CurrentStageData
    --if not stage then
    --    XLog.Error("[XTemple2SystemControl] 未设置当前关卡")
    --    return
    --end
    --local stageId = stage.Id
    --local history = self._Model:GetHistory(stageId)
    --local mapId = stageId
    --if history then
    --    if history.MapId and history.MapId ~= 0 then
    --        mapId = history.MapId
    --    else
    --        XLog.Error("[XTemple2SystemControl] 历史记录里还没有mapId, 暂时用stageId代替")
    --    end
    --end
    --
    --local gameControl = self._MainControl:GetGameControl()
    --local isSuccess = gameControl:SetSelectedStage({
    --    StageId = stageId,
    --    MapId = mapId,
    --    Seed = history and history.StartTime
    --})
    --if isSuccess and history then
    --    gameControl:SetNpcId(history.CharacterId)
    --    gameControl:RestoreRecord(history)
    --    XLuaUiManager.Open("UiTemple2GameReplay")
    --end
end

function XTemple2SystemControl:GetDataStageDetailOfBlock()
    if not self._CurrentStageData then
        return {}
    end
    local stageId = self._CurrentStageData.Id
    if not stageId then
        return {}
    end

    local allMap = self._Model:GetAllRandomMap(stageId)

    -- 收集用到的所有格子
    ---@type XTable.XTableTemple2Grid[]
    local usedGrids = {}

    local favouriteGrids = {}

    ---@type XTemple2Game
    local game = require("XModule/XTemple2/Game/XTemple2Game").New()

    game:SetNpcId(self._SelectedCharacter.Id)
    if #game:GetAllBlock() == 0 then
        local allBlockConfigs = self._Model:GetAllBlocks()
        if allBlockConfigs then
            game:InitBlocks(allBlockConfigs, self._Model)
        end
    end

    for mapId, _ in pairs(allMap) do

        ---@type XTable.XTableTemple2Stage
        local config = self._Model:GetStageGameConfig(mapId)
        if config then
            local mapConfig = self._Model:GetMapConfig(mapId)
            game:InitGame(config, self._Model, mapConfig)
        end

        ---@type XTable.XTableTemple2StageGame[]
        local stageGameConfig = self._Model:GetStageGameConfig(mapId)
        if not stageGameConfig then
            return {}
        end

        local debugStr
        if XMain.IsEditorDebug then
            debugStr = "[XTemple2SystemControl] 根据角色喜好, 过滤掉了地块:"
        end
        local pool = game:GetBlockPool()
        for i = 1, #pool do
            local block = pool[i]
            if block:CheckIsSelected4FavouriteRule(game, self._Model) then
                game:_FindBlockUsedGrids(block, usedGrids, self._Model, favouriteGrids)
            elseif XMain.IsEditorDebug then
                debugStr = debugStr .. block:GetName() .. "|" .. (block:GetNpcId() or "") .. ","
            end
        end

        local randomPool = game:GetBlockRandomPool()
        for i = 1, #randomPool do
            local block = randomPool[i]
            if block:CheckIsSelected4FavouriteRule(game, self._Model) then
                game:_FindBlockUsedGrids(block, usedGrids, self._Model, favouriteGrids)
            elseif XMain.IsEditorDebug then
                debugStr = debugStr .. block:GetName() .. "|" .. (block:GetNpcId() or "") .. ","
            end
        end
        if XMain.IsEditorDebug then
            XLog.Debug(debugStr)
        end

        -- 收集地图上所有格子
        --for id, config in pairs(stageGameConfig) do
        --    self:_FindGridIcon(config.Map, usedGrids)
        --end

        -- 收集地块所有格子
        --local blocks = {}
        -----@type XTable.XTableTemple2StageGame
        --local firstLine = stageGameConfig[1]-- 因为只存在第一行
        --for i = 1, #firstLine.BlockPool do
        --    local id = firstLine.BlockPool[i]
        --    blocks[id] = true
        --end
        --for i = 1, #firstLine.RandomBlockPool do
        --    local id = firstLine.RandomBlockPool[i]
        --    blocks[id] = true
        --end
        --for blockId, _ in pairs(blocks) do
        --    ---@type XTable.XTableTemple2Block
        --    local blockConfig = self._Model:GetBlock(blockId)
        --    if blockConfig then
        --        self:_FindGridIcon(blockConfig.Grid1, usedGrids)
        --        self:_FindGridIcon(blockConfig.Grid2, usedGrids)
        --        self:_FindGridIcon(blockConfig.Grid3, usedGrids)
        --    end
        --end
    end

    local result = {}
    for gridId, gridConfig in pairs(usedGrids) do
        if gridConfig then
            ---@class XUiTemple2PopupChapterDetailGridBlockData
            local data = {
                Name = gridConfig.Name,
                Desc = XUiHelper.ReplaceTextNewLine(gridConfig.Desc),
                Icon = gridConfig.Icon,
                Id = gridId,
                IsFavourite = favouriteGrids[gridId]
            }
            result[#result + 1] = data
        end
    end
    ---@param a XUiTemple2PopupChapterDetailGridBlockData
    ---@param b XUiTemple2PopupChapterDetailGridBlockData
    table.sort(result, function(a, b)
        if a.IsFavourite ~= b.IsFavourite then
            return a.IsFavourite
        end
        return a.Id > b.Id
    end)
    return result
end

function XTemple2SystemControl:_FindGridIcon(grids, result)
    for i = 1, #grids do
        local gridId = grids[i]
        if result[gridId] == nil then
            ---@type XTable.XTableTemple2Grid
            local gridConfig = self._Model:GetGrid(gridId)
            if gridConfig and gridConfig.ShowOnStageDetail == 1 then
                result[gridId] = gridConfig
            else
                result[gridId] = false
            end
        end
    end
end

---@param block XTemple2Block
function XTemple2SystemControl:_FindBlockUsedGrids(block, result, favouriteGrids)
    local row = block:GetRowAmount()
    local column = block:GetColumnAmount()
    for y = 1, column do
        for x = 1, row do
            local grid = block:GetGrid(x, y)
            local gridId = grid:GetId()
            if result[gridId] == nil then
                ---@type XTable.XTableTemple2Grid
                local gridConfig = self._Model:GetGrid(gridId)
                if gridConfig and gridConfig.ShowOnStageDetail == 1 then
                    result[gridId] = gridConfig
                    if block:IsFavouriteBlock() then
                        favouriteGrids[gridId] = true
                    end
                else
                    result[gridId] = false
                end
            end
        end
    end
end

function XTemple2SystemControl:CheckPlayMovie()
    if not self._CurrentChapterData then
        XLog.Warning("[XTemple2SystemControl] 查找当前章节失败:")
        return
    end
    local chapterIndex = self._CurrentChapterData.Index
    local allChapter = self._Model:GetAllChapter()
    ---@type XTable.XTableTemple2Chapter
    local chapter = allChapter[chapterIndex]
    if not chapter then
        XLog.Warning("[XTemple2SystemControl] 查找当前章节失败:", chapterIndex)
        return
    end
    local timeId = chapter.TimeId
    if XFunctionManager.CheckInTimeByTimeId(timeId) then
        local bubbleId = chapter.BubbleId
        if not self._Model:IsStoryUnlock(bubbleId) then
            local bubble = self._Model:GetBubble(bubbleId)
            if bubble then
                local storyId = bubble.StoryId
                if storyId and bubble.StoryId ~= nil then
                    XMVCA.XTemple2:PlayMovie(storyId, function()
                        self._Model:SetStoryUnlock(bubbleId)
                        XMVCA.XTemple2:RequestBubble(bubbleId)
                    end)
                end
            end
        end
    end
end

return XTemple2SystemControl