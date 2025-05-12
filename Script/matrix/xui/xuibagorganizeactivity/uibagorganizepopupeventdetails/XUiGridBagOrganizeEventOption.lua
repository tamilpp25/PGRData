--- 随机事件的选项
---@class XUiGridBagOrganizeEventOption: XUiNode
local XUiGridBagOrganizeEventOption = XClass(XUiNode, 'XUiGridBagOrganizeEventOption')

function XUiGridBagOrganizeEventOption:OnStart()
    self.GridBtn.CallBack = handler(self, self.OnBtnClick)
end

function XUiGridBagOrganizeEventOption:RefreshShow(index, content)
    self.Index = index
    self.GridBtn:SetNameByGroup(0, content)
end

function XUiGridBagOrganizeEventOption:OnBtnClick()
    self.Parent:OnOptionSelect(self.Index)
end

return XUiGridBagOrganizeEventOption