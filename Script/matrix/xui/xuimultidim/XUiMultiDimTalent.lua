local XUiMultiDimTalent = XLuaUiManager.Register(XLuaUi, "UiMultiDimTalent")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local UiMultiDimTalentPopup = "UiMultiDimTalentPopup"

function XUiMultiDimTalent:OnAwake()
    self:RegisterUiEvents()
    self:InitSceneRoot()
    self.CareerId = 1
end

function XUiMultiDimTalent:OnStart()
    local itemId = XDataCenter.MultiDimManager.GetActivityItemId()
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ itemId }, self.PanelSpecialTool, self)
    
    self:InitLeftTabBtn()
    self.MultiDimCareer = XDataCenter.MultiDimManager.GetMultiDimCareerInfo()
    
    -- 开启自动关闭检查
    local endTime = XDataCenter.MultiDimManager.GetEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.MultiDimManager.HandleActivityEndTime()
        end
    end)
end

function XUiMultiDimTalent:OnEnable()
    self.Super.OnEnable(self)
    self.PanelPropertyButtons:SelectIndex(self.CurrentTab or 1)
    --是否在冷却中
    local isCoolingTime = XDataCenter.MultiDimManager.CheckTalentResetCoolingTime()
    self:RefreshTalentResetBtn(isCoolingTime)
    if isCoolingTime then
        self:StartTime()
    end
end

function XUiMultiDimTalent:OnGetEvents()
    return {
        XEventId.EVENT_MULTI_DIM_TALENT_LEVEL_UPDATE,
    }
end

function XUiMultiDimTalent:OnNotify(event, ...)
    if event == XEventId.EVENT_MULTI_DIM_TALENT_LEVEL_UPDATE then
        -- 刷新UI
        self:RefreshView()
    end
end

function XUiMultiDimTalent:OnDisable()
    self.Super.OnDisable(self)
    self:StopTime()
end

function XUiMultiDimTalent:InitLeftTabBtn()
    local tabGroup = {
        self.BtnTabAttack,
        self.BtnTabArmor,
        self.BtnTabAuxiliary,
    }
    self.PanelPropertyButtons:Init(tabGroup, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
end

function XUiMultiDimTalent:OnClickTabCallBack(tabIndex)
    if self.CurrentTab and self.CurrentTab == tabIndex then
        return
    end

    self.CurrentTab = tabIndex
    local config = self.MultiDimCareer[tabIndex]
    self.CareerId = config.Career
    -- 刷新模型
    self:RefreshModel()
    -- 刷新UI
    self:RefreshView()
end

--region 3D模型

function XUiMultiDimTalent:InitSceneRoot()
    local root = self.UiModelGo.transform
    self.PanelModel = root:FindTransform("PanelModel")
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelModel, self.Name, nil, true)
end

function XUiMultiDimTalent:RefreshModel()
    -- 模型根据预选角色去加载
    local entityIds = XDataCenter.MultiDimManager.GetPresetCharacters(self.CareerId)
    local entity = XDataCenter.CharacterManager.GetCharacter(entityIds[1])
    if not entity or not entity.GetCharacterViewModel then
        self.RoleModelPanel:HideRoleModel()
        return
    end
    local characterViewModel = entity:GetCharacterViewModel()
    local sourceEntityId = characterViewModel:GetSourceEntityId()
    self.RoleModelPanel:UpdateCharacterModel(sourceEntityId, self.PanelModel, self.Name, function(model) end, nil, characterViewModel:GetFashionId())
    self.RoleModelPanel:ShowRoleModel()
end

--endregion

function XUiMultiDimTalent:RefreshView()
    for _, talentType in pairs(XMultiDimConfig.TalentType) do
        local name = XDataCenter.MultiDimManager.GetTalentName(self.CareerId, talentType)
        local level = XDataCenter.MultiDimManager.GetTalentLevel(self.CareerId, talentType)
        local icon = XDataCenter.MultiDimManager.GetTalentIcon(self.CareerId, talentType)
        if talentType == XMultiDimConfig.TalentType.CoreTalent then
            -- 核心天赋
            self.BtnMajorTalent:SetNameByGroup(0, CSXTextManagerGetText("MultiDimCoreTalentGrade", level))
            self.BtnMajorTalent:SetNameByGroup(1, name)
            self.BtnMajorTalent:SetSprite(icon)
        else
            -- 子天赋
            local btnName = "BtnTalent0" .. talentType
            self[btnName]:SetNameByGroup(0, name)
            self[btnName]:SetNameByGroup(1, CSXTextManagerGetText("MultiDimChildTalentGrade", level))
            self[btnName]:SetRawImage(icon)
        end
    end
end

function XUiMultiDimTalent:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMajorTalent, self.OnBtnMajorTalentClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTalent01, self.OnBtnTalent01Click)
    XUiHelper.RegisterClickEvent(self, self.BtnTalent02, self.OnBtnTalent02Click)
    XUiHelper.RegisterClickEvent(self, self.BtnTalent03, self.OnBtnTalent03Click)
    XUiHelper.RegisterClickEvent(self, self.BtnTongBlack, self.OnBtnTongBlackClick)
end

function XUiMultiDimTalent:OnBtnBackClick()
    self:Close()
end

function XUiMultiDimTalent:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
-- 天赋
function XUiMultiDimTalent:OnBtnMajorTalentClick()
    self:OpenTalentPopup(self.BtnMajorTalent, XMultiDimConfig.TalentType.CoreTalent)
end
-- 子天赋
function XUiMultiDimTalent:OnBtnTalent01Click()
    self:OpenTalentPopup(self.BtnTalent01, XMultiDimConfig.TalentType.Talent01)
end
-- 子天赋
function XUiMultiDimTalent:OnBtnTalent02Click()
    self:OpenTalentPopup(self.BtnTalent02, XMultiDimConfig.TalentType.Talent02)
end
-- 子天赋
function XUiMultiDimTalent:OnBtnTalent03Click()
    self:OpenTalentPopup(self.BtnTalent03, XMultiDimConfig.TalentType.Talent03)
end

function XUiMultiDimTalent:OpenTalentPopup(btn, talentType)
    if not XLuaUiManager.IsUiShow(UiMultiDimTalentPopup) then
        self:OpenChildUi(UiMultiDimTalentPopup)
    else
        return
    end
    btn:SetButtonState(XUiButtonState.Select)
    self:FindChildUiObj(UiMultiDimTalentPopup):Refresh(self.CareerId, talentType, function()
        btn:SetButtonState(XUiButtonState.Normal)
    end)
end

-- 重置
function XUiMultiDimTalent:OnBtnTongBlackClick()
    local isCoolingTime = XDataCenter.MultiDimManager.CheckTalentResetCoolingTime()
    if isCoolingTime then
        return
    end
    
    local title = CSXTextManagerGetText("MultiDimTalentResetTitle")
    local content = CSXTextManagerGetText("MultiDimTalentResetContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal,
            nil, 
            function()
                -- 重置天赋 默认值为0时是重置所以天赋
                XDataCenter.MultiDimManager.MultiDimResetTalentRequest(0, function()
                    self:RefreshTalentResetBtn(true)
                    self:StartTime()
                end)
            end)
end

--region 重置倒计时

function XUiMultiDimTalent:RefreshTalentResetBtn(isCoolingTime)
    self.BtnTongBlack:SetButtonState(isCoolingTime and XUiButtonState.Disable or XUiButtonState.Normal)
end

function XUiMultiDimTalent:StartTime()
    if self.Timer then
        self:StopTime()
    end
    
    self:UpdateTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTime()
    end, XScheduleManager.SECOND)
end

function XUiMultiDimTalent:UpdateTime()
    if XTool.UObjIsNil(self.BtnTongBlack) then
        self:StopTime()
        return
    end
    local resetRemainTime = XDataCenter.MultiDimManager.GetTalentResetCoolingTime()
    if resetRemainTime <= 0 then
        self:StopTime()
        -- 重置冷却时间结束
        self:RefreshTalentResetBtn(false)
        return
    end

    local timeText = XUiHelper.GetTime(resetRemainTime, XUiHelper.TimeFormatType.Multi_Dim)
    self.BtnTongBlack:SetNameByGroup(1, CSXTextManagerGetText("MultiDimTalentResetTimeText", timeText))
end

function XUiMultiDimTalent:StopTime()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--endregion

return XUiMultiDimTalent