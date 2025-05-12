local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
--######################## XUiReform2ndChildPanel ########################
local XUiReform2ndChildPanel = XClass(nil, "XUiReform2ndChildPanel")

function XUiReform2ndChildPanel:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)

    self.BtnChar1.gameObject:SetActiveEx(false)
    self.BtnChar2.gameObject:SetActiveEx(false)
    self.BtnChar3.gameObject:SetActiveEx(false)
end

function XUiReform2ndChildPanel:SetData(stageId)
    local rootStageId = XMVCA.XReform:GetRootStageId(stageId)
    local star = XMVCA.XReform:GetStageStarByPressure(rootStageId)
    self.TxtRecommendScore.text = XUiHelper.GetText("ReformRoleRoomStar", star)
    self.TxtScore.text = XUiHelper.GetText("ReformRoleRoomPressure", XMVCA.XReform:GetStagePressure(rootStageId))
end

--######################## XUiReform2ndBattleRoleRoom ########################
local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiReform2ndBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiReform2ndBattleRoleRoom")

function XUiReform2ndBattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiReform2nd/MainPage/XUiReform2ndBattleRoomRoleDetail")
end

function XUiReform2ndBattleRoleRoom:GetAutoCloseInfo()
    local endTime = XMVCA.XReform:GetActivityEndTime()
    return true, endTime, function(isClose)
        if isClose then
            XMVCA.XReform:HandleActivityEndTime()
        end
    end
end

-- 获取子面板数据，主要用来增加编队界面自身玩法信息，就不用污染通用的预制体
--[[
    return : {
        assetPath : 资源路径
        proxy : 子面板代理
        proxyArgs : 子面板SetData传入的参数列表
    }
]]
function XUiReform2ndBattleRoleRoom:GetChildPanelData()
    return {
        assetPath = XUiConfigs.GetComponentUrl("PanelReformBattleRoom"),
        proxy = XUiReform2ndChildPanel,
        proxyArgs = { "StageId" }
    }
end

---@param ui XUiBattleRoleRoom
function XUiReform2ndBattleRoleRoom:AOPOnStartAfter(ui)
    --关卡内可上阵角色有限制时，隐藏预设按钮
    local stageId = ui.StageId
    local characterList = XMVCA.XReform:GetCharacterCanSelect(stageId)
    if #characterList > 0 then
        ui.BtnTeamPrefab.gameObject:SetActiveEx(false)
    end
end

---@param ui XUiBattleRoleRoom
function XUiReform2ndBattleRoleRoom:AOPOnStartBefore(ui)
    local playerAmount = self:GetReformPlayerAmount(ui)
    local maxAmount = XEnumConst.FuBen.PlayerAmount
    if playerAmount ~= maxAmount then
        ---@type XTeam
        local team = ui.Team
        for i = playerAmount + 1, maxAmount do
            team:UpdateEntityTeamPos(0, i, true)

            local btnChar = ui["BtnChar" .. i]
            if btnChar then
                btnChar.gameObject:SetActiveEx(false)
            end

            local uiModelRoot = ui.UiModelGo.transform
            local panelRoleBGEffect = uiModelRoot:FindTransform("PanelRoleEffect" .. i)
            panelRoleBGEffect.gameObject:SetActiveEx(false)

            ---@type XUiButtonLongClick
            local button = ui["XUiButtonLongClick" .. i]
            if button then
                button.GameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiReform2ndBattleRoleRoom:GetReformPlayerAmount(ui)
    if not self._ReformPlayerAmount then
        if not ui then
            return XEnumConst.FuBen.PlayerAmount
        end
        local playerAmount = XMVCA.XReform:GetStagePlayerAmount(ui.StageId)
        self._ReformPlayerAmount = playerAmount
    end
    return self._ReformPlayerAmount
end

-- 检查是否满足关卡配置的强制性条件
-- return : bool
function XUiReform2ndBattleRoleRoom:CheckStageForceConditionWithTeamEntityId(team, stageId, showTip)
    if #team > self:GetReformPlayerAmount() then
        return false
    end
    return true
end

function XUiReform2ndBattleRoleRoom:CheckIsCanMoveDownCharacter(index)
    local amount = self:GetReformPlayerAmount()
    if index > amount then
        return false
    end
    return true
end

function XUiReform2ndBattleRoleRoom:FilterPresetTeamEntitiyIds(teamData)
    local amount = self:GetReformPlayerAmount()
    if amount ~= XEnumConst.FuBen.PlayerAmount then
        teamData = XTool.Clone(teamData)
        for pos, characterId in ipairs(teamData.TeamData) do
            if pos > amount then
                teamData.TeamData[pos] = 0
            end
        end
    end
    return teamData
end

function XUiReform2ndBattleRoleRoom:CheckShowAnimationSet()
    return false
end

return XUiReform2ndBattleRoleRoom