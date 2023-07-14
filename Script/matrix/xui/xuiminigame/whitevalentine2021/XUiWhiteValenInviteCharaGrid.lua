-- 白色情人节约会活动成员资料牌UI控件
local XUiWhiteValenInviteCharaGrid = XClass(nil, "XUiWhiteValenInviteCharaGrid")
--================
--构造函数(作为动态列表组件初始化时不在这里做)
--================
function XUiWhiteValenInviteCharaGrid:Ctor(ui, chara)
    if ui then XTool.InitUiObjectByUi(self, ui) end
    self:RefreshData(chara)
end
--================
--刷新数据
--@param chara:活动角色对象
--@param gridIndex:控件序号
--================
function XUiWhiteValenInviteCharaGrid:RefreshData(chara)
    if not chara then
        return
    end
    self.Chara = chara
    self:SetChara()
end
--================
--设置角色数据
--================
function XUiWhiteValenInviteCharaGrid:SetChara()
    self.TxtName.text = self.Chara:GetName()
    self.RImgIcon:SetRawImage(self.Chara:GetIconPath())
    self.RImgAttr:SetRawImage(self.Chara:GetAttrIcon())
    self.TxtValues.text = self.Chara:GetAttrValue()
end

return XUiWhiteValenInviteCharaGrid