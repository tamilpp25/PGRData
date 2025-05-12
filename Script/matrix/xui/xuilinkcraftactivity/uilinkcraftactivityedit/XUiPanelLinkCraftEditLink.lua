local Parent = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityChapter/XUiPanelLinkCraftActivityLink')
---管理编辑界面左边链条技能列表的类
---@class XUiPanelLinkCraftEditLink
---@field private _Control XLinkCraftActivityControl
local XUiPanelLinkCraftEditLink = XClass(Parent, 'XUiPanelLinkCraftEditLink')

local XUiGridLinkCraftEditSkill = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityEdit/XUiGridLinkCraftEditSkill')

function XUiPanelLinkCraftEditLink:OnStart()
    self.Super.OnStart(self)
    self.ButtonGroup:InitBtns(self.ButtonGroup.TabBtnList:ToArray(),handler(self,self.OnBtnGroupClick))
end


function XUiPanelLinkCraftEditLink:GetSkillClass()
    return XUiGridLinkCraftEditSkill
end

function XUiPanelLinkCraftEditLink:Init(index)
    self._Control:SetSelectIndex(index)
    self._NeedAnimation = true
    self.ButtonGroup:SelectIndex(self._Control:GetSelectIndex())
end

function XUiPanelLinkCraftEditLink:OnBtnGroupClick(index)
    self._Control:SetSelectIndex(index)
    self:RefreshSkillList()
end

function XUiPanelLinkCraftEditLink:RefreshSkillList()
    self.Parent._ListPanel:Refresh(nil, self._NeedAnimation)
    self._NeedAnimation = false
end

---@overload
function XUiPanelLinkCraftEditLink:Refresh()
    self.Super.Refresh(self)
    ---判断链条有效性
    if self.TxtTips then
        self.TxtTips.gameObject:SetActiveEx(false)
    end
    for i, v in pairs(self._GridSkills) do
        v:ShowErrorIcon(false)
    end
    
    local isValid, errorIndex = self._Control:CheckLinkIsValid()
    self._IsValid = isValid
    if not isValid and self._GridSkills[errorIndex] then
        self._GridSkills[errorIndex]:ShowErrorIcon(true)
        if self.TxtTips then
            self.TxtTips.gameObject:SetActiveEx(true)
        end
        --弹窗提示
        XUiManager.TipMsg(self._Control:GetClientConfigString('LinkOrderingInvalidTips'))
    end
end

return XUiPanelLinkCraftEditLink