XUiGridTeamRole = XClass(nil, "XUiGridTeamRole")

function XUiGridTeamRole:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
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
end
-- auto
function XUiGridTeamRole:SetNull()
    self.ImgLeftnull.color = XDataCenter.TeamManager.GetTeamMemberColor(self.CurPos)
    self.ImgRightnull.color = XDataCenter.TeamManager.GetTeamMemberColor(self.CurPos)

    self.PanelHave.gameObject:SetActive(false)
    self.PanelNull.gameObject:SetActive(true)
end

function XUiGridTeamRole:SetHave(chrId)
    self.PanelHave.gameObject:SetActive(true)
    self.PanelNull.gameObject:SetActive(false)
    local character = XDataCenter.CharacterManager.GetCharacter(chrId)
    if not character then return end

    self.ImgLeftSkill.color = XDataCenter.TeamManager.GetTeamMemberColor(self.CurPos)
    self.ImgRightSkill.color = XDataCenter.TeamManager.GetTeamMemberColor(self.CurPos)
    self.RootUi:SetUiSprite(self.ImgIcon, XDataCenter.CharacterManager.GetCharBigHeadIcon(character.Id))
    self.RootUi:SetUiSprite(self.ImgQuality, XCharacterConfigs.GetCharacterQualityIcon(character.Quality))
end

function XUiGridTeamRole:Refresh(curPos, teamData, characterLimitType, limitBuffId)
    self.CharacterLimitType = characterLimitType
    self.LimitBuffId = limitBuffId
    self.CurPos = curPos
    self.TeamData = teamData
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

    self.TeamData.TeamData = teamData
    for pos, charId in ipairs(self.TeamData.TeamData) do
        if charId > 0 then
            firstCharPos = pos
            charCount = charCount + 1
        end
    end

    if charCount == 1 then
        self.TeamData.CaptainPos = firstCharPos
        self.TeamData.FirstFightPos = firstCharPos
    end

    XDataCenter.TeamManager.SetPlayerTeam(self.TeamData, true)
end

function XUiGridTeamRole:OnBtnClickClick()
    XLuaUiManager.Open("UiRoomCharacter", self.TeamData.TeamData, self.CurPos, handler(self, self.OnSelect), nil, self.CharacterLimitType, {LimitBuffId = self.LimitBuffId})
end
