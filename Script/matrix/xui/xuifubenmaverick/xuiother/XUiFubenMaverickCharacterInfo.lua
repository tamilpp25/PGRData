local XUiFubenMaverickCharacterInfo = XClass(nil, "XUiFubenMaverickCharacterInfo")

function XUiFubenMaverickCharacterInfo:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)

    self.DisplayPropertyTexts = { }
    local memberPropertyTypes = XDataCenter.MaverickManager.MemberPropertyTypes
    for name, index in pairs(memberPropertyTypes) do
        self.DisplayPropertyTexts[index] = self["Txt" .. name]
    end
end

function XUiFubenMaverickCharacterInfo:Refresh(memberId)
    self.MemberId = memberId or self.MemberId
    
    local member = XDataCenter.MaverickManager.GetMember(self.MemberId)
    --特性标签
    local attributes = XDataCenter.MaverickManager.GetAttributes(self.MemberId)
    self.TxtAttribute1.text = attributes[1]
    self.TxtAttribute2.text = attributes[2]
    --角色名
    local robotId = XDataCenter.MaverickManager.GetRobotId(member)
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)
    self.TxtName.text = XMVCA.XCharacter:GetCharacterName(robotCfg.CharacterId)
    --类型图标
    local jobType = XRobotManager.GetRobotJobType(robotId)
    self.RImgTypeIcon:SetRawImage(XCharacterConfigs.GetNpcTypeIcon(jobType))
    --等级
    local maxLevel = XDataCenter.MaverickManager.GetMaxMemberLevel(self.MemberId)
    self.TxtLevel.text = member.Level .. "/" .. maxLevel
    --战斗参数
    local combatScore = XDataCenter.MaverickManager.GetCombatScore(member)
    self.TxtCombatScore.text = combatScore
    --展示的基础属性
    local attribs = XDataCenter.MaverickManager.GetDisplayAttribs(member)
    for index, textComponent in pairs(self.DisplayPropertyTexts) do
        if textComponent then
            textComponent.text = attribs[index]
        end
    end
    --改造按钮红点
    XRedPointManager.CheckOnce(self.OnCheckRedDot, self, { XRedPointConditions.Types.CONDITION_MAVERICK_CHARACTER }, self.MemberId)
end

function XUiFubenMaverickCharacterInfo:OnCheckRedDot(count)
    self.ImgRedPoint.gameObject:SetActiveEx(count >= 0)
end

return XUiFubenMaverickCharacterInfo