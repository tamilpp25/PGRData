---@class XUiTheatreMassageGrid
local XUiTheatreMassageGrid = XClass(nil, "XUiTheatreMassageGrid")

function XUiTheatreMassageGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
    if not self.PanelUniframe then
        ---@type UnityEngine.RectTransform
        self.PanelUniframe = XUiHelper.TryGetComponent(self.Transform, "CharHeadCurrentPerfab/PanelUniframe")
    end
    ---@type UnityEngine.UI.Image
    self.ImgInitQuality = XUiHelper.TryGetComponent(self.Transform, "CharHeadCurrentPerfab/PanelInitQuality/ImgInitQuality", "Image")
end

---@param entity XTheatreAdventureRole
function XUiTheatreMassageGrid:SetData(entity)
    self.AdventureRole = entity
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    local characterViewModel = entity:GetCharacterViewModel()
    local characterId = characterViewModel:GetId()

    -- 等级
    self.TxtLevel.text = entity:GetLevel()
    -- 战力
    self.TxtFight.text = entity:GetAbility()
    -- 品质
    local qualityIcon = characterViewModel:GetQualityIcon()
    self.RImgQuality:SetRawImage(qualityIcon)
    -- 头像
    local headIcon = characterViewModel:GetSmallHeadIcon()
    self.RImgHeadIcon:SetRawImage(headIcon)
    -- 职业
    if self.RImgTypeIcon then
        self.RImgTypeIcon:SetRawImage(characterViewModel:GetProfessionIcon())
    end
    -- 经验条
    self.PanelStaminaBar.gameObject:SetActiveEx(false)
    -- 试玩标记
    local isLocalRole = entity:GetIsLocalRole()
    self.PanelTry.gameObject:SetActiveEx(not isLocalRole)
    -- 独域图标
    if self.PanelUniframe then
        local isUniframe = self.CharacterAgency:GetIsIsomer(characterId)
        self.PanelUniframe.gameObject:SetActiveEx(isUniframe)
    end
    -- 元素图标
    local obtainElementIcons = characterViewModel:GetObtainElementIcons()
    local elementIcon
    for i = 1, 3 do
        elementIcon = obtainElementIcons[i]
        local rImgCharElementName = "RImgCharElement" .. i
        if self[rImgCharElementName] then
            self[rImgCharElementName].gameObject:SetActiveEx(elementIcon ~= nil)
            if elementIcon then
                self[rImgCharElementName]:SetRawImage(elementIcon)
            end
        end
    end
    -- 初始品质
    if self.ImgInitQuality then
        local initQuality = characterAgency:GetCharacterInitialQuality(characterId)
        local icon = characterAgency:GetModelCharacterQualityIcon(initQuality).IconCharacterInit
        self.ImgInitQuality:SetSprite(icon)
    end
end

function XUiTheatreMassageGrid:SetSelect(isSelected)
    self.ImgSelected.gameObject:SetActiveEx(isSelected)
end

--region Old
--function XUiTheatreMassageGrid:Ctor(ui)
--    self.GameObject = ui.gameObject
--    self.Transform = ui.transform
--
--    XTool.InitUiObject(self)
--
--    self:InitAutoScript()
--end
--
--function XUiTheatreMassageGrid:InitAutoScript()
--    self:AutoInitUi()
--
--    if self.PanelSupportLock then
--        self.PanelSupportLock.gameObject:SetActiveEx(false)
--    end
--
--    if self.PanelSupportIn then
--        self.PanelSupportIn.gameObject:SetActiveEx(false)
--    end
--    if self.TxtCur then
--        self.TxtCur.gameObject:SetActiveEx(false)
--    end
--    if self.ImgRedPoint then
--        self.ImgRedPoint.gameObject:SetActiveEx(false)
--    end
--    if self.ImgInTeam then
--        self.ImgInTeam.gameObject:SetActiveEx(false)
--    end
--    if self.PanelFragment then
--        self.PanelFragment.gameObject:SetActiveEx(false)
--    end
--    if self.ImgLock then
--        self.ImgLock.gameObject:SetActiveEx(false)
--    end
--end
--
--function XUiTheatreMassageGrid:AutoInitUi()
--    self.PanelHead = self.Transform:Find("PanelHead")
--    self.RImgHeadIcon = self.Transform:Find("PanelHead/RImgHeadIcon"):GetComponent("RawImage")
--    self.PanelLevel = self.Transform:Find("PanelLevel")
--    self.TxtLevel = self.Transform:Find("PanelLevel/TxtLevel"):GetComponent("Text")
--    self.PanelGrade = self.Transform:Find("PanelGrade")
--    self.RImgGrade = self.Transform:Find("PanelGrade/RImgGrade"):GetComponent("RawImage")
--    self.RImgQuality = self.Transform:Find("RImgQuality"):GetComponent("RawImage")
--    self.PanelFragment = self.Transform:Find("PanelFragment")
--    self.TxtCurCount = self.Transform:Find("PanelFragment/TxtCurCount"):GetComponent("Text")
--    self.TxtNeedCount = self.Transform:Find("PanelFragment/TxtNeedCount"):GetComponent("Text")
--    self.ImgLock = self.Transform:Find("ImgLock"):GetComponent("Image")
--    self.BtnCharacter = self.Transform:Find("BtnCharacter"):GetComponent("Button")
--    self.ImgInTeam = self.Transform:Find("ImgInTeam"):GetComponent("Image")
--    self.PanelSelected = self.Transform:Find("PanelSelected")
--    self.ImgSelected = self.Transform:Find("PanelSelected/ImgSelected"):GetComponent("Image")
--    self.ImgRedPoint = self.Transform:Find("ImgRedPoint"):GetComponent("Image")
--    self.TxtCur = self.Transform:Find("TxtCur"):GetComponent("Text")
--    self.PanelTry = self.Transform:Find("PanelTry")
--    self.RoleQieHuan = XUiHelper.TryGetComponent(self.Transform, "Animation/RoleQieHuan")
--end
--
--function XUiTheatreMassageGrid:UpdateGrid(adventureRole)
--    self.AdventureRole = adventureRole
--    local characterViewModel = adventureRole:GetCharacterViewModel()
--
--    self.TxtLevel.text = adventureRole:GetLevel()
--    local gradeIcon = characterViewModel:GetGradeIcon()
--    self.RImgGrade:SetRawImage(gradeIcon)
--
--    local qualityIcon = characterViewModel:GetQualityIcon()
--    self.RImgQuality:SetRawImage(qualityIcon)
--
--    local headIcon = characterViewModel:GetSmallHeadIcon()
--    self.RImgHeadIcon:SetRawImage(headIcon)
--
--    --试玩标记
--    local isLocalRole = adventureRole:GetIsLocalRole()
--    self.PanelTry.gameObject:SetActiveEx(not isLocalRole)
--end
--
--function XUiTheatreMassageGrid:SetSelect(isSelect)
--    self.ImgSelected.gameObject:SetActiveEx(isSelect)
--end
--
--function XUiTheatreMassageGrid:PlaySwitchAnima()
--    self.RoleQieHuan:PlayTimelineAnimation()
--end
--
--function XUiTheatreMassageGrid:GetEntityId()
--    local adventureRole = self.AdventureRole
--    local entityId = adventureRole:GetId()
--    return entityId
--end
--endregion

return XUiTheatreMassageGrid