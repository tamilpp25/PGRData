--######################## XUiSkillGrid ########################
local XUiSkillGrid = XClass(nil, "XUiSkillGrid")

function XUiSkillGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.ClickCallBack = nil
    self.Skill = nil
    XUiHelper.RegisterClickEvent(self, self.BtnSelf, self.OnBtnSelfClicked)
end

-- skill : XSCSkill
function XUiSkillGrid:SetData(skill, index)
    self.Skill = skill
    self.RImgSkillIcon:SetRawImage(skill:GetIcon())
    self.RImgSkillIcon.gameObject:SetActiveEx(true)
    if self.PanelEmpty then
        self.PanelEmpty.gameObject:SetActiveEx(false)
    end
end

function XUiSkillGrid:SetClickCallBack(callback)
    self.ClickCallBack = callback
end

function XUiSkillGrid:SetIsEmpty(value)
    if value then
        self.Skill = nil
    end
    if self.PanelEmpty then
        self.RImgSkillIcon.gameObject:SetActiveEx(false)
        self.PanelEmpty.gameObject:SetActiveEx(true)
    end
end

function XUiSkillGrid:SetSelectStatus(value)
    self.PanelSelect.gameObject:SetActiveEx(value)
end

function XUiSkillGrid:OnBtnSelfClicked(playAnim)
    if self.ClickCallBack then
        self.ClickCallBack(self.Skill, self, playAnim)
    end
end

function XUiSkillGrid:GetSkill()
    return self.Skill
end

--######################## XUiSelectSkillGrid ########################
local XUiSelectSkillGrid = XClass(nil, "XUiSelectSkillGrid")

function XUiSelectSkillGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.Index = nil
end

-- skill : XSCRoleSkill
function XUiSelectSkillGrid:SetData(skill, index)
    self.Index = index
    self.RImgIcon:SetRawImage(skill:GetIcon())
    self.TxtName.text = skill:GetName()
    self.PanelSelected.gameObject:SetActiveEx(false)
end

function XUiSelectSkillGrid:SetSelectStatus(value)
    self.PanelSelected.gameObject:SetActiveEx(value)
end

function XUiSelectSkillGrid:GetIndex()
    return self.Index
end

function XUiSelectSkillGrid:PlayEnableAnim()
    self.AnimEnable:Play()
end

function XUiSelectSkillGrid:PlayUnloadAnim()
    self.AnimUnload:Play()
end

--######################## XUiSameColorGamePanelReady ########################
local XUiSameColorGamePanelReady = XClass(nil, "XUiSameColorGamePanelReady")

local MaxSkillGridCount = 3

function XUiSameColorGamePanelReady:Ctor(ui, rootUi)
    self.SameColorGameActivity = XDataCenter.SameColorActivityManager
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.RootUi = rootUi
    -- XSCRole
    self.Role = nil
    -- XSCBoss
    self.Boss = nil
    self.SelectSkills = nil
    self.CurrentEquipSkillIndex = nil
    self:RegisterUiEvents()
    -- 可选择技能列表
    self.DynamicTable = XDynamicTableNormal.New(self.SelectSkillList)
    self.DynamicTable:SetProxy(XUiSelectSkillGrid)
    self.DynamicTable:SetDelegate(self)
    self.SelectSkillGrid.gameObject:SetActiveEx(false)
    self.CurrentSelectSkillIndex = nil
    -- 使用中的技能
    self.SkillGrid0 = XUiSkillGrid.New(self.GridMainSkillItem, self)
    self.SkillGrid1 = XUiSkillGrid.New(self.GridSkillItem1, self)
    self.SkillGrid2 = XUiSkillGrid.New(self.GridSkillItem2, self)
    self.SkillGrid3 = XUiSkillGrid.New(self.GridSkillItem3, self)
end

-- role : XSCRole
function XUiSameColorGamePanelReady:SetData(role, boss)
    self.Role = role
    self.Boss = boss
    self.CurrentSelectSkillIndex = nil
    local usingSkillGroupIds = role:GetUsingSkillGroupIds()
    self:RefreshRoleSkills(usingSkillGroupIds)
    self:RefreshSelectSkills()
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
    if skillCount >= XSameColorGameConfigs.RoleMaxSkillCount then
        self.CurrentEquipSkillIndex = nil
    else
        self.CurrentEquipSkillIndex = firstZeroIndex or 1
    end
    self:ActiveGridSelectStatus(self["SkillGrid" .. (self.CurrentEquipSkillIndex or -1)])
end

function XUiSameColorGamePanelReady:RefreshRoleSkills(skillGroupIds)
    skillGroupIds = skillGroupIds or self.Role:GetUsingSkillGroupIds()
    local gridClickHandler = handler(self, self.OnSkillGridClicked)
    self.SkillGrid0:SetData(self.Role:GetMainSkill())
    self.SkillGrid0:SetClickCallBack(gridClickHandler)
    local skillGroupId, skillGrid
    for i = 1, MaxSkillGridCount do
        skillGroupId = skillGroupIds[i]
        skillGrid = self["SkillGrid" .. i]
        if skillGroupId and skillGroupId > 0 then
            skillGrid:SetData(self.SameColorGameActivity.GetRoleShowSkill(skillGroupId))
        else
            skillGrid:SetIsEmpty(true)
        end
        skillGrid:SetClickCallBack(gridClickHandler)
    end
end

function XUiSameColorGamePanelReady:OnSkillGridClicked(skill, grid, playAnim)
    if playAnim == nil then playAnim = true end
    if playAnim then 
        self:PlaySelectSkillsAnim()
    end
    -- 设置技能选中状态
    self.CurrentEquipSkillIndex = self:ActiveGridSelectStatus(grid)
    if not skill then return end
    XLuaUiManager.Open("UiSameColorGamePopupTwo", self.Role, skill, self.CurrentEquipSkillIndex, handler(self, self.OnPopupCloseCallBack))
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

function XUiSameColorGamePanelReady:OnPopupCloseCallBack(isUpdated, skillGroupId)
    if isUpdated then
        self:RefreshSelectSkills(skillGroupId)
        self:RefreshRoleSkills()
    end
    self.CurrentSelectSkillIndex = nil
    for _, v in ipairs(self.DynamicTable:GetGrids()) do
        v:SetSelectStatus(false)
    end
end

function XUiSameColorGamePanelReady:ActiveGridSelectStatus(grid)
    local skillGrid, isActive, activeIndex
    for i = 0, MaxSkillGridCount do
        skillGrid = self["SkillGrid" .. i]
        isActive = grid == skillGrid
        skillGrid:SetSelectStatus(isActive)
        if isActive then
            activeIndex = i
        end
    end
    return activeIndex
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

function XUiSameColorGamePanelReady:OnDynamicTableEvent(event, index, grid)
    local skill = self.SelectSkills[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(skill, index)
        grid:SetSelectStatus(self.CurrentSelectSkillIndex == index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurrentSelectSkillIndex = index
        for _, v in ipairs(self.DynamicTable:GetGrids()) do
            v:SetSelectStatus(v:GetIndex() == self.CurrentSelectSkillIndex)
        end
        XLuaUiManager.Open("UiSameColorGamePopup", self.Role, skill, self.CurrentEquipSkillIndex, handler(self, self.OnPopupCloseCallBackWithEquip))
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

function XUiSameColorGamePanelReady:RegisterUiEvents()
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
    self.SameColorGameActivity.OpenShopUi()
end

return XUiSameColorGamePanelReady