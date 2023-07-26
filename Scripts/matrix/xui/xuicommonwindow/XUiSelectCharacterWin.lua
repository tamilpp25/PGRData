--选取角色页面
local XUiSelectCharacterWin = XLuaUiManager.Register(XLuaUi, "UiSelectCharacterWin")
local XUiSelectCharacterGrid = require("XUi/XUiCommonWindow/XUiSelectCharacterGrid")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

--自定义选择种类
UiSelectCharacterType = {
    Normal = 1, --选取我所拥有的角色
    LimitedByCharacterAndRobot = 2, --在给定的限制范围（robotId，以及这些robot对应的characterid）内选取角色 工会boss使用
    WorldBoss = 3, --选取我所拥有的角色和开放的机器人（世界Boss用）
    NieROnlyRobot = 4, --仅使用开放的机器人（尼尔玩法用）
}

function XUiSelectCharacterWin:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnJoinTeam.CallBack = function() self:OnBtnJoinTeamClick() end
    self.BtnQuitTeam.CallBack = function() self:OnBtnQuitTeamClick() end
    self.BtnFashion.CallBack = function() self:OnBtnFashionClick() end
    self.BtnFashion2.CallBack = function() self:OnBtnFashionClick() end
    self.BtnConsciousness.CallBack = function() self:OnBtnConsciousnessClick() end
    self.BtnWeapon.CallBack = function() self:OnBtnWeaponClick() end
    self.BtnTeaching.CallBack = function() self:OnBtnTeachingClick() end
    self:RegisterClickEvent(self.BtnPartner, self.OnCarryPartnerClick)

    self.GridCharacterObj.gameObject:SetActiveEx(false)
    self.BtnFashion2.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelCharacterList)
    self.DynamicTable:SetProxy(XUiSelectCharacterGrid)
    self.DynamicTable:SetDelegate(self)

    local root = self.UiModelGo
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true)
    self.XDrag = self.PanelDrag:GetComponent("XDrag")

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.CharacterGrids = {}
    self.CurSelectData = nil
    self.SelectIndex = 1

    self.NeedUpdate = false
end

function XUiSelectCharacterWin:OnStart(cb, type, teamData, editPos, ...)
    self.Cb = cb --选择回调
    self.Type = type --选择类型
    self.TeamData = teamData --当前队伍情况
    self.EditPos = editPos --当前编辑的位置
    self.Args = (...)
end

function XUiSelectCharacterWin:UpdateByType()
    if self.Type == UiSelectCharacterType.Normal then
        self:NormalTypeUpdate(self.Args)
    elseif self.Type == UiSelectCharacterType.LimitedByCharacterAndRobot then
        self:LimitedByCharacterAndRobotTypeUpdate(self.Args)
    elseif self.Type == UiSelectCharacterType.WorldBoss then
        self:WorldBossUpdate(self.Args)
    elseif self.Type == UiSelectCharacterType.NieROnlyRobot then
        self:NieRUpdate(self.Args)
    end
end

function XUiSelectCharacterWin:OnEnable()
    self:UpdateByType()
    if self.NeedUpdate then
        self:OnSelect(self.CurSelectData)
    end
    self.NeedUpdate = true
end

function XUiSelectCharacterWin:NormalTypeUpdate()

end


--LimitedByCharacterAndRobot规则的构造列表 参数：(机器人id列表，角色原型Id列表)
function XUiSelectCharacterWin:LimitedByCharacterAndRobotTypeUpdate(robotTab)
    local list = XTool.Clone(robotTab)
    --拥有对应的character才加入可选列表
    for i = 1, #robotTab do
        local characterId = XRobotManager.GetRobotTemplate(robotTab[i]).CharacterId
        if XDataCenter.CharacterManager.IsOwnCharacter(characterId) then
            table.insert(list, characterId)
        end
    end
    self.GridData = {}
    for i = 1, #list do
        if i <= #robotTab then
            table.insert(self.GridData, { Type = UiCharacterGridType.Try, Id = list[i] })
        else
            table.insert(self.GridData, { Type = UiCharacterGridType.Normal, Id = list[i] })
        end
    end

    --排序
    local function sortByAbility(a, b)
        return self:GetAbility(a) > self:GetAbility(b)
    end
    table.sort(self.GridData, sortByAbility)

    self:DefaultSelect()
    self.DynamicTable:SetDataSource(self.GridData)
    self.DynamicTable:ReloadDataASync(self.SelectIndex)
end

function XUiSelectCharacterWin:WorldBossUpdate(robotTab)
    local list = XTool.Clone(robotTab)
    local charlist = XDataCenter.CharacterManager.GetCharacterListInTeam(XCharacterConfigs.CharacterType.Normal)
    for _, char in pairs(charlist) do
        table.insert(list, char.Id)
    end


    self.GridData = {}
    for i = 1, #list do
        if i <= #robotTab then
            table.insert(self.GridData, { Type = UiCharacterGridType.Try, Id = list[i] })
        else
            table.insert(self.GridData, { Type = UiCharacterGridType.Normal, Id = list[i] })
        end
    end

    --排序
    local function sortByAbility(a, b)
        if a.Type == b.Type then
            return self:GetAbility(a) > self:GetAbility(b)
        else
            return a.Type == UiCharacterGridType.Try
        end

    end
    table.sort(self.GridData, sortByAbility)

    self:DefaultSelect()
    self.DynamicTable:SetDataSource(self.GridData)
    self.DynamicTable:ReloadDataASync(self.SelectIndex)
end

function XUiSelectCharacterWin:NieRUpdate(robotTab)
    local list = XTool.Clone(robotTab)

    self.GridData = {}
    for i = 1, #list do
        table.insert(self.GridData, { Type = UiCharacterGridType.Try, Id = list[i], NieRCharacterId = XDataCenter.NieRManager.GetCharacterIdByNieRRobotId(list[i]) })
    end

    --排序
    local function sortByAbility(a, b)
        if a.Type == b.Type then
            local aCharacterId = a.NieRCharacterId
            local bCharacterId = b.NieRCharacterId
            if aCharacterId == 0 and 0 ~= bCharacterId then
                return true
            elseif aCharacterId ~= 0 and bCharacterId ~= 0 then
                return XDataCenter.NieRManager.GetNieRCharacterByCharacterId(aCharacterId):GetAbilityNum() > XDataCenter.NieRManager.GetNieRCharacterByCharacterId(bCharacterId):GetAbilityNum()
            elseif 0 == aCharacterId and 0 == bCharacterId then
                return self:GetAbility(a) > self:GetAbility(b)
            end
            return false
        else
            return a.Type == UiCharacterGridType.Try
        end

    end
    table.sort(self.GridData, sortByAbility)

    self:DefaultSelect()
    self.DynamicTable:SetDataSource(self.GridData)
    self.DynamicTable:ReloadDataASync(self.SelectIndex)
end

--获取战力
function XUiSelectCharacterWin:GetAbility(data)
    if data.Type == UiCharacterGridType.Try then
        return XRobotManager.GetRobotAbility(data.Id)
    elseif data.Type == UiCharacterGridType.Normal then
        return XDataCenter.CharacterManager.GetCharacter(data.Id).Ability
    end
end

--每种情况下的默认选择
function XUiSelectCharacterWin:DefaultSelect()
    if self.Type == UiSelectCharacterType.Normal then

    elseif self.Type == UiSelectCharacterType.LimitedByCharacterAndRobot then
        if self.TeamData[self.EditPos] ~= 0 then
            for i = 1, #self.GridData do
                if self.TeamData[self.EditPos] == self.GridData[i].Id then
                    self.SelectIndex = i
                    break
                end
            end
        end
    elseif self.Type == UiSelectCharacterType.WorldBoss then
        if self.TeamData[self.EditPos] ~= 0 then
            for i = 1, #self.GridData do
                if self.TeamData[self.EditPos] == self.GridData[i].Id then
                    self.SelectIndex = i
                    break
                end
            end
        end
    elseif self.Type == UiSelectCharacterType.NieROnlyRobot then
        if self.TeamData[self.EditPos] ~= 0 then
            for i = 1, #self.GridData do
                if self.TeamData[self.EditPos] == self.GridData[i].Id then
                    self.SelectIndex = i
                    break
                end
            end
        end
    end
end

--每种类型的功能按钮需求
function XUiSelectCharacterWin:UpdateFunctionBtn()
    local isSame = self.TeamData[self.EditPos] == self.CurSelectData.Id
    self.BtnJoinTeam.gameObject:SetActiveEx(not isSame)
    self.BtnQuitTeam.gameObject:SetActiveEx(isSame)
    self.BtnFashion2.gameObject:SetActiveEx(false)

    if self.Type == UiSelectCharacterType.NieROnlyRobot then
        local nierChId = XDataCenter.NieRManager.GetCharacterIdByNieRRobotId(self.CurSelectData.Id)
        if nierChId ~= 0 then
            self.BtnFashion2.gameObject:SetActiveEx(true)
        end
    end
    if self.CurSelectData.Type == UiCharacterGridType.Normal then
        self.BtnFashion.gameObject:SetActiveEx(true)
        self.BtnConsciousness.gameObject:SetActiveEx(true)
        self.BtnWeapon.gameObject:SetActiveEx(true)
        self.BtnPartner.gameObject:SetActiveEx(true)
    elseif self.CurSelectData.Type == UiCharacterGridType.Try then
        self.BtnFashion.gameObject:SetActiveEx(false)
        self.BtnConsciousness.gameObject:SetActiveEx(false)
        self.BtnWeapon.gameObject:SetActiveEx(false)
        self.BtnPartner.gameObject:SetActiveEx(false)
    end
end

--每种情况下获取选中的characterId
function XUiSelectCharacterWin:GetCharacterId()
    if self.CurSelectData.Type == UiCharacterGridType.Normal then
        return self.CurSelectData.CharacterData.Id
    elseif self.CurSelectData.Type == UiCharacterGridType.Try then
        return self.CurSelectData.RobotData.CharacterId
    end
end

--把id转换成characterId
function XUiSelectCharacterWin:GetCharacterIdById(id)
    if not XRobotManager.CheckIsRobotId(id) then
        return id
    elseif id > 0 then
        return XRobotManager.GetRobotTemplate(id).CharacterId
    end
end

function XUiSelectCharacterWin:UpdateRoleModel(targetUiName)
    local loadModeCb = function(model)
        if not model then
            return
        end
        self.XDrag.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActive(false)
        self.ImgEffectHuanren.gameObject:SetActive(true)
    end
    if self.CurSelectData.Type == UiCharacterGridType.Try then
        local robotId = self.CurSelectData.Id
        local robotCfg = XRobotManager.GetRobotTemplate(robotId)
        if self.Type == UiSelectCharacterType.NieROnlyRobot then
            local fashionId = robotCfg.FashionId
            local weaponId = robotCfg.WeaponId
            local nierChId = XDataCenter.NieRManager.GetCharacterIdByNieRRobotId(robotId)
            if nierChId ~= 0 then
                local nierCharacter = XDataCenter.NieRManager.GetNieRCharacterByCharacterId(nierChId)
                weaponId = nierCharacter:GetNieRWeaponId()
                fashionId = nierCharacter:GetNieRFashionId()
            end
            self.RoleModelPanel:UpdateRobotModel(robotId, self:GetCharacterId(), nil, fashionId, weaponId, loadModeCb)
        else
            self.RoleModelPanel:UpdateRobotModel(robotId, self:GetCharacterId(), nil, robotCfg.FashionId, robotCfg.WeaponId, loadModeCb)
        end

    else
        self.RoleModelPanel:UpdateCharacterModel(self:GetCharacterId(), nil, targetUiName, loadModeCb)
    end
end



--On Event
function XUiSelectCharacterWin:OnSelect(data)
    self.CurSelectData = data
    self:UpdateRoleModel(self.Name)
    self:UpdateFunctionBtn()
    if self.Type == UiSelectCharacterType.NieROnlyRobot then
        local nierChId = XDataCenter.NieRManager.GetCharacterIdByNieRRobotId(self.CurSelectData.Id)
        if nierChId ~= 0 then
            XDataCenter.NieRManager.SetSelCharacterId(nierChId)
        end
    end
    -- 检查教学功能按钮红点
    XRedPointManager.CheckOnceByButton(self.BtnTeaching, { XRedPointConditions.Types.CONDITION_CELICA_TEACH }, self.CurSelectData.Id)
end

function XUiSelectCharacterWin:OnBtnCloseClick()
    self:Close()
    if self.CloseFinishCallBack then
        self.CloseFinishCallBack()
    end
end

function XUiSelectCharacterWin:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateInfo(self.GridData[index], self.TeamData, self.EditPos, self)
        grid:SetSelectMark(index == self.SelectIndex)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local lastGrid = self.DynamicTable:GetGridByIndex(self.SelectIndex)
        if lastGrid then
            self.DynamicTable:GetGridByIndex(self.SelectIndex):SetSelectMark(false)
        end
        self.SelectIndex = index
        grid:SetSelectMark(true)
        self:OnSelect(self.GridData[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:OnSelect(self.GridData[self.SelectIndex])
    end
end

function XUiSelectCharacterWin:OnBtnBackClick()
    if self.Cb then
        self.Cb(self.TeamData)
    end
    self:Close()
end

function XUiSelectCharacterWin:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiSelectCharacterWin:OnBtnJoinTeamClick()
    local finishCallBack = function()
        --如果该角色已经在队伍中
        for i = 1, #self.TeamData do
            if i ~= self.EditPos and self:GetCharacterIdById(self.TeamData[i]) == self:GetCharacterIdById(self.CurSelectData.Id) then
                self.TeamData[i] = 0
            end
        end
        if self.Cb then
            self.TeamData[self.EditPos] = self.CurSelectData.Id
            self.Cb(self.TeamData)
        end
        self:Close()
    end
    XDataCenter.PracticeManager.OnJoinTeam(self.CurSelectData.Id, handler(self, self.OnBtnTeachingClick), finishCallBack)
end

function XUiSelectCharacterWin:OnBtnQuitTeamClick()
    local id = self.CurSelectData.Id
    for k, v in pairs(self.TeamData) do
        if v == id then
            self.TeamData[k] = 0
            break
        end
    end

    if self.Cb then
        self.Cb(self.TeamData)
    end
    self:Close()
end

function XUiSelectCharacterWin:OnCarryPartnerClick()
    XDataCenter.PartnerManager.GoPartnerCarry(self.CurSelectData.Id, false)
end

function XUiSelectCharacterWin:OnBtnFashionClick()
    if self.Type == UiSelectCharacterType.NieROnlyRobot then
        XLuaUiManager.Open("UiFashion", self.CurSelectData.Id, true, true, XUiConfigs.OpenUiType.NieRCharacterUI)
    else
        XLuaUiManager.Open("UiFashion", self.CurSelectData.Id, true, true)
    end
end

function XUiSelectCharacterWin:OnBtnConsciousnessClick()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwareness(self.CurSelectData.Id)
end

function XUiSelectCharacterWin:OnBtnWeaponClick()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self.CurSelectData.Id, nil, true)
end

function XUiSelectCharacterWin:OnBtnTeachingClick()
    XDataCenter.PracticeManager.OpenUiFubenPractice(self.CurSelectData.Id, true)
end
--On Event end