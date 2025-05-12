local Parent = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityChapter/XUiGridLinkCraftActivitySkill')
---编辑界面左边列表里的技能格子
local XUiGridLinkCraftEditSkill = XClass(Parent, 'XUiGridLinkCraftEditSkill')

function XUiGridLinkCraftEditSkill:OnBtnClickEvent()
    
end

function XUiGridLinkCraftEditSkill:ShowErrorIcon(able)
    if self.ImgWrong then
        self.ImgWrong.gameObject:SetActiveEx(able)
    end
end

return XUiGridLinkCraftEditSkill