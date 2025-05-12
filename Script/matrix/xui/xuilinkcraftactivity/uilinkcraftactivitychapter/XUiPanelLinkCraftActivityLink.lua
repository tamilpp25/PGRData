---@class XUiPanelLinkCraftActivityLink
---@field private _Control XLinkCraftActivityControl
local XUiPanelLinkCraftActivityLink = XClass(XUiNode, 'XUiPanelLinkCraftActivityLink')
local XUiGridLinkCraftActivitySkill = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityChapter/XUiGridLinkCraftActivitySkill')

function XUiPanelLinkCraftActivityLink:OnStart()
    if self.BtnSwitch then
        self.BtnSwitch.CallBack = handler(self,self.OnBtnSwitchClickEvent)
    end
    self._GridSkills = {}
    self:InitSkillGrids()
end

function XUiPanelLinkCraftActivityLink:OnEnable()
    self:Refresh()
end

function XUiPanelLinkCraftActivityLink:InitSkillGrids()
    local index = 1
    local btnSkill = nil
    local class = self:GetSkillClass()
    repeat
        btnSkill = self['BtnSkill'..index]
        if btnSkill then
            local grid = class.New(btnSkill, self, index)
            grid:Open()
            table.insert(self._GridSkills, grid)
        end
        index = index + 1
    until btnSkill == nil or index > 99999 --限定值防卡死
end

function XUiPanelLinkCraftActivityLink:Refresh()
    local curListData = self._Control:GetCurLinkListData()

    if XTool.IsTableEmpty(curListData) then
        curListData = self._Control:GetLastSelectChapterLinkData()
        if XTool.IsTableEmpty(curListData) then
            XLog.Error('当前链条数据获取失败')
            self:Close()
            return
        end
    end

    if self.BtnSwitch then
        self.BtnSwitch:SetNameByGroup(1, self._Control:GetLinkNameById(curListData:GetId()))
    end

    for i, v in ipairs(self._GridSkills) do
        v:Open()
        v:Refresh(curListData._SkillData[i] or 0)
    end
end

function XUiPanelLinkCraftActivityLink:OnBtnSwitchClickEvent()
    XLuaUiManager.Open('UiLinkCraftActivityEdit', 1)
end

function XUiPanelLinkCraftActivityLink:GetSkillClass()
    return XUiGridLinkCraftActivitySkill
end

return XUiPanelLinkCraftActivityLink