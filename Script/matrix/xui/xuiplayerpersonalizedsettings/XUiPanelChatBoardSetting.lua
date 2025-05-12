local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--==========================================XUiPanelChatBoardInfo==================================
local XUiPanelChatBoardInfo = XClass(XUiNode, 'XUiPanelChatBoardInfo')

function XUiPanelChatBoardInfo:OnStart()
    self.BtnHeadSure.CallBack = handler(self, self.OnBtnChatBoardSureClick)
end

-- 用于访问顶层Ui，主要是方便访问公共变量，后续如果该系统进行MVCA改造后，界面公共变量可转移到Control，直接访问Control
function XUiPanelChatBoardInfo:SetRootUi(root)
    self._RootUi = root
    self.BtnHeadCancel.CallBack = handler(self._RootUi, self._RootUi.OnBtnCancelClick)
end

function XUiPanelChatBoardInfo:OnBtnChatBoardSureClick()
    if self.BtnHeadSure.ButtonState == CS.UiButtonState.Disable then
        return
    end
    
    if self._RootUi.TempChatBoardId ~= nil then

        local id = self._RootUi.TempChatBoardId
        
        -- 判断是否已过期
        if XTool.IsNumberValid(id) then
            local chatBoardData = XDataCenter.ChatManager.GetChatBoardDataById(id)
            local chatBoardCfg = XChatConfigs.GetChatBoardCfgById(id)
            if XTool.IsNumberValid(chatBoardCfg.Duration) or not string.IsNilOrEmpty(chatBoardCfg.ExpireTimeStr) then
                if chatBoardData == nil or ( XTool.IsNumberValid(chatBoardData.EndTime) and XTime.GetServerNowTimestamp() >= chatBoardData.EndTime ) then
                    XUiManager.TipText('ChatBoardOverdue')
                    self.Parent:SetHeadTimeText(XUiHelper.GetText('ChatBoardOverdue'))
                    return
                end
            end
        end
        
        XDataCenter.ChatManager.SetCurChatBoardRequest(self._RootUi.TempChatBoardId, function()
            XUiManager.TipText("ChatBoardUsecomplete")
            self.Parent:RefreshChatBoardDynamicTable()
            self.Parent:SetChatBoardImgRole(self._RootUi.TempChatBoardId)
        end)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_HEAD_PORTRAIT_RESETINFO)
end

---@param info XTableChatBoard
function XUiPanelChatBoardInfo:SetChatBoardDesc(info, Id ,curId)
    local isValid = not XDataCenter.ChatManager.CheckChatBoardIsLockById(Id)

    self.TxtHeadName.text = info.Name
    self.TxtDecs.text = info.WorldDesc
    self.TxtDecs.transform.anchoredPosition = Vector2.zero
    self.TxtCondition.text = info.GetDesc

    if Id == curId then
        self.BtnHeadSure:SetButtonState(CS.UiButtonState.Disable)
        self.BtnIsUsing.gameObject:SetActiveEx(true)
        self.BtnIsNotHave.gameObject:SetActiveEx(false)
    elseif not isValid then
        self.BtnHeadSure:SetButtonState(CS.UiButtonState.Disable)
        self.BtnIsUsing.gameObject:SetActiveEx(false)
        self.BtnIsNotHave.gameObject:SetActiveEx(true)
    else
        self.BtnHeadSure:SetButtonState(CS.UiButtonState.Normal)
    end
end

--===========================================XUiPanelChatBoardSetting===============================
local XUiPanelChatBoardSetting = XClass(XUiNode, 'XUiPanelChatBoardSetting')
local XUiGridChatBoard = require("XUi/XUiPlayerPersonalizedSettings/XUiGridChatBoard")

function XUiPanelChatBoardSetting:OnStart(headFrameInfo)
    self._PanelChatBoardInfo = XUiPanelChatBoardInfo.New(headFrameInfo, self)
    self._PanelChatBoardInfo:SetRootUi(self.Parent)
    self:InitChatBoardDynamicTable()
end

function XUiPanelChatBoardSetting:OnDisable()
    self._PanelChatBoardInfo:Close()
    self:ShowPreviewChatBoardInPreviewPanelOnly()
    self.Parent.TempChatBoardId = 0
end

function XUiPanelChatBoardSetting:InitChatBoardDynamicTable()
    self._ChatBoardDynamicTable = XDynamicTableNormal.New(self.GameObject)
    self._ChatBoardDynamicTable:SetProxy(XUiGridChatBoard, self, self.Parent)
    self._ChatBoardDynamicTable:SetDelegate(self)
    self.Parent.GridHeadChatBoard.gameObject:SetActiveEx(false)
end

function XUiPanelChatBoardSetting:SetupChatBoardDynamicTable(index)
    self.PageDatas = XDataCenter.ChatManager.GetShowedChatBoardCfgList()
    self._ChatBoardDynamicTable:SetDataSource(self.PageDatas)
    self._ChatBoardDynamicTable:ReloadDataSync(index and index or 1)
end

function XUiPanelChatBoardSetting:RefreshChatBoardDynamicTable()
    self.Parent.CurrChatBoardId = XDataCenter.ChatManager.GetCurChatBoardId() or 0
    self._ChatBoardDynamicTable:ReloadDataSync()
end

function XUiPanelChatBoardSetting:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self)
        self:SetChatBoardRedPoint(grid)
    end
end

function XUiPanelChatBoardSetting:SetChatBoardRedPoint(grid)
    grid:ShowRedPoint(XDataCenter.ChatManager.CheckIsNewChatBoardById(grid.ChatBoardId), false)
end

function XUiPanelChatBoardSetting:ShowPreviewChatBoard()
    local curChatBoardId = XDataCenter.ChatManager.GetCurChatBoardId()
    if XTool.IsNumberValid(curChatBoardId) then
        self.Parent.CurrChatBoardId = curChatBoardId
    else
        self.Parent.CurrChatBoardId = CS.XGame.ClientConfig:GetInt('DefaultChatBoardId')
    end
    self.Parent.OldChatBoardSelectGrig = nil
    local IsTrueChatBoard =self:SetChatBoardImgRole(self.Parent.TempChatBoardId ~= 0 and self.Parent.TempChatBoardId or self.Parent.CurrChatBoardId)
    return IsTrueChatBoard
end

function XUiPanelChatBoardSetting:ShowPreviewChatBoardInPreviewPanelOnly()
    local curChatBoardId = XDataCenter.ChatManager.GetCurChatBoardId()
    if XTool.IsNumberValid(curChatBoardId) then
        self.Parent.CurrChatBoardId = curChatBoardId
    else
        self.Parent.CurrChatBoardId = CS.XGame.ClientConfig:GetInt('DefaultChatBoardId')
    end
    self.Parent.OldChatBoardSelectGrig = nil
    local info = XChatConfigs.GetChatBoardCfgById(self.Parent.CurrChatBoardId)
    if info ~= nil then
        self.Parent._ChatBoradPreview:Refresh(info.Id)
        self.Parent.TempChatBoardId = self.Parent.CurrChatBoardId
    end
end

function XUiPanelChatBoardSetting:ShowChatBoardPanel()
    local isTrueChatBoard = self:ShowPreviewChatBoard()

    if isTrueChatBoard then
        self._PanelChatBoardInfo:Open()
        self.Parent._PanelNoSelectInfo:Close()
    else
        self.Parent._PanelNoSelectInfo:Open()
        self.Parent._PanelNoSelectInfo:RefreshData(CS.XTextManager.GetText("HeadFrameNoSelectTitle"), CS.XTextManager.GetText("ChatBoardNoSelectHint"))
    end

end

function XUiPanelChatBoardSetting:SetChatBoardImgRole(chatBoardId)
    local info = XChatConfigs.GetChatBoardCfgById(chatBoardId)
    if info ~= nil then
        self.Parent._ChatBoradPreview:Refresh(info.Id)
        self.Parent.TempChatBoardId = chatBoardId
        if self.Parent.CurType == XHeadPortraitConfigs.HeadType.ChatBoard then
            self.Parent:SetHeadTime(info,self._PanelChatBoardInfo, chatBoardId, XHeadPortraitConfigs.HeadType.ChatBoard)
            self._PanelChatBoardInfo:SetChatBoardDesc(info, chatBoardId, self.Parent.CurrChatBoardId)
        end
        return true
    else
        return false
    end
end
function XUiPanelChatBoardSetting:SetHeadTimeText(text)
    self.Parent:SetHeadTimeText(self._PanelChatBoardInfo, text)
end

return XUiPanelChatBoardSetting