--------------------XUiSkillGrid 技能格子--------------------
local XUiSkillGrid = XClass(nil, "XUiSkillGrid")

function XUiSkillGrid:Ctor(ui, index, clickCb, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ClickCb = clickCb
    self.Index = index
    self.RootUi = rootUi
    self.Btn = self.Transform:GetComponent("XUiButton")
    self.Disable = XUiHelper.TryGetComponent(self.Transform, "Disable")
    self.Enable = XUiHelper.TryGetComponent(self.Transform, "Activation")
    self.Select = XUiHelper.TryGetComponent(self.Transform, "Select")
    self.Lock = XUiHelper.TryGetComponent(self.Transform, "Lock")
    self.ActiveEffect = XUiHelper.TryGetComponent(self.Transform, "Activation/Effect")

    self.ActiveEffect.gameObject:SetActiveEx(false)
    self:SetSelectStateActive(false)
    XUiHelper.RegisterClickEvent(self, self.Btn, handler(self, self.OnClickIcon))
end

function XUiSkillGrid:Refresh(strengthenId, activeSkillId)
    self.StrengthenId = strengthenId
    self.Btn:SetRawImage(XBiancaTheatreConfigs.GetStrengthenIcon(strengthenId))

    --是否已购买激活
    local isBuy = XDataCenter.BiancaTheatreManager.IsBuyStrengthen(strengthenId)
    local unlock = XDataCenter.BiancaTheatreManager.CheckStrengthenUnlock(strengthenId)
    self.Disable.gameObject:SetActiveEx(unlock and not isBuy)
    self.Enable.gameObject:SetActiveEx(unlock and isBuy)
    self.Lock.gameObject:SetActiveEx(not unlock and not isBuy)
    self:CheckIsActiveEffect(activeSkillId)
end

function XUiSkillGrid:OnClickIcon()
    local groupId = XBiancaTheatreConfigs.GetStrengthenGroupId(self.StrengthenId)
    local preGroupId = XBiancaTheatreConfigs.GetStrengthenGroupPreStrengthenGroupId(groupId)
    local isUnlock = XDataCenter.BiancaTheatreManager.IsStrengthenGroupAllBuy(preGroupId)
    if not isUnlock then
        return
    end
    if self.ClickCb then
        self.ClickCb(self)
    end
    self:SetSelectStateActive(true)
end

function XUiSkillGrid:GetStrengthenId()
    return self.StrengthenId
end

function XUiSkillGrid:GetIndex()
    return self.Index
end

--按钮的选中图标是否显示
function XUiSkillGrid:SetSelectStateActive(isActive)
    if self.Select then
        self.Select.gameObject:SetActiveEx(isActive)
    end
end

--检查激活特效是否显示
function XUiSkillGrid:CheckIsActiveEffect(activeId)
    local isShow = self:GetStrengthenId() == activeId
    self.ActiveEffect.gameObject:SetActiveEx(isShow)
    if isShow then
        XScheduleManager.ScheduleOnce(function()
            if XTool.UObjIsNil(self.GameObject) then
                return
            end
            self.ActiveEffect.gameObject:SetActiveEx(false)
            self.RootUi:SetCurActiveSkillId(0)
        end, 1000)
    end
end


----------肉鸽玩法二期 外循环强化系统 技能面板-------------
local XUiSkillPanel = XClass(nil, "XUiSkillPanel")

local SKILL_GRID_COUNT = 8
local SKILL_PANEL_COUNT = 3

function XUiSkillPanel:Ctor(ui, rootUi, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCb = clickCb
    XUiHelper.InitUiClass(self, ui)

end

function XUiSkillPanel:Init()
    self.SkillGridList = {}
    local btn
    for i = 1, SKILL_GRID_COUNT do
        btn = self["Icon" .. i]
        if btn then
            local skillNode = btn.gameObject:LoadPrefab(XBiancaTheatreConfigs.GetStrengthenSkillNodePrefab())
            table.insert(self.SkillGridList, XUiSkillGrid.New(skillNode, i, handler(self, self.OnClickIcon), self.RootUi))
        end
    end
end

function XUiSkillPanel:Refresh(strengthenGroupId, activeSkillId)
    XTool.InitUiObjectByUi(self, self["GirdSkillPanel" .. strengthenGroupId])
    self:Init()
    for i = 1, SKILL_PANEL_COUNT do
        self["GirdSkillPanel" .. i].gameObject:SetActiveEx(strengthenGroupId == i)
    end
    
    self.StrengthenGroupId = strengthenGroupId
    self.RawImgTitle:SetRawImage(XBiancaTheatreConfigs.GetStrengthenGroupTitleAsset(strengthenGroupId))
    self.RawImgLevel:SetRawImage(XBiancaTheatreConfigs.GetStrengthenGroupLevelAsset(strengthenGroupId))

    self.StrengthenIdList = XBiancaTheatreConfigs.GetStrengthenIdList(strengthenGroupId)
    self:UpdateSkillGrids(activeSkillId)

    --隐藏/显示格子
    for i, grid in ipairs(self.SkillGridList) do
        local id = self.StrengthenIdList[i]
        grid.GameObject:SetActiveEx(XTool.IsNumberValid(id))
    end
end

function XUiSkillPanel:UpdateSkillGrids(activeSkillId)
    local strengthenIdList = self.StrengthenIdList
    local isActive, unlocked
    local skillGrid
    
    for i = 1, SKILL_GRID_COUNT do
        local line = self["Line" .. i]
        if line then
            line.gameObject:SetActiveEx(false)
        end
    end

    for index, strengthenId in ipairs(strengthenIdList) do
        isActive = XDataCenter.BiancaTheatreManager.IsBuyStrengthen(strengthenId)
        unlocked = XDataCenter.BiancaTheatreManager.CheckStrengthenUnlock(strengthenId)
        --更新格子
        skillGrid = self.SkillGridList[index]
        if skillGrid then
            skillGrid:Refresh(strengthenId, activeSkillId)
        end

        --更新线段是否显示
        local linesIndex = XBiancaTheatreConfigs.GetStrengthenActiveLinesIndex(strengthenId)
        for _, lineIndex in ipairs(linesIndex) do
            local line = self["Line" .. lineIndex]
            if line then
                line.gameObject:SetActiveEx(true)
                local activeLine = XUiHelper.TryGetComponent(line.transform, "LineActive")   --已激活的线段
                local unlockLine = XUiHelper.TryGetComponent(line.transform, "LineUnLock")   --已解锁的线段
                local lockedLine = XUiHelper.TryGetComponent(line.transform, "LineLocked")   --未解锁的线段
                activeLine.gameObject:SetActiveEx(isActive)
                unlockLine.gameObject:SetActiveEx(not isActive and unlocked)
                lockedLine.gameObject:SetActiveEx(not isActive and not unlocked)
            end
        end
    end
end

function XUiSkillPanel:OnClickIcon(skillGrid)
    if self.ClickCb then
        self.ClickCb(skillGrid)
    end
    
    self:CancelSelectGrid()
    self.CurSelectSkillGrid = skillGrid
end

function XUiSkillPanel:CancelSelectGrid()
    if self.CurSelectSkillGrid then
        self.CurSelectSkillGrid:SetSelectStateActive(false)
        self.CurSelectSkillGrid = nil
    end
end

return XUiSkillPanel