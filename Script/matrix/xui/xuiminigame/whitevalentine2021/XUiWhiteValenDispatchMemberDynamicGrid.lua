local XSuper = require("XUi/XUiMiniGame/WhiteValentine2021/XUiWhiteValenInviteCharaGrid")
--
local XUiWhiteValenDispatchMemberDynamicGrid = XClass(XSuper, "XUiWhiteValenDispatchMemberDynamicGrid")

--================
--构造函数(动态列表组件初始化时不在这里做)
--================
function XUiWhiteValenDispatchMemberDynamicGrid:Ctor()

end
--================
--初始化
--================
function XUiWhiteValenDispatchMemberDynamicGrid:Init(dTable, ui)
    self.DynamicTable = dTable
    XTool.InitUiObjectByUi(self, ui)
end
--================
--刷新数据
--@param chara:活动角色对象
--@param gridIndex:控件序号
--================
function XUiWhiteValenDispatchMemberDynamicGrid:RefreshData(chara, gridIndex)
    if not chara then
        return
    end
    self.Chara = chara
    if gridIndex then self.GridIndex = gridIndex end
    self:SetChara()
    self:SetIsSelect(false)
    self:SetDispatch()
end
--================
--设置是否被派遣
--@param isDispatch:是否被派遣
--================
function XUiWhiteValenDispatchMemberDynamicGrid:SetDispatch()
    self.CharaDispatch.gameObject:SetActiveEx(self.Chara:GetDispatching())
end
--================
--设置是否被选择
--@param isSelect:是否被选择
--================
function XUiWhiteValenDispatchMemberDynamicGrid:SetIsSelect(isSelect)
    self.ItemSele.gameObject:SetActiveEx(isSelect)
end
--================
--点击时
--================
function XUiWhiteValenDispatchMemberDynamicGrid:OnClick()
    if self.Chara:GetDispatching() then
        XUiManager.TipMsg(CS.XTextManager.GetText("WhiteValentineCharaIsDispatching"))
        return
    end
    self.DynamicTable:SetSelect(self)
    self:SetIsSelect(true)
end
return XUiWhiteValenDispatchMemberDynamicGrid