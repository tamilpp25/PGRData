local XUiInstruction = require('XUi/XUiSet/XUiInstruction')
local XUiInstructionLinkItem = require('XUi/XUiSet/ChildItem/XUiInstructionLinkItem')
---@class XUiInstructionLink
---@field private _Control XLinkCraftActivityControl
local XUiInstructionLink = XClass(XUiInstruction,'XUiInstructionLink')

local TabType={
    Skill = 1,
    Link = 2,
}

function XUiInstructionLink:OnStart()
    self.Super.OnStart(self)
    self.TabBtnGroup:InitBtns(self.TabBtnGroup.TabBtnList:ToArray(),handler(self,self.OnBtnGroupClick))
    self:InitLinkPanel()
    self.TabBtnGroup:SelectIndex(1)
end

function XUiInstructionLink:InitLinkPanel()
    self._LinkPanel = {}
    XTool.InitUiObjectByUi(self._LinkPanel,self.PanelLink)
    self._SkillCtrl = {}
    
    local curLinkData = self._Control:GetCurLinkListData()

    if XTool.IsTableEmpty(curLinkData) then
        curLinkData = self._Control:GetLastSelectChapterLinkData()
        if XTool.IsTableEmpty(curLinkData) then
            XLog.Error('当前链条数据获取失败')
            self:Close()
            return
        end
    end
    
    local skillIds = curLinkData:GetSkillList()
    
    for i = 1, 100 do
        local gridLink = self._LinkPanel['GridLink'..i]
        if gridLink then
            if XTool.IsNumberValid(skillIds[i]) then
                local ctrl = XUiInstructionLinkItem.New(gridLink, self, skillIds[i])
                ctrl:Open()
                table.insert(self._SkillCtrl, ctrl)
            else
                gridLink.gameObject:SetActiveEx(false)
            end
        else
            break
        end
    end
end

function XUiInstructionLink:OnBtnGroupClick(index)
    self.PanelSkill.gameObject:SetActiveEx(index == TabType.Skill)
    self.PanelLink.gameObject:SetActiveEx(index == TabType.Link)
    
    if index == TabType.Skill then
            
    elseif index == TabType.Link then
        
    end
end

return XUiInstructionLink