local XSuper = require("XUi/XUiMiniGame/WhiteValentine2021/XUiWhiteValenInviteCharaGrid")
-- 白色情人节约会活动邀约界面成员动态列表组件控件
local XUiWhiteValenInviteMemberDynamicGrid = XClass(XSuper, "XUiWhiteValenInviteMemberDynamicGrid")
--================
--构造函数(动态列表组件初始化时不在这里做)
--================
function XUiWhiteValenInviteMemberDynamicGrid:Ctor()

end
--================
--初始化
--================
function XUiWhiteValenInviteMemberDynamicGrid:Init(dTable, ui)
    self.DynamicTable = dTable
    XTool.InitUiObjectByUi(self, ui)
end
--================
--刷新数据
--@param chara:活动角色对象
--@param gridIndex:控件序号
--================
function XUiWhiteValenInviteMemberDynamicGrid:RefreshData(chara, gridIndex)
    if not chara then
        return
    end
    self.Chara = chara
    if gridIndex then self.GridIndex = gridIndex end
    self:SetChara()
    self:SetIsSelect(false)
end
--================
--设置是否被选择
--@param isSelect:是否被选择
--================
function XUiWhiteValenInviteMemberDynamicGrid:SetIsSelect(isSelect)
    self.ItemSele.gameObject:SetActiveEx(isSelect)
end
--================
--点击时
--================
function XUiWhiteValenInviteMemberDynamicGrid:OnClick()
    self.DynamicTable:SetSelect(self)
    self:SetIsSelect(true)
end

return XUiWhiteValenInviteMemberDynamicGrid