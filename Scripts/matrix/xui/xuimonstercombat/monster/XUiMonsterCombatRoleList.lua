local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiGridMonsterRole = require("XUi/XUiMonsterCombat/Monster/XUiGridMonsterRole")
---@class XUiMonsterCombatRoleList : XLuaUi
local XUiMonsterCombatRoleList = XLuaUiManager.Register(XLuaUi, "UiMonsterCombatRoleList")

function XUiMonsterCombatRoleList:OnAwake()
    self.MonsterTeam = nil
    self.StageId = nil
    self.Pos = nil
    self:RegisterUiEvents()
    self:InitUiPanelRoleModel()
    self.GridCharacterNew.gameObject:SetActiveEx(false)
end

---@param monsterTeam XMonsterTeam
function XUiMonsterCombatRoleList:OnStart(type, stageId, monsterTeam, pos)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.CurrentMonsterId = nil
    self.IsBattle = type == XMonsterCombatConfigs.MonsterInterfaceType.Battle
    if self.IsBattle then
        self.StageId = stageId
        self.MonsterTeam = monsterTeam
        self.Pos = pos
        self.CurrentMonsterId = self.MonsterTeam:GetMonsterIdByPos(pos)
    end
    self:InitDynamicTable()

    -- 开启自动关闭检查
    local endTime = XDataCenter.MonsterCombatManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.MonsterCombatManager.OnActivityEnd(true)
        end
    end)
end

function XUiMonsterCombatRoleList:OnEnable()
    self.Super.OnEnable(self)
    self:SetupDynamicTable(self.CurrentMonsterId)
end

function XUiMonsterCombatRoleList:InitUiPanelRoleModel()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    ---@type XUiPanelRoleModel
    self.UiPanelRoleModel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true, true)
end

function XUiMonsterCombatRoleList:GetMonsterInfoList()
    local monsterList = {}
    if not self.IsBattle then
        monsterList = XMonsterCombatConfigs.GetAllMonsterIds()
    else
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
        local chapterId = stageInfo.ChapterId
        local chapterEntity = XDataCenter.MonsterCombatManager.GetChapterEntity(chapterId)
        monsterList = XTool.Clone(chapterEntity:GetLimitMonsters())
    end
    return monsterList
end

function XUiMonsterCombatRoleList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelCharacterList)
    self.DynamicTable:SetProxy(XUiGridMonsterRole, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiMonsterCombatRoleList:SetupDynamicTable(monsterId)
    local monsterList = self:GetMonsterInfoList()
    self:MonsterListSort(monsterList)
    local index = 1
    local isSetMonsterId = true
    if monsterId then
        for k, v in pairs(monsterList) do
            if v == monsterId then
                index = k
                isSetMonsterId = false
            end
        end
    end
    if isSetMonsterId then
        monsterId = monsterList[index]
    end
    self:UpdateCurMonsterInfo(monsterId)
    self.DataList = monsterList
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(index)
end

---@param grid XUiGridMonsterRole
function XUiMonsterCombatRoleList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local monsterId = self.DataList[index]
        grid:Refresh(monsterId)
        local isSelect = self.CurrentMonsterId == monsterId
        if isSelect then
            self.CurSelectGrid = grid
        end
        grid:SetSelectStatus(isSelect)
        grid:RefreshRedPoint(self:CheckMonsterClick(monsterId, isSelect))
        grid:SetInTeamStatus(self:GetMonsterIdIsInTeam(monsterId))
        grid:SetInRecommendStatus(self:GetMonsterIdIsInRecommend(monsterId))
        grid:SetInFetterStatus(self:GetMonsterIdIsInFetter(monsterId))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local monsterId = self.DataList[index]
        if self.CurrentMonsterId ~= monsterId then
            if self.CurSelectGrid then
                self.CurSelectGrid:SetSelectStatus(false)
            end
            grid:SetSelectStatus(true)
            grid:RefreshRedPoint(self:CheckMonsterClick(monsterId, true))
            self.CurSelectGrid = grid
            self:UpdateCurMonsterInfo(monsterId)
        end
    end
end

-- 当前怪物是否在队伍中
function XUiMonsterCombatRoleList:GetMonsterIdIsInTeam(monsterId)
    if not self.IsBattle then
        return false
    end
    return self.MonsterTeam:GetMonsterIdIsInTeam(monsterId)
end

-- 当前怪物是否是推荐怪物
function XUiMonsterCombatRoleList:GetMonsterIdIsInRecommend(monsterId)
    if not self.IsBattle then
        return false
    end
    local stageEntity = XDataCenter.MonsterCombatManager.GetStageEntity(self.StageId)
    return table.contains(stageEntity:GetRecommendMonsters(), monsterId)
end

-- 当前怪物是否是羁绊怪物
function XUiMonsterCombatRoleList:GetMonsterIdIsInFetter(monsterId)
    if not self.IsBattle then
        return false
    end
    local buffConfig = XMonsterCombatConfigs.GetBuffConfigByMonsterId(monsterId)
    -- 羁绊角色
    local characterIds = buffConfig.CharacterIds
    local curCharacterId = self.MonsterTeam:GetCaptainPosEntityId()
    if not XTool.IsNumberValid(curCharacterId) then
        return false
    end
    if XEntityHelper.GetIsRobot(curCharacterId) then
        curCharacterId = XRobotManager.GetCharacterId(curCharacterId)
    end
    return table.contains(characterIds, curCharacterId)
end

-- 检查怪物是否是新解锁
function XUiMonsterCombatRoleList:CheckMonsterRedPoint(monsterId)
    if self.IsBattle then
        return false
    end
    local monsterEntity = XDataCenter.MonsterCombatManager.GetMonsterEntity(monsterId)
    return monsterEntity:CheckNewUnlockMonster()
end

-- 点击怪物 返回是否显示红点
function XUiMonsterCombatRoleList:CheckMonsterClick(monsterId, isSelect)
    local isRedPoint = self:CheckMonsterRedPoint(monsterId)
    if isSelect and isRedPoint then
        XDataCenter.MonsterCombatManager.SaveMonsterClick(monsterId)
        isRedPoint = false
    end
    return isRedPoint
end

local UnlockSort = function(idA, idB)
    local isUnlcokA = XDataCenter.MonsterCombatManager.GetMonsterEntity(idA):CheckIsUnlock()
    local isUnlcokB = XDataCenter.MonsterCombatManager.GetMonsterEntity(idB):CheckIsUnlock()
    if isUnlcokA ~= isUnlcokB then
        return true, isUnlcokA
    end
    return false
end

local OrderSort = function(idA, idB)
    local orderA = XDataCenter.MonsterCombatManager.GetMonsterEntity(idA):GetOrder()
    local orderB = XDataCenter.MonsterCombatManager.GetMonsterEntity(idB):GetOrder()
    if orderA ~= orderB then
        return true, orderA < orderB
    end
    return false
end

function XUiMonsterCombatRoleList:InTeamAndInRecommendSort(idA, idB)
    if not self.IsBattle then
        return false
    end
    local weightA = 0
    local weightB = 0
    local isInTeamA = self:GetMonsterIdIsInTeam(idA)
    local isInTeamB = self:GetMonsterIdIsInTeam(idB)
    weightA = weightA + (isInTeamA and 1000 or 0)
    weightB = weightB + (isInTeamB and 1000 or 0)
    local isInRecommendA = self:GetMonsterIdIsInRecommend(idA)
    local isInRecommendB = self:GetMonsterIdIsInRecommend(idB)
    weightA = weightA + (isInRecommendA and 100 or 0)
    weightB = weightB + (isInRecommendB and 100 or 0)
    local isInFetterA = self:GetMonsterIdIsInFetter(idA)
    local isInFetterB = self:GetMonsterIdIsInFetter(idB)
    weightA = weightA + (isInFetterA and 10 or 0)
    weightB = weightB + (isInFetterB and 10 or 0)
    if weightA ~= weightB then
        return true, weightA > weightB
    end
    return false
end

function XUiMonsterCombatRoleList:MonsterListSort(monsterList)
    table.sort(monsterList, function(a, b)
        local isSort, sortResult = UnlockSort(a, b)
        if isSort then
            return sortResult
        end
        isSort, sortResult = self:InTeamAndInRecommendSort(a, b)
        if isSort then
            return sortResult
        end
        isSort, sortResult = OrderSort(a, b)
        if isSort then
            return sortResult
        end
        return a < b
    end)
end

function XUiMonsterCombatRoleList:UpdateCurMonsterInfo(monsterId)
    self.CurrentMonsterId = monsterId
    self:UpdateRoleModel()

    if not XLuaUiManager.IsUiShow(XMonsterCombatConfigs.MonsterInfoUiName) then
        self:OpenOneChildUi(XMonsterCombatConfigs.MonsterInfoUiName, self)
    end
    ---@type XUiMonsterCombatInfo
    local childUi = self:FindChildUiObj(XMonsterCombatConfigs.MonsterInfoUiName)
    childUi:Refresh(monsterId)
    if self.IsBattle then
        childUi:SetJoinBtnIsActive(not self:GetMonsterIdIsInTeam(monsterId))
    else
        childUi:SetTeamBtnStatus(false)
    end
    --childUi:SetPanelDateActive(not self.IsBattle)
    childUi:PlayAnimation("AnimEnable")
end

-- 更新模型
function XUiMonsterCombatRoleList:UpdateRoleModel()
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    local monsterEntity = XDataCenter.MonsterCombatManager.GetMonsterEntity(self.CurrentMonsterId)
    local roleName = monsterEntity:GetUiModelId()
    self.UiPanelRoleModel:UpdateRoleModel(roleName, self.PanelRoleModel, self.Name, function(model)
        self.PanelDrag.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    end)
end

function XUiMonsterCombatRoleList:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)

    self:BindHelpBtn(self.BtnHelp, XDataCenter.MonsterCombatManager.GetHelpKey())
end

function XUiMonsterCombatRoleList:OnBtnBackClick()
    self:Close()
end

function XUiMonsterCombatRoleList:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiMonsterCombatRoleList:OnBtnJoinTeamClicked()
    -- 负重上限
    local costLimit = XDataCenter.MonsterCombatManager.GetActivityMonsterCostLimit()
    -- 当前选择的怪物负重
    local curMonsterEntity = XDataCenter.MonsterCombatManager.GetMonsterEntity(self.CurrentMonsterId)
    local curCost = curMonsterEntity:GetCost()
    if curCost > costLimit then
        XLog.Error(string.format("当前选择的怪物负重超出负重上限,当前怪物负重：%s,负重上限:%s", curCost, costLimit))
        return
    end
    -- 已选择的总负重(排除当前位置的怪物)
    local totalCost = 0
    for i, monsterId in pairs(self.MonsterTeam:GetMonsterIds()) do
        if XTool.IsNumberValid(monsterId) and i ~= self.Pos then
            local monsterEntity = XDataCenter.MonsterCombatManager.GetMonsterEntity(monsterId)
            totalCost = totalCost + monsterEntity:GetCost()
        end
    end
    -- 超出负重上限 清空怪物
    if curCost + totalCost > costLimit then
        self.MonsterTeam:ClearMonsterIds()
    end
    self.MonsterTeam:UpdateMonsterPos(self.CurrentMonsterId, self.Pos, true)
    self:Close(true)
end

function XUiMonsterCombatRoleList:OnBtnQuitTeamClicked()
    self.MonsterTeam:UpdateMonsterPos(self.CurrentMonsterId, self.Pos, false)
    self:Close()
end

function XUiMonsterCombatRoleList:Close(updated)
    if updated then
        self:EmitSignal("UpdateMonsterId", self.CurrentMonsterId)
    end
    self.Super.Close(self)
end

return XUiMonsterCombatRoleList