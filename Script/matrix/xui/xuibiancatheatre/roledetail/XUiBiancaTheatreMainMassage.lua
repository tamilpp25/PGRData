local XUiTheatreMassageGrid = require("XUi/XUiBiancaTheatre/RoleDetail/XUiTheatreMassageGrid")
local XUiTheatreOwnedInfoPanel = require("XUi/XUiBiancaTheatre/RoleDetail/XUiTheatreOwnedInfoPanel")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

--肉鸽二期成员列表界面
---@class XUiBiancaTheatreMainMassage:XLuaUi
local XUiBiancaTheatreMainMassage = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreMainMassage")

function XUiBiancaTheatreMainMassage:OnAwake()
    self:AddBtnListener()
end

function XUiBiancaTheatreMainMassage:OnStart()
    self:Init()
end

function XUiBiancaTheatreMainMassage:OnEnable()
    if XTool.IsNumberValid(self._CurSelectIndex) then
        self._PanelFilter:DoSelectIndex(self._CurSelectIndex)
    end
end

function XUiBiancaTheatreMainMassage:OnDestroy()
    self:RemovePanelAsset()
end

function XUiBiancaTheatreMainMassage:Init()
    ---@type XBiancaTheatreAdventureManager
    self.AdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()

    self:InitPanelAsset()
    self:InitRoleDetail()
    self:InitModel()
    self:InitFilter()
end

--region Data - Getter
function XUiBiancaTheatreMainMassage:GetCurrentCharacterId()
    local entityId = self._CurrentEntityId
    local adventureRole = self.AdventureManager:GetRole(entityId)
    return adventureRole:GetCharacterId()
end
--endregion

--region Ui - PanelAsset
function XUiBiancaTheatreMainMassage:InitPanelAsset()
    self._PanelAsset = XUiHelper.NewPanelActivityAssetSafe(XDataCenter.BiancaTheatreManager.GetAdventureAssetItemIds(), self.PanelSpecialTool, self, nil, XDataCenter.BiancaTheatreManager.AdventureAssetItemOnBtnClick)
end

function XUiBiancaTheatreMainMassage:RemovePanelAsset()
    XDataCenter.ItemManager.RemoveCountUpdateListener(self._PanelAsset)
end
--endregion

--region Ui - Filter
function XUiBiancaTheatreMainMassage:InitFilter()
    if not self.PanelZuo then
        return
    end
    local checkInTeam = function(id)
        return true
    end
    ---@type XCommonCharacterFilterAgency
    self.FiltAgecy = XMVCA:GetAgency(ModuleId.XCommonCharacterFilter)
    self._PanelFilter = self.FiltAgecy:InitFilter(self.PanelZuo, self)

    local clickTag = function()
        self:_RefreshEmptyPanel()
    end
    self._PanelFilter:InitData(handler(self, self._OnSelectTab), clickTag, nil, nil, XUiTheatreMassageGrid, checkInTeam)
    self._PanelFilter:SetGetCharIdFun(function(adventureRole)
        return adventureRole:GetId()
    end)
    self._PanelFilter:ImportList(self:_GetCharacterList())
    self._PanelFilter:RefreshList()
end

function XUiBiancaTheatreMainMassage:_GetCharacterList()
    return self.AdventureManager:GetCurrentRoles(true)
end

---@param character XBiancaTheatreAdventureRole
function XUiBiancaTheatreMainMassage:_OnSelectTab(character, index, grid)
    self._CurrentEntityId = character:GetId()
    self._CurSelectIndex = index
    self:RefreshModel()
    self:RefreshRoleDetail()
end

function XUiBiancaTheatreMainMassage:_RefreshEmptyPanel()
    self.UiOwnedInfo.gameObject:SetActiveEx(not self._PanelFilter:IsCurListEmpty())
    self.BtnFashion.gameObject:SetActiveEx(not self._PanelFilter:IsCurListEmpty())
    self.BtnOwnedDetail.gameObject:SetActiveEx(not self._PanelFilter:IsCurListEmpty())
    self.BtnTeaching.gameObject:SetActiveEx(not self._PanelFilter:IsCurListEmpty())
end
--endregion

--region Ui - RoleDetail
function XUiBiancaTheatreMainMassage:InitRoleDetail()
    ---@type XUiBiancaTheatreOwnedInfoPanel
    self._OwnedInfoPanel = XUiTheatreOwnedInfoPanel.New(self.UiOwnedInfo, nil, self)
end

function XUiBiancaTheatreMainMassage:RefreshRoleDetail()
    local entityId = self._CurrentEntityId
    local adventureRole = self.AdventureManager:GetRole(entityId)
    self._OwnedInfoPanel:SetData(adventureRole, entityId)

    local isShowBtnFashion = false
    local characterViewModel = adventureRole:GetCharacterViewModel()
    if characterViewModel then
        local sourceEntityId = characterViewModel:GetSourceEntityId()
        local robot2CharId = XRobotManager.GetCharacterId(sourceEntityId)
        -- 机器人有配置就展示涂装按钮
        if XRobotManager.CheckIsRobotId(sourceEntityId)  then
            isShowBtnFashion = XRobotManager.CheckUseFashion(sourceEntityId)
        -- 玩家拥有角色就展示涂装按钮
        elseif XMVCA.XCharacter:IsOwnCharacter(robot2CharId) then
            isShowBtnFashion = true
        end
    end
    self.BtnFashion.gameObject:SetActiveEx(isShowBtnFashion)
end
--endregion

--region Scene - Model
function XUiBiancaTheatreMainMassage:InitModel()
    local panelRoleModel = self.UiModelGo.transform:FindTransform("PanelRoleModel")
    ---@type UnityEngine.Transform
    self.ImgEffectHuanren = self.UiModelGo.transform:FindTransform("ImgEffectHuanren")
    ---@type UnityEngine.Transform
    self.ImgEffectHuanren1 = self.UiModelGo.transform:FindTransform("ImgEffectHuanren1")

    ---@type XUiPanelRoleModel
    self._UiPanelRoleModel = XUiPanelRoleModel.New(panelRoleModel, self.Name, nil, true)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
end

function XUiBiancaTheatreMainMassage:RefreshModel()
    local entityId = self._CurrentEntityId
    local adventureRole = self.AdventureManager:GetRole(entityId)
    local characterViewModel = adventureRole:GetCharacterViewModel()
    if not characterViewModel then
        return
    end

    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    local finishedCallback = function(model)
        self.PanelDrag.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(characterViewModel:GetCharacterType() == XEnumConst.CHARACTER.CharacterType.Normal)
        self.ImgEffectHuanren1.gameObject:SetActiveEx(characterViewModel:GetCharacterType() == XEnumConst.CHARACTER.CharacterType.Isomer)
    end

    local sourceEntityId = characterViewModel:GetSourceEntityId()
    if XRobotManager.CheckIsRobotId(sourceEntityId) then
        local robot2CharId = XRobotManager.GetCharacterId(sourceEntityId)
        local isOwn = XMVCA.XCharacter:IsOwnCharacter(robot2CharId)
        if XRobotManager.CheckUseFashion(sourceEntityId) and isOwn then
            local character = XMVCA.XCharacter:GetCharacter(robot2CharId)
            local robot2CharViewModel = character:GetCharacterViewModel()
            self._UiPanelRoleModel:UpdateCharacterModel(robot2CharId, nil, nil, finishedCallback, nil, robot2CharViewModel:GetFashionId())
        else
            local robotConfig = XRobotManager.GetRobotTemplate(sourceEntityId)
            self._UiPanelRoleModel:UpdateRobotModel(sourceEntityId, robotConfig.CharacterId, nil, robotConfig.FashionId, robotConfig.WeaponId, finishedCallback)
        end
    else
        self._UiPanelRoleModel:UpdateCharacterModel(sourceEntityId, nil, nil, finishedCallback, nil, characterViewModel:GetFashionId())
    end
end
--endregion

--region Ui - BtnListener
function XUiBiancaTheatreMainMassage:AddBtnListener()
    self:BindHelpBtn(self.BtnHelp, XDataCenter.BiancaTheatreManager.GetHelpKey())
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)

    self:RegisterClickEvent(self.BtnFashion, self.OnBtnFashionClick)
    self:RegisterClickEvent(self.BtnOwnedDetail, self.OnBtnOwnedDetailClick)
    self:RegisterClickEvent(self.BtnTeaching, self.OnBtnTeachingClick)
end

function XUiBiancaTheatreMainMassage:OnBtnOwnedDetailClick()
    XLuaUiManager.Open("UiCharacterDetail", self:GetCurrentCharacterId())
end

function XUiBiancaTheatreMainMassage:OnBtnTeachingClick()
    XDataCenter.PracticeManager.OpenUiFubenPractice(self:GetCurrentCharacterId())
end

function XUiBiancaTheatreMainMassage:OnBtnFashionClick()
    XLuaUiManager.Open("UiFashion", self:GetCurrentCharacterId())
end
--endregion

return XUiBiancaTheatreMainMassage