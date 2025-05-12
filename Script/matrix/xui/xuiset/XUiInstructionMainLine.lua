---@class XUiInstructionMainLine : XUiNode
local XUiInstructionMainLine = XClass(XUiNode, "XUiInstructionMainLine")

function XUiInstructionMainLine:OnStart()
    self.StageId = CS.XFight.Instance.FightData.StageId
    self.CharacterIds = {}
    self.SelectCharIndex = nil
    self.ShowPanelNpc = false
    self.ShowPanelAchieve = false
    self.IsAllAchieveComplete = true
    self.GridOwnDic = {}
    self.GridEnemyDic = {}

    self:InitUiObj()
    self:RegisterUiEvents()
    self:InitPanelNpc()
    self:InitPanelAchieve()

    -- 有成就未完成时，战中暂停默认打开成就二级页签界面
    if not self.IsAllAchieveComplete then
        self.TabBtnGroup:SelectIndex(self.PanelIndex.Achieve)
    else
        local index = self.ShowPanelNpc and self.PanelIndex.Npc or self.PanelIndex.Achieve
        self.TabBtnGroup:SelectIndex(index)
    end
end

function XUiInstructionMainLine:InitUiObj()
    self.PanelIndex = { Npc = 1, Achieve = 2 }
    self.PanelSkill.gameObject:SetActiveEx(true)
    self.PanelAchieve.gameObject:SetActiveEx(false)
    self.Tabs = { self.BtnTabSkill, self.BtnTabAchieve, self.BtnTabState }
    self.Panels = { self.PanelSkill, self.PanelAchieve, self.PanelAffix }
    self.Npcs = { self.Npc1, self.Npc2, self.Npc3 }
    self.ImgPortraits = { self.TogPortrait1, self.TogPortrait2, self.TogPortrait3 }
    self.CoreHeadLineGos = { self.TxtSkillName }
    self.CoreDesGos = { self.TxtSkillbrief }
    self.AchieveGos = { self.GridAchieve }
end

function XUiInstructionMainLine:RegisterUiEvents()
    self.TabBtnGroup:Init(self.Tabs, function(index) self:OnTabClick(index)  end)
    self.PanelNpc:Init(self.Npcs, function(index) self:OnNpcClick(index) end)
end

function XUiInstructionMainLine:InitPanelNpc()
    local agency = XMVCA:GetAgency(ModuleId.XMainLine2)
    self.ShowPanelNpc = not agency:IsStageMonster(self.StageId)
    self.Tabs[self.PanelIndex.Npc].gameObject:SetActiveEx(self.ShowPanelNpc)
    if not self.ShowPanelNpc then
        return
    end

    local role = CS.XFight.GetActivateClientRole()
    local firstIndex = role.Npc and (role.Npc.Index + 1) or 1
    local firstHasNpc = role:GetNpc(firstIndex - 1)
    if not firstHasNpc then
        firstIndex = nil
    end
    
    ---@type XFubenAgency
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    local maxNpcCnt = #self.Npcs
    for i = 1, maxNpcCnt do
        local hasNpc, npc = role:GetNpc(i - 1)
        self.Npcs[i].gameObject:SetActiveEx(hasNpc)
        if hasNpc then
            local templateId = npc.TemplateId
            local characterId = math.floor(templateId / 10)
            local iconPath = npc.Template.HeadImageName

            -- 将Q版机器人id转回普通角色id
            if fubenAgency:IsStageCute(self.StageId) then
                characterId = XCharacterCuteConfig.GetCharacterIdByNpcId(templateId) or characterId
            end

            -- 兼容黑幕模式
            if npc.Fight.IsFubenDebug and npc.RLNpc then
                local template = npc.RLNpc:GetUiResTemplate()
                iconPath = template and template.HeadImageName or ""
            elseif npc.FightNpcData ~= nil then
                iconPath = XMVCA.XCharacter:GetFightCharHeadIcon(npc.FightNpcData.Character, characterId)
            end

            self.ImgPortraits[i]:SetSprite(iconPath)
            self.CharacterIds[i] = characterId

            firstIndex = firstIndex or i
        end
    end
    self.PanelNpc:SelectIndex(firstIndex or 1)
end

function XUiInstructionMainLine:InitPanelAchieve()
    local agency = XMVCA:GetAgency(ModuleId.XMainLine2)
    self.ShowPanelAchieve = agency:IsStageAchievement(self.StageId)
    self.IsAllAchieveComplete = true
    self.Tabs[self.PanelIndex.Achieve].gameObject:SetActiveEx(self.ShowPanelAchieve)
    if not self.ShowPanelAchieve then
        return
    end

    -- 刷新成就列表
    local achieveInfos = agency:GetStagesAchievementInfos(self.StageId, true)
    local ACHIEVEMENT_TYPE = XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE
    for i, info in ipairs(achieveInfos) do
        local uiObj = self.AchieveGos[i]
        if not uiObj then
            local go = CS.UnityEngine.Object.Instantiate(self.GridAchieve.gameObject, self.PanelAchieveList.transform)
            uiObj = go:GetComponent("UiObject")
            self.AchieveGos[i] = uiObj
        end

        if not info.IsFightUnLock and not info.IsUnLock then
            self.IsAllAchieveComplete = false
        end

        -- 隐藏显示
        local isHide = info.Type == ACHIEVEMENT_TYPE.HIDE and not info.IsUnLock
        if isHide then
            uiObj.gameObject:SetActiveEx(false)
            goto CONTINUE
        end

        -- 确定状态go
        local panelIncomplete = uiObj:GetObject("PanelIncomplete")
        local panelComplete = uiObj:GetObject("PanelComplete")
        local panelEnd = uiObj:GetObject("PanelEnd")
        panelIncomplete.gameObject:SetActiveEx(false)
        panelComplete.gameObject:SetActiveEx(false)
        panelEnd.gameObject:SetActiveEx(false)
        local panel = panelIncomplete
        if info.IsUnLock then
            panel = panelEnd
        elseif info.IsFightUnLock then
            panel = panelComplete
        end

        -- 详情
        panel.gameObject:SetActiveEx(true)
        if not info.IsUnLock and not info.IsFightUnLock then
            panel:GetObject("TxtDetail").text = info.UndoneDesc
        else
            panel:GetObject("TxtDetail").text = info.FullDesc
        end
        panel:GetObject("PanelNormal").gameObject:SetActiveEx(info.Type == ACHIEVEMENT_TYPE.NORMAL)
        panel:GetObject("PanelSpecial").gameObject:SetActiveEx(info.Type == ACHIEVEMENT_TYPE.SPECIAL)
        panel:GetObject("TxtTitleNormal").text = info.Name
        panel:GetObject("TxtTitleSpecial").text = info.Name

        local panelRealHide = panel:GetObject('PanelRealHide')
        local txtTitleRealHide = panel:GetObject("TxtTitleRealHide")
        
        if panelRealHide then
            panelRealHide.gameObject:SetActiveEx(info.Type == ACHIEVEMENT_TYPE.HIDE)
        end

        if txtTitleRealHide then
            txtTitleRealHide.text = info.Name
        end
        
        ::CONTINUE::
    end
end

function XUiInstructionMainLine:OnEnable()
end

function XUiInstructionMainLine:RefreshPanelAffix()
    local fight = CS.XFight.Instance
    if not fight then
        return
    end

    local uiAffix = fight.UiManager:GetUi(typeof(CS.XUiFightAffix))
    if not uiAffix then
        return
    end

    local selfAffixList = uiAffix:DoGetSelfUiAffixes()
    local enemyAffixList = uiAffix:DoGetEnemyUiAffixes()

    selfAffixList = XTool.CsList2LuaTable(selfAffixList)
    enemyAffixList = XTool.CsList2LuaTable(enemyAffixList)

    local selfAffixListFinal = {}
    for k, v in pairs(selfAffixList) do
        if v.AffixData.IsTrigger then
            table.insert(selfAffixListFinal, v)
        end
    end

    local enemyAffixListFinal = {}
    for k, v in pairs(enemyAffixList) do
        if v.AffixData.IsTrigger then
            table.insert(enemyAffixListFinal, v)
        end
    end

    local isSelfEmpty = XTool.IsTableEmpty(selfAffixListFinal)
    self.PanelNoneOwn.gameObject:SetActiveEx(isSelfEmpty)
    
    local isEnemyEmpty = XTool.IsTableEmpty(enemyAffixListFinal)
    self.PanelNoneEnemy.gameObject:SetActiveEx(isEnemyEmpty)

    local XGridAffix = require("XUi/XUiSet/ChildItem/XGridAffix")
    for k, data in pairs(selfAffixListFinal) do
        local grid = self.GridOwnDic[k]
        if not grid then
            local uiGo = XUiHelper.Instantiate(self.PanelDataOwn, self.PanelDataOwn.parent)
            uiGo.gameObject:SetActiveEx(false)
            grid = XGridAffix.New(uiGo, self)
            self.GridOwnDic[k] = grid
        end
        if self.PanelAffix.gameObject.activeSelf then
            grid:Open()
        else
            grid:Close()
        end
        grid:Refresh(data)
    end

    for k, data in pairs(enemyAffixListFinal) do
        local grid = self.GridEnemyDic[k]
        if not grid then
            local uiGo = XUiHelper.Instantiate(self.PanelDataEnemy, self.PanelDataEnemy.parent)
            uiGo.gameObject:SetActiveEx(false)
            grid = XGridAffix.New(uiGo, self)
            self.GridEnemyDic[k] = grid
        end
        if self.PanelAffix.gameObject.activeSelf then
            grid:Open()
        else
            grid:Close()
        end
        grid:Refresh(data)
        -- 自适应刷新
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(grid.GameObject:GetComponent("RectTransform"))
    end

    self.PanelDataOwn.gameObject:SetActiveEx(false)
    self.PanelDataEnemy.gameObject:SetActiveEx(false)
end

function XUiInstructionMainLine:OnTabClick(index)
    for i, panel in ipairs(self.Panels) do
        local isShow = i == index
        panel.gameObject:SetActiveEx(isShow)
    end
    self:RefreshPanelAffix()
end

function XUiInstructionMainLine:OnNpcClick(index)
    for _, go in pairs(self.CoreHeadLineGos) do
        go.gameObject:SetActiveEx(false)
    end
    for _, go in pairs(self.CoreDesGos) do
        go.gameObject:SetActiveEx(false)
    end

    -- 图片
    local characterId = self.CharacterIds[index]
    local skillIcon = XMVCA.XCharacter:GetCharTeachIconById(characterId)
    self.ImgCoreSkill:SetRawImage(skillIcon)

    -- 描述
    local headLines = XMVCA.XCharacter:GetCharTeachHeadLineById(characterId)
    local descriptions = XMVCA.XCharacter:GetCharTeachDescriptionById(characterId)
    for i, message in pairs(descriptions) do
        local headLine = headLines[i]
        if headLine then
            self:SetTextInfo(self.TxtSkillName, self.CoreHeadLineGos, i, headLine)
        end
        self:SetTextInfo(self.TxtSkillbrief, self.CoreDesGos, i, message)
    end
end

function XUiInstructionMainLine:SetTextInfo(targetGo, txtGo, i, info)
    local go = txtGo[i]
    if not go then
        go = XUiHelper.Instantiate(targetGo.gameObject, self.PanelReward)
        txtGo[i] = go
    end
    go.gameObject:SetActiveEx(true)
    go.transform:SetAsLastSibling()
    local goTxt = go:GetComponent("Text")
    goTxt.text = XUiHelper.ConvertLineBreakSymbol(info)
end

function XUiInstructionMainLine:CheckDataIsChange()
    return false
end

return XUiInstructionMainLine