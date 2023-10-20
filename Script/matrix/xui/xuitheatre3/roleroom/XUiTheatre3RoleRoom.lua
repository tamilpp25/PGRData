local XPanelTheatre3Energy = require("XUi/XUiTheatre3/Adventure/Main/XPanelTheatre3Energy")

---@class XUiTheatre3RoleRoom : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3RoleRoom = XLuaUiManager.Register(XLuaUi, "UiTheatre3RoleRoom")

local Position = { First = 1, Second = 2, Third = 3 }

function XUiTheatre3RoleRoom:OnAwake()
    self.BtnTeamInstall.CallBack = handler(self, self.OnTeamInstall)
    self.BtnBattle.CallBack = handler(self, self.OnBattle)
    self.BtnBack.CallBack = handler(self, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnAdd1, function()
        self:OnClickRole(Position.First)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnAdd2, function()
        self:OnClickRole(Position.Second)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnAdd3, function()
        self:OnClickRole(Position.Third)
    end)
end

function XUiTheatre3RoleRoom:OnStart(isBattle,isStartAdventure)
    self._IsBattle = isBattle
    self._IsStartAdventure = isStartAdventure
    -- 没有动画先拿来顶一下，阻碍按钮点击
    ---@type UnityEngine.UI.GraphicRaycaster
    self._GraphicRaycaster = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane", "GraphicRaycaster")

    self:InitCompnent()
    self._IsDirty = false
end

function XUiTheatre3RoleRoom:OnEnable()
    if self._GraphicRaycaster then
        self._GraphicRaycaster.enabled = false
    end
    self._EnableTimer = XScheduleManager.ScheduleOnce(function()
        if not XTool.UObjIsNil(self._GraphicRaycaster) then
            self._GraphicRaycaster.enabled = true
        end
    end, 400)
    self:Update()
end

function XUiTheatre3RoleRoom:OnDisable()
    if self._EnableTimer then
        XScheduleManager.UnSchedule(self._EnableTimer)
    end
    self._IsDirty = true
end

function XUiTheatre3RoleRoom:InitCompnent()
    ---@type XPanelTheatre3Energy
    self._PanelEnergy = XPanelTheatre3Energy.New(self.Energy, self)
end

function XUiTheatre3RoleRoom:OnGetEvents()
    return { XEventId.EVENT_THEATRE3_SAVE_TEAM }
end

function XUiTheatre3RoleRoom:OnNotify(evt)
    self:Update()
end

function XUiTheatre3RoleRoom:Update()
    self:UpdateRole()
    self:UpdateEnergy()
    self:UpdateButton()
end

function XUiTheatre3RoleRoom:UpdateEnergy()
    self._PanelEnergy:Refresh()
end

function XUiTheatre3RoleRoom:UpdateRole()
    self:SetRole(self.BtnChar1, Position.First)
    self:SetRole(self.BtnChar2, Position.Second)
    self:SetRole(self.BtnChar3, Position.Third)
end

function XUiTheatre3RoleRoom:UpdateButton()
    local isTeamHasChar = false
    for i = 1, 3 do
        if self._Control:CheckIsHaveCharacter(i) then
            isTeamHasChar = true
            break
        end
    end
    self.BtnTeamInstall.gameObject:SetActiveEx(isTeamHasChar)

    if self._IsStartAdventure then
        self.BtnBattle:SetNameByGroup(0, XUiHelper.GetText("Theatre3AdventureBtnStartName"))
    elseif self._IsBattle then
        self.BtnBattle:SetNameByGroup(0, XUiHelper.GetText("Theatre3AdventureBtnBattleName"))
    else
        self.BtnBattle:SetNameByGroup(0, XUiHelper.GetText("ConfirmText"))
    end
end

function XUiTheatre3RoleRoom:SetRole(go, position)
    local uiObject = {}
    XTool.InitUiObjectByUi(uiObject, go)
    local characterId = self._Control:GetSlotCharacter(position)
    local colorIdx = self._Control:GetSlotOrder(position)
    uiObject.TxtIndex.text = position
    uiObject.PanelLeader.gameObject:SetActiveEx(self._Control:CheckIsCaptainPos(colorIdx))
    uiObject.PanelFirstRole.gameObject:SetActiveEx(self._Control:CheckIsFirstFightPos(colorIdx))
    uiObject.ImgColor1.gameObject:SetActiveEx(colorIdx == Position.First)
    uiObject.ImgColor2.gameObject:SetActiveEx(colorIdx == Position.Second)
    uiObject.ImgColor3.gameObject:SetActiveEx(colorIdx == Position.Third)
    uiObject.ImgNumber:SetSprite(self._Control:GetClientConfig("Theatre3CharacterIndexIcon", position))
    if characterId ~= 0 then
        uiObject.ImgDraw.gameObject:SetActiveEx(true)
        ---@type XCharacterAgency
        local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
        local characterIcon = characterAgency:GetCharHalfBodyImage(characterId)
        uiObject.ImgDraw:SetRawImage(characterIcon)
    else
        uiObject.ImgDraw.gameObject:SetActiveEx(false)
    end
    if uiObject.ImgNormal then
        uiObject.ImgNormal.gameObject:SetActiveEx(not XTool.IsNumberValid(characterId))
    end
    if uiObject.ImgNormal1 then
        uiObject.ImgNormal1.gameObject:SetActiveEx(not XTool.IsNumberValid(characterId))
    end
end

function XUiTheatre3RoleRoom:OnTeamInstall()
    XLuaUiManager.Open("UiTheatre3TeamInstall")
end

function XUiTheatre3RoleRoom:OnBattle()
    if not self._IsStartAdventure and not self._IsBattle then
        if self._IsDirty then
            self._Control:RequestSetTeam(function()
                self:Close()
            end)
        else
            self:Close()
        end
        return
    end
    
    if not self._Control:CheckCaptainHasEntityId() then
        XUiManager.TipText("TeamManagerCheckCaptainNil")
        return
    end
    if not self._Control:CheckFirstFightHasEntityId() then
        XUiManager.TipText("TeamManagerCheckFirstFightNil")
        return
    end
    if self._IsStartAdventure then  -- 冒险开始时出击为编队
        self._Control:RequestSetTeam(function()
            self._Control:RequestAdventureEndRecruit(function()
                self._Control:CheckAndOpenAdventureNextStep(true)
            end)
        end)
    else                            -- 冒险中为进入战斗
        ---@type XFubenAgency
        local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
        local nodeSlot = self._Control:GetAdventureLastNodeSlot()
        local fightTemplateId = nodeSlot:GetFightTemplateId()
        if not XTool.IsNumberValid(fightTemplateId) then
            XLog.Error("当前节点非战斗类型："..nodeSlot)
            return
        end
        local stageId = self._Control:GetFightStageTemplateStageId(fightTemplateId)
        self._Control:RequestSetTeam(function()
            fubenAgency:EnterFightByStageId(stageId, nil, false, 1, nil, function()
                ---@type XTheatre3Agency
                local theatre3Agency = XMVCA:GetAgency(ModuleId.XTheatre3)
                theatre3Agency:RemoveStepView()
            end)
        end)
    end
end

function XUiTheatre3RoleRoom:OnClickRole(pos)
    local cur, total = self._Control:GetCurEnergy()
    if total - cur <= 0 and not self._Control:CheckIsHaveCharacter(pos) then
        -- 【有空槽】并且【能量=0】
        XUiManager.TipMsg(XUiHelper.GetText("Theatre3EnergyNoEnoughTip"))
        return
    end
    XLuaUiManager.Open("UiTheatre3RoleRoomDetail", pos)
end

return XUiTheatre3RoleRoom