-- 肉鸽二期羁绊列表
local XTheatreComboList = XClass(nil, "XTheatreComboList")
local XCombo = require("XEntity/XBiancaTheatre/Combo/XTheatreCombo")
--================
--构造函数
--@param team：XTheatreTeam
--================
function XTheatreComboList:Ctor(team)
    self.Team = team
    self:InitCombos()  
end
--================
--初始化羁绊
--================
function XTheatreComboList:InitCombos()
    self.Combos = {}
    local childCombos = XBiancaTheatreConfigs.GetBiancaTheatreChildCombo()
    for id, combo in pairs(childCombos) do
        self.Combos[id] = XCombo.New(combo, self.Team)
    end
    self:InitComboReferences()
end
--================
--初始化所有羁绊的固定关联人员列表
--================
function XTheatreComboList:InitComboReferences()
    local allCharas = XBiancaTheatreConfigs.GetBiancaTheatreBaseCharacter()
    for eBaseId, config in pairs(allCharas) do
        for _, comboId in pairs(XBiancaTheatreConfigs.GetBaseCharacterReferenceComboId(eBaseId)) do
            local combo = self.Combos[comboId]
            if combo then
                combo:SetDefaultReferenceCharaList(config.CharacterId)
            end
        end
    end
end
--================
--获取所有羁绊对象列表（包括没激活的）
--================
function XTheatreComboList:GetAllCombos()
    return self.Combos
end
--================
--获取指定Id的组合对象
--@param comboId:BiancaTheatreChildCombo表的Id
--================
function XTheatreComboList:GetComboByComboId(comboId)
    return self.Combos[comboId]
end
--================
--获取指定组合Id的总星级
--@param comboId:BiancaTheatreChildCombo表的Id
--@param adventureRoles: XAdventureRole的列表，可为空
--================
function XTheatreComboList:GetComboTotalLevelByComboId(comboId, adventureRoles)
    local combo = self:GetComboByComboId(comboId)
    return combo:GetTotalRank(adventureRoles)
end
--================
--获取已激活的羁绊列表
--@param maxCount：返回的最大数量，默认全部
--================
function XTheatreComboList:GetActiveComboList(maxCount, adventureRoles)
    local allCombos = self:GetAllCombos()
    local activeComboList = {}
    for _, combo in pairs(allCombos) do
        if combo:GetTotalRank(adventureRoles) > 0 then
            table.insert(activeComboList, combo)
        end
        if maxCount and #activeComboList >= maxCount then
            break
        end
    end
    return activeComboList
end
--================
--检查队伍羁绊列表
--@param team:队伍（XTheatreTeam）
--================
function XTheatreComboList:CheckCombos(team)
    if not team then return end
    local tempIds = {}
    self:ResetComboCheckList()
    self.CurrentCombos = {}
    for _, teamChara in pairs(team) do
        local comboIds = teamChara:GetCharacterComboIds()
        for _, comboId in pairs(comboIds) do
            local combo = self:GetComboByComboId(comboId)
            if not tempIds[comboId] then
                tempIds[comboId] = true
                --if combo:CheckDefaultTeamCombo() then
                    table.insert(self.CurrentCombos, combo)
                --end
            end
            combo:AddCheckList(teamChara)
        end
    end
    self:CheckActiveStatus()
end
--================
--获取所有现在关联的羁绊列表（包括没激活的）
--================
function XTheatreComboList:GetCurrentCombos(team)
    self:CheckCombos(team)
    return self.CurrentCombos
end
--================
--重置当前组合状态列表的所有组合检查列表
--================
function XTheatreComboList:ResetComboCheckList()
    if not self.CurrentCombos then return end
    for _, combo in pairs(self.Combos) do
        combo:ResetCheckList()
    end
end
--================
--刷新当前组合状态列表的所有组合状态
--================
function XTheatreComboList:CheckActiveStatus()
    for _, combo in pairs(self.CurrentCombos) do
        combo:Check()
    end
end
--================
--获取角色有效的羁绊ID列表
--@param echara: XAdventureRole
--================
function XTheatreComboList:GetActiveComboIdsByEChara(eChara, isSort)
    local previewList = {}
    local comboIds = eChara:GetCharacterComboIds()
    for _, comboId in pairs(comboIds) do
        table.insert(previewList, comboId)
    end
    if isSort then
        table.sort(previewList, self.SortComboIdsFunc)
    end
    return previewList
end
--================
--返回招募时的预览羁绊ID列表
--@param echara: XAdventureRole
--================
function XTheatreComboList:GetPreviewCombosWhenRecruit(eChara, isSort)
    local previewList = {}
    local comboIds = eChara:GetCharacterComboIds()
    for _, comboId in pairs(comboIds) do
        local combo = self:GetComboByComboId(comboId)
        combo:PreviewCheckNew(eChara)
        table.insert(previewList, comboId)
    end
    if isSort then
        table.sort(previewList, self.SortComboIdsFunc)
    end
    return previewList
end
--================
--展示组合排序  核心羁绊＞当前羁绊星级＞人数 (激活状态按照星级排序，未激活状态按照人数排序)
--================
function XTheatreComboList.SortComboIdsFunc(a, b)
    local ACombo = self:GetComboByComboId(a)
    local BCombo = self:GetComboByComboId(b)
    local aActive = ACombo:GetComboActive()
    local aRank = ACombo:GetTotalRank()
    local aReachNum = ACombo:GetReachConditionNum()
    local bActive = BCombo:GetComboActive()
    local bRank = BCombo:GetTotalRank()
    local bReachNum = BCombo:GetReachConditionNum()
    if aActive ~= bActive then
        return aActive and not bActive
    end
    if aActive and bActive and aRank ~= bRank then
        return aRank > bRank
    end
    if not aActive and not bActive and aReachNum ~= bReachNum then
        return aReachNum > bReachNum
    end
    return a > b
end
return XTheatreComboList