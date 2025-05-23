local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by heyupeng.
--- DateTime: 2024/6/4 9:58
---

local PanelType = {
    Skill = 1,
    Buff = 2,
}

local XUiSucceedBossPopupSkillGridItem = require("XUi/XUiSucceedBoss/XUiSucceedBossPopupSkillGridItem")
local XUiSucceedBossPopupSkill = XLuaUiManager.Register(XLuaUi, "UiSucceedBossPopupSkill")

--重写父类方法
function XUiSucceedBossPopupSkill:OnAwake()

end

function XUiSucceedBossPopupSkill:OnStart()
    self:InitAutoScript()
end

function XUiSucceedBossPopupSkill:OnEnable(isSkillTag, selectMonsterIndex)
    self.IsSkillTag = isSkillTag and true or false
    self.SelectMonsterIndex = selectMonsterIndex
    self:InitData()
    self:Refresh()
end

function XUiSucceedBossPopupSkill:InitAutoScript()
    self:AutoAddListener()
    self.BtnGroupBtns = { self.BtnTabTask1 }
    self.BtnTabTask2.gameObject:SetActiveEx(false)
    --for i = 1, 2 do
    --    table.insert(self.BtnGroupBtns, self["BtnTabTask" .. i])
    --end
    self.BtnGroup:Init(self.BtnGroupBtns, function(index)
        self:OnBtnTabClick(index)
    end)

    self.DynamicTableSkill = XDynamicTableNormal.New(self.PanelSkill)
    self.DynamicTableSkill:SetProxy(XUiSucceedBossPopupSkillGridItem, self._Control)
    self.DynamicTableSkill:SetDelegate({
        OnDynamicTableEvent = function(proxy, event, index, grid)
            if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
                grid:Refresh(self.DynamicTableSkill:GetData(index))
            end
        end
    })

    --self.DynamicTableBuff = XDynamicTableNormal.New(self.PanelBuff)
    --self.DynamicTableBuff:SetProxy(XUiSucceedBossPopupSkillGridItem, self._Control)
    --self.DynamicTableBuff:SetDelegate({
    --    OnDynamicTableEvent = function(proxy, event, index, grid)
    --        if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
    --            grid:Refresh(self.BuffFightEventIds[index])
    --        end
    --    end
    --})
end

function XUiSucceedBossPopupSkill:AutoAddListener()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnTanchuangCloseClick)
end

function XUiSucceedBossPopupSkill:OnBtnTanchuangCloseClick()
    self:Close()
end

function XUiSucceedBossPopupSkill:OnBtnTabClick(index)
    if self._CurSelectPanel == index then
        return
    end

    --if index == PanelType.Skill then
    self.PanelSkill.gameObject:SetActiveEx(true)
    self.PanelBuff.gameObject:SetActiveEx(false)
    local dataSource = XTool.MergeArray(self.SkillFightEventIds, self.BuffFightEventIds)
    self.DynamicTableSkill:SetDataSource(dataSource)
    self.DynamicTableSkill:ReloadDataASync()
    --elseif index == PanelType.Buff then
    --    self.PanelSkill.gameObject:SetActiveEx(false)
    --    self.PanelBuff.gameObject:SetActiveEx(true)
    --    self.DynamicTableBuff:SetDataSource(self.BuffFightEventIds)
    --    self.DynamicTableBuff:ReloadDataASync()
    --end

    self._CurSelectPanel = index
end

function XUiSucceedBossPopupSkill:InitData()
    self.SkillFightEventIds = {}
    self.BuffFightEventIds = {}
    if XTool.IsNumberValid(self.SelectMonsterIndex) then
        self.SkillFightEventIds = self._Control:GetCurrentSkillFightEventIdsOptional(self.SelectMonsterIndex)
        self.BuffFightEventIds = self._Control:GetCurrentBuffFightEventIdsOptional(self.SelectMonsterIndex)
    else
        self.SkillFightEventIds = self._Control:GetCurrentSkillFightEventIds()
        self.BuffFightEventIds = self._Control:GetCurrentBuffFightEventIds()
    end

    self._CurSelectPanel = 0
end

function XUiSucceedBossPopupSkill:Refresh()
    --self:RefreshBtnTabActive()
    self.BtnGroup:SelectIndex(PanelType.Skill)
    --if self.IsSkillTag then
    --    self.BtnGroup:SelectIndex(PanelType.Skill)
    --else
    --    self.BtnGroup:SelectIndex(PanelType.Buff)
    --end
end

--function XUiSucceedBossPopupSkill:RefreshPanel(rootTransform, gridGo, container, datas)
--    XUiHelper.RefreshCustomizedList(rootTransform, gridGo, XTool.GetTableCount(datas), function(index, go)
--        local gridSkillItem = container[index]
--        if gridSkillItem == nil then
--            gridSkillItem = XUiSucceedBossPopupSkillGridItem.New(go, self)
--            container[index] = gridSkillItem
--        end
--        gridSkillItem:Open()
--        gridSkillItem:Refresh(datas[index])
--    end)
--end

--function XUiSucceedBossPopupSkill:RefreshBtnTabActive()
--    self.BtnGroupBtns[PanelType.Skill].gameObject:SetActiveEx(not XTool.IsTableEmpty(self.SkillFightEventIds))
--    self.BtnGroupBtns[PanelType.Buff].gameObject:SetActiveEx(not XTool.IsTableEmpty(self.BuffFightEventIds))
--end

--function XUiSucceedBossPopupSkill:OnDynamicTableEvent(event, index, grid)
--    local data = {}
--
--    if self._CurSelectPanel == PanelType.Skill then
--        data = self.SkillFightEventIds
--    elseif self._CurSelectPanel == PanelType.Buff then
--        data = self.BuffFightEventIds
--    end
--
--    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
--        grid:Refresh(data[index])
--    end
--end

return XUiSucceedBossPopupSkill