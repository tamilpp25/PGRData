-- 虚像地平线组合对象列表
local XExpeditionComboList = XClass(nil, "XExpeditionComboList")
local XCombo = require("XEntity/XExpedition/XExpeditionCombo")
local COMBOTYPE_TACTICS = 1 -- 战术连携
--================
--构造函数
--================
function XExpeditionComboList:Ctor(team)
    self.Team = team
    self:InitCombos()  
end
--================
--初始化羁绊
--================
function XExpeditionComboList:InitCombos()
    self.Combos = {}
    local childComboList = XExpeditionConfig.GetChildComboTable()
    for id, combo in pairs(childComboList) do
        self.Combos[id] = XCombo.New(combo, self.Team)
    end
    self:InitComboReferences()
end
--================
--初始化所有羁绊的固定关联人员列表
--================
function XExpeditionComboList:InitComboReferences()
    local allCharas = XExpeditionConfig.GetBaseCharacterCfg()
    for eBaseId, eBaseCharaCfg in pairs(allCharas) do
        for _, comboId in pairs(eBaseCharaCfg.ReferenceComboId) do
            if self.Combos[comboId] and self.Combos[comboId]:GetComboTypeId() == COMBOTYPE_TACTICS then
                self.Combos[comboId]:SetDefaultReferenceCharaList(eBaseId)
            end
        end
    end
end
--================
--获取所有羁绊对象列表（包括没激活的）
--================
function XExpeditionComboList:GetAllCombos()
    return self.Combos
end
--================
--获取指定Id的组合对象
--@param comboId:组合ID
--================
function XExpeditionComboList:GetComboByComboId(comboId)
    if not self.Combos[comboId] then
        return nil
    end
    return self.Combos[comboId]
end
--================
--检查队伍羁绊列表
--@param team:队伍
--================
function XExpeditionComboList:CheckCombos(team)
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
                table.insert(self.CurrentCombos, combo)
            end
            combo:AddCheckList(teamChara)
        end
    end
    self:CheckActiveStatus()
end
--================
--获取所有现在关联的羁绊列表（包括没激活的）
--================
function XExpeditionComboList:GetCurrentCombos(team)
    self:CheckCombos(team)
    return self.CurrentCombos
end
--================
--重置当前组合状态列表的所有组合检查列表
--================
function XExpeditionComboList:ResetComboCheckList()
    if not self.CurrentCombos then return end
    for _, combo in pairs(self.Combos) do
        combo:ResetCheckList()
    end
end
--================
--刷新当前组合状态列表的所有组合状态
--================
function XExpeditionComboList:CheckActiveStatus()
    for _, combo in pairs(self.CurrentCombos) do
        combo:Check()
    end
end
--================
--获取角色有效的羁绊ID列表
--================
function XExpeditionComboList:GetActiveComboIdsByEChara(eChara)
    local previewList = {}
    
    local comboIds = eChara:GetCharacterComboIds()
    for _, comboId in pairs(comboIds) do
        local combo = self:GetComboByComboId(comboId)
        --if combo:GetComboActive() then
            table.insert(previewList, comboId)
        --end
    end
    return previewList
end
--================
--返回招募时的预览羁绊ID列表
--================
function XExpeditionComboList:GetPreviewCombosWhenRecruit(eChara)
    local previewList = {}
    local comboIds = eChara:GetCharacterComboIds()
    for _, comboId in pairs(comboIds) do
        local combo = self:GetComboByComboId(comboId)
        combo:PreviewCheckNew(eChara)
        --if combo:GetPreActive() then
            table.insert(previewList, comboId)
        --end
    end
    return previewList
end
return XExpeditionComboList