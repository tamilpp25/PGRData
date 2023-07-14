--===========================
--超级爬塔队伍列表角色控件
--===========================
local XUiStTpMemberGrid = XClass(nil, "XUiStTpMemberGrid")

function XUiStTpMemberGrid:Ctor(uiGameObject, rootUi)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.RootUi = rootUi
    self.BtnClick.CallBack = function() self:OnClick() end
end

function XUiStTpMemberGrid:Reset()
    --self.ImgLock.gameObject:SetActiveEx(true)
end

function XUiStTpMemberGrid:RefreshData(role)
    if not role then
        self:Reset()
        return
    end
    self.Role = role
    self:RefreshImg()
    self:RefreshHp()
    self:RefreshSp()
    self:RefreshSuperLevel()
end

function XUiStTpMemberGrid:RefreshImg()
    self.RImgRole:SetRawImage(self.Role:GetCharacterViewModel():GetHalfBodyCommonIcon())
    self.GridLv.gameObject:SetActiveEx(XDataCenter.SuperTowerManager.GetFunctionManager():CheckFunctionUnlockByKey(XDataCenter.SuperTowerManager.FunctionName.Transfinite))
    self.ImgSpRoleIcon.gameObject:SetActiveEx(self.Role:GetIsInDult())
    --self.ImgLock.gameObject:SetActiveEx(false)
end

function XUiStTpMemberGrid:RefreshHp()
    self.TxtHpPercent.text = self.Role:GetHpLeft() .. "%"
    self.ImgHpProgress.fillAmount = self.Role:GetHpLeft() / 100
end

function XUiStTpMemberGrid:RefreshSp()
    self.ImgSpRoleIcon.gameObject:SetActiveEx(self.Role:GetIsInDult())
end

function XUiStTpMemberGrid:RefreshSuperLevel()
    self.TxtLevel.text = self.Role:GetSuperLevel()
end

function XUiStTpMemberGrid:SetLeader(isShow)
    self.ImgLeader.gameObject:SetActiveEx(isShow)
end

function XUiStTpMemberGrid:SetFirst(isShow)
    self.ImgFirstRole.gameObject:SetActiveEx(isShow)
end

function XUiStTpMemberGrid:OnClick()
    
end

return XUiStTpMemberGrid