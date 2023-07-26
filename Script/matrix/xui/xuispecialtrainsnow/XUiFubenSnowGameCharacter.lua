local XUIGridFubenSnowGameCharacter = require("XUi/XUiSpecialTrainSnow/XUIGridFubenSnowGameCharacter")
---@class XUiFubenSnowGameCharacter : XLuaUi
local XUiFubenSnowGameCharacter = XLuaUiManager.Register(XLuaUi, "UiFubenSnowGameCharacter")

function XUiFubenSnowGameCharacter:OnAwake()
    self:RegisterUiEvents()
    self.GridCharacterNew.gameObject:SetActiveEx(false)
end

function XUiFubenSnowGameCharacter:OnStart(updateCb, closeCb)
    self.UpdateCb = updateCb
    self.CloseCb = closeCb
    self.CurrentRobotId = XDataCenter.FubenSpecialTrainManager.GetSnowGameRobotId()
    self:InitDynamicTable()
end

function XUiFubenSnowGameCharacter:OnEnable()
    self:SetupDynamicTable(self.CurrentRobotId)
end

function XUiFubenSnowGameCharacter:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelScrollView)
    self.DynamicTable:SetProxy(XUIGridFubenSnowGameCharacter, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiFubenSnowGameCharacter:SetupDynamicTable(robotId)
    self.DataList = XFubenConfigs.GetStageTypeRobot(XDataCenter.FubenManager.StageType.SpecialTrainSnow)
    local index = 1
    local isSetRobotId = true
    if robotId then
        for k, v in pairs(self.DataList) do
            if v == robotId then
                index = k
                isSetRobotId = false
                break
            end
        end
    end
    if isSetRobotId then
        robotId = self.DataList[index]
        self:UpdateCurRobotInfo(robotId)
    end
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(index)
end

---@param grid XUIGridFubenSnowGameCharacter
function XUiFubenSnowGameCharacter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local robotId = self.DataList[index]
        grid:Refresh(robotId)
        local isSelect = self.CurrentRobotId == robotId
        if isSelect then
            self.CurSelectGrid = grid
        end
        grid:SetSelected(isSelect)
        grid:SetCurrentSign(isSelect)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local robotId = self.DataList[index]
        if self.CurrentRobotId ~= robotId then
            if self.CurSelectGrid then
                self.CurSelectGrid:SetSelected(false)
                self.CurSelectGrid:SetCurrentSign(false)
            end
            grid:SetSelected(true)
            grid:SetCurrentSign(true)
            self.CurSelectGrid = grid
            self:UpdateCurRobotInfo(robotId)
        end
    end
end

function XUiFubenSnowGameCharacter:UpdateCurRobotInfo(robotId)
    self.CurrentRobotId = robotId
    XDataCenter.FubenSpecialTrainManager.SpecialTrainRankSetRobotRequest(self.CurrentRobotId, self.UpdateCb)
end

function XUiFubenSnowGameCharacter:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, self.OnBtnCancelClick)
end

function XUiFubenSnowGameCharacter:OnBtnCancelClick()
    if self.CloseCb then
        self.CloseCb()
    end
    self:Close()
end

return XUiFubenSnowGameCharacter