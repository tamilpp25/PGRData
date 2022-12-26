local CSXTextManagerGetText = CS.XTextManager.GetText
local PlatForm = CS.UnityEngine.Application.platform
local IsWindows = PlatForm == CS.UnityEngine.RuntimePlatform.WindowsEditor or PlatForm == CS.UnityEngine.RuntimePlatform.WindowsPlayer

local XUiInfestorExploreTeamEdit = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreTeamEdit")

local CHAR_POS1 = 1
local CHAR_POS2 = 2
local CHAR_POS3 = 3
local MAX_CHAR_COUNT = 3
local LONG_CLICK_TIME = 0
local TIMER = 1
local LOAD_TIME = 10

function XUiInfestorExploreTeamEdit:OnAwake()
    self:AutoAddListener()
    self.RectTransform = self.Transform:GetComponent("RectTransform")
    self.PanelTip.gameObject:SetActiveEx(false)
    self.ImgRoleRepace.gameObject:SetActiveEx(false)
    self.BtnTeamPrefab.gameObject:SetActiveEx(false)
    self:InitFirstFightTabBtns()
end

function XUiInfestorExploreTeamEdit:OnStart(characterLimitType, limitBuffId, characterIds, captainPos, saveCallBack, enterCallBack, forbitReplaceCharacter, firstFightPos)
    self.CharacterLimitType = characterLimitType
    self.LimitBuffId = limitBuffId
    self.ChangeCharIndex = 0
    self.CaptainPos = captainPos or 1
    self.FirstFightPos = firstFightPos or 1
    self.CharacterIds = characterIds
    self.SaveCallBack = saveCallBack
    self.EnterCallBack = enterCallBack
    self.ForbitReplaceCharacter = forbitReplaceCharacter
    self.IsShowCharacterInfo = false
    self:InitSceneRoot()
    self:InitCharacterLimit()
end

function XUiInfestorExploreTeamEdit:OnEnable()
    self:UpdateTeamInfo()

    self:OnClickTabCaptainCallBack(self.CaptainPos)
    self.PanelTabCaptain:SelectIndex(self.FirstFightPos)
end

function XUiInfestorExploreTeamEdit:OnDisable()
    self:RemoveTimer()
    self.SaveCallBack(self.CharacterIds, self.CaptainPos, self.FirstFightPos)
end

function XUiInfestorExploreTeamEdit:InitCharacterLimit()
    local characterLimitType = self.CharacterLimitType

    if not XFubenConfigs.IsStageCharacterLimitConfigExist(characterLimitType) then
        self.PanelRequireCharacter.gameObject:SetActiveEx(false)
        return
    else
        self.PanelRequireCharacter.gameObject:SetActiveEx(true)
    end

    local icon = XFubenConfigs.GetStageCharacterLimitImageTeamEdit(characterLimitType)
    self.ImgRequireCharacter:SetSprite(icon)
end

function XUiInfestorExploreTeamEdit:GetCurTeamCharacterType()
    for _, characterId in pairs(self.CharacterIds) do
        if characterId > 0 then
            return XCharacterConfigs.GetCharacterType(characterId)
        end
    end
end

function XUiInfestorExploreTeamEdit:RefreshCharacterTypeTips()
    local characterLimitType = self.CharacterLimitType
    local limitBuffId = self.LimitBuffId
    local characterType = self:GetCurTeamCharacterType()
    local defaultCharacterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)
    local text = XFubenConfigs.GetStageCharacterLimitTextTeamEdit(characterLimitType, characterType, limitBuffId)
    self.TxtRequireCharacter.text = text

    local buffDes = XDataCenter.FubenInfestorExploreManager.GetBuffDes()
    if buffDes ~= "" then
        self.TxtEffectPosition.text = buffDes
        self.PanelBuffDes.gameObject:SetActiveEx(true)
    else
        self.PanelBuffDes.gameObject:SetActiveEx(false)
    end
end

function XUiInfestorExploreTeamEdit:InitFirstFightTabBtns()
    local tabGroup = {
        self.BtnRed,
        self.BtnBlue,
        self.BtnYellow,
    }
    self.PanelTabCaptain:Init(tabGroup, function(tabIndex) self:OnFirstFightTabClick(tabIndex) end)
end

function XUiInfestorExploreTeamEdit:InitSceneRoot()
    local sceneRoot = self.UiSceneInfo.Transform
    self.PanelRoleEffect = {
        [CHAR_POS1] = sceneRoot.transform:FindTransform("PanelRoleEffect1"),
        [CHAR_POS2] = sceneRoot.transform:FindTransform("PanelRoleEffect2"),
        [CHAR_POS3] = sceneRoot.transform:FindTransform("PanelRoleEffect3"),
    }
    self.RoleModelPanel = {
        [CHAR_POS1] = XUiPanelRoleModel.New(sceneRoot.transform:FindTransform("PanelRoleModel1"), self.Name, nil, true, nil, true, true),
        [CHAR_POS2] = XUiPanelRoleModel.New(sceneRoot.transform:FindTransform("PanelRoleModel2"), self.Name, nil, true, nil, true, true),
        [CHAR_POS3] = XUiPanelRoleModel.New(sceneRoot.transform:FindTransform("PanelRoleModel3"), self.Name, nil, true, nil, true, true),
    }
end

-- 设置首次出场
function XUiInfestorExploreTeamEdit:OnFirstFightTabClick(tabIndex)
    self.FirstFightPos = tabIndex
    for i = 1, MAX_CHAR_COUNT do
        self["PanelFirstRole" .. i].gameObject:SetActiveEx(i == tabIndex)
    end
end

-- 设置队长技能
function XUiInfestorExploreTeamEdit:OnClickTabCaptainCallBack(tabIndex)
    local captainPos = tabIndex

    -- 隐藏全部队长标签
    for i = 1, MAX_CHAR_COUNT do
        self["PanelLeader" .. i].gameObject:SetActiveEx(false)
    end

    self:UpdateCaptainSkill(captainPos)
end

function XUiInfestorExploreTeamEdit:UpdateTeamInfo()
    self.LoadModelCount = 0
    local characterIds = self.CharacterIds
    for i = 1, MAX_CHAR_COUNT do
        local characterId = characterIds[i]

        if characterId > 0 then
            self.LoadModelCount = self.LoadModelCount + 1
        end

        self["Timer" .. i] = XScheduleManager.ScheduleOnce(function()
            if XTool.UObjIsNil(self.Transform) or not self.GameObject.activeSelf then
                return
            end

            if characterId > 0 then
                self:UpdateRoleModel(characterId, self.RoleModelPanel[i], i)
                self["ImgAdd" .. i].gameObject:SetActiveEx(false)
                self:UpdateRoleStanmina(characterId, i)
            else
                self.RoleModelPanel[i]:HideRoleModel()
                self["PanelStaminaBar" .. i].gameObject:SetActiveEx(false)
                self["ImgAdd" .. i].gameObject:SetActiveEx(true)
            end
        end, i * LOAD_TIME)
    end
    self.BtnEnterFight.gameObject:SetActiveEx(false)

    self:UpdateCharacterInfo()
    self:UpdateCaptainSkill(self.CaptainPos)
    self:RefreshCharacterTypeTips()
end

--更新模型
function XUiInfestorExploreTeamEdit:UpdateRoleModel(characterId, roleModelPanel, pos)
    roleModelPanel:ShowRoleModel() -- 先Active 再加载模型以及播放动画
    local callback = function(model)
        self.LoadModelCount = self.LoadModelCount - 1
        if self.LoadModelCount <= 0 then
            self.BtnEnterFight.gameObject:SetActiveEx(true)
        end
    end
    roleModelPanel:UpdateCharacterModel(characterId, nil, nil, nil, callback)
end

function XUiInfestorExploreTeamEdit:UpdateRoleStanmina(characterId, index)
    local hpPercent = XDataCenter.FubenInfestorExploreManager.GetCharacterHpPrecent(characterId)
    self["TxtMyStamina" .. index].text = CSXTextManagerGetText("InfestorExploreCharacterHpPercent", hpPercent)
    self["ImgStaminaExpFill" .. index].fillAmount = hpPercent * 0.01
    self["PanelStaminaBar" .. index].gameObject:SetActiveEx(true)
end

function XUiInfestorExploreTeamEdit:UpdateCaptainSkill(captainPos)
    if not captainPos then return end
    self.CaptainPos = captainPos

    -- 开启技能面板、队长头像、技能描述
    self.PanelSkill.gameObject:SetActiveEx(true)
    self.PanelRole.gameObject:SetActiveEx(true)
    self.TxtSkillDesc.gameObject:SetActiveEx(true)

    local teamMemberNum = self:GetCurTeamMemberNum()
    local captainId = self.CharacterIds[self.CaptainPos]

    -- 队长位没有角色
    if captainId <= 0 then
        if teamMemberNum <= 0 then
            -- 队伍内没有角色，隐藏技能面板
            self.PanelSkill.gameObject:SetActiveEx(false)
        else
            -- 队伍内还有其他角色，隐藏队长头像与技能描述
            self.PanelRole.gameObject:SetActiveEx(false)
            self.TxtSkillDesc.gameObject:SetActiveEx(false)

            -- 队长技能名称更改为未选择队长
            self.TxtSkillName.text = CS.XTextManager.GetText("TeamDoNotChooseCaptain")
        end
        return
    end

    local captianSkillInfo = XDataCenter.CharacterManager.GetCaptainSkillInfo(captainId)
    self.RImgCapIcon:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(captainId))
    self:SetUiSprite(self.ImgSkillIcon, captianSkillInfo.Icon)
    self.TxtSkillName.text = captianSkillInfo.Name
    self.TxtSkillDesc.text = captianSkillInfo.Level > 0 and captianSkillInfo.Intro or CS.XTextManager.GetText("CaptainSkillLock")
end

--更新战斗信息
function XUiInfestorExploreTeamEdit:UpdateCharacterInfo()
    if self.IsShowCharacterInfo then
        self.BtnShowInfoToggle:SetButtonState(XUiButtonState.Select)
        for i = 1, #self.CharacterIds do
            local character = XDataCenter.CharacterManager.GetCharacter(self.CharacterIds[i])
            if character == nil then
                self["CharacterInfo" .. i].gameObject:SetActiveEx(false)
            else
                self["CharacterInfo" .. i].gameObject:SetActiveEx(true)
                self["TxtFight" .. i].text = math.floor(character.Ability)
                self["RImgType" .. i]:SetRawImage(XCharacterConfigs.GetNpcTypeIcon(character.Type))
            end
        end
    else
        self.BtnShowInfoToggle:SetButtonState(XUiButtonState.Normal)
        for i = 1, MAX_CHAR_COUNT do
            self["CharacterInfo" .. i].gameObject:SetActiveEx(false)
        end
    end
end

function XUiInfestorExploreTeamEdit:RemoveTimer()
    for i = 1, MAX_CHAR_COUNT do
        if self["Timer" .. i] then
            XScheduleManager.UnSchedule(self["Timer" .. i])
            self["Timer" .. i] = nil
        end
    end
end

function XUiInfestorExploreTeamEdit:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnEnterFight, self.OnBtnEnterFightClick)
    self.BtnShowInfoToggle.CallBack = function(val) self:OnBtnShowInfoToggle(val) end
    self.BtnGo.CallBack = function() self:OnPanelBtnLeaderClick() end
    for i = 1, MAX_CHAR_COUNT do
        local btnChar = self["BtnChar" .. i]
        btnChar.CallBack = function() self:OnBtnCharClick(i) end

        local btnLongClick = btnChar:GetComponent("XUiPointer")
        local longClickCallback = function(_, time) self:OnBtnUnLockLongClick(i, time) end
        XUiButtonLongClick.New(btnLongClick, 10, self, nil, longClickCallback, self.OnBtnUnLockLongUp, false)
    end
end

function XUiInfestorExploreTeamEdit:OnPanelBtnLeaderClick()
    XLuaUiManager.Open("UiNewRoomSingleTip", self, self.CharacterIds, self.CaptainPos, function(index)
        self:OnClickTabCaptainCallBack(index)
    end)
end

function XUiInfestorExploreTeamEdit:OnBtnShowInfoToggle(val)
    self.IsShowCharacterInfo = val ~= 0 and true or false
    self:UpdateCharacterInfo()
end

function XUiInfestorExploreTeamEdit:OnBtnUnLockLongUp()
    self.ImgRoleRepace.gameObject:SetActiveEx(false)
    self.IsUp = not self.IsUp
    LONG_CLICK_TIME = 0

    if self.ChangeCharIndex > 0 then
        local targetX = math.floor(self:GetPisont().x + self.RectTransform.rect.width / 2)
        local targetIndex = 0
        if targetX <= self.RectTransform.rect.width / 3 then
            targetIndex = CHAR_POS2
        elseif targetX > self.RectTransform.rect.width / 3 and targetX <= self.RectTransform.rect.width / 3 * 2 then
            targetIndex = CHAR_POS1
        else
            targetIndex = CHAR_POS3
        end

        if targetIndex > 0 and targetIndex ~= self.ChangeCharIndex then
            local teamData = XTool.Clone(self.CharacterIds)
            local targetId = teamData[targetIndex]
            teamData[targetIndex] = teamData[self.ChangeCharIndex]
            teamData[self.ChangeCharIndex] = targetId
            self:UpdateTeam(teamData)
        end
        self.ChangeCharIndex = 0
    end
end

function XUiInfestorExploreTeamEdit:OnBtnUnLockLongClick(index, time)
    if self.CharacterIds[index] <= 0 then
        self.IsUp = true
        return
    end

    LONG_CLICK_TIME = LONG_CLICK_TIME + time / 1000
    if self.IsUp then
        self.IsUp = false
        return
    end
    if LONG_CLICK_TIME > TIMER and not self.IsUp then
        self.IsUp = false
        self.ImgRoleRepace.gameObject:SetActiveEx(true)
        self.ImgRoleRepace.gameObject.transform.localPosition = self:GetPisont()
    end
    if self.ChangeCharIndex <= 0 then
        self.ChangeCharIndex = index
    end
end

function XUiInfestorExploreTeamEdit:GetPisont()
    local screenPoint
    if IsWindows then
        screenPoint = CS.UnityEngine.Vector2(CS.UnityEngine.Input.mousePosition.x, CS.UnityEngine.Input.mousePosition.y)
    else
        screenPoint = CS.UnityEngine.Input.GetTouch(0).position
    end

    -- 设置拖拽
    local hasValue, v2 = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.RectTransform, screenPoint, CS.XUiManager.Instance.UiCamera)
    if hasValue then
        return CS.UnityEngine.Vector3(v2.x, v2.y, 0)
    else
        return CS.UnityEngine.Vector3.zero
    end
end

function XUiInfestorExploreTeamEdit:OnBtnBackClick()
    if self:IsCaptainEmpty() or self:IsFirstFightEmpty() then return end
    self:Close()
end

function XUiInfestorExploreTeamEdit:OnBtnMainUiClick()
    if self:IsCaptainEmpty() or self:IsFirstFightEmpty() then return end
    XLuaUiManager.RunMain()
end

function XUiInfestorExploreTeamEdit:OnBtnCharClick(index)
    if self.ForbitReplaceCharacter then
        XUiManager.TipText("InfestorExploreTeamForbitReplaceCharacter")
        return
    end

    local teamData = XTool.Clone(self.CharacterIds)
    XLuaUiManager.Open("UiRoomCharacter", teamData, index, function(resTeam)
        self:UpdateTeam(resTeam)
    end, XDataCenter.FubenManager.StageType.InfestorExplore, self.CharacterLimitType, { LimitBuffId = self.LimitBuffId })
end

-- 更新队伍
function XUiInfestorExploreTeamEdit:UpdateTeam(teamData)
    self.CharacterIds = XTool.Clone(teamData)
    self:UpdateTeamInfo()
end

function XUiInfestorExploreTeamEdit:GetCurTeamMemberNum()
    local count = 0
    for _, id in pairs(self.CharacterIds) do
        if id > 0 then
            count = count + 1
        end
    end
    return count
end

function XUiInfestorExploreTeamEdit:OnBtnEnterFightClick()
    if self:IsCaptainEmpty() or self:IsFirstFightEmpty() then return end

    self:Close()
    if self.EnterCallBack then self.EnterCallBack() end
end

function XUiInfestorExploreTeamEdit:PlayTips(key, isOn)
    local msg = CSXTextManagerGetText(key)
    self.TxtTips1.text = isOn and msg or ""
    self.TxtTips2.text = isOn and "" or msg
    self.PanelTip.gameObject:SetActiveEx(true)

    self:PlayAnimation("PanelTipEnable", handler(self, function()
        self.PanelTip.gameObject:SetActiveEx(false)
    end))
end

function XUiInfestorExploreTeamEdit:IsCaptainEmpty()
    local captainId = self.CharacterIds[self.CaptainPos]
    if captainId <= 0 then
        XUiManager.TipText("TeamManagerCheckCaptainNil")
        return true
    end
    return false
end

function XUiInfestorExploreTeamEdit:IsFirstFightEmpty()
    local firstFightId = self.CharacterIds[self.FirstFightPos]
    if firstFightId <= 0 then
        XUiManager.TipText("TeamManagerCheckFirstFightNil")
        return true
    end
    return false
end