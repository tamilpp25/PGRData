local XUiSameColorGameGridRoleSkill = require("XUi/XUiSameColorGame/BattleReady/XUiSameColorGameGridRoleSkill")
local XUiSameColorGameGridSkillSelect = require("XUi/XUiSameColorGame/BattleReady/XUiSameColorGameGridSkillSelect")

---@class XUiSameColorGamePanelReady
local XUiSameColorGamePanelReady = XClass(nil, "XUiSameColorGamePanelReady")

local MaxSkillGridCount = 3

---@param rootUi XUiSameColorGameBoss
function XUiSameColorGamePanelReady:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
    ---@type XSCRole
    self.Role = nil
    ---@type XSCBoss
    self.Boss = nil
    self.SameColorGameActivity = XDataCenter.SameColorActivityManager
    
    self.CurrentEquipSkillIndex = nil
    self:AddBtnListener()
    self:InitSkillSelect()
    self:InitRoleSkill()
end

---@param role XSCRole
---@param boss XSCBoss
function XUiSameColorGamePanelReady:SetData(role, boss)
    self.Role = role
    self.Boss = boss
    self.CurrentSelectSkillIndex = nil
    local usingSkillGroupIds = role:GetUsingSkillGroupIds(nil, self.Boss:IsTimeType())
    self:RefreshSelectSkills()
    self:RefreshRoleSkills(usingSkillGroupIds)
    self:RefreshCurSelectSkill(usingSkillGroupIds)
end

--region Ui - SkillSelect
function XUiSameColorGamePanelReady:InitSkillSelect()
    ---@type XSCRoleSkill[]
    self.SelectSkills = nil
    self.CurrentSelectSkillIndex = nil
    
    self.DynamicTable = XDynamicTableNormal.New(self.SelectSkillList)
    self.DynamicTable:SetProxy(XUiSameColorGameGridSkillSelect)
    self.DynamicTable:SetDelegate(self)
    self.SelectSkillGrid.gameObject:SetActiveEx(false)
end

---@param grid XUiSameColorGameGridSkillSelect
function XUiSameColorGamePanelReady:OnDynamicTableEvent(event, index, grid)
    local skill = self.SelectSkills[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        --local isForbid = self.Boss:IsTimeType() and skill:IsForbidInTime()
        grid:SetData(skill, index, false)
        grid:SetSelectStatus(self.CurrentSelectSkillIndex == index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        --local isForbid = self.Boss:IsTimeType() and skill:IsForbidInTime()
        --if isForbid then
        --    XUiManager.TipText("SameColorGameForbidSkillTips")
        --    return
        --end

        self.CurrentSelectSkillIndex = index
        for _, v in pairs(self.DynamicTable:GetGrids()) do
            v:SetSelectStatus(v:GetIndex() == self.CurrentSelectSkillIndex)
        end
        XLuaUiManager.Open("UiSameColorGamePopup", self.Boss, self.Role, skill, self.CurrentEquipSkillIndex, handler(self, self.OnPopupCloseCallBackWithEquip))
    end
end

function XUiSameColorGamePanelReady:RefreshSelectSkills(currentSkillGroupId)
    local allUsableSkillGroupIds = self.SameColorGameActivity.GetAllUsableSkillGroupIds()
    local usingSkillGroupIds = self.Role:GetUsingSkillGroupIds()
    local usingSkillGroupIdDic = {}
    for _, v in ipairs(usingSkillGroupIds) do
        if v > 0 then
            usingSkillGroupIdDic[v] = true
        end
    end
    for i = #allUsableSkillGroupIds, 1, -1 do
        if usingSkillGroupIdDic[allUsableSkillGroupIds[i]] then
            table.remove(allUsableSkillGroupIds, i)
        end
    end
    local selectSkills = {}
    local index = 1
    for i, skillGroupId in ipairs(allUsableSkillGroupIds) do
        if currentSkillGroupId == skillGroupId then
            index = i
        end
        table.insert(selectSkills, self.SameColorGameActivity.GetRoleShowSkill(skillGroupId))
    end
    self.SelectSkills = selectSkills
    self.DynamicTable:SetDataSource(selectSkills)
    self.DynamicTable:ReloadDataSync(index)
    self.PanelNotSkill.gameObject:SetActiveEx(#selectSkills <= 0)
    if currentSkillGroupId and currentSkillGroupId > 0 then
        self.DynamicTable:GetGridByIndex(index):PlayUnloadAnim()
    end
end

function XUiSameColorGamePanelReady:OnPopupCloseCallBackWithEquip(isUpdated, skillGroupId)
    self:OnPopupCloseCallBack(isUpdated, skillGroupId)
    if isUpdated then
        -- 从头开始找到空的设置选中，如果没有不处理
        local skillGrid
        for i = 1, 3 do
            skillGrid = self["SkillGrid" .. i]
            if skillGrid:GetSkill() == nil then
                skillGrid:OnBtnSelfClicked(false)
                return
            end
        end
    end
end

function XUiSameColorGamePanelReady:PlaySelectSkillsAnim()
    local gridDic = self.DynamicTable:GetGrids()
    if XTool.IsTableEmpty(gridDic) then return end
    local grids = table.dicToArray(gridDic)
    table.sort(grids, function(gridA, gridB)
        return gridA.key < gridB.key
    end)
    local gridIndex = 1
    local grid = grids[gridIndex]
    if not grid then return end
    XScheduleManager.Schedule(function()
        grid = grids[gridIndex].value
        if grid then grid:PlayEnableAnim() end
        gridIndex = gridIndex + 1
    end, 10, #grids, 0)
end
--endregion

--region Ui - RoleSkill
function XUiSameColorGamePanelReady:InitRoleSkill()
    ---@type XUiSameColorGameGridRoleSkill
    self.SkillGrid0 = XUiSameColorGameGridRoleSkill.New(self.GridMainSkillItem, self)
    ---@type XUiSameColorGameGridRoleSkill
    self.SkillGrid1 = XUiSameColorGameGridRoleSkill.New(self.GridSkillItem1, self)
    ---@type XUiSameColorGameGridRoleSkill
    self.SkillGrid2 = XUiSameColorGameGridRoleSkill.New(self.GridSkillItem2, self)
    ---@type XUiSameColorGameGridRoleSkill
    self.SkillGrid3 = XUiSameColorGameGridRoleSkill.New(self.GridSkillItem3, self)
end

function XUiSameColorGamePanelReady:RefreshRoleSkills(skillGroupIds)
    skillGroupIds = skillGroupIds or self.Role:GetUsingSkillGroupIds()
    local gridClickHandler = handler(self, self.OnSkillGridClicked)
    self.SkillGrid0:SetData(self.Role:GetMainSkill())
    self.SkillGrid0:SetClickCallBack(gridClickHandler)

    local skillGroupId
    for i = 1, MaxSkillGridCount do
        skillGroupId = skillGroupIds[i]
        ---@type XUiSameColorGameGridRoleSkill
        local skillGrid = self["SkillGrid" .. i]
        if skillGroupId and skillGroupId > 0 then
            skillGrid:SetData(self.SameColorGameActivity.GetRoleShowSkill(skillGroupId))
        else
            skillGrid:SetIsEmpty(true)
        end
        skillGrid:SetClickCallBack(gridClickHandler)
    end
end

function XUiSameColorGamePanelReady:RefreshCurSelectSkill(usingSkillGroupIds)
    -- 设置默认选中的技能
    local skillCount = 0
    local firstZeroIndex = nil
    for i, v in ipairs(usingSkillGroupIds) do
        if v > 0 then
            skillCount = skillCount + 1
        elseif v <= 0 and firstZeroIndex == nil then
            firstZeroIndex = i
        end
    end
    -- 如果达到最大技能数量，默认不选中
    if skillCount >= XEnumConst.SAME_COLOR_GAME.ROLE_MAX_SKILL_COUNT then
        self.CurrentEquipSkillIndex = nil
    else
        self.CurrentEquipSkillIndex = firstZeroIndex or 1
    end
    self:ActiveGridSelectStatus(self["SkillGrid" .. (self.CurrentEquipSkillIndex or -1)])
end

function XUiSameColorGamePanelReady:OnSkillGridClicked(skill, grid, playAnim)
    if playAnim == nil then playAnim = true end
    if playAnim then
        self:PlaySelectSkillsAnim()
    end
    -- 设置技能选中状态
    self.CurrentEquipSkillIndex = self:ActiveGridSelectStatus(grid)
    if not skill then return end
    XLuaUiManager.Open("UiSameColorGamePopupTwo", self.Role, skill, self.CurrentEquipSkillIndex, self.Boss:IsTimeType(), handler(self, self.OnPopupCloseCallBack))
end

function XUiSameColorGamePanelReady:OnPopupCloseCallBack(isUpdated, skillGroupId)
    if isUpdated then
        self:RefreshSelectSkills(skillGroupId)
        self:RefreshRoleSkills()
    end
    self.CurrentSelectSkillIndex = nil
    for _, v in pairs(self.DynamicTable:GetGrids()) do
        v:SetSelectStatus(false)
    end
end

---@param grid XUiSameColorGameGridRoleSkill
function XUiSameColorGamePanelReady:ActiveGridSelectStatus(grid)
    local isActive, activeIndex
    for i = 0, MaxSkillGridCount do
        ---@type XUiSameColorGameGridRoleSkill
        local skillGrid = self["SkillGrid" .. i]
        isActive = grid == skillGrid
        skillGrid:SetSelectStatus(isActive)
        if isActive then
            activeIndex = i
        end
    end
    return activeIndex
end
--endregion

--region Ui - BtnListener
function XUiSameColorGamePanelReady:AddBtnListener()
    self.BtnStart.CallBack = function() self:OnBtnStartClicked() end
    self.BtnShop.CallBack = function() self:OnBtnShopClicked() end
end

function XUiSameColorGamePanelReady:OnBtnStartClicked()
    self.SameColorGameActivity.RequestEnterStage(self.Role:GetId(), self.Boss:GetId(), self.Role:GetUsingSkillGroupIds(true), function (actionsList)
        self.SameColorGameActivity:ClearMainUiModelInfo()
        XLuaUiManager.PopThenOpen("UiSameColorGameBattle", self.Role, self.Boss)
    end)
end

function XUiSameColorGamePanelReady:OnBtnShopClicked()
    self.RootUi._Control:OpenShop()
end
--endregion

return XUiSameColorGamePanelReady