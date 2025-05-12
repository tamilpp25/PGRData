local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")
local XTempleConfigControl = require("XModule/XTemple/XTempleConfigControl")

---@class XTempleUiControl:XTempleConfigControl
---@field private _Model XTempleModel
---@field private _MainControl XTempleControl
local XTempleUiControl = XClass(XTempleConfigControl, "XTempleUiControl")

function XTempleUiControl:Ctor()
    self._ExpireTimer = false

    self._StageId = false
end

function XTempleUiControl:OnInit()
    if not self._ExpireTimer then
        self._ExpireTimer = XScheduleManager.ScheduleForever(function()
            self:CheckExpire()
        end, XScheduleManager.SECOND)
    end
end

function XTempleUiControl:OnRelease()
    if self._ExpireTimer then
        XScheduleManager.UnSchedule(self._ExpireTimer)
        self._ExpireTimer = false
    end
end

function XTempleUiControl:CheckExpire()
    local endTime = self._Model:GetActivityEndTime()
    local currentTime = XTime.GetServerNowTimestamp()
    if currentTime > endTime then
        XUiManager.TipText("ActivityMainLineEnd")
        XLuaUiManager.RunMain()
    end
end

function XTempleUiControl:GetRemainTime()
    local endTime = self._Model:GetActivityEndTime()
    local currentTime = XTime.GetServerNowTimestamp()
    local remainTime = endTime - currentTime
    remainTime = math.max(remainTime, 0)
    local timeStr = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.TEMPLE)
    return timeStr
end

function XTempleUiControl:GetChapterStarAmount()
    local star, totalStar = self._Model:GetChapterStar(self._MainControl:GetChapter())
    return star, totalStar
end

function XTempleUiControl:GetChapterStar1()
    local star, totalStar = self._Model:GetChapterStar(XTempleEnumConst.CHAPTER.SPRING)
    return star .. "/" .. totalStar
end

function XTempleUiControl:GetChapterPhoto2()
    return self:GetTextPassedCharacterAmount(XTempleEnumConst.CHAPTER.COUPLE)
end

function XTempleUiControl:GetChapterStar3()
    local star, totalStar = self._Model:GetChapterStar(XTempleEnumConst.CHAPTER.LANTERN)
    return star .. "/" .. totalStar
end

function XTempleUiControl:GetMessagePassedStageAmount()
    local chapter = self._MainControl:GetChapter()
    local passedAmount, totalAmount = self._Model:GetMessagePassedStageAmount(chapter)
    return passedAmount .. "/" .. totalAmount
end

function XTempleUiControl:GetCoupleStageList()
    local chapterId = XTempleEnumConst.CHAPTER.COUPLE
    return self:GetStageList(chapterId)
end

function XTempleUiControl:GetCurrentChapterStageList()
    return self:GetStageList(self._MainControl:GetChapter())
end

local function SortStage(a, b)
    return a.StageId < b.StageId
end

function XTempleUiControl:GetStageList(chapterId)
    local allStage = self._Model:GetStageConfigList()
    local stages = {}

    local activityData = self._Model:GetActivityData()
    local stageId2Continue
    if activityData:HasStage2Continue(self._MainControl:GetChapter()) then
        stageId2Continue = activityData:GetStageId2Continue(self._MainControl:GetChapter())
    end

    local isHideStar = self._MainControl:IsCoupleChapter()

    for _, stage in pairs(allStage) do
        if stage.ChapterId == chapterId then
            local stageId = stage.Id
            local star = self._Model:GetStageStar(stageId)
            local maxStar = self._Model:GetStageMaxStar(stageId)

            local isShowContinue = stageId2Continue == stageId
            local isShowLock = false
            local isShowAbandon = isShowContinue
            local isShowMask = false

            if not isShowContinue then
                if not self._Model:IsStageCanChallenge(stageId) then
                    isShowLock = true
                    isShowMask = true
                end
                if stageId2Continue then
                    isShowMask = true
                    --isShowLock = true
                end
            end

            local isMaxStar = maxStar == star
            if isHideStar then
                isMaxStar = self._Model:IsStagePassed(stageId)
            end

            local isShowRead = XMVCA.XTemple:IsNewStageJustUnlock(stageId)

            ---@class XTempleUiControlStage
            local data = {
                StarAmount = star,
                Name = stage.StageName,
                StageId = stageId,
                ImageNumber = self._Model:GetStageImageNumber(stageId),
                IsShowMask = isShowMask,
                IsShowAbandon = isShowAbandon,
                IsShowLock = isShowLock,
                IsShowContinue = isShowContinue,
                IsHideStar = isHideStar,
                IsMaxStar = isMaxStar,
                IsShowRed = isShowRead,
            }
            stages[#stages + 1] = data
        end
    end
    table.sort(stages, SortStage)

    local index = nil
    for i = 1, #stages do
        local stage = stages[i]
        if stage.IsShowContinue then
            index = i
            break
        end
    end
    if not index then
        local isMaxStar = true
        for i = 1, #stages do
            local stage = stages[i]
            if not stage.IsMaxStar then
                isMaxStar = false
                break
            end
        end
        if isMaxStar then
            index = 1
        else
            for i = 1, #stages do
                local stage = stages[i]
                if not stage.IsShowLock and stage.StarAmount == 0 then
                    index = i
                    break
                end
            end

            if not index then
                for i = 1, #stages do
                    local stage = stages[i]
                    if not stage.IsMaxStar then
                        index = i
                        break
                    end
                end
            end
        end
    end
    if not index then
        index = 1
    end

    return stages, index
end

function XTempleUiControl:GetTextTimeUnlock(stageId)
    local unlockTimeId = self._Model:GetStageUnlockTimeId(stageId)
    if not XFunctionManager.CheckInTimeByTimeId(unlockTimeId) then
        local endTime = XFunctionManager.GetStartTimeByTimeId(unlockTimeId)
        local remainTime = endTime - XTime.GetServerNowTimestamp()
        remainTime = math.max(remainTime, 1)
        local strTime = XUiHelper.GetTime(remainTime)
        return XUiHelper.GetText("TempleTimeUnlock", strTime)
    end
    return false
end

function XTempleUiControl:IsStageExist(stageId)
    if XMain.IsWindowsEditor then
        local gameConfig = self._Model:GetStageGameConfig(stageId)
        if XTool.IsTableEmpty(gameConfig) then
            return false
        end
        return true
    end
    -- 外网总是存在
    return true
end

function XTempleUiControl:OnClickChapter(chapter)
    if not self:IsChapterUnlock(chapter) then
        return
    end

    self._MainControl:SetChapter(chapter)
    if chapter == XTempleEnumConst.CHAPTER.SPRING then
        XLuaUiManager.Open("UiTempleSpringFestivalChapter")
    elseif chapter == XTempleEnumConst.CHAPTER.COUPLE then
        -- 每次都重新选
        XLuaUiManager.Open("UiTempleValentinesDayChapter")
    elseif chapter == XTempleEnumConst.CHAPTER.LANTERN then
        XLuaUiManager.Open("UiTempleLanternFestivalChapter")
    end
    XSaveTool.SaveData(self:GetChapterJustUnlockKey(chapter), true)
    XMVCA.XTemple:SetChapterAllStageNotJustUnlockOnce(chapter)
end

function XTempleUiControl:OnClickAbandon()
    XLuaUiManager.Open("UiTempleTips", function()
        local currentStageId = self._Model:GetActivityData():GetStageId2Continue(self._MainControl:GetChapter())
        XMVCA.XTemple:RequestFail(currentStageId)
    end, XUiHelper.GetText("TempleAbandon"))
end

function XTempleUiControl:OnClickStage(stageId)
    local unlockTimeId = self._Model:GetStageUnlockTimeId(stageId)
    if not XFunctionManager.CheckInTimeByTimeId(unlockTimeId) then
        XUiManager.TipText("TempleStageLockTime")
        return
    end
    if not self._Model:IsPreStagePassed(stageId) then
        XUiManager.TipText("TempleStageLockPreStage")
        return
    end

    if self:IsStageExist(stageId) then
        local activityData = self._Model:GetActivityData()
        if activityData:HasStage2Continue(self._MainControl:GetChapter()) then
            local stage2Continue = activityData:GetStageId2Continue(self._MainControl:GetChapter())
            if stage2Continue ~= stageId then
                XUiManager.TipText("TempleStageContinue")
                return
            end
            self._MainControl:ContinueGame()
            return
        end
        XLuaUiManager.Open("UiTempleChapterDetail", stageId)
    else
        XLog.Error("[XUiTempleSpringFestivalChapterGrid] 关卡不存在:", stageId)
    end
end

function XTempleUiControl:SetCurrentStageId(stageId)
    self._StageId = stageId
end

local function SortId(a, b)
    return a.Id < b.Id
end

local function SortCharacter(a, b)
    --未解锁>已解锁>好感度>id;
    --if a.IsUnlock ~= b.IsUnlock then
    --    return b.IsUnlock
    --end
    if a.Level ~= b.Level then
        return a.Level > b.Level
    end
    if a.HeartLv ~= b.HeartLv then
        return a.HeartLv > b.HeartLv
    end
    return a.Index < b.Index
end

function XTempleUiControl:GetCharacterList()
    local configs = self._Model:GetAllNpcCouple()
    local data = {}
    for i, config in pairs(configs) do
        local characterId = config.NpcId
        local headIcon = XCharacterCuteConfig.GetCuteModelRoundnessHeadIcon(characterId)

        local trustLv = XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(characterId)
        local name = XMVCA.XCharacter:GetCharacterName(characterId)
        local tradeName = XMVCA.XCharacter:GetCharacterTradeName(characterId)
        local curFavorabilityTableData = XMVCA.XFavorability:GetFavorabilityTableData(characterId)
        local heartText = XMVCA.XFavorability:GetWordsWithColor(trustLv, curFavorabilityTableData.Name)
        local heartIcon = XMVCA.XFavorability:GetTrustLevelIconByLevel(trustLv)
        local photoData = self._Model:GetActivityData():GetPhotoData(characterId)

        ---@class XTempleUiControlCharacter
        local t = {
            Icon = headIcon,
            Name = name,
            TradeName = tradeName,
            HeartIcon = heartIcon,
            HeartLv = trustLv,
            HeartText = heartText,
            Id = characterId,
            IsUnlock = photoData and true or false,
            Index = config.Id
        }
        data[#data + 1] = t
    end
    table.sort(data, SortCharacter)
    return data
end

function XTempleUiControl:IsCharacterSelected(id)
    return self:GetSelectedCharacterId() == id
end

function XTempleUiControl:GetSelectedCharacterId()
    local characterId = self._Model:GetActivityData():GetSelectedCharacterId(self._Model)
    return characterId
end

function XTempleUiControl:GetSelectedCharacterIcon()
    local npcId = self:GetSelectedCharacterId()
    local text, body = self._Model:GetTalkText(npcId, XTempleEnumConst.NPC_TALK.STAGE_ENTER, true)
    return body
end

function XTempleUiControl:GetStageCharacterTextAndImage()
    local npcIndex = self._Model:GetNpcIndex(self._StageId)
    return self._Model:GetTalkText(npcIndex, XTempleEnumConst.NPC_TALK.STAGE_ENTER, false)
end

function XTempleUiControl:SetSelectedCharacterId(characterId)
    self._Model:GetActivityData():SetSelectedCharacterId(characterId)
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_CHANGE_ROLE)
end

function XTempleUiControl:GetDataPhoto()
    local configs = self._Model:GetAllNpcCouple()
    local data = {}
    for i, config in pairs(configs) do
        local characterId = config.NpcId
        local headIcon = XCharacterCuteConfig.GetCuteModelRoundnessHeadIcon(characterId)
        local photoData = self._Model:GetActivityData():GetPhotoData(characterId)
        local stageData
        if photoData then
            local stageId = photoData.StageId
            if not photoData.IsDecode then
                photoData.IsDecode = true
                photoData.PicData = XMessagePack.Decode(photoData.PicData) or {}
                photoData.Grids = {}

                local map = {}
                for i = 1, #photoData.PicData do
                    local gridData = photoData.PicData[i]
                    local x = gridData.X
                    local y = gridData.Y
                    if x and y then
                        map[x] = map[x] or {}
                        map[x][y] = gridData
                        gridData.Icon = self._Model:GetGridIcon(gridData.Id)
                    end
                end

                local size = XTempleEnumConst.MAP_SIZE
                for y = 1, size do
                    for x = 1, size do
                        local gridData
                        if map[x] then
                            gridData = map[x][y]
                        end
                        if not gridData then
                            gridData = {
                                Icon = self._Model:GetGridIcon(0),
                                Rotation = 0,
                            }
                        end
                        photoData.Grids[#photoData.Grids + 1] = gridData
                    end
                end
            end

            local bg
            if stageId and stageId ~= 0 then
                bg = self._Model:GetStageBg(stageId)
            end

            ---@type XTempleUiControlCharacter
            stageData = {
                Icon = headIcon,
                Grids = photoData.Grids,
                Id = characterId,
                Bg = bg,
                Level = XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(characterId),
                IsUnlock = true,
                Index = config.Id
            }
        else
            stageData = {
                Icon = headIcon,
                Grids = false,
                Id = characterId,
                Level = XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(characterId),
                IsUnlock = false,
                Index = config.Id
            }
        end
        data[#data + 1] = stageData
    end
    table.sort(data, SortCharacter)
    return data
end

function XTempleUiControl:GetPhotoDetailData(characterId)
    local photoData = self._Model:GetActivityData():GetPhotoData(characterId)
    if photoData then
        local text, body = self._Model:GetTalkText(characterId, XTempleEnumConst.NPC_TALK.SUCCESS, self._MainControl:IsCoupleChapter())
        local bg = self._Model:GetStageBg(photoData.StageId)
        local data = {
            Icon = body,
            Text = text,
            Grids = photoData.Grids,
            Id = characterId,
            Bg = bg
        }
        return data
    end
end

function XTempleUiControl:GetDataMessage()
    local chapterId = self._MainControl:GetChapter()
    local stageList = {}
    local allStage = self._Model:GetStageConfigList()
    for _, stage in pairs(allStage) do
        if stage.ChapterId == chapterId and not string.IsNilOrEmpty(stage.Message) then
            local stageId = stage.Id
            if self._Model:IsStagePassed(stageId) then
                local characterId = self._Model:GetNpcId(stageId)
                local icon = XCharacterCuteConfig.GetCuteModelRoundnessHeadIcon(characterId)
                stageList[#stageList + 1] = {
                    Message = XUiHelper.ReplaceTextNewLine(stage.Message),
                    Id = stageId,
                    Icon = icon
                }
            end
        end
    end
    table.sort(stageList, SortId)
    return stageList
end

function XTempleUiControl:GetPassedCharacterAmount(chapter)
    return self._Model:GetPassedCharacterAmount(chapter or self._MainControl:GetChapter())
end

function XTempleUiControl:GetTextPassedCharacterAmount(chapter)
    local value1, value2 = self:GetPassedCharacterAmount(chapter)
    return value1 .. "/" .. value2
end

function XTempleUiControl:IsChapterUnlock(chapterId)
    local timeId = self._Model:GetChapterTimeId(chapterId)
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XTempleUiControl:GetChapterUnlockText(chapterId)
    local timeId = self._Model:GetChapterTimeId(chapterId)
    local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
    local currentTime = XTime.GetServerNowTimestamp()
    return XUiHelper.GetTime(startTime - currentTime), currentTime > startTime
end

function XTempleUiControl:IsChapterJustUnlock(chapterId)
    local value = XSaveTool.GetData(self:GetChapterJustUnlockKey(chapterId))
    if value == nil then
        return true
    end
    return false
end

function XTempleUiControl:GetChapterJustUnlockKey(chapterId)
    return XMVCA.XTemple:GetChapterJustUnlockKey(chapterId)
end

return XTempleUiControl
