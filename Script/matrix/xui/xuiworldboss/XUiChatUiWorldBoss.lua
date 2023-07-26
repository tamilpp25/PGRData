local XUiChatUiWorldBoss = XLuaUiManager.Register(XLuaUi, "UiChatUiWorldBoss")
local XUiGridReportMsgItem = require("XUi/XUiWorldBoss/XUiGridReportMsgItem")

function XUiChatUiWorldBoss:OnStart()
    self:SetButtonCallBack()
    self:InitDynamicTable()
    self:UpdateReportData()
end

function XUiChatUiWorldBoss:OnDestroy()
end

function XUiChatUiWorldBoss:OnEnable()
    XDataCenter.WorldBossManager.CheckWorldBossActivityReset()
    XLuaUiManager.SetMask(true)
    XEventManager.AddEventListener(XEventId.EVENT_WORLDBOSS_REPORT, self.UpdateReportData, self)
    self:PlayAnimation("AnimChatEnter", function()
            XLuaUiManager.SetMask(false)
        end)
    
end

function XUiChatUiWorldBoss:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_WORLDBOSS_REPORT, self.UpdateReportData, self)
end

function XUiChatUiWorldBoss:UpdateReportData()
    self:SetupDynamicTable()
end

function XUiChatUiWorldBoss:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelChatView)
    self.DynamicTable:SetProxy(XUiGridReportMsgItem)
    self.GridChatItem.gameObject:SetActiveEx(false)
    self.DynamicTable:SetDelegate(self)
end

function XUiChatUiWorldBoss:SetupDynamicTable()
    self.PageDatas = XDataCenter.WorldBossManager.GetWorldBossReportList()
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(#self.PageDatas)
end

function XUiChatUiWorldBoss:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.PageDatas[index])
    end
end

function XUiChatUiWorldBoss:SetButtonCallBack()
    self.BtnClocs.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnChat.CallBack = function()
        self:OnBtnClocsClick()
    end
end

function XUiChatUiWorldBoss:OnBtnCloseClick()
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("AnimChatOut", function()
            XLuaUiManager.SetMask(false)
            self:Close()
        end)
end