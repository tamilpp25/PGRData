local XUiNewRoomSingleTip = XLuaUiManager.Register(XLuaUi, "UiNewRoomSingleTip")

local MAX_CHAR_COUNT = 3

function XUiNewRoomSingleTip:OnAwake()
    self:AddListener()
    self:InitSelectTabGroup()

    for i = 1, MAX_CHAR_COUNT do
        local panelEnable = string.format("%s%s", "Ena0", i)
        local panelDisable = string.format("%s%s", "Dis0", i)
        local btnSelect = string.format("%s%s", "BtnSel0", i)

        if self[panelEnable] then
            self[panelEnable].gameObject:SetActiveEx(false)
        end
        if self[panelDisable] then
            self[panelDisable].gameObject:SetActiveEx(true)
        end
        if self[btnSelect] then
            self[btnSelect]:SetButtonState(CS.UiButtonState.Disable)
        end
    end

end

function XUiNewRoomSingleTip:AddListener()
    self.BtnTanchuangCloseBig.CallBack = function() self:OnCloseClick() end
end

function XUiNewRoomSingleTip:InitSelectTabGroup()
    self.tabGroup = {
        self.BtnSel01,
        self.BtnSel02,
        self.BtnSel03,
    }
    self.PanelBtnSel:Init(self.tabGroup, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
end

function XUiNewRoomSingleTip:OnClickTabCallBack(index)
    if self.CurCaptainPos == index or self.tabGroup[index].ButtonState == CS.UiButtonState.Disable then
        return
    else
        self.CurCaptainPos = index
    end
end

---=================================
--- 'teamData'是当前队伍角色
--- 索引：1中间，2左边，3右边
--- 值：角色的CharacterId或RobotId
---
--- 'curCaptainPos'是当前队长技能位置
--- 当关闭当前界面时，会调用'cb'函数更新相应界面
---
---'characterIdToIsIsAssitantDic'是角色是否为援助角色（即该角色是否不属于自己的）
---索引：角色的CharacterId或RobotId
---值：是否为援助角色
---@param rootUi table
---@param teamData table
---@param curCaptainPos number
---@param cb function
---=================================
function XUiNewRoomSingleTip:OnStart(rootUi, teamData, curCaptainPos, cb, characterIdToIsIsAssitantDic)
    self.RootUi = rootUi
    self.TeamData = teamData
    self.CurCaptainPos = curCaptainPos
    self.Cb = cb
    self.CharacterIdToIsIsAssitantDic = characterIdToIsIsAssitantDic
    self:Refresh()
end

function XUiNewRoomSingleTip:OnEnable()

end

function XUiNewRoomSingleTip:OnDisable()

end

function XUiNewRoomSingleTip:Refresh()
    if not self.TeamData then
        XLog.Error("XUiNewRoomSingleTip:Refresh函数错误：self.TeamData为nil")
        return
    end

    -- 设置三个角色栏的技能信息
    for i, char in pairs(self.TeamData) do
        local charId = 0

        if self.RootUi.IsExpedition and self.RootUi:IsExpedition() then
            local eCharCfg = XDataCenter.ExpeditionManager.GetMemberECfgByBaseId(char)
            charId = eCharCfg and eCharCfg.RobotId or 0
        else
            charId = char
        end

        if charId > 0 then
            local captianSkillInfo
            local head
            local skillDesc
            local isAssitant
            local charConfig = XMVCA.XCharacter:GetCharacterTemplate(charId)
            if charConfig == nil then
                return
            end

            if not XRobotManager.CheckIsRobotId(charId) then
                -- 玩家角色
                captianSkillInfo = XDataCenter.CharacterManager.GetCaptainSkillInfo(charId)
                if captianSkillInfo == nil then
                    return
                end

                -- 如果机器人使用了CharacterId，会误判断成玩家角色，并使用玩家角色的数据
                head = XDataCenter.CharacterManager.GetCharSmallHeadIcon(charId)
                isAssitant = self.CharacterIdToIsIsAssitantDic and self.CharacterIdToIsIsAssitantDic[charId] or false
                skillDesc = (captianSkillInfo.Level > 0 or isAssitant) and captianSkillInfo.Intro
                    or string.format("%s%s", captianSkillInfo.Intro, CS.XTextManager.GetText("CaptainSkillLock"))
            else
                -- 使用了RobotId的机器人
                head = XRobotManager.GetRobotSmallHeadIcon(charId)
                captianSkillInfo = XRobotManager.GetRobotCaptainSkillInfo(charId)
                if captianSkillInfo == nil then
                    return
                end
                skillDesc = captianSkillInfo.Intro
            end

            local name = string.format("%s%s", "TextName0", i)
            local skillName = string.format("%s%s", "TextJinengName0", i)
            local ImgHead = string.format("%s%s", "RawImage0", i)
            local skillInfo = string.format("%s%s", "TextJinengInfo0", i)

            local panelEnable = string.format("%s%s", "Ena0", i)
            local panelDisable = string.format("%s%s", "Dis0", i)
            local btnSelect = string.format("%s%s", "BtnSel0", i)

            if self[name] then
                self[name].text = string.format("%s-%s", charConfig.Name, charConfig.TradeName)
            end
            if self[skillName] then
                self[skillName].text = captianSkillInfo.Name
            end
            if head and self[ImgHead] then
                self[ImgHead]:SetRawImage(head)
            end
            if skillDesc and self[skillInfo] then
                self[skillInfo].text = skillDesc
            end

            if self[panelEnable] then
                self[panelEnable].gameObject:SetActiveEx(true)
            end
            if self[panelDisable] then
                self[panelDisable].gameObject:SetActiveEx(false)
            end
            if self[btnSelect] then
                self[btnSelect]:SetButtonState(CS.UiButtonState.Normal)
            end
        else
            local panelEnable = string.format("%s%s", "Ena0", i)
            local panelDisable = string.format("%s%s", "Dis0", i)
            local btnSelect = string.format("%s%s", "BtnSel0", i)

            -- 当前位置未上阵角色
            if self[panelEnable] then
                self[panelEnable].gameObject:SetActiveEx(false)
            end
            if self[panelDisable] then
                self[panelDisable].gameObject:SetActiveEx(true)
            end
            if self[btnSelect] then
                self[btnSelect]:SetButtonState(CS.UiButtonState.Disable)
            end
        end
    end

    if not self.CurCaptainPos or self.CurCaptainPos <= 0 or self.CurCaptainPos > 3 then
        XLog.Error("XUiNewRoomSingleTip:Refresh函数错误：self.CurCaptainPos超出队伍索引范围")
        return
    end

    self.PanelBtnSel:SelectIndex(self.CurCaptainPos)
end

function XUiNewRoomSingleTip:OnCloseClick()
    if self.Cb then
        self.Cb(self.CurCaptainPos)
    end
    self:Close()
end