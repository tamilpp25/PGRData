
local XUiSSBCInfo = XClass(nil, "XUiSSBCInfo")

function XUiSSBCInfo:Ctor(prefab)
    XTool.InitUiObjectByUi(self, prefab)
    XUiHelper.RegisterClickEvent(self, self.BtnCareerTips, function() self:OnClickBtnCareerTips() end)
    self.BtnElementDetail.CallBack = function() self:OnClickBtnElementDetail() end
end
--================
--刷新角色
--================
function XUiSSBCInfo:Refresh(chara)
    self.Chara = chara
    self.TxtName.text = self.Chara:GetName()
    self.TxtAbility.text = self.Chara:GetAbility()
    self.RImgTypeIcon:SetRawImage(self.Chara:GetCareerIcon())
    self.TxtNameOther.text = self.Chara:GetTradeName()
    self:SetElementIcons()
end
--================
--设置元素图标
--================
function XUiSSBCInfo:SetElementIcons()
    local elementList = self.Chara:GetObtainElementIcons()
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if rImg and elementList[i] then
            rImg.transform.gameObject:SetActive(true)
            rImg:SetRawImage(elementList[i])
        elseif rImg then
            rImg.transform.gameObject:SetActive(false)
        end
    end
end
--================
--点击职业信息
--================
function XUiSSBCInfo:OnClickBtnCareerTips()
    if not self.Chara then return end
    XLuaUiManager.Open("UiCharacterCarerrTips", self.Chara:GetCharacterId())
end
--================
--点击元素信息
--================
function XUiSSBCInfo:OnClickBtnElementDetail()
    if not self.Chara then return end
    XLuaUiManager.Open("UiCharacterElementDetail", self.Chara:GetCharacterId())
end

return XUiSSBCInfo