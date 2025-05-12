-- 兵法蓝图天赋详细页面
local XUiRpgTowerNature = XLuaUiManager.Register(XLuaUi, "UiRpgTowerNature")
local ItemIcon = require("XUi/XUiRpgTower/Common/XUiRpgTowerItemIcon")
function XUiRpgTowerNature:OnAwake()
    XTool.InitUiObject(self)
    self.BtnClose.CallBack = function() self:OnClose() end
    self.BtnActive.CallBack = function() self:OnClickActive() end
    self.BtnReset.CallBack = function() self:OnClickReset() end
end

function XUiRpgTowerNature:OnStart(rTalent)
    self.RTalent = rTalent
    self:RefreshTalent()
end

function XUiRpgTowerNature:OnEnable()
    self:AddEventListener()
end

function XUiRpgTowerNature:OnDisable()
    self:RemoveEventListener()
end

function XUiRpgTowerNature:OnDestroy()
    self:RemoveEventListener()
end
--================
--增加Event监听
--================
function XUiRpgTowerNature:AddEventListener()
    if self.AddEvent == true then return end
    self.AddEvent = true
    XEventManager.AddEventListener(XEventId.EVENT_RPGTOWER_ON_TALENT_UNLOCK, self.OnUnLockSuccess, self)
    XEventManager.AddEventListener(XEventId.EVENT_RPGTOWER_ON_TALENT_RESET, self.OnResetSuccess, self)
end
--================
--移除Event监听
--================
function XUiRpgTowerNature:RemoveEventListener()
    if self.AddEvent == false then return end
    self.AddEvent = false
    XEventManager.RemoveEventListener(XEventId.EVENT_RPGTOWER_ON_TALENT_UNLOCK, self.OnUnLockSuccess, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RPGTOWER_ON_TALENT_RESET, self.OnResetSuccess, self)
end
--================
--天赋解锁成功时（回调）
--================
function XUiRpgTowerNature:OnUnLockSuccess()
    self:Close()
end
--================
--天赋重置成功时（回调）
--================
function XUiRpgTowerNature:OnResetSuccess()
    self:Close()
end
--================
--刷新面板内容控件
--================
function XUiRpgTowerNature:RefreshTalent()
    self.RImgSkill:SetRawImage(self.RTalent:GetIconPath())
    self.TxtCost.text = self.RTalent:GetCostStr()
    self.TxtName.text = self.RTalent:GetTalentName()
    self.TxtDesc.text = self.RTalent:GetDescription()
    local chara = XDataCenter.RpgTowerManager.GetTeamMemberByCharacterId(self.RTalent:GetCharacterId())
    self.ItemIcon = ItemIcon.New(self.RImgTalentIcon, chara:GetTalentItem(self.RTalent:GetTalentType()))
    local isUnlock = self.RTalent:GetIsUnLock()
    self.PanelBefore.gameObject:SetActiveEx(not isUnlock)
    self.PanelAfter.gameObject:SetActiveEx(isUnlock)
    if self.RTalent:GetIsUnLock() then
        self.TxtCost.gameObject:SetActiveEx(false)
        self.BtnActive:SetButtonState(CS.UiButtonState.Disable)
        self.BtnActive:SetName(CS.XTextManager.GetText("RpgTowerTalentActive"))
        self.BtnReset:SetButtonState(CS.UiButtonState.Normal)
    elseif not self.RTalent:GetCanUnLock() then
        if not self.RTalent:CheckNeedTeamLevel() then
            self.TxtCost.gameObject:SetActiveEx(false)
            self.BtnActive:SetName(CS.XTextManager.GetText("RpgTowerTalentLock"))
        else
            self.TxtCost.gameObject:SetActiveEx(true)
            self.BtnActive:SetButtonState(CS.UiButtonState.Normal)
            self.BtnActive:SetName(CS.XTextManager.GetText("RpgTowerUnlockTalent"))
        end
    else
        self.TxtCost.gameObject:SetActiveEx(true)
        self.BtnActive:SetButtonState(CS.UiButtonState.Normal)
        self.BtnActive:SetName(CS.XTextManager.GetText("RpgTowerUnlockTalent"))
    end
end
--================
--点击激活按钮
--================
function XUiRpgTowerNature:OnClickActive()
    XDataCenter.RpgTowerManager.CharaTalentActive(self.RTalent)
end
--================
--点击重置按钮
--================
function XUiRpgTowerNature:OnClickReset()
    local rChar = XDataCenter.RpgTowerManager.GetTeamMemberByCharacterId(self.RTalent:GetCharacterId())
    if rChar:GetCharaTalentType() ~= self.RTalent:GetTalentType() then
        XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerTalentCompatibilityTips"))
        return
    end

    local tipTitle = CS.XTextManager.GetText("RpgTowerResetOneTalentConfirmTitle")
    local content = CS.XTextManager.GetText("RpgTowerResetOneTalentConfirmContent")
    local confirmCb = function()
        XDataCenter.RpgTowerManager.ResetOneTalent(self.RTalent:GetCharacterId(), self.RTalent)
    end
    XLuaUiManager.Open("UiDialog", tipTitle, content, XUiManager.DialogType.Normal, nil, confirmCb)
end
--================
--点击关闭按钮
--================
function XUiRpgTowerNature:OnClose()
    self:Close()
end