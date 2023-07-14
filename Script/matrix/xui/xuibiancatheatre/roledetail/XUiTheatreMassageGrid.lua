--肉鸽二期成员列表界面--角色格子
local XUiTheatreMassageGrid = XClass(nil, "XUiTheatreMassageGrid")

function XUiTheatreMassageGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self:InitAutoScript()
end

function XUiTheatreMassageGrid:InitAutoScript()
    self:AutoInitUi()

    if self.PanelSupportLock then
        self.PanelSupportLock.gameObject:SetActiveEx(false)
    end
    if self.PanelSupportIn then
        self.PanelSupportIn.gameObject:SetActiveEx(false)
    end
    if self.TxtCur then
        self.TxtCur.gameObject:SetActiveEx(false)
    end
    if self.ImgRedPoint then
        self.ImgRedPoint.gameObject:SetActiveEx(false)
    end
    if self.ImgInTeam then
        self.ImgInTeam.gameObject:SetActiveEx(false)
    end
    if self.PanelFragment then
        self.PanelFragment.gameObject:SetActiveEx(false)
    end
    if self.ImgLock then
        self.ImgLock.gameObject:SetActiveEx(false)
    end
end

function XUiTheatreMassageGrid:AutoInitUi()
    self.PanelHead = XUiHelper.TryGetComponent(self.Transform,"PanelHead")
    self.RImgHeadIcon = XUiHelper.TryGetComponent(self.Transform,"PanelHead/RImgHeadIcon", "RawImage")
    self.PanelLevel = XUiHelper.TryGetComponent(self.Transform,"PanelLevel")
    self.TxtLevel = XUiHelper.TryGetComponent(self.Transform,"PanelLevel/TxtLevel", "Text")
    self.RImgQuality = XUiHelper.TryGetComponent(self.Transform,"RImgQuality", "RawImage")
    self.PanelFragment = XUiHelper.TryGetComponent(self.Transform,"PanelFragment")
    self.TxtCurCount = XUiHelper.TryGetComponent(self.Transform,"PanelFragment/TxtCurCount", "Text")
    self.TxtNeedCount = XUiHelper.TryGetComponent(self.Transform,"PanelFragment/TxtNeedCount", "Text")
    self.ImgLock = XUiHelper.TryGetComponent(self.Transform,"ImgLock", "Image")
    self.BtnCharacter = XUiHelper.TryGetComponent(self.Transform,"BtnCharacter", "Button")
    self.ImgInTeam = XUiHelper.TryGetComponent(self.Transform,"ImgInTeam", "Image")
    self.PanelSelected = XUiHelper.TryGetComponent(self.Transform,"PanelSelected")
    self.ImgSelected = XUiHelper.TryGetComponent(self.Transform,"PanelSelected/ImgSelected", "Image")
    self.ImgRedPoint = XUiHelper.TryGetComponent(self.Transform,"ImgRedPoint", "Image")
    self.TxtCur = XUiHelper.TryGetComponent(self.Transform,"TxtCur", "Text")
    self.PanelTry = XUiHelper.TryGetComponent(self.Transform,"PanelTry")
    self.PanelOwn = XUiHelper.TryGetComponent(self.Transform,"PanelTry2")
    self.RoleQieHuan = XUiHelper.TryGetComponent(self.Transform, "Animation/RoleQieHuan")
    self.PanelStar = XUiHelper.TryGetComponent(self.Transform, "PanelStar", "Text")
end

function XUiTheatreMassageGrid:UpdateGrid(adventureRole)
    self.AdventureRole = adventureRole
    local characterViewModel = adventureRole:GetCharacterViewModel()

    --星级
    self.PanelStar.text = adventureRole:GetLevel()
    --战力
    self.TxtLevel.text = adventureRole:GetAbility()
    --阶级
    local qualityIcon = characterViewModel:GetQualityIcon()
    self.RImgQuality:SetRawImage(qualityIcon)
    --头像
    local headIcon = characterViewModel:GetSmallHeadIcon()
    self.RImgHeadIcon:SetRawImage(headIcon)
    --试玩标记
    local isLocalRole = adventureRole:GetIsLocalRole()
    self.PanelTry.gameObject:SetActiveEx(not isLocalRole)
    --自机标记
    self.PanelOwn.gameObject:SetActiveEx(isLocalRole)
end

function XUiTheatreMassageGrid:SetSelect(isSelect)
    self.ImgSelected.gameObject:SetActiveEx(isSelect)
end

function XUiTheatreMassageGrid:PlaySwitchAnima()
    self.RoleQieHuan:PlayTimelineAnimation()
end

function XUiTheatreMassageGrid:GetEntityId()
    local adventureRole = self.AdventureRole
    local entityId = adventureRole:GetId()
    return entityId
end

return XUiTheatreMassageGrid