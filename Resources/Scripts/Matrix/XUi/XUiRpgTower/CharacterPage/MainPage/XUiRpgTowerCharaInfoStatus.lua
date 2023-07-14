-- 兵器蓝图角色页面角色状态面板属性栏
local XUiRpgTowerCharaInfoStatus = XClass(nil, "XUiRpgTowerCharaInfoStatus")
function XUiRpgTowerCharaInfoStatus:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end
--================
--刷新状态信息
--================
function XUiRpgTowerCharaInfoStatus:RefreshStatus(rCharacter)
    local attr = rCharacter:GetCharaAttributes()
    local attrTypeData = rCharacter:GetDisplayAttrTypeData()
    for i = 1, #attrTypeData do
        self["TxtAttrib" .. i].text = FixToInt(attr[attrTypeData[i].Type])
        self["TxtAttribName" .. i].text = attrTypeData[i].Name
    end
end
return XUiRpgTowerCharaInfoStatus