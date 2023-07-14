-- 兵器蓝图角色页面角色状态面板人物信息栏
local XUiRpgTowerCharaInfoInfo = XClass(nil, "XUiRpgTowerCharaInfoInfo")
local XUiRpgTowerStarPanel = require("XUi/XUiRpgTower/Common/XUiRpgTowerStarPanel")
function XUiRpgTowerCharaInfoInfo:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnCareerTips, function() self:OnClickBtnCareerTips() end)
    self.BtnElementDetail.CallBack = function() self:OnClickBtnElementDetail() end
end
--================
--刷新角色信息
--================
function XUiRpgTowerCharaInfoInfo:RefreshInfo(rCharacter)
    self.RChara = rCharacter
    self.RImgTypeIcon:SetRawImage(rCharacter:GetJobTypeIcon())
    self.TxtName.text = rCharacter:GetCharaName()
    self.TxtAbility.text = rCharacter:GetAbility()
    self.TxtNameOther.text = rCharacter:GetModelName()
    local elementList = rCharacter:GetElements()
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if rImg and elementList[i] then
            rImg.transform.gameObject:SetActive(true)
            rImg:SetRawImage(elementList[i].Icon)
        elseif rImg then
            rImg.transform.gameObject:SetActive(false)
        end
    end
end
--================
--点击元素信息
--================
function XUiRpgTowerCharaInfoInfo:OnClickBtnElementDetail()
    if not self.RChara then return end
    XLuaUiManager.Open("UiCharacterElementDetail", self.RChara:GetCharacterId())
end
--================
--点击职业信息
--================
function XUiRpgTowerCharaInfoInfo:OnClickBtnCareerTips()
    XLuaUiManager.Open("UiCharacterCarerrTips")
end
return XUiRpgTowerCharaInfoInfo