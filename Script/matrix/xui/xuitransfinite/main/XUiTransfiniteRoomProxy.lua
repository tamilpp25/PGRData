local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiTransfiniteRoomProxy = XClass(XUiBattleRoleRoomDefaultProxy, "XUiTransfiniteRoomProxy")

function XUiTransfiniteRoomProxy:Ctor(team, stageId)
    self.StagId = stageId
    self.Team = team
end

function XUiTransfiniteRoomProxy:GetCurrentMemberList(stageGroup)
    if not stageGroup then
        stageGroup = XDataCenter.TransfiniteManager.GetStageGroupByStageId(self.StagId)
    end
    
    local stageTeam = stageGroup:GetTeam()
    
    return stageTeam:GetMembers()
end

function XUiTransfiniteRoomProxy:CheckMemberIsDead(index)
    local memberList = self:GetCurrentMemberList()
    local member = memberList[index]

    if member and member:IsValid() then
        local hp = member:GetHp() / 100

        return hp <= 0
    end
    
    return false
end

function XUiTransfiniteRoomProxy:AOPOnStartAfter(ui)
    local stageGroup = XDataCenter.TransfiniteManager.GetStageGroupByStageId(self.StagId)
    local memberList = self:GetCurrentMemberList(stageGroup)
    
    for i = 1, XTeamConfig.MEMBER_AMOUNT do
        local member = memberList[i]

        if member and member:IsValid() then
            local hp = member:GetHp() / 100
            local deadTag = ui["BtnChar" .. i].transform:FindTransform("PanelDead")

            if deadTag then
                deadTag.gameObject:SetActiveEx(hp <= 0)
            end
        end
    end

    ui.BtnEnterFight:SetNameByGroup(0, XUiHelper.GetText("ConfirmText"))
    ui.BtnTeamPrefab.gameObject:SetActiveEx(not stageGroup:IsBegin())
end

function XUiTransfiniteRoomProxy:AOPOnClickFight(ui)
    local canEnterFight, errorTip = self:GetIsCanEnterFight(self.Team, self.StageId)
    
    if not canEnterFight then
        if errorTip then
            XUiManager.TipError(errorTip)
        end
    else
        ui:Close()
    end
    
    return true
end

function XUiTransfiniteRoomProxy:AOPOnCharacterClickBefore(_, _)
    local stageGroup = XDataCenter.TransfiniteManager.GetStageGroupByStageId(self.StagId)

    if stageGroup:IsBegin() then
        XUiManager.TipText("TransfiniteTimeLockTeam2")
        return true
    end

    return false
end

function XUiTransfiniteRoomProxy:AOPGoPartnerCarry(_, pos)
    return self:CheckMemberIsDead(pos)
end

---@param buttonGroup XUiButtonGroup
---@param index number
---@param team XTeam
function XUiTransfiniteRoomProxy:AOPOnFirstFightBtnClick(buttonGroup, index, team)
    local memberList = self:GetCurrentMemberList()
    local selectMember = memberList[index]
    
    if selectMember and selectMember:IsValid() then
        local selectHp = selectMember:GetHp()
        
        if selectHp > 0 then
            return false
        else
            for i = 1, XTeamConfig.MEMBER_AMOUNT do
                local member = memberList[i]

                if member and member:IsValid() then
                    local hp = member:GetHp() / 100

                    if hp > 0 and i == team:GetFirstFightPos() then
                        buttonGroup:SelectIndex(i, false)
                        XUiManager.TipText("TransfiniteTeamMemberDead")
                        return true
                    end
                end
            end
        end
    else
       return false 
    end
end

---@param newCaptainPos number
function XUiTransfiniteRoomProxy:AOPOnCaptainPosChangeBefore(newCaptainPos, _)
    if self:CheckMemberIsDead(newCaptainPos) then
        XUiManager.TipText("TransfiniteTeamMemberDead")
        return true
    end
    
    return false
end

function XUiTransfiniteRoomProxy:CheckIsCanMoveUpCharacter(index, _)
    local stageGroup = XDataCenter.TransfiniteManager.GetStageGroupByStageId(self.StagId)

    if stageGroup:IsBegin() then
        XUiManager.TipText("TransfiniteTimeLockTeam2")
        return false
    end

    return true
end

function XUiTransfiniteRoomProxy:CheckIsCanMoveDownCharacter(index)
    local stageGroup = XDataCenter.TransfiniteManager.GetStageGroupByStageId(self.StagId)

    if stageGroup:IsBegin() then
        XUiManager.TipText("TransfiniteTimeLockTeam2")
        return false
    end

    return true
end

return XUiTransfiniteRoomProxy
