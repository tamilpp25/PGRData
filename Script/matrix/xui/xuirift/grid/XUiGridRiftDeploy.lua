local XUiGridRiftDeploy = XClass(nil, "XUiGridRiftDeploy")
local XUiGridRiftDeployMember = require("XUi/XUiRift/Grid/XUiGridRiftDeployMember")

function XUiGridRiftDeploy:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.MemberGrids = {}
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self.BtnLeader.CallBack = function() self:OnBtnLeaderClick() end
    self.BtnTemplate.CallBack = function() self:OnBtnTemplateClick() end
    self.GridDeployMember.gameObject:SetActiveEx(false)
end

function XUiGridRiftDeploy:Refresh(xTeam, xStageGroup, index)
    self.XTeam = xTeam
    self.XStageGroup = xStageGroup
    self.TeamIndex = index

    self:UpdateUiShow()
    self:UpdateTeam()
    self:UpdateTemplate()
end

function XUiGridRiftDeploy:UpdateUiShow()
    local currXStage = self.XStageGroup:GetAllEntityStages()[self.TeamIndex]
    local isFinished = currXStage:CheckHasPassed()
    self.PanelVictory.gameObject:SetActiveEx(isFinished)
end

function XUiGridRiftDeploy:UpdateTeam()
    self.TxtLeaderSkill.text = self.XTeam:GetCaptainSkillDesc() -- 队长技

    for index = 1, 3 do
        local grid = self.MemberGrids[index]
        if not grid then
            local go =
                index == 1 and self.GridDeployMember or
                CS.UnityEngine.Object.Instantiate(self.GridDeployMember, self.PanelDeployMembers)
            grid = XUiGridRiftDeployMember.New(go)
            self.MemberGrids[index] = grid
        end
        grid:Refresh(self.XTeam, index)
        --蓝色放到第一位
        if index == 2 then
            grid.Transform:SetAsFirstSibling()
        end
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiGridRiftDeploy:UpdateTemplate()
    local tempId = self.XTeam:GetShowAttrTemplateId()
    local temp = XDataCenter.RiftManager.GetAttrTemplate(tempId)
    if not temp then
        return
    end
    self.TxtTitle.text = temp:GetName()
    for i, v in pairs(temp.AttrList) do
        self["Txt0"..i].text = XRiftConfig.GetTeamAttributeName(i)
        self["TxtSu0"..i].text = v.Level
    end
end

function XUiGridRiftDeploy:OnBtnLeaderClick()
    local characterIdList = self.XTeam:GetEntityIds()
    local captainPos = self.XTeam:GetCaptainPos()
    XLuaUiManager.Open(
        "UiNewRoomSingleTip",
        self,
        characterIdList,
        captainPos,
        function(index)
            self.XTeam:UpdateCaptainPos(index)
            self:UpdateTeam()
        end
    )
end

function XUiGridRiftDeploy:OnBtnTemplateClick()
    -- 检测加点功能开放
    local isUnlock = XDataCenter.RiftManager.IsFuncUnlock(XRiftConfig.FuncUnlockId.Attribute)
    if not isUnlock then
        XUiManager.TipError(CS.XTextManager.GetText("RiftAttributeLimit"))
        return
    end

    local tempId = self.XTeam:GetShowAttrTemplateId()
    local changeCb = function (newTempId)
        self:UpdateTemplate()
        XDataCenter.RiftManager.RiftSetTeamRequest(self.XTeam, newTempId, function ()
            self:UpdateTemplate()
        end)
    end
    local clearCb = function (clearTempId)
        self.RootUi:UpdateTeamList()
    end
    XLuaUiManager.Open("UiRiftTemplate", tempId, changeCb, clearCb)
end

function XUiGridRiftDeploy:OnDestroy()
end

return XUiGridRiftDeploy
