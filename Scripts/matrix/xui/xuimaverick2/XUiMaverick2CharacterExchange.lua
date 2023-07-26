local XUiMaverick2CharacterExchangeGrid = require("XUi/XUiMaverick2/XUiMaverick2CharacterExchangeGrid")

-- 异构阵线2.0 切换角色界面
local XUiMaverick2CharacterExchange = XLuaUiManager.Register(XLuaUi, "UiMaverick2CharacterExchange")

function XUiMaverick2CharacterExchange:OnAwake()
    self.Parent = nil -- 父界面
    self.ChangeCharCb = nil --改变角色回调函数

    self:SetButtonCallBack()
    self:InitDynamicTable()
end

function XUiMaverick2CharacterExchange:OnStart(parent, stageId, changeCharCb)
    self.Parent = parent
    self.StageId = stageId
    self.ChangeCharCb = changeCharCb

    self.RobotCfgList = XDataCenter.Maverick2Manager.GetRobotCfgList(self.StageId, true)
    self:RefreshDynamicTable()
end

function XUiMaverick2CharacterExchange:OnEnable()
    self.Super.OnEnable(self)
end


function XUiMaverick2CharacterExchange:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, self.OnClickBtnClose)
end

function XUiMaverick2CharacterExchange:OnClickBtnClose()
    self.Parent:OnClickBtnBack()
end

function XUiMaverick2CharacterExchange:InitDynamicTable()
    self.GridCharacterNew.gameObject:SetActive(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelScrollView)
    self.DynamicTable:SetProxy(XUiMaverick2CharacterExchangeGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiMaverick2CharacterExchange:RefreshDynamicTable()

    -- 优先选中上次的机器人
    self.SelectRobotIndex = 1
    local robotId = XDataCenter.Maverick2Manager.GetLastSelRobotId()
    local isForbid = XDataCenter.Maverick2Manager.IsRobotForbid(robotId, self.StageId)
    if not isForbid then
        for i, robotCfg in ipairs(self.RobotCfgList) do
            if robotCfg.RobotId == robotId then 
                self.SelectRobotIndex = i
            end
        end
    end

    -- 刷新机器人列表
    self.DynamicTable:SetDataSource(self.RobotCfgList)
    if #self.RobotCfgList > 0 then
        self.DynamicTable:ReloadDataASync(self.SelectRobotIndex)
    end
end

function XUiMaverick2CharacterExchange:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local robotCfg = self.RobotCfgList[index]
        local isSelect = self.SelectRobotIndex == index
        grid:Refresh(robotCfg, self.StageId)
        grid:ShowSelect(isSelect)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickRobot(index, grid)
    end
end

function XUiMaverick2CharacterExchange:OnClickRobot(index, selectGrid)
    -- 禁用/未解锁，播放禁止音效
    local robotCfg = self.RobotCfgList[index]
    local isForbid = XDataCenter.Maverick2Manager.IsRobotForbid(robotCfg.RobotId, self.StageId)
    local isUnlock = XDataCenter.Maverick2Manager.IsRobotUnlock(robotCfg.RobotId)
    if isForbid or not isUnlock then
        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Intercept)
        return
    end

    -- 切换按钮状态
    self.SelectRobotIndex = index
    local grids = self.DynamicTable:GetGrids()
    for i, grid in pairs(grids) do
        local isSelect = i == self.SelectRobotIndex
        grid:ShowSelect(isSelect)
    end

    -- 刷新角色
    self.Parent:UpdateRoleModel(robotCfg.RobotId) 
    self.ChangeCharCb(robotCfg.RobotId)

    -- 关闭界面
    self:OnClickBtnClose()
end

return XUiMaverick2CharacterExchange