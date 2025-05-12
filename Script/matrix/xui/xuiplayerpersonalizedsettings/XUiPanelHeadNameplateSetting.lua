local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--==========================================XUiPanelHeadNameplateInfo==================================
local XUiPanelHeadNameplateInfo = XClass(XUiNode, 'XUiPanelHeadNameplateInfo')

function XUiPanelHeadNameplateInfo:OnStart()
    self.BtnHeadSure.CallBack = handler(self, self.OnBtnHeadNameplateSureClick)
end

-- 用于访问顶层Ui，主要是方便访问公共变量，后续如果该系统进行MVCA改造后，界面公共变量可转移到Control，直接访问Control
function XUiPanelHeadNameplateInfo:SetRootUi(root)
    self._RootUi = root
    self.BtnHeadCancel.CallBack = handler(self._RootUi, self._RootUi.OnBtnCancelClick)
end

function XUiPanelHeadNameplateInfo:OnBtnHeadNameplateSureClick()
    if self.BtnHeadSure.ButtonState == CS.UiButtonState.Disable then
        return
    end
    if self._RootUi.TempHeadNameplateId ~= nil then
        local id = 0
        if self.BtnType == XHeadPortraitConfigs.BtnState.Use then
            id = self._RootUi.TempHeadNameplateId
        end
        
        -- 判断有没有过期
        
        if XTool.IsNumberValid(id) then
            local data = XDataCenter.MedalManager.CheckNameplateGroupUnluck(XMedalConfigs.GetNameplateConfigById(id).Group)
            if data and not data:IsNamepalteForever() and data:GetNamepalteLeftTime() <= 0 then
                XUiManager.TipText('NameplateOutTime')
                return
            end
        end

        XDataCenter.MedalManager.WearNameplate(id, function()
            if id == 0 then
                self._RootUi.TempHeadNameplateId = 0
                XUiManager.TipText("HeadFrameNonUsecomplete")
            else
                XUiManager.TipText("HeadFrameUsecomplete")
            end
            self.Parent:RefreshHeadNameplateDynamicTable()
            self.Parent:SetHeadNameplateImgRole(self._RootUi.TempHeadNameplateId)
            self.Parent:ShowHeadNameplatePanel()
        end)

    end
    XEventManager.DispatchEvent(XEventId.EVENT_HEAD_PORTRAIT_RESETINFO)
end

function XUiPanelHeadNameplateInfo:SetHeadNameplateDesc(info, Id ,curId)
    local data =  XDataCenter.MedalManager.CheckNameplateGroupUnluck(XMedalConfigs.GetNameplateGroup(Id))

    self.TxtHeadName.text = XTool.IsNumberValid(info.Name) and XMedalConfigs.GetNameplateMapText(info.Name) or info.Name
    
    --描述
    local descTab = {}
    local HintList = XMedalConfigs.GetNameplateHint(Id)
    for index, text in pairs(HintList) do
        table.insert(descTab, XMedalConfigs.GetNameplateMapText(text))
        table.insert(descTab, '\n\n')
    end
    local formatContent = XUiHelper.ReplaceTextNewLine(XUiHelper.GetText('NameplateDescFormat', XMedalConfigs.GetNameplateDescription(Id), table.concat(descTab)))
    self.TxtDecs.text = formatContent
    self.TxtDecs.transform.anchoredPosition = Vector2.zero
    self.TxtCondition.text = XTool.IsNumberValid(info.NameplateGetWay) and XMedalConfigs.GetNameplateMapText(info.NameplateGetWay) or info.NameplateGetWay
    
    self.PanelTxt2.gameObject:SetActiveEx(true)
    self.TxtCondition2.text = XTime.TimestampToGameDateTimeString(data.GetTime)

    if Id == curId then
        self.BtnHeadSure:SetButtonState(CS.UiButtonState.Normal)
        self.BtnHeadSure:SetName(CS.XTextManager.GetText("HeadFrameNonUse"))
        self.BtnType = XHeadPortraitConfigs.BtnState.NonUse
    else
        self.BtnHeadSure:SetButtonState(CS.UiButtonState.Normal)
        self.BtnHeadSure:SetName(CS.XTextManager.GetText("HeadFrameUse"))
        self.BtnType = XHeadPortraitConfigs.BtnState.Use
    end
    
    -- 显示等级图标
    if not XMedalConfigs.GetNameplateQualityIcon(Id) then
        self.IconLevel.gameObject:SetActiveEx(false)
    else
        self.IconLevel.gameObject:SetActiveEx(true)
        self.IconLevel:SetSprite(XMedalConfigs.GetNameplateQualityIcon(Id))
    end
    
    -- 显示等级和升级进度
    if XMedalConfigs.GetNameplateUpgradeType(Id) ~= XMedalConfigs.NameplateGetType.TypeThree or not data then
        self.PanelLevel.gameObject:SetActiveEx(false)
    else
        self.PanelLevel.gameObject:SetActiveEx(true)
        self.TextLevel.text = CS.XTextManager.GetText("NameplateLv", XMedalConfigs.GetNameplateQuality(Id))
        self.TextNum.text = CS.XTextManager.GetText("NameplateExp", data:GetNamepalteExp(), data:GetNameplateUpgradeExp())
        self.ImageExp.fillAmount = data:GetNamepalteExp() / data:GetNameplateUpgradeExp()
    end
end
--===========================================XUiPanelHeadNameplateSetting===============================
local XUiPanelHeadNameplateSetting = XClass(XUiNode, 'XUiPanelHeadNameplateSetting')
local XUiGridHeadNameplate = require('XUi/XUiPlayerPersonalizedSettings/XUiGridHeadNameplate')

function XUiPanelHeadNameplateSetting:OnStart(headNameplate)
    self._PanelHeadNameplateInfo = XUiPanelHeadNameplateInfo.New(headNameplate, self)
    self._PanelHeadNameplateInfo:SetRootUi(self.Parent)
    self._PanelHeadNameplateInfo:Close()
    self:InitHeadNameplateDynamicTable()
end

function XUiPanelHeadNameplateSetting:OnDisable()
    self._PanelHeadNameplateInfo:Close()
    self.HeadNameplateEmpty.gameObject:SetActiveEx(false)
    self:ShowPreviewHeadNameplateInPreviewPanelOnly()
    self.Parent.TempHeadNameplateId = 0
end

function XUiPanelHeadNameplateSetting:InitHeadNameplateDynamicTable()
    self._HeadNameplateDynamicTable = XDynamicTableNormal.New(self.GameObject)
    self._HeadNameplateDynamicTable:SetProxy(XUiGridHeadNameplate, self, self.Parent)
    self._HeadNameplateDynamicTable:SetDelegate(self)
    self.Parent.GridHeadNameplate.gameObject:SetActiveEx(false)
end

function XUiPanelHeadNameplateSetting:ShowPreviewHeadNameplate()
    self.Parent.CurrHeadNameplateId = XDataCenter.MedalManager.GetNameplateCurId() or 0
    self.Parent.OldNameplateSelectGrig = nil
    local IsTrueHeadNameplate =self:SetHeadNameplateImgRole(self.Parent.TempHeadNameplateId ~= 0 and self.Parent.TempHeadNameplateId or self.Parent.CurrHeadNameplateId)
    return IsTrueHeadNameplate
end

function XUiPanelHeadNameplateSetting:ShowPreviewHeadNameplateInPreviewPanelOnly()
    self.Parent.CurrHeadNameplateId = XDataCenter.MedalManager.GetNameplateCurId() or 0
    self.Parent.OldNameplateSelectGrig = nil

    if not XTool.IsNumberValid(self.Parent.CurrHeadNameplateId) then
        self.Parent._PanelNameplate.GameObject:SetActiveEx(false)
        return
    end
    local cfg = XMedalConfigs.GetNameplateConfigById(self.Parent.CurrHeadNameplateId)

    if not cfg then
        self.Parent._PanelNameplate.GameObject:SetActiveEx(false)
        return
    end
    self.Parent._PanelNameplate.GameObject:SetActiveEx(true)
    self.Parent._PanelNameplate:UpdateDataById(self.Parent.CurrHeadNameplateId)

    if (cfg ~= nil) then
        self.Parent.TempHeadNameplateId = self.Parent.CurrHeadNameplateId
    end
end

function XUiPanelHeadNameplateSetting:ShowHeadNameplatePanel()
    local isTrueHeadNameplate = self:ShowPreviewHeadNameplate()

    if isTrueHeadNameplate then
        self._PanelHeadNameplateInfo:Open()
        self.Parent._PanelNoSelectInfo:Close()
    else
        self.Parent._PanelNoSelectInfo:Open()
        self._PanelHeadNameplateInfo:Close()
        self.Parent._PanelNoSelectInfo:RefreshData(CS.XTextManager.GetText("HeadFrameNoSelectTitle"), CS.XTextManager.GetText("HeadNameplateNoSelectHint"))
    end

end

function XUiPanelHeadNameplateSetting:SetupHeadNameplateDynamicTable(index)
    self.PageDatas = XDataCenter.MedalManager.GetNameplateGroupList()
    self._HeadNameplateDynamicTable:SetDataSource(self.PageDatas)
    self._HeadNameplateDynamicTable:ReloadDataSync(index and index or 1)
    if XTool.GetTableCount(self.PageDatas) <= 0 then
        self.HeadNameplateEmpty.gameObject:SetActiveEx(true)
        return
    else
        self.HeadNameplateEmpty.gameObject:SetActiveEx(false)
    end

end

function XUiPanelHeadNameplateSetting:RefreshHeadNameplateDynamicTable()
    self.Parent.CurrHeadNameplateId = XDataCenter.MedalManager.GetNameplateCurId()  or 0
    self._HeadNameplateDynamicTable:ReloadDataSync()
end

function XUiPanelHeadNameplateSetting:SetHeadNameplateRedPoint(grid)
    grid:ShowRedPoint(XDataCenter.MedalManager.CheckHaveNewNameplateById(grid.HeadNameplateId))
end

function XUiPanelHeadNameplateSetting:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self)
        self:SetHeadNameplateRedPoint(grid)
    end
end

function XUiPanelHeadNameplateSetting:SetHeadNameplateImgRole(nameplateId)
    if not XTool.IsNumberValid(nameplateId) then
        self.Parent._PanelNameplate.GameObject:SetActiveEx(false)
        return false
    end
    local cfg = XMedalConfigs.GetNameplateConfigById(nameplateId)

    if not cfg then
        self.Parent._PanelNameplate.GameObject:SetActiveEx(false)
        return false
    end
    self.Parent._PanelNameplate.GameObject:SetActiveEx(true)
    self.Parent._PanelNameplate:UpdateDataById(nameplateId)
    
    if (cfg ~= nil) then
        self.Parent.TempHeadNameplateId = nameplateId
        if self.Parent.CurType == XHeadPortraitConfigs.HeadType.Nameplate then
            self.Parent:SetHeadTime(cfg, self._PanelHeadNameplateInfo, nameplateId, XHeadPortraitConfigs.HeadType.Nameplate)
            self._PanelHeadNameplateInfo:SetHeadNameplateDesc(cfg, nameplateId, self.Parent.CurrHeadNameplateId)
        end
        return true
    else
        return false
    end
end

return XUiPanelHeadNameplateSetting