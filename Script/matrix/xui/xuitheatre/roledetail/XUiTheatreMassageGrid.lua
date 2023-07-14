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
    self.PanelHead = self.Transform:Find("PanelHead")
    self.RImgHeadIcon = self.Transform:Find("PanelHead/RImgHeadIcon"):GetComponent("RawImage")
    self.PanelLevel = self.Transform:Find("PanelLevel")
    self.TxtLevel = self.Transform:Find("PanelLevel/TxtLevel"):GetComponent("Text")
    self.PanelGrade = self.Transform:Find("PanelGrade")
    self.RImgGrade = self.Transform:Find("PanelGrade/RImgGrade"):GetComponent("RawImage")
    self.RImgQuality = self.Transform:Find("RImgQuality"):GetComponent("RawImage")
    self.PanelFragment = self.Transform:Find("PanelFragment")
    self.TxtCurCount = self.Transform:Find("PanelFragment/TxtCurCount"):GetComponent("Text")
    self.TxtNeedCount = self.Transform:Find("PanelFragment/TxtNeedCount"):GetComponent("Text")
    self.ImgLock = self.Transform:Find("ImgLock"):GetComponent("Image")
    self.BtnCharacter = self.Transform:Find("BtnCharacter"):GetComponent("Button")
    self.ImgInTeam = self.Transform:Find("ImgInTeam"):GetComponent("Image")
    self.PanelSelected = self.Transform:Find("PanelSelected")
    self.ImgSelected = self.Transform:Find("PanelSelected/ImgSelected"):GetComponent("Image")
    self.ImgRedPoint = self.Transform:Find("ImgRedPoint"):GetComponent("Image")
    self.TxtCur = self.Transform:Find("TxtCur"):GetComponent("Text")
    self.PanelTry = self.Transform:Find("PanelTry")
    self.RoleQieHuan = XUiHelper.TryGetComponent(self.Transform, "Animation/RoleQieHuan")
end

function XUiTheatreMassageGrid:UpdateGrid(adventureRole)
    self.AdventureRole = adventureRole
    local characterViewModel = adventureRole:GetCharacterViewModel()

    self.TxtLevel.text = adventureRole:GetLevel()
    local gradeIcon = characterViewModel:GetGradeIcon()
    self.RImgGrade:SetRawImage(gradeIcon)

    local qualityIcon = characterViewModel:GetQualityIcon()
    self.RImgQuality:SetRawImage(qualityIcon)

    local headIcon = characterViewModel:GetSmallHeadIcon()
    self.RImgHeadIcon:SetRawImage(headIcon)

    --试玩标记
    local isLocalRole = adventureRole:GetIsLocalRole()
    self.PanelTry.gameObject:SetActiveEx(not isLocalRole)
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