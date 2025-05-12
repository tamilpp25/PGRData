---@class XUiLinkCraftActivityEdit
---@field private _Control XLinkCraftActivityControl
local XUiLinkCraftActivityEdit = XLuaUiManager.Register(XLuaUi, 'UiLinkCraftActivityEdit')

local XUiPanelLinkCraftActivityList = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityEdit/XUiPanelLinkCraftActivityList')
local XUiPanelLinkCraftEditLink = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityEdit/XUiPanelLinkCraftEditLink')
--region 生命周期------------------>>>
function XUiLinkCraftActivityEdit:OnAwake()
    self.BtnBack.CallBack = function() self:CloseEdit() end
    self.BtnMainUi.CallBack = function() self:CloseEdit(true) end
    self.BindHelpBtn(self,self.BtnHelp,"LinkCraftActivity")
end

function XUiLinkCraftActivityEdit:OnStart(index)
    self._SelectIndex = index
    local linkData = self._Control:GetCurLinkListData()
    if linkData == nil then
        self._ErrorTag = true
        self:Close()
        return
    else
        self._ErrorTag = nil
    end
    self._SelectLinkId = linkData:GetId()
    
    self._ListPanel = XUiPanelLinkCraftActivityList.New(self.ListSkill, self, self._SelectLinkId)
    self._ListPanel:Open()

    self._PanelLink = XUiPanelLinkCraftEditLink.New(self.PanelLinkFore,self)
    self._PanelLink:Open()
    self._PanelLink:Init(self._SelectIndex)
    
    self:InitBackground()
    
    self._Control:BackupLinkData()
end

function XUiLinkCraftActivityEdit:OnDestroy()
    if self._Control:CheckIsEditLink() then
        self._Control:SetIsEditLink(false)
        if self._PanelLink._IsValid then
            XMVCA.XLinkCraftActivity:RequestLinkCraftSetLinkSkills()
        else
            --还原
            self._Control:RestoreLinkData()
        end
    end
end
--endregion <<<---------------------

function XUiLinkCraftActivityEdit:InitBackground()
    local curChapterId = self._Control:GetCurChapterId()
    for i = 1, 10 do
        local bg =  self['RImgBg'..i]
        if bg then
            if i == curChapterId then
                bg.gameObject:SetActiveEx(true)
            else
                bg.gameObject:SetActiveEx(false)
            end
        else
            break
        end
    end
end

--需要对无效编辑进行拦截，因此额外定义关闭方法
function XUiLinkCraftActivityEdit:CloseEdit(toMain)
    
    local submitCb = function()
        --正常的关闭流程
        if toMain then
            XLuaUiManager.RunMain()
        else
            self:Close()
        end
    end
    
    --编辑有效性判断
    if not self._ErrorTag and self._PanelLink._IsValid == false then
        XUiManager.DialogTip(self._Control:GetClientConfigString('LinkCannotSubimtTipsTitle'), self._Control:GetClientConfigString('LinkCannotSubimtTips'), XUiManager.DialogType.NormalAndNoBtnTanchuangClose, nil, submitCb)
    else
        submitCb()    
    end
   
end

return XUiLinkCraftActivityEdit