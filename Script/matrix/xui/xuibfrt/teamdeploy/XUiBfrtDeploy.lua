---@class XBfrtEchelonData
---@field BfrtGroupId number
---@field MemberIndex number
---@field RequireAbility number
---@field BaseStageId number
---@field StageId number
---@field EchelonRequireCharacterNum number
---@field EchelonIndex number
---@field EchelonId number
---@field EchelonType number
---@field TeamList table<number, number[]>
---@field CharacterIdListWrap table 暂且不知何用
---@field TeamHasLeader boolean
---@field TeamHasFirstFight boolean
---@field ConditionId number
---@field IsRecordPass boolean

local pairs = pairs
local ipairs = ipairs
local ANIMATION_OPEN = "AniBfrtDeployBegin"

local XUiGridEchelon = require("XUi/XUiBfrt/TeamDeploy/XUiGridEchelon")

---@class XUiBfrtDeploy:XLuaUi
local XUiBfrtDeploy = XLuaUiManager.Register(XLuaUi, "UiBfrtDeploy")

function XUiBfrtDeploy:OnAwake()
    XDataCenter.BfrtManager.InitTeamCaptainPos()
    XDataCenter.BfrtManager.InitTeamFirstFightPos()
    self:AutoAddListener()
    self:ResetGroupInfo()
end

function XUiBfrtDeploy:OnStart(groupId)
    self:InitGroupInfo(groupId)
    self:PlayAnimation(ANIMATION_OPEN)
    self:AddEventListener()
    self:SetFunctionClose()
end

function XUiBfrtDeploy:OnEnable()
    self:UpdateEchelonList()
end

function XUiBfrtDeploy:OnDestroy()
    XDataCenter.BfrtManager.InitTeamCaptainPos()
    XDataCenter.BfrtManager.InitTeamFirstFightPos()
    self:ResetGroupInfo()
    XDataCenter.BfrtManager.ReleaseViewData()
    self:RemoveEventListener()
end

--region Data&Obj
function XUiBfrtDeploy:ResetGroupInfo()
    self.GroupId = nil
    self.FightInfoIdList = {}
    self.LogisticsInfoIdList = {}
    self.CharacterIdListWrap = {}
    ---@type XUiGridEchelon[]
    self.LogisticsTeamGridList = {}
    ---@type XUiGridEchelon[]
    self.FightTeamGridList = {}
end

function XUiBfrtDeploy:InitGroupInfo(groupId)
    if not groupId then
        XLog.Error("XUiBfrtDeploy:InitGroupInfo error: groupId not Exist.")
        return
    end
    self.GroupId = groupId
    self.FightInfoIdList = XDataCenter.BfrtManager.GetFightInfoIdList(groupId)
    self.LogisticsInfoIdList = XDataCenter.BfrtManager.GetLogisticsInfoIdList(groupId)
    XDataCenter.BfrtManager.InitViewData(groupId)
end
--endregion

---region 设置某些功能关闭
function XUiBfrtDeploy:SetFunctionClose()
    self.BtnAutoTeam.gameObject:SetActiveEx(false)
end
---endregion

--region Ui - Echelon
function XUiBfrtDeploy:UpdateEchelonList()
    self:_RefreshFightTeam()
    self:_RefreshLogisticsTeam()
    self:UpdateQuickPassBtn()

    self.PanelDanger.gameObject:SetActiveEx(false)
    self.GridEchelon.gameObject:SetActiveEx(false)
end

function XUiBfrtDeploy:UpdateQuickPassBtn()
    if not XDataCenter.BfrtManager.GetGroupClearOpen(self.GroupId) then
        self.BtnTongBlue.gameObject:SetActiveEx(false)
        if self.ImgPjzlBg then
            self.ImgPjzlBg.gameObject:SetActiveEx(false)
        end
        return
    end
    local isShowBtn, avgAbility = self:_GetQuickPassParams()
    self:_RefreshQuickPassBtn(isShowBtn, avgAbility)
end

function XUiBfrtDeploy:_GetQuickPassParams()
    local numberCount = 0
    local avgAbility = 0
    local totalAbility = 0
    local fightTeamList = XDataCenter.BfrtManager.GetViewGroupFightTeams()
    for _, team in ipairs(fightTeamList) do
        for _, characterId in ipairs(team) do
            if XTool.IsNumberValid(characterId) then
                local char = XMVCA.XCharacter:GetCharacter(characterId)
                totalAbility = totalAbility + (char and char.Ability or 0)
                numberCount = numberCount + 1
            end
        end
    end
    local logisticsTeamList = XDataCenter.BfrtManager.GetViewGroupFightTeams(true)
    for _, team in ipairs(logisticsTeamList) do
        for _, characterId in ipairs(team) do
            if XTool.IsNumberValid(characterId) then
                local char = XMVCA.XCharacter:GetCharacter(characterId)
                totalAbility = totalAbility + (char and char.Ability or 0)
                numberCount = numberCount + 1
            end
        end
    end
    if numberCount > 0 then
        avgAbility = math.floor(totalAbility / numberCount)
        local requireNumberCount = 0
        for _, echelonId in ipairs(self.FightInfoIdList) do
            ---@type XBfrtEchelonData
            requireNumberCount = requireNumberCount + XDataCenter.BfrtManager.GetEchelonNeedCharacterNum(echelonId)
        end
        local isShowBtn = numberCount == requireNumberCount and avgAbility >= XDataCenter.BfrtManager.GetGroupNeedAbility(self.GroupId)
        return isShowBtn, avgAbility
    else
        return false, avgAbility
    end
end

function XUiBfrtDeploy:_RefreshQuickPassBtn(isShow, avgAbility)
    self.BtnTongBlue:SetDisable(not isShow)
    if self.ImgPjzlBg then
        self.ImgPjzlBg.text = XUiHelper.GetText("BfrtCurAbilityProcess", avgAbility, XDataCenter.BfrtManager.GetGroupNeedAbility(self.GroupId))
    end
end

function XUiBfrtDeploy:_RefreshFightTeam()
    for index, echelonId in ipairs(self.FightInfoIdList) do
        ---@type XBfrtEchelonData
        local data = self:_GetEchelonData(echelonId, index, true)

        local grid = self.FightTeamGridList[index]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridEchelon)
            grid = XUiGridEchelon.New(ui, self, data)
            grid.Transform:SetParent(self.PanelEchelonContent, false)
            grid.GameObject:SetActiveEx(true)
            grid.GameObject.name = tostring(echelonId)
            self.FightTeamGridList[index] = grid
        else
            grid:UpdateEchelonInfo(data)
        end
    end
    local fightTeamList = XDataCenter.BfrtManager.GetViewGroupFightTeams()
    for i = #self.FightInfoIdList + 1, #fightTeamList do
        fightTeamList[i] = nil
    end
end

function XUiBfrtDeploy:_RefreshLogisticsTeam()
    for index, echelonId in ipairs(self.LogisticsInfoIdList) do
        ---@type XBfrtEchelonData
        local data = self:_GetEchelonData(echelonId, index, false)

        local grid = self.LogisticsTeamGridList[index]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridEchelon)
            grid = XUiGridEchelon.New(ui, self, data)
            grid.Transform:SetParent(self.PanelEchelonContent, false)
            grid.GameObject:SetActiveEx(true)
            grid.GameObject.name = tostring(echelonId)
            self.LogisticsTeamGridList[index] = grid
        else
            grid:UpdateEchelonInfo(data)
        end
    end

    -- 部分红点逻辑自分了文件夹,不能直接用文件名作为全局变量调用
    -- 可使用XRedPointConditions.CONDITION_XXX代替   
    local logisticsTeamList = XDataCenter.BfrtManager.GetViewGroupFightTeams(true)
    for i = #self.LogisticsInfoIdList + 1, #logisticsTeamList do
        logisticsTeamList[i] = nil
    end
end

---@return XBfrtEchelonData
function XUiBfrtDeploy:_GetEchelonData(echelonId, index, isFight)
    ---@type XBfrtEchelonData
    local data = {}
    local stageIds = XDataCenter.BfrtManager.GetStageIdList(self.GroupId)
    data.BfrtGroupId = self.GroupId
    data.BaseStageId = XDataCenter.BfrtManager.GetBaseStage(self.GroupId)
    data.StageId = stageIds[index]
    data.EchelonType = isFight and XDataCenter.BfrtManager.EchelonType.Fight or XDataCenter.BfrtManager.EchelonType.Logistics
    data.EchelonId = echelonId
    data.EchelonIndex = index
    data.TeamList = XDataCenter.BfrtManager.GetViewGroupFightTeams(not isFight)
    data.CharacterIdListWrap = self.CharacterIdListWrap
    data.TeamHasLeader = data.EchelonType == XDataCenter.BfrtManager.EchelonType.Fight
    data.TeamHasFirstFight = data.EchelonType == XDataCenter.BfrtManager.EchelonType.Fight
    data.EchelonRequireCharacterNum = XDataCenter.BfrtManager.GetEchelonNeedCharacterNum(echelonId)
    data.ConditionId = XDataCenter.BfrtManager.GetEchelonConditionId(echelonId)
    data.IsRecordPass = XDataCenter.BfrtManager.CheckIsGroupStageRecordStage(self.GroupId, data.StageId)
    return data
end

function XUiBfrtDeploy:CheckAllTeamEmpty()
    local fightTeamList = XDataCenter.BfrtManager.GetViewGroupFightTeams()
    for echelonIndex, team in pairs(fightTeamList) do
        for _, id in pairs(team) do
            if id and id > 0 then
                return false
            end
        end
    end

    local logisticsTeamList = XDataCenter.BfrtManager.GetViewGroupFightTeams(true)
    for _, team in pairs(logisticsTeamList) do
        for _, id in pairs(team) do
            if id and id > 0 then
                return false
            end
        end
    end

    return true
end
--endregion

--region Ui - Team
function XUiBfrtDeploy:CheckIsInPassTeam(characterId, echelonIndex)
    local curEchelonIndex = XDataCenter.BfrtManager.CheckIsInTeamList(characterId)

    if XTool.IsNumberValid(curEchelonIndex) and echelonIndex ~= curEchelonIndex then
        local stageIds = XDataCenter.BfrtManager.GetStageIdList(self.GroupId)
        return XDataCenter.BfrtManager.CheckIsGroupStageRecordStage(self.GroupId, stageIds[curEchelonIndex])
    else
        return false
    end
end

function XUiBfrtDeploy:FindTeamPos(characterId)
    if not characterId or characterId <= 0 then
        return
    end
    local findTeam, findPos

    local fightTeamList = XDataCenter.BfrtManager.GetViewGroupFightTeams()
    for _, team in pairs(fightTeamList) do
        for pos, id in pairs(team) do
            if id == characterId then
                findTeam = team
                findPos = pos
                break
            end
        end
    end

    if not findTeam then
        local logisticsTeamList = XDataCenter.BfrtManager.GetViewGroupFightTeams(true)
        for _, team in pairs(logisticsTeamList) do
            for pos, id in pairs(team) do
                if id == characterId then
                    findTeam = team
                    findPos = pos
                    break
                end
            end
        end
    end

    return findTeam, findPos
end

function XUiBfrtDeploy:CharacterSwapEchelon(oldCharacterId, newCharacterId, selectPos)
    local oldTeam, oldCharacterPos = self:FindTeamPos(oldCharacterId)
    local newTeam, newCharacterPos = self:FindTeamPos(newCharacterId)

    if oldTeam and oldCharacterPos then
        oldTeam[oldCharacterPos] = newCharacterId
    else
        XDataCenter.BfrtManager.SetViewGroupFightTeamData(XDataCenter.BfrtManager.GetCurSelectTeamIdx(), selectPos, newCharacterId)
    end

    if newTeam and newCharacterPos then
        newTeam[newCharacterPos] = oldCharacterId
    end
end
--endregion

--region Ui - BtnListener
function XUiBfrtDeploy:AutoAddListener()
    self.BtnAutoTeam.CallBack = function()
        self:OnBtnAutoTeamClick()
    end
    self.BtnFight.CallBack = function()
        self:OnBtnFightClick()
    end
    self.BtnFight.IsOpenClickCD = true
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnQuickDeploy.CallBack = function()
        self:OnBtnQuickDeployClick()
    end
    self.BtnTongBlue.CallBack = function()
        self:OnBtnQuickClearClick()
    end
end

function XUiBfrtDeploy:OnBtnFightClick()
    local groupId = self.GroupId
    local fightTeamList = XDataCenter.BfrtManager.GetViewGroupFightTeams()
    local generalSkillIdList = XDataCenter.BfrtManager.GetViewGroupGeneralSkills() or {}
    local cgIndexGroup = XDataCenter.BfrtManager.GetViewCgIndexGroup()
    local checkTeamCb = function(errorText)
        if errorText then
            XUiManager.TipMsg(errorText)
            return
        end

        self:Close()
        XDataCenter.BfrtManager.SetHandEnterFightChapterId(XDataCenter.BfrtManager.GetGroupChapterId(groupId))
        XDataCenter.BfrtManager.EnterFight({
            GroupId = groupId,
            FightTeams = fightTeamList,
            GeneralSkills = generalSkillIdList,
            CgIndexGroup = cgIndexGroup,
        })
    end

    XDataCenter.BfrtManager.SetTeamAndDoCB(self.GroupId, fightTeamList, self.LogisticsInfoIdList, checkTeamCb)
end

function XUiBfrtDeploy:OnBtnAutoTeamClick()
    local fightTeamList, logisticsTeamList, anyMemberInTeam = XDataCenter.BfrtManager.AutoTeam(self.GroupId)
    if not anyMemberInTeam then
        XUiManager.TipMsg(CS.XTextManager.GetText("BfrtAutoTeamNoMember"))
        return
    end

    XDataCenter.BfrtManager.SetViewGroupFightTeams(fightTeamList)
    XDataCenter.BfrtManager.SetViewGroupFightTeams(logisticsTeamList, true)
    self:UpdateEchelonList()
end

function XUiBfrtDeploy:OnBtnQuickDeployClick()
    local groupId = self.GroupId
    local saveCb = function()
        self:UpdateEchelonList()
    end
    self:OpenChildUi("UiBfrtQuickDeploy", groupId, self, saveCb)
end

function XUiBfrtDeploy:OnBtnBackClick()
    self:Close()
end

function XUiBfrtDeploy:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiBfrtDeploy:OnBtnQuickClearClick()
    local isShowBtn, _ = self:_GetQuickPassParams()
    if not isShowBtn then
        return
    end

    local cb = function(errorText)
        if errorText then
            XUiManager.TipMsg(errorText)
            return
        end
        local groupId = self.GroupId
        local chapterId = XDataCenter.BfrtManager.GetGroupChapterId(groupId)
        -- 有压制记录则重置记录
        if XDataCenter.BfrtManager.CheckIsGroupStagePassRecord(groupId) then
            XDataCenter.BfrtManager.RequestResetGroupStage(nil, true, function()
                XDataCenter.BfrtManager.RequestFastPassGroup(chapterId, groupId)
            end)
        else
            XDataCenter.BfrtManager.RequestFastPassGroup(chapterId, groupId)
        end
    end

    local fightTeamList = XDataCenter.BfrtManager.GetViewGroupFightTeams()
    XDataCenter.BfrtManager.SetTeamAndDoCB(self.GroupId, fightTeamList, self.LogisticsInfoIdList, cb)
end

--endregion

--region Event
function XUiBfrtDeploy:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_BFRT_TEAM_UPDATE, self.UpdateEchelonList, self)
    XEventManager.AddEventListener(XEventId.EVENT_BFRT_TEAM_SWAP, self.CharacterSwapEchelon, self)
end

function XUiBfrtDeploy:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_BFRT_TEAM_UPDATE, self.UpdateEchelonList, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BFRT_TEAM_SWAP, self.CharacterSwapEchelon, self)
end
--endregion
