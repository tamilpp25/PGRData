XUiGridTeamRole = XClass(nil, "XUiGridTeamRole")

function XUiGridTeamRole:Ctor(rootUi, ui, stageId)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.StageId = stageId
    --辅助机控件
    self.PanelPartner = {}
    XTool.InitUiObject(self)
    XTool.InitUiObjectByUi(self.PanelPartner, self.CharacterPets)
    self.CharacterPets.gameObject:SetActiveEx(true)
    self:AddListener()
end

function XUiGridTeamRole:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridTeamRole:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridTeamRole:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridTeamRole:AddListener()
    self:RegisterClickEvent(self.BtnPlus, self.OnBtnClickClick)
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick)

    self.PanelPartner.BtnClick.CallBack = function() 
        self:OnClickBtnPetClick()
    end
end
-- auto
function XUiGridTeamRole:SetNull()
    self.ImgLeftnull.color = XDataCenter.TeamManager.GetTeamMemberColor(self.CurPos)
    self.ImgRightnull.color = XDataCenter.TeamManager.GetTeamMemberColor(self.CurPos)

    self.PanelHave.gameObject:SetActive(false)
    self.PanelNull.gameObject:SetActive(true)
    --self.CharacterPets.gameObject:SetActiveEx(false)
    self.PanelPartner.RImgType.gameObject:SetActiveEx(false)
end

function XUiGridTeamRole:SetHave(chrId)
    self.PanelHave.gameObject:SetActive(true)
    self.PanelNull.gameObject:SetActive(false)
    local character = XDataCenter.CharacterManager.GetCharacter(chrId)
    if not character then return end

    self.ImgLeftSkill.color = XDataCenter.TeamManager.GetTeamMemberColor(self.CurPos)
    self.ImgRightSkill.color = XDataCenter.TeamManager.GetTeamMemberColor(self.CurPos)
    if self.PartnerPrefab then
        local partnerId = self.PartnerPrefab:GetPartnerIdByPos(self.CurPos)
        local partner = XDataCenter.PartnerManager.GetPartnerEntityById(partnerId)
        if partner then
            self.PanelPartner.RImgType.gameObject:SetActiveEx(true)
            self.PanelPartner.RImgType:SetRawImage(partner:GetIcon())
            self.PanelPartner.ImgPlus.gameObject:SetActiveEx(false)
        else
            self.PanelPartner.RImgType.gameObject:SetActiveEx(false)
            self.PanelPartner.ImgPlus.gameObject:SetActiveEx(true)
        end
    end
    
    self.ImgIcon:SetSprite(XDataCenter.CharacterManager.GetCharBigHeadIcon(character.Id))
    self.ImgQuality:SetSprite(XCharacterConfigs.GetCharacterQualityIcon(character.Quality))
end

function XUiGridTeamRole:Refresh(curPos, teamData, characterLimitType, limitBuffId)
    self.CharacterLimitType = characterLimitType
    self.LimitBuffId = limitBuffId
    self.CurPos = curPos
    self.TeamData = teamData
    --@class XPartnerPrefab
    self.PartnerPrefab = XDataCenter.TeamManager.GetPartnerPrefab(teamData.TeamId)
    local chrId = teamData.TeamData[curPos]

    self.IconLeader.gameObject:SetActiveEx(teamData.CaptainPos == self.CurPos)
    self.IconFirstFight.gameObject:SetActiveEx(teamData.FirstFightPos == self.CurPos)

    if chrId > 0 then
        self:SetHave(chrId)
    else
        self:SetNull()
    end
end

function XUiGridTeamRole:OnSelect(teamData)
    local firstCharPos
    local charCount = 0
    
    --在预设队伍数据更新之前
    local tmpChrId = self.TeamData.TeamData[self.CurPos]
    self.TeamData.TeamData = teamData
    for pos, charId in ipairs(self.TeamData.TeamData) do
        if charId > 0 then
            firstCharPos = pos
            charCount = charCount + 1
        end
    end
    --在预设队伍数据更新之后
    local chrId = self.TeamData.TeamData[self.CurPos]
    --当前位置的角色被卸载了
    if XTool.IsNumberValid(tmpChrId) and tmpChrId ~= chrId then
        self.PartnerPrefab:Unload(self.CurPos)
    end
    --检查当前角色是否携带了辅助机，如果携带了，则自动加入到预设系统中
    --if XTool.IsNumberValid(chrId) then
    --    local partnerId = XDataCenter.PartnerManager.GetCarryPartnerIdByCarrierId(chrId)
    --    self.PartnerPrefab:Equip(self.CurPos, partnerId)
    --end

    if charCount == 1 then
        self.TeamData.CaptainPos = firstCharPos
        self.TeamData.FirstFightPos = firstCharPos
    end

    XDataCenter.TeamManager.SetPlayerTeam(self.TeamData, true)
end

--点击辅助机
function XUiGridTeamRole:OnClickBtnPetClick()
    --TeamData不会为空，不做判空处理
    local chrId = self.TeamData.TeamData[self.CurPos]
    if XTool.IsNumberValid(chrId) then
        XDataCenter.PartnerManager.GoPartnerPreset(self.TeamData, self.CurPos)
    else
       XUiManager.TipText("RoomTeamPrefabRoleEmptyTips")
    end
end

function XUiGridTeamRole:OnBtnClickClick()
    if XTool.USENEWBATTLEROOM then
        RunAsyn(function()
            local teamManager = XDataCenter.TeamManager 
            local team = teamManager.GetXTeamWithPrefab(self.TeamData.TeamId) or teamManager.CreateTempTeam({0, 0, 0})
            XLuaUiManager.Open("UiBattleRoomRoleDetail", self.StageId, team, self.CurPos)
            local signalCode = XLuaUiManager.AwaitSignal("UiBattleRoomRoleDetail", "UpdateEntityId", self)
            if signalCode ~= XSignalCode.SUCCESS then return end 
            self:OnSelect(team:GetEntityIds())
        end)
    else
        XLuaUiManager.Open("UiRoomCharacter", self.TeamData.TeamData, self.CurPos, handler(self, self.OnSelect), nil, self.CharacterLimitType, {LimitBuffId = self.LimitBuffId})
    end
end
