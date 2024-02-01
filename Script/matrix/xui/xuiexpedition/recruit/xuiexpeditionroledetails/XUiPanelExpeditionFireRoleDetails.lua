local XUiPanelExpeditionBaseRoleDetails = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoleDetails/XUiPanelExpeditionBaseRoleDetails")
local XUiPanelExpeditionFireRoleDetails = XClass(XUiPanelExpeditionBaseRoleDetails, "XUiPanelExpeditionFireRoleDetails")
local XUiPanelExpeditionFashionList = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoleDetails/XUiPanelExpeditionFashionList")

local GridType = {
    FashionCharacter = 1,--成员涂装
    FashionWeapon = 2,--武器涂装
}

function XUiPanelExpeditionFireRoleDetails:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.OnBtnTanchuangCloseBigClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTcanchaungRed, self.OnBtnTcanchaungRedClick)
end

function XUiPanelExpeditionFireRoleDetails:OnBtnTanchuangCloseBigClick()
    self:Close()
end
-- 解雇
function XUiPanelExpeditionFireRoleDetails:OnBtnTcanchaungRedClick()
    self:Close()
    XDataCenter.ExpeditionManager.FireMember(self.EChara:GetBaseId(), self.EChara:GetECharaId())
end

function XUiPanelExpeditionFireRoleDetails:InitView()
    self.DetailsType = XExpeditionConfig.MemberDetailsType.FireMember
    
    self.GridRoleFashion = XUiPanelExpeditionFashionList.New(GridType.FashionCharacter, self.Painting, self)
    self.GridWeaponFashion = XUiPanelExpeditionFashionList.New(GridType.FashionWeapon, self.WeaponPainting, self)
    
    self.PanelPreviewModel = {
        [1] = self.PanelWeaponPreview,
        [2] = self.PanelFashionPreview,
    }
    
    self.TabGroup = {
        self.TogStory,
        self.TogDaily
    }
    
    self.TabPanel:Init(self.TabGroup, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
end

function XUiPanelExpeditionFireRoleDetails:Refresh(eChara, gridIndex)
    self.Super.Refresh(self, eChara, gridIndex)
    self:RefreshBtnView()
    self:RefreshFashion()
    self.TabPanel:SelectIndex(1)
    self.RootUi:PlayAnimation("PanelRoleDetails2Enable")
end

function XUiPanelExpeditionFireRoleDetails:RefreshBtnView()
    local isDefault = self.EChara:GetIsDefaultTeamMember()
    self.BtnTcanchaungRed.gameObject:SetActiveEx(not isDefault)
end

function XUiPanelExpeditionFireRoleDetails:RefreshFashion()
    local robotId = self.EChara:GetRobotId()
    local characterId = self.EChara:GetCharacterId()
    local isOwn = XMVCA.XCharacter:IsOwnCharacter(characterId)
    if XRobotManager.CheckUseFashion(robotId) and isOwn then
        -- 角色涂装
        local roleFashionList = XDataCenter.FashionManager.GetCurrentTimeFashionByCharId(characterId)
        self.GridRoleFashion:Refresh(roleFashionList, characterId)
        -- 武器涂装
        local weaponFashionList = XDataCenter.WeaponFashionManager.GetSortedWeaponFashionIdsByCharacterId(characterId)
        self.GridWeaponFashion:Refresh(weaponFashionList, characterId, robotId)
    else
        -- 未拥有角色时不显示该角色涂装信息
        self.GridRoleFashion:Refresh({}, characterId)
        self.GridWeaponFashion:Refresh({}, characterId)
    end
end

function XUiPanelExpeditionFireRoleDetails:OnClickTabCallBack(tabIndex)
    if self.CurrentTabIndex and self.CurrentTabIndex == tabIndex then
        return
    end

    self.CurrentTabIndex = tabIndex
    self:ActivePreview(tabIndex)
    self.RootUi:PlayAnimation("QieHuan")
end

function XUiPanelExpeditionFireRoleDetails:ActivePreview(index)
    for _, view in pairs(self.PanelPreviewModel) do
        view.gameObject:SetActiveEx(false)
    end
    self.PanelPreviewModel[index].gameObject:SetActiveEx(true)
end

function XUiPanelExpeditionFireRoleDetails:Close()
    self.GridRoleFashion:CancelSelect()
    self.GridWeaponFashion:CancelSelect()
    self.RootUi:Close()
end

return XUiPanelExpeditionFireRoleDetails