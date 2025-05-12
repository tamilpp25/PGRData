local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--==========================================XUiPanelHeadFrameInfo==================================
local XUiPanelHeadFrameInfo = XClass(XUiNode, 'XUiPanelHeadFrameInfo')

function XUiPanelHeadFrameInfo:OnStart()
    self.BtnHeadSure.CallBack = handler(self, self.OnBtnHeadFrameSureClick)
end

-- 用于访问顶层Ui，主要是方便访问公共变量，后续如果该系统进行MVCA改造后，界面公共变量可转移到Control，直接访问Control
function XUiPanelHeadFrameInfo:SetRootUi(root)
    self._RootUi = root
    self.BtnHeadCancel.CallBack = handler(self._RootUi, self._RootUi.OnBtnCancelClick)
end

function XUiPanelHeadFrameInfo:OnBtnHeadFrameSureClick()
    if self.BtnHeadSure.ButtonState == CS.UiButtonState.Disable then
        return
    end
    if self._RootUi.TempHeadFrameId ~= nil then
        local id = 0
        if self.BtnType == XHeadPortraitConfigs.BtnState.Use then
            id = self._RootUi.TempHeadFrameId
            -- 判断有没过期
            if XTool.IsNumberValid(self.Parent._UnLockMarkMap[id]) and not XDataCenter.HeadPortraitManager.IsHeadPortraitValid(id) then
                -- 提示已过期
                XUiManager.TipText('HeadFrameOutTime')
                return
            end
        end
        XDataCenter.HeadPortraitManager.ChangeHeadFrame(id, function()
            if id == 0 then
                self._RootUi.TempHeadFrameId = 0
                XUiManager.TipText("HeadFrameNonUsecomplete")
            else
                XUiManager.TipText("HeadFrameUsecomplete")
            end
            self.Parent:RefreshHeadFrameDynamicTable()
            self.Parent:SetHeadFrameImgRole(self._RootUi.TempHeadFrameId)
            self.Parent:ShowHeadFramePanel()
        end)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_HEAD_PORTRAIT_RESETINFO)
end

function XUiPanelHeadFrameInfo:SetHeadFrameDesc(info, Id ,curId)
    local isValid = XDataCenter.HeadPortraitManager.IsHeadPortraitValid(Id)

    self.TxtHeadName.text = info.Name
    self.TxtDecs.text = info.WorldDesc
    self.TxtDecs.transform.anchoredPosition = Vector2.zero
    self.TxtCondition.text = info.LockDesc

    if Id == curId then
        self.BtnHeadSure:SetButtonState(CS.UiButtonState.Normal)
        self.BtnHeadSure:SetName(CS.XTextManager.GetText("HeadFrameNonUse"))
        self.BtnType = XHeadPortraitConfigs.BtnState.NonUse
    elseif not isValid then
        self.BtnHeadSure:SetButtonState(CS.UiButtonState.Disable)
        self.BtnIsUsing.gameObject:SetActiveEx(false)
        self.BtnIsNotHave.gameObject:SetActiveEx(true)
    else
        self.BtnHeadSure:SetButtonState(CS.UiButtonState.Normal)
        self.BtnHeadSure:SetName(CS.XTextManager.GetText("HeadFrameUse"))
        self.BtnType = XHeadPortraitConfigs.BtnState.Use
    end
end

--===========================================XUiPanelHeadFrameSetting===============================
local XUiPanelHeadFrameSetting = XClass(XUiNode, 'XUiPanelHeadFrameSetting')
local XUiGridHeadFrame = require("XUi/XUiPlayer/XUiGridHeadFrame")

function XUiPanelHeadFrameSetting:OnStart(headFrameInfo)
    self._PanelHeadFrameInfo = XUiPanelHeadFrameInfo.New(headFrameInfo, self)
    self._PanelHeadFrameInfo:SetRootUi(self.Parent)
    self._UnLockMarkMap = {} -- 用于记录当前打开时各个头像框的解锁状态
    self:InitHeadFrameDynamicTable()
end

function XUiPanelHeadFrameSetting:OnDisable()
    self._PanelHeadFrameInfo:Close()
    self:ShowPreviewHeadFrameInPreviewPanelOnly()
    self.Parent.TempHeadFrameId = 0
end

function XUiPanelHeadFrameSetting:InitHeadFrameDynamicTable()
    self._HeadFrameDynamicTable = XDynamicTableNormal.New(self.GameObject)
    self._HeadFrameDynamicTable:SetProxy(XUiGridHeadFrame, self, self.Parent)
    self._HeadFrameDynamicTable:SetDelegate(self)
    self.Parent.GridHeadFrame.gameObject:SetActiveEx(false)
end

function XUiPanelHeadFrameSetting:SetupHeadFrameDynamicTable(index)
    self.PageDatas = XDataCenter.HeadPortraitManager.GetUnlockedHeadPortraitIds(XHeadPortraitConfigs.HeadType.HeadFrame)
    self._HeadFrameDynamicTable:SetDataSource(self.PageDatas)
    self._HeadFrameDynamicTable:ReloadDataSync(index and index or 1)
end

function XUiPanelHeadFrameSetting:RefreshHeadFrameDynamicTable()
    self.Parent.CurrHeadFrameId = XPlayer.CurrHeadFrameId or 0
    self._HeadFrameDynamicTable:ReloadDataSync()
end

function XUiPanelHeadFrameSetting:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self)
        self:SetHeadFrameRedPoint(grid)
    end
end

function XUiPanelHeadFrameSetting:SetHeadFrameRedPoint(grid)
    grid:ShowRedPoint(XDataCenter.HeadPortraitManager.CheckIsNewHeadPortraitById(grid.HeadFrameId), false)
end

function XUiPanelHeadFrameSetting:ShowPreviewHeadFrame()
    self.Parent.CurrHeadFrameId = XPlayer.CurrHeadFrameId or 0
    self.Parent.OldFrameSelectGrig = nil
    local IsTrueHeadFrame =self:SetHeadFrameImgRole(self.Parent.TempHeadFrameId ~= 0 and self.Parent.TempHeadFrameId or self.Parent.CurrHeadFrameId)
    return IsTrueHeadFrame
end

function XUiPanelHeadFrameSetting:ShowPreviewHeadFrameInPreviewPanelOnly()
    self.Parent.CurrHeadFrameId = XPlayer.CurrHeadFrameId or 0
    self.Parent.OldFrameSelectGrig = nil

    local info = XPlayerManager.GetHeadPortraitInfoById(self.Parent.CurrHeadFrameId)
    XUiPlayerHead.InitPortrait(nil, self.Parent.CurrHeadFrameId, self.Parent.Head)
    if (info ~= nil) then
        self.Parent.TempHeadFrameId = self.Parent.CurrHeadFrameId
    end
end

function XUiPanelHeadFrameSetting:ShowHeadFramePanel()
    local isTrueHeadFrame = self:ShowPreviewHeadFrame()
    
    if isTrueHeadFrame then
        self._PanelHeadFrameInfo:Open()
        self.Parent._PanelNoSelectInfo:Close()
    else
        self.Parent._PanelNoSelectInfo:Open()
        self._PanelHeadFrameInfo:Close()
        self.Parent._PanelNoSelectInfo:RefreshData(CS.XTextManager.GetText("HeadFrameNoSelectTitle"), CS.XTextManager.GetText("HeadFrameNoSelectHint"))
    end

end

function XUiPanelHeadFrameSetting:SetHeadFrameImgRole(headId)
    local info = XPlayerManager.GetHeadPortraitInfoById(headId)
    XUiPlayerHead.InitPortrait(nil, headId, self.Parent.Head)
    if (info ~= nil) then
        self.Parent.TempHeadFrameId = headId
        if self.Parent.CurType == XHeadPortraitConfigs.HeadType.HeadFrame then
            self.Parent:SetHeadTime(info,self._PanelHeadFrameInfo, headId)
            self._PanelHeadFrameInfo:SetHeadFrameDesc(info, headId, self.Parent.CurrHeadFrameId)
        end
        return true
    else
        return false
    end
end

--- 用于记录打开界面那一刻头像框的解锁情况，用于指导头像框未解锁时点击装备是提示“未解锁"还是提示”已过期“
function XUiPanelHeadFrameSetting:SetFrameUnLockMark(frameId, unlock)
    self._UnLockMarkMap[frameId] = unlock
end


return XUiPanelHeadFrameSetting