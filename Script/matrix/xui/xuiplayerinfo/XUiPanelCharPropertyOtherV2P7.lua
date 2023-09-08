local XUiPanelCharPropertyOtherV2P7 = XLuaUiManager.Register(XLuaUi, "UiPanelCharPropertyOtherV2P7")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

function XUiPanelCharPropertyOtherV2P7:OnAwake()
    self:InitButton()
    self:InitPanelEquip()

    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiPanelCharPropertyOtherV2P7:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

function XUiPanelCharPropertyOtherV2P7:InitPanelEquip()
    self.PanelEquips = XMVCA.XEquip:InitPanelCharInfoWithEquipOther(self.PanelEquip, self, self)
    ---@type XUiPanelCharInfoWithEquipOther
    self.PanelEquips:InitData()
end

function XUiPanelCharPropertyOtherV2P7:OnStart(data)
    self.Character = data.Character
    self.EquipList = data.EquipList
    self.WeaponFashionId = data.WeaponFashionId
    self.AssignChapterRecords = data.AssignChapterRecords
    self.Partner = data.Partner
    self.AwarenessSetPositions = data.AwarenessSetPositions

    self.Awareness = {}
    for _, v in pairs(data.EquipList) do
        if XDataCenter.EquipManager.IsClassifyEqualByTemplateId(v.TemplateId, XEquipConfig.Classify.Weapon) then
            self.Weapon = v
        else
            table.insert(self.Awareness, v)
        end
    end

    self.PanelEquips:Open()
    self.PanelEquips:UpdateCharacter(data)
    self.RoleModelPanel:UpdateCharacterModelOther(self.Character, self.Weapon, self.WeaponFashionId, self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiCharacter, function(model)
        self.PanelDrag.Target = model.transform
    end)
end

return XUiPanelCharPropertyOtherV2P7