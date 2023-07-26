local XUiTRPGNewCharacter = XLuaUiManager.Register(XLuaUi, "UiTRPGNewCharacter")

function XUiTRPGNewCharacter:OnAwake()
    self:AutoAddListener()
end

function XUiTRPGNewCharacter:OnStart(roleId)
    self.RoleId = roleId

    self:InitUi()
end

function XUiTRPGNewCharacter:InitUi()
    local roleId = self.RoleId

    local name = XTRPGConfigs.GetRoleName(roleId)
    self.TxtName.text = name

    local desc = XTRPGConfigs.GetRoleDesc(roleId)
    self.TxtInformation.text = desc

    local image = XTRPGConfigs.GetRoleImage(roleId)
    self.RImgCharacter:SetRawImage(image)

    local attributes = XDataCenter.TRPGManager.GetRoleAttributes(roleId)
    for index, attr in pairs(attributes) do
        local value = attr.Value
        self["TxtValue" .. index].text = value

        local maxValue = XTRPGConfigs.GetRoleAttributeMaxValue(attr.Type)
        local rate = value / maxValue

        local center = self.Transform:FindTransform("Center")
        local cPos = center.transform.localPosition
        local pos = self["Point" .. index].transform.localPosition
        self["Point" .. index].transform.localPosition = (pos - cPos) * rate + cPos
    end

    self.GraphPolygon:Refresh()
end

function XUiTRPGNewCharacter:AutoAddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnBackClick)
end

function XUiTRPGNewCharacter:OnBtnBackClick()
    self:Close()
end