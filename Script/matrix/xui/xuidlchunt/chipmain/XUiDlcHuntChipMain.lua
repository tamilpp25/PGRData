local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XViewModelDlcHuntChip = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntChip")
local XUiDlcHuntChipGridAttr = require("XUi/XUiDlcHunt/Chip/XUiDlcHuntChipGridAttr")
local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiDlcHuntChipMainGroupGrid = require("XUi/XUiDlcHunt/ChipMain/XUiDlcHuntChipMainGroupGrid")

---@class XUiDlcHuntChipMain:XLuaUi
local XUiDlcHuntChipMain = XLuaUiManager.Register(XLuaUi, "UiDlcHuntChipMain")

function XUiDlcHuntChipMain:Ctor()
    ---@type XViewModelDlcHuntChip
    self._ViewModel = XViewModelDlcHuntChip.New()
    self._UiAttrList = {}
    self._Ui3DRoot = {}
    ---@type DlcHuntChipMainModel[]
    self._ModelChip = {}
    self._Callback = false
    self._Timer = false
end

function XUiDlcHuntChipMain:OnAwake()
    self:RegisterClickEvent(self.BtnMainUi, function()
        XLuaUiManager.RunMain()
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnClickBack, true)
    XUiHelper.RegisterClickEvent(self, self.BtnEquip, self.OnClickEquip)
    XUiHelper.RegisterClickEvent(self, self.BtnGroup, self.OnClickShowGroupList)
    XUiHelper.RegisterClickEvent(self, self.BtnExclamatoryMark, self.OnClickGroupAttr)
    XUiHelper.RegisterClickEvent(self, self.BtnWrite, self.OnClickRename)
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, self.OnClickHideGroupList)

    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelChipHelp)
    self.DynamicTable:SetProxy(XUiDlcHuntChipMainGroupGrid)
    self.DynamicTable:SetDelegate(self)
    self.PanelBagItem.gameObject:SetActiveEx(false)

    local helpBtn = XUiHelper.TryGetComponent(self.BtnBack.transform.parent, "BtnHelp", "Button")
    self:BindHelpBtn(helpBtn, XDlcHuntConfigs.HELP_KEY.CHIP_GROUP)
    self.UiNearCamera = XUiHelper.TryGetComponent(self.UiModel.UiNearRoot, "UiNearCamera", "Camera")
end

function XUiDlcHuntChipMain:OnStart(chipGroup, callback)
    self._Callback = callback
    local panelModel = XUiHelper.TryGetComponent(self.UiModel.UiNearRoot, "PanelModel")
    self._Ui3DRoot.Transform = panelModel
    XTool.InitUiObject(self._Ui3DRoot)
    for i = 1, XDlcHuntChipConfigs.CHIP_GROUP_CHIP_AMOUNT do
        local isMainChip = XDlcHuntChipConfigs.IsMainChipByPos(i)
        local uiChipName = self._Ui3DRoot["TxtLevel" .. i]
        local uiBreakthroughIcon = XUiHelper.TryGetComponent(uiChipName.transform.parent, "ImgIcon", "Image")
                or XUiHelper.TryGetComponent(uiChipName.transform.parent, "Image", "Image")
        ---@alias DlcHuntChipMainModel{Model:XUiPanelRoleModel,Text:table,IconAdd:table,ChipId:number,IconBreakthrough:table}
        self._ModelChip[i] = {
            Model = XUiPanelRoleModel.New(self:GetChipModelRoot(i), nil, nil, nil, not isMainChip),
            Text = uiChipName,
            IconAdd = self._Ui3DRoot["IconJia" .. i],
            EffectRefresh = self._Ui3DRoot["EffectRefresh" .. i],
            ChipId = 0,
            IconBreakthrough = uiBreakthroughIcon
        }
        local button = self._Ui3DRoot["BtnClick" .. i]
        XUiHelper.RegisterClickEvent(self, button, function()
            XLuaUiManager.Open("UiDlcHuntChipReplace", self._ViewModel:GetChipGroup(), i)
        end)
    end

    self.PanelChipReplace.gameObject:SetActiveEx(false)
    self._ViewModel:SetDefaultGroup(chipGroup)

    local root = self.UiSceneInfo.Transform
    local objGroupBase = root:FindTransform("GroupBase")
    self._ObjFxExitGate = objGroupBase:FindTransform("FxExitGate")

    local modelRoot = self.UiModelGo.transform
    local sceneAnimationEnable = XUiHelper.TryGetComponent(modelRoot, "AnimEnable/Enable", "PlayableDirector")
    sceneAnimationEnable.gameObject:PlayTimelineAnimation()
end

function XUiDlcHuntChipMain:OnEnable()
    self:Update()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_UPDATE, self.Update, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_CLOSE, self.HideGroupList, self)
    self:HideScreenEffect4ChipMain()

    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateGuideChipBtnPosition()
        end, 0)
    end
    self:SelectCamera4Ipad()
end

function XUiDlcHuntChipMain:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_UPDATE, self.Update, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_CLOSE, self.HideGroupList, self)
    self:ShowScreenEffect4ChipMain()

    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiDlcHuntChipMain:Update()
    self.TxtTitle2.text = self._ViewModel:GetFightingPower()
    self:UpdateGroupName()
    self:UpdateAttr()
    self:UpdateGroupInScene()
    self:UpdateSelected()
end

function XUiDlcHuntChipMain:UpdateGroupName()
    self.TxtName.text = self._ViewModel:GetGroupName()
end

function XUiDlcHuntChipMain:UpdateAttr()
    local attrTable = self._ViewModel:GetChipAttr4Display()
    XUiDlcHuntUtil.UpdateDynamicItem(self._UiAttrList, attrTable, self.PanelAttr1, XUiDlcHuntChipGridAttr)
end

function XUiDlcHuntChipMain:OnClickShowGroupList()
    self.PanelChipReplace.gameObject:SetActiveEx(true)
    self:UpdateGroupList()
end

function XUiDlcHuntChipMain:OnClickEquip()
    XLuaUiManager.Open("UiDlcHuntChipBatch", self._ViewModel:GetChipGroup())
end

function XUiDlcHuntChipMain:OnClickGroupAttr()
    XLuaUiManager.Open("UiDlcHuntAttrDialog", { ChipGroup = self._ViewModel:GetChipGroup() })
end

function XUiDlcHuntChipMain:OnClickRename()
    XLuaUiManager.Open("UiDlcHuntRenaming", self._ViewModel:GetChipGroup())
end

function XUiDlcHuntChipMain:GetChipModelRoot(index)
    if index == 1 then
        return self._Ui3DRoot.PanelChipMain
    end
    if index == 2 then
        return self._Ui3DRoot.PanelChipSub01
    end
    if index == 3 then
        return self._Ui3DRoot.PanelChipSub02
    end
    if index == 4 then
        return self._Ui3DRoot.PanelChipSub03
    end
    if index == 5 then
        return self._Ui3DRoot.PanelChipSub04
    end
    if index == 6 then
        return self._Ui3DRoot.PanelChipSub05
    end
    if index == 7 then
        return self._Ui3DRoot.PanelChipSub06
    end
    if index == 8 then
        return self._Ui3DRoot.PanelChipSub07
    end
    if index == 9 then
        return self._Ui3DRoot.PanelChipSub08
    end
    XLog.Error("[XUiDlcHuntChipMain] get chip model root error:" .. tostring(index))
end

function XUiDlcHuntChipMain:UpdateGroupInScene()
    local group = self._ViewModel:GetChipGroup()
    local isChipGroupChange = self._ViewModel:IsChipGroupChange()
    for i = 1, group:GetCapacity() do
        local chip = group:GetChip(i)
        local data = self._ModelChip[i]
        local isPlayEffect = false
        local currentChipId = chip and chip:GetUid() or 0
        if data.ChipId ~= currentChipId then
            data.ChipId = currentChipId
            isPlayEffect = true
        end

        if chip then
            local needDisplayController = nil
            if chip:IsMainChip() then
                needDisplayController = false
            else
                needDisplayController = true
            end
            data.Model:UpdateRoleModel(chip:GetModel(), nil, nil, nil, nil, needDisplayController)
            data.Model:ShowRoleModel()
            data.Model:LoadEffect(chip:GetEffectUiChipMain())
            data.IconAdd.gameObject:SetActiveEx(false)
            data.Text.text = XUiHelper.GetText("DlcHuntChipGroupLevel", chip:GetLevel())
            data.Text.gameObject:SetActiveEx(true)
            data.IconBreakthrough:SetSprite(chip:GetIconBreakthroughColorInverse())
            data.IconBreakthrough.gameObject:SetActiveEx(true)
        else
            data.Model:HideRoleModel()
            data.IconAdd.gameObject:SetActiveEx(true)
            data.Text.gameObject:SetActiveEx(false)
            data.ChipId = 0
            data.EffectRefresh.gameObject:SetActiveEx(false)
            data.IconBreakthrough.gameObject:SetActiveEx(false)
        end
        if isChipGroupChange or isPlayEffect then
            data.EffectRefresh.gameObject:SetActiveEx(false)
            data.EffectRefresh.gameObject:SetActiveEx(true)
        else
            data.EffectRefresh.gameObject:SetActiveEx(false)
        end
    end
end

function XUiDlcHuntChipMain:OnClickHideGroupList()
    self:HideGroupList()
end

function XUiDlcHuntChipMain:HideGroupList()
    self.PanelChipReplace.gameObject:SetActiveEx(false)
end

function XUiDlcHuntChipMain:UpdateGroupList()
    self.DynamicTable:SetDataSource(self._ViewModel:GetAllChipGroup())
    self.DynamicTable:ReloadDataASync(1)
end

---@param grid XUiDlcHuntChipMainGroupGrid
function XUiDlcHuntChipMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetViewModel(self._ViewModel)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
    end
end

function XUiDlcHuntChipMain:UpdateSelected()
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        grid:UpdateSelected()
    end
end

function XUiDlcHuntChipMain:OnClickBack()
    if self._Callback then
        self._Callback(self._ViewModel:GetChipGroup())
    end
    self:Close()
end

function XUiDlcHuntChipMain:HideScreenEffect4ChipMain()
    self._ObjFxExitGate.gameObject:SetActiveEx(false)
end

function XUiDlcHuntChipMain:ShowScreenEffect4ChipMain()
    self._ObjFxExitGate.gameObject:SetActiveEx(true)
end

function XUiDlcHuntChipMain:UpdateGuideChipBtnPosition()
    if self.Chip3d then
        local pos = self._Ui3DRoot.BtnClick1.transform.position
        local camera = self.UiNearCamera
        local screenPos = camera:WorldToScreenPoint(pos);
        local viewRatio = CS.XUiManager.ViewRatio;
        local uiPos = CS.UnityEngine.Vector2(screenPos.x * viewRatio, screenPos.y * viewRatio)
        self.Chip3d.anchoredPosition = uiPos
    end
end

function XUiDlcHuntChipMain:SelectCamera4Ipad()
    local width = CS.XUiManager.RealScreenWidth
    local height = CS.XUiManager.RealScreenHeight
    local ipadRatio = 1.6
    if width / height < ipadRatio then
        local camNearMainIpad = XUiHelper.TryGetComponent(self.UiModel.UiNearRoot, "CamNearMainIpad", "Transform")
        camNearMainIpad.gameObject:SetActiveEx(true)

        local camFarMainIpad = XUiHelper.TryGetComponent(self.UiModel.UiFarRoot, "CamFarMainIpad", "Transform")
        camFarMainIpad.gameObject:SetActiveEx(true)

        local camUiIpad = XUiHelper.TryGetComponent(self.UiModelGo.transform, "UiRoot/CamUiIpad", "Transform")
        camUiIpad.gameObject:SetActiveEx(true)
    end
end

return XUiDlcHuntChipMain