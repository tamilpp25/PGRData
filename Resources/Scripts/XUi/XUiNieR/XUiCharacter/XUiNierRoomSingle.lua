local XUiNierRoomSingle = XLuaUiManager.Register(XLuaUi, "UiNierRoomSingle")

local MAX_CHAR_COUNT = 3
function XUiNierRoomSingle:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end

    self:AutoAddListener()
end

function XUiNierRoomSingle:OnStart()
    local uiModelRoot = self.UiModelGo.transform
    self.PanelCharacterInfo = {
        [1] = {
            PanelRoleEffect = uiModelRoot:FindTransform("PanelRoleEffect1"),
            TongdiaoEffect = uiModelRoot:FindTransform("ImgEffectTongDiao1"),
            RoleModelPanel = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelRoleModel1"), self.Name, nil, true, nil, true, true),
        },
        [2] = {
            PanelRoleEffect = uiModelRoot:FindTransform("PanelRoleEffect2"),
            TongdiaoEffect = uiModelRoot:FindTransform("ImgEffectTongDiao2"),
            RoleModelPanel = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelRoleModel2"), self.Name, nil, true, nil, true, true),
        },
        [3] = {
            PanelRoleEffect = uiModelRoot:FindTransform("PanelRoleEffect3"),
            TongdiaoEffect = uiModelRoot:FindTransform("ImgEffectTongDiao3"),
            RoleModelPanel = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelRoleModel3"), self.Name, nil, true, nil, true, true),
        },
    }
    self.NierCharacters = XDataCenter.NieRManager.GetCurDevelopCharacterIds()


end

function XUiNierRoomSingle:OnEnable()
    self:InitPanelNierCharacter()
end

function XUiNierRoomSingle:OnDisable()

end

function XUiNierRoomSingle:OnDestroy()

end

function XUiNierRoomSingle:AutoAddListener()
    self:RegisterClickEvent(self.BtnChar1, self.OnBtnChar1Click)
    self:RegisterClickEvent(self.BtnChar2, self.OnBtnChar2Click)
    self:RegisterClickEvent(self.BtnChar3, self.OnBtnChar3Click)
end

function XUiNierRoomSingle:InitPanelNierCharacter()
    for index = 1, MAX_CHAR_COUNT do
        local characterId = self.NierCharacters[index]
        if not characterId then
            self["BtnChar" .. index].gameObject:SetActiveEx(false)
        else
            self["BtnChar" .. index].gameObject:SetActiveEx(true)
            local nieRCharacter = XDataCenter.NieRManager.GetNieRCharacterByCharacterId(characterId)
            local condit, desc = nieRCharacter:CheckNieRCharacterCondition()
            if condit then
                self["PanelAbility" .. index].gameObject:SetActiveEx(true)
                self["PanelFirstRole" .. index].gameObject:SetActiveEx(false)
                self["TxtAbility" .. index].text = "LV" .. nieRCharacter:GetNieRCharacterLevel()
                local careerIcon = XCharacterConfigs.GetNpcTypeIcon(nieRCharacter:GetRobotCharacterCareerType())
                local rImgArms = self["RImgArms" .. index]
                if careerIcon then
                    rImgArms:SetRawImage(careerIcon)
                    rImgArms.gameObject:SetActiveEx(true)
                else
                    rImgArms.gameObject:SetActiveEx(false)
                end

            else
                self["PanelAbility" .. index].gameObject:SetActiveEx(false)
                self["PanelFirstRole" .. index].gameObject:SetActiveEx(true)
                self["PanelFirstRole" .. index].gameObject:SetActiveEx(true)

                local text = XUiHelper.TryGetComponent(self["PanelFirstRole" .. index].transform, "Text3", "Text")
                text.text = desc
            end
            self:UpdateRoleModel(nieRCharacter:GetNieRCharacterRobotId(), nieRCharacter:GetNieRFashionId(), nieRCharacter:GetNieRWeaponId(), self.PanelCharacterInfo[index].RoleModelPanel)
        end

    end
end

function XUiNierRoomSingle:OnBtnBackClick()
    self:Close()
end

function XUiNierRoomSingle:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiNierRoomSingle:OnBtnChar1Click()
    self:OnRealBtnCharClick(1)
end

function XUiNierRoomSingle:OnBtnChar2Click()
    self:OnRealBtnCharClick(2)
end

function XUiNierRoomSingle:OnBtnChar3Click()
    self:OnRealBtnCharClick(3)
end

function XUiNierRoomSingle:OnRealBtnCharClick(index)
    if not self.NierCharacters[index] then
        return
    end
    XDataCenter.NieRManager.SetSelCharacterId(self.NierCharacters[index])
    XLuaUiManager.Open("UiNierCharacter")
end

--更新模型
function XUiNierRoomSingle:UpdateRoleModel(robotId, fashionId, weaponId, roleModelPanel)
    roleModelPanel:ShowRoleModel() -- 先Active 再加载模型以及播放动画
    local callback = function()

    end
    local characterId = XRobotManager.GetCharacterId(robotId)
    roleModelPanel:UpdateRobotModel(robotId, characterId, callback, fashionId, weaponId)
end