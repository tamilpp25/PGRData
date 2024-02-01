local XUiGridTRPGRoleDetail = require("XUi/XUiTRPG/XUiGridTRPGRoleDetail")
local XUiGridTRPGBuff = require("XUi/XUiTRPG/XUiGridTRPGBuff")
local XUiTRPGPanelLevel = require("XUi/XUiTRPG/XUiTRPGPanel/XUiTRPGPanelLevel")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXTextManagerGetText = CS.XTextManager.GetText
local stringGsub = string.gsub

--虚拟相机Index
local CAMERA_INDEX = {
    MAIN = 1, --主界面
    TALENT = 2, --天赋界面
    TALENT_DETAIL = 3, --天赋详情界面
}

local XUiTRPGYingDi = XLuaUiManager.Register(XLuaUi, "UiTRPGYingDi")

function XUiTRPGYingDi:OnAwake()
    self:AutoAddListener()
    self.GridBuff.gameObject:SetActiveEx(false)
    self.LevelPanel = XUiTRPGPanelLevel.New(self.PanelLevel)

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.TRPGMoney, function()
        self.AssetActivityPanel:Refresh({ XDataCenter.ItemManager.ItemId.TRPGMoney })
    end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh({ XDataCenter.ItemManager.ItemId.TRPGMoney })
end

function XUiTRPGYingDi:OnStart()
    self.TabBtns = {}
    self.BuffGrids = {}
    self.SelectIndex = 1

    self:InitSceneRoot()
    self:InitRoles()
    self:RegisterRedPointEvent()
end

function XUiTRPGYingDi:OnEnable()
    XDataCenter.TRPGManager.CheckActivityEnd()
    self:UpdateRoles()
    self:UpdateCamera(CAMERA_INDEX.MAIN)
    self:UpdateBtnState()
end

function XUiTRPGYingDi:OnDestroy()
    self.LevelPanel:Delete()
    XRedPointManager.RemoveRedPointEvent(self.RedCollection)
    XRedPointManager.RemoveRedPointEvent(self.RedTalent)
end

function XUiTRPGYingDi:OnGetEvents()
    return { XEventId.EVENT_TRPG_ROLES_DATA_CHANGE, XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE }
end

function XUiTRPGYingDi:OnNotify(evt, ...)
    if evt == XEventId.EVENT_TRPG_ROLES_DATA_CHANGE then
        self:UpdateRoles()
    elseif evt == XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE then
        XDataCenter.TRPGManager.OnActivityMainLineStateChange(...)
    end
end

function XUiTRPGYingDi:InitSceneRoot()
    local root = self.UiModelGo.transform

    self.PanelRoleModel = root:FindTransform("UiModelParent")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.CameraNear = {
        [CAMERA_INDEX.MAIN] = root:FindTransform("YingdiNear01"),
        [CAMERA_INDEX.TALENT] = root:FindTransform("YingdiNear02"),
        [CAMERA_INDEX.TALENT_DETAIL] = root:FindTransform("YingdiNear03"),
    }
    self.CameraFar = {
        [CAMERA_INDEX.MAIN] = root:FindTransform("YingdiFar01"),
        [CAMERA_INDEX.TALENT] = root:FindTransform("YingdiFar02"),
        [CAMERA_INDEX.TALENT_DETAIL] = root:FindTransform("YingdiFar03"),
    }
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiTRPGYingDi:InitRoles()
    if XDataCenter.TRPGManager.IsRolesEmpty() then
        XLog.Error("XUiTRPGYingDi:InitRoles error: 调查员数据不存在")
        self:Close()
        return
    end

    local roleIds = XDataCenter.TRPGManager.GetSortedAllRoleIds()
    if XTool.IsTableEmpty(roleIds) then
        self:Close()
        return
    end
    self.RoleIds = roleIds

    local btns = {}
    for index, roleId in pairs(roleIds) do
        local btn = index == 1 and self.BtnHead or CSUnityEngineObjectInstantiate(self.BtnHead, self.PanelHead.transform)
        btns[index] = btn
    end
    self.PanelHead:Init(btns, function(index) self:OnSelectRole(index) end)
    self.TabBtns = btns
end

function XUiTRPGYingDi:UpdateRoles()
    local roleIds = self.RoleIds
    if XTool.IsTableEmpty(roleIds) then
        return
    end

    local firstOwnIndex
    self.RoleCount = 0
    for index, roleId in pairs(roleIds) do
        local btn = self.TabBtns[index]
        local isLock = not XDataCenter.TRPGManager.IsRoleOwn(roleId)

        if isLock then
            btn:SetDisable(true)
        else
            btn:SetDisable(false)
            local icon = XTRPGConfigs.GetRoleHeadIcon(roleId)
            btn:SetRawImage(icon)

            self.RoleCount = self.RoleCount + 1

            firstOwnIndex = firstOwnIndex or index
        end
    end

    if not XDataCenter.TRPGManager.IsRoleOwn(roleIds[self.SelectIndex]) then
        self.SelectIndex = firstOwnIndex
    end
    self.PanelHead:SelectIndex(self.SelectIndex)
end

function XUiTRPGYingDi:UpdateRoleDetail()
    local roleId = self.RoleIds[self.SelectIndex]

    local isLock = not XDataCenter.TRPGManager.IsRoleOwn(roleId)
    if isLock then
        XUiManager.TipText("TRPGRoleUnlockTip")
        return
    end

    local attributes = XDataCenter.TRPGManager.GetRoleAttributes(roleId)
    for index, attr in pairs(attributes) do
        local attrName = XTRPGConfigs.GetRoleAttributeName(attr.Type)
        self["TxtAttrType" .. index].text = attrName
        self["TxtValue" .. index].text = attr.Value
    end

    local buffGrids = self.BuffGrids
    local buffIds = XDataCenter.TRPGManager.GetRoleBuffIds(roleId)
    for index, buffId in pairs(buffIds) do
        local grid = buffGrids[index]
        if not grid then
            local ui = index == 1 and self.GridBuff or CSUnityEngineObjectInstantiate(self.GridBuff, self.PanelBuffContent)
            grid = XUiGridTRPGBuff.New(ui, self)
            buffGrids[index] = grid
        end

        grid:Refresh(buffId)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #buffIds + 1, #buffGrids do
        local grid = buffGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end

    local modelId = XTRPGConfigs.GetRoleModelId(roleId)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.RoleModelPanel:UpdateRoleModel(modelId, self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiTRPGYingDi, function(model)
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    end, nil, true)
end

function XUiTRPGYingDi:UpdateCamera(selectIndex)
    for index, camera in pairs(self.CameraNear) do
        camera.gameObject:SetActiveEx(index == selectIndex)
    end

    for index, camera in pairs(self.CameraFar) do
        camera.gameObject:SetActiveEx(index == selectIndex)
    end
end

function XUiTRPGYingDi:OnSelectRole(index)
    local roleId = self.RoleIds[index]

    local isLock = not XDataCenter.TRPGManager.IsRoleOwn(roleId)
    if isLock then return end

    self.SelectIndex = index

    self:UpdateRoleDetail()

    local notNext = index + 1 > self.RoleCount
    local notLast = index - 1 < 1
    self:FindChildUiObj("UiTRPGTalenTree"):RefreshData(roleId, notNext, notLast)
end

function XUiTRPGYingDi:OnSelectNextRole()
    local index = self.SelectIndex + 1
    if index > self.RoleCount then
        index = 1
    end

    self.PanelHead:SelectIndex(index)
end

function XUiTRPGYingDi:OnSelectLastRole()
    local index = self.SelectIndex - 1
    if index < 1 then
        index = self.SelectIndex
    end

    self.PanelHead:SelectIndex(index)
end

function XUiTRPGYingDi:AutoAddListener()
    self:RegisterClickEvent(self.BtnOverview, self.OnClickBtnOverview)
    self:RegisterClickEvent(self.BtnBlackCollection, self.OnClickBtnBlackCollection)
    self:RegisterClickEvent(self.BtniBag, self.OnClickBtnBag)
    self:RegisterClickEvent(self.BtnBack, self.OnClickBtnBack)
    self:RegisterClickEvent(self.BtnMainUi, self.OnClickBtnMainUi)
    self:RegisterClickEvent(self.BtnTalent, self.OnClickBtnTalent)
    self:RegisterClickEvent(self.BtnDesc, self.OnClickBtnDesc)
end

function XUiTRPGYingDi:OnClickBtnOverview()
    XLuaUiManager.Open("UiTRPGTalentOverView")
end

function XUiTRPGYingDi:OnClickBtnBlackCollection()
    local ret, desc = XTRPGConfigs.CheckButtonCondition(XTRPGConfigs.ButtonConditionId.Collection)
    if not ret then
        XUiManager.TipError(desc)
        return
    end
    XLuaUiManager.Open("UiTRPGCollection")
end

function XUiTRPGYingDi:OnClickBtnBag()
    self:UpdateCamera(CAMERA_INDEX.TALENT_DETAIL)
    XLuaUiManager.Open("UiTRPGBag")
end

function XUiTRPGYingDi:OnClickBtnBack()
    self:Close()
end

function XUiTRPGYingDi:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiTRPGYingDi:OnClickBtnDesc()
    local title = CSXTextManagerGetText("TRPGYingdiDescTitle")
    local desc = CSXTextManagerGetText("TRPGYingdiDesc")
    desc = stringGsub(desc, "\\n", "\n")
    XUiManager.UiFubenDialogTip(title, desc)
end

function XUiTRPGYingDi:OnClickBtnTalent()
    local ret, desc = XTRPGConfigs.CheckButtonCondition(XTRPGConfigs.ButtonConditionId.Talent)
    if not ret then
        XUiManager.TipError(desc)
        return
    end
    self:UpdateCamera(CAMERA_INDEX.TALENT)

    local index = self.SelectIndex
    local roleId = self.RoleIds[index]
    local showDetailCb = function() self:UpdateCamera(CAMERA_INDEX.TALENT_DETAIL) end
    local hideDetailCb = function() self:UpdateCamera(CAMERA_INDEX.TALENT) end
    local selectNextCb = function() self:OnSelectNextRole() end
    local selectLastCb = function() self:OnSelectLastRole() end
    local notNext = index + 1 > self.RoleCount or not XDataCenter.TRPGManager.IsRoleOwn(self.RoleIds[index + 1])
    local notLast = index - 1 < 1 or not XDataCenter.TRPGManager.IsRoleOwn(self.RoleIds[index - 1])

    local closeCb = function()
        self:UpdateCamera(CAMERA_INDEX.MAIN)
        self:PlayAnimation("PanelYingDiEnable")
    end
    self:OpenChildUi("UiTRPGTalenTree", roleId, closeCb, showDetailCb, hideDetailCb, selectNextCb, selectLastCb, notNext, notLast)

    self:PlayAnimation("PanelYingDiDisable")
end

function XUiTRPGYingDi:RegisterRedPointEvent()
    self.RedCollection = XRedPointManager.AddRedPointEvent(self.BtnBlackCollection, self.OnCheckBtnBlackCollectionRedPoint, self, { XRedPointConditions.Types.CONDITION_TRPG_COLLECTION_MEMOIR })
    self.RedTalent = XRedPointManager.AddRedPointEvent(self.BtnTalent, self.OnCheckBtnTalentRedPoint, self, { XRedPointConditions.Types.CONDITION_TRPG_ROLE_TALENT })
end

function XUiTRPGYingDi:OnCheckBtnBlackCollectionRedPoint(count)
    self.BtnBlackCollection:ShowReddot(count >= 0)
end

function XUiTRPGYingDi:OnCheckBtnTalentRedPoint(count)
    self.BtnTalent:ShowReddot(count >= 0)
end

function XUiTRPGYingDi:UpdateBtnState()
    local ret = XTRPGConfigs.CheckButtonCondition(XTRPGConfigs.ButtonConditionId.Collection)
    self.BtnBlackCollection:SetDisable(not ret)
    ret = XTRPGConfigs.CheckButtonCondition(XTRPGConfigs.ButtonConditionId.Talent)
    self.BtnTalent:SetDisable(not ret)
end