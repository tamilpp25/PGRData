local XUiGuidMultiDimPresetRole = XClass(nil, "XUiGuidMultiDimPresetRole")

function XUiGuidMultiDimPresetRole:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiGuidMultiDimPresetRole:Refresh(entityId, pos)
    if not XTool.IsNumberValid(entityId) then
        self:ActiveUi(false)
        return
    end
    local entity = XMVCA.XCharacter:GetCharacter(entityId)
    if not entity or not entity.GetCharacterViewModel then
        self:ActiveUi(false)
        return
    end
    
    self:ActiveUi(true)
    local characterViewModel = entity:GetCharacterViewModel()
    -- 品质图标
    self.RImgIcon:SetRawImage(characterViewModel:GetQualityIcon())
    -- 获得角色半身像（通用）
    self.RImgRole:SetRawImage(characterViewModel:GetHalfBodyCommonIcon())
    -- 战力
    self.TxtNumber.text = characterViewModel:GetAbility()
    -- 按钮
    self.BtnRole.CallBack = function() 
        self.RootUi:OnBtnRoleClick(pos)
    end
end

function XUiGuidMultiDimPresetRole:ActiveUi(isShow)
    self.RImgRole.gameObject:SetActiveEx(isShow)
    self.PanelDetail.gameObject:SetActiveEx(isShow)
    self.BtnRole.gameObject:SetActiveEx(isShow)
    self.TxtNone.gameObject:SetActiveEx(not isShow)
end

return XUiGuidMultiDimPresetRole