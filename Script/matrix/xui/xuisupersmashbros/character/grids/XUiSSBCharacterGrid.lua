--================
--角色页面角色列表项控件
--================
local XUiSSBCharacterGrid = XClass(nil, "XUiSSBCharacterGrid")

function XUiSSBCharacterGrid:Ctor()
    
end
--================
--初始化
--================
function XUiSSBCharacterGrid:Init(gridPrefab)
    XTool.InitUiObjectByUi(self, gridPrefab)
end
--================
--刷新数据
--================
function XUiSSBCharacterGrid:RefreshData(data, index, isInTeam)
    self.CharaData = data
    self.Index = index
    self.ImgInTeam.gameObject:SetActiveEx(isInTeam)
    self.RImgHeadIcon:SetRawImage(self.CharaData:GetSmallHeadIcon())
    self.RImgQuality:SetRawImage(self.CharaData:GetQualityIcon())
    self.TxtAbility.text = self.CharaData:GetAbility()
    self.PanelTry.gameObject:SetActiveEx(self.CharaData:GetIsRobot())
    self:SetCore()
end
--================
--设置核心
--================
function XUiSSBCharacterGrid:SetCore()
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
function XUiSSBCharacterGrid:SetSelect(value)
    self.PanelSelected.gameObject:SetActiveEx(value)
end
--================
--设置红点状态
--================
function XUiSSBCharacterGrid:SetRedPoint(value)
    self.ImgRedPoint.gameObject:SetActiveEx(value)
end
--================
--点击时
--================
function XUiSSBCharacterGrid:OnClick()
    
end
--================
--获取序号
--================
function XUiSSBCharacterGrid:GetIndex()
    return self.Index
end
--================
--获取角色对象
--================
function XUiSSBCharacterGrid:GetChara()
    return self.CharaData
end

return XUiSSBCharacterGrid