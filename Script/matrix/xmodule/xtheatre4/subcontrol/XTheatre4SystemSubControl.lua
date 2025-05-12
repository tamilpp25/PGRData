local XTheatre4BattlePassConfig = require("XModule/XTheatre4/XEntity/System/XConfig/XTheatre4BattlePassConfig")
local XTheatre4BattlePassEntity = require("XModule/XTheatre4/XEntity/System/XTheatre4BattlePassEntity")
local XTheatre4TechConfig = require("XModule/XTheatre4/XEntity/System/XConfig/XTheatre4TechConfig")
local XTheatre4TechEntity = require("XModule/XTheatre4/XEntity/System/XTheatre4TechEntity")
local XTheatre4ItemConfig = require("XModule/XTheatre4/XEntity/System/XConfig/XTheatre4ItemConfig")
local XTheatre4ItemEntity = require("XModule/XTheatre4/XEntity/System/XTheatre4ItemEntity")
local XTheatre4ColorTalentConfig = require("XModule/XTheatre4/XEntity/System/XConfig/XTheatre4ColorTalentConfig")
local XTheatre4ColorTalentEntity = require("XModule/XTheatre4/XEntity/System/XTheatre4ColorTalentEntity")
local XTheatre4MapIndexConfig = require("XModule/XTheatre4/XEntity/System/XConfig/XTheatre4MapIndexConfig")
local XTheatre4MapIndexEntity = require("XModule/XTheatre4/XEntity/System/XTheatre4MapIndexEntity")

---@class XTheatre4SystemSubControl : XControl
---@field _Model XTheatre4Model
---@field _MainControl XTheatre4Control
local XTheatre4SystemSubControl = XClass(XControl, "XTheatre4SystemSubControl")

function XTheatre4SystemSubControl:OnInit()
    -- 初始化内部变量
    ---@type XTheatre4BattlePassEntity[]
    self._BattlePassEntitys = nil
    ---@type XTheatre4BattlePassEntity
    self._BattlePassInitialEntity = nil
    ---@type table<number, XTheatre4TechEntity[]>
    self._TechEntityMap = nil
    ---@type table<number, XTheatre4ItemEntity[]>
    self._ItemEntityMap = nil
    ---@type table<number, XTheatre4ColorTalentEntity[]>
    self._TalentEntityMap = nil
    ---@type XTheatre4MapIndexEntity[]
    self._MapIndexEntitys = nil

    ---@type table<number, XTheatre4SetControlGeniusData[]>
    self._GeniusDataMap = {}

    self._BattlePassMaxExp = nil

    self._IsSkipSettlement = XSaveTool.GetData("Theatre4SkipSettlement" .. XPlayer.Id, false)
end

function XTheatre4SystemSubControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XTheatre4SystemSubControl:RemoveAgencyEvent()

end

function XTheatre4SystemSubControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
    self:_ReleaseEntity(self._BattlePassInitialEntity)
    self:_ReleaseEntitys(self._MapIndexEntitys)
    self:_ReleaseEntitys(self._BattlePassEntitys)
    self:_ReleaseAllEntitys(self._TechEntityMap)
    self:_ReleaseAllEntitys(self._ItemEntityMap)
    self:_ReleaseAllEntitys(self._TalentEntityMap)

    self._BattlePassInitialEntity = nil
    self._MapIndexEntitys = nil
    self._BattlePassEntitys = nil
    self._ItemEntityMap = nil
    self._TechEntityMap = nil
    self._TalentEntityMap = nil

    self._GeniusDataMap = {}

    self._BattlePassMaxExp = nil
end

-- region Entity Getter/Setter

---@return XTheatre4BattlePassEntity[]
function XTheatre4SystemSubControl:GetBattlePassEntitys()
    if XTool.IsTableEmpty(self._BattlePassEntitys) then
        local configs = self._Model:GetBattlePassConfigs()
        local currentExp = 0
        local index = 1

        self._BattlePassEntitys = {}
        for level, config in pairs(configs) do
            ---@type XTheatre4BattlePassEntity
            local entity = XTheatre4BattlePassEntity.New(self)

            currentExp = currentExp + config.NeedExp
            entity:SetConfig(XTheatre4BattlePassConfig.New(config))
            entity:SetCurrentExp(currentExp)
            entity:SetIndex(index)

            index = index + 1
            table.insert(self._BattlePassEntitys, entity)
        end
    end

    return self._BattlePassEntitys
end

---@return XTheatre4BattlePassEntity
function XTheatre4SystemSubControl:GetCurrentBattlePassEntity()
    local entitys = self:GetBattlePassEntitys()
    local totalExp = self:GetCurrentBattlePassTotalExp()
    local result = nil
    local nextExp = 0

    for index, entity in pairs(entitys) do
        if entity:GetCurrentExp() > totalExp then
            local config = entity:GetConfig()

            nextExp = config:GetNextLvExp()
            break
        end
        result = entity
    end

    return result or self:GetInitialBattlePassEntity(), nextExp
end

---@return XTheatre4BattlePassEntity
function XTheatre4SystemSubControl:GetInitialBattlePassEntity()
    if not self._BattlePassInitialEntity then
        local needExp = self._Model:GetBattlePassNextLvExpByLevel(1)
        ---@type XTheatre4BattlePassEntity
        local entity = XTheatre4BattlePassEntity.New(self)

        entity:SetConfig(XTheatre4BattlePassConfig.New({
            NeedExp = needExp or 0,
        }))
        entity:SetCurrentExp(0)
        entity:SetIsInitial(true)
        entity:SetIndex(1)

        self._BattlePassInitialEntity = entity
    end

    return self._BattlePassInitialEntity
end

---@return XTheatre4BattlePassEntity
function XTheatre4SystemSubControl:GetNextDisplayBattlePassEntity(index)
    local entitys = self:GetBattlePassEntitys()

    for i = index, #entitys do
        local entity = entitys[i]

        if entity and not entity:IsEmpty() and entity:GetConfig():GetIsDisplay() then
            return entity
        end
    end

    return nil
end

---@return table<number, XTheatre4TechEntity[]>
function XTheatre4SystemSubControl:GetTechEntityMap()
    if XTool.IsTableEmpty(self._TechEntityMap) then
        local configs = self._Model:GetTechConfigs()
        ---@type XTheatre4TechEntity[]
        local entitys = {}

        self._TechEntityMap = {}
        for id, config in pairs(configs) do
            ---@type XTheatre4TechEntity
            local entity = XTheatre4TechEntity.New(self)

            entity:SetConfig(XTheatre4TechConfig.New(config))
            entitys[id] = entity
            if not self._TechEntityMap[config.Type] then
                self._TechEntityMap[config.Type] = {}
            end
        end
        for id, config in pairs(configs) do
            local entity = entitys[id]

            if entity and config.PreIds then
                for _, preId in pairs(config.PreIds) do
                    entity:AddPreEntity(entitys[preId])
                end
                table.insert(self._TechEntityMap[config.Type], entity)
            end
        end
    end

    return self._TechEntityMap
end

---@return table<number, XTheatre4TechEntity[]>
function XTheatre4SystemSubControl:GetAllTechEntityList()
    local techMap = self:GetTechEntityMap()
    local result = {}

    for _, entitys in pairs(techMap) do
        table.insert(result, entitys)
    end

    return result
end

---@return XTheatre4TechEntity[]
function XTheatre4SystemSubControl:GetTechEntitysByType(techType)
    local techMap = self:GetTechEntityMap()

    return techMap[techType]
end

---@type table<number, XTheatre4ItemEntity[]>
function XTheatre4SystemSubControl:GetItemEntityMap()
    if XTool.IsTableEmpty(self._ItemEntityMap) then
        local configs = self._Model:GetItemConfigs()

        self._ItemEntityMap = {}
        for id, config in pairs(configs) do
            if not self._ItemEntityMap[config.Type] then
                self._ItemEntityMap[config.Type] = {}
            end

            local entity = XTheatre4ItemEntity.New(self)

            entity:SetConfig(XTheatre4ItemConfig.New(config))

            table.insert(self._ItemEntityMap[config.Type], entity)
        end
        for _, entitys in pairs(self._ItemEntityMap) do
            table.sort(entitys, function(entityA, entityB)
                ---@type XTheatre4ItemConfig
                local configA = entityA:GetConfig()
                ---@type XTheatre4ItemConfig
                local configB = entityB:GetConfig()

                if configA:GetQuality() == configB:GetQuality() then
                    return configA:GetId() < configB:GetId()
                end

                return configA:GetQuality() > configB:GetQuality()
            end)
        end
    end

    return self._ItemEntityMap
end

---@return table<number, XTheatre4ItemEntity[]>
function XTheatre4SystemSubControl:GetAllItemEntityList()
    local itemMap = self:GetItemEntityMap()
    local itemTypeList = {}
    local result = {}

    for itemType, entitys in pairs(itemMap) do
        table.insert(itemTypeList, itemType)
    end

    table.sort(itemTypeList, function(itemTypeA, itemTypeB)
        return itemTypeA < itemTypeB
    end)

    for _, itemType in ipairs(itemTypeList) do
        table.insert(result, itemMap[itemType])
    end

    return result
end

---@return XTheatre4ItemEntity[]
function XTheatre4SystemSubControl:GetItemEntitysByType(itemType)
    local itemMap = self:GetItemEntityMap()

    return itemMap[itemType]
end

---@type table<number, XTheatre4ColorTalentEntity[]>
function XTheatre4SystemSubControl:GetTalentEntityMap()
    if XTool.IsTableEmpty(self._TalentEntityMap) then
        local configs = self._Model:GetColorTalentConfigs()

        self._TalentEntityMap = {}
        for _, config in pairs(configs) do
            if config.Type == XEnumConst.Theatre4.TalentType.Big and XTool.IsNumberValid(config.ColorType) then
                if not self._TalentEntityMap[config.ColorType] then
                    self._TalentEntityMap[config.ColorType] = {}
                end

                ---@type XTheatre4ColorTalentEntity
                local entity = XTheatre4ColorTalentEntity.New(self)

                entity:SetConfig(XTheatre4ColorTalentConfig.New(config))
                table.insert(self._TalentEntityMap[config.ColorType], entity)
            end
        end
        for _, entitys in pairs(self._TalentEntityMap) do
            table.sort(entitys, function(entityA, entityB)
                ---@type XTheatre4ColorTalentConfig
                local configA = entityA:GetConfig()
                ---@type XTheatre4ColorTalentConfig
                local configB = entityB:GetConfig()

                return configA:GetId() < configB:GetId()
            end)
        end
    end

    return self._TalentEntityMap
end

---@return XTheatre4ColorTalentEntity[]
function XTheatre4SystemSubControl:GetTalentEntitysByColorType(colorType)
    local talentMap = self:GetTalentEntityMap()

    return talentMap[colorType]
end

---@return XTheatre4MapIndexEntity[]
function XTheatre4SystemSubControl:GetMapIndexEntitys()
    if XTool.IsTableEmpty(self._MapIndexEntitys) then
        local configs = self._Model:GetMapIndexConfigs()

        self._MapIndexEntitys = {}
        for _, config in pairs(configs) do
            ---@type XTheatre4MapIndexEntity
            local entity = XTheatre4MapIndexEntity.New(self)

            entity:SetConfig(XTheatre4MapIndexConfig.New(config))
            table.insert(self._MapIndexEntitys, entity)
        end
    end

    return self._MapIndexEntitys
end

-- endregion

-- region Config Getter

function XTheatre4SystemSubControl:GetTaskTabNameByTaskType(taskType)
    return self._Model:GetTaskNameById(taskType)
end

-- endregion

-- region Data Getter/Setter

function XTheatre4SystemSubControl:GetTaskDatasByTaskType(taskType)
    local taskIds = self._Model:GetTaskTaskIdById(taskType)

    return XDataCenter.TaskManager.GetTaskIdListData(taskIds, true)
end

function XTheatre4SystemSubControl:GetCurrentBattlePassTotalExp()
    return self._Model.ActivityData:GetTotalBattlePassExp()
end

---@return XTheatre4SetControlGeniusData[]
function XTheatre4SystemSubControl:GetGeniusDatasByColorType(colorType)
    if not self._GeniusDataMap[colorType] then
        local slotConfigs = self._Model:GetColorTalentSlotConfigByColor(colorType)
        local index = 0

        self._GeniusDataMap[colorType] = {}
        table.sort(slotConfigs, function(a, b)
            return a.Id < b.Id
        end)
        for _, slotConfig in pairs(slotConfigs) do
            if slotConfig.Level ~= 0 then
                local groupId = slotConfig.GeneratePoolGroup
                local talentIds = self._Model:GetColorTalentPoolTalentByGroup(groupId)
                local talentDatas = {}
                local isBig = slotConfig.GenerateType == XEnumConst.Theatre4.TalentType.Big

                index = index + 1
                for i, talentId in pairs(talentIds) do
                    local talentConfig = self._Model:GetColorTalentConfigById(talentId)
                    local showLevel = talentConfig.ShowLevel
                    local levelIcon = nil

                    if not isBig then
                        showLevel = XTool.IsNumberValid(showLevel) and showLevel or 1

                        levelIcon = self._Model:GetClientConfig("GeniusLevelIcon", showLevel)
                    end

                    table.insert(talentDatas, {
                        Id = talentId,
                        Icon = talentConfig.Icon,
                        IsActive = true,
                        IsCanClick = not isBig,
                        IsShowQuestionMark = isBig,
                        Index = index,
                        LevelIcon = levelIcon,
                    })
                end

                self._GeniusDataMap[colorType][index] = {
                    IsActive = true,
                    List = talentDatas,
                    Index = index,
                    UnlockPoint = slotConfig.UnlockPoint,
                    IsBig = isBig,
                    ColorType = colorType,
                }
            end
        end
    end

    for _, colorData in pairs(self._GeniusDataMap) do
        for _, indexData in pairs(colorData) do
            for _, talentData in pairs(indexData.List) do
                talentData.IsSelected = self._SelectedGeniusId == talentData.Id and self._SelectedGeniusIndex
                        == talentData.Index
            end
        end
    end

    return self._GeniusDataMap[colorType]
end

---@param data XTheatre4SetControlGeniusSubData
function XTheatre4SystemSubControl:SetSelectedGenius(data)
    if not data then
        self._SelectedGeniusId = false
        self._SelectedGeniusIndex = false
        return
    end
    self._SelectedGeniusId = data.Id
    self._SelectedGeniusIndex = data.Index
end

-- endregion

-- region Other

function XTheatre4SystemSubControl:RecordBattlePassOldExp()
    self._Model:RecordOldExp()
end

function XTheatre4SystemSubControl:ClearAllItemRedDot()
    local itemEntityList = self:GetItemEntityMap()

    for _, entitys in pairs(itemEntityList) do
        if not XTool.IsTableEmpty(entitys) then
            for _, entity in pairs(entitys) do
                if not entity:IsEmpty() then
                    entity:DisappearRedPoint()
                end
            end
        end
    end
    self._Model:SaveLocalUnlockItemMap()
end

function XTheatre4SystemSubControl:ClearAllTalentRedDot()
    local talentEntityList = self:GetTalentEntityMap()

    for _, entitys in pairs(talentEntityList) do
        if not XTool.IsTableEmpty(entitys) then
            for _, entity in pairs(entitys) do
                if not entity:IsEmpty() then
                    entity:DisappearRedPoint()
                end
            end
        end
    end
    self._Model:SaveLocalUnlockColorTalentMap()
end

function XTheatre4SystemSubControl:FinishAllTaskIdByTaskType(taskType)
    local taskDatas = self:GetTaskDatasByTaskType(taskType)
    local taskIds = {}

    for _, taskData in pairs(taskDatas) do
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(taskIds, taskData.Id)
        end
    end

    self:RecordBattlePassOldExp()
    XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, function(goodsList)
        XLuaUiManager.Open("UiTheatre4PopupGetReward", goodsList, nil, function()
            self:CheckShowBattlePassLvUpImmediately()
        end)
    end)
end

function XTheatre4SystemSubControl:GetUnlockItemCountAndTotalCount()
    local itemMap = self:GetItemEntityMap()
    local count = 0
    local totalCount = 0

    if not XTool.IsTableEmpty(itemMap) then
        for itemType, entitys in pairs(itemMap) do
            if not XTool.IsTableEmpty(entitys) then
                for _, entity in pairs(entitys) do
                    totalCount = totalCount + 1
                    if entity:IsUnlock() then
                        count = count + 1
                    end
                end
            end
        end
    end

    return count, totalCount
end

function XTheatre4SystemSubControl:GetUnlockTalentCountAndTotalCount()
    local talentMap = self:GetTalentEntityMap()
    local count = 0
    local totalCount = 0

    if not XTool.IsTableEmpty(talentMap) then
        for itemType, entitys in pairs(talentMap) do
            if not XTool.IsTableEmpty(entitys) then
                for _, entity in pairs(entitys) do
                    totalCount = totalCount + 1
                    if entity:IsUnlock() then
                        count = count + 1
                    end
                end
            end
        end
    end

    return count, totalCount
end

function XTheatre4SystemSubControl:GetUnlockTalentCountAndTotalCountByType(colorType)
    local entitys = self:GetTalentEntitysByColorType(colorType)
    local count = 0
    local totalCount = 0

    if not XTool.IsTableEmpty(entitys) then
        for _, entity in pairs(entitys) do
            totalCount = totalCount + 1
            if entity:IsUnlock() then
                count = count + 1
            end
        end
    end

    return count, totalCount
end

function XTheatre4SystemSubControl:GetFirstReceiveBattlePassIndex(defaultValue)
    local enititys = self:GetBattlePassEntitys()
    local result = defaultValue

    if not XTool.IsTableEmpty(enititys) then
        for _, entity in pairs(enititys) do
            if entity:IsCanReceive() then
                result = entity:GetIndex()

                break
            end
        end
    end

    return result
end

function XTheatre4SystemSubControl:GetBattlePassMaxExp()
    if not self._BattlePassMaxExp then
        local configs = self._Model:GetBattlePassConfigs()
        local totalExp = 0

        for _, config in pairs(configs) do
            totalExp = totalExp + config.NeedExp
        end

        self._BattlePassMaxExp = totalExp
    end

    return self._BattlePassMaxExp
end

-- endregion

-- region Check

---@param entity XTheatre4BattlePassEntity
function XTheatre4SystemSubControl:CheckBattlePassEntityInitial(entity)
    return entity and not entity:IsEmpty() and not entity:IsInitial()
end

function XTheatre4SystemSubControl:CheckAllTechRedDot()
    ---@type XTheatre4Agency
    local agency = self:GetAgency()

    return agency:CheckAllTechRedDot()
end

function XTheatre4SystemSubControl:CheckAllHandBookRedDot()
    ---@type XTheatre4Agency
    local agency = self:GetAgency()

    return agency:CheckAllHandBookRedDot()
end

function XTheatre4SystemSubControl:CheckAllBattlePassRedDot()
    ---@type XTheatre4Agency
    local agency = self:GetAgency()

    return agency:CheckAllBattlePassRedDot()
end

function XTheatre4SystemSubControl:CheckBattlePassHasReward()
    return self:CheckBattlePassRedDot()
end

function XTheatre4SystemSubControl:CheckBattlePassRedDot()
    ---@type XTheatre4Agency
    local agency = self:GetAgency()

    return agency:CheckBattlePassRedDot()
end

function XTheatre4SystemSubControl:CheckAllBattlePassTaskRedDot()
    ---@type XTheatre4Agency
    local agency = self:GetAgency()

    return agency:CheckAllBattlePassTaskRedDot()
end

function XTheatre4SystemSubControl:CheckBattlePassChallengeTaskRedDot()
    ---@type XTheatre4Agency
    local agency = self:GetAgency()

    return agency:CheckBattlePassChallengeTaskRedDot()
end

function XTheatre4SystemSubControl:CheckBattlePassProcessTaskRedDot()
    ---@type XTheatre4Agency
    local agency = self:GetAgency()

    return agency:CheckBattlePassProcessTaskRedDot()
end

function XTheatre4SystemSubControl:CheckBattlePassVersionTaskRedDot()
    ---@type XTheatre4Agency
    local agency = self:GetAgency()

    return agency:CheckBattlePassVersionTaskRedDot()
end

function XTheatre4SystemSubControl:CheckColorTalentHandBookRedDot()
    ---@type XTheatre4Agency
    local agency = self:GetAgency()

    return agency:CheckColorTalentHandBookRedDot()
end

function XTheatre4SystemSubControl:CheckItemHandBookRedDot()
    ---@type XTheatre4Agency
    local agency = self:GetAgency()

    return agency:CheckItemHandBookRedDot()
end

function XTheatre4SystemSubControl:CheckMapIndexHandBookRedDot()
    ---@type XTheatre4Agency
    local agency = self:GetAgency()

    return agency:CheckMapIndexHandBookRedDot()
end

function XTheatre4SystemSubControl:CheckColorTalentHandBookRedDotByColorType(colorType)
    local entitys = self:GetTalentEntitysByColorType(colorType)

    if not XTool.IsTableEmpty(entitys) then
        for _, entity in pairs(entitys) do
            if entity:IsShowRedPoint() then
                return true
            end
        end
    end

    return false
end

function XTheatre4SystemSubControl:CheckRedColorTalentHandBookRedDot()
    return self:CheckColorTalentHandBookRedDotByColorType(XEnumConst.Theatre4.ColorType.Red)
end

function XTheatre4SystemSubControl:CheckYellowColorTalentHandBookRedDot()
    return self:CheckColorTalentHandBookRedDotByColorType(XEnumConst.Theatre4.ColorType.Yellow)
end

function XTheatre4SystemSubControl:CheckBlueColorTalentHandBookRedDot()
    return self:CheckColorTalentHandBookRedDotByColorType(XEnumConst.Theatre4.ColorType.Blue)
end

function XTheatre4SystemSubControl:CheckTechRedDotByColorType(colorType)
    local entitys = self:GetTechEntitysByType(colorType)

    if not XTool.IsTableEmpty(entitys) then
        for _, entity in pairs(entitys) do
            if entity:IsShowRedPoint() then
                return true
            end
        end
    end

    return false
end

function XTheatre4SystemSubControl:CheckRedTechRedDot()
    return self:CheckTechRedDotByColorType(XEnumConst.Theatre4.ColorType.Red)
end

function XTheatre4SystemSubControl:CheckYellowTechRedDot()
    return self:CheckTechRedDotByColorType(XEnumConst.Theatre4.ColorType.Yellow)
end

function XTheatre4SystemSubControl:CheckBlueTechRedDot()
    return self:CheckTechRedDotByColorType(XEnumConst.Theatre4.ColorType.Blue)
end

function XTheatre4SystemSubControl:CheckAwakeTechRedDot()
    return self:CheckTechRedDotByColorType(XEnumConst.Theatre4.TreeTalent.Awake)
end

function XTheatre4SystemSubControl:CheckShowBattlePassLvUp(ui)
    local isShow = self._Model:GetIsBattlePassLvUp()

    if isShow then
        local oldExp, newExp = self._Model:GetBattlePassOldAndNewExp()

        if oldExp < newExp then
            local configs = self._Model:GetBattlePassConfigs()
            local currentExp = 0
            local oldLv = 0
            local newLv = 0

            for level, config in pairs(configs) do
                currentExp = currentExp + config.NeedExp
                if oldExp >= currentExp then
                    oldLv = level
                end
                if newExp >= currentExp then
                    newLv = level
                end
            end

            if oldLv < newLv then
                XLuaUiManager.SetMask(true, "UiTheatre4PopupLv")
                ui.PopupLvTimer = XScheduleManager.ScheduleOnce(function()
                    ui.PopupLvTimer = nil
                    XLuaUiManager.SetMask(false, "UiTheatre4PopupLv")
                    XLuaUiManager.Open("UiTheatre4PopupLv", oldLv, newLv)
                end, 0.5 * XScheduleManager.SECOND)
            end
        end
    end
    self._Model:SetIsBattlePassLvUp(false)
    self:RecordBattlePassOldExp()
end

function XTheatre4SystemSubControl:CheckShowBattlePassLvUpImmediately()
    local isShow = self._Model:GetIsBattlePassLvUp()

    if isShow then
        local oldExp, newExp = self._Model:GetBattlePassOldAndNewExp()

        if oldExp < newExp then
            local configs = self._Model:GetBattlePassConfigs()
            local currentExp = 0
            local oldLv = 0
            local newLv = 0

            for level, config in pairs(configs) do
                currentExp = currentExp + config.NeedExp
                if oldExp >= currentExp then
                    oldLv = level
                end
                if newExp >= currentExp then
                    newLv = level
                end
            end

            if oldLv < newLv then
                XLuaUiManager.Open("UiTheatre4PopupLv", oldLv, newLv)
            end
        end
    end
    self._Model:SetIsBattlePassLvUp(false)
    self:RecordBattlePassOldExp()
end

-- endregion

-- region Private/Protected

---@param entity XTheatre4EntityBase
function XTheatre4SystemSubControl:_ReleaseEntity(entity)
    if entity then
        entity:Release()
    end
end

---@param entitys XTheatre4EntityBase[]
function XTheatre4SystemSubControl:_ReleaseEntitys(entitys)
    if not XTool.IsTableEmpty(entitys) then
        for _, entity in pairs(entitys) do
            self:_ReleaseEntity(entity)
        end
    end
end

---@param entitys table<number, XTheatre4EntityBase[]>
function XTheatre4SystemSubControl:_ReleaseAllEntitys(entitysMap)
    if not XTool.IsTableEmpty(entitysMap) then
        for key, entitys in pairs(entitysMap) do
            self:_ReleaseEntitys(entitys)
        end
    end
end

-- endregion

function XTheatre4SystemSubControl:SetIsSkipSettlement(value)
    if self._IsSkipSettlement == value then
        return
    end
    self._IsSkipSettlement = value
    XSaveTool.SaveData("Theatre4SkipSettlement" .. XPlayer.Id, value)
end

function XTheatre4SystemSubControl:GetIsSkipSettlement()
    return self._IsSkipSettlement
end

function XTheatre4SystemSubControl:GetMainBgByEnding()
    local endingList = self._Model.ActivityData:GetEndings()
    local configs = {}
    for id, _ in pairs(endingList) do
        local config = self._Model:GetEndingConfigById(id)
        if config and next(config) then
            configs[#configs + 1] = config
        end
    end
    table.sort(configs, function(a, b)
        return a.MainBgPriority > b.MainBgPriority
    end)
    for i = 1, #configs do
        local config = configs[i]
        if config.MainBg and config.MainBg ~= "" then
            return config.MainBg
        end
    end
    return false
end

return XTheatre4SystemSubControl
