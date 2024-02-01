local XUiGridRiftPluginDrop = require("XUi/XUiRift/Grid/XUiGridRiftPluginDrop")

--大秘境关卡战斗结算界面
local XUiRiftSettlePlugin = XLuaUiManager.Register(XLuaUi, "UiRiftSettlePlugin")

function XUiRiftSettlePlugin:OnAwake()
    self:InitButton()
    self:InitDynamicTable()
end

function XUiRiftSettlePlugin:InitButton()
    self:RegisterClickEvent(self.BtnQuit, self.OnBtnQuitClick)
    self:RegisterClickEvent(self.BtnQuitLuck, self.OnBtnQuitClick)
    self:RegisterClickEvent(self.BtnNext, self.OnBtnNextClick)
    self:RegisterClickEvent(self.BtnSettle, self.OnBtnSettleClick)
    self:RegisterClickEvent(self.BtnContinue, self.OnBtnContinueClick)
end

function XUiRiftSettlePlugin:OnStart(settleData, nextStageGroup, nextStageIndex)
    self.SettleData = settleData
    self.RiftSettleResult = settleData.RiftSettleResult
    self.NextStageGroup = nextStageGroup
    self.NextStageIndex = nextStageIndex

    self.DataList = self.SettleData.RiftSettleResult.PluginDropRecords
    table.sort(self.DataList, XDataCenter.RiftManager.SortDropPluginBase)
end

function XUiRiftSettlePlugin:OnEnable()
    -- 判断要不要进行下一关，显示对应按钮
    if not self.NextStageGroup then
        self.BtnQuit.gameObject:SetActiveEx(false)
        self.BtnNext.gameObject:SetActiveEx(false)
        self.BtnSettle.gameObject:SetActiveEx(true)
    end
    -- 刷新插件列表
    self:RefreshDynamicTable()
    self:SetMouseVisible()
end

-- 进行下一关战斗
function XUiRiftSettlePlugin:OnBtnNextClick()
    CS.XFight.ExitForClient(true)
    -- 直接再进入战斗，关闭界面会在退出战斗前通过remove移除
    XDataCenter.RiftManager.SetCurrSelectRiftStage(self.NextStageGroup)
    local team = nil
    if self.NextStageGroup:GetType() == XRiftConfig.StageGroupType.Multi then
        team = XDataCenter.RiftManager.GetMultiTeamData()[self.NextStageIndex]
    else
        team = XDataCenter.RiftManager.GetSingleTeamData()
    end
    XDataCenter.RiftManager.EnterFight(team)
end

function XUiRiftSettlePlugin:OnBtnSettleClick()
    -- 层结算，不通过直接打开ui来跳转，通过发送trigger，在进入层选择界面是自动检测打开
    local layerId = XDataCenter.RiftManager.GetLastFightXStage():GetParent():GetParent():GetId()
    XLuaUiManager.PopThenOpen("UiRiftSettleWin", layerId, self.SettleData.RiftSettleResult)
end

function XUiRiftSettlePlugin:OnBtnQuitClick()
    self:Close()
end

function XUiRiftSettlePlugin:InitDynamicTable()
    self.GridRiftPluginTips.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelPluginList)
    self.DynamicTable:SetProxy(XUiGridRiftPluginDrop,self)
    self.DynamicTable:SetDelegate(self)
end

function XUiRiftSettlePlugin:RefreshDynamicTable()
    self._PluginShowMap = {}
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiRiftSettlePlugin:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local dropData = self.DataList[index]
        grid:Refresh(dropData)
        grid:RefreshBg()
        grid:SetClickCallBack(handler(self, self.OnBtnContinueClick))
        table.insert(self._PluginShowMap, grid)
    end
end

function XUiRiftSettlePlugin:OnBtnContinueClick()
    if not self._HasPlayAnimation then
        self._HasPlayAnimation = true
        for _, v in pairs(self._PluginShowMap) do
            v:DoOverturn()
        end
    end
    self.BtnContinue.gameObject:SetActiveEx(false)
end

function XUiRiftSettlePlugin:OnDestroy()
    CS.XFight.ExitForClient(true)
end

function XUiRiftSettlePlugin:SetMouseVisible()
    -- 这里只有PC端开启了键鼠以后才能获取到设备
    if CS.XFight.Instance and CS.XFight.Instance.InputSystem then
        local inputKeyboard = CS.XFight.Instance.InputSystem:GetDevice(typeof(CS.XInputKeyboard))
        inputKeyboard.HideMouseEvenByDrag = false
    end
    CS.UnityEngine.Cursor.lockState = CS.UnityEngine.CursorLockMode.None
    CS.UnityEngine.Cursor.visible = true
end

return XUiRiftSettlePlugin