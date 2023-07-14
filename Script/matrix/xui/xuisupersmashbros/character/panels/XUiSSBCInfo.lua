
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
    ---@type XSmashBCharacter
    self.Chara = chara
    self.TxtName.text = self.Chara:GetName()
    self.TxtAbility.text = self.Chara:GetAbility()
    local careerIcon = self.Chara:GetCareerIcon()
    if careerIcon then
        self.RImgTypeIcon.gameObject:SetActiveEx(true)
        self.RImgTypeIcon:SetRawImage(careerIcon)
    else
        self.RImgTypeIcon.gameObject:SetActiveEx(false)
    end
    local tradeName = self.Chara:GetTradeName()
    if tradeName then
        self.TxtNameOther.gameObject:SetActiveEx(true)
        self.TxtNameOther.text = self.Chara:GetTradeName()
    else
        self.TxtNameOther.gameObject:SetActiveEx(false)
    end
    self:SetElementIcons()
    if self.Panel4Hide then
        self.Panel4Hide.gameObject:SetActiveEx(false)
    end
end
--================
--设置元素图标
--================
function XUiSSBCInfo:SetElementIcons()
    local elementList = self.Chara:GetObtainElementIcons()
    if not elementList then
        self.BtnElementDetail.gameObject:SetActiveEx(false)
        return
    end
    self.BtnElementDetail.gameObject:SetActiveEx(true)
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
    if self.Chara:IsNoCareer() then
        return
    end
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