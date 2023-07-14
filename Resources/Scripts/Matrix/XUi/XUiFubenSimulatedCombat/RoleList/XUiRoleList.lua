--成员列表页面
local CSXTextManagerGetText = CS.XTextManager.GetText
local XUiSimulatedCombatList = XLuaUiManager.Register(XLuaUi, "UiSimulatedCombatRoleList")
local XUiCharacterList = require("XUi/XUiFubenSimulatedCombat/RoleList/CharacterPanel/XUiCharacterList")
local CAMERA_NUM = 5
XUiSimulatedCombatList.ChildUiName = {
    UiSimulatedCombatListCharaInfo = "UiSimulatedCombatListCharaInfo",
    UiSimulatedCombatViewRole = "UiSimulatedCombatViewRole"
}
function XUiSimulatedCombatList:OnAwake()
    XTool.InitUiObject(self)
    --XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:AddListener()
end

function XUiSimulatedCombatList:OnStart(memberId, stageInterId)
    self.MemberId = memberId
    self.StageInterId = stageInterId
    self:OpenChild(XUiSimulatedCombatList.ChildUiName.UiSimulatedCombatListCharaInfo)
    self.CharaInfo = self:FindChildUiObj(XUiSimulatedCombatList.ChildUiName.UiSimulatedCombatListCharaInfo)
    self:InitModel()
    self:InitCharacterList()
end

function XUiSimulatedCombatList:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, "SimulatedCombat")
end

function XUiSimulatedCombatList:OnBtnBackClick()
    if self.OpenChildName == XUiSimulatedCombatList.ChildUiName.UiSimulatedCombatViewRole then
        self:OpenChild(XUiSimulatedCombatList.ChildUiName.UiSimulatedCombatListCharaInfo)
        self.CharaInfo = self:FindChildUiObj(XUiSimulatedCombatList.ChildUiName.UiSimulatedCombatListCharaInfo)
        self:UpdateCamera(XCharacterConfigs.XUiCharacter_Camera.MAIN)
        self.TextRoleList.gameObject:SetActiveEx(true)
        return
    else
        self:Close()
    end
end

function XUiSimulatedCombatList:OnBtnMainUiClick()
    -- 二次弹窗确认
    local title = CSXTextManagerGetText("TipTitle")
    local content = CSXTextManagerGetText("SimulatedCombatBackConfirm")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        XLuaUiManager.RunMain()
    end)
end

function XUiSimulatedCombatList:Refresh(characterId, robotId)
    self.RobotId = robotId
    self.CharacterId = characterId
    self.RobotCfg = XRobotManager.GetRobotTemplate(robotId)
    self:UpdateModel(characterId, robotId)
    self.CharaInfo:UpdateView(robotId)
end

function XUiSimulatedCombatList:InitModel()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.ImgEffectLogoGouzao = root:FindTransform("ImgEffectLogoGouzao")
    self.ImgEffectLogoGanran = root:FindTransform("ImgEffectLogoGanran")
    self.CameraFar = {
        root:FindTransform("UiCamFarLv"),
        root:FindTransform("UiCamFarGrade"),
        root:FindTransform("UiCamFarQuality"),
        root:FindTransform("UiCamFarSkill"),
        root:FindTransform("UiCamFarrExchange"),
    }
    self.CameraNear = {
        root:FindTransform("UiCamNearLv"),
        root:FindTransform("UiCamNearGrade"),
        root:FindTransform("UiCamNearQuality"),
        root:FindTransform("UiCamNearSkill"),
        root:FindTransform("UiCamNearrExchange"),
    }
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiSimulatedCombatList:OnGetEvents()
    return { XEventId.EVENT_ACTIVITY_ON_RESET }
end

function XUiSimulatedCombatList:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.SimulatedCombat then return end
        XDataCenter.FubenSimulatedCombatManager.OnActivityEnd()
    end
end

function XUiSimulatedCombatList:UpdateCamera(index)
    self.CurCameraIndex = index
    for i = 1, CAMERA_NUM do
        if self.CurCameraIndex ~= i then
            self.CameraFar[i].gameObject:SetActiveEx(false)
            self.CameraNear[i].gameObject:SetActiveEx(false)
        end
    end

    if self.CameraFar[self.CurCameraIndex] then
        self.CameraFar[self.CurCameraIndex].gameObject:SetActiveEx(true)
    end
    if self.CameraNear[self.CurCameraIndex] then
        self.CameraNear[self.CurCameraIndex].gameObject:SetActiveEx(true)
    end
end

function XUiSimulatedCombatList:InitCharacterList()
    -- 加载左侧角色列表
    self.CharacterList = XUiCharacterList.New(self.PanelRoleContent, self, self.GridCharacter)
    self.CharacterList:UpdateData(self.MemberId)
end

function XUiSimulatedCombatList:UpdateModel(characterId, robotId)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    local cb = function(model)
        self.PanelDrag.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    end
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)
    self.RoleModelPanel:UpdateRobotModel(robotId, characterId, nil, robotCfg and robotCfg.FashionId, robotCfg and robotCfg.WeaponId, cb)
end

function XUiSimulatedCombatList:OpenChild(childName)
    if self.OpenChildName == childName then return end
    self.OpenChildName = childName
    self:OpenOneChildUi(childName, self)
    if childName == XUiSimulatedCombatList.ChildUiName.UiSimulatedCombatViewRole then
        self.TextRoleList.gameObject:SetActiveEx(false)
        local propertyChildUi = self:FindChildUiObj(childName)
        propertyChildUi:UpdateShowPanel()
    end

end

return XUiSimulatedCombatList