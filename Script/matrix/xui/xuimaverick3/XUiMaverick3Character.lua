---@class XUiMaverick3Character : XLuaUi 孤胆枪手出战准备
---@field _Control XMaverick3Control
local XUiMaverick3Character = XLuaUiManager.Register(XLuaUi, "UiMaverick3Character")

function XUiMaverick3Character:OnAwake()
    self.BtnFight.CallBack = handler(self, self.OnBtnFightClick)
    self.BtnSelect.CallBack = handler(self, self.OnBtnSelectClick)
    self.BtnBubbleClose.CallBack = handler(self, self.CloseBubble)
end

function XUiMaverick3Character:OnStart(stageId)
    self._StageId = stageId
    self._CurFightIndex = self._Control:GetFightIndex()
    self._ShowRobotId = self._Control:GetShowRobotId()

    local teachChapter = self._Control:GetTeachChapter()
    self._IsTeachStage = XTool.IsNumberValid(stageId) and self._Control:GetStageById(stageId).ChapterId == teachChapter.ChapterId
    self._TeachStageRobotId = tonumber(self._Control:GetClientConfig("TeachStageRobotId"))
    self._IsQieHuanPlay = not self._StageId -- 从主界面进来

    self:InitModel()
    self:InitView()
    self:CloseBubble()
end

function XUiMaverick3Character:OnEnable()
    if self._IsQieHuanPlay then
        self._IsQieHuanPlay = false
        self:PlayAnimationWithMask("QieHuanEnable")
    else
        self:PlayAnimationWithMask("Enable")
    end
end

function XUiMaverick3Character:OnDisable()

end

function XUiMaverick3Character:OnDestroy()
    self:RemoveTimer()
    if self._VideoPlayer then
        self._VideoPlayer:Stop()
    end
    self:SaveData()
end

function XUiMaverick3Character:Close()
    self:PlayAnimationWithMask("QieHuanDisable", function()
        self.Super.Close(self)
    end)
end

function XUiMaverick3Character:InitModel()
    self._PanelRoleModel = self.UiModelGo.transform:FindTransform("PanelRoleModel")
    ---@type XUiPanelRoleModel
    self._RoleModelPanel = require("XUi/XUiCharacter/XUiPanelRoleModel").New(self._PanelRoleModel, self.Name, nil, true, false)

    if not XTool.IsNumberValid(self._StageId) then
        -- 主界面进用长镜头
        local camRoleEnable = self.UiModelGo.transform:FindTransform("CamRoleEnable")
        if not XTool.UObjIsNil(camRoleEnable) then
            camRoleEnable:PlayTimelineAnimation()
        end
    else
        -- 关卡进用短镜头
        local camRoleEnable = self.UiModelGo.transform:FindTransform("CharacterEnable")
        if not XTool.UObjIsNil(camRoleEnable) then
            camRoleEnable:PlayTimelineAnimation()
        end
    end
end

function XUiMaverick3Character:InitView()
    local ItemIds = { XEnumConst.Maverick3.Currency.Cultivate }
    XUiHelper.NewPanelActivityAssetSafe(ItemIds, self.PanelSpecialTool, self)
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)

    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end, nil, 0)

    self._BubbleSkillDetail = {}
    XUiHelper.InitUiClass(self._BubbleSkillDetail, self.BubbleSkillDetail)
    ---@type XVideoPlayerUGUI
    self._VideoPlayer = self._BubbleSkillDetail.VideoPlayer

    self._BubbleTalentDetail = {}
    XUiHelper.InitUiClass(self._BubbleTalentDetail, self.BubbleTalentDetail)

    ---@type XUiGridMaverick3Ornaments
    self._GridOrnaments = require("XUi/XUiMaverick3/Grid/XUiGridMaverick3Ornaments").New(self.GridOrnaments, self)
    ---@type XUiGridMaverick3Slay
    self._GridSlay = require("XUi/XUiMaverick3/Grid/XUiGridMaverick3Slay").New(self.GridSlay, self)
    -- 教学关不能切换装备
    if not self._IsTeachStage then
        self._GridOrnaments:AddClick(function()
            local id = self._Control:GetSelectOrnamentsId(self._CurSelectCharIndex)
            XLuaUiManager.OpenWithCloseCallback("UiMaverick3Handbook", handler(self, self.UpdatePrepareBattle), self._CurSelectCharIndex, id)
        end)
        self._GridSlay:AddClick(function()
            local id = self._Control:GetSelectSlayId(self._CurSelectCharIndex)
            XLuaUiManager.OpenWithCloseCallback("UiMaverick3Handbook", handler(self, self.UpdatePrepareBattle), self._CurSelectCharIndex, id)
        end)
    end

    self.BtnFight.gameObject:SetActiveEx(XTool.IsNumberValid(self._StageId))
    self:InitCharacter()
end

function XUiMaverick3Character:InitCharacter()
    ---@type XUiComponent.XUiButton[]
    self._CharacterBtns = {}
    self._CharacterCondStrMap = {}
    for i = 1, 3 do
        ---@type XUiComponent.XUiButton
        local btn = self["GridCharacter" .. i]
        local cfg = self._Control:GetRobotById(i)
        local isUnlock, condStr = true, nil
        if XTool.IsNumberValid(cfg.Condition) then
            isUnlock, condStr = XConditionManager.CheckCondition(cfg.Condition)
        end
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, btn)
        uiObject.GridCharacter:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(XRobotManager.GetCharacterId(cfg.RobotId), true))
        uiObject.ImgInTeam.gameObject:SetActiveEx(self._CurFightIndex == i)
        uiObject.ImgLock.gameObject:SetActiveEx(not isUnlock)
        uiObject.GameObject:SetActiveEx(not self._IsTeachStage or i == self._TeachStageRobotId)
        self._CharacterBtns[i] = uiObject.GridCharacter
        self._CharacterCondStrMap[i] = not isUnlock and condStr
    end
    self.CharacterGroup:Init(self._CharacterBtns, function(index)
        self:OnCharacterSelect(index)
    end)
    self.CharacterGroup:SelectIndex(self._IsTeachStage and self._TeachStageRobotId or self._CurFightIndex)
end

function XUiMaverick3Character:OnCharacterSelect(index)
    self:SaveDataToLocal()

    self._CurSelectCharIndex = index
    local robotCfg = self._Control:GetRobotById(index)

    local condStr = self._CharacterCondStrMap[index]
    if not condStr and not self._IsTeachStage then
        self._CurFightIndex = index
    end
    self.BtnSelect.gameObject:SetActiveEx(not XTool.IsNumberValid(self._StageId) and not condStr and not self._IsTeachStage)
    self.BtnSelect:SetButtonState(self._ShowRobotId ~= index and XUiButtonState.Normal or XUiButtonState.Disable)
    self.BtnFight:SetButtonState(condStr and XUiButtonState.Disable or XUiButtonState.Normal)
    self.PanelCondition.gameObject:SetActiveEx(condStr)
    self.TxtCondition.text = condStr or ""

    self._CurSkillIndex = self._Control:GetSelectSkillIndex(index)
    self._CurTalentIndex = self._Control:GetSelectTalentIndex(index)
    self:UpdateCharacterDetail(index)
    
    local characterId = XRobotManager.GetCharacterId(robotCfg.RobotId)
    XDataCenter.DisplayManager.UpdateRoleModel(self._RoleModelPanel, characterId, nil, robotCfg.FashionId)

    for i, btn in ipairs(self._CharacterBtns) do
        btn:SetSpriteVisible(self._CurFightIndex == i)
    end
end

function XUiMaverick3Character:SaveDataToLocal()
    if not self._CurSelectCharIndex then
        return
    end
    if self._CurSkillIndex ~= self._CurSelectSkillIndex then
        self._Control:SaveSelectSkillIndex(self._CurSelectCharIndex, self._CurSelectSkillIndex)
    end
    if self._CurTalentIndex ~= self._CurSelectTalentIndex then
        self._Control:SaveSelectTalentIndex(self._CurSelectCharIndex, self._CurSelectTalentIndex)
    end
end

function XUiMaverick3Character:UpdateCharacterDetail(index)
    local cfg = self._Control:GetRobotById(index)
    local btns = {}
    local skillDatas = {}
    local talentDatas = {}
    local uiObject
    self.TxtName.text = XMVCA.XCharacter:GetCharacterName(XRobotManager.GetCharacterId(cfg.RobotId))
    -- 技能
    XUiHelper.RefreshCustomizedList(self.GridSkill.parent, self.GridSkill, #cfg.SkillIds, function(i, go)
        local skillCfg = self._Control:GetSkillById(cfg.SkillIds[i])
        uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.GridSkill:SetRawImage(skillCfg.Icon)
        table.insert(skillDatas, skillCfg)
        table.insert(btns, uiObject.GridSkill)
    end)
    self._CurSelectSkillIndex = nil
    self.SkillGroup:Init(btns, function(i)
        if self._CurSelectSkillIndex then
            self:OpenSkillDetailBubble(skillDatas[i])
        end
        self._CurSelectSkillIndex = i
    end)
    self.SkillGroup:SelectIndex(self._CurSkillIndex)
    -- 天赋
    btns = {}
    ---@type XUiComponent.XUiButton[]
    self._TalentBtnMap = {}
    self._TalentSelectMap = {}
    ---@type UnityEngine.Transform[]
    self._TalentAnimMap = {}
    XUiHelper.RefreshCustomizedList(self.GridTalent.parent, self.GridTalent, #cfg.Talentds, function(i, go)
        local talentCfg = self._Control:GetTalentById(cfg.Talentds[i])
        local isUnlock = self._Control:IsTalentUnlock(talentCfg.Id)
        uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.GridTalent:SetRawImage(talentCfg.Icon)
        uiObject.GridTalent:SetButtonState(isUnlock and XUiButtonState.Normal or XUiButtonState.Disable)
        table.insert(talentDatas, talentCfg)
        table.insert(btns, uiObject.GridTalent)
        self._TalentBtnMap[talentCfg.Id] = uiObject.GridTalent
        self._TalentSelectMap[i] = uiObject.ImgSelect
        self._TalentAnimMap[talentCfg.Id] = uiObject.Transform:FindTransform("GridTalentUnlock")
    end)
    self._CurSelectTalentIndex = nil
    self.TalentGroup:Init(btns, function(i)
        if self._CurSelectTalentIndex then
            self:OpenTalentDetailBubble(talentDatas[i])
        end
        self._CurSelectTalentIndex = i
        for idx, img in pairs(self._TalentSelectMap) do
            img.gameObject:SetActiveEx(idx == i)
        end
    end)
    self.TalentGroup:SelectIndex(self._CurTalentIndex)
    -- 挂饰&必杀
    self:UpdatePrepareBattle()
    -- 弹框
    if self.BubbleSkillDetail.gameObject.activeSelf then
        self.SkillGroup:SelectIndex(self._CurSelectSkillIndex)
    end
    if self.BubbleTalentDetail.gameObject.activeSelf then
        self.TalentGroup:SelectIndex(self._CurSelectTalentIndex)
    end
end

function XUiMaverick3Character:UpdateTalentUnlock()
    for id, btn in pairs(self._TalentBtnMap) do
        local isUnlock = self._Control:IsTalentUnlock(id)
        btn:SetButtonState(isUnlock and XUiButtonState.Normal or XUiButtonState.Disable)
    end
end

function XUiMaverick3Character:UpdatePrepareBattle()
    local id = self._Control:GetSelectOrnamentsId(self._CurSelectCharIndex)
    self._GridOrnaments:SetData(id)
    id = self._Control:GetSelectSlayId(self._CurSelectCharIndex)
    self._GridSlay:SetData(id)
end

---@param cfg XTableMaverick3Skill
function XUiMaverick3Character:OpenSkillDetailBubble(cfg)
    self.BtnBubbleClose.gameObject:SetActiveEx(true)
    self.BubbleSkillDetail.gameObject:SetActiveEx(true)
    self._BubbleSkillDetail.RImgIcon:SetRawImage(cfg.Icon)
    self._BubbleSkillDetail.TxtTitle.text = cfg.Name
    self._BubbleSkillDetail.TxtDetail.text = cfg.Desc

    self:RemoveTimer()
    self:CloseTalentDetailBubble()

    if self._VideoPlayer.VideoPlayerInst.player.status == CS.CriWare.CriMana.Player.Status.Pause then
        self._VideoPlayer:Resume()
    end
    if self._VideoPlayer:IsPlaying() then
        self._VideoPlayer:Stop()
        self._Timer = XScheduleManager.ScheduleForever(function()
            local status = self._VideoPlayer.VideoPlayerInst.player.status
            if status == CS.CriWare.CriMana.Player.Status.Stop or status == CS.CriWare.CriMana.Player.Status.PlayEnd then
                self:RemoveTimer()
                self:PlayVideoSkill(cfg.Video)
            end
        end, 1)
    else
        self:PlayVideoSkill(cfg.Video)
    end
end

---@param cfg XTableMaverick3Talent
function XUiMaverick3Character:OpenTalentDetailBubble(cfg)
    self:CloseSkillDetailBubble()
    self.BtnBubbleClose.gameObject:SetActiveEx(true)
    self.BubbleTalentDetail.gameObject:SetActiveEx(true)
    self._BubbleTalentDetail.TxtTitle.text = cfg.Name
    self._BubbleTalentDetail.TxtDetail.text = cfg.Desc
    self._BubbleTalentDetail.RImgIcon:SetRawImage(cfg.Icon)
    -- 未解锁
    if XTool.IsNumberValid(cfg.Condition) then
        local isUnlock, desc = XConditionManager.CheckCondition(cfg.Condition)
        if not isUnlock then
            self._BubbleTalentDetail.PanelLock.gameObject:SetActiveEx(true)
            self._BubbleTalentDetail.BtnUnlock.gameObject:SetActiveEx(false)
            self._BubbleTalentDetail.TxtLock.text = desc
            return
        end
    end
    -- 未拥有
    if not self._Control:IsTalentUnlock(cfg.Id) then
        self._BubbleTalentDetail.PanelLock.gameObject:SetActiveEx(false)
        self._BubbleTalentDetail.BtnUnlock.gameObject:SetActiveEx(true)
        local itemCount = XDataCenter.ItemManager.GetCount(XEnumConst.Maverick3.Currency.Cultivate)
        local isCanBuy = itemCount >= cfg.NeedItemCount
        self._BubbleTalentDetail.BtnUnlock:SetButtonState(isCanBuy and XUiButtonState.Normal or XUiButtonState.Disable)
        self._BubbleTalentDetail.BtnConsume:SetButtonState(isCanBuy and XUiButtonState.Normal or XUiButtonState.Disable)
        self._BubbleTalentDetail.BtnConsume:SetNameByGroup(0, cfg.NeedItemCount)
        self._BubbleTalentDetail.BtnConsume:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XEnumConst.Maverick3.Currency.Cultivate))
        self._BubbleTalentDetail.BtnUnlock.CallBack = function()
            if not isCanBuy then
                XUiManager.TipError(XUiHelper.GetText("Maverick3UnlockTalentTip"))
                return
            end
            self._Control:RequestMaverick3UnlockTalent(cfg.Id, function()
                local anim = self._TalentAnimMap[cfg.Id]
                if XTool.UObjIsNil(anim) then
                    self:UpdateTalentUnlock()
                    self:OpenTalentDetailBubble(cfg)
                else
                    anim:PlayTimelineAnimation(function()
                        self:UpdateTalentUnlock()
                        self:OpenTalentDetailBubble(cfg)
                    end)
                end
            end)
        end
        return
    end
    -- 已拥有
    self._BubbleTalentDetail.PanelLock.gameObject:SetActiveEx(false)
    self._BubbleTalentDetail.BtnUnlock.gameObject:SetActiveEx(false)
end

function XUiMaverick3Character:CloseBubble()
    self.BtnBubbleClose.gameObject:SetActiveEx(false)
    self:CloseSkillDetailBubble()
    self:CloseTalentDetailBubble()
end

function XUiMaverick3Character:CloseSkillDetailBubble()
    self.BubbleSkillDetail.gameObject:SetActiveEx(false)
    if self._VideoPlayer:IsPlaying() then
        self._VideoPlayer:Pause()
    end
    self:RemoveTimer()
end

function XUiMaverick3Character:CloseTalentDetailBubble()
    self.BubbleTalentDetail.gameObject:SetActiveEx(false)
end

function XUiMaverick3Character:PlayVideoSkill(video)
    self._VideoPlayer:SetVideoFromRelateUrl(video)
    self._VideoPlayer:PrepareThenPlay()
end

function XUiMaverick3Character:RemoveTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiMaverick3Character:OnBtnFightClick()
    if self._CharacterCondStrMap[self._CurSelectCharIndex] then
        XUiManager.TipError(XUiHelper.GetText("Maverick3RobotLock"))
        return
    end
    self:SaveData()
    XMVCA.XFuben:EnterFightByStageId(self._StageId, nil, false, 1, nil)
    XLuaUiManager.Remove("UiMaverick3Character")
end

function XUiMaverick3Character:OnBtnSelectClick()
    if self._ShowRobotId ~= self._CurSelectCharIndex then
        XUiManager.TipError(XUiHelper.GetText("Maverick3RoleSwitchSuccess"))
    end
    self._ShowRobotId = self._CurSelectCharIndex
    self.BtnSelect:SetButtonState(XUiButtonState.Disable)
end

function XUiMaverick3Character:SaveData()
    if not self._IsTeachStage then
        self._Control:SaveFightIndex(self._CurFightIndex)
        self._Control:SaveShowRobotId(self._ShowRobotId)
    end
    self._Control:SaveSelectSkillIndex(self._CurSelectCharIndex, self._CurSelectSkillIndex)
    self._Control:SaveSelectTalentIndex(self._CurSelectCharIndex, self._CurSelectTalentIndex)
end

return XUiMaverick3Character