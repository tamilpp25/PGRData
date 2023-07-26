--==============
--超限乱斗角色页面
--==============
local XUiSuperSmashBrosCharacter = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosCharacter")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

function XUiSuperSmashBrosCharacter:OnStart(teamIds, pickOrReady)
    self.PickOrReady = pickOrReady
    self.TeamIds = teamIds
    self:InitBtns()
    self:InitPanels()
    self:SetActivityTimeLimit()
end

function XUiSuperSmashBrosCharacter:InitBtns()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    self:BindHelpBtn(self.BtnHelp, "SuperSmashBrosHelp")
end
--==============
--初始化各部分面板
--==============
function XUiSuperSmashBrosCharacter:InitPanels()
    self:InitModel()
    self:InitCharacterList() --角色列表
    self:InitCharacterInfo() --角色详细
end

function XUiSuperSmashBrosCharacter:InitModel()
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

function XUiSuperSmashBrosCharacter:InitCharacterList()
    local script = require("XUi/XUiSuperSmashBros/Character/Panels/XUiSSBCharacterListPanel")
    self.CharacterList = script.New(self.PanelCharaList, self.TeamIds, self.PickOrReady, function(xRole) self:OnSelectChara(xRole) end)
end

function XUiSuperSmashBrosCharacter:InitCharacterInfo()
    local script = require("XUi/XUiSuperSmashBros/Character/Panels/XUiSSBCharacterInfoPanel")
    self.CharacterInfo = script.New(self.PanelCharaInfo)
end

function XUiSuperSmashBrosCharacter:OnSelectChara(xRole)
    self.CharacterInfo:Refresh(xRole)
    self:UpdateModel(xRole)
end

function XUiSuperSmashBrosCharacter:UpdateModel(xRole)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    local cb = function(model)
        self.PanelDrag.Target = model.transform
        if not xRole:CheckIsIsomer() then
            self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        else
            self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
        end
    end
    if xRole:GetIsRobot() then
        local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(xRole:GetCharacterId())
        if XRobotManager.CheckUseFashion(xRole:GetId()) and isOwn then
            local character = XDataCenter.CharacterManager.GetCharacter(xRole:GetCharacterId())
            local robot2CharViewModel = character:GetCharacterViewModel()
            self.RoleModelPanel:UpdateRobotModel(xRole:GetId(), xRole:GetCharacterId(), nil, robot2CharViewModel:GetFashionId(), xRole:GetUsingWeaponId(), cb)
        else
            self.RoleModelPanel:UpdateRobotModel(xRole:GetId(), xRole:GetCharacterId(), nil, xRole:GetFashionId(), xRole:GetUsingWeaponId(), cb)
        end
    else
        --MODEL_UINAME对应UiModelTransform表，设置模型位置
        self.RoleModelPanel:UpdateCharacterModel(xRole:GetCharacterId(), self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiSuperSmashBrosCharacter, cb)
    end
end

function XUiSuperSmashBrosCharacter:OnEnable()
    XUiSuperSmashBrosCharacter.Super.OnEnable(self)
    self.CharacterList:OnRefresh()
end

--==============
--主界面按钮
--==============
function XUiSuperSmashBrosCharacter:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end
--==============
--返回按钮
--==============
function XUiSuperSmashBrosCharacter:OnClickBtnBack()
    self:Close()
end

function XUiSuperSmashBrosCharacter:OnGetEvents()
    return { XEventId.EVENT_SSB_CORE_REFRESH }
end

function XUiSuperSmashBrosCharacter:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_SSB_CORE_REFRESH then
        self.CharacterInfo:OnRefresh()
        self.CharacterList:OnRefresh()
    end
end
--==============
--设置活动关闭时处理
--==============
function XUiSuperSmashBrosCharacter:SetActivityTimeLimit()
    -- 自动关闭
    local endTime = XDataCenter.SuperSmashBrosManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.SuperSmashBrosManager.OnActivityEndHandler()
        end
    end)
end