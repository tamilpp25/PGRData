local XUiSSBMonsterListGrid = XClass(nil, "XUiSSBMonsterListGrid")

function XUiSSBMonsterListGrid:Ctor(uiPrefab)
    
end

function XUiSSBMonsterListGrid:Init(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:SetSelect(false)
end

--================
--刷新数据
--================
function XUiSSBMonsterListGrid:Refresh(data, index)
    self.MonsterGroup = data
    self.Index = index
    self.RImgHeadIcon:SetRawImage(self.MonsterGroup:GetIcon())
    self.TxtAbility.text = self.MonsterGroup:GetAbility()
    self.TxtCareer.text = self.MonsterGroup:GetMonsterTypeName()
    --local mainMonster =
    --self.TxtCareer.text = ""--self.MonsterGroup:Get()
    --self:SetCore()
end
--================
--设置核心
--================
function XUiSSBMonsterListGrid:SetCore()
    local core = self.CharaData:GetCore()
    self.PanelCoreIn.gameObject:SetActiveEx(core ~= nil)
    self.PanelCoreOut.gameObject:SetActiveEx(core == nil)
    if core then
        self.RImgCoreIcon:SetRawImage(core:GetIcon())
    end
end
--================
--设置被选中状态
--================
function XUiSSBMonsterListGrid:SetSelect(value)
    self.PanelSelected.gameObject:SetActiveEx(value)
end
--================
--设置红点状态
--================
function XUiSSBMonsterListGrid:SetRedPoint(value)
    self.ImgRedPoint.gameObject:SetActiveEx(value)
end
--================
--点击时
--================
function XUiSSBMonsterListGrid:OnClick()

end
--================
--获取序号
--================
function XUiSSBMonsterListGrid:GetIndex()
    return self.Index
end
--================
--获取角色对象
--================
function XUiSSBMonsterListGrid:GetMonster()
    return self.MonsterGroup
end

return XUiSSBMonsterListGrid