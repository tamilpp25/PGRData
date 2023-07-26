--虚像地平线成员列表页面
local XUiExpeditionRoleList = XLuaUiManager.Register(XLuaUi, "UiExpeditionRoleList")
local XUiExpeditionRoleListCharacterList = require("XUi/XUiExpedition/RoleList/XUiExpeditionRoleListCharacterPanel/XUiExpeditionRoleListCharacterList")
local XUiExpeditionRoleListComboList = require("XUi/XUiExpedition/RoleList/XUiExpeditionRoleListComboPanel/XUiExpeditionRoleListComboList")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local XTeam = require("XEntity/XExpedition/XExpeditionTeam")
local CAMERA_NUM = 5
XUiExpeditionRoleList.ChildUiName = {
    UiExpeditionRoleListCharaInfo = "UiExpeditionRoleListCharaInfo",
    UiExpeditionViewRole = "UiExpeditionViewRole"
}
function XUiExpeditionRoleList:OnAwake()
    XTool.InitUiObject(self)
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:AddListener()
end
--==================
--@param defaultTeamId:预设小队Id
--若传入defaultTeamId,则表示这个是预览预设小队的界面，只显示预设小队内容
--==================
function XUiExpeditionRoleList:OnStart(defaultTeamId)
    self:InitDefaultTeam(defaultTeamId)
    self:OpenChild(XUiExpeditionRoleList.ChildUiName.UiExpeditionRoleListCharaInfo)
    self:InitModel()
    self:InitCharacterList()
    self:InitComboList()
end

function XUiExpeditionRoleList:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, "ExpeditionMainHelp")
end

function XUiExpeditionRoleList:OnBtnBackClick()
    if self.OpenChildName == XUiExpeditionRoleList.ChildUiName.UiExpeditionViewRole then
        self:OpenChild(XUiExpeditionRoleList.ChildUiName.UiExpeditionRoleListCharaInfo)
        self:UpdateCamera(XCharacterConfigs.XUiCharacter_Camera.MAIN)
        self.TextRoleList.gameObject:SetActiveEx(true)
        return
    else
        self:Close()
    end
end

function XUiExpeditionRoleList:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiExpeditionRoleList:Refresh(characterId, robotId, eCharaId)
    self.RobotId = robotId
    self.CharacterId = characterId
    self.RobotCfg = XRobotManager.GetRobotTemplate(robotId)
    self:UpdateModel(characterId, robotId)
    self:UpdateCharaInfo(eCharaId)
end

function XUiExpeditionRoleList:InitModel()
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

function XUiExpeditionRoleList:OnGetEvents()
    return { XEventId.EVENT_ACTIVITY_ON_RESET }
end

function XUiExpeditionRoleList:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.Expedition then return end
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionOnClose"))
    end
end

function XUiExpeditionRoleList:UpdateCamera(index)
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

function XUiExpeditionRoleList:InitCharacterList()
    self.CharacterList = XUiExpeditionRoleListCharacterList.New(self.PanelRoleContent, self, self.GridCharacter)
end

function XUiExpeditionRoleList:InitComboList()
    self.ComboList = XUiExpeditionRoleListComboList.New(self.SViewComboList, self)
    self.ComboList:UpdateData()
end

function XUiExpeditionRoleList:UpdateModel(characterId, robotId)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    local cb = function(model)
        self.PanelDrag.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    end
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)
    self.RoleModelPanel:UpdateRobotModel(robotId, characterId, nil, robotCfg and robotCfg.FashionId, robotCfg and robotCfg.WeaponId, cb)
end

function XUiExpeditionRoleList:UpdateCharaInfo(eCharacterId)
    self.CharaInfo:UpdateView(eCharacterId)
end

function XUiExpeditionRoleList:OpenChild(childName)
    if self.OpenChildName == childName then return end
    self.OpenChildName = childName
    self:OpenOneChildUi(childName, self)
    if childName == XUiExpeditionRoleList.ChildUiName.UiExpeditionViewRole then
        self.TextRoleList.gameObject:SetActiveEx(false)
        local propertyChildUi = self:FindChildUiObj(childName)
        propertyChildUi:UpdateShowPanel()
    end
end

function XUiExpeditionRoleList:InitDefaultTeam(defaultTeamId)
    self.IsPreviewDefault = defaultTeamId and defaultTeamId > 0
    if not defaultTeamId then return end
    self.PreviewTeam = XTeam.New(defaultTeamId)
    local eActivity = XDataCenter.ExpeditionManager.GetEActivity()
    local robotMaxNum = eActivity:GetRecruitRobotMaxNum()
    self.PreviewTeam:InitTeamPos(robotMaxNum)
    local teamCfg = XExpeditionConfig.GetDefaultTeamCfgByTeamId(defaultTeamId)
    self.PreviewTeam:AddMemberListByECharaIds(teamCfg.ECharacterIds)
end

return XUiExpeditionRoleList