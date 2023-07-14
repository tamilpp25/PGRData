local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiGridAssignFormationMember = XClass(nil, "XUiGridAssignFormationMember") -- XUiGridEchelonMember

function XUiGridAssignFormationMember:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiGridAssignFormationMember:InitComponent()
    CsXUiHelper.RegisterClickEvent(self.BtnMember, function() self:OnMemberClick() end)
    self.RImgRole.gameObject:SetActiveEx(false)
    self.ImgLeader.gameObject:SetActiveEx(false)
    self.ImgAbility.gameObject:SetActiveEx(false)
    -- self.TxtAbility
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(false)
    self.ImgFirstRole.gameObject:SetActiveEx(false)
end

function XUiGridAssignFormationMember:Refresh(groupId, teamOrder, teamData, memberOrder)
    self.GroupId = groupId
    self.TeamOrder = teamOrder
    self.TeamData = teamData
    self.MemberOrder = memberOrder

    local memberData = teamData:GetMemberList()[memberOrder]
    self.MemberData = memberData
    self.CurCharacterId = nil

    local index = memberData:GetIndex()
    local color = XUiHelper.Hexcolor2Color(XDataCenter.FubenAssignManager.MemberColor[index])
    self.ImgLeftSkill.color = color
    self.ImgRightSkill.color = color

    self.ImgSelect.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(false)

    self.CharacterId = memberData:GetCharacterId()
    if self.CharacterId and self.CharacterId ~= 0 then
        self.RImgRole.gameObject:SetActiveEx(true)
        self.RImgRole:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(self.CharacterId))

    else
        self.RImgRole.gameObject:SetActiveEx(false)
    end

    self:RefreshLeaderIndex()
end

-- 更新角色grid的队长与首发标签
function XUiGridAssignFormationMember:RefreshLeaderIndex()
    if not self.MemberData then
        return
    end
    local index = self.MemberData:GetIndex()
    local leaderIndex = self.TeamData:GetLeaderIndex()
    local firstFightIndex = self.TeamData:GetFirstFightIndex()

    self.ImgLeader.gameObject:SetActiveEx(index == leaderIndex)
    self.ImgFirstRole.gameObject:SetActiveEx(index == firstFightIndex)
end

function XUiGridAssignFormationMember:OnMemberClick()
    local firstOrder = XDataCenter.FubenAssignManager.OccupyFirstSelectOrder
    if not firstOrder and not self.CharacterId then
        XLog.Debug("请选中角色")
        return
    end

    local teamId = self.TeamData:GetId()
    local memberList = self.TeamData:GetMemberList()
    -- 选第一个
    if not firstOrder then
        firstOrder = self.MemberOrder
        self.ImgSelect.gameObject:SetActiveEx(true)

        XDataCenter.FubenAssignManager.OccupyFirstSelectTeamId = teamId
        XDataCenter.FubenAssignManager.OccupyFirstSelectOrder = firstOrder
    else
        if teamId == XDataCenter.FubenAssignManager.OccupyFirstSelectTeamId and firstOrder == self.MemberOrder then -- 反选第一个
            -- memberList[firstOrder]:SetCharacterId(nil)
            return
        else
            -- self.ImgSelect.gameObject:SetActiveEx(true)
            local srcTeamId = XDataCenter.FubenAssignManager.OccupyFirstSelectTeamId
            local srcTeamData = XDataCenter.FubenAssignManager.GetTeamDataById(srcTeamId)
            local srcMemberList = srcTeamData:GetMemberList()
            local srcCharacterId = srcMemberList[firstOrder]:GetCharacterId()
            local dstCharacterId = self.CharacterId

            local swapFunc = function(isReset)
                if isReset then
                    srcTeamData:ClearMemberList()
                    self.TeamData:ClearMemberList()
                end

                srcMemberList[firstOrder]:SetCharacterId(self.CharacterId)
                memberList[self.MemberOrder]:SetCharacterId(srcCharacterId)

                XDataCenter.FubenAssignManager.OccupySecondSelectTeamId = teamId
                XDataCenter.FubenAssignManager.OccupySecondSelectOrder = self.MemberOrder

                CsXGameEventManager.Instance:Notify(XEventId.EVENT_ASSIGN_REFRESH_FORMATION) -- 刷新编队界面  将调用RefreshEffect
            end

            local oldCharacterLimitType = XFubenConfigs.GetStageCharacterLimitType(srcTeamId)
            local newCharacterLimitType = XFubenConfigs.GetStageCharacterLimitType(teamId)

            local oldCharacterType = srcTeamData:GetCharacterType()
            local newCharacterType = self.TeamData:GetCharacterType()

            --仅当副本限制类型为构造体/感染体强制要求时赋值
            local oldForceCharacterType = XDataCenter.FubenManager.GetForceCharacterTypeByCharacterLimitType(oldCharacterLimitType)
            local newForceCharacterType = XDataCenter.FubenManager.GetForceCharacterTypeByCharacterLimitType(newCharacterLimitType)

            --角色类型不符合副本限制类型
            if oldForceCharacterType and newCharacterType and oldForceCharacterType ~= newCharacterType
            or newForceCharacterType and oldCharacterType and newForceCharacterType ~= oldCharacterType then
                XUiManager.TipText("SwapCharacterTypeIsNotMatch")
                return
            end

            local limitType = XFubenConfigs.GetStageCharacterLimitType(teamId)
            if limitType == XFubenConfigs.CharacterLimitType.Isomer or
                limitType == XFubenConfigs.CharacterLimitType.Normal then
                --角色类型不一致
                if newCharacterType and oldCharacterType and oldCharacterType ~= newCharacterType then
                    local content = CSXTextManagerGetText("SwapCharacterTypeIsDiffirent")
                    local sureCallBack = function() swapFunc(true) end
                    XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, sureCallBack)
                    return
                end
            end

            swapFunc()
        end

    end
end


function XUiGridAssignFormationMember:RefreshEffect(state)
    if state == XDataCenter.FubenAssignManager.FormationState.Effect then -- 隐藏选框，显示特效
        local firstTeamId = XDataCenter.FubenAssignManager.OccupyFirstSelectTeamId or 0
        local secondTeamId = XDataCenter.FubenAssignManager.OccupySecondSelectTeamId or 0
        local firstOrder = XDataCenter.FubenAssignManager.OccupyFirstSelectOrder
        local secondOrder = XDataCenter.FubenAssignManager.OccupySecondSelectOrder
        local teamId = self.TeamData:GetId()
        local isFirstSelected = (teamId == firstTeamId and self.MemberOrder == firstOrder)
        local isSecondSelect = (teamId == secondTeamId and self.MemberOrder == secondOrder)
        self.ImgSelect.gameObject:SetActiveEx(false)
        self.PanelEffect.gameObject:SetActiveEx(isFirstSelected or isSecondSelect)

    elseif state == XDataCenter.FubenAssignManager.FormationState.Reset then -- 重置数据
        XDataCenter.FubenAssignManager.OccupyFirstSelectTeamId = nil
        XDataCenter.FubenAssignManager.OccupyFirstSelectOrder = nil
        XDataCenter.FubenAssignManager.OccupySecondSelectTeamId = nil
        XDataCenter.FubenAssignManager.OccupySecondSelectOrder = nil
        self.ImgSelect.gameObject:SetActiveEx(false)
        self.PanelEffect.gameObject:SetActiveEx(false)
    end
end

return XUiGridAssignFormationMember