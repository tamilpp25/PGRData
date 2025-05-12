local STEP = {
    NONE = 0,
    SELECT_DIFFICULTY = 1, -- 选择难度
    SELECT_COLLECTION = 2, -- 选择藏品继承
    SELECT_AFFIX = 3, -- 选择词缀
    SELECT_CHARACTER = 4, -- 选择角色
    GAME = 5,
}

---@field _Model XTheatre4Model
---@field _MainControl XTheatre4Control
---@class XTheatre4SetControl
local XTheatre4SetControl = XClass(XControl, "XTheatre4SetControl")

function XTheatre4SetControl:Ctor()
    self._Step = STEP.NONE

    self._UiData = {
        Difficulty = {
            ---@type XTheatre4SetControlDifficultyData[]
            DifficultyList = {},
            Hp = 0,
            RewardRatio = 0,
            IsUnlock = false,
            UnlockDesc = "",
            StoryDesc = "",
            CurrentDifficultyDescList = {}
        },
        Affix = {
            ---@type XTheatre4SetControlAffixData[]
            AffixList = {}
        },
        Character = {
            HeadCount = 0,
            RefreshCount = "",
            ---@type XTheatre4SetControlMemberData[]
            CharacterList = {},
            ModelUrl = nil,
            SceneUrl = nil,
        },
        Collection = {
            ---@type XTheatre4SetControlCollectionData[]
            CollectionList = {},
        },
        Genius = {
            List = {},
            -- 当前建设度
            BuildingPointNow = 0,
            BuildingPointAccumulate = 0,
        },
    }

    ---@type XTheatre4SetControlAffixData
    self._CurrentAffix = false

    self._CurrentGeniusColor = XEnumConst.Theatre4.ColorType.Red

    ---@type XTheatre4SetControlGeniusSubData
    self._SelectedGenius = false

    self._SelectedDifficultyIndex = XSaveTool.GetData("XTheater4DifficultyIndex" .. XPlayer.Id) or 1
end

function XTheatre4SetControl:OnInit()
    --XEventManager.AddEventListener(XEventId.EVENT_THEATRE4_UPDATE_ADVENTURE_DATA, self.NextStep, self)
end

function XTheatre4SetControl:OnRelease()
    --XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE4_UPDATE_ADVENTURE_DATA, self.NextStep, self)
end

function XTheatre4SetControl:GetUiData()
    return self._UiData
end

function XTheatre4SetControl:UpdateCurrentDifficulty()
    local uiData = self:GetUiData().Difficulty

    ---@type XTheatre4Set
    local set = self._Model:GetSet()
    ---@type XTheatre4Difficulty
    local currentDifficulty = set:GetCurrentDifficulty()

    if not currentDifficulty then
        local index = self._SelectedDifficultyIndex
        local allDifficulty = set:GetAllDifficulty()
        currentDifficulty = allDifficulty[index]
        set:SetDifficulty(currentDifficulty)
    end
    if not currentDifficulty then
        XLog.Error("[XTheatre4SetControl] 难度配置为空")
        return
    end

    uiData.Hp = currentDifficulty:GetHp()
    uiData.RewardRatio = currentDifficulty:GetBpExpRatio()

    local descList = currentDifficulty:GetDesc()
    uiData.CurrentDifficultyDescList = descList
    uiData.IsUnlock, uiData.UnlockDesc = currentDifficulty:IsUnlock(true)
    uiData.StoryDesc = currentDifficulty:GetStoryDesc()
end

function XTheatre4SetControl:UpdateAllDifficulty()
    local uiData = self:GetUiData().Difficulty

    ---@type XTheatre4Set
    local set = self._Model:GetSet()
    ---@type XTheatre4Difficulty[]
    local allDifficulty = set:GetAllDifficulty()
    local currentDifficulty = set:GetCurrentDifficulty()

    local difficultyList = {}
    uiData.DifficultyList = difficultyList
    for i = 1, #allDifficulty do
        local difficulty = allDifficulty[i]
        ---@class XTheatre4SetControlDifficultyData
        local difficultyData = {
            Name = difficulty:GetName(),
            Desc = difficulty:GetDesc(),
            ExtraDesc = difficulty:GetStoryDesc(),
            Temperature = difficulty:GetTemperature(),
            IsSelected = difficulty:Equals(currentDifficulty),
            IsUnlock = difficulty:IsUnlock(),
        }
        difficultyList[#difficultyList + 1] = difficultyData
    end
end

function XTheatre4SetControl:SelectDifficulty(index)
    local set = self._Model:GetSet()
    local difficulty = set:GetDifficultyByIndex(index)
    if difficulty then
        if self._SelectedDifficultyIndex ~= index then
            XSaveTool.SaveData("XTheater4DifficultyIndex" .. XPlayer.Id, index)
            self._SelectedDifficultyIndex = index
        end
        set:SetCurrentDifficulty(difficulty)
    else
        XLog.Error("[XTheatre4SetControl] 选择困难, index错误", index)
    end
end

function XTheatre4SetControl:GetCurrentStep()
    ---@type XTheatre4Adventure
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return STEP.SELECT_DIFFICULTY
    end
    -- 难度
    if adventureData:GetDifficulty() == 0 then
        return STEP.SELECT_DIFFICULTY
    end

    -- 继承藏品
    local inheritItemId = adventureData:GetInheritItemId()
    if inheritItemId == 0 then
        local settleData = self._Model:GetPreAdventureSettleData()
        local inheritItems = settleData and settleData:GetInheritItems() or {}
        if #inheritItems > 0 then
            return STEP.SELECT_COLLECTION
        end
    end

    -- 词缀
    if (not adventureData.Affix) or adventureData.Affix == 0 then
        return STEP.SELECT_AFFIX
    end

    -- 招募角色
    local count = self._Model:GetTransactionDataCountByType(XEnumConst.Theatre4.TransactionType.Recruit)
    if count > 0 then
        return STEP.SELECT_CHARACTER
    end

    return STEP.GAME
end

-- 重置步骤
function XTheatre4SetControl:ResetStep()
    self._Step = STEP.NONE
end

function XTheatre4SetControl:NextStep()
    local step = self:GetCurrentStep()
    if step == self._Step then
        XLog.Error("[XTheatre4SetControl] 重复的step，待处理")
        --return
    end
    self._Step = step

    -- 选择困难
    if self._Step == STEP.SELECT_DIFFICULTY then
        XLuaUiManager.Open("UiTheatre4Difficulty")
        return
    end

    -- 藏品
    if self._Step == STEP.SELECT_COLLECTION then
        XLuaUiManager.Open("UiTheatre4PopupInherit")
        XLuaUiManager.SafeClose("UiTheatre4Difficulty")
        return
    end

    -- 词缀
    if self._Step == STEP.SELECT_AFFIX then
        XLuaUiManager.Open("UiTheatre4OpeningEffect")
        XLuaUiManager.SafeClose("UiTheatre4Difficulty")
        XLuaUiManager.SafeClose("UiTheatre4PopupInherit")
        return
    end

    -- 招募角色
    if self._Step == STEP.SELECT_CHARACTER then
        XLuaUiManager.Open("UiTheatre4Recruit")
        XLuaUiManager.SafeClose("UiTheatre4OpeningEffect")
        return
    end

    -- 关闭开局所有界面
    if self._Step == STEP.NONE then
        XLuaUiManager.SafeClose("UiTheatre4Difficulty")
        XLuaUiManager.SafeClose("UiTheatre4PopupInherit")
        XLuaUiManager.SafeClose("UiTheatre4OpeningEffect")
        XLuaUiManager.SafeClose("UiTheatre4Recruit")
        return
    end

    -- 进入游戏
    if self._Step == STEP.GAME then
        XLuaUiManager.Open("UiTheatre4Game")
        XLuaUiManager.SafeClose("UiTheatre4Difficulty")
        XLuaUiManager.SafeClose("UiTheatre4PopupInherit")
        XLuaUiManager.SafeClose("UiTheatre4OpeningEffect")
        XLuaUiManager.SafeClose("UiTheatre4Recruit")
        return
    end
end

function XTheatre4SetControl:UpdateAffix()
    local data = self:GetUiData().Affix
    local affixList = {}
    data.AffixList = affixList
    local selectedAffixId
    if self._CurrentAffix then
        selectedAffixId = self._CurrentAffix.Id
    end

    local set = self._Model:GetSet()
    ---@type XTheatre4Affix[]
    local allAffix = set:GetAllAffix()
    for i = 1, #allAffix do
        local affix = allAffix[i]
        local isUnlock, lockDesc = affix:IsUnlock()

        ---@class XTheatre4SetControlAffixData
        local affixData = {
            Id = affix:GetId(),
            Name = affix:GetName(),
            Desc = affix:GetDesc(),
            TeamLogo = affix:GetTeamLogo(),
            Icon = affix:GetIcon(),
            IsSelected = affix:GetId() == selectedAffixId,
            IsUnlock = isUnlock,
            LockDesc = lockDesc,
        }
        affixList[#affixList + 1] = affixData
    end

    -- 默认不选中
    --if not self._CurrentAffix then
    --    self._CurrentAffix = affixList[1]
    --    self._CurrentAffix.IsSelected = true
    --end
end

---@param affix XTheatre4SetControlAffixData
function XTheatre4SetControl:SelectAffix(affix)
    self._CurrentAffix = affix
end

function XTheatre4SetControl:UpdateCharacter()
    --local transactions = self._Model:GetTransaction()
    --if XMain.IsWindowsEditor then
    --    if transactions then
    --        local amount = 0
    --        for i = 1, #transactions do
    --            local transaction = transactions[i]
    --            if transaction.Type == TRANSACTION.RECRUIT then
    --                amount = amount + 1
    --            end
    --        end
    --        if amount > 1 then
    --            XLog.Error("[XTheatre4SetControl] 选择角色的事务数量大于1, 记录可能有问题")
    --        end
    --    end
    --
    --    if not transactions then
    --        transactions = {
    --            {
    --                RefreshTimes = 1,
    --                MaxRefreshTimes = 3,
    --                Type = TRANSACTION.RECRUIT,
    --                ConfigId = 1,
    --                Characters = {
    --                    {
    --                        CharacterId = 1,
    --                        Star = 2,
    --                    },
    --                    {
    --                        CharacterId = 2,
    --                        Star = 2,
    --                    },
    --                },
    --                SelectIds = {},
    --            }
    --        }
    --    end
    --end
    --
    --if not transactions then
    --    XLog.Error("[XTheatre4SetControl] 不存在选人数据, 但是打开了选人界面")
    --    return
    --end

    ---@type XTheatre4Transaction
    local currentTransaction = self._Model:GetTransactionDataByType(XEnumConst.Theatre4.TransactionType.Recruit)
    if not currentTransaction then
        XLog.Error("[XTheatre4SetControl] 当前没有进行中的选择角色事务, 但是试图刷新选择角色界面")
        return
    end

    local set = self._Model:GetSet()

    local uidData = self:GetUiData()
    local memberDataList = {}
    uidData.Character.CharacterList = memberDataList
    local members = currentTransaction:GetCharacters()
    for index, member in pairs(members) do
        local isSelected = false
        local selectedIds = currentTransaction:GetSelectIds()
        for i = 1, #selectedIds do
            if index == selectedIds[i] then
                isSelected = true
                break
            end
        end

        if isSelected then
            memberDataList[#memberDataList + 1] = false
        else
            local memberId = member:GetCharacterId()
            ---@type XTheatre4Character
            local character = set:GetCharacter(memberId, self._Model)
            if character then
                local modelId = character:GetModelId()
                if modelId then
                    local star = member:GetStar()
                    local resources = member:GetColorLevelAdds()
                    if not resources then
                        resources = {}
                    end
                    local isShowStarButton = self._Model:IsCharacterHired(memberId)
                    ---@class XTheatre4SetControlMemberData
                    local memberData = {
                        Index = index,
                        TransactionId = currentTransaction:GetId(),
                        Id = memberId,
                        Model = modelId,
                        Name = character:GetFullName(),
                        ResourceList = resources,
                        Star = star,
                        IsShowStarButton = isShowStarButton,
                        IsSelected = table.contains(currentTransaction:GetSelectIds(), index)
                    }
                    memberDataList[#memberDataList + 1] = memberData
                else
                    XLog.Error("[XTheatre4SetControl] 该角色获取模型失败:", memberId)
                end
            else
                XLog.Error("[XTheatre4SetControl] 服务端数据里有不存在的角色TheatreCharacter:", memberId)
            end
        end
    end

    --local characterList = set:GetHireCharacterList()
    local ticketId = currentTransaction.ConfigId
    --local maxSelectCount = set:GetMaxSelectNum(ticketId, self._Model)
    --local selectCount = maxSelectCount - (#characterList)

    local refreshTimes = currentTransaction.RefreshTimes
    local refreshLimit = currentTransaction.RefreshLimit
    if not refreshLimit or refreshLimit == 0 then
        refreshLimit = self._Model:GetRecruitTicketRefreshLimitById(ticketId) or 0
        XLog.Warning("[XTheatre4SetControl] 服务端没赋值刷新上限RefreshLimit")
    end
    uidData.Character.HeadCount = refreshTimes .. "/" .. refreshLimit

    local selectTimes = currentTransaction.SelectTimes
    local selectLimit = currentTransaction.SelectLimit
    uidData.Character.RefreshCount = selectTimes .. "/" .. selectLimit
end

function XTheatre4SetControl:UpdateMap()
    local uiData = self:GetUiData().Character
    local mapId = self._MainControl.MapSubControl:GetCurrentMapId()
    if not XTool.IsNumberValid(mapId) then
        XLog.Error("[XTheatre4SetControl] 没有找到当前章节数据")
        local maps = self._Model:GetMapConfigs()
        for _, map in pairs(maps) do
            mapId = map.Id
            break
        end
    end
    if not mapId then
        return
    end
    local config = self._Model:GetMapClientConfigById(mapId)
    local modelUrl = config.ModelUrl
    local sceneUrl = config.SceneUrl
    uiData.ModelUrl = modelUrl
    uiData.SceneUrl = sceneUrl
end

function XTheatre4SetControl:RequestRefreshCharacters()
    local currentTransaction = self._Model:GetTransactionDataByType(XEnumConst.Theatre4.TransactionType.Recruit)
    if currentTransaction then
        if currentTransaction.RefreshTimes <= 0 then
            self._MainControl:ShowRightTipPopup(XUiHelper.GetText("DifferentRefreshTimes"))
            return
        end
        self._MainControl:RefreshCharacterRequest(currentTransaction.Id)
    else
        XLog.Error("[XTheatre4SetControl] 找不到当前招募事务")
    end
end

---@param data XTheatre4SetControlMemberData
function XTheatre4SetControl:RequestHire(data)
    self._MainControl:ConfirmRecruitRequest(data.TransactionId, data.Index, function()
        local step = self:GetCurrentStep()
        if step == STEP.SELECT_CHARACTER then
            XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_UPDATE_HIRE)
            return
        end
        if self._Step == STEP.GAME then
            self._MainControl:CheckNeedOpenNextPopup("UiTheatre4Recruit", true)
            return
        end
        self:NextStep()
    end)
end

function XTheatre4SetControl:UpdateCollection()
    local uiData = self:GetUiData().Collection
    local collectionList = {}
    uiData.CollectionList = collectionList

    local settleData = self._Model:GetPreAdventureSettleData()
    if not settleData then
        return
    end
    local collections = settleData.InheritItems

    for i = 1, #collections do
        local collectionId = collections[i]
        local config = self._Model:GetItemConfigById(collectionId)
        if config then
            ---@class XTheatre4SetControlCollectionData
            local collectionData = {
                Id = collectionId,
                Icon = config.Icon,
                Name = config.Name,
                Desc = config.Desc,
                Quality = config.Quality,
                Index = i
            }
            collectionList[#collectionList + 1] = collectionData
        else
            XLog.Error("[XTheatre4SetControl] 服务端数据中存在无对应配置的收藏品", collectionId)
        end
    end
end

---@param data XTheatre4SetControlCollectionData
function XTheatre4SetControl:SelectCollection(data)
    self._MainControl:SelectInheritRequest(data.Id, function()
        XLuaUiManager.Close("UiTheatre4PopupInherit")
        self:NextStep()
    end)
end

function XTheatre4SetControl:RequestSetDifficulty()
    ---@type XTheatre4Set
    local set = self._Model:GetSet()
    ---@type XTheatre4Difficulty
    local currentDifficulty = set:GetCurrentDifficulty()
    if currentDifficulty then
        self._MainControl:SelectDifficultRequest(currentDifficulty:GetId(), function()
            self:NextStep()
        end)
    else
        XLog.Error("[XTheatre4SetControl] 不存在当前难度，逻辑有问题")
    end
end

---@param data XTheatre4SetControlAffixData
function XTheatre4SetControl:RequestSetAffix(data)
    self._MainControl:SelectAffixRequest(data.Id, function()
        self:NextStep()
    end)
end

function XTheatre4SetControl:GetColorResources()
    local adventureData = self._Model:GetAdventureData()
    if adventureData then
        local colors = adventureData.Colors
        if colors then
            return colors
        end
    end
    return {}
end

function XTheatre4SetControl:UpdateGenius()
    local geniusData = {}
    local colorType = self._CurrentGeniusColor
    self._UiData.Genius.List = geniusData

    local talentDataDict = {}

    local slotConfigs = self._Model:GetColorTalentSlotConfigByColor(colorType)
    table.sort(slotConfigs, function(a, b)
        return a.Id < b.Id
    end)
    for i = 1, #slotConfigs do
        local slotConfig = slotConfigs[i]
        if slotConfig.Level ~= 0 then
            if slotConfig.GenerateType == XEnumConst.Theatre4.TalentType.Big then
                ---@type XTheatre4SetControlGeniusData
                local talentData = {
                    Id = slotConfig.Id,
                    Talents = { false },
                    IsActive = false,
                    UnlockPoint = 0,
                    List = nil,
                    Index = i,
                    IsBig = true,
                }
                -- 存在nil问题
                talentDataDict[slotConfig.Id] = talentData
            elseif slotConfig.GenerateType == XEnumConst.Theatre4.TalentType.Small then
                local groupId = slotConfig.GeneratePoolGroup
                local talentIdArray = self._Model:GetColorTalentPoolTalentByGroup(groupId)
                local talentData = {
                    Id = slotConfig.Id,
                    Talents = { talentIdArray[1] },
                    IsActive = false,
                    UnlockPoint = 0,
                    List = nil,
                    Index = i,
                    IsBig = false
                }
                -- 存在nil问题
                talentDataDict[slotConfig.Id] = talentData
            end
        end
    end

    local maxIndex = 1
    local adventureData = self._Model:GetAdventureData()
    if adventureData then
        ---@type XTheatre4ColorTalent
        local colorData = adventureData:GetColorData(colorType)
        if colorData then
            local slots = colorData:GetSlots()
            for i, slot in pairs(slots) do
                local id = slot:GetSlotId()
                local configData = talentDataDict[id]
                if configData then
                    -- 有服务端数据则覆盖之, 存在nil问题
                    local talentIds = slot:GetTalentIds()
                    local isBig = configData and configData.IsBig and #talentIds <= 1
                    talentDataDict[id] = {
                        Id = i,
                        Talents = talentIds,
                        IsActive = true,
                        IsBig = isBig
                    }
                    if maxIndex > id then
                        maxIndex = i
                    end
                end
            end
        end
    end

    -- 解锁点数
    for i = 1, #slotConfigs do
        local slotConfig = slotConfigs[i]
        if talentDataDict[slotConfig.Id] then
            talentDataDict[slotConfig.Id].UnlockPoint = slotConfig.UnlockPoint
        end
    end

    -- 解决nil问题
    --self:FillUpSparseArray(talentDataDict)
    local talentDataList = {}
    for id, data in pairs(talentDataDict) do
        talentDataList[#talentDataList + 1] = data
    end
    table.sort(talentDataList, function(a, b)
        return a.Id < b.Id
    end)

    for i = 1, #talentDataList do
        local talentData = talentDataList[i]
        local list = {}
        for j = 1, 3 do
            local talentId = talentData.Talents[j]
            local isSelected = false
            if self._SelectedGenius then
                if talentId then
                    isSelected = talentId == self._SelectedGenius.Id and self._SelectedGenius.Index == i
                else
                    isSelected = self._SelectedGenius.Index == i
                            and self._SelectedGenius.SubIndex == j
                end
            end
            ---@type XTheatre4SetControlGeniusSubData
            local subData
            if talentId then
                local talentConfig = self._Model:GetColorTalentConfigById(talentId)
                if talentConfig then
                    local showLevel = talentConfig.ShowLevel
                    if showLevel == nil or showLevel == 0 then
                        showLevel = 1
                    end
                    ---@class XTheatre4SetControlGeniusSubData
                    local temp = {
                        Id = talentId,
                        Icon = talentConfig.Icon,
                        IsActive = talentData.IsActive,
                        Index = i,
                        SubIndex = j,
                        LevelIcon = self._Model:GetClientConfig("GeniusLevelIcon", showLevel),
                        IsSelected = isSelected,
                        IsShowQuestionMark = false,
                    }
                    subData = temp
                    if talentConfig.Icon == nil then
                        XLog.Warning("[XTheatre4SetControl] 天赋icon未配置", talentId)
                    end
                else
                    XLog.Warning("[XTheatre4SetControl] 不存在于配置表的天赋:", talentId)
                end
            elseif talentId == false then
                subData = {
                    Id = talentId,
                    Icon = false,
                    IsActive = false,
                    Index = i,
                    SubIndex = j,
                    IsSelected = isSelected,
                    IsShowQuestionMark = talentData.IsBig,
                }
            end
            --if subData then
            --    list[#list + 1] = subData
            --    subData.IsCanClick = (not talentData.IsBig) or talentData.IsActive
            --end
            if subData then
                list[#list + 1] = subData
                subData.IsCanClick = true
            end
        end

        ---@class XTheatre4SetControlGeniusData
        local data = {
            List = list,
            UnlockPoint = talentData.UnlockPoint,
            IsActive = talentData.IsActive,
            Index = i,
            IsBig = talentData.IsBig,
            ColorType = colorType,
            IsPlayEffect = true,
        }
        geniusData[#geniusData + 1] = data
    end

    local lastOne
    for i = 1, #geniusData do
        local data = geniusData[i]
        lastOne = data
        if not data.IsActive then
            break
        end
    end

    if adventureData then
        self._UiData.Genius.BuildingPointAccumulate = adventureData:GetColorPointById(colorType)
    else
        self._UiData.Genius.BuildingPointAccumulate = 0
    end
    -- 只有红色买死值
    if colorType == XEnumConst.Theatre4.ColorType.Red and self._MainControl.EffectSubControl:GetEffectRedBuyDeadAvailable() then
        self._UiData.Genius.BuildingPointNow = self._MainControl.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.ColorCostPoint, colorType)
    else
        self._UiData.Genius.BuildingPointNow = nil
    end
end

function XTheatre4SetControl:FillUpSparseArray(array)
    local maxNumber = 0
    for i, _ in pairs(array) do
        if i > maxNumber then
            maxNumber = i
        end
    end
    if maxNumber == 0 then
        return
    end

    local left = 1
    local right = 1
    -- 100为magic num，防止死循环
    local magicNum = 100
    local i = 1
    local isSparse = false
    while (i < magicNum) do
        i = i + 1
        local elementLeft = array[left]
        if elementLeft then
            left = left + 1
            if left > right then
                right = left
            end
        else
            isSparse = true
            local elementRight = array[right]
            if elementRight then
                array[left] = elementRight
                array[right] = nil
            else
                right = right + 1
            end
        end

        if right > maxNumber or left > maxNumber then
            break
        end
    end
    if i == magicNum then
        XLog.Warning("[XTheatre4SetControl] 可能存在死循环")
    end
    --if isSparse then
    --    XLog.Warning("[XTheatre4SetControl] 天赋树界面，数组为稀疏数组，可能有问题")
    --end
end

function XTheatre4SetControl:SetGeniusColor(color)
    self._CurrentGeniusColor = color
end

function XTheatre4SetControl:GetTalentEntity4UiCard(talentId)
    local XTheatre4ColorTalentEntity = require("XModule/XTheatre4/XEntity/System/XTheatre4ColorTalentEntity")
    local XTheatre4ColorTalentConfig = require("XModule/XTheatre4/XEntity/System/XConfig/XTheatre4ColorTalentConfig")

    local config = self._Model:GetColorTalentConfigById(talentId)
    ---@type XTheatre4ColorTalentEntity
    local entity = XTheatre4ColorTalentEntity.New(self)
    entity:SetConfig(XTheatre4ColorTalentConfig.New(config))
    return entity
end

function XTheatre4SetControl:IsShowCharacterBtn()
    local characterIds = XMVCA.XTheatre4:GetRecruitedCharacterIds()
    if not characterIds then
        return false
    end
    return #characterIds > 0
end

---@param data XTheatre4SetControlGeniusSubData
function XTheatre4SetControl:SetSelectedGenius(data)
    if not data then
        self._SelectedGenius = false
        return
    end
    self._SelectedGenius = data
end

return XTheatre4SetControl
