---@class XUiMainLine2DetailBattle:XLuaUi
---@field private _Control XMainLine2Control
local XUiMainLine2DetailBattle = XLuaUiManager.Register(XLuaUi, "UiMainLine2DetailBattle")

function XUiMainLine2DetailBattle:OnAwake()
    self.BtnMode.gameObject:SetActiveEx(false)
    self.ImgVtTag.gameObject:SetActiveEx(false)
    self.GridStage.gameObject:SetActiveEx(false)

    self.AchievementUiObjs = { self.GridAchievement }
    self.CharacterUiObjs = { self.GridCharacter }
    self.GridPoints = { self.GridPoint }
    self:RegisterUiEvents()
end

function XUiMainLine2DetailBattle:OnStart(stageIds, chapterId, mainId)
    self.StageIds = stageIds
    self.ChapterId = chapterId
    self.MainId = mainId

    self.UnlockStageIds = self:GetUnlockStageIds(stageIds)
    self.StageIndex = 1
    self.StageId = stageIds[self.StageIndex]
    self:InitStageIcons()
end

function XUiMainLine2DetailBattle:OnEnable()
    self:Refresh()
end

function XUiMainLine2DetailBattle:OnRelease()
    self.AchievementUiObjs = nil
    self.CharacterUiObjs = nil
    self.GridPoints = nil
end

function XUiMainLine2DetailBattle:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
end

function XUiMainLine2DetailBattle:OnBtnEnterClick()
    local stageId = self.StageId
    self:Close()

    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    local stageCfg = fubenAgency:GetStageCfg(stageId)
    local team = XDataCenter.TeamManager.GetXTeamByStageId(stageId)
    if #stageCfg.RobotId > 0 then
        fubenAgency:EnterFightByStageId(stageId, team:GetId())
    else
        local proxy = require("XUi/XUiMainLine2/XUiMainLine2BattleRoleRoom")
        XLuaUiManager.Open("UiBattleRoleRoom", stageId, team, proxy)
    end
end

-- 初始化关卡图
function XUiMainLine2DetailBattle:InitStageIcons()
    local XUiMainLine2GridStage = require("XUi/XUiMainLine2/XUiMainLine2GridStage")
    self.DynamicTable = XDynamicTableCurve.New(self.PanelStages)
    self.DynamicTable:SetProxy(XUiMainLine2GridStage, self)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetDataSource(self.UnlockStageIds)
    self.DynamicTable:ReloadData(0)

    local isShowPoint = #self.UnlockStageIds > 1
    self.PanelPoint.gameObject:SetActiveEx(isShowPoint)
    if isShowPoint then 
        local CSInstantiate = CS.UnityEngine.Object.Instantiate
        for i, stageId in ipairs(self.UnlockStageIds) do
            local point = self.GridPoints[i]
            if not point then
                local go = CSInstantiate(self.GridPoint.gameObject, self.PanelPoint.transform)
                point = go:GetComponent("UiObject")
                self.GridPoints[i] = point
            end
        end
    end
end

function XUiMainLine2DetailBattle:Refresh()
    self:RefreshInfo()
    self:RefreshProgress()
    self:RefreshAchievements()
    self:RefreshCharacters()
    self:RefreshPoints()
end

function XUiMainLine2DetailBattle:RefreshInfo()
    local stageCfg = XMVCA:GetAgency(ModuleId.XFuben):GetStageCfg(self.StageId)
    local title = self._Control:GetMainTitle(self.MainId)
    local specialorder = self._Control:GetStageSpecialorder(self.StageId)
    self.TxtName.text = string.format("%s-%s%s %s", title, stageCfg.OrderId, specialorder or "", stageCfg.Name)
    self.TxtDesc.text = stageCfg.Description
    self.TxtTarget.text = stageCfg.StarDesc[1]
end

-- 刷新进度
function XUiMainLine2DetailBattle:RefreshProgress()
    local reachCnt, allCnt = self._Control:GetStageProgress(self.StageId)
    if allCnt <= 0 or reachCnt == allCnt then
        self.TxtTargetProgress.text = ""
    else
        self.TxtTargetProgress.text = math.floor(reachCnt / allCnt * 100) .. "%"
    end

    local agency = XMVCA:GetAgency(ModuleId.XMainLine2)
    local isPass = agency:IsStagePass(self.StageId)
    self.ClearTag.gameObject:SetActiveEx(isPass)
end

-- 刷新成就列表
function XUiMainLine2DetailBattle:RefreshAchievements()
    local stageCfg = self._Control:GetConfigStage(self.StageId)
    local isShow = stageCfg.AchievementDescs and #stageCfg.AchievementDescs > 0
    self.PanelAchievement.gameObject:SetActiveEx(isShow)
    if not isShow then
        return
    end

    local count, achieveMap = self._Control:GetStageAchievementMap(self.StageId)
    local unlockDesc = self._Control:GetClientConfigParams("StageAchievementUnlockDesc", 1)
    for i, desc in ipairs(stageCfg.AchievementDescs) do
        local uiObj = self.AchievementUiObjs[i]
        if not uiObj then
            local go = CS.UnityEngine.Object.Instantiate(self.GridAchievement.gameObject, self.PanelAchievement.transform)
            uiObj = go:GetComponent("UiObject")
            self.AchievementUiObjs[i] = uiObj
        end

        -- 图标
        local achieveType = stageCfg.AchievementTpyes[i]
        local isNormal = achieveType == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.NORMAL
        local isSpecial = achieveType == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.SPECIAL
        uiObj:GetObject("RImgNormalOn").gameObject:SetActiveEx(isNormal)
        uiObj:GetObject("RImgNormalOff").gameObject:SetActiveEx(isNormal)
        uiObj:GetObject("RImgSpecialOn").gameObject:SetActiveEx(isSpecial)
        uiObj:GetObject("RImgSpecialOff").gameObject:SetActiveEx(isSpecial)

        -- 描述
        uiObj:GetObject("TxtDescOn").text = desc
        uiObj:GetObject("TxtDescOff").text = isSpecial and unlockDesc or desc

        -- 解锁状态
        local isUnlock = achieveMap and achieveMap[i] == true
        uiObj:GetObject("PanelOn").gameObject:SetActiveEx(isUnlock)
        uiObj:GetObject("PanelOff").gameObject:SetActiveEx(not isUnlock)
    end
end

-- 刷新出站成员
function XUiMainLine2DetailBattle:RefreshCharacters()
    local monsterHead = self._Control:GetStageMonsterHead(self.StageId)
    if monsterHead then
        local uiObj = self.CharacterUiObjs[1]
        uiObj:GetObject("RImgCharater"):SetRawImage(monsterHead)
        uiObj:GetObject("FirstTag").gameObject:SetActiveEx(true)
        return
    end

    local stageCfg = XMVCA:GetAgency(ModuleId.XFuben):GetStageCfg(self.StageId)
    local isShow = #stageCfg.RobotId > 0
    self.PanelCharacter.gameObject:SetActiveEx(isShow)
    if not isShow then
        return
    end

    for i, robotId in ipairs(stageCfg.RobotId) do
        local uiObj = self.CharacterUiObjs[i]
        if not uiObj then
            local go = CS.UnityEngine.Object.Instantiate(self.GridCharacter.gameObject, self.CharacterList.transform)
            uiObj = go:GetComponent("UiObject")
            self.CharacterUiObjs[i] = uiObj
        end

        local icon = XRobotManager.GetRobotSmallHeadIcon(robotId)
        uiObj:GetObject("RImgCharater"):SetRawImage(icon)
        uiObj:GetObject("FirstTag").gameObject:SetActiveEx(i == 1)
    end
end

-- 刷新关卡图标选中点
function XUiMainLine2DetailBattle:RefreshPoints()
    for i, point in ipairs(self.GridPoints) do
        local isSelect = i == self.StageIndex
        point:GetObject("ImgOn").gameObject:SetActiveEx(isSelect)
        point:GetObject("ImgOff").gameObject:SetActiveEx(not isSelect)
    end
end

function XUiMainLine2DetailBattle:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local stageId = self.UnlockStageIds[index + 1]
        grid:Refresh(stageId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        local startIndex = self.DynamicTable.Imp.StartIndex
        self:OnStageChange(startIndex + 1)
    end
end

-- 切换关卡Id
function XUiMainLine2DetailBattle:OnStageChange(index)
    self.StageIndex = index
    self.StageId = self.UnlockStageIds[self.StageIndex]
    self:Refresh()
end

-- 获取解锁的关卡Id列表
function XUiMainLine2DetailBattle:GetUnlockStageIds(stageIds)
    local result = {}
    for _, stageId in ipairs(stageIds) do
        local isUnlock = self._Control:IsStageUnlock(stageId)
        if isUnlock then
            table.insert(result, stageId)
        end
    end
    return result
end

return XUiMainLine2DetailBattle