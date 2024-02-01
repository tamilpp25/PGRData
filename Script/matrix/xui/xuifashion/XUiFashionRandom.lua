
local XUiFashionRandom = XLuaUiManager.Register(XLuaUi, "UiFashionRandom")

function XUiFashionRandom:OnAwake()
    self.RandomFashionListReadyToRequset = {}
    self.BindWeaponFashionDic = {}
    self.RecordBeforeChangeRandomFashionList = {} --用来记录进入界面还未选择任何涂装前的数据
    self.RecordBeforeChangeBindWeaponFashionDic = {} -- 记录绑定的武器
    self:InitModel()
    self:InitButton()
    self:InitDynamicTable()
end

function XUiFashionRandom:InitModel()
    local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")

    ---@type XUiPanelModelV2P6
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

-- RandomFashionListReadyToRequset = {fashionId1 = true , fashionId2 = false ....}
function XUiFashionRandom:RefreshRandomFashionDataList()
    local dataList = XDataCenter.FashionManager.GetCurrentTimeFashionByCharId(self.CharacterId)
    for k, fashionId in pairs(dataList) do
        local fashionData = XDataCenter.FashionManager.GetOwnFashionDataById(fashionId)
        if fashionData then
            self.RandomFashionListReadyToRequset[fashionId] = fashionData.IsRandom and true or false
            self.BindWeaponFashionDic[fashionId] = fashionData.WeaponFashionId
        end
    end

    self.RecordBeforeChangeRandomFashionList = XTool.Clone(self.RandomFashionListReadyToRequset)
    self.RecordBeforeChangeBindWeaponFashionDic = XTool.Clone(self.BindWeaponFashionDic)
    self.BtnSave:SetDisable(true)
end

function XUiFashionRandom:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAllRandom, self.OnBtnAllRandomClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAllCancel, self.OnBtnAllCancelClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRandom, self.OnBtnRandomClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSave, self.OnBtnSaveClick)
end

function XUiFashionRandom:InitDynamicTable()
    self.DynamicTableF = XDynamicTableCurve.New(self.FashionList)
    local grid = require("XUi/XUiFashion/XUiGridFashionRandom")
    self.DynamicTableF:SetProxy(grid, self)
    self.DynamicTableF:SetDelegate(self)
    self.DynamicTableF:SetDynamicEventDelegate(function (event, index, grid, ...)
        self:OnDynamicTableEvent(event, index, grid, ...)
    end)
    
    self.DynamicTableP = XDynamicTableNormal.New(self.FashionPointList)
    local grid = require("XUi/XUiFashion/XUiGridFashionRandomPoint")
    self.DynamicTableP:SetProxy(grid, self)
    self.DynamicTableP:SetDelegate(self)
    self.DynamicTableP:SetDynamicEventDelegate(function (event, index, grid, ...)
        self:OnDynamicTableEventP(event, index, grid, ...)
    end)
end

function XUiFashionRandom:OnStart(characterId)
    self.CharacterId = characterId
    self.InitFashionId = XMVCA.XCharacter:GetCharacter(characterId).FashionId
    self:RefreshRandomFashionDataList()
end

function XUiFashionRandom:OnEnable()
    self:RefreshDynamicTable()
end

function XUiFashionRandom:RefreshDynamicTable(luaIndex)
    local dataList = {}
    for k, v in pairs(self.RandomFashionListReadyToRequset) do
        table.insert(dataList, k)
    end
    table.sort(dataList, function (idA, idB)
        return idA > idB
    end)

    if XTool.IsNumberValid(self.InitFashionId) then
        for k, id in pairs(dataList) do
            if self.InitFashionId == id then
                luaIndex = k
            end
        end
    end
    self.InitFashionId = nil

    self.DynamicTableF:SetDataSource(dataList)
    self.DynamicTableF:ReloadData((luaIndex or 0) - 1)

    self.DynamicTableP:SetDataSource(dataList)
    self.DynamicTableP:ReloadDataSync((luaIndex or 0) - 1)
end

function XUiFashionRandom:OnDynamicTableEvent(event, index, grid, curSelectLuaIndex)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local luaIndex = index + 1
        local fashionId = self.DynamicTableF.DataSource[luaIndex]
        grid:Refresh(fashionId, luaIndex)
        if curSelectLuaIndex == luaIndex then
            self:OnCurSelect(fashionId, curSelectLuaIndex)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_END_DRAG then
        local fashionId = self.DynamicTableF.DataSource[curSelectLuaIndex]
        self:OnCurSelect(fashionId, curSelectLuaIndex)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        local fashionId = self.DynamicTableF.DataSource[curSelectLuaIndex]
        XScheduleManager.ScheduleOnce(function () -- 下一帧再执行
            self:OnCurSelect(fashionId, curSelectLuaIndex)
        end, 0)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        -- local luaIndex = index + 1
        -- local fashionId = self.DynamicTableF.DataSource[luaIndex]
        -- self:OnCurSelect(fashionId, luaIndex)
    end
end

function XUiFashionRandom:OnDynamicTableEventP(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.CurSelectIndex == index, index)
    end
end

function XUiFashionRandom:OnlyRefreshDynamicTableFData()
    local allGrid = self.DynamicTableF:GetGrids()
    for k, grid in pairs(allGrid) do
        local luaIndex = k + 1
        local fashionId = self.DynamicTableF.DataSource[luaIndex]
        grid:Refresh(fashionId, luaIndex)
    end
end

function XUiFashionRandom:OnlyRefreshDynamicTablePData(curSelectIndex)
    local allGrid = self.DynamicTableP:GetGrids()
    for k, grid in pairs(allGrid) do
        grid:Refresh(curSelectIndex == k, k)
    end
end

-- 动态列表选择涂装的回调
function XUiFashionRandom:OnCurSelect(fashionId, curSelectIndex)
    self:RefreshAllSelectBtns()
    self:RefreshBtnRandomState(fashionId, curSelectIndex)
    self:RefreshModel(fashionId)
    self:OnlyRefreshDynamicTablePData(curSelectIndex)
    
    local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
    self.TxtFashionName.text = template.Name

    self.CurSelectFashionId = fashionId or self.CurSelectFashionId
    self.CurSelectIndex = curSelectIndex or self.CurSelectIndex

    self:OnlyRefreshDynamicTableFData(curSelectIndex)
end

-- 绑定的武器涂装切换时调用，由动态列表的gridProxy调用
function XUiFashionRandom:OnBindWeaponFashionChange(fashionId, weaponFashionId, index)
    self.ChangedBindWeaponTrigger = true
    self.BindWeaponFashionDic[fashionId] = weaponFashionId
    self:RefreshDynamicTable(index)
    self:OnRecordDataChange()
end

--检测选择的数据是否有变化，包括涂装选择，武器涂装绑定
function XUiFashionRandom:IsDataSame()
    local isFashionDataSame = XTool.DeepCompare(self.RandomFashionListReadyToRequset, self.RecordBeforeChangeRandomFashionList)
    local isWeaponFashionDataSame = XTool.DeepCompare(self.BindWeaponFashionDic, self.RecordBeforeChangeBindWeaponFashionDic)

    return isFashionDataSame and isWeaponFashionDataSame
end

--检测选择的数据是否有变化 并改变按钮状态
function XUiFashionRandom:OnRecordDataChange() 
    local isDataSame = self:IsDataSame()
    self.BtnSave:SetDisable(isDataSame)
end

function XUiFashionRandom:RefreshModel(fashionId)
    if fashionId == self.CurSelectFashionId and not self.ChangedBindWeaponTrigger then
        return
    end
    self.ChangedBindWeaponTrigger = false -- 绑定武器的脏标记检测

    local targetWeaponFashionId = self.BindWeaponFashionDic[fashionId]
    local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
    self.RoleModelPanel:UpdateCharacterResModel(template.ResourcesId, template.CharacterId, XModelManager.MODEL_UINAME.XUiFashion, function (model)
        if model == self.CurModel and self.CurWeaponId == targetWeaponFashionId then
            return
        end
        if self.CurModel then
            local uiCueId = 1051 
            CS.XAudioManager.PlaySound(uiCueId)
        end

        self.PanelDrag.Target = model.transform

        self.ImgEffectHuanren.gameObject:SetActiveEx(false)
        self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
        if XMVCA.XCharacter:GetIsIsomer(template.CharacterId) then
            self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
        else
            self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        end

        self.CurModel = model
        self.CurWeaponId = targetWeaponFashionId
    end, nil, targetWeaponFashionId)
end

-- 刷新【编入随机】这个按钮的状态，每次动态列表选择涂装时调用
function XUiFashionRandom:RefreshBtnRandomState(fashionId, curSelectIndex)
    local fId = fashionId or self.CurSelectFashionId
    if self.RandomFashionListReadyToRequset[fId] then
        self.BtnRandom:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnRandom:SetButtonState(CS.UiButtonState.Normal)
    end
end

-- 刷新【全部随机】【全部取消】两个按钮的状态
function XUiFashionRandom:RefreshAllSelectBtns()
    local isAllSelect = true
    for k, v in pairs(self.RandomFashionListReadyToRequset) do
        if not v then
            isAllSelect = false
            break
        end
    end

    self.BtnAllRandom.gameObject:SetActiveEx(not isAllSelect)
    self.BtnAllCancel.gameObject:SetActiveEx(isAllSelect)
end

-- 这个回调是在toggle切换状态前触发的
function XUiFashionRandom:OnBtnRandomClick()
    local isRandom = self.RandomFashionListReadyToRequset[self.CurSelectFashionId]
    self.RandomFashionListReadyToRequset[self.CurSelectFashionId] = not isRandom

    -- 每次操作 检查操作后是否为空，禁止玩家设置空列表，弹提示拦截并还原数据
    local isNoSelect = true
    for k, v in pairs(self.RandomFashionListReadyToRequset) do
        if v then
            isNoSelect = false
            break
        end
    end
    if isNoSelect then
        XUiManager.TipError(CS.XTextManager.GetText("RandomFashionLeastSelectOne"))
        self.RandomFashionListReadyToRequset[self.CurSelectFashionId] = true
        self:RefreshBtnRandomState()
        return
    end
    self:OnlyRefreshDynamicTableFData()
    self:OnRecordDataChange()
end

function XUiFashionRandom:OnBtnAllRandomClick()
    for k, v in pairs(self.RandomFashionListReadyToRequset) do
        self.RandomFashionListReadyToRequset[k] = true
    end
    self:RefreshAllSelectBtns()
    self:RefreshBtnRandomState()
    self:OnlyRefreshDynamicTableFData()
    self:OnRecordDataChange()
    XUiManager.TipError(CS.XTextManager.GetText("RandomFashionAllSelect"))
end

function XUiFashionRandom:OnBtnAllCancelClick()
    for k, v in pairs(self.RandomFashionListReadyToRequset) do
        self.RandomFashionListReadyToRequset[k] = false
    end
    self.RandomFashionListReadyToRequset[self.CurSelectFashionId] = true
    self:RefreshAllSelectBtns()
    self:RefreshBtnRandomState()
    self:OnlyRefreshDynamicTableFData()
    self:OnRecordDataChange()
    XUiManager.TipError(CS.XTextManager.GetText("RandomFashionAllCancel"))
end

function XUiFashionRandom:OnBtnSaveClick()
    if self.BtnSave.ButtonState == CS.UiButtonState.Disable then
        return
    end
   
    self:DoSaveDataByRPC(function ()
        self:RefreshRandomFashionDataList()
        self:RefreshDynamicTable(self.CurSelectIndex)
        XUiManager.PopupLeftTip(CS.XTextManager.GetText("RandomFashionSaveSuccess"))
    end)
end

function XUiFashionRandom:OnBtnBackClick()
    local isDataSame = self:IsDataSame()
    if not isDataSame then
        local cancelCb = function ()
            self:Close()
        end
        local confirmCb = function ()
            self:DoSaveDataByRPC()
            self:Close()
        end
        XLuaUiManager.Open("UiDialog", CS.XTextManager.GetText("MissionTeamCountTipTile"), CS.XTextManager.GetText("SettingCheckSave"), XUiManager.DialogType.Normal, cancelCb, confirmCb)
        return    
    end
    self:Close()
end

function XUiFashionRandom:OnBtnMainUiClick()
    local isDataSame = self:IsDataSame()
    if not isDataSame then
        local cancelCb = function ()
            XLuaUiManager.RunMain()
        end
        local confirmCb = function ()
            self:DoSaveDataByRPC()
            XLuaUiManager.RunMain()
        end
        XLuaUiManager.Open("UiDialog", CS.XTextManager.GetText("MissionTeamCountTipTile"), CS.XTextManager.GetText("SettingCheckSave"), XUiManager.DialogType.Normal, cancelCb, confirmCb)
        return    
    end

    XLuaUiManager.RunMain()
end

function XUiFashionRandom:DoSaveDataByRPC(cb)
    local activeList = {}
    for fashionId, v in pairs(self.RandomFashionListReadyToRequset) do
        if v then
            table.insert(activeList, fashionId)
        end
    end
    local fashionSuit = XTool.Clone(self.BindWeaponFashionDic)
    XDataCenter.FashionManager.FashionSuitPoolSaveRequest(self.CharacterId, fashionSuit, activeList, cb)
end

function XUiFashionRandom:OnDestroy()
end

return XUiFashionRandom