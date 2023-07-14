local CsXTextManager = CS.XTextManager

--######################## UiSuperTowerRoleGrid ########################
local XUiSuperTowerRoleGrid = XClass(nil, "XUiSuperTowerRoleGrid")

function XUiSuperTowerRoleGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    -- XSuperTowerRole
    self.SuperTowerRole = nil
end

-- superTowerRole : XSuperTowerRole
function XUiSuperTowerRoleGrid:SetData(superTowerRole)
    local superTowerManager = XDataCenter.SuperTowerManager
    self.SuperTowerRole = superTowerRole
    local characterViewModel = superTowerRole:GetCharacterViewModel()
    self.RImgHeadIcon:SetRawImage(characterViewModel:GetSmallHeadIcon())
    self.TxtPower.text = superTowerRole:GetAbility()
    self.TxtLevel.text = characterViewModel:GetLevel()
    self.RImgQuality:SetRawImage(characterViewModel:GetQualityIcon())
    -- 超限
    self.TxtSuperLevel.text = superTowerRole:GetSuperLevel()
    local isOpenTransfinite = superTowerManager.CheckFunctionUnlockByKey(superTowerManager.FunctionName.Transfinite)
    self.PanelSuperLevel.gameObject:SetActiveEx(isOpenTransfinite)
    -- 试玩
    self.PanelSw.gameObject:SetActiveEx(superTowerRole:GetIsRobot())
    -- 特典
    local isOpenBonusChara = superTowerManager.CheckFunctionUnlockByKey(superTowerManager.FunctionName.BonusChara)
    self.PanalTedianyq.gameObject:SetActiveEx(isOpenBonusChara and superTowerRole:GetIsInDult())
    -- 小红点
    self.ImgRedPoint.gameObject:SetActiveEx(
        superTowerManager.GetRoleManager():CheckRoleShowRedDot(superTowerRole:GetId()))
    -- 是否在队伍中, 不会有这种情况，暂时保留
    self.ImgInTeam.gameObject:SetActiveEx(false)
    -- 元素图标
    local obtainElementIcons = characterViewModel:GetObtainElementIcons()
    local elementIcon
    for i = 1, 2 do
        elementIcon = obtainElementIcons[i]
        self["RImgElement" .. i].gameObject:SetActiveEx(elementIcon ~= nil)
        if elementIcon then
            self["RImgElement" .. i]:SetRawImage(elementIcon)
        end
    end
end

function XUiSuperTowerRoleGrid:SetSelectStatus(value)
    self.PanelSelected.gameObject:SetActiveEx(value)
end

return XUiSuperTowerRoleGrid